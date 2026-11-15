-- A transient UMG tree. Every visible element belongs to the local player's viewport.
local art = require("adart")
local model = require("adworld")
local view = {}
local function valid(o) return o and o:IsValid() end
local function asset(path)
    local o=StaticFindObject(path)
    assert(valid(o),"missing "..path)
    return o
end
local function v(x,y) return {X=x,Y=y} end
local function color(r,g,b) return {R=r,G=g,B=b,A=1} end
local ink=color(.035,.045,.032)
local rust=color(.32,.075,.038)
local gold=color(.82,.63,.33)
local light=color(.96,.88,.66)
local classes={}
local function widget(s,kind)
    if not valid(classes[kind]) then classes[kind]=asset("/Script/UMG."..kind) end
    local obj=StaticConstructObject(classes[kind],s.tree)
    assert(valid(obj),"failed to create "..kind)
    return obj
end
local function put(panel,item,x,y,w,h,z)
    local slot=panel:AddChildToCanvas(item)
    assert(valid(slot),"failed to attach widget")
    slot:SetSize(v(w,h)); slot:SetPosition(v(x,y)); slot:SetZOrder(z)
    return slot
end
local function box(s,x,y,w,h,z,tint)
    local b=widget(s,"Border")
    b:SetBrushColor(tint); b:SetVisibility(3)
    return put(s.board,b,x,y,w,h,z)
end
local function label(s,size,tint)
    local o=widget(s,"TextBlock")
    o.Font.Size=size
    o:SetColorAndOpacity({SpecifiedColor=tint,ColorUseRule=0})
    o:SetJustification(1); o:SetVisibility(3)
    return o
end
local function write(s,label,text)
    if label.value~=text then
        label.widget:SetText(s.text:Conv_StringToText(text))
        label.value=text
    end
end
local function caption(s,x,y,w,h,z,size,tint,text)
    local item={widget=label(s,size,tint)}
    put(s.board,item.widget,x,y,w,h,z)
    write(s,item,text)
    return item
end
local function button(s,x,y,w,h,content,tint)
    local b=widget(s,"Button")
    b.IsFocusable=false
    b:SetBackgroundColor(tint)
    if type(content)=="string" then
        local text=label(s,13,light)
        text:SetText(s.text:Conv_StringToText(content))
        content=text
    end
    b:AddChild(content)
    put(s.board,b,x,y,w,h,90)
    -- Slate dispatches a click even if both mouse edges occur between Lua ticks.
    local marker=widget(s,"CanvasPanel")
    marker:SetVisibility(1)
    put(s.board,marker,0,0,1,1,0)
    marker:AddChild(widget(s,"Border"))
    b.OnClicked:Add(marker,FName("ClearChildren"))
    return {widget=b,marker=marker}
end
function view.clicked(s,button)
    if button.marker:GetChildrenCount()>0 then return false end
    button.marker:AddChild(widget(s,"Border"))
    return true
end
local function vipButton(s)
    local lines=widget(s,"VerticalBox")
    local small=label(s,5,color(.43,.21,.13))
    small:SetRenderOpacity(.18)
    small:SetText(s.text:Conv_StringToText("给BOSS"))
    lines:AddChildToVerticalBox(small)
    local title=label(s,18,light)
    title.Font.TypefaceFontName=FName("Bold")
    title:SetText(s.text:Conv_StringToText("充值VIP跳过广告"))
    lines:AddChildToVerticalBox(title)
    return button(s,206,62,208,47,lines,rust)
end
function view.showResult(s,outcome)
    s.vip.widget:SetVisibility(1)
    s.close.widget:SetVisibility(1)
    s.pause.widget:SetVisibility(1)
    s.hintBox:SetVisibility(1)
    s.holdBar:SetSize(v(0,3))
    write(s,s.noticeLabel,"")
    if outcome=="completed" then write(s,s.timer,"00:00") end

    box(s,0,0,620,765,110,{R=.018,G=.012,B=.009,A=.68})
    local frame=widget(s,"Border")
    frame:SetBrushColor(gold)
    frame:SetPadding({Left=4,Top=4,Right=4,Bottom=4})
    local face=widget(s,"Border")
    face:SetBrushColor(outcome=="vip" and color(.64,.065,.029) or color(.018,.25,.16))
    face:SetHorizontalAlignment(2)
    face:SetVerticalAlignment(2)
    local headline=label(s,47,light)
    headline.Font.TypefaceFontName=FName("Bold")
    headline:SetShadowOffset(v(2,3))
    headline:SetShadowColorAndOpacity(ink)
    headline:SetText(s.text:Conv_StringToText(outcome=="vip" and "充值成功!" or "复活成功!"))
    face:AddChild(headline)
    frame:AddChild(face)
    frame:SetRenderScale(v(.88,.88))
    put(s.board,frame,78,321,464,123,111)
    return frame
end
function view.animateResult(frame,elapsed)
    local t=math.min(1,elapsed/.24)
    local scale=1+(1-t)^2*(.60*t-.12)
    frame:SetRenderScale(v(scale,scale))
end

local function keyFor(name)
    if not name then return end
    if type(name)~="string" then name=name:ToString() end
    local id=name:lower():gsub("[%s_%-]","")
    if id:find("playstation") or id:find("dualsense") or id:find("dualshock") or id:find("ps[345]")
        or id:find("sony") or id:find("054c") then return "○" end
    if id:find("xbox") or id:find("xinput") or id:find("xsx") or id:find("steamdeck")
        or id:find("045e") then return "B" end
    if id:find("nintendo") or id:find("switchpro") then return "A" end
end

local function padKey(s)
    if valid(s.commonInput) then
        if s.commonInput:GetCurrentInputType()~=1 then return end
        local key=keyFor(s.commonInput:GetCurrentGamepadName())
        if key then return key end
    end
    if valid(s.devices) then
        local hw=s.devices:GetMostRecentlyUsedHardwareDevice(s.pc:GetPlatformUserId())
        if hw and hw.PrimaryDeviceType==2 then
            return keyFor(hw.HardwareDeviceIdentifier) or keyFor(hw.InputClassName) or "右侧键"
        end
    end
    if valid(s.commonInput) then return "右侧键" end
end
local function tex(s,name)
    local t=s.textures[name]
    if valid(t) then return t end
    local file=name=="ground" and "ground.png" or assert(art[name],name)
    t=s.render:ImportFileAsTexture2D(s.pawn,s.dir.."\\Art\\"..file)
    assert(valid(t),"cannot import "..file)
    s.textures[name]=t
    return t
end
local function sprite(s,name,x,y,size,z)
    local n=s.used+1
    s.used=n
    local item=s.pool[n]
    if not item then
        local img=widget(s,"Image")
        img:SetVisibility(3)
        item={img=img,slot=put(s.board,img,0,0,size,size,z)}
        s.pool[n]=item
    end
    if item.hidden then item.img:SetVisibility(3); item.hidden=false end
    if item.name~=name then item.img:SetBrushFromTexture(tex(s,name),false); item.name=name end
    if item.size~=size then item.slot:SetSize(v(size,size)); item.size=size end
    if item.z~=z then item.slot:SetZOrder(z); item.z=z end
    item.slot:SetPosition(v(x-size/2,y-size/2))
end
local function bar(s,x,y,w,h,tint)
    local n=s.barsUsed+1
    s.barsUsed=n
    local item=s.bars[n]
    if not item then
        local b=widget(s,"Border")
        b:SetVisibility(3)
        item={b=b,slot=put(s.board,b,x,y,w,h,32)}
        s.bars[n]=item
    end
    if item.hidden then item.b:SetVisibility(3); item.hidden=false end
    if item.tint~=tint then item.b:SetBrushColor(tint); item.tint=tint end
    item.slot:SetPosition(v(x,y)); item.slot:SetSize(v(w,h))
end
function view.layout(s)
    local pixels=s.layout:GetViewportSize(s.pawn)
    local dpi=s.layout:GetViewportScale(s.pawn)
    assert(dpi>0 and pixels.X>0 and pixels.Y>0,"invalid viewport size")
    local w,h=pixels.X/dpi,pixels.Y/dpi
    if s.width==w and s.height==h then return end
    s.width,s.height=w,h
    s.scale=math.min(w/620,h/765)
    s.x,s.y=(w-620*s.scale)/2,(h-765*s.scale)/2
    s.boardSlot:SetPosition(v(s.x,s.y))
    s.board:SetRenderScale(v(s.scale,s.scale))
end
function view.draw(s,p,left,paused,vipHold,notice)
    local w=p.world
    s.used,s.barsUsed=0,0
    for i,c in ipairs(w.cards) do
        local reward=model.rewardInfo(c.reward)
        local x=(i==1 and 76 or 226)
        write(s,s.cardNames[i],reward.short)
        write(s,s.cardTypes[i],reward.kind)
        write(s,s.cardHP[i],tostring(math.ceil(c.hp)))
        sprite(s,reward.name,x,286,64,22)
        bar(s,x-32,378,64*c.hp/c.max,3,gold)
    end
    for _,e in ipairs(w.enemies) do
        local size=e.tribe=="boss" and 103 or e.tribe=="elite" and 80 or 56
        sprite(s,model.ENEMIES[e.tribe][e.unit+1],e.x,e.y,size,24)
        bar(s,e.x-size*.28,e.y-size*.5-4,size*.56*e.hp/e.max,3,rust)
    end
    for i,a in ipairs(w.allies) do
        local pos=model.formation(w,i-1)
        local ally=model.ALLIES[a.unit+1]
        sprite(s,ally.name,pos.x,pos.y,42,28)
        bar(s,pos.x-11,pos.y+21,22*a.hp/ally.hp,2,gold)
    end
    sprite(s,model.HERO,w.x,675,74,26)
    bar(s,w.x-22,714,44*w.hp/100,3,rust)
    for _,shot in ipairs(w.shots) do
        local width=math.min(18,shot.size)
        bar(s,shot.x-width/2,shot.y-7,width,15,shot.friendly and gold or ink)
    end
    for _,shot in ipairs(w.hostile) do bar(s,shot.x-3,shot.y-4,6,9,rust) end
    for i=s.used+1,#s.pool do
        local item=s.pool[i]
        if not item.hidden then item.img:SetVisibility(1); item.hidden=true end
    end
    for i=s.barsUsed+1,#s.bars do
        local item=s.bars[i]
        if not item.hidden then item.b:SetVisibility(1); item.hidden=true end
    end
    local gear=0
    for _,n in ipairs(w.weapons) do gear=gear+n end
    write(s,s.timer,paused and "已暂停" or string.format("00:%02d",left))
    write(s,s.hud,string.format("气血 %d       队友 %d       武器 %d       击破 %d",math.ceil(w.hp),#w.allies,gear,w.kills))
    write(s,s.noticeLabel,notice or "")
    local key
    if not paused then key=padKey(s) end
    if key~=s.hintKey then
        if key then write(s,s.vipHint,"长按 "..key) end
        s.hintBox:SetVisibility(key and 3 or 1)
        s.hintKey=key
    end
    s.holdBar:SetSize(v(208*math.min(1,vipHold/.8),3))
end
function view.mount(s)
    s.ui=asset("/Script/UMG.Default__WidgetBlueprintLibrary")
    s.layout=asset("/Script/UMG.Default__WidgetLayoutLibrary")
    s.render=asset("/Script/Engine.Default__KismetRenderingLibrary")
    s.text=asset("/Script/Engine.Default__KismetTextLibrary")
    s.focus=asset("/Script/ProjectPBZ.Default__PBZBlueprintFunctionLibrary")
    s.host=s.ui:Create(s.pawn,asset("/Script/LevelSequence.LevelSequenceBurnIn"),s.pc)
    assert(valid(s.host),"cannot create viewport host")
    s.host.bIsFocusable=false
    s.host.bAutomaticallyRegisterInputOnConstruction=false
    s.tree=s.host.WidgetTree
    if not valid(s.tree) then
        s.tree=StaticConstructObject(asset("/Script/UMG.WidgetTree"),s.host)
        s.host.WidgetTree=s.tree
    end
    local root=widget(s,"CanvasPanel")
    s.tree.RootWidget=root
    s.board=widget(s,"CanvasPanel")
    s.board:SetRenderTransformPivot(v(0,0)); s.board:SetClipping(1)
    s.boardSlot=put(root,s.board,0,0,620,765,0)
    s.pool,s.bars,s.textures={},{},{}
    local ground=widget(s,"Image")
    ground:SetBrushFromTexture(tex(s,"ground"),false)
    ground:SetVisibility(3); put(s.board,ground,0,0,620,765,0)
    s.cardNames,s.cardHP,s.cardTypes={},{},{}
    for i,x in ipairs({76,226}) do
        box(s,x-53,231,106,124,10,ink)
        s.cardTypes[i]=caption(s,x-53,234,106,26,35,13,gold,"")
        s.cardNames[i]=caption(s,x-59,322,118,29,35,15,light,"")
        s.cardHP[i]=caption(s,x-50,354,100,24,35,15,ink,"")
    end
    box(s,249,0,122,59,60,ink)
    caption(s,249,3,122,19,70,12,gold,"广告剩余")
    s.timer=caption(s,249,21,122,37,70,24,light,"")
    s.vip=vipButton(s)
    s.holdBar=box(s,206,106,0,3,91,gold)
    s.hintBox=widget(s,"Border")
    s.hintBox:SetBrushColor(ink)
    s.hintBox:SetVisibility(1)
    s.vipHint={widget=label(s,11,light)}
    s.hintBox:AddChild(s.vipHint.widget)
    s.hintBox:SetVerticalAlignment(2) -- Center
    put(s.board,s.hintBox,420,74,84,24,90)
    s.close=button(s,514,7,100,35,"关闭广告",ink)
    s.pause=button(s,6,7,86,35,"暂停 / 继续",ink)
    box(s,0,734,620,31,60,ink)
    s.hud=caption(s,0,737,620,28,70,15,light,"")
    s.noticeLabel=caption(s,12,593,596,36,70,16,ink,"")
    view.layout(s)
    s.host:AddToViewport(10000)
    assert(s.host:IsInViewport(),"ad was not added to the viewport")
    s.cursor=s.pc.bShowMouseCursor
    local gameplay=asset("/Script/Engine.Default__GameplayStatics")
    s.capture=gameplay:GetViewportMouseCaptureMode(s.pawn)
    s.gameplay=gameplay
    local subsystems=asset("/Script/Engine.Default__SubsystemBlueprintLibrary")
    s.commonInput=subsystems:GetLocalPlayerSubSystemFromPlayerController(s.pc,asset("/Script/CommonInput.CommonInputSubsystem"))
    s.devices=subsystems:GetEngineSubsystem(asset("/Script/Engine.InputDeviceSubsystem"))
    local router=subsystems:GetLocalPlayerSubSystemFromPlayerController(s.pc,asset("/Script/ProjectPBZ.PBZUIActionRouterBase"))
    if valid(router) then
        s.mode=router:GetActiveInputMode()
        s.previousFocus=router:GetActiveWidget()
    end
    s.inputOwned=true
    -- Release any high-precision mouse capture left over from combat. Slate
    -- handles clicks; unhandled keys and axes continue to reach PlayerInput.
    s.ui:SetInputMode_GameAndUIEx(s.pc,nil,3,false,false)
    gameplay:SetViewportMouseCaptureMode(s.pawn,0)
    s.pc.bShowMouseCursor=true
    s.ui:SetFocusToGameViewport()
end
function view.unmount(s)
    if valid(s.host) then s.host:RemoveFromParent() end
    if s.inputOwned and valid(s.pc) and valid(s.pawn) then
        local previous=valid(s.previousFocus) and s.previousFocus or nil
        if s.mode==0 then s.ui:SetInputMode_UIOnlyEx(s.pc,previous,3,true)
        elseif s.mode==2 then s.ui:SetInputMode_GameAndUIEx(s.pc,previous,3,false,true)
        else s.ui:SetInputMode_GameOnly(s.pc,true) end
        s.pc.bShowMouseCursor=s.cursor
        s.gameplay:SetViewportMouseCaptureMode(s.pawn,s.capture)
    end
    s.inputOwned=false
end
return view
