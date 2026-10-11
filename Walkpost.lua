--========================================================
--  TIANG PATH GUI v1.4.3 — "SILAU NEON"
--  TAB 1 📍 TIANG  : pasang (Y), koneksi manual pilih 2 tiang
--  TAB 2 🔴 RECORD : rekam jalur (G), mati = hangus,
--                    🎯 solo (tampil 1 saja) + 👁 SEMUA
--  Keybind: F = GUI | Y = pasang tiang | G = rekam
--========================================================

pcall(function()
    if type(getgenv) == "function" and getgenv()._TiangPathBersihkan then
        getgenv()._TiangPathBersihkan()
    end
end)

-- [1] PENGAMAN DASAR -----------------------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
    warn("[TiangPath] GAGAL: harus jalan di CLIENT (executor / LocalScript), bukan server!")
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
    warn("[TiangPath] GAGAL: LocalPlayer belum ada. Masuk dulu ke dalam game, lalu execute ulang.")
    return
end

-- [2] KONFIGURASI ---------------------------------------------------
local ICON_SIZE       = 36
local TOGGLE_KEY      = Enum.KeyCode.F
local PASANG_KEY      = Enum.KeyCode.Y
local REC_KEY         = Enum.KeyCode.G
local TIANG_TINGGI    = 4
local TIANG_TEBAL     = 1.1
local TELEPORT_OFFSET = 3.5
local ANGKAT_GARIS    = 2
local JARAK_SAMPL     = 3
local TINGGI_SCAN     = 250
local TOLERANSI_GARIS = 0.2
local SAMPL_REKAM     = 1.2
local MAX_TITIK       = 2500
local TEBAL_LINE_REK  = 0.08
local TOLERANSI_REK   = 0.06
local LED_TEXT        = "⚡ S I L A U ⚡"
local SOUND_ON        = true
local NAMA_FILE       = "TiangPath_Silau.json"
local NAMA_BACKUP     = "TiangPath_Silau_backup.json"

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
    Hijau     = Color3.fromRGB(57, 255, 20),
    Hijau2    = Color3.fromRGB(16, 185, 129),
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

-- nomor otomatis: ambil nomor terkecil yang belum dipakai
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

-- [4b] REGISTRY KONEKSI ---------------------------------------------
local semuaKoneksi = {}
local refGui, refFolder = nil, nil

local function catat(conn)
    table.insert(semuaKoneksi, conn)
    return conn
end

local function putuskan(conn)
    local i = table.find(semuaKoneksi, conn)
    if i then table.remove(semuaKoneksi, i) end
    pcall(function() conn:Disconnect() end)
end

local jalankanScript -- deklarasi maju

local function unloadScript(sebab)
    for _, c in ipairs(semuaKoneksi) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(semuaKoneksi)

    if refFolder then
        pcall(function() refFolder:Destroy() end)
        refFolder = nil
    end
    if refGui then
        pcall(function() refGui:Destroy() end)
        refGui = nil
    end
    print("[TiangPath] " .. (sebab or "Script ditutup ✔ (data file tetap aman)"))
end

local function resetScript()
    unloadScript("Muat ulang...")
    task.wait(0.1)
    jalankanScript()
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

--=====================================================================
jalankanScript = function()

local refreshList, refreshRekList
local mulaiRekam, stopRekam, toggleRekam

-- [6] SCREENGUI -----------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TiangPathGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() screenGui.OnTopOfCoreBlur = true end)
refGui = screenGui

local kandidatParent = {}
pcall(function() if gethui then table.insert(kandidatParent, gethui()) end end)
pcall(function() table.insert(kandidatParent, game:GetService("CoreGui")) end)
pcall(function() table.insert(kandidatParent, LocalPlayer:WaitForChild("PlayerGui")) end)

for _, t in ipairs(kandidatParent) do
    pcall(function()
        local lama = t:FindFirstChild("TiangPathGui")
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
    warn("[TiangPath] GAGAL: tidak bisa memasang GUI.")
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

-- [7] BANGUN UI -----------------------------------------------------
local screenFx = buat("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 900,
}, screenGui)

local root = buat("Frame", {
    Size = UDim2.fromOffset(300, 500),
    Position = UDim2.new(0.5, 0, 0.20, 0),
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
        Size = UDim2.fromOffset(26, 430),
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
    Text = "⚡ TIANG PATH ⚡",
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

-- [7b] TAB BAR ------------------------------------------------------
local tabTiang = buat("TextButton", {
    Size = UDim2.new(0.5, -6, 0, 26),
    Position = UDim2.new(0, 12, 0, 52),
    BackgroundColor3 = Warna.Ungu,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "📍 TIANG",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, tabTiang)

local tabRekam = buat("TextButton", {
    Size = UDim2.new(0.5, -6, 0, 26),
    Position = UDim2.new(0.5, -6, 0, 52),
    BackgroundColor3 = Warna.AbuMuda,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🔴 RECORD",
    TextColor3 = Warna.AbuTeks,
    TextSize = 12,
    AutoButtonColor = false,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, tabRekam)

-- [7c] KONTEN TAB 1: TIANG ------------------------------------------
local kontenTiang = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, panel)

local nameBox = buat("TextBox", {
    Size = UDim2.new(1, -116, 0, 34),
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
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, nameBox)
local nameStroke = buat("UIStroke", {Color = Warna.Ungu, Thickness = 1, Transparency = 0.5}, nameBox)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10)}, nameBox)

local saveBtn = buat("TextButton", {
    Size = UDim2.fromOffset(92, 34),
    Position = UDim2.new(1, -104, 0, 2),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "➕ PASANG",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, kontenTiang)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, saveBtn)
ledSweep(saveBtn, Warna.Ungu, Warna.Putih, Warna.Biru2, 2.4)

local searchBox = buat("TextBox", {
    Size = UDim2.new(1, -24, 0, 28),
    Position = UDim2.new(0, 12, 0, 42),
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
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, searchBox)
local searchStroke = buat("UIStroke", {Color = Warna.Biru, Thickness = 1, Transparency = 0.6}, searchBox)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10)}, searchBox)

local btnBersih = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 24),
    Position = UDim2.new(0, 12, 0, 76),
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

local btnGaris = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 24),
    Position = UDim2.new(0.5, 4, 0, 76),
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

local btnSambung = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 24),
    Position = UDim2.new(0, 12, 0, 106),
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

local btnPutus = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 24),
    Position = UDim2.new(0.5, 4, 0, 106),
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

local btnPulihkan = buat("TextButton", {
    Size = UDim2.new(1, -24, 0, 24),
    Position = UDim2.new(0, 12, 0, 136),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "♻ PULIHKAN BACKUP",
    TextColor3 = Warna.Putih,
    TextSize = 10,
    AutoButtonColor = false,
}, kontenTiang)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnPulihkan)
buat("UIStroke", {Color = Warna.Biru, Thickness = 1, Transparency = 0.3}, btnPulihkan)

local btnTutup = buat("TextButton", {
    Size = UDim2.new(1, -24, 0, 24),
    Position = UDim2.new(0, 12, 0, 166),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🗑️ HAPUS & TUTUP SCRIPT",
    TextColor3 = Warna.Putih,
    TextSize = 10,
    AutoButtonColor = false,
}, kontenTiang)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnTutup)
buat("UIStroke", {Color = Warna.Merah, Thickness = 1}, btnTutup)

local listLabel = buat("TextLabel", {
    Position = UDim2.new(0, 12, 0, 196),
    Size = UDim2.new(1, -24, 0, 14),
    BackgroundTransparency = 1,
    FontFace = fnt("semi"),
    Text = "📍 TIANG • 0  (klik nomor = pilih)",
    TextColor3 = Warna.AbuTeks,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, kontenTiang)

local scroll = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 214),
    Size = UDim2.new(1, -24, 1, -244),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Ungu,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, kontenTiang)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)

-- [7d] KONTEN TAB 2: RECORD -----------------------------------------
local kontenRekam = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 80),
    Size = UDim2.new(1, 0, 1, -110),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
}, panel)

local recBtn = buat("TextButton", {
    Size = UDim2.new(1, -24, 0, 34),
    Position = UDim2.new(0, 12, 0, 2),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "⏺ MULAI REKAM  [G]",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, kontenRekam)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, recBtn)
ledSweep(recBtn, Warna.Hijau2, Warna.Putih, Warna.Hijau, 2.4)

local statusLabel = buat("TextLabel", {
    Position = UDim2.new(0, 12, 0, 40),
    Size = UDim2.new(1, -24, 0, 14),
    BackgroundTransparency = 1,
    FontFace = fnt("semi"),
    Text = "Belum merekam • tekan [G] atau tombol di atas",
    TextColor3 = Warna.AbuTeks,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, kontenRekam)

local btnTampil = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 24),
    Position = UDim2.new(0, 12, 0, 58),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "👁 LINE: ON",
    TextColor3 = Warna.Putih,
    TextSize = 10,
    AutoButtonColor = false,
}, kontenRekam)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnTampil)
ledSweep(btnTampil, Warna.Hijau2, Warna.Putih, Warna.Hijau, 2.8)

local btnGabung = buat("TextButton", {
    Size = UDim2.new(0.5, -4, 0, 24),
    Position = UDim2.new(0.5, 4, 0, 58),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🔗 GABUNG",
    TextColor3 = Warna.Putih,
    TextSize = 10,
    AutoButtonColor = false,
}, kontenRekam)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnGabung)
ledSweep(btnGabung, Warna.Ungu, Warna.Putih, Warna.Biru2, 2.4)

-- BARU v1.4.3: tampilkan semua
local btnSemua = buat("TextButton", {
    Size = UDim2.new(1, -24, 0, 24),
    Position = UDim2.new(0, 12, 0, 88),
    BackgroundColor3 = Warna.Putih,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "👁 TAMPILKAN SEMUA",
    TextColor3 = Warna.Putih,
    TextSize = 10,
    AutoButtonColor = false,
}, kontenRekam)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btnSemua)
ledSweep(btnSemua, Warna.Biru, Warna.Putih, Warna.Ungu2, 2.8)

local listLabelRek = buat("TextLabel", {
    Position = UDim2.new(0, 12, 0, 118),
    Size = UDim2.new(1, -24, 0, 14),
    BackgroundTransparency = 1,
    FontFace = fnt("semi"),
    Text = "🎥 RECORD • 0  (🎯 = tampil itu saja)",
    TextColor3 = Warna.AbuTeks,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, kontenRekam)

local scrollRek = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 136),
    Size = UDim2.new(1, -24, 1, -172),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Warna.Hijau2,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, kontenRekam)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollRek)

-- [7e] FOOTER -------------------------------------------------------
local footer = buat("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    Position = UDim2.new(0, 0, 1, -30),
    BackgroundColor3 = Warna.Hitam2,
    BorderSizePixel = 0,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 11)}, footer)
buat("Frame", {
    Size = UDim2.new(1, 0, 0, 11),
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
    Position = UDim2.fromOffset(280, 0),
    Size = UDim2.fromOffset(820, 13),
    FontFace = fnt("med"),
    Text = "⌨ F = GUI   ✦   Y = pasang tiang   ✦   G = rekam jalur   ✦   🎯 solo: tampil 1 jalur saja   ✦   👁 SEMUA utk munculkan lagi   ✦   🔗 gabung record   ✦   💀 mati = record hangus   ✦   ♻ backup otomatis",
    TextColor3 = Warna.AbuGelap,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, marqueeClip)
tween(marquee, TweenInfo.new(15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Position = UDim2.fromOffset(-820, 0)})

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

-- [8] PARTIKEL AMBIENT ----------------------------------------------
local emojiAmbient = {"✨", "⚡", "💜", "💙", "⭐", "💫", "🔹", "🌟"}
task.spawn(function()
    while partBox.Parent do
        if root.Visible then
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
local paletKonfeti = {Warna.Ungu, Warna.Ungu2, Warna.Biru, Warna.Biru2, Warna.Putih, Warna.Hijau2}

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

-- [10] IKON MINIMIZE ------------------------------------------------
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

-- [11] TOAST --------------------------------------------------------
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

-- [12] FADE PER-ELEMEN ----------------------------------------------
local elemenFade = {}
local fadeVal = Instance.new("NumberValue")
pcall(function() fadeVal.Parent = screenGui end)

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

-- [13] DUNIA: TIANG -------------------------------------------------
local daftarTiang  = {}
local daftarRekaman = {}
local koneksiAktif = {}
local genPath      = 0

pcall(function()
    local lama = workspace:FindFirstChild("TiangPath_Silau")
    if lama then lama:Destroy() end
end)

local folderDunia = Instance.new("Folder")
folderDunia.Name = "TiangPath_Silau"
pcall(function() folderDunia.Parent = workspace end)
refFolder = folderDunia

local folderRekaman = Instance.new("Folder")
folderRekaman.Name = "Rekaman"
folderRekaman.Parent = folderDunia

local function buatTiangVisual(basePos, nomor)
    local model = Instance.new("Model")
    model.Name = "Tiang_" .. nomor

    local p = Instance.new("Part")
    p.Name = "Batang"
    p.Shape = Enum.PartType.Cylinder
    p.Material = Enum.Material.Neon
    p.Color = Warna.Ungu
    p.Transparency = 0.15
    p.Size = Vector3.new(TIANG_TINGGI, TIANG_TEBAL, TIANG_TEBAL)
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CFrame = CFrame.new(basePos + Vector3.new(0, TIANG_TINGGI / 2, 0))
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
    bb.StudsOffset = Vector3.new(0, TIANG_TINGGI / 2 + 1.1, 0)
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

-- [14] GARIS --------------------------------------------------------
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

        local dasarA, dasarB = tA.cframe.Position, tB.cframe.Position
        local jarak = (Vector3.new(dasarB.X, 0, dasarB.Z)
            - Vector3.new(dasarA.X, 0, dasarA.Z)).Magnitude

        local jumlahSampel = math.clamp(math.ceil(jarak / JARAK_SAMPL), 1, 250)
        local tinggiAtas = math.max(tA.topPos.Y, tB.topPos.Y) + TINGGI_SCAN

        local poin = {tA.topPos}
        local yTerakhir = tA.topPos.Y

        for i = 1, jumlahSampel - 1 do
            local t = i / jumlahSampel
            local titik = dasarA:Lerp(dasarB, t)
            local dari = Vector3.new(titik.X, tinggiAtas, titik.Z)
            local ray = workspace:Raycast(dari, Vector3.new(0, -(tinggiAtas + 50), 0), rayParams)

            local y
            if ray then
                y = ray.Position.Y + ANGKAT_GARIS
            else
                y = yTerakhir
            end
            yTerakhir = y
            table.insert(poin, Vector3.new(titik.X, y, titik.Z))
        end

        table.insert(poin, tB.topPos)
        if myGen ~= genPath then return end

        local poinRapi = sederhanakan(poin, TOLERANSI_GARIS)
        for i = 1, #poinRapi - 1 do
            local warnaG = (i % 2 == 0) and Warna.Biru2 or Warna.Ungu2
            local prt = buatSegmen(poinRapi[i], poinRapi[i + 1], warnaG, nil, folderDunia)
            if prt then table.insert(k.parts, prt) end
        end
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

-- [15] PERSISTENSI ---------------------------------------------------
local fileOk = (type(writefile) == "function" and type(readfile) == "function")

local function idBaru()
    return tostring(os.time()) .. "-" .. tostring(rnd(100000, 999999))
end

local function r2(n)
    return math.floor(n * 100 + 0.5) / 100
end

local function simpanKeFile()
    if not fileOk then return end
    local data = {games = {}}
    local isi
    pcall(function() isi = readfile(NAMA_FILE) end)
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
        table.insert(daftarK, {a = k.a, b = k.b})
    end
    entri.koneksi = daftarK

    local daftarR = {}
    for _, r in ipairs(daftarRekaman) do
        local poinSimpan = {}
        for _, p in ipairs(r.poin) do
            table.insert(poinSimpan, {r2(p.X), r2(p.Y), r2(p.Z)})
        end
        table.insert(daftarR, {
            id     = r.id,
            nama   = r.nama,
            tampil = r.tampil,
            poin   = poinSimpan,
        })
    end
    entri.records = daftarR

    data.games[tostring(game.PlaceId)] = entri

    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if ok and type(json) == "string" then
        pcall(function()
            local isiLama = readfile(NAMA_FILE)
            if type(isiLama) == "string" and #isiLama > 0 then
                writefile(NAMA_BACKUP, isiLama)
            end
        end)

        local okTulis = pcall(function() writefile(NAMA_FILE, json) end)
        if not okTulis then
            warn("[TiangPath] Gagal menulis file penyimpanan: " .. NAMA_FILE)
        end
    end
end

-- [16] LOGIKA TIANG -------------------------------------------------
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

    emojiBurst(screenFx, UDim2.new(0.5, 0, 0.5, 0), {"🚀", "✨", "⚡", "💫", "🌟"}, 10)

    tween(panelScale, TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.965})
    task.delay(0.1, function()
        tween(panelScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    end)
end

local function teleportKe(posisi)
    local _, hrp, hum = getKarakter()
    if not hrp then return end
    if hum and hum.SeatPart then hum.Sit = false end
    hrp.CFrame = CFrame.new(posisi) + Vector3.new(0, TELEPORT_OFFSET, 0)
    hrp.AssemblyLinearVelocity  = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
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
    simpanKeFile()
    toast("🗑️ Dihapus: " .. nama, Warna.Merah)
    refreshList(true)
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
    simpanKeFile()
    toast("🧹 Semua tiang dihapus", Warna.Merah)
    refreshList(true)
end

local function pasangTiang(namaManual)
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
        topPos = basePos + Vector3.new(0, TIANG_TINGGI, 0),
        model  = model,
        batang = batang,
        pilih  = false,
    })
    simpanKeFile()

    refreshList(true)
    scroll.CanvasPosition = Vector2.new(0, 1e6)
    bunyi(SND_SNAP, 0.4)
    konfeti(root, pusatDiRoot(saveBtn), 12)
    emojiBurst(root, pusatDiRoot(saveBtn), {"📍", "⚡", "✨"}, 5)
    toast("➕ " .. nama .. " terpasang • total " .. #daftarTiang, Warna.Ungu)
    pulseIkon()
end

refreshList = function(animasi)
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end

    local q = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    local daftar = {}
    for _, lok in ipairs(daftarTiang) do
        if q == "" or lok.nama:lower():find(q, 1, true) then
            table.insert(daftar, lok)
        end
    end

    listLabel.Text = (q ~= "" and "🔍 HASIL" or "📍 TIANG")
        .. string.format(" • %d  (klik nomor = pilih)", #daftar)

    if #daftar == 0 then
        local kosong = buat("Frame", {
            Size = UDim2.new(1, -6, 1, 0), BackgroundTransparency = 1,
        }, scroll)
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
            Position = UDim2.new(0, 10, 0, 80),
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
            bunyi(SND_PING, 0.2, lok.pilih and 1.3 or 0.9)
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
            bunyi(SND_SNAP, 0.3, 0.7)
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

local function tiangTerpilih()
    local hasil = {}
    for _, t in ipairs(daftarTiang) do
        if t.pilih then table.insert(hasil, t) end
    end
    return hasil
end

local function bersihkanPilihanTiang()
    for _, t in ipairs(daftarTiang) do t.pilih = false end
    refreshList(false)
end

-- [17] RECORD JALUR -------------------------------------------------
local sedangRekam = false
local rekamPoin = {}
local rekamMulai = 0
local rekamConn = nil
local rekamDiedConn = nil
local tampilRekamanGlobal = true

local recBadge, recBadgeLabel = nil, nil
local tepiRekam = {}

local function buatTepiRekam()
    tepiRekam = {}
    local konf = {
        {UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 4)},
        {UDim2.new(0, 0, 1, -4), UDim2.new(1, 0, 0, 4)},
        {UDim2.new(0, 0, 0, 0), UDim2.new(0, 4, 1, 0)},
        {UDim2.new(1, -4, 0, 0), UDim2.new(0, 4, 1, 0)},
    }
    for _, c in ipairs(konf) do
        local f = buat("Frame", {
            Position = c[1], Size = c[2],
            BackgroundColor3 = Warna.Merah,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 960,
        }, screenGui)
        table.insert(tepiRekam, f)
    end
    task.spawn(function()
        while #tepiRekam > 0 and tepiRekam[1].Parent do
            for _, f in ipairs(tepiRekam) do
                tween(f, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.75})
            end
            task.wait(0.55)
            if #tepiRekam == 0 or not tepiRekam[1].Parent then break end
            for _, f in ipairs(tepiRekam) do
                tween(f, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.3})
            end
            task.wait(0.55)
        end
    end)
end

local function hapusTepiRekam()
    for _, f in ipairs(tepiRekam) do
        pcall(function() f:Destroy() end)
    end
    tepiRekam = {}
end

local function formatWaktu(det)
    local m = math.floor(det / 60)
    local s = math.floor(det % 60)
    return string.format("%02d:%02d", m, s)
end

local function resetUIRekam()
    recBtn.Text = "⏺ MULAI REKAM  [G]"
    recBtn.BackgroundColor3 = Warna.Putih
    statusLabel.Text = "Belum merekam • tekan [G] atau tombol di atas"
end

mulaiRekam = function()
    if sedangRekam then return end
    local char, hrp, hum = getKarakter()
    if not hrp then
        toast("⚠️ Karakter belum siap", Warna.Merah)
        return
    end

    sedangRekam = true
    rekamPoin = {hrp.Position}
    rekamMulai = os.clock()

    recBadge = buat("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 10),
        Size = UDim2.fromOffset(210, 32),
        BackgroundColor3 = Warna.Hitam,
        BorderSizePixel = 0,
        ZIndex = 970,
    }, screenGui)
    buat("UICorner", {CornerRadius = UDim.new(0, 9)}, recBadge)
    local bs = buat("UIStroke", {Color = Warna.Merah, Thickness = 2}, recBadge)
    tween(bs, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.6})

    recBadgeLabel = buat("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        FontFace = fnt("bold"),
        Text = "⏺ REC 00:00 • 1 titik",
        TextColor3 = Warna.Merah,
        TextSize = 13,
        ZIndex = 971,
    }, recBadge)

    buatTepiRekam()
    bunyi(SND_PING, 0.35, 1.35)
    toast("⏺ MULAI MEREKAM — jalan sesukamu!", Warna.Hijau2)

    rekamConn = RunService.Heartbeat:Connect(function()
        local _, h = getKarakter()
        if not h then return end
        local pos = h.Position
        local last = rekamPoin[#rekamPoin]
        if not last or (pos - last).Magnitude >= SAMPL_REKAM then
            if #rekamPoin < MAX_TITIK then
                table.insert(rekamPoin, pos)
            else
                toast("⚠️ Record penuh (" .. MAX_TITIK .. " titik) — auto stop", Warna.Merah)
                stopRekam()
            end
        end
    end)
    catat(rekamConn)

    if hum then
        rekamDiedConn = hum.Died:Connect(function()
            if rekamConn then putuskan(rekamConn) rekamConn = nil end
            if rekamDiedConn then putuskan(rekamDiedConn) rekamDiedConn = nil end
            sedangRekam = false
            rekamPoin = {}
            if recBadge then pcall(function() recBadge:Destroy() end) recBadge = nil end
            recBadgeLabel = nil
            hapusTepiRekam()
            resetUIRekam()
            bunyi(SND_SNAP, 0.35, 0.5)
            toast("💀 Kamu mati — record dibatalkan & terhapus", Warna.Merah)
        end)
        catat(rekamDiedConn)
    end

    recBtn.Text = "⏹ STOP REKAM  [G]"
    recBtn.BackgroundColor3 = Warna.Merah
end

stopRekam = function()
    if not sedangRekam then return end
    sedangRekam = false

    if rekamConn then
        putuskan(rekamConn)
        rekamConn = nil
    end
    if rekamDiedConn then
        putuskan(rekamDiedConn)
        rekamDiedConn = nil
    end

    if recBadge then pcall(function() recBadge:Destroy() end) recBadge = nil end
    recBadgeLabel = nil
    hapusTepiRekam()
    resetUIRekam()

    bunyi(SND_SNAP, 0.35, 0.7)

    if #rekamPoin < 2 then
        toast("⚠️ Terlalu pendek — record dibatalkan", Warna.Merah)
        rekamPoin = {}
        return
    end

    local namaNama = {}
    for _, r in ipairs(daftarRekaman) do table.insert(namaNama, r.nama) end
    local namaBaru = "Rekaman " .. nomorBebas("Rekaman", namaNama)

    local rek = {
        id     = idBaru(),
        nama   = namaBaru,
        poin   = rekamPoin,
        tampil = true,
        pilih  = false,
        folder = Instance.new("Folder"),
    }
    rek.folder.Name = "Rek_" .. rek.id
    rek.folder.Parent = folderRekaman
    table.insert(daftarRekaman, rek)
    rekamPoin = {}

    if tampilRekamanGlobal and rek.tampil then
        local poinRapi = sederhanakan(rek.poin, TOLERANSI_REK)
        for i = 1, #poinRapi - 1 do
            buatSegmen(poinRapi[i], poinRapi[i + 1], Warna.Hijau, TEBAL_LINE_REK, rek.folder)
        end
    end

    simpanKeFile()
    refreshRekList(true)
    konfeti(root, pusatDiRoot(recBtn), 14)
    emojiBurst(root, pusatDiRoot(recBtn), {"🎥", "✅", "✨"}, 5)
    toast("✅ " .. rek.nama .. " tersimpan • " .. #rek.poin .. " titik", Warna.Hijau2)
end

toggleRekam = function()
    if sedangRekam then stopRekam() else mulaiRekam() end
end

task.spawn(function()
    while screenGui.Parent do
        task.wait(0.25)
        if sedangRekam and recBadgeLabel and recBadgeLabel.Parent then
            local waktu = formatWaktu(os.clock() - rekamMulai)
            local teks = "⏺ REC " .. waktu .. " • " .. #rekamPoin .. " titik"
            recBadgeLabel.Text = teks
            if statusLabel.Parent then
                statusLabel.Text = "🔴 Merekam " .. waktu .. " • " .. #rekamPoin .. " titik"
            end
        end
    end
end)

local function bangunLineRek(rek)
    rek.folder:ClearAllChildren()
    if tampilRekamanGlobal and rek.tampil then
        local poinRapi = sederhanakan(rek.poin, TOLERANSI_REK)
        for i = 1, #poinRapi - 1 do
            buatSegmen(poinRapi[i], poinRapi[i + 1], Warna.Hijau, TEBAL_LINE_REK, rek.folder)
        end
    end
end

local function hapusRekaman(rek)
    local i = table.find(daftarRekaman, rek)
    if not i then return end
    pcall(function() rek.folder:Destroy() end)
    table.remove(daftarRekaman, i)
    simpanKeFile()
    toast("🗑️ Record dihapus: " .. rek.nama, Warna.Merah)
    refreshRekList(true)
end

-- BARU v1.4.3: SOLO — tampilkan 1 record saja
local function soloRek(target)
    for _, r in ipairs(daftarRekaman) do
        r.tampil = (r == target)
        bangunLineRek(r)
    end
    simpanKeFile()
    refreshRekList(false)
    bunyi(SND_PING, 0.3, 1.35)
    toast("🎯 Solo: hanya '" .. target.nama .. "' yang tampil", Warna.Hijau2)
end

refreshRekList = function(animasi)
    for _, c in ipairs(scrollRek:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end

    local nTampil = 0
    for _, r in ipairs(daftarRekaman) do
        if r.tampil then nTampil += 1 end
    end
    listLabelRek.Text = "🎥 RECORD • " .. #daftarRekaman
        .. "  •  tampil " .. nTampil .. "/" .. #daftarRekaman

    if #daftarRekaman == 0 then
        local kosong = buat("Frame", {
            Size = UDim2.new(1, -6, 1, 0), BackgroundTransparency = 1,
        }, scrollRek)
        local pin = buat("TextLabel", {
            Name = "NoFade", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0, 44), Size = UDim2.fromOffset(40, 40),
            BackgroundTransparency = 1, Font = Enum.Font.SourceSans,
            Text = "🎥", TextSize = 30,
        }, kosong)
        task.spawn(function()
            while pin.Parent do
                tween(pin, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 0, 38)})
                task.wait(0.9)
                if not pin.Parent then break end
                tween(pin, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Position = UDim2.new(0.5, 0, 0, 44)})
                task.wait(0.9)
            end
        end)
        buat("TextLabel", {
            Position = UDim2.new(0, 10, 0, 84),
            Size = UDim2.new(1, -20, 0, 40),
            BackgroundTransparency = 1,
            FontFace = fnt("med"),
            Text = "Belum ada record.\nTekan [G] untuk mulai merekam jalur.",
            TextColor3 = Warna.AbuTeks,
            TextSize = 12,
            TextWrapped = true,
        }, kosong)
        kumpulkanFade()
        return
    end

    for i, rek in ipairs(daftarRekaman) do
        local item = buat("Frame", {
            Size = UDim2.new(1, -6, 0, 36),
            BackgroundColor3 = rek.tampil and Warna.AbuItem or Color3.fromRGB(240, 238, 248),
            BorderSizePixel = 0,
            LayoutOrder = i,
        }, scrollRek)
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
            tween(item, TweenInfo.new(0.12), {BackgroundColor3 = Warna.BiruMuda})
        end)
        item.MouseLeave:Connect(function()
            tween(item, TweenInfo.new(0.12), {
                BackgroundColor3 = rek.tampil and Warna.AbuItem or Color3.fromRGB(240, 238, 248),
            })
        end)

        -- checkbox utk gabung
        local cekBtn = buat("TextButton", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(0, 6, 0.5, -9),
            BackgroundColor3 = rek.pilih and Warna.Hijau2 or Warna.Putih,
            BorderSizePixel = 0,
            FontFace = fnt("bold"),
            Text = rek.pilih and "✓" or "",
            TextColor3 = Warna.Putih,
            TextSize = 12,
            AutoButtonColor = false,
        }, item)
        buat("UICorner", {CornerRadius = UDim.new(0, 5)}, cekBtn)
        buat("UIStroke", {Color = Warna.Hijau2, Thickness = 1, Transparency = 0.3}, cekBtn)

        cekBtn.MouseButton1Click:Connect(function()
            rek.pilih = not rek.pilih
            cekBtn.BackgroundColor3 = rek.pilih and Warna.Hijau2 or Warna.Putih
            cekBtn.Text = rek.pilih and "✓" or ""
            bunyi(SND_PING, 0.2, rek.pilih and 1.3 or 0.9)
        end)

        local nameEdit = buat("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 28, 0, 0),
            Size = UDim2.new(1, -168, 1, 0),
            FontFace = fnt("med"),
            Text = rek.nama,
            TextColor3 = rek.tampil and Warna.TeksGelap or Warna.AbuTeks,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
        }, item)

        nameEdit.Focused:Connect(function()
            nameEdit.BackgroundTransparency = 0.85
        end)
        nameEdit.FocusLost:Connect(function()
            nameEdit.BackgroundTransparency = 1
            local baru = nameEdit.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if baru ~= "" and baru ~= rek.nama then
                rek.nama = baru
                simpanKeFile()
            elseif baru == "" then
                nameEdit.Text = rek.nama
            end
        end)

        -- BARU v1.4.3: SOLO 🎯 — tampil ini saja
        local soloBtn = buat("TextButton", {
            Size = UDim2.fromOffset(26, 26),
            Position = UDim2.new(1, -142, 0.5, -13),
            BackgroundColor3 = Warna.Putih,
            BorderSizePixel = 0,
            FontFace = fnt("reg"),
            Text = "🎯",
            TextSize = 12,
            AutoButtonColor = false,
        }, item)
        buat("UICorner", {CornerRadius = UDim.new(0, 7)}, soloBtn)
        buat("UIStroke", {Color = Warna.Hijau2, Thickness = 1, Transparency = 0.5}, soloBtn)

        soloBtn.MouseButton1Click:Connect(function()
            ripple(soloBtn, Warna.Hijau2)
            soloRek(rek)
        end)

        -- TP ke titik AKHIR
        local tpBtn = buat("TextButton", {
            Size = UDim2.fromOffset(30, 26),
            Position = UDim2.new(1, -106, 0.5, -13),
            BackgroundColor3 = Warna.Putih,
            BorderSizePixel = 0,
            FontFace = fnt("bold"),
            Text = "🏁",
            TextSize = 12,
            AutoButtonColor = false,
        }, item)
        buat("UICorner", {CornerRadius = UDim.new(0, 7)}, tpBtn)
        ledSweep(tpBtn, Warna.Hijau2, Warna.Putih, Warna.Hijau, 2.2)

        tpBtn.MouseButton1Click:Connect(function()
            ripple(tpBtn, Warna.Putih)
            local akhir = rek.poin[#rek.poin]
            if akhir then
                teleportKe(akhir)
                fxTeleport()
                toast("🏁 Ke akhir " .. rek.nama, Warna.Hijau2)
            end
        end)

        -- show/hide per record
        local eyeBtn = buat("TextButton", {
            Size = UDim2.fromOffset(26, 26),
            Position = UDim2.new(1, -68, 0.5, -13),
            BackgroundColor3 = Warna.Putih,
            BorderSizePixel = 0,
            FontFace = fnt("reg"),
            Text = rek.tampil and "👁" or "🚫",
            TextSize = 12,
            AutoButtonColor = false,
        }, item)
        buat("UICorner", {CornerRadius = UDim.new(0, 7)}, eyeBtn)

        eyeBtn.MouseButton1Click:Connect(function()
            rek.tampil = not rek.tampil
            eyeBtn.Text = rek.tampil and "👁" or "🚫"
            bangunLineRek(rek)
            simpanKeFile()
            bunyi(SND_PING, 0.25, rek.tampil and 1.2 or 0.8)
            refreshRekList(false)
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
                hapusRekaman(rek)
            end)
        end)

        efekTombol(tpBtn)
        efekTombol(soloBtn, 1.1)
        efekTombol(eyeBtn, 1.1)
        efekTombol(delBtn, 1.1)
    end

    kumpulkanFade()
end

-- [18] MUAT FILE ----------------------------------------------------
local function muatDariFile()
    if not fileOk then return end
    local isi
    pcall(function() isi = readfile(NAMA_FILE) end)
    if type(isi) ~= "string" or #isi == 0 then return end

    local data
    pcall(function() data = HttpService:JSONDecode(isi) end)
    if type(data) ~= "table" or type(data.games) ~= "table" then return end

    local entri = data.games[tostring(game.PlaceId)]
    if type(entri) ~= "table" then return end

    local daftarT, daftarK, daftarR = {}, {}, {}

    if type(entri.tiang) == "table" then
        daftarT = entri.tiang
        if type(entri.koneksi) == "table" then daftarK = entri.koneksi end
        if type(entri.records) == "table" then daftarR = entri.records end
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
                    topPos = cf.Position + Vector3.new(0, TIANG_TINGGI, 0),
                    model  = model,
                    batang = batang,
                    pilih  = false,
                })
            end
        end
    end
    perbaruiNomor()

    for _, k in ipairs(daftarK) do
        if type(k) == "table" and type(k.a) == "string" and type(k.b) == "string"
        and tiangDariId(k.a) and tiangDariId(k.b)
        and not koneksiAntara(k.a, k.b) then
            table.insert(koneksiAktif, {a = k.a, b = k.b, parts = {}})
        end
    end

    for _, e in ipairs(daftarR) do
        if type(e) == "table" and type(e.nama) == "string"
        and type(e.poin) == "table" and #e.poin >= 2 then
            local poin = {}
            local valid = true
            for _, p in ipairs(e.poin) do
                if type(p) == "table" and #p >= 3
                and type(p[1]) == "number" and type(p[2]) == "number" and type(p[3]) == "number" then
                    table.insert(poin, Vector3.new(p[1], p[2], p[3]))
                    if #poin >= MAX_TITIK then break end
                else
                    valid = false
                    break
                end
            end
            if valid and #poin >= 2 then
                local rek = {
                    id     = tostring(e.id or e.nama),
                    nama   = e.nama,
                    poin   = poin,
                    tampil = (e.tampil ~= false),
                    pilih  = false,
                    folder = Instance.new("Folder"),
                }
                rek.folder.Name = "Rek_" .. rek.id
                rek.folder.Parent = folderRekaman
                table.insert(daftarRekaman, rek)
            end
        end
    end

    for _, rek in ipairs(daftarRekaman) do
        bangunLineRek(rek)
    end

    if #koneksiAktif > 0 then rebuildGaris() end

    if #daftarTiang == 0 and #daftarRekaman == 0 then
        local adaBackup
        pcall(function() adaBackup = readfile(NAMA_BACKUP) end)
        if type(adaBackup) == "string" and #adaBackup > 0 then
            task.delay(2, function()
                toast("ℹ️ Ada backup tersimpan — tombol ♻ PULIHKAN BACKUP di tab Tiang", Warna.Biru)
            end)
        end
    end
end

-- [19] BUKA / TUTUP -------------------------------------------------
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

-- [20] TAB SWITCH ---------------------------------------------------
local function setTab(n)
    kontenTiang.Visible = (n == 1)
    kontenRekam.Visible = (n == 2)

    if n == 1 then
        tabTiang.BackgroundColor3 = Warna.Ungu
        tabTiang.TextColor3 = Warna.Putih
        tabRekam.BackgroundColor3 = Warna.AbuMuda
        tabRekam.TextColor3 = Warna.AbuTeks
    else
        tabRekam.BackgroundColor3 = Warna.Hijau2
        tabRekam.TextColor3 = Warna.Putih
        tabTiang.BackgroundColor3 = Warna.AbuMuda
        tabTiang.TextColor3 = Warna.AbuTeks
    end
    bunyi(SND_PING, 0.2, n == 1 and 1.1 or 1.25)
end

-- [21] KONEKSI ------------------------------------------------------
local function pasangDariInput()
    local teks = nameBox.Text
    pasangTiang(teks)
    nameBox.Text = ""
    nameBox:ReleaseFocus()
end

minBtn.MouseButton1Click:Connect(function()
    ripple(minBtn, Warna.Ungu2)
    minimizeGui()
end)
saveBtn.MouseButton1Click:Connect(function()
    ripple(saveBtn, Warna.Putih)
    pasangDariInput()
end)
nameBox.FocusLost:Connect(function(enter)
    if enter then pasangDariInput() end
end)
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    refreshList(false)
end)

tabTiang.MouseButton1Click:Connect(function() ripple(tabTiang, Warna.Putih) setTab(1) end)
tabRekam.MouseButton1Click:Connect(function() ripple(tabRekam, Warna.Putih) setTab(2) end)

recBtn.MouseButton1Click:Connect(function()
    ripple(recBtn, Warna.Putih)
    toggleRekam()
end)

btnTampil.MouseButton1Click:Connect(function()
    tampilRekamanGlobal = not tampilRekamanGlobal
    btnTampil.Text = tampilRekamanGlobal and "👁 LINE: ON" or "👁 LINE: OFF"
    for _, rek in ipairs(daftarRekaman) do
        bangunLineRek(rek)
    end
    bunyi(SND_PING, 0.3, tampilRekamanGlobal and 1.2 or 0.8)
    toast(tampilRekamanGlobal and "👁 Semua line record: ON" or "🚫 Semua line record: OFF", Warna.Hijau2)
end)

-- BARU v1.4.3: tampilkan semua record
btnSemua.MouseButton1Click:Connect(function()
    for _, r in ipairs(daftarRekaman) do
        r.tampil = true
        bangunLineRek(r)
    end
    simpanKeFile()
    refreshRekList(false)
    bunyi(SND_PING, 0.3, 1.2)
    toast("👁 Semua record tampil lagi", Warna.Biru)
end)

btnGabung.MouseButton1Click:Connect(function()
    local pilih = {}
    for _, rek in ipairs(daftarRekaman) do
        if rek.pilih then table.insert(pilih, rek) end
    end
    if #pilih < 2 then
        toast("⚠️ Pilih minimal 2 record (kotak ✓ hijau)", Warna.Merah)
        return
    end

    local poinBaru = {}
    for _, rek in ipairs(pilih) do
        for _, p in ipairs(rek.poin) do
            if #poinBaru < MAX_TITIK then
                table.insert(poinBaru, p)
            end
        end
    end

    local namaNama = {}
    for _, r in ipairs(daftarRekaman) do table.insert(namaNama, r.nama) end
    local gab = {
        id     = idBaru(),
        nama   = "Gabungan " .. nomorBebas("Gabungan", namaNama),
        poin   = poinBaru,
        tampil = true,
        pilih  = false,
        folder = Instance.new("Folder"),
    }
    gab.folder.Name = "Rek_" .. gab.id
    gab.folder.Parent = folderRekaman
    table.insert(daftarRekaman, gab)

    for _, rek in ipairs(pilih) do
        rek.pilih = false
    end

    bangunLineRek(gab)
    simpanKeFile()
    refreshRekList(true)
    konfeti(root, pusatDiRoot(btnGabung), 14)
    toast("🔗 Digabung " .. #pilih .. " record → '" .. gab.nama .. "'", Warna.Ungu)
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

    simpanKeFile()
    bersihkanPilihanTiang()
    bunyi(SND_PING, 0.3, 1.3)
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

    simpanKeFile()
    bersihkanPilihanTiang()
    bunyi(SND_SNAP, 0.35, 0.7)
    toast("✂️ Koneksi diputus", Warna.Merah)
end)

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
        bunyi(SND_SNAP, 0.3, 0.8)
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
        bunyi(SND_SNAP, 0.35, 0.6)
        hapusSemuaTiang()
    end
end)

btnGaris.MouseButton1Click:Connect(function()
    if #koneksiAktif == 0 then
        toast("⚠️ Belum ada koneksi untuk dihitung ulang", Warna.Merah)
        return
    end
    bunyi(SND_PING, 0.3, 1.2)
    rebuildGaris()
    toast("↺ " .. #koneksiAktif .. " garis dihitung ulang", Warna.Biru)
end)

local pulihkanSiap = false
btnPulihkan.MouseButton1Click:Connect(function()
    if not pulihkanSiap then
        pulihkanSiap = true
        btnPulihkan.Text = "❗ TIMPA DATA DENGAN BACKUP? KLIK LAGI"
        btnPulihkan.BackgroundColor3 = Warna.Merah
        bunyi(SND_SNAP, 0.3, 0.8)
        task.delay(3, function()
            pulihkanSiap = false
            if btnPulihkan.Parent then
                btnPulihkan.Text = "♻ PULIHKAN BACKUP"
                btnPulihkan.BackgroundColor3 = Warna.Putih
            end
        end)
    else
        pulihkanSiap = false
        local isiBackup
        pcall(function() isiBackup = readfile(NAMA_BACKUP) end)
        if type(isiBackup) == "string" and #isiBackup > 0 then
            pcall(function() writefile(NAMA_FILE, isiBackup) end)
            bunyi(SND_PING, 0.35, 1.2)
            toast("♻ Backup dipulihkan — memuat ulang...", Warna.Biru)
            task.wait(0.3)
            resetScript()
        else
            toast("⚠️ Tidak ada file backup", Warna.Merah)
        end
    end
end)

local tutupSiap = false
btnTutup.MouseButton1Click:Connect(function()
    if not tutupSiap then
        tutupSiap = true
        btnTutup.Text = "❗ HAPUS SEMUA DATA & TUTUP? KLIK LAGI"
        btnTutup.BackgroundColor3 = Warna.Merah
        bunyi(SND_SNAP, 0.3, 0.8)
        task.delay(3, function()
            tutupSiap = false
            if btnTutup.Parent then
                btnTutup.Text = "🗑️ HAPUS & TUTUP SCRIPT"
                btnTutup.BackgroundColor3 = Warna.Putih
            end
        end)
    else
        tutupSiap = false
        bunyi(SND_SNAP, 0.35, 0.5)

        local terhapus = false
        if fileOk then
            pcall(function()
                if type(delfile) == "function" then
                    if type(isfile) ~= "function" or isfile(NAMA_FILE) then
                        delfile(NAMA_FILE)
                    end
                    if type(isfile) ~= "function" or isfile(NAMA_BACKUP) then
                        delfile(NAMA_BACKUP)
                    end
                    terhapus = true
                else
                    writefile(NAMA_FILE, "{}")
                    pcall(function() writefile(NAMA_BACKUP, "{}") end)
                    terhapus = true
                end
            end)
        end

        unloadScript("File data " .. (terhapus and "DIHAPUS" or "tidak bisa dihapus") .. " & script ditutup ✔")
    end
end)

sorotInput(nameBox, nameStroke, 0.5)
sorotInput(searchBox, searchStroke, 0.6)

efekTombol(saveBtn)
efekTombol(minBtn, 1.1)
efekTombol(btnBersih)
efekTombol(btnGaris)
efekTombol(btnSambung)
efekTombol(btnPutus)
efekTombol(btnPulihkan)
efekTombol(btnTutup)
efekTombol(recBtn)
efekTombol(btnTampil)
efekTombol(btnSemua)
efekTombol(btnGabung)
efekTombol(tabTiang)
efekTombol(tabRekam)

buatDraggable(header, root)
buatDraggable(icon, icon, bukaGui)

catat(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TOGGLE_KEY then
        if root.Visible then minimizeGui() else bukaGui() end
    elseif input.KeyCode == PASANG_KEY then
        pasangTiang(nameBox.Text)
        nameBox.Text = ""
    elseif input.KeyCode == REC_KEY then
        toggleRekam()
    end
end))

pcall(function()
    getgenv()._TiangPathBersihkan = function()
        for _, c in ipairs(semuaKoneksi) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(semuaKoneksi)
    end
end)

-- [22] MULAI --------------------------------------------------------
muatDariFile()

refreshList(true)
refreshRekList(false)
setTab(1)
task.delay(0.15, bukaGui)

task.delay(1.2, function()
    local total = #daftarTiang + #daftarRekaman
    if total > 0 then
        toast("📂 Dimuat: " .. #daftarTiang .. " tiang • " .. #koneksiAktif .. " koneksi • " .. #daftarRekaman .. " record", Warna.Biru)
    elseif not fileOk then
        toast("⚠️ Penyimpanan file tidak tersedia", Warna.Merah)
    end
end)

print("[TiangPath] v1.4.3 SIAP ✔ — F = GUI | Y = pasang | G = rekam")
print("[TiangPath] 🎯 SOLO (tampil 1 saja) + 👁 TAMPILKAN SEMUA")

end -- akhir jalankanScript

-- [23] EKSEKUSI PERTAMA ---------------------------------------------
jalankanScript()
