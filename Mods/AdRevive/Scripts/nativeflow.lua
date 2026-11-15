-- Only the local player's actual black-blade action can create a ticket.
local blade=require("reborn")
local TITLE_SECONDS=1
local Flow={}
Flow.__index=Flow
function Flow.new(g,ad,log,title)
    return setmetatable({g=g,ad=ad,log=log,title=title},Flow)
end

function Flow:releaseWindow(t)
    if t.ticket then self.ad.discard(t.ticket,true); t.ticket=nil end
    if t.overlay then self.title.hide(t.overlay); t.overlay=nil end
    if self.pauseOwner then
        if self.g.same(self.pauseOwner,self.pauseOwner) then
            local ok,why=self.g.pause(self.pauseOwner,false)
            if not ok then self.log("world resume pending: " .. tostring(why)); return false end
        end
        self.pauseOwner=nil
    end
    return true
end
function Flow:started(t)
    self.session=t
    t.phase="offer"
    t.context=self.g.offerContext(t.pawn)
    local world=t.context.world
    self.log("native Reborn started, weapons=" .. t.weapons .. ", natural charge=" .. tostring(t.natural)
        .. ", spec=" .. tostring(t.id) .. ", HP=" .. tostring(self.g.sample(t.pawn)))
    local r=self.binding
    blade.takePending(r,t)
    if r.attacker and t.attemptTime-r.hitTime<=0.25 then
        t.attacker=r.attacker
        self.log(self.g.encounterSample(t.attacker,"before"))
    end
    local paused,why=self.g.paused(world)
    if paused~=false then self:decide("closed",why or "world was already paused"); return end
    self.pauseOwner=world
    local ok
    ok,why=self.g.pause(world,true)
    if not ok then self:decide("closed",why); return end
    t.overlay,why=self.title.showPaused(t.pawn)
    if not t.overlay then self.log("native title unavailable: " .. tostring(why)) end
    t.adOpensAt=os.clock()+(t.overlay and TITLE_SECONDS or 0)
end
function Flow:decide(result,reason)
    local t=self.session
    if not t or t.phase~="offer" then return end
    local paid=result=="completed" or result=="vip"
    t.phase=paid and "paid" or (t.natural and "natural" or "death")
    self.log("ad result=" .. result .. ", route=" .. t.phase .. (reason and (", " .. tostring(reason)) or ""))
    if t.ticket then self.ad.discard(t.ticket,reason~=nil); t.ticket=nil end
    if result=="vip" then
        local ok,why=pcall(self.g.healFightingEnemies,t.pawn,t.context,t.opponents,self.log)
        if not ok then self.log("VIP enemy healing: " .. tostring(why)) end
    end
    -- Defer cancellation and GE_Kill until the native activation stack has
    -- unwound, including when pause setup fails synchronously in started().
    if t.phase~="death" then self:releaseWindow(t) end
end
function Flow:death(t)
    local r=self.binding
    r.suppressed,r.forceDeath=true,true
    if t then blade.cancel(t) end
    blade.retire(r)
    if t and t.phase~="natural" then blade.cleanup(t,false) end
    blade.releaseReadiness(r)
    if t and not self:releaseWindow(t) then return end
    blade.returnPending(r,t)
    if not blade.committed(r) then
        local ok,why=self.g.die(r.pawn,true,true)
        assert(ok,why)
    end
    self.log("released to native death/checkpoint")
    self.session=nil
    r.awaitRespawn=true
    r.deadTime=r.pawn:GetGameTimeSinceCreation()
end
function Flow:reset()
    local t,r=self.session,self.binding
    self.session=nil
    if r then r.suppressed=true end
    if t then
        self:releaseWindow(t)
        if self.g.same(t.asc,t.asc) and (t.phase=="paid" or not t.natural) then
            pcall(blade.cancel,t)
            pcall(blade.cleanup,t,false)
        end
    end
    if r then
        local ok,why=pcall(blade.detach,r)
        if not ok then self.log("native grant cleanup: " .. tostring(why)) end
    end
    self.title.dispose()
    self.player,self.binding=nil,nil
end
function Flow:checkpoint(pawn)
    if self.binding and self.g.same(self.player,pawn) then
        local r=self.binding
        r.checkpoint=true
        local ok,status=pcall(blade.deathStatus,r)
        self.log("original checkpoint committed, " .. (ok and status or "weapon state unreadable")
            .. ", native action=" .. tostring(self.session and self.session.id))
    end
end
function Flow:weaponChanged()
    local r=self.binding
    if not r then return end
    r.nextArm=nil
    if self.session or r.suppressed or r.checkpoint or r.awaitRespawn or r.syncing or not self.g.same(r.pawn,self.g.getPlayer()) then return end
    local hp=self.g.sample(r.pawn)
    if hp and hp>0 and not blade.pending(r) and not blade.committed(r) then self:syncWeapon(r) end
end
function Flow:syncWeapon(r)
    r.syncing=true
    local ok,why=pcall(blade.arm,r)
    r.syncing=false
    if not ok then self:abort(why); return end
    r.nextArm=r.pawn:GetGameTimeSinceCreation()+0.12
end
function Flow:abort(why)
    local r,t=self.binding,self.session
    if not r then return end
    self.log("native gate error: " .. tostring(why))
    if t then
        if t.phase=="offer" then self:decide("closed","native gate interrupted") end
        if t.phase=="paid" and (self.g.sample(t.pawn) or 0)>0 then
            self:releaseWindow(t)
            local ok,err=pcall(blade.cleanup,t,true)
            if not ok then self.log("paid effect cleanup incomplete: " .. tostring(err)) end
            self.session=nil
        elseif t.phase~="natural" then
            self:releaseWindow(t)
            local ok,err=pcall(self.death,self,t)
            if not ok then self.log("native death recovery: " .. tostring(err)) end
        end
    end
    self:reset()
    self.retryAfter=os.time()+2
end
function Flow:updateSession(t)
    if t.phase=="offer" then
        if t.ended or not blade.running(t) then self:decide("closed","action ended while paused"); return end
        if not self.g.paused(t.context.world) then
            local ok,why=self.g.pause(t.context.world,true)
            if not ok then self:decide("closed",why); return end
        end
        if not t.ticket then
            if os.clock()<t.adOpensAt then return end
            local why
            t.ticket,why=self.ad.open(t.pawn)
            if not t.ticket then self:decide("closed",why); return end
            self.log("ad opened on confirmed native Reborn")
            return
        end
        local result=self.ad.poll(t.ticket)
        if result then
            self:decide(result)
            if t.phase=="death" then self:death(t) end
        end
        return
    end
    if t.phase=="death" then self:death(t); return end
    if not self:releaseWindow(t) then return end
    blade.sampleMotion(t)
    if not t.ended and blade.running(t) then return end
    if t.phase=="paid" then
        blade.cleanup(t,true)
        t.sweeps=(t.sweeps or 0)+1
        if t.sweeps<3 then return end
    end
    local hp,max=self.g.sample(t.pawn)
    local point=self.g.position(t.pawn)
    local origin=t.context.origin
    local distance=point and origin and math.sqrt((point.x-origin.x)^2+(point.y-origin.y)^2+(point.z-origin.z)^2)
    self.log(string.format("native Reborn settled, route=%s, HP=%s/%s, cooldown=%s, displacement cm=%s",
        t.phase,tostring(hp),tostring(max),tostring(blade.cooling(self.binding)),tostring(distance)))
    if t.attacker then self.log(self.g.encounterSample(t.attacker,"after")) end
    if hp and hp>0 then
        if t.phase=="paid" then blade.afterPaid(self.binding)
        elseif t.phase=="natural" and blade.cooling(self.binding) then
            self.binding.restoreSpent=true
            self.binding.nextArm=nil
        end
    end
    if hp and hp<=0 and not blade.committed(self.binding) then
        self:death(t)
    else self.session=nil end
end
function Flow:tick()
    if self.pauseOwner and not self.session then
        if not self:releaseWindow(self.session or {}) then return end
    end
    local g=self.g
    local p=g.getPlayer()
    if self.binding and (not g.same(self.player,p) or not g.ownsOffer(self.binding.context,p)
            or not g.same(self.binding.asc,p.AbilitySystemComponent)) then self:reset() end
    if not p or (self.retryAfter and os.time()<self.retryAfter) then return end
    local r=self.binding
    if not r then
        if not g.sample(p) or not g.same(p.AbilitySystemComponent,p.AbilitySystemComponent) then return end
        r={pawn=p,asc=p.AbilitySystemComponent,context=g.offerContext(p),log=self.log}
        self.player,self.binding=p,r
        blade.prepare(r,self)
        self.title.prepare(p)
    end
    local hp,max=g.sample(p)
    if not hp then self:reset(); return end
    if r.checkpoint then
        self:reset()
        self.retryAfter=os.time()+1
        return
    end
    if self.session then self:updateSession(self.session); return end
    if blade.committed(r) then r.awaitRespawn=true; return end
    if r.awaitRespawn then
        if hp<=0 or blade.pending(r) or (r.deadTime and p:GetGameTimeSinceCreation()-r.deadTime<1) then return end
        r.suppressed,r.awaitRespawn,r.forceDeath=false,false,false
    end
    if blade.pending(r) then
        -- A native state can legitimately wait for Vanish through a combo.
        -- Give the native task the first tick; retry a spent charge only while
        -- its original listeners still report the readiness state.
        if not blade.eligible(r) or not blade.ready(r) then r.pendingSince=nil; return end
        if not r.pendingSince then r.pendingSince=p:GetGameTimeSinceCreation(); return end
        blade.trySpent(r)
        if not self.session and r.action and not r.exactRetry and blade.ready(r) and blade.eligible(r) then
            r.exactRetry=true
            blade.tryBorrowed(r)
        end
        if not self.session and (r.action or r.passive) and blade.eligible(r) and blade.ready(r)
                and p:GetGameTimeSinceCreation()-r.pendingSince>0.35 then
            self.log("native Reborn did not start; skipping ad, last arm=" .. tostring(r.lastArm))
            self:death(nil)
        end
        return
    end
    r.pendingSince,r.candidate,r.exactRetry=nil,nil,nil
    blade.observeBonus(p,hp,max)
    if hp>0 and (not r.nextArm or p:GetGameTimeSinceCreation()>=r.nextArm) then
        self:syncWeapon(r)
    end
end
return Flow
