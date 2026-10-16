--========================================================
--  TELEPORT GUI v5.5 — "SILAU NEON" + AUTO TP + ANTI-AFK
--  Lokasi tersimpan di file executor, dipisah per game.
--  Keybind: F = buka/tutup
--
--  FITUR:
--   💾 Simpan lokasi permanen (per game)
--   🤖 Auto TP  : teleport otomatis semua titik berurutan
--   ⏱ Delay    : global + bisa diset per titik
--   💀 Auto Respawn : habis summit → mati → respawn → ulang dari titik 1
--   🎭 Gerak Summit : saat "tunggu" di summit → jalan/putar/lompat acak
--   🔁 Loop     : habis summit → balik titik 1 tanpa mati (opsional)
--   👻 Anti-AFK : 2 lapis, tak terlihat, menangkal kick 20 menit
--========================================================

-- [1] PENGAMAN DASAR -----------------------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
    warn("[TeleportGui] GAGAL: harus jalan di CLIENT (executor / LocalScript), bukan server!")
    return
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
if not LocalPlayer then
    warn("[TeleportGui] GAGAL: LocalPlayer belum ada. Masuk dulu ke dalam game, lalu execute ulang.")
    return
end

-- [2] KONFIGURASI ---------------------------------------------------
local ICON_SIZE       = 36
local TOGGLE_KEY      = Enum.KeyCode.F
local TELEPORT_OFFSET = 3.5
local LED_TEXT        = "⚡ S I L A U ⚡"
local SOUND_ON        = true
local FX_LEVEL        = 1
local NAMA_FILE       = "TeleportGui_Silau.json" -- file penyimpanan lokasi

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
    HijauMuda = Color3.fromRGB(187, 247, 208),
    Kuning    = Color3.fromRGB(250, 204, 21),
}

-- [2B] PENGATURAN AUTO TP / AUTO RESPAWN (bisa diubah lewat GUI) ----
local AUTO = {
    delayDefault    = 2,     -- detik antar titik (dipakai jika titik tidak punya delay sendiri)
    respawnDelay    = 3,     -- detik berdiri di titik TERAKHIR (summit) sebelum mati
    respawnWait     = 2,     -- detik jeda setelah respawn sebelum TP dimulai lagi
    loop            = true,  -- habis titik terakhir → balik ke titik 1 (tanpa mati)
    autoRespawn     = true,  -- habis titik terakhir → mati + respawn → mulai dari titik 1
    restartJikaMati = true,  -- mati di tengah jalan → otomatis mulai lagi dari titik 1
    gerakSaatDelay  = false, -- true = gerakan acak juga selama delay antar titik (bukan cuma di summit)
}

local autoState = {
    aktif        = false,
    indeks       = 1,
    delay        = AUTO.delayDefault,
    loop         = AUTO.loop,
    respawn      = AUTO.autoRespawn,
    restart      = AUTO.restartJikaMati,
    respawnDelay = AUTO.respawnDelay,
    respawnWait  = AUTO.respawnWait,
    gerak        = true, -- 🎭 gerak bebas saat "tunggu" di summit
}

local autoUI = {} -- elemen UI auto (diisi di bagian [8B])

-- [3] FONT KOMPATIBEL -----------------------------------------------
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
    cacheFont[k] = v
    return v
end

local TEKS_CLASS = {TextLabel = true, TextButton = true, TextBox = true}

-- [4] HELPER --------------------------------------------------------
local rnd = math.random

local function buat(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k == "FontFace" and TEKS_CLASS[class] and not FONT_OK then
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

local SND_PING   = "rbxasset://sounds/electronicpingshort.wav"
local SND_SNAP   = "rbxasset://sounds/snap.mp3"
local SND_WHOOSH = "rbxasset://sounds/unsheath.wav"

-- [5] SCREENGUI -----------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportGui"
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
        local lama = t:FindFirstChild("TeleportGui")
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
    warn("[TeleportGui] GAGAL: tidak bisa memasang GUI.")
    return
end

local function bunyi(id, vol, pitch)
    if not SOUND_ON then return end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = vol or 0.35
    s.PlaybackSpeed = pitch or 1
    s.Parent = screenGui
    s:Play()
    task.delay(3, function() s:Destroy() end)
end

-- [6] EFEK LED ------------------------------------------------------
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

-- [7] HELPER UI -----------------------------------------------------
local function buatDraggable(handle, target, onClickIfClick)
    local dragging, dragStart, startPos, jarak = false, nil, nil, 0
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos, jarak = true, input.Position, target.Position, 0
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and onClickIfClick and jarak < 6 then onClickIfClick() end
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            jarak = math.abs(delta.X) + math.abs(delta.Y)
            target.Position = UDim2.new(
                startPos.X.Scale, math.round(startPos.X.Offset + delta.X),
                startPos.Y.Scale, math.round(startPos.Y.Offset + delta.Y)
            )
        end
    end)
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

local function angkaDari(teks)
    local v = tostring(teks):gsub(",", ".")
    return tonumber((v:gsub("[^%d%.]", "")))
end

-- [8] BANGUN UI -----------------------------------------------------
local screenFx = buat("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 900,
}, screenGui)

local root = buat("Frame", {
    Size = UDim2.fromOffset(300, 646),
    Position = UDim2.new(0.5, 0, 0.11, 0),
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

local breath = buat("UIScale", {Scale = 1}, outer)
tween(breath, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.012})

local partBox = buat("Frame", {
    Name = "NoFade",
    Position = UDim2.new(0, 4, 0, 50),
    Size = UDim2.new(1, -8, 1, -94),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, panel)

for i = 1, 3 do
    local stripe = buat("Frame", {
        Name = "NoFade",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.3 * i, 0, 0.5, 0),
        Size = UDim2.fromOffset(26, 540),
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
    Text = "⚡ TELEPORT ⚡",
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

local titleScale = buat("UIScale", {Scale = 1}, title)
tween(titleScale, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.05})

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

local nameBox = buat("TextBox", {
    Size = UDim2.new(1, -116, 0, 34),
    Position = UDim2.new(0, 12, 0, 58),
    BackgroundColor3 = Warna.AbuMuda,
    BorderSizePixel = 0,
    FontFace = fnt("med"),
    PlaceholderText = "📍 Ketik nama lokasi...",
    PlaceholderColor3 = Warna.AbuTeks,
    Text = "",
    TextColor3 = Warna.TeksGelap,
    TextSize = 13,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, nameBox)
local nameStroke = buat("UIStroke", {Color = Warna.Ungu, Thickness = 1, Transparency = 0.5}, nameBox)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10)}, nameBox)

local saveBtn = buat("TextButton", {
    Size = UDim2.fromOffset(92, 34),
    Position = UDim2.new(1, -104, 0, 58),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "💾 SIMPAN",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, saveBtn)
ledSweep(saveBtn, Warna.Ungu, Warna.Putih, Warna.Biru2, 2.4)

local searchBox = buat("TextBox", {
    Size = UDim2.new(1, -24, 0, 30),
    Position = UDim2.new(0, 12, 0, 102),
    BackgroundColor3 = Warna.AbuMuda,
    BorderSizePixel = 0,
    FontFace = fnt("reg"),
    PlaceholderText = "🔍 Cari lokasi...",
    PlaceholderColor3 = Warna.AbuTeks,
    Text = "",
    TextColor3 = Warna.TeksGelap,
    TextSize = 12,
    ClearTextOnFocus = false,
    TextXAlignment = Enum.TextXAlignment.Left,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, searchBox)
local searchStroke = buat("UIStroke", {Color = Warna.Biru, Thickness = 1, Transparency = 0.6}, searchBox)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10)}, searchBox)

local listLabel = buat("TextLabel", {
    Position = UDim2.new(0, 12, 0, 140),
    Size = UDim2.new(1, -24, 0, 16),
    BackgroundTransparency = 1,
    FontFace = fnt("semi"),
    Text = "📍 LOKASI TERSIMPAN • 0",
    TextColor3 = Warna.AbuTeks,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local scroll = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 160),
    Size = UDim2.new(1, -24, 1, -372),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Ungu,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)

-- [8B] PANEL AUTO TP + RESPAWN + ANTI-AFK ---------------------------
local autoPanel = buat("Frame", {
    Name = "AutoPanel",
    Position = UDim2.new(0, 12, 1, -211),
    Size = UDim2.new(1, -24, 0, 170),
    BackgroundColor3 = Warna.Hitam2,
    BorderSizePixel = 0,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 10)}, autoPanel)
buat("UIStroke", {Color = Warna.Ungu, Thickness = 1, Transparency = 0.5}, autoPanel)
ledSweep(autoPanel, Warna.Hitam2, Warna.Ungu, Warna.Biru, 4)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 6),
    Size = UDim2.new(0, 160, 0, 14),
    FontFace = fnt("semi"),
    Text = "🤖 AUTO TP + RESPAWN",
    TextColor3 = Warna.UnguMuda,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, autoPanel)

autoUI.status = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 22),
    Size = UDim2.new(1, -118, 0, 12),
    FontFace = fnt("reg"),
    Text = "⏹ Nonaktif",
    TextColor3 = Warna.AbuGelap,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, autoPanel)

autoUI.btn = buat("TextButton", {
    Size = UDim2.fromOffset(92, 32),
    Position = UDim2.new(1, -100, 0, 8),
    BackgroundColor3 = Warna.Hijau,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "▶ MULAI",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, autoPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, autoUI.btn)
autoUI.btnStroke = buat("UIStroke", {Color = Warna.HijauMuda, Thickness = 1, Transparency = 0.4}, autoUI.btn)

-- baris 2 : delay global + loop
buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 44),
    Size = UDim2.fromOffset(52, 22),
    FontFace = fnt("med"),
    Text = "⏱ Delay",
    TextColor3 = Warna.Putih,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, autoPanel)

autoUI.delayBox = buat("TextBox", {
    Size = UDim2.fromOffset(44, 22),
    Position = UDim2.new(0, 62, 0, 44),
    BackgroundColor3 = Warna.Hitam,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    PlaceholderText = "2",
    PlaceholderColor3 = Warna.AbuGelap,
    Text = tostring(autoState.delay),
    TextColor3 = Warna.HijauMuda,
    TextSize = 11,
    ClearTextOnFocus = false,
}, autoPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 6)}, autoUI.delayBox)
local delayGStroke = buat("UIStroke", {Color = Warna.Hijau, Thickness = 1, Transparency = 0.5}, autoUI.delayBox)
buat("UIPadding", {PaddingLeft = UDim.new(0, 6)}, autoUI.delayBox)
sorotInput(autoUI.delayBox, delayGStroke, 0.5)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 110, 0, 44),
    Size = UDim2.fromOffset(36, 22),
    FontFace = fnt("reg"),
    Text = "detik",
    TextColor3 = Warna.AbuGelap,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, autoPanel)

autoUI.loopBtn = buat("TextButton", {
    Size = UDim2.fromOffset(94, 22),
    Position = UDim2.new(1, -104, 0, 44),
    BackgroundColor3 = Warna.Hijau,
    BackgroundTransparency = 0.78,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🔁 Loop: ON",
    TextColor3 = Warna.HijauMuda,
    TextSize = 10,
    AutoButtonColor = false,
}, autoPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 6)}, autoUI.loopBtn)
buat("UIStroke", {Color = Warna.Hijau, Thickness = 1, Transparency = 0.45}, autoUI.loopBtn)

-- baris 3 : auto respawn + jeda tunggu di summit
autoUI.respawnBtn = buat("TextButton", {
    Size = UDim2.fromOffset(122, 22),
    Position = UDim2.new(0, 10, 0, 70),
    BackgroundColor3 = Warna.Hijau,
    BackgroundTransparency = 0.78,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "💀 Respawn: ON",
    TextColor3 = Warna.HijauMuda,
    TextSize = 10,
    AutoButtonColor = false,
}, autoPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 6)}, autoUI.respawnBtn)
buat("UIStroke", {Color = Warna.Hijau, Thickness = 1, Transparency = 0.45}, autoUI.respawnBtn)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 136, 0, 70),
    Size = UDim2.fromOffset(40, 22),
    FontFace = fnt("reg"),
    Text = "tunggu",
    TextColor3 = Warna.AbuGelap,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, autoPanel)

autoUI.respawnDelayBox = buat("TextBox", {
    Size = UDim2.fromOffset(36, 22),
    Position = UDim2.new(0, 176, 0, 70),
    BackgroundColor3 = Warna.Hitam,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    PlaceholderText = "3",
    PlaceholderColor3 = Warna.AbuGelap,
    Text = tostring(autoState.respawnDelay),
    TextColor3 = Warna.HijauMuda,
    TextSize = 11,
    ClearTextOnFocus = false,
}, autoPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 6)}, autoUI.respawnDelayBox)
local rDelayStroke = buat("UIStroke", {Color = Warna.Hijau, Thickness = 1, Transparency = 0.5}, autoUI.respawnDelayBox)
buat("UIPadding", {PaddingLeft = UDim.new(0, 6)}, autoUI.respawnDelayBox)
sorotInput(autoUI.respawnDelayBox, rDelayStroke, 0.5)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 214, 0, 70),
    Size = UDim2.fromOffset(34, 22),
    FontFace = fnt("reg"),
    Text = "detik",
    TextColor3 = Warna.AbuGelap,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, autoPanel)

-- baris 4 : restart dari titik 1 kalau mati di tengah jalan
autoUI.restartBtn = buat("TextButton", {
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.new(0, 10, 0, 95),
    BackgroundColor3 = Warna.Hijau,
    BackgroundTransparency = 0.78,
    BorderSizePixel = 0,
    FontFace = fnt("reg"),
    Text = "⚰ Mati di tengah jalan → mulai lagi dari titik 1: ON",
    TextColor3 = Warna.HijauMuda,
    TextSize = 10,
    TextTruncate = Enum.TextTruncate.AtEnd,
    AutoButtonColor = false,
}, autoPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 6)}, autoUI.restartBtn)
buat("UIStroke", {Color = Warna.Hijau, Thickness = 1, Transparency = 0.45}, autoUI.restartBtn)

-- baris 5 : ANTI-AFK
autoUI.afkBtn = buat("TextButton", {
    Size = UDim2.fromOffset(118, 22),
    Position = UDim2.new(0, 10, 0, 117),
    BackgroundColor3 = Warna.Hijau,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "👻 Anti-AFK: ON",
    TextColor3 = Warna.HijauMuda,
    TextSize = 10,
    AutoButtonColor = false,
}, autoPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 6)}, autoUI.afkBtn)
buat("UIStroke", {Color = Warna.Hijau, Thickness = 1, Transparency = 0.45}, autoUI.afkBtn)

autoUI.afkStatus = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 134, 0, 117),
    Size = UDim2.new(1, -144, 0, 22),
    FontFace = fnt("reg"),
    Text = "🛡 siaga",
    TextColor3 = Warna.HijauMuda,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, autoPanel)

-- baris 6 : 🎭 GERAK BEBAS SAAT TUNGGU DI SUMMIT
autoUI.gerakBtn = buat("TextButton", {
    Size = UDim2.fromOffset(118, 22),
    Position = UDim2.new(0, 10, 0, 139),
    BackgroundColor3 = Warna.Hijau,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🎭 Gerak Summit: ON",
    TextColor3 = Warna.HijauMuda,
    TextSize = 10,
    AutoButtonColor = false,
}, autoPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 6)}, autoUI.gerakBtn)
buat("UIStroke", {Color = Warna.Hijau, Thickness = 1, Transparency = 0.45}, autoUI.gerakBtn)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 134, 0, 139),
    Size = UDim2.new(1, -144, 0, 22),
    FontFace = fnt("reg"),
    Text = "jalan • putar • lompat (acak)",
    TextColor3 = Warna.AbuGelap,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, autoPanel)

local function gayaToggle(btn, on)
    btn.BackgroundColor3 = on and Warna.Hijau or Warna.Merah
    btn.BackgroundTransparency = on and 0.78 or 0.82
    btn.TextColor3 = on and Warna.HijauMuda or Warna.MerahMuda
end

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
    Text = LED_TEXT,
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
    Position = UDim2.fromOffset(300, 0),
    Size = UDim2.fromOffset(900, 13),
    FontFace = fnt("med"),
    Text = "⌨ F = buka/tutup   ✦   💾 lokasi permanen (auto-save)   ✦   🤖 AUTO TP semua titik   ✦   ⏱ delay per titik   ✦   💀 auto respawn setelah summit   ✦   🎭 gerak bebas saat tunggu   ✦   👻 anti-AFK menangkal kick 20 menit",
    TextColor3 = Warna.AbuGelap,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, marqueeClip)
tween(marquee, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Position = UDim2.fromOffset(-900, 0)})

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
        if FX_LEVEL == 1 and root.Visible then
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
local paletKonfeti = {Warna.Ungu, Warna.Ungu2, Warna.Biru, Warna.Biru2, Warna.Putih}

local function konfeti(parent, pos, n)
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

local function emojiBurst(parent, pos, daftar, n)
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

local function pusatDiRoot(gui)
    local sz = gui.AbsoluteSize
    return UDim2.new(0, gui.AbsolutePosition.X - root.AbsolutePosition.X + sz.X / 2,
        0, gui.AbsolutePosition.Y - root.AbsolutePosition.Y + sz.Y / 2)
end

-- [11] IKON MINIMIZE ------------------------------------------------
local icon = buat("Frame", {
    Name = "Ikon",
    Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
    Position = UDim2.new(0, 10, 1, -10),
    AnchorPoint = Vector2.new(0, 1),
    BackgroundColor3 = Warna.Hitam,
    BorderSizePixel = 0,
    Visible = false,
}, screenGui)
buat("UICorner", {CornerRadius = UDim.new(0, 10)}, icon)
local iconStroke = buat("UIStroke", {Color = Warna.Ungu, Thickness = 2}, icon)
local iconScale = buat("UIScale", {Scale = 1}, icon)

local kotakPutih = buat("Frame", {
    Size = UDim2.fromOffset(18, 18),
    Position = UDim2.new(0.5, -9, 0.5, -9),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    Rotation = 18,
}, icon)
buat("UICorner", {CornerRadius = UDim.new(0, 3)}, kotakPutih)
local lubang = buat("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(0.5, -4, 0.5, -4),
    BackgroundColor3 = Warna.Hitam,
    BorderSizePixel = 0,
}, kotakPutih)
buat("UICorner", {CornerRadius = UDim.new(0, 2)}, lubang)

cycleColor(kotakPutih, "BackgroundColor3", {Warna.Putih, Warna.UnguMuda, Warna.BiruMuda}, 0.8)
icon.MouseEnter:Connect(function()
    tween(iconScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.18})
    tween(kotakPutih, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 30})
end)
icon.MouseLeave:Connect(function()
    tween(iconScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
    tween(kotakPutih, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 18})
end)
task.spawn(function()
    while icon.Parent do
        if icon.Visible then
            tween(iconStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.5})
            task.wait(0.8)
            if not icon.Parent then break end
            tween(iconStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0})
            task.wait(0.8)
        else
            task.wait(0.5)
        end
    end
end)

local function pulseIkon()
    if not icon.Visible then return end
    tween(iconScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 1, true), {Scale = 1.35})
end

-- [12] TOAST --------------------------------------------------------
local function toast(teks, aksen)
    local t = buat("Frame", {
        Name = "NoFade",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -44),
        Size = UDim2.fromOffset(240, 30),
        BackgroundColor3 = Warna.Putih,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 850,
    }, root)
    buat("UICorner", {CornerRadius = UDim.new(0, 10)}, t)
    local st = buat("UIStroke", {Color = aksen or Warna.Ungu, Thickness = 1, Transparency = 1}, t)
    local lb = buat("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 0),
        Size = UDim2.new(1, -10, 1, 0),
        FontFace = fnt("semi"),
        Text = teks,
        TextColor3 = Warna.TeksGelap,
        TextSize = 12,
        TextTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, t)

    local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tween(t,  ti, {BackgroundTransparency = 0.05, Position = UDim2.new(0.5, 0, 1, -36)})
    tween(st, ti, {Transparency = 0.15})
    tween(lb, ti, {TextTransparency = 0})

    task.delay(1.4, function()
        local to = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(t,  to, {BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 1, -28)})
        tween(st, to, {Transparency = 1})
        tween(lb, to, {TextTransparency = 1})
        task.delay(0.3, function() t:Destroy() end)
    end)
end

-- [13] FADE PER-ELEMEN ----------------------------------------------
local elemenFade = {}
local fadeVal = Instance.new("NumberValue")

local function kumpulkanFade()
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

local function setFade(t)
    for _, e in ipairs(elemenFade) do
        e[1][e[2]] = e[3] + (1 - e[3]) * t
    end
end

fadeVal.Changed:Connect(setFade)

-- [14] PERSISTENSI LOKASI — simpan ke file executor -----------------
local lokasiTersimpan = {}
local counterNama = 0

local fileOk = (type(writefile) == "function" and type(readfile) == "function")

local function idBaru()
    return tostring(os.time()) .. "-" .. tostring(rnd(100000, 999999))
end

local function muatLokasi()
    if not fileOk then return end
    local isi
    pcall(function() isi = readfile(NAMA_FILE) end)
    if type(isi) ~= "string" or #isi == 0 then return end

    local data
    pcall(function() data = HttpService:JSONDecode(isi) end)
    if type(data) ~= "table" or type(data.games) ~= "table" then return end

    local entri = data.games[tostring(game.PlaceId)]
    if type(entri) ~= "table" then return end

    for _, e in ipairs(entri) do
        if type(e) == "table" and type(e.nama) == "string"
        and type(e.cf) == "table" and #e.cf >= 12 then
            local ok, cf = pcall(CFrame.new, table.unpack(e.cf, 1, 12))
            if ok and cf then
                table.insert(lokasiTersimpan, {
                    id     = tostring(e.id or e.nama),
                    nama   = e.nama,
                    cframe = cf,
                    delay  = tonumber(e.delay), -- delay per titik (boleh nil)
                })
            end
        end
    end
end

local function simpanKeFile()
    if not fileOk then return end

    local data = { games = {} }
    local isi
    pcall(function() isi = readfile(NAMA_FILE) end)
    if type(isi) == "string" and #isi > 0 then
        local lama
        pcall(function() lama = HttpService:JSONDecode(isi) end)
        if type(lama) == "table" and type(lama.games) == "table" then
            data.games = lama.games
        end
    end

    local daftar = {}
    for _, l in ipairs(lokasiTersimpan) do
        table.insert(daftar, {
            id    = l.id,
            nama  = l.nama,
            delay = l.delay,
            cf    = { l.cframe:GetComponents() },
        })
    end
    data.games[tostring(game.PlaceId)] = daftar

    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if ok and type(json) == "string" then
        local okTulis = pcall(function() writefile(NAMA_FILE, json) end)
        if not okTulis then
            warn("[TeleportGui] Gagal menulis file penyimpanan: " .. NAMA_FILE)
        end
    end
end

muatLokasi()

for _, l in ipairs(lokasiTersimpan) do
    local n = tonumber(l.nama:match("^Lokasi (%d+)$"))
    if n and n > counterNama then counterNama = n end
end

-- [15] LOGIKA TELEPORT ----------------------------------------------
local function getKarakter()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function fxTeleport()
    bunyi(SND_WHOOSH, 0.4, 1.1)

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
    hrp.CFrame = cf + Vector3.new(0, TELEPORT_OFFSET, 0)
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function refreshList(animasi)
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end

    local q = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    local daftar = {}
    for _, lok in ipairs(lokasiTersimpan) do
        if q == "" or lok.nama:lower():find(q, 1, true) then
            table.insert(daftar, lok)
        end
    end

    listLabel.Text = (q ~= "" and "🔍 HASIL PENCARIAN" or "📍 LOKASI TERSIMPAN")
        .. string.format(" • %d", #daftar)

    if #daftar == 0 then
        local kosong = buat("Frame", {
            Size = UDim2.new(1, -6, 1, 0), BackgroundTransparency = 1,
        }, scroll)

        local ring = buat("Frame", {
            Name = "NoFade", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0, 50), Size = UDim2.fromOffset(46, 46),
            BackgroundTransparency = 1, BorderSizePixel = 0,
        }, kosong)
        buat("UICorner", {CornerRadius = UDim.new(1, 0)}, ring)
        local ringS = buat("UIStroke", {Color = Warna.Ungu, Thickness = 2, Transparency = 0.4}, ring)
        tween(ringS, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.9})
        tween(ring, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Size = UDim2.fromOffset(58, 58)})

        local pin = buat("TextLabel", {
            Name = "NoFade", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0, 50), Size = UDim2.fromOffset(40, 40),
            BackgroundTransparency = 1, Font = Enum.Font.SourceSans,
            Text = "📍", TextSize = 30,
        }, kosong)
        task.spawn(function()
            while pin.Parent do
                tween(pin, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 0, 44)})
                task.wait(0.9)
                if not pin.Parent then break end
                tween(pin, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 0, 50)})
                task.wait(0.9)
            end
        end)

        buat("TextLabel", {
            Position = UDim2.new(0, 10, 0, 92),
            Size = UDim2.new(1, -20, 0, 40),
            BackgroundTransparency = 1,
            FontFace = fnt("med"),
            Text = q ~= "" and ('Tidak ada hasil untuk "' .. q .. '"')
                or "Belum ada lokasi tersimpan.\nIsi nama lalu klik SIMPAN.",
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
        }, scroll)
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

        local badge = buat("TextLabel", {
            Position = UDim2.new(0, 8, 0.5, -9),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = Warna.Putih,
            BorderSizePixel = 0,
            FontFace = fnt("bold"),
            Text = tostring(i),
            TextColor3 = Warna.Putih,
            TextSize = 11,
        }, item)
        buat("UICorner", {CornerRadius = UDim.new(1, 0)}, badge)
        buat("UIGradient", {Color = ColorSequence.new(Warna.Ungu, Warna.Biru), Rotation = i % 2 == 0 and 25 or -25}, badge)

        local nameEdit = buat("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 32, 0, 0),
            Size = UDim2.new(1, -192, 1, 0),
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
        nameEdit.Focused:Connect(function()
            nameEdit.BackgroundTransparency = 0.85
        end)
        nameEdit.FocusLost:Connect(function()
            nameEdit.BackgroundTransparency = 1
            local baru = nameEdit.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if baru ~= "" and baru ~= lok.nama then
                lok.nama = baru
                simpanKeFile()
            elseif baru == "" then
                nameEdit.Text = lok.nama
            end
        end)

        -- ⏱ DELAY PER TITIK (kosong = pakai delay global)
        local delayBox = buat("TextBox", {
            Size = UDim2.fromOffset(38, 24),
            Position = UDim2.new(1, -152, 0.5, -12),
            BackgroundColor3 = Warna.Putih,
            BorderSizePixel = 0,
            FontFace = fnt("bold"),
            PlaceholderText = "auto",
            PlaceholderColor3 = Warna.AbuTeks,
            Text = lok.delay and tostring(lok.delay) or "",
            TextColor3 = Warna.Ungu,
            TextSize = 11,
            ClearTextOnFocus = false,
        }, item)
        buat("UICorner", {CornerRadius = UDim.new(0, 7)}, delayBox)
        local delayStroke = buat("UIStroke", {Color = Warna.Ungu, Thickness = 1, Transparency = 0.65}, delayBox)
        buat("UIPadding", {PaddingLeft = UDim.new(0, 5)}, delayBox)
        sorotInput(delayBox, delayStroke, 0.65)

        delayBox.FocusLost:Connect(function()
            local n = angkaDari(delayBox.Text)
            if n and n > 0 then
                lok.delay = n
                delayBox.Text = tostring(n)
            else
                lok.delay = nil
                delayBox.Text = ""
            end
            simpanKeFile()
        end)

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
            teleportKe(lok.cframe)
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
            bunyi(SND_SNAP, 0.3, 0.7)
            local sc = item:FindFirstChildOfClass("UIScale")
            tween(item, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
            if sc then tween(sc, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.6}) end
            task.delay(0.17, function()
                for idx, l in ipairs(lokasiTersimpan) do
                    if l == lok then
                        table.remove(lokasiTersimpan, idx)
                        break
                    end
                end
                simpanKeFile()
                toast("🗑️ Dihapus: " .. lok.nama, Warna.Merah)
                refreshList(true)
            end)
        end)

        efekTombol(tpBtn)
        efekTombol(delBtn, 1.1)
    end

    kumpulkanFade()
end

local function simpanLokasi()
    local _, hrp = getKarakter()
    if not hrp then return end

    local nama = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if nama == "" then
        counterNama += 1
        nama = "Lokasi " .. counterNama
    end

    table.insert(lokasiTersimpan, {
        id     = idBaru(),
        nama   = nama,
        cframe = hrp.CFrame,
    })
    simpanKeFile()

    nameBox.Text = ""
    nameBox:ReleaseFocus()
    refreshList(true)
    scroll.CanvasPosition = Vector2.new(0, 1e6)

    bunyi(SND_SNAP, 0.4)
    konfeti(root, pusatDiRoot(saveBtn), 16)
    emojiBurst(root, pusatDiRoot(saveBtn), {"🎉", "✨", "💾"}, 6)
    toast(fileOk and ("💾 Tersimpan permanen: " .. nama) or ("💾 Tersimpan: " .. nama), Warna.Ungu)
    pulseIkon()
end

-- [15B] MESIN AUTO TP + AUTO RESPAWN --------------------------------
local function autoSetStatus(teks, warna)
    if autoUI.status then
        autoUI.status.Text = teks
        autoUI.status.TextColor3 = warna or Warna.AbuGelap
    end
end

local function autoUpdateTombol()
    if not autoUI.btn then return end
    if autoState.aktif then
        autoUI.btn.Text = "⏹ STOP"
        autoUI.btn.BackgroundColor3 = Warna.Merah
        autoUI.btnStroke.Color = Warna.MerahMuda
    else
        autoUI.btn.Text = "▶ MULAI"
        autoUI.btn.BackgroundColor3 = Warna.Hijau
        autoUI.btnStroke.Color = Warna.HijauMuda
    end
end

local function matikanKarakter()
    local char, _, hum = getKarakter()
    if hum then
        if hum.SeatPart then hum.Sit = false end
        hum.Health = 0
        task.wait(0.4)
        if hum.Health > 0 and hum.Parent then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
        end
    elseif char then
        pcall(function() char:BreakJoints() end)
    end
end

local function tungguRespawn(charLama, timeout)
    local t0 = os.clock()
    while os.clock() - t0 < (timeout or 25) do
        local char = LocalPlayer.Character
        if char and char ~= charLama then
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
            if hrp then return char end
        end
        task.wait(0.1)
    end
    return nil
end

-- [15C] 🎭 GERAKAN ACAK — dipakai saat "tunggu" sebelum mati ---------
-- Gerakan dibuat NETRAL (bolak-balik) supaya karakter tetap
-- berada di sekitar titik summit dan tidak jatuh/nyasar.
local function gerakanAcak(durasi)
    if (durasi or 0) < 0.6 then return end
    local _, hrp, hum = getKarakter()
    if not hrp or not hum or hum.Health <= 0 then return end

    local awalCf = hrp.CFrame -- posisi summit, untuk dikunci balik di akhir
    local t0 = os.clock()

    local function jalan(arahFn, dur)
        local t = os.clock()
        while autoState.aktif and os.clock() - t < dur do
            if hum.Health <= 0 then break end
            hum:Move(arahFn(), false)
            task.wait(0.08)
        end
        hum:Move(Vector3.zero, false)
    end

    local function putar(sudut, dur)
        local langkah = 8
        for _ = 1, langkah do
            if not autoState.aktif or hum.Health <= 0 then break end
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(sudut / langkah), 0)
            task.wait(dur / langkah)
        end
    end

    while autoState.aktif and os.clock() - t0 < durasi do
        if hum.Health <= 0 then break end

        local pola    = rnd(1, 5)
        local langkah = rnd(25, 45) / 100 -- 0.25 - 0.45 detik per langkah

        if pola == 1 then      -- jalan maju → mundur
            jalan(function() return  hrp.CFrame.LookVector end, langkah)
            jalan(function() return -hrp.CFrame.LookVector end, langkah)
        elseif pola == 2 then  -- mundur → maju
            jalan(function() return -hrp.CFrame.LookVector end, langkah)
            jalan(function() return  hrp.CFrame.LookVector end, langkah)
        elseif pola == 3 then  -- geser kiri → kanan
            jalan(function() return -hrp.CFrame.RightVector end, langkah)
            jalan(function() return  hrp.CFrame.RightVector end, langkah)
        elseif pola == 4 then  -- putar badan → balik arah semula
            local a = rnd(30, 75) * (rnd(0, 1) == 0 and 1 or -1)
            putar(a, 0.5)
            putar(-a, 0.5)
        else                   -- lompat di tempat
            pcall(function() hum.Jump = true end)
            task.wait(0.7)
        end

        task.wait(rnd(10, 25) / 100) -- jeda kecil antar gerakan
    end

    pcall(function() hum:Move(Vector3.zero, false) end)
    pcall(function() hrp.CFrame = awalCf end) -- kunci balik pas di titik summit
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

-- [15D] LOOP UTAMA AUTO TP ------------------------------------------
local function jalankanAutoTP()
    while autoState.aktif do
        local _, hrp, hum = getKarakter()

        -- karakter belum siap / sedang mati
        if not hrp or (hum and hum.Health <= 0) then
            autoSetStatus("⏳ Menunggu karakter siap...", Warna.Kuning)
            task.wait(0.5)
            local _, hrp2 = getKarakter()
            if hrp2 then task.wait(autoState.respawnWait) end

        elseif #lokasiTersimpan == 0 then
            autoSetStatus("⚠️ Belum ada lokasi tersimpan!", Warna.Merah)
            task.wait(1.2)
            autoState.aktif = false

        else
            local lok = lokasiTersimpan[autoState.indeks]

            if lok then
                -- ===== TP ke titik ini =====
                teleportKe(lok.cframe)
                fxTeleport()
                local d = tonumber(lok.delay) or autoState.delay
                autoSetStatus(string.format("🚀 Titik %d/%d — %s (%.1fs)",
                    autoState.indeks, #lokasiTersimpan, lok.nama, d), Warna.HijauMuda)

                if AUTO.gerakSaatDelay and autoState.gerak then
                    gerakanAcak(d)
                else
                    local t0 = os.clock()
                    while autoState.aktif and os.clock() - t0 < d do
                        local _, _, h2 = getKarakter()
                        if h2 and h2.Health <= 0 then break end
                        task.wait(0.1)
                    end
                end

                if autoState.aktif then
                    local _, _, hNow = getKarakter()
                    if not hNow or hNow.Health > 0 then
                        autoState.indeks += 1
                    end
                end
            else
                -- ===== SEMUA TITIK SELESAI (SUMMIT) =====
                if autoState.respawn then
                    if autoState.gerak then
                        -- 🎭 gerak bebas selama waktu "tunggu" lalu mati
                        autoSetStatus(string.format("🎭 Summit! Gerak bebas %.1fs lalu mati...", autoState.respawnDelay), Warna.Ungu2)
                        gerakanAcak(autoState.respawnDelay)
                        if not autoState.aktif then break end
                    else
                        autoSetStatus("🏁 SUMMIT! Mati dalam " .. string.format("%.1f", autoState.respawnDelay) .. "s...", Warna.Ungu2)
                        local t0 = os.clock()
                        while autoState.aktif and os.clock() - t0 < autoState.respawnDelay do
                            task.wait(0.1)
                        end
                        if not autoState.aktif then break end
                    end

                    local charLama = LocalPlayer.Character
                    matikanKarakter()
                    autoSetStatus("💀 Mati... menunggu respawn", Warna.Merah)

                    local charBaru = tungguRespawn(charLama, 25)
                    if charBaru and autoState.aktif then
                        task.wait(autoState.respawnWait)
                        autoState.indeks = 1
                        autoSetStatus("🔄 Mulai ulang dari titik 1", Warna.Biru2)
                        toast("🔄 Respawn! Auto TP mulai ulang dari titik 1", Warna.Biru)
                        task.wait(0.5)
                    else
                        autoState.aktif = false
                        toast("⚠️ Respawn tidak terdeteksi — Auto TP berhenti", Warna.Merah)
                    end

                elseif autoState.loop then
                    autoState.indeks = 1
                    autoSetStatus("🔁 Loop: balik ke titik 1", Warna.Biru2)
                    task.wait(0.4)

                else
                    autoState.aktif = false
                    autoSetStatus("✅ Semua titik selesai", Warna.HijauMuda)
                    toast("✅ Auto TP selesai — semua titik sudah dikunjungi", Warna.Hijau)
                end
            end
        end
    end

    autoUpdateTombol()
end

local function toggleAutoTP()
    autoState.aktif = not autoState.aktif
    bunyi(SND_PING, 0.35, autoState.aktif and 1.2 or 0.8)
    if autoState.aktif then
        autoState.indeks = 1
        autoSetStatus("🚀 Mulai dari titik 1...", Warna.HijauMuda)
        toast("🤖 Auto TP DIMULAI — dari titik 1", Warna.Hijau)
        task.spawn(jalankanAutoTP)
    else
        autoSetStatus("⏹ Dihentikan", Warna.AbuGelap)
        toast("⏹ Auto TP dihentikan", Warna.Merah)
    end
    autoUpdateTombol()
end

-- [16] BUKA / TUTUP -------------------------------------------------
local sesiAnim = 0

local function minimizeGui()
    if not root.Visible then return end
    sesiAnim += 1
    local id = sesiAnim
    bunyi(SND_PING, 0.3, 0.75)

    icon.Visible = true
    iconScale.Scale = 0.4
    kotakPutih.Rotation = 18
    tween(iconScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})

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
    bunyi(SND_PING, 0.35, 1.15)

    icon.Visible = false
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

-- [17] KONEKSI ------------------------------------------------------
minBtn.MouseButton1Click:Connect(function()
    ripple(minBtn, Warna.Ungu2)
    minimizeGui()
end)
saveBtn.MouseButton1Click:Connect(function()
    ripple(saveBtn, Warna.Putih)
    simpanLokasi()
end)
nameBox.FocusLost:Connect(function(enter)
    if enter then simpanLokasi() end
end)
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    refreshList(false)
end)

sorotInput(nameBox, nameStroke, 0.5)
sorotInput(searchBox, searchStroke, 0.6)

efekTombol(saveBtn)
efekTombol(minBtn, 1.1)

buatDraggable(header, root)
buatDraggable(icon, icon, bukaGui)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TOGGLE_KEY then
        if root.Visible then minimizeGui() else bukaGui() end
    end
end)

-- [17B] KONEKSI AUTO TP ---------------------------------------------
autoUI.btn.MouseButton1Click:Connect(function()
    ripple(autoUI.btn, Warna.Putih)
    toggleAutoTP()
end)

autoUI.delayBox.FocusLost:Connect(function()
    local n = angkaDari(autoUI.delayBox.Text)
    if n and n >= 0.2 then
        autoState.delay = n
        autoUI.delayBox.Text = tostring(n)
    else
        autoUI.delayBox.Text = tostring(autoState.delay)
    end
end)

autoUI.respawnDelayBox.FocusLost:Connect(function()
    local n = angkaDari(autoUI.respawnDelayBox.Text)
    if n and n >= 0.5 then
        autoState.respawnDelay = n
        autoUI.respawnDelayBox.Text = tostring(n)
    else
        autoUI.respawnDelayBox.Text = tostring(autoState.respawnDelay)
    end
end)

autoUI.loopBtn.MouseButton1Click:Connect(function()
    ripple(autoUI.loopBtn, Warna.HijauMuda)
    autoState.loop = not autoState.loop
    gayaToggle(autoUI.loopBtn, autoState.loop)
    autoUI.loopBtn.Text = autoState.loop and "🔁 Loop: ON" or "🔁 Loop: OFF"
    bunyi(SND_PING, 0.3, autoState.loop and 1.1 or 0.9)
end)

autoUI.respawnBtn.MouseButton1Click:Connect(function()
    ripple(autoUI.respawnBtn, Warna.HijauMuda)
    autoState.respawn = not autoState.respawn
    gayaToggle(autoUI.respawnBtn, autoState.respawn)
    autoUI.respawnBtn.Text = autoState.respawn and "💀 Respawn: ON" or "💀 Respawn: OFF"
    bunyi(SND_PING, 0.3, autoState.respawn and 1.1 or 0.9)
end)

autoUI.restartBtn.MouseButton1Click:Connect(function()
    ripple(autoUI.restartBtn, Warna.HijauMuda)
    autoState.restart = not autoState.restart
    gayaToggle(autoUI.restartBtn, autoState.restart)
    autoUI.restartBtn.Text = autoState.restart
        and "⚰ Mati di tengah jalan → mulai lagi dari titik 1: ON"
        or  "⚰ Mati di tengah jalan → lanjut di titik yang sama: OFF"
    bunyi(SND_PING, 0.3, autoState.restart and 1.1 or 0.9)
end)

autoUI.gerakBtn.MouseButton1Click:Connect(function()
    ripple(autoUI.gerakBtn, Warna.HijauMuda)
    autoState.gerak = not autoState.gerak
    gayaToggle(autoUI.gerakBtn, autoState.gerak)
    autoUI.gerakBtn.Text = autoState.gerak and "🎭 Gerak Summit: ON" or "🎭 Gerak Summit: OFF"
    bunyi(SND_PING, 0.3, autoState.gerak and 1.15 or 0.9)
    toast(autoState.gerak and "🎭 Gerak saat tunggu summit: AKTIF"
        or "🎭 Gerak saat tunggu summit: MATI", autoState.gerak and Warna.Hijau or Warna.Merah)
end)

efekTombol(autoUI.btn)
efekTombol(autoUI.loopBtn, 1.05)
efekTombol(autoUI.respawnBtn, 1.05)
efekTombol(autoUI.restartBtn, 1.02)
efekTombol(autoUI.gerakBtn, 1.05)

-- kalau mati di tengah jalan (atau respawn), mulai lagi dari titik 1
LocalPlayer.CharacterAdded:Connect(function()
    if autoState.aktif and autoState.restart then
        autoState.indeks = 1
    end
end)

-- [17C] MESIN ANTI-AFK — menangkal kick 20 menit --------------------
local VirtualUser = game:GetService("VirtualUser")

local AFK_CFG = {
    interval     = 240,   -- detik antar intervensi terjadwal (4 menit)
    jitter       = 60,    -- + acak, biar polanya tidak kaku
    jumpMode     = false, -- ubah ke true HANYA kalau game punya anti-AFK sendiri
    jumpInterval = 45,
}

local afkState = { aktif = true, jumlah = 0, terakhir = 0, sudahIngatkan = false }
local inputTerakhir = os.time()
UserInputService.InputBegan:Connect(function() inputTerakhir = os.time() end)

local function afkStatusUpdate()
    if not autoUI.afkStatus then return end
    if afkState.aktif then
        if afkState.terakhir > 0 then
            autoUI.afkStatus.Text = string.format("🛡 %dx • %dm lalu",
                afkState.jumlah, math.floor((os.time() - afkState.terakhir) / 60))
        else
            autoUI.afkStatus.Text = string.format("🛡 %dx • siaga", afkState.jumlah)
        end
        autoUI.afkStatus.TextColor3 = Warna.HijauMuda
    else
        autoUI.afkStatus.Text = "🛡 mati"
        autoUI.afkStatus.TextColor3 = Warna.AbuGelap
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
    print("[Anti-AFK] intervensi #" .. afkState.jumlah .. " (" .. tostring(alasan) .. ")")
    afkStatusUpdate()
end

LocalPlayer.Idled:Connect(function()
    if afkState.aktif then afkIntervensi("event Idled") end
end)

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

task.spawn(function()
    while screenGui.Parent do
        task.wait(30)
        afkStatusUpdate()
    end
end)

task.spawn(function()
    while screenGui.Parent do
        task.wait(10)
        if autoState.aktif and not afkState.aktif and not afkState.sudahIngatkan then
            afkState.sudahIngatkan = true
            toast("⚠️ Auto TP jalan tapi Anti-AFK mati — bisa ke-kick 20 menit!", Warna.Merah)
        end
        if afkState.aktif then afkState.sudahIngatkan = false end
    end
end)

autoUI.afkBtn.MouseButton1Click:Connect(function()
    ripple(autoUI.afkBtn, Warna.HijauMuda)
    afkState.aktif = not afkState.aktif
    gayaToggle(autoUI.afkBtn, afkState.aktif)
    autoUI.afkBtn.Text = afkState.aktif and "👻 Anti-AFK: ON" or "👻 Anti-AFK: OFF"
    bunyi(SND_PING, 0.3, afkState.aktif and 1.15 or 0.85)
    afkStatusUpdate()
    toast(afkState.aktif and "👻 Anti-AFK aktif — aman AFK berjam-jam"
        or "👻 Anti-AFK mati", afkState.aktif and Warna.Hijau or Warna.Merah)
end)

efekTombol(autoUI.afkBtn, 1.05)
afkStatusUpdate()

-- [18] MULAI --------------------------------------------------------
refreshList(true)
task.delay(0.15, bukaGui)

task.delay(1.2, function()
    if #lokasiTersimpan > 0 then
        toast("📂 " .. #lokasiTersimpan .. " lokasi dimuat — siap auto TP", Warna.Biru)
    elseif not fileOk then
        toast("⚠️ Penyimpanan file tidak tersedia — lokasi hanya untuk sesi ini", Warna.Merah)
    end
end)

print("[TeleportGui] SIAP ✔ — tekan F untuk buka/tutup")
print("[TeleportGui] Auto TP: MULAI/STOP di panel bawah. Delay per titik di kotak kecil tiap baris (kosong = pakai delay global).")
print("[TeleportGui] 🎭 Gerak Summit: ON — saat 'tunggu' sebelum mati, karakter jalan/putar/lompat acak lalu kembali ke titik summit.")
print("[TeleportGui] Anti-AFK: aktif otomatis (2 lapis) — status di panel bawah, cek F9 untuk log intervensi.")
print("[TeleportGui] Penyimpanan: " .. (fileOk and ("file '" .. NAMA_FILE .. "' (per game: " .. game.PlaceId .. ")") or "TIDAK TERSEDIA (bukan executor / tanpa file API)"))
