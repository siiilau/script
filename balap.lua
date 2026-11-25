--========================================================
--  ABSOLUTE V1.0 — LOCAL ONLY
--  Tab: MOVEMENT & VISUAL • TITIK • SYSTEM
--  Keybind: G=GUI  Q=Speed  C=Shift  LShift=Tengah
--           F=Moon  R=Hide  T=Cahaya  K×2=Rejoin
--========================================================
print("[Absolute V1.0] load mulai...")

-- [0] DIAGNOSTIK -----------------------------------------
local diagSet, diagHapus
do
  local __dGui, __dLbl
  pcall(function()
    __dGui = Instance.new("ScreenGui")
    __dGui.Name = "ABSOLUTE_DIAG"
    __dGui.ResetOnSpawn = false
    __dGui.DisplayOrder = 1000000
    __dLbl = Instance.new("TextLabel")
    __dLbl.Size = UDim2.new(0, 480, 0, 70)
    __dLbl.Position = UDim2.new(0, 8, 0, 120)
    __dLbl.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    __dLbl.BackgroundTransparency = 0.1
    __dLbl.BorderSizePixel = 0
    __dLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    __dLbl.Font = Enum.Font.GothamBold
    __dLbl.TextSize = 14
    __dLbl.TextWrapped = true
    __dLbl.ClipsDescendants = true
    __dLbl.Text = "Absolute: memulai..."
    __dLbl.Parent = __dGui
    local cr = Instance.new("UICorner")
    cr.CornerRadius = UDim.new(0, 8)
    cr.Parent = __dLbl
    local dipasang = false
    pcall(function() if gethui then __dGui.Parent = gethui(); dipasang = true end end)
    if not dipasang then
      pcall(function() __dGui.Parent = game:GetService("CoreGui"); dipasang = true end)
    end
    if not dipasang then
      pcall(function()
        __dGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
        dipasang = true
      end)
    end
  end)
  diagSet = function(teks, warna)
    print("[Absolute-DIAG] " .. tostring(teks))
    pcall(function()
      if __dGui and __dGui.Parent and __dLbl then
        __dLbl.Text = tostring(teks)
        if warna then __dLbl.BackgroundColor3 = warna end
      end
    end)
  end
  diagHapus = function()
    pcall(function() if __dGui then __dGui:Destroy() end end)
  end
end

local VERSI = "V1.0"
local __ABSOLUTE_LOAD_OK__ = xpcall(function()

-- [1] PENGAMAN DASAR ------------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
  warn("[Absolute] GAGAL: harus jalan di CLIENT!")
  return
end
if not game:IsLoaded() then
  diagSet("menunggu game load...")
  game.Loaded:Wait()
end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")

diagSet("menunggu LocalPlayer...")
local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
if not LocalPlayer then
  warn("[Absolute] GAGAL: LocalPlayer belum ada.")
  diagSet("GAGAL: LocalPlayer tidak ada", Color3.fromRGB(239, 68, 68))
  return
end

diagSet("cek Terrain...")
local Terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace:WaitForChild("Terrain", 10)
if not Terrain then
  warn("[Absolute] Terrain tidak ketemu — lanjut tanpa Terrain.")
end

local MY_TOKEN = {}
_G.__ABSOLUTE_TOKEN__ = MY_TOKEN
_G.__ABSOLUTE_MAIN__ = true

-- [2] KONFIGURASI ---------------------------------------
local CFG = {
  TOGGLE_KEY      = Enum.KeyCode.G,
  LED_TEXT        = "⚡ A B S O L U T E ⚡",
  SOUND_ON        = true,
  FX_LEVEL        = 1,
  SPEED_OFF   = 17.15, SPEED_ON_1  = 17.25, SPEED_ON_2  = 40,
  MOON_TURN_MAX = 12, MOON_SMOOTH = 10,
  SLT_WAKTU   = 0.25, SLT_DOT     = 7, SLT_DOT_Y   = 0.60,
  SWIM_BONUS         = 1.025,
  UI_LEBAR     = 360, UI_TINGGI    = 720,
  UI_SCALE_MIN = 0.45, UI_SCALE_MAX = 1.25,
  SND_PING   = "rbxasset://sounds/electronicpingshort.wav",
  SND_SNAP   = "rbxasset://sounds/snap.mp3",
}

local Warna = {
  Ungu      = Color3.fromRGB(124, 58, 237),
  Ungu2     = Color3.fromRGB(167, 139, 250),
  UnguMuda  = Color3.fromRGB(237, 233, 254),
  Biru      = Color3.fromRGB(37, 99, 235),
  Biru2     = Color3.fromRGB(59, 130, 246),
  BiruMuda  = Color3.fromRGB(219, 234, 254),
  Hitam     = Color3.fromRGB(12, 10, 20),
  Hitam2    = Color3.fromRGB(22, 18, 38),
  Putih     = Color3.fromRGB(255, 255, 255),
  PutihLap  = Color3.fromRGB(250, 250, 255),
  AbuMuda   = Color3.fromRGB(243, 242, 250),
  AbuItem   = Color3.fromRGB(246, 245, 252),
  TeksGelap = Color3.fromRGB(28, 24, 46),
  AbuTeks   = Color3.fromRGB(130, 125, 155),
  AbuGelap  = Color3.fromRGB(160, 155, 185),
  Merah     = Color3.fromRGB(239, 68, 68),
  MerahMuda = Color3.fromRGB(254, 202, 202),
  Hijau     = Color3.fromRGB(34, 197, 94),
  Hijau2    = Color3.fromRGB(16, 185, 129),
  HijauMuda = Color3.fromRGB(187, 247, 208),
  Kuning    = Color3.fromRGB(250, 204, 21),
  Oranye    = Color3.fromRGB(249, 115, 22),
  Gray      = Color3.fromRGB(72, 72, 94),
  Card2     = Color3.fromRGB(40, 40, 62),
}

-- [3] FONT KOMPATIBEL -----------------------------------
local FONT_OK = pcall(function()
  return Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Regular)
end)

local fnt
do
  local cache = {}
  fnt = function(k)
    if cache[k] then return cache[k] end
    local v
    if FONT_OK then
      local fam = {
        judul = "rbxasset://fonts/families/Bangers.json",
        bold  = "rbxasset://fonts/families/Montserrat.json",
        semi  = "rbxasset://fonts/families/Montserrat.json",
        med   = "rbxasset://fonts/families/Montserrat.json",
        reg   = "rbxasset://fonts/families/Montserrat.json",
      }
      local wts = {
        judul = Enum.FontWeight.Regular, bold  = Enum.FontWeight.Bold,
        semi  = Enum.FontWeight.SemiBold, med   = Enum.FontWeight.Medium,
        reg   = Enum.FontWeight.Regular,
      }
      v = Font.new(fam[k], wts[k])
    else
      local legacy = {
        judul = Enum.Font.Bangers, bold  = Enum.Font.GothamBold,
        semi  = Enum.Font.GothamSemibold, med   = Enum.Font.GothamMedium,
        reg   = Enum.Font.Gotham,
      }
      v = legacy[k]
    end
    cache[k] = v
    return v
  end
end

-- [4] HELPER --------------------------------------------
local rnd = math.random
pcall(function()
  math.randomseed(os.time() + math.floor((os.clock() % 1) * 100000))
end)

local function buat(class, props, parent)
  local obj = Instance.new(class)
  local isTextClass = (class == "TextLabel" or class == "TextButton" or class == "TextBox")
  for k, v in pairs(props) do
    if k == "FontFace" and isTextClass and not FONT_OK then
      obj.Font = v
    else
      obj[k] = v
    end
  end
  obj.Parent = parent
  return obj
end

local function tween(obj, info, props)
  local t = TweenService:Create(obj, info, props)
  t:Play()
  return t
end

local function angkaDari(teks)
  local v = tostring(teks):gsub(",", ".")
  return tonumber((v:gsub("[^%d%.]", "")))
end

local function clamp2(v) return math.floor(v * 100 + 0.5) / 100 end

local function fmtNum(v)
  v = clamp2(v)
  if v % 1 == 0 then return tostring(math.floor(v)) end
  local s = string.format("%.2f", v)
  s = s:gsub("0+$", "")
  s = s:gsub("%.$", "")
  return s
end

diagSet("dasar OK — siapkan helper GUI...")

-- [5] REGISTRY KONEKSI ----------------------------------
local semuaKoneksi = {}
local function catat(conn)
  table.insert(semuaKoneksi, conn)
  return conn
end

local State = { Removed = false }
local Original = {}
local Setters, Switches = {}, {}
local effGradients, effTweens = {}, {}
local setFeature, togglePanel, rejoin, unloadScript
local applySpeed, RefreshSpeed, SpeedLabel
local oLight, lightConn
local toast
local tabBtns, kontenTabs, setTab
local kontenMove, scrollMove
local kontenTitik, scrollTitik
local kontenSistem, scrollSistem

setFeature = function(name, v, silent)
  local f = Setters[name]
  if f then f(v, silent) end
end

local function getChar() return LocalPlayer.Character end
local function getHum()
  local c = getChar()
  return c and c:FindFirstChildOfClass("Humanoid")
end

-- [6] TITIK LOKAL ---------------------------------------
local TITIK_FILE = "ABSOLUTE_TITIK.json"
local TITIK = { poin = {}, hapus = {}, aktif = false, tampilTitik = true, folder = nil }
local titikRenderUI = function() end
local titikStatusUI = function() end

local function namaDefaultTitik(nama)
  return tostring(nama or ""):match("^Titik %d+$") ~= nil
end

local function namaTitikDipakai(nama, kecuali)
  local target = tostring(nama or ""):lower()
  for _, point in ipairs(TITIK.poin) do
    if point ~= kecuali and tostring(point.name or ""):lower() == target then return true end
  end
  return false
end

local function rapikanNomorTitik()
  local dipakai = {}
  for _, point in ipairs(TITIK.poin) do
    if not point.defaultName then dipakai[tostring(point.name or ""):lower()] = true end
  end
  local nomor = 1
  for _, point in ipairs(TITIK.poin) do
    if point.defaultName then
      local nama
      repeat
        nama = "Titik " .. nomor
        nomor += 1
      until not dipakai[nama:lower()]
      point.name = nama
      dipakai[nama:lower()] = true
    end
  end
end

local function namaDefaultBerikutnya()
  local nomor = 1
  while namaTitikDipakai("Titik " .. nomor) do nomor += 1 end
  return "Titik " .. nomor
end

local function titikFolder()
  if TITIK.folder and TITIK.folder.Parent then return TITIK.folder end
  local f = Instance.new("Folder")
  f.Name = "ABSOLUTE_TITIK_MARKERS"
  f.Parent = Workspace
  TITIK.folder = f
  return f
end

local function titikSimpan()
  local data = {}
  for _, p in ipairs(TITIK.poin) do
    local normal = p.normal or Vector3.new(0, 1, 0)
    data[#data + 1] = {id = p.id, name = p.name, x = p.pos.X, y = p.pos.Y, z = p.pos.Z, nx = normal.X, ny = normal.Y, nz = normal.Z}
  end
  getgenv().ABSOLUTE_TITIK_DATA = data
  if type(writefile) == "function" then
    pcall(function() writefile(TITIK_FILE, HttpService:JSONEncode(data)) end)
  end
end

local function titikMuat()
  local data
  if type(readfile) == "function" and type(isfile) == "function" then
    pcall(function()
      if isfile(TITIK_FILE) then data = HttpService:JSONDecode(readfile(TITIK_FILE)) end
    end)
  end
  if type(data) ~= "table" then data = rawget(getgenv(), "ABSOLUTE_TITIK_DATA") end
  if type(data) == "table" then
    for _, v in ipairs(data) do
      local x, y, z = tonumber(v.x), tonumber(v.y), tonumber(v.z)
      local nx, ny, nz = tonumber(v.nx) or 0, tonumber(v.ny) or 1, tonumber(v.nz) or 0
      if x and y and z then
        TITIK.poin[#TITIK.poin + 1] = {
          id = tostring(v.id or ("legacy-" .. (#TITIK.poin + 1) .. "-" .. math.random(1000, 9999))),
          name = tostring(v.name or ("Titik " .. (#TITIK.poin + 1))),
          defaultName = namaDefaultTitik(v.name or ("Titik " .. (#TITIK.poin + 1))),
          pos = Vector3.new(x, y, z),
          normal = Vector3.new(nx, ny, nz),
        }
      end
    end
  end
end

local function titikBersihkanDot()
  if TITIK.folder then
    for _, obj in ipairs(TITIK.folder:GetChildren()) do obj:Destroy() end
  end
end

local function titikBuatDot(p, nomor)
  local folder = titikFolder()
  local normal = p.normal or Vector3.new(0, 1, 0)
  if normal.Magnitude < 0.01 then normal = Vector3.new(0, 1, 0) end
  normal = normal.Unit
  local base = p.pos + normal * 0.025
  local tiangTinggi, tiangLebar = 1/3, 0.08
  local orient = CFrame.lookAt(base, base + normal) * CFrame.Angles(math.pi/2, 0, 0)
  local tiang = Instance.new("Part")
  tiang.Name = "Tiang_" .. tostring(nomor); tiang.Shape = Enum.PartType.Cylinder; tiang.Anchored = true
  tiang.CanCollide = false; tiang.CanTouch = false; tiang.CanQuery = false; tiang.CastShadow = false
  tiang.Material = Enum.Material.Neon; tiang.Color = Warna.Ungu2; tiang.Size = Vector3.new(tiangLebar, tiangTinggi, tiangLebar)
  tiang.CFrame = orient; tiang.Parent = folder
  local dot = Instance.new("Part")
  dot.Name = "Titik_" .. tostring(nomor); dot.Shape = Enum.PartType.Ball; dot.Anchored = true
  dot.CanCollide = false; dot.CanTouch = false; dot.CanQuery = false; dot.CastShadow = false
  dot.Material = Enum.Material.Neon; dot.Color = Warna.Ungu2; dot.Size = Vector3.new(0.44, 0.44, 0.44)
  dot.Position = base + normal * tiangTinggi
  dot.Parent = folder
end

local function titikUrutkanTerdekat()
  if #TITIK.poin < 2 then return end
  local char=getChar(); local hrp=char and char:FindFirstChild("HumanoidRootPart")
  local current=hrp and hrp.Position or TITIK.poin[1].pos
  local belum={}; for _,p in ipairs(TITIK.poin) do belum[#belum+1]=p end
  local urut={}
  while #belum>0 do
    local bestIndex,bestDist=1,math.huge
    for i,p in ipairs(belum) do
      local d=(p.pos-current).Magnitude
      if d<bestDist then bestIndex,bestDist=i,d end
    end
    local nextPoint=table.remove(belum,bestIndex)
    urut[#urut+1]=nextPoint; current=nextPoint.pos
  end
  table.clear(TITIK.poin); for _,p in ipairs(urut) do TITIK.poin[#TITIK.poin+1]=p end
end

local function titikRefreshDot()
  titikBersihkanDot()
  if not TITIK.tampilTitik then return end
  for i, p in ipairs(TITIK.poin) do titikBuatDot(p, i) end
end

local function titikTambah(name, pos, normal)
  if typeof(pos) ~= "Vector3" then return false end
  normal = (typeof(normal) == "Vector3" and normal.Magnitude > 0.01) and normal.Unit or Vector3.new(0, 1, 0)
  name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local defaultName = name == ""
  if defaultName then name = namaDefaultBerikutnya() end
  if namaTitikDipakai(name) then
    titikStatusUI("Nama titik sudah dipakai: " .. name)
    return false
  end
  local id = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
  TITIK.poin[#TITIK.poin + 1] = {id = id, name = name, defaultName = defaultName or namaDefaultTitik(name), pos = pos, normal = normal}
  titikSimpan()
  pcall(function() if type(toast) == "function" then toast("✓ Titik disimpan: " .. name, Warna.Hijau) end end)
  titikRefreshDot()
  titikRenderUI()
  titikStatusUI("Titik ditambahkan: " .. name)
  return true
end

local function titikHapus(nomor)
  if TITIK.poin[nomor] then
    local nama = TITIK.poin[nomor].name
    local id = TITIK.poin[nomor].id or nama
    table.remove(TITIK.poin, nomor)
    TITIK.hapus[#TITIK.hapus + 1] = tostring(id)
    titikSimpan(); pcall(function() if type(toast) == "function" then toast("✓ Titik dihapus", Warna.Hijau) end end); titikRefreshDot(); titikRenderUI()
    titikStatusUI("Titik dihapus: " .. nama)
  end
end

local function titikCariIndex(point)
  for i, p in ipairs(TITIK.poin) do
    if p == point or (point.id and p.id == point.id) then return i end
  end
  return nil
end

local function titikTeleport(nomor)
  local p = TITIK.poin[nomor]
  local char = getChar()
  local hrp = char and char:FindFirstChild("HumanoidRootPart")
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  if not p or not hrp or (hum and hum.Health <= 0) then
    titikStatusUI("Karakter belum siap")
    return
  end
  hrp.CFrame = CFrame.new(p.pos + Vector3.new(0, 3, 0))
  titikStatusUI("Pindah ke: " .. p.name)
end

local function titikRaycast(origin, direction)
  local params = RaycastParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  local filter = {}
  local char = getChar()
  if char then filter[#filter + 1] = char end
  if TITIK.folder then filter[#filter + 1] = TITIK.folder end
  params.FilterDescendantsInstances = filter
  return Workspace:Raycast(origin, direction, params)
end

local function titikKlikDunia()
  local mouse = LocalPlayer:GetMouse()
  if not mouse or not mouse.UnitRay then return end
  local ray = mouse.UnitRay
  local hit = titikRaycast(ray.Origin, ray.Direction * 2000)
  if hit then titikTambah(nil, hit.Position, hit.Normal) end
end

local function titikPosisiKarakter()
  local char = getChar()
  local hrp = char and char:FindFirstChild("HumanoidRootPart")
  if not hrp then return nil end
  local hit = titikRaycast(hrp.Position + Vector3.new(0, 3, 0), Vector3.new(0, -30, 0))
  if hit then return hit.Position, hit.Normal end
  return hrp.Position, Vector3.new(0, 1, 0)
end

titikMuat()
titikSimpan()
titikRefreshDot()

-- [7] EFEK LED & UI HELPER ------------------------------
local function ledSweep(inst, base, bandA, bandB, dur)
  local g = buat("UIGradient", {
    Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0.00, base),
      ColorSequenceKeypoint.new(0.40, base),
      ColorSequenceKeypoint.new(0.47, bandA),
      ColorSequenceKeypoint.new(0.54, bandB),
      ColorSequenceKeypoint.new(0.61, base),
      ColorSequenceKeypoint.new(1.00, base),
    }),
    Offset = Vector2.new(-1, 0),
  }, inst)
  local tw = tween(g, TweenInfo.new(dur or 2.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Offset = Vector2.new(1, 0)})
  table.insert(effGradients, g)
  table.insert(effTweens, tw)
  return g
end

local function cycleColor(obj, prop, colors, interval)
  task.spawn(function()
    local i = 1
    while obj.Parent do
      tween(obj, TweenInfo.new(interval * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {[prop] = colors[i]})
      task.wait(interval)
      if not obj.Parent then break end
      i = i % #colors + 1
    end
  end)
end

local function buatDraggable(handle, target, onClickIfClick)
  local dragging, dragStart, startPos, jarak = false, nil, nil, 0
  catat(handle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
      dragging, dragStart, startPos, jarak = true, input.Position, target.Position, 0
    end
  end))
  catat(handle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
      if dragging and onClickIfClick and jarak < 6 then onClickIfClick() end
      dragging = false
    end
  end))
  catat(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
      local delta = input.Position - dragStart
      jarak = math.abs(delta.X) + math.abs(delta.Y)
      target.Position = UDim2.new(
        startPos.X.Scale, math.round(startPos.X.Offset + delta.X),
        startPos.Y.Scale, math.round(startPos.Y.Offset + delta.Y)
      )
    end
  end))
end

local function ripple(btn, warna)
  btn.ClipsDescendants = true
  local c = buat("Frame", {
    Name = "NoFade",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(8, 8),
    BackgroundColor3 = warna or Warna.Putih,
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
  }, btn)
  buat("UICorner", {CornerRadius = UDim.new(1, 0)}, c)
  local target = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.4
  tween(c, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {Size = UDim2.fromOffset(target, target), BackgroundTransparency = 1})
  task.delay(0.5, function() c:Destroy() end)
end

local function efekTombol(btn, skalaHover)
  local s = buat("UIScale", {Scale = 1}, btn)
  local target = skalaHover or 1.06
  btn.MouseEnter:Connect(function()
    tween(s, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = target})
  end)
  btn.MouseLeave:Connect(function()
    tween(s, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
  end)
  btn.MouseButton1Down:Connect(function()
    tween(s, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = target * 0.9})
  end)
  btn.MouseButton1Up:Connect(function()
    tween(s, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = target})
  end)
end

-- [8] SCREENGUI -----------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AbsoluteMain"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() screenGui.OnTopOfCoreBlur = true end)

local kandidatParent = {}
pcall(function() if gethui then table.insert(kandidatParent, gethui()) end end)
pcall(function() table.insert(kandidatParent, game:GetService("CoreGui")) end)
pcall(function() table.insert(kandidatParent, LocalPlayer:WaitForChild("PlayerGui")) end)

for _, t in ipairs(kandidatParent) do
  pcall(function()
    local lama = t:FindFirstChild("AbsoluteMain")
    if lama then lama:Destroy() end
  end)
end

local terpasang = false
for _, t in ipairs(kandidatParent) do
  local ok = pcall(function() screenGui.Parent = t end)
  if ok and screenGui.Parent == t then
    terpasang = true
    break
  end
end

if not terpasang then
  warn("[Absolute] GAGAL: tidak bisa memasang GUI.")
  return
end

local function bunyi(id, vol, pitch)
  if not CFG.SOUND_ON then return end
  local s = Instance.new("Sound")
  s.SoundId = id
  s.Volume = vol or 0.35
  s.PlaybackSpeed = pitch or 1
  s.Parent = screenGui
  s:Play()
  task.delay(3, function() s:Destroy() end)
end

-- [9] BANGUN UI: ROOT + OUTER + PANEL -------------------
local root = buat("Frame", {
  Size = UDim2.fromOffset(CFG.UI_LEBAR, CFG.UI_TINGGI),
  Position = UDim2.new(0.5, 0, 0.10, 0),
  AnchorPoint = Vector2.new(0.5, 0),
  BackgroundTransparency = 1,
  BorderSizePixel = 0,
  Visible = false,
}, screenGui)

local panelScale = buat("UIScale", {Scale = 1}, root)
local fitScale = buat("UIScale", {Scale = 1}, root)

local function fitPanel()
  local cam = Workspace.CurrentCamera
  local vp = cam and cam.ViewportSize
  if not vp or vp.X <= 0 or vp.Y <= 0 then return end
  local s = math.min(
    (vp.X - 16) / CFG.UI_LEBAR,
    (vp.Y * 0.90 - 6) / CFG.UI_TINGGI
  )
  fitScale.Scale = math.clamp(s, CFG.UI_SCALE_MIN, CFG.UI_SCALE_MAX)
end

local camConn
local function ikatKamera()
  if camConn then camConn:Disconnect() camConn = nil end
  local cam = Workspace.CurrentCamera
  if cam then
    camConn = catat(cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel))
    fitPanel()
  end
end

catat(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(ikatKamera))
ikatKamera()

local outer = buat("Frame", {
  Size = UDim2.new(1, 0, 1, 0),
  BackgroundColor3 = Warna.Hitam,
  BorderSizePixel = 0,
}, root)
buat("UICorner", {CornerRadius = UDim.new(0, 16)}, outer)

local borderStroke = buat("UIStroke", {Color = Warna.Ungu, Thickness = 3}, outer)
local borderGrad = buat("UIGradient", {
  Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Warna.Ungu),
    ColorSequenceKeypoint.new(0.25, Warna.Biru),
    ColorSequenceKeypoint.new(0.50, Warna.Ungu2),
    ColorSequenceKeypoint.new(0.75, Warna.Biru2),
    ColorSequenceKeypoint.new(1.00, Warna.Ungu),
  }),
}, borderStroke)
table.insert(effTweens, tween(borderGrad, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = 360}))

local ring2Stroke = buat("UIStroke", {Color = Warna.Putih, Thickness = 1, Transparency = 0.45}, outer)
local ring2Grad = buat("UIGradient", {Color = ColorSequence.new(Warna.Ungu2, Warna.Biru2)}, ring2Stroke)
table.insert(effTweens, tween(ring2Grad, TweenInfo.new(3.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = -360}))

local panel = buat("Frame", {
  Size = UDim2.new(1, -10, 1, -10),
  Position = UDim2.new(0, 5, 0, 5),
  BackgroundColor3 = Warna.PutihLap,
  BorderSizePixel = 0,
}, outer)
buat("UICorner", {CornerRadius = UDim.new(0, 11)}, panel)
buat("UIStroke", {Color = Warna.UnguMuda, Thickness = 1, Transparency = 0.35}, panel)
ledSweep(panel, Warna.PutihLap, Warna.Putih, Warna.BiruMuda, 5)

local partBox = buat("Frame", {
  Name = "NoFade",
  Position = UDim2.new(0, 4, 0, 50),
  Size = UDim2.new(1, -8, 1, -84),
  BackgroundTransparency = 1,
  BorderSizePixel = 0,
  ClipsDescendants = true,
}, panel)

local header = buat("Frame", {
  Size = UDim2.new(1, 0, 0, 46),
  BackgroundColor3 = Warna.Hitam2,
  BorderSizePixel = 0,
  Active = true,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 11)}, header)
buat("Frame", {
  Size = UDim2.new(1, 0, 0, 11),
  Position = UDim2.new(0, 0, 0, 35),
  BackgroundColor3 = Warna.Hitam2,
  BorderSizePixel = 0,
}, panel)

local title = buat("TextLabel", {
  BackgroundTransparency = 1,
  Position = UDim2.new(0, 12, 0, 0),
  Size = UDim2.new(1, -104, 1, 0),
  FontFace = fnt("judul"),
  Text = "⚡ Absolute " .. VERSI .. " ⚡",
  TextColor3 = Warna.Putih,
  TextSize = 22,
  TextXAlignment = Enum.TextXAlignment.Left,
}, header)
ledSweep(title, Warna.Putih, Warna.Ungu2, Warna.Biru2, 2.2)

local titleGlow = buat("UIStroke", {Name = "NoFade", Color = Warna.Ungu2, Thickness = 1, Transparency = 0.5}, title)

local minBtn = buat("TextButton", {
  Size = UDim2.fromOffset(28, 28),
  Position = UDim2.new(1, -40, 0.5, -14),
  BackgroundColor3 = Warna.Hitam,
  BorderSizePixel = 0,
  FontFace = fnt("bold"),
  Text = "–",
  TextColor3 = Warna.Putih,
  TextSize = 18,
  AutoButtonColor = false,
}, header)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, minBtn)
buat("UIStroke", {Color = Warna.Ungu, Thickness = 1, Transparency = 0.3}, minBtn)

local accent = buat("Frame", {
  Size = UDim2.new(1, 0, 0, 2),
  Position = UDim2.new(0, 0, 0, 46),
  BorderSizePixel = 0,
}, panel)
ledSweep(accent, Warna.Biru, Warna.Putih, Warna.Ungu2, 2.6)

-- [13] TAB BAR ------------------------------------------
local function buildUI()
  tabBtns = {}
  local tabLabels = {"MOVEMENT & VISUAL", "TITIK", "SYSTEM"}
  local tabColors = {Warna.Ungu2, Warna.Hijau2, Warna.AbuGelap}
  kontenTabs = {}
  for i, lbl in ipairs(tabLabels) do
    local tab = buat("TextButton", {
      Size = UDim2.new(1 / 3, -3.2, 0, 24),
      Position = UDim2.new((i - 1) * (1 / 3), 2.8 + (i - 1) * 1.4, 0, 50),
      BackgroundColor3 = (i == 1) and tabColors[i] or Warna.AbuMuda,
      BorderSizePixel = 0,
      FontFace = fnt("bold"),
      Text = lbl,
      TextWrapped = true,
      TextColor3 = (i == 1) and Warna.Putih or Warna.AbuTeks,
      TextScaled = true,
      AutoButtonColor = false,
    }, panel)
    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, tab)
    buat("UITextSizeConstraint", {MaxTextSize = 11}, tab)
    efekTombol(tab, 1.04)
    table.insert(tabBtns, tab)
  end

  setTab = function(n)
    for i, t in ipairs(tabBtns) do
      local aktif = (i == n)
      t.BackgroundColor3 = aktif and tabColors[i] or Warna.AbuMuda
      t.TextColor3 = aktif and Warna.Putih or Warna.AbuTeks
    end
    for i, k in ipairs(kontenTabs) do
      k.Visible = (i == n)
    end
    bunyi(CFG.SND_PING, 0.2, 1.0 + 0.1 * n)
  end

  for i, t in ipairs(tabBtns) do
    local idx = i
    t.MouseButton1Click:Connect(function()
      ripple(t, Warna.Putih)
      setTab(idx)
    end)
  end

  -- [14] TAB 1: MOVEMENT & VISUAL ---------------------
  kontenMove = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
  }, panel)
  table.insert(kontenTabs, kontenMove)

  scrollMove = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 2),
    Size = UDim2.new(1, -24, 1, -6),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Ungu,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
  }, kontenMove)
  buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollMove)

  local sOrder = 0
  local function nextOrder() sOrder += 1 return sOrder end

  local function buatHeader(parent, text)
    return buat("TextLabel", {
      BackgroundTransparency = 1,
      Size = UDim2.new(1, 0, 0, 18),
      FontFace = fnt("bold"),
      TextSize = 12,
      TextColor3 = Warna.Ungu,
      TextXAlignment = Enum.TextXAlignment.Left,
      Text = "▎" .. string.upper(text),
      LayoutOrder = nextOrder(),
    }, parent)
  end

  local function buatToggleRow(parent, labelText, keyText, featureName)
    local row = buat("Frame", {
      BackgroundColor3 = Warna.AbuItem,
      Size = UDim2.new(1, 0, 0, 32),
      LayoutOrder = nextOrder(),
    }, parent)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    local label = buat("TextLabel", {
      BackgroundTransparency = 1,
      Position = UDim2.new(0, 10, 0, 0),
      Size = UDim2.new(1, -110, 1, 0),
      FontFace = fnt("med"),
      TextSize = 13,
      TextColor3 = Warna.TeksGelap,
      TextXAlignment = Enum.TextXAlignment.Left,
      TextTruncate = Enum.TextTruncate.AtEnd,
      Text = labelText,
    }, row)
    if keyText then
      local cw = math.max(24, 14 + #keyText * 8)
      local chip = buat("TextLabel", {
        BackgroundColor3 = Warna.Card2,
        Size = UDim2.new(0, cw, 0, 20),
        Position = UDim2.new(1, -58 - cw, 0.5, -10),
        FontFace = fnt("bold"),
        TextSize = 12,
        TextColor3 = Warna.AbuGelap,
        Text = keyText,
      }, row)
      buat("UICorner", {CornerRadius = UDim.new(0, 6)}, chip)
    end
    local sw = buat("TextButton", {
      BackgroundColor3 = Warna.Gray,
      Size = UDim2.new(0, 40, 0, 20),
      Position = UDim2.new(1, -50, 0.5, -10),
      Text = "",
      AutoButtonColor = false,
    }, row)
    buat("UICorner", {CornerRadius = UDim.new(0, 10)}, sw)
    local knob = buat("Frame", {
      BackgroundColor3 = Color3.fromRGB(235, 235, 240),
      Size = UDim2.new(0, 14, 0, 14),
      Position = UDim2.new(0, 3, 0.5, -7),
    }, sw)
    buat("UICorner", {CornerRadius = UDim.new(0, 10)}, knob)
    local api = {}
    function api.set(on)
      tween(sw, TweenInfo.new(0.15), {BackgroundColor3 = on and Warna.Hijau or Warna.Gray})
      tween(knob, TweenInfo.new(0.15), {
        Position = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
      })
    end
    Switches[featureName] = api
    api.set(State[featureName .. "On"])
    sw.MouseButton1Click:Connect(function()
      setFeature(featureName, not State[featureName .. "On"])
    end)
    return row, label
  end

  local function buatStepperRow(parent, labelText, getV, setV)
    local row = buat("Frame", {
      BackgroundColor3 = Warna.AbuItem,
      Size = UDim2.new(1, 0, 0, 30),
      LayoutOrder = nextOrder(),
    }, parent)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    if labelText then
      buat("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(0, 100, 1, 0),
        FontFace = fnt("med"),
        TextSize = 12,
        TextColor3 = Warna.TeksGelap,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = labelText,
      }, row)
    end
    local minus = buat("TextButton", {
      BackgroundColor3 = Warna.Card2,
      Size = UDim2.new(0, 32, 0, 22),
      Position = UDim2.new(0, labelText and 110 or 8, 0.5, -11),
      FontFace = fnt("bold"),
      TextSize = 16,
      TextColor3 = Warna.Putih,
      Text = "-",
      AutoButtonColor = false,
    }, row)
    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, minus)
    local box = buat("TextBox", {
      BackgroundColor3 = Warna.Hitam2,
      Size = UDim2.new(1, labelText and -192 or -92, 0, 22),
      Position = UDim2.new(0, labelText and 148 or 46, 0.5, -11),
      FontFace = fnt("reg"),
      TextSize = 14,
      TextColor3 = Warna.Putih,
      Text = fmtNum(getV()),
      ClearTextOnFocus = false,
    }, row)
    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, box)
    local plus = buat("TextButton", {
      BackgroundColor3 = Warna.Card2,
      Size = UDim2.new(0, 32, 0, 22),
      Position = UDim2.new(1, -40, 0.5, -11),
      FontFace = fnt("bold"),
      TextSize = 16,
      TextColor3 = Warna.Putih,
      Text = "+",
      AutoButtonColor = false,
    }, row)
    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, plus)
    local function refresh() box.Text = fmtNum(getV()) end
    local function notifChange()
      if labelText then
        toast(labelText .. ": " .. fmtNum(getV()), Warna.Biru)
      end
    end
    minus.MouseButton1Click:Connect(function() setV(clamp2(getV() - 0.25)); refresh(); notifChange() end)
    plus.MouseButton1Click:Connect(function() setV(clamp2(getV() + 0.25)); refresh(); notifChange() end)
    box.FocusLost:Connect(function()
      local n = angkaDari(box.Text)
      if n then setV(clamp2(math.clamp(n, 0, 1000))) end
      refresh()
      notifChange()
    end)
    return refresh
  end

  local function buatActionRow(parent, text, color, callback)
    local btn = buat("TextButton", {
      BackgroundColor3 = color,
      Size = UDim2.new(1, 0, 0, 30),
      LayoutOrder = nextOrder(),
      FontFace = fnt("bold"),
      TextSize = 13,
      TextColor3 = Warna.Putih,
      Text = text,
      AutoButtonColor = false,
    }, parent)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
    btn.MouseButton1Click:Connect(callback)
    efekTombol(btn, 1.03)
    return btn
  end

  -- init State
  State.SpeedOn = false
  State.SpeedValue = CFG.SPEED_ON_1
  State.ShiftOn = false
  State.IsSwimming = false
  State.HideOn  = false
  State.LWOn    = false
  State.LightOn = false
  State.MoonOn  = false
  State.TengahOn = false
  State.CuacaOn    = false

  oLight = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    ExposureCompensation = Lighting.ExposureCompensation,
    FogEnd = Lighting.FogEnd,
  }
  lightConn = nil

  -- Baris TAB 1
  buatHeader(scrollMove, "Player")
  local _, speedLbl = buatToggleRow(scrollMove, "Speed (Q): OFF (" .. fmtNum(CFG.SPEED_OFF) .. ")", "Q", "Speed")
  SpeedLabel = speedLbl
  RefreshSpeed = buatStepperRow(scrollMove, "Speed",
    function() return State.SpeedValue end,
    function(v)
      State.SpeedValue = math.clamp(v, CFG.SPEED_ON_1, CFG.SPEED_ON_2)
      if State.SpeedOn then applySpeed() end
      if SpeedLabel and SpeedLabel.Parent then
        SpeedLabel.Text = "Speed (Q): " .. (State.SpeedOn and fmtNum(State.SpeedValue) or ("OFF (" .. fmtNum(CFG.SPEED_OFF) .. ")"))
      end
    end)
  buatToggleRow(scrollMove, "Shiftlock Mobile", "C", "Shift")
  buatToggleRow(scrollMove, "Shiftlock Tengah", "Shift", "Tengah")
  buatToggleRow(scrollMove, "Moonwalk", "F", "Moon")
  buatHeader(scrollMove, "Visual")
  buatToggleRow(scrollMove, "Hide Player + Kendaraan", "R", "Hide")
  buatToggleRow(scrollMove, "Cahaya Auto (2 arah)", "T", "Light")
  buatToggleRow(scrollMove, "Remove Cuaca (kabut/awan)", nil, "Cuaca")
  buatHeader(scrollMove, "Lightweight")
  buatToggleRow(scrollMove, "Partikel / Bayangan / Efek", nil, "LW")

  -- [15] TAB SYSTEM ----------------------------------
  kontenSistem = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
  }, panel)
  scrollSistem = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 2),
    Size = UDim2.new(1, -24, 1, -6),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Ungu,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
  }, kontenSistem)
  buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollSistem)

  -- TAB TITIK
  kontenTitik = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80), Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
  }, panel)
  scrollTitik = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 2), Size = UDim2.new(1, -24, 1, -6),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Hijau2, ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
  }, kontenTitik)
  buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollTitik)

  local titikOrder = 0
  local function titikNext() titikOrder += 1; return titikOrder end

  local titikStatus = buat("TextLabel", {
    BackgroundColor3 = Warna.AbuItem, Size = UDim2.new(1, 0, 0, 30),
    FontFace = fnt("med"), TextSize = 11, TextColor3 = Warna.TeksGelap,
    TextWrapped = true, Text = "Titik tersimpan: " .. #TITIK.poin,
    LayoutOrder = titikNext(),
  }, scrollTitik)
  buat("UICorner", {CornerRadius = UDim.new(0, 8)}, titikStatus)
  buat("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, titikStatus)

  titikStatusUI = function(teks)
    if titikStatus and titikStatus.Parent then titikStatus.Text = teks .. " • Total: " .. #TITIK.poin end
  end

  local namaTitikBox = buat("TextBox", {
    BackgroundColor3 = Warna.Hitam2, Size = UDim2.new(1, 0, 0, 30),
    FontFace = fnt("reg"), TextSize = 12, TextColor3 = Warna.Putih,
    PlaceholderText = "Nama titik baru (opsional)", PlaceholderColor3 = Warna.AbuGelap,
    Text = "", ClearTextOnFocus = false, LayoutOrder = titikNext(),
  }, scrollTitik)
  buat("UICorner", {CornerRadius = UDim.new(0, 8)}, namaTitikBox)

  local modeTitikBtn = buatActionRow(scrollTitik, "📍 MODE CTRL + KLIK: OFF", Warna.Hijau2, function() end)
  modeTitikBtn.LayoutOrder = titikNext()
  local function refreshModeTitik()
    modeTitikBtn.Text = TITIK.aktif and "📍 MODE CTRL + KLIK: ON" or "📍 MODE CTRL + KLIK: OFF"
    modeTitikBtn.BackgroundColor3 = TITIK.aktif and Warna.Hijau2 or Warna.Card2
  end
  modeTitikBtn.MouseButton1Click:Connect(function()
    TITIK.aktif = not TITIK.aktif; refreshModeTitik()
    titikStatusUI(TITIK.aktif and "Aktif: tahan CTRL + klik kiri" or "Mode penempatan dimatikan")
  end)

  buatActionRow(scrollTitik, "➕ TAMBAH DARI POSISI SAYA", Warna.Biru, function()
    local pos, normal = titikPosisiKarakter()
    if pos then titikTambah(namaTitikBox.Text, pos, normal) else titikStatusUI("Karakter belum siap") end
    namaTitikBox.Text = ""
  end).LayoutOrder = titikNext()

  buatActionRow(scrollTitik, "● TITIK: TAMPIL / SEMBUNYI", Warna.Ungu2, function()
    TITIK.tampilTitik = not TITIK.tampilTitik; titikRefreshDot()
    titikStatusUI(TITIK.tampilTitik and "Titik ditampilkan" or "Titik disembunyikan")
  end).LayoutOrder = titikNext()

  buatActionRow(scrollTitik, "🗑 HAPUS SEMUA TITIK", Warna.Merah, function()
    for _, p in ipairs(TITIK.poin) do TITIK.hapus[#TITIK.hapus + 1] = tostring(p.id or p.name) end
    table.clear(TITIK.poin)
    titikSimpan()
    pcall(function() if type(toast) == "function" then toast("✓ Semua titik dihapus", Warna.Hijau) end end)
    titikRefreshDot()
    titikRenderUI()
    titikStatusUI("Semua titik dihapus")
  end).LayoutOrder = titikNext()

  buatActionRow(scrollTitik,"↻ URUTKAN TIANG TERDEKAT",Warna.Biru,function()
    titikUrutkanTerdekat()
    rapikanNomorTitik()
    titikRefreshDot()
    titikSimpan()
    titikRenderUI()
    if type(toast)=="function" then toast("✓ Tiang diurutkan",Warna.Hijau) end
  end).LayoutOrder=titikNext()

  local titikList = buat("Frame", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = titikNext(),
  }, scrollTitik)
  buat("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, titikList)

  titikRenderUI = function()
    for _, obj in ipairs(titikList:GetChildren()) do
      if obj:IsA("Frame") then obj:Destroy() end
    end
    local daftar = {}
    for i, point in ipairs(TITIK.poin) do
      daftar[#daftar + 1] = {point = point, index = i}
    end
    for urutan, entry in ipairs(daftar) do
      local point = entry.point
      local row = buat("Frame", {
        BackgroundColor3 = Warna.AbuItem, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = urutan,
      }, titikList)
      buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
      local box = buat("TextBox", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 2),
        Size = UDim2.new(1, -120, 0, 24), FontFace = fnt("med"), TextSize = 11,
        TextColor3 = Warna.TeksGelap, TextXAlignment = Enum.TextXAlignment.Left,
        Text = point.name, ClearTextOnFocus = false,
      }, row)
      box.FocusLost:Connect(function()
        local nama = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if nama == "" then
          box.Text = point.name
        elseif namaTitikDipakai(nama, point) then
          box.Text = point.name
          titikStatusUI("Nama titik sudah dipakai: " .. nama)
        else
          point.name = nama
          point.defaultName = namaDefaultTitik(nama)
          titikSimpan(); pcall(function() if type(toast) == "function" then toast("✓ Nama disimpan", Warna.Hijau) end end); titikRefreshDot(); titikStatusUI("Nama diubah")
        end
      end)
      local go = buat("TextButton", {
        BackgroundColor3 = Warna.Biru, Position = UDim2.new(1, -108, 0, 6),
        Size = UDim2.fromOffset(50, 28), FontFace = fnt("bold"), TextSize = 10,
        TextColor3 = Warna.Putih, Text = "KE SANA", AutoButtonColor = false,
      }, row)
      buat("UICorner", {CornerRadius = UDim.new(0, 6)}, go)
      go.MouseButton1Click:Connect(function()
        local index = titikCariIndex(point)
        if index then titikTeleport(index) end
      end)
      local del = buat("TextButton", {
        BackgroundColor3 = Warna.Merah, Position = UDim2.new(1, -53, 0, 6),
        Size = UDim2.fromOffset(45, 28), FontFace = fnt("bold"), TextSize = 10,
        TextColor3 = Warna.Putih, Text = "HAPUS", AutoButtonColor = false,
      }, row)
      buat("UICorner", {CornerRadius = UDim.new(0, 6)}, del)
      del.MouseButton1Click:Connect(function()
        local index = titikCariIndex(point)
        if index then titikHapus(index) end
      end)
    end
    titikStatusUI("Titik tersimpan: " .. #TITIK.poin)
  end
  titikRenderUI()

  buat("TextLabel", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 42),
    FontFace = fnt("reg"), TextSize = 10, TextColor3 = Warna.AbuTeks,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Aktifkan mode, lalu tahan CTRL + klik kiri pada tanah/dinding untuk menempelkan titik.",
    LayoutOrder = titikNext(),
  }, scrollTitik)

  -- urutan kontenTabs
  table.insert(kontenTabs, kontenTitik)
  table.insert(kontenTabs, kontenSistem)

  -- SYSTEM tab content
  buatHeader(scrollSistem, "Info")
  local infoUser = buat("TextLabel", {
    BackgroundColor3 = Warna.AbuItem,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    FontFace = fnt("med"),
    TextSize = 12,
    TextColor3 = Warna.TeksGelap,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Text = "⚡ Absolute " .. VERSI .. "\n"
      .. "👤 User: " .. tostring(LocalPlayer.Name) .. " (" .. tostring(LocalPlayer.DisplayName) .. ")\n"
      .. "💻 Device: " .. (UserInputService.TouchEnabled and not UserInputService.MouseEnabled
      and "HP" or "PC"),
    LayoutOrder = nextOrder(),
  }, scrollSistem)
  buat("UICorner", {CornerRadius = UDim.new(0, 8)}, infoUser)
  buat("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, infoUser)

  do
    local executorTeks = "tidak dikenal"
    pcall(function()
      if type(identifyexecutor) == "function" then
        executorTeks = tostring(identifyexecutor())
      elseif type(getexecutorname) == "function" then
        executorTeks = tostring(getexecutorname())
      end
    end)
    infoUser.Text = infoUser.Text .. "\n🔧 Executor: " .. executorTeks
  end

  task.spawn(function()
    local namaMap = tostring(game.Name)
    pcall(function()
      local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
      if info and info.Name and #info.Name > 0 then namaMap = info.Name end
    end)
    if infoUser and infoUser.Parent then
      infoUser.Text = infoUser.Text
        .. "\n🗺️ Map: " .. namaMap .. " (" .. tostring(game.PlaceId) .. ")"
    end
  end)

  local infoFps = buat("TextLabel", {
    BackgroundColor3 = Warna.AbuItem,
    Size = UDim2.new(1, 0, 0, 26),
    FontFace = fnt("med"),
    TextSize = 12,
    TextColor3 = Warna.TeksGelap,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "📊 FPS: mengukur...",
    LayoutOrder = nextOrder(),
  }, scrollSistem)
  buat("UICorner", {CornerRadius = UDim.new(0, 8)}, infoFps)
  buat("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, infoFps)

  do
    local frames, cekTerakhir = 0, os.clock()
    catat(RunService.RenderStepped:Connect(function()
      frames += 1
      local now = os.clock()
      if now - cekTerakhir >= 0.5 then
        local fps = math.floor(frames / (now - cekTerakhir) + 0.5)
        frames = 0
        cekTerakhir = now
        if infoFps and infoFps.Parent then
          infoFps.Text = "📊 FPS: " .. fps
        end
      end
    end))
  end

  buatHeader(scrollSistem, "Aksi")
  buatActionRow(scrollSistem, "🔁 REJOIN SERVER  [K×2]", Warna.Biru, function() rejoin() end)
  buatActionRow(scrollSistem, "🗑️ HAPUS SCRIPT", Warna.Merah, function()
    if not _G.__ABSOLUTE_DELETE_ARMED__ then
      _G.__ABSOLUTE_DELETE_ARMED__ = true
      bunyi(CFG.SND_SNAP, 0.3, 0.8)
      toast("Tekan HAPUS sekali lagi", Warna.Merah)
      task.delay(3, function() _G.__ABSOLUTE_DELETE_ARMED__ = nil end)
    else
      _G.__ABSOLUTE_DELETE_ARMED__ = nil
      unloadScript()
    end
  end)
end -- akhir buildUI()

buildUI()
diagSet("GUI utama OK — bikin efek & notif...")

-- [17] FOOTER + LED (ringan, tanpa marquee loop) --------
local function buildFX()
  local footer = buat("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 1, -30),
    BackgroundColor3 = Warna.Hitam2,
    BorderSizePixel = 0,
  }, panel)
  buat("UICorner", {CornerRadius = UDim.new(0, 11)}, footer)
  buat("Frame", {
    Size = UDim2.new(1, 0, 0, 11),
    Position = UDim2.new(0, 0, 1, -41),
    BackgroundColor3 = Warna.Hitam2,
    BorderSizePixel = 0,
  }, panel)
  ledSweep(footer, Warna.Hitam2, Warna.Ungu, Warna.Biru, 3.2)

  local ledLabel = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 0, 17),
    FontFace = fnt("judul"),
    Text = CFG.LED_TEXT,
    TextColor3 = Warna.Putih,
    TextSize = 15,
  }, footer)
  local ledGlow = buat("UIStroke", {Name = "NoFade", Color = Warna.Ungu2, Thickness = 1, Transparency = 0.4}, ledLabel)
  cycleColor(ledLabel, "TextColor3", {Warna.Putih, Warna.Ungu2, Warna.Biru2, Warna.Ungu2}, 0.4)

  -- marquee STATIS (tanpa loop tween)
  local marqueeClip = buat("Frame", {
    Position = UDim2.new(0, 6, 0, 17),
    Size = UDim2.new(1, -12, 0, 13),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
  }, footer)
  buat("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 1, 0),
    FontFace = fnt("med"),
    Text = "G=GUI • Q=Speed • C=Shift • F=Moon • R=Hide • T=Cahaya • K×2=Rejoin",
    TextColor3 = Warna.AbuGelap,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Center,
  }, marqueeClip)

  -- bracket pojok STATIS
  local function bracket(ax, ay, px, py, warna)
    local bar1 = buat("Frame", {Name = "NoFade", AnchorPoint = Vector2.new(ax, ay),
      Position = UDim2.new(px, ax == 1 and -8 or 8, py, ay == 1 and -8 or 8),
      Size = UDim2.fromOffset(14, 3), BackgroundColor3 = warna, BorderSizePixel = 0, ZIndex = 3}, outer)
    local bar2 = buat("Frame", {Name = "NoFade", AnchorPoint = Vector2.new(ax, ay),
      Position = UDim2.new(px, ax == 1 and -3 or 3, py, ay == 1 and -3 or 3),
      Size = UDim2.fromOffset(3, 14), BackgroundColor3 = warna, BorderSizePixel = 0, ZIndex = 3}, outer)
    return {bar1, bar2}
  end
  bracket(0, 0, 0, 0, Warna.Ungu2)
  bracket(1, 0, 1, 0, Warna.Biru2)
  bracket(0, 1, 0, 1, Warna.Biru2)
  bracket(1, 1, 1, 1, Warna.Ungu2)
end

buildFX()
diagSet("efek OK — pasang logika fitur...")

-- [20] TOAST --------------------------------------------
local notifHolder = buat("Frame", {
  Name = "NotifHolder",
  AnchorPoint = Vector2.new(1, 0),
  Position = UDim2.new(1, -10, 0, 10),
  Size = UDim2.fromOffset(280, 400),
  BackgroundTransparency = 1,
  BorderSizePixel = 0,
  ZIndex = 980,
}, screenGui)
buat("UIListLayout", {
  Padding = UDim.new(0, 6),
  SortOrder = Enum.SortOrder.LayoutOrder,
  HorizontalAlignment = Enum.HorizontalAlignment.Right,
  VerticalAlignment = Enum.VerticalAlignment.Top,
}, notifHolder)

local notifCounter = 0
toast = function(teks, aksen)
  notifCounter += 1
  local t = buat("Frame", {
    Name = "NoFade",
    AnchorPoint = Vector2.new(1, 0),
    Size = UDim2.fromOffset(270, 32),
    BackgroundColor3 = Warna.Putih,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 981,
    LayoutOrder = notifCounter,
  }, notifHolder)
  buat("UICorner", {CornerRadius = UDim.new(0, 10)}, t)
  local st = buat("UIStroke", {Color = aksen or Warna.Ungu, Thickness = 1, Transparency = 1}, t)
  local dot = buat("Frame", {
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 8, 0.5, 0),
    Size = UDim2.fromOffset(6, 6),
    BackgroundColor3 = aksen or Warna.Ungu,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
  }, t)
  buat("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
  local lb = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 22, 0, 0),
    Size = UDim2.new(1, -28, 1, 0),
    FontFace = fnt("semi"),
    Text = teks,
    TextColor3 = Warna.TeksGelap,
    TextSize = 13,
    TextTransparency = 1,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextXAlignment = Enum.TextXAlignment.Left,
  }, t)
  t.Position = UDim2.new(1, 20, 0, 0)
  local ti = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
  tween(t,   ti, {BackgroundTransparency = 0.05, Position = UDim2.new(1, 0, 0, 0)})
  tween(st,  ti, {Transparency = 0.15})
  tween(dot, ti, {BackgroundTransparency = 0})
  tween(lb,  ti, {TextTransparency = 0})
  task.delay(1.6, function()
    local to = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tween(t,   to, {BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0)})
    tween(st,  to, {Transparency = 1})
    tween(dot, to, {BackgroundTransparency = 1})
    tween(lb,  to, {TextTransparency = 1})
    task.delay(0.3, function() t:Destroy() end)
  end)
  local list = {}
  for _, c in ipairs(notifHolder:GetChildren()) do
    if c:IsA("Frame") and c.Name == "NoFade" then table.insert(list, c) end
  end
  if #list > 5 then
    list[1]:Destroy()
  end
end

diagSet("efek OK — pasang logika fitur...")

-- [21] LOGIKA UTAMA -------------------------------------
local function initLogic()

  applySpeed = function()
    local hum = getHum()
    if not hum then return end
    local base = State.SpeedOn and State.SpeedValue or CFG.SPEED_OFF
    if State.TengahOn and State.IsSwimming then
      base = base * CFG.SWIM_BONUS
    end
    hum.WalkSpeed = base
  end

  local function updateSpeedLabel()
    if SpeedLabel and SpeedLabel.Parent then
      SpeedLabel.Text = "Speed (Q): "
        .. (State.SpeedOn and fmtNum(State.SpeedValue) or ("OFF (" .. fmtNum(CFG.SPEED_OFF) .. ")"))
    end
  end

  local function syncNotify(name, v, silent, label)
    local sw = Switches[name]
    if sw then sw.set(v) end
    if not silent then
      toast(label .. ": " .. (v and "ON" or "OFF"), v and Warna.Hijau or Warna.Merah)
    end
  end

  Setters.Speed = function(v, silent)
    if State.SpeedOn == v then return end
    State.SpeedOn = v
    applySpeed()
    updateSpeedLabel()
    if not v then
      task.spawn(function()
        for _ = 1, 8 do
          task.wait(0.25)
          if State.SpeedOn or State.Removed then return end
          local h = getHum()
          if h and h.WalkSpeed ~= CFG.SPEED_OFF then
            h.WalkSpeed = CFG.SPEED_OFF
          end
        end
      end)
    end
    syncNotify("Speed", v, silent, "Speed")
  end

  local function sedangDuduk(h)
    return h ~= nil and (h.SeatPart ~= nil or h.Sit == true)
  end

  Setters.Shift = function(v, silent)
    if State.ShiftOn == v then return end
    State.ShiftOn = v
    if v then
      if State.TengahOn then setFeature("Tengah", false, true) end
      local hum = getHum()
      if hum then hum.AutoRotate = false end
      pcall(function() RunService:UnbindFromRenderStep("ABSOLUTE_SHIFTLOCK") end)
      RunService:BindToRenderStep("ABSOLUTE_SHIFTLOCK", Enum.RenderPriority.Character.Value + 1, function()
        local char = getChar()
        local h = char and char:FindFirstChildOfClass("Humanoid")
        local r = char and char:FindFirstChild("HumanoidRootPart")
        if h and sedangDuduk(h) then
          if not h.AutoRotate then h.AutoRotate = true end
          return
        end
        if h and h.AutoRotate then h.AutoRotate = false end
        if h and r and h.Health > 0 then
          local cam = Workspace.CurrentCamera
          local _, yaw = cam.CFrame:ToOrientation()
          r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, yaw, 0)
        end
      end)
    else
      RunService:UnbindFromRenderStep("ABSOLUTE_SHIFTLOCK")
      local hum = getHum()
      if hum then hum.AutoRotate = true end
      applySpeed()
    end
    syncNotify("Shift", v, silent, "Shiftlock Mobile")
  end

  Setters.Moon = function(v, silent)
    if State.MoonOn == v then return end
    State.MoonOn = v
    if v then
      if State.TengahOn then setFeature("Tengah", false, true) end
      local hum = getHum()
      if hum then hum.AutoRotate = false end
      pcall(function() RunService:UnbindFromRenderStep("ABSOLUTE_MOONWALK") end)
      RunService:BindToRenderStep("ABSOLUTE_MOONWALK", Enum.RenderPriority.Character.Value + 1, function(dt)
        local char = getChar()
        local h = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if h and sedangDuduk(h) then
          if not h.AutoRotate then h.AutoRotate = true end
          return
        end
        if h and h.AutoRotate then h.AutoRotate = false end
        if h and hrp and h.Health > 0 then
          local cam = Workspace.CurrentCamera
          if cam and h.MoveDirection.Magnitude > 0.01 then
            local _, yawCam = cam.CFrame:ToOrientation()
            local target = yawCam + math.pi
            local _, yawSek = hrp.CFrame:ToOrientation()
            local selisih = ((target - yawSek + math.pi) % (2 * math.pi)) - math.pi
            local langkah = selisih * math.min(dt * CFG.MOON_SMOOTH, 1)
            local maks = CFG.MOON_TURN_MAX * dt
            if langkah > maks then langkah = maks elseif langkah < -maks then langkah = -maks end
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yawSek + langkah, 0)
          end
        end
      end)
    else
      RunService:UnbindFromRenderStep("ABSOLUTE_MOONWALK")
      local hum = getHum()
      if hum then hum.AutoRotate = true end
    end
    syncNotify("Moon", v, silent, "Moonwalk")
  end

  local sltTween, sltTweening, sltOffsetAsli = nil, false, nil
  local sltDotGui, sltDot
  local sltUGS
  pcall(function() sltUGS = UserSettings():GetService("UserGameSettings") end)

  local function sltDotShow()
    if sltDot then sltDot.Visible = true return end
    sltDotGui = buat("ScreenGui", {
      Name = "ABSOLUTE_TengahDot",
      ResetOnSpawn = false,
      DisplayOrder = 99999,
      IgnoreGuiInset = true,
    })
    sltDot = buat("Frame", {
      Name = "Lingkaran",
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = UDim2.fromScale(0.5, CFG.SLT_DOT_Y),
      Size = UDim2.fromOffset(CFG.SLT_DOT, CFG.SLT_DOT),
      BackgroundColor3 = Warna.Putih,
      BackgroundTransparency = 0.1,
      BorderSizePixel = 0,
    }, sltDotGui)
    buat("UICorner", {CornerRadius = UDim.new(1, 0)}, sltDot)
    buat("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1,
      Transparency = 0.35}, sltDot)
    local kandidat = {}
    pcall(function() if gethui then table.insert(kandidat, gethui()) end end)
    pcall(function() table.insert(kandidat, game:GetService("CoreGui")) end)
    pcall(function() table.insert(kandidat, LocalPlayer:WaitForChild("PlayerGui")) end)
    for _, t in ipairs(kandidat) do
      pcall(function()
        local lama = t:FindFirstChild("ABSOLUTE_TengahDot")
        if lama and lama ~= sltDotGui then lama:Destroy() end
      end)
    end
    for _, t in ipairs(kandidat) do
      local ok = pcall(function() sltDotGui.Parent = t end)
      if ok and sltDotGui.Parent == t then break end
    end
  end

  local function sltDotHide()
    if sltDot then sltDot.Visible = false end
  end

  Setters.Tengah = function(v, silent)
    if State.TengahOn == v then return end
    State.TengahOn = v
    if v then
      if State.ShiftOn then setFeature("Shift", false, true) end
      if State.MoonOn then setFeature("Moon", false, true) end
      local hum = getHum()
      if hum then
        sltOffsetAsli = hum.CameraOffset
        sltTweening = true
        if sltTween then sltTween:Cancel() end
        sltTween = TweenService:Create(hum,
          TweenInfo.new(CFG.SLT_WAKTU, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
          {CameraOffset = Vector3.zero})
        sltTween:Play()
        sltTween.Completed:Connect(function() sltTweening = false end)
      end
      pcall(function() RunService:UnbindFromRenderStep("ABSOLUTE_TENGAH") end)
      RunService:BindToRenderStep("ABSOLUTE_TENGAH", Enum.RenderPriority.Camera.Value + 1, function()
        local h = getHum()
        if h and h.Health > 0 then
          UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
          if sltUGS then
            pcall(function() sltUGS.RotationType = Enum.RotationType.CameraRelative end)
          end
          if not sltTweening and h.CameraOffset ~= Vector3.zero then
            h.CameraOffset = Vector3.zero
          end
        end
      end)
      pcall(function() UserInputService.MouseIconEnabled = false end)
      sltDotShow()
    else
      pcall(function() RunService:UnbindFromRenderStep("ABSOLUTE_TENGAH") end)
      UserInputService.MouseBehavior = Enum.MouseBehavior.Default
      if sltUGS then
        pcall(function() sltUGS.RotationType = Enum.RotationType.MovementRelative end)
      end
      if sltTween then sltTween:Cancel() end
      local hum = getHum()
      if hum and sltOffsetAsli then hum.CameraOffset = sltOffsetAsli end
      sltOffsetAsli = nil
      pcall(function() UserInputService.MouseIconEnabled = true end)
      sltDotHide()
    end
    applySpeed()
    syncNotify("Tengah", v, silent, "Shiftlock Tengah")
  end

  -- HIDE PLAYER + KENDARAAN
  local hiddenParts, hiddenBB, hiddenEffects, hiddenHumans, hiddenCharConns = {}, {}, {}, {}, {}
  local function hideApplyTo(obj)
    local effect = obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
      or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Highlight")
      or obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight")
      or obj:IsA("SurfaceGui")
    if effect and hiddenEffects[obj] == nil then
      hiddenEffects[obj] = obj.Enabled
      obj.Enabled = false
    elseif (obj:IsA("BasePart") or obj:IsA("Decal")) and hiddenParts[obj] == nil then
      hiddenParts[obj] = obj.Transparency
      obj.Transparency = 1
    elseif obj:IsA("BillboardGui") and hiddenBB[obj] == nil then
      hiddenBB[obj] = obj.Enabled
      obj.Enabled = false
    end
  end

  local function hideCharacter(char)
    if hiddenCharConns[char] then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
      hiddenHumans[hum] = hum.DisplayDistanceType
      hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    for _, obj in ipairs(char:GetDescendants()) do hideApplyTo(obj) end
    hiddenCharConns[char] = char.DescendantAdded:Connect(hideApplyTo)
  end

  local function unhideCharacter(char)
    local conn = hiddenCharConns[char]
    if conn then conn:Disconnect() hiddenCharConns[char] = nil end
  end

  local function unhideAll()
    for obj, t in pairs(hiddenParts) do
      pcall(function() if obj.Parent then obj.Transparency = t end end)
    end
    table.clear(hiddenParts)
    for obj, e in pairs(hiddenBB) do
      pcall(function() if obj.Parent then obj.Enabled = e end end)
    end
    table.clear(hiddenBB)
    for obj, e in pairs(hiddenEffects) do
      pcall(function() if obj.Parent then obj.Enabled = e end end)
    end
    table.clear(hiddenEffects)
    for hum, d in pairs(hiddenHumans) do
      pcall(function() if hum.Parent then hum.DisplayDistanceType = d end end)
    end
    table.clear(hiddenHumans)
    for char in pairs(hiddenCharConns) do unhideCharacter(char) end
  end

  local vehParts = {}
  local overlapParams = OverlapParams.new()
  local function isMyStuff(model)
    local char = getChar()
    if not char then return false end
    if model == char or char:IsDescendantOf(model) then return true end
    local hum = getHum()
    if hum and hum.SeatPart then
      if hum.SeatPart:FindFirstAncestorOfClass("Model") == model then return true end
    end
    return false
  end

  local function vehicleModelFromPart(part)
    local m = part:FindFirstAncestorOfClass("Model")
    while m do
      if m:FindFirstChildWhichIsA("Humanoid", true) then return nil end
      if m:FindFirstChildWhichIsA("VehicleSeat", true) or m:FindFirstChildWhichIsA("Seat", true) then
        local s = m:GetExtentsSize()
        if math.max(s.X, s.Y, s.Z) <= 64 then return m end
        return nil
      end
      m = m:FindFirstAncestorOfClass("Model")
    end
    return nil
  end

  local function applyVehicleHide(model)
    local set = vehParts[model]
    if not set then set = {} vehParts[model] = set end
    for _, p in ipairs(model:GetDescendants()) do
      if p:IsA("BasePart") and set[p] == nil then
        set[p] = p.Transparency
        p.Transparency = math.max(p.Transparency, 0.8)
      end
    end
  end

  local function restoreVehicle(model)
    local set = vehParts[model]
    if not set then return end
    vehParts[model] = nil
    for p, t in pairs(set) do
      pcall(function() if p.Parent then p.Transparency = t end end)
    end
  end

  local function updateVehicles()
    local char = getChar()
    local r = char and char:FindFirstChild("HumanoidRootPart")
    if not r then return end
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = char and {char} or {}
    local near = {}
    for _, part in ipairs(Workspace:GetPartBoundsInRadius(r.Position, 12, overlapParams)) do
      local m = vehicleModelFromPart(part)
      if m and not isMyStuff(m) then near[m] = true end
    end
    for m in pairs(near) do applyVehicleHide(m) end
    for m in pairs(vehParts) do
      if not near[m] then restoreVehicle(m) end
    end
  end

  local function restoreAllVehicles()
    for m in pairs(vehParts) do restoreVehicle(m) end
  end

  local function playerHideHook(plr)
    if plr == LocalPlayer then return end
    catat(plr.CharacterAdded:Connect(function(char)
      task.wait(0.4)
      if State.HideOn and not State.Removed then hideCharacter(char) end
    end))
    if plr.Character and State.HideOn then hideCharacter(plr.Character) end
  end

  Setters.Hide = function(v, silent)
    if State.HideOn == v then return end
    State.HideOn = v
    if v then
      for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then hideCharacter(plr.Character) end
      end
    else
      unhideAll()
      restoreAllVehicles()
    end
    syncNotify("Hide", v, silent, "Hide Player + Kendaraan")
  end

  -- REMOVE CUACA (Atmosphere & Clouds) — Toggle 100% lokal
  local weatherHidden = {}
  local weatherFolder = Instance.new("Folder")
  weatherFolder.Name = "__ABSOLUTE_CUACA_HIDDEN__"
  weatherFolder.Parent = Lighting
  local weatherConn = nil
  local CUACA_CONTAINERS = { Lighting, Workspace, Terrain }

  local function sapuCuaca()
    for _, container in ipairs(CUACA_CONTAINERS) do
      for _, obj in ipairs(container:GetChildren()) do
        if (obj:IsA("Atmosphere") or obj:IsA("Clouds")) and obj.Parent ~= weatherFolder then
          weatherHidden[obj] = obj.Parent
          obj.Parent = weatherFolder
        end
      end
    end
  end

  local function kembalikanCuaca()
    for obj, asli in pairs(weatherHidden) do
      pcall(function()
        if obj.Parent and asli then obj.Parent = asli end
      end)
    end
    table.clear(weatherHidden)
  end

  Setters.Cuaca = function(v, silent)
    if State.CuacaOn == v then return end
    State.CuacaOn = v
    if v then
      sapuCuaca()
      weatherConn = Lighting.DescendantAdded:Connect(function(obj)
        if not State.CuacaOn or State.Removed then return end
        if obj:IsA("Atmosphere") or obj:IsA("Clouds") then
          task.defer(function()
            if not State.CuacaOn or State.Removed then return end
            if obj.Parent and obj.Parent ~= weatherFolder then
              weatherHidden[obj] = obj.Parent
              obj.Parent = weatherFolder
            end
          end)
        end
      end)
    else
      if weatherConn then weatherConn:Disconnect() weatherConn = nil end
      kembalikanCuaca()
    end
    syncNotify("Cuaca", v, silent, "Remove Cuaca")
  end

  -- LIGHTWEIGHT
  local lwEffects, lwConns = {}, {}
  local function lwDisable(obj)
    local dis = obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
      or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("PostEffect")
    if dis and lwEffects[obj] == nil then
      lwEffects[obj] = obj.Enabled
      obj.Enabled = false
    end
  end

  Setters.LW = function(v, silent)
    if State.LWOn == v then return end
    State.LWOn = v
    if v then
      Original.GlobalShadows = Lighting.GlobalShadows
      Lighting.GlobalShadows = false
      Original.WaterWaveSize = Terrain.WaterWaveSize
      Original.WaterWaveSpeed = Terrain.WaterWaveSpeed
      Terrain.WaterWaveSize = 0
      Terrain.WaterWaveSpeed = 0
      for _, obj in ipairs(Workspace:GetDescendants()) do lwDisable(obj) end
      for _, obj in ipairs(Lighting:GetDescendants()) do lwDisable(obj) end
      table.insert(lwConns, Workspace.DescendantAdded:Connect(function(obj) task.defer(lwDisable, obj) end))
      table.insert(lwConns, Lighting.DescendantAdded:Connect(function(obj) task.defer(lwDisable, obj) end))
    else
      if Original.GlobalShadows ~= nil then Lighting.GlobalShadows = Original.GlobalShadows end
      if Original.WaterWaveSize ~= nil then Terrain.WaterWaveSize = Original.WaterWaveSize end
      if Original.WaterWaveSpeed ~= nil then Terrain.WaterWaveSpeed = Original.WaterWaveSpeed end
      for obj, e in pairs(lwEffects) do
        pcall(function() if obj.Parent then obj.Enabled = e end end)
      end
      table.clear(lwEffects)
      for _, c in ipairs(lwConns) do c:Disconnect() end
      table.clear(lwConns)
    end
    syncNotify("LW", v, silent, "Lightweight")
  end

  -- CAHAYA AUTO
  local CAHAYA = {
    JAM_MALAM_MULAI  = 18,
    JAM_MALAM_AKHIR  = 6,
    CLOCK_TERANGI    = 14,
    BRIGHT_TERANGI   = 2.5,
    AMBIENT_TERANGI  = Color3.fromRGB(140, 140, 165),
    CLOCK_ANTISILAU  = 17.5,
    BRIGHT_ANTISILAU = 1.6,
    AMBIENT_LEMBUT   = Color3.fromRGB(110, 110, 120),
    FOG_BUKA         = 100000,
  }
  local lightPernahAktif = false

  local function apakahMalam()
    local t = Lighting.ClockTime
    return t >= CAHAYA.JAM_MALAM_MULAI or t < CAHAYA.JAM_MALAM_AKHIR
  end

  local function targetCahaya()
    if apakahMalam() then
      return CAHAYA.CLOCK_TERANGI, CAHAYA.BRIGHT_TERANGI, CAHAYA.AMBIENT_TERANGI
    end
    return CAHAYA.CLOCK_ANTISILAU, CAHAYA.BRIGHT_ANTISILAU, CAHAYA.AMBIENT_LEMBUT
  end

  local function langkahCahaya()
    local jamTarget, brightTarget, ambientTarget = targetCahaya()
    local jam0 = Lighting.ClockTime
    local delta = jamTarget - jam0
    if delta > 12 then delta -= 24 elseif delta < -12 then delta += 24 end
    local bright0 = Lighting.Brightness
    local ambient0 = Lighting.Ambient
    local out0 = Lighting.OutdoorAmbient
    local jumlah = 22
    for i = 1, jumlah do
      if not State.LightOn or State.Removed then return end
      local a = i / jumlah
      pcall(function()
        Lighting.ClockTime = (jam0 + delta * a) % 24
        Lighting.Brightness = bright0 + (brightTarget - bright0) * a
        Lighting.Ambient = ambient0:Lerp(ambientTarget, a)
        Lighting.OutdoorAmbient = out0:Lerp(ambientTarget, a)
      end)
      task.wait(0.05)
    end
    pcall(function()
      Lighting.ClockTime = jamTarget % 24
      Lighting.Brightness = brightTarget
      Lighting.Ambient = ambientTarget
      Lighting.OutdoorAmbient = ambientTarget
    end)
  end

  Setters.Light = function(v, silent)
    if State.LightOn == v then return end
    State.LightOn = v
    if v then
      lightPernahAktif = true
      oLight.Brightness = Lighting.Brightness
      oLight.Ambient = Lighting.Ambient
      oLight.OutdoorAmbient = Lighting.OutdoorAmbient
      oLight.ClockTime = Lighting.ClockTime
      oLight.ExposureCompensation = Lighting.ExposureCompensation
      oLight.FogEnd = Lighting.FogEnd
      if Lighting.FogEnd < 5000 then
        Lighting.FogEnd = CAHAYA.FOG_BUKA
      end
      if lightConn then task.cancel(lightConn) end
      lightConn = task.spawn(function()
        while State.LightOn and not State.Removed do
          langkahCahaya()
          local tunggu = 0
          while tunggu < 2 and State.LightOn and not State.Removed do
            task.wait(0.25)
            tunggu += 0.25
          end
        end
      end)
    else
      if lightConn then task.cancel(lightConn) lightConn = nil end
      pcall(function()
        Lighting.ClockTime = oLight.ClockTime
        Lighting.Brightness = oLight.Brightness
        Lighting.Ambient = oLight.Ambient
        Lighting.OutdoorAmbient = oLight.OutdoorAmbient
        Lighting.ExposureCompensation = oLight.ExposureCompensation
        Lighting.FogEnd = oLight.FogEnd
      end)
    end
    syncNotify("Light", v, silent, "Cahaya Auto")
  end

  rejoin = function()
    toast("🔁 Rejoin dalam 3 detik...", Warna.Biru)
    task.delay(3, function()
      local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
      end)
      if not ok then
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
      end
    end)
  end

  unloadScript = function(tenang)
    if State.Removed then return end
    State.Removed = true
    pcall(setFeature, "Speed", false, true)
    pcall(setFeature, "Shift", false, true)
    pcall(setFeature, "Moon", false, true)
    pcall(setFeature, "Tengah", false, true)
    pcall(setFeature, "Hide", false, true)
    pcall(setFeature, "LW", false, true)
    pcall(setFeature, "Light", false, true)
    pcall(setFeature, "Cuaca", false, true)
    pcall(function() RunService:UnbindFromRenderStep("ABSOLUTE_SHIFTLOCK") end)
    pcall(function() RunService:UnbindFromRenderStep("ABSOLUTE_MOONWALK") end)
    pcall(function() RunService:UnbindFromRenderStep("ABSOLUTE_TENGAH") end)
    pcall(function()
      if sltDotGui then sltDotGui:Destroy() end
      sltDotGui, sltDot = nil, nil
    end)
    if not tenang then
      pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
      pcall(function()
        UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.MovementRelative
      end)
      pcall(function() UserInputService.MouseIconEnabled = true end)
    end
    pcall(function() if TITIK.folder then TITIK.folder:Destroy(); TITIK.folder = nil end end)
    if lightConn then pcall(function() task.cancel(lightConn) end) lightConn = nil end
    pcall(function() if weatherFolder then weatherFolder:Destroy() weatherFolder = nil end end)
    for _, c in ipairs(semuaKoneksi) do
      pcall(function() c:Disconnect() end)
    end
    table.clear(semuaKoneksi)
    pcall(function()
      if lightPernahAktif and oLight then
        Lighting.ClockTime = oLight.ClockTime
        Lighting.Brightness = oLight.Brightness
        Lighting.Ambient = oLight.Ambient
        Lighting.OutdoorAmbient = oLight.OutdoorAmbient
        Lighting.ExposureCompensation = oLight.ExposureCompensation
        Lighting.FogEnd = oLight.FogEnd
      end
    end)
    pcall(function()
      if Original then
        if Original.GlobalShadows ~= nil then Lighting.GlobalShadows = Original.GlobalShadows end
        if Original.WaterWaveSize ~= nil then Terrain.WaterWaveSize = Original.WaterWaveSize end
        if Original.WaterWaveSpeed ~= nil then Terrain.WaterWaveSpeed = Original.WaterWaveSpeed end
      end
    end)
    if not tenang then
      pcall(function()
        local char = LocalPlayer.Character
        if char then
          local h = char:FindFirstChildOfClass("Humanoid")
          if h then
            h.WalkSpeed = CFG.SPEED_OFF
            h.AutoRotate = true
          end
        end
      end)
    end
    pcall(function() if screenGui then screenGui:Destroy() end end)
    _G.__ABSOLUTE_MAIN__ = nil
    _G.__ABSOLUTE_DELETE_ARMED__ = nil
    pcall(function()
      if script and script.Parent then
        script.Disabled = true
        script:Destroy()
      end
    end)
    print("[Absolute] Script dihapus total ✔")
  end

  task.spawn(function()
    while not State.Removed do
      if _G.__ABSOLUTE_TOKEN__ ~= MY_TOKEN or not screenGui.Parent then
        local adaPenerus = (_G.__ABSOLUTE_TOKEN__ ~= MY_TOKEN)
        pcall(function() unloadScript(adaPenerus) end)
        break
      end
      task.wait(0.5)
    end
  end)

  local initedChar
  local function initCharacter(char)
    if State.Removed then return end
    if initedChar == char then return end
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    initedChar = char
    local function matikanGerak()
      local ada = State.ShiftOn or State.MoonOn or State.TengahOn
      if State.ShiftOn then setFeature("Shift", false, true) end
      if State.MoonOn then setFeature("Moon", false, true) end
      if State.TengahOn then setFeature("Tengah", false, true) end
      if ada and not State.Removed then
        toast("Shiftlock/Moonwalk OFF (mati/respawn)", Warna.Kuning)
      end
    end
    matikanGerak()
    catat(hum.Died:Connect(matikanGerak))
    catat(hum.StateChanged:Connect(function(_, newState)
      local swimming = (newState == Enum.HumanoidStateType.Swimming)
      if swimming ~= State.IsSwimming then
        State.IsSwimming = swimming
        applySpeed()
      end
    end))
    task.wait(0.25)
    if State.Removed then return end
    if State.SpeedOn then applySpeed() end
  end

  catat(LocalPlayer.CharacterAdded:Connect(initCharacter))
  task.spawn(function()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    initCharacter(c)
  end)

  catat(Players.PlayerAdded:Connect(playerHideHook))
  for _, plr in ipairs(Players:GetPlayers()) do playerHideHook(plr) end
  catat(Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then unhideCharacter(plr.Character) end
  end))

  task.spawn(function()
    while not State.Removed do
      if State.HideOn then pcall(updateVehicles) end
      task.wait(0.8)
    end
  end)

  local function minimizeGui()
    if not root.Visible then return end
    bunyi(CFG.SND_PING, 0.3, 0.75)
    root.Visible = false
    root.Rotation = 0
    panelScale.Scale = 1
  end

  local function bukaGui()
    fitPanel()
    bunyi(CFG.SND_PING, 0.35, 1.15)
    root.Visible = true
    root.Rotation = 0
    panelScale.Scale = 1
  end

  togglePanel = function()
    if root.Visible then minimizeGui() else bukaGui() end
  end

  minBtn.MouseButton1Click:Connect(function()
    ripple(minBtn, Warna.Ungu2)
    minimizeGui()
  end)

  buatDraggable(header, root)

  catat(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or State.Removed or not TITIK.aktif then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
    or UserInputService:IsKeyDown(Enum.KeyCode.RightControl))
    and not UserInputService:GetFocusedTextBox() then
      titikKlikDunia()
    end
  end))

  local lastK = 0
  catat(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.S
    and not UserInputService:GetFocusedTextBox()
    and not State.Removed and State.MoonOn then
      setFeature("Moon", false)
      return
    end
    if gameProcessed then return end
    if State.Removed then return end
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == CFG.TOGGLE_KEY then
      togglePanel()
    elseif input.KeyCode == Enum.KeyCode.Q then
      setFeature("Speed", not State.SpeedOn)
    elseif input.KeyCode == Enum.KeyCode.C then
      setFeature("Shift", not State.ShiftOn)
    elseif input.KeyCode == Enum.KeyCode.F then
      setFeature("Moon", not State.MoonOn)
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
      setFeature("Tengah", not State.TengahOn)
    elseif input.KeyCode == Enum.KeyCode.R then
      setFeature("Hide", not State.HideOn)
    elseif input.KeyCode == Enum.KeyCode.T then
      setFeature("Light", not State.LightOn)
    elseif input.KeyCode == Enum.KeyCode.K then
      local now = os.clock()
      if now - lastK < 0.45 then
        lastK = 0
        rejoin()
      else
        lastK = now
        toast("Tekan K sekali lagi untuk Rejoin", Warna.Biru)
      end
    end
  end))

  diagSet("keybind OK — finalisasi...")

  updateSpeedLabel()
  setTab(1)
  task.delay(0.15, function()
    local okG, errG = pcall(bukaGui)
    if not okG then
      diagSet("GUI gagal terbuka: " .. tostring(errG), Color3.fromRGB(239, 68, 68))
      warn("[Absolute] bukaGui error: " .. tostring(errG))
    end
  end)

  print("[Absolute " .. VERSI .. "] SIAP ✔ — G = GUI | K×2 = rejoin")
  diagHapus()
end

initLogic()
getgenv().ABSOLUTE_API = { Setters = Setters, State = State }

end, function(e)
  local teks = tostring(e)
  print("==================================================")
  print("[Absolute " .. VERSI .. "] ERROR SAAT LOAD:")
  print(teks)
  pcall(function() print(debug.traceback("", 2)) end)
  print("==================================================")
  pcall(function()
    diagSet("ERROR LOAD: " .. teks:sub(1, 260), Color3.fromRGB(239, 68, 68))
  end)
end)

if not __ABSOLUTE_LOAD_OK__ then
  warn("[Absolute " .. VERSI .. "] Script GAGAL load — banner MERAH di layar berisi errornya.")
end
