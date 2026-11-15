local M = {}
local unwrap = require("ueobject")
local root = "/PBZCombatAsset/ActorData/Players/Hun/"
local weapon = root .. "Weapon/HeiMoShang/"
local art = root .. "Abilities/HeiMoShang/GA_Hun_HeiMoShang_Reborn"
local skillPath = art .. ".GA_Hun_HeiMoShang_Reborn_C"
local bladePath = weapon .. "BP_Weapon_Hun_HeiMoShang.BP_Weapon_Hun_HeiMoShang_C"
local passivePath = "/Script/PBZCombatAsset.GA_HeiMoShang_RebornPassive"
local readyTag = "CharacterState.Immortal.HeiMoShang"
local cooldownTag = "CharacterState.AbilityState.HeiMoShang.RebornCooldown"
local function effectPath(name) return weapon .. name .. "." .. name .. "_C" end
local amplification = effectPath("GE_HeiMoShang_RebornPhysicalAmplification")
-- The recovery GE belongs to the game's healing sequence, including later ticks.
local recovery = effectPath("GE_HeiMoShang_RebornRecovery")
local finishEffects = {
    [effectPath("GE_HeiMoShang_RebornLoseHealth")] = true,
    [effectPath("GE_HeiMoShang_Reborning")] = true,
    ["/Script/PBZCombatAsset.GE_HeiMoShang_RebornCooldown"] = true,
}
local function valid(o) return o and o:IsValid() end
local function same(a,b) return valid(a) and valid(b) and a:GetAddress() == b:GetAddress() end
local function hasTag(asc, key) return asc:HasMatchingGameplayTag({TagName=FName(key)}) end
local skill, passive, config, library, utils, bonus
local hooks = {}
local linkedEffects = {}
local function granted(asc, path, id, exclude, activeOnly)
    local items = asc.ActivatableAbilities.Items
    for i=1,#items do
        local spec = unwrap(items[i])
        local a = unwrap(spec.Ability)
        if valid(a) and a:IsA(path) and not spec.PendingRemove and spec.Handle.Handle ~= exclude
                and (not id or spec.Handle.Handle == id) and (not activeOnly or spec.ActiveCount>0) then return spec end
    end
end

local function blocksMedicine(asc, def)
    local flask = granted(asc, "/Game/PBZContent/Blueprint/Item/Ability/Medicine/GA_Medicine_Base.GA_Medicine_Base_C")
    if not flask then return false end
    local ability = unwrap(flask.Ability)
    local function matches(owned, blocked)
        local a, b = owned and owned.GameplayTags, blocked and blocked.GameplayTags
        for i=1,a and #a or 0 do
            local name = unwrap(a[i]).TagName:ToString()
            for j=1,b and #b or 0 do
                local key = unwrap(b[j]).TagName:ToString()
                if name == key or name:sub(1,#key+1) == key .. "." then return true end
            end
        end
        return false
    end
    if matches(library:GetGameplayEffectGrantedTags(def:GetClass()), ability.ActivationBlockedTags)
            or matches(ability.AbilityTags, def.InheritableBlockedAbilityTagsContainer.CombinedTags) then return true end
    for i=1,#def.GEComponents do
        local c=unwrap(def.GEComponents[i])
        if valid(c) and c:IsA("/Script/GameplayAbilities.BlockAbilityTagsGameplayEffectComponent")
                and matches(ability.AbilityTags,c.InheritableBlockedAbilityTagsContainer.CombinedTags) then return true end
    end
    return false
end

local function effects(asc)
    local result = {}
    local list = asc:GetActiveEffects({})
    for i=1,#list do
        local id = unwrap(list[i]).Handle
        local h = {Handle=id}
        local def = library:GetGameplayEffectFromActiveEffectHandle(h)
        if valid(def) then
            local path = def:GetClass():GetFullName():match("([^ ]+)$")
            local tracked = finishEffects[path] or path == amplification or path == recovery
            if not tracked and linkedEffects[path] then
                local ok, blocked=pcall(blocksMedicine,asc,def)
                tracked=ok and blocked
            end
            if tracked then
                result[id] = {path=path, stacks=library:GetActiveGameplayEffectStackCount(h), def=def}
            end
        end
    end
    return result
end
local function healingBlock(asc,def)
    local ok,result=pcall(blocksMedicine,asc,def)
    -- When a linked bonus cannot be inspected, remove its newly-added
    -- stacks too. The native recovery GE is explicitly outside this list.
    return not ok or result
end
local function strip(t, keepBonus)
    for id,e in pairs(effects(t.asc)) do
        local old = t.before[id]
        local added = e.stacks - (old and old.stacks or 0)
        if added > 0 and not (keepBonus and e.path==recovery) then
            if keepBonus and e.path == amplification and not t.bonusBlocksMedicine then
                bonus = {pawn=t.pawn, asc=t.asc, id=id, base=old and old.stacks or 0, added=added}
            else
                assert(t.asc:RemoveActiveGameplayEffect({Handle=id},added), "effect removal declined: " .. e.path)
                t.log("black blade removed " .. e.path .. ", handle=" .. id .. ", stacks=" .. added)
            end
        end
    end
end

local function releaseBonus()
    local old=bonus
    if old and valid(old.asc) then
        local h={Handle=old.id}
        local n=math.min(old.added,library:GetActiveGameplayEffectStackCount(h)-old.base)
        if n>0 then assert(old.asc:RemoveActiveGameplayEffect(h,n), "attack bonus removal declined") end
    end
    bonus=nil
end


local function tag(name) return {TagName=FName(name)} end
local dead, vanish = "CharacterState.Dead", "CharacterState.Vanish"
local function eligible(r)
    return r.state:InPendingState(tag(dead))
       and not r.state:InExactState(tag(dead))
       and not hasTag(r.asc, "CharacterState.Forbid.Resurrect")
       and not hasTag(r.asc, "CharacterState.Immortal.XuKongHuaShan")
       and r.state:CanActivateNewState(tag(vanish))
end
local configPath = weapon .. "Weapon_Hun_HeiMoShang.Weapon_Hun_HeiMoShang"
local function equipment(r)
    local data={}
    local read,current=pcall(function()
        r.weapons:GetCurrentWeapon(tag("Weapon.Slot.Main"),data,false,{})
        return unwrap(data.WeaponConfig)
    end)
    if read and valid(current) then return same(current,config),current:GetFName():ToString() end
    local names, held = {}, false
    local actors = r.pawn:GetCurrentWeapons()
    for i=1,#actors do
        local actor = unwrap(actors[i])
        if valid(actor) then
            names[#names+1] = actor:GetFName():ToString()
            if actor:IsA(bladePath) then held=true end
        end
    end
    if #names>0 then return held, table.concat(names,",") end
    return nil,"unavailable"
end
local function loadObjects()
    local k = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
    if not valid(skill) then
        skill = StaticFindObject(skillPath)
        if not valid(skill) then
            skill = k:LoadClassAsset_Blocking(k:Conv_SoftClassPathToSoftClassRef(k:MakeSoftClassPath(skillPath)))
        end
        assert(valid(skill),"native Reborn class unavailable")
        local refs=skill.HardReferencedAssets
        for i=1,refs and #refs or 0 do
            local ref=unwrap(refs[i])
            if valid(ref) and ref:IsA("/Script/CoreUObject.Class") then
                linkedEffects[ref:GetFullName():match("([^ ]+)$")]=true
            end
        end
    end
    if not valid(config) then
        config=StaticFindObject(configPath)
        if not valid(config) then
            config=k:LoadAsset_Blocking(k:Conv_SoftObjPathToSoftObjRef(k:MakeSoftObjectPath(configPath)))
        end
    end
    passive=StaticFindObject(passivePath)
    library=StaticFindObject("/Script/GameplayAbilities.Default__AbilitySystemBlueprintLibrary")
    utils=StaticFindObject("/Script/SGameUtils.Default__AbilityUtils")
    assert(valid(config) and valid(passive) and valid(library) and valid(utils),"native black blade assets unavailable")
end

-- Check eligibility while the pending state still exists. The Blueprint may
-- consume it inside ActivateAbility. A check alone never opens a window.
local gate
function M.prepare(r, flow)
    loadObjects()
    local callbacks = {}
    callbacks.K2_CanActivateAbility = function(_,info,handle)
        local a=info:get()
        if not same(unwrap(a.AvatarActor),r.pawn) or not same(unwrap(a.AbilitySystemComponent),r.asc) then return end
        if not same(r.pawn,flow.g.getPlayer()) then return end
        local id=handle:get().Handle
        -- Two ability specs can be visible during an equipment change.
        -- Once this death has a running action neither spec may start another.
        if flow.session then return false end
        if r.suppressed or not eligible(r) then
            r.candidate=nil
            if id==r.action or r.forceDeath then return false end
            return
        end
        local held,names=equipment(r)
        local original=granted(r.asc,passivePath,nil,r.passive,true)
        local natural=original and (held==true or (held==nil and id~=r.action and not r.passive))
            and M.ready(r) and not hasTag(r.asc,cooldownTag)
        releaseBonus()
        r.candidate={pawn=r.pawn,asc=r.asc,id=id,before=effects(r.asc),log=r.log,
            natural=natural==true,weapons=names,attemptTime=r.pawn:GetGameTimeSinceCreation()}
        -- Reborn can clear AI hatred before its ActivateAbility callback.
        -- Snapshot the current fight while the original death is still pending.
        local recent=r.attacker and r.candidate.attemptTime-r.hitTime<=0.25 and r.attacker or nil
        r.candidate.opponents=flow.g.fightingEnemies(r.pawn,recent)
        -- Observe the decision. The original Blueprint returns its own result.
    end
    callbacks.K2_ActivateAbility = function(ctx)
        local a=ctx:get()
        if not same(a:GetAvatarActorFromActorInfo(),r.pawn) or not same(a:GetAbilitySystemComponentFromActorInfo(),r.asc) then return end
        local t=r.candidate
        r.candidate=nil
        local id=utils:GetAbilityHandle(a).Handle
        if flow.session and same(flow.session.ability,a) then return end
        if not t or r.suppressed or flow.session or id~=t.id
                or r.pawn:GetGameTimeSinceCreation()~=t.attemptTime then
            r.log("native Reborn outside matched death check, spec=" .. tostring(id))
            if id==r.action and utils:IsAbilityActive(a) then a:K2_CancelAbility() end
            return
        end
        if M.committed(r) or hasTag(r.asc,"CharacterState.Forbid.Resurrect")
                or hasTag(r.asc,"CharacterState.Immortal.XuKongHuaShan") then return end
        t.ability=a
        flow:started(t)
    end
    callbacks.K2_OnEndAbility = function(ctx,cancelled)
        local t=flow.session
        if t and same(t.ability,ctx:get()) then
            t.ended=true
            t.cancelled=cancelled:get()==true
            r.log("native Reborn end, cancelled=" .. tostring(t.cancelled))
        end
    end
    for _,method in ipairs({"K2_CanActivateAbility","K2_ActivateAbility","K2_OnEndAbility"}) do
        if not hooks[method] then
            local path=skillPath .. ":" .. method
            assert(valid(StaticFindObject(path)), "missing " .. method)
            local id=RegisterHook(path,function(...)
                local current=gate
                if current then
                    local ok,result=pcall(current.callbacks[method],...)
                    if ok then return result end
                    current.flow:abort(result)
                end
            end)
            assert(type(id)=="number" and id>=0,"cannot observe " .. method)
            hooks[method]=true
        end
    end
    r.weapons=r.pawn:GetComponentByClass(StaticFindObject("/Script/SGameCombatSystem.CharacterWeaponsComponent"))
    r.state=r.pawn:GetComponentByClass(StaticFindObject("/Script/SGameActorState.ActorStateComponent"))
    if not valid(r.state) then r.state=r.pawn:GetActorStateComponent() end
    r.input=valid(r.weapons) and unwrap(r.weapons.AbilityInput)
    if not valid(r.input) then r.input=r.pawn:GetComponentByClass(StaticFindObject("/Script/SGameInputSystem.AbilityInputComponent")) end
    if not valid(r.input) then r.input=r.pawn:GetAbilityInputComponent() end
    assert(valid(r.state) and valid(r.weapons) and valid(r.input),"player combat components unavailable")
    gate={r=r,callbacks=callbacks,flow=flow}
    for _,method in ipairs({"SetCurrentWeapon","SetSlotWeapon","ForceSetNextWeapon","AutoSetCurrentWeapon"}) do
        local path="/Script/SGameCombatSystem.CharacterWeaponsComponent:" .. method
        if not hooks[path] and valid(StaticFindObject(path)) then
            local ok,id=pcall(RegisterHook,path,function() end,function(ctx)
                local current=gate
                if current and same(ctx:get(),current.r.weapons) then current.flow:weaponChanged() end
            end)
            hooks[path]=ok and type(id)=="number" and id>=0
        end
    end
end

local function clearGrant(r,key)
    local id=r[key]
    if not id then return end
    if valid(r.asc) then
        if key=="action" and valid(r.weapons) then r.weapons:UnregisterExternalWeaponAbility({Handle=id}) end
        if granted(r.asc,key=="action" and skillPath or passivePath,id) then r.asc:ClearAbility({Handle=id}) end
    end
    r[key]=nil
end
local function grant(r,key,class)
    local h=r.asc:K2_GiveAbility(class,1,-1)
    assert(h and type(h.Handle)=="number" and h.Handle>0,"cannot grant native " .. key)
    r[key]=h.Handle
    if key=="action" then r.weapons:RegisterExternalWeaponAbility({Handle=h.Handle},config) end
    return assert(granted(r.asc,key=="action" and skillPath or passivePath,h.Handle),"new spec missing")
end
function M.detach(r)
    if gate and gate.r==r then gate=nil end
    clearGrant(r,"passive")
    clearGrant(r,"action")
    if r.leasedReady and valid(r.asc) and valid(r.state) and M.cooling(r) then M.releaseReadiness(r) end
    releaseBonus()
end
function M.retire(r)
    r.suppressed=true
    r.candidate=nil
    clearGrant(r,"passive")
    clearGrant(r,"action")
end
function M.arm(r)
    if hasTag(r.asc,"CharacterState.Forbid.Resurrect") or hasTag(r.asc,"CharacterState.Immortal.XuKongHuaShan") then return end
    local held,names=equipment(r)
    local native=granted(r.asc,passivePath,nil,r.passive,true)
    local original=native and native.Handle.Handle
    local cooling=hasTag(r.asc,cooldownTag)
    local originalAction=granted(r.asc,skillPath,nil,r.action)
    local useOriginal=originalAction and (held==true or (held==nil and native))
    if useOriginal then clearGrant(r,"action")
    elseif not r.action or not granted(r.asc,skillPath,r.action) then grant(r,"action",skill) end
    local change=names~=r.weaponName or original~=r.nativePassive
    if native then
        local handoff=r.passive~=nil
        clearGrant(r,"passive")
        -- The original and borrowed tasks use the same actor state. Ending
        -- one task can release the other's state. Reconcile once per handoff,
        -- never every tick after a native execution has revoked readiness.
        local restore=handoff or (change and (r.weaponName~=nil or cooling)) or r.restoreSpent
        if restore
                and not M.ready(r) and not M.pending(r) and not M.committed(r) then
            r.state:TryActivateNewState(tag(readyTag))
            r.leasedReady=M.ready(r) and cooling
        end
    else
        local spec=r.passive and granted(r.asc,passivePath,r.passive)
        if not spec then spec=grant(r,"passive",passive) end
        if spec.ActiveCount==0 then
            assert(r.asc:TryActivateAbility({Handle=r.passive},false),"native passive did not activate")
        end
        -- A late unequip can end the old task after our task started.
        if change and r.weaponName~=nil and not M.ready(r) and not M.pending(r) and not M.committed(r) then
            r.state:TryActivateNewState(tag(readyTag))
        end
    end
    r.nativePassive,r.weaponName,r.restoreSpent=original,names,nil
    if not cooling then r.leasedReady=nil end
    local key=names .. "/" .. tostring(original) .. "/" .. tostring(r.passive) .. "/" .. tostring(r.action) .. "/" .. tostring(cooling)
    if key~=r.lastArm then
        r.lastArm=key
        r.log("native death gate armed, weapons=" .. names .. ", real passive=" .. tostring(original)
            .. ", ready=" .. tostring(M.ready(r)) .. ", borrowed passive=" .. tostring(r.passive)
            .. ", borrowed action=" .. tostring(r.action) .. ", pre-existing cooldown=" .. tostring(cooling))
    end
end
function M.cooling(r) return hasTag(r.asc,cooldownTag) end
function M.pending(r) return r.state:InPendingState(tag(dead)) end
M.eligible=eligible
function M.committed(r) return r.state:InExactState(tag(dead)) end
function M.ready(r) return hasTag(r.asc,readyTag) end
function M.deathStatus(r)
    local _,name=equipment(r)
    local original=granted(r.asc,passivePath,nil,r.passive,true)
    return string.format("weapon=%s, real passive=%s, borrowed passive=%s, ready=%s, cooldown=%s, pending=%s, forbid=%s",
        name,tostring(original and original.Handle.Handle),tostring(r.passive),tostring(M.ready(r)),
        tostring(M.cooling(r)),tostring(M.pending(r)),tostring(hasTag(r.asc,"CharacterState.Forbid.Resurrect")))
end
function M.releaseReadiness(r)
    if M.ready(r) then r.state:StopState(tag(readyTag),false) end
    r.leasedReady=nil
end
function M.takePending(r,t)
    if M.pending(r) and not M.committed(r) then
        r.state:RemovePendingState(tag(dead))
        t.tookPending=not M.pending(r)
        r.log("confirmed Reborn took pending death=" .. tostring(t.tookPending))
    end
end
function M.returnPending(r,t)
    if t and t.tookPending and not M.pending(r) and not M.committed(r) then
        r.state:AddPendingState(tag(dead))
    end
end
function M.trySpent(r)
    -- Native UltraKill/Forbid listeners withdraw readiness. Only the charge
    -- count is virtual. An already-spent genuine charge stays spent on close.
    if M.cooling(r) and M.ready(r) and eligible(r) then
        return r.input:ForceActivateExternalActionAbilityByTag(tag("Ability.Action.Hun.HeiMoShang.Reborn"),nil,-5)
    end
end
function M.tryBorrowed(r)
    if r.action and M.ready(r) and eligible(r) then
        -- Supply only missing activation *requirements* that the real blade
        -- config declares as equipment tags, for this synchronous attempt.
        -- Preserve the original Blueprint result and all blocked-state tags.
        local equip={}
        local inspected=pcall(function() config:GetEquipTags(equip) end)
        if not inspected then equip={} end
        local spec=granted(r.asc,skillPath,r.action)
        if not spec then return false end
        local required=unwrap(spec.Ability).ActivationRequiredTags
        local wanted=required and required.GameplayTags
        local added={}
        local ok,accepted=pcall(function()
            for i=1,equip.GameplayTags and #equip.GameplayTags or 0 do
                local name=unwrap(equip.GameplayTags[i]).TagName:ToString()
                for j=1,wanted and #wanted or 0 do
                    local req=unwrap(wanted[j]).TagName:ToString()
                    if (name==req or name:sub(1,#req+1)==req .. ".") and not hasTag(r.asc,req) then
                        utils:AddLooseGameplayTagForSystem(r.asc,tag(name),false)
                        added[#added+1]=name
                    end
                end
            end
            return r.asc:TryActivateAbility({Handle=r.action},false)
        end)
        for _,name in ipairs(added) do utils:RemoveLooseGameplayTagForSystem(r.asc,tag(name),false) end
        if not ok then error(accepted,0) end
        if not accepted then
            local read,names=pcall(function()
                local list=utils:GetActivateAbilityFailureTags(r.asc).GameplayTags
                local tags={}
                for i=1,#list do tags[i]=unwrap(list[i]).TagName:ToString() end
                return table.concat(tags,",")
            end)
            r.log("borrowed Reborn declined, handle=" .. r.action .. ", failure tags=" ..
                (read and names~="" and names or "unreported"))
        end
        return accepted
    end
end
function M.afterPaid(r)
    -- A previously-spent passive can retain its internal consumed flag after
    -- a virtual use. Recreate only our own passive to obtain its native
    -- listeners and readiness state for the next hit.
    if r.passive and (M.cooling(r) or not M.ready(r)) then clearGrant(r,"passive") end
    r.restoreSpent=M.cooling(r)
    M.arm(r)
end
function M.cleanup(t,paid)
    if paid then
        for _,e in pairs(effects(t.asc)) do
            if e.path==amplification then t.bonusBlocksMedicine=healingBlock(t.asc,e.def) end
        end
    end
    strip(t,paid)
end
function M.observeBonus(pawn,hp,max)
    if bonus and (not same(bonus.pawn,pawn) or hp<=max/2) then releaseBonus() end
end
function M.sampleMotion(t)
    local anim=t.pawn.Mesh:GetAnimInstance()
    local clip=valid(anim) and anim:GetCurrentActiveMontage()
    local name=valid(clip) and clip:GetFullName() or "none"
    if name~=t.clip then t.log("black blade native motion sample: " .. name); t.clip=name end
end
function M.running(t)
    return valid(t.ability) and utils:IsAbilityActive(t.ability)
end
function M.cancel(t)
    if M.running(t) then t.ability:K2_CancelAbility() end
    if M.running(t) then t.ability:K2_EndAbility() end
end
return M
