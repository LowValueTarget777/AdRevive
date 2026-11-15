local strings=require("adstrings")
local language={}

function language.resolve(tag)
    local id=(tag or ""):lower():gsub("_","-"):match("^%s*([a-z0-9-]+)") or ""
    local base=id:match("^[a-z]+")
    if base=="zh" then
        local parts="-"..id.."-"
        if parts:find("-hant-",1,true) or parts:find("-cht-",1,true) then return "zh-Hant" end
        if parts:find("-hans-",1,true) then return "zh-Hans" end
        return (parts:match("%-tw%-") or parts:match("%-hk%-") or parts:match("%-mo%-")) and "zh-Hant" or "zh-Hans"
    end
    if base=="pt" then return id:match("^pt%-br") and "pt-BR" or "pt-PT" end
    if base=="es" then return (id=="es" or id:match("^es%-es")) and "es" or "es-419" end
    return strings[base] and base or "en"
end

-- PBZ stores text and Wwise audio languages separately.
function language.savedCulture(path)
    local f=io.open(path,"rb")
    if not f then return end
    local content=f:read("*a"); f:close()
    if content:sub(1,2)=="\255\254" then content=content:sub(3):gsub("%z","") end
    content=content:gsub("^\239\187\191","")
    local section
    for line in content:gmatch("[^\r\n]+") do
        local header=line:match("^%s*%[([^%]]+)%]")
        if header then section=header:lower()
        elseif section=="/script/projectpbz.pbzsettingslocal" then
            local tag=line:lower():match('^%s*culturename%s*=%s*"?([%w_-]+)')
            if tag then return tag end
        end
    end
end

function language.current()
    local ok,tag=pcall(function()
        local lib=StaticFindObject("/Script/Engine.Default__KismetInternationalizationLibrary")
        if not lib or not lib:IsValid() then return end
        local value=lib:GetCurrentLanguage()
        return type(value)=="string" and value or value:ToString()
    end)
    local source="engine"
    if not ok or type(tag)~="string" or not tag:match("%S") then
        local profile=os.getenv("LOCALAPPDATA")
        tag=profile and language.savedCulture(profile.."\\ProjectPBZ\\Saved\\Config\\Windows\\GameUserSettings.ini")
        source=tag and "GameUserSettings" or "default"
    end
    local id=language.resolve(tag)
    return strings[id],id,source
end
return language
