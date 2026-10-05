--[[=============================================================
    ⛓️Siiilau⚡ - ALL-IN-ONE HUB (MERGED v1.8 — ⚡ PERFORMANCE FIX)
    =============================================================
    PERUBAHAN v1.8 (PERFORMANCE) :
      - BUKA/TUTUP INSTAN: F -> langsung muncul/hilang. TANPA animasi.
      - HAPUS semua sumber lag: breathing UIScale, loop cycleColor,
        partikel ambient, sparkle, kedip bracket, pulse glow,
        sistem bola/meteor
      - Sisa animasi hanya TweenService murni (murah, C++ side):
        LED sweep, border berputar, marquee
      - Freecam dioptimalkan (MouseBehavior tidak di-set tiap frame)
      - SEMUA FITUR UTUH & NORMAL: speed/jump/crosshair/info/hitbox/
        freecam/TP/hide/lowgfx/brightness/hotkeys/reset/keluar
    =============================================================
    MOVEMENT      : Speed & Swim [Q] | Jump Power | Scooshlock
    PLAYER DISPLAY: Info Other Players [C] | Hitbox Players
    CAMERA        : FREE CAM [CAPS LOCK] | Auto Brightness [T]
                    Kamera->Karakter [G] | TP Karakter->Kamera [C]
                    TP Jarak Mundur : BISA DIATUR (+/-)
    VISUAL        : Hide Other Players [R] | Hide All Effects
                    Low Graphic + No Fog
    HOTKEYS       : F=GUI | CAPSLOCK=Freecam | T=AutoBrightness
                    G=KeKarakter | C=TP Kamera/Info | Q=Speed | R=Hide
    ===============================================================]]

--═══════════════ KONFIG ═══════════════
local DEFAULT_SPEED = 17.25
local DEFAULT_JUMP  = 52.25
local STEP          = 0.25
local INFO_INTERVAL = 0.1
local INFO_MAX_DIST = 100
local LOCK_TIME     = true

local CONFIG = {
    KECEPATAN_NORMAL   = 30,
    KECEPATAN_CEPAT    = 85,
    SENSITIVITAS_MOUSE = 0.25,
    BATAS_PITCH        = 85,
    KEHALUSAN          = 10,
    INTERVAL_STREAM    = 1,
    DURASI_EFEK_MATI   = 0.6,
    JARAK_BELAKANG     = 10,
    TINGGI_KAMERA      = 4,
    SUDUT_TP           = -15,

    TP_JARAK_MUNDUR    = 3,
    TP_JARAK_STEP      = 0.5,
    TP_JARAK_MIN       = 0,
    TP_JARAK_MAKS      = 100,
}
local NAMA_BIND = "SiiilauFreecamRender"
local SOUND_ON  = true    -- ⚡ set false = tanpa suara
local FX_LED    = true    -- ⚡ set false = matikan LED sweep (hemat lagi)
local FX_PUTAR  = true    -- ⚡ set false = matikan border berputar
local UKURAN_GUI = 0.8    -- ukuran GUI 80%

--═══════════════ LAYANAN ═══════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
if not LocalPlayer then
    warn("[SiiilauHub] GAGAL: LocalPlayer belum ada. Masuk game dulu, lalu execute ulang.")
    return
end
local camera = Workspace.CurrentCamera

--═══════════════ TRACKING KONEKSI ═══════════════
local conns = {}
local function addConn(c) table.insert(conns, c) return c end

--═══════════════ SCREENGUI ═══════════════
local gui = Instance.new("ScreenGui")
gui.Name = "SiiilauHub"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.OnTopOfCoreBlur = true end)

local kandidatParent = {}
pcall(function() if gethui then table.insert(kandidatParent, gethui()) end end)
pcall(function() table.insert(kandidatParent, game:GetService("CoreGui")) end)
pcall(function() table.insert(kandidatParent, LocalPlayer:WaitForChild("PlayerGui")) end)

for _, t in ipairs(kandidatParent) do
    pcall(function()
        local lama = t:FindFirstChild("SiiilauHub")
        if lama then lama:Destroy() end
    end)
end

local terpasang = false
for _, t in ipairs(kandidatParent) do
    local ok = pcall(function() gui.Parent = t end)
    if ok and gui.Parent == t then
        terpasang = true
        break
    end
end
if not terpasang then
    warn("[SiiilauHub] GAGAL: tidak bisa memasang GUI.")
    return
end

--═══════════════ FONT KOMPATIBEL ═══════════════
local FONT_OK = pcall(function()
    return Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Regular)
end)
local cacheFont = {}
local function fnt(k)
    if cacheFont[k] then return cacheFont[k] end
    local v
    if FONT_OK then
        local fam = {
            judul = "rbxasset://fonts/families/Bangers.json",
            bold  = "rbxasset://fonts/families/Montserrat.json",
            semi  = "rbxasset://fonts/families/Montserrat.json",
            med   = "rbxasset://fonts/families/Montserrat.json",
        }
        local wts = {
            judul = Enum.FontWeight.Regular,
            bold  = Enum.FontWeight.Bold,
            semi  = Enum.FontWeight.SemiBold,
            med   = Enum.FontWeight.Medium,
        }
        v = Font.new(fam[k], wts[k])
    else
        local legacy = {
            judul = Enum.Font.Bangers,
            bold  = Enum.Font.GothamBold,
            semi  = Enum.Font.GothamSemibold,
            med   = Enum.Font.GothamMedium,
        }
        v = legacy[k]
    end
    cacheFont[k] = v
    return v
end
local TEKS_CLASS = {TextLabel = true, TextButton = true, TextBox = true}

--═══════════════ TEMA WARNA "SILAU NEON" ═══════════════
local C = {
    Hitam     = Color3.fromRGB(12, 10, 20),
    Hitam2    = Color3.fromRGB(22, 18, 38),
    Baris     = Color3.fromRGB(28, 24, 48),
    BarisHov  = Color3.fromRGB(41, 34, 72),
    offBg     = Color3.fromRGB(42, 24, 68),
    Ungu      = Color3.fromRGB(124, 58, 237),
    Ungu2     = Color3.fromRGB(167, 139, 250),
    UnguMuda  = Color3.fromRGB(237, 233, 254),
    UnguD     = Color3.fromRGB(88, 30, 150),
    Biru      = Color3.fromRGB(37, 99, 235),
    Biru2     = Color3.fromRGB(59, 130, 246),
    BiruMuda  = Color3.fromRGB(219, 234, 254),
    Putih     = Color3.fromRGB(255, 255, 255),
    Hijau     = Color3.fromRGB(0, 255, 90),
    Merah     = Color3.fromRGB(239, 68, 68),
    Abuk      = Color3.fromRGB(160, 155, 185),
    AbuTeks   = Color3.fromRGB(130, 125, 155),
}

--═══════════════ HELPER ═══════════════
local function new(class, props, parent)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k == "FontFace" and TEKS_CLASS[class] and not FONT_OK then
                inst.Font = v
            else
                inst[k] = v
            end
        end
    end
    inst.Parent = parent
    return inst
end
local function fmt(v) return string.format("%.2f", v) end
local function fmt2(v)
    if type(v) ~= "number" or v ~= v then return "0,00" end
    return (string.format("%.2f", v):gsub("%.", ","))
end
local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

-- 🔊 SUARA
local SND_PING   = "rbxasset://sounds/electronicpingshort.wav"
local SND_SNAP   = "rbxasset://sounds/snap.mp3"
local SND_WHOOSH = "rbxasset://sounds/unsheath.wav"
local function bunyi(id, vol, pitch)
    if not SOUND_ON then return end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = vol or 0.3
    s.PlaybackSpeed = pitch or 1
    s.Parent = gui
    s:Play()
    task.delay(3, function() s:Destroy() end)
end

-- 💡 LED SWEEP (TweenService murni — murah, tidak bikin stutter)
local function ledSweep(inst, base, bandA, bandB, dur)
    if not FX_LED then return nil end
    local g = new("UIGradient", {
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

-- 🌊 RIPPLE
local function ripple(btn, warna)
    btn.ClipsDescendants = true
    local c = new("Frame", {
        Name = "NoFade",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = warna or C.Putih,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, btn)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, c)
    local target = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.4
    tween(c, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromOffset(target, target), BackgroundTransparency = 1})
    task.delay(0.5, function() c:Destroy() end)
end

-- 🔍 EFEK TOMBOL (hover pop — hanya saat hover, tidak jalan terus)
local function efekTombol(btn, skalaHover)
    local s = new("UIScale", {Scale = 1}, btn)
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

-- ✨ EMOJI BURST (hanya dipanggil saat TP — sesaat, bukan loop)
local function emojiBurst(parent, pos, daftar, n)
    for _ = 1, n do
        local l = new("TextLabel", {
            Name = "NoFade",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = pos,
            Size = UDim2.fromOffset(24, 24),
            BackgroundTransparency = 1,
            Font = Enum.Font.SourceSans,
            Text = daftar[math.random(1, #daftar)],
            TextSize = math.random(14, 22),
            Rotation = math.random(-20, 20),
            ZIndex = 801,
        }, parent)
        local sudut = math.random(1, 360) * math.pi / 180
        local jarak = math.random(70, 160)
        local dur = math.random(60, 90) / 100
        tween(l, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(pos.X.Scale, pos.X.Offset + math.cos(sudut) * jarak,
                pos.Y.Scale, pos.Y.Offset + math.sin(sudut) * jarak - 40),
            Rotation = l.Rotation + math.random(-180, 180),
            TextTransparency = 1,
        })
        task.delay(dur + 0.05, function() l:Destroy() end)
    end
end

-- layer efek layar penuh (flash TP)
local screenFx = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    BorderSizePixel = 0, ZIndex = 900,
}, gui)

--═══════════════ BRIGHTNESS <-> JAM ═══════════════
local function brightnessFromTime(t)
    local d = math.clamp(math.sin((t - 6) / 12 * math.pi), 0, 1)
    return 0.5 + d * 2.5
end
local function formatClock(t)
    t = t % 24
    local h = math.floor(t)
    local m = math.floor((t - h) * 60 + 0.5)
    if m == 60 then h, m = h + 1, 0 end
    if h == 24 then h = 0 end
    return string.format("%02d:%02d", h, m)
end

--═══════════════ GUI UTAMA (SILAU NEON — 80%, RINGAN) ═══════════════
local main = new("Frame", {
    Size = UDim2.fromOffset(480, 800),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, BorderSizePixel = 0, Active = true,
    Visible = false,
}, gui)
local panelScale = new("UIScale", {Scale = UKURAN_GUI}, main)

local outer = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
    ClipsDescendants = true,   -- 🔒 semua isi ter-kunci di dalam frame
}, main)
new("UICorner", {CornerRadius = UDim.new(0, 18)}, outer)

-- border gradient berputar ⚡ (TweenService — murah)
local borderStroke = new("UIStroke", {Name = "NoFade", Color = C.Ungu, Thickness = 3}, outer)
if FX_PUTAR then
    local borderGrad = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, C.Ungu),
            ColorSequenceKeypoint.new(0.25, C.Biru),
            ColorSequenceKeypoint.new(0.50, C.Ungu2),
            ColorSequenceKeypoint.new(0.75, C.Biru2),
            ColorSequenceKeypoint.new(1.00, C.Ungu),
        }),
    }, borderStroke)
    tween(borderGrad, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = 360})
end

-- ring putih kedua ✦ (statis — tidak berputar, hemat)
local ring2 = new("UIStroke", {Name = "NoFade", Color = C.Putih, Thickness = 1, Transparency = 0.45}, outer)
if FX_PUTAR then
    local ring2Grad = new("UIGradient", {Color = ColorSequence.new(C.Ungu2, C.Biru2)}, ring2)
    tween(ring2Grad, TweenInfo.new(3.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = -360})
end

local panel = new("Frame", {
    Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5),
    BackgroundColor3 = C.Hitam2, BorderSizePixel = 0,
    ClipsDescendants = true,   -- 🔒 anti bocor
}, outer)
new("UICorner", {CornerRadius = UDim.new(0, 13)}, panel)
new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.55}, panel)
ledSweep(panel, C.Hitam2, C.Ungu, C.Biru, 5)

-- wadah garis diagonal statis (TANPA animasi — hemat)
local partBox = new("Frame", {
    Name = "PartBox", Position = UDim2.new(0, 4, 0, 52),
    Size = UDim2.new(1, -8, 1, -110), BackgroundTransparency = 1,
    BorderSizePixel = 0, ClipsDescendants = true,
}, panel)
for i = 1, 3 do
    new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.3 * i, 0, 0.5, 0), Size = UDim2.fromOffset(26, 500),
        Rotation = 24, BackgroundColor3 = i % 2 == 0 and C.BiruMuda or C.UnguMuda,
        BackgroundTransparency = 0.9, BorderSizePixel = 0,
    }, partBox)
end

-- HEADER / TITLE BAR
local title = new("Frame", {
    Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.Hitam,
    BorderSizePixel = 0, Active = true,
    ClipsDescendants = true,
}, panel)
new("UICorner", {CornerRadius = UDim.new(0, 13)}, title)
new("Frame", {
    Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 36),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
}, panel)

local judulLabel = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -70, 1, 0), FontFace = fnt("judul"),
    Text = "⛓️ S I I L A U ⚡", TextColor3 = C.Putih, TextSize = 24,
    TextXAlignment = Enum.TextXAlignment.Left,
}, title)
ledSweep(judulLabel, C.Putih, C.Ungu2, C.Biru2, 2.2)
-- glow statis (tanpa pulse loop)
new("UIStroke", {Name = "NoFade", Color = C.Ungu2, Thickness = 1, Transparency = 0.35}, judulLabel)

local minBtn = new("TextButton", {
    Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -40, 0.5, -14),
    BackgroundColor3 = C.Hitam2, BorderSizePixel = 0, AutoButtonColor = false,
    FontFace = fnt("bold"), Text = "–", TextColor3 = C.Putih, TextSize = 18,
}, title)
new("UICorner", {CornerRadius = UDim.new(0, 9)}, minBtn)
new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.3}, minBtn)
efekTombol(minBtn, 1.1)

-- garis aksen LED di bawah header
local accent = new("Frame", {
    Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, 48),
    BorderSizePixel = 0,
}, panel)
ledSweep(accent, C.Biru, C.Putih, C.Ungu2, 2.6)

-- AREA SCROLL
local scroll = new("ScrollingFrame", {
    Position = UDim2.new(0, 10, 0, 56), Size = UDim2.new(1, -20, 1, -146),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 5, ScrollBarImageColor3 = C.Ungu2,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
new("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)

-- MARQUEE teks berjalan 📜 (1 tween saja — murah)
local marqueeStrip = new("Frame", {
    Position = UDim2.new(0, 10, 1, -88), Size = UDim2.new(1, -20, 0, 20),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
}, panel)
new("UICorner", {CornerRadius = UDim.new(0, 8)}, marqueeStrip)
ledSweep(marqueeStrip, C.Hitam, C.Ungu, C.Biru, 4)
local marqueeClip = new("Frame", {
    Position = UDim2.new(0, 6, 0, 3), Size = UDim2.new(1, -12, 0, 14),
    BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
}, marqueeStrip)
local marquee = new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(320, 0),
    Size = UDim2.fromOffset(1200, 14), FontFace = fnt("med"),
    Text = "⌨ F = GUI ✦ CAPSLOCK = freecam ✦ T = auto brightness ✦ G = kamera→karakter ✦ C = TP kamera / info players ✦ Q = speed ✦ R = hide players ✦ WASD + QE + SPACE = gerak freecam ✦ ⚡ S I L A U  N E O N ⚡",
    TextColor3 = C.Abuk, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
}, marqueeClip)
tween(marquee, TweenInfo.new(16, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Position = UDim2.fromOffset(-1200, 0)})

-- BAR BAWAH (reset & keluar)
local bottom = new("Frame", {
    Position = UDim2.new(0, 0, 1, -56), Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
    ClipsDescendants = true,
}, panel)
new("UICorner", {CornerRadius = UDim.new(0, 13)}, bottom)
new("Frame", {
    Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -64),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
}, panel)

local resetBtn = new("TextButton", {
    Size = UDim2.new(0.5, -12, 1, -16), Position = UDim2.new(0, 8, 0, 8),
    BackgroundColor3 = C.Biru, BorderSizePixel = 0, AutoButtonColor = false,
    FontFace = fnt("bold"), TextSize = 18, Text = "🔄 Reset Script", TextColor3 = C.Putih,
}, bottom)
new("UICorner", {CornerRadius = UDim.new(0, 12)}, resetBtn)
ledSweep(resetBtn, C.Biru, C.Putih, C.Ungu2, 2.4)
efekTombol(resetBtn)

local exitBtn = new("TextButton", {
    Size = UDim2.new(0.5, -12, 1, -16), Position = UDim2.new(0.5, 4, 0, 8),
    BackgroundColor3 = C.Hitam2, BorderSizePixel = 0, AutoButtonColor = false,
    FontFace = fnt("bold"), TextSize = 18, Text = "🗑️ Hapus / Keluar", TextColor3 = C.Merah,
}, bottom)
new("UICorner", {CornerRadius = UDim.new(0, 12)}, exitBtn)
-- stroke statis (tanpa pulse loop)
new("UIStroke", {Color = C.Merah, Thickness = 2, Transparency = 0.6}, exitBtn)
efekTombol(exitBtn)

-- BRACKET HUD di sudut (STATIS — tanpa loop kedip)
local function bracket(ax, ay, px, py, warna)
    new("Frame", {Name = "NoFade", AnchorPoint = Vector2.new(ax, ay),
        Position = UDim2.new(px, ax == 1 and -8 or 8, py, ay == 1 and -8 or 8),
        Size = UDim2.fromOffset(14, 3), BackgroundColor3 = warna,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 3}, outer)
    new("Frame", {Name = "NoFade", AnchorPoint = Vector2.new(ax, ay),
        Position = UDim2.new(px, ax == 1 and -3 or 3, py, ay == 1 and -3 or 3),
        Size = UDim2.fromOffset(3, 14), BackgroundColor3 = warna,
        BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 3}, outer)
end
bracket(0, 0, 0, 0, C.Ungu2)
bracket(1, 0, 1, 0, C.Biru2)
bracket(0, 1, 0, 1, C.Biru2)
bracket(1, 1, 1, 1, C.Ungu2)

--═══════════════ NOTIFIKASI MUNGIL (POJOK KANAN ATAS — SUBTLE) ═══════════════
local notifHolder = new("Frame", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -10, 0, 10),
    Size = UDim2.fromOffset(240, 500),
    BackgroundTransparency = 1, ZIndex = 60,
}, gui)
new("UIListLayout", {
    Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
}, notifHolder)

local notifSeq, silent = 0, false
local function notify(msg, state)
    if silent then return end
    notifSeq += 1
    local aksen = (state == true) and C.Biru2 or (state == false) and C.Merah or C.Ungu2
    local ikon  = (state == true) and "✓" or (state == false) and "✕" or "⚡"
    local teks  = (state == nil) and msg or (msg .. " " .. (state and "ON" or "OFF"))

    local n = new("Frame", {
        Size = UDim2.fromOffset(190, 24), BackgroundColor3 = C.Hitam2,
        BackgroundTransparency = 1, BorderSizePixel = 0,
        LayoutOrder = notifSeq, ZIndex = 60,
        ClipsDescendants = true,
    }, notifHolder)
    new("UICorner", {CornerRadius = UDim.new(0, 7)}, n)
    local st = new("UIStroke", {Color = aksen, Thickness = 1, Transparency = 1}, n)
    local ic = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 6, 0, 0),
        Size = UDim2.new(0, 14, 1, 0), Font = Enum.Font.SourceSans,
        Text = ikon, TextSize = 12, TextColor3 = aksen, ZIndex = 61,
    }, n)
    local lb = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 22, 0, 0),
        Size = UDim2.new(1, -28, 1, 0), FontFace = fnt("semi"),
        Text = teks, TextSize = 11, TextColor3 = C.UnguMuda,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 61,
    }, n)
    local sc = new("UIScale", {Scale = 0.85}, n)

    bunyi(SND_PING, 0.12, state == true and 1.2 or state == false and 0.7 or 1)

    task.spawn(function()
        tween(sc, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
        tween(n,  TweenInfo.new(0.22), {BackgroundTransparency = 0.25})
        tween(st, TweenInfo.new(0.22), {Transparency = 0.55})
        tween(lb, TweenInfo.new(0.22), {TextTransparency = 0.1})
        tween(ic, TweenInfo.new(0.22), {TextTransparency = 0.1})
        task.wait(1.2)
        tween(n,  TweenInfo.new(0.3), {BackgroundTransparency = 1})
        tween(st, TweenInfo.new(0.3), {Transparency = 1})
        tween(lb, TweenInfo.new(0.3), {TextTransparency = 1})
        tween(ic, TweenInfo.new(0.3), {TextTransparency = 1})
        task.wait(0.32)
        n:Destroy()
    end)
end

--═══════════════ CROSSHAIR ═══════════════
local crosshair = new("Frame", {
    Visible = false, BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromOffset(2, 2), ZIndex = 50,
}, gui)
local function crossLine(x, y, w, h)
    new("Frame", {BackgroundColor3 = C.Hijau, BorderSizePixel = 0, ZIndex = 50,
        Size = UDim2.fromOffset(w, h), Position = UDim2.new(0, x, 0, y)}, crosshair)
end
crossLine(-1, -16, 2, 12)
crossLine(-1,   4, 2, 12)
crossLine(-16, -1, 12, 2)
crossLine(  4, -1, 12, 2)
crossLine(-1,  -1, 2, 2)

--═══════════════ PEMBANGUN UI ═══════════════
local order = 0
local function addSection(text)
    order += 1
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
        LayoutOrder = order,
    }, scroll)
    local lb = new("TextLabel", {
        Size = UDim2.new(1, -10, 0, 26), Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1, Text = "▎ " .. text,
        FontFace = fnt("judul"), TextSize = 21, TextColor3 = C.Ungu2,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)
    ledSweep(lb, C.Ungu2, C.Putih, C.Biru2, 3)
    local bar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 4, 1, -4),
        BackgroundColor3 = C.Ungu, BorderSizePixel = 0,
    }, holder)
    ledSweep(bar, C.Ungu, C.Putih, C.Biru, 2.8)
end
local function addHint(text)
    order += 1
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = "💡 " .. text, FontFace = fnt("med"), TextSize = 14, TextColor3 = C.AbuTeks,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = order,
    }, scroll)
end

local function addRow(labelText, opts)
    opts = opts or {}
    order += 1
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.Baris,
        BorderSizePixel = 0, LayoutOrder = order,
        ClipsDescendants = true,
    }, scroll)
    new("UICorner", {CornerRadius = UDim.new(0, 12)}, row)
    local rowStroke = new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.78}, row)

    -- notch LED statis (tanpa cycleColor loop — hemat)
    new("Frame", {
        Size = UDim2.new(0, 3, 1, -18), Position = UDim2.new(0, 6, 0, 9),
        BackgroundColor3 = C.Ungu2, BorderSizePixel = 0,
    }, row)

    row.MouseEnter:Connect(function()
        tween(row, TweenInfo.new(0.12), {BackgroundColor3 = C.BarisHov})
        tween(rowStroke, TweenInfo.new(0.12), {Transparency = 0.45})
    end)
    row.MouseLeave:Connect(function()
        tween(row, TweenInfo.new(0.12), {BackgroundColor3 = C.Baris})
        tween(rowStroke, TweenInfo.new(0.12), {Transparency = 0.78})
    end)

    local ref = {row = row}
    local vshift = opts.toggle and 0 or 88
    local lw = -92
    if opts.value then lw = opts.toggle and -300 or -212 end
    ref.label = new("TextLabel", {
        Size = UDim2.new(1, lw, 1, 0), Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1, Text = labelText,
        FontFace = fnt("semi"), TextSize = 17, TextColor3 = C.UnguMuda,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    if opts.value then
        ref.minus = new("TextButton", {
            Size = UDim2.new(0, 28, 1, -16), Position = UDim2.new(1, -284 + vshift, 0, 8),
            BackgroundColor3 = C.UnguD, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "-", FontFace = fnt("bold"), TextSize = 22, TextColor3 = C.Putih,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 10)}, ref.minus)
        efekTombol(ref.minus, 1.12)

        ref.val = new("TextLabel", {
            Size = UDim2.new(0, 80, 1, -16), Position = UDim2.new(1, -252 + vshift, 0, 8),
            BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
            Text = "--", FontFace = fnt("bold"), TextSize = 17, TextColor3 = C.UnguMuda,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 10)}, ref.val)
        new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.5}, ref.val)

        ref.plus = new("TextButton", {
            Size = UDim2.new(0, 28, 1, -16), Position = UDim2.new(1, -168 + vshift, 0, 8),
            BackgroundColor3 = C.UnguD, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "+", FontFace = fnt("bold"), TextSize = 22, TextColor3 = C.Putih,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 10)}, ref.plus)
        efekTombol(ref.plus, 1.12)
    end

    if opts.action then
        ref.action = new("TextButton", {
            Size = UDim2.new(0, 68, 1, -16), Position = UDim2.new(1, -76, 0, 8),
            BackgroundColor3 = C.Biru, BorderSizePixel = 0, AutoButtonColor = false,
            Text = opts.action, FontFace = fnt("bold"), TextSize = 17, TextColor3 = C.Putih,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 10)}, ref.action)
        efekTombol(ref.action)
    end

    if opts.toggle then
        ref.toggle = new("TextButton", {
            Size = UDim2.new(0, 68, 1, -16), Position = UDim2.new(1, -76, 0, 8),
            BackgroundColor3 = C.offBg, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "OFF", FontFace = fnt("bold"), TextSize = 17, TextColor3 = C.Abuk,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 10)}, ref.toggle)
        new("UIStroke", {Color = C.Ungu, Thickness = 1.5, Transparency = 0.6}, ref.toggle)
        efekTombol(ref.toggle)
    end
    return ref
end

local function styleToggle(btn, on)
    btn.Text = on and "ON" or "OFF"
    btn.BackgroundColor3 = on and C.Biru or C.offBg
    btn.TextColor3 = on and C.Putih or C.Abuk
    local st = btn:FindFirstChildOfClass("UIStroke")
    if st then
        st.Color = on and C.Biru2 or C.Ungu
        st.Transparency = on and 0.1 or 0.6
    end
    local g = btn:FindFirstChild("LedGrad")
    if on and not g then
        local gg = ledSweep(btn, C.Biru, C.Putih, C.Biru2, 2.2)
        if gg then gg.Name = "LedGrad" end
    elseif not on and g then
        g:Destroy()
    end
end

--═══════════════ ISI PANEL ═══════════════
addSection("MOVEMENT")
local rSpeed = addRow("🏃 Speed & Swim [Q]", {value = true, toggle = true})
local rJump  = addRow("🦘 Jump Power",       {value = true, toggle = true})
local rCross = addRow("🎯 Scooshlock (Crosshair)", {toggle = true})

addSection("PLAYER DISPLAY")
local rInfo = addRow("👤 Info Other Players [C]", {toggle = true})
local rHit  = addRow("📦 Hitbox Players",          {toggle = true})

addSection("CAMERA / FREECAM")
local rFree    = addRow("🎥 Free Cam [CAPS LOCK]",    {toggle = true})
local rTpKam   = addRow("🌀 TP Karakter→Kamera [C]",  {toggle = true})
local rTpJarak = addRow("↩️ TP Jarak Mundur",         {value = true})
local rKeKar   = addRow("🧲 Kamera → Karakter [G]",   {action = "GO"})
local rKeKam   = addRow("🚀 Karakter → Kamera",       {action = "TP"})
addHint("WASD gerak • QE turun/naik • Space cepat")
addHint("Jarak mundur: 0 = tepat di kamera")

addSection("VISUAL")
local rHideP = addRow("🙈 Hide Other Players [R]", {toggle = true})
local rHideF = addRow("✨ Hide All Effects",        {toggle = true})
local rLowG  = addRow("🌫️ Low Graphic + No Fog",   {toggle = true})

addSection("ENVIRONMENT")
local rClock = addRow("🕒 Auto Brightness [T]", {value = true, toggle = true})

--═══════════════ STATE ═══════════════
local S = {
    speedOn = false, speedValue = DEFAULT_SPEED,
    jumpOn = false,  jumpValue = DEFAULT_JUMP,
    crosshairOn = false, infoOn = false, hitboxOn = false,
    hidePlayersOn = false, hideFxOn = false, lowGfxOn = false,
    clockOn = false, clockTouched = false,
    clockValue = Lighting.ClockTime,
    tpJarakMundur = CONFIG.TP_JARAK_MUNDUR,
}
local orig = {brightness = Lighting.Brightness, clockTime = Lighting.ClockTime}

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local freecamAktif, tpKameraAktif = false, false
local adaPosisiTersimpan = false
local fcTarget = Vector3.zero
local yaw, pitch = 0, 0
local posNow = Vector3.zero
local yawNow, pitchNow = 0, 0
local tombolTekan = {}
local threadStream = nil

local efekKoreksi, tweenEfek = nil, nil
local hitamPutihAktif = false

local function segarkanToggle()
    styleToggle(rSpeed.toggle, S.speedOn)
    styleToggle(rJump.toggle, S.jumpOn)
    styleToggle(rCross.toggle, S.crosshairOn)
    styleToggle(rInfo.toggle, S.infoOn)
    styleToggle(rHit.toggle, S.hitboxOn)
    styleToggle(rFree.toggle, freecamAktif)
    styleToggle(rTpKam.toggle, tpKameraAktif)
    styleToggle(rHideP.toggle, S.hidePlayersOn)
    styleToggle(rHideF.toggle, S.hideFxOn)
    styleToggle(rLowG.toggle, S.lowGfxOn)
    styleToggle(rClock.toggle, S.clockOn)
end

--═══════════════ MOVEMENT (FIX v1.1) ═══════════════
local savedHum = {}
local FALLBACK_WS  = 16
local lastWsNormal = 16

local function captureHum(h)
    if savedHum[h] then return end
    local ws0 = h.WalkSpeed
    if ws0 == nil or ws0 < 1 then
        ws0 = (lastWsNormal >= 1) and lastWsNormal or FALLBACK_WS
    elseif not S.speedOn then
        lastWsNormal = ws0
    end
    local jp0 = h.JumpPower
    if jp0 == nil or jp0 < 1 then jp0 = 50 end
    local rec = {ws = ws0, ujp = h.UseJumpPower, jp = jp0, ss = nil, jh = nil}
    pcall(function() rec.ss = h.SwimSpeed end)
    pcall(function() rec.jh = h.JumpHeight end)
    savedHum[h] = rec
end

local function restoreHum(h)
    local rec = savedHum[h]
    if not rec then return end
    pcall(function() h.WalkSpeed    = rec.ws  end)
    pcall(function() h.UseJumpPower = rec.ujp end)
    pcall(function() h.JumpPower    = rec.jp  end)
    if rec.jh then pcall(function() h.JumpHeight = rec.jh end) end
    if rec.ss then pcall(function() h.SwimSpeed  = rec.ss end) end
    savedHum[h] = nil
    if h.WalkSpeed < 1 then
        pcall(function()
            h.WalkSpeed = (rec.ws and rec.ws >= 1) and rec.ws or FALLBACK_WS
        end)
    end
end

local jagaId = 0
local function jagaGerak(durasi)
    jagaId += 1
    local myId = jagaId
    task.spawn(function()
        local t0 = os.clock()
        while os.clock() - t0 < (durasi or 3) and myId == jagaId do
            if not gui.Parent then return end
            if S.speedOn then return end
            local h = getHum()
            if h and h.Health > 0 and not h.SeatPart and h.WalkSpeed < 1 then
                pcall(function()
                    h.WalkSpeed = (lastWsNormal >= 1) and lastWsNormal or FALLBACK_WS
                end)
            end
            task.wait(0.25)
        end
    end)
end

local function applyMovement()
    local h = getHum()
    if not h then return end
    if S.speedOn or S.jumpOn then captureHum(h) end
    if S.speedOn then
        h.WalkSpeed = S.speedValue
        pcall(function() h.SwimSpeed = S.speedValue end)
    end
    if S.jumpOn then
        pcall(function()
            h.UseJumpPower = true
            h.JumpPower = S.jumpValue
        end)
    end
end

local function setSpeed(on)
    S.speedOn = on
    if on then
        applyMovement()
    else
        local h = getHum()
        if h then restoreHum(h) end
        if S.jumpOn then applyMovement() end
        jagaGerak(3)
    end
    styleToggle(rSpeed.toggle, on)
    notify("Speed & Swim", on)
end

local function setJump(on)
    S.jumpOn = on
    if on then
        applyMovement()
    else
        local h = getHum()
        if h then restoreHum(h) end
        if S.speedOn then applyMovement() end
        jagaGerak(3)
    end
    styleToggle(rJump.toggle, on)
    notify("Jump Power", on)
end

local function setCrosshair(on)
    S.crosshairOn = on
    crosshair.Visible = on
    styleToggle(rCross.toggle, on)
    notify("Scooshlock", on)
end

--═══════════════ INFO / HITBOX ═══════════════
local infoRefs = {}

local function cleanupInfo(char)
    local bb = char and char:FindFirstChild("PH_Info")
    if bb then bb:Destroy() end
end
local function cleanupHitbox(char)
    if not char then return end
    local glow = char:FindFirstChild("PH_Glow")
    if glow then glow:Destroy() end
    for _, d in ipairs(char:GetDescendants()) do
        if d.Name == "PH_Box" then d:Destroy() end
    end
end

local function getRealStats(char, root)
    local ws, jp = 0, 0
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return ws, jp end
    if root then
        local v = root.AssemblyLinearVelocity
        ws = Vector3.new(v.X, 0, v.Z).Magnitude
        if ws < 0.05 then ws = 0 end
        if v.Y > 3 then
            pcall(function() jp = (hum.UseJumpPower and hum.JumpPower) or hum.JumpHeight end)
        end
    end
    return ws, jp
end

local function attachInfo(plr, char)
    local head = char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChildWhichIsA("BasePart")
    if not head then return nil end
    pcall(cleanupInfo, char)
    local bb = new("BillboardGui", {
        Name = "PH_Info", Adornee = head,
        Size = UDim2.fromOffset(220, 48),
        StudsOffset = Vector3.new(0, 2.9, 0),
        AlwaysOnTop = true, MaxDistance = INFO_MAX_DIST,
    }, char)
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = C.Putih, TextStrokeTransparency = 0.25,
        Text = "👤 " .. plr.DisplayName .. " (@" .. plr.Name .. ")",
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, bb)
    local stat = new("TextLabel", {
        Position = UDim2.new(0, 0, 0, 23), Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = C.Biru2, TextStrokeTransparency = 0.3,
        Text = "WS 0,00 | JP 0,00",
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, bb)
    return {bb = bb, stat = stat, char = char, last = ""}
end

local function attachHitbox(plr, char)
    pcall(cleanupHitbox, char)
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            new("BoxHandleAdornment", {
                Name = "PH_Box", Adornee = part, Parent = part,
                Size = part.Size, Color3 = C.Hijau, Transparency = 0.6,
                AlwaysOnTop = true, ZIndex = 2,
            }, part)
        end
    end
    pcall(function()
        new("Highlight", {
            Name = "PH_Glow", Parent = char, FillTransparency = 1,
            OutlineColor = C.Hijau, OutlineTransparency = 0.35,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
        }, char)
    end)
end

local function syncDisplays()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                if S.infoOn then
                    local root = char:FindFirstChild("HumanoidRootPart")
                        or char:FindFirstChildWhichIsA("BasePart")
                    if myPos and root and (root.Position - myPos).Magnitude > INFO_MAX_DIST then
                        local ref = infoRefs[plr]
                        if ref then
                            if ref.bb.Enabled then ref.bb.Enabled = false end
                        elseif char:FindFirstChild("PH_Info") then
                            pcall(cleanupInfo, char)
                        end
                    else
                        local ref = infoRefs[plr]
                        if not ref or ref.char ~= char or not ref.bb.Parent or not ref.stat.Parent then
                            local newRef = attachInfo(plr, char)
                            if newRef then
                                infoRefs[plr] = newRef
                                ref = newRef
                            else
                                ref = nil
                            end
                        end
                        if ref then
                            if not ref.bb.Enabled then ref.bb.Enabled = true end
                            local ws, jp = getRealStats(char, root)
                            local txt = "WS " .. fmt2(ws) .. " | JP " .. fmt2(jp)
                            if txt ~= ref.last then
                                ref.stat.Text = txt
                                ref.last = txt
                            end
                        end
                    end
                elseif infoRefs[plr] or char:FindFirstChild("PH_Info") then
                    infoRefs[plr] = nil
                    pcall(cleanupInfo, char)
                end
                if S.hitboxOn then
                    if not char:FindFirstChild("PH_Glow") then
                        attachHitbox(plr, char)
                    end
                elseif char:FindFirstChild("PH_Glow") or char:FindFirstChild("PH_Box") then
                    pcall(cleanupHitbox, char)
                end
            end
        end
    end
end

local function toggleInfoPlayers()
    S.infoOn = not S.infoOn
    syncDisplays()
    styleToggle(rInfo.toggle, S.infoOn)
    notify("Info Other Players", S.infoOn)
end

--═══════════════ HIDE OTHER PLAYERS ═══════════════
local hideLoopId = 0

local function applyHide()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            for _, d in ipairs(plr.Character:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.LocalTransparencyModifier = S.hidePlayersOn and 1 or 0
                end
            end
        end
    end
end

local function setHidePlayers(on)
    S.hidePlayersOn = on
    hideLoopId += 1
    local myId = hideLoopId
    if on then
        task.spawn(function()
            while S.hidePlayersOn and myId == hideLoopId do
                applyHide()
                task.wait(0.2)
            end
        end)
    end
    applyHide()
    styleToggle(rHideP.toggle, on)
    notify("Hide Other Players", on)
end

--═══════════════ HIDE ALL EFFECTS ═══════════════
local FX_CLASSES = {
    ParticleEmitter = "Enabled", Fire = "Enabled", Smoke = "Enabled",
    Sparkles = "Enabled", Beam = "Enabled", Trail = "Enabled",
    PointLight = "Enabled", SpotLight = "Enabled", SurfaceLight = "Enabled",
}
local savedFx, fxConn = {}, nil

local function disableFx(inst)
    local prop = FX_CLASSES[inst.ClassName]
    if prop and savedFx[inst] == nil then
        pcall(function()
            savedFx[inst] = {prop = prop, value = inst[prop]}
            inst[prop] = false
        end)
    end
end

local function setHideFx(on)
    S.hideFxOn = on
    if on then
        for _, d in ipairs(workspace:GetDescendants()) do disableFx(d) end
        fxConn = workspace.DescendantAdded:Connect(disableFx)
    else
        if fxConn then fxConn:Disconnect() fxConn = nil end
        for inst, data in pairs(savedFx) do
            pcall(function() inst[data.prop] = data.value end)
        end
        savedFx = {}
    end
    styleToggle(rHideF.toggle, on)
    notify("Hide All Effects", on)
end

--═══════════════ LOW GRAPHIC MODE ═══════════════
local savedGfx, gfxConn = {}, nil
local savedQuality, gfxApplied = nil, false

local function setLowGfx(on)
    S.lowGfxOn = on
    if on then
        gfxApplied = true
        savedQuality = nil
        pcall(function() savedQuality = settings().Rendering.QualityLevel end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        savedGfx.shadows = Lighting.GlobalShadows
        savedGfx.fogStart, savedGfx.fogEnd = Lighting.FogStart, Lighting.FogEnd
        Lighting.GlobalShadows = false
        Lighting.FogStart, Lighting.FogEnd = 9e9, 9e9
        pcall(function()
            savedGfx.deco = workspace.Terrain.Decoration
            workspace.Terrain.Decoration = false
            savedGfx.wave = workspace.Terrain.WaterWaveSize
            workspace.Terrain.WaterWaveSize = 0
            savedGfx.refl = workspace.Terrain.WaterReflectance
            workspace.Terrain.WaterReflectance = 0
        end)
        for _, d in ipairs(Lighting:GetDescendants()) do
            if d:IsA("PostEffect") then savedGfx[d] = d.Enabled; d.Enabled = false end
        end
        gfxConn = Lighting.ChildAdded:Connect(function(d)
            if S.lowGfxOn and d:IsA("PostEffect") then savedGfx[d] = d.Enabled; d.Enabled = false end
        end)
    elseif gfxApplied then
        pcall(function()
            if savedQuality ~= nil then
                settings().Rendering.QualityLevel = savedQuality
            else
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            end
        end)
        if savedGfx.shadows  ~= nil then Lighting.GlobalShadows = savedGfx.shadows end
        if savedGfx.fogStart ~= nil then Lighting.FogStart = savedGfx.fogStart end
        if savedGfx.fogEnd   ~= nil then Lighting.FogEnd = savedGfx.fogEnd end
        pcall(function()
            if savedGfx.deco ~= nil then workspace.Terrain.Decoration = savedGfx.deco end
            if savedGfx.wave ~= nil then workspace.Terrain.WaterWaveSize = savedGfx.wave end
            if savedGfx.refl ~= nil then workspace.Terrain.WaterReflectance = savedGfx.refl end
        end)
        for d, v in pairs(savedGfx) do
            if typeof(d) == "Instance" then pcall(function() d.Enabled = v end) end
        end
        savedGfx = {}
        if gfxConn then gfxConn:Disconnect() gfxConn = nil end
        gfxApplied = false
    end
    styleToggle(rLowG.toggle, on)
    notify("Low Graphic Mode", on)
end

--═══════════════ AUTO BRIGHTNESS [ON/OFF] ═══════════════
local clockSnap = nil

local function applyLockedClock()
    pcall(function() Lighting.Brightness = brightnessFromTime(S.clockValue) end)
    if LOCK_TIME then
        pcall(function() Lighting.ClockTime = S.clockValue end)
    end
end

local function setClock(on)
    if on then
        if not S.clockOn then
            clockSnap = {ct = Lighting.ClockTime, br = Lighting.Brightness}
            S.clockTouched = true
        end
        S.clockOn = true
        applyLockedClock()
    else
        S.clockOn = false
        if clockSnap then
            pcall(function() Lighting.ClockTime = clockSnap.ct end)
            pcall(function() Lighting.Brightness = clockSnap.br end)
            clockSnap = nil
        end
    end
    styleToggle(rClock.toggle, S.clockOn)
    notify("Auto Brightness", S.clockOn)
end

local function bumpClock(d)
    S.clockValue = (S.clockValue + d) % 24
    if S.clockValue < 0 then S.clockValue += 24 end
    rClock.val.Text = formatClock(S.clockValue)
    if not S.clockOn then
        setClock(true)
    else
        applyLockedClock()
    end
end

--═══════════════ FREECAM - HELPER ═══════════════
local function dapatkanRoot()
    local karakter = LocalPlayer.Character
    return karakter and karakter:FindFirstChild("HumanoidRootPart")
end

local function cfTegak(cf)
    local look = cf.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.001 then
        flat = Vector3.new(0, 0, -1)
    end
    return CFrame.lookAt(cf.Position, cf.Position + flat.Unit)
end

local function netralkanFisika(root)
    if not root then return end
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end

local function requestStream(pos)
    if Workspace.StreamingEnabled then
        task.spawn(function()
            pcall(function() LocalPlayer:RequestStreamAroundAsync(pos) end)
        end)
    end
end

local function tahanKarakter()
    local hum = getHum()
    if not hum then return end
    pcall(function()
        hum:Move(Vector3.zero, false)
        hum.Jump = false
    end)
end

--═══════════════ EFEK FLASH TELEPORT 🚀 (sesaat saat TP saja) ═══════════════
local function fxTeleport()
    bunyi(SND_WHOOSH, 0.4, 1.1)

    local fl = new("Frame", {
        Name = "NoFade", Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = C.Putih, BackgroundTransparency = 1,
        BorderSizePixel = 0, ZIndex = 950,
    }, screenFx)
    tween(fl, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.55})
    task.delay(0.1, function()
        tween(fl, TweenInfo.new(0.3), {BackgroundTransparency = 1})
        task.delay(0.35, function() fl:Destroy() end)
    end)

    local r = new("Frame", {
        Name = "NoFade", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 949,
    }, screenFx)
    new("UICorner", {CornerRadius = UDim.new(1, 0)}, r)
    local rs = new("UIStroke", {Color = C.Ungu, Thickness = 4, Transparency = 0}, r)
    tween(r,  TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(430, 430)})
    tween(rs, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
    task.delay(0.55, function() r:Destroy() end)

    emojiBurst(screenFx, UDim2.new(0.5, 0, 0.5, 0), {"🚀", "✨", "⚡", "💫", "🌟"}, 8)

    tween(panelScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = UKURAN_GUI * 0.96})
    task.delay(0.1, function()
        tween(panelScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = UKURAN_GUI})
    end)
end

--═══════════════ KAMERA -> KARAKTER [G] ═══════════════
local function kameraKeKarakter()
    if not freecamAktif then return false end
    local root = dapatkanRoot()
    if not root then return false end

    local look = root.CFrame.LookVector
    fcTarget = root.Position
        + Vector3.new(0, CONFIG.TINGGI_KAMERA, 0)
        - look * CONFIG.JARAK_BELAKANG

    yaw   = math.deg(math.atan2(-look.X, -look.Z))
    pitch = math.clamp(CONFIG.SUDUT_TP, -CONFIG.BATAS_PITCH, CONFIG.BATAS_PITCH)
    yawNow, pitchNow = yaw, pitch

    requestStream(fcTarget)
    bunyi(SND_WHOOSH, 0.25, 1.2)
    return true
end

--═══════════════ TELEPORT KARAKTER ═══════════════
local function teleportKarakter(cf)
    local root = dapatkanRoot()
    if not root then return false end

    local humanoid = getHum()
    if humanoid and humanoid.SeatPart then
        pcall(function() humanoid.Sit = false end)
    end

    root.CFrame = cf
    netralkanFisika(root)
    requestStream(cf.Position)
    return true
end

local function teleportKeKamera(manual)
    if not freecamAktif then return false end
    if not manual and not tpKameraAktif then return false end

    local cfKamera = camera.CFrame
    local look     = cfKamera.LookVector

    local posisi = cfKamera.Position - look * S.tpJarakMundur
    local tujuan = cfTegak(CFrame.lookAt(posisi, posisi + look))

    local ok = teleportKarakter(tujuan)
    if ok then fxTeleport() end
    return ok
end

--═══════════════ EFEK HITAM PUTIH (MATI) ═══════════════
local function setHitamPutih(aktif)
    hitamPutihAktif = aktif
    if aktif then
        if not (efekKoreksi and efekKoreksi.Parent) then
            efekKoreksi = Instance.new("ColorCorrectionEffect")
            efekKoreksi.Name       = "EfekMati_HitamPutih"
            efekKoreksi.Saturation = 0
            efekKoreksi.Contrast   = 0
            efekKoreksi.Parent     = Lighting
        end
        if tweenEfek then tweenEfek:Cancel() end
        tweenEfek = TweenService:Create(
            efekKoreksi,
            TweenInfo.new(CONFIG.DURASI_EFEK_MATI, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Saturation = -1, Contrast = 0.15 }
        )
        tweenEfek:Play()
    else
        if efekKoreksi and efekKoreksi.Parent then
            if tweenEfek then tweenEfek:Cancel() end
            tweenEfek = TweenService:Create(
                efekKoreksi,
                TweenInfo.new(CONFIG.DURASI_EFEK_MATI, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Saturation = 0, Contrast = 0 }
            )
            tweenEfek:Play()
            tweenEfek.Completed:Once(function(state)
                if state == Enum.PlaybackState.Completed and not hitamPutihAktif and efekKoreksi then
                    efekKoreksi:Destroy()
                    efekKoreksi = nil
                end
            end)
        end
    end
end

--═══════════════ UPDATE KAMERA (TIAP FRAME — DIOPTIMALKAN) ═══════════════
local lastMouseState = nil

local function updateFreecam(dt)
    tahanKarakter()

    camera.CameraType = Enum.CameraType.Scriptable

    -- MouseBehavior hanya di-set saat berubah (hemat tiap frame)
    local state = main.Visible
    if state ~= lastMouseState then
        lastMouseState = state
        if state then
            UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        else
            UserInputService.MouseBehavior    = Enum.MouseBehavior.LockCenter
            UserInputService.MouseIconEnabled = false
        end
    end

    local maju    = (tombolTekan[Enum.KeyCode.W] and 1 or 0) - (tombolTekan[Enum.KeyCode.S] and 1 or 0)
    local samping = (tombolTekan[Enum.KeyCode.D] and 1 or 0) - (tombolTekan[Enum.KeyCode.A] and 1 or 0)
    local naik    = (tombolTekan[Enum.KeyCode.E] and 1 or 0) - (tombolTekan[Enum.KeyCode.Q] and 1 or 0)

    local arah = Vector3.zero
    if maju ~= 0 or samping ~= 0 or naik ~= 0 then
        local rotasi = CFrame.fromOrientation(math.rad(pitchNow), math.rad(yawNow), 0)
        local depan  = rotasi.LookVector
        local kanan  = CFrame.fromOrientation(0, math.rad(yawNow), 0).RightVector
        arah = (depan * maju) + (kanan * samping) + Vector3.new(0, naik, 0)
        if arah.Magnitude > 0 then
            arah = arah.Unit
        end
    end

    local kecepatan = tombolTekan[Enum.KeyCode.Space] and CONFIG.KECEPATAN_CEPAT or CONFIG.KECEPATAN_NORMAL
    fcTarget = fcTarget + (arah * kecepatan * dt)

    local alpha = math.clamp(dt * CONFIG.KEHALUSAN, 0, 1)
    posNow   = posNow:Lerp(fcTarget, alpha)
    yawNow   = yawNow   + (yaw   - yawNow)   * alpha
    pitchNow = pitchNow + (pitch - pitchNow) * alpha

    local rot = CFrame.fromOrientation(math.rad(pitchNow), math.rad(yawNow), 0)
    camera.CFrame = CFrame.new(posNow) * rot
end

--═══════════════ FREECAM ON/OFF ═══════════════
local function mulaiFreecam()
    if freecamAktif then return end
    freecamAktif = true
    bunyi(SND_WHOOSH, 0.3, 1.1)

    if not adaPosisiTersimpan then
        local cf   = camera.CFrame
        local look = cf.LookVector
        fcTarget = cf.Position
        yaw      = math.deg(math.atan2(-look.X, -look.Z))
        pitch    = math.clamp(math.deg(math.asin(math.clamp(look.Y, -1, 1))), -CONFIG.BATAS_PITCH, CONFIG.BATAS_PITCH)
        adaPosisiTersimpan = true
    end
    posNow, yawNow, pitchNow = fcTarget, yaw, pitch

    camera.CameraType = Enum.CameraType.Scriptable

    pcall(function() RunService:UnbindFromRenderStep(NAMA_BIND) end)
    pcall(function()
        RunService:BindToRenderStep(NAMA_BIND, Enum.RenderPriority.Camera.Value + 1, updateFreecam)
    end)

    threadStream = task.spawn(function()
        while freecamAktif do
            requestStream(posNow)
            task.wait(CONFIG.INTERVAL_STREAM)
        end
    end)
end

local function hentikanFreecam()
    if not freecamAktif then return end
    freecamAktif = false

    pcall(function() RunService:UnbindFromRenderStep(NAMA_BIND) end)

    if threadStream then
        pcall(task.cancel, threadStream)
        threadStream = nil
    end

    camera.CameraType = Enum.CameraType.Custom
    local humanoid = getHum()
    if humanoid then
        pcall(function() camera.CameraSubject = humanoid end)
    end

    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
    lastMouseState = nil
end

local function perbaruiTombol()
    styleToggle(rFree.toggle,  freecamAktif)
    styleToggle(rClock.toggle, S.clockOn)
    styleToggle(rTpKam.toggle, tpKameraAktif)
end

local function setFreecam(aktif)
    if aktif == freecamAktif then perbaruiTombol() return end
    if aktif then mulaiFreecam() else hentikanFreecam() end
    perbaruiTombol()
    notify("Free Cam", freecamAktif)
end

local function setTpKamera(aktif)
    tpKameraAktif = aktif
    perbaruiTombol()
    notify("TP Karakter -> Kamera", aktif)
end

--═══════════════ RESET SCRIPT ═══════════════
local function resetScript()
    silent = true
    setSpeed(false); setJump(false); setCrosshair(false)
    setFreecam(false)
    setTpKamera(false)
    if S.clockOn then setClock(false) end
    S.infoOn, S.hitboxOn = false, false
    syncDisplays()
    styleToggle(rInfo.toggle, false); styleToggle(rHit.toggle, false)
    setHidePlayers(false); setHideFx(false); setLowGfx(false)
    S.speedValue, S.jumpValue = DEFAULT_SPEED, DEFAULT_JUMP
    S.tpJarakMundur = CONFIG.TP_JARAK_MUNDUR
    rTpJarak.val.Text = fmt(S.tpJarakMundur)
    S.clockValue = orig.clockTime
    pcall(function() Lighting.ClockTime = orig.clockTime end)
    pcall(function() Lighting.Brightness = orig.brightness end)
    S.clockTouched = false
    rClock.val.Text = formatClock(S.clockValue)
    rSpeed.val.Text, rJump.val.Text = fmt(S.speedValue), fmt(S.jumpValue)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Visible = true
    scroll.CanvasPosition = Vector2.new(0, 0)
    silent = false
    notify("Script direset")
end

--═══════════════ HAPUS SCRIPT / KELUAR ═══════════════
local function unloadScript()
    silent = true
    S.speedOn, S.jumpOn = false, false
    for h in pairs(savedHum) do restoreHum(h) end
    S.infoOn, S.hitboxOn = false, false
    syncDisplays()
    setCrosshair(false)
    setFreecam(false)
    setHidePlayers(false)
    setHideFx(false)
    setLowGfx(false)
    setClock(false)
    if S.clockTouched then
        pcall(function() Lighting.ClockTime = orig.clockTime end)
        pcall(function() Lighting.Brightness = orig.brightness end)
    end
    if tweenEfek then pcall(function() tweenEfek:Cancel() end) tweenEfek = nil end
    if efekKoreksi then pcall(function() efekKoreksi:Destroy() end) efekKoreksi = nil end
    pcall(function() RunService:UnbindFromRenderStep(NAMA_BIND) end)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
    pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
    pcall(function() UserInputService.MouseIconEnabled = true end)
    gui:Destroy()
end

--═══════════════ DRAG STATE ═══════════════
local dragging, dragStart, startPos, dragInput = false, nil, nil, nil

--═══════════════ WIRING TOMBOL ═══════════════
rSpeed.toggle.MouseButton1Click:Connect(function()
    ripple(rSpeed.toggle, C.Putih)
    setSpeed(not S.speedOn)
end)
rJump.toggle.MouseButton1Click:Connect(function()
    ripple(rJump.toggle, C.Putih)
    setJump(not S.jumpOn)
end)
rCross.toggle.MouseButton1Click:Connect(function()
    ripple(rCross.toggle, C.Putih)
    setCrosshair(not S.crosshairOn)
end)
rInfo.toggle.MouseButton1Click:Connect(function()
    ripple(rInfo.toggle, C.Putih)
    toggleInfoPlayers()
end)
rHit.toggle.MouseButton1Click:Connect(function()
    ripple(rHit.toggle, C.Putih)
    S.hitboxOn = not S.hitboxOn
    syncDisplays()
    styleToggle(rHit.toggle, S.hitboxOn)
    notify("Hitbox Players", S.hitboxOn)
end)
rFree.toggle.MouseButton1Click:Connect(function()
    ripple(rFree.toggle, C.Putih)
    setFreecam(not freecamAktif)
end)
rTpKam.toggle.MouseButton1Click:Connect(function()
    ripple(rTpKam.toggle, C.Putih)
    setTpKamera(not tpKameraAktif)
end)
rHideP.toggle.MouseButton1Click:Connect(function()
    ripple(rHideP.toggle, C.Putih)
    setHidePlayers(not S.hidePlayersOn)
end)
rHideF.toggle.MouseButton1Click:Connect(function()
    ripple(rHideF.toggle, C.Putih)
    setHideFx(not S.hideFxOn)
end)
rLowG.toggle.MouseButton1Click:Connect(function()
    ripple(rLowG.toggle, C.Putih)
    setLowGfx(not S.lowGfxOn)
end)
rClock.toggle.MouseButton1Click:Connect(function()
    ripple(rClock.toggle, C.Putih)
    setClock(not S.clockOn)
end)

rKeKar.action.MouseButton1Click:Connect(function()
    ripple(rKeKar.action, C.Putih)
    if kameraKeKarakter() then
        notify("Kamera -> Karakter")
    else
        notify("Nyalakan Free Cam dulu", false)
    end
end)
rKeKam.action.MouseButton1Click:Connect(function()
    ripple(rKeKam.action, C.Putih)
    if teleportKeKamera(true) then
        notify("Karakter -> Kamera")
    else
        notify("Nyalakan Free Cam dulu", false)
    end
end)

local function bumpSpeed(d)
    S.speedValue = math.clamp(S.speedValue + d, 0, 500)
    rSpeed.val.Text = fmt(S.speedValue)
    if S.speedOn then applyMovement() end
end
local function bumpJump(d)
    S.jumpValue = math.clamp(S.jumpValue + d, 0, 1000)
    rJump.val.Text = fmt(S.jumpValue)
    if S.jumpOn then applyMovement() end
end
local function bumpTpJarak(d)
    S.tpJarakMundur = math.clamp(S.tpJarakMundur + d, CONFIG.TP_JARAK_MIN, CONFIG.TP_JARAK_MAKS)
    rTpJarak.val.Text = fmt(S.tpJarakMundur)
end

rSpeed.minus.MouseButton1Click:Connect(function()
    ripple(rSpeed.minus, C.Ungu2); bunyi(SND_SNAP, 0.2, 1.1); bumpSpeed(-STEP)
end)
rSpeed.plus.MouseButton1Click:Connect(function()
    ripple(rSpeed.plus, C.Ungu2); bunyi(SND_SNAP, 0.2, 1.3); bumpSpeed(STEP)
end)
rJump.minus.MouseButton1Click:Connect(function()
    ripple(rJump.minus, C.Ungu2); bunyi(SND_SNAP, 0.2, 1.1); bumpJump(-STEP)
end)
rJump.plus.MouseButton1Click:Connect(function()
    ripple(rJump.plus, C.Ungu2); bunyi(SND_SNAP, 0.2, 1.3); bumpJump(STEP)
end)
rTpJarak.minus.MouseButton1Click:Connect(function()
    ripple(rTpJarak.minus, C.Ungu2); bunyi(SND_SNAP, 0.2, 1.1); bumpTpJarak(-CONFIG.TP_JARAK_STEP)
end)
rTpJarak.plus.MouseButton1Click:Connect(function()
    ripple(rTpJarak.plus, C.Ungu2); bunyi(SND_SNAP, 0.2, 1.3); bumpTpJarak(CONFIG.TP_JARAK_STEP)
end)
rClock.minus.MouseButton1Click:Connect(function()
    ripple(rClock.minus, C.Ungu2); bumpClock(-0.25)  -- -15 menit
end)
rClock.plus.MouseButton1Click:Connect(function()
    ripple(rClock.plus, C.Ungu2); bumpClock(0.25)    -- +15 menit
end)

minBtn.MouseButton1Click:Connect(function()
    ripple(minBtn, C.Ungu2)
    main.Visible = false   -- ⚡ INSTAN
end)
resetBtn.MouseButton1Click:Connect(function()
    ripple(resetBtn, C.Putih)
    bunyi(SND_WHOOSH, 0.25, 0.9)
    resetScript()
end)
exitBtn.MouseButton1Click:Connect(function()
    ripple(exitBtn, C.Merah)
    bunyi(SND_SNAP, 0.3, 0.6)
    unloadScript()
end)

--═══════════════ HOTKEYS ═══════════════
addConn(UserInputService.InputBegan:Connect(function(input, processed)
    local kc = input.KeyCode
    tombolTekan[kc] = true
    if processed then return end

    if kc == Enum.KeyCode.F then
        main.Visible = not main.Visible   -- ⚡ INSTAN — tanpa animasi
    elseif kc == Enum.KeyCode.CapsLock then
        setFreecam(not freecamAktif)
    elseif kc == Enum.KeyCode.T then
        setClock(not S.clockOn)
    elseif kc == Enum.KeyCode.G then
        if kameraKeKarakter() then
            notify("Kamera -> Karakter")
        else
            notify("Nyalakan Free Cam dulu", false)
        end
    elseif kc == Enum.KeyCode.C then
        if freecamAktif then
            if tpKameraAktif then
                if teleportKeKamera(false) then
                    notify("Karakter -> Kamera")
                else
                    notify("Karakter tidak ada", false)
                end
            else
                notify("Nyalakan toggle TP dulu", false)
            end
        else
            toggleInfoPlayers()
        end
    elseif kc == Enum.KeyCode.Q then
        if not freecamAktif then
            setSpeed(not S.speedOn)
        end
    elseif kc == Enum.KeyCode.R then
        setHidePlayers(not S.hidePlayersOn)
    end
end))

addConn(UserInputService.InputEnded:Connect(function(input)
    tombolTekan[input.KeyCode] = nil
end))

addConn(UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        and freecamAktif and not main.Visible then
        yaw   = yaw - input.Delta.X * CONFIG.SENSITIVITAS_MOUSE
        pitch = math.clamp(pitch - input.Delta.Y * CONFIG.SENSITIVITAS_MOUSE,
                -CONFIG.BATAS_PITCH, CONFIG.BATAS_PITCH)
    end
end))

--═══════════════ EVENT KARAKTER ═══════════════
addConn(LocalPlayer.CharacterAdded:Connect(function(char)
    setHitamPutih(false)
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    hum.Died:Connect(function()
        if freecamAktif then setHitamPutih(true) end
    end)
    task.wait(0.2)
    if S.speedOn or S.jumpOn then applyMovement() end
end))

addConn(LocalPlayer.CharacterRemoving:Connect(function(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then savedHum[hum] = nil end
end))

addConn(Players.PlayerRemoving:Connect(function(plr)
    infoRefs[plr] = nil
    if plr.Character then
        pcall(cleanupInfo, plr.Character)
        pcall(cleanupHitbox, plr.Character)
    end
end))

--═══════════════ LOOP SYNC INFO/HITBOX ═══════════════
task.spawn(function()
    while gui.Parent do
        if S.infoOn or S.hitboxOn then
            syncDisplays()
        end
        task.wait(INFO_INTERVAL)
    end
end)

--═══════════════ DRAG (title bar) ═══════════════
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

addConn(UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end))

--═══════════════ INISIALISASI ═══════════════
rSpeed.val.Text   = fmt(S.speedValue)
rJump.val.Text    = fmt(S.jumpValue)
rTpJarak.val.Text = fmt(S.tpJarakMundur)
rClock.val.Text   = formatClock(S.clockValue)

segarkanToggle()

task.delay(0.3, function()
    notify("Siiilau v1.8 siap ⚡")
end)

print("[SiiilauHub] SIAP ✔ — F = buka/tutup INSTAN (v1.8 PERFORMANCE FIX ⚡)")
