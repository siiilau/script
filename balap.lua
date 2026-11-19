--========================================================
--  BALAP V1.5 — TEMA: SILAU NEON (ungu/biru LED) — LOCAL ONLY
--  Tab: MOVEMENT & VISUAL • ANIMASI • EMOTE • TITIK • SYSTEM
--
--  Keybind:
--    G = buka/tutup GUI      Q = Speed          J = JumpPower
--    C = Shiftlock Mobile    LShift/RShift = Shiftlock Tengah
--    F = Moonwalk            R = Hide           Z = Hide Atas
--    T = Cahaya Auto         X = Dinding Batas  K = Rejoin (tekan 2x)
--
--  Riwayat:
--    v1.1 benang/garis dihapus
--    v1.2 emote/paket bisa dihapus
--    v1.3 Cloud Titik, Label Jarak & Panah Deteksi dihapus demi performa
--    v1.4 emote favorit pindah grup ★, hapus emote/paket/bundle dibuang,
--         RESET/ASLI benar-benar balik ke animasi asli (baseline disimpan
--         ke file), kolom TAMBAH EMOTE dibuang
--    v1.5 FILTER ANIMASI + RINGAN + 24 EMOTE:
--         • EMOTE_PRESET difilter: IDLE=Vampire, RUN=Ninja+Mage,
--           JUMP/FALL=Oldschool, WALK/SWIM/CLIMB=KOSONG
--         • BUNDLE_ANIMATIONS difilter: IDLE=Adidas Community+Vampire,
--           RUN=11 bundle, JUMP/FALL=Oldschool+Wickled Popular,
--           WALK/SWIM/CLIMB=KOSONG
--         • EMOTE_CATALOG difilter: hanya 24 emote pilihan user
--         • HAPUS dekorasi berat: partikel ambient, marquee teks
--           berjalan, bracket pulse, title glow loop, header sparkle
--         • Virtual scroll Emote (max 40 button sekaligus)
--         • Optimize HideAtas (DescendantAdded ganti Heartbeat)
--         • Optimize Vehicle hide (radius 20→12, cek 0.3→0.8 dtk)
--         • Reset baseline safeguard: kebal ternoda
--========================================================
print("[BALAP V1.5] load mulai...")

-- [0] DIAGNOSTIK ON-SCREEN ------------------------------------
local diagSet, diagHapus
do
  local __dGui, __dLbl
  pcall(function()
    __dGui = Instance.new("ScreenGui")
    __dGui.Name = "BALAP_DIAG"
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
    __dLbl.Text = "BALAP: memulai..."
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
    print("[BALAP-DIAG] " .. tostring(teks))
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

local VERSI = "V1.5"
local __BALAP_LOAD_OK__ = xpcall(function()

-- [1] PENGAMAN DASAR --------------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
  warn("[BALAP] GAGAL: harus jalan di CLIENT (executor / LocalScript), bukan server!")
  return
end
if not game:IsLoaded() then
  diagSet("menunggu game load... (nyangkut di sini = game belum selesai load)")
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
  warn("[BALAP] GAGAL: LocalPlayer belum ada.")
  diagSet("GAGAL: LocalPlayer tidak ada (dapat nil)", Color3.fromRGB(239, 68, 68))
  return
end

diagSet("cek Terrain...")
local Terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace:WaitForChild("Terrain", 10)
if not Terrain then
  warn("[BALAP] Terrain tidak ketemu (10 dtk) — lanjut tanpa Terrain.")
  diagSet("Terrain tidak ketemu — lanjut tanpa Terrain")
end

local MY_TOKEN = {}
_G.__BALAP_TOKEN__ = MY_TOKEN
_G.__BALAP_MAIN__ = true

-- [2] KONFIGURASI -----------------------------------------
local CFG = {
  TOGGLE_KEY      = Enum.KeyCode.G,
  LED_TEXT        = "⚡ B A L A P ⚡",
  SOUND_ON        = true,
  FX_LEVEL        = 1,
  SPEED_OFF   = 17.15,
  SPEED_ON_1  = 17.25,
  SPEED_ON_2  = 40,
  ON_JUMP_MIN = 51.25,
  ON_JUMP_MAX = 70,
  ON_JUMP     = 65.25,
  ON_JUMP_H_MIN = 6.69,
  ON_JUMP_H   = 8.50,
  ON_JUMP_H_MAX = 12.49,
  MOON_TURN_MAX = 12,
  MOON_SMOOTH = 10,
  SLT_WAKTU   = 0.25,
  SLT_DOT     = 7,
  SLT_DOT_Y   = 0.60,
  EMOTE_TUNGGAK    = 0.25,
  SWIM_BONUS         = 1.025,
  UI_LEBAR     = 360,
  UI_TINGGI    = 720,
  UI_SCALE_MIN = 0.45,
  UI_SCALE_MAX = 1.25,
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

-- [3] FONT KOMPATIBEL -------------------------------------
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
        judul = Enum.FontWeight.Regular,
        bold  = Enum.FontWeight.Bold,
        semi  = Enum.FontWeight.SemiBold,
        med   = Enum.FontWeight.Medium,
        reg   = Enum.FontWeight.Regular,
      }
      v = Font.new(fam[k], wts[k])
    else
      local legacy = {
        judul = Enum.Font.Bangers,
        bold  = Enum.Font.GothamBold,
        semi  = Enum.Font.GothamSemibold,
        med   = Enum.Font.GothamMedium,
        reg   = Enum.Font.Gotham,
      }
      v = legacy[k]
    end
    cache[k] = v
    return v
  end
end

-- [4] HELPER ----------------------------------------------
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

-- [5] REGISTRY KONEKSI & FORWARD DECLARE ------------------
local semuaKoneksi = {}
local function catat(conn)
  table.insert(semuaKoneksi, conn)
  return conn
end

local function putuskan(conn)
  local i = table.find(semuaKoneksi, conn)
  if i then table.remove(semuaKoneksi, i) end
  pcall(function() conn:Disconnect() end)
end

local State = { Removed = false }
local Original = {}
local Setters, Switches = {}, {}
local effGradients, effTweens = {}, {}
local setFeature, togglePanel, rejoin, unloadScript
local applySpeed, applyJump, updateJumpLabel
local RefreshSpeed, RefreshJump, JumpLabel, SpeedLabel
local oLight, lightConn

local konfeti, emojiBurst, pusatDiRoot, toast
local emoteSetMaster, emotePilihPreset, emotePilihBundle, emoteRefreshGrid, emoteBukaChooser

local tabBtns, kontenTabs, setTab
local kontenMove, scrollMove
local kontenAnim, scrollAnim
local kontenEmote, scrollEmote
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

-- [6] TITIK LOKAL -----------------------------------------
local TITIK_FILE = "BALAP_TITIK.json"
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
  f.Name = "BALAP_TITIK_MARKERS"
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
  getgenv().BALAP_TITIK_DATA = data
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
  if type(data) ~= "table" then data = rawget(getgenv(), "BALAP_TITIK_DATA") end
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
  pcall(function() if type(toast) == "function" then toast("✓ Titik disimpan lokal: " .. name, Warna.Hijau) end end)
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
    titikSimpan(); pcall(function() if type(toast) == "function" then toast("✓ Titik dihapus dan disimpan lokal", Warna.Hijau) end end); titikRefreshDot(); titikRenderUI()
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

-- [7] EFEK LED & UI HELPER --------------------------------
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

local function sorotInput(box, stroke, rest)
  box.Focused:Connect(function()
    tween(stroke, TweenInfo.new(0.15), {Transparency = 0})
  end)
  box.FocusLost:Connect(function()
    tween(stroke, TweenInfo.new(0.2), {Transparency = rest})
  end)
end

local function gayaToggle(btn, on)
  btn.BackgroundColor3 = on and Warna.Hijau or Warna.Merah
  btn.BackgroundTransparency = on and 0.78 or 0.82
  btn.TextColor3 = on and Warna.HijauMuda or Warna.MerahMuda
end

-- [8] SCREENGUI -------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BalapMain"
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
    local lama = t:FindFirstChild("BalapMain")
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
  warn("[BALAP] GAGAL: tidak bisa memasang GUI.")
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

-- [9] BANGUN UI: ROOT + OUTER + PANEL ---------------------
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

-- v1.5: HAPUS stripe dekorasi (berat, tidak perlu)

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
  Text = "⚡ BALAP " .. VERSI .. " ⚡",
  TextColor3 = Warna.Putih,
  TextSize = 22,
  TextXAlignment = Enum.TextXAlignment.Left,
}, header)
ledSweep(title, Warna.Putih, Warna.Ungu2, Warna.Biru2, 2.2)

-- v1.5: titleGlow STATIS (tanpa loop tween — hemat CPU)
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

-- [10] MODUL ANIMASI (tab ANIMASI) — v1.5 FILTERED --------
-- v1.5: EMOTE_PRESET difilter sesuai permintaan user:
--   IDLE: Vampire
--   WALK: KOSONG
--   RUN: Ninja, Mage
--   JUMP: Oldschool
--   FALL: Oldschool
--   CLIMB: KOSONG
--   SWIM: KOSONG
local EMOTE_PRESET = {
  idle = {
    { n = "Vampire", i15 = 1083445855, i6 = 1113742618 },
  },
  walk = {},
  run = {
    { n = "Ninja", i15 = 656118852, i6 = 658830056 },
    { n = "Mage", i15 = 707861613, i6 = 754635032 },
  },
  jump = {
    { n = "Oldschool", i15 = 5319841935, i6 = 5319917561 },
  },
  fall = {
    { n = "Oldschool", i15 = 5319839762, i6 = 5319914476 },
  },
  climb = {},
  swim = {},
}

-- v1.5: BUNDLE_ANIMATIONS difilter sesuai permintaan user:
--   IDLE: Adidas Community, Vampire
--   RUN: Wickled Popular, Unboxed, Stylized Female, Sneaky, Mr. Toilet,
--        Bold, Adidas Sports, Adidas Community, Adidas Aura, Ninja, Mage
--   JUMP: Oldschool, Wickled Popular
--   FALL: Oldschool, Wickled Popular
--   WALK/SWIM/CLIMB: KOSONG (field di-set 0)
local BUNDLE_ANIMATIONS = {
  Emotes = {Weight=9, Weight2=1},
  -- IDLE
  ['Adidas Community'] = {Idle=122257458498464, Idle2=102357151005774, Idle3=89262795687364, Walk=0, Run=0, Jump=0, Climb=0, Fall=0, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  ['Vampire'] = {Idle=1083445855, Idle2=1083450166, Idle3=1088037547, Walk=0, Run=0, Jump=0, Climb=0, Fall=0, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  -- RUN
  ['Wickled Popular'] = {Idle=0, Idle2=0, Idle3=0, Walk=0, Run=72301599441680, Jump=104325245285198, Climb=0, Fall=121152442762481, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  ['Unboxed'] = {Idle=0, Idle2=0, Idle3=0, Walk=0, Run=134824450619865, Jump=121454505477205, Climb=0, Fall=94788218468396, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  ['Stylized Female'] = {Idle=0, Idle2=0, Idle3=0, Walk=0, Run=4708192705, Jump=4708188025, Climb=0, Fall=4708186162, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  ['Sneaky'] = {Idle=0, Idle2=0, Idle3="None", Walk=0, Run=1132494274, Jump=1132489853, Climb=0, Fall=1132469004, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  ['Mr. Toilet'] = {Idle=0, Idle2=0, Idle3=0, Walk=2510202577, Run=4417979645, Jump=2510197830, Climb=0, Fall=2510195892, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  ['Bold'] = {Idle=0, Idle2=0, Idle3=0, Walk=0, Run=16738337225, Jump=16738336650, Climb=0, Fall=16738333171, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  ['Adidas Sports'] = {Idle=0, Idle2=0, Idle3=0, Walk=0, Run=18537384940, Jump=18537380791, Climb=0, Fall=18537367238, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  ['Adidas Aura'] = {Idle=0, Idle2=0, Idle3=0, Walk=0, Run=118320322718866, Jump=109996626521204, Climb=0, Fall=95603166884636, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  ['Ninja'] = {Idle=0, Idle2=0, Idle3=0, Walk=0, Run=656118852, Jump=656117878, Climb=0, Fall=656115606, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  ['Mage'] = {Idle=0, Idle2=0, Idle3=0, Walk=0, Run=707861613, Jump=707853694, Climb=0, Fall=707829716, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
  -- JUMP/FALL
  ['Oldschool'] = {Idle=0, Idle2=0, Idle3=0, Walk=0, Run=0, Jump=5319841935, Climb=0, Fall=5319839762, Swim=0, SwimIdle=0, Weight=9, Weight2=1},
}

-- v1.5: EMOTE_CATALOG difilter — hanya 24 emote pilihan user
local EMOTE_CATALOG = {
  ["Baby Dance"] = 4265725525;
  ["Beckon"] = 5230598276;
  ["BLACKPINK As If It's Your Last"] = 18855536648;
  ["BLACKPINK DDU-DU DDU-DU"] = 16553170471;
  ["BLACKPINK LISA Money"] = 15679623052;
  ["BLACKPINK Pink Venom - Get em Get em Get em"] = 14548619594;
  ["Bone Chillin' Bop"] = 15122972413;
  ["Bored"] = 5230599789;
  ["BURBERRY LOLA ATTITUDE - NIMBUS"] = 10147821284;
  ["Cartwheel - George Ezra"] = 10370351535;
  ["Country Line Dance - Lil Nas X"] = 5915712534;
  ["Cower"] = 4940563117;
  ["Dolphin Dance"] = 5918726674;
  ["Dorky Dance"] = 4212455378;
  ["Elton John - Elevate"] = 11394033602;
  ["Fashion Spin"] = 131669256082047;
  ["Frosty Flair - Tommy Hilfiger"] = 10214311282;
  ["Hero Landing"] = 5104344710;
  ["High Wave"] = 5915690960;
  ["Salute"] = 3333474484;
  ["Skadoosh Emote - Kung Fu Panda 4"] = 16371217304;
  ["Sneaky"] = 3334424322;
  ["TMNT Dance"] = 18665811005;
  ["TWICE-Fancy"] = 13520524517;
}

local EMOTE_FAV_FILE = "balap_emote_favorit.json"
local EMOTE_SESSION = { favorites = {}, loop = false, track = nil, name = nil }
local emoteMotionConn
local emoteLoopUIRefresh = function() end

local function emoteFavSave()
  getgenv().BALAP_EMOTE_FAVORITES = EMOTE_SESSION.favorites
  if type(writefile) == "function" then
    pcall(function()
      writefile(EMOTE_FAV_FILE, HttpService:JSONEncode(EMOTE_SESSION.favorites))
    end)
  end
end

local function emoteFavLoad()
  local data
  if type(readfile) == "function" and type(isfile) == "function" then
    pcall(function()
      if isfile(EMOTE_FAV_FILE) then
        data = HttpService:JSONDecode(readfile(EMOTE_FAV_FILE))
      end
    end)
  end
  if type(data) ~= "table" then
    data = rawget(getgenv(), "BALAP_EMOTE_FAVORITES")
  end
  if type(data) == "table" then
    for k, v in pairs(data) do
      if v == true and EMOTE_CATALOG[k] then EMOTE_SESSION.favorites[k] = true end
    end
  end
end

emoteFavLoad()

local function emoteStopTrack(disableLoop)
  if disableLoop then
    EMOTE_SESSION.loop = false
    pcall(emoteLoopUIRefresh)
  end
  if emoteMotionConn then emoteMotionConn:Disconnect(); emoteMotionConn = nil end
  local tr = EMOTE_SESSION.track
  EMOTE_SESSION.track = nil
  pcall(function() if tr then tr:Stop(0.12); tr:Destroy() end end)
end

local function emotePlay(name)
  local id = EMOTE_CATALOG[name]
  if not id then return false end
  local char = getChar()
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:FindFirstChild("Animator"))
  if not animator then return false end
  emoteStopTrack()
  local animation = Instance.new("Animation")
  animation.AnimationId = "rbxassetid://" .. tostring(id)
  local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
  if not ok or not track then animation:Destroy(); return false end
  track.Priority = Enum.AnimationPriority.Action
  track.Looped = EMOTE_SESSION.loop
  EMOTE_SESSION.track = track
  EMOTE_SESSION.name = name
  track.Stopped:Connect(function()
    if EMOTE_SESSION.track == track and not EMOTE_SESSION.loop then
      EMOTE_SESSION.track = nil
      pcall(function() animation:Destroy() end)
    end
  end)
  track:Play(0.12, 1, 1)
  local function stopForMovement(speed)
    if speed and speed > 0.05 then emoteStopTrack(true) end
  end
  emoteMotionConn = hum.Running:Connect(stopForMovement)
  local movementStates = {
    [Enum.HumanoidStateType.Jumping] = true,
    [Enum.HumanoidStateType.Freefall] = true,
    [Enum.HumanoidStateType.FallingDown] = true,
    [Enum.HumanoidStateType.Climbing] = true,
    [Enum.HumanoidStateType.Swimming] = true,
    [Enum.HumanoidStateType.Seated] = true,
  }
  local stateConn = hum.StateChanged:Connect(function(_, state)
    if movementStates[state] then emoteStopTrack(true) end
  end)
  catat(stateConn)
  return true
end

local function emoteSetLoop(v)
  EMOTE_SESSION.loop = v and true or false
  if EMOTE_SESSION.track then
    EMOTE_SESSION.track.Looped = EMOTE_SESSION.loop
  end
end

local SLOT_FOLDERS = {
  idle  = { "idle" },
  walk  = { "walk" },
  run   = { "run" },
  jump  = { "jump" },
  fall  = { "fall" },
  climb = { "climb" },
  swim  = { "swim", "swimidle" },
}

local SLOT_LIST = {
  { k = "idle",  t = "IDLE"   },
  { k = "walk",  t = "JALAN"  },
  { k = "run",   t = "LARI"   },
  { k = "swim",  t = "RENANG" },
  { k = "climb", t = "MANJAT" },
  { k = "jump",  t = "LOMPAT" },
  { k = "fall",  t = "JATUH"  },
}

local SLOT_BY_KEY = {}
for i, s in ipairs(SLOT_LIST) do SLOT_BY_KEY[s.k] = i end

local function slotLabel(k)
  local sv = SLOT_LIST[SLOT_BY_KEY[k]]
  return sv and sv.t or string.upper(k)
end

local EMOTE = {
  master     = false,
  preset     = {},
  bundle     = {},
  baseline   = {},
  rig        = "?",
}

local function emoteResolveSlot(k)
  local bo = EMOTE.bundle[k]
  if bo then return "rbxassetid://" .. bo.id, bo.n end
  local pi = EMOTE.preset[k] or 0
  local p = (EMOTE_PRESET[k] or {})[pi]
  if pi == 0 or not p then return nil, "ASLI" end
  local utama = (EMOTE.rig == "R6") and p.i6 or p.i15
  if not utama then return nil, p.n .. " (beda rig)" end
  return "rbxassetid://" .. utama, p.n
end

local function emoteJumlahAktif()
  local n = 0
  for _, s in ipairs(SLOT_LIST) do
    if emoteResolveSlot(s.k) then n = n + 1 end
  end
  return n
end

local function emoteSimpan()
  getgenv().BALAP_EMOTE_DATA = { master = EMOTE.master, preset = EMOTE.preset, bundle = EMOTE.bundle }
end

local function emoteDeteksiRig(char)
  local hum = char and char:FindFirstChildOfClass("Humanoid")
  if hum then
    if hum.RigType == Enum.HumanoidRigType.R15 then EMOTE.rig = "R15"
    elseif hum.RigType == Enum.HumanoidRigType.R6 then EMOTE.rig = "R6" end
  end
  return EMOTE.rig
end

local ID_KITA = {}
for _, arr in pairs(EMOTE_PRESET) do
  for _, p in ipairs(arr) do
    for _, v in ipairs({ p.i15, p.i6, p.i15b }) do
      if v then ID_KITA["rbxassetid://" .. tostring(v)] = true end
    end
  end
end
for _, b in pairs(BUNDLE_ANIMATIONS) do
  for _, fn in ipairs({ "Idle", "Idle2", "Idle3", "Walk", "Run", "Jump", "Climb", "Fall", "Swim", "SwimIdle" }) do
    local v = b[fn]
    if type(v) == "number" and v > 0 then
      ID_KITA["rbxassetid://" .. tostring(v)] = true
    end
  end
end

local BASELINE_FILE = "balap_animasi_asli.json"
local GAME_KEY = tostring(game.PlaceId)
local BASELINE_SIMPAN = {}

local function emoteBaselineMuat()
  local data
  if type(readfile) == "function" and type(isfile) == "function" then
    pcall(function()
      if isfile(BASELINE_FILE) then
        data = HttpService:JSONDecode(readfile(BASELINE_FILE))
      end
    end)
  end
  if type(data) ~= "table" then data = rawget(getgenv(), "BALAP_ANIMASI_ASLI") end
  if type(data) == "table" and type(data[GAME_KEY]) == "table" then
    for rig, slotData in pairs(data[GAME_KEY]) do
      if type(slotData) == "table" then BASELINE_SIMPAN[rig] = slotData end
    end
  end
end

local function emoteBaselineSimpan(urut)
  local data = rawget(getgenv(), "BALAP_ANIMASI_ASLI")
  if type(data) ~= "table" then data = {} end
  local rigData = data[GAME_KEY]
  if type(rigData) ~= "table" then rigData = {} end
  for k, arr in pairs(urut) do
    local ids = {}
    for _, an in ipairs(arr) do ids[#ids + 1] = an.AnimationId end
    rigData[k] = ids
  end
  data[GAME_KEY] = rigData
  BASELINE_SIMPAN[EMOTE.rig] = rigData
  getgenv().BALAP_ANIMASI_ASLI = data
  if type(writefile) == "function" then
    pcall(function() writefile(BASELINE_FILE, HttpService:JSONEncode(data)) end)
  end
end

emoteBaselineMuat()

-- v1.5: SAFEGUARD tambahan — kalau baseline ternoda & tidak ada backup,
-- WARNING user untuk respawn. Baseline ternoda tidak akan disimpan.
local function emoteCaptureBaseline(char)
  local a = char and char:FindFirstChild("Animate")
  if not a then return end
  if EMOTE.rig == "?" then emoteDeteksiRig(char) end
  if EMOTE.rig == "?" then return end

  local urut = {}
  for k, folders in pairs(SLOT_FOLDERS) do
    if #folders > 0 then
      local arr = {}
      for _, fname in ipairs(folders) do
        local f = a:FindFirstChild(fname)
        if f then
          for _, an in ipairs(f:GetDescendants()) do
            if an:IsA("Animation") then arr[#arr + 1] = an end
          end
        end
      end
      urut[k] = arr
    end
  end

  local bersih = true
  for _, arr in pairs(urut) do
    for _, an in ipairs(arr) do
      if ID_KITA[an.AnimationId] then bersih = false break end
    end
    if not bersih then break end
  end

  -- SAFEGUARD: kalau ternoda, pakai backup dari file
  local sumber = not bersih and BASELINE_SIMPAN[EMOTE.rig] or nil

  if not bersih and not sumber then
    warn("[BALAP] Baseline ternoda & tidak ada backup — RESET mungkin tidak sempurna. Respawn karakter untuk baseline bersih.")
  end

  for k, arr in pairs(urut) do
    local simpan = {}
    local sumberSlot = sumber and sumber[k] or nil
    for i, an in ipairs(arr) do
      local id = sumberSlot and sumberSlot[i]
      if type(id) ~= "string" then id = an.AnimationId end
      simpan[an] = id
    end
    EMOTE.baseline[k] = simpan
  end

  -- simpan hanya baseline yang benar-benar asli
  if bersih then
    emoteBaselineSimpan(urut)
    print("[BALAP] Baseline asli tersimpan untuk rig " .. EMOTE.rig)
  else
    print("[BALAP] Baseline ternoda — pakai backup dari file")
  end
end

local function emoteSetSlotId(k, char, id)
  local a = char and char:FindFirstChild("Animate")
  if not a then return false end
  local folders = SLOT_FOLDERS[k]
  if not folders or #folders == 0 then return false end
  local idB = nil
  if id and k == "swim" then
    local bo = EMOTE.bundle[k]
    if bo then
      idB = bo.idB
    else
      local p = (EMOTE_PRESET[k] or {})[EMOTE.preset[k] or 0]
      if p then idB = p.i15b end
    end
  end
  for _, fname in ipairs(folders) do
    local f = a:FindFirstChild(fname)
    if f then
      local target = id
      if target and fname == "swimidle" then
        target = (idB and EMOTE.rig ~= "R6") and ("rbxassetid://" .. idB) or id
      end
      for _, an in ipairs(f:GetDescendants()) do
        if an:IsA("Animation") then
          if target then
            an.AnimationId = target
          else
            local asli = EMOTE.baseline[k] and EMOTE.baseline[k][an]
            if asli then an.AnimationId = asli end
          end
        end
      end
    end
  end
  return true
end

local function emoteRestartAnimate()
  local char = getChar()
  local a = char and char:FindFirstChild("Animate")
  if not a then return end
  pcall(function()
    a.Disabled = true
    task.wait()
    a.Disabled = false
  end)
end

local function emoteTerapkanSemua(char)
  char = char or getChar()
  if not char then return end
  if not char:FindFirstChild("Animate") then return end
  for _, s in ipairs(SLOT_LIST) do
    local k = s.k
    local id = nil
    if EMOTE.master then id = emoteResolveSlot(k) end
    emoteSetSlotId(k, char, id)
  end
  emoteRestartAnimate()
end

emoteSetMaster = function(on, silent)
  on = on and true or false
  if EMOTE.master == on and State.EmoteOn == on then return end
  EMOTE.master = on
  State.EmoteOn = on
  emoteSimpan()
  emoteTerapkanSemua()
  if not silent then
    if on then
      toast("⚡ Animasi kustom ON — gaya pilihanmu aktif", Warna.Hijau)
    else
      toast("⚡ Animasi kustom OFF — balik ke animasi game", Warna.Kuning)
    end
  end
  if Switches["Emote"] then Switches["Emote"].set(on) end
  if emoteRefreshGrid then emoteRefreshGrid() end
end

emotePilihPreset = function(k, pi)
  if not SLOT_FOLDERS[k] then return end
  EMOTE.preset[k] = pi
  EMOTE.bundle[k] = nil
  emoteSimpan()
  local char = getChar()
  if char then
    local id = nil
    if EMOTE.master then id = emoteResolveSlot(k) end
    emoteSetSlotId(k, char, id)
    emoteRestartAnimate()
  end
  if emoteRefreshGrid then emoteRefreshGrid() end
  local _, nama = emoteResolveSlot(k)
  toast("🎬 " .. slotLabel(k) .. ": " .. tostring(nama), Warna.Ungu2)
end

local BUNDLE_FIELD = {
  idle = "Idle", walk = "Walk", run = "Run", jump = "Jump",
  climb = "Climb", fall = "Fall", swim = "Swim",
}

emotePilihBundle = function(k, bundleName)
  local b = BUNDLE_ANIMATIONS[bundleName]
  local field = BUNDLE_FIELD[k]
  local id = b and b[field]
  if not field or type(id) ~= "number" or id <= 0 then return end
  EMOTE.bundle[k] = {
    n = bundleName,
    id = id,
    idB = (type(b.SwimIdle) == "number" and b.SwimIdle > 0) and b.SwimIdle or nil,
  }
  EMOTE.preset[k] = 0
  emoteSimpan()
  local char = getChar()
  if char then
    local aid = nil
    if EMOTE.master then aid = emoteResolveSlot(k) end
    emoteSetSlotId(k, char, aid)
    emoteRestartAnimate()
  end
  if emoteRefreshGrid then emoteRefreshGrid() end
  toast("🎬 " .. slotLabel(k) .. ": " .. tostring(bundleName), Warna.Ungu2)
end

local emoteCharSudah = {}
local function emoteInitCharacter(char)
  if not char or emoteCharSudah[char] then return end
  emoteCharSudah[char] = true
  task.spawn(function()
    local a = char:WaitForChild("Animate", 15)
    if not a then return end
    task.wait(CFG.EMOTE_TUNGGAK)
    if State.Removed or not char.Parent then return end
    emoteDeteksiRig(char)
    emoteCaptureBaseline(char)
    emoteTerapkanSemua(char)
    if emoteRefreshGrid then emoteRefreshGrid() end
  end)
end

State.EmoteOn = EMOTE.master

catat(LocalPlayer.CharacterAdded:Connect(function(char)
  emoteStopTrack()
  emoteInitCharacter(char)
end))

task.spawn(function()
  task.wait(1.0)
  local char = getChar()
  if char then emoteInitCharacter(char) end
end)

print("[BALAP-EMOTE] siap — 7 slot • master "
  .. (EMOTE.master and "ON" or "OFF")
  .. " • aktif " .. emoteJumlahAktif() .. "/7")

-- [13] TAB BAR (5 TAB) ------------------------------------
local function buildUI()
  tabBtns = {}
  local tabLabels = {"MOVEMENT & VISUAL", "ANIMASI", "EMOTE", "TITIK", "SYSTEM"}
  local tabColors = {Warna.Ungu2, Warna.Biru, Warna.Ungu2, Warna.Hijau2, Warna.AbuGelap}
  kontenTabs = {}
  for i, lbl in ipairs(tabLabels) do
    local tab = buat("TextButton", {
      Size = UDim2.new(1 / 5, -3.2, 0, 24),
      Position = UDim2.new((i - 1) * (1 / 5), 2.8 + (i - 1) * 1.4, 0, 50),
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

  -- [14] KONTEN TAB 1: MOVEMENT & VISUAL ----------------
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

  -- ===== init State =====
  State.SpeedOn = false
  State.SpeedValue = CFG.SPEED_ON_1
  State.JumpOn  = false
  State.JumpValue = CFG.ON_JUMP
  State.JumpHeightValue = CFG.ON_JUMP_H
  State.JumpAwal = nil
  State.JumpAwalH = nil
  State.ShiftOn = false
  State.IsSwimming = false
  State.HideOn  = false
  State.LWOn    = false
  State.WallsOn = false
  State.LightOn = false
  State.MoonOn  = false
  State.TengahOn = false
  State.HideAtasOn = false

  oLight = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    ExposureCompensation = Lighting.ExposureCompensation,
    FogEnd = Lighting.FogEnd,
  }
  lightConn = nil

  -- ===== baris TAB 1 =====
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
  local _, jumpLabelRow = buatToggleRow(scrollMove, "JumpPower", "J", "Jump")
  JumpLabel = jumpLabelRow
  RefreshJump = buatStepperRow(scrollMove, "Jump",
    function()
      local hum = getHum()
      if hum and hum.UseJumpPower == false then return State.JumpHeightValue end
      return State.JumpValue
    end,
    function(v)
      local hum = getHum()
      if hum and hum.UseJumpPower == false then
        State.JumpHeightValue = math.clamp(v, CFG.ON_JUMP_H_MIN, CFG.ON_JUMP_H_MAX)
      else
        State.JumpValue = math.clamp(v, CFG.ON_JUMP_MIN, CFG.ON_JUMP_MAX)
      end
      if State.JumpOn then applyJump() end
    end)
  buatToggleRow(scrollMove, "Shiftlock Mobile", "C", "Shift")
  buatToggleRow(scrollMove, "Shiftlock Tengah", "Shift", "Tengah")
  buatToggleRow(scrollMove, "Moonwalk", "F", "Moon")
  buatHeader(scrollMove, "Visual")
  buatToggleRow(scrollMove, "Hide Player + Kendaraan", "R", "Hide")
  buatToggleRow(scrollMove, "Hide Badan Atas (kaki tetap)", "Z", "HideAtas")
  buatToggleRow(scrollMove, "Cahaya Auto (2 arah)", "T", "Light")
  buatHeader(scrollMove, "Lightweight")
  buatToggleRow(scrollMove, "Partikel / Bayangan / Efek", nil, "LW")
  buatHeader(scrollMove, "Map")
  buatToggleRow(scrollMove, "Dinding Batas", "X", "Walls")

  -- [15] KONTEN TAB 5: SYSTEM ---------------------------
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

  -- [16] KONTEN TAB 2: ANIMASI ----
  kontenAnim = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
  }, panel)
  scrollAnim = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 2),
    Size = UDim2.new(1, -24, 1, -6),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Ungu2,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
  }, kontenAnim)
  buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollAnim)

  buatHeader(scrollAnim, "Gaya Gerak")
  buatToggleRow(scrollAnim, "⚡ Animasi Kustom (master)", nil, "Emote")

  local emoteStatus = buat("TextLabel", {
    BackgroundColor3 = Warna.AbuItem,
    Size = UDim2.new(1, 0, 0, 26),
    FontFace = fnt("med"),
    TextSize = 11,
    TextColor3 = Warna.AbuTeks,
    TextXAlignment = Enum.TextXAlignment.Center,
    Text = "Rig: mendeteksi... • klik slot = pilih gaya",
    LayoutOrder = nextOrder(),
  }, scrollAnim)
  buat("UICorner", {CornerRadius = UDim.new(0, 8)}, emoteStatus)

  local emoteSubs = {}
  local emoteGrid = buat("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 156),
    LayoutOrder = nextOrder(),
  }, scrollAnim)
  buat("UIGridLayout", {
    CellSize = UDim2.new(1 / 3, -4, 0, 48),
    CellPadding = UDim2.new(0, 4, 0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
  }, emoteGrid)

  for i, s in ipairs(SLOT_LIST) do
    local b = buat("TextButton", {
      BackgroundColor3 = Warna.AbuItem, BorderSizePixel = 0,
      Text = "", AutoButtonColor = false, LayoutOrder = i,
    }, emoteGrid)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, b)
    buat("TextLabel", {
      BackgroundTransparency = 1,
      Position = UDim2.new(0, 0, 0, 6),
      Size = UDim2.new(1, 0, 0, 16),
      FontFace = fnt("bold"), TextSize = 12,
      TextColor3 = Warna.TeksGelap, Text = s.t,
    }, b)
    local sub = buat("TextLabel", {
      BackgroundTransparency = 1,
      Position = UDim2.new(0, 4, 0, 24),
      Size = UDim2.new(1, -8, 0, 16),
      FontFace = fnt("reg"), TextSize = 10, TextScaled = true,
      TextColor3 = Warna.AbuTeks, Text = "ASLI",
    }, b)
    buat("UITextSizeConstraint", {MaxTextSize = 10}, sub)
    efekTombol(b, 1.05)
    local skey = s.k
    b.MouseButton1Click:Connect(function()
      ripple(b, Warna.Putih)
      if emoteBukaChooser then emoteBukaChooser(skey) end
    end)
    emoteSubs[s.k] = sub
  end

  emoteRefreshGrid = function()
    for _, s in ipairs(SLOT_LIST) do
      local sub = emoteSubs[s.k]
      if sub then
        local id, nama = emoteResolveSlot(s.k)
        if EMOTE.master and id then
          sub.Text = tostring(nama)
          sub.TextColor3 = Warna.Ungu
        else
          sub.Text = "ASLI"
          sub.TextColor3 = Warna.AbuTeks
        end
      end
    end
    local n = emoteJumlahAktif()
    emoteStatus.Text = "Rig: " .. tostring(EMOTE.rig) .. " • " .. n .. "/7 slot gaya baru • "
      .. (EMOTE.master and "master ON" or "master OFF")
  end

  -- Konten EMOTE
  kontenEmote = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
  }, panel)
  scrollEmote = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 2),
    Size = UDim2.new(1, -24, 1, -6),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Ungu2,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
  }, kontenEmote)
  buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollEmote)

  -- ===== EMOTE FAVORIT / LOOP =====
  buatHeader(scrollEmote, "Emote Catalog")
  local emoteSearch = buat("TextBox", {
    BackgroundColor3 = Warna.Hitam2, Size = UDim2.new(1, 0, 0, 28),
    FontFace = fnt("reg"), TextSize = 12, TextColor3 = Warna.Putih,
    PlaceholderText = "Cari emote...", PlaceholderColor3 = Warna.AbuGelap,
    Text = "", ClearTextOnFocus = false, LayoutOrder = nextOrder(),
  }, scrollEmote)
  buat("UICorner", {CornerRadius = UDim.new(0, 8)}, emoteSearch)

  local emoteTools = buat("Frame", {
    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = nextOrder(),
  }, scrollEmote)
  local favOnly = false
  local favBtn = buat("TextButton", {
    BackgroundColor3 = Warna.Card2, Size = UDim2.new(0.48, 0, 1, 0),
    FontFace = fnt("bold"), TextSize = 11, TextColor3 = Warna.Putih,
    Text = "☆ FAVORIT SAJA", AutoButtonColor = false,
  }, emoteTools)
  buat("UICorner", {CornerRadius = UDim.new(0, 7)}, favBtn)
  local loopBtn = buat("TextButton", {
    BackgroundColor3 = Warna.Card2, Position = UDim2.new(0.52, 0, 0, 0),
    Size = UDim2.new(0.48, 0, 1, 0), FontFace = fnt("bold"), TextSize = 11,
    TextColor3 = Warna.Putih, Text = "↻ LOOP: OFF", AutoButtonColor = false,
  }, emoteTools)
  buat("UICorner", {CornerRadius = UDim.new(0, 7)}, loopBtn)

  local renderEmoteList
  local emoteListFrame = buat("ScrollingFrame", {
    BackgroundColor3 = Warna.AbuItem,
    Size = UDim2.new(1, 0, 0, 500),
    BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    LayoutOrder = nextOrder(),
  }, scrollEmote)
  buat("UICorner", {CornerRadius = UDim.new(0, 8)}, emoteListFrame)
  buat("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, emoteListFrame)

  local emoteOrder = 0

  -- v1.5: VIRTUAL SCROLL — max 40 button sekaligus (hemat 80% CPU)
  local EMOTE_VISIBLE_LIMIT = 40

  renderEmoteList = function()
    for _, c in ipairs(emoteListFrame:GetChildren()) do
      if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
    end
    emoteOrder = 0
    local q = string.lower(emoteSearch.Text or "")
    local favNames, names = {}, {}
    for name in pairs(EMOTE_CATALOG) do
      if q == "" or string.find(string.lower(name), q, 1, true) then
        if EMOTE_SESSION.favorites[name] then
          favNames[#favNames + 1] = name
        else
          names[#names + 1] = name
        end
      end
    end
    local function urut(t)
      table.sort(t, function(a, b) return a:lower() < b:lower() end)
    end
    urut(favNames); urut(names)

    local totalRendered = 0
    local truncated = false

    local function kepala(teks, warna)
      if totalRendered >= EMOTE_VISIBLE_LIMIT then return end
      emoteOrder += 1
      buat("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 20),
        FontFace = fnt("bold"), TextSize = 11, TextColor3 = warna,
        TextXAlignment = Enum.TextXAlignment.Left, Text = teks,
        LayoutOrder = emoteOrder,
      }, emoteListFrame)
    end

    local function barisEmote(name)
      if totalRendered >= EMOTE_VISIBLE_LIMIT then
        truncated = true
        return
      end
      totalRendered += 1
      emoteOrder += 1
      local row = buat("TextButton", {
        BackgroundColor3 = Warna.Card2, Size = UDim2.new(1, -6, 0, 27),
        Text = "", AutoButtonColor = false, LayoutOrder = emoteOrder,
      }, emoteListFrame)
      buat("UICorner", {CornerRadius = UDim.new(0, 6)}, row)
      local label = buat("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(1, -48, 1, 0), FontFace = fnt("med"), TextSize = 11,
        TextColor3 = Warna.Putih, TextXAlignment = Enum.TextXAlignment.Left, Text = name,
      }, row)
      local star = buat("TextButton", {
        BackgroundTransparency = 1, Position = UDim2.new(1, -38, 0, 0),
        Size = UDim2.fromOffset(32, 27), FontFace = fnt("bold"), TextSize = 16,
        TextColor3 = Warna.Kuning, Text = EMOTE_SESSION.favorites[name] and "★" or "☆",
        AutoButtonColor = false,
      }, row)
      star.MouseButton1Click:Connect(function()
        EMOTE_SESSION.favorites[name] = not EMOTE_SESSION.favorites[name] or nil
        emoteFavSave(); renderEmoteList()
      end)
      row.MouseButton1Click:Connect(function()
        if emotePlay(name) then
          toast("Emote: " .. name, Warna.Ungu2)
        end
      end)
    end

    if #favNames > 0 then
      kepala("★ FAVORIT (" .. #favNames .. ")", Warna.Kuning)
      for _, name in ipairs(favNames) do barisEmote(name) end
    elseif q == "" then
      kepala("Belum ada favorit — tekan ☆ pada emote", Warna.AbuTeks)
    end

    if not favOnly and not truncated then
      if #names > 0 then
        kepala("EMOTE (" .. #names .. ")", Warna.AbuTeks)
        for _, name in ipairs(names) do barisEmote(name) end
      elseif #favNames > 0 then
        kepala("Semua emote ada di grup FAVORIT", Warna.AbuTeks)
      end
    elseif truncated then
      local sisa = (#favNames + #names) - totalRendered
      emoteOrder += 1
      buat("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 22),
        FontFace = fnt("med"), TextSize = 10, TextColor3 = Warna.AbuGelap,
        TextXAlignment = Enum.TextXAlignment.Center,
        Text = "⚡ " .. sisa .. " emote lagi — ketik di kotak cari untuk filter",
        LayoutOrder = emoteOrder,
      }, emoteListFrame)
    end
  end

  favBtn.MouseButton1Click:Connect(function()
    favOnly = not favOnly
    favBtn.Text = favOnly and "★ FAVORIT SAJA: ON" or "☆ FAVORIT SAJA"
    renderEmoteList()
  end)

  emoteLoopUIRefresh = function()
    if loopBtn and loopBtn.Parent then
      loopBtn.Text = EMOTE_SESSION.loop and "↻ LOOP: ON" or "↻ LOOP: OFF"
      loopBtn.BackgroundColor3 = EMOTE_SESSION.loop and Warna.Ungu or Warna.Card2
    end
  end

  loopBtn.MouseButton1Click:Connect(function()
    emoteSetLoop(not EMOTE_SESSION.loop)
    emoteLoopUIRefresh()
  end)

  emoteSearch:GetPropertyChangedSignal("Text"):Connect(renderEmoteList)
  renderEmoteList()

  -- RESET SEMUA — konfirmasi 2 langkah
  local armResetEmote = 0
  local btnResetEmote = buatActionRow(scrollAnim, "↺ RESET SEMUA → ANIMASI ASLI", Warna.Merah, function()
    local now = os.clock()
    if now - armResetEmote > 3 then
      armResetEmote = now
      btnResetEmote.Text = "⚠️ YAKIN? TEKAN LAGI"
      toast("Semua slot balik ke animasi ASLI — tekan lagi", Warna.Kuning)
      task.delay(3, function()
        if btnResetEmote.Parent and btnResetEmote.Text ~= "↺ RESET SEMUA → ANIMASI ASLI" then
          btnResetEmote.Text = "↺ RESET SEMUA → ANIMASI ASLI"
        end
      end)
    else
      armResetEmote = 0
      btnResetEmote.Text = "↺ RESET SEMUA → ANIMASI ASLI"
      for _, s in ipairs(SLOT_LIST) do
        EMOTE.preset[s.k] = nil
        EMOTE.bundle[s.k] = nil
      end
      emoteSimpan()
      emoteTerapkanSemua()
      if emoteRefreshGrid then emoteRefreshGrid() end
      toast("Semua slot balik ke animasi ASLI", Warna.Merah)
    end
  end)

  -- Tombol RESET BASELINE (untuk kasus edge: baseline ternoda)
  buatActionRow(scrollAnim, "🔄 RESET BASELINE (dari file)", Warna.Biru, function()
    emoteBaselineMuat()
    local char = getChar()
    if char then
      emoteCaptureBaseline(char)
      emoteTerapkanSemua(char)
    end
    toast("Baseline di-reset dari file backup", Warna.Hijau)
  end)

  buat("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 40),
    FontFace = fnt("reg"), TextSize = 10,
    TextColor3 = Warna.AbuTeks, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Bundle dan emote ini dipakai lokal untuk karakter kamu. "
      .. "Bundle gaya gerak jadi opsi PER KATEGORI di tiap slot (IDLE, "
      .. "JALAN, LARI, dst — bisa dicampur, bukan 1 set). Emote yang "
      .. "di★-kan pindah ke grup ★ FAVORIT (beda lokasi daftar) supaya "
      .. "gampang dicari; favorit tersimpan lokal. Daftar emote, paket, "
      .. "dan bundle selalu utuh — tidak ada fitur hapus. RESET SEMUA / "
      .. "pilihan ASLI memulihkan animasi asli game (animasi asli "
      .. "tersimpan sekali ke file, aman walau script dijalankan ulang). "
      .. "Animasi dipasang lagi setelah mati/respawn; awal load selalu "
      .. "OFF + semua slot ASLI — nyalakan ⚡ master dulu, gaya "
      .. "pilihanmu aktif selama sesi saja (script dijalankan ulang = "
      .. "balik default).",
    LayoutOrder = nextOrder(),
  }, scrollAnim)

  -- ===== POPUP PILIH GAYA =====
  local chooserBackdrop = buat("TextButton", {
    Visible = false, ZIndex = 60,
    BackgroundColor3 = Warna.Hitam, BackgroundTransparency = 0.35,
    Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false,
  }, panel)
  local chooser = buat("Frame", {
    Visible = false, ZIndex = 61,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(1, -30, 0, 330),
    BackgroundColor3 = Warna.Hitam2, BorderSizePixel = 0,
  }, panel)
  buat("UICorner", {CornerRadius = UDim.new(0, 12)}, chooser)
  buat("UIStroke", {Color = Warna.Ungu2, Thickness = 2}, chooser)

  local chooserJudul = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -64, 0, 18),
    FontFace = fnt("bold"), TextSize = 13,
    TextColor3 = Warna.Putih,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "PILIH GAYA",
  }, chooser)

  local chooserTutupBtn = buat("TextButton", {
    Position = UDim2.new(1, -34, 0, 6),
    Size = UDim2.fromOffset(28, 22),
    BackgroundColor3 = Warna.Merah,
    FontFace = fnt("bold"), TextSize = 12,
    TextColor3 = Warna.Putih, Text = "✕", AutoButtonColor = false,
  }, chooser)
  buat("UICorner", {CornerRadius = UDim.new(0, 6)}, chooserTutupBtn)

  local chooserList = buat("ScrollingFrame", {
    Position = UDim2.new(0, 10, 0, 30),
    Size = UDim2.new(1, -20, 1, -40),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = Warna.Ungu2,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
  }, chooser)
  buat("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, chooserList)

  local chooserOrder = 0
  local function chooserNext() chooserOrder = chooserOrder + 1 return chooserOrder end

  emoteBukaChooser = function(skey)
    if not SLOT_FOLDERS[skey] then return end
    local rig = EMOTE.rig
    local aktifPi = EMOTE.preset[skey] or 0
    if EMOTE.bundle[skey] then aktifPi = -1 end
    chooserJudul.Text = "GAYA " .. slotLabel(skey) .. "  (rig " .. rig .. ")"
    chooserOrder = 0
    for _, c in ipairs(chooserList:GetChildren()) do
      if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end

    local function tambahBar(teks, warna, bisa, cb)
      local br = buat("TextButton", {
        Size = UDim2.new(1, -6, 0, 30),
        BackgroundColor3 = bisa and Warna.Card2 or Warna.Hitam,
        Text = "", AutoButtonColor = false,
        LayoutOrder = chooserNext(),
      }, chooserList)
      buat("UICorner", {CornerRadius = UDim.new(0, 8)}, br)
      buat("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        FontFace = fnt("med"), TextSize = 12,
        TextColor3 = warna,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = teks,
      }, br)
      br.MouseButton1Click:Connect(function()
        if bisa then cb() elseif cb then toast("Preset ini tidak untuk rig " .. rig, Warna.Kuning) end
      end)
    end

    tambahBar("ASLI — animasi default game" .. (aktifPi == 0 and "   ✓" or ""),
      Warna.Putih, true, function()
        emotePilihPreset(skey, 0)
        chooserBackdrop.Visible = false; chooser.Visible = false
      end)

    for pi, p in ipairs(EMOTE_PRESET[skey] or {}) do
      local id = (rig == "R6") and p.i6 or p.i15
      local tagRig = (p.i15 and p.i6 and "(R15+R6)") or (p.i15 and "(R15)") or "(R6)"
      local teks = p.n .. "  " .. tagRig
      if aktifPi == pi then teks = teks .. "   ✓" end
      if id then
        tambahBar(teks, Warna.Ungu2, true, function()
          emotePilihPreset(skey, pi)
          chooserBackdrop.Visible = false; chooser.Visible = false
        end)
      else
        tambahBar(teks, Warna.AbuGelap, false, function()
          toast("Preset ini tidak untuk rig " .. rig, Warna.Kuning)
        end)
      end
    end

    local field = BUNDLE_FIELD[skey]
    local namaPreset = {}
    for _, p in ipairs(EMOTE_PRESET[skey] or {}) do namaPreset[p.n] = true end
    local bundleList = {}
    for bn, b in pairs(BUNDLE_ANIMATIONS) do
      local bid = b[field]
      if type(bid) == "number" and bid > 0 and not namaPreset[bn] then
        bundleList[#bundleList + 1] = bn
      end
    end
    if #bundleList > 0 then
      table.sort(bundleList, function(a, c) return a:lower() < c:lower() end)
      tambahBar("BUNDLE — PER KATEGORI", Warna.AbuGelap, false, nil)
      local bo = EMOTE.bundle[skey]
      for _, bn in ipairs(bundleList) do
        local teks = bn .. "  (R15+R6)"
        if bo and bo.n == bn then teks = teks .. "   ✓" end
        tambahBar(teks, Warna.Biru2, true, function()
          emotePilihBundle(skey, bn)
          chooserBackdrop.Visible = false; chooser.Visible = false
        end)
      end
    end

    chooserBackdrop.Visible = true
    chooser.Visible = true
  end

  chooserBackdrop.MouseButton1Click:Connect(function()
    chooserBackdrop.Visible = false
    chooser.Visible = false
  end)
  chooserTutupBtn.MouseButton1Click:Connect(function()
    chooserBackdrop.Visible = false
    chooser.Visible = false
  end)

  -- ===== TAB TITIK ================================================
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
    titikStatusUI(TITIK.aktif and "Aktif: tahan CTRL lalu klik kiri permukaan dunia" or "Mode penempatan dimatikan")
  end)

  buatActionRow(scrollTitik, "➕ TAMBAH DARI POSISI SAYA", Warna.Biru, function()
    local pos, normal = titikPosisiKarakter()
    if pos then titikTambah(namaTitikBox.Text, pos, normal) else titikStatusUI("Karakter belum siap") end
    namaTitikBox.Text = ""
  end).LayoutOrder = titikNext()

  buatActionRow(scrollTitik, "● TITIK: TAMPILKAN / SEMBUNYIKAN", Warna.Ungu2, function()
    TITIK.tampilTitik = not TITIK.tampilTitik; titikRefreshDot()
    titikStatusUI(TITIK.tampilTitik and "Titik kecil ditampilkan" or "Titik kecil disembunyikan")
  end).LayoutOrder = titikNext()

  buatActionRow(scrollTitik, "🗑 HAPUS SEMUA TITIK", Warna.Merah, function()
    for _, p in ipairs(TITIK.poin) do TITIK.hapus[#TITIK.hapus + 1] = tostring(p.id or p.name) end
    table.clear(TITIK.poin)
    titikSimpan()
    pcall(function() if type(toast) == "function" then toast("✓ Semua titik dihapus dan disimpan lokal", Warna.Hijau) end end)
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
    if type(toast)=="function" then toast("✓ Tiang diurutkan berdasarkan jarak terdekat",Warna.Hijau) end
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
          titikSimpan(); pcall(function() if type(toast) == "function" then toast("✓ Nama titik disimpan", Warna.Hijau) end end); titikRefreshDot(); titikStatusUI("Nama titik diubah")
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
    Text = "Aktifkan mode, lalu tahan CTRL + klik kiri pada tanah atau dinding untuk menempelkan titik kecil. Titik tidak melayang dan semua perpindahan hanya untuk karakter kamu.",
    LayoutOrder = titikNext(),
  }, scrollTitik)

  -- urutan kontenTabs
  table.insert(kontenTabs, kontenAnim)
  table.insert(kontenTabs, kontenEmote)
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
    Text = "⚡ BALAP v" .. VERSI .. "\n"
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
    if not _G.__KS_DELETE_ARMED__ then
      _G.__KS_DELETE_ARMED__ = true
      bunyi(CFG.SND_SNAP, 0.3, 0.8)
      toast("Tekan HAPUS sekali lagi untuk konfirmasi", Warna.Merah)
      task.delay(3, function() _G.__KS_DELETE_ARMED__ = nil end)
    else
      _G.__KS_DELETE_ARMED__ = nil
      unloadScript()
    end
  end)
end -- akhir buildUI()

buildUI()
diagSet("GUI utama OK — bikin efek & notif...")

-- [17] FOOTER + LED (v1.5: tanpa marquee loop, tanpa bracket pulse) -----
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

  -- v1.5: marquee STATIS (tanpa loop tween — hemat CPU)
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
    Text = "G=GUI • Q=Speed • J=Jump • C=Shift • F=Moon • R=Hide • T=Cahaya • X=Dinding • K×2=Rejoin",
    TextColor3 = Warna.AbuGelap,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Center,
  }, marqueeClip)

  -- bracket pojok STATIS (tanpa pulse loop)
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

-- [19] BURST FX ---------------------------------------
local paletKonfeti = {Warna.Ungu, Warna.Ungu2, Warna.Biru, Warna.Biru2, Warna.Putih, Warna.Hijau2}
konfeti = function(parent, pos, n)
  for _ = 1, n do
    local c = buat("Frame", {
      Name = "NoFade",
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = pos,
      Size = UDim2.fromOffset(rnd(5, 9), rnd(5, 9)),
      BackgroundColor3 = paletKonfeti[rnd(1, #paletKonfeti)],
      BorderSizePixel = 0,
      Rotation = rnd(0, 360),
      ZIndex = 800,
    }, parent)
    local sudut = rnd(1, 360) * math.pi / 180
    local jarak = rnd(60, 150)
    local dur = rnd(55, 85) / 100
    tween(c, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
      Position = UDim2.new(pos.X.Scale, pos.X.Offset + math.cos(sudut) * jarak,
        pos.Y.Scale, pos.Y.Offset + math.sin(sudut) * jarak + 30),
      Rotation = c.Rotation + rnd(180, 540),
      BackgroundTransparency = 1,
    })
    task.delay(dur + 0.05, function() c:Destroy() end)
  end
end

emojiBurst = function(parent, pos, daftar, n)
  for _ = 1, n do
    local l = buat("TextLabel", {
      Name = "NoFade",
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = pos,
      Size = UDim2.fromOffset(24, 24),
      BackgroundTransparency = 1,
      Font = Enum.Font.SourceSans,
      Text = daftar[rnd(1, #daftar)],
      TextSize = rnd(14, 22),
      Rotation = rnd(-20, 20),
      ZIndex = 801,
    }, parent)
    local sudut = rnd(1, 360) * math.pi / 180
    local jarak = rnd(70, 160)
    local dur = rnd(60, 90) / 100
    tween(l, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
      Position = UDim2.new(pos.X.Scale, pos.X.Offset + math.cos(sudut) * jarak,
        pos.Y.Scale, pos.Y.Offset + math.sin(sudut) * jarak - 40),
      Rotation = l.Rotation + rnd(-180, 180),
      TextTransparency = 1,
    })
    task.delay(dur + 0.05, function() l:Destroy() end)
  end
end

pusatDiRoot = function(gui)
  local sz = gui.AbsoluteSize
  return UDim2.new(0, gui.AbsolutePosition.X - root.AbsolutePosition.X + sz.X / 2,
    0, gui.AbsolutePosition.Y - root.AbsolutePosition.Y + sz.Y / 2)
end

-- [20] TOAST — KANAN ATAS LAYAR ----------------------
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

-- [21] LOGIKA UTAMA ---------------------------------------
local function initLogic()

  -- SPEED & JUMP
  applySpeed = function()
    local hum = getHum()
    if not hum then return end
    local base = State.SpeedOn and State.SpeedValue or CFG.SPEED_OFF
    if State.TengahOn and State.IsSwimming then
      base = base * CFG.SWIM_BONUS
    end
    hum.WalkSpeed = base
  end

  applyJump = function()
    local hum = getHum()
    if not hum then return end
    if State.JumpAwal == nil then
      State.JumpAwal = hum.JumpPower
      State.JumpAwalH = hum.JumpHeight
    end
    if State.JumpOn then
      if hum.UseJumpPower then
        hum.JumpPower = State.JumpValue
      else
        hum.JumpHeight = State.JumpHeightValue
      end
    else
      if hum.UseJumpPower then
        hum.JumpPower = State.JumpAwal
      else
        hum.JumpHeight = State.JumpAwalH
      end
    end
  end

  updateJumpLabel = function()
    local hum = getHum()
    if JumpLabel then
      JumpLabel.Text = (hum and hum.UseJumpPower) and "JumpPower" or "JumpHeight (auto)"
    end
    if RefreshJump then RefreshJump() end
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

  Setters.Jump = function(v, silent)
    if State.JumpOn == v then return end
    State.JumpOn = v
    applyJump()
    if not v then
      task.spawn(function()
        for _ = 1, 8 do
          task.wait(0.25)
          if State.JumpOn or State.Removed then return end
          local h = getHum()
          if h then
            if h.UseJumpPower then
              if State.JumpAwal and h.JumpPower ~= State.JumpAwal then h.JumpPower = State.JumpAwal end
            elseif State.JumpAwalH and h.JumpHeight ~= State.JumpAwalH then
              h.JumpHeight = State.JumpAwalH
            end
          end
        end
      end)
    end
    syncNotify("Jump", v, silent, "JumpPower")
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
      pcall(function() RunService:UnbindFromRenderStep("KS_SHIFTLOCK") end)
      RunService:BindToRenderStep("KS_SHIFTLOCK", Enum.RenderPriority.Character.Value + 1, function()
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
      RunService:UnbindFromRenderStep("KS_SHIFTLOCK")
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
      pcall(function() RunService:UnbindFromRenderStep("KS_MOONWALK") end)
      RunService:BindToRenderStep("KS_MOONWALK", Enum.RenderPriority.Character.Value + 1, function(dt)
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
      RunService:UnbindFromRenderStep("KS_MOONWALK")
      local hum = getHum()
      if hum then hum.AutoRotate = true end
    end
    syncNotify("Moon", v, silent, "Moonwalk")
  end

  -- SHIFTLOCK TENGAH
  local sltTween, sltTweening, sltOffsetAsli = nil, false, nil
  local sltDotGui, sltDot
  local sltUGS
  pcall(function() sltUGS = UserSettings():GetService("UserGameSettings") end)

  local function sltDotShow()
    if sltDot then sltDot.Visible = true return end
    sltDotGui = buat("ScreenGui", {
      Name = "BALAP_TengahDot",
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
        local lama = t:FindFirstChild("BALAP_TengahDot")
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
      pcall(function() RunService:UnbindFromRenderStep("KS_TENGAH") end)
      RunService:BindToRenderStep("KS_TENGAH", Enum.RenderPriority.Camera.Value + 1, function()
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
      pcall(function() RunService:UnbindFromRenderStep("KS_TENGAH") end)
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

  Setters.Emote = function(v, silent)
    emoteSetMaster(v, silent)
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
    -- v1.5: radius 20 → 12 (hemat CPU)
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

  -- HIDE BADAN ATAS
  local atasConn, atasT = nil, 0
  local atasDecalOrig = {}
  local ATAS_R15 = {
    Head = true, UpperTorso = true,
    LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
    RightUpperArm = true, RightLowerArm = true, RightHand = true,
  }
  local ATAS_R6 = { Head = true, Torso = true, ["Left Arm"] = true, ["Right Arm"] = true }
  local BADAN_KENAL = {
    Head = true, UpperTorso = true, LowerTorso = true,
    LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
    RightUpperArm = true, RightLowerArm = true, RightHand = true,
    LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
    RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
    Torso = true, ["Left Arm"] = true, ["Right Arm"] = true,
    ["Left Leg"] = true, ["Right Leg"] = true, HumanoidRootPart = true,
  }

  local function atasIkat(part, hop)
    if hop > 6 then return nil end
    for _, w in ipairs(part:GetChildren()) do
      if w:IsA("Motor6D") or w:IsA("Weld") or w:IsA("AccessoryWeld") or w:IsA("WeldConstraint") then
        local lain = (w.Part0 == part) and w.Part1 or w.Part0
        if lain then
          if BADAN_KENAL[lain.Name] then return lain.Name end
          local r = atasIkat(lain, hop + 1)
          if r then return r end
        end
      end
    end
    return nil
  end

  local function atasCariAcc(part)
    local p = part.Parent
    local hop = 0
    while p and hop < 4 do
      if p:IsA("Accessory") then return p end
      p = p.Parent
      hop = hop + 1
    end
    return nil
  end

  local function atasSapu(on)
    local char = LocalPlayer.Character
    if not char then return end
    local batasY = nil
    pcall(function()
      local hrp = char:FindFirstChild("HumanoidRootPart")
      if hrp then batasY = hrp.Position.Y - 1.0 end
    end)
    local petaIkat = {}
    for _, bp in ipairs(char:GetDescendants()) do
      pcall(function()
        if bp:IsA("BasePart") and BADAN_KENAL[bp.Name] then
          for _, c in ipairs(bp:GetChildren()) do
            if c:IsA("Attachment") then petaIkat[c.Name] = bp.Name end
          end
        end
      end)
    end
    for _, d in ipairs(char:GetDescendants()) do
      pcall(function()
        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
          local sembunyi = false
          if BADAN_KENAL[d.Name] then
            sembunyi = (ATAS_R15[d.Name] or ATAS_R6[d.Name]) and true or false
          else
            local tubuh = atasIkat(d, 0)
            if tubuh then
              sembunyi = (ATAS_R15[tubuh] or ATAS_R6[tubuh]) and true or false
            else
              local acc = atasCariAcc(d)
              local att = acc and acc:FindFirstChildWhichIsA("Attachment", true) or nil
              local owner = att and petaIkat[att.Name] or nil
              if owner then
                sembunyi = (ATAS_R15[owner] or ATAS_R6[owner]) and true or false
              else
                local okP, pos = pcall(function() return d.Position end)
                if okP and pos and batasY then
                  sembunyi = pos.Y > batasY
                else
                  sembunyi = true
                end
              end
            end
          end
          if on then
            if sembunyi then
              d.LocalTransparencyModifier = 1
              for _, c in ipairs(d:GetDescendants()) do
                if c:IsA("Decal") then
                  if atasDecalOrig[c] == nil then atasDecalOrig[c] = c.Transparency end
                  c.Transparency = 1
                end
              end
            end
          else
            d.LocalTransparencyModifier = 0
          end
        end
      end)
    end
    if not on then
      for c, tr in pairs(atasDecalOrig) do
        pcall(function() if c.Parent then c.Transparency = tr end end)
      end
      table.clear(atasDecalOrig)
    end
  end

  -- v1.5: HideAtas pakai DescendantAdded (hemat 90% CPU)
  Setters.HideAtas = function(v, silent)
    if State.HideAtasOn == v then return end
    State.HideAtasOn = v
    if v then
      atasSapu(true)
      local char = getChar()
      if char then
        if atasConn then atasConn:Disconnect() end
        atasConn = catat(char.DescendantAdded:Connect(function(d)
          if not State.HideAtasOn or State.Removed then return end
          task.defer(function()
            if d:IsA("BasePart") or d:IsA("Decal") then
              atasSapu(true)
            end
          end)
        end))
      end
    else
      if atasConn then atasConn:Disconnect() atasConn = nil end
      atasSapu(false)
    end
    syncNotify("HideAtas", v, silent, "Hide Badan Atas")
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

  -- DINDING BATAS
  local wallOriginal = {}
  local wallBoxes = {}
  local wallConn
  local WALL_ISI  = Color3.fromRGB(70, 70, 70)
  local WALL_TEPI = Color3.fromRGB(150, 150, 150)

  local function isWallCandidate(part)
    if not part:IsA("BasePart") or part == Terrain then return false end
    if part.Transparency < 0.95 then return false end
    if not part.CanCollide then return false end
    local m = part:FindFirstAncestorOfClass("Model")
    if m and Players:GetPlayerFromCharacter(m) then return false end
    return true
  end

  local function wallify(part)
    if wallOriginal[part] then return end
    wallOriginal[part] = {Transparency = part.Transparency, Color = part.Color}
    part.Transparency = 0.6
    part.Color = WALL_ISI
    pcall(function()
      local box = Instance.new("SelectionBox")
      box.Adornee = part
      box.LineThickness = 0.05
      box.Color3 = WALL_TEPI
      box.SurfaceTransparency = 1
      box.Visible = true
      box.Parent = part
      wallBoxes[part] = box
    end)
  end

  Setters.Walls = function(v, silent)
    if State.WallsOn == v then return end
    State.WallsOn = v
    if v then
      for _, obj in ipairs(Workspace:GetDescendants()) do
        if isWallCandidate(obj) then wallify(obj) end
      end
      wallConn = Workspace.DescendantAdded:Connect(function(obj)
        task.defer(function()
          if State.WallsOn and isWallCandidate(obj) then wallify(obj) end
        end)
      end)
    else
      if wallConn then wallConn:Disconnect() wallConn = nil end
      for part, d in pairs(wallOriginal) do
        pcall(function()
          if part.Parent then
            part.Transparency = d.Transparency
            part.Color = d.Color
          end
        end)
      end
      for _, box in pairs(wallBoxes) do
        pcall(function() box:Destroy() end)
      end
      table.clear(wallOriginal)
      table.clear(wallBoxes)
    end
    syncNotify("Walls", v, silent, "Dinding Batas")
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

  -- REJOIN
  rejoin = function()
    toast("🔁 Rejoin: balik ke server dalam 3 detik...", Warna.Biru)
    task.delay(3, function()
      local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
      end)
      if not ok then
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
      end
    end)
  end

  -- UNLOAD SCRIPT
  unloadScript = function(tenang)
    if State.Removed then return end
    State.Removed = true
    pcall(setFeature, "Speed", false, true)
    pcall(setFeature, "Jump", false, true)
    pcall(setFeature, "Shift", false, true)
    pcall(setFeature, "Moon", false, true)
    pcall(setFeature, "Tengah", false, true)
    pcall(setFeature, "Hide", false, true)
    pcall(setFeature, "LW", false, true)
    pcall(setFeature, "Walls", false, true)
    pcall(setFeature, "Light", false, true)
    pcall(setFeature, "HideAtas", false, true)
    pcall(setFeature, "Emote", false, true)
    pcall(function() RunService:UnbindFromRenderStep("KS_SHIFTLOCK") end)
    pcall(function() RunService:UnbindFromRenderStep("KS_MOONWALK") end)
    pcall(function() RunService:UnbindFromRenderStep("KS_TENGAH") end)
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
    pcall(emoteStopTrack)
    pcall(function() if TITIK.folder then TITIK.folder:Destroy(); TITIK.folder = nil end end)
    if lightConn then pcall(function() task.cancel(lightConn) end) lightConn = nil end
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
            if h.UseJumpPower then
              if State.JumpAwal then h.JumpPower = State.JumpAwal end
            elseif State.JumpAwalH then
              h.JumpHeight = State.JumpAwalH
            end
            h.AutoRotate = true
          end
        end
      end)
    end
    pcall(function() if screenGui then screenGui:Destroy() end end)
    _G.__BALAP_MAIN__ = nil
    _G.__KS_DELETE_ARMED__ = nil
    pcall(function()
      if script and script.Parent then
        script.Disabled = true
        script:Destroy()
      end
    end)
    print("[BALAP] Script dihapus total — semua dibersihkan ✔")
  end

  -- WATCHDOG TAKEOVER
  task.spawn(function()
    while not State.Removed do
      if _G.__BALAP_TOKEN__ ~= MY_TOKEN or not screenGui.Parent then
        local adaPenerus = (_G.__BALAP_TOKEN__ ~= MY_TOKEN)
        pcall(function() unloadScript(adaPenerus) end)
        break
      end
      task.wait(0.5)
    end
  end)

  -- KARAKTER RESPAWN
  local initedChar
  local function initCharacter(char)
    if State.Removed then return end
    if initedChar == char then return end
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    initedChar = char
    updateJumpLabel()
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
    if State.JumpAwal == nil and hum then
      State.JumpAwal = hum.JumpPower
      State.JumpAwalH = hum.JumpHeight
    end
    if State.SpeedOn then applySpeed() end
    if State.JumpOn then applyJump() end
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

  -- v1.5: task.wait 0.3 → 0.8 (hemat CPU)
  task.spawn(function()
    while not State.Removed do
      if State.HideOn then pcall(updateVehicles) end
      task.wait(0.8)
    end
  end)

  -- BUKA / TUTUP GUI
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

  -- CTRL + KLIK
  catat(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or State.Removed or not TITIK.aktif then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
    and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
    or UserInputService:IsKeyDown(Enum.KeyCode.RightControl))
    and not UserInputService:GetFocusedTextBox() then
      titikKlikDunia()
    end
  end))

  -- KEYBIND
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
    elseif input.KeyCode == Enum.KeyCode.J then
      setFeature("Jump", not State.JumpOn)
    elseif input.KeyCode == Enum.KeyCode.C then
      setFeature("Shift", not State.ShiftOn)
    elseif input.KeyCode == Enum.KeyCode.F then
      setFeature("Moon", not State.MoonOn)
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
      setFeature("Tengah", not State.TengahOn)
    elseif input.KeyCode == Enum.KeyCode.Z then
      setFeature("HideAtas", not State.HideAtasOn)
    elseif input.KeyCode == Enum.KeyCode.R then
      setFeature("Hide", not State.HideOn)
    elseif input.KeyCode == Enum.KeyCode.T then
      setFeature("Light", not State.LightOn)
    elseif input.KeyCode == Enum.KeyCode.X then
      setFeature("Walls", not State.WallsOn)
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
      warn("[BALAP] bukaGui error: " .. tostring(errG))
    end
  end)

  print("[BALAP " .. VERSI .. "] SIAP ✔ — G = GUI | K×2 = rejoin")
  print("[BALAP] MOVE&VISUAL | ANIMASI | EMOTE | TITIK | SYSTEM")
  diagHapus()
end -- akhir initLogic()

initLogic()
getgenv().BALAP_API = { Setters = Setters, State = State }

end, function(e)
  local teks = tostring(e)
  print("==================================================")
  print("[BALAP " .. VERSI .. "] ERROR SAAT LOAD — kirim teks ini ke dev:")
  print(teks)
  pcall(function() print(debug.traceback("", 2)) end)
  print("==================================================")
  pcall(function()
    diagSet("ERROR LOAD: " .. teks:sub(1, 260), Color3.fromRGB(239, 68, 68))
  end)
end)

if not __BALAP_LOAD_OK__ then
  warn("[BALAP " .. VERSI .. "] Script GAGAL load — banner MERAH di layar berisi errornya.")
end
