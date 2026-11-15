-- Player discovery and GAS ownership, without a game process.
package.path = "Mods/AdRevive/Scripts/?.lua;" .. package.path
local game = dofile("Mods/AdRevive/Scripts/pbz.lua")
local nextAddress = 0
local function object(fields)
    fields = fields or {}
    nextAddress = nextAddress + 1
    local address = nextAddress
    function fields:IsValid() return self.destroyed ~= true end
    function fields:GetAddress() return address end
    function fields:GetOuter() return self.outer end
    return fields
end
local function controller(localPlayer)
    local c = object()
    function c:IsLocalPlayerController() return localPlayer end
    return c
end
local function character(c)
    local p = object({Controller = c})
    function p:IsA(path) return path == "/Script/ProjectPBZ.PBZCharacter" end
    c.Pawn = p
    return p
end

local stale = controller(true)
function stale:IsLocalPlayerController() error("old world") end
local remote, current = controller(false), controller(true)
character(remote)
local player = character(current)
local candidates = {stale, remote, current}
local scans = 0
function FindAllOf(class)
    assert(class == "PlayerController")
    scans = scans + 1
    return candidates
end
assert(game.getPlayer() == player)
assert(game.getPlayer() == player and scans == 1)
local nextController = controller(true)
local nextPlayer = character(nextController)
current.Pawn = nil
candidates = {remote, current, nextController}
assert(game.getPlayer() == nextPlayer and scans == 2)
nextPlayer.Controller = remote
local nobody, why = game.getPlayer()
assert(nobody == nil and why == "no possessed local PBZ character")

local set = object({
    Health = {CurrentValue = 85}, Health_Max = {CurrentValue = 100},
    Health_Min = {BaseValue = 0, CurrentValue = 0}, outer = player
})
player.AttributeSetBase = set
assert(game.sample(player) == 85)
local marker = string.unpack("<f", string.pack("<f", 0.01)) / 2
for _, pair in ipairs({{0,marker,0,0}, {marker,0,0,0}, {marker,marker,0,0},
        {1,marker,1,1}, {marker,2,0,2}, {1,2,1,2}, {0,0.00500005,0,0.00500005}}) do
    set.Health_Min.BaseValue, set.Health_Min.CurrentValue = pair[1], pair[2]
    assert(game.clearFloor(player, marker))
    assert(set.Health_Min.BaseValue == pair[3] and set.Health_Min.CurrentValue == pair[4])
end
set.Health_Min.BaseValue, set.Health_Min.CurrentValue = 1, 1
assert(not game.setFloor(player, marker) and set.Health_Min.CurrentValue == 1)
set.Health_Min.BaseValue, set.Health_Min.CurrentValue = 0, 0
set.outer = object()
local registered = set
local asc = object({AvatarActor = player, SpawnedAttributes = {}})
function asc.SpawnedAttributes:ForEach(callback)
    callback(1, {get = function() return registered end})
end
player.AbilitySystemComponent = asc
assert(game.sample(player) == 85)
asc.AvatarActor = nextPlayer
assert(game.sample(player) == nil, "another pawn's ASC must not own this set")
asc.AvatarActor, registered = player, object()
assert(game.sample(player) == nil, "foreign set is not registered with player's ASC")
print("PBZ player discovery and pawn/ASC attribute-set ownership passed")
