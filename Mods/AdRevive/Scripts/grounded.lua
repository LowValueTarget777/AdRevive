-- Shared by movement history and all three revival eligibility checks.
local function inspect(pawn)
    local movement = pawn.CharacterMovement
    if not movement or not movement:IsValid() then return false, "unreadable_movement" end
    local mode = tonumber(movement.MovementMode)
    if not mode then return false, "unreadable_movement_mode" end
    if mode ~= 1 and mode ~= 2 then return false, "airborne" end
    local ok, grounded = pcall(function() return movement:IsMovingOnGround() end)
    if ok and type(grounded) == "boolean" then
        if not grounded then return false, "airborne" end
    else
        local falling = movement:IsFalling()
        if type(falling) ~= "boolean" then return false, "unreadable_ground_state" end
        if falling then return false, "airborne" end
    end
    if mode == 2 then
        -- PhysNavWalking does not maintain the ordinary walking floor sweep;
        -- even a positive old sweep cannot prove the navmesh is supported now.
        local base = movement:GetMovementBase()
        if not base or not base:IsValid() then return false, "no_floor" end
    else
        local floor = movement.CurrentFloor
        local blocking = floor and floor.bBlockingHit
        local walkable = floor and floor.bWalkableFloor
        if type(blocking) ~= "boolean" or type(walkable) ~= "boolean" then return false, "unreadable_floor" end
        if not blocking or not walkable then return false, "no_floor" end
    end
    return true
end

return function(pawn)
    local ok, safe, reason = pcall(inspect, pawn)
    if not ok then return false, "ground_binding: " .. tostring(safe):match("^[^\r\n]*") end
    return safe, reason
end
