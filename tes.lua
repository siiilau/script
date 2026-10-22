--========================================================
--  BALAP v1.1 — Script Balapan Gabungan
--
--  TEMA: SILAU NEON (ungu/biru LED)
--
--  3 TAB:
--    1 🏃 GERAK  : Speed, Jump, Shiftlock, Moonwalk, Fall Assist, Anti-AFK
--    2 🎨 VISUAL : Hide, Hide Pemain Lain, Cahaya Auto 2 arah, Lightweight, Dinding Batas
--    3 ⚙️ SISTEM : Layar PC, reset, rejoin, hapus script
--
--  BARU v1.1 — 🖥️ LAYAR PC:
--    Tampilan dikunci seperti di PC 24/27/32 inci walau main di device
--    apapun (laptop/HP/tablet): UI game di-scale + FOV lebar (opsional).
--    Default aktif: PC 27" (UI 82% + FOV 74°).
--
--  Keybind:
--    F = buka/tutup GUI (saat tutup = hilang total)
--    Q = Speed ON/OFF (nilai ON dipilih di panel: 17.25-21.25)
--    J = JumpPower (51.25 ⇄ 65.25)    C = Shiftlock Mobile
--    G = Moonwalk    B = Smart Fall Assist    R = Hide
--    T = Cahaya Auto (2 arah)    X = Dinding Batas
--    N = Layar PC: cycle 24" → 27" → 32" → OFF
--    K = Rejoin (double-tap)
--========================================================
local VERSI = "1.1"

-- [1] PENGAMAN DASAR -----------------------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
    warn("[BALAP] GAGAL: harus jalan di CLIENT (executor / LocalScript), bukan server!")
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
    warn("[BALAP] GAGAL: LocalPlayer belum ada.")
    return
end
local Terrain = Workspace:WaitForChild("Terrain")

-- anti double-run
if _G.__BALAP_MAIN__ then return end
_G.__BALAP_MAIN__ = true

-- [2] KONFIGURASI ---------------------------------------------------
-- Semua konstanta digabung ke dalam 1 table CFG untuk hemat local count
-- (Luau limit 200 local per function)
local CFG = {
    ICON_SIZE       = 36,
    TOGGLE_KEY      = Enum.KeyCode.F,
    LED_TEXT        = "⚡ B A L A P ⚡",
    SOUND_ON        = true,
    FX_LEVEL        = 1,
    -- Speed cycle 3 state (17.10 → 17.25 → 21.25 → balik OFF)
    SPEED_OFF   = 17.10,
    SPEED_ON_1  = 17.25,
    SPEED_ON_2  = 21.25,
    -- Jump: OFF 51.25 ⇄ ON 65.25 (kondisional UseJumpPower / JumpHeight)
    OFF_JUMP    = 51.25,
    ON_JUMP     = 65.25,
    OFF_JUMP_H  = 6.69,
    ON_JUMP_H   = 8.50,
    SND_PING   = "rbxasset://sounds/electronicpingshort.wav",
    SND_SNAP   = "rbxasset://sounds/snap.mp3",
}
-- Preset Layar PC (baru v1.1): emulasi monitor besar supaya tampilan
-- konsisten seperti di PC walau main dari device apapun.
-- ui  = faktor scale UI game (makin kecil = terasa monitor makin besar)
-- fov = FieldOfView kamera saat "Lebar Pandang" aktif (70 = normal)
local PC_MODES = {
    [0] = { nama = "OFF",     ui = 1.00, fov = 70 },
    [1] = { nama = "PC 24\"", ui = 0.92, fov = 70 },
    [2] = { nama = "PC 27\"", ui = 0.82, fov = 74 },
    [3] = { nama = "PC 32\"", ui = 0.72, fov = 78 },
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
local RefreshSpeed, RefreshJump, JumpLabel, SpeedLabel, AfkLabel
local cfgFall, oLight, fallState, fallRay, lightConn
local PCBtns, PCStatus, updatePCStatus  -- UI Layar PC (di-expose via buildUI)
local notifHolder                        -- di-expose via buildFX (dipakai Layar PC)

-- Forward declare untuk part3 (FX/footer/icon) — di-expose via buildFX()
local konfeti, emojiBurst, pusatDiRoot, toast
local kumpulkanFade, setFade, fadeVal

-- Forward declare untuk part2 (UI builder) — di-expose via buildUI()
local tabBtns, kontenTabs, setTab
local kontenKing, scrollKing, kontenVisual, scrollVisual
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
local function getKarakter()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

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

-- [7] BANGUN UI: ROOT + OUTER + PANEL -------------------------------
local screenFx = buat("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 900,
}, screenGui)
-- screenFx akan di-akses lintas part (untuk FX overlay teleport)
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
    Text = "⚡ BALAP v1.1 ⚡",
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

-- [7b] TAB BAR (3 TAB) ----------------------------------------------
-- Bungkus dengan function untuk hemat local count (Luau limit 200)
local function buildUI()
tabBtns = {}
local tabLabels = {"🏃 GERAK", "🎨 VISUAL", "⚙️ SISTEM"}
local tabColors = {Warna.Ungu2, Warna.Biru, Warna.AbuGelap}
kontenTabs = {}
for i, lbl in ipairs(tabLabels) do
    local tab = buat("TextButton", {
        Size = UDim2.new(1 / 3, -3.4, 0, 24),
        Position = UDim2.new((i - 1) * (1 / 3), 3.5 + (i - 1) * 2, 0, 50),
        BackgroundColor3 = (i == 1) and tabColors[i] or Warna.AbuMuda,
        BorderSizePixel = 0,
        FontFace = fnt("bold"),
        Text = lbl,
        TextColor3 = (i == 1) and Warna.Putih or Warna.AbuTeks,
        TextSize = 10,
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

-- [7c] KONTEN TAB 1: GERAK ------------------------------------------
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

-- ===== baris generik (dipakai tab GERAK / VISUAL / SISTEM) =====
local function buatHeader(parent, text)
    return buat("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        FontFace = fnt("bold"),
        TextSize = 11,
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
local function buatActionRow(parent, text, color, callback)
    local btn = buat("TextButton", {
        BackgroundColor3 = color,
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = nextOrder(),
        FontFace = fnt("bold"),
        TextSize = 12,
        TextColor3 = Warna.Putih,
        Text = text,
        AutoButtonColor = false,
    }, parent)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
    btn.MouseButton1Click:Connect(callback)
    efekTombol(btn, 1.03)
    return btn
end

-- ===== init State KING (dibuat SEBELUM baris toggle) =====
State.SpeedOn = false
State.SpeedValue = CFG.SPEED_ON_1
State.JumpOn  = false
State.JumpValue = CFG.ON_JUMP
State.JumpHeightValue = CFG.ON_JUMP_H
State.ShiftOn = false
State.IsSwimming = false
State.HideOn  = false
State.LWOn    = false
State.WallsOn = false
State.PlayersOn = false  -- Hide Pemain Lain (baru v2.2)
State.LightOn = false
State.FallOn  = false
State.MoonOn  = false  -- Moonwalk (G)
State.AfkOn   = true   -- Anti-AFK (port dari A, default ON)
State.PCFovOn = true   -- Layar PC: ikutkan lebar pandang (FOV) — PCMode di-set saat MULAI

-- Config Fall Assist v3.1 "VIRTUAL BRANCH" (nilai baru spec §7)
cfgFall = {
    minJatuh = 35,
    posisi   = 0.70,
}

-- Original Lighting (untuk restore saat cahaya dimatikan)
oLight = {
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    ExposureCompensation = Lighting.ExposureCompensation,
    FogEnd = Lighting.FogEnd,
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

-- ===== baris TAB 1: GERAK =====
buatHeader(scrollKing, "Player")
local _, speedLbl = buatToggleRow(scrollKing, "Speed (Q): OFF (17.10)", "Q", "Speed")
SpeedLabel = speedLbl
-- Nilai ON dipilih via stepper: rentang 17.25 - 21.25 (Q = ON/OFF saja)
RefreshSpeed = buatStepperRow(
    scrollKing,
    "Speed",
    function() return State.SpeedValue end,
    function(v)
        State.SpeedValue = math.clamp(v, CFG.SPEED_ON_1, CFG.SPEED_ON_2)
        if State.SpeedOn then applySpeed() end
        if SpeedLabel and SpeedLabel.Parent then
            SpeedLabel.Text = "Speed (Q): " .. (State.SpeedOn and fmtNum(State.SpeedValue) or ("OFF (" .. fmtNum(CFG.SPEED_OFF) .. ")"))
        end
    end
)
local _, jumpLabelRow = buatToggleRow(scrollKing, "JumpPower", "J", "Jump")
JumpLabel = jumpLabelRow
RefreshJump = buatStepperRow(
    scrollKing,
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
buatToggleRow(scrollKing, "Shiftlock Mobile", "C", "Shift")
buatToggleRow(scrollKing, "Moonwalk", "G", "Moon")
buatHeader(scrollKing, "Anti AFK")
local _, afkLbl = buatToggleRow(scrollKing, "👻 Anti-AFK (2 lapis)", nil, "Afk")
AfkLabel = afkLbl
buatHeader(scrollKing, "Jatuh Cerdas")
buatToggleRow(scrollKing, "Smart Fall Assist", "B", "Fall")

-- King number row (untuk pengaturan fall assist — number row tetap ada)
local function buatNumRow(parent, labelText, default, cb)
    local row = buat("Frame", {
        BackgroundColor3 = Warna.AbuItem,
        Size = UDim2.new(1, 0, 0, 30),
        LayoutOrder = nextOrder(),
    }, parent)
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
buatNumRow(scrollKing, "MIN JATUH (stud)", cfgFall.minJatuh, function(n) cfgFall.minJatuh = n end)
buatNumRow(scrollKing, "POSISI BENTUR (0-1)", cfgFall.posisi, function(n)
    if n > 0 and n < 1 then cfgFall.posisi = n end
end)

-- [7d] KONTEN TAB 2: VISUAL -----------------------------------------
kontenVisual = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
}, panel)
table.insert(kontenTabs, kontenVisual)
scrollVisual = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 2),
    Size = UDim2.new(1, -24, 1, -6),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Ungu,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, kontenVisual)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollVisual)
buatHeader(scrollVisual, "Visual")
buatToggleRow(scrollVisual, "Hide Player + Kendaraan", "R", "Hide")
buatToggleRow(scrollVisual, "Hide Pemain Lain", nil, "Players")
buatToggleRow(scrollVisual, "Cahaya Auto (2 arah)", "T", "Light")
buatHeader(scrollVisual, "Lightweight")
buatToggleRow(scrollVisual, "Partikel / Bayangan / Efek", nil, "LW")
buatHeader(scrollVisual, "Map")
buatToggleRow(scrollVisual, "Dinding Batas", "X", "Walls")

-- [7g] KONTEN TAB 3: SISTEM -----------------------------------------
kontenSistem = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
}, panel)
table.insert(kontenTabs, kontenSistem)
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
buatHeader(scrollSistem, "Info")
local infoVersi = buat("TextLabel", {
    BackgroundColor3 = Warna.AbuItem,
    Size = UDim2.new(1, 0, 0, 76),
    FontFace = fnt("med"),
    TextSize = 11,
    TextColor3 = Warna.TeksGelap,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Text = "⚡ BALAP v1.1\n"
        .. "Script balapan gabungan — fitur dinding skrip lain melebur di sini\n"
        .. "3 TAB: 🏃 GERAK | 🎨 VISUAL | ⚙️ SISTEM\n"
        .. "Keybind: F panel • Q speed • J jump • C shift • G moon\n"
        .. "B fall • R hide • T cahaya • X dinding • N layar PC • K×2 rejoin\n"
        .. "🖥️ Layar PC: emulasi monitor 24/27/32\" di device apapun (default 27\")",
    LayoutOrder = nextOrder(),
}, scrollSistem)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, infoVersi)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, infoVersi)

-- ===== section 🖥️ LAYAR PC (baru v1.1) =====
buatHeader(scrollSistem, "Layar PC")
PCStatus = buat("TextLabel", {
    BackgroundColor3 = Warna.AbuItem,
    Size = UDim2.new(1, 0, 0, 22),
    FontFace = fnt("med"),
    TextSize = 11,
    TextColor3 = Warna.Ungu,
    TextXAlignment = Enum.TextXAlignment.Left,
    Text = "Aktif: PC 27\" • UI 82% • FOV 74°",
    LayoutOrder = nextOrder(),
}, scrollSistem)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, PCStatus)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10)}, PCStatus)
local pcRow = buat("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 30),
    LayoutOrder = nextOrder(),
}, scrollSistem)
buat("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, pcRow)
PCBtns = {}
for i, pc in ipairs({{n = 1, label = "24\""}, {n = 2, label = "27\""}, {n = 3, label = "32\""}, {n = 0, label = "OFF"}}) do
    local b = buat("TextButton", {
        BackgroundColor3 = Warna.AbuItem,
        Size = UDim2.new(0.25, -7, 1, 0),
        FontFace = fnt("bold"),
        TextSize = 11,
        Text = pc.label,
        TextColor3 = Warna.AbuTeks,
        AutoButtonColor = false,
        LayoutOrder = i,
    }, pcRow)
    buat("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
    efekTombol(b, 1.05)
    PCBtns[pc.n] = b
    b.MouseButton1Click:Connect(function()
        ripple(b, Warna.Putih)
        setFeature("PCScreen", pc.n)
    end)
end
buatToggleRow(scrollSistem, "Lebar Pandang (FOV)", nil, "PCFov")
updatePCStatus = function()
    if not PCStatus or not PCStatus.Parent then return end
    local mode = State.PCMode or 0
    local m = PC_MODES[mode]
    if mode > 0 then
        local fovTxt = (State.PCFovOn and m.fov ~= 70) and (" • FOV " .. m.fov .. "°") or " • FOV normal"
        PCStatus.Text = "Aktif: " .. m.nama .. " • UI " .. math.floor(m.ui * 100 + 0.5) .. "%" .. fovTxt
    else
        PCStatus.Text = "Layar normal (tanpa emulasi PC)"
    end
    if PCBtns then
        for n, b in pairs(PCBtns) do
            local aktif = (n == mode)
            b.BackgroundColor3 = aktif and Warna.Ungu or Warna.AbuItem
            b.TextColor3 = aktif and Warna.Putih or Warna.AbuTeks
        end
    end
end
updatePCStatus()

buatHeader(scrollSistem, "Aksi")
buatActionRow(scrollSistem, "🔄 RESET SCRIPT", Warna.Biru, function() resetAll() end)
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
buatHeader(scrollSistem, "Tentang")
local infoKredit = buat("TextLabel", {
    BackgroundColor3 = Warna.AbuItem,
    Size = UDim2.new(1, 0, 0, 58),
    FontFace = fnt("med"),
    TextSize = 11,
    TextColor3 = Warna.AbuTeks,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Text = "Tema SILAU NEON (ungu/biru LED) ⚡\n"
        .. "Basis: SILAU BALAPAN v1.1 (5 skrip digabung)\n"
        .. "v1.0.1: rename BALAP — 3 tab fokus balapan\n"
        .. "v1.1: 🖥️ Layar PC — emulasi monitor 24/27/32\" + FOV (keybind N)",
    LayoutOrder = nextOrder(),
}, scrollSistem)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, infoKredit)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, infoKredit)

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
    Size = UDim2.fromOffset(1600, 13),
    FontFace = fnt("med"),
    Text = "⌨ F = GUI   ✦   🏃 Q Speed ON/OFF (nilai ON 17.25-21.25 di panel) • J Jump (51.25/65.25) • C Shift • G Moonwalk • B FallAssist   ✦   🎨 R Hide • Hide Pemain Lain • T Cahaya 2-arah • X Dinding • LW   ✦   🖥️ N Layar PC (24/27/32\") • K×2 rejoin • Notif kanan atas",
    TextColor3 = Warna.AbuGelap,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, marqueeClip)
tween(marquee, TweenInfo.new(24, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Position = UDim2.fromOffset(-1600, 0)})

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
notifHolder = buat("Frame", {
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

end -- akhir buildFX()

-- Eksekusi buildFX() sekarang (panel, root, outer sudah ada dari part1)
buildFX()

-- [14] LOGIKA UTAMA -------------------------------------------------
-- Bungkus part logika dengan function untuk hemat local count (Luau limit 200)
local function initLogic()


-- [17C] MESIN ANTI-AFK 2 LAPIS — port dari A ------------------------
-- Lapis 1: VirtualUser CaptureController + ClickButton2 (event Idled + jadwal)
-- Lapis 2: gerakan mikro (opsional, jumpMode)
local AFK_CFG = {
    interval     = 240,   -- detik antar intervensi terjadwal (4 menit)
    jitter       = 60,    -- + acak, biar polanya tidak kaku
    jumpMode     = false, -- ubah ke true HANYA kalau game punya anti-AFK sendiri
    jumpInterval = 45,
}
local afkState = { aktif = State.AfkOn, jumlah = 0, terakhir = 0, sudahIngatkan = false }
local inputTerakhir = os.time()
catat(UserInputService.InputBegan:Connect(function() inputTerakhir = os.time() end))
local function afkStatusUpdate()
    if AfkLabel and AfkLabel.Parent then
        if afkState.aktif then
            if afkState.terakhir > 0 then
                AfkLabel.Text = string.format("👻 Anti-AFK (2 lapis) • %dx • %dm lalu",
                    afkState.jumlah, math.floor((os.time() - afkState.terakhir) / 60))
            else
                AfkLabel.Text = string.format("👻 Anti-AFK (2 lapis) • %dx • siaga", afkState.jumlah)
            end
        else
            AfkLabel.Text = "👻 Anti-AFK (2 lapis) • MATI"
        end
    end
end
local function afkIntervensi(alasan)
    local ok = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    if not ok then
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(5, 5, 1, true, game, 0)
            vim:SendMouseButtonEvent(5, 5, 1, false, game, 0)
        end)
    end
    afkState.jumlah += 1
    afkState.terakhir = os.time()
    print("[BALAP][Anti-AFK] intervensi #" .. afkState.jumlah .. " (" .. tostring(alasan) .. ")")
    afkStatusUpdate()
end
catat(LocalPlayer.Idled:Connect(function()
    if afkState.aktif then afkIntervensi("event Idled") end
end))

-- lapis 1: jadwal berkala (hanya kalau user lama tidak input apa pun)
task.spawn(function()
    while screenGui.Parent do
        if afkState.aktif then
            local tunggu = AFK_CFG.interval + rnd(0, AFK_CFG.jitter)
            task.wait(tunggu)
            if afkState.aktif and screenGui.Parent
            and (os.time() - inputTerakhir) >= AFK_CFG.interval then
                afkIntervensi("jadwal " .. tunggu .. "s")
            end
        else
            task.wait(2)
        end
    end
end)

-- lapis 2: gerakan mikro (default OFF, aktifkan via jumpMode)
if AFK_CFG.jumpMode then
    task.spawn(function()
        while screenGui.Parent do
            task.wait(AFK_CFG.jumpInterval)
            if afkState.aktif then
                local _, _, hum = getKarakter()
                if hum and hum.Health > 0 then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jump) end)
                end
            end
        end
    end)
end

-- refresh tampilan status anti-afk tiap 30 detik
task.spawn(function()
    while screenGui.Parent do
        task.wait(30)
        afkStatusUpdate()
    end
end)

-- [18] LOGIKA KING ---------------------------------------------------
-- SPEED & JUMP
applySpeed = function()
    local hum = getHum()
    if not hum then return end
    local base = State.SpeedOn and State.SpeedValue or CFG.SPEED_OFF
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

-- label Speed menampilkan nilai state saat ini (ON/OFF, nilai via stepper)
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

-- HIDE PEMAIN LAIN (baru v2.2 — toggle terpisah dari Hide R)
-- Hanya pemain lain (tanpa kendaraan), pakai LocalTransparencyModifier
-- supaya tidak konflik dengan fitur Hide (R) yang memakai Transparency.
-- LTM bisa di-reset kamera/respawn -> loop penjaga Heartbeat tiap ~0.3s.
local plrHideConn, plrHideT = nil, 0
local function plrHideSapu(on)
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            for _, d in ipairs(pl.Character:GetDescendants()) do
                pcall(function()
                    if d:IsA("BasePart") or d:IsA("Decal") then
                        d.LocalTransparencyModifier = on and 1 or 0
                    elseif d:IsA("Humanoid") and not (not on and State.HideOn) then
                        -- saat OFF, jangan ganggu Humanoid kalau Hide (R) masih pegang kendali
                        d.DisplayDistanceType = on and Enum.HumanoidDisplayDistanceType.None
                            or Enum.HumanoidDisplayDistanceType.Viewer
                        d.HealthDisplayType = on and Enum.HumanoidHealthDisplayType.AlwaysOff
                            or Enum.HumanoidHealthDisplayType.WhenDamaged
                    end
                end)
            end
        end
    end
end
Setters.Players = function(v, silent)
    if State.PlayersOn == v then return end
    State.PlayersOn = v
    if v then
        plrHideSapu(true)
        plrHideT = 0
        plrHideConn = RunService.Heartbeat:Connect(function(dt)
            if not State.PlayersOn or State.Removed then return end
            plrHideT = plrHideT + dt
            if plrHideT >= 0.3 then
                plrHideT = 0
                plrHideSapu(true)
            end
        end)
    else
        if plrHideConn then plrHideConn:Disconnect() plrHideConn = nil end
        plrHideSapu(false)
    end
    syncNotify("Players", v, silent, "Hide Pemain Lain")
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

-- DINDING BATAS (upgrade: lihat dinding tak terlihat -> jalur tipis gampang dicari)
-- Dinding invisible (CanCollide + nyaris transparan) dibikin kelihatan:
--   isi abu gelap tembus pandang (60%) + garis tepi, jadi dinding se tipis
--   apa pun tetap kebaca dari jauh. Tanpa bikin part baru -> tetap ringan.
local wallOriginal = {}
local wallBoxes = {}   -- part -> SelectionBox (garis tepi)
local wallConn
local WALL_ISI  = Color3.fromRGB(70, 70, 70)    -- isi abu gelap
local WALL_TEPI = Color3.fromRGB(150, 150, 150) -- garis tepi abu sedang
local function isWallCandidate(part)
    if not part:IsA("BasePart") or part == Terrain then return false end
    if part.Transparency < 0.95 then return false end  -- tangkap juga yang "hampir" tak terlihat
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
        box.Parent = part   -- ikut terhapus otomatis kalau part-nya dihancurkan game
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

-- CAHAYA AUTO DUA ARAH (baru v2.0 — pengganti Auto Terang lama dari E)
-- Malam (< 6 atau >= 18) → terangi   : ClockTime ≈ 14, Brightness naik ≈ 2.5, fog gelap dibuka
-- Siang                  → gelapkan  : ClockTime ≈ 17.5 (senja lembut), Brightness ≈ 1.6 (anti-silau)
-- Loop penjaga tiap ~2 detik; saat OFF semua nilai asli di-restore.
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

-- ClockTime wrap 0-24: jangan di-tween mentah — step bertahap via loop task.wait
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
        -- capture original first (ClockTime/Brightness/Exposure/FogEnd disimpan semua)
        oLight.Brightness = Lighting.Brightness
        oLight.Ambient = Lighting.Ambient
        oLight.OutdoorAmbient = Lighting.OutdoorAmbient
        oLight.ClockTime = Lighting.ClockTime
        oLight.ExposureCompensation = Lighting.ExposureCompensation
        oLight.FogEnd = Lighting.FogEnd
        -- turunkan fog gelap bila ada (biar malam yang diterangi tidak berkabut)
        if Lighting.FogEnd < 5000 then
            Lighting.FogEnd = CAHAYA.FOG_BUKA
        end
        if lightConn then task.cancel(lightConn) end
        lightConn = task.spawn(function()
            while State.LightOn and not State.Removed do
                langkahCahaya()
                -- loop penjaga: tiap ~2 detik cek ClockTime lagi
                -- (kalau game mengubah jam ke malam saat ON → otomatis diterangi lagi,
                --  kalau ke siang terik → digelapkan sedikit lagi)
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

-- SMART FALL ASSIST v3.1 "VIRTUAL BRANCH"
-- Jatuh normal kencang -> sekali di posisi bentur (0.70) perjalanan:
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
                        fallRay.FilterDescendantsInstances = char and {char} or {}
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

-- ANTI-AFK (port dari A) — toggle via Tab 1, sinkron dengan afkState
Setters.Afk = function(v, silent)
    State.AfkOn = v
    afkState.aktif = v
    if v then afkState.sudahIngatkan = false end
    afkStatusUpdate()
    syncNotify("Afk", v, silent, "Anti-AFK")
end

-- Q — Speed ON/OFF murni (v2.1)
-- Nilai ON (17.25 / 21.25, atau di antaranya) dipilih via stepper di Tab GERAK.
-- Keybind Q langsung panggil setFeature("Speed", ...) dari handler [21].

-- LAYAR PC (baru v1.1) — emulasi monitor 24/27/32" di device apapun
-- 1) Scale UI game (PlayerGui) + best-effort UI Roblox (CoreGui: chat/playerlist/topbar)
-- 2) Lebar pandang FOV opsional (PC 27" = 74°, PC 32" = 78°)
-- 3) Panel & notif BALAP ikut diskalakan biar tampilan konsisten
-- Catatan: panelScale dipakai animasi buka/tutup, jadi scale PC pakai UIScale terpisah.
local pcScalePanel, pcScaleNotif
local pcInjected = {}
do
    if Original.FOV == nil then
        local cam0 = Workspace.CurrentCamera
        Original.FOV = (cam0 and cam0.FieldOfView) or 70
    end
    pcScalePanel = buat("UIScale", {Name = "BalapPCScale", Scale = 1}, root)
    pcScaleNotif = buat("UIScale", {Name = "BalapPCScale", Scale = 1}, notifHolder)

    local function applyFovPC()
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local mode = State.PCMode or 0
        local m = PC_MODES[mode]
        local target = Original.FOV or 70
        if mode > 0 and State.PCFovOn and m.fov ~= 70 then target = m.fov end
        pcall(function() cam.FieldOfView = target end)
    end

    local function pasangScaleGui(gui, faktor, allowRoblox)
        if not gui or State.Removed then return end
        if not (gui:IsA("LayerCollector") or gui:IsA("GuiObject")) then return end
        local nm = gui.Name or ""
        if nm == "BalapMain" then return end
        if not allowRoblox and nm:sub(1, 6) == "Roblox" then return end
        local s = gui:FindFirstChild("BalapPCScale")
        if s and s:IsA("UIScale") then
            s.Scale = faktor
            if not table.find(pcInjected, s) then table.insert(pcInjected, s) end
            return
        end
        pcall(function()
            local ns = Instance.new("UIScale")
            ns.Name = "BalapPCScale"
            ns.Scale = faktor
            ns.Parent = gui
            table.insert(pcInjected, ns)
        end)
    end

    local function bersihkanPC()
        for _, s in ipairs(pcInjected) do
            pcall(function() if s and s.Parent then s:Destroy() end end)
        end
        table.clear(pcInjected)
        if pcScalePanel then pcScalePanel.Scale = 1 end
        if pcScaleNotif then pcScaleNotif.Scale = 1 end
    end

    local function sapuPC()
        if (State.PCMode or 0) == 0 or State.Removed then return end
        local faktor = PC_MODES[State.PCMode].ui
        -- semua ScreenGui milik game di PlayerGui
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            for _, c in ipairs(pg:GetChildren()) do
                pasangScaleGui(c, faktor, false)
            end
        end
        -- best-effort UI Roblox (kalau executor melarang, otomatis dilewati)
        pcall(function()
            local cg = game:GetService("CoreGui")
            for _, nm in ipairs({"RobloxGui", "PlayerListMaster", "Chat", "TextChat", "Backpack"}) do
                local c = cg:FindFirstChild(nm)
                if c then pasangScaleGui(c, faktor, true) end
            end
        end)
        if pcScalePanel then pcScalePanel.Scale = faktor end
        if pcScaleNotif then pcScaleNotif.Scale = faktor end
    end

    Setters.PCScreen = function(n, silent)
        n = tonumber(n) or 0
        if not PC_MODES[n] then n = 0 end
        if (State.PCMode or 0) == n and pcScalePanel and pcScalePanel.Parent then
            if updatePCStatus then updatePCStatus() end
            return
        end
        State.PCMode = n
        if n == 0 then
            bersihkanPC()
        else
            pcall(sapuPC)
        end
        pcall(applyFovPC)
        if updatePCStatus then updatePCStatus() end
        if not silent then
            toast("🖥️ Layar PC: " .. PC_MODES[n].nama, n > 0 and Warna.Biru or Warna.Merah)
        end
    end

    Setters.PCFov = function(v, silent)
        if State.PCFovOn == v then return end
        State.PCFovOn = v
        pcall(applyFovPC)
        if updatePCStatus then updatePCStatus() end
        syncNotify("PCFov", v, silent, "Lebar Pandang (FOV)")
    end

    -- Penjaga ringan: FOV dicek tiap 1 detik, sapu UI tiap 5 detik (hanya saat aktif)
    local pcTick = 0
    task.spawn(function()
        while screenGui.Parent and not State.Removed do
            if (State.PCMode or 0) > 0 then
                pcall(applyFovPC)
                pcTick += 1
                if pcTick >= 5 then
                    pcTick = 0
                    pcall(sapuPC)
                end
            end
            task.wait(1)
        end
    end)

    -- UI game baru muncul (popup/belanja) → pasang scale lagi
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            catat(pg.ChildAdded:Connect(function()
                if (State.PCMode or 0) == 0 or State.Removed then return end
                task.delay(0.6, function()
                    if (State.PCMode or 0) > 0 and not State.Removed then pcall(sapuPC) end
                end)
            end))
        end
    end)

    -- Respawn → UI game di-rebuild + kamera baru → terapkan ulang
    catat(LocalPlayer.CharacterAdded:Connect(function()
        if (State.PCMode or 0) == 0 or State.Removed then return end
        task.delay(1, function()
            if (State.PCMode or 0) > 0 and not State.Removed then
                pcall(sapuPC)
                pcall(applyFovPC)
            end
        end)
    end))
    catat(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.delay(0.25, function()
            if not State.Removed then pcall(applyFovPC) end
        end)
    end))
end

-- RESET & REJOIN
resetAll = function()
    setFeature("Speed", false, true)
    setFeature("Jump", false, true)
    setFeature("Shift", false, true)
    setFeature("Moon", false, true)
    setFeature("Hide", false, true)
    setFeature("Players", false, true)
    setFeature("LW", false, true)
    setFeature("Walls", false, true)
    setFeature("Light", false, true)
    setFeature("Fall", false, true)
    State.SpeedValue, State.JumpValue, State.JumpHeightValue = CFG.SPEED_ON_1, CFG.ON_JUMP, CFG.ON_JUMP_H
    if RefreshSpeed then RefreshSpeed() end
    if RefreshJump then RefreshJump() end
    updateSpeedLabel()
    toast("🔄 Reset: semua OFF (Speed " .. fmtNum(CFG.SPEED_OFF) .. " / Jump " .. fmtNum(CFG.OFF_JUMP) .. ")", Warna.Biru)
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

-- HAPUS SCRIPT — BERSIH TOTAL, TIDAK ADA YANG TERTINGGAL
unloadScript = function()
    if State.Removed then return end
    State.Removed = true
    -- 1) Matikan semua fitur (restore visual, kendaraan, dinding, cahaya, fall)
    pcall(setFeature, "Speed", false, true)
    pcall(setFeature, "Jump", false, true)
    pcall(setFeature, "Shift", false, true)
    pcall(setFeature, "Moon", false, true)
    pcall(setFeature, "Hide", false, true)
    pcall(setFeature, "Players", false, true)
    pcall(setFeature, "LW", false, true)
    pcall(setFeature, "Walls", false, true)
    pcall(setFeature, "Light", false, true)
    pcall(setFeature, "Fall", false, true)
    -- 2) Unbind semua RenderStep binding
    pcall(function() RunService:UnbindFromRenderStep("KS_SHIFTLOCK") end)
    pcall(function() RunService:UnbindFromRenderStep("KS_MOONWALK") end)
    -- 3) Cancel semua task/thread yang masih jalan
    if lightConn then pcall(function() task.cancel(lightConn) end) lightConn = nil end
    if fallState and fallState.conn then
        pcall(function() fallState.conn:Disconnect() end)
        fallState.conn = nil
    end
    -- 3) Disconnect SEMUA event yang di-catat lewat catat()
    for _, c in ipairs(semuaKoneksi) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(semuaKoneksi)
    -- 4) Restore Lighting ke kondisi awal (hanya kalau Cahaya pernah ON)
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
    -- 5) Restore Terrain water (kalau LW pernah diaktifkan)
    pcall(function()
        if Original then
            if Original.GlobalShadows ~= nil then Lighting.GlobalShadows = Original.GlobalShadows end
            if Original.WaterWaveSize ~= nil then Terrain.WaterWaveSize = Original.WaterWaveSize end
            if Original.WaterWaveSpeed ~= nil then Terrain.WaterWaveSpeed = Original.WaterWaveSpeed end
        end
    end)
    -- 5b) Restore Layar PC: hapus semua scale yang dipasang + balikin FOV asli
    pcall(function()
        State.PCMode = 0
        for _, s in ipairs(pcInjected) do
            pcall(function() if s.Parent then s:Destroy() end end)
        end
        table.clear(pcInjected)
        if pcScalePanel then pcScalePanel.Scale = 1 end
        if pcScaleNotif then pcScaleNotif.Scale = 1 end
        local cam = Workspace.CurrentCamera
        if cam and Original.FOV then cam.FieldOfView = Original.FOV end
    end)
    -- 6) Reset karakter: WalkSpeed, JumpPower, JumpHeight, AutoRotate
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local h = char:FindFirstChildOfClass("Humanoid")
            if h then
                h.WalkSpeed = 16
                if h.UseJumpPower then
                    h.JumpPower = 50
                else
                    h.JumpHeight = 7.2
                end
                h.AutoRotate = true
            end
        end
    end)
    -- 7) Restore player lain yang di-hide
    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                for _, d in ipairs(plr.Character:GetDescendants()) do
                    if d:IsA("BasePart") then
                        d.LocalTransparencyModifier = 0
                    elseif d:IsA("BillboardGui") then
                        d.Enabled = true
                    end
                end
                local h = plr.Character:FindFirstChildOfClass("Humanoid")
                if h then
                    h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
                end
            end
        end
    end)
    -- 8) Reset status label
    -- 9) Hapus ScreenGui (parent dari semua UI: panel, notif, footer, dll)
    pcall(function() if screenGui then screenGui:Destroy() end end)
    -- 10) Clear global flag supaya script bisa di-execute lagi
    _G.__BALAP_MAIN__ = nil
    _G.__KS_DELETE_ARMED__ = nil
    -- 11) Destroy script itu sendiri (kalau via LocalScript)
    pcall(function()
        if script and script.Parent then
            script.Disabled = true
            script:Destroy()
        end
    end)
    print("[BALAP] Script dihapus total — semua dibersihkan ✔")
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

-- [20] KONEKSI UI ----------------------------------------------------
minBtn.MouseButton1Click:Connect(function()
    ripple(minBtn, Warna.Ungu2)
    minimizeGui()
end)
buatDraggable(header, root)


-- [21] KEYBIND -------------------------------------------------------
local lastK = 0
catat(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if State.Removed then return end
    if input.KeyCode == CFG.TOGGLE_KEY then
        togglePanel()
    elseif input.KeyCode == Enum.KeyCode.Q then
        setFeature("Speed", not State.SpeedOn)
    elseif input.KeyCode == Enum.KeyCode.J then
        setFeature("Jump", not State.JumpOn)
    elseif input.KeyCode == Enum.KeyCode.C then
        setFeature("Shift", not State.ShiftOn)
    elseif input.KeyCode == Enum.KeyCode.G then
        setFeature("Moon", not State.MoonOn)
    elseif input.KeyCode == Enum.KeyCode.B then
        setFeature("Fall", not State.FallOn)
    elseif input.KeyCode == Enum.KeyCode.R then
        setFeature("Hide", not State.HideOn)
    elseif input.KeyCode == Enum.KeyCode.T then
        setFeature("Light", not State.LightOn)
    elseif input.KeyCode == Enum.KeyCode.X then
        setFeature("Walls", not State.WallsOn)
    elseif input.KeyCode == Enum.KeyCode.N then
        setFeature("PCScreen", (State.PCMode or 0) >= 3 and 0 or (State.PCMode or 0) + 1)
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

-- [22] MULAI ---------------------------------------------------------
afkStatusUpdate()
updateSpeedLabel()
setFeature("PCScreen", 2)  -- 🖥️ Layar PC 27" aktif otomatis (N untuk ganti)
setTab(1)  -- 🏃 GERAK jadi tab pertama
task.delay(0.15, bukaGui)
print("[BALAP v" .. VERSI .. "] SIAP ✔ — F = GUI | K×2 = rejoin")
print("[BALAP] 3 TAB: 🏃 GERAK | 🎨 VISUAL | ⚙️ SISTEM")
print("[BALAP] Keybind: Q speed ON/OFF (nilai di panel 17.25-21.25) • J jump (51.25/65.25) • C shift • G moonwalk")
print("[BALAP]           B fall assist • R hide • T cahaya 2-arah • X dinding • N layar PC • K×2 rejoin")
print("[BALAP] 🖥️ Layar PC 27\" aktif: UI game di-scale 82% + FOV 74° — N = ganti 24/27/32/OFF")
print("[BALAP] Fitur dinding (X) dari skrip lain sudah jadi 1 dengan script balapan")
end -- akhir initLogic()

-- Eksekusi initLogic() sekarang (UI + helpers sudah siap dari part1-4)
initLogic()
