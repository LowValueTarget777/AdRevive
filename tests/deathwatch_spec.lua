-- Exercise the target and UFunction declarations without a game process.
local root = "/Game/PBZContent/Blueprint/Character/Player/"
local base = root .. "BP_Player_Base.BP_Player_Base_C:OnDie"
local soul = root .. "BP_Player_Soul.BP_Player_Soul_C:OnDie"
local force = "/Script/ProjectPBZ.PBZAbilityBlueprintLibrary:SetCharacterToDie"
local effect = "/Script/GameplayAbilities.AbilitySystemComponent:BP_ApplyGameplayEffectToSelf"
local killPackage = "/Game/PBZContent/Blueprint/Ability/GameplayEffects/GE_Kill"
local function object()
    return {IsValid = function() return true end}
end
local function param(obj) return {get = function() return obj end} end
local function asset(package, name)
    local value = object()
    function value:GetFName() return {ToString = function() return name end} end
    function value:GetFullName() return "BlueprintGeneratedClass " .. package .. "." .. name end
    return param(value)
end

local available = {[base] = true, [effect] = true, [force] = true}
local callbacks, retry, cancelled = {}, nil, false
function StaticFindObject(path) return available[path] and object() or nil end
function RegisterHook(path, cb)
    assert(available[path] and not callbacks[path], "unloaded or duplicate hook")
    callbacks[path] = cb
    return 1, 2
end
function LoopInGameThreadWithDelay(ms, cb) assert(ms > 0 and not retry); retry = cb; return 7 end
function CancelDelayedAction(id) assert(id == 7); cancelled = true end
local player, other = object(), object()
player.AbilitySystemComponent, other.AbilitySystemComponent = object(), object()
local notices, errors = 0, 0
local g = {getPlayer = function() return player end, same = function(a, b) return a == b end}
local function noticed(p) assert(p == player); notices = notices + 1 end
local function log() errors = errors + 1 end
local watcher = dofile("Mods/AdRevive/Scripts/deathwatch.lua")
watcher.install(g, noticed, log)
assert(retry and not cancelled and callbacks[force] and callbacks[effect] and callbacks[base] and not callbacks[soul])
watcher.install(g, noticed, log)
local function owned(callback, expected)
    local before = notices
    assert(callback() == nil, "UFunction return override")
    assert(notices - before == expected, "incorrect player ownership")
end
owned(function() return callbacks[force](nil, param(other)) end, 0)
owned(function() return callbacks[force](nil, param(player)) end, 1)
owned(function() return callbacks[base](param(other)) end, 0)
owned(function() return callbacks[base](param(player)) end, 1)
owned(function() return callbacks[effect](param(other.AbilitySystemComponent), asset(killPackage, "GE_Kill_C")) end, 0)
owned(function() return callbacks[effect](param(player.AbilitySystemComponent), asset("/Other/GE_Kill", "GE_Kill_C")) end, 0)
owned(function() return callbacks[effect](param(player.AbilitySystemComponent), asset(killPackage, "GE_Kill_C")) end, 1)
owned(function() return callbacks[effect](param(player.AbilitySystemComponent), asset(killPackage, "Default__GE_Kill_C")) end, 1)
owned(function() return callbacks[effect](param(player.AbilitySystemComponent), asset(killPackage, "GE_Heal")) end, 0)
retry()
assert(not cancelled and not callbacks[soul], "pending optional blueprint must remain untouched")
available[soul] = true
local renew = "/Game/RenewalContent/Prototypes/Character/BP_RenewalPlayer.BP_RenewalPlayer_C:"
for _, method in ipairs({"On Dead", "Respawn Set Transform", "Respawn Refresh Monster", "Respawn Reset Combat Logic", "Respawn"}) do
    available[renew .. method] = true
end
available["/Game/RenewalContent/Actors/Players/BP_Renewal_Hun.BP_Renewal_Hun_C:Respawn"] = true
available["/Game/PBZContent/UI/InGame/Dead/GA_PlayerRespawn.GA_PlayerRespawn_C:K2_ActivateAbility"] = true
retry()
assert(cancelled and callbacks[soul])
owned(function() return callbacks[soul](param(player)) end, 1)
local oldPawn = player
player = other
owned(function() return callbacks[soul](param(oldPawn)) end, 0)
owned(function() return callbacks[effect](param(oldPawn.AbilitySystemComponent), asset(killPackage, "GE_Kill_C")) end, 0)
assert(errors == 0)
print("death observers passed ownership, streaming and native-call pass-through checks")
