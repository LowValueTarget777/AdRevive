local clock = 0
local env, objects = setmetatable({}, {__index = _G}), {}
local pawn = {Controller = {}}
function pawn:IsValid() return true end
function pawn:GetAddress() return self end
local f = dofile("tests/support/deathui_fixture.lua")(env, objects, pawn, function() return clock end)
function env.StaticFindObject(path) return objects[path] end
objects["/Script/Engine.Default__GameplayStatics"] = {
    IsValid = function() return true end, GetUnpausedTimeSeconds = function() return clock end,
}
local ui = assert(loadfile("Mods/AdRevive/Scripts/deathui.lua", "t", env))()
assert(ui.prepare(pawn))
assert(ui.prepare(pawn) and f.builds == 1)
assert(f.sourceTree.RootWidget:GetChildrenCount() == 3)
assert(f.tree.RootWidget:GetChildrenCount() == 1)
local tracks = f.animation.MovieScene.ObjectBindings[1].Tracks
assert(#f.animation.MovieScene.Tracks == 0 and #tracks == 1 and tracks[1].kind == "MovieSceneFloatTrack")
assert(#f.sourceAnimation.MovieScene.Tracks == 1)
assert(#f.sourceAnimation.MovieScene.ObjectBindings[1].Tracks == 3)
assert(not f.animation.CompiledData and f.sourceAnimation.CompiledData.containsDeathEvents)
assert(f.animation.Signature ~= f.sourceAnimation.Signature)
assert(f.host.visibility == 1 and not f.host.bIsFocusable)
local token = assert(ui.showPaused(pawn))
assert(f.host.frozen and f.host.time == 0.65 and f.host.visibility == 3)
assert(ui.hide(token) and f.host.visibility == 1)
assert(ui.showPaused(pawn) == token and f.builds == 1)
ui.dispose()
assert(f.removals == 1 and not f.host.attached)
assert(ui.showPaused(pawn) == nil)
f.copyFails = true
local ok, why = ui.prepare(pawn)
assert(not ok and why:find("cannot copy death artwork", 1, true) and not f.host.attached)
f.copyFails = false
assert(ui.prepare(pawn) and f.builds == 3)
ui.dispose()
print("native title adapter passed: independent tree/sequence, visual-only tracks, glyph visibility, ownership, reuse and failed construction")
