-- Drive the production viewport, timer, controls and save files without launching PBZ.
local scripts=os.getenv("PBZ_ADREVIVE_SCRIPTS") or "Mods/AdRevive/Scripts"
package.path=scripts.."/?.lua;"..package.path
local now,focused,capture=0,true,2
local originalClock=os.clock
os.clock=function() return now end
local point={X=400,Y=500}
local function valid(self) return true end
local function noop() end
local function obj(kind)
    local o={kind=kind,IsValid=valid,Font={},children={},IsInViewport=function(s) return s.mounted end,
        HasUserFocus=function() return false end,HasUserFocusedDescendants=function() return false end}
    for _,n in ipairs({"SetBrushColor","SetColorAndOpacity","SetJustification","SetBackgroundColor","SetVerticalAlignment","SetClipping",
            "SetRenderScale","SetRenderTransformPivot","SetPosition","SetSize","SetZOrder","SetBrushFromTexture",
            "SetPadding","SetShadowOffset","SetShadowColorAndOpacity","SetHorizontalAlignment","SetStretch","SetStretchDirection"}) do o[n]=noop end
    function o:SetRenderOpacity(a) self.opacity=a end
    function o:SetVisibility(v) self.visibility=v end
    function o:SetText(t) self.value=t end
    function o:AddToViewport(z) assert(z==10000); self.mounted=true end
    function o:RemoveFromParent() self.mounted=false end
    function o:AddChild(w) table.insert(self.children,w);return obj("Slot") end
    o.AddChildToCanvas=o.AddChild
    o.AddChildToVerticalBox=o.AddChild
    function o:GetChildrenCount() return #self.children end
    function o:ClearChildren() self.children={} end
    o.OnClicked={Add=function(_,w,n) o.click=function() w[n](w) end end}
    return o
end
local inputType,padName,hardware,holdButton=0,"Xbox",{PrimaryDeviceType=1},false
local common={IsValid=valid,GetCurrentInputType=function() return inputType end,
    GetCurrentGamepadName=function() return {ToString=function() return padName end} end}
local deviceSubsystem={IsValid=valid,GetMostRecentlyUsedHardwareDevice=function(_,id) assert(id==9);return hardware end}
local culture="zh-Hans-CN"
local libs={
    KismetInternationalizationLibrary={GetCurrentLanguage=function() return {ToString=function() return culture end} end},
    WidgetBlueprintLibrary={Create=function() return obj("Host") end, SetFocusToGameViewport=noop,
        SetInputMode_GameAndUIEx=noop,SetInputMode_GameOnly=noop},
    SubsystemBlueprintLibrary={
        GetLocalPlayerSubSystemFromPlayerController=function(_,pc,cls)
            if cls.kind=="CommonInputSubsystem" then return common end
        end,
        GetEngineSubsystem=function(_,cls) assert(cls.kind=="InputDeviceSubsystem");return deviceSubsystem end,
    },
    WidgetLayoutLibrary={GetViewportScale=function() return 1.5 end,
        GetViewportSize=function() return {X=1920,Y=1080} end, GetMousePositionOnViewport=function() return point end},
    KismetRenderingLibrary={ImportFileAsTexture2D=function(_,_,name)
        local f=assert(io.open(name:gsub("\\","/"),"rb"))
        assert(f:read(8)=="\137PNG\r\n\26\n"); f:close(); return obj("Texture")
    end},
    KismetTextLibrary={Conv_StringToText=function(_,text) return text end},
    PBZBlueprintFunctionLibrary={IsFocusOnViewport=function() return focused end},
    GameplayStatics={GetUnpausedTimeSeconds=function() return now end,GetViewportMouseCaptureMode=function() return capture end,
        SetViewportMouseCaptureMode=function(_,_,n) capture=n end},
}
function StaticFindObject(path)
    local name=path:match("Default__(.+)")
    if name then local l=assert(libs[name],name);l.IsValid=valid;return l end
    return obj(path:match("[^.]+$"))
end
FName=function(n) return n end
StaticConstructObject=function(cls) return obj(cls.kind) end
local pc={IsValid=valid,bShowMouseCursor=false,GetPlatformUserId=function() return 9 end,
    IsInputKeyDown=function(_,key) return key.KeyName=="Gamepad_FaceButton_Right" and holdButton end,
    GetInputAnalogKeyState=function() return 0 end}
local pawn={IsValid=valid,Controller=pc}
local logs={}
local dir=scripts:gsub("[/\\]Scripts$","")
local ad=require("ingamead").new(dir,function(l) logs[#logs+1]=l end)
-- No test runner should write to a user's real ADgame profile.
local save=require("adstore")
local temp=os.tmpname()
os.remove(temp)
local open,saveTo=save.open,save.save
save.open=function(_,newWorld) return open(temp,newWorld) end
save.save=function(_,p) return saveTo(temp,p) end
local function show()
    local s,why=ad.open(pawn)
    assert(s,why);assert(pc.bShowMouseCursor and capture==0 and s.host.mounted)
    return s
end
local function tick(s)
    now=now+.05
    return ad.poll(s)
end
local function banner(s,result,title)
    assert(s.result==result and s.resultFrame.children[1].children[1].children[1].value==title)
    assert(s.vip.widget.visibility==1 and s.close.widget.visibility==1 and s.pause.widget.visibility==1)
    local worldTime,completed,sequence=s.progress.world.time,s.progress.completed,s.progress.sequence
    focused=false; now=now+2; assert(not tick(s) and s.resultElapsed==0)
    focused=true; assert(not tick(s))
    -- Stale click events during the display must not cancel or change this reward.
    s.vip.widget.click();s.close.widget.click()
    for _=1,29 do assert(not tick(s)) end
    assert((tick(s) or tick(s))==result,"reward was not released after the banner")
    assert(s.progress.world.time==worldTime and s.progress.completed==completed and s.progress.sequence==sequence)
end
local s=show()
for _=1,20 do assert(not tick(s)) end
local elapsed=s.progress.seconds
assert(math.abs(elapsed-1)<1e-6)
focused=false; now=now+10;tick(s);assert(s.progress.seconds==elapsed)
focused=true;tick(s);assert(s.progress.seconds==elapsed)
s.pause.widget.click();tick(s)
for _=1,6 do assert(not tick(s)) end
assert(s.progress.seconds==elapsed)
s.close.widget.click();assert(tick(s)=="closed"); ad.discard(s)
assert(not pc.bShowMouseCursor and capture==2 and not s.host.mounted)
s=show();assert(math.abs(s.progress.seconds-elapsed)<1e-6 and not s.paused)
s.progress.world.nextMob=1000  -- Keep the timer-only case independent of random combat.
for _=1,590 do assert(not tick(s));if s.result then break end end
assert(s.timer.value=="00:00" and s.progress.completed==1 and s.progress.seconds==0)
banner(s,"completed","复活成功!")
local oldTime=s.progress.world.time
ad.discard(s);s=show()
assert(math.abs(s.progress.world.time-oldTime)<1e-6)
s.vip.widget.click();assert(not tick(s));banner(s,"vip","充值成功!")
ad.discard(s);s=show()
assert(s.progress.completed==2 and s.progress.seconds==0)
local lines=s.vip.widget.children[1].children[1].children
assert(#lines==2 and lines[1].value=="给BOSS" and lines[2].value=="充值VIP跳过广告")
assert(lines[1].Font.Size==5 and lines[1].opacity<.2 and lines[2].Font.Size==18 and s.hintBox.visibility==1)
inputType=1;tick(s);assert(s.hintBox.visibility==3 and s.vipHint.value=="长按 B")
holdButton=true
for _=1,8 do assert(not tick(s)) end
holdButton=false;tick(s);assert(s.hold==0)
padName="PS5";tick(s);assert(s.vipHint.value=="长按 ○")
inputType=0;tick(s);assert(s.hintBox.visibility==1)
inputType=1;padName="Generic";hardware={PrimaryDeviceType=2,InputClassName="WinDualShock",HardwareDeviceIdentifier="None"}
tick(s);assert(s.hintBox.visibility==3 and s.vipHint.value=="长按 ○")
hardware.InputClassName="Unknown";tick(s);assert(s.vipHint.value=="长按 右侧键")
hardware.InputClassName="XInputInterface";tick(s);assert(s.vipHint.value=="长按 B")
inputType=2;tick(s);assert(s.hintBox.visibility==1)
for _,name in ipairs({"Xbox Series X","DualSense"}) do
    inputType,padName,holdButton=1,name,true
    for _=1,15 do assert(not tick(s)) end
    assert(s.hold<.8)
    assert(not tick(s))
    if not s.result then assert(not tick(s)) end -- Round-off at 0.8 s.
    banner(s,"vip","充值成功!")
    ad.discard(s); holdButton=false; s=show()
end
-- Exercise real combat on the last frame, including a simultaneous VIP click.
local function shot(w,x,y)
    w.hostile={{kind="gun",x=x,y=y,vx=0,vy=0,attack=10}}
    w.guard=0
end
s.progress.world=require("adworld").newWorld()
local w=s.progress.world
w.allies={{unit=0,hp=1,cool=1}}
local front=require("adworld").formation(w,0)
shot(w,front.x,front.y)
assert(not tick(s) and not s.result and #w.allies==0 and w.hp==100)
for _,seconds in ipairs({12,29.99}) do
    w=s.progress.world
    w.hp=1
    s.progress.seconds=seconds
    local completed,deaths=s.progress.completed,s.progress.deaths
    shot(w,w.x,675)
    s.vip.widget.click()
    assert(not tick(s))
    banner(s,"failed","复活失败!")
    ad.discard(s); s=show()
    assert(s.progress.seconds==0 and s.progress.deaths==deaths+1 and s.progress.completed==completed)
    assert(s.progress.world.time==0 and s.progress.world.hp==100)
end
-- A failed write cannot convert a loss into a dismissal with a natural revive.
local writeSave=save.save
save.save=function() error("fixture write refused") end
s.progress.world.hp=1;shot(s.progress.world,s.progress.world.x,675)
assert(not tick(s));banner(s,"failed","复活失败!")
save.save=writeSave
local deaths=s.progress.deaths
ad.discard(s);s=show()
assert(s.progress.deaths==deaths and s.progress.seconds==0)
ad.discard(s)
culture="en-us";s=show()
assert(s.lang.completed=="Revived!" and s.close.caption.value=="Close ad")
s.pause.widget.click();tick(s);assert(s.pause.caption.value=="Resume" and s.timer.value=="Paused")
s.pause.widget.click();tick(s)
s.feedback("hurt",{key="heroHit",amount=8,lost=11});tick(s)
assert(s.noticeLabel.value=="Soul lost 8 HP · Dropped Dark Wound")
s.vip.widget.click();assert(not tick(s));banner(s,"vip","Top-up successful!");ad.discard(s)
culture="ja-JP";s=show()
assert(s.close.caption.value=="広告を閉じる" and s.progress.deaths==deaths)
ad.discard(s)
for _,suffix in ipairs({"-0.json","-1.json"}) do os.remove(temp..suffix) end
os.clock=originalClock
print("Viewport passed: timer, VIP, lethal hits, failure banner, fresh run, focus and input cleanup")
