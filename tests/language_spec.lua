local dir=os.getenv("PBZ_ADREVIVE_SCRIPTS") or "Mods/AdRevive/Scripts"
package.path=dir.."/?.lua;"..package.path
local language=require("adlanguage")
local strings=require("adstrings")
local model=require("adworld")
local cases={
    ["en-us"]="en",["zh_Hans_CN"]="zh-Hans",["zh-Hant-HK"]="zh-Hant",["fr-FR"]="fr",["de-DE"]="de",
    ["es-ES"]="es",["es-419"]="es-419",["ru-RU"]="ru",["ja-JP"]="ja",["ko-KR"]="ko",["it-IT"]="it",
    ["pt-BR"]="pt-BR",["pt-PT"]="pt-PT",["th-TH"]="th",["vi-VN"]="vi",
}
for tag,id in pairs(cases) do
    assert(language.resolve(tag)==id,tag)
    local words=strings[id]
    for key in pairs(strings.en) do assert(words[key] and words[key]~="",id.." "..key) end
    assert(#words.names==#model.ALLIES+#model.WEAPONS)
    assert(string.format(words.hold,"○"):find("○",1,true))
    assert(string.format(words.hud,23,4,6,97):find("97",1,true))
    for i,name in ipairs(words.names) do
        local gain=model.formatNotice({key="bossGain",id=i-1,copies=2},words)
        assert(gain:find(name,1,true) and gain:find("×2",1,true) and not gain:find("{",1,true))
    end
    for _,event in ipairs({{key="gain",id=0},{key="fallen",id=1},{key="allyHit",id=10,amount=3},
            {key="heroHit",amount=2,lost=21},{key="bossArrival"}}) do
        assert(not model.formatNotice(event,words):find("{",1,true))
    end
end
assert(language.resolve("zh_TW")=="zh-Hant" and language.resolve("ZH-hk")=="zh-Hant")
assert(language.resolve("es_MX")=="es-419" and language.resolve("pt_br")=="pt-BR")
assert(language.resolve("unsupported")=="en" and language.resolve(nil)=="en")

-- Read only the game's text-language key, including Unreal UTF-16 INI files.
local path=os.tmpname()
local ini="[Other]\r\nCultureName=fr\r\n[/Script/ProjectPBZ.PBZSettingsLocal]\r\nWwiseCultureName=English(US)\r\nCultureName=zh-TW\r\n"
for _,data in ipairs({ini,"\255\254"..ini:gsub(".",function(c) return c.."\0" end)}) do
    local f=assert(io.open(path,"wb"));f:write(data);f:close()
    assert(language.resolve(language.savedCulture(path))=="zh-Hant")
end
os.remove(path)
local saved=language.savedCulture
language.savedCulture=function() return "vi-VN" end
StaticFindObject=function() error("unavailable") end
local words,id,source=language.current()
assert(id=="vi" and words==strings.vi and source=="GameUserSettings")
StaticFindObject=function() return {IsValid=function() return true end,GetCurrentLanguage=function() return "de-DE" end} end
words,id,source=language.current()
assert(id=="de" and source=="engine" and words==strings.de)
language.savedCulture=saved
print("Language selection, both INI encodings and all 15 interface locales passed")
