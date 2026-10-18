--========================================================
--  TELEPORT + TRAINING SCRIPT v3.0.0 — ALL-IN-ONE
--  1 script untuk SEMUA: TP + Simpan Lokasi + Training
--
--  FITUR:
--   🚀 TP + Simpan Lokasi (per game, file-based persistence)
--      - Simpan posisi sekarang dengan nama custom / auto
--      - Klik tombol TP untuk teleport ke lokasi tersimpan
--      - Hapus lokasi → nomor otomatis dirapikan
--      - Search / rename lokasi
--   🌗 Auto Terang  : toggle siang ⇄ malam (keybind B / klik tombol)
--   🏃 SpeedWalk    : keybind Q — cycle 17.25 / 21.25 (klik tombol juga bisa)
--   🦘 JumpPower    : keybind J — cycle 51.2 / 65.25 (klik tombol juga bisa)
--
--  KEYBINDS:
--   F = buka/tutup panel
--   Q = cycle WalkSpeed
--   J = cycle JumpPower
--   B = toggle siang ⇄ malam
--
--========================================================

local VERSI = "3.0.0"

-- [1] PENGAMAN DASAR ----------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
    warn("[TeleportTrain] GAGAL: harus jalan di CLIENT (executor / LocalScript).")
    return
end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local Lighting           = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
if not LocalPlayer then
    warn("[TeleportTrain] GAGAL: LocalPlayer belum ada. Masuk ke game dulu.")
    return
end

-- [2] KONFIGURASI — ubah di sini kalau mau ------------
local ICON_SIZE       = 36
local TOGGLE_KEY      = Enum.KeyCode.F        -- buka/tutup panel
local TELEPORT_OFFSET = 3.5
local NAMA_FILE       = "TeleportTrain.json"

-- Training config
local SPEED_OPTIONS   = { 17.25, 21.25 }
local JUMP_OPTIONS    = { 51.2,  65.25 }
local KEY_SPEED       = Enum.KeyCode.Q
local KEY_JUMP        = Enum.KeyCode.J
local KEY_BRIGHT      = Enum.KeyCode.B

local SIANG_CLOCK      = 12
local MALAM_CLOCK      = 0
local BRIGHTNESS_SIANG = 2.5
local BRIGHTNESS_MALAM = 0.3

local Warna = {
    Ungu     = Color3.fromRGB(124, 58, 237),
    Ungu2    = Color3.fromRGB(167, 139, 250),
    UnguMuda = Color3.fromRGB(237, 233, 254),
    Biru     = Color3.fromRGB(37, 99, 235),
    Biru2    = Color3.fromRGB(59, 130, 246),
    BiruMuda = Color3.fromRGB(219, 234, 254),
    Hitam    = Color3.fromRGB(12, 10, 20),
    Hitam2   = Color3.fromRGB(22, 18, 38),
    Putih    = Color3.fromRGB(255, 255, 255),
    PutihLap = Color3.fromRGB(250, 250, 255),
    AbuMuda  = Color3.fromRGB(243, 242, 250),
    AbuItem  = Color3.fromRGB(246, 245, 252),
    TeksGelap= Color3.fromRGB(28, 24, 46),
    AbuTeks  = Color3.fromRGB(130, 125, 155),
    AbuGelap = Color3.fromRGB(160, 155, 185),
    Merah    = Color3.fromRGB(239, 68, 68),
    MerahMuda= Color3.fromRGB(254, 202, 202),
    Hijau    = Color3.fromRGB(34, 197, 94),
    HijauMuda= Color3.fromRGB(187, 247, 208),
    Kuning   = Color3.fromRGB(250, 204, 21),
}

local trainState = {
    speedIdx    = 1,
    jumpIdx     = 1,
    paksaSiang  = nil,
}

-- [3] FONT HELPER (dengan fallback aman) --------------
local FONT_OK = pcall(function()
    return Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Regular)
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

-- [4] HELPER ------------------------------------------
local rnd = math.random

local function buat(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k == "FontFace" and not FONT_OK then
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

local function sorotInput(box, stroke, rest)
    box.Focused:Connect(function()
        tween(stroke, TweenInfo.new(0.15), {Transparency = 0})
    end)
    box.FocusLost:Connect(function()
        tween(stroke, TweenInfo.new(0.2), {Transparency = rest})
    end)
end

-- [5] SCREENGUI — pasang di parent aman ---------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportTrainGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() screenGui.OnTopOfCoreBlur = true end)
pcall(function() screenGui.IgnoreGuiInset = true end)

local kandidatParent = {}
pcall(function() if gethui then table.insert(kandidatParent, gethui()) end end)
pcall(function() table.insert(kandidatParent, game:GetService("CoreGui")) end)
pcall(function() table.insert(kandidatParent, LocalPlayer:WaitForChild("PlayerGui", 5)) end)

for _, t in ipairs(kandidatParent) do
    pcall(function()
        local lama = t:FindFirstChild("TeleportTrainGui")
        if lama then lama:Destroy() end
    end)
end

local terpasang = false
for _, t in ipairs(kandidatParent) do
    if t then
        local ok = pcall(function() screenGui.Parent = t end)
        if ok and screenGui.Parent == t then
            terpasang = true
            break
        end
    end
end
if not terpasang then
    warn("[TeleportTrain] GAGAL: tidak bisa memasang GUI. Coba executor lain (Synapse/Krnl/Fluxus/Script-Ware).")
    return
end

local function bunyi(id, vol, pitch)
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = vol or 0.35
    s.PlaybackSpeed = pitch or 1
    s.Parent = screenGui
    s:Play()
    task.delay(3, function() s:Destroy() end)
end

local SND_PING   = "rbxasset://sounds/electronicpingshort.wav"
local SND_SNAP   = "rbxasset://sounds/snap.mp3"
local SND_WHOOSH = "rbxasset://sounds/unsheath.wav"

-- [6] EFEK LED ----------------------------------------
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

-- [7] HELPER UI - DRAGGABLE ---------------------------
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

-- [8] BANGUN UI - ROOT + PANEL ------------------------
local root = buat("Frame", {
    Size = UDim2.fromOffset(300, 720),
    Position = UDim2.new(0.5, 0, 0.05, 0),
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

local panel = buat("Frame", {
    Size = UDim2.new(1, -10, 1, -10),
    Position = UDim2.new(0, 5, 0, 5),
    BackgroundColor3 = Warna.PutihLap,
    BorderSizePixel = 0,
}, outer)
buat("UICorner", {CornerRadius = UDim.new(0, 11)}, panel)
buat("UIStroke", {Color = Warna.UnguMuda, Thickness = 1, Transparency = 0.35}, panel)
ledSweep(panel, Warna.PutihLap, Warna.Putih, Warna.BiruMuda, 5)

-- HEADER
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
    Text = "⚡ TP + TRAIN ⚡",
    TextColor3 = Warna.Putih,
    TextSize = 21,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)
ledSweep(title, Warna.Putih, Warna.Ungu2, Warna.Biru2, 2.2)

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

-- [8A] TRAINING PANEL (3 tombol) ----------------------
local trainPanel = buat("Frame", {
    Name = "TrainPanel",
    Position = UDim2.new(0, 12, 0, 54),
    Size = UDim2.new(1, -24, 0, 92),
    BackgroundColor3 = Warna.Hitam2,
    BorderSizePixel = 0,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 10)}, trainPanel)
buat("UIStroke", {Color = Warna.Ungu, Thickness = 1, Transparency = 0.5}, trainPanel)
ledSweep(trainPanel, Warna.Hitam2, Warna.Ungu, Warna.Biru, 4)

buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 4),
    Size = UDim2.new(0, 220, 0, 14),
    FontFace = fnt("semi"),
    Text = "🏃 TRAINING OOB",
    TextColor3 = Warna.UnguMuda,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, trainPanel)

-- Speed button
local speedBtn = buat("TextButton", {
    Size = UDim2.fromOffset(86, 32),
    Position = UDim2.new(0, 10, 0, 24),
    BackgroundColor3 = Warna.Biru,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🏃 17.25",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, trainPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, speedBtn)
buat("UIStroke", {Color = Warna.Biru2, Thickness = 1, Transparency = 0.4}, speedBtn)

-- Jump button
local jumpBtn = buat("TextButton", {
    Size = UDim2.fromOffset(86, 32),
    Position = UDim2.new(0, 102, 0, 24),
    BackgroundColor3 = Warna.Hijau,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🦘 51.2",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, trainPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, jumpBtn)
buat("UIStroke", {Color = Warna.HijauMuda, Thickness = 1, Transparency = 0.4}, jumpBtn)

-- Brightness button
local brightBtn = buat("TextButton", {
    Size = UDim2.fromOffset(86, 32),
    Position = UDim2.new(1, -96, 0, 24),
    BackgroundColor3 = Warna.Kuning,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🌞 Auto",
    TextColor3 = Warna.Hitam,
    TextSize = 12,
    AutoButtonColor = false,
}, trainPanel)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, brightBtn)
buat("UIStroke", {Color = Warna.Kuning, Thickness = 1, Transparency = 0.4}, brightBtn)

-- Hint text
buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 64),
    Size = UDim2.new(1, -20, 0, 22),
    FontFace = fnt("reg"),
    Text = "Q=speed  •  J=jump  •  B=terang  •  klik tombol juga bisa",
    TextColor3 = Warna.AbuGelap,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, trainPanel)

-- DIVIDER
buat("Frame", {
    Position = UDim2.new(0, 12, 0, 152),
    Size = UDim2.new(1, -24, 0, 1),
    BackgroundColor3 = Warna.UnguMuda,
    BorderSizePixel = 0,
    BackgroundTransparency = 0.5,
}, panel)

-- [8B] TP SAVE SECTION --------------------------------
local sectionLabel = buat("TextLabel", {
    Position = UDim2.new(0, 12, 0, 158),
    Size = UDim2.new(1, -24, 0, 16),
    BackgroundTransparency = 1,
    FontFace = fnt("semi"),
    Text = "💾 TP + SIMPAN LOKASI",
    TextColor3 = Warna.AbuTeks,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local nameBox = buat("TextBox", {
    Size = UDim2.new(1, -116, 0, 34),
    Position = UDim2.new(0, 12, 0, 178),
    BackgroundColor3 = Warna.AbuMuda,
    BorderSizePixel = 0,
    FontFace = fnt("med"),
    PlaceholderText = "📍 Ketik nama lokasi... (kosong = auto)",
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
    Position = UDim2.new(1, -104, 0, 178),
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
    Position = UDim2.new(0, 12, 0, 218),
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
    Position = UDim2.new(0, 12, 0, 254),
    Size = UDim2.new(1, -24, 0, 16),
    BackgroundTransparency = 1,
    FontFace = fnt("semi"),
    Text = "📍 LOKASI TERSIMPAN • 0",
    TextColor3 = Warna.AbuTeks,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, panel)

local scroll = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 274),
    Size = UDim2.new(1, -24, 1, -310),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Ungu,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)

-- [8C] FOOTER ------------------------------------------
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
    Text = "⚡ S I L A U ⚡",
    TextColor3 = Warna.Putih,
    TextSize = 14,
}, footer)
cycleColor(ledLabel, "TextColor3", {Warna.Putih, Warna.Ungu2, Warna.Biru2, Warna.Ungu2}, 0.4)

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
    Text = "⌨ F = buka/tutup   ✦   💾 TP + lokasi permanen   ✦   🏃 SpeedWalk Q (17.25/21.25)   ✦   🦘 Jump J (51.2/65.25)   ✦   🌗 B = siang/malam",
    TextColor3 = Warna.AbuGelap,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, marqueeClip)
tween(marquee, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Position = UDim2.fromOffset(-900, 0)})

-- [9] TOAST -------------------------------------------
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

-- [10] FX TELEPORT ------------------------------------
local screenFx = buat("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 900,
}, screenGui)

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

    tween(panelScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.965})
    task.delay(0.1, function()
        tween(panelScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    end)
end

-- [11] PERSISTENSI LOKASI -----------------------------
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
            cf    = { l.cframe:GetComponents() },
        })
    end
    data.games[tostring(game.PlaceId)] = daftar

    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if ok and type(json) == "string" then
        pcall(function() writefile(NAMA_FILE, json) end)
    end
end

muatLokasi()

local function nomorUlang()
    local n = 0
    for _, l in ipairs(lokasiTersimpan) do
        if l.nama:match("^Lokasi %d+$") then
            n += 1
            l.nama = "Lokasi " .. n
        end
    end
    counterNama = n
end

nomorUlang()
if fileOk and #lokasiTersimpan > 0 then
    simpanKeFile()
end

-- [12] LOGIKA TELEPORT --------------------------------
local function getKarakter()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function teleportKe(cf)
    local _, hrp, hum = getKarakter()
    if not hrp then return end
    if hum and hum.SeatPart then hum.Sit = false end
    hrp.CFrame = cf + Vector3.new(0, TELEPORT_OFFSET, 0)
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

-- [13] REFRESH LIST -----------------------------------
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
        buat("TextLabel", {
            Name = "NoFade", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0, 50), Size = UDim2.fromOffset(40, 40),
            BackgroundTransparency = 1, Font = Enum.Font.SourceSans,
            Text = "📍", TextSize = 30,
        }, kosong)
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
            Size = UDim2.new(1, -120, 1, 0),
            FontFace = fnt("med"),
            Text = lok.nama,
            TextColor3 = Warna.TeksGelap,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
        }, item)

        nameEdit.FocusLost:Connect(function()
            local baru = nameEdit.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if baru ~= "" and baru ~= lok.nama then
                lok.nama = baru
                nomorUlang()
                nameEdit.Text = lok.nama
                simpanKeFile()
            elseif baru == "" then
                nameEdit.Text = lok.nama
            end
        end)

        local tpBtn = buat("TextButton", {
            Size = UDim2.fromOffset(46, 26),
            Position = UDim2.new(1, -78, 0.5, -13),
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
                local namaHapus = lok.nama
                for idx, l in ipairs(lokasiTersimpan) do
                    if l == lok then
                        table.remove(lokasiTersimpan, idx)
                        break
                    end
                end
                nomorUlang()
                simpanKeFile()
                toast("🗑️ Dihapus: " .. namaHapus, Warna.Merah)
                refreshList(true)
            end)
        end)

        efekTombol(tpBtn)
        efekTombol(delBtn, 1.1)
    end
end

local function simpanLokasi()
    local _, hrp = getKarakter()
    if not hrp then
        toast("⚠️ Karakter belum siap", Warna.Merah)
        return
    end

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
    toast(fileOk and ("💾 Tersimpan: " .. nama) or ("💾 Tersimpan sesi ini: " .. nama), Warna.Ungu)
end

-- [14] TRAINING LOGIC ---------------------------------
local function getHum()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function applySpeed()
    local hum = getHum()
    if not hum then return end
    pcall(function() hum.WalkSpeed = SPEED_OPTIONS[trainState.speedIdx] end)
end

local function applyJump()
    local hum = getHum()
    if not hum then return end
    pcall(function()
        hum.UseJumpPower = true
        hum.JumpPower = JUMP_OPTIONS[trainState.jumpIdx]
    end)
end

local function applyBrightness()
    if trainState.paksaSiang == nil then return end
    local targetTime = trainState.paksaSiang and SIANG_CLOCK or MALAM_CLOCK
    local targetBrt = trainState.paksaSiang and BRIGHTNESS_SIANG or BRIGHTNESS_MALAM
    pcall(function()
        tween(Lighting, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {ClockTime = targetTime, Brightness = targetBrt})
    end)
end

local function updateTrainUI()
    if speedBtn and speedBtn.Parent then
        speedBtn.Text = string.format("🏃 %.2f", SPEED_OPTIONS[trainState.speedIdx])
    end
    if jumpBtn and jumpBtn.Parent then
        jumpBtn.Text = string.format("🦘 %.2f", JUMP_OPTIONS[trainState.jumpIdx])
    end
    if brightBtn and brightBtn.Parent then
        if trainState.paksaSiang == nil then
            brightBtn.Text = "🌞 Auto"
            brightBtn.TextColor3 = Warna.Hitam
        elseif trainState.paksaSiang then
            brightBtn.Text = "🌞 Siang"
            brightBtn.TextColor3 = Warna.Hitam
        else
            brightBtn.Text = "🌙 Malam"
            brightBtn.TextColor3 = Warna.Putih
        end
    end
end

local function cycleSpeed()
    trainState.speedIdx = trainState.speedIdx % #SPEED_OPTIONS + 1
    applySpeed()
    updateTrainUI()
    toast(string.format("🏃 WalkSpeed: %.2f", SPEED_OPTIONS[trainState.speedIdx]), Warna.Biru)
end

local function cycleJump()
    trainState.jumpIdx = trainState.jumpIdx % #JUMP_OPTIONS + 1
    applyJump()
    updateTrainUI()
    toast(string.format("🦘 JumpPower: %.2f", JUMP_OPTIONS[trainState.jumpIdx]), Warna.Hijau)
end

local function toggleBrightness()
    local currentHour = Lighting.ClockTime or 12
    local saatIniSiang = (currentHour >= 6 and currentHour < 18)
    if saatIniSiang then
        trainState.paksaSiang = false
    else
        trainState.paksaSiang = true
    end
    applyBrightness()
    updateTrainUI()
    toast(trainState.paksaSiang and "🌞 Paksa Siang" or "🌙 Paksa Malam", Warna.Kuning)
end

-- Auto re-apply on respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)
    applySpeed()
    applyJump()
    applyBrightness()
end)

-- Initial apply
task.spawn(function()
    task.wait(1)
    applySpeed()
    applyJump()
    updateTrainUI()
end)

-- [15] BUKA / TUTUP -----------------------------------
local sesiAnim = 0

local function minimizeGui()
    if not root.Visible then return end
    sesiAnim += 1
    local id = sesiAnim
    bunyi(SND_PING, 0.3, 0.75)

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

local function bukaGui()
    sesiAnim += 1
    bunyi(SND_PING, 0.35, 1.15)

    root.Visible = true
    root.Rotation = -8
    panelScale.Scale = 0.6

    tween(root, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = 0})
    tween(panelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
end

-- [16] KONEKSI ----------------------------------------
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
efekTombol(speedBtn)
efekTombol(jumpBtn)
efekTombol(brightBtn)

buatDraggable(header, root)

-- Training buttons
speedBtn.MouseButton1Click:Connect(function()
    ripple(speedBtn, Warna.Putih)
    cycleSpeed()
end)
jumpBtn.MouseButton1Click:Connect(function()
    ripple(jumpBtn, Warna.Putih)
    cycleJump()
end)
brightBtn.MouseButton1Click:Connect(function()
    ripple(brightBtn, Warna.Putih)
    toggleBrightness()
end)

-- Keybinds (F + Q + J + B)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TOGGLE_KEY then
        if root.Visible then minimizeGui() else bukaGui() end
    elseif input.KeyCode == KEY_SPEED then
        cycleSpeed()
    elseif input.KeyCode == KEY_JUMP then
        cycleJump()
    elseif input.KeyCode == KEY_BRIGHT then
        toggleBrightness()
    end
end)

-- [17] MULAI ------------------------------------------
refreshList(true)
task.delay(0.15, bukaGui)

task.delay(1.2, function()
    if #lokasiTersimpan > 0 then
        toast("📂 " .. #lokasiTersimpan .. " lokasi dimuat", Warna.Biru)
    elseif not fileOk then
        toast("⚠️ File API tidak tersedia — simpan sesi ini saja", Warna.Merah)
    end
end)

print("==================================================")
print("[TeleportTrain v" .. VERSI .. "] SIAP ✔ — ALL-IN-ONE")
print("[TeleportTrain] F = buka/tutup panel")
print("[TeleportTrain] Q = cycle WalkSpeed (17.25 / 21.25)")
print("[TeleportTrain] J = cycle JumpPower (51.2 / 65.25)")
print("[TeleportTrain] B = toggle siang ⇄ malam (auto-detect)")
print("[TeleportTrain] 💾 TP + Save Lokasi AKTIF (klik SIMPAN)")
print("[TeleportTrain] Penyimpanan: " .. (fileOk and ("file '" .. NAMA_FILE .. "' (PlaceId: " .. game.PlaceId .. ")") or "TIDAK TERSEDIA (executor tanpa file API)"))
print("==================================================")
