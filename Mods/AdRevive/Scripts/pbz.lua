-- PBZ game-thread bindings. Health_Min is consumed by the game's damage calculation.
-- Writing Health=0 alone does not perform PBZ's normal death/respawn transition.
local pbz = {}
local controller
local killPath = "/Game/PBZContent/Blueprint/Ability/GameplayEffects/GE_Kill"
local healthPath = "/PBZCombatAsset/Config/AttributesModifyEffect/GE_MA_Health_1_Override"
local staticsPath = "/Script/Engine.Default__GameplayStatics"
local attributesPath = "/Script/SGameAttributes.Default__AttributeUtils"
local abilitiesPath = "/Script/GameplayAbilities.Default__AbilitySystemBlueprintLibrary"

local function valid(object)
    return object ~= nil and object:IsValid()
end

local function finite(number)
    return type(number) == "number" and math.abs(number) < math.huge
end

local function close(a, b)
    return finite(a) and finite(b) and math.abs(a - b) <= math.max(1e-7, math.abs(b) * 1e-6)
end

local function action(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then return false, tostring(err) end
    return true
end

local function lookup(path)
    local obj = StaticFindObject(path)
    assert(valid(obj), "missing game object: " .. path)
    return obj
end

local function asset(package, suffix)
    local path = package .. "." .. suffix
    local obj = StaticFindObject(path)
    if valid(obj) then return obj end
    -- The asset registry indexes the blueprint asset, not its generated _C class.
    local objectPath = package .. "." .. package:match("([^/]+)$")
    LoadAsset(objectPath)
    obj = StaticFindObject(path)
    if valid(obj) then return obj end
    LoadAsset(package)
    return lookup(path)
end

function pbz.same(a, b)
    local ok, same = pcall(function()
        return valid(a) and valid(b) and a:GetAddress() == b:GetAddress()
    end)
    return ok and same == true
end

local function possessedPawn(candidate)
    if valid(candidate) and candidate:IsLocalPlayerController() then
        local pawn = candidate.Pawn
        if valid(pawn) and pbz.same(pawn.Controller, candidate)
                and pawn:IsA("/Script/ProjectPBZ.PBZCharacter") then return pawn end
    end
end

local function findPlayer()
    local ok, pawn = pcall(possessedPawn, controller)
    if ok and pawn then return pawn end
    controller = nil
    -- Include controller blueprint subclasses. A stale entry during world travel
    -- must not prevent checking the next local controller.
    local reason = "no possessed local PBZ character"
    for _, candidate in ipairs(FindAllOf("PlayerController") or {}) do
        ok, pawn = pcall(possessedPawn, candidate)
        if ok and pawn then
            controller = candidate
            return pawn
        end
        if not ok then reason = tostring(pawn) end
    end
    return nil, reason
end

function pbz.getPlayer()
    local ok, result, why = pcall(findPlayer)
    if ok then return result, why end
    controller = nil
    return nil, tostring(result)
end

pbz.onGround = require("grounded")

local timeLibrary
function pbz.now(pawn)
    if not valid(timeLibrary) then timeLibrary = lookup(staticsPath) end
    return timeLibrary:GetUnpausedTimeSeconds(pawn)
end

local function ownedSet(pawn)
    assert(valid(pawn), "invalid player")
    local set = pawn.AttributeSetBase
    assert(valid(set), "missing AttributeSetBase")
    local outer = set
    for _ = 1, 8 do
        if pbz.same(outer, pawn) then return set end
        outer = outer:GetOuter()
        if not valid(outer) then break end
    end
    -- GAS may own a player's attributes on the PlayerState. The pawn must be
    -- the current avatar and this exact set must be registered with its ASC.
    local asc = pawn.AbilitySystemComponent
    if valid(asc) and pbz.same(asc.AvatarActor, pawn) then
        local found = false
        asc.SpawnedAttributes:ForEach(function(_, entry)
            if pbz.same(entry:get(), set) then found = true end
        end)
        if found then return set end
    end
    error("player does not own AttributeSetBase", 0)
end

local function sample(pawn)
    local set = ownedSet(pawn)
    local hp = set.Health.CurrentValue
    local max = set.Health_Max.CurrentValue
    local floor = set.Health_Min
    assert(finite(hp) and finite(max) and max > 0, "unavailable player health")
    assert(finite(floor.CurrentValue) and finite(floor.BaseValue), "unavailable Health_Min")
    return hp, max, floor.CurrentValue, floor.BaseValue
end

function pbz.sample(pawn)
    local ok, hp, max, floor, base = pcall(sample, pawn)
    if not ok then return nil, tostring(hp) end
    return hp, max, floor, base
end

local function changeFloor(pawn, value)
    local set = ownedSet(pawn)
    local previousBase = set.Health_Min.BaseValue
    local previousCurrent = set.Health_Min.CurrentValue
    assert(finite(value) and close(previousBase, previousCurrent), "Health_Min has another modifier")
    if value > 0 then assert(previousBase == 0 and previousCurrent == 0, "Health_Min already in use") end
    local ok, why = pcall(function()
        local floor = set.Health_Min
        floor.BaseValue = value
        floor.CurrentValue = value
        assert(close(set.Health_Min.BaseValue, value) and close(set.Health_Min.CurrentValue, value),
               "Health_Min readback differs")
    end)
    if not ok then
        -- Both fields used to agree. Undo any half-completed write.
        local floor = set.Health_Min
        floor.BaseValue = previousBase
        floor.CurrentValue = previousCurrent
        error(why, 0)
    end
end

function pbz.setFloor(pawn, value)
    return action(changeFloor, pawn, value)
end

function pbz.clearFloor(pawn, marker)
    return action(function()
        local floor = ownedSet(pawn).Health_Min
        local base, current = floor.BaseValue, floor.CurrentValue
        assert(finite(base) and finite(current), "unavailable Health_Min")
        -- GAS can restore either field independently between game-thread callbacks.
        -- Only undo fields still carrying our exact float. If a different base
        -- is active, it is the floor to restore when our current value is stale.
        if base == marker then floor.BaseValue = 0 end
        if floor.CurrentValue == marker then floor.CurrentValue = floor.BaseValue end
        assert(floor.BaseValue ~= marker and floor.CurrentValue ~= marker, "Health_Min cleanup readback differs")
    end)
end

-- This PBZ data asset holds the game's actual FGameplayAttribute descriptor.
-- Passing it to AttributeUtils lets GAS notify the HUD as it does for in-game healing.
local function healthBinding(pawn)
    local set = ownedSet(pawn)
    local effect = asset(healthPath, "GE_MA_Health_1_Override")
    local modifiers = effect.Modifiers
    assert(#modifiers == 1, "unexpected Health modifier list")
    local first = modifiers[1]
    if type(first) == "userdata" then
        local kind = first:type()
        if kind == "RemoteUnrealParam" or kind == "LocalUnrealParam" then first = first:get() end
    end
    local attr = first.Attribute
    local abilities = lookup(abilitiesPath)
    local descriptorValid = lookup("/Script/GameplayAbilities.AbilitySystemBlueprintLibrary:IsValid")
    assert(descriptorValid(abilities, attr), "invalid Health descriptor")
    local label = abilities:GetDebugStringFromGameplayAttribute(attr)
    if type(label) ~= "string" then label = label:ToString() end
    assert(label:match("([^.:/ ]+)$") == "Health", "wrong Health descriptor: " .. label)
    local utils = lookup(attributesPath)
    assert(close(utils:GetCharacterAttributeValue(pawn, attr), set.Health.CurrentValue), "Health readback differs")
    return utils, attr, set
end

local function abilitySystem(pawn)
    local asc = lookup(abilitiesPath):GetAbilitySystemComponent(pawn)
    assert(valid(asc) and (pbz.same(asc:GetOwner(), pawn) or pbz.same(asc.AvatarActor, pawn)),
           "ability system does not belong to this player")
    return asc
end

function pbz.offerContext(pawn)
    return {controller = pawn.Controller, world = pawn:GetWorld(), origin = pbz.position(pawn)}
end

function pbz.position(pawn)
    local ok, point = pcall(function() return pawn:K2_GetActorLocation() end)
    if ok and point and finite(point.X) and finite(point.Y) and finite(point.Z) then
        return {x = point.X, y = point.Y, z = point.Z}
    end
end

function pbz.ownsOffer(context, pawn)
    return pbz.same(context.controller, pawn.Controller) and pbz.same(context.world, pawn:GetWorld())
end

local hatredPath="/SGameAI/Tools/Hatred/BP_SGameHatredManagerComponent.BP_SGameHatredManagerComponent_C"
local unwrap=require("ueobject")

function pbz.fightingEnemies(pawn, attacker)
    local opponents,seen={},{}
    local world=pawn:GetWorld()
    local faction=StaticFindObject("/Script/SGameCombatSystem.Default__FactionUtils")
    local function include(actor)
        actor=unwrap(actor)
        if not valid(actor) then return end
        if actor:IsA("/Script/Engine.Controller") then actor=unwrap(actor.Pawn) end
        if not valid(actor) or pbz.same(actor,pawn) or not pbz.same(actor:GetWorld(),world)
                or not actor:IsA("/Script/Engine.Pawn") or seen[actor:GetAddress()] then return end
        if not valid(faction) or faction:GetFactionRelation(pawn,actor)~=2 then return end
        local hp=actor.AttributeSetBase
        if not valid(hp) or hp.Health.CurrentValue<=0 then return end
        seen[actor:GetAddress()]=true
        opponents[#opponents+1]=actor
    end
    pcall(include,attacker)
    local ok,found=pcall(function()
        local manager=pawn:GetComponentByClass(lookup(hatredPath))
        if not valid(manager) then return false end
        local list=manager.BeHatredList
        if not list then return false end
        for i=1,#list do pcall(include,list[i]) end
        return #list>0
    end)
    -- Some encounters clear the reciprocal list during the lethal hit.
    -- Check each NPC's own hatred for the local player in that case.
    if not ok or not found then
        pcall(function()
            local targets=lookup("/Script/PBZAbilityTargetRuntime.Default__PBZPlayerAbilityTargetLibrary")
            local actors={}
            lookup(staticsPath):GetAllActorsOfClass(pawn,lookup("/Script/ProjectPBZ.PBZCharacter_NPC"),actors)
            for _,entry in ipairs(actors) do
                pcall(function()
                    local actor=unwrap(entry)
                    if valid(actor) and targets:IsPlayerInCasterHatredList(actor) then include(actor) end
                end)
            end
        end)
    end
    return opponents
end

function pbz.healFightingEnemies(pawn,context,opponents,log)
    if not pbz.same(pawn,pbz.getPlayer()) or not pbz.ownsOffer(context,pawn) then return end
    local restore=StaticFindObject("/Script/ProjectPBZ.Default__PBZRestoreQueryLibrary")
    local faction=lookup("/Script/SGameCombatSystem.Default__FactionUtils")
    local healed,full=0,0
    for _,enemy in ipairs(opponents) do
        local ok,why=pcall(function()
            if not valid(enemy) or pbz.same(enemy,pawn) or not pbz.same(enemy:GetWorld(),context.world)
                    or faction:GetFactionRelation(pawn,enemy)~=2 or enemy:IsActorBeingDestroyed() then return end
            local stats=enemy.AttributeSetBase
            if not valid(stats) then return end
            local hp,max=stats.Health.CurrentValue,stats.Health_Max.CurrentValue
            if not finite(hp) or not finite(max) or hp<=0 or max<=0 then return end
            if hp>=max then full=full+1;return end
            local asc=enemy.AbilitySystemComponent
            if valid(asc) and asc:HasMatchingGameplayTag({TagName=FName("CharacterState.Dead")}) then return end
            if valid(restore) then pcall(function() restore:ResetHealthToMax(enemy) end) end
            if not close(stats.Health.CurrentValue,max) then
                local fixed,err=pbz.setHealth(enemy,max)
                if not fixed then error(err) end
            end
            healed=healed+1
            log(string.format("VIP healed %s, HP=%.2f -> %.2f",enemy:GetFullName(),hp,stats.Health.CurrentValue))
        end)
        if not ok then log("VIP enemy heal failed: "..tostring(why)) end
    end
    log(string.format("VIP encounter: captured=%d, healed=%d, already full=%d",#opponents,healed,full))
end

-- Sample the actual attacker bound to this offer. Phase tags are optional
-- evidence: some encounters store their phase only in a quest or AI graph.
function pbz.encounterSample(enemy, when)
    local ok, detail = pcall(function()
        assert(valid(enemy), "actor expired")
        local hp = enemy.AttributeSetBase
        local tagsOk, tags = pcall(function()
            local lib = lookup("/Script/GameplayTags.Default__BlueprintGameplayTagLibrary")
            local owned = lib:GetOwnedGameplayTags(enemy.AbilitySystemComponent)
            local names = lib:GetDebugStringFromGameplayTagContainer(owned)
            if type(names) ~= "string" then names = names:ToString() end
            local phase = {}
            for name in names:gmatch("[%w_.]+") do
                local key = name:lower()
                if key:find("phase", 1, true) or key:find("stage", 1, true) then phase[#phase + 1] = name end
            end
            table.sort(phase)
            return #phase > 0 and table.concat(phase, ",") or "unreported"
        end)
        return string.format("%s, HP=%s/%s, phase tags=%s", enemy:GetFullName(),
            tostring(hp.Health.CurrentValue), tostring(hp.Health_Max.CurrentValue), tagsOk and tags or "unavailable")
    end)
    return "encounter attacker " .. when .. ": " .. tostring(detail)
end

local poseNames = {AM_Hun_Dead_F = true, AM_Hun_Dead_B = true}
local poseMontages = {}
local poseLookupStarted = false

local function rememberMontage(obj)
    if not valid(obj) then return end
    local name = obj:GetFName():ToString()
    if poseNames[name] then poseMontages[name] = obj end
end

local function prepareMontages()
    if poseLookupStarted then return end
    poseLookupStarted = true
    -- Snapshot the loaded class once before combat. The observer fills gaps
    -- when levels stream in and replaces references to reloaded animations.
    -- Neither a missing animation nor a stale one should delay the overlay.
    pcall(NotifyOnNewObject, "/Script/Engine.AnimMontage", rememberMontage)
    for _, obj in ipairs(FindAllOf("AnimMontage") or {}) do rememberMontage(obj) end
    -- Prepare the two possible defeat poses before arming the HP floor.
    if valid(poseMontages.AM_Hun_Dead_F) then return end
    local helpers = lookup("/Script/AssetRegistry.Default__AssetRegistryHelpers")
    local registry = helpers:GetAssetRegistry()
    assert(valid(registry), "animation registry unavailable")
    local assets = {}
    registry:GetAssetsByClass({PackageName = FName("/Script/Engine"), AssetName = FName("AnimMontage")}, assets, true)
    for _, entry in ipairs(assets) do
        local name = entry.AssetName
        if type(name) ~= "string" then name = name:ToString() end
        if poseNames[name] and not valid(poseMontages[name]) then
            rememberMontage(helpers:GetAsset(entry))
        end
    end
end

function pbz.prepare(pawn, log)
    return action(function()
        sample(pawn)
        asset(killPath, "GE_Kill_C")
        abilitySystem(pawn)
        local paused, why = pbz.paused(pawn)
        assert(type(paused) == "boolean", why or "pause state unavailable")
        pcall(prepareMontages)
    end)
end

function pbz.setHealth(pawn, value)
    return action(function()
        local utils, attr, set = healthBinding(pawn)
        assert(finite(value) and value > 0 and value <= set.Health_Max.CurrentValue, "invalid heal target")
        utils:ModifyCharacterAttributeValue(pawn, attr, 3, value) -- EGameplayModOp::Override
        assert(close(set.Health.CurrentValue, value), "heal readback differs")
    end)
end

function pbz.die(pawn, nativeHandoff, pendingDeath)
    return action(function()
        local hp, _, floor = sample(pawn)
        if hp <= 0 and not pendingDeath and (not nativeHandoff or abilitySystem(pawn):HasMatchingGameplayTag({TagName=FName("CharacterState.Dead")})) then return end
        assert(floor <= 0 or nativeHandoff, "release Health_Min before applying GE_Kill")
        local effect = asset(killPath, "GE_Kill_C")
        local asc = abilitySystem(pawn)
        asc:BP_ApplyGameplayEffectToSelf(effect, 1.0, {})
    end)
end

local function pauseState(pawn)
    assert(valid(pawn), "invalid pause context")
    local statics = lookup(staticsPath)
    local queried, value = pcall(function() return statics:IsGamePaused(pawn) end)
    if queried and type(value) == "boolean" then return value end
    local settings = pawn:GetWorld():K2_GetWorldSettings()
    assert(valid(settings), "world settings unavailable for pause check")
    return valid(settings.PauserPlayerState)
end

function pbz.paused(pawn)
    local ok, state = pcall(pauseState, pawn)
    if not ok then return nil, tostring(state) end
    return state
end

function pbz.pause(pawn, value)
    return action(function()
        assert(valid(pawn) and type(value) == "boolean", "invalid pause request")
        local statics = lookup(staticsPath)
        if pauseState(pawn) ~= value then
            statics:SetGamePaused(pawn, value)
            assert(pauseState(pawn) == value, "game rejected pause change")
        end
    end)
end

-- These are the player's visual montages. Avoid activating PBZ's death ability while
-- the offer is open. The real gameplay effect is reserved for pbz.die.
local function playerAnim(pawn)
    assert(valid(pawn) and valid(pawn.Mesh), "player mesh unavailable")
    local anim = pawn.Mesh:GetAnimInstance()
    assert(valid(anim), "player animation instance unavailable")
    return anim
end

function pbz.bindPose(pawn)
    local ok, binding = pcall(function()
        local down = poseMontages.AM_Hun_Dead_F
        if not valid(down) then down = poseMontages.AM_Hun_Dead_B end
        assert(valid(down), "Soul's defeat montage is not loaded")
        return {pawn = pawn, down = down}
    end)
    if not ok then return nil, tostring(binding) end
    return binding
end

function pbz.playDefeat(pawn, binding)
    if not binding then
        local why
        binding, why = pbz.bindPose(pawn)
        if not binding then return nil, why end
    end
    local ok, pose = pcall(function()
        assert(pbz.same(pawn, binding.pawn) and valid(binding.down), "player pose binding expired")
        local anim = playerAnim(pawn)
        local down = binding.down
        assert(not anim:Montage_IsActive(down), "a defeat montage is already running")
        local length = down:GetPlayLength()
        assert(finite(length) and length > 0, "invalid defeat montage length")
        local at = math.max(length * 0.5, length - math.max(0.18, length * 0.17))
        local result = anim:Montage_Play(down, 1.0, 0, 0.0, false)
        assert(finite(result) and result > 0, "defeat montage was rejected")
        return {pawn = pawn, anim = anim, down = down,
                holdAt = at}
    end)
    if not ok then return nil, tostring(pose) end
    return pose
end

local function poseAnim(pawn, pose)
    assert(pose and pbz.same(pawn, pose.pawn), "different player owns the pose")
    local anim = playerAnim(pawn)
    assert(pbz.same(anim, pose.anim), "player animation instance changed")
    return anim
end

function pbz.holdPose(pawn, pose)
    return action(function()
        local anim = poseAnim(pawn, pose)
        assert(valid(pose.down) and anim:Montage_IsActive(pose.down), "defeat montage was interrupted")
        anim:Montage_SetPosition(pose.down, pose.holdAt)
        anim:Montage_Pause(pose.down)
    end)
end

function pbz.cleanupPose(pawn, pose)
    if not pose then return true end
    return action(function()
        local anim = poseAnim(pawn, pose)
        if valid(pose.down) and anim:Montage_IsActive(pose.down) then
            anim:Montage_Stop(0.15, pose.down)
        end
    end)
end

return pbz
