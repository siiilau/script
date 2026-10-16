--========================================================
--  SIIILAU HUB SCRIPTS v1.0.01
--  F=GUI  Q=speed  Q Q=sprint  V=jump  R=hide player
--  T=brightness  C=renang  X=dinding  Z=info  K K=hapus
--
--  SMART FALL ASSIST (mesin baru):
--   jatuh bebas normal -> BENTURAN di 50% ketinggian
--   (sentakan sekali, seperti nabrak pipa tak terlihat)
--   -> jatuh lanjut normal terpagar -42/s
--   -> 12 stud terakhir diperlunak ke -28/s
--   -> mendarat pelan, damage minimum
--   Darah TIDAK disentuh sama sekali.
--========================================================
print("[SilauHub] v1.0.01 loading...")

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
 t.BackgroundColor3=Color3.fromRGB(40,0,0) t.TextColor3=Color3.fromRGB(255,120,120)
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

-- ================= NILAI (bisa diubah lewat GUI) =================
local cfg={
 wOff=17.10, wOn=17.25,
 sOff=21.10, sOn=21.25,
 jOff=55.00, jOn=65.00,
 -- fall assist
 fMinJatuh=30, fPosisi=0.50, fCadang=-70,
 fBenturKe=-14, fBenturDur=0.15,
 fPagar=-42, fLembutJarak=12, fLembutKe=-28,
}

-- ================= WARNA =================
local C={
 bg=Color3.fromRGB(12,10,20), bg2=Color3.fromRGB(22,18,38),
 pink=Color3.fromRGB(236,72,153), pink2=Color3.fromRGB(251,207,232),
 ungu=Color3.fromRGB(124,58,237), ungu2=Color3.fromRGB(167,139,250),
 unguM=Color3.fromRGB(237,233,254),
 biru=Color3.fromRGB(59,130,246), biruM=Color3.fromRGB(219,234,254),
 putih=Color3.new(1,1,1), putihLap=Color3.fromRGB(250,250,255),
 abu=Color3.fromRGB(246,245,252), teks=Color3.fromRGB(28,24,46),
 abuT=Color3.fromRGB(130,125,155), abuG=Color3.fromRGB(200,198,215),
 merah=Color3.fromRGB(239,68,68), merahM=Color3.fromRGB(254,202,202),
 hijau=Color3.fromRGB(34,197,94), hijauM=Color3.fromRGB(187,247,208),
 kuning=Color3.fromRGB(250,204,21),
}
local F_TITLE=Enum.Font.Bangers
local F_BOLD=Enum.Font.GothamBold
local F_SEMI=Enum.Font.GothamSemibold
local F_REG=Enum.Font.Gotham

-- ================= STATE =================
local mv={walk=false,sprint=false,jump=false,dj=false,fall=false,djOK=true}
local vis={esp=false,tag=false,cross=0,moon=false,hideP=false,fx=false,br=false,swim=0,wall=false}
local hud={afk=true}
local espF,tagF,hidP,hidFX,wallP={},{},{},{},{}
local gyro=nil
local kill=nil
local orig={ws=16,jp=50,u=true}
local oLight={B=LG.Brightness,A=LG.Ambient,O=LG.OutdoorAmbient}
local ray=RaycastParams.new()
pcall(function() ray.FilterType=Enum.RaycastFilterType.Exclude end)
local HOK=pcall(function() local t=Instance.new("Highlight") t:Destroy() end)
print("[SilauHub] Highlight:",HOK)

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
print("[SilauHub] GUI di:",pg:GetFullName())

local function mk(cl,pr,par)
 local o=Instance.new(cl)
 for k,v in pairs(pr) do o[k]=v end
 o.Parent=par return o
end
local function tw(o,t,p)
 local x=TS:Create(o,TweenInfo.new(t or .25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),p)
 x:Play() return x
end
local function corner(p,r) return mk("UICorner",{CornerRadius=UDim.new(0,r or 8)},p) end
local function stroke(p,c,t,tr) return mk("UIStroke",{Color=c,Thickness=t or 1,Transparency=tr or 0},p) end

local function ledLoop(inst,base,a,b,dur)
 local gr=mk("UIGradient",{Color=ColorSequence.new({
  ColorSequenceKeypoint.new(0,base),ColorSequenceKeypoint.new(.4,base),
  ColorSequenceKeypoint.new(.47,a),ColorSequenceKeypoint.new(.54,b),
  ColorSequenceKeypoint.new(.61,base),ColorSequenceKeypoint.new(1,base)}),
  Offset=Vector2.new(-1,0)},inst)
 task.spawn(function()
  while inst.Parent and RUN do
   local t=TS:Create(gr,TweenInfo.new(dur or 2.4,Enum.EasingStyle.Linear),
    {Offset=Vector2.new(1,0)})
   t:Play() t.Completed:Wait()
   gr.Offset=Vector2.new(-1,0)
   task.wait(.15)
  end
 end)
 return gr
end

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

local function snd(id,v,p)
 pcall(function()
  local s=Instance.new("Sound")
  s.SoundId=id s.Volume=v or .3 s.PlaybackSpeed=p or 1
  s.Parent=g s:Play()
  task.delay(2.5,function() s:Destroy() end)
 end)
end
local S_PING="rbxasset://sounds/electronicpingshort.wav"

-- ================= HUD =================
local hudF=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1},g)

local function mkPanel(pos,size,judul,aksen)
 local p=mk("Frame",{Position=pos,Size=size,BackgroundColor3=C.bg2,
  BackgroundTransparency=0.08,BorderSizePixel=0,Active=true},hudF)
 corner(p,10)
 local st=stroke(p,aksen,1,0.35)
 task.spawn(function()
  while p.Parent and RUN do
   tw(st,.9,{Transparency=0.65}).Completed:Wait()
   tw(st,.9,{Transparency=0.35}).Completed:Wait()
  end
 end)
 mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,9,0,3),
  Size=UDim2.new(1,-18,0,13),Font=F_SEMI,TextSize=9,
  TextColor3=C.pink2,Text=judul,TextXAlignment=Enum.TextXAlignment.Left},p)
 drag(p,p)
 return p
end

-- STATUS kiri bawah
local pSt=mkPanel(UDim2.new(0,10,1,-176),UDim2.fromOffset(200,120),"STATUS",C.ungu)
local stL=mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,9,0,17),
 Size=UDim2.new(1,-18,1,-20),Font=F_REG,TextSize=10,TextColor3=C.putih,
 Text="...",TextXAlignment=Enum.TextXAlignment.Left,
 TextYAlignment=Enum.TextYAlignment.Top},pSt)

-- FPS kiri bawah
local pFp=mkPanel(UDim2.new(0,10,1,-48),UDim2.fromOffset(200,40),"FPS / PING",C.hijau)
local fpL=mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,9,0,16),
 Size=UDim2.new(1,-18,1,-19),Font=F_BOLD,TextSize=11,
 TextColor3=C.hijauM,Text="FPS ...  |  ... MS",TextXAlignment=Enum.TextXAlignment.Left},pFp)

-- NOTIF kanan atas
local nf=mk("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-10,0,10),
 Size=UDim2.fromOffset(220,340),BackgroundTransparency=1},hudF)
mk("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder,
 HorizontalAlignment=Enum.HorizontalAlignment.Right},nf)
local no=0
local function notif(tx,c)
 no+=1
 local n=mk("Frame",{Size=UDim2.new(1,0,0,26),BackgroundColor3=C.bg2,
  BackgroundTransparency=0.08,LayoutOrder=no},nf)
 corner(n,8) stroke(n,c or C.ungu,1,0.3)
 local lb=mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,0),
  Size=UDim2.new(1,-16,1,0),Font=F_SEMI,TextSize=10,TextColor3=C.putih,Text=tx,
  TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},n)
 lb.TextTransparency=1
 tw(lb,.22,{TextTransparency=0})
 task.delay(3,function()
  if n.Parent then tw(n,.25,{BackgroundTransparency=1}) end
  task.delay(.3,function() pcall(function() n:Destroy() end) end)
 end)
 local k=0
 for _,x in ipairs(nf:GetChildren()) do if x:IsA("Frame") then k+=1 end end
 if k>6 then
  for _,x in ipairs(nf:GetChildren()) do if x:IsA("Frame") then x:Destroy() break end end
 end
end

-- ================= PANEL UTAMA =================
local root=mk("Frame",{Size=UDim2.fromOffset(350,505),
 Position=UDim2.new(0.5,0,0.08,0),AnchorPoint=Vector2.new(0.5,0),
 BackgroundTransparency=1,Visible=false},g)

local outer=mk("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.bg},root)
corner(outer,16)
local outSt=stroke(outer,C.pink,3)
local outGrad=mk("UIGradient",{Color=ColorSequence.new({
 ColorSequenceKeypoint.new(0,C.pink),ColorSequenceKeypoint.new(.25,C.ungu),
 ColorSequenceKeypoint.new(.5,C.biru),ColorSequenceKeypoint.new(.75,C.pink),
 ColorSequenceKeypoint.new(1,C.ungu2)})},outSt)
task.spawn(function()
 while outGrad.Parent and RUN do
  local t=tw(outGrad,4.5,{Rotation=360})
  t.Completed:Wait() outGrad.Rotation=0
 end
end)

local panel=mk("Frame",{Size=UDim2.new(1,-8,1,-8),Position=UDim2.new(0,4,0,4),
 BackgroundColor3=C.putihLap},outer)
corner(panel,11) stroke(panel,C.pink2,1,0.35)
ledLoop(panel,C.putihLap,C.putih,C.pink2,5)

local acc=mk("Frame",{Size=UDim2.new(1,0,0,2),Position=UDim2.new(0,0,0,40),
 BorderSizePixel=0,BackgroundColor3=C.biru},panel)
ledLoop(acc,C.biru,C.putih,C.pink,2.6)

local hdr=mk("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=C.bg2,Active=true},panel)
corner(hdr,11)
local ttl=mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,0),
 Size=UDim2.new(1,-110,1,0),Font=F_TITLE,TextSize=19,TextColor3=C.putih,
 Text="SIIILAU HUB",TextXAlignment=Enum.TextXAlignment.Left},hdr)
ledLoop(ttl,C.putih,C.pink2,C.biru,2.2)
local ttlSt=stroke(ttl,C.pink2,1,0.35)
task.spawn(function()
 while ttlSt.Parent and RUN do
  tw(ttlSt,.8,{Transparency=.7}).Completed:Wait()
  tw(ttlSt,.8,{Transparency=.35}).Completed:Wait()
 end
end)

local helpB=mk("TextButton",{Size=UDim2.fromOffset(26,26),
 Position=UDim2.new(1,-66,0.5,-13),BackgroundColor3=C.bg,
 Font=F_BOLD,TextSize=14,TextColor3=C.pink2,Text="?"},hdr)
corner(helpB,9) stroke(helpB,C.pink,1,0.3)
local minB=mk("TextButton",{Size=UDim2.fromOffset(26,26),
 Position=UDim2.new(1,-34,0.5,-13),BackgroundColor3=C.bg,
 Font=F_BOLD,TextSize=14,TextColor3=C.putih,Text="-"},hdr)
corner(minB,9) stroke(minB,C.ungu,1,0.3)
drag(hdr,root)

local tbar=mk("Frame",{Position=UDim2.new(0,10,0,46),Size=UDim2.new(1,-20,0,28),
 BackgroundTransparency=1},panel)
mk("UIListLayout",{Padding=UDim.new(0,4),FillDirection=Enum.FillDirection.Horizontal},tbar)
local tb={}
for i,nm in ipairs({"MOVEMENT","VISUAL","HUD"}) do
 local b=mk("TextButton",{Size=UDim2.new(1/3,-3,1,0),
  BackgroundColor3=i==1 and C.bg2 or C.abu,Font=F_BOLD,TextSize=10,
  TextColor3=i==1 and C.putih or C.teks,Text=nm},tbar)
 corner(b,8)
 tb[i]={b=b,s=stroke(b,i==1 and C.pink or C.abuT,1,i==1 and 0 or .6)}
end

local tf={}
for i=1,3 do
 tf[i]=mk("ScrollingFrame",{Position=UDim2.new(0,10,0,80),
  Size=UDim2.new(1,-20,1,-108),BackgroundTransparency=1,ScrollBarThickness=3,
  ScrollBarImageColor3=C.pink,AutomaticCanvasSize=Enum.AutomaticSize.Y,
  CanvasSize=UDim2.new(),Visible=i==1},panel)
 mk("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},tf[i])
end

task.spawn(function()
 local cols={C.pink,C.ungu,C.biru}
 while RUN do
  task.wait(.5)
  if root.Visible and RUN then
   local x0=math.random(6,94)/100
   local d=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.new(x0,0,1.05,0),Size=UDim2.fromOffset(math.random(3,5),math.random(3,5)),
    BackgroundColor3=cols[math.random(1,#cols)],BackgroundTransparency=.4,
    BorderSizePixel=0},panel)
   corner(d,10)
   local dur=math.random(28,44)/10
   tw(d,dur,{Position=UDim2.new(x0+math.random(-5,5)/100,0,-0.05,0),BackgroundTransparency=1})
   task.delay(dur+.05,function() pcall(function() d:Destroy() end) end)
  end
 end
end)

-- ================= FACTORY =================
local oc={0,0,0}
local function rSect(ti,tx)
 oc[ti]+=1
 return mk("TextLabel",{Size=UDim2.new(1,-4,0,20),BackgroundTransparency=1,
  Font=F_BOLD,TextSize=10,TextColor3=C.ungu,Text="-- "..tx.." --",
  TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=oc[ti]},tf[ti])
end
local function rInfo(ti,tx,h)
 oc[ti]+=1
 return mk("TextLabel",{Size=UDim2.new(1,-4,0,h or 26),BackgroundTransparency=1,
  Font=F_REG,TextSize=9,TextColor3=C.abuT,Text=tx,TextWrapped=true,
  TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=oc[ti]},tf[ti])
end
local function mkSwitch(row,initial)
 local sw=mk("TextButton",{Size=UDim2.fromOffset(42,20),
  Position=UDim2.new(1,-50,0.5,-10),BackgroundColor3=initial and C.hijau or C.merah,
  Text="",AutoButtonColor=false},row)
 corner(sw,10)
 stroke(sw,initial and C.hijau or C.merah,1,.35)
 local kn=mk("Frame",{Size=UDim2.fromOffset(14,14),
  Position=initial and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
  BackgroundColor3=C.putih},sw)
 corner(kn,7)
 return sw,kn
end
local function rTgl(ti,tx,ini,cb)
 oc[ti]+=1
 local row=mk("Frame",{Size=UDim2.new(1,-4,0,28),BackgroundColor3=C.abu,
  LayoutOrder=oc[ti]},tf[ti])
 corner(row,8)
 mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,0),
  Size=UDim2.new(1,-64,1,0),Font=F_SEMI,TextSize=10,TextColor3=C.teks,Text=tx,
  TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},row)
 local sw,kn=mkSwitch(row,ini)
 local o={s=ini}
 o.set=function(v)
  o.s=v
  tw(sw,.15,{BackgroundColor3=v and C.hijau or C.merah})
  tw(kn,.15,{Position=v and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)})
  snd(S_PING,.25,v and 1.15 or .9)
  pcall(function() cb(v) end)
 end
 sw.MouseButton1Click:Connect(function() o.set(not o.s) end)
 return o
end
local function rAct(ti,tx,cb,h)
 oc[ti]+=1
 local b=mk("TextButton",{Size=UDim2.new(1,-4,0,h or 28),BackgroundColor3=C.ungu,
  Font=F_BOLD,TextSize=10,TextColor3=C.putih,Text=tx,
  AutoButtonColor=false,LayoutOrder=oc[ti]},tf[ti])
 corner(b,8)
 ledLoop(b,C.ungu,C.putih,C.pink,2.6)
 b.MouseButton1Click:Connect(function()
  snd(S_PING,.25,1.1)
  pcall(function() cb(b) end)
 end)
 return b
end
local function rNum(ti,label,default,cb)
 oc[ti]+=1
 local row=mk("Frame",{Size=UDim2.new(1,-4,0,26),BackgroundColor3=C.abu,
  LayoutOrder=oc[ti]},tf[ti])
 corner(row,8)
 mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,0),
  Size=UDim2.new(1,-84,1,0),Font=F_SEMI,TextSize=10,TextColor3=C.teks,
  Text=label,TextXAlignment=Enum.TextXAlignment.Left},row)
 local bx=mk("TextBox",{Size=UDim2.fromOffset(64,18),Position=UDim2.new(1,-72,0.5,-9),
  BackgroundColor3=C.putih,Font=F_BOLD,TextSize=10,Text=string.format("%.2f",default),
  TextColor3=C.ungu,ClearTextOnFocus=false},row)
 corner(bx,6) stroke(bx,C.ungu,1,.5)
 bx.FocusLost:Connect(function()
  local n=tonumber((bx.Text:gsub("[^%d%.%-]","")))
  if n then
   if label:find("CADANG") or label:find("PAGAR") or label:find("BENTUR KE")
   or label:find("LEMBUT KE") then n=-math.abs(n) end
   cb(n) bx.Text=string.format("%.2f",n)
   notif(label.." = "..string.format("%.2f",n),C.biru)
  else
   bx.Text=string.format("%.2f",default)
  end
 end)
end

-- ================= TAB 1 : MOVEMENT =================
local infoSpeed
infoSpeed=rInfo(1,"")
local function updInfoSpeed()
 infoSpeed.Text="OFF "..string.format("%.2f",cfg.wOff)
  .."  |  WALK "..string.format("%.2f",cfg.wOn).." [Q]"
  .."  |  SPRINT "..string.format("%.2f",cfg.sOn).." [Q Q]"
end
updInfoSpeed()

local tgW=rTgl(1,"WALK SPEED [Q]",false,function(v)
 mv.walk=v
 notif(v and ("WALK "..string.format("%.2f",cfg.wOn).." ON")
  or ("SPEED NORMAL "..string.format("%.2f",cfg.wOff)),C.biru)
end)
local lblS=rInfo(1,"SPRINT OFF - tekan Q dua kali")
local tgS=rTgl(1,"SPRINT [Q Q]",false,function(v)
 mv.sprint=v
 if v then
  lblS.Text="SPRINT AKTIF -> "..string.format("%.2f",cfg.sOn).." stud/s"
  notif("SPRINT ON "..string.format("%.2f",cfg.sOn),C.pink)
 else
  lblS.Text="SPRINT OFF - melambat halus"
  notif("SPRINT OFF - transisi "..string.format("%.2f",cfg.sOff),C.pink)
 end
end)

rSect(1,"LOMPATAN")
local tgJump=rTgl(1,"JUMP POWER [V] (ON "..string.format("%.0f",cfg.jOn).." / OFF "..string.format("%.0f",cfg.jOff)..")",false,function(v)
 mv.jump=v
 notif(v and ("JUMP "..string.format("%.0f",cfg.jOn).." ON")
  or ("JUMP NORMAL "..string.format("%.0f",cfg.jOff)),C.ungu)
end)
rTgl(1,"DOUBLE JUMP (1X EXTRA)",false,function(v)
 mv.dj=v mv.djOK=true
 notif(v and "DOUBLE JUMP ON" or "DOUBLE JUMP OFF",C.biru)
end)

rSect(1,"JATUH CERDAS")
local tgFall=rTgl(1,"SMART FALL ASSIST",false,function(v)
 mv.fall=v
 notif(v and "FALL ASSIST ON" or "FALL ASSIST OFF",C.hijau)
end)
rInfo(1,"Jatuh bebas normal -> TERBENTUR di 50% ketinggian\n(sentakan sekali, seperti nabrak pipa)\n-> jatuh lanjut terpagar -> mendarat pelan.\nDarah tidak disentuh - damage tampil normal.",46)

rSect(1,"PENGATURAN NILAI")
rNum(1,"SPEED OFF",cfg.wOff,function(n) cfg.wOff=n updInfoSpeed() end)
rNum(1,"SPEED ON",cfg.wOn,function(n) cfg.wOn=n updInfoSpeed() end)
rNum(1,"SPRINT OFF",cfg.sOff,function(n) cfg.sOff=n updInfoSpeed() end)
rNum(1,"SPRINT ON",cfg.sOn,function(n) cfg.sOn=n updInfoSpeed() end)
rNum(1,"JUMP OFF",cfg.jOff,function(n) cfg.jOff=n end)
rNum(1,"JUMP ON",cfg.jOn,function(n) cfg.jOn=n end)

rSect(1,"PENGATURAN FALL ASSIST")
rNum(1,"MIN JATUH",cfg.fMinJatuh,function(n) cfg.fMinJatuh=n end)
rNum(1,"POSISI BENTUR (0-1)",cfg.fPosisi,function(n)
 if n>0 and n<1 then cfg.fPosisi=n end
end)
rNum(1,"BENTUR CADANG",cfg.fCadang,function(n) cfg.fCadang=n end)
rNum(1,"BENTUR KE",cfg.fBenturKe,function(n) cfg.fBenturKe=n end)
rNum(1,"PAGAR KECEPATAN",cfg.fPagar,function(n) cfg.fPagar=n end)
rNum(1,"LEMBUT JARAK",cfg.fLembutJarak,function(n) cfg.fLembutJarak=n end)
rNum(1,"LEMBUT KE",cfg.fLembutKe,function(n) cfg.fLembutKe=n end)

-- ================= TAB 2 : VISUAL =================
rSect(2,"TARGET")
rTgl(2,"ESP / HIGHLIGHT (WARNA TIM)",false,function(v)
 vis.esp=v
 if v and not HOK then notif("HIGHLIGHT TIDAK DIDUKUNG EXECUTOR",C.kuning) end
 if not v then
  for _,d in pairs(espF) do pcall(function() d:Destroy() end) end
  espF={}
 end
 notif(v and "ESP ON" or "ESP OFF",C.ungu)
end)
local tglTag=rTgl(2,"NAMETAG + INFO PLAYER [Z]",false,function(v)
 vis.tag=v
 if not v then
  for _,t in pairs(tagF) do pcall(function() t.bb:Destroy() end) end
  tagF={}
 end
 notif(v and "INFO PLAYER ON" or "INFO PLAYER OFF",C.biru)
end)
rInfo(2,"Merah otomatis jika speed/jump pemain lain mencurigakan.")

rSect(2,"GAYA")
local gayaNama={"OFF","DOT","CROSS","CIRCLE"}
rAct(2,"CROSSHAIR: OFF (KLIK GANTI)",function(b)
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
    Size=UDim2.fromOffset(6,6),BackgroundColor3=C.putih},f)
   corner(d,3) stroke(d,Color3.new(0,0,0),1,.4)
  elseif vis.cross==2 then
   mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(20,2),BackgroundColor3=C.putih},f)
   mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(2,20),BackgroundColor3=C.putih},f)
  else
   local c=mk("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(22,22),BackgroundTransparency=1},f)
   corner(c,11) stroke(c,C.putih,2)
  end
 end
 b.Text="CROSSHAIR: "..gayaNama[vis.cross+1].." (KLIK GANTI)"
 notif("CROSSHAIR: "..gayaNama[vis.cross+1],C.pink)
end)
rTgl(2,"MOONWALK (BADAN MENGHADAP KAMERA)",false,function(v)
 vis.moon=v
 notif(v and "MOONWALK ON - HADAP KAMERA" or "MOONWALK OFF",C.pink)
end)

rSect(2,"LAYAR BERSIH")
local tgHideP=rTgl(2,"SEMBUNYIKAN PEMAIN LAIN [R]",false,function(v)
 vis.hideP=v
 if not v then
  for _,p in ipairs(hidP) do pcall(function() p.LocalTransparencyModifier=0 end) end
  hidP={}
 end
 notif(v and "PEMAIN DISEMBUNYIKAN (ESP TETAP)" or "PEMAIN TAMPIL",C.ungu)
end)
rTgl(2,"MATIKAN SEMUA EFEK (FPS)",false,function(v)
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
  notif("EFEK MATI - FPS NAIK",C.hijau)
 else
  for _,d in ipairs(hidFX) do pcall(function() d.Enabled=true end) end
  hidFX={}
  notif("EFEK DINYALAKAN",C.hijau)
 end
end)

rSect(2,"LINGKUNGAN")
local tglBr=rTgl(2,"AUTO BRIGHTNESS [T]",false,function(v)
 vis.br=v
 if not v then
  pcall(function()
   LG.Brightness=oLight.B LG.Ambient=oLight.A LG.OutdoorAmbient=oLight.O
  end)
 end
 notif(v and "AUTO BRIGHTNESS ON" or "AUTO BRIGHTNESS OFF",C.kuning)
end)
local namaSwim={"KATAK +20% (TEGAK, HADAP KAMERA)","TEGAK (HADAP ARAH GERAK)","NORMAL"}
local btnSwim
local function siklusSwim()
 vis.swim=vis.swim%3+1
 if vis.swim==3 then
  btnSwim.Text="RENANG: NORMAL [C]"
 else
  btnSwim.Text="RENANG: "..namaSwim[vis.swim].." [C]"
 end
 notif("RENANG: "..(vis.swim==3 and "NORMAL" or namaSwim[vis.swim]),C.biru)
end
btnSwim=rAct(2,"RENANG: NORMAL [C]",function() siklusSwim() end,30)
local function scanW()
 if not vis.wall then return end
 for _,d in ipairs(workspace:GetDescendants()) do
  pcall(function()
   if d:IsA("BasePart") and not wallP[d] and d.Transparency>0.5 and d.CanCollide then
    wallP[d]={t=d.Transparency,c=d.Color}
    d.Transparency=0.55 d.Color=C.ungu
   end
  end)
 end
end
local tglWall=rTgl(2,"DINDING TAK TERLIHAT [X]",false,function(v)
 vis.wall=v
 if v then scanW() notif("DINDING TERSEMBUNYI DITAMPILKAN",C.ungu)
 else
  for d,o in pairs(wallP) do pcall(function() d.Transparency=o.t d.Color=o.c end) end
  wallP={}
  notif("DINDING DISEMBUNYIKAN",C.ungu)
 end
end)
rAct(2,"SCAN ULANG DINDING",function()
 if vis.wall then scanW() notif("SCAN ULANG SELESAI",C.biru)
 else notif("NYALAKAN DINDING DULU",C.kuning) end
end)

-- ================= TAB 3 : HUD =================
rInfo(3,"Panel bisa digeser (drag judulnya).")
rTgl(3,"STATUS (KIRI BAWAH)",true,function(v) pSt.Visible=v end)
rTgl(3,"FPS / PING (KIRI BAWAH)",true,function(v) pFp.Visible=v end)

rSect(3,"LAINNYA")
rTgl(3,"ANTI-AFK (TANGKAL KICK 20 MENIT)",true,function(v)
 hud.afk=v
 notif(v and "ANTI-AFK ON" or "ANTI-AFK OFF",v and C.hijau or C.merah)
end)
rAct(3,"MODE BERSIH (SEMBUNYIKAN HUD)",function()
 hudF.Visible=not hudF.Visible
 notif(hudF.Visible and "HUD KEMBALI" or "MODE BERSIH AKTIF",C.kuning)
end)
rAct(3,"HAPUS SCRIPT TOTAL",function()
 notif("MENGHAPUS...",C.merah)
 task.wait(0.3)
 if kill then kill() end
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
  if math.abs(h.JumpPower-jpT)>0.01 then h.JumpPower=jpT end
 end)

 if curSpeed==nil then curSpeed=h.WalkSpeed end
 local target
 if mv.sprint then target=cfg.sOn
 elseif mv.walk then target=cfg.wOn
 else target=cfg.wOff end
 curSpeed=curSpeed+(target-curSpeed)*math.clamp(dt*8,0,1)
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
 task.spawn(function()
  local h=c:WaitForChild("Humanoid",10)
  if h then orig={ws=h.WalkSpeed,jp=h.JumpPower,u=h.UseJumpPower} end
 end)
end)

-- ===== SMART FALL ASSIST v1.0.6 (BENTURAN + PAGAR) =====
local fJatuh=false
local fApex=0
local fBentur=false
local fBenturSampai=0
local fPagar=false
local fSejak=0

RS.Heartbeat:Connect(function(dt)
 if not RUN or not mv.fall then return end
 local c,h,hp=ch()
 if not h or not hp then return end
 local now=os.clock()
 local v=hp.AssemblyLinearVelocity

 -- sentakan benturan
 if now<fBenturSampai then
  local nv=v.Y+(cfg.fBenturKe-v.Y)*math.clamp(dt*12,0,1)
  hp.AssemblyLinearVelocity=Vector3.new(v.X,nv,v.Z)
 -- pagar kecepatan setelah benturan
 elseif fPagar and v.Y<cfg.fPagar then
  local nv=v.Y+(cfg.fPagar-v.Y)*math.clamp(dt*4,0,1)
  hp.AssemblyLinearVelocity=Vector3.new(v.X,nv,v.Z)
 end

 local st=h:GetState()

 if st==Enum.HumanoidStateType.Freefall and v.Y<-4 then
  if not fJatuh then
   fJatuh=true
   fApex=hp.Position.Y
   fBentur=false
   fPagar=false
   fSejak=now
  end
  fApex=math.max(fApex,hp.Position.Y)
  local sudahTurun=fApex-hp.Position.Y

  local r=workspace:Raycast(hp.Position,Vector3.new(0,-800,0),ray)
  local tinggiTotal,sisaJatuh
  if r then
   sisaJatuh=hp.Position.Y-r.Position.Y
   tinggiTotal=fApex-r.Position.Y
  end

  -- pemicu benturan (3 jalur)
  if not fBentur and sudahTurun>15 and v.Y<-40 then
   local picu=false
   if tinggiTotal and tinggiTotal>=cfg.fMinJatuh
   and sisaJatuh<=tinggiTotal*(1-cfg.fPosisi) then
    picu=true
   end
   if not picu and v.Y<cfg.fCadang then picu=true end
   if not picu and not tinggiTotal and (now-fSejak)>0.5 and v.Y<-70 then
    picu=true
   end
   if picu then
    fBentur=true
    fPagar=true
    fBenturSampai=now+cfg.fBenturDur
    notif("TERBENTUR - kecepatan terpangkas",C.kuning)
   end
  end

  -- pelembut menjelang tanah
  if fBentur and sisaJatuh and sisaJatuh<cfg.fLembutJarak
  and v.Y<cfg.fLembutKe then
   local nv=v.Y+(cfg.fLembutKe-v.Y)*math.clamp(dt*5,0,1)
   hp.AssemblyLinearVelocity=Vector3.new(v.X,nv,v.Z)
  end

 elseif fJatuh then
  fJatuh=false
  fPagar=false
  local tdah=fBentur
  fBentur=false
  if tdah then
   notif("MENDARAT - damage minimal",C.hijau)
  end
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
       bg.BackgroundTransparency=0.35 bg.BorderSizePixel=0 bg.Parent=b
       local bc=Instance.new("UICorner") bc.CornerRadius=UDim.new(0,8) bc.Parent=bg
       local bs=Instance.new("UIStroke")
       bs.Color=C.pink bs.Thickness=1 bs.Transparency=0.4 bs.Parent=bg
       local l1=Instance.new("TextLabel")
       l1.Size=UDim2.new(1,0,0,22) l1.BackgroundTransparency=1
       l1.Font=F_BOLD l1.TextSize=14 l1.TextColor3=C.putih
       l1.TextStrokeTransparency=0.3 l1.Text=p.DisplayName l1.Parent=bg
       local l2=Instance.new("TextLabel")
       l2.Position=UDim2.new(0,0,0,23) l2.Size=UDim2.new(1,0,0,20)
       l2.BackgroundTransparency=1 l2.Font=F_BOLD l2.TextSize=12
       l2.TextColor3=C.hijauM l2.TextStrokeTransparency=0.35
       l2.Text="..." l2.Parent=bg
       local l3=Instance.new("TextLabel")
       l3.Position=UDim2.new(0,0,0,44) l3.Size=UDim2.new(1,0,0,17)
       l3.BackgroundTransparency=1 l3.Font=F_SEMI l3.TextSize=11
       l3.TextColor3=C.abuG l3.TextStrokeTransparency=0.4 l3.Text="" l3.Parent=bg
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
      d.inf.TextColor3=cg and C.merahM or C.hijauM
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
      d.Transparency=0.55 d.Color=C.ungu
     end
    end)
   end
  end
 end
end)

-- RENANG: KATAK = tegak hadap kamera +20% | TEGAK = tegak hadap arah gerak
RS.Heartbeat:Connect(function()
 if not RUN then return end
 local c,h,hp=ch()
 if not h or not hp then return end
 local sw=false
 pcall(function() sw=h:GetState()==Enum.HumanoidStateType.Swimming end)
 if sw and vis.swim>0 then
  if not gyro or not gyro.Parent then
   gyro=Instance.new("BodyGyro")
   gyro.MaxTorque=Vector3.new(4e5,4e5,4e5)
   gyro.P=8000 gyro.D=500 gyro.Parent=hp
  end
  local md=h.MoveDirection
  local fl=md.Magnitude>0.01 and Vector3.new(md.X,0,md.Z).Unit or hp.CFrame.LookVector
  if vis.swim==1 then
   local cam=workspace.CurrentCamera
   local cl=cam and cam.CFrame.LookVector or fl
   local cf=Vector3.new(cl.X,0,cl.Z)
   if cf.Magnitude<0.01 then cf=fl end
   gyro.CFrame=CFrame.lookAt(Vector3.zero,cf.Unit)
  else
   gyro.CFrame=CFrame.lookAt(Vector3.zero,fl)
  end
  if vis.swim==1 then
   local t=(mv.sprint and cfg.sOn or (mv.walk and cfg.wOn or cfg.wOff))*1.2
   if math.abs(h.WalkSpeed-t)>0.01 then pcall(function() h.WalkSpeed=t end) end
  end
 else
  if gyro then pcall(function() gyro:Destroy() end) gyro=nil end
 end
end)

-- MOONWALK: badan terkunci menghadap kamera (skip saat renang)
RS.RenderStepped:Connect(function()
 if not RUN or not vis.moon then return end
 local c,h,hp=ch()
 if not h or not hp then return end
 local sw=false
 pcall(function() sw=h:GetState()==Enum.HumanoidStateType.Swimming end)
 if sw and vis.swim>0 then return end
 local cam=workspace.CurrentCamera
 if not cam then return end
 local cl=cam.CFrame.LookVector
 local f=Vector3.new(cl.X,0,cl.Z)
 if f.Magnitude>0.01 then
  pcall(function()
   hp.CFrame=CFrame.lookAt(hp.Position,hp.Position-f.Unit)
  end)
 end
end)

local fc=0
RS.RenderStepped:Connect(function() if RUN then fc+=1 end end)
task.spawn(function()
 while RUN do
  task.wait(1)
  local fps=fc fc=0
  local ping=0
  pcall(function() ping=math.floor(LP:GetNetworkPing()*1000) end)
  fpL.Text=string.format("FPS %d  |  %d MS",fps,ping)
  fpL.TextColor3=(fps>=50 and C.hijauM) or (fps>=25 and C.kuning) or C.merahM
 end
end)

task.spawn(function()
 while RUN do
  task.wait(0.25)
  local _,h,hp=ch()
  if h then
   local jp=h.UseJumpPower and h.JumpPower or h.JumpHeight
   stL.Text=string.format("SPEED : %.2f stud/s\nJUMP  : %.2f\nHP    : %.0f / %.0f\nMODE  : %s",
    h.WalkSpeed,jp,h.Health,h.MaxHealth,
    mv.sprint and "SPRINT" or (mv.walk and "WALK" or "NORMAL"))
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
  tb[i].b.BackgroundColor3=i==n and C.bg2 or C.abu
  tb[i].b.TextColor3=i==n and C.putih or C.teks
  tb[i].s.Color=i==n and C.pink or C.abuT
  tb[i].s.Transparency=i==n and 0 or .6
 end
 snd(S_PING,.2,1+.1*n)
end
for i,t in ipairs(tb) do
 t.b.MouseButton1Click:Connect(function() tab(i) end)
end

local function minimize()
 root.Visible=false
 snd(S_PING,.25,.75)
end
local function buka()
 root.Visible=true
 local s=mk("UIScale",{Scale=.6},root)
 tw(s,.35,{Scale=1},Enum.EasingStyle.Back)
 task.delay(.4,function() pcall(function() s:Destroy() end) end)
 snd(S_PING,.3,1.15)
end
minB.MouseButton1Click:Connect(minimize)

local helpF=mk("Frame",{Position=UDim2.new(0,6,0,46),Size=UDim2.new(1,-12,1,-88),
 BackgroundColor3=C.bg2,Visible=false,ZIndex=60},panel)
corner(helpF,10) stroke(helpF,C.pink,1,.4)
mk("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,10,0,6),
 Size=UDim2.new(1,-20,1,-44),Font=F_REG,TextSize=10,TextColor3=C.unguM,
 TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
 Text="F      : buka/tutup GUI\nQ      : walk speed ON/OFF\nQ Q    : sprint (Q lagi = OFF)\nV      : jump power ON/OFF\nR      : sembunyikan pemain lain\nT      : auto brightness\nC      : renang (katak/tegak/normal)\nX      : dinding tak terlihat\nZ      : info player\nK K    : hapus script (konfirmasi)",
 ZIndex=61},helpF)
local hClose=mk("TextButton",{Size=UDim2.new(1,-20,0,24),Position=UDim2.new(0,10,1,-30),
 BackgroundColor3=C.pink,Font=F_BOLD,TextSize=11,TextColor3=C.putih,
 Text="X TUTUP",ZIndex=61},helpF)
corner(hClose,7)
hClose.MouseButton1Click:Connect(function() helpF.Visible=false end)
helpB.MouseButton1Click:Connect(function()
 helpF.Visible=not helpF.Visible
 snd(S_PING,.25,helpF.Visible and 1.2 or .9)
end)

-- ================= KILL =================
kill=function()
 RUN=false
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
 if gyro then pcall(function() gyro:Destroy() end) end
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
 elseif k==Enum.KeyCode.K then
  local now=os.clock()
  if now-kLast<2 then
   kLast=0
   notif("MENGHAPUS SIIILAU HUB...",C.merah)
   task.wait(0.3)
   kill()
  else
   kLast=now
   notif("TEKAN K LAGI UNTUK HAPUS!",C.kuning)
   task.delay(2.1,function()
    if kLast~=0 and os.clock()-kLast>=2 then kLast=0 end
   end)
  end
 end
end)

-- ================= BADGE + MULAI =================
do
 local bd=mk("TextLabel",{AnchorPoint=Vector2.new(.5,.5),
  Position=UDim2.new(0.5,0,0.38,0),Size=UDim2.fromOffset(310,42),
  BackgroundColor3=C.bg,Font=F_TITLE,TextSize=16,
  TextColor3=C.pink2,Text="SIIILAU HUB SCRIPTS  v1.0.01",ZIndex=999},g)
 corner(bd,10) stroke(bd,C.pink,2)
 task.delay(1.5,function()
  pcall(function()
   tw(bd,.35,{TextTransparency=1,BackgroundTransparency=1})
   task.delay(.4,function() bd:Destroy() end)
  end)
 end)
end

local foot=mk("TextLabel",{Size=UDim2.new(1,0,0,14),
 Position=UDim2.new(0,0,1,-18),BackgroundTransparency=1,
 Font=F_SEMI,TextSize=8,TextColor3=C.abuT,
 Text="SIIILAU HUB SCRIPTS  v1.0.01"},panel)

tab(1)
task.delay(0.45,function() buka() end)
task.delay(1.2,function()
 notif("SIIILAU HUB v1.0.01 SIAP - TEKAN F",C.pink)
end)

print("[SilauHub] v1.0.01 SIAP")

end)

if not ok then fatal(e) end
