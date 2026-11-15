-- OnTaken is the player passive's synchronous, resolved damage receipt. All
-- evidence below belongs to this payload, including the source owner.
local M = {}
local passive = "/PBZCombatAsset/Prototypes/Abilities/GA_CommonUtilitiesPassive.GA_CommonUtilitiesPassive_C:OnTaken"
local dataClass = "/Script/PBZCombatAsset.PBZ_DamageBulletDataBase"
local combat = "/Script/SGameCombatSystem."
local general = "Damage.Damage.Target.GeneralDamage."
local installed, factionLibrary
local unwrap = require("ueobject")

local function valid(obj)
    return obj ~= nil and obj:IsValid()
end

local function special(text)
    local s = text:lower()
    for _, word in ipairs({"execut", "simpleexe", "instakill", "instantkill", "instantdeath",
            "assassin", "suicide", "lethal", "fatal", "killzone", "killz", "ge_kill",
            "outofbounds", "falldamage", "fallingdamage", "falldeath", "deepwater", "deepriver",
            "suffocat", "drown", "trap", "scripted", "cinematic"}) do
        if s:find(word, 1, true) then return true end
    end
    -- PBZ also names execution/grab moves GEx and GEd (attacker and victim).
    return s:match("%f[%w]gex%f[%W]") or s:match("%f[%w]ged%f[%W]") or s:match("%f[%w]exe%f[%W]")
end

local function directCause(cause)
    -- In this build ordinary strikes usually have no override. Named status,
    -- accessory and deflect causes are separate damage events.
    return cause == "None"
end

local function damageAmount(payload)
    local amount, excluded = 0, nil
    -- PBZ UE4SS exposes each TMap pair as two RemoteUnrealParams.
    for tag, entry in pairs(payload:GetDamageData()) do
        local name, v = tag:get().TagName:ToString(), entry:get()
        if type(v) ~= "number" or not (math.abs(v) < math.huge) then return 0, "invalid_amount" end
        if v > 0 then
            if name:sub(1, #general) == general then amount = amount + v
            elseif name == "Damage.Damage.Target.TrueDamage" or name == "Damage.Damage.Target.AngerDamage.Suffocation" then
                excluded = name
            end
        end
    end
    if not (amount < math.huge) then return 0, "invalid_amount" end
    return amount, excluded
end

local function normalCalculator(obj)
    obj = unwrap(obj)
    if not valid(obj) then return true end
    local class = obj:GetClass():GetFName():ToString()
    return class == "DamageCalculator_PBZNormal" or class == "DamageCalculator_PBZPlayerScaled"
end

local function ordinaryData(data)
    data = unwrap(data)
    if not valid(data) or not data:IsA(dataClass) then return nil end
    if special(data:GetFullName()) or special(data.AttackType.TagName:ToString())
        or special(data.SkillType.TagName:ToString()) or not normalCalculator(data.CustomDamageCalculator) then return false end
    return directCause(data.DamageCause.TagName:ToString())
end

local function ordinaryAbility(ability)
    return valid(ability) and not special(ability:GetClass():GetFullName())
end

local directAttack = {
    ["Damage.Attack.Target.PhysicalDamage"]=true, ["Damage.Attack.Target.PhysicalDamage.Sharp"]=true,
    ["Damage.Attack.Target.PhysicalDamage.Blunt"]=true, ["Damage.Attack.Target.ElementDamage"]=true,
    ["Damage.Attack.Target.AquaDamage"]=true, ["Damage.Attack.Target.BloodDamage"]=true,
    ["Damage.Attack.Target.ChaosDamage"]=true, ["Damage.Attack.Target.FireDamage"]=true,
    ["Damage.Attack.Target.IceDamage"]=true, ["Damage.Attack.Target.LightningDamage"]=true,
    ["Damage.Attack.Target.ToxinDamage"]=true
}
local function isDirectStrike(payload)
    local hit = false
    for key, entry in pairs(payload:GetAttackData()) do
        local tag, value = key:get().TagName:ToString(), entry:get()
        if type(value) ~= "number" or not (math.abs(value) < math.huge) then return nil end
        if value > 0 then
            if tag == "Damage.Attack.Target.TrueDamage" or tag == "Damage.Attack.Target.SuffocationDamage"
                or tag:match("^Damage%.Attack%.Target%.StatusDamage%.") then return false end
            if directAttack[tag] then hit = true end
        end
    end
    if hit then return true end
end

local function checkSource(source, payload)
    -- nil means insufficient evidence. It cannot start an offer, but it also
    -- cannot overturn an earlier, independently verified lethal hit.
    if not valid(source) then return nil, "missing_source" end
    local sourceName = source:GetFullName()
    if special(sourceName) then return false, "special_source/" .. sourceName end
    if source:IsA(dataClass) then return ordinaryData(source), "bullet_data" end
    if source:IsA("/Script/Engine.Pawn") then
        -- A pawn by itself does not distinguish a weapon attack from a status
        -- tick. Require this payload's direct attack input and resolved HP channel.
        return isDirectStrike(payload), "direct_pawn", source
    end
    if source:IsA(combat .. "BulletAttackModule") then
        if not normalCalculator(source.DamageCalculator) then return false, "custom_calculator" end
        local known = ordinaryData(source.BulletData)
        if known == nil then return nil, "missing_bullet_data" end
        if not known then return false, "special_bullet_data" end
        source = unwrap(source.Bullet)
        if not valid(source) then return nil, "missing_bullet" end
        if special(source:GetFullName()) then return false, "special_bullet" end
    end
    if source:IsA(combat .. "BulletObjectBase") or source:IsA(combat .. "BulletActorBase") then
        local ability = unwrap(source.BulletSourceAbility)
        if valid(ability) and not ordinaryAbility(ability) then return false, "special_ability" end
        return ordinaryData(source.BulletData), "bullet", source.BulletOwnerAvatar
    end
    if source:IsA(combat .. "DamageSource_GameplayEffect") then
        local attack = source.AttackType.TagName:ToString()
        local ability = unwrap(source.SourceAbility)
        local abilityClass = valid(ability) and ability:GetClass():GetFullName() or "None"
        local detail = "attack=" .. attack .. ", ability=" .. abilityClass
        if special(attack) or special(abilityClass) then return false, "special ability: " .. detail end
        local typed = attack == "AttackType.Physical" or attack == "AttackType.Energy"
            or attack:match("^AttackType%.Physical%.") or attack:match("^AttackType%.Energy%.")
        if attack == "None" and valid(ability) and payload.GetAttackData then
            typed = isDirectStrike(payload)
        end
        if not typed or not valid(ability) then return nil, "unclassified ability_damage: " .. detail end
        return true, "ability_damage", source.SourceAvatar
    end
    -- Some PBZ attacks carry an instanced damage source whose outer is the
    -- originating bullet data asset. Its calculator and name are still inspectable.
    local outer = unwrap(source:GetOuter())
    if valid(outer) and outer:IsA(dataClass) then return ordinaryData(outer), "bullet_data_outer" end
    return nil, "unrecognized_source/" .. source:GetClass():GetFName():ToString()
end

local function asPawn(g, actor)
    if not valid(actor) then return nil end
    if actor:IsA("/Script/Engine.Pawn") then return actor end
    if actor:IsA("/Script/Engine.Controller") then
        local pawn = unwrap(actor.Pawn)
        if valid(pawn) and g.same(pawn.Controller, actor) then return pawn end
    end
end

local function hostile(pawn, attacker)
    if not valid(factionLibrary) then factionLibrary = StaticFindObject(combat .. "Default__FactionUtils") end
    if valid(factionLibrary) then return factionLibrary:GetFactionRelation(pawn, attacker) == 2 end
    local factionClass = StaticFindObject(combat .. "FactionComponent")
    if not valid(factionClass) then return false end
    local faction = pawn:GetComponentByClass(factionClass)
    return valid(faction) and faction:GetFactionRelation(attacker) == 2
end

local function classify(g, pawn, event)
    local payload = unwrap(event:get().OptionalObject)
    if not valid(payload) or payload:GetClass():GetFName():ToString() ~= "DamageTakenPayload" then
        return false, "wrong_payload", 0
    end
    if not g.same(pawn, unwrap(payload.TargetActor)) then return false, "wrong_target", 0 end
    local amount, excluded = damageAmount(payload)
    if excluded then return false, excluded, amount end
    if amount <= 0 then return false, "no_health_damage", amount end
    local cause = payload.DamageCause.TagName:ToString()
    if not directCause(cause) then return false, "damage_cause/" .. cause, amount end
    local accepted, kind, bulletOwner = checkSource(unwrap(payload.DamageSource), payload)
    if not accepted then return accepted, kind, amount end
    local owner = unwrap(payload:GetDamageSourceOwner())
    bulletOwner = unwrap(bulletOwner)
    if valid(owner) and special(owner:GetFullName()) then return false, "special_source_owner", amount end
    local attacker = asPawn(g, valid(owner) and owner or bulletOwner)
    if not attacker then return nil, "missing_attacker", amount end
    if g.same(pawn, attacker) then return false, "self_attacker", amount end
    if valid(bulletOwner) and not g.same(attacker, asPawn(g, bulletOwner)) then return nil, "source_owner_mismatch", amount end
    if not hostile(pawn, attacker) then return false, "nonhostile_source", amount end
    return true, kind, amount, attacker
end

function M.install(g, callback, log)
    if installed then return true end
    local found, fn = pcall(StaticFindObject, passive)
    if not found or not valid(fn) then return false end
    local reported = {}
    local function report(key, err)
        if not reported[key] then
            reported[key] = true
            log("OnTaken " .. key .. ": " .. tostring(err))
        end
    end
    local function onTaken(context, event)
        local ok, pawn = pcall(function()
            local avatar = context:get():GetAvatarActorFromActorInfo()
            local player = g.getPlayer()
            if g.same(avatar, player) then return player end
        end)
        if not ok then report("avatar", pawn); return end
        if not pawn then return end
        local read, allowed, reason, amount, attacker = pcall(classify, g, pawn, event)
        if not read then
            report("unreadable receipt", allowed)
            allowed, reason, amount = nil, "unreadable_receipt", 0
        end
        local handled, err = pcall(callback, pawn, allowed, reason, amount, attacker)
        if not handled then report("callback", err) end
    end
    -- UE4SS uses the first callback argument as its post hook on blueprint functions.
    local ok, id = pcall(RegisterHook, passive, onTaken)
    if ok and type(id) == "number" and id >= 0 then installed = true end
    return installed == true
end

function M.observeAttacker(g, callback, log)
    local fn=StaticFindObject(passive)
    if not valid(fn) then return false end
    local reported=false
    local ok,id=pcall(RegisterHook,passive,function(ctx,event)
        local read,why=pcall(function()
            local p=ctx:get():GetAvatarActorFromActorInfo()
            if not g.same(p,g.getPlayer()) then return end
            local payload=unwrap(event:get().OptionalObject)
            local enemy
            if valid(payload) and g.same(p,unwrap(payload.TargetActor)) then
                enemy=asPawn(g,unwrap(payload:GetDamageSourceOwner()))
            end
            callback(p,enemy)
        end)
        if not read and not reported then log("attacker telemetry: " .. tostring(why)); reported=true end
    end)
    return ok and type(id)=="number" and id>=0
end
return M
