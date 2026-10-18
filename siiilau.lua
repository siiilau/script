--========================================================
--  SILAU NEON MAIN v1.4 — Script Utama Gabungan
--  TIANG PATH (v1.4.3) + KING UTILITY (v1.5)
--    + CAHAYA AUTO + FALL ASSIST v3.1 + MOONWALK
--  v1.4: hapus baris PULIHKAN+TP TERPILIH, TP pakai 🚀 per-row
--
--  TEMA: SILAU NEON (ungu/biru LED)
--  Keybind:
--    F = buka/tutup GUI (saat tutup = hilang total)
--    Y = pasang tiang
--    Q = Speed      C = Shiftlock Mobile
--    G = Moonwalk   R = Hide
--    X = Dinding Batas   T = Cahaya Auto
--    K = Rejoin (double-tap)
--========================================================

local VERSI = "1.4-MAIN"

-- [1] PENGAMAN DASAR -----------------------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
    warn("[SilauNeon] GAGAL: harus jalan di CLIENT (executor / LocalScript), bukan server!")
    return
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local TeleportService  = game:GetService("TeleportService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local VirtualUser      = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
if not LocalPlayer then
    warn("[SilauNeon] GAGAL: LocalPlayer belum ada.")
    return
end

local Terrain = Workspace:WaitForChild("Terrain")

-- anti double-run
if _G.__SILAU_NEON_MAIN__ then return end
_G.__SILAU_NEON_MAIN__ = true

-- [2] KONFIGURASI ---------------------------------------------------
-- Semua konstanta digabung ke dalam 1 table CFG untuk hemat local count
-- (Luau limit 200 local per function)
local CFG = {
    ICON_SIZE       = 36,
    TOGGLE_KEY      = Enum.KeyCode.F,
    PASANG_KEY      = Enum.KeyCode.Y,
    TELEPORT_OFFSET = 3.5,
    TIANG_TINGGI    = 4,
    TIANG_TEBAL     = 1.1,
    ANGKAT_GARIS    = 2,
    JARAK_SAMPL     = 3,
    TINGGI_SCAN     = 250,
    TOLERANSI_GARIS = 0.2,
    SAMPL_REKAM     = 1.2,
    MAX_TITIK       = 2500,
    TEBAL_LINE_REK  = 0.08,
    TOLERANSI_REK   = 0.06,
    LED_TEXT        = "⚡ S I L A U ⚡",
    SOUND_ON        = true,
    FX_LEVEL        = 1,
    NAMA_FILE_TIANG  = "TiangPath_Silau.json",
    NAMA_FILE_TIANG_B = "TiangPath_Silau_backup.json",
    DEFAULT_SPEED  = 17.25,
    DEFAULT_JUMP   = 62.00,
    OFF_SPEED      = 17,
    OFF_JUMP       = 51.25,
    OFF_JUMP_H     = 6.69,
    SND_PING   = "rbxasset://sounds/electronicpingshort.wav",
    SND_SNAP   = "rbxasset://sounds/snap.mp3",
    SND_WHOOSH = "rbxasset://sounds/unsheath.wav",
}
-- shorthand alias untuk konstanta yang dipakai banyak (tetap hemat local)
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
    Gray      = Color3.fromRGB(72, 72, 94),
    Card2     = Color3.fromRGB(40, 40, 62),
}

-- [3] FONT KOMPATIBEL -----------------------------------------------
local FONT_OK = pcall(function()
    return Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Regular)
end)

-- cacheFont di-inline ke dalam closure fnt untuk hemat local count
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

-- TEKS_CLASS di-inline ke dalam buat (hemat local count)

-- [4] HELPER --------------------------------------------------------
local rnd = math.random

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

-- SND_* sudah di CFG, pakai langsung CFG.CFG.SND_PING / CFG.CFG.SND_SNAP / CFG.CFG.SND_WHOOSH

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

local function nomorBebas(prefix, daftarNama)
    local pakai = {}
    for _, nama in ipairs(daftarNama) do
        local n = tonumber(nama:match("^" .. prefix .. " (%d+)$"))
        if n then pakai[n] = true end
    end
    local n = 1
    while pakai[n] do n += 1 end
    return n
end

local function idBaru()
    return tostring(os.time()) .. "-" .. tostring(rnd(100000, 999999))
end

-- r2 di-inline (hemat local)

-- [4b] REGISTRY KONEKSI & FORWARD DECLARE ---------------------------
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
local setFeature, togglePanel, resetAll, rejoin, unloadScript
local applySpeed, applyJump, updateJumpLabel
local RefreshSpeed, RefreshJump, JumpLabel
local refreshListTiang
local pasangTiang
local cfgFall, oLight, fallState, fallRay, lightConn

-- Forward declare untuk part3 (FX/footer/icon) — di-expose via buildFX()
local konfeti, emojiBurst, pusatDiRoot, toast
local kumpulkanFade, setFade, fadeVal
local folderDunia

-- Forward declare untuk part2 (UI builder) — di-expose via buildUI()
local tabBtns, kontenTabs, setTab
local kontenTiang, kontenKing, scrollKing
local nameBoxTiang, nameStrokeTiang, saveBtnTiang, searchBoxTiang, searchStrokeTiang
local btnBersih, btnGaris, btnSambung, btnPutus, listLabelTiang, scrollTiang

setFeature = function(name, v, silent)
    local f = Setters[name]
    if f then f(v, silent) end
end

local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
-- getRoot di-inline (hemat local)
local function getKarakter()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local fileOk = (type(writefile) == "function" and type(readfile) == "function")

-- [5] EFEK LED & UI HELPER ------------------------------------------
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
    tween(g, TweenInfo.new(dur or 2.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
        {Offset = Vector2.new(1, 0)})
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

-- [6] SCREENGUI -----------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SilauNeonMain"
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
        local lama = t:FindFirstChild("SilauNeonMain")
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
    warn("[SilauNeon] GAGAL: tidak bisa memasang GUI.")
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

-- [7] BANGUN UI: ROOT + OUTER + PANEL -------------------------------
local screenFx = buat("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 900,
}, screenGui)
-- screenFx akan di-akses lintas part (part4 pakai untuk FX overlay)

local root = buat("Frame", {
    Size = UDim2.fromOffset(360, 720),
    Position = UDim2.new(0.5, 0, 0.10, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
}, screenGui)
local panelScale = buat("UIScale", {Scale = 1}, root)

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
tween(borderGrad, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = 360})

local ring2Stroke = buat("UIStroke", {Color = Warna.Putih, Thickness = 1, Transparency = 0.45}, outer)
local ring2Grad = buat("UIGradient", {Color = ColorSequence.new(Warna.Ungu2, Warna.Biru2)}, ring2Stroke)
tween(ring2Grad, TweenInfo.new(3.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = -360})

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

for i = 1, 3 do
    local stripe = buat("Frame", {
        Name = "NoFade",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.3 * i, 0, 0.5, 0),
        Size = UDim2.fromOffset(26, 580),
        Rotation = 24,
        BackgroundColor3 = i % 2 == 0 and Warna.UnguMuda or Warna.BiruMuda,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, partBox)
    tween(stripe, TweenInfo.new(6 + i * 2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true),
        {Position = UDim2.new(0.3 * i + 0.25, 0, 0.5, 0)})
end

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
    Size = UDim2.new(1, -70, 1, 0),
    FontFace = fnt("judul"),
    Text = "⚡ SILAU NEON ⚡",
    TextColor3 = Warna.Putih,
    TextSize = 21,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)
ledSweep(title, Warna.Putih, Warna.Ungu2, Warna.Biru2, 2.2)

local titleGlow = buat("UIStroke", {Name = "NoFade", Color = Warna.Ungu2, Thickness = 1, Transparency = 0.35}, title)
task.spawn(function()
    while title.Parent do
        tween(titleGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.75})
        task.wait(0.8)
        if not title.Parent then break end
        tween(titleGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.35})
        task.wait(0.8)
    end
end)

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
-- [7b] TAB BAR (2 TAB — KING DULU, TIANG KEDUA) ---------------------
-- Bungkus dengan function untuk hemat local count (Luau limit 200)
local function buildUI()
tabBtns = {}
local tabLabels = {"👑 KING", "🗄️ TIANG"}
local tabColors = {Warna.Ungu2, Warna.Biru}
kontenTabs = {}

for i, lbl in ipairs(tabLabels) do
    local tab = buat("TextButton", {
        Size = UDim2.new(0.5, -3, 0, 24),
        Position = UDim2.new((i - 1) * 0.5, 6 + (i - 1) * 2, 0, 50),
        BackgroundColor3 = (i == 1) and tabColors[i] or Warna.AbuMuda,
        BorderSizePixel = 0,
        FontFace = fnt("bold"),
        Text = lbl,
        TextColor3 = (i == 1) and Warna.Putih or Warna.AbuTeks,
        TextSize = 11,
        AutoButtonColor = false,
    }, panel)
    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, tab)
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

-- [7d] KONTEN TAB 2: TIANG ------------------------------------------
kontenTiang = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
}, panel)
table.insert(kontenTabs, kontenTiang)

nameBoxTiang = buat("TextBox", {
    Size = UDim2.new(1, -116, 0, 32),
    Position = UDim2.new(0, 12, 0, 2),
    BackgroundColor3 = Warna.AbuMuda,
    BorderSizePixel = 0,
    FontFace = fnt("med"),
    PlaceholderText = "📍 Ketik nama tiang...",
    PlaceholderColor3 = Warna.AbuTeks,
    Text = "",
    TextColor3 = Warna.TeksGelap,
    TextSize = 13,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
}, kontenTiang)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, nameBoxTiang)
nameStrokeTiang = buat("UIStroke", {Color = Warna.Ungu, Thickness = 1, Transparency = 0.5}, nameBoxTiang)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10)}, nameBoxTiang)

saveBtnTiang = buat("TextButton", {
    Size = UDim2.fromOffset(92, 32),
    Position = UDim2.new(1, -104, 0, 2),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "➕ PASANG",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, kontenTiang)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, saveBtnTiang)
ledSweep(saveBtnTiang, Warna.Ungu, Warna.Putih, Warna.Biru2, 2.4)

searchBoxTiang = buat("TextBox", {
    Size = UDim2.new(1, -24, 0, 28),
    Position = UDim2.new(0, 12, 0, 40),
    BackgroundColor3 = Warna.AbuMuda,
    BorderSizePixel = 0,
    FontFace = fnt("reg"),
    PlaceholderText = "🔍 Cari tiang...",
    PlaceholderColor3 = Warna.AbuTeks,
    Text = "",
    TextColor3 = Warna.TeksGelap,
    TextSize = 12,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
}, kontenTiang)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, searchBoxTiang)
searchStrokeTiang = buat("UIStroke", {Color = Warna.Biru, Thickness = 1, Transparency = 0.6}, searchBoxTiang)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10)}, searchBoxTiang)

btnBersih = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 22),
    Position = UDim2.new(0, 12, 0, 72),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🧹 HAPUS SEMUA",
    TextColor3 = Warna.Putih,
    TextSize = 10,
    AutoButtonColor = false,
}, kontenTiang)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnBersih)
buat("UIStroke", {Color = Warna.Merah, Thickness = 1, Transparency = 0.4}, btnBersih)

btnGaris = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 22),
    Position = UDim2.new(0.5, 4, 0, 72),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "↺ HITUNG GARIS",
    TextColor3 = Warna.Putih,
    TextSize = 10,
    AutoButtonColor = false,
}, kontenTiang)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnGaris)
ledSweep(btnGaris, Warna.Biru, Warna.Putih, Warna.Ungu2, 2.4)

btnSambung = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 22),
    Position = UDim2.new(0, 12, 0, 100),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🔗 SAMBUNG",
    TextColor3 = Warna.Putih,
    TextSize = 10,
    AutoButtonColor = false,
}, kontenTiang)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnSambung)
ledSweep(btnSambung, Warna.Hijau2, Warna.Putih, Warna.Hijau, 2.6)

btnPutus = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 22),
    Position = UDim2.new(0.5, 4, 0, 100),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "✂️ PUTUS",
    TextColor3 = Warna.Putih,
    TextSize = 10,
    AutoButtonColor = false,
}, kontenTiang)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnPutus)
buat("UIStroke", {Color = Warna.Merah, Thickness = 1, Transparency = 0.4}, btnPutus)

-- (baris PULIHKAN + TP TERPILIH dihapus v1.4 — TP pakai tombol 🚀 per-row di list)

listLabelTiang = buat("TextLabel", {
    Position = UDim2.new(0, 12, 0, 130),
    Size = UDim2.new(1, -24, 0, 14),
    BackgroundTransparency = 1,
    FontFace = fnt("semi"),
    Text = "📍 TIANG • 0  (klik nomor = pilih • 🚀 = TP ke tiang)",
    TextColor3 = Warna.AbuTeks,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, kontenTiang)

scrollTiang = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 148),
    Size = UDim2.new(1, -24, 1, -160),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Ungu,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, kontenTiang)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollTiang)

-- [7f] KONTEN TAB 4: KING (tanpa Cahaya) ----------------------------
kontenKing = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
}, panel)
table.insert(kontenTabs, kontenKing)

scrollKing = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 2),
    Size = UDim2.new(1, -24, 1, -6),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Ungu,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, kontenKing)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollKing)

local sOrder = 0
local function nextOrder() sOrder += 1 return sOrder end

local function kingHeader(text)
    return buat("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        FontFace = fnt("bold"),
        TextSize = 11,
        TextColor3 = Warna.Ungu,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "▎" .. string.upper(text),
        LayoutOrder = nextOrder(),
    }, scrollKing)
end

local function kingToggleRow(labelText, keyText, featureName)
    local row = buat("Frame", {
        BackgroundColor3 = Warna.AbuItem,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = nextOrder(),
    }, scrollKing)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)

    local label = buat("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -110, 1, 0),
        FontFace = fnt("med"),
        TextSize = 12,
        TextColor3 = Warna.TeksGelap,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = labelText,
    }, row)

    if keyText then
        local chip = buat("TextLabel", {
            BackgroundColor3 = Warna.Card2,
            Size = UDim2.new(0, 22, 0, 20),
            Position = UDim2.new(1, -80, 0.5, -10),
            FontFace = fnt("bold"),
            TextSize = 11,
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

local function kingStepperRow(labelText, getV, setV)
    local row = buat("Frame", {
        BackgroundColor3 = Warna.AbuItem,
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = nextOrder(),
    }, scrollKing)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    if labelText then
        buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(0, 100, 1, 0),
            FontFace = fnt("med"),
            TextSize = 11,
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
        TextSize = 15,
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
        TextSize = 13,
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
        TextSize = 15,
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
        local n = tonumber(box.Text)
        if n then setV(clamp2(math.clamp(n, 0, 1000))) end
        refresh()
        notifChange()
    end)
    return refresh
end

local function kingActionRow(text, color, callback)
    local btn = buat("TextButton", {
        BackgroundColor3 = color,
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = nextOrder(),
        FontFace = fnt("bold"),
        TextSize = 12,
        TextColor3 = Warna.Putih,
        Text = text,
        AutoButtonColor = false,
    }, scrollKing)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
    btn.MouseButton1Click:Connect(callback)
    efekTombol(btn, 1.03)
    return btn
end

-- init State KING
State.SpeedOn = false
State.SpeedValue = CFG.DEFAULT_SPEED
State.JumpOn  = false
State.JumpValue = CFG.DEFAULT_JUMP
State.JumpHeightValue = 7.2
State.ShiftOn = false
State.IsSwimming = false
State.HideOn  = false
State.LWOn    = false
State.WallsOn = false
State.LightOn = false
State.FallOn  = false
State.MoonOn  = false  -- Moonwalk (G)

-- Config Fall Assist v3.1 "VIRTUAL BRANCH"
cfgFall = {
    minJatuh = 50,
    posisi   = 0.80,
}

-- Original Lighting (untuk restore saat cahaya dimatikan)
oLight = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

-- State Fall Assist
fallState = {
    jatuh   = false,
    apex    = 0,
    bentur  = false,
    sejak   = 0,
    groundY = nil,
    lastRay = 0,
    conn    = nil,
}

-- Raycast params khusus Fall Assist
fallRay = RaycastParams.new()
fallRay.FilterType = Enum.RaycastFilterType.Exclude

lightConn = nil

kingHeader("Player")
kingToggleRow("Speed", "Q", "Speed")
RefreshSpeed = kingStepperRow(
    "Speed",
    function() return State.SpeedValue end,
    function(v)
        State.SpeedValue = v
        if State.SpeedOn then applySpeed() end
    end
)
local _, jumpLabelRow = kingToggleRow("JumpPower", nil, "Jump")
JumpLabel = jumpLabelRow
RefreshJump = kingStepperRow(
    "Jump",
    function()
        local hum = getHum()
        if hum and hum.UseJumpPower == false then return State.JumpHeightValue end
        return State.JumpValue
    end,
    function(v)
        local hum = getHum()
        if hum and hum.UseJumpPower == false then State.JumpHeightValue = v else State.JumpValue = v end
        if State.JumpOn then applyJump() end
    end
)
kingToggleRow("Shiftlock Mobile", "C", "Shift")
kingToggleRow("Moonwalk", "G", "Moon")

kingHeader("Visual")
kingToggleRow("Hide Player + Kendaraan", "R", "Hide")

kingHeader("Lightweight")
kingToggleRow("Partikel / Bayangan / Efek", nil, "LW")

kingHeader("Map")
kingToggleRow("Dinding Batas", "X", "Walls")

kingHeader("Lingkungan")
kingToggleRow("Cahaya Auto", "T", "Light")

kingHeader("Jatuh Cerdas")
kingToggleRow("Smart Fall Assist", nil, "Fall")

-- King number row (untuk pengaturan fall assist)
local function kingNumRow(labelText, default, cb)
    local row = buat("Frame", {
        BackgroundColor3 = Warna.AbuItem,
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = nextOrder(),
    }, scrollKing)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    buat("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -100, 1, 0),
        FontFace = fnt("med"),
        TextSize = 11,
        TextColor3 = Warna.TeksGelap,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = labelText,
    }, row)
    local bx = buat("TextBox", {
        BackgroundColor3 = Warna.Hitam2,
        Size = UDim2.fromOffset(70, 22),
        Position = UDim2.new(1, -80, 0.5, -11),
        FontFace = fnt("reg"),
        TextSize = 12,
        TextColor3 = Warna.Putih,
        Text = string.format("%.2f", default),
        ClearTextOnFocus = false,
    }, row)
    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, bx)
    buat("UIStroke", {Color = Warna.AbuGelap, Thickness = 1, Transparency = 0.5}, bx)
    bx.FocusLost:Connect(function()
        local n = tonumber((bx.Text:gsub("[^%d%.%-]", "")))
        if n then
            cb(n)
            bx.Text = string.format("%.2f", n)
            toast(labelText .. ": " .. string.format("%.2f", n), Warna.Biru)
        else
            bx.Text = string.format("%.2f", default)
        end
    end)
end

kingNumRow("MIN JATUH (stud)", cfgFall.minJatuh, function(n) cfgFall.minJatuh = n end)
kingNumRow("POSISI BENTUR (0-1)", cfgFall.posisi, function(n)
    if n > 0 and n < 1 then cfgFall.posisi = n end
end)

kingHeader("Ekstra")
kingActionRow("🔄 RESET SCRIPT", Warna.Biru, function() resetAll() end)
kingActionRow("🔁 REJOIN SERVER  [K×2]", Warna.Biru, function() rejoin() end)
kingActionRow("🗑️ HAPUS SCRIPT", Warna.Merah, function()
    if not _G.__KS_DELETE_ARMED__ then
        _G.__KS_DELETE_ARMED__ = true
        bunyi(CFG.SND_SNAP, 0.3, 0.8)
        task.delay(3, function() _G.__KS_DELETE_ARMED__ = nil end)
    else
        _G.__KS_DELETE_ARMED__ = nil
        unloadScript()
    end
end)

end -- akhir buildUI()

-- Eksekusi buildUI() sekarang (panel, root, outer, Warna, buat sudah ada dari part1)
buildUI()
-- [8] FOOTER + LED + MARQUEE ---------------------------------------
-- Bungkus dengan function untuk hemat local count (Luau limit 200)
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
    TextSize = 14,
}, footer)
local ledGlow = buat("UIStroke", {Name = "NoFade", Color = Warna.Ungu2, Thickness = 1, Transparency = 0.4}, ledLabel)
cycleColor(ledLabel, "TextColor3", {Warna.Putih, Warna.Ungu2, Warna.Biru2, Warna.Ungu2}, 0.4)
task.spawn(function()
    while ledGlow.Parent do
        tween(ledGlow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.8})
        task.wait(0.5)
        if not ledGlow.Parent then break end
        tween(ledGlow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.2})
        task.wait(0.5)
    end
end)

local marqueeClip = buat("Frame", {
    Position = UDim2.new(0, 6, 0, 17),
    Size = UDim2.new(1, -12, 0, 13),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, footer)
local marquee = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(360, 0),
    Size = UDim2.fromOffset(1400, 13),
    FontFace = fnt("med"),
    Text = "⌨ F = GUI   ✦   👑 KING: Q Speed / C Shift / G Moonwalk / R Hide / X Walls / T Cahaya / Fall Assist   ✦   🗄️ TIANG: Y pasang + 🔗 sambung + 🚀 TP per-row   ✦   Notif kanan atas",
    TextColor3 = Warna.AbuGelap,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, marqueeClip)
tween(marquee, TweenInfo.new(20, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Position = UDim2.fromOffset(-1400, 0)})

-- bracket pojok (dekorasi)
local posisiTitik = {
    UDim2.new(0.5, 0, 0, 1),
    UDim2.new(0.5, 0, 1, -1),
    UDim2.new(0, 1, 0.5, 0),
    UDim2.new(1, -1, 0.5, 0),
}
for i, p in ipairs(posisiTitik) do
    local d = buat("Frame", {
        Name = "NoFade",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = p,
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = Warna.Ungu2,
        BorderSizePixel = 0,
        ZIndex = 3,
    }, outer)
    buat("UICorner", {CornerRadius = UDim.new(1, 0)}, d)
    cycleColor(d, "BackgroundColor3", {Warna.Putih, Warna.Ungu2, Warna.Biru2, Warna.Ungu}, 0.6 * i + 0.3)
end

local function bracket(ax, ay, px, py, warna)
    local bar1 = buat("Frame", {Name = "NoFade", AnchorPoint = Vector2.new(ax, ay),
        Position = UDim2.new(px, ax == 1 and -8 or 8, py, ay == 1 and -8 or 8),
        Size = UDim2.fromOffset(14, 3), BackgroundColor3 = warna, BorderSizePixel = 0, ZIndex = 3}, outer)
    local bar2 = buat("Frame", {Name = "NoFade", AnchorPoint = Vector2.new(ax, ay),
        Position = UDim2.new(px, ax == 1 and -3 or 3, py, ay == 1 and -3 or 3),
        Size = UDim2.fromOffset(3, 14), BackgroundColor3 = warna, BorderSizePixel = 0, ZIndex = 3}, outer)
    return {bar1, bar2}
end
local semuaBracket = {
    bracket(0, 0, 0, 0, Warna.Ungu2),
    bracket(1, 0, 1, 0, Warna.Biru2),
    bracket(0, 1, 0, 1, Warna.Biru2),
    bracket(1, 1, 1, 1, Warna.Ungu2),
}
task.spawn(function()
    while outer.Parent do
        for i, pasang in ipairs(semuaBracket) do
            for _, b in ipairs(pasang) do
                tween(b, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {BackgroundTransparency = (i % 2 == 0) and 0.7 or 0.1})
            end
        end
        task.wait(0.62)
        if not outer.Parent then break end
        for i, pasang in ipairs(semuaBracket) do
            for _, b in ipairs(pasang) do
                tween(b, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {BackgroundTransparency = (i % 2 == 0) and 0.1 or 0.7})
            end
        end
        task.wait(0.62)
    end
end)

-- [9] PARTIKEL AMBIENT ----------------------------------------------
local emojiAmbient = {"✨", "⚡", "💜", "💙", "⭐", "💫", "🔹", "🌟"}
task.spawn(function()
    while partBox.Parent do
        if CFG.FX_LEVEL == 1 and root.Visible then
            local x0 = rnd(6, 94) / 100
            local l = buat("TextLabel", {
                Name = "NoFade",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(x0, 0, 1.05, 0),
                Size = UDim2.fromOffset(20, 20),
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSans,
                Text = emojiAmbient[rnd(1, #emojiAmbient)],
                TextSize = rnd(11, 17),
                TextColor3 = Warna.Putih,
                TextTransparency = 1,
                Rotation = rnd(-15, 15),
            }, partBox)
            local dur = rnd(28, 46) / 10
            tween(l, TweenInfo.new(0.35), {TextTransparency = 0.55})
            tween(l, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Position = UDim2.new(x0 + rnd(-6, 6) / 100, 0, -0.08, 0)})
            tween(l, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {Rotation = l.Rotation + rnd(16, 30) * (rnd(0, 1) == 0 and 1 or -1)})
            task.delay(dur - 0.4, function()
                if l.Parent then tween(l, TweenInfo.new(0.4), {TextTransparency = 1}) end
            end)
            task.delay(dur + 0.1, function() l:Destroy() end)
            task.wait(rnd(4, 8) / 10)
        else
            task.wait(0.8)
        end
    end
end)

task.spawn(function()
    while header.Parent do
        task.wait(rnd(6, 14) / 10)
        if not header.Parent then break end
        local s = buat("TextLabel", {
            Name = "NoFade",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(rnd(5, 90) / 100, 0, rnd(20, 80) / 100, 0),
            Size = UDim2.fromOffset(14, 14),
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            Text = rnd(0, 1) == 0 and "✦" or "✨",
            TextSize = rnd(9, 13),
            TextColor3 = Warna.Putih,
            TextTransparency = 1,
            ZIndex = 2,
        }, header)
        tween(s, TweenInfo.new(0.2), {TextTransparency = 0.1})
        task.delay(0.35, function()
            if s.Parent then tween(s, TweenInfo.new(0.35), {TextTransparency = 1}) end
        end)
        task.delay(0.75, function() s:Destroy() end)
    end
end)

-- [10] BURST FX -----------------------------------------------------
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


-- [12] TOAST — KANAN ATAS LAYAR (stack vertikal) -------------------
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
    -- dot indikator warna
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
        TextSize = 12,
        TextTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, t)

    -- animasi masuk: slide dari kanan + fade in
    t.Position = UDim2.new(1, 20, 0, 0)  -- start offset right
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

    -- batasi max 5 notif tampil
    local list = {}
    for _, c in ipairs(notifHolder:GetChildren()) do
        if c:IsA("Frame") and c.Name == "NoFade" then table.insert(list, c) end
    end
    if #list > 5 then
        list[1]:Destroy()
    end
end

-- [13] FADE PER-ELEMEN ----------------------------------------------
local elemenFade = {}
fadeVal = Instance.new("NumberValue")
pcall(function() fadeVal.Parent = screenGui end)

kumpulkanFade = function()
    table.clear(elemenFade)
    local daftar = outer:GetDescendants()
    table.insert(daftar, outer)
    for _, obj in ipairs(daftar) do
        if obj.Name ~= "NoFade" then
            if obj:IsA("Frame") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
                if obj.BackgroundTransparency < 1 then
                    table.insert(elemenFade, {obj, "BackgroundTransparency", obj.BackgroundTransparency})
                end
                if (obj:IsA("TextLabel") or obj:IsA("TextBox")) and obj.TextTransparency < 1 then
                    table.insert(elemenFade, {obj, "TextTransparency", obj.TextTransparency})
                end
            elseif obj:IsA("UIStroke") and obj.Transparency < 1 then
                table.insert(elemenFade, {obj, "Transparency", obj.Transparency})
            end
        end
    end
end

setFade = function(t)
    for _, e in ipairs(elemenFade) do
        e[1][e[2]] = e[3] + (1 - e[3]) * t
    end
end

fadeVal.Changed:Connect(setFade)

-- [13b] DUNIA: FOLDER TIANG + REKAMAN --------------------------------
pcall(function()
    local lama = workspace:FindFirstChild("TiangPath_Silau")
    if lama then lama:Destroy() end
end)

folderDunia = Instance.new("Folder")
folderDunia.Name = "TiangPath_Silau"
pcall(function() folderDunia.Parent = workspace end)

end -- akhir buildFX()

-- Eksekusi buildFX() sekarang (panel, root, outer sudah ada dari part1)
buildFX()

-- [13c] STATE TIANG (RECORD dihapus v1.3)
local daftarTiang    = {}
local koneksiAktif   = {}
local genPath        = 0

-- [13d] STATE TELEPORT — DIHAPUS (tab teleport dihapus)
-- lokasiTersimpan & counterNamaTP tidak lagi dipakai
-- [14] LOGIKA TELEPORT — DIHAPUS (tab teleport dihapus)
-- Bungkus part4+5+6 dengan function untuk hemat local count (Luau limit 200)
local function initLogic()

-- Hanya teleportKe & fxTeleport yang dipertahankan (dipakai TIANG/RECORD)
local function fxTeleport()
    bunyi(CFG.SND_WHOOSH, 0.4, 1.1)
    local fl = buat("Frame", {
        Name = "NoFade", Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Warna.Putih, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 950,
    }, screenFx)
    tween(fl, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.55})
    task.delay(0.1, function()
        tween(fl, TweenInfo.new(0.3), {BackgroundTransparency = 1})
        task.delay(0.35, function() fl:Destroy() end)
    end)
    local r = buat("Frame", {
        Name = "NoFade", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 949,
    }, screenFx)
    buat("UICorner", {CornerRadius = UDim.new(1, 0)}, r)
    local rs = buat("UIStroke", {Color = Warna.Ungu, Thickness = 4, Transparency = 0}, r)
    tween(r,  TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(430, 430)})
    tween(rs, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
    task.delay(0.55, function() r:Destroy() end)
    emojiBurst(screenFx, UDim2.new(0.5, 0, 0.5, 0), {"🚀", "✨", "⚡", "💫", "🌟"}, 10)
    tween(panelScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.965})
    task.delay(0.1, function()
        tween(panelScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    end)
end

local function teleportKe(cf)
    local _, hrp, hum = getKarakter()
    if not hrp then return end
    if hum and hum.SeatPart then hum.Sit = false end
    -- Handle both CFrame and Vector3 input
    if typeof(cf) == "Vector3" then
        cf = CFrame.new(cf)
    end
    hrp.CFrame = cf + Vector3.new(0, CFG.TELEPORT_OFFSET, 0)
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

-- [15] LOGIKA TIANG: VISUAL TIANG -----------------------------------
local function buatTiangVisual(basePos, nomor)
    local model = Instance.new("Model")
    model.Name = "Tiang_" .. nomor

    local p = Instance.new("Part")
    p.Name = "Batang"
    p.Shape = Enum.PartType.Cylinder
    p.Material = Enum.Material.Neon
    p.Color = Warna.Ungu
    p.Transparency = 0.15
    p.Size = Vector3.new(CFG.TIANG_TINGGI, CFG.TIANG_TEBAL, CFG.TIANG_TEBAL)
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CFrame = CFrame.new(basePos + Vector3.new(0, CFG.TIANG_TINGGI / 2, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    p.Parent = model

    buat("PointLight", {Color = Warna.Ungu2, Range = 8, Brightness = 1}, p)

    local alas = Instance.new("Part")
    alas.Name = "Alas"
    alas.Shape = Enum.PartType.Cylinder
    alas.Material = Enum.Material.Neon
    alas.Color = Warna.Ungu2
    alas.Size = Vector3.new(0.25, 2.4, 2.4)
    alas.Anchored = true
    alas.CanCollide = false
    alas.CanQuery = false
    alas.CFrame = CFrame.new(basePos + Vector3.new(0, 0.125, 0))
        * CFrame.Angles(0, 0, math.rad(90))
    alas.Parent = model

    local bb = Instance.new("BillboardGui")
    bb.Name = "Nomor"
    bb.Size = UDim2.fromOffset(36, 36)
    bb.StudsOffset = Vector3.new(0, CFG.TIANG_TINGGI / 2 + 1.1, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = 400
    bb.Parent = p

    buat("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        FontFace = fnt("judul"),
        Text = tostring(nomor),
        TextColor3 = Warna.Putih,
        TextSize = 24,
        TextStrokeColor3 = Warna.Ungu,
        TextStrokeTransparency = 0.15,
    }, bb)

    model.Parent = folderDunia
    return model, p
end

local function perbaruiNomor()
    for i, t in ipairs(daftarTiang) do
        local bb = t.batang and t.batang:FindFirstChild("Nomor")
        local lb = bb and bb:FindFirstChildOfClass("TextLabel")
        if lb then lb.Text = tostring(i) end
    end
end

-- [15b] GARIS -------------------------------------------------------
local function buatSegmen(p1, p2, warna, tebal, parent)
    local jarak = (p2 - p1).Magnitude
    if jarak < 0.1 then return end
    local prt = Instance.new("Part")
    prt.Name = "Garis"
    prt.Size = Vector3.new(tebal or 0.16, tebal or 0.16, jarak)
    prt.CFrame = CFrame.lookAt((p1 + p2) / 2, p2)
    prt.Anchored = true
    prt.CanCollide = false
    prt.CanQuery = false
    prt.CanTouch = false
    prt.Material = Enum.Material.Neon
    prt.Color = warna
    prt.Transparency = 0.1
    prt.Parent = parent
    return prt
end

local function sederhanakan(poin, tol)
    if #poin <= 2 then return poin end
    local hasil = {poin[1]}
    local i = 1
    while i < #poin do
        local pilih = i + 1
        local j = i + 2
        while j <= #poin do
            local A, B = poin[i], poin[j]
            local arah = B - A
            local panjang = arah.Magnitude
            if panjang < 0.05 then break end
            arah = arah / panjang
            local ok = true
            for m = i + 1, j - 1 do
                local v = poin[m] - A
                local dev = (v - arah * v:Dot(arah)).Magnitude
                if dev > tol then ok = false break end
            end
            if ok then pilih = j; j += 1 else break end
        end
        table.insert(hasil, poin[pilih])
        i = pilih
    end
    return hasil
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function tiangDariId(id)
    for _, t in ipairs(daftarTiang) do
        if t.id == id then return t end
    end
end

local function koneksiAntara(idA, idB)
    for _, k in ipairs(koneksiAktif) do
        if (k.a == idA and k.b == idB) or (k.a == idB and k.b == idA) then
            return k
        end
    end
end

local function tiangPunyaKoneksi(id)
    for _, k in ipairs(koneksiAktif) do
        if k.a == id or k.b == id then return true end
    end
    return false
end

local function bangunGarisKoneksi(k)
    local tA, tB = tiangDariId(k.a), tiangDariId(k.b)
    if not tA or not tB then return end
    k.parts = k.parts or {}
    local myGen = genPath
    task.spawn(function()
        local filter = {folderDunia}
        local char = LocalPlayer.Character
        if char then table.insert(filter, char) end
        rayParams.FilterDescendantsInstances = filter
        -- pastikan raycast kena SEMUA part (termasuk CanCollide=false)
        rayParams.RespectCanCollide = false
        rayParams.IgnoreWater = false
        local dasarA, dasarB = tA.cframe.Position, tB.cframe.Position

        -- ===== DETEKSI AIR di posisi tiang A dan B =====
        -- Raycast dari atas ke bawah, cek apakah material yang terkena = Water
        local function cekAir(pos)
            local dari = pos + Vector3.new(0, 1000, 0)
            local r = workspace:Raycast(dari, Vector3.new(0, -2000, 0), rayParams)
            if r and r.Material == Enum.Material.Water then
                return true
            end
            return false
        end
        local airA = cekAir(dasarA)
        local airB = cekAir(dasarB)

        -- ===== KASUS 1: KEDUA TIANG DI AIR → garis lurus saja =====
        if airA and airB then
            local poinLurus = {tA.topPos, tB.topPos}
            -- simpan poin tersimpan supaya persisten saat reload
            k.poinTersimpan = poinLurus
            for i = 1, #poinLurus - 1 do
                local warnaG = (i % 2 == 0) and Warna.Biru2 or Warna.Ungu2
                local prt = buatSegmen(poinLurus[i], poinLurus[i + 1], warnaG, nil, folderDunia)
                if prt then table.insert(k.parts, prt) end
            end
            -- auto-save ke file
            simpanKeFileTiang()
            return
        end

        -- ===== KASUS 2: IKUT KONTUR TANAH + RINTANGAN =====
        local jarak = (Vector3.new(dasarB.X, 0, dasarB.Z)
            - Vector3.new(dasarA.X, 0, dasarA.Z)).Magnitude
        -- sample sangat rapat (1 stud) supaya kontur halus + kena semua rintangan
        local jumlahSampel = math.clamp(math.ceil(jarak), 2, 800)
        -- TINGGI SCAN 1000 stud supaya raycast mulai di atas SEMUA rintangan
        -- (sebelumnya 250 stud — kalau gunung > 250 stud, tidak terdeteksi)
        local tinggiAtas = math.max(tA.topPos.Y, tB.topPos.Y) + 1000
        local poin = {tA.topPos}
        local yTerakhir = tA.topPos.Y
        for i = 1, jumlahSampel - 1 do
            local t = i / jumlahSampel
            local titik = dasarA:Lerp(dasarB, t)
            local dari = Vector3.new(titik.X, tinggiAtas, titik.Z)
            -- raycast vertikal dari Y tinggi ke bawah, panjang = tinggiAtas + 500
            local ray = workspace:Raycast(dari, Vector3.new(0, -(tinggiAtas + 500), 0), rayParams)
            local y
            if ray then
                -- AMBIL Y apa pun yang kena (tanah, batu, gunung es, air)
                -- JANGAN skip air di mode kontur — biar garis tidak menembus rintangan
                y = ray.Position.Y + CFG.ANGKAT_GARIS
            else
                y = yTerakhir
            end
            yTerakhir = y
            table.insert(poin, Vector3.new(titik.X, y, titik.Z))
        end
        table.insert(poin, tB.topPos)
        if myGen ~= genPath then return end
        -- tolerance kecil = 0.05 stud supaya kontur naik/turun tetap detail
        local poinRapi = sederhanakan(poin, 0.05)
        -- SIMPAN titik-titik yang sudah dihitung ke koneksi
        -- supaya saat masuk sesi lagi, garis 100% sama tanpa re-scan
        k.poinTersimpan = poinRapi
        for i = 1, #poinRapi - 1 do
            local warnaG = (i % 2 == 0) and Warna.Biru2 or Warna.Ungu2
            local prt = buatSegmen(poinRapi[i], poinRapi[i + 1], warnaG, nil, folderDunia)
            if prt then table.insert(k.parts, prt) end
        end
        -- auto-save ke file setelah hitung selesai
        simpanKeFileTiang()
    end)
end

local function hancurkanPartsKoneksi(k)
    for _, prt in ipairs(k.parts or {}) do
        prt:Destroy()
    end
    k.parts = {}
end

local function rebuildGaris()
    genPath += 1
    for _, k in ipairs(koneksiAktif) do
        hancurkanPartsKoneksi(k)
    end
    task.wait()
    for _, k in ipairs(koneksiAktif) do
        bangunGarisKoneksi(k)
    end
end

-- [15c] PERSISTENSI TIANG -------------------------------------------
-- r2: round to 2 decimal places (untuk simpan Vector3 ke JSON)
local function r2(n) return math.floor(n * 100 + 0.5) / 100 end

local function simpanKeFileTiang()
    if not fileOk then return end
    local data = {games = {}}
    local isi
    pcall(function() isi = readfile(CFG.NAMA_FILE_TIANG) end)
    if type(isi) == "string" and #isi > 0 then
        local lama
        pcall(function() lama = HttpService:JSONDecode(isi) end)
        if type(lama) == "table" and type(lama.games) == "table" then
            data.games = lama.games
        end
    end
    local entri = {}
    local daftarT = {}
    for _, t in ipairs(daftarTiang) do
        table.insert(daftarT, {
            id   = t.id,
            nama = t.nama,
            cf   = {t.cframe:GetComponents()},
        })
    end
    entri.tiang = daftarT
    local daftarK = {}
    for _, k in ipairs(koneksiAktif) do
        local poinJson = nil
        -- simpan titik-titik poin yang sudah dihitung (Vector3 → {x,y,z})
        -- supaya saat masuk sesi lagi, garis 100% sama tanpa re-scan
        if k.poinTersimpan and #k.poinTersimpan > 0 then
            poinJson = {}
            for _, p in ipairs(k.poinTersimpan) do
                table.insert(poinJson, {
                    r2(p.X), r2(p.Y), r2(p.Z)
                })
            end
        end
        table.insert(daftarK, {a = k.a, b = k.b, poin = poinJson})
    end
    entri.koneksi = daftarK
    -- records dihapus v1.3 (tab RECORD dihapus)
    data.games[tostring(game.PlaceId)] = entri
    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if ok and type(json) == "string" then
        pcall(function()
            local isiLama = readfile(CFG.NAMA_FILE_TIANG)
            if type(isiLama) == "string" and #isiLama > 0 then
                writefile(CFG.NAMA_FILE_TIANG_B, isiLama)
            end
        end)
        pcall(function() writefile(CFG.NAMA_FILE_TIANG, json) end)
    end
end

-- [15d] PASANG / HAPUS TIANG ----------------------------------------
pasangTiang = function(namaManual)
    local char, hrp = getKarakter()
    if not hrp then
        toast("⚠️ Karakter belum siap", Warna.Merah)
        return
    end
    local basePos
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {char, folderDunia}
    local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), rp)
    if ray then
        basePos = ray.Position + Vector3.new(0, 0.05, 0)
    else
        basePos = hrp.Position - Vector3.new(0, 3, 0)
    end
    local nama = (namaManual or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if nama == "" then
        local namaNama = {}
        for _, t in ipairs(daftarTiang) do table.insert(namaNama, t.nama) end
        nama = "Tiang " .. nomorBebas("Tiang", namaNama)
    end
    local nomor = #daftarTiang + 1
    local model, batang = buatTiangVisual(basePos, nomor)
    table.insert(daftarTiang, {
        id     = idBaru(),
        nama   = nama,
        cframe = CFrame.new(basePos),
        topPos = basePos + Vector3.new(0, CFG.TIANG_TINGGI, 0),
        model  = model,
        batang = batang,
        pilih  = false,
    })
    simpanKeFileTiang()
    refreshListTiang(true)
    scrollTiang.CanvasPosition = Vector2.new(0, 1e6)
    bunyi(CFG.SND_SNAP, 0.4)
    konfeti(root, pusatDiRoot(saveBtnTiang), 12)
    emojiBurst(root, pusatDiRoot(saveBtnTiang), {"📍", "⚡", "✨"}, 5)
    toast("➕ " .. nama .. " terpasang • total " .. #daftarTiang, Warna.Ungu)
end

local function hapusTiang(idx)
    local t = daftarTiang[idx]
    if not t then return end
    local nama = t.nama
    genPath += 1
    for i = #koneksiAktif, 1, -1 do
        local k = koneksiAktif[i]
        if k.a == t.id or k.b == t.id then
            hancurkanPartsKoneksi(k)
            table.remove(koneksiAktif, i)
        end
    end
    if t.model then t.model:Destroy() end
    table.remove(daftarTiang, idx)
    perbaruiNomor()
    simpanKeFileTiang()
    toast("🗑️ Dihapus: " .. nama, Warna.Merah)
    refreshListTiang(true)
end

local function hapusSemuaTiang()
    genPath += 1
    for _, k in ipairs(koneksiAktif) do
        hancurkanPartsKoneksi(k)
    end
    table.clear(koneksiAktif)
    for _, t in ipairs(daftarTiang) do
        if t.model then t.model:Destroy() end
    end
    table.clear(daftarTiang)
    simpanKeFileTiang()
    toast("🧹 Semua tiang dihapus", Warna.Merah)
    refreshListTiang(true)
end

local function tiangTerpilih()
    local hasil = {}
    for _, t in ipairs(daftarTiang) do
        if t.pilih then table.insert(hasil, t) end
    end
    return hasil
end

local function bersihkanPilihanTiang()
    for _, t in ipairs(daftarTiang) do t.pilih = false end
    refreshListTiang(false)
end

-- [15e] REFRESH LIST TIANG ------------------------------------------
refreshListTiang = function(animasi)
    if not scrollTiang then return end
    for _, c in ipairs(scrollTiang:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local q = searchBoxTiang.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    local daftar = {}
    for _, lok in ipairs(daftarTiang) do
        if q == "" or lok.nama:lower():find(q, 1, true) then
            table.insert(daftar, lok)
        end
    end
    listLabelTiang.Text = (q ~= "" and "🔍 HASIL" or "📍 TIANG")
        .. string.format(" • %d  (klik nomor = pilih)", #daftar)

    if #daftar == 0 then
        local kosong = buat("Frame", {
            Size = UDim2.new(1, -6, 1, 0), BackgroundTransparency = 1,
        }, scrollTiang)
        local ring = buat("Frame", {
            Name = "NoFade", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(46, 46),
            BackgroundTransparency = 1, BorderSizePixel = 0,
        }, kosong)
        buat("UICorner", {CornerRadius = UDim.new(1, 0)}, ring)
        local ringS = buat("UIStroke", {Color = Warna.Ungu, Thickness = 2, Transparency = 0.4}, ring)
        tween(ringS, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.9})
        tween(ring, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.fromOffset(58, 58)})
        local pin = buat("TextLabel", {
            Name = "NoFade", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(40, 40),
            BackgroundTransparency = 1, Font = Enum.Font.SourceSans,
            Text = "📍", TextSize = 30,
        }, kosong)
        task.spawn(function()
            while pin.Parent do
                tween(pin, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 0, 34)})
                task.wait(0.9)
                if not pin.Parent then break end
                tween(pin, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 0, 40)})
                task.wait(0.9)
            end
        end)
        buat("TextLabel", {
            Position = UDim2.new(0, 10, 0, 82),
            Size = UDim2.new(1, -20, 0, 40),
            BackgroundTransparency = 1,
            FontFace = fnt("med"),
            Text = q ~= "" and ('Tidak ada hasil untuk "' .. q .. '"')
                or "Belum ada tiang.\nTekan [Y] atau klik ➕ PASANG.",
            TextColor3 = Warna.AbuTeks,
            TextSize = 12,
            TextWrapped = true,
        }, kosong)
        kumpulkanFade()
        return
    end

    for i, lok in ipairs(daftar) do
        local item = buat("Frame", {
            Size = UDim2.new(1, -6, 0, 36),
            BackgroundColor3 = Warna.AbuItem,
            BorderSizePixel = 0,
            LayoutOrder = i,
        }, scrollTiang)
        buat("UICorner", {CornerRadius = UDim.new(0, 9)}, item)

        if animasi then
            local sc = buat("UIScale", {Scale = 0.6}, item)
            task.delay(0.05 * i, function()
                if item.Parent then
                    tween(sc, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
                end
            end)
        end

        item.MouseEnter:Connect(function()
            tween(item, TweenInfo.new(0.12), {BackgroundColor3 = Warna.UnguMuda})
        end)
        item.MouseLeave:Connect(function()
            tween(item, TweenInfo.new(0.12), {BackgroundColor3 = Warna.AbuItem})
        end)

        local badge = buat("TextButton", {
            Position = UDim2.new(0, 8, 0.5, -9),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = lok.pilih and Warna.Hijau2 or Warna.Putih,
            BorderSizePixel = 0,
            FontFace = fnt("bold"),
            Text = tostring(i),
            TextColor3 = Warna.Putih,
            TextSize = 11,
            AutoButtonColor = false,
        }, item)
        buat("UICorner", {CornerRadius = UDim.new(1, 0)}, badge)
        local badgeGrad = buat("UIGradient", {
            Color = lok.pilih
                and ColorSequence.new(Warna.Hijau2, Warna.Hijau)
                or  ColorSequence.new(Warna.Ungu, Warna.Biru),
            Rotation = i % 2 == 0 and 25 or -25,
        }, badge)
        buat("UIStroke", {
            Color = Warna.Hijau2,
            Thickness = 2,
            Transparency = tiangPunyaKoneksi(lok.id) and 0 or 1,
        }, badge)

        badge.MouseButton1Click:Connect(function()
            lok.pilih = not lok.pilih
            badge.BackgroundColor3 = lok.pilih and Warna.Hijau2 or Warna.Putih
            badgeGrad.Color = lok.pilih
                and ColorSequence.new(Warna.Hijau2, Warna.Hijau)
                or  ColorSequence.new(Warna.Ungu, Warna.Biru)
            bunyi(CFG.SND_PING, 0.2, lok.pilih and 1.3 or 0.9)
        end)

        local nameEdit = buat("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 32, 0, 0),
            Size = UDim2.new(1, -150, 1, 0),
            FontFace = fnt("med"),
            Text = lok.nama,
            TextColor3 = Warna.TeksGelap,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
        }, item)
        nameEdit.MouseEnter:Connect(function()
            tween(nameEdit, TweenInfo.new(0.12), {BackgroundTransparency = 0.85})
        end)
        nameEdit.MouseLeave:Connect(function()
            if not nameEdit:IsFocused() then
                tween(nameEdit, TweenInfo.new(0.12), {BackgroundTransparency = 1})
            end
        end)
        nameEdit.Focused:Connect(function() nameEdit.BackgroundTransparency = 0.85 end)
        nameEdit.FocusLost:Connect(function()
            nameEdit.BackgroundTransparency = 1
            local baru = nameEdit.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if baru ~= "" and baru ~= lok.nama then
                lok.nama = baru
                simpanKeFileTiang()
            elseif baru == "" then
                nameEdit.Text = lok.nama
            end
        end)

        if tiangPunyaKoneksi(lok.id) then
            buat("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -148, 0.5, -8),
                Size = UDim2.fromOffset(16, 16),
                Font = Enum.Font.SourceSans,
                Text = "🔗",
                TextSize = 12,
            }, item)
        end

        local tpBtn = buat("TextButton", {
            Size = UDim2.fromOffset(46, 26),
            Position = UDim2.new(1, -110, 0.5, -13),
            BackgroundColor3 = Warna.Putih,
            BorderSizePixel = 0,
            FontFace = fnt("bold"),
            Text = "🚀 TP",
            TextColor3 = Warna.Putih,
            TextSize = 11,
            AutoButtonColor = false,
        }, item)
        buat("UICorner", {CornerRadius = UDim.new(0, 7)}, tpBtn)
        ledSweep(tpBtn, Warna.Biru, Warna.Putih, Warna.Ungu2, 2.2)
        tpBtn.MouseButton1Click:Connect(function()
            ripple(tpBtn, Warna.Putih)
            teleportKe(lok.cframe.Position)
            fxTeleport()
            toast("🚀 Teleport ke " .. lok.nama, Warna.Biru)
        end)

        local delBtn = buat("TextButton", {
            Size = UDim2.fromOffset(26, 26),
            Position = UDim2.new(1, -34, 0.5, -13),
            BackgroundColor3 = Warna.Merah,
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            FontFace = fnt("reg"),
            Text = "🗑️",
            TextSize = 12,
            AutoButtonColor = false,
        }, item)
        buat("UICorner", {CornerRadius = UDim.new(0, 7)}, delBtn)
        buat("UIStroke", {Color = Warna.Merah, Thickness = 1, Transparency = 0.4}, delBtn)
        delBtn.MouseButton1Click:Connect(function()
            ripple(delBtn, Warna.Merah)
            bunyi(CFG.SND_SNAP, 0.3, 0.7)
            local sc = item:FindFirstChildOfClass("UIScale")
            tween(item, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
            if sc then tween(sc, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.6}) end
            task.delay(0.17, function()
                local idx = table.find(daftarTiang, lok)
                if idx then hapusTiang(idx) end
            end)
        end)

        efekTombol(tpBtn)
        efekTombol(delBtn, 1.1)
    end
    kumpulkanFade()
end

-- [17] MUAT FILE TIANG (RECORD dihapus v1.3) -------------------------
local function muatDariFileTiang()
    if not fileOk then return end
    local isi
    pcall(function() isi = readfile(CFG.NAMA_FILE_TIANG) end)
    if type(isi) ~= "string" or #isi == 0 then return end
    local data
    pcall(function() data = HttpService:JSONDecode(isi) end)
    if type(data) ~= "table" or type(data.games) ~= "table" then return end
    local entri = data.games[tostring(game.PlaceId)]
    if type(entri) ~= "table" then return end
    local daftarT, daftarK = {}, {}
    if type(entri.tiang) == "table" then
        daftarT = entri.tiang
        if type(entri.koneksi) == "table" then daftarK = entri.koneksi end
    else
        daftarT = entri
    end
    for _, e in ipairs(daftarT) do
        if type(e) == "table" and type(e.nama) == "string"
        and type(e.cf) == "table" and #e.cf >= 12 then
            local ok, cf = pcall(CFrame.new, table.unpack(e.cf, 1, 12))
            if ok and cf then
                local nomor = #daftarTiang + 1
                local model, batang = buatTiangVisual(cf.Position, nomor)
                table.insert(daftarTiang, {
                    id     = tostring(e.id or e.nama),
                    nama   = e.nama,
                    cframe = cf,
                    topPos = cf.Position + Vector3.new(0, CFG.TIANG_TINGGI, 0),
                    model  = model,
                    batang = batang,
                    pilih  = false,
                })
            end
        end
    end
    perbaruiNomor()
    -- helper: bangun segmen dari array poin Vector3 (tanpa re-scan)
    local function bangunDariPoin(k, poinVec)
        if not poinVec or #poinVec < 2 then return false end
        k.poinTersimpan = poinVec
        for i = 1, #poinVec - 1 do
            local warnaG = (i % 2 == 0) and Warna.Biru2 or Warna.Ungu2
            local prt = buatSegmen(poinVec[i], poinVec[i + 1], warnaG, nil, folderDunia)
            if prt then table.insert(k.parts, prt) end
        end
        return true
    end

    for _, k in ipairs(daftarK) do
        if type(k) == "table" and type(k.a) == "string" and type(k.b) == "string"
        and tiangDariId(k.a) and tiangDariId(k.b)
        and not koneksiAntara(k.a, k.b) then
            local koneksi = {a = k.a, b = k.b, parts = {}, poinTersimpan = nil}
            -- PRIORITY 1: pakai poin tersimpan jika ada (garis 100% sama, NO re-scan)
            local pakaiTersimpan = false
            if type(k.poin) == "table" and #k.poin >= 2 then
                local poinVec = {}
                local valid = true
                for _, p in ipairs(k.poin) do
                    if type(p) == "table" and #p >= 3
                    and type(p[1]) == "number" and type(p[2]) == "number" and type(p[3]) == "number" then
                        table.insert(poinVec, Vector3.new(p[1], p[2], p[3]))
                    else
                        valid = false
                        break
                    end
                end
                if valid and #poinVec >= 2 then
                    pakaiTersimpan = bangunDariPoin(koneksi, poinVec)
                end
            end
            table.insert(koneksiAktif, koneksi)
            -- PRIORITY 2: fallback re-scan (data lama tanpa poin)
            if not pakaiTersimpan then
                bangunGarisKoneksi(koneksi)
            end
        end
    end
    -- jika ada koneksi tanpa poin tersimpan (data lama), rebuildGaris akan handle
    -- (sudah dipanggil via bangunGarisKoneksi di atas)
end

muatDariFileTiang()
-- [18] LOGIKA KING (TANPA CAHAYA) -----------------------------------
-- SPEED & JUMP
applySpeed = function()
    local hum = getHum()
    if not hum then return end
    local base = State.SpeedOn and State.SpeedValue or CFG.OFF_SPEED
    if State.ShiftOn and State.IsSwimming then
        base = base * 1.10
    end
    hum.WalkSpeed = base
end
applyJump = function()
    local hum = getHum()
    if not hum then return end
    if hum.UseJumpPower then
        hum.JumpPower = State.JumpOn and State.JumpValue or CFG.OFF_JUMP
    else
        hum.JumpHeight = State.JumpOn and State.JumpHeightValue or CFG.OFF_JUMP_H
    end
end
updateJumpLabel = function()
    local hum = getHum()
    if JumpLabel then
        JumpLabel.Text = (hum and hum.UseJumpPower) and "JumpPower" or "JumpHeight (auto)"
    end
    if RefreshJump then RefreshJump() end
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
    if not v then
        task.spawn(function()
            for _ = 1, 8 do
                task.wait(0.25)
                if State.SpeedOn or State.Removed then return end
                local h = getHum()
                if h and h.WalkSpeed ~= CFG.OFF_SPEED then
                    h.WalkSpeed = CFG.OFF_SPEED
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
                    if h.UseJumpPower and h.JumpPower ~= CFG.OFF_JUMP then
                        h.JumpPower = CFG.OFF_JUMP
                    elseif not h.UseJumpPower and h.JumpHeight ~= CFG.OFF_JUMP_H then
                        h.JumpHeight = CFG.OFF_JUMP_H
                    end
                end
            end
        end)
    end
    syncNotify("Jump", v, silent, "JumpPower")
end

-- SHIFTLOCK MOBILE
Setters.Shift = function(v, silent)
    if State.ShiftOn == v then return end
    State.ShiftOn = v
    if v then
        local hum = getHum()
        if hum then hum.AutoRotate = false end
        RunService:BindToRenderStep("KS_SHIFTLOCK", Enum.RenderPriority.Character.Value + 1, function()
            local char = getChar()
            local h = char and char:FindFirstChildOfClass("Humanoid")
            local r = char and char:FindFirstChild("HumanoidRootPart")
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

-- MOONWALK (G) — badan TERKUNCI menghadap kamera/layar saat jalan
Setters.Moon = function(v, silent)
    if State.MoonOn == v then return end
    State.MoonOn = v
    if v then
        local hum = getHum()
        if hum then hum.AutoRotate = false end
        RunService:BindToRenderStep("KS_MOONWALK", Enum.RenderPriority.Character.Value + 1, function()
            local char = getChar()
            local h = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.Health > 0 then
                local cam = Workspace.CurrentCamera
                if cam then
                    local _, yaw = cam.CFrame:ToOrientation()
                    -- putar 180 derajat = badan menghadap kamera
                    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw + math.pi, 0)
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

-- HIDE PLAYER + KENDARAAN
local hiddenParts, hiddenBB, hiddenHumans, hiddenCharConns = {}, {}, {}, {}
local function hideApplyTo(obj)
    if (obj:IsA("BasePart") or obj:IsA("Decal")) and hiddenParts[obj] == nil then
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
    for _, part in ipairs(Workspace:GetPartBoundsInRadius(r.Position, 20, overlapParams)) do
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
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.4)
        if State.HideOn and not State.Removed then hideCharacter(char) end
    end)
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

-- LIGHTWEIGHT (Partikel / Bayangan / Efek)
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
local wallConn
local function isWallCandidate(part)
    if not part:IsA("BasePart") or part == Terrain then return false end
    if part.Transparency < 1 then return false end
    if not part.CanCollide then return false end
    local m = part:FindFirstAncestorOfClass("Model")
    if m and Players:GetPlayerFromCharacter(m) then return false end
    return true
end
local function wallify(part)
    if wallOriginal[part] then return end
    wallOriginal[part] = {Transparency = part.Transparency, Color = part.Color}
    part.Transparency = 0.35
    part.Color = Color3.fromRGB(205, 205, 205)
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
        table.clear(wallOriginal)
    end
    syncNotify("Walls", v, silent, "Dinding Batas")
end

-- CAHAYA AUTO (auto brightness berdasarkan waktu game)
Setters.Light = function(v, silent)
    if State.LightOn == v then return end
    State.LightOn = v
    if v then
        -- capture original first
        oLight.Brightness = Lighting.Brightness
        oLight.Ambient = Lighting.Ambient
        oLight.OutdoorAmbient = Lighting.OutdoorAmbient
        -- start loop
        if lightConn then task.cancel(lightConn) end
        lightConn = task.spawn(function()
            while State.LightOn and not State.Removed do
                local t = Lighting.ClockTime
                if t >= 18 or t < 6 then
                    -- malam: terangkan
                    Lighting.Brightness = 3
                    Lighting.Ambient = Color3.fromRGB(140, 140, 165)
                    Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 165)
                else
                    -- siang: sedikit naik dari default
                    Lighting.Brightness = 1
                    Lighting.Ambient = Color3.fromRGB(110, 110, 120)
                    Lighting.OutdoorAmbient = Color3.fromRGB(110, 110, 120)
                end
                task.wait(5)
            end
        end)
    else
        if lightConn then task.cancel(lightConn) lightConn = nil end
        pcall(function()
            Lighting.Brightness = oLight.Brightness
            Lighting.Ambient = oLight.Ambient
            Lighting.OutdoorAmbient = oLight.OutdoorAmbient
        end)
    end
    syncNotify("Light", v, silent, "Cahaya Auto")
end

-- SMART FALL ASSIST v3.1 "VIRTUAL BRANCH"
-- Jatuh normal kencang -> sekali di 80% perjalanan:
-- platform tak terlihat muncul 4 stud di bawah kaki ->
-- karakter MENDARAT BENERAN (reset penghitung jatuh) ->
-- 0.15 detik kemudian platform hilang -> jatuh sisa pendek
Setters.Fall = function(v, silent)
    if State.FallOn == v then return end
    State.FallOn = v
    if v then
        if fallState.conn then return end  -- sudah jalan
        fallState.conn = RunService.Heartbeat:Connect(function()
            if not State.FallOn or State.Removed then return end
            local char, hum, hrp = getKarakter()
            if not hum or not hrp then return end
            local now = os.clock()
            local vel = hrp.AssemblyLinearVelocity
            local st
            pcall(function() st = hum:GetState() end)

            if st == Enum.HumanoidStateType.Freefall and vel.Y < -4 then
                if not fallState.jatuh then
                    fallState.jatuh = true
                    fallState.apex = hrp.Position.Y
                    fallState.bentur = false
                    fallState.sejak = now
                    fallState.groundY = nil
                    fallState.lastRay = 0
                end
                fallState.apex = math.max(fallState.apex, hrp.Position.Y)
                local sudahTurun = fallState.apex - hrp.Position.Y

                -- update cache ketinggian tanah: 10Hz saat jauh, tiap frame saat dekat
                if sudahTurun > 10 and vel.Y < -40 then
                    local dekat = (fallState.groundY ~= nil) and (hrp.Position.Y - fallState.groundY) < 60
                    if dekat or (now - fallState.lastRay) >= 0.1 then
                        fallState.lastRay = now
                        local filter = {workspace:FindFirstChild("TiangPath_Silau")}
                        if char then table.insert(filter, char) end
                        fallRay.FilterDescendantsInstances = filter
                        local r = workspace:Raycast(hrp.Position, Vector3.new(0, -800, 0), fallRay)
                        if r then fallState.groundY = r.Position.Y else fallState.groundY = nil end
                    end
                end

                local tinggiTotal, sisaJatuh
                if fallState.groundY then
                    sisaJatuh = hrp.Position.Y - fallState.groundY
                    tinggiTotal = fallState.apex - fallState.groundY
                end

                -- VIRTUAL BRANCH: sekali per jatuh di posisi bentur
                if not fallState.bentur and sudahTurun > 10 and vel.Y < -40 then
                    local picu = false
                    if tinggiTotal and tinggiTotal >= cfgFall.minJatuh
                    and sisaJatuh <= tinggiTotal * (1 - cfgFall.posisi) then
                        picu = true
                    end
                    if not picu and not tinggiTotal and (now - fallState.sejak) > 0.6 and vel.Y < -70 then
                        picu = true
                    end
                    if picu then
                        fallState.bentur = true
                        pcall(function()
                            local plat = Instance.new("Part")
                            plat.Name = "Branch"
                            plat.Size = Vector3.new(6, 0.4, 6)
                            plat.Transparency = 1
                            plat.Anchored = true
                            plat.CanCollide = true
                            plat.CanQuery = false
                            plat.CanTouch = false
                            plat.CastShadow = false
                            plat.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 4, hrp.Position.Z)
                            plat.Parent = workspace
                            task.delay(0.15, function()
                                pcall(function() plat:Destroy() end)
                            end)
                        end)
                    end
                end
            elseif fallState.jatuh then
                fallState.jatuh = false
                fallState.bentur = false
            end
        end)
    else
        if fallState.conn then
            fallState.conn:Disconnect()
            fallState.conn = nil
        end
        fallState.jatuh = false
        fallState.bentur = false
    end
    syncNotify("Fall", v, silent, "Smart Fall Assist")
end

-- RESET & REJOIN
resetAll = function()
    setFeature("Speed", false, true)
    setFeature("Jump", false, true)
    setFeature("Shift", false, true)
    setFeature("Moon", false, true)
    setFeature("Hide", false, true)
    setFeature("LW", false, true)
    setFeature("Walls", false, true)
    setFeature("Light", false, true)
    setFeature("Fall", false, true)
    State.SpeedValue, State.JumpValue, State.JumpHeightValue = CFG.DEFAULT_SPEED, CFG.DEFAULT_JUMP, 7.2
    if RefreshSpeed then RefreshSpeed() end
    if RefreshJump then RefreshJump() end
    toast("🔄 Reset: semua OFF (Speed 17 / Jump 51.25)", Warna.Biru)
end
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

-- HAPUS SCRIPT
unloadScript = function()
    if State.Removed then return end
    State.Removed = true
    setFeature("Speed", false, true)
    setFeature("Jump", false, true)
    setFeature("Shift", false, true)
    setFeature("Moon", false, true)
    setFeature("Hide", false, true)
    setFeature("LW", false, true)
    setFeature("Walls", false, true)
    setFeature("Light", false, true)
    setFeature("Fall", false, true)
    RunService:UnbindFromRenderStep("KS_SHIFTLOCK")
    RunService:UnbindFromRenderStep("KS_MOONWALK")
    if lightConn then task.cancel(lightConn) lightConn = nil end
    if fallState.conn then fallState.conn:Disconnect() fallState.conn = nil end
    pcall(function()
        Lighting.Brightness = oLight.Brightness
        Lighting.Ambient = oLight.Ambient
        Lighting.OutdoorAmbient = oLight.OutdoorAmbient
    end)
    pcall(function() screenGui:Destroy() end)
    _G.__SILAU_NEON_MAIN__ = nil
    pcall(function()
        if script and script.Parent then
            script.Disabled = true
            script:Destroy()
        end
    end)
end

-- KARAKTER: PASANG ULANG SAAT RESPAWN
local initedChar
local function initCharacter(char)
    if State.Removed then return end
    if initedChar == char then return end
    initedChar = char
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    updateJumpLabel()
    hum.StateChanged:Connect(function(_, newState)
        local swimming = (newState == Enum.HumanoidStateType.Swimming)
        if swimming ~= State.IsSwimming then
            State.IsSwimming = swimming
            if State.ShiftOn then applySpeed() end
        end
    end)
    task.wait(0.25)
    if State.Removed then return end
    if State.SpeedOn then applySpeed() end
    if State.JumpOn then applyJump() end
    if State.ShiftOn then hum.AutoRotate = false end
end
LocalPlayer.CharacterAdded:Connect(initCharacter)
task.spawn(function()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    initCharacter(c)
end)

Players.PlayerAdded:Connect(playerHideHook)
for _, plr in ipairs(Players:GetPlayers()) do playerHideHook(plr) end
Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then unhideCharacter(plr.Character) end
end)

task.spawn(function()
    while not State.Removed do
        if State.HideOn then pcall(updateVehicles) end
        task.wait(0.3)
    end
end)

-- [19] BUKA / TUTUP GUI ---------------------------------------------
local sesiAnim = 0
local function minimizeGui()
    if not root.Visible then return end
    sesiAnim += 1
    local id = sesiAnim
    bunyi(CFG.SND_PING, 0.3, 0.75)
    -- icon minimize DIHAPUS — GUI sembunyi total, buka lewat F
    local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tween(panelScale, ti, {Scale = 0.5})
    tween(root, ti, {Rotation = 8})
    tween(fadeVal, ti, {Value = 1})
    task.delay(0.22, function()
        if sesiAnim ~= id then return end
        root.Visible = false
        root.Rotation = 0
        panelScale.Scale = 1
        fadeVal.Value = 0
    end)
end

local function bukaGui()
    sesiAnim += 1
    bunyi(CFG.SND_PING, 0.35, 1.15)
    root.Visible = true
    root.Rotation = -8
    panelScale.Scale = 0.6
    fadeVal.Value = 1
    setFade(1)
    tween(root, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0})
    tween(panelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    tween(fadeVal, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Value = 0})
    konfeti(root, UDim2.new(0.5, 0, 0.5, 0), 12)
    emojiBurst(root, UDim2.new(0.5, 0, 0.5, 0), {"✨", "⚡", "💜", "💙"}, 6)
end

togglePanel = function()
    if root.Visible then minimizeGui() else bukaGui() end
end

-- [20] KONEKSI UI ---------------------------------------------------
minBtn.MouseButton1Click:Connect(function()
    ripple(minBtn, Warna.Ungu2)
    minimizeGui()
end)
buatDraggable(header, root)

-- TAB TIANG
saveBtnTiang.MouseButton1Click:Connect(function()
    ripple(saveBtnTiang, Warna.Putih)
    local teks = nameBoxTiang.Text
    pasangTiang(teks)
    nameBoxTiang.Text = ""
    nameBoxTiang:ReleaseFocus()
end)
nameBoxTiang.FocusLost:Connect(function(enter)
    if enter then
        local teks = nameBoxTiang.Text
        pasangTiang(teks)
        nameBoxTiang.Text = ""
    end
end)
searchBoxTiang:GetPropertyChangedSignal("Text"):Connect(function() refreshListTiang(false) end)
sorotInput(nameBoxTiang, nameStrokeTiang, 0.5)
sorotInput(searchBoxTiang, searchStrokeTiang, 0.6)
efekTombol(saveBtnTiang)
efekTombol(btnBersih)
efekTombol(btnGaris)
efekTombol(btnSambung)
efekTombol(btnPutus)
-- btnPulihkan & btnTPSelected dihapus v1.4

local bersihSiap = false
btnBersih.MouseButton1Click:Connect(function()
    if #daftarTiang == 0 then
        toast("⚠️ Tidak ada tiang untuk dihapus", Warna.Merah)
        return
    end
    if not bersihSiap then
        bersihSiap = true
        btnBersih.Text = "❗ YAKIN? KLIK LAGI"
        btnBersih.BackgroundColor3 = Warna.Merah
        bunyi(CFG.SND_SNAP, 0.3, 0.8)
        task.delay(3, function()
            bersihSiap = false
            if btnBersih.Parent then
                btnBersih.Text = "🧹 HAPUS SEMUA"
                btnBersih.BackgroundColor3 = Warna.Putih
            end
        end)
    else
        bersihSiap = false
        btnBersih.Text = "🧹 HAPUS SEMUA"
        btnBersih.BackgroundColor3 = Warna.Putih
        bunyi(CFG.SND_SNAP, 0.35, 0.6)
        hapusSemuaTiang()
    end
end)

btnGaris.MouseButton1Click:Connect(function()
    if #koneksiAktif == 0 then
        toast("⚠️ Belum ada koneksi untuk dihitung ulang", Warna.Merah)
        return
    end
    bunyi(CFG.SND_PING, 0.3, 1.2)
    rebuildGaris()
    toast("↺ " .. #koneksiAktif .. " garis dihitung ulang", Warna.Biru)
end)

btnSambung.MouseButton1Click:Connect(function()
    local pilih = tiangTerpilih()
    if #pilih < 2 then
        toast("⚠️ Klik nomor 2 tiang dulu (jadi hijau)", Warna.Merah)
        return
    end
    local dibuat, sudah = 0, 0
    for i = 2, #pilih do
        local A, B = pilih[i - 1], pilih[i]
        if koneksiAntara(A.id, B.id) then
            sudah += 1
        else
            table.insert(koneksiAktif, {a = A.id, b = B.id, parts = {}})
            bangunGarisKoneksi(koneksiAktif[#koneksiAktif])
            dibuat += 1
        end
    end
    simpanKeFileTiang()
    bersihkanPilihanTiang()
    bunyi(CFG.SND_PING, 0.3, 1.3)
    if dibuat > 0 then
        local pesan = "🔗 " .. dibuat .. " garis dibuat"
        if sudah > 0 then pesan = pesan .. " • " .. sudah .. " sudah ada" end
        toast(pesan, Warna.Hijau2)
    else
        toast("⚠️ Semua pasangan sudah terhubung", Warna.Merah)
    end
end)

btnPutus.MouseButton1Click:Connect(function()
    local pilih = tiangTerpilih()
    if #pilih ~= 2 then
        toast("⚠️ Pilih tepat 2 tiang untuk putus", Warna.Merah)
        return
    end
    local k = koneksiAntara(pilih[1].id, pilih[2].id)
    if not k then
        toast("⚠️ Dua tiang ini tidak terhubung", Warna.Merah)
        return
    end
    genPath += 1
    hancurkanPartsKoneksi(k)
    local i = table.find(koneksiAktif, k)
    if i then table.remove(koneksiAktif, i) end
    simpanKeFileTiang()
    bersihkanPilihanTiang()
    bunyi(CFG.SND_SNAP, 0.35, 0.7)
    toast("✂️ Koneksi diputus", Warna.Merah)
end)

-- (blok btnPulihkan & btnTPSelected caller dihapus v1.4 — TP pakai tombol 🚀 per-row)

-- [21] KEYBIND ------------------------------------------------------
local lastK = 0
catat(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if State.Removed then return end
    if input.KeyCode == CFG.TOGGLE_KEY then
        togglePanel()
    elseif input.KeyCode == CFG.PASANG_KEY then
        pasangTiang(nameBoxTiang.Text)
        nameBoxTiang.Text = ""
    elseif input.KeyCode == Enum.KeyCode.G then
        setFeature("Moon", not State.MoonOn)
    elseif input.KeyCode == Enum.KeyCode.Q then
        setFeature("Speed", not State.SpeedOn)
    elseif input.KeyCode == Enum.KeyCode.C then
        setFeature("Shift", not State.ShiftOn)
    elseif input.KeyCode == Enum.KeyCode.R then
        setFeature("Hide", not State.HideOn)
    elseif input.KeyCode == Enum.KeyCode.X then
        setFeature("Walls", not State.WallsOn)
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

-- [22] MULAI --------------------------------------------------------
refreshListTiang(false)
setTab(1)  -- KING jadi tab pertama
task.delay(0.15, bukaGui)

task.delay(1.2, function()
    if #daftarTiang > 0 then
        toast("📂 Tiang: " .. #daftarTiang .. " • koneksi " .. #koneksiAktif, Warna.Ungu)
    end
    if not fileOk then
        toast("⚠️ Penyimpanan file tidak tersedia", Warna.Merah)
    end
end)

print("[SilauNeon v" .. VERSI .. "] SIAP ✔ — F = GUI | Y = pasang tiang | Q/C/G/R/X/T/K = KING")
print("[SilauNeon] 2 TAB: 👑 KING | 🗄️ TIANG (Speed/Jump/Shift/Moonwalk/Hide/LW/Walls/Cahaya/Fall)")
print("[SilauNeon] Penyimpanan: " .. (fileOk
    and ("Tiang='" .. CFG.NAMA_FILE_TIANG .. "' (per game: " .. game.PlaceId .. ")")
    or "TIDAK TERSEDIA"))

end -- akhir initLogic()

-- Eksekusi initLogic() sekarang (UI + helpers sudah siap dari part1-3)
initLogic()
