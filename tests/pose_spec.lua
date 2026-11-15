-- Verify streaming and stale montages without performing a global lookup in combat.
package.path = "Mods/AdRevive/Scripts/?.lua;" .. package.path
local pbz = dofile("Mods/AdRevive/Scripts/pbz.lua")
local function obj(fields)
    local value = fields or {}
    value.IsValid = function(self) return not self.stale end
    value.GetAddress = function(self) return self end
    return value
end
local function montage(name)
    return obj({GetFName = function() return {ToString = function() return name end} end})
end
local pawn = obj()
pawn.AttributeSetBase = obj({
    Health = {CurrentValue = 100}, Health_Max = {CurrentValue = 100}, Health_Min = {CurrentValue = 0, BaseValue = 0},
    GetOuter = function() return pawn end,
})
local asc = obj({GetOwner = function() return pawn end})
local statics = obj({
    IsGamePaused = function() return false end,
    GetAbilitySystemComponent = function() return asc end,
})
function StaticFindObject() return statics end

local scans, observer = 0, nil
local back = montage("AM_Hun_Dead_B")
function FindAllOf(class)
    assert(class == "AnimMontage")
    scans = scans + 1
    return {montage("OtherMontage"), back}
end
function NotifyOnNewObject(class, callback)
    assert(class == "/Script/Engine.AnimMontage" and not observer)
    observer = callback
end
assert(pbz.prepare(pawn) and pbz.prepare(pawn))
assert(scans == 1 and observer)
local binding = assert(pbz.bindPose(pawn))
assert(binding.down == back and binding.up == nil)
back.stale = true
assert(not pbz.bindPose(pawn))
local front, up = montage("AM_Hun_Dead_F"), montage("AM_Hun_Unarmed_Getup_F")
observer(front); observer(up)
binding = assert(pbz.bindPose(pawn))
assert(binding.down == front and binding.up == nil and scans == 1)
print("pose cache passed: one preparation scan, stale assets skipped, streamed poses available without a rescan")

-- A fresh save can lack both the death and get-up assets in the loaded-object list.
local registryScans, loads = 0, 0
local registry = obj({GetAssetsByClass = function(_, class, entries, recursive)
    assert(class.PackageName == "/Script/Engine" and class.AssetName == "AnimMontage" and recursive)
    registryScans = registryScans + 1
    entries[1] = {AssetName = "AM_Hun_Dead_F"}
    entries[2] = {AssetName = "AM_Hun_Unarmed_Getup_F"}
    entries[3] = {AssetName = "UnrelatedMontage"}
end})
local helpers = obj({
    GetAssetRegistry = function() return registry end,
    GetAsset = function(_, entry)
        assert(entry.AssetName ~= "UnrelatedMontage")
        loads = loads + 1
        return entry.AssetName == "AM_Hun_Dead_F" and front or up
    end,
})
function StaticFindObject(path)
    if path == "/Script/AssetRegistry.Default__AssetRegistryHelpers" then return helpers end
    return statics
end
function FindAllOf() return {} end
function NotifyOnNewObject() end
function FName(value) return value end
local fresh = dofile("Mods/AdRevive/Scripts/pbz.lua")
assert(fresh.prepare(pawn) and fresh.prepare(pawn))
binding = assert(fresh.bindPose(pawn))
assert(binding.down == front and binding.up == nil and registryScans == 1 and loads == 1)
print("pose preload passed: registry lookup before combat loads only the named defeat assets")
