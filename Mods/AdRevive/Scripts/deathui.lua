-- Present a copy of PBZ's death artwork without constructing its death widget.
-- The native LevelSequenceBurnIn host has no PBZ death/respawn callbacks.
local ui = {}
local cached
local path = "/Game/PBZContent/UI/InGame/Dead/W_PlayerDead.W_PlayerDead_C"
local artwork = {yun = true, ming = true, Blood1 = true, Blood2 = true, red = true}
local visualTracks = {
    MovieSceneFloatTrack = true, MovieSceneDoubleTrack = true,
    MovieScene2DTransformTrack = true, MovieSceneColorTrack = true,
    MovieSceneMarginTrack = true, MovieSceneWidgetMaterialTrack = true,
    MovieSceneVisibilityTrack = true, MovieSceneBoolTrack = true,
    MovieSceneByteTrack = true, MovieSceneVectorTrack = true,
}

local function valid(obj) return obj ~= nil and obj:IsValid() end
local function same(a, b) return valid(a) and valid(b) and a:GetAddress() == b:GetAddress() end
local function name(obj) return obj:GetFName():ToString() end
local function lookup(p)
    local obj = StaticFindObject(p)
    assert(valid(obj), "missing UI object: " .. p)
    return obj
end
local function value(item)
    if type(item) == "userdata" and item:type():match("UnrealParam$") then return item:get() end
    return item
end
local function each(array, callback)
    for i = 1, #array do callback(value(array[i])) end
end
local function owned(obj, outer)
    for _ = 1, 16 do
        if same(obj, outer) then return true end
        if not valid(obj) then return false end
        obj = obj:GetOuter()
    end
    return false
end

-- Retain only the two characters, their original decoration and layout ancestors.
-- Remove buttons, death counters and nested UserWidgets before Slate constructs them.
local function prune(widget, tree, images)
    assert(owned(widget, tree), "copied widget still belongs to original tree")
    local key = name(widget)
    if widget:IsA("/Script/UMG.Image") and artwork[key] then
        images[key] = widget
        return true, key == "yun" or key == "ming"
    end
    if not widget:IsA("/Script/UMG.PanelWidget") then return false, false end
    local keep, hasTitle = false, false
    for i = widget:GetChildrenCount() - 1, 0, -1 do
        local child = widget:GetChildAt(i)
        local retained, title = prune(child, tree, images)
        if retained then
            keep, hasTitle = true, hasTitle or title
            if title and widget:IsA("/Script/UMG.WidgetSwitcher") then widget:SetActiveWidget(child) end
        else
            assert(widget:RemoveChild(child), "cannot remove death UI child")
        end
    end
    return keep, hasTitle
end

local function clear(state)
    if not state or not valid(state.host) then return end
    state.host:StopAllAnimations()
    state.host:SetVisibility(1) -- Collapsed
end

function ui.hide(state)
    local ok, why = pcall(clear, state)
    return ok, why
end

function ui.dispose()
    local state = cached
    cached = nil
    if state then
        ui.hide(state)
        if valid(state.host) then pcall(function() state.host:RemoveFromParent() end) end
    end
end

function ui.prepare(pawn)
    if cached and same(cached.pawn, pawn) and valid(cached.host) and cached.host:IsInViewport() then return true end
    ui.dispose()
    local state = {pawn = pawn}
    local ok, why = pcall(function()
        local class = StaticFindObject(path)
        if not valid(class) then
            local system = lookup("/Script/Engine.Default__KismetSystemLibrary")
            local soft = system:Conv_SoftClassPathToSoftClassRef(system:MakeSoftClassPath(path))
            class = system:LoadClassAsset_Blocking(soft)
        end
        assert(valid(class) and valid(class.WidgetTree), "native death widget template unavailable")
        local sourceAnimation
        each(class.Animations, function(anim)
            if name(anim) == "Deadpopup" or name(anim) == "Deadpopup_INST" then sourceAnimation = anim end
        end)
        assert(valid(sourceAnimation), "native Deadpopup animation unavailable")
        local library = lookup("/Script/UMG.Default__WidgetBlueprintLibrary")
        local host = library:Create(pawn, lookup("/Script/LevelSequence.LevelSequenceBurnIn"), pawn.Controller)
        assert(valid(host), "cannot create native presentation host")
        state.host = host
        host.bIsFocusable = false
        host.bAutomaticallyRegisterInputOnConstruction = false
        host.TickFrequency = 1 -- Auto, including UMG sequence playback.
        local duplicate = lookup("/Script/SGameAI.Default__SGameAIFunctionLibrary")
        local tree = duplicate:DuplicateObject(class.WidgetTree, host)
        assert(valid(tree) and not same(tree, class.WidgetTree), "cannot copy death artwork")
        host.WidgetTree = tree
        local images = {}
        assert(valid(tree.RootWidget) and prune(tree.RootWidget, tree, images), "empty death artwork")
        assert(valid(images.yun) and valid(images.ming), "native death glyphs unavailable")
        assert(valid(images.yun.Brush.ResourceObject) and valid(images.ming.Brush.ResourceObject),
               "native death glyph textures unavailable")
        state.images = images
        local animation = duplicate:DuplicateObject(sourceAnimation, host)
        assert(valid(animation) and not same(animation, sourceAnimation), "cannot copy death animation")
        local movie = animation.MovieScene
        assert(valid(movie) and owned(movie, animation), "death sequence was not copied")
        -- Event/audio/subsequence tracks can initiate the original death flow.
        -- Edit only the duplicated sequence and admit visual property tracks.
        movie.Tracks = {}
        each(movie.ObjectBindings, function(binding)
            local retained = {}
            each(binding.Tracks, function(track)
                assert(owned(track, movie), "shared bound animation track")
                if visualTracks[name(track:GetClass())] then retained[#retained + 1] = track end
            end)
            binding.Tracks = retained
        end)
        -- Cooked evaluation data can still contain removed event tracks. Force
        -- compilation of this instance's visual-only sequence before playback.
        animation.CompiledData = nil
        local guid = lookup("/Script/Engine.Default__KismetGuidLibrary")
        animation.Signature, movie.Signature = guid:NewGuid(), guid:NewGuid()
        state.animation = animation
        -- A reflected reference keeps the duplicated animation alive while hidden.
        -- This deliberately unbound callback has no death event target.
        host.AnimationCallbacks = {{Animation = animation, AnimationEvent = 0, UserTag = FName("AdRevive")}}
        host:SetVisibility(1)
        host:AddToViewport(9000)
        assert(host:IsInViewport(), "cannot attach native title to viewport")
        cached = state
    end)
    if not ok then
        ui.hide(state)
        if valid(state.host) then pcall(function() state.host:RemoveFromParent() end) end
    end
    return ok, why
end

-- Seek the copied title to a readable frame with the combat world already paused.
function ui.showPaused(pawn)
    local state = cached
    local ok, why = pcall(function()
        assert(state and same(state.pawn, pawn) and valid(state.animation), "native title was not prepared")
        assert(valid(state.host) and state.host:IsInViewport(), "native title host expired")
        clear(state)
        state.host:SetVisibility(3) -- HitTestInvisible
        state.host:PlayAnimation(state.animation, 0, 1, 0, 1, true)
        local clip, host = state.animation, state.host
        local start, finish = clip:GetStartTime(), clip:GetEndTime()
        host:FlushAnimations()
        host:SetAnimationCurrentTime(clip, start + math.max(0, finish - start) * 0.65)
        host:FlushAnimations()
        host:PauseAnimation(clip)
        for _, glyph in ipairs({state.images.yun, state.images.ming}) do
            glyph:SetOpacity(1)
            local node = glyph
            while valid(node) do
                node:SetVisibility(3)
                node:SetRenderOpacity(1)
                local parent = node:GetParent()
                if valid(parent) and parent:IsA("/Script/UMG.WidgetSwitcher") then parent:SetActiveWidget(node) end
                node = parent
            end
        end
    end)
    if not ok then ui.hide(state); return nil, tostring(why) end
    return state
end

return ui
