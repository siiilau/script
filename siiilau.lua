--========================================================
--  SIIILAU HUB SCRIPTS v1.0.1
--  F=GUI  Q=speed  Q Q=sprint  V=jump  G=moonwalk
--  R=hide player  T=brightness  C=renang  X=dinding
--  Z=info  K K=hapus
--
--  MOONWALK: badan TERKUNCI menghadap kamera/layar
--  FALL ASSIST v3 (SIMPLE - FINAL):
--   lompat - jatuh - NYENGGOL sekali di 80% perjalanan
--   - jatuh sebentar - mendarat - selesai
--   Cuma 2 pengaturan: MIN JATUH (50) & POSISI BENTUR (0.80)
--   Kecepatan setelah nyenggol: -30 (internal)
--========================================================
print("[SilauHub] v1.0.1 loading...")

local function fatal(e)
 warn("[SilauHub] ERROR: "..tostring(e))
 local lp=game:GetService("Players").LocalPlayer
 if not lp then return end
 local g=Instance.new("ScreenGui") g.ResetOnSpawn=false g.DisplayOrder=99999
 local pg=lp:FindFirstChild("PlayerGui")
 if pg then pcall(function() g.Parent=pg end) end
 if not g.Parent then return end
 local t=Instance.new("TextLabel")
 t.Size=UDim2.fromOffset(460,150) t.Position=UDim2.new(0.5,-230,0.5,-75)
 t.BackgroundColor3=Color3.fromRGB(30,10,10) t.TextColor3=Color3.fromRGB(255,120,120)
 t.Font=Enum.Font.Code t.TextSize=13 t.TextWrapped=true
 t.Text="SIIILAU HUB ERROR (screenshot & kirim):\n"..tostring(e)
 t.Parent=g
end

local ok,e=pcall(function()

local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("RunService")
local TS=game:GetService("TweenService")
local LG=game:GetService("Lighting")
local VU=game:GetService("VirtualUser")
local LP=Players.LocalPlayer
local RUN=true

-- ================= NILAI =================
local SWIM_BOOST=1.15
local cfg={
 wOff=17.10, wOn=17.25,
 sOff=21.10, sOn=21.25,
 jOff=51.25, jOn=65.50,
 -- FALL ASSIST v3 (SIMPLE - FINAL)
 fMinJatuh=50,   -- jatuh harus lebih tinggi dari ini (stud)
 fPosisi=0.80,   -- nyenggol di 80% perjalanan jatuh (dekat tanah)
 fBenturKe=-30,  -- (internal tetap) kecepatan setelah nyenggol
}

-- ================= TEMA KING SILAU =================
local C={
 bg=Color3.fromRGB(15,15,23),
 card=Color3.fromRGB(28,28,44),
 card2=Color3.fromRGB(40,40,62),
 ungu=Color3.fromRGB(140,70,255),
 biru=Color3.fromRGB(45,140,255),
 putih=Color3.fromRGB(235,235,245),
 abuT=Color3.fromRGB(150,150,175),
 hijau=Color3.fromRGB(60,200,110),
 merah=Color3.fromRGB(235,75,75),
 abu=Color3.fromRGB(72,72,94),
}
local F_B=Enum.Font.GothamBold
local F_M=Enum.Font.GothamMedium
local F_R=Enum.Font.Gotham
local F_BLK=Enum.Font.GothamBlack

-- ================= STATE =================
local mv={walk=false,sprint=false,jump=false,dj=false,fall=false,djOK=true}
local vis={esp=false,tag=false,cross=0,moon=false,hideP=false,fx=false,br=false,swim=false,wall=false}
local hud={afk=true}
local espF,tagF,hidP,hidFX,wallP={},{},{},{},{}
local kill=nil
local orig={ws=16,jp=50,u=true}
local oLight={B=LG.Brightness,A=LG.Ambient,O=LG.OutdoorAmbient}
local ray=RaycastParams.new()
pcall(function() ray.FilterType=Enum.RaycastFilterType.Exclude end)
local HOK=pcall(function() local t=Instance.new("Highlight") t:Destroy() end)

local function ch()
 local c=LP.Character
 if not c then return nil end
 return c,c:FindFirstChildOfClass("Humanoid"),c:FindFirstChild("HumanoidRootPart")
end
local function rayUpd()
 local c=LP.Character
 if c then ray.FilterDescendantsInstances={c} end
end
rayUpd()
do local _,h=ch() if h then orig={ws=h.WalkSpeed,jp=h.JumpPower,u=h.UseJumpPower} end end
local function wTeam(p)
 if p.Team then return p.TeamColor.Color end
 return C.ungu
end

-- ================= GUI =================
local g=Instance.new("ScreenGui")
g.Name="SilauHub" g.ResetOnSpawn=false g.DisplayOrder=9997
local pg=LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui",9)
g.Parent=pg

local function mk(cl,pr,par)
 local o=Instance.new(cl)
 for k,v in pairs(pr) do o[k]=v end
 o.Parent=par return o
end
local function corner(p,r) return mk("UICorner",{CornerRadius=UDim.new(0,r or 8)},p) end

local function snd(v,p)
 pcall(function()
  local s=Instance.new("Sound")
  s.SoundId="rbxasset://sounds/electronicpingshort.wav"
  s.Volume=v or .2 s.PlaybackSpeed=p or 1
  s.Parent=g s:Play()
  task.delay(1.5,function() s:Destroy() end)
 end)
end

-- ================= NOTIF =================
local nf=mk("Frame",{AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,10),
 Size=UDim2.fromOffset(280,300),BackgroundTransparency=1},g)
mk("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,
 HorizontalAlignment=Enum.HorizontalAlignment.Center},nf)
local no=0
local function notif(tx,okNotif)
 no+=1
 local n=mk("Frame",{Size=UDim2.fromOffset(250,30),BackgroundColor3=C.card,
  LayoutOrder=no},nf)
 corner(n,8)
 mk("UIStroke",{Color=okNotif and C.hijau or C.ungu,Thickness=1,Transparency=0.5},n)
 local dot=mk("Frame",{BackgroundColor3=okNotif and C.hijau or C.ungu,
  Size=UDim2.fromOffset(8,8),Position=UDim2.new(0,10,0.5,-4)},n)
 corner(dot,4)
 mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,26,0,0),
  Size=UDim2.new(1,-34,1,0),Font=F_B,TextSize=11,TextColor3=C.putih,Text=tx,
  TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},n)
 task.delay(1.8,function()
  if n.Parent then n:Destroy() end
 end)
 local k=0
 for _,x in ipairs(nf:GetChildren()) do if x:IsA("Frame") then k+=1 end end
 if k>5 then
  for _,x in ipairs(nf:GetChildren()) do if x:IsA("Frame") then x:Destroy() break end end
 end
end

-- ================= HUD CHIPS =================
local hudF=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1},g)

local pFp=mk("Frame",{Position=UDim2.new(0,8,1,-26),Size=UDim2.fromOffset(150,20),
 BackgroundColor3=C.bg,BackgroundTransparency=0.4,Active=true},hudF)
corner(pFp,6)
local fpL=mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,6,0,0),
 Size=UDim2.new(1,-12,1,0),Font=F_R,TextSize=11,TextColor3=C.abuT,
 Text="FPS: --",TextXAlignment=Enum.TextXAlignment.Left},pFp)

local pSt=mk("Frame",{Position=UDim2.new(0,8,1,-156),Size=UDim2.fromOffset(190,122),
 BackgroundColor3=C.bg,BackgroundTransparency=0.15,BorderSizePixel=0,Active=true,
 Visible=false},hudF)
corner(pSt,10)
mk("UIStroke",{Color=C.ungu,Thickness=1,Transparency=0.5},pSt)
mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,9,0,4),
 Size=UDim2.new(1,-18,0,13),Font=F_B,TextSize=10,TextColor3=C.ungu,
 Text="STATUS",TextXAlignment=Enum.TextXAlignment.Left},pSt)
local stL=mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,9,0,20),
 Size=UDim2.new(1,-18,1,-24),Font=F_R,TextSize=10,TextColor3=C.putih,
 Text="...",TextXAlignment=Enum.TextXAlignment.Left,
 TextYAlignment=Enum.TextYAlignment.Top},pSt)

local function drag(h,t)
 local d,s,p=false,nil,nil
 h.InputBegan:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
   d,s,p=true,i.Position,t.Position
  end
 end)
 h.InputEnded:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
   d=false
  end
 end)
 UIS.InputChanged:Connect(function(i)
  if d and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
   local dl=i.Position-s
   t.Position=UDim2.new(p.X.Scale,p.X.Offset+dl.X,p.Y.Scale,p.Y.Offset+dl.Y)
  end
 end)
end
drag(pFp,pFp)
drag(pSt,pSt)

-- ================= PANEL UTAMA =================
local root=mk("Frame",{Size=UDim2.fromOffset(320,430),
 Position=UDim2.new(0.5,-160,0.5,-215),BackgroundColor3=C.bg,
 Active=true,Visible=false,BorderSizePixel=0},g)
corner(root,12)
mk("UIStroke",{Color=C.ungu,Thickness=1.5,Transparency=0.4},root)

mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,14,0,0),
 Size=UDim2.new(1,-60,0,40),Font=F_BLK,TextSize=17,TextColor3=C.putih,
 Text="SIIILAU HUB",TextXAlignment=Enum.TextXAlignment.Left},root)

local grad=mk("Frame",{BackgroundColor3=Color3.new(1,1,1),Size=UDim2.new(1,-24,0,2),
 Position=UDim2.new(0,12,0,40),BorderSizePixel=0},root)
mk("UIGradient",{Color=ColorSequence.new(C.ungu,C.biru)},grad)

local minB=mk("TextButton",{BackgroundColor3=C.card2,Size=UDim2.fromOffset(26,26),
 Position=UDim2.new(1,-34,0,7),Font=F_B,TextSize=12,TextColor3=C.putih,Text="X",
 AutoButtonColor=false},root)
corner(minB,6)

local titleHit=mk("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,-44,0,40),
 Active=true},root)
local function drag(h,t)
 local d,s,p=false,nil,nil
 h.InputBegan:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
   d,s,p=true,i.Position,t.Position
  end
 end)
 h.InputEnded:Connect(function(i)
  if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
   d=false
  end
 end)
 UIS.InputChanged:Connect(function(i)
  if d and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
   local dl=i.Position-s
   t.Position=UDim2.new(p.X.Scale,p.X.Offset+dl.X,p.Y.Scale,p.Y.Offset+dl.Y)
  end
 end)
end
drag(titleHit,root)

local tbar=mk("Frame",{Position=UDim2.new(0,10,0,46),Size=UDim2.new(1,-20,0,26),
 BackgroundTransparency=1},root)
mk("UIListLayout",{Padding=UDim.new(0,4),FillDirection=Enum.FillDirection.Horizontal},tbar)
local tb={}
for i,nm in ipairs({"MOVEMENT","VISUAL","HUD"}) do
 local b=mk("TextButton",{Size=UDim2.new(1/3,-3,1,0),
  BackgroundColor3=i==1 and C.card2 or C.card,Font=F_B,TextSize=10,
  TextColor3=i==1 and C.putih or C.abuT,Text=nm,AutoButtonColor=false},tbar)
 corner(b,7)
 tb[i]={b=b,s=mk("UIStroke",{Color=i==1 and C.ungu or C.abu,Thickness=1,
  Transparency=i==1 and 0.2 or 0.6},b)}
end

local tf={}
for i=1,3 do
 tf[i]=mk("ScrollingFrame",{Position=UDim2.new(0,10,0,78),
  Size=UDim2.new(1,-20,1,-88),BackgroundTransparency=1,ScrollBarThickness=3,
  ScrollBarImageColor3=C.ungu,AutomaticCanvasSize=Enum.AutomaticSize.Y,
  CanvasSize=UDim2.new(),Visible=i==1,BorderSizePixel=0},root)
 mk("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},tf[i])
end

-- ================= FACTORY =================
local oc={0,0,0}
local function header(ti,tx)
 oc[ti]+=1
 return mk("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,16),
  Font=F_B,TextSize=11,TextColor3=C.ungu,TextXAlignment=Enum.TextXAlignment.Left,
  Text="▎"..string.upper(tx),LayoutOrder=oc[ti]},tf[ti])
end
local function rInfo(ti,tx,h)
 oc[ti]+=1
 return mk("TextLabel",{Size=UDim2.new(1,0,0,h or 24),BackgroundTransparency=1,
  Font=F_R,TextSize=10,TextColor3=C.abuT,Text=tx,TextWrapped=true,
  TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=oc[ti]},tf[ti])
end
local function makeSwitch(row,initial)
 local sw=mk("TextButton",{BackgroundColor3=initial and C.hijau or C.abu,
  Size=UDim2.fromOffset(40,20),Position=UDim2.new(1,-50,0.5,-10),
  Text="",AutoButtonColor=false},row)
 corner(sw,10)
 local kn=mk("Frame",{BackgroundColor3=Color3.fromRGB(235,235,240),
  Size=UDim2.fromOffset(14,14),
  Position=initial and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)},sw)
 corner(kn,7)
 return sw,kn
end
local function rTgl(ti,tx,hint,ini,cb)
 oc[ti]+=1
 local row=mk("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.card,
  LayoutOrder=oc[ti]},tf[ti])
 corner(row,8)
 mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,10,0,0),
  Size=UDim2.new(1,-110,1,0),Font=F_M,TextSize=12,TextColor3=C.putih,
  Text=tx,TextXAlignment=Enum.TextXAlignment.Left,
  TextTruncate=Enum.TextTruncate.AtEnd},row)
 if hint then
  local chip=mk("TextLabel",{BackgroundColor3=C.card2,Size=UDim2.fromOffset(24,20),
   Position=UDim2.new(1,-80,0.5,-10),Font=F_B,TextSize=10,TextColor3=C.abuT,
   Text=hint},row)
  corner(chip,6)
 end
 local sw,kn=makeSwitch(row,ini)
 local o={s=ini}
 o.set=function(v,noSnd)
  o.s=v
  TS:Create(sw,TweenInfo.new(0.15),
   {BackgroundColor3=v and C.hijau or C.abu}):Play()
  TS:Create(kn,TweenInfo.new(0.15),
   {Position=v and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}):Play()
  if not noSnd then snd(.2,v and 1.15 or .9) end
  pcall(function() cb(v) end)
 end
 sw.MouseButton1Click:Connect(function() o.set(not o.s) end)
 return o
end
local function rAct(ti,tx,cb,h)
 oc[ti]+=1
 local b=mk("TextButton",{Size=UDim2.new(1,0,0,h or 30),BackgroundColor3=C.card2,
  Font=F_B,TextSize=12,TextColor3=C.putih,Text=tx,
  AutoButtonColor=false,LayoutOrder=oc[ti]},tf[ti])
 corner(b,8)
 b.MouseButton1Click:Connect(function()
  snd(.2,1.1)
  pcall(function() cb(b) end)
 end)
 return b
end
local function rNum(ti,label,default,cb)
 oc[ti]+=1
 local row=mk("Frame",{Size=UDim2.new(1,0,0,30),BackgroundColor3=C.card,
  LayoutOrder=oc[ti]},tf[ti])
 corner(row,8)
 mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,10,0,0),
  Size=UDim2.new(1,-100,1,0),Font=F_M,TextSize=11,TextColor3=C.putih,
  Text=label,TextXAlignment=Enum.TextXAlignment.Left},row)
 local bx=mk("TextBox",{Size=UDim2.fromOffset(70,22),Position=UDim2.new(1,-80,0.5,-11),
  BackgroundColor3=C.bg,Font=F_R,TextSize=12,Text=string.format("%.2f",default),
  TextColor3=C.putih,ClearTextOnFocus=false},row)
 corner(bx,6)
 mk("UIStroke",{Color=C.abu,Thickness=1,Transparency=0.5},bx)
 bx.FocusLost:Connect(function()
  local n=tonumber((bx.Text:gsub("[^%d%.%-]","")))
  if n then
   cb(n) bx.Text=string.format("%.2f",n)
   notif(label.." = "..string.format("%.2f",n),true)
  else
   bx.Text=string.format("%.2f",default)
  end
 end)
end

-- ================= TAB 1 : MOVEMENT =================
header(1,"Player")
local infoSpeed
infoSpeed=rInfo(1,"")
local function updInfoSpeed()
 infoSpeed.Text="OFF "..string.format("%.2f",cfg.wOff)
  .."  |  WALK "..string.format("%.2f",cfg.wOn).." [Q]"
  .."  |  SPRINT "..string.format("%.2f",cfg.sOn).." [Q Q]"
end
updInfoSpeed()

local tgW=rTgl(1,"Speed","Q",false,function(v)
 mv.walk=v
 notif(v and ("SPEED "..string.format("%.2f",cfg.wOn)) or ("NORMAL "..string.format("%.2f",cfg.wOff)),v)
end)
local lblS=rInfo(1,"Sprint OFF - tekan Q dua kali")
local tgS=rTgl(1,"Sprint","Q Q",false,function(v)
 mv.sprint=v
 if v then
  lblS.Text="Sprint aktif -> "..string.format("%.2f",cfg.sOn).." stud/s"
 else
  lblS.Text="Sprint OFF - melambat halus"
 end
 notif(v and ("SPRINT "..string.format("%.2f",cfg.sOn)) or "SPRINT OFF",v)
end)

header(1,"Lompatan")
local tgJump=rTgl(1,"JumpPower","V",false,function(v)
 mv.jump=v
 notif(v and ("JUMP "..string.format("%.2f",cfg.jOn)) or ("NORMAL "..string.format("%.2f",cfg.jOff)),v)
end)
rTgl(1,"Double Jump (1x)",nil,false,function(v)
 mv.dj=v mv.djOK=true
 notif(v and "DOUBLE JUMP ON" or "DOUBLE JUMP OFF",v)
end)

header(1,"Jatuh Cerdas")
local tgFall=rTgl(1,"Smart Fall Assist",nil,false,function(v)
 mv.fall=v
end)
rInfo(1,"Jatuh normal kencang -> nyenggol sekali di 80%\n(menjelang tanah) -> mendarat pelan.\nSekali saja. Darah tidak disentuh. Tanpa notif.",40)

header(1,"Pengaturan Fall Assist")
rNum(1,"MIN JATUH",cfg.fMinJatuh,function(n) cfg.fMinJatuh=n end)
rNum(1,"POSISI BENTUR (0-1)",cfg.fPosisi,function(n)
 if n>0 and n<1 then cfg.fPosisi=n end
end)

header(1,"Pengaturan Nilai")
rNum(1,"SPEED OFF",cfg.wOff,function(n) cfg.wOff=n updInfoSpeed() end)
rNum(1,"SPEED ON",cfg.wOn,function(n) cfg.wOn=n updInfoSpeed() end)
rNum(1,"SPRINT OFF",cfg.sOff,function(n) cfg.sOff=n updInfoSpeed() end)
rNum(1,"SPRINT ON",cfg.sOn,function(n) cfg.sOn=n updInfoSpeed() end)
rNum(1,"JUMP OFF",cfg.jOff,function(n) cfg.jOff=n end)
rNum(1,"JUMP ON",cfg.jOn,function(n) cfg.jOn=n end)

-- ================= TAB 2 : VISUAL =================
header(2,"Target")
rTgl(2,"ESP / Highlight",nil,false,function(v)
 vis.esp=v
 if v and not HOK then notif("HIGHLIGHT TIDAK DIDUKUNG",false) end
 if not v then
  for _,d in pairs(espF) do pcall(function() d:Destroy() end) end
  espF={}
 end
 notif(v and "ESP ON" or "ESP OFF",v)
end)
local tglTag=rTgl(2,"Nametag + Info","Z",false,function(v)
 vis.tag=v
 if not v then
  for _,t in pairs(tagF) do pcall(function() t.bb:Destroy() end) end
  tagF={}
 end
 notif(v and "INFO PLAYER ON" or "INFO PLAYER OFF",v)
end)
rInfo(2,"Merah otomatis jika speed/jump lain mencurigakan.")

header(2,"Gaya")
local gayaNama={"OFF","DOT","CROSS","CIRCLE"}
rAct(2,"Crosshair: OFF (klik ganti)",function(b)
 vis.cross=(vis.cross+1)%4
 for _,x in ipairs(hudF:GetChildren()) do
  if x.Name=="XC" then x:Destroy() end
 end
 if vis.cross>0 then
  local f=mk("Frame",{Name="XC",AnchorPoint=Vector2.new(.5,.5),
   Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(0,0),
   BackgroundTransparency=1},hudF)
  if vis.cross==1 then
   local d=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(6,6),BackgroundColor3=Color3.new(1,1,1)},f)
   corner(d,3)
  elseif vis.cross==2 then
   mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(20,2),BackgroundColor3=Color3.new(1,1,1)},f)
   mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(2,20),BackgroundColor3=Color3.new(1,1,1)},f)
  else
   local c=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(22,22),BackgroundTransparency=1},f)
   corner(c,11)
   mk("UIStroke",{Color=Color3.new(1,1,1),Thickness=2},c)
  end
 end
 b.Text="Crosshair: "..gayaNama[vis.cross+1].." (klik ganti)"
 notif("CROSSHAIR: "..gayaNama[vis.cross+1],vis.cross>0)
end)
local tgMoon=rTgl(2,"Moonwalk","G",false,function(v)
 vis.moon=v
 if v and vis.swim then
  vis.swim=false
  if btnSwim then btnSwim.Text="Renang: NORMAL [C]" end
  notif("RENANG OTOMATIS OFF (MOONWALK)",false)
 end
 notif(v and "MOONWALK ON" or "MOONWALK OFF",v)
end)

header(2,"Layar Bersih")
local tgHideP=rTgl(2,"Hide Player","R",false,function(v)
 vis.hideP=v
 if not v then
  for _,p in ipairs(hidP) do pcall(function() p.LocalTransparencyModifier=0 end) end
  hidP={}
 end
 notif(v and "PLAYER DISEMBUNYIKAN" or "PLAYER TAMPIL",v)
end)
rTgl(2,"Matikan Efek (FPS)",nil,false,function(v)
 vis.fx=v
 if v then
  for _,d in ipairs(workspace:GetDescendants()) do
   pcall(function()
    if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke")
    or d:IsA("Sparkles") or d:IsA("Beam") or d:IsA("Trail") then
     if d.Enabled then d.Enabled=false table.insert(hidFX,d) end
    end
   end)
  end
  for _,d in ipairs(LG:GetChildren()) do
   pcall(function()
    if d:IsA("PostEffect") and d.Enabled then d.Enabled=false table.insert(hidFX,d) end
   end)
  end
  notif("EFEK MATI - FPS NAIK",true)
 else
  for _,d in ipairs(hidFX) do pcall(function() d.Enabled=true end) end
  hidFX={}
  notif("EFEK DINYALAKAN",true)
 end
end)

header(2,"Lingkungan")
local tglBr=rTgl(2,"Auto Brightness","T",false,function(v)
 vis.br=v
 if not v then
  pcall(function()
   LG.Brightness=oLight.B LG.Ambient=oLight.A LG.OutdoorAmbient=oLight.O
  end)
 end
 notif(v and "BRIGHTNESS ON" or "BRIGHTNESS OFF",v)
end)
local btnSwim
local function siklusSwim()
 vis.swim=not vis.swim
 if vis.swim and vis.moon then
  vis.moon=false
  if tgMoon then tgMoon.set(false,true) end
  notif("MOONWALK OTOMATIS OFF (RENANG)",false)
 end
 if vis.swim then
  btnSwim.Text="Renang: KATAK +15% [C]"
  notif("RENANG KATAK +15%",true)
 else
  btnSwim.Text="Renang: NORMAL [C]"
  notif("RENANG NORMAL",true)
 end
end
btnSwim=rAct(2,"Renang: NORMAL [C]",function() siklusSwim() end)
local function scanW()
 if not vis.wall then return end
 for _,d in ipairs(workspace:GetDescendants()) do
  pcall(function()
   if d:IsA("BasePart") and not wallP[d] and d.Transparency>0.5 and d.CanCollide then
    wallP[d]={t=d.Transparency,c=d.Color}
    d.Transparency=0.55 d.Color=Color3.fromRGB(205,205,205)
   end
  end)
 end
end
local tglWall=rTgl(2,"Dinding Tak Terlihat","X",false,function(v)
 vis.wall=v
 if v then scanW() notif("DINDING DITAMPILKAN",true)
 else
  for d,o in pairs(wallP) do pcall(function() d.Transparency=o.t d.Color=o.c end) end
  wallP={}
  notif("DINDING DISEMBUNYIKAN",true)
 end
end)
rAct(2,"Scan Ulang Dinding",function()
 if vis.wall then scanW() notif("SCAN SELESAI",true)
 else notif("NYALAKAN DINDING DULU",false) end
end)

-- ================= TAB 3 : HUD =================
header(3,"Panel")
rTgl(3,"FPS / Ping",nil,true,function(v) pFp.Visible=v end)
rTgl(3,"Status",nil,false,function(v) pSt.Visible=v end)
rInfo(3,"Panel bisa digeser (drag).")

header(3,"Lainnya")
rTgl(3,"Anti-AFK (20 menit)",nil,true,function(v)
 hud.afk=v
 notif(v and "ANTI-AFK ON" or "ANTI-AFK OFF",v)
end)
rAct(3,"Mode Bersih (HUD hilang)",function()
 hudF.Visible=not hudF.Visible
 notif(hudF.Visible and "HUD KEMBALI" or "MODE BERSIH",hudF.Visible)
end)
rAct(3,"HAPUS SCRIPT TOTAL",function()
 notif("MENGHAPUS...",false)
 task.wait(0.3)
 if kill then kill() end
end,32)

-- ================= RENANG RINGAN (TANPA BODYGYRO) =================
local swimBound=false
local SWIM_BIND="SILAU_SWIM"

local function unbindSwim()
 if swimBound then
  pcall(function() RS:UnbindFromRenderStep(SWIM_BIND) end)
  swimBound=false
 end
 local _,h=ch()
 if h then pcall(function() h.AutoRotate=true end) end
end

RS.Heartbeat:Connect(function()
 if not RUN then return end
 local c,h,hp=ch()
 if not h or not hp then return end
 local sw=false
 pcall(function() sw=h:GetState()==Enum.HumanoidStateType.Swimming end)
 local aktifSwim=sw and vis.swim

 if aktifSwim and not swimBound then
  swimBound=true
  pcall(function() h.AutoRotate=false end)
  pcall(function()
   RS:BindToRenderStep(SWIM_BIND,Enum.RenderPriority.Character.Value+1,function()
    local c2,h2,hp2=ch()
    if not h2 or not hp2 then return end
    local st2=false
    pcall(function() st2=h2:GetState()==Enum.HumanoidStateType.Swimming end)
    if not (st2 and vis.swim) then return end
    local cam=workspace.CurrentCamera
    local cl=cam and cam.CFrame.LookVector
    local face=cl and Vector3.new(cl.X,0,cl.Z)
    if face and face.Magnitude>0.01 then
     local yaw=math.atan2(-face.X,-face.Z)
     hp2.CFrame=CFrame.new(hp2.Position)*CFrame.Angles(0,yaw,0)
    end
   end)
  end)
 elseif not aktifSwim and swimBound then
  unbindSwim()
 end
end)

-- ================= LOOPS =================
local curSpeed=nil

RS.Heartbeat:Connect(function(dt)
 if not RUN then return end
 local _,h=ch()
 if not h then return end
 if h.FloorMaterial~=Enum.Material.Air then mv.djOK=true end

 local jpT=mv.jump and cfg.jOn or cfg.jOff
 pcall(function()
  if not h.UseJumpPower then h.UseJumpPower=true end
  local cur=h.JumpPower
  local newJp=cur+(jpT-cur)*math.clamp(dt*6,0,1)
  if math.abs(newJp-jpT)<0.05 then newJp=jpT end
  if math.abs(h.JumpPower-newJp)>0.01 then h.JumpPower=newJp end
 end)

 if curSpeed==nil then curSpeed=h.WalkSpeed end
 local target
 if mv.sprint then target=cfg.sOn
 elseif mv.walk then target=cfg.wOn
 else target=cfg.wOff end
 local swimming=false
 pcall(function() swimming=h:GetState()==Enum.HumanoidStateType.Swimming end)
 if swimming and vis.swim then target=target*SWIM_BOOST end
 curSpeed=curSpeed+(target-curSpeed)*math.clamp(dt*3,0,1)
 if math.abs(target-curSpeed)<0.01 then curSpeed=target end
 if math.abs(h.WalkSpeed-curSpeed)>0.005 then
  pcall(function() h.WalkSpeed=curSpeed end)
 end
end)

UIS.JumpRequest:Connect(function()
 if not RUN or not mv.dj or not mv.djOK then return end
 local _,h=ch()
 if h and h.FloorMaterial==Enum.Material.Air
 and h:GetState()~=Enum.HumanoidStateType.Swimming then
  mv.djOK=false
  pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
 end
end)

LP.CharacterAdded:Connect(function(c)
 rayUpd() mv.djOK=true curSpeed=nil
 unbindSwim()
 task.spawn(function()
  local h=c:WaitForChild("Humanoid",10)
  if h then orig={ws=h.WalkSpeed,jp=h.JumpPower,u=h.UseJumpPower} end
 end)
end)

-- ================================================================
--  FALL ASSIST v3 (SIMPLE - FINAL)
--  Jatuh normal kencang -> NYENGGOL SEKALI di 80% perjalanan
--  (velocity vertikal langsung jadi -30, tanpa pantulan)
--  + landed-semu (reset persepsi jatuh game)
--  WASD bebas. Darah tidak disentuh. Tanpa notif.
-- ================================================================
local fJatuh=false
local fApex=0
local fBentur=false
local fSejak=0

RS.Heartbeat:Connect(function(dt)
 if not RUN or not mv.fall then return end
 local c,h,hp=ch()
 if not h or not hp then return end
 local now=os.clock()
 local v=hp.AssemblyLinearVelocity

 local st=h:GetState()

 if st==Enum.HumanoidStateType.Freefall and v.Y<-4 then
  if not fJatuh then
   fJatuh=true
   fApex=hp.Position.Y
   fBentur=false
   fSejak=now
  end
  fApex=math.max(fApex,hp.Position.Y)
  local sudahTurun=fApex-hp.Position.Y

  -- ukur tinggi total jatuh (dari apex ke tanah)
  local r=workspace:Raycast(hp.Position,Vector3.new(0,-800,0),ray)
  local tinggiTotal,sisaJatuh
  if r then
   sisaJatuh=hp.Position.Y-r.Position.Y
   tinggiTotal=fApex-r.Position.Y
  end

  -- ===== NYENGGOL SEKALI di POSISI BENTUR (80%) =====
  if not fBentur and sudahTurun>10 and v.Y<-40 then
   local picu=false
   -- syarat utama: tinggi jatuh >= MIN JATUH & sudah melewati titik 80%
   if tinggiTotal and tinggiTotal>=cfg.fMinJatuh
   and sisaJatuh<=tinggiTotal*(1-cfg.fPosisi) then
    picu=true
   end
   -- jaring pengaman internal: kalau tanah tak terdeteksi
   -- dan sudah lama jatuh kencang, lakukan nyenggolan sekarang
   if not picu and not tinggiTotal and (now-fSejak)>0.6 and v.Y<-70 then
    picu=true
   end
   if picu then
    fBentur=true
    -- velocity vertikal langsung jadi -30 (ala kena tepi)
    -- WASD (horizontal) tidak disentuh
    pcall(function()
     local hor=Vector3.new(v.X,0,v.Z)
     hp.AssemblyLinearVelocity=Vector3.new(hor.X,cfg.fBenturKe,hor.Z)
    end)
    -- landed-semu: game mengira sudah mendarat sekali
    task.delay(0.03,function()
     if not RUN then return end
     pcall(function()
      local _,h2,_=ch()
      if h2 and h2:GetState()==Enum.HumanoidStateType.Freefall then
       h2:ChangeState(Enum.HumanoidStateType.Landed)
       task.delay(0.03,function()
        if not RUN then return end
        pcall(function()
         local _,h3,_=ch()
         if h3 and h3:GetState()==Enum.HumanoidStateType.Landed then
          h3:ChangeState(Enum.HumanoidStateType.Freefall)
         end
        end)
       end)
      end
     end)
    end)
   end
  end

 elseif fJatuh then
  -- mendarat: reset, siap untuk jatuh berikutnya
  fJatuh=false
  fBentur=false
 end
end)

-- ESP + tag
task.spawn(function()
 while RUN do
  task.wait(1)
  if vis.esp and HOK then
   for _,p in ipairs(Players:GetPlayers()) do
    if p~=LP and p.Character then
     local h=espF[p]
     if h and not h.Parent then h=nil espF[p]=nil end
     if not h then
      pcall(function()
       local x=Instance.new("Highlight")
       x.Name="SilauESP"
       x.FillTransparency=0.75 x.FillColor=wTeam(p) x.OutlineColor=wTeam(p)
       x.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
       x.Parent=p.Character
       espF[p]=x
      end)
     end
    end
   end
  end
  if vis.tag then
   for _,p in ipairs(Players:GetPlayers()) do
    if p~=LP and p.Character and not tagF[p] then
     local hd=p.Character:FindFirstChild("Head")
     if hd then
      pcall(function()
       local b=Instance.new("BillboardGui")
       b.Name="SilauTag" b.Size=UDim2.fromOffset(176,64)
       b.StudsOffset=Vector3.new(0,3,0) b.AlwaysOnTop=true b.Parent=hd
       local bg=Instance.new("Frame")
       bg.Size=UDim2.new(1,0,1,0) bg.BackgroundColor3=C.bg
       bg.BackgroundTransparency=0.25 bg.BorderSizePixel=0 bg.Parent=b
       local bc=Instance.new("UICorner") bc.CornerRadius=UDim.new(0,8) bc.Parent=bg
       local bs=Instance.new("UIStroke")
       bs.Color=C.ungu bs.Thickness=1 bs.Transparency=0.5 bs.Parent=bg
       local l1=Instance.new("TextLabel")
       l1.Size=UDim2.new(1,0,0,22) l1.BackgroundTransparency=1
       l1.Font=F_B l1.TextSize=14 l1.TextColor3=C.putih
       l1.TextStrokeTransparency=0.3 l1.Text=p.DisplayName l1.Parent=bg
       local l2=Instance.new("TextLabel")
       l2.Position=UDim2.new(0,0,0,23) l2.Size=UDim2.new(1,0,0,20)
       l2.BackgroundTransparency=1 l2.Font=F_B l2.TextSize=12
       l2.TextColor3=Color3.fromRGB(140,230,160) l2.TextStrokeTransparency=0.35
       l2.Text="..." l2.Parent=bg
       local l3=Instance.new("TextLabel")
       l3.Position=UDim2.new(0,0,0,44) l3.Size=UDim2.new(1,0,0,17)
       l3.BackgroundTransparency=1 l3.Font=F_M l3.TextSize=11
       l3.TextColor3=C.abuT l3.TextStrokeTransparency=0.4 l3.Text="" l3.Parent=bg
       tagF[p]={bb=b,inf=l2,dst=l3}
      end)
     end
    end
   end
  end
 end
end)

task.spawn(function()
 while RUN do
  task.wait(0.3)
  local _,_,mh=ch()
  if vis.tag and mh then
   for p,d in pairs(tagF) do
    if p.Parent and p.Character then
     local h2=p.Character:FindFirstChildOfClass("Humanoid")
     local hp2=p.Character:FindFirstChild("HumanoidRootPart")
     if h2 and hp2 and d.inf then
      local sp=h2.WalkSpeed
      local jp=h2.UseJumpPower and h2.JumpPower or h2.JumpHeight
      local ds=(hp2.Position-mh.Position).Magnitude
      local cg=sp>cfg.wOn+0.05 or (h2.UseJumpPower and jp>cfg.jOff+0.05)
      d.inf.Text=string.format("SPD %.1f | JMP %.1f%s",sp,jp,cg and "  !!" or "")
      d.inf.TextColor3=cg and C.merah or Color3.fromRGB(140,230,160)
      d.dst.Text=string.format("%d STUD",ds)
     end
    else
     if d.inf then d.inf.Text="..." end
     if d.dst then d.dst.Text="" end
    end
   end
  end
  if vis.hideP then
   for _,p in ipairs(Players:GetPlayers()) do
    if p~=LP and p.Character then
     for _,d in ipairs(p.Character:GetDescendants()) do
      if d:IsA("BasePart") and not table.find(hidP,d) then
       pcall(function()
        d.LocalTransparencyModifier=0.85
        table.insert(hidP,d)
       end)
      end
     end
    end
   end
  end
 end
end)

task.spawn(function()
 while RUN do
  task.wait(1)
  if vis.br then
   pcall(function()
    local t=LG.ClockTime
    if t>=18 or t<6 then
     LG.Brightness=3
     LG.Ambient=Color3.fromRGB(140,140,165)
     LG.OutdoorAmbient=Color3.fromRGB(140,140,165)
    else
     LG.Brightness=1
     LG.Ambient=Color3.fromRGB(110,110,120)
     LG.OutdoorAmbient=Color3.fromRGB(110,110,120)
    end
   end)
  end
  if vis.wall and math.random()<0.08 then
   for _,d in ipairs(workspace:GetDescendants()) do
    pcall(function()
     if d:IsA("BasePart") and not wallP[d] and d.Transparency>0.5 and d.CanCollide then
      wallP[d]={t=d.Transparency,c=d.Color}
      d.Transparency=0.55 d.Color=Color3.fromRGB(205,205,205)
     end
    end)
   end
  end
 end
end)

-- ===== MOONWALK: badan TERKUNCI menghadap kamera/layar =====
-- apapun tombol: W=melangkah mundur, S=maju, A/D=samping,
-- lompat pun wajah tetap ke layar (seperti shiftlock terbalik)
RS.RenderStepped:Connect(function()
 if not RUN or not vis.moon then return end
 if vis.swim then return end
 local c,h,hp=ch()
 if not h or not hp then return end
 local cam=workspace.CurrentCamera
 if not cam then return end
 local _,yaw=cam.CFrame:ToOrientation()
 pcall(function()
  hp.CFrame=CFrame.new(hp.Position)*CFrame.Angles(0,yaw+math.pi,0)
 end)
end)

local fc=0
RS.RenderStepped:Connect(function() if RUN then fc+=1 end end)
task.spawn(function()
 while RUN do
  task.wait(1)
  local fps=fc fc=0
  local ping=0
  pcall(function() ping=math.floor(LP:GetNetworkPing()*1000) end)
  if pFp.Visible then
   fpL.Text=string.format("FPS: %d  |  %d ms",fps,ping)
   fpL.TextColor3=(fps>=50 and Color3.fromRGB(140,230,160))
    or (fps>=25 and Color3.fromRGB(250,204,21)) or C.merah
  end
 end
end)

task.spawn(function()
 while RUN do
  task.wait(0.25)
  if pSt.Visible then
   local _,h,hp=ch()
   if h then
    local jp=h.UseJumpPower and h.JumpPower or h.JumpHeight
    stL.Text=string.format("Speed : %.2f stud/s\nJump  : %.2f\nHP    : %.0f / %.0f\nMode  : %s",
     h.WalkSpeed,jp,h.Health,h.MaxHealth,
     mv.sprint and "SPRINT" or (mv.walk and "WALK" or "NORMAL"))
   end
  end
 end
end)

LP.Idled:Connect(function()
 if RUN and hud.afk then
  pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end)
 end
end)
task.spawn(function()
 while RUN do
  task.wait(240+math.random(0,60))
  if RUN and hud.afk then
   pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end)
  end
 end
end)

-- ================= TAB & BUKA/TUTUP =================
local function tab(n)
 for i=1,3 do
  tf[i].Visible=i==n
  tb[i].b.BackgroundColor3=i==n and C.card2 or C.card
  tb[i].b.TextColor3=i==n and C.putih or C.abuT
  tb[i].s.Color=i==n and C.ungu or C.abu
  tb[i].s.Transparency=i==n and 0.2 or 0.6
 end
 snd(.15,1+.1*n)
end
for i,t in ipairs(tb) do
 t.b.MouseButton1Click:Connect(function() tab(i) end)
end

local function minimize()
 root.Visible=false
 snd(.15,.75)
end
local function buka()
 root.Visible=true
 snd(.2,1.15)
end
minB.MouseButton1Click:Connect(minimize)

local helpF=mk("Frame",{Position=UDim2.new(0,10,0,78),
 Size=UDim2.new(1,-20,1,-88),BackgroundColor3=C.card,Visible=false,
 ZIndex=60,BorderSizePixel=0},root)
corner(helpF,10)
mk("UIStroke",{Color=C.ungu,Thickness=1,Transparency=0.4,ZIndex=60},helpF)
mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,10,0,6),
 Size=UDim2.new(1,-20,1,-44),Font=F_R,TextSize=10,TextColor3=C.putih,
 TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
 Text="F      : buka/tutup GUI\nQ      : speed ON/OFF\nQ Q    : sprint (Q lagi = OFF)\nV      : jump power ON/OFF\nG      : moonwalk ON/OFF\nR      : hide player\nT      : auto brightness\nC      : renang katak +15%\nX      : dinding tak terlihat\nZ      : info player\nK K    : hapus script (konfirmasi)",
 ZIndex=61},helpF)
local hClose=mk("TextButton",{Size=UDim2.new(1,-20,0,24),Position=UDim2.new(0,10,1,-30),
 BackgroundColor3=C.ungu,Font=F_B,TextSize=11,TextColor3=C.putih,
 Text="X TUTUP",ZIndex=61},helpF)
corner(hClose,7)
hClose.MouseButton1Click:Connect(function() helpF.Visible=false end)
local helpB=mk("TextButton",{BackgroundColor3=C.card2,Size=UDim2.fromOffset(26,26),
 Position=UDim2.new(1,-64,0,7),Font=F_B,TextSize=12,TextColor3=C.putih,Text="?",
 AutoButtonColor=false,ZIndex=55},root)
corner(helpB,6)
helpB.MouseButton1Click:Connect(function()
 helpF.Visible=not helpF.Visible
 snd(.15,helpF.Visible and 1.2 or .9)
end)

-- ================= KILL =================
kill=function()
 RUN=false
 unbindSwim()
 pcall(function()
  local _,h=ch()
  if h then
   h.WalkSpeed=orig.ws h.JumpPower=orig.jp h.UseJumpPower=orig.u
  end
 end)
 for _,d in pairs(espF) do pcall(function() d:Destroy() end) end
 for _,t in pairs(tagF) do pcall(function() t.bb:Destroy() end) end
 for d,o in pairs(wallP) do pcall(function() d.Transparency=o.t d.Color=o.c end) end
 for _,p in ipairs(hidP) do pcall(function() p.LocalTransparencyModifier=0 end) end
 for _,d in ipairs(hidFX) do pcall(function() d.Enabled=true end) end
 pcall(function()
  LG.Brightness=oLight.B LG.Ambient=oLight.A LG.OutdoorAmbient=oLight.O
 end)
 pcall(function() g:Destroy() end)
 print("[SilauHub] dihapus total")
end

-- ================= KEYBIND =================
local qLast,kLast=0,0
UIS.InputBegan:Connect(function(inp,gp)
 if not RUN or gp then return end
 if UIS:GetFocusedTextBox() then return end
 local k=inp.KeyCode
 if k==Enum.KeyCode.F then
  if root.Visible then minimize() else buka() end
 elseif k==Enum.KeyCode.Q then
  if mv.sprint then
   tgS.set(false) tgW.set(false)
  else
   local now=os.clock()
   if now-qLast<0.3 then
    qLast=0 tgS.set(true)
   else
    qLast=now
    task.delay(0.32,function()
     if qLast~=0 and os.clock()-qLast>=0.3 then
      qLast=0
      tgW.set(not tgW.s)
     end
    end)
   end
  end
 elseif k==Enum.KeyCode.T then
  tglBr.set(not vis.br)
 elseif k==Enum.KeyCode.C then
  siklusSwim()
 elseif k==Enum.KeyCode.X then
  tglWall.set(not vis.wall)
 elseif k==Enum.KeyCode.Z then
  tglTag.set(not vis.tag)
 elseif k==Enum.KeyCode.R then
  tgHideP.set(not vis.hideP)
 elseif k==Enum.KeyCode.V then
  tgJump.set(not mv.jump)
 elseif k==Enum.KeyCode.G then
  tgMoon.set(not vis.moon)
 elseif k==Enum.KeyCode.K then
  local now=os.clock()
  if now-kLast<2 then
   kLast=0
   notif("MENGHAPUS SIIILAU HUB...",false)
   task.wait(0.3)
   kill()
  else
   kLast=now
   notif("TEKAN K LAGI UNTUK HAPUS!",true)
   task.delay(2.1,function()
    if kLast~=0 and os.clock()-kLast>=2 then kLast=0 end
   end)
  end
 end
end)

-- ================= MULAI =================
tab(1)
task.delay(0.4,function() buka() end)
task.delay(1.2,function()
 notif("SIIILAU HUB SIAP - TEKAN F",true)
end)

print("[SilauHub] v1.0.1 SIAP (tema King Silau)")

end)

if not ok then fatal(e) end
