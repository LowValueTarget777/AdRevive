local source = debug.getinfo(1, "S").source:gsub("/", "\\")
local modDir = assert(source:match("^@(.+)\\[Ss]cripts\\[^\\]+$"), "missing AdRevive directory")
local g = require("pbz")
local flow = require("nativeflow")
local function log(line) print("[AdRevive] " .. line .. "\n") end
local ad = require("ingamead").new(modDir, log)

local controller
local function guard(action)
    local ok, why = pcall(action)
    if not ok then
        log("interrupted: " .. tostring(why))
        controller:abort(why)
    end
end
controller = flow.new(g, ad, log, require("deathui"))
RegisterLoadMapPreHook(function() controller:reset() end)
ExecuteInGameThread(function()
    require("deathwatch").install(g, function(p, kind)
        if kind == "checkpoint" then controller:checkpoint(p) end
    end, log, function() return controller.player end)
    -- Optional encounter telemetry. It never participates in eligibility.
    local function observeHit()
        return require("receipt").observeAttacker(g,function(p,enemy)
            local r=controller.binding
            if r and g.same(r.pawn,p) then r.attacker,r.hitTime=enemy,p:GetGameTimeSinceCreation() end
        end,log)
    end
    if not observeHit() then
        local retry
        retry=LoopInGameThreadWithDelay(2000,function() if observeHit() then CancelDelayedAction(retry) end end)
    end
end)
local nextPlayerCheck = 0
LoopInGameThreadWithDelay(33, function()
    if not controller.player and os.time() < nextPlayerCheck then return end
    guard(function() controller:tick() end)
    if not controller.player then nextPlayerCheck = os.time() + 1 end
end)
log("loaded v0.13.3 (HeiMoShang / in-game ADgame)")
