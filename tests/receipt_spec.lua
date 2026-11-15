-- Call the same one-callback Blueprint hook installed in UE4SS. Mock TMap
-- keys/values are RemoteUnrealParams just as they are on the PBZ loader.
package.path = "Mods/AdRevive/Scripts/?.lua;" .. package.path
local receipt = dofile("Mods/AdRevive/Scripts/receipt.lua")
local hookPath = "/PBZCombatAsset/Prototypes/Abilities/GA_CommonUtilitiesPassive.GA_CommonUtilitiesPassive_C:OnTaken"
local namespace = "/Script/SGameCombatSystem."
local dataClass = "/Script/PBZCombatAsset.PBZ_DamageBulletDataBase"
local function name(value) return {ToString=function() return value end} end
local function tag(value) return {TagName=name(value)} end
local function param(value) return {get=function() return value end} end
local function obj(class, path, fields)
    local o = fields or {}
    o.path = path
    function o:IsValid() return true end
    function o:IsA(wanted) return class == wanted end
    function o:GetFullName() return self.path end
    function o:GetOuter() return self.outer end
    function o:GetClass()
        return {GetFName=function() return name(class:match("([^.]+)$")) end, GetFullName=function() return self.path end}
    end
    return o
end
local player = obj("/Script/Engine.Pawn", "Soul")
local enemy = obj("/Script/Engine.Pawn", "MaleThug")
local ally = obj("/Script/Engine.Pawn", "Ally")
local hazard = obj("/Script/Engine.Actor", "Trap")
local controller = obj("/Script/Engine.Controller", "EnemyController", {Pawn=enemy})
enemy.Controller = controller
local factions = obj("FactionUtils", "CDO", {GetFactionRelation=function(_, p, a)
    assert(p == player)
    return a == enemy and 2 or 0
end})
local loaded, registrationWorks, savedHook, registrations = false, false, nil, 0
function StaticFindObject(path)
    if path == hookPath then return loaded and obj("Function", path) or nil end
    assert(path == namespace .. "Default__FactionUtils")
    return factions
end
function RegisterHook(path, callback, ...)
    assert(path == hookPath and select("#", ...) == 0)
    registrations = registrations + 1
    if not registrationWorks then error("not loaded") end
    savedHook = callback
    return 5, 5
end
local observed, logs = {}, {}
local game = {getPlayer=function() return player end, same=function(a,b) return a ~= nil and a == b end}
local function install()
    return receipt.install(game, function(pawn, accepted, reason, value)
        assert(pawn == player and (accepted == nil or type(accepted) == "boolean"))
        assert(type(reason) == "string" and type(value) == "number")
        observed[#observed+1] = {accepted=accepted, reason=reason, value=value}
    end, function(line) logs[#logs+1] = line end)
end
assert(not install() and registrations == 0)
loaded = true
assert(not install() and registrations == 1)
registrationWorks = true
assert(install() and install() and registrations == 2)

local data = obj(dataClass, "/PBZCombatAsset/Common/BulletData/BD_Sword", {
    DamageCause=tag("None"), SkillType=tag("None"), AttackType=tag("None")
})
local ability = obj("GameplayAbility", "/PBZCombatAsset/ActorData/Mobs/Sword/GA_HeavyAttack")
local bullet = obj(namespace .. "BulletObjectBase", "BulletObject_3", {
    BulletSourceAbility=ability, BulletOwnerAvatar=enemy, BulletData=data
})
local module = obj(namespace .. "BulletAttackModule", "BulletAttackModule_3", {Bullet=bullet, BulletData=data})
local effect = obj(namespace .. "DamageSource_GameplayEffect", "DamageSource_GameplayEffect_36", {
    AttackType=tag("AttackType.Energy"), SourceAbility=ability, SourceAvatar=enemy
})
local attributes = obj("DamageTakenPayload", "DamageTakenPayload_3", {
    DamageSource=data, DamageCause=tag("None"), TargetActor=player, owner=enemy,
    GetDamageSourceOwner=function(self) return self.owner end,
    GetDamageData=function(self) return self.channels end
})
local function channels(values)
    local m = {}
    for key,value in pairs(values) do m[param(tag("Damage.Damage." .. key))] = param(value) end
    attributes.channels = m
end
local currentAvatar = player
local context = param({GetAvatarActorFromActorInfo=function() return currentAvatar end})
local event = param({OptionalObject=attributes})
local function hit(accepted, amount)
    local count = #observed
    savedHook(context, event)
    local result = observed[#observed]
    assert(#observed == count+1 and result.accepted == accepted and result.value == amount,
        "expected " .. tostring(accepted) .. " at " .. tostring(amount) .. ", got " .. tostring(result and result.reason))
    return result
end
channels({["Target.GeneralDamage.Physical"]=8.5, ["Target.GeneralDamage.Fire"]=3,
          ["Target.AngerDamage.Normal"]=20, ["Target.PoiseDamage"]=14, ["Attacker.GeneralDamage.Fire"]=7})
currentAvatar = enemy
savedHook(context, event)
assert(#observed == 0, "nonlocal ability callback leaked into the player's flow")
currentAvatar = player
hit(true, 11.5)
attributes.TargetActor = enemy
assert(hit(false, 0).reason == "wrong_target")
attributes.TargetActor = player
for _, source in ipairs({bullet, module, effect, obj("InstancedDamageSource", "BD_Sword:DamageSource_0", {outer=data})}) do
    attributes.DamageSource = source
    hit(true, 11.5)
end
attributes.DamageSource = bullet
attributes.owner = nil
hit(true, 11.5) -- direct live bullet owner, no cached source
attributes.owner = controller
hit(true, 11.5)
attributes.owner = enemy
bullet.BulletOwnerAvatar = player
hit(nil, 11.5)
bullet.BulletOwnerAvatar = enemy
attributes.DamageSource = data
for _, owner in ipairs({player, ally, hazard}) do attributes.owner = owner; hit(false, 11.5) end
attributes.owner = nil
hit(nil, 11.5)
attributes.owner = enemy
for _, source in ipairs({hazard, obj(namespace .. "DamageSource_GameplayEffect", "GE_Kill_0")}) do
    attributes.DamageSource = source
    hit(false, 11.5)
end
attributes.DamageSource = obj("ScriptObject", "UnidentifiedEffect")
hit(nil, 11.5)
attributes.DamageSource = data
for _, path in ipairs({"/BulletData/ExE/BD_X", "BD_Vessel_GEx_01", "BD_FallDamage", "BP_DeepRiver", "BD_Trap"}) do
    data.path = path
    hit(false, 11.5)
end
data.path = "BD_Sword"
local lethal = obj("DamageCalculator_PBZLethal", "Lethal")
data.CustomDamageCalculator = lethal
hit(false, 11.5)
data.CustomDamageCalculator = nil
module.DamageCalculator = lethal
attributes.DamageSource = module
hit(false, 11.5)
module.DamageCalculator = nil
for _, path in ipairs({"GA_GreatBladeMan_CA_01_Gex_Normal", "GA_SimpleExecution", "GA_Sword_GEd_ToNpc"}) do
    ability.path = path
    hit(false, 11.5)
end
ability.path = "GA_HeavyAttack"
attributes.DamageSource = effect
effect.AttackType = tag("None")
assert(hit(nil, 11.5).reason:find("attack=None", 1, true))
ability.path = "GA_Sword_GEd_ToNpc"
assert(hit(false, 11.5).reason:find("GA_Sword_GEd_ToNpc", 1, true))
ability.path = "GA_HeavyAttack"
effect.AttackType = tag("AttackType.Physical.Slash.Default")
effect.SourceAbility = nil
assert(hit(nil, 11.5).reason:find("ability=None", 1, true))
effect.SourceAbility = ability
hit(true, 11.5)
attributes.DamageSource = enemy
local function directAttack(values)
    attributes.GetAttackData = function()
        local m = {}
        for key, value in pairs(values) do m[param(tag("Damage.Attack.Target." .. key))] = param(value) end
        return m
    end
end
directAttack({PhysicalDamage=8})
hit(true, 11.5)
local function wrapped(kind, value)
    return {type=function() return kind end, Get=function() return value end, get=function() return value end}
end
effect.AttackType = tag("None")
effect.SourceAbility = wrapped("FWeakObjectPtr", ability)
attributes.DamageSource = wrapped("RemoteUnrealParam", effect)
attributes.owner = wrapped("FWeakObjectPtr", enemy)
local plainEvent = event
event = param({OptionalObject = wrapped("FWeakObjectPtr", attributes)})
hit(true, 11.5)
ability.path = "GA_Sword_GEd_ToNpc"
hit(false, 11.5)
ability.path = "GA_HeavyAttack"
attributes.DamageSource, event, effect.SourceAbility = enemy, plainEvent, ability
attributes.owner = ally
hit(nil, 11.5)
attributes.owner = enemy
for _, special in ipairs({"SuffocationDamage", "TrueDamage", "StatusDamage.Fire"}) do
    directAttack({PhysicalDamage=8,[special]=1})
    hit(false, 11.5)
end
directAttack({PoiseDamage=2})
hit(nil, 11.5)
attributes.DamageSource = effect
for _, cause in ipairs({"Damage.Cause.StatusInfliction.Ignite", "Damage.Cause.Deflect.Perfect",
                        "Damage.Cause.Accessory.Electrified", "UnknownDamage"}) do
    attributes.DamageCause = tag(cause)
    hit(false, 11.5)
end
attributes.DamageCause = tag("None")
for _, kind in ipairs({"Target.TrueDamage", "Target.AngerDamage.Suffocation"}) do
    channels({[kind]=5, ["Target.GeneralDamage.Physical"]=3})
    hit(false, 3)
end
channels({["Target.PoiseDamage"]=94, ["Target.AngerDamage.Normal"]=200, ["Attacker.GeneralDamage.Fire"]=9})
hit(false, 0)
channels({["Target.GeneralDamage.Physical"]=0/0})
hit(false, 0)
local oldEvent = event
event = param({OptionalObject=hazard})
assert(hit(false, 0).reason == "wrong_payload")
event = oldEvent
attributes.GetDamageData = function() error("bad map") end
assert(hit(nil, 0).reason == "unreadable_receipt")
hit(nil, 0)
assert(#logs == 1, "repeated bridge failures spammed the log")
print("OnTaken receipt passed: local target, hostile source, typed health channels, executions, environmental causes and registration retries")
