local deathwatch = {}
local current
local playerFolder = "/Game/PBZContent/Blueprint/Character/Player/"
local killPackage = "/Game/PBZContent/Blueprint/Ability/GameplayEffects/GE_Kill"

local function valid(obj)
    return obj ~= nil and obj:IsValid()
end

local function isKillEffect(effect)
    if not valid(effect) then return false end
    -- BP_ApplyGameplayEffectToSelf normally supplies a UClass. Recognise its
    -- class default object as well, without a short-name match on other assets.
    local name = effect:GetFName():ToString()
    if name ~= "GE_Kill_C" and name ~= "Default__GE_Kill_C" then return false end
    local path = effect:GetFullName():match("^[^ ]+ (.+)$")
    return path == killPackage .. ".GE_Kill_C" or path == killPackage .. ".Default__GE_Kill_C"
end

function deathwatch.install(game, onNativeDeath, log, originalPawn)
    if current then return end
    current = true
    local lastDyingPawn
    local function notifyTarget(target, kind)
        if not valid(target) then return end
        local player = game.getPlayer() or (originalPawn and originalPawn())
        if game.same(player, target) then
            lastDyingPawn = player
            onNativeDeath(player, kind)
        end
    end
    local function onDie(context)
        notifyTarget(context:get(), "OnDie")
    end
    local function setToDie(_, handler)
        -- UE4SS v4 unwraps FInterfaceProperty to its implementing UObject.
        notifyTarget(handler:get())
    end
    local function applyEffect(context, effectParam)
        if not isKillEffect(effectParam:get()) then return end
        local player = game.getPlayer()
        if valid(player) and game.same(player.AbilitySystemComponent, context:get()) then
            lastDyingPawn = player
            onNativeDeath(player)
        end
    end
    local pending = {
        ["/Script/ProjectPBZ.PBZAbilityBlueprintLibrary:SetCharacterToDie"] = setToDie,
        ["/Script/GameplayAbilities.AbilitySystemComponent:BP_ApplyGameplayEffectToSelf"] = applyEffect,
        [playerFolder .. "BP_Player_Base.BP_Player_Base_C:OnDie"] = onDie,
        [playerFolder .. "BP_Player_Soul.BP_Player_Soul_C:OnDie"] = onDie,
    }
    -- Observe the reflected BP steps without overriding their return values.
    -- Blueprint hooks in this loader observe a function after it executes.
    local renewal = "/Game/RenewalContent/Prototypes/Character/BP_RenewalPlayer.BP_RenewalPlayer_C:"
    local hun = "/Game/RenewalContent/Actors/Players/BP_Renewal_Hun.BP_Renewal_Hun_C:"
    local function traceStep(label, pawn)
        local player = game.getPlayer() or lastDyingPawn
        if not player or not game.same(player, pawn) then return end
        local point = game.position(pawn)
        local at = point and string.format("(%.0f, %.0f, %.0f) cm", point.x, point.y, point.z) or "unknown"
        log("native respawn step: " .. label .. ", player location=" .. at)
        if label == "BP_RenewalPlayer.On Dead" then onNativeDeath(pawn, "checkpoint") end
    end
    for _, method in ipairs({"On Dead", "Respawn Set Transform", "Respawn Refresh Monster",
                             "Respawn Reset Combat Logic", "Respawn"}) do
        pending[renewal .. method] = function(ctx) traceStep("BP_RenewalPlayer." .. method, ctx:get()) end
    end
    pending[hun .. "Respawn"] = function(ctx) traceStep("BP_Renewal_Hun.Respawn", ctx:get()) end
    local ability = "/Game/PBZContent/UI/InGame/Dead/GA_PlayerRespawn.GA_PlayerRespawn_C:K2_ActivateAbility"
    pending[ability] = function(ctx)
        traceStep("GA_PlayerRespawn.K2_ActivateAbility", ctx:get():GetAvatarActorFromActorInfo())
    end
    local lastError = {}
    local function reportOnce(path, detail)
        detail = tostring(detail)
        if detail ~= lastError[path] then
            lastError[path] = detail
            log("death observer " .. path .. ": " .. detail)
        end
    end
    local function register()
        for path, handler in pairs(pending) do
            -- Avoid asking RegisterHook to allocate registry references for
            -- unstreamed blueprints. The public loader observes native calls
            -- before the function and Blueprint events after the function.
            local found, fn = pcall(StaticFindObject, path)
            if found and valid(fn) then
                local registered, id = pcall(RegisterHook, path, function(...)
                    local ok, err = pcall(handler, ...)
                    if not ok then reportOnce(path, err) end
                    -- No return override. The game's original function proceeds.
                end)
                if registered and type(id) == "number" then
                    pending[path] = nil
                else
                    reportOnce(path, id)
                end
            end
        end
        return next(pending) == nil
    end
    if not register() then
        local retry
        retry = LoopInGameThreadWithDelay(2000, function()
            if register() then CancelDelayedAction(retry) end
        end)
    end
end

return deathwatch
