local model=require("adworld")
local store=require("adstore")
local view=require("adview")
local language=require("adlanguage")
local ad={}
local RESULT_SECONDS=1.5
local keys={}
local function down(s,name)
    if not keys[name] then keys[name]={KeyName=FName(name)} end
    return s.pc:IsInputKeyDown(keys[name])
end
-- On Windows the embedded Lua CRT clock measures elapsed wall time. PBZ hit-stop
-- and world dilation must not lengthen a 30 second ad.
local function clock() return os.clock() end
local function focused(s)
    return s.focus:IsFocusOnViewport(s.pawn) or s.host:HasUserFocus(s.pc) or s.host:HasUserFocusedDescendants(s.pc)
end
local function draw(s)
    view.draw(s,s.progress,math.ceil(model.AD_SECONDS-s.progress.seconds),s.paused,s.hold,s.notice)
end
local function feedback(s,_,event)
    if event then s.notice=model.formatNotice(event,s.lang); s.noticeUntil=s.last+1.7 end
end
function ad.new(dir,log)
    local base=assert(os.getenv("LOCALAPPDATA")).."\\PBZ\\AdRevive\\battle"
    local api={}
    function api.open(pawn)
        local s={dir=dir,pawn=pawn,pc=pawn.Controller,hold=0,autosave=0}
        local ok,err=pcall(function()
            local id,source
            s.lang,id,source=language.current()
            log("ADgame text language="..id.." ("..source..")")
            s.progress=store.open(base,model.newWorld)
            view.mount(s)
            s.last=clock()
            s.active=focused(s)
            s.blockVip=down(s,"Gamepad_FaceButton_Right")
            s.pauseKey=down(s,"P") or down(s,"Gamepad_Special_Right")
            s.closeKey=down(s,"Gamepad_Special_Left")
            s.feedback=function(cue,message) feedback(s,cue,message) end
            draw(s)
        end)
        if not ok then pcall(view.unmount,s); return nil,"in-game ad: "..tostring(err) end
        log(("ADgame mounted in viewport, remaining=%.2f"):format(model.AD_SECONDS-s.progress.seconds))
        return s
    end
    local function finish(s,result)
        local p=s.progress
        local previous=p.seconds
        if result=="failed" then
            s.result=result
            p.deaths=p.deaths+1
            p.world=model.newWorld()
        else
            p.completed=p.completed+1
        end
        p.seconds=0
        local ok,err=pcall(store.save,base,p)
        if not ok then
            log("ADgame save failed: "..tostring(err))
            if result~="failed" then
                p.seconds=math.min(previous,model.AD_SECONDS-.001); p.completed=p.completed-1
                return "closed"
            end
            s.retrySave=true
        end
        local shown,frame=pcall(view.showResult,s,result)
        s.result,s.resultElapsed,s.last=result,0,clock()
        if not shown then
            log("ADgame result banner unavailable: "..tostring(frame))
            return result
        end
        s.resultFrame=frame
        log("ADgame result banner: "..result)
    end
    function api.poll(s)
        if not s.host:IsValid() or not s.host:IsInViewport() then return s.result or "closed" end
        local now=clock()
        local dt=math.max(0,math.min(.25,now-s.last))
        s.last=now
        view.layout(s)
        if not s.result and view.clicked(s,s.close) then return "closed" end
        if not focused(s) then
            if s.active then
                if not s.result then store.save(base,s.progress) end
                s.active=false; s.hold=0; s.blockVip=true
            end
            return
        end
        if not s.active then s.active=true; dt=0 end
        if s.result then
            s.resultElapsed=s.resultElapsed+dt
            if s.resultElapsed>=RESULT_SECONDS then return s.result end
            view.animateResult(s.resultFrame,s.resultElapsed)
            return
        end
        local closeKey=down(s,"Gamepad_Special_Left")
        if closeKey and not s.closeKey then return "closed" end
        s.closeKey=closeKey
        local pauseKey=down(s,"P") or down(s,"Gamepad_Special_Right")
        if view.clicked(s,s.pause) or (pauseKey and not s.pauseKey) then
            s.paused=not s.paused; s.hold=0; dt=0
            if s.paused then store.save(base,s.progress) end
        end
        s.pauseKey=pauseKey
        local vipClick=view.clicked(s,s.vip)
        local vipDown=down(s,"Gamepad_FaceButton_Right")
        if not vipDown then s.blockVip=false; s.hold=0 end
        if s.paused then draw(s); return end
        if vipDown and not s.blockVip then s.hold=s.hold+dt end
        local p=s.progress
        local remaining=model.AD_SECONDS-p.seconds
        local point=s.layout:GetMousePositionOnViewport(s.pawn)
        local x,y=(point.X-s.x)/s.scale,(point.Y-s.y)/s.scale
        if s.mouseX and (s.mouseX~=x or s.mouseY~=y) and x>=0 and x<=620 and y>=0 and y<=765 then s.aim=x end
        s.mouseX,s.mouseY=x,y
        local axis=s.pc:GetInputAnalogKeyState({KeyName=FName("Gamepad_LeftX")})
        if math.abs(axis)<.18 then axis=0 else axis=(axis<0 and -1 or 1)*(math.abs(axis)-.18)/.82 end
        local left=down(s,"A") or down(s,"Left")
        local right=down(s,"D") or down(s,"Right")
        if left or right then axis=(right and 1 or 0)-(left and 1 or 0) end
        if axis~=0 then s.aim=nil end
        local credit=math.min(dt,remaining)
        local todo=credit
        while todo>1e-8 do
            local step=math.min(1/60,todo)
            model.advance(p.world,step,s.aim,s.feedback,axis)
            todo=todo-step
            if p.world.hp<=0 then return finish(s,"failed") end
        end
        if credit>=remaining then return finish(s,"completed") end
        if vipClick or s.hold>=.8 then return finish(s,"vip") end
        p.seconds=p.seconds+credit
        s.autosave=s.autosave+credit
        if s.autosave>=1 then store.save(base,p); s.autosave=0 end
        if s.noticeUntil and now>=s.noticeUntil then s.notice,s.noticeUntil=nil,nil end
        draw(s)
    end
    function api.discard(s)
        local ok,err=pcall(view.unmount,s)
        if not ok then log("ADgame UI cleanup: "..tostring(err)) end
        if not s.result or s.retrySave then
            ok,err=pcall(store.save,base,s.progress)
            if not ok then log("ADgame progress write failed: "..tostring(err)) end
        end
    end
    return api
end
return ad
