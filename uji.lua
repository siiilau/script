--========================================================
--  SILAU HUB v1.1 — MOVEMENT + VISUAL + HUD (AUDITED)
--  Keybind:
--   F    : buka/tutup GUI
--   Q    : Speed OFF→WALK(17.25)→OFF
--   Q Q  : SPRINT (21.25-23.00) | Q saat sprint = OFF semua
--   Shift: tahan = sprint sementara
--   T    : Auto Brightness
--   C    : Swim mode (Normal→Katak+20%→Tegak)
--   X    : Reveal Invisible Wall
--   Z    : Info player (nametag)
--   K K  : HAPUS SCRIPT (konfirmasi 2 detik)
--========================================================

local VERSI = "1.1"
local RUNNING = true

-- [1] PENGAMAN & SERVICES -------------------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then warn("[SilauHub] Harus di CLIENT!") return end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser        = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
if not LocalPlayer then warn("[SilauHub] LocalPlayer belum ada.") return end

-- [2] KONFIGURASI ----------------------------------------------------
local KEY_GUI, KEY_Q, KEY_T, KEY_C, KEY_X, KEY_Z, KEY_K =
    Enum.KeyCode.F, Enum.KeyCode.Q, Enum.KeyCode.T,
    Enum.KeyCode.C, Enum.KeyCode.X, Enum.KeyCode.Z, Enum.KeyCode.K
local SPRINT_KEYS = {Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift}

local WALK_ON, WALK_OFF      = 17.25, 17.00
local SPRINT_MIN, SPRINT_MAX = 21.25, 23.00
local JUMP_ON_MIN, JUMP_ON_MAX, JUMP_OFF = 61.25, 63.50, 51.25
local SWIM_BOOST = 0.20
local NEGATE_MAX = 0.25
local ROLL_MIN   = 25

local Warna = {
    Ungu=Color3.fromRGB(124,58,237), Ungu2=Color3.fromRGB(167,139,250),
    UnguMuda=Color3.fromRGB(237,233,254), Biru=Color3.fromRGB(37,99,235),
    Biru2=Color3.fromRGB(59,130,246), BiruMuda=Color3.fromRGB(219,234,254),
    Pink=Color3.fromRGB(236,72,153), Pink2=Color3.fromRGB(251,207,232),
    Hitam=Color3.fromRGB(12,10,20), Hitam2=Color3.fromRGB(22,18,38),
    Putih=Color3.fromRGB(255,255,255), PutihLap=Color3.fromRGB(250,250,255),
    AbuMuda=Color3.fromRGB(243,242,250), AbuItem=Color3.fromRGB(246,245,252),
    TeksGelap=Color3.fromRGB(28,24,46), AbuTeks=Color3.fromRGB(130,125,155),
    AbuGelap=Color3.fromRGB(160,155,185), Merah=Color3.fromRGB(239,68,68),
    MerahMuda=Color3.fromRGB(254,202,202), Hijau=Color3.fromRGB(34,197,94),
    HijauMuda=Color3.fromRGB(187,247,208), Kuning=Color3.fromRGB(250,204,21),
}

-- [3] STATE ----------------------------------------------------------
local mv   = {walk=false, sprint=false, shift=false, jump=false, dj=false,
              fall=false, sprintVal=22.1, jumpVal=62.0}
local vis  = {esp=false, tag=false, cross=false, crossStyle=0, moon=false,
              hideP=false, hideFx=false, bright=false, swim=0, wall=false}
local hudOn = {afk=true}
local alarm = {aktif=false, akhir=0}
local bersihMode = false

local espFolder, tagFolder = {}, {}
local hiddenParts, hiddenFx = {}, {}
local wallParts, pins = {}, {}
local myGyro = nil
local canDouble = true
local original = {walk=16, jump=50, useJP=true}
local origLight = nil
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- [4] FONT & HELPER --------------------------------------------------
local FONT_OK = pcall(function()
    return Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Regular)
end)
local cacheFont = {}
local function fnt(k)
    if cacheFont[k] then return cacheFont[k] end
    local v
    if FONT_OK then
        local fam={judul="rbxasset://fonts/families/Bangers.json",bold="rbxasset://fonts/families/Montserrat.json",semi="rbxasset://fonts/families/Montserrat.json",med="rbxasset://fonts/families/Montserrat.json",reg="rbxasset://fonts/families/Montserrat.json"}
        local wts={judul=Enum.FontWeight.Regular,bold=Enum.FontWeight.Bold,semi=Enum.FontWeight.SemiBold,med=Enum.FontWeight.Medium,reg=Enum.FontWeight.Regular}
        v=Font.new(fam[k],wts[k])
    else
        local legacy={judul=Enum.Font.Bangers,bold=Enum.Font.GothamBold,semi=Enum.Font.GothamSemibold,med=Enum.Font.GothamMedium,reg=Enum.Font.Gotham}
        v=legacy[k]
    end
    cacheFont[k]=v return v
end
local TEKS_CLASS={TextLabel=true,TextButton=true,TextBox=true}
local rnd = math.random

local function buat(class,props,parent)
    local obj=Instance.new(class)
    for k,v in pairs(props) do
        if k=="FontFace" and TEKS_CLASS[class] and not FONT_OK then obj.Font=v else obj[k]=v end
    end
    obj.Parent=parent return obj
end
local function tween(obj,info,props)
    local t=TweenService:Create(obj,info,props) t:Play() return t
end
local SND_PING="rbxasset://sounds/electronicpingshort.wav"
local SND_SNAP="rbxasset://sounds/snap.mp3"

-- [5] SCREENGUI ------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name="SilauHubGui" screenGui.ResetOnSpawn=false
screenGui.DisplayOrder=9997 screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
pcall(function() screenGui.OnTopOfCoreBlur=true end)

local kandidat={}
pcall(function() if gethui then table.insert(kandidat,gethui()) end end)
pcall(function() table.insert(kandidat,game:GetService("CoreGui")) end)
pcall(function() table.insert(kandidat,LocalPlayer:WaitForChild("PlayerGui")) end)
for _,t in ipairs(kandidat) do
    pcall(function() local l=t:FindFirstChild("SilauHubGui") if l then l:Destroy() end end)
end
local terpasang=false
for _,t in ipairs(kandidat) do
    local o=pcall(function() screenGui.Parent=t end)
    if o and screenGui.Parent==t then terpasang=true break end
end
if not terpasang then warn("[SilauHub] Gagal pasang GUI.") return end

local function bunyi(id,vol,pitch)
    local s=Instance.new("Sound") s.SoundId=id s.Volume=vol or 0.3
    s.PlaybackSpeed=pitch or 1 s.Parent=screenGui s:Play()
    task.delay(3,function() s:Destroy() end)
end

-- [6] EFEK -----------------------------------------------------------
local function ledSweep(inst,base,bandA,bandB,dur)
    local g=buat("UIGradient",{Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,base),ColorSequenceKeypoint.new(0.4,base),
        ColorSequenceKeypoint.new(0.47,bandA),ColorSequenceKeypoint.new(0.54,bandB),
        ColorSequenceKeypoint.new(0.61,base),ColorSequenceKeypoint.new(1,base)}),
        Offset=Vector2.new(-1,0)},inst)
    tween(g,TweenInfo.new(dur or 2.4,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1),{Offset=Vector2.new(1,0)})
end
local function buatDraggable(handle,target,onClickIfClick)
    local drag,ds,sp,jarak=false,nil,nil,0
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag,ds,sp,jarak=true,inp.Position,target.Position,0
        end
    end)
    handle.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            if drag and onClickIfClick and jarak<6 then onClickIfClick() end
            drag=false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds
            jarak=math.abs(d.X)+math.abs(d.Y)
            target.Position=UDim2.new(sp.X.Scale,math.round(sp.X.Offset+d.X),sp.Y.Scale,math.round(sp.Y.Offset+d.Y))
        end
    end)
end

-- [7] KARAKTER -------------------------------------------------------
local function getMy()
    local c=LocalPlayer.Character
    if not c then return nil end
    return c, c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end
local function refreshRay()
    local c=LocalPlayer.Character
    if c then rayParams.FilterDescendantsInstances={c} end
end
refreshRay()

local _, myHum0 = getMy()
if myHum0 then
    original.walk=myHum0.WalkSpeed
    original.jump=myHum0.JumpPower
    original.useJP=myHum0.UseJumpPower
end

-- [8] HUD CONTAINER + NOTIF ------------------------------------------
local hudFrame = buat("Frame",{
    Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,
},screenGui)

local notifList = buat("Frame",{
    AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,12),
    Size=UDim2.new(0,250,0,400),BackgroundTransparency=1,BorderSizePixel=0,
},hudFrame)
buat("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,
    HorizontalAlignment=Enum.HorizontalAlignment.Right},notifList)
local notifOrder=0

local function notif(teks,warnaAksen)
    notifOrder+=1
    local n=buat("Frame",{
        Size=UDim2.new(1,0,0,28),BackgroundColor3=Warna.Hitam2,
        BackgroundTransparency=0.15,BorderSizePixel=0,LayoutOrder=notifOrder,
    },notifList)
    buat("UICorner",{CornerRadius=UDim.new(0,8)},n)
    buat("UIStroke",{Color=warnaAksen or Warna.Ungu,Thickness=1,Transparency=0.4},n)
    buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,0),
        Size=UDim2.new(1,-16,1,0),FontFace=fnt("semi"),Text=teks,
        TextColor3=Warna.Putih,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd},n)
    task.delay(3.5,function()
        if n.Parent then
            tween(n,TweenInfo.new(0.3),{BackgroundTransparency=1})
            task.delay(0.35,function() n:Destroy() end)
        end
    end)
    local c=0
    for _,ch in ipairs(notifList:GetChildren()) do
        if ch:IsA("GuiObject") then c+=1 end
    end
    if c>6 then
        for _,ch in ipairs(notifList:GetChildren()) do
            if ch:IsA("GuiObject") then ch:Destroy() break end
        end
    end
end

-- [9] BANGUN PANEL UTAMA ---------------------------------------------
local root = buat("Frame",{
    Size=UDim2.fromOffset(360,540),Position=UDim2.new(0.5,0,0.1,0),
    AnchorPoint=Vector2.new(0.5,0),BackgroundTransparency=1,BorderSizePixel=0,
    Visible=false,
},screenGui)
local panelScale=buat("UIScale",{Scale=1},root)

local outer=buat("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Warna.Hitam,
    BorderSizePixel=0},root)
buat("UICorner",{CornerRadius=UDim.new(0,16)},outer)
local borderStroke=buat("UIStroke",{Color=Warna.Pink,Thickness=3},outer)
local borderGrad=buat("UIGradient",{Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Warna.Pink),ColorSequenceKeypoint.new(0.25,Warna.Ungu),
    ColorSequenceKeypoint.new(0.5,Warna.Biru2),ColorSequenceKeypoint.new(0.75,Warna.Pink),
    ColorSequenceKeypoint.new(1,Warna.Ungu2)})},borderStroke)
tween(borderGrad,TweenInfo.new(4.5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1),{Rotation=360})

local panel=buat("Frame",{Size=UDim2.new(1,-10,1,-10),Position=UDim2.new(0,5,0,5),
    BackgroundColor3=Warna.PutihLap,BorderSizePixel=0},outer)
buat("UICorner",{CornerRadius=UDim.new(0,11)},panel)
buat("UIStroke",{Color=Warna.Pink2,Thickness=1,Transparency=0.35},panel)
ledSweep(panel,Warna.PutihLap,Warna.Putih,Warna.Pink2,5)

local header=buat("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=Warna.Hitam2,
    BorderSizePixel=0,Active=true},panel)
buat("UICorner",{CornerRadius=UDim.new(0,11)},header)
buat("Frame",{Size=UDim2.new(1,0,0,11),Position=UDim2.new(0,0,0,33),
    BackgroundColor3=Warna.Hitam2,BorderSizePixel=0},panel)

local title=buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,0),
    Size=UDim2.new(1,-100,1,0),FontFace=fnt("judul"),Text="⚡ SILAU HUB ⚡",
    TextColor3=Warna.Putih,TextSize=20,TextXAlignment=Enum.TextXAlignment.Left},header)
ledSweep(title,Warna.Putih,Warna.Pink2,Warna.Biru2,2.2)

local helpBtn=buat("TextButton",{Size=UDim2.fromOffset(26,26),
    Position=UDim2.new(1,-70,0.5,-13),BackgroundColor3=Warna.Hitam,
    BorderSizePixel=0,FontFace=fnt("bold"),Text="?",TextColor3=Warna.Pink2,
    TextSize=15,AutoButtonColor=false},header)
buat("UICorner",{CornerRadius=UDim.new(0,9)},helpBtn)
buat("UIStroke",{Color=Warna.Pink,Thickness=1,Transparency=0.3},helpBtn)

local minBtn=buat("TextButton",{Size=UDim2.fromOffset(26,26),
    Position=UDim2.new(1,-36,0.5,-13),BackgroundColor3=Warna.Hitam,
    BorderSizePixel=0,FontFace=fnt("bold"),Text="–",TextColor3=Warna.Putih,
    TextSize=17,AutoButtonColor=false},header)
buat("UICorner",{CornerRadius=UDim.new(0,9)},minBtn)
buat("UIStroke",{Color=Warna.Ungu,Thickness=1,Transparency=0.3},minBtn)

local tabBar=buat("Frame",{Position=UDim2.new(0,10,0,50),Size=UDim2.new(1,-20,0,30),
    BackgroundTransparency=1,BorderSizePixel=0},panel)
buat("UIListLayout",{Padding=UDim.new(0,5),FillDirection=Enum.FillDirection.Horizontal},tabBar)
local tabBtns={}
for i,nm in ipairs({"🏃 MOVEMENT","👁 VISUAL","🖥 HUD"}) do
    local b=buat("TextButton",{Size=UDim2.new(1/3,-4,1,0),
        BackgroundColor3=i==1 and Warna.Hitam2 or Warna.AbuItem,BorderSizePixel=0,
        FontFace=fnt("bold"),Text=nm,
        TextColor3=i==1 and Warna.Putih or Warna.TeksGelap,TextSize=11,
        AutoButtonColor=false,LayoutOrder=i},tabBar)
    buat("UICorner",{CornerRadius=UDim.new(0,8)},b)
    tabBtns[i]={btn=b,
        stroke=buat("UIStroke",{Color=i==1 and Warna.Pink or Warna.AbuTeks,
        Thickness=1,Transparency=i==1 and 0 or 0.6},b)}
end

local tabFrames={}
for i=1,3 do
    local sf=buat("ScrollingFrame",{
        Position=UDim2.new(0,10,0,86),Size=UDim2.new(1,-20,1,-140),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,
        ScrollBarImageColor3=Warna.Pink,ScrollingDirection=Enum.ScrollingDirection.Y,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        Visible=i==1,
    },panel)
    buat("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},sf)
    tabFrames[i]=sf
end

local helpPanel=buat("Frame",{Position=UDim2.new(0,6,0,50),
    Size=UDim2.new(1,-12,1,-90),BackgroundColor3=Warna.Hitam2,
    BorderSizePixel=0,Visible=false,ZIndex=50},panel)
buat("UICorner",{CornerRadius=UDim.new(0,10)},helpPanel)
buat("UIStroke",{Color=Warna.Pink,Thickness=1,Transparency=0.4,ZIndex=50},helpPanel)
buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,8),
    Size=UDim2.new(1,-24,1,-50),FontFace=fnt("med"),
    Text="F buka/tutup  •  Q speed walk  •  Q Q sprint  •  Shift sprint sementara\nT auto brightness  •  C swim mode  •  X invisible wall  •  Z info player\nK K (dobel) = HAPUS SCRIPT  •  semua toggle juga ada di tab\n\nSpeed: OFF 17.00 | WALK 17.25 | SPRINT 21.25-23.00 (acak)\nJump: OFF 51.25 | ON 61.25-63.50 (acak)\nFall Assist: pantul kena atap • slide lereng • roll mendarat •\ndash jatuh dalam. Damage ≤25% darah di-no-kan, besar dibiarkan.",
    TextColor3=Warna.UnguMuda,TextSize=10,TextWrapped=true,
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=51},helpPanel)
local helpClose=buat("TextButton",{Size=UDim2.new(1,-24,0,24),
    Position=UDim2.new(0,12,1,-32),BackgroundColor3=Warna.Pink,
    BorderSizePixel=0,FontFace=fnt("bold"),Text="✕ TUTUP",
    TextColor3=Warna.Putih,TextSize=12,AutoButtonColor=false,ZIndex=51},helpPanel)
buat("UICorner",{CornerRadius=UDim.new(0,8)},helpClose)

local footer=buat("Frame",{Size=UDim2.new(1,0,0,26),Position=UDim2.new(0,0,1,-26),
    BackgroundColor3=Warna.Hitam2,BorderSizePixel=0},panel)
buat("UICorner",{CornerRadius=UDim.new(0,11)},footer)
buat("Frame",{Size=UDim2.new(1,0,0,11),Position=UDim2.new(0,0,1,-37),
    BackgroundColor3=Warna.Hitam2,BorderSizePixel=0},panel)
ledSweep(footer,Warna.Hitam2,Warna.Pink,Warna.Ungu,3.2)
buat("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
    FontFace=fnt("judul"),Text="⚡ S I L A U   H U B ⚡",TextColor3=Warna.Putih,
    TextSize=12},footer)

local icon=buat("Frame",{Size=UDim2.fromOffset(36,36),Position=UDim2.new(0,10,1,-10),
    AnchorPoint=Vector2.new(0,1),BackgroundColor3=Warna.Hitam,BorderSizePixel=0,
    Visible=false},screenGui)
buat("UICorner",{CornerRadius=UDim.new(0,10)},icon)
buat("UIStroke",{Color=Warna.Pink,Thickness=2},icon)
local iconScale=buat("UIScale",{Scale=1},icon)
buat("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
    FontFace=fnt("judul"),Text="⚡",TextColor3=Warna.Pink2,TextSize=18},icon)

-- [10] FACTORY BARIS -------------------------------------------------
local orderCounter={0,0,0}

local function rowToggle(tabIdx,teks,hint,initial,cb)
    orderCounter[tabIdx]+=1
    local sf=tabFrames[tabIdx]
    local row=buat("Frame",{Size=UDim2.new(1,-6,0,28),
        BackgroundColor3=Warna.AbuItem,BorderSizePixel=0,
        LayoutOrder=orderCounter[tabIdx]},sf)
    buat("UICorner",{CornerRadius=UDim.new(0,8)},row)
    buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,0),
        Size=UDim2.new(1,-80,1,0),FontFace=fnt("semi"),
        Text=hint and (teks.."  ["..hint.."]") or teks,
        TextColor3=Warna.TeksGelap,TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd},row)
    local sw=buat("TextButton",{Size=UDim2.fromOffset(52,20),
        Position=UDim2.new(1,-60,0.5,-10),BackgroundColor3=initial and Warna.Hijau or Warna.Merah,
        BackgroundTransparency=0.75,BorderSizePixel=0,FontFace=fnt("bold"),
        Text=initial and "ON" or "OFF",
        TextColor3=initial and Warna.HijauMuda or Warna.MerahMuda,
        TextSize=10,AutoButtonColor=false},row)
    buat("UICorner",{CornerRadius=UDim.new(0,6)},sw)
    buat("UIStroke",{Color=initial and Warna.Hijau or Warna.Merah,Thickness=1,Transparency=0.45},sw)
    local obj={state=initial}
    function obj.set(v,noCb)
        obj.state=v
        sw.Text=v and "ON" or "OFF"
        sw.BackgroundColor3=v and Warna.Hijau or Warna.Merah
        sw.BackgroundTransparency=v and 0.75 or 0.82
        sw.TextColor3=v and Warna.HijauMuda or Warna.MerahMuda
        if not noCb then cb(v) end
    end
    sw.MouseButton1Click:Connect(function()
        bunyi(SND_PING,0.25,obj.state and 0.9 or 1.15)
        obj.set(not obj.state)
    end)
    return obj
end

local function rowAksi(tabIdx,teks,cb,h)
    orderCounter[tabIdx]+=1
    local sf=tabFrames[tabIdx]
    local b=buat("TextButton",{Size=UDim2.new(1,-6,0,h or 28),
        BackgroundColor3=Warna.Putih,BorderSizePixel=0,
        FontFace=fnt("bold"),Text=teks,TextColor3=Warna.Putih,TextSize=11,
        AutoButtonColor=false,LayoutOrder=orderCounter[tabIdx]},sf)
    buat("UICorner",{CornerRadius=UDim.new(0,8)},b)
    ledSweep(b,Warna.Ungu,Warna.Putih,Warna.Pink,2.6)
    b.MouseButton1Click:Connect(function() cb(b) end)
    return b
end

local function rowInfo(tabIdx,teks,h)
    orderCounter[tabIdx]+=1
    local sf=tabFrames[tabIdx]
    return buat("TextLabel",{Size=UDim2.new(1,-6,0,h or 22),
        BackgroundTransparency=1,BorderSizePixel=0,FontFace=fnt("reg"),
        Text=teks,TextColor3=Warna.AbuTeks,TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,
        LayoutOrder=orderCounter[tabIdx]},sf)
end

-- [11] TAB 1 : MOVEMENT ---------------------------------------------
rowInfo(1,"🚶 OFF 17.00 → ON 17.25 | Sprint QQ: 21.25-23.00 acak")

local tglWalk = rowToggle(1,"🚶 Walk Speed 17.25","Q",false,function(v)
    mv.walk=v
    notif(v and "🚶 WalkSpeed 17.25 ON" or "🚶 WalkSpeed normal (17.00)",Warna.Biru)
end)

local lblSprint = rowInfo(1,"🏃 Sprint: OFF (Q-Q untuk aktifkan)")
local tglSprint = rowToggle(1,"🏃 Sprint 21.25-23.00","Q Q",false,function(v)
    mv.sprint=v
    if v then
        mv.sprintVal=rnd(SPRINT_MIN*100,SPRINT_MAX*100)/100
        lblSprint.Text="🏃 Sprint aktif: "..string.format("%.2f",mv.sprintVal).." stud/s"
    else
        lblSprint.Text="🏃 Sprint: OFF (Q-Q untuk aktifkan)"
    end
    notif(v and ("🏃 SPRINT ON — "..string.format("%.2f",mv.sprintVal)) or "🏃 Sprint OFF semua",Warna.Pink)
end)

local tglJump = rowToggle(1,"🦘 Jump Power 61.25-63.50",nil,false,function(v)
    mv.jump=v
    local _,hum=getMy()
    if hum then
        pcall(function()
            hum.UseJumpPower=true
            hum.JumpPower = v and mv.jumpVal or JUMP_OFF
        end)
    end
    notif(v and "🦘 Jump tinggi ON" or "🦘 Jump normal (51.25)",Warna.Ungu)
end)

rowToggle(1,"🪂 Double Jump (1x ekstra)",nil,false,function(v)
    mv.dj=v canDouble=true
    notif(v and "🪂 Double Jump ON" or "🪂 Double Jump OFF",Warna.Biru2)
end)

rowToggle(1,"💨 Smart Fall Assist",nil,false,function(v)
    mv.fall=v
    notif(v and "💨 Fall Assist ON — pantul/slide/roll/dash" or "💨 Fall Assist OFF",Warna.Hijau)
end)
rowInfo(1,"💨 Pantul kena atap • slide di lereng • roll mendarat rata •\ndash kalau jatuh dalam. Damage ≤25% darah otomatis di-no-kan.")

-- [12] TAB 2 : VISUAL -----------------------------------------------
local cam = workspace.CurrentCamera
local crossFrame = nil

local function warnaUntuk(p)
    if p.Team then return p.TeamColor.Color end
    return Warna.Ungu
end

-- FIX #4: ESP pasang ulang otomatis setelah respawn
local tglESP = rowToggle(2,"👁 ESP / Highlight","warna tim",false,function(v)
    vis.esp=v
    if not v then
        for _,d in pairs(espFolder) do pcall(function() d:Destroy() end) end
        table.clear(espFolder)
    end
    notif(v and "👁 ESP ON" or "👁 ESP OFF",Warna.Ungu)
end)

-- FIX #3: nametag pakai referensi label eksplisit
local tglTag = rowToggle(2,"🏷 Nametag + Info Player","Z",false,function(v)
    vis.tag=v
    if not v then
        for _,t in pairs(tagFolder) do pcall(function() t.bb:Destroy() end) end
        table.clear(tagFolder)
    end
    notif(v and "🏷 Info player ON" or "🏷 Info player OFF",Warna.Biru)
end)

-- FIX #2: crosshair ditulis ulang bersih
local function bangunCrosshair()
    if crossFrame then pcall(function() crossFrame:Destroy() end) crossFrame=nil end
    if not vis.cross then return end
    crossFrame=buat("Frame",{AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(0,0),
        BackgroundTransparency=1,BorderSizePixel=0,ZIndex=900},hudFrame)
    if vis.crossStyle==1 then -- dot
        local d=buat("Frame",{AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(6,6),
            BackgroundColor3=Warna.Putih,BorderSizePixel=0,ZIndex=901},crossFrame)
        buat("UICorner",{CornerRadius=UDim.new(1,0)},d)
        buat("UIStroke",{Color=Warna.Hitam,Thickness=1,Transparency=0.5},d)
    elseif vis.crossStyle==2 then -- cross +
        buat("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(20,2),BackgroundColor3=Warna.Putih,
            BorderSizePixel=0,ZIndex=901},crossFrame)
        buat("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(2,20),BackgroundColor3=Warna.Putih,
            BorderSizePixel=0,ZIndex=901},crossFrame)
    else -- circle
        local c=buat("Frame",{AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(22,22),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=901},crossFrame)
        buat("UICorner",{CornerRadius=UDim.new(1,0)},c)
        buat("UIStroke",{Color=Warna.Putih,Thickness=2},c)
    end
end

local gayaNama={"OFF","Dot","Cross","Circle"}
local btnCross = rowAksi(2,"✛ Crosshair: OFF (klik = ganti)",function(b)
    vis.crossStyle=(vis.crossStyle+1)%4
    vis.cross=(vis.crossStyle>0)
    bangunCrosshair()
    b.Text="✛ Crosshair: "..gayaNama[vis.crossStyle+1].." (klik = ganti)"
    bunyi(SND_PING,0.25,1+vis.crossStyle*0.1)
    if vis.cross then notif("✛ Crosshair: "..gayaNama[vis.crossStyle+1],Warna.Pink) end
end,26)

rowToggle(2,"🚶‍♂️ Moonwalk",nil,false,function(v)
    vis.moon=v
    notif(v and "🕺 Moonwalk ON — hee-hee!" or "🕺 Moonwalk OFF",Warna.Pink)
end)

local tglHideP = rowToggle(2,"🫥 Hide Other Players",nil,false,function(v)
    vis.hideP=v
    if not v then
        for _,pt in ipairs(hiddenParts) do
            pcall(function() pt.LocalTransparencyModifier=0 end)
        end
        table.clear(hiddenParts)
    end
    notif(v and "🫥 Pemain lain disembunyikan (ESP tetap)" or "🫥 Pemain lain ditampilkan",Warna.Ungu)
end)

local tglHideFx = rowToggle(2,"✨ Hide All Effects (FPS boost)",nil,false,function(v)
    vis.hideFx=v
    if v then
        for _,d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke")
            or d:IsA("Sparkles") or d:IsA("Beam") or d:IsA("Trail") then
                if d.Enabled then
                    d.Enabled=false
                    table.insert(hiddenFx,d)
                end
            end
        end
        for _,d in ipairs(Lighting:GetChildren()) do
            if d:IsA("PostEffect") and d.Enabled then
                d.Enabled=false table.insert(hiddenFx,d)
            end
        end
        notif("✨ Efek dimatikan — FPS naik!",Warna.Hijau)
    else
        for _,d in ipairs(hiddenFx) do pcall(function() d.Enabled=true end) end
        table.clear(hiddenFx)
        notif("✨ Efek dikembalikan",Warna.Hijau)
    end
end)

origLight = {B=Lighting.Brightness,A=Lighting.Ambient,OA=Lighting.OutdoorAmbient}
local tglBright = rowToggle(2,"🌗 Auto Brightness","T",false,function(v)
    vis.bright=v
    if not v and origLight then
        Lighting.Brightness=origLight.B
        Lighting.Ambient=origLight.A
        Lighting.OutdoorAmbient=origLight.OA
    end
    notif(v and "🌗 Auto Brightness ON" or "🌗 Auto Brightness OFF",Warna.Kuning)
end)

-- FIX #1: swim pakai satu fungsi bersama (dipakai GUI & keybind C)
local namaSwim={"Normal","🐸 Katak (+20%)","🧍 Tegak"}
local siklusSwim
local btnSwim = rowAksi(2,"🏊 Swim Mode: Normal (C = ganti)",function(b)
    siklusSwim()
end,26)
siklusSwim = function()
    vis.swim=vis.swim%3+1
    btnSwim.Text="🏊 Swim Mode: "..namaSwim[vis.swim+1].." (C = ganti)"
    bunyi(SND_PING,0.25,1+vis.swim*0.15)
    notif("🏊 Swim: "..namaSwim[vis.swim+1],Warna.Biru)
end

local function scanWall()
    if not vis.wall then return end
    for _,d in ipairs(workspace:GetDescendants()) do
        if d:IsA("BasePart") and not wallParts[d]
        and d.Transparency>0.5 and d.CanCollide then
            wallParts[d]={t=d.Transparency,c=d.Color}
            pcall(function()
                d.Transparency=0.55
                d.Color=Warna.Ungu
            end)
        end
    end
end
local tglWall = rowToggle(2,"🧱 Reveal Invisible Wall","X",false,function(v)
    vis.wall=v
    if v then
        scanWall()
        notif("🧱 Invisible wall ditampilkan!",Warna.Ungu)
    else
        for d,o in pairs(wallParts) do
            pcall(function() d.Transparency=o.t d.Color=o.c end)
        end
        table.clear(wallParts)
        notif("🧱 Invisible wall disembunyikan",Warna.Ungu)
    end
end)
rowAksi(2,"🔍 Scan Ulang Invisible Wall",function()
    if vis.wall then
        scanWall()
        notif("🧱 Scan ulang selesai",Warna.Biru)
    else
        notif("⚠️ Nyalakan Reveal dulu",Warna.Kuning)
    end
end,24)

-- [13] TAB 3 : HUD ---------------------------------------------------
local function buatPanelJudul(pos,size,judul)
    local p=buat("Frame",{Position=pos,Size=size,BackgroundColor3=Warna.Hitam2,
        BackgroundTransparency=0.12,BorderSizePixel=0,Active=true},hudFrame)
    buat("UICorner",{CornerRadius=UDim.new(0,10)},p)
    buat("UIStroke",{Color=Warna.Pink,Thickness=1,Transparency=0.4},p)
    buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,3),
        Size=UDim2.new(1,-16,0,13),FontFace=fnt("semi"),Text=judul,
        TextColor3=Warna.Pink2,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},p)
    return p
end

local stPanel = buatPanelJudul(UDim2.new(0,12,0,120),UDim2.fromOffset(170,96),"📊 STATUS")
buatDraggable(stPanel,stPanel)
local stLbl = buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,18),
    Size=UDim2.new(1,-16,1,-24),FontFace=fnt("med"),Text="...",
    TextColor3=Warna.Putih,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top,LineHeight=1.15},stPanel)

local idPanel = buatPanelJudul(UDim2.new(0,12,0,12),UDim2.fromOffset(170,30),"🪪")
buatDraggable(idPanel,idPanel)
buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,14),
    Size=UDim2.new(1,-16,1,-18),FontFace=fnt("semi"),
    Text=LocalPlayer.DisplayName.." @"..LocalPlayer.Name,
    TextColor3=Warna.Putih,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},idPanel)

local clPanel = buatPanelJudul(UDim2.new(0,12,0,224),UDim2.fromOffset(170,86),"🕐 WAKTU & POSISI")
buatDraggable(clPanel,clPanel)
local clLbl = buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,18),
    Size=UDim2.new(1,-16,1,-24),FontFace=fnt("med"),Text="...",
    TextColor3=Warna.Putih,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top,LineHeight=1.2},clPanel)

local fpsPanel = buatPanelJudul(UDim2.new(0,12,0,318),UDim2.fromOffset(170,30),"📈")
buatDraggable(fpsPanel,fpsPanel)
local fpsLbl = buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,14),
    Size=UDim2.new(1,-16,1,-18),FontFace=fnt("semi"),Text="FPS ... | ... ms",
    TextColor3=Warna.HijauMuda,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},fpsPanel)

local svPanel = buatPanelJudul(UDim2.new(0,12,0,356),UDim2.fromOffset(170,68),"🖥 SERVER")
buatDraggable(svPanel,svPanel)
local svLbl = buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,18),
    Size=UDim2.new(1,-16,1,-24),FontFace=fnt("med"),Text="...",
    TextColor3=Warna.Putih,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top,LineHeight=1.2},svPanel)

rowToggle(3,"📊 Status sendiri",nil,true,function(v) stPanel.Visible=v end)
rowToggle(3,"🪪 Display & Username",nil,true,function(v) idPanel.Visible=v end)
rowToggle(3,"🕐 Tanggal, Jam, Koordinat",nil,true,function(v) clPanel.Visible=v end)
rowToggle(3,"📈 FPS + Ping",nil,true,function(v) fpsPanel.Visible=v end)
rowToggle(3,"🖥 Info Server",nil,true,function(v) svPanel.Visible=v end)
rowInfo(3,"Semua panel bisa digeser — drag judulnya.")

-- Alarm
orderCounter[3]+=1
local alarmRow=buat("Frame",{Size=UDim2.new(1,-6,0,30),BackgroundColor3=Warna.AbuItem,
    BorderSizePixel=0,LayoutOrder=orderCounter[3]},tabFrames[3])
buat("UICorner",{CornerRadius=UDim.new(0,8)},alarmRow)
buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,0),
    Size=UDim2.new(0,44,1,0),FontFace=fnt("semi"),Text="⏰ Alarm",
    TextColor3=Warna.TeksGelap,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},alarmRow)
local alarmBox=buat("TextBox",{Size=UDim2.fromOffset(40,20),
    Position=UDim2.new(0,54,0.5,-10),BackgroundColor3=Warna.Putih,
    BorderSizePixel=0,FontFace=fnt("bold"),PlaceholderText="mnt",
    Text="",TextColor3=Warna.Ungu,TextSize=11,ClearTextOnFocus=false},alarmRow)
buat("UICorner",{CornerRadius=UDim.new(0,6)},alarmBox)
buat("UIPadding",{PaddingLeft=UDim.new(0,5)},alarmBox)
local alarmBtn=buat("TextButton",{Size=UDim2.fromOffset(60,20),
    Position=UDim2.new(0,100,0.5,-10),BackgroundColor3=Warna.Hijau,
    BackgroundTransparency=0.75,BorderSizePixel=0,FontFace=fnt("bold"),
    Text="▶ SET",TextColor3=Warna.HijauMuda,TextSize=10,AutoButtonColor=false},alarmRow)
buat("UICorner",{CornerRadius=UDim.new(0,6)},alarmBtn)
buat("UIStroke",{Color=Warna.Hijau,Thickness=1,Transparency=0.45},alarmBtn)
local alarmStat=buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,166,0,0),
    Size=UDim2.new(1,-174,1,0),FontFace=fnt("reg"),Text="",
    TextColor3=Warna.AbuGelap,TextSize=9,TextXAlignment=Enum.TextXAlignment.Left},alarmRow)

alarmBtn.MouseButton1Click:Connect(function()
    if alarm.aktif then
        alarm.aktif=false alarmStat.Text="dibatalkan"
        notif("⏰ Alarm dibatalkan",Warna.Merah)
        return
    end
    local n=tonumber((alarmBox.Text:gsub("[^%d]","")))
    if n and n>=1 then
        alarm.aktif=true alarm.akhir=os.clock()+n*60
        alarmStat.Text="⏳ "..n.." menit"
        bunyi(SND_PING,0.3,1.2)
        notif("⏰ Alarm "..n.." menit diset!",Warna.Hijau)
    else
        alarmStat.Text="isi menit dulu"
    end
end)

-- FOV
orderCounter[3]+=1
local fovRow=buat("Frame",{Size=UDim2.new(1,-6,0,30),BackgroundColor3=Warna.AbuItem,
    BorderSizePixel=0,LayoutOrder=orderCounter[3]},tabFrames[3])
buat("UICorner",{CornerRadius=UDim.new(0,8)},fovRow)
buat("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,0),
    Size=UDim2.new(0,70,1,0),FontFace=fnt("semi"),Text="🔍 FOV Zoom",
    TextColor3=Warna.TeksGelap,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},fovRow)
local function fovBtn(teks,x,fn)
    local b=buat("TextButton",{Size=UDim2.fromOffset(38,20),
        Position=UDim2.new(0,x,0.5,-10),BackgroundColor3=Warna.Hitam2,
        BorderSizePixel=0,FontFace=fnt("bold"),Text=teks,
        TextColor3=Warna.Putih,TextSize=10,AutoButtonColor=false},fovRow)
    buat("UICorner",{CornerRadius=UDim.new(0,6)},b)
    b.MouseButton1Click:Connect(function() fn() bunyi(SND_PING,0.2,1) end)
end
fovBtn("– 5",84,function() cam.FieldOfView=math.clamp(cam.FieldOfView+5,50,120) end)
fovBtn("+ 5",126,function() cam.FieldOfView=math.clamp(cam.FieldOfView-5,50,120) end)
fovBtn("RESET",168,function() cam.FieldOfView=70 end)
rowInfo(3,"(– 5 = zoom out lebih jauh, + 5 = balik dekat)")

-- Pin lokasi
rowAksi(3,"📍 Pin Lokasi di Sini",function()
    local _,_,hrp=getMy()
    if not hrp then return end
    local pos=hrp.Position
    local pin=Instance.new("Part")
    pin.Shape=Enum.PartType.Ball pin.Size=Vector3.new(0.6,0.6,0.6)
    pin.Position=pos+Vector3.new(0,1,0)
    pin.Anchored=true pin.CanCollide=false pin.CanQuery=false
    pin.Material=Enum.Material.Neon pin.Color=Warna.Pink
    pin.Parent=workspace
    local bb=Instance.new("BillboardGui")
    bb.Size=UDim2.fromOffset(120,30) bb.StudsOffset=Vector3.new(0,2,0)
    bb.AlwaysOnTop=true bb.Parent=pin
    local tl=Instance.new("TextLabel")
    tl.Size=UDim2.new(1,0,1,0) tl.BackgroundTransparency=1
    tl.Font=Enum.Font.GothamBold tl.TextSize=10 tl.TextColor3=Warna.Pink2
    tl.Text=string.format("📍 %.0f, %.0f, %.0f",pos.X,pos.Y,pos.Z)
    tl.TextStrokeTransparency=0.4 tl.Parent=bb
    table.insert(pins,pin)
    bunyi(SND_PING,0.3,1.3)
    notif("📍 Pin dipasang (#"..#pins..")",Warna.Pink)
end)
rowAksi(3,"🗑️ Hapus Semua Pin",function()
    for _,p in ipairs(pins) do pcall(function() p:Destroy() end) end
    table.clear(pins)
    notif("🗑️ Semua pin dihapus",Warna.Merah)
end,24)

-- Anti-AFK (2 lapis)
rowToggle(3,"👻 Anti-AFK",nil,true,function(v)
    hudOn.afk=v
    notif(v and "👻 Anti-AFK ON" or "👻 Anti-AFK OFF",v and Warna.Hijau or Warna.Merah)
end)
task.spawn(function()
    while RUNNING do
        task.wait(240+rnd(0,60))
        if RUNNING and hudOn.afk then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- Mode bersih & tombol kill
rowAksi(3,"📸 Mode Bersih (sembunyikan semua HUD)",function()
    bersihMode=not bersihMode
    hudFrame.Visible=not bersihMode
    notif(bersihMode and "📸 Mode bersih — HUD tersembunyi" or "📸 HUD kembali",Warna.Kuning)
end,26)
rowAksi(3,"💥 HAPUS SCRIPT (sama dengan K-K)",function()
    notif("💥 Menghapus...",Warna.Merah)
    task.wait(0.4)
    killScript()
end,26)

-- [14] MOVEMENT LOOP -------------------------------------------------
local nextSprintRot=0
local nextJumpRot=0

RunService.Heartbeat:Connect(function()
    if not RUNNING then return end
    local c,hum,hrp=getMy()
    if not hum or not hrp then return end

    local now=os.clock()
    if mv.sprint and now>nextSprintRot then
        mv.sprintVal=rnd(SPRINT_MIN*100,SPRINT_MAX*100)/100
        nextSprintRot=now+rnd(12,20)
        lblSprint.Text="🏃 Sprint aktif: "..string.format("%.2f",mv.sprintVal).." stud/s"
    end
    if mv.jump and now>nextJumpRot then
        mv.jumpVal=rnd(JUMP_ON_MIN*100,JUMP_ON_MAX*100)/100
        nextJumpRot=now+rnd(8,14)
        pcall(function() hum.JumpPower=mv.jumpVal end)
    end

    local target
    if mv.sprint or mv.shift then target=mv.sprintVal
    elseif mv.walk then target=WALK_ON
    else target=WALK_OFF end
    if math.abs(hum.WalkSpeed-target)>0.01 then
        pcall(function() hum.WalkSpeed=target end)
    end
end)

-- Double jump
UserInputService.JumpRequest:Connect(function()
    if not RUNNING or not mv.dj or not canDouble then return end
    local _,hum=getMy()
    if hum and hum.FloorMaterial==Enum.Material.Air
    and hum:GetState()~=Enum.HumanoidStateType.Swimming then
        canDouble=false
        task.delay(0.15,function() end) -- pemisah biar tidak dobel-pemicu
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(c)
    refreshRay()
    canDouble=true
    task.spawn(function()
        local hum=c:WaitForChild("Humanoid",10)
        if hum then
            original.walk=hum.WalkSpeed
            original.jump=hum.JumpPower
            original.useJP=hum.UseJumpPower
        end
    end)
end)

-- [14B] SMART FALL ASSIST (FIX #5: pantul dideteksi SEBELUM menabrak)
local falling=false, fallTopY=0, healthBefore=0, bounced=false

RunService.Heartbeat:Connect(function()
    if not RUNNING or not mv.fall then return end
    local c,hum,hrp=getMy()
    if not hum or not hrp then return end
    local st=hum:GetState()
    local v=hrp.AssemblyLinearVelocity

    if st==Enum.HumanoidStateType.Freefall and v.Y<-5 then
        if not falling then
            falling=true fallTopY=hrp.Position.Y
            healthBefore=hum.Health bounced=false
        end
        fallTopY=math.max(fallTopY,hrp.Position.Y)
        local jarakJatuh=fallTopY-hrp.Position.Y

        -- 🏀 PANTUL: akan menabrak atap/obstacle (bukan tanah) saat jatuh kencang
        if not bounced and v.Y<-70 and jarakJatuh>30 then
            local r=workspace:Raycast(hrp.Position,Vector3.new(0,-25,0),rayParams)
            if r then
                -- cek: di bawah obstacle ada tanah lagi? kalau ya → r adalah atap
                local ground=workspace:Raycast(r.Position+Vector3.new(0,-3,0),
                    Vector3.new(0,-150,0),rayParams)
                if ground then
                    bounced=true
                    hrp.AssemblyLinearVelocity=Vector3.new(v.X*0.8,25,v.Z*0.8)
                    notif("🏀 PANTUL dari obstacle!",Warna.Kuning)
                    return
                end
            end
        end

        -- 💫 DASH: jatuh sangat dalam → lempar ke arah terbuka
        if v.Y<-60 and jarakJatuh>80 then
            local r=workspace:Raycast(hrp.Position,Vector3.new(0,-500,0),rayParams)
            if r and (hrp.Position.Y-r.Position.Y)>100 then
                local best
                for i=0,7 do
                    local ang=i*math.pi/4
                    local dir=Vector3.new(math.cos(ang),0,math.sin(ang))
                    if not workspace:Raycast(hrp.Position,dir*30,rayParams) then
                        best=dir break
                    end
                end
                if best then
                    hrp.AssemblyLinearVelocity=Vector3.new(best.X*55,v.Y*0.85,best.Z*55)
                    notif("💨 DASH menyelamatkan!",Warna.Biru)
                end
            end
        end

    elseif falling then
        falling=false
        local fallDist=fallTopY-hrp.Position.Y
        if fallDist>15 then
            local hit=workspace:Raycast(hrp.Position,Vector3.new(0,-8,0),rayParams)
            if hit then
                local n=hit.Normal
                if n.Y<0.85 and n.Y>0.2 then
                    -- 🌀 SLIDE lereng
                    local h=Vector3.new(n.X,0,n.Z)
                    if h.Magnitude>0.05 then
                        local downhill=(-h.Unit)*22
                        hrp.AssemblyLinearVelocity=Vector3.new(downhill.X,
                            hrp.AssemblyLinearVelocity.Y,downhill.Z)
                        notif("🌀 Slide lereng",Warna.Hijau)
                    end
                elseif n.Y>=0.85 and fallDist>=ROLL_MIN and fallDist<=90 then
                    -- 🌀 ROLL mendarat rata
                    local look=hrp.CFrame.LookVector
                    hrp.AssemblyLinearVelocity+=Vector3.new(look.X,0,look.Z)*16
                    notif("🌀 Roll mendarat!",Warna.Hijau)
                end
            end
            -- NEGATE damage kecil
            if fallDist<=90 and not bounced then
                task.delay(0.12,function()
                    local _,hum2=getMy()
                    if hum2 and RUNNING then
                        local lost=healthBefore-hum2.Health
                        if lost>0 and lost<=hum2.MaxHealth*NEGATE_MAX then
                            hum2.Health=math.min(hum2.MaxHealth,hum2.Health+lost)
                        end
                    end
                end)
            end
        end
    end
end)

-- [15] VISUAL LOOP ---------------------------------------------------
task.spawn(function()
    while RUNNING do
        task.wait(1)
        if vis.esp then
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    local h=espFolder[p]
                    if h and h.Parent==nil then h=nil espFolder[p]=nil end -- FIX #4
                    if not h then
                        local nh=Instance.new("Highlight")
                        nh.Name="SilauESP" nh.FillTransparency=0.75
                        nh.FillColor=warnaUntuk(p) nh.OutlineColor=warnaUntuk(p)
                        nh.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                        nh.Parent=p.Character
                        espFolder[p]=nh
                    else
                        pcall(function()
                            h.FillColor=warnaUntuk(p)
                            h.OutlineColor=warnaUntuk(p)
                        end)
                    end
                end
            end
        end
        if vis.tag then
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character and not tagFolder[p] then
                    local head=p.Character:FindFirstChild("Head")
                    if head then
                        local bb=Instance.new("BillboardGui")
                        bb.Name="SilauTag" bb.Size=UDim2.fromOffset(150,54)
                        bb.StudsOffset=Vector3.new(0,2.6,0) bb.AlwaysOnTop=true
                        bb.Parent=head
                        local nm=Instance.new("TextLabel")
                        nm.Size=UDim2.new(1,0,0,18) nm.BackgroundTransparency=1
                        nm.Font=Enum.Font.GothamBold nm.TextSize=11
                        nm.TextColor3=Warna.Putih nm.TextStrokeTransparency=0.3
                        nm.Text=p.DisplayName nm.Parent=bb
                        local inf=Instance.new("TextLabel")
                        inf.Position=UDim2.new(0,0,0,19) inf.Size=UDim2.new(1,0,0,16)
                        inf.BackgroundTransparency=1 inf.Font=Enum.Font.Gotham
                        inf.TextSize=9 inf.TextColor3=Warna.HijauMuda
                        inf.TextStrokeTransparency=0.4 inf.Text="..." inf.Parent=bb
                        local dst=Instance.new("TextLabel")
                        dst.Position=UDim2.new(0,0,0,36) dst.Size=UDim2.new(1,0,0,14)
                        dst.BackgroundTransparency=1 dst.Font=Enum.Font.Gotham
                        dst.TextSize=9 dst.TextColor3=Warna.AbuGelap
                        dst.TextStrokeTransparency=0.4 dst.Text="" dst.Parent=bb
                        tagFolder[p]={bb=bb,info=inf,dist=dst} -- FIX #3
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while RUNNING do
        task.wait(0.3)
        local _,_,myHrp=getMy()
        if vis.tag and myHrp then
            for p,data in pairs(tagFolder) do
                if p.Parent and p.Character then
                    local hum2=p.Character:FindFirstChildOfClass("Humanoid")
                    local hrp2=p.Character:FindFirstChild("HumanoidRootPart")
                    if hum2 and hrp2 then
                        local sp=hum2.WalkSpeed
                        local jp=hum2.UseJumpPower and hum2.JumpPower or hum2.JumpHeight
                        local dist=(hrp2.Position-myHrp.Position).Magnitude
                        local curang=(sp>WALK_ON+0.05)
                            or (hum2.UseJumpPower and jp>JUMP_OFF+0.05)
                        data.info.Text=string.format("🏃%.1f 🦘%.1f%s",sp,jp,curang and " ⚠️" or "")
                        data.info.TextColor3=curang and Warna.Merah or Warna.HijauMuda
                        data.dist.Text=string.format("📏 %d stud",dist)
                    end
                else
                    data.info.Text="..." data.dist.Text=""
                end
            end
        end
        if vis.hideP then
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character then
                    for _,d in ipairs(p.Character:GetDescendants()) do
                        if d:IsA("BasePart") and not table.find(hiddenParts,d) then
                            d.LocalTransparencyModifier=0.85
                            table.insert(hiddenParts,d)
                        end
                    end
                end
            end
        end
    end
end)

-- Auto brightness + wall scan
task.spawn(function()
    while RUNNING do
        task.wait(1)
        if vis.bright then
            local t=Lighting.ClockTime
            if t>=18 or t<6 then
                Lighting.Brightness=3
                Lighting.Ambient=Color3.fromRGB(140,140,165)
                Lighting.OutdoorAmbient=Color3.fromRGB(140,140,165)
            else
                Lighting.Brightness=1
                Lighting.Ambient=Color3.fromRGB(110,110,120)
                Lighting.OutdoorAmbient=Color3.fromRGB(110,110,120)
            end
        end
        if vis.wall and math.random()<0.06 then scanWall() end
    end
end)

-- Swim mode
RunService.Heartbeat:Connect(function()
    if not RUNNING then return end
    local c,hum,hrp=getMy()
    if not hum or not hrp then return end
    local swimming=(hum:GetState()==Enum.HumanoidStateType.Swimming)
    if swimming and vis.swim>0 then
        if not myGyro or not myGyro.Parent then
            myGyro=Instance.new("BodyGyro")
            myGyro.MaxTorque=Vector3.new(4e5,4e5,4e5)
            myGyro.P=8000 myGyro.D=500
            myGyro.Parent=hrp
        end
        local md=hum.MoveDirection
        local flat=(md.Magnitude>0.01) and Vector3.new(md.X,0,md.Z).Unit
            or hrp.CFrame.LookVector
        if vis.swim==1 then -- katak: horizontal
            myGyro.CFrame=CFrame.lookAt(Vector3.zero,flat)
                *CFrame.Angles(math.rad(80),0,0)
        else -- tegak
            myGyro.CFrame=CFrame.lookAt(Vector3.zero,flat)
        end
        -- boost +20% saat renang katak
        if vis.swim==1 then
            local target=(mv.sprint or mv.shift) and mv.sprintVal
                or (mv.walk and WALK_ON or WALK_OFF)
            target=target*(1+SWIM_BOOST)
            if math.abs(hum.WalkSpeed-target)>0.01 then
                pcall(function() hum.WalkSpeed=target end)
            end
        end
    else
        if myGyro then pcall(function() myGyro:Destroy() end) myGyro=nil end
    end
end)

-- Moonwalk (hanya saat di tanah, biar tidak chaos di udara)
RunService.RenderStepped:Connect(function()
    if not RUNNING or not vis.moon then return end
    local c,hum,hrp=getMy()
    if not hum or not hrp then return end
    if hum.FloorMaterial==Enum.Material.Air then return end
    local md=hum.MoveDirection
    if md.Magnitude>0.05 then
        local flat=Vector3.new(md.X,0,md.Z)
        if flat.Magnitude>0.01 then
            pcall(function()
                hrp.CFrame=CFrame.lookAt(hrp.Position,hrp.Position-flat.Unit)
            end)
        end
    end
end)

-- FPS & ping
local frameCount=0
RunService.RenderStepped:Connect(function()
    if RUNNING then frameCount+=1 end
end)
task.spawn(function()
    while RUNNING do
        task.wait(1)
        local fps=frameCount frameCount=0
        local ping=math.floor(LocalPlayer:GetNetworkPing()*1000)
        if fpsPanel.Visible then
            fpsLbl.Text=string.format("FPS %d | %d ms",fps,ping)
            fpsLbl.TextColor3=(fps>=50 and Warna.HijauMuda) or (fps>=25 and Warna.Kuning) or Warna.MerahMuda
        end
    end
end)

local namaGame="?"
pcall(function()
    local info=MarketplaceService:GetProductInfo(game.PlaceId)
    if info and info.Name then namaGame=info.Name end
end)

task.spawn(function()
    while RUNNING do
        task.wait(0.25)
        local _,hum,hrp=getMy()
        if clPanel.Visible then
            local pos=hrp and hrp.Position or Vector3.zero
            clLbl.Text=os.date("%d/%m/%Y  %H:%M:%S")
                ..string.format("\n📍 %.0f, %.0f, %.0f",pos.X,pos.Y,pos.Z)
                .."\n🎮 "..namaGame:sub(1,18)
        end
        if stPanel.Visible and hum then
            local jp=hum.UseJumpPower and hum.JumpPower or hum.JumpHeight
            local pos=hrp and hrp.Position or Vector3.zero
            stLbl.Text=string.format("🏃 %.2f\n🦘 %.2f\n❤️ %.0f/%.0f\n📍 %.0f,%.0f,%.0f",
                hum.WalkSpeed,jp,hum.Health,hum.MaxHealth,pos.X,pos.Y,pos.Z)
        end
        if svPanel.Visible then
            svLbl.Text=string.format("👥 %d/%d pemain\n🆔 Place: %d\n🔑 Job: %s",
                #Players:GetPlayers(),Players.MaxPlayers,game.PlaceId,
                game.JobId:sub(1,12).."…")
        end
        if alarm.aktif then
            local sisa=math.max(0,math.floor(alarm.akhir-os.clock()))
            alarmStat.Text=string.format("⏳ %d:%02d",math.floor(sisa/60),sisa%60)
            if sisa<=0 then
                alarm.aktif=false
                alarmStat.Text="🔔 WAKTUNYA!"
                bunyi(SND_PING,0.5,1.5)
                task.delay(0.4,function() bunyi(SND_PING,0.5,1.5) end)
                notif("⏰ ALARM! Waktunya tiba!",Warna.Merah)
            end
        end
    end
end)

-- Anti-AFK lapis 1 (event)
LocalPlayer.Idled:Connect(function()
    if RUNNING and hudOn.afk then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- [16] BUKA/TUTUP + TAB ---------------------------------------------
local sesi=0
local function pilihTab(n)
    for i=1,3 do
        tabFrames[i].Visible=(i==n)
        tabBtns[i].btn.BackgroundColor3=i==n and Warna.Hitam2 or Warna.AbuItem
        tabBtns[i].btn.TextColor3=i==n and Warna.Putih or Warna.TeksGelap
        tabBtns[i].stroke.Color=i==n and Warna.Pink or Warna.AbuTeks
        tabBtns[i].stroke.Transparency=i==n and 0 or 0.6
    end
    bunyi(SND_PING,0.2,1+0.1*n)
end
for i,t in ipairs(tabBtns) do
    t.btn.MouseButton1Click:Connect(function() pilihTab(i) end)
end

local function minimize()
    if not root.Visible then return end
    sesi+=1 local id=sesi
    bunyi(SND_PING,0.25,0.75)
    icon.Visible=true
    iconScale.Scale=0.4
    tween(iconScale,TweenInfo.new(0.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1})
    local ti=TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    tween(panelScale,ti,{Scale=0.5})
    task.delay(0.22,function()
        if sesi~=id then return end
        root.Visible=false panelScale.Scale=1
    end)
end
local function buka()
    sesi+=1
    bunyi(SND_PING,0.3,1.15)
    icon.Visible=false root.Visible=true
    panelScale.Scale=0.6
    tween(panelScale,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1})
end
minBtn.MouseButton1Click:Connect(minimize)
helpBtn.MouseButton1Click:Connect(function()
    helpPanel.Visible=not helpPanel.Visible
end)
helpClose.MouseButton1Click:Connect(function() helpPanel.Visible=false end)
buatDraggable(header,root)
buatDraggable(icon,icon,buka)

-- [17] KEYBIND -------------------------------------------------------
-- FIX #7: kill script pakai nilai asli game
function killScript()
    RUNNING=false
    pcall(function()
        local _,hum=getMy()
        if hum then
            hum.WalkSpeed=original.walk
            hum.JumpPower=original.jump
            hum.UseJumpPower=original.useJP
        end
    end)
    for _,d in pairs(espFolder) do pcall(function() d:Destroy() end) end
    for _,t in pairs(tagFolder) do pcall(function() t.bb:Destroy() end) end
    for _,p in ipairs(pins) do pcall(function() p:Destroy() end) end
    for d,o in pairs(wallParts) do pcall(function() d.Transparency=o.t d.Color=o.c end) end
    for _,pt in ipairs(hiddenParts) do pcall(function() pt.LocalTransparencyModifier=0 end) end
    for _,fx in ipairs(hiddenFx) do pcall(function() fx.Enabled=true end) end
    if origLight then
        pcall(function()
            Lighting.Brightness=origLight.B
            Lighting.Ambient=origLight.A
            Lighting.OutdoorAmbient=origLight.OA
        end)
    end
    pcall(function() cam.FieldOfView=70 end)
    if myGyro then pcall(function() myGyro:Destroy() end) end
    if crossFrame then pcall(function() crossFrame:Destroy() end) end
    screenGui:Destroy()
    print("[SilauHub] Script dihapus total ✔")
end

local function doQ()
    if mv.sprint then
        tglSprint.set(false,true)
        tglWalk.set(false,true)
        notif("⏹ Speed OFF semua",Warna.Merah)
    else
        tglWalk.set(not mv.walk)
    end
end

local qCount,qTimer=0,nil
local kCount,kTimer=0,nil

UserInputService.InputBegan:Connect(function(input,gp)
    if not RUNNING then return end
    if gp then return end
    if UserInputService:GetFocusedTextBox() then return end
    local k=input.KeyCode

    if k==KEY_GUI then
        if root.Visible then minimize() else buka() end

    elseif k==KEY_Q then
        qCount+=1
        if qTimer then task.cancel(qTimer) qTimer=nil end
        if qCount>=2 then
            qCount=0
            tglSprint.set(true)
        else
            qTimer=task.delay(0.28,function()
                if qCount==1 then doQ() end
                qCount=0
            end)
        end

    elseif k==KEY_T then
        tglBright.set(not vis.bright)

    elseif k==KEY_C then
        siklusSwim() -- FIX #1

    elseif k==KEY_X then
        tglWall.set(not vis.wall)

    elseif k==KEY_Z then
        tglTag.set(not vis.tag)

    elseif k==KEY_K then
        kCount+=1
        if kTimer then task.cancel(kTimer) kTimer=nil end
        if kCount>=2 then
            kCount=0
            notif("💥 Menghapus SILAU HUB...",Warna.Merah)
            task.wait(0.4)
            killScript()
        else
            notif("⚠️ Tekan K LAGI untuk hapus script!",Warna.Kuning)
            kTimer=task.delay(2,function() kCount=0 end)
        end

    elseif table.find(SPRINT_KEYS,k) then
        mv.shift=true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if table.find(SPRINT_KEYS,input.KeyCode) then
        mv.shift=false
    end
end)

-- [18] MULAI ---------------------------------------------------------
pilihTab(1)
task.delay(0.15,buka)
task.delay(1,function()
    notif("⚡ SILAU HUB v"..VERSI.." siap! F = GUI",Warna.Pink)
end)

print("[SilauHub v"..VERSI.."] SIAP ✔ (audited) — F=GUI Q=speed QQ=sprint T=brightness C=swim X=wall Z=info KK=kill")
