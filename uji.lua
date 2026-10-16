--========================================================
--  SILAU CLONE v1.0 — COPY AVATAR + EMOTE MIRROR
--  Keybind:
--   F        : buka/tutup GUI
--   L        : copy emote target (auto simpan ke slot kosong)
--   L + 1..8 : mainkan emote slot 1-8
--   J        : hapus semua emote
--   J + 1..8 : hapus slot tertentu
--   P + 1    : copy BADAN      P + 2 : copy WAJAH
--   P + 3    : copy BAJU       P + 4 : copy AKSESORIS
--   P + 8    : copy SEMUA      (P sendirian = tidak ngapa2)
--   O        : hapus copy + kembalikan avatar asli
--  Catatan: hasil copy terlihat di layarmu (client-side).
--========================================================

local VERSI = "1.0"

-- [1] PENGAMAN DASAR -----------------------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
    warn("[SilauClone] GAGAL: harus jalan di CLIENT (executor / LocalScript)!")
    return
end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
if not LocalPlayer then
    warn("[SilauClone] GAGAL: LocalPlayer belum ada.")
    return
end

-- [2] KONFIGURASI ---------------------------------------------------
local TOGGLE_KEY = Enum.KeyCode.F
local KEY_L      = Enum.KeyCode.L
local KEY_P      = Enum.KeyCode.P
local KEY_J      = Enum.KeyCode.J
local KEY_O      = Enum.KeyCode.O

local ICON_SIZE = 36
local LED_TEXT  = "⚡ S I L A U   C L O N E ⚡"
local SOUND_ON  = true
local FX_LEVEL  = 1

local Warna = {
    Ungu      = Color3.fromRGB(124, 58, 237),
    Ungu2     = Color3.fromRGB(167, 139, 250),
    UnguMuda  = Color3.fromRGB(237, 233, 254),
    Biru      = Color3.fromRGB(37, 99, 235),
    Biru2     = Color3.fromRGB(59, 130, 246),
    BiruMuda  = Color3.fromRGB(219, 234, 254),
    Pink      = Color3.fromRGB(236, 72, 153),
    Pink2     = Color3.fromRGB(251, 207, 232),
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

-- [2B] STATE UTAMA --------------------------------------------------
local state = {
    target       = nil,        -- Player yang jadi target
    klikMode     = false,      -- mode "klik pemain di dunia"
    originalDesc = nil,        -- deskripsi avatar asli (untuk restore)
    outfitAktif  = nil,        -- hasil copy terakhir (untuk pasang ulang)
    autoReapply  = true,       -- pasang ulang otomatis setelah respawn
    highlight    = nil,
    emoteSlots   = {},         -- [1..8] = animationId
    myEmoteTrack = nil,
    autoMirror   = false,
    mirrorSource = "semua",    -- "semua" | "target"
    seenMirrors  = {},
    seenCount    = 0,
}

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
screenGui.Name = "SilauCloneGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9998
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() screenGui.OnTopOfCoreBlur = true end)

local kandidatParent = {}
pcall(function() if gethui then table.insert(kandidatParent, gethui()) end end)
pcall(function() table.insert(kandidatParent, game:GetService("CoreGui")) end)
pcall(function() table.insert(kandidatParent, LocalPlayer:WaitForChild("PlayerGui")) end)

for _, t in ipairs(kandidatParent) do
    pcall(function()
        local lama = t:FindFirstChild("SilauCloneGui")
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
    warn("[SilauClone] GAGAL: tidak bisa memasang GUI.")
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

local function gayaToggle(btn, on)
    btn.BackgroundColor3 = on and Warna.Hijau or Warna.Merah
    btn.BackgroundTransparency = on and 0.78 or 0.82
    btn.TextColor3 = on and Warna.HijauMuda or Warna.MerahMuda
end

-- [8] BANGUN UI -----------------------------------------------------
local root = buat("Frame", {
    Size = UDim2.fromOffset(340, 592),
    Position = UDim2.new(0.5, 0, 0.12, 0),
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

local borderStroke = buat("UIStroke", {Color = Warna.Pink, Thickness = 3}, outer)
local borderGrad = buat("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Warna.Pink),
        ColorSequenceKeypoint.new(0.25, Warna.Ungu),
        ColorSequenceKeypoint.new(0.50, Warna.Biru2),
        ColorSequenceKeypoint.new(0.75, Warna.Pink),
        ColorSequenceKeypoint.new(1.00, Warna.Ungu2),
    }),
}, borderStroke)
tween(borderGrad, TweenInfo.new(4.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = 360})

local panel = buat("Frame", {
    Size = UDim2.new(1, -10, 1, -10),
    Position = UDim2.new(0, 5, 0, 5),
    BackgroundColor3 = Warna.PutihLap,
    BorderSizePixel = 0,
}, outer)
buat("UICorner", {CornerRadius = UDim.new(0, 11)}, panel)
buat("UIStroke", {Color = Warna.Pink2, Thickness = 1, Transparency = 0.35}, panel)
ledSweep(panel, Warna.PutihLap, Warna.Putih, Warna.Pink2, 5)

local breath = buat("UIScale", {Scale = 1}, outer)
tween(breath, TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Scale = 1.012})

local partBox = buat("Frame", {
    Name = "NoFade",
    Position = UDim2.new(0, 4, 0, 50),
    Size = UDim2.new(1, -8, 1, -90),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, panel)

for i = 1, 3 do
    local stripe = buat("Frame", {
        Name = "NoFade",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.3 * i, 0, 0.5, 0),
        Size = UDim2.fromOffset(26, 520),
        Rotation = 24,
        BackgroundColor3 = i % 2 == 0 and Warna.Pink2 or Warna.BiruMuda,
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
    Size = UDim2.new(1, -100, 1, 0),
    FontFace = fnt("judul"),
    Text = "⚡ CLONE ⚡",
    TextColor3 = Warna.Putih,
    TextSize = 21,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)
ledSweep(title, Warna.Putih, Warna.Pink2, Warna.Biru2, 2.2)

local titleGlow = buat("UIStroke", {Name = "NoFade", Color = Warna.Pink2, Thickness = 1, Transparency = 0.35}, title)
task.spawn(function()
    while title.Parent do
        tween(titleGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.75})
        task.wait(0.8)
        if not title.Parent then break end
        tween(titleGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.35})
        task.wait(0.8)
    end
end)

local helpBtn = buat("TextButton", {
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.new(1, -72, 0.5, -14),
    BackgroundColor3 = Warna.Hitam,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "?",
    TextColor3 = Warna.Pink2,
    TextSize = 16,
    AutoButtonColor = false,
}, header)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, helpBtn)
buat("UIStroke", {Color = Warna.Pink, Thickness = 1, Transparency = 0.3}, helpBtn)

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
ledSweep(accent, Warna.Biru, Warna.Putih, Warna.Pink, 2.6)

-- TAB BAR
local tabBar = buat("Frame", {
    Position = UDim2.new(0, 10, 0, 52),
    Size = UDim2.new(1, -20, 0, 32),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, panel)
buat("UIListLayout", {Padding = UDim.new(0, 6), FillDirection = Enum.FillDirection.Horizontal}, tabBar)

local tabBtn1 = buat("TextButton", {
    Size = UDim2.new(0.5, -3, 1, 0),
    BackgroundColor3 = Warna.Hitam2,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "👥 COPY AVATAR",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
    LayoutOrder = 1,
}, tabBar)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, tabBtn1)
local tabStroke1 = buat("UIStroke", {Color = Warna.Pink, Thickness = 1}, tabBtn1)
ledSweep(tabBtn1, Warna.Hitam2, Warna.Pink, Warna.Ungu2, 2.4)

local tabBtn2 = buat("TextButton", {
    Size = UDim2.new(0.5, -3, 1, 0),
    BackgroundColor3 = Warna.AbuItem,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🎬 EMOTE",
    TextColor3 = Warna.TeksGelap,
    TextSize = 12,
    AutoButtonColor = false,
    LayoutOrder = 2,
}, tabBar)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, tabBtn2)
buat("UIStroke", {Color = Warna.AbuTeks, Thickness = 1, Transparency = 0.6}, tabBtn2)

-- TAB 1 : COPY AVATAR
local tab1 = buat("Frame", {
    Position = UDim2.new(0, 10, 0, 90),
    Size = UDim2.new(1, -20, 1, -128),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, panel)

local statusTarget = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 2, 0, 0),
    Size = UDim2.new(1, -4, 0, 16),
    FontFace = fnt("semi"),
    Text = "🎯 Target: belum ada",
    TextColor3 = Warna.AbuTeks,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, tab1)

local klikBtn = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 28),
    Position = UDim2.new(0, 2, 0, 20),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🎯 Klik Pemain",
    TextColor3 = Warna.Putih,
    TextSize = 11,
    AutoButtonColor = false,
}, tab1)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, klikBtn)
ledSweep(klikBtn, Warna.Pink, Warna.Putih, Warna.Ungu2, 2.6)

local dekatBtn = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 28),
    Position = UDim2.new(0.5, 2, 0, 20),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "📍 Terdekat",
    TextColor3 = Warna.Putih,
    TextSize = 11,
    AutoButtonColor = false,
}, tab1)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, dekatBtn)
ledSweep(dekatBtn, Warna.Biru, Warna.Putih, Warna.Pink, 2.6)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 2, 0, 54),
    Size = UDim2.new(1, -4, 0, 14),
    FontFace = fnt("semi"),
    Text = "👥 PEMAIN ONLINE — klik nama = jadi target",
    TextColor3 = Warna.AbuTeks,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, tab1)

local playerScroll = buat("ScrollingFrame", {
    Position = UDim2.new(0, 2, 0, 70),
    Size = UDim2.new(1, -4, 0, 118),
    BackgroundColor3 = Warna.AbuMuda,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Pink,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, tab1)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, playerScroll)
buat("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, playerScroll)

local function tombolKategori(teks, x, y, w)
    local b = buat("TextButton", {
        Size = UDim2.new(w or 0.5, -4, 0, 30),
        Position = UDim2.new(x, y and 0 or 0, 0, y),
        BackgroundColor3 = Warna.Putih,
        BorderSizePixel = 0,
        FontFace = fnt("bold"),
        Text = teks,
        TextColor3 = Warna.Putih,
        TextSize = 11,
        AutoButtonColor = false,
    }, tab1)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, b)
    ledSweep(b, Warna.Ungu, Warna.Putih, Warna.Pink, 2.4)
    return b
end

local btnBadan  = tombolKategori("🧍 P+1  Badan", 0, 196)
btnBadan.Position = UDim2.new(0, 2, 0, 196)
local btnWajah  = tombolKategori("😊 P+2  Wajah", 0, 196)
btnWajah.Position = UDim2.new(0.5, 2, 0, 196)
local btnBaju   = tombolKategori("👕 P+3  Baju", 0, 232)
btnBaju.Position = UDim2.new(0, 2, 0, 232)
local btnAks    = tombolKategori("💇 P+4  Aksesoris", 0, 232)
btnAks.Position = UDim2.new(0.5, 2, 0, 232)

local btnSemua = buat("TextButton", {
    Size = UDim2.new(1, -4, 0, 30),
    Position = UDim2.new(0, 2, 0, 268),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "⚡ P+8  COPY SEMUA",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, tab1)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnSemua)
ledSweep(btnSemua, Warna.Pink, Warna.Putih, Warna.Biru2, 2.0)

local btnKembali = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 28),
    Position = UDim2.new(0, 2, 0, 304),
    BackgroundColor3 = Warna.Biru,
    BackgroundTransparency = 0.78,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🔄 Kembali Asli",
    TextColor3 = Warna.Biru2,
    TextSize = 11,
    AutoButtonColor = false,
}, tab1)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnKembali)
buat("UIStroke", {Color = Warna.Biru, Thickness = 1, Transparency = 0.45}, btnKembali)

local btnHapusCopy = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 28),
    Position = UDim2.new(0.5, 2, 0, 304),
    BackgroundColor3 = Warna.Merah,
    BackgroundTransparency = 0.78,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🧹 Hapus Copy (O)",
    TextColor3 = Warna.MerahMuda,
    TextSize = 11,
    AutoButtonColor = false,
}, tab1)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnHapusCopy)
buat("UIStroke", {Color = Warna.Merah, Thickness = 1, Transparency = 0.45}, btnHapusCopy)

local btnReapply = buat("TextButton", {
    Size = UDim2.new(1, -4, 0, 24),
    Position = UDim2.new(0, 2, 0, 338),
    BackgroundColor3 = Warna.Hijau,
    BackgroundTransparency = 0.78,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "♻️ Pasang-ulang otomatis: ON",
    TextColor3 = Warna.HijauMuda,
    TextSize = 10,
    AutoButtonColor = false,
}, tab1)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnReapply)
buat("UIStroke", {Color = Warna.Hijau, Thickness = 1, Transparency = 0.45}, btnReapply)

local statusCopy = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 2, 0, 366),
    Size = UDim2.new(1, -4, 0, 14),
    FontFace = fnt("reg"),
    Text = "💤 belum ada copy",
    TextColor3 = Warna.AbuGelap,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, tab1)

-- TAB 2 : EMOTE MIRROR
local tab2 = buat("Frame", {
    Position = UDim2.new(0, 10, 0, 90),
    Size = UDim2.new(1, -20, 1, -128),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
}, panel)

local statusEmote = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 2, 0, 0),
    Size = UDim2.new(1, -4, 0, 16),
    FontFace = fnt("semi"),
    Text = "🎬 Siap — L = copy emote target",
    TextColor3 = Warna.AbuTeks,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, tab2)

local btnCopyEmote = buat("TextButton", {
    Size = UDim2.new(1, -4, 0, 30),
    Position = UDim2.new(0, 2, 0, 20),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🎬 L — Copy Emote Target",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, tab2)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnCopyEmote)
ledSweep(btnCopyEmote, Warna.Pink, Warna.Putih, Warna.Biru2, 2.0)

local btnMirror = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 26),
    Position = UDim2.new(0, 2, 0, 56),
    BackgroundColor3 = Warna.Merah,
    BackgroundTransparency = 0.82,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🪞 Auto-Mirror: OFF",
    TextColor3 = Warna.MerahMuda,
    TextSize = 10,
    AutoButtonColor = false,
}, tab2)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnMirror)
buat("UIStroke", {Color = Warna.Merah, Thickness = 1, Transparency = 0.45}, btnMirror)

local btnSumber = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 26),
    Position = UDim2.new(0.5, 2, 0, 56),
    BackgroundColor3 = Warna.Biru,
    BackgroundTransparency = 0.78,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🌍 Sumber: Semua",
    TextColor3 = Warna.Biru2,
    TextSize = 10,
    AutoButtonColor = false,
}, tab2)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnSumber)
buat("UIStroke", {Color = Warna.Biru, Thickness = 1, Transparency = 0.45}, btnSumber)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 2, 0, 88),
    Size = UDim2.new(1, -4, 0, 14),
    FontFace = fnt("semi"),
    Text = "💾 SLOT EMOTE — klik = mainkan • J+angka = hapus",
    TextColor3 = Warna.AbuTeks,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, tab2)

local slotBtns = {}
for i = 1, 8 do
    local col = (i - 1) % 4
    local row = math.floor((i - 1) / 4)
    local b = buat("TextButton", {
        Size = UDim2.new(0.25, -4, 0, 28),
        Position = UDim2.new(col * 0.25, 2, 0, 104 + row * 32),
        BackgroundColor3 = Warna.AbuMuda,
        BorderSizePixel = 0,
        FontFace = fnt("bold"),
        Text = tostring(i),
        TextColor3 = Warna.AbuTeks,
        TextSize = 12,
        AutoButtonColor = false,
        LayoutOrder = i,
    }, tab2)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, b)
    local st = buat("UIStroke", {Color = Warna.Ungu, Thickness = 1, Transparency = 0.8}, b)
    slotBtns[i] = {btn = b, stroke = st}
end

local btnStopEmote = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 28),
    Position = UDim2.new(0, 2, 0, 174),
    BackgroundColor3 = Warna.Kuning,
    BackgroundTransparency = 0.75,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "⏹ Stop Emote",
    TextColor3 = Warna.TeksGelap,
    TextSize = 11,
    AutoButtonColor = false,
}, tab2)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnStopEmote)
buat("UIStroke", {Color = Warna.Kuning, Thickness = 1, Transparency = 0.4}, btnStopEmote)

local btnHapusEmote = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 28),
    Position = UDim2.new(0.5, 2, 0, 174),
    BackgroundColor3 = Warna.Merah,
    BackgroundTransparency = 0.78,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🗑️ Hapus Semua (J)",
    TextColor3 = Warna.MerahMuda,
    TextSize = 11,
    AutoButtonColor = false,
}, tab2)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnHapusEmote)
buat("UIStroke", {Color = Warna.Merah, Thickness = 1, Transparency = 0.45}, btnHapusEmote)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 2, 0, 210),
    Size = UDim2.new(1, -4, 0, 40),
    FontFace = fnt("reg"),
    Text = "L = copy emote target → otomatis masuk slot kosong.\nL+1..8 = mainkan slot • J = hapus semua • J+1..8 = hapus slot.\nAuto-Mirror meniru emote (prioritas Action) secara real-time.",
    TextColor3 = Warna.AbuGelap,
    TextSize = 9,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
}, tab2)

-- PANEL BANTUAN (di dalam GUI, bukan overlay layar)
local helpPanel = buat("Frame", {
    Position = UDim2.new(0, 6, 0, 52),
    Size = UDim2.new(1, -12, 1, -92),
    BackgroundColor3 = Warna.Hitam2,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 50,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 10)}, helpPanel)
buat("UIStroke", {Color = Warna.Pink, Thickness = 1, Transparency = 0.4, ZIndex = 50}, helpPanel)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -24, 0, 16),
    FontFace = fnt("judul"),
    Text = "⌨ KEYBIND",
    TextColor3 = Warna.Pink2,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 51,
}, helpPanel)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 28),
    Size = UDim2.new(1, -24, 1, -76),
    FontFace = fnt("med"),
    Text =
        "F          : buka/tutup GUI\n" ..
        "L          : copy emote target (slot otomatis)\n" ..
        "L + 1..8   : mainkan emote slot\n" ..
        "J          : hapus semua emote\n" ..
        "J + 1..8   : hapus slot tertentu\n" ..
        "P + 1      : copy BADAN\n" ..
        "P + 2      : copy WAJAH\n" ..
        "P + 3      : copy BAJU\n" ..
        "P + 4      : copy AKSESORIS\n" ..
        "P + 8      : copy SEMUA\n" ..
        "P          : (sendirian) tidak ngapa-ngapain\n" ..
        "O          : hapus copy + kembali avatar asli",
    TextColor3 = Warna.UnguMuda,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    ZIndex = 51,
}, helpPanel)

local helpClose = buat("TextButton", {
    Size = UDim2.new(1, -24, 0, 26),
    Position = UDim2.new(0, 12, 1, -34),
    BackgroundColor3 = Warna.Pink,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "✕ TUTUP",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
    ZIndex = 51,
}, helpPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, helpClose)

-- FOOTER
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
ledSweep(footer, Warna.Hitam2, Warna.Pink, Warna.Ungu, 3.2)

local ledLabel = buat("TextLabel", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 17),
    FontFace = fnt("judul"),
    Text = LED_TEXT,
    TextColor3 = Warna.Putih,
    TextSize = 13,
}, footer)
local ledGlow = buat("UIStroke", {Name = "NoFade", Color = Warna.Pink2, Thickness = 1, Transparency = 0.4}, ledLabel)
cycleColor(ledLabel, "TextColor3", {Warna.Putih, Warna.Pink2, Warna.Biru2, Warna.Pink2}, 0.4)
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
    Position = UDim2.fromOffset(340, 0),
    Size = UDim2.fromOffset(950, 13),
    FontFace = fnt("med"),
    Text = "👥 copy avatar per kategori   ✦   🎯 klik pemain / terdekat / daftar   ✦   🎬 L = copy emote • L+1..8 = mainkan   ✦   🪞 auto-mirror   ✦   ♻️ pasang-ulang otomatis   ✦   ⌨ ? = bantuan keybind",
    TextColor3 = Warna.AbuGelap,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, marqueeClip)
tween(marquee, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Position = UDim2.fromOffset(-950, 0)})

-- PARTIKEL AMBIENT
local emojiAmbient = {"✨", "⚡", "💜", "💙", "🩷", "⭐", "💫", "🌟"}
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

-- [9] BURST FX ------------------------------------------------------
local paletKonfeti = {Warna.Ungu, Warna.Pink, Warna.Biru, Warna.Biru2, Warna.Putih, Warna.Pink2}

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

local function pusatDi(gui)
    local sz = gui.AbsoluteSize
    return UDim2.new(0, gui.AbsolutePosition.X - root.AbsolutePosition.X + sz.X / 2,
        0, gui.AbsolutePosition.Y - root.AbsolutePosition.Y + sz.Y / 2)
end

local function fxSukses(btn, emoji)
    bunyi(SND_WHOOSH, 0.35, 1.2)
    konfeti(root, pusatDi(btn), 14)
    emojiBurst(root, pusatDi(btn), emoji or {"✨", "👥", "⚡"}, 5)
    tween(panelScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.965})
    task.delay(0.1, function()
        tween(panelScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    end)
end

-- [10] TOAST --------------------------------------------------------
local function toast(teks, aksen)
    local t = buat("Frame", {
        Name = "NoFade",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -44),
        Size = UDim2.fromOffset(250, 30),
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
        TextSize = 11,
        TextTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 851,
    }, t)

    local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tween(t,  ti, {BackgroundTransparency = 0.05, Position = UDim2.new(0.5, 0, 1, -36)})
    tween(st, ti, {Transparency = 0.15})
    tween(lb, ti, {TextTransparency = 0})

    task.delay(1.5, function()
        local to = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(t,  to, {BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 1, -28)})
        tween(st, to, {Transparency = 1})
        tween(lb, to, {TextTransparency = 1})
        task.delay(0.3, function() t:Destroy() end)
    end)
end

-- [11] IKON MINIMIZE ------------------------------------------------
local icon = buat("Frame", {
    Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
    Position = UDim2.new(0, 10, 1, -10),
    AnchorPoint = Vector2.new(0, 1),
    BackgroundColor3 = Warna.Hitam,
    BorderSizePixel = 0,
    Visible = false,
}, screenGui)
buat("UICorner", {CornerRadius = UDim.new(0, 10)}, icon)
local iconStroke = buat("UIStroke", {Color = Warna.Pink, Thickness = 2}, icon)
local iconScale = buat("UIScale", {Scale = 1}, icon)

local kotakPutih = buat("Frame", {
    Size = UDim2.fromOffset(18, 18),
    Position = UDim2.new(0.5, -9, 0.5, -9),
    BackgroundColor3 = Warna.Pink2,
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

cycleColor(kotakPutih, "BackgroundColor3", {Warna.Pink2, Warna.UnguMuda, Warna.BiruMuda}, 0.8)
icon.MouseEnter:Connect(function()
    tween(iconScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.18})
end)
icon.MouseLeave:Connect(function()
    tween(iconScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
end)

-- [12] KARAKTER & DESKRIPSI -----------------------------------------
local function getMyChar()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char, char:FindFirstChildOfClass("Humanoid")
end

local function pastikanOriginal()
    if state.originalDesc then return end
    local _, hum = getMyChar()
    if hum then
        local ok, d = pcall(hum.GetAppliedDescription, hum)
        if ok and d then state.originalDesc = d end
    end
end

-- Properti HumanoidDescription per kategori
local LIST_BADAN = {
    "DepthScale", "WidthScale", "HeightScale", "HeadScale",
    "BodyTypeScale", "ProportionScale",
    "HeadColor", "TorsoColor",
    "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor",
}
local LIST_WAJAH     = {"Face"}
local LIST_BAJU      = {"Shirt", "Pants", "GraphicTShirt"}
local LIST_AKSESORIS = {
    "BackAccessory", "FaceAccessory", "FrontAccessory", "HairAccessory",
    "HatAccessory", "NeckAccessory", "ShouldersAccessory", "WaistAccessory",
    "EyebrowAccessory", "EyelashAccessory",
}
local LIST_SEMUA = {}
for _, v in ipairs(LIST_BADAN)     do table.insert(LIST_SEMUA, v) end
for _, v in ipairs(LIST_WAJAH)     do table.insert(LIST_SEMUA, v) end
for _, v in ipairs(LIST_BAJU)      do table.insert(LIST_SEMUA, v) end
for _, v in ipairs(LIST_AKSESORIS) do table.insert(LIST_SEMUA, v) end

local function updateStatusCopy()
    if state.outfitAktif then
        statusCopy.Text = "🧬 copy aktif — respawn otomatis dipasang ulang"
        statusCopy.TextColor3 = Warna.HijauMuda
    else
        statusCopy.Text = "💤 belum ada copy"
        statusCopy.TextColor3 = Warna.AbuGelap
    end
end

local function salinAvatar(daftarProp, label, btnFx)
    pastikanOriginal()
    local _, hum = getMyChar()
    if not hum or hum.Health <= 0 then
        toast("❌ Karakter kamu belum siap", Warna.Merah)
        return
    end

    local target = state.target
    if not target or not target.Parent then
        toast("🎯 Pilih target dulu! (daftar / 📍 / 🎯)", Warna.Merah)
        return
    end
    local tchar = target.Character
    local thum = tchar and tchar:FindFirstChildOfClass("Humanoid")
    if not thum or thum.Health <= 0 then
        toast("❌ Target tidak valid", Warna.Merah)
        return
    end

    -- peringatan kalau rig beda
    if hum.RigType ~= thum.RigType then
        toast("⚠️ Rig beda (R6 vs R15) — hasil terbatas", Warna.Kuning)
    end

    local okT, tDesc = pcall(thum.GetAppliedDescription, thum)
    if not okT or not tDesc then
        toast("❌ Gagal membaca deskripsi target", Warna.Merah)
        return
    end
    local okM, mDesc = pcall(hum.GetAppliedDescription, hum)
    if not okM or not mDesc then
        toast("❌ Gagal membaca deskripsimu", Warna.Merah)
        return
    end

    local n = 0
    for _, prop in ipairs(daftarProp) do
        local okr, v = pcall(function() return tDesc[prop] end)
        if okr and v ~= nil then
            local okw = pcall(function() mDesc[prop] = v end)
            if okw then n += 1 end
        end
    end

    local okA, err = pcall(function() hum:ApplyDescription(mDesc) end)
    if okA then
        state.outfitAktif = mDesc
        updateStatusCopy()
        toast("✅ " .. label .. " dicopy dari " .. target.Name .. " (" .. n .. " data)", Warna.Hijau)
        if btnFx then fxSukses(btnFx, {"👥", "✨", "⚡"}) end
    else
        toast("⚠️ Gagal apply: " .. tostring(err):sub(1, 60), Warna.Merah)
    end
end

local function kembalikanAsli(senyap)
    if not state.originalDesc then
        if not senyap then toast("⚠️ Data avatar asli belum tersedia", Warna.Kuning) end
        return
    end
    local _, hum = getMyChar()
    if not hum then return end
    local ok = pcall(function() hum:ApplyDescription(state.originalDesc) end)
    if ok and not senyap then
        toast("🔄 Avatar asli dikembalikan", Warna.Biru)
    end
end

local function hapusCopy()
    state.outfitAktif = nil
    kembalikanAsli(true)
    updateStatusCopy()
    bunyi(SND_SNAP, 0.35, 0.7)
    toast("🧹 Semua copy dihapus — avatar asli dipasang", Warna.Merah)
end

-- pasang ulang otomatis setelah respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        task.wait(0.8)
        if state.outfitAktif and state.autoReapply then
            local ok = pcall(function() hum:ApplyDescription(state.outfitAktif) end)
            if ok then
                toast("♻️ Outfit copy dipasang ulang otomatis", Warna.Hijau)
            end
        end
    end)
end)

task.spawn(function()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    char:WaitForChild("Humanoid", 10)
    pastikanOriginal()
end)

-- [13] TARGET -------------------------------------------------------
local refreshPlayers -- forward declaration

local targetConn = nil

local function updateStatusTarget()
    local t = state.target
    if t and t.Parent then
        local rig = "R15"
        local hum = t.Character and t.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.RigType == Enum.HumanoidRigType.R6 then rig = "R6" end
        statusTarget.Text = "🎯 Target: " .. t.DisplayName .. " (@" .. t.Name .. ") • " .. rig
        statusTarget.TextColor3 = Warna.Pink2
    else
        statusTarget.Text = "🎯 Target: belum ada"
        statusTarget.TextColor3 = Warna.AbuTeks
    end
end

local function bersihkanHighlight()
    if state.highlight then
        pcall(function() state.highlight:Destroy() end)
        state.highlight = nil
    end
end

local function pasangHighlight(char)
    bersihkanHighlight()
    if not char then return end
    local h = Instance.new("Highlight")
    h.Name = "SilauCloneTarget"
    h.FillTransparency = 1
    h.OutlineColor = Warna.Pink
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
    state.highlight = h
    task.spawn(function()
        while h.Parent do
            tween(h, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {OutlineTransparency = 0.65})
            task.wait(0.7)
            if not h.Parent then break end
            tween(h, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {OutlineTransparency = 0})
            task.wait(0.7)
        end
    end)
end

refreshPlayers = function()
    for _, c in ipairs(playerScroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local daftar = Players:GetPlayers()
    local urut = 0
    for _, p in ipairs(daftar) do
        if p ~= LocalPlayer then
            urut += 1
            local dipilih = (state.target == p)
            local row = buat("TextButton", {
                Size = UDim2.new(1, -6, 0, 24),
                BackgroundColor3 = dipilih and Warna.Hitam2 or Warna.AbuItem,
                BorderSizePixel = 0,
                FontFace = fnt("med"),
                Text = (dipilih and "✔ " or "👤 ") .. p.DisplayName .. " (@" .. p.Name .. ")",
                TextColor3 = dipilih and Warna.Pink2 or Warna.TeksGelap,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                LayoutOrder = urut,
            }, playerScroll)
            buat("UICorner", {CornerRadius = UDim.new(0, 7)}, row)
            if dipilih then
                buat("UIStroke", {Color = Warna.Pink, Thickness = 1, Transparency = 0.3}, row)
            end
            row.MouseButton1Click:Connect(function()
                bunyi(SND_PING, 0.3, 1.1)
                state.target = p
                pasangHighlight(p.Character)
                updateStatusTarget()
                refreshPlayers()
                toast("🎯 Target: " .. p.DisplayName, Warna.Pink)
            end)
        end
    end
    if urut == 0 then
        buat("TextLabel", {
            Size = UDim2.new(1, -6, 0, 40),
            BackgroundTransparency = 1,
            FontFace = fnt("reg"),
            Text = "solo mode — tidak ada pemain lain 😢",
            TextColor3 = Warna.AbuTeks,
            TextSize = 10,
        }, playerScroll)
    end
end

local function setTargetPlayer(p)
    if targetConn then targetConn:Disconnect() targetConn = nil end
    state.target = p
    if p then
        if p.Character then pasangHighlight(p.Character) end
        targetConn = p.CharacterAdded:Connect(function(c)
            task.wait(0.3)
            if state.target == p then pasangHighlight(c) end
        end)
        toast("🎯 Target: " .. p.DisplayName, Warna.Pink)
    else
        bersihkanHighlight()
    end
    updateStatusTarget()
    refreshPlayers()
end

local function targetTerdekat()
    local _, myHum = getMyChar()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then
        toast("❌ Karakter kamu belum siap", Warna.Merah)
        return
    end
    local best, bestD
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local c = p.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - myHrp.Position).Magnitude
                if not bestD or d < bestD then
                    best, bestD = p, d
                end
            end
        end
    end
    if best then
        setTargetPlayer(best)
        toast("📍 Terdekat: " .. best.DisplayName .. " (" .. math.floor(bestD) .. " stud)", Warna.Biru)
    else
        toast("😢 Tidak ada pemain lain di dekatmu", Warna.Merah)
    end
end

local function cariKarakterDari(inst)
    local cur = inst
    while cur and cur ~= workspace do
        if cur:FindFirstChildOfClass("Humanoid") then return cur end
        cur = cur.Parent
    end
    return nil
end

local function aktifkanKlikTarget()
    state.klikMode = true
    bunyi(SND_PING, 0.3, 1.2)
    toast("🎯 Klik pemain di dunia! (klik kanan = batal)", Warna.Pink)
end

local mouse = LocalPlayer:GetMouse()

-- [14] EMOTE --------------------------------------------------------
local refreshSlots -- forward

local function getMyAnimator()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum:FindFirstChildOfClass("Animator")
end

local function stopEmote()
    if state.myEmoteTrack then
        pcall(function() state.myEmoteTrack:Stop(0.15) end)
        state.myEmoteTrack = nil
    end
end

local function mainkanEmoteId(id, senyap)
    local anim = getMyAnimator()
    if not anim or not id then return false end
    stopEmote()
    local a = Instance.new("Animation")
    a.AnimationId = id
    local ok, track = pcall(function() return anim:LoadAnimation(a) end)
    if ok and track then
        pcall(function() track.Priority = Enum.AnimationPriority.Action4 end)
        track:Play()
        state.myEmoteTrack = track
        return true
    end
    if not senyap then
        toast("⚠️ Animasi tidak bisa dimuat (protected)", Warna.Kuning)
    end
    return false
end

local function ambilEmoteTarget()
    local t = state.target
    if not t or not t.Parent then return nil end
    local thum = t.Character and t.Character:FindFirstChildOfClass("Humanoid")
    local tanim = thum and thum:FindFirstChildOfClass("Animator")
    if not tanim then return nil end

    local tracks = tanim:GetPlayingAnimationTracks()
    local pilihan, waktuTerbaik = nil, -1

    -- pilih track Action tertinggi yang paling baru mulai
    for _, tr in ipairs(tracks) do
        local pr = tr.Priority
        local isAction = (pr == Enum.AnimationPriority.Action
            or pr == Enum.AnimationPriority.Action2
            or pr == Enum.AnimationPriority.Action3
            or pr == Enum.AnimationPriority.Action4)
        if isAction then
            local st = 0
            pcall(function() st = tr.StartTime end)
            if st > waktuTerbaik then
                pilihan, waktuTerbaik = tr, st
            end
        end
    end

    -- fallback: track apa pun yang paling baru
    if not pilihan then
        for _, tr in ipairs(tracks) do
            local st = 0
            pcall(function() st = tr.StartTime end)
            if st > waktuTerbaik then
                pilihan, waktuTerbaik = tr, st
            end
        end
    end

    if pilihan then
        local id = ""
        pcall(function() id = pilihan.Animation.AnimationId end)
        if id ~= "" then return id end
    end
    return nil
end

local function copyEmote()
    local id = ambilEmoteTarget()
    if not id then
        toast("❌ Target tidak sedang main emote", Warna.Merah)
        return
    end
    local slot
    for i = 1, 8 do
        if not state.emoteSlots[i] then slot = i break end
    end
    if not slot then
        slot = 8 -- penuh: timpa slot 8
    end
    state.emoteSlots[slot] = id
    if mainkanEmoteId(id) then
        refreshSlots()
        fxSukses(btnCopyEmote, {"🎬", "💃", "✨"})
        toast("🎬 Emote disimpan di slot " .. slot .. " & diputar", Warna.Pink)
    end
end

refreshSlots = function()
    for i = 1, 8 do
        local data = slotBtns[i]
        if data then
            if state.emoteSlots[i] then
                data.btn.BackgroundColor3 = Warna.Hitam2
                data.btn.TextColor3 = Warna.Pink2
                data.stroke.Transparency = 0.1
                data.stroke.Color = Warna.Pink
            else
                data.btn.BackgroundColor3 = Warna.AbuMuda
                data.btn.TextColor3 = Warna.AbuTeks
                data.stroke.Transparency = 0.8
                data.stroke.Color = Warna.Ungu
            end
        end
    end
end

local function mainkanSlot(n)
    local id = state.emoteSlots[n]
    if id then
        if mainkanEmoteId(id) then
            statusEmote.Text = "▶️ Slot " .. n .. " diputar"
            statusEmote.TextColor3 = Warna.HijauMuda
        end
    else
        statusEmote.Text = "❌ Slot " .. n .. " kosong — pakai L untuk mengisi"
        statusEmote.TextColor3 = Warna.MerahMuda
    end
end

local function hapusSlot(n)
    if state.emoteSlots[n] then
        state.emoteSlots[n] = nil
        refreshSlots()
        statusEmote.Text = "🗑️ Slot " .. n .. " dikosongkan"
        statusEmote.TextColor3 = Warna.AbuGelap
        bunyi(SND_SNAP, 0.3, 0.7)
    else
        statusEmote.Text = "Slot " .. n .. " memang kosong"
        statusEmote.TextColor3 = Warna.AbuGelap
    end
end

local function hapusSemuaEmote()
    stopEmote()
    table.clear(state.emoteSlots)
    refreshSlots()
    statusEmote.Text = "🗑️ Semua slot emote dikosongkan"
    statusEmote.TextColor3 = Warna.MerahMuda
    bunyi(SND_SNAP, 0.35, 0.6)
    toast("🗑️ Semua emote tersimpan dihapus", Warna.Merah)
end

-- AUTO-MIRROR (polling animator semua pemain)
local PRIORITAS_EMOTE = {
    [Enum.AnimationPriority.Action]  = true,
    [Enum.AnimationPriority.Action2] = true,
    [Enum.AnimationPriority.Action3] = true,
    [Enum.AnimationPriority.Action4] = true,
}

task.spawn(function()
    while screenGui.Parent do
        if state.autoMirror then
            local sumber
            if state.mirrorSource == "target" then
                if state.target and state.target.Parent then
                    sumber = {state.target}
                else
                    sumber = {}
                end
            else
                sumber = Players:GetPlayers()
            end

            for _, p in ipairs(sumber) do
                if p ~= LocalPlayer and p.Parent then
                    local thum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                    local tanim = thum and thum:FindFirstChildOfClass("Animator")
                    if tanim then
                        local tracks
                        pcall(function() tracks = tanim:GetPlayingAnimationTracks() end)
                        if tracks then
                            for _, tr in ipairs(tracks) do
                                local id = ""
                                pcall(function() id = tr.Animation.AnimationId end)
                                local key = tostring(p.UserId) .. "|" .. id
                                if id ~= "" and not state.seenMirrors[key] then
                                    state.seenMirrors[key] = true
                                    state.seenCount += 1
                                    if state.seenCount > 400 then
                                        table.clear(state.seenMirrors)
                                        state.seenCount = 0
                                    end
                                    pcall(function()
                                        tr.Stopped:Connect(function()
                                            state.seenMirrors[key] = nil
                                        end)
                                    end)
                                    local baru = true
                                    pcall(function() baru = tr.TimePosition < 1.5 end)
                                    if PRIORITAS_EMOTE[tr.Priority] and baru then
                                        if mainkanEmoteId(id, true) then
                                            statusEmote.Text = "🪞 Meniru emote dari " .. p.DisplayName
                                            statusEmote.TextColor3 = Warna.Pink2
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            task.wait(0.5)
        end
        task.wait(0.15)
    end
end)

-- [15] KEYBIND ------------------------------------------------------
local ANGKA_KEYS = {
    [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
    [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8,
    [Enum.KeyCode.KeypadOne] = 1, [Enum.KeyCode.KeypadTwo] = 2,
    [Enum.KeyCode.KeypadThree] = 3, [Enum.KeyCode.KeypadFour] = 4,
    [Enum.KeyCode.KeypadFive] = 5, [Enum.KeyCode.KeypadSix] = 6,
    [Enum.KeyCode.KeypadSeven] = 7, [Enum.KeyCode.KeypadEight] = 8,
}

local KATEGORI_KEYS = {
    [1] = {list = LIST_BADAN,     label = "🧍 Badan"},
    [2] = {list = LIST_WAJAH,     label = "😊 Wajah"},
    [3] = {list = LIST_BAJU,      label = "👕 Baju"},
    [4] = {list = LIST_AKSESORIS, label = "💇 Aksesoris"},
    [8] = {list = LIST_SEMUA,     label = "⚡ Semua"},
}

local tahan = {L = false, P = false, J = false, dipakai = false}

local minimizeGui -- forward
local bukaGui

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if UserInputService:GetFocusedTextBox() then return end

    local k = input.KeyCode

    -- klik-pemain mode
    if state.klikMode then
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state.klikMode = false
            local char = cariKarakterDari(mouse.Target or mouse.TargetModel)
            if char then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == char then
                        setTargetPlayer(p)
                        bunyi(SND_PING, 0.35, 1.3)
                        return
                    end
                end
            end
            toast("❌ Itu bukan pemain — coba lagi", Warna.Merah)
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            state.klikMode = false
            toast("🎯 Mode klik dibatalkan", Warna.AbuGelap)
        end
        return
    end

    if k == TOGGLE_KEY then
        if root.Visible then minimizeGui() else bukaGui() end
        return
    end

    -- angka + tahan L / P / J
    if ANGKA_KEYS[k] then
        local n = ANGKA_KEYS[k]
        if tahan.L and not tahan.dipakai then
            tahan.dipakai = true
            mainkanSlot(n)
        elseif tahan.P and not tahan.dipakai then
            tahan.dipakai = true
            local kat = KATEGORI_KEYS[n]
            if kat then
                salinAvatar(kat.list, kat.label, n == 8 and btnSemua or nil)
            else
                toast("P+" .. n .. " tidak dipakai (1-4 kategori, 8 semua)", Warna.AbuGelap)
            end
        elseif tahan.J and not tahan.dipakai then
            tahan.dipakai = true
            hapusSlot(n)
        end
        return
    end

    if k == KEY_L then
        tahan.L = true
        tahan.dipakai = false
    elseif k == KEY_P then
        tahan.P = true
        tahan.dipakai = false
    elseif k == KEY_J then
        tahan.J = true
        tahan.dipakai = false
    elseif k == KEY_O then
        hapusCopy()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local k = input.KeyCode
    if k == KEY_L then
        if tahan.L and not tahan.dipakai then
            copyEmote() -- L sendirian = copy emote target
        end
        tahan.L = false
    elseif k == KEY_P then
        tahan.P = false -- P sendirian = tidak ngapa-ngapain
    elseif k == KEY_J then
        if tahan.J and not tahan.dipakai then
            hapusSemuaEmote()
        end
        tahan.J = false
    end
end)

-- [16] TAB & BUKA/TUTUP --------------------------------------------
local sesiAnim = 0
local tabAktif = 1

local function pilihTab(n)
    tabAktif = n
    tab1.Visible = (n == 1)
    tab2.Visible = (n == 2)
    if n == 1 then
        tabBtn1.BackgroundColor3 = Warna.Hitam2
        tabBtn1.TextColor3 = Warna.Putih
        tabStroke1.Color = Warna.Pink
        tabBtn2.BackgroundColor3 = Warna.AbuItem
        tabBtn2.TextColor3 = Warna.TeksGelap
        bunyi(SND_PING, 0.25, 1.1)
    else
        tabBtn2.BackgroundColor3 = Warna.Hitam2
        tabBtn2.TextColor3 = Warna.Putih
        tabStroke1.Color = Warna.AbuTeks
        tabBtn1.BackgroundColor3 = Warna.AbuItem
        tabBtn1.TextColor3 = Warna.TeksGelap
        bunyi(SND_PING, 0.25, 1.25)
    end
end

minimizeGui = function()
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

    task.delay(0.22, function()
        if sesiAnim ~= id then return end
        root.Visible = false
        root.Rotation = 0
        panelScale.Scale = 1
    end)
end

bukaGui = function()
    sesiAnim += 1
    bunyi(SND_PING, 0.35, 1.15)

    icon.Visible = false
    root.Visible = true
    root.Rotation = -8
    panelScale.Scale = 0.6

    tween(root, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0})
    tween(panelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})

    konfeti(root, UDim2.new(0.5, 0, 0.5, 0), 12)
    emojiBurst(root, UDim2.new(0.5, 0, 0.5, 0), {"✨", "👥", "🩷", "💙"}, 6)
end

-- [17] KONEKSI UI ---------------------------------------------------
tabBtn1.MouseButton1Click:Connect(function() pilihTab(1) end)
tabBtn2.MouseButton1Click:Connect(function() pilihTab(2) end)

minBtn.MouseButton1Click:Connect(function()
    ripple(minBtn, Warna.Ungu2)
    minimizeGui()
end)
helpBtn.MouseButton1Click:Connect(function()
    ripple(helpBtn, Warna.Pink2)
    helpPanel.Visible = not helpPanel.Visible
    bunyi(SND_PING, 0.3, helpPanel.Visible and 1.2 or 0.9)
end)
helpClose.MouseButton1Click:Connect(function()
    helpPanel.Visible = false
    bunyi(SND_PING, 0.25, 0.9)
end)

klikBtn.MouseButton1Click:Connect(function()
    ripple(klikBtn, Warna.Putih)
    aktifkanKlikTarget()
end)
dekatBtn.MouseButton1Click:Connect(function()
    ripple(dekatBtn, Warna.Putih)
    targetTerdekat()
end)

btnBadan.MouseButton1Click:Connect(function()
    ripple(btnBadan, Warna.Putih)
    salinAvatar(LIST_BADAN, "🧍 Badan", btnBadan)
end)
btnWajah.MouseButton1Click:Connect(function()
    ripple(btnWajah, Warna.Putih)
    salinAvatar(LIST_WAJAH, "😊 Wajah", btnWajah)
end)
btnBaju.MouseButton1Click:Connect(function()
    ripple(btnBaju, Warna.Putih)
    salinAvatar(LIST_BAJU, "👕 Baju", btnBaju)
end)
btnAks.MouseButton1Click:Connect(function()
    ripple(btnAks, Warna.Putih)
    salinAvatar(LIST_AKSESORIS, "💇 Aksesoris", btnAks)
end)
btnSemua.MouseButton1Click:Connect(function()
    ripple(btnSemua, Warna.Putih)
    salinAvatar(LIST_SEMUA, "⚡ Semua", btnSemua)
end)
btnKembali.MouseButton1Click:Connect(function()
    ripple(btnKembali, Warna.Biru2)
    kembalikanAsli()
end)
btnHapusCopy.MouseButton1Click:Connect(function()
    ripple(btnHapusCopy, Warna.Merah)
    hapusCopy()
end)
btnReapply.MouseButton1Click:Connect(function()
    ripple(btnReapply, Warna.HijauMuda)
    state.autoReapply = not state.autoReapply
    gayaToggle(btnReapply, state.autoReapply)
    btnReapply.Text = state.autoReapply and "♻️ Pasang-ulang otomatis: ON" or "♻️ Pasang-ulang otomatis: OFF"
    bunyi(SND_PING, 0.3, state.autoReapply and 1.1 or 0.9)
end)

btnCopyEmote.MouseButton1Click:Connect(function()
    ripple(btnCopyEmote, Warna.Putih)
    copyEmote()
end)
btnMirror.MouseButton1Click:Connect(function()
    ripple(btnMirror, Warna.Pink2)
    state.autoMirror = not state.autoMirror
    gayaToggle(btnMirror, state.autoMirror)
    btnMirror.Text = state.autoMirror and "🪞 Auto-Mirror: ON" or "🪞 Auto-Mirror: OFF"
    statusEmote.Text = state.autoMirror and "🪞 Auto-Mirror AKTIF — ikuti emote!"
        or "🪞 Auto-Mirror mati"
    statusEmote.TextColor3 = state.autoMirror and Warna.HijauMuda or Warna.AbuGelap
    bunyi(SND_PING, 0.35, state.autoMirror and 1.25 or 0.85)
    toast(state.autoMirror and "🪞 Auto-Mirror ON — kamu akan meniru emote"
        or "🪞 Auto-Mirror OFF", state.autoMirror and Warna.Hijau or Warna.Merah)
end)
btnSumber.MouseButton1Click:Connect(function()
    ripple(btnSumber, Warna.Biru2)
    if state.mirrorSource == "semua" then
        state.mirrorSource = "target"
        btnSumber.Text = "🎯 Sumber: Target"
        toast("🪞 Mirror sumber: TARGET saja", Warna.Biru)
    else
        state.mirrorSource = "semua"
        btnSumber.Text = "🌍 Sumber: Semua"
        toast("🪞 Mirror sumber: SEMUA pemain", Warna.Biru)
    end
    bunyi(SND_PING, 0.3, 1.15)
end)
btnStopEmote.MouseButton1Click:Connect(function()
    ripple(btnStopEmote, Warna.TeksGelap)
    stopEmote()
    statusEmote.Text = "⏹ Emote dihentikan"
    statusEmote.TextColor3 = Warna.AbuGelap
    bunyi(SND_SNAP, 0.3, 0.8)
end)
btnHapusEmote.MouseButton1Click:Connect(function()
    ripple(btnHapusEmote, Warna.Merah)
    hapusSemuaEmote()
end)

for i = 1, 8 do
    local data = slotBtns[i]
    if data then
        data.btn.MouseButton1Click:Connect(function()
            ripple(data.btn, Warna.Pink2)
            mainkanSlot(i)
        end)
        efekTombol(data.btn, 1.08)
    end
end

efekTombol(tabBtn1, 1.03)
efekTombol(tabBtn2, 1.03)
efekTombol(minBtn, 1.1)
efekTombol(helpBtn, 1.1)
efekTombol(klikBtn)
efekTombol(dekatBtn)
efekTombol(btnBadan)
efekTombol(btnWajah)
efekTombol(btnBaju)
efekTombol(btnAks)
efekTombol(btnSemua)
efekTombol(btnKembali, 1.05)
efekTombol(btnHapusCopy, 1.05)
efekTombol(btnReapply, 1.04)
efekTombol(btnCopyEmote)
efekTombol(btnMirror, 1.04)
efekTombol(btnSumber, 1.04)
efekTombol(btnStopEmote, 1.05)
efekTombol(btnHapusEmote, 1.05)

buatDraggable(header, root)
buatDraggable(icon, icon, bukaGui)

-- bersihkan kalau pemain keluar
Players.PlayerRemoving:Connect(function(p)
    if state.target == p then
        setTargetPlayer(nil)
        toast("👋 Target keluar game — target direset", Warna.Kuning)
    end
    refreshPlayers()
end)
Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    refreshPlayers()
end)

-- [18] MULAI --------------------------------------------------------
refreshPlayers()
refreshSlots()
updateStatusTarget()
updateStatusCopy()
gayaToggle(btnReapply, state.autoReapply)
pilihTab(1)

task.delay(0.15, bukaGui)

task.delay(1.2, function()
    toast("⚡ SILAU CLONE siap! Tekan ? di pojok untuk keybind", Warna.Pink)
end)

print("[SilauClone v" .. VERSI .. "] SIAP ✔ — F = buka/tutup, ? di GUI = daftar keybind")
print("[SilauClone] P+1 Badan • P+2 Wajah • P+3 Baju • P+4 Aksesoris • P+8 Semua • O hapus copy")
print("[SilauClone] L copy emote • L+1..8 mainkan slot • J hapus semua • J+1..8 hapus slot")
print("[SilauClone] Catatan: copy bersifat client-side (terlihat di layarmu).")
