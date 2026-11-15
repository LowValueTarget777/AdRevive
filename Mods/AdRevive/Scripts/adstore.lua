local json = require("adjson")
local store = {}

-- Keep the last committed slot while its successor is being written.
function store.open(base, newWorld)
    local best, found
    for slot = 0, 1 do
        local f = io.open(base .. "-" .. slot .. ".json", "rb")
        if f then
            found = true
            local bytes = f:read("*a")
            f:close()
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
    return best or {version=2, sequence=0, seconds=0, completed=0, deaths=0, world=newWorld()}
end

function store.save(base,p)
    local seq = p.sequence+1
    local dest = base .. "-" .. (seq%2) .. ".json"
    local tmp = dest .. ".tmp"
    p.sequence = seq
    local ok, err = pcall(function()
        local data = json.encode(p)
        local f = assert(io.open(tmp,"wb"))
        local wrote,why = f:write(data)
        local closed,e = f:close()
        assert(wrote,why)
        assert(closed,e)
        os.remove(dest)
        assert(os.rename(tmp,dest))
    end)
    if not ok then p.sequence=seq-1; os.remove(tmp); error(err) end
end
return store
