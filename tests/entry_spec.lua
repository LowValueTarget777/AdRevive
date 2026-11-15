-- Boot the distributed Lua entry point using only simulated UE4SS and Windows APIs.
-- Pass PBZ_ADREVIVE_SCRIPTS to exercise an installed copy without starting PBZ.
local scripts = os.getenv("PBZ_ADREVIVE_SCRIPTS") or "Mods/AdRevive/Scripts"
local modPath = [[C:\OfflineFixture\Mods\AdRevive]]
local passive = "/PBZCombatAsset/Prototypes/Abilities/GA_CommonUtilitiesPassive.GA_CommonUtilitiesPassive_C:OnTaken"
local factionPath = "/Script/SGameCombatSystem.Default__FactionUtils"
local function obj(kind, path, fields)
    local o = fields or {}
    function o:IsValid() return true end
    function o:GetAddress() return self end
    function o:GetFullName() return path or kind end
    function o:GetFName() return {ToString=function() return kind end} end
    function o:IsA(class) return class == kind end
    function o:GetClass() return self end
    return o
end
local function param(v) return {get=function() return v end} end
local function tag(v) return {TagName={ToString=function() return v end}} end

local clock, paused, streamed = 0, false, false
local logs, hooks, loops, pending = {}, {}, {}, {}
local activeAd, mapReset, lastAd
local order = {}
local function step(action) order[#order + 1] = action end
local modules, objects = {}, {}
local env = setmetatable({}, {__index=_G})
function env.require(name)
    if modules[name] then return modules[name] end
    local f = assert(io.open(scripts .. "/" .. name .. ".lua", "rb"))
    local source = f:read("*a")
    f:close()
    local chunk = assert(load(source, "@" .. modPath .. [[\Scripts\]] .. name .. ".lua", "t", env))
    local result = chunk()
    modules[name] = result or true
    return modules[name]
end
function env.print(s) logs[#logs+1] = s end
local function logged(s) return table.concat(logs):find(s, 1, true) ~= nil end
function env.RegisterHook(path, before, after)
    assert(not hooks[path], "duplicate registration for " .. path)
    hooks[path] = {before=before, after=after}
    return 9, 10
end
function env.RegisterLoadMapPreHook(cb) mapReset = cb end
function env.ExecuteInGameThread(cb) cb() end
function env.ExecuteInGameThreadWithDelay(ms, cb)
    pending[ms] = pending[ms] or {}
    table.insert(pending[ms], cb)
end
function env.LoopInGameThreadWithDelay(ms, cb) loops[ms] = cb; return ms end
function env.CancelDelayedAction(id) loops[id] = nil end
env.FName = function(name) return name end
env.os = {time=function() return 1000+math.floor(clock) end,clock=function() return clock end}
env.package={loadlib=function() error("unexpected external launcher") end}
modules.ingamead={new=function()
    return {
        open=function(pawn)
            assert(paused and pawn and not activeAd)
            activeAd={}; lastAd=activeAd
            return activeAd
        end,
        poll=function(s) assert(s==activeAd); return s.answer end,
        discard=function(s) assert(s==activeAd); s.discarded=true; activeAd=nil end,
    }
end}

local player, boss = obj("/Script/ProjectPBZ.PBZCharacter"), obj("/Script/Engine.Pawn", "Boss")
boss.AttributeSetBase = {Health = {CurrentValue = 777}}
boss.Phase = 2
local controller = obj("PlayerController", nil, {Pawn=player, IsLocalPlayerController=function() return true end})
player.Controller = controller
local down, up = obj("AM_Hun_Dead_F"), obj("AM_Hun_Unarmed_Getup_F")
local canIndexPoses = true
function env.FindAllOf(class)
    if class == "AnimMontage" then
        assert(canIndexPoses and not paused, "montage scan in critical path")
        return {down, up}
    end
    assert(class == "PlayerController")
    return {controller}
end
local health, minimum = {CurrentValue=100}, {CurrentValue=0, BaseValue=0}
local maximum = {CurrentValue=100}
player.AttributeSetBase = obj("AttributeSet", nil, {
    Health=health, Health_Max=maximum, Health_Min=minimum, GetOuter=function() return player end,
})
local world = obj("World", nil, {K2_GetWorldSettings=function()
    return obj("WorldSettings", nil, {bEnableWorldBoundsChecks=true, KillZ=-1000, PauserPlayerState=paused and player or nil})
end})
function player:GetWorld() return world end
function controller:GetWorld() return world end
local location = {X=1200, Y=3400, Z=100}
function player:K2_GetActorLocation() return location end
function player:IsActorBeingDestroyed() return false end
player.CharacterMovement = obj("Movement", nil, {
    MovementMode=1, CurrentFloor={bBlockingHit=true, bWalkableFloor=true},
    IsMovingOnGround=function() return true end, GetPhysicsVolume=function() return nil end,
})
local manager = obj("SequenceManager", nil, {IsInSequence=function() return false end})
objects["/Script/Engine.Default__SubsystemBlueprintLibrary"] = obj("Subsystem", nil, {
    GetWorldSubsystem=function(_, pawn) assert(pawn == player); return manager end,
})
local executed, deaths = false, 0
local renewalPath = "/Game/RenewalContent/Prototypes/Character/BP_RenewalPlayer.BP_RenewalPlayer_C:"
local asc = obj("ASC", nil, {
    ActivatableAbilities={Items={}},
    HasMatchingGameplayTag=function(_, t)
        return (executed and t.TagName == "Ability.Executed") or
            (health.CurrentValue <= 0 and t.TagName == "CharacterState.Dead")
    end,
    GetOwner=function() return player end,
    BP_ApplyGameplayEffectToSelf=function(_, effect)
        assert(effect:GetFullName():find("GE_Kill_C", 1, true) and minimum.CurrentValue == 0)
        deaths, health.CurrentValue = deaths + 1, 0
        step("die")
        hooks["/Game/PBZContent/Blueprint/Character/Player/BP_Player_Soul.BP_Player_Soul_C:OnDie"].before(param(player))
    end,
})
player.AbilitySystemComponent = asc
objects["/Script/GameplayAbilities.Default__AbilitySystemBlueprintLibrary"] = obj("Abilities", nil, {
    GetAbilitySystemComponent=function(_, p) assert(p == player); return asc end,
})
objects["/Script/ProjectPBZ.Default__PBZRestoreQueryLibrary"] = obj("Restore", nil, {
    ResetHealthToMax=function() error("ad rebirth must leave all healing to the native ability") end,
})
objects["/Script/Engine.Default__GameplayStatics"] = obj("Statics", nil, {
    GetUnpausedTimeSeconds=function() return clock end,
    IsGamePaused=function(_, p) assert(p == world or p == player); return paused end,
    SetGamePaused=function(_, p, value)
        assert(p == world)
        paused = value
        step(value and "pause" or "resume")
    end,
})
local nativeBlade, bladeReady, nativeUses = false, false, 0
local requests, grants, clears = 0,0,0
local passiveClass = "/Script/PBZCombatAsset.GA_HeiMoShang_RebornPassive"
local root = "/PBZCombatAsset/ActorData/Players/Hun/"
local skillName = "GA_Hun_HeiMoShang_Reborn"
local skillPath = root .. "Abilities/HeiMoShang/" .. skillName
local skillClass = skillPath .. "." .. skillName .. "_C"
local weapon = root .. "Weapon/HeiMoShang/"
local function effect(name) return weapon .. name .. "." .. name .. "_C" end
local drain = effect("GE_HeiMoShang_RebornLoseHealth")
local lock = effect("GE_HeiMoShang_Reborning")
local amplification = effect("GE_HeiMoShang_RebornPhysicalAmplification")
local recovery = effect("GE_HeiMoShang_RebornRecovery")
local cooldown = "/Script/PBZCombatAsset.GE_HeiMoShang_RebornCooldown"
-- Synthetic referenced GE carrying a flask restriction, with an unrelated
-- outside GE on the same ASC. Neither is identified by substring matching.
local linkedBlock = "/Fixture/Weapon/HealingRestriction"
local activeEffects = {[1]={path="/Game/Unrelated",n=1}}
local lib=objects["/Script/GameplayAbilities.Default__AbilitySystemBlueprintLibrary"]
function asc:GetActiveEffects()
    local result={}
    for i in pairs(activeEffects) do result[#result+1]={Handle=i} end
    return result
end
function lib:GetGameplayEffectFromActiveEffectHandle(h)
    local path=activeEffects[h.Handle].path
    return obj("GameplayEffect",path,{GEComponents={},InheritableBlockedAbilityTagsContainer={CombinedTags={}}})
end
function lib:GetGameplayEffectGrantedTags(cls) return {GameplayTags=cls:GetFullName()==linkedBlock and {tag("Fixture.Flask.Block")} or {}} end
objects["/Script/GameplayTags.Default__BlueprintGameplayTagLibrary"]=obj("TagLibrary",nil,{
    HasAnyTags=function(_,a,b) return a[1]~=nil and a[1]==b[1] end,
})
function lib:GetActiveGameplayEffectStackCount(h) local e=activeEffects[h.Handle]; return e and e.n or 0 end
function asc:RemoveActiveGameplayEffect(h,n)
    local e=assert(activeEffects[h.Handle]); assert(h.Handle~=1 and n>0 and n<=e.n)
    e.n=e.n-n
    if e.n==0 then activeEffects[h.Handle]=nil end
    return true
end
local waitDead,canVanish,forbid,otherImmortal,committed=false,true,false,false,false
local ready,held,playing,reject,requireEquip=false,false,nil,false,false
local emptyActors,unknownSlot,queueDeath=false,false,false
local equipTag,loose="Weapon.Equip.HeiMoShang",0
local registered,spare,nextID={},nil,100
local function has(tagName)
    if tagName=="CharacterState.Dead" then return committed end
    if tagName=="CharacterState.Immortal.HeiMoShang" then return ready end
    if tagName=="CharacterState.Forbid.Resurrect" then return forbid end
    if tagName=="CharacterState.Immortal.XuKongHuaShan" then return otherImmortal end
    if tagName=="CharacterState.AbilityState.HeiMoShang.RebornCooldown" then return activeEffects[5]~=nil end
    if tagName==equipTag then return loose>0 or held end
    return false
end
function asc:HasMatchingGameplayTag(t) return has(t.TagName) end
local function findSpec(path,id)
    for _,spec in ipairs(asc.ActivatableAbilities.Items) do
        if spec.Ability:IsA(path) and (not id or spec.Handle.Handle==id) then return spec end
    end
end
local function spec(path,id,count)
    local o=obj(path)
    o.ActivationRequiredTags={GameplayTags={tag(equipTag)}}
    local spec={Ability=o,Handle={Handle=id},ActiveCount=count or 0}
    table.insert(asc.ActivatableAbilities.Items,spec)
    return spec
end
local configPath=weapon.."Weapon_Hun_HeiMoShang.Weapon_Hun_HeiMoShang"
local config=obj("WeaponConfig",configPath,{GetEquipTags=function(_,out) out.GameplayTags={tag(equipTag)} end})
local skill=obj("Class",skillClass,{HardReferencedAssets={obj("/Script/CoreUObject.Class",linkedBlock)}})
objects[skillClass],objects[configPath],objects[passiveClass]=skill,config,obj("Class",passiveClass)
local bladeActor=obj(weapon.."BP_Weapon_Hun_HeiMoShang.BP_Weapon_Hun_HeiMoShang_C")
local otherActor=obj("OtherSword")
function player:GetCurrentWeapons() return emptyActors and {} or {held and bladeActor or otherActor} end
function player:GetGameTimeSinceCreation() return clock end
function player:IsActorBeingDestroyed() return false end
local function hook(name,...) return hooks[skillClass..":"..name].before(...) end
local info=param({AvatarActor=player,AbilitySystemComponent=asc})
local state=obj("States",nil,{
    InPendingState=function(_,t) assert(t.TagName=="CharacterState.Dead"); return waitDead end,
    InExactState=function(_,t) assert(t.TagName=="CharacterState.Dead"); return committed end,
    CanActivateNewState=function(_,t) assert(t.TagName=="CharacterState.Vanish"); return canVanish end,
    TryActivateNewState=function(_,t) assert(t.TagName=="CharacterState.Immortal.HeiMoShang"); ready=true end,
    StopState=function(_,t,children) assert(t.TagName=="CharacterState.Immortal.HeiMoShang" and not children); ready=false end,
    RemovePendingState=function(_,t)
        assert(t.TagName=="CharacterState.Dead" and not committed and waitDead and playing)
        waitDead=false
    end,
    AddPendingState=function(_,t)
        assert(t.TagName=="CharacterState.Dead" and not committed and not playing)
        waitDead=true;step("return pending death")
    end,
})
local function endNative(cancel)
    local a=assert(playing)
    a.running=false; playing=nil
    a.spec.ActiveCount=0
    if not cancel then health.CurrentValue=47 end
    hook("K2_OnEndAbility",param(a),param(cancel))
end
local nativeStarts=0
local function nativeAttempt(id)
    local s=assert(findSpec(skillClass,id))
    if requireEquip and not has(equipTag) then return false end
    local response=hook("K2_CanActivateAbility",nil,info,param(s.Handle))
    assert(response~=true,"mod bypassed an original Blueprint decision")
    if reject or response==false then return false end
    if not held and not registered[id] then return false end
    local a=obj("Reborn",nil,{spec=s,running=true,
        GetAvatarActorFromActorInfo=function() return player end,
        GetAbilitySystemComponentFromActorInfo=function() return asc end,
        K2_CancelAbility=function() endNative(true) end})
    playing=a;s.ActiveCount=1; nativeStarts=nativeStarts+1
    waitDead=queueDeath
    activeEffects[3]={path=drain,n=1}
    activeEffects[4]={path=lock,n=1}
    activeEffects[6]={path=amplification,n=1}
    activeEffects[7]={path=linkedBlock,n=1}
    activeEffects[8]={path=recovery,n=1}
    hook("K2_ActivateAbility",param(a))
    if waitDead then
        committed=true
        hooks[renewalPath.."On Dead"].before(param(player))
        endNative(true)
    end
    return true
end
local function force()
    local s=findSpec(skillClass)
    if not s or not nativeAttempt(s.Handle.Handle) then return false end
    ready=false
    if not activeEffects[5] then activeEffects[5]={path=cooldown,n=1} end
    return true
end
local input=obj("Input",nil,{ForceActivateExternalActionAbilityByTag=function(_,t,a,priority)
    assert(t.TagName=="Ability.Action.Hun.HeiMoShang.Reborn" and a==nil and priority==-5)
    return force()
end})
local weapons=obj("Weapons",nil,{AbilityInput=input,
    GetCurrentWeapon=function(_,slot,data,withPending,outIndex)
        assert(slot.TagName=="Weapon.Slot.Main" and withPending==false and type(outIndex)=="table")
        if not unknownSlot then data.WeaponConfig=held and config or otherActor end
    end,
    RegisterExternalWeaponAbility=function(_,h,c) assert(c==config and h.Handle>=100);registered[h.Handle]=true end,
    UnregisterExternalWeaponAbility=function(_,h) assert(registered[h.Handle]); registered[h.Handle]=nil end})
function player:GetComponentByClass(c)
    if c:GetFullName():find("ActorStateComponent",1,true) then return state end
    if c:GetFullName():find("CharacterWeaponsComponent",1,true) then return weapons end
end
function asc:K2_GiveAbility(c)
    assert(c==skill or c==objects[passiveClass])
    nextID=nextID+1
    return spec(c:GetFullName(),nextID).Handle
end
function asc:TryActivateAbility(h)
    local passiveSpec=findSpec(passiveClass,h.Handle)
    if passiveSpec then passiveSpec.ActiveCount=1; ready=not forbid;return true end
    return nativeAttempt(h.Handle)
end
function asc:ClearAbility(h)
    assert(h.Handle>=100,"touched a real weapon spec")
    for i,s in ipairs(self.ActivatableAbilities.Items) do
        if s.Handle.Handle==h.Handle then
            if s.Ability:IsA(passiveClass) then ready=false end
            table.remove(self.ActivatableAbilities.Items,i);return
        end
    end
end
local rawRemove=asc.RemoveActiveGameplayEffect
function asc:RemoveActiveGameplayEffect(h,n)
    local ok=rawRemove(self,h,n)
    if h.Handle==5 and not activeEffects[5] and not committed then ready=true end
    return ok
end
local rawDie=asc.BP_ApplyGameplayEffectToSelf
function asc:BP_ApplyGameplayEffectToSelf(e,...)
    rawDie(self,e,...)
    waitDead,committed=false,true
end
objects["/Script/SGameUtils.Default__AbilityUtils"]=obj("Utils",nil,{
    GetAbilityHandle=function(_,a) return a.spec.Handle end,
    IsAbilityActive=function(_,a) return a.running end,
    AddLooseGameplayTagForSystem=function(_,sys,t) assert(t.TagName==equipTag and sys==asc);loose=loose+1 end,
    RemoveLooseGameplayTagForSystem=function(_,sys,t) assert(t.TagName==equipTag and sys==asc);loose=loose-1 end,
})
player.Mesh=obj("Mesh",nil,{GetAnimInstance=function() return obj("Anim",nil,{GetCurrentActiveMontage=function() return nil end}) end})
function env.StaticFindObject(path)
    if path==passive and not streamed then return nil end
    return objects[path] or obj("Mock",path)
end
local title=dofile("tests/support/deathui_fixture.lua")(env,objects,player,function() return clock end,step)
local function tick(dt) clock=clock+(dt or 0.04); loops[33]();assert(not logged("interrupted:"),table.concat(logs)) end
local function worldStart(wield,spent,offhand)
    if mapReset then mapReset() end
    paused=false; held=wield;ready=wield and not spent;playing=nil
    forbid,otherImmortal,committed,waitDead,canVanish,reject,requireEquip=false,false,false,false,true,false,false
    activeEffects={[1]={path="/Other",n=1}};registered={};health.CurrentValue=100
    if spent then activeEffects[5]={path=cooldown,n=1} end
    asc.ActivatableAbilities.Items={}
    local medicine=spec("/Game/PBZContent/Blueprint/Item/Ability/Medicine/GA_Medicine_Base.GA_Medicine_Base_C",70)
    medicine.Ability.ActivationBlockedTags={GameplayTags={tag("Fixture.Flask")}}; medicine.Ability.AbilityTags={GameplayTags={}}
    if wield or offhand then spec(skillClass,72);spec(passiveClass,71,wield and 1 or 0) end
    tick(2)
end
local function lethal()
    health.CurrentValue=0;waitDead=true
    if canVanish and not forbid and not otherImmortal and ready and not activeEffects[5] then force() end
end
local function window()
    assert(paused and title.host.frozen and playing and not activeAd,table.concat(logs))
    tick(title.host.started+0.99-clock)
    assert(paused and playing and not activeAd,"ad appeared before the title's first second")
    tick(.011)
    assert(paused and playing and activeAd,table.concat(logs))
end
local function answer(result)
    activeAd.answer=result; tick()
    assert(not paused and minimum.CurrentValue==0)
end
local function settle()
    endNative(false);tick()
    if not activeEffects[5] then activeEffects[5]={path=cooldown,n=1} end
    tick();tick()
    assert(health.CurrentValue==47 and not activeEffects[3] and not activeEffects[4] and not activeEffects[7])
    assert(activeEffects[8] and activeEffects[1] and boss.AttributeSetBase.Health.CurrentValue==777 and boss.Phase==2)
end
env.require("main")
worldStart(false,false,false)
assert(logged("loaded v0.13.2") and next(registered) and ready,table.concat(logs))
-- A low-HP poll and a check without activation can never create an offer.
health.CurrentValue=0.005;tick(); assert(not paused and not activeAd)
-- A map transition during the one-second title must drop the pending offer.
lethal();tick(.5);assert(paused and not activeAd)
mapReset();tick(1.1);assert(not paused and not activeAd and not lastAd)
worldStart(false,false,false)
lethal();window();answer("completed");settle()
assert(not activeEffects[5] and deaths==0)
-- Repeat, same life and no checkpoint / bonfire.
lethal();window();answer("completed");settle()
worldStart(true,false,false);lethal();window();answer("closed");endNative(false);tick()
assert(activeEffects[5] and activeEffects[3] and health.CurrentValue==47 and deaths==0)
worldStart(false,false,false);lethal();window();answer("closed");tick()
assert(deaths==1 and committed and not playing and not activeEffects[3] and not activeEffects[8] and not ready)
-- A real spent charge survives watching and closing. The native input path
-- is simulated at zero HP while death is pending, never on ordinary HP polls.
worldStart(true,true,false);lethal();tick();tick();window();answer("completed");settle()
assert(activeEffects[5].n==1 and ready)
lethal();tick();tick();window();answer("closed");tick()
assert(deaths==2 and committed and activeEffects[5].n==1)
-- Inactive original spec takes precedence in the game's tag search. Retry the
-- externally registered spec under its own config, then release scoped tags.
worldStart(false,false,true);requireEquip=true;lethal();tick();tick(0.4)
window();assert(loose==0);answer("completed");settle()
worldStart(false,false,false);reject=true;lethal();tick();tick(0.4)
assert(not activeAd and not paused and committed and deaths==3 and not next(registered))
-- Same damage can enter two different state routes. No attack-name decisions.
for _,kind in ipairs({"forbid","other","vanish","committed","noPending"}) do
    worldStart(false,false,false)
    forbid=kind=="forbid";otherImmortal=kind=="other";canVanish=kind~="vanish"
    committed=kind=="committed";waitDead=kind~="noPending";health.CurrentValue=0
    tick();tick(0.5)
    assert(not playing and not activeAd and not paused and deaths==3)
    if kind~="committed" then
        local borrowed=next(registered)
        assert(hook("K2_CanActivateAbility",nil,info,param({Handle=borrowed}))==false)
        assert(not paused and not activeAd)
    end
end
worldStart(false,false,false);lethal();window();mapReset()
assert(not paused and not next(registered) and not playing and lastAd.discarded)
lastAd.answer="completed";tick(2);assert(health.CurrentValue==0)
worldStart(false,false,false);lethal();window();activeAd.answer="closed"
clock=clock+17;tick();tick()
assert(deaths==4 and not paused)
-- A recovered original weapon can take over from the borrowed passive.
worldStart(false,false,false);held=true;spec(skillClass,72);spec(passiveClass,71,1);tick(0.3)
assert(ready and not next(registered) and #asc.ActivatableAbilities.Items==3)
lethal();window();answer("closed");endNative(false);tick()
assert(deaths==4 and activeEffects[5] and activeEffects[3])
worldStart(false,false,false);lethal();window()
hooks[renewalPath.."On Dead"].before(param(player));lastAd.answer="completed";tick()
assert(not paused and not playing and not next(registered) and health.CurrentValue==0 and not activeEffects[8])

-- The live build returned an empty actor array throughout the encounter.
-- Simulate the same-frame pending death and a switch before the next poll.
emptyActors,queueDeath=true,true
local function changeWeapon()
    hooks["/Script/SGameCombatSystem.CharacterWeaponsComponent:SetCurrentWeapon"].after(param(weapons))
end
worldStart(true,false,false)
assert(ready and not next(registered) and #asc.ActivatableAbilities.Items==3)
local starts=nativeStarts
lethal();window()
assert(not committed and not waitDead and nativeStarts==starts+1)
assert(hook("K2_CanActivateAbility",nil,info,param({Handle=72}))==false)
answer("completed");settle()
assert(deaths==4 and not activeEffects[5] and not next(registered))

held=false;findSpec(passiveClass,71).ActiveCount=0;ready=false
changeWeapon()
assert(ready and next(registered))
lethal();tick();tick();window();answer("completed");settle()
assert(not committed and deaths==4)
-- Equip the genuine weapon before the next poll. Both tasks coexist during
-- the switch. Removing the borrowed task also stops its shared state.
held=true;findSpec(passiveClass,71).ActiveCount=1;changeWeapon()
assert(ready and not next(registered) and #asc.ActivatableAbilities.Items==3)
lethal();window();answer("closed");endNative(false);tick()
assert(deaths==4 and activeEffects[5] and activeEffects[3])
tick();lethal();tick();tick();window();answer("closed")
assert(committed and deaths==5 and activeEffects[5].n==1 and not ready)
assert(order[#order-1]=="return pending death")

-- A missing actor and config is unknown. Reuse the actual running weapon
-- passive until the slot is resolved, even across repeated samples.
unknownSlot=true
worldStart(true,false,false);tick(0.3)
assert(not next(registered) and #asc.ActivatableAbilities.Items==3)
lethal();window();answer("closed");endNative(false);tick()
assert(not committed and deaths==5 and activeEffects[5])

-- Capture the local encounter before the ability clears hatred. A VIP
-- restores every surviving opponent once. Paid time and dismissal do not.
local function fighter(name,hp,max,hostile)
    local actor=obj("/Script/Engine.Pawn",name,{hostile=hostile,heals=0})
    actor.AttributeSetBase=obj("Attributes",nil,{Health={CurrentValue=hp},Health_Max={CurrentValue=max}})
    function actor:GetWorld() return world end
    function actor:IsActorBeingDestroyed() return false end
    return actor
end
local chief=fighter("Boss",31,400,true)
local mob=fighter("Guard",12,50,true)
local deadMob=fighter("Dead",0,80,true)
local ally=fighter("Ally",8,50,false)
local idle=fighter("Spectator",27,75,true)
local stale=fighter("OutsideWorld",21,80,true)
function stale:GetWorld() return obj("OtherWorld") end
local haters=obj("Haters",nil,{BeHatredList={}})
local origComponent=player.GetComponentByClass
function player:GetComponentByClass(c)
    if c:GetFullName():find("HatredManagerComponent",1,true) then return haters end
    return origComponent(self,c)
end
objects["/Script/SGameCombatSystem.Default__FactionUtils"]=obj("Factions",nil,{
    GetFactionRelation=function(_,p,e) assert(p==player);return e.hostile and 2 or 0 end})
objects["/Script/ProjectPBZ.Default__PBZRestoreQueryLibrary"].ResetHealthToMax=function(_,enemy)
    assert(enemy==mob or enemy==chief,"invalid VIP target")
    enemy.heals=enemy.heals+1
    enemy.AttributeSetBase.Health.CurrentValue=enemy.AttributeSetBase.Health_Max.CurrentValue
    return true
end
unknownSlot=false
worldStart(false,false,false)
haters.BeHatredList={chief,mob,mob,deadMob,ally,stale,player}
lethal();window();haters.BeHatredList={};answer("vip");settle()
assert(chief.heals==1 and chief.AttributeSetBase.Health.CurrentValue==400 and mob.heals==1 and mob.AttributeSetBase.Health.CurrentValue==50)
assert(deadMob.AttributeSetBase.Health.CurrentValue==0 and ally.heals==0 and idle.heals==0 and stale.heals==0)
assert(logged("ad result=vip, route=paid") and logged("VIP encounter: captured=2, healed=2, already full=0"))
chief.AttributeSetBase.Health.CurrentValue=19;haters.BeHatredList={chief}
lethal();window();answer("completed");settle()
assert(chief.heals==1 and chief.AttributeSetBase.Health.CurrentValue==19)
lethal();window();answer("closed");assert(chief.heals==1)

worldStart(false,false,false)
haters.BeHatredList={}
objects["/Script/Engine.Default__GameplayStatics"].GetAllActorsOfClass=function(_,p,cls,out)
    assert(p==player and cls:GetFullName()=="/Script/ProjectPBZ.PBZCharacter_NPC");out[1]=chief;out[2]=idle
end
objects["/Script/PBZAbilityTargetRuntime.Default__PBZPlayerAbilityTargetLibrary"]=obj("HatredQuery",nil,{
    IsPlayerInCasterHatredList=function(_,actor)return actor==chief end})
lethal();window();answer("vip");settle()
assert(chief.heals==2 and idle.heals==0)
assert(not logged("native gate error:") and loose==0,table.concat(logs))
print("Native entry passed: empty weapon array, equip and unequip between polls, same-frame death, repeat rewards, original charges, map travel and native-only healing")
