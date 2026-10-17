--========================================================
--  SIIILAU HUB SCRIPTS v1.0.3 "LIGHT EDITION"
--  F=GUI  Q=speed  Q Q=sprint  V=jump  G=moonwalk
--  R=hide player  T=brightness  C=renang  X=dinding
--  Z=info  K K=hapus
--
--  MOONWALK: badan TERKUNCI menghadap kamera/layar
--  FALL ASSIST v3.1 "VIRTUAL BRANCH":
--   Jatuh normal kencang -> sekali di 80% perjalanan:
--   platform tak terlihat muncul di bawah kaki ->
--   kamu MENDARAT BENERAN (reset semua penghitung jatuh,
--   client & server, seperti kena ranting asli) ->
--   platform hilang -> jatuh sisa pendek -> damage kecil
--   WASD bebas. Darah tidak disentuh. Tanpa notif.
--
--  ================== PERBAIKAN v1.0.2 ==================
--  [FIX-01] FREEZE UTAMA: workspace:GetDescendants() yang
--           diproses habis dalam SATU frame (bisa 100rb-1jt
--           instance) diganti scanner bertahap (maks ~3000
--           instance per frame) -> tidak ada freeze.
--  [FIX-02] pcall(function()...end) PER INSTANCE di dalam
--           loop scan dihapus (v1.0.1 bikin closure baru
--           ratusan ribu kali -> GC spike). Sekarang 1 pcall
--           per blok chunk.
--  [FIX-03] Re-scan dinding acak (8% tiap detik = scan map
--           PENUH lagi) DIHAPUS -> diganti event
--           DescendantAdded + slow-scan 30 detik.
--  [FIX-04] Hide Player: table.find() linear per part
--           (O(n^2) saat banyak pemain) -> hash set O(1).
--  [FIX-05] 3 koneksi Heartbeat -> 1. GetState() dipanggil
--           1x per frame (dulu 2-3x + pcall ganda).
--  [FIX-06] 2 koneksi RenderStepped -> 1 (FPS counter +
--           moonwalk digabung).
--  [FIX-07] Fall Assist: raycast 800 stud TIAP FRAME saat
--           jatuh -> cache ketinggian tanah (refresh 10x
--           per detik, tiap frame saat dekat tanah).
--  [FIX-08] Memory leak: tagF dibersihkan saat pemain
--           keluar (PlayerRemoving) & respawn; wallP/hidFX/
--           hidP jadi weak table (part hancur = auto GC).
--  [FIX-09] Loop latar 5 -> 3; interval 0.25/0.3s -> 0.5s.
--  [FIX-10] Fungsi drag() dobel dihapus; Sound klik dipool
--           jadi 1 instance (v1.0.1 bikin baru tiap klik).
--  [FIX-11] Bug v1.0.1: label tombol Renang tidak di-reset
--           saat Moonwalk menyala (btnSwim belum dideklarasi
--           saat closure dibuat) -> forward declare.
--
--  ================ PERUBAHAN v1.0.3 ================
--  [CHG-01] ESP / Highlight DIHAPUS total (toggle, loop
--           pembuatan, dan cleanup-nya ikut dibersihkan).
--  [CHG-02] Nametag lebih jelas: hanya DisplayName +
--           Speed & Jump. Nama 18px GothamBlack, info 15px,
--           outline hitam penuh, billboard lebih besar.
--           Baris jarak (STUD) dihapus.
--  [CHG-03] Crosshair (4 gaya) DIHAPUS total.
--  Keybind tetap sama: F Q QQ V G R T C X Z K K
--========================================================
print("[SilauHub] v1.0.3 LIGHT loading...")

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
 -- FALL ASSIST v3.1 "VIRTUAL BRANCH"
 fMinJatuh=50,   -- jatuh harus lebih tinggi dari ini (stud)
 fPosisi=0.80,   -- mendarat virtual di 80% perjalanan (dekat tanah)
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
local vis={tag=false,moon=false,hideP=false,fx=false,br=false,swim=false,wall=false}
local hud={afk=true}
local tagF={}
local kill=nil
local orig={ws=16,jp=50,u=true}
local oLight={B=LG.Brightness,A=LG.Ambient,O=LG.OutdoorAmbient}
local ray=RaycastParams.new()
pcall(function() ray.FilterType=Enum.RaycastFilterType.Exclude end)

-- [FIX-08] weak table: part/effect yang sudah dihancurkan game
-- otomatis dibuang garbage collector -> memori tidak numpuk
-- di sesi panjang (v1.0.1 menyimpan referensi kuat selamanya)
local hidP=setmetatable({},{__mode="k"})
local hidFX=setmetatable({},{__mode="k"})
local wallP=setmetatable({},{__mode="k"})
local fxConn=nil   -- koneksi DescendantAdded utk mode efek
local wallConn=nil -- koneksi DescendantAdded utk mode dinding

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

-- ============ SCANNER BERTAHAP [FIX-01]+[FIX-02] ============
-- v1.0.1: workspace:GetDescendants() lalu loop penuh +
-- pcall(function() end) PER INSTANCE, semua dalam 1 frame.
-- Di map besar (100rb-1jt instance) = ratusan ribu alokasi
-- closure sekaligus + iterasi jutaan -> game FREEZE.
-- v1.0.2: jalan pohon instance lewat stack, proses maks
-- SCAN_CHUNK node per frame, 1 pcall per blok chunk.
local SCAN_CHUNK=3000
local scanning={}
local function walkAsync(fn,tag,onDone,activeFn)
 if scanning[tag] then return end
 scanning[tag]=true
 task.spawn(function()
  local stack={workspace}
  while #stack>0 do
   if not RUN then break end
   if activeFn and not activeFn() then break end
   local n=math.min(#stack,SCAN_CHUNK)
   local batch={}
   for k=1,n do
    batch[k]=stack[#stack]
    stack[#stack]=nil
   end
   pcall(function()
    for k=1,n do
     local inst=batch[k]
     fn(inst)
     local kids=inst:GetChildren()
     for j=1,#kids do stack[#stack+1]=kids[j] end
    end
   end)
   if #stack>0 then task.wait() end
  end
  scanning[tag]=false
  if onDone and RUN and (not activeFn or activeFn()) then onDone() end
 end)
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

-- [FIX-10] satu Sound dipakai ulang (v1.0.1 membuat Sound
-- baru + destroy setiap klik toggle)
local sndS=Instance.new("Sound")
sndS.SoundId="rbxasset://sounds/electronicpingshort.wav"
sndS.Volume=.2 sndS.Parent=g
local function snd(v,p)
 pcall(function()
  sndS.Volume=v or .2
  sndS.PlaybackSpeed=p or 1
  sndS:Play()
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

-- [FIX-10] drag() cukup didefinisikan SEKALI
-- (v1.0.1 mendefinisikan fungsi drag 2x)
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
drag(titleHit,root) -- [FIX-10] pakai fungsi drag yang sama

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
rInfo(1,"Jatuh normal kencang -> sekali di 80% perjalanan:\nmendarat sesaat di ranting virtual (reset penghitung\njatuh game, client & server) -> jatuh sisa pendek.\nDarah tidak disentuh. Tanpa notif.",46)

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
-- [CHG-01] ESP / Highlight dihapus total (v1.0.3)
local tglTag=rTgl(2,"Nametag + Info","Z",false,function(v)
 vis.tag=v
 if not v then
  for _,t in pairs(tagF) do pcall(function() t.bb:Destroy() end) end
  tagF={}
 end
 notif(v and "INFO PLAYER ON" or "INFO PLAYER OFF",v)
end)
rInfo(2,"Nama + Speed & Jump saja, tulisan besar.\nMerah otomatis jika speed/jump mencurigakan.",34)

header(2,"Gaya")
-- [CHG-03] Crosshair (4 gaya) DIHAPUS total (v1.0.3),
-- Moonwalk jadi satu-satunya di bagian Gaya
-- [FIX-11] btnSwim dideklarasi di depan agar closure
-- moonwalk bisa meng-reset label tombol renang
local btnSwim
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
  -- [FIX-08] hidP sekarang hash set, dibersihkan in-place
  for d in pairs(hidP) do
   pcall(function() d.LocalTransparencyModifier=0 end)
   hidP[d]=nil
  end
 end
 notif(v and "PLAYER DISEMBUNYIKAN" or "PLAYER TAMPIL",v)
end)
rTgl(2,"Matikan Efek (FPS)",nil,false,function(v)
 vis.fx=v
 if v then
  notif("MEMATIKAN EFEK (SCAN BERTAHAP)...",true)
  -- [FIX-01]+[FIX-02] scan bertahap: tidak freeze di map besar
  walkAsync(function(d)
   if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke")
   or d:IsA("Sparkles") or d:IsA("Beam") or d:IsA("Trail") then
    if d.Enabled then d.Enabled=false hidFX[d]=true end
   end
  end,"fx",function()
   if vis.fx then notif("EFEK MATI - FPS NAIK",true) end
  end,function() return vis.fx end)
  for _,d in ipairs(LG:GetChildren()) do
   if d:IsA("PostEffect") and d.Enabled then d.Enabled=false hidFX[d]=true end
  end
  -- [FIX-03] efek BARU (map streaming) langsung dimatikan
  -- lewat event, tanpa perlu scan ulang seluruh map
  if fxConn then fxConn:Disconnect() end
  fxConn=workspace.DescendantAdded:Connect(function(d)
   if not vis.fx then return end
   if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke")
   or d:IsA("Sparkles") or d:IsA("Beam") or d:IsA("Trail") then
    if d.Enabled then d.Enabled=false hidFX[d]=true end
   end
  end)
 else
  if fxConn then fxConn:Disconnect() fxConn=nil end
  for d in pairs(hidFX) do
   pcall(function() d.Enabled=true end)
   hidFX[d]=nil
  end
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
local function wallApply(d)
 if d:IsA("BasePart") and not wallP[d] and d.Transparency>0.5 and d.CanCollide then
  wallP[d]={t=d.Transparency,c=d.Color}
  d.Transparency=0.55 d.Color=Color3.fromRGB(205,205,205)
 end
end
local function scanW()
 if not vis.wall then return end
 -- [FIX-01] scan bertahap + bisa dibatalkan otomatis
 -- kalau mode dinding dimatikan di tengah scan
 walkAsync(wallApply,"wall",function()
  if vis.wall then notif("SCAN SELESAI",true) end
 end,function() return vis.wall end)
end
local tglWall=rTgl(2,"Dinding Tak Terlihat","X",false,function(v)
 vis.wall=v
 if v then
  scanW()
  -- [FIX-03] dinding baru (map streaming) otomatis terlihat
  -- lewat event; re-scan acak tiap detik DIHAPUS
  if wallConn then wallConn:Disconnect() end
  wallConn=workspace.DescendantAdded:Connect(function(d)
   if vis.wall then wallApply(d) end
  end)
  notif("DINDING DITAMPILKAN",true)
 else
  if wallConn then wallConn:Disconnect() wallConn=nil end
  for d,o in pairs(wallP) do
   pcall(function() d.Transparency=o.t d.Color=o.c end)
   wallP[d]=nil
  end
  notif("DINDING DISEMBUNYIKAN",true)
 end
end)
rAct(2,"Scan Ulang Dinding",function()
 if vis.wall then scanW()
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

-- ================= LOOP UTAMA (Heartbeat) =================
-- [FIX-05] v1.0.1 punya 3 koneksi Heartbeat terpisah yang
-- masing-masing manggil ch() + GetState() + pcall tiap
-- frame. Sekarang semua tugas digabung jadi SATU koneksi:
-- double-jump reset, lerp jump/speed, boost renang, dan
-- bind/unbind orientasi renang katak.
local curSpeed=nil
RS.Heartbeat:Connect(function(dt)
 if not RUN then return end
 local c,h,hp=ch()
 if not h or not hp then return end

 local st
 pcall(function() st=h:GetState() end)
 local swimming=(st==Enum.HumanoidStateType.Swimming)

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
 if swimming and vis.swim then target=target*SWIM_BOOST end
 curSpeed=curSpeed+(target-curSpeed)*math.clamp(dt*3,0,1)
 if math.abs(target-curSpeed)<0.01 then curSpeed=target end
 if math.abs(h.WalkSpeed-curSpeed)>0.005 then
  pcall(function() h.WalkSpeed=curSpeed end)
 end

 local aktifSwim=swimming and vis.swim
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
--  FALL ASSIST v3.1 "VIRTUAL BRANCH" (versi hemat raycast)
--  Jatuh normal kencang -> sekali di 80% perjalanan:
--  platform tak terlihat muncul 4 stud di bawah kaki ->
--  karakter MENDARAT BENERAN di atasnya (landing fisika asli:
--  kecepatan vertikal mati alami, state Landed asli,
--  penghitung jatuh game client & server ter-reset,
--  persis seperti kena ranting asli di game) ->
--  0.15 detik kemudian platform hilang ->
--  jatuh sisa pendek -> damage kecil.
--  WASD bebas. Darah tidak disentuh. Tanpa notif.
--
--  [FIX-07] v1.0.1 melempar raycast 800 stud ke bawah TIAP
--  FRAME selama jatuh. Sekarang ketinggian tanah di-CACHE:
--  refresh 10x per detik saat masih jauh, tiap frame saat
--  sudah dekat tanah (<60 stud) agar presisi mendarat tetap.
--  Logika pemicu "virtual branch" sama persis.
-- ================================================================
local fJatuh=false
local fApex=0
local fBentur=false
local fSejak=0
local groundY=nil
local lastRayT=0

RS.Heartbeat:Connect(function(dt)
 if not RUN or not mv.fall then return end
 local c,h,hp=ch()
 if not h or not hp then return end
 local now=os.clock()
 local v=hp.AssemblyLinearVelocity

 local st
 pcall(function() st=h:GetState() end)

 if st==Enum.HumanoidStateType.Freefall and v.Y<-4 then
  if not fJatuh then
   fJatuh=true
   fApex=hp.Position.Y
   fBentur=false
   fSejak=now
   groundY=nil lastRayT=0
  end
  fApex=math.max(fApex,hp.Position.Y)
  local sudahTurun=fApex-hp.Position.Y

  -- [FIX-7] refresh cache ketinggian tanah:
  -- 10Hz saat jauh, tiap frame saat dekat tanah
  if sudahTurun>10 and v.Y<-40 then
   local dekat=(groundY~=nil) and (hp.Position.Y-groundY)<60
   if dekat or (now-lastRayT)>=0.1 then
    lastRayT=now
    local r=workspace:Raycast(hp.Position,Vector3.new(0,-800,0),ray)
    if r then groundY=r.Position.Y else groundY=nil end
   end
  end

  -- ukur tinggi total jatuh (dari apex ke tanah, dari cache)
  local tinggiTotal,sisaJatuh
  if groundY then
   sisaJatuh=hp.Position.Y-groundY
   tinggiTotal=fApex-groundY
  end

  -- ===== VIRTUAL BRANCH: SEKALI per jatuh di POSISI BENTUR =====
  if not fBentur and sudahTurun>10 and v.Y<-40 then
   local picu=false
   -- syarat utama: tinggi jatuh >= MIN JATUH & sudah melewati
   -- titik posisi bentur
   if tinggiTotal and tinggiTotal>=cfg.fMinJatuh
   and sisaJatuh<=tinggiTotal*(1-cfg.fPosisi) then
    picu=true
   end
   -- jaring pengaman internal: tanah tak terdeteksi &
   -- lama jatuh kencang
   if not picu and not tinggiTotal and (now-fSejak)>0.6 and v.Y<-70 then
    picu=true
   end
   if picu then
    fBentur=true
    -- RANTING VIRTUAL: platform tak terlihat 4 stud di bawah kaki
    pcall(function()
     local plat=Instance.new("Part")
     plat.Name="Branch"
     plat.Size=Vector3.new(6,0.4,6)
     plat.Transparency=1
     plat.Anchored=true
     plat.CanCollide=true
     plat.CanQuery=false
     plat.CanTouch=false
     plat.CastShadow=false
     plat.CFrame=CFrame.new(hp.Position.X,hp.Position.Y-4,hp.Position.Z)
     plat.Parent=workspace
     -- cukup 0.15 detik: mendarat tercatat lalu hilang
     task.delay(0.15,function()
      pcall(function() plat:Destroy() end)
     end)
    end)
   end
  end

 elseif fJatuh then
  -- mendarat beneran: reset, siap untuk jatuh berikutnya
  fJatuh=false
  fBentur=false
 end
end)

-- [FIX-06] SATU RenderStepped untuk semua kebutuhan per-frame:
-- counter FPS + moonwalk (v1.0.1 punya 2 koneksi terpisah)
local fc=0
RS.RenderStepped:Connect(function()
 if not RUN then return end
 fc+=1
 if vis.moon and not vis.swim then
  local c,h,hp=ch()
  if h and hp then
   local cam=workspace.CurrentCamera
   if cam then
    local _,yaw=cam.CFrame:ToOrientation()
    hp.CFrame=CFrame.new(hp.Position)*CFrame.Angles(0,yaw+math.pi,0)
   end
  end
 end
end)

-- [FIX-08] pemain keluar dari server -> data langsung
-- dibersihkan (v1.0.1: numpuk jadi memory leak)
Players.PlayerRemoving:Connect(function(p)
 local tt=tagF[p]
 if tt then pcall(function() tt.bb:Destroy() end) tagF[p]=nil end
end)

-- ================= LOOP LATAR =================
-- [FIX-09] v1.0.1: 5 loop latar (1s, 0.3s, 1s, 0.25s, 240s).
-- v1.0.2: hanya 3 loop (1s, 0.5s, 240s) + 1 slow-scan
-- dinding tiap 30 detik yang bertahap & bisa dibatalkan.

-- LOOP 1 detik: nametag, brightness, FPS/ping
task.spawn(function()
 while RUN do
  task.wait(1)
  -- [CHG-01] blok pembuatan ESP Highlight dihapus (v1.0.3)
  if vis.tag then
   for _,p in ipairs(Players:GetPlayers()) do
    if p~=LP and p.Character then
     -- [FIX-08] tag lama ikut hancur saat pemain respawn ->
     -- bersihkan supaya tag dibuat ulang (v1.0.1: tag hilang
     -- permanen setelah pemain respawn)
     local old=tagF[p]
     if old and not old.bb.Parent then tagF[p]=nil end
     if not tagF[p] then
      local hd=p.Character:FindFirstChild("Head")
      if hd then
       pcall(function()
        -- [CHG-02] nametag jelas: nama BESAR + SPD/JMP saja
        local b=Instance.new("BillboardGui")
        b.Name="SilauTag" b.Size=UDim2.fromOffset(210,66)
        b.StudsOffset=Vector3.new(0,3,0) b.AlwaysOnTop=true b.Parent=hd
        local bg=Instance.new("Frame")
        bg.Size=UDim2.new(1,0,1,0) bg.BackgroundColor3=C.bg
        bg.BackgroundTransparency=0.1 bg.BorderSizePixel=0 bg.Parent=b
        local bc=Instance.new("UICorner") bc.CornerRadius=UDim.new(0,8) bc.Parent=bg
        local bs=Instance.new("UIStroke")
        bs.Color=C.ungu bs.Thickness=1.5 bs.Transparency=0.25 bs.Parent=bg
        local l1=Instance.new("TextLabel")
        l1.Size=UDim2.new(1,0,0,32) l1.BackgroundTransparency=1
        l1.Font=F_BLK l1.TextSize=18 l1.TextColor3=C.putih
        l1.TextStrokeColor3=Color3.fromRGB(0,0,0) l1.TextStrokeTransparency=0
        l1.Text=p.DisplayName l1.Parent=bg
        local l2=Instance.new("TextLabel")
        l2.Position=UDim2.new(0,0,0,34) l2.Size=UDim2.new(1,0,0,26)
        l2.BackgroundTransparency=1 l2.Font=F_B l2.TextSize=15
        l2.TextColor3=Color3.fromRGB(140,230,160)
        l2.TextStrokeColor3=Color3.fromRGB(0,0,0) l2.TextStrokeTransparency=0
        l2.Text="..." l2.Parent=bg
        tagF[p]={bb=b,inf=l2}
       end)
      end
     end
    end
   end
  end
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

-- LOOP 0.5 detik: info nametag, hide player, status panel,
-- slow-scan dinding
-- [FIX-09] loop 0.3s + 0.25s v1.0.1 digabung jadi 0.5s
-- [FIX-04] hide player pakai hash set O(1), bukan
-- table.find() linear per part yang jadi O(n^2) saat
-- banyak pemain
local lastWallScan=0
task.spawn(function()
 while RUN do
  task.wait(0.5)
  local _,h=ch()
  if vis.tag then
   for p,d in pairs(tagF) do
    if p.Parent and p.Character then
     local h2=p.Character:FindFirstChildOfClass("Humanoid")
     if h2 and d.inf then
      local sp=h2.WalkSpeed
      local jp=h2.UseJumpPower and h2.JumpPower or h2.JumpHeight
      local cg=sp>cfg.wOn+0.05 or (h2.UseJumpPower and jp>cfg.jOff+0.05)
      d.inf.Text=string.format("SPD %.1f | JMP %.1f%s",sp,jp,cg and "  !!" or "")
      d.inf.TextColor3=cg and C.merah or Color3.fromRGB(140,230,160)
     end
    else
     if d.inf then d.inf.Text="..." end
    end
   end
  end
  if vis.hideP then
   for _,p in ipairs(Players:GetPlayers()) do
    if p~=LP and p.Character then
     for _,d in ipairs(p.Character:GetDescendants()) do
      if d:IsA("BasePart") and not hidP[d] then
       d.LocalTransparencyModifier=0.85
       hidP[d]=true
      end
     end
    end
   end
  end
  if pSt.Visible and h then
   local jp=h.UseJumpPower and h.JumpPower or h.JumpHeight
   stL.Text=string.format("Speed : %.2f stud/s\nJump  : %.2f\nHP    : %.0f / %.0f\nMode  : %s",
    h.WalkSpeed,jp,h.Health,h.MaxHealth,
    mv.sprint and "SPRINT" or (mv.walk and "WALK" or "NORMAL"))
  end
  -- [FIX-03] pengganti re-scan acak 8%/detik milik v1.0.1:
  -- slow-scan 30 detik yang BERTAHAP (maks 3000/frame) dan
  -- tidak menumpuk (ada guard scanning)
  if vis.wall and os.clock()-lastWallScan>30 then
   lastWallScan=os.clock()
   scanW()
  end
 end
end)

-- LOOP 4-5 menit: anti-AFK cadangan
task.spawn(function()
 while RUN do
  task.wait(240+math.random(0,60))
  if RUN and hud.afk then
   pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end)
  end
 end
end)

LP.Idled:Connect(function()
 if RUN and hud.afk then
  pcall(function() VU:CaptureController() VU:ClickButton2(Vector2.new()) end)
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
 Text="F      : buka/tutup GUI\nQ      : speed ON/OFF\nQ Q    : sprint (Q lagi = OFF)\nV      : jump power ON/OFF\nG      : moonwalk ON/OFF\nR      : hide player\nT      : auto brightness\nC      : renang katak +15%\nX      : dinding tak terlihat\nZ      : info player (nama+SPD/JMP)\nK K    : hapus script (konfirmasi)\nv1.0.3 LIGHT: tanpa freeze scan",
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
 -- [FIX-08] putuskan semua koneksi event yang masih hidup
 if fxConn then pcall(function() fxConn:Disconnect() end) fxConn=nil end
 if wallConn then pcall(function() wallConn:Disconnect() end) wallConn=nil end
 for _,t in pairs(tagF) do pcall(function() t.bb:Destroy() end) end
 for d,o in pairs(wallP) do
  pcall(function() d.Transparency=o.t d.Color=o.c end)
  wallP[d]=nil
 end
 for d in pairs(hidP) do
  pcall(function() d.LocalTransparencyModifier=0 end)
  hidP[d]=nil
 end
 for d in pairs(hidFX) do
  pcall(function() d.Enabled=true end)
  hidFX[d]=nil
 end
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

print("[SilauHub] v1.0.3 LIGHT SIAP (tema King Silau)")

end)

if not ok then fatal(e) end
