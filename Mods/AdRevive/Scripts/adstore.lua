local json = require("adjson")
local store = {}

local function engineFiles()
    local files=StaticFindObject("/Script/EasyCsv.Default__EasyCsv")
    assert(files and files:IsValid(),"PBZ file writer unavailable")
    return files
end

local function readSlot(path)
    -- The Windows Lua CRT can misinterpret UTF-8 Steam library paths.
    if path:find("[\128-\255]") then
        local paths=StaticFindObject("/Script/Engine.Default__BlueprintPathsLibrary")
        if not paths:FileExists(path) then return end
        local out={}
        assert(engineFiles():LoadStringFromLocalFile(path,out),"cannot read "..path)
        return out.OutString:ToString()
    end
    local f,why,code=io.open(path,"rb")
    if not f and code==2 then return end
    assert(f,why)
    local bytes,err=f:read("*a")
    f:close()
    return assert(bytes,err)
end

-- Keep the last committed slot while its successor is being written.
function store.read(base)
    local best, found
    for slot = 0, 1 do
        local bytes = readSlot(base .. "-" .. slot .. ".json")
        if bytes then
            found = true
            local ok, p = pcall(json.decode, bytes)
            if ok and type(p)=="table" and p.version==2 and type(p.world)=="table"
                and type(p.world.cards)=="table" and #p.world.cards==2
                and type(p.seconds)=="number" and p.seconds>=0 and p.seconds<30
                and type(p.completed)=="number" and type(p.deaths)=="number" then
                p.sequence = p.sequence or 0
                if type(p.sequence)=="number" and (not best or p.sequence>best.sequence) then best=p end
            end
        end
    end
    assert(best or not found, "cannot read the saved ADgame battle")
    return best
end

function store.save(base,p)
    local seq = p.sequence+1
    local dest = base .. "-" .. (seq%2) .. ".json"
    local tmp
    p.sequence = seq
    local ok, err = pcall(function()
        local data = json.encode(p)
        if dest:find("[\128-\255]") then
            -- The other slot remains intact if this write is interrupted.
            assert(engineFiles():SaveStringToFileWithFullPath(data,dest),"cannot write "..dest)
            return
        end
        tmp = dest .. ".tmp"
        local f, openError, code = io.open(tmp,"wb")
        if not f and code == 2 then
            -- PBZ's in-process file writer creates missing parent directories.
            -- Only bootstrap our temporary slot, then use the normal byte writer.
            assert(engineFiles():SaveStringToFileWithFullPath("{}", tmp), openError)
            f, openError = io.open(tmp, "wb")
        end
        assert(f, openError)
        local wrote,why = f:write(data)
        local closed,e = f:close()
        assert(wrote,why)
        assert(closed,e)
        os.remove(dest)
        assert(os.rename(tmp,dest))
    end)
    if not ok then
        p.sequence=seq-1
        if tmp then os.remove(tmp) end
        error(err)
    end
end
return store
