-- Reflected UMG fixtures shared by the adapter and distributed-entry regressions.
return function(env, objects, pawn, now, step)
    local f = {builds = 0, removals = 0, opacity = 1, layout = true}
    step = step or function() end
    local function object(kind, key, outer)
        local o = {kind = kind, key = key, outer = outer}
        function o:IsValid() return not self.stale end
        function o:GetAddress() return self end
        function o:GetFName() return {ToString = function() return self.key end} end
        function o:GetOuter() return self.outer end
        function o:GetClass() return object("Class", self.kind) end
        function o:IsA(path)
            local class = path:match("[^.]+$")
            return self.kind == class or class == "PanelWidget" and self.children ~= nil
        end
        return o
    end
    local function widget(kind, key, tree)
        local w = object(kind, key, tree)
        w.visibility, w.opacity = 0, 1
        function w:GetVisibility() return self.visibility end
        function w:SetVisibility(v) self.visibility = v end
        function w:SetOpacity(v) self.ColorAndOpacity.A = v end
        function w:SetRenderOpacity(v) self.opacity = v end
        function w:GetRenderOpacity()
            if self.key == "yun" or self.key == "ming" then return f.opacity * self.opacity end
            return self.opacity
        end
        function w:GetParent() return self.parent end
        function w:GetCachedGeometry() return {X = f.layout and 100 or 0, Y = 100} end
        if kind == "Image" then
            w.Brush = {ResourceObject = object("Texture2D", key .. "Texture")}
            w.ColorAndOpacity = {A = 1}
        elseif kind == "CanvasPanel" or kind == "WidgetSwitcher" then
            w.children = {}
            function w:GetChildrenCount() return #self.children end
            function w:GetChildAt(i) return self.children[i + 1] end
            function w:RemoveChild(child)
                for i, c in ipairs(self.children) do
                    if c == child then table.remove(self.children, i); child.parent = nil; return true end
                end
                return false
            end
            function w:SetActiveWidget(child) self.active = child end
            function w:GetActiveWidget() return self.active end
        end
        return w
    end
    local function add(parent, child)
        table.insert(parent.children, child)
        child.parent = parent
    end
    local tree = object("WidgetTree", "WidgetTree")
    tree.RootWidget = widget("CanvasPanel", "Root", tree)
    local switch = widget("WidgetSwitcher", "Language", tree)
    local letters = widget("CanvasPanel", "Letters", tree)
    add(tree.RootWidget, switch)
    add(switch, letters)
    add(letters, widget("Image", "yun", tree))
    add(letters, widget("Image", "ming", tree))
    add(letters, widget("Image", "Blood1", tree))
    add(tree.RootWidget, widget("UserWidget", "ReturnButton", tree))
    add(tree.RootWidget, widget("TextBlock", "DeathCount", tree))
    f.sourceTree = tree
    local function animation(outer)
        local a = object("WidgetAnimation", "Deadpopup_INST", outer)
        function a:GetStartTime() return 0 end
        function a:GetEndTime() return 1 end
        local movie = object("MovieScene", "MovieScene", a)
        movie.Tracks = {object("MovieSceneEventTrack", "RootEvents", movie)}
        movie.ObjectBindings = {{Tracks = {
            object("MovieSceneFloatTrack", "GlyphOpacity", movie),
            object("MovieSceneEventTrack", "DieEvent", movie),
            object("MovieSceneSubTrack", "RespawnSequence", movie),
        }}}
        a.MovieScene = movie
        a.CompiledData = {containsDeathEvents = true}
        return a
    end
    f.sourceAnimation = animation()
    local blueprint = object("WidgetBlueprintGeneratedClass", "W_PlayerDead_C")
    blueprint.WidgetTree, blueprint.Animations = tree, {f.sourceAnimation}
    objects["/Game/PBZContent/UI/InGame/Dead/W_PlayerDead.W_PlayerDead_C"] = blueprint
    objects["/Script/LevelSequence.LevelSequenceBurnIn"] = object("Class", "LevelSequenceBurnIn")
    objects["/Script/UMG.Default__WidgetBlueprintLibrary"] = object("Library", "UI")
    objects["/Script/UMG.Default__WidgetBlueprintLibrary"].Create = function(_, p, class, controller)
        assert(p == pawn and controller == pawn.Controller and class.key == "LevelSequenceBurnIn")
        f.builds = f.builds + 1
        local host = widget("LevelSequenceBurnIn", "AdReviveTitle", pawn)
        function host:AddToViewport(z) assert(z == 9000); self.attached = true end
        function host:IsInViewport() return self.attached == true end
        function host:RemoveFromParent() self.attached = false; f.removals = f.removals + 1 end
        function host:StopAllAnimations() self.playing = false end
        function host:PlayAnimation(a, start, loops, mode, rate, restore)
            assert(a ~= f.sourceAnimation and start == 0 and restore and self.visibility == 3)
            assert(self.AnimationCallbacks[1].Animation == a)
            self.started, self.playing, self.frozen = now(), true, false
            step("title")
        end
        function host:GetAnimationCurrentTime(a)
            assert(a ~= f.sourceAnimation)
            return self.playing and now() - self.started or 0
        end
        function host:PauseAnimation() self.frozen = true; step("freeze title") end
        function host:FlushAnimations() end
        function host:SetAnimationCurrentTime(_, at) self.time = at end
        function host:IsAnimationPlaying() return self.playing and not self.frozen end
        f.host = host
        return host
    end
    local function clone(source, copiedTree)
        local w = widget(source.kind, source.key, copiedTree)
        w.opacity, w.visibility = source.opacity, source.visibility
        if source.Brush then w.Brush.ResourceObject = source.Brush.ResourceObject end
        for _, c in ipairs(source.children or {}) do add(w, clone(c, copiedTree)) end
        return w
    end
    local copier = object("Library", "Duplicate")
    objects["/Script/SGameAI.Default__SGameAIFunctionLibrary"] = copier
    function copier:DuplicateObject(source, outer)
        if f.copyFails then return nil end
        if source == tree then
            local copied = object("WidgetTree", "WidgetTree", outer)
            copied.RootWidget = clone(tree.RootWidget, copied)
            f.tree = copied
            return copied
        end
        assert(source == f.sourceAnimation)
        f.animation = animation(outer)
        return f.animation
    end
    objects["/Script/UMG.Default__SlateBlueprintLibrary"] = {IsValid = function() return true end,
        GetLocalSize = function(_, g) return g end}
    objects["/Script/Engine.Default__KismetGuidLibrary"] = {IsValid = function() return true end,
        NewGuid = function() return {} end}
    env.FName = function(s) return s end
    return f
end
