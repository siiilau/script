--========================================================
-- ROUTETOOLS v6.3 LITE — Teleport + Speedwalk + Fullbright
-- Keybind: F=GUI  Q=Speed  C=Cahaya
--========================================================

-- [1] PENGAMAN ------------------------------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
    warn("[RouteTools] GAGAL: harus jalan di CLIENT (executor)!")
    return
end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
if not LocalPlayer then
    warn("[RouteTools] GAGAL: LocalPlayer belum ada.")
    return
end

-- [2] KONFIGURASI ---------------------------------------------------
local TOGGLE_KEY = Enum.KeyCode.F
local KEY_SPEED  = Enum.KeyCode.Q
local KEY_LIGHT  = Enum.KeyCode.C

local TELEPORT_OFFSET = 3.5
local SOUND_ON        = true

local SPEED_MIN, SPEED_MAX, SPEED_STEP = 17.00, 25.00, 0.25
local SPEED_DEFAULT = 17.25
local SPEED_NORMAL  = 17

local FILE_LOKASI = "TeleportGui_Silau.json"

-- [3] TEMA ----------------------------------------------------------
local W = {
    BG0     = Color3.fromRGB(10, 16, 30),
    BG1     = Color3.fromRGB(13, 21, 38),
    CARD    = Color3.fromRGB(19, 28, 48),
    CARD2   = Color3.fromRGB(24, 34, 58),
    BORDER  = Color3.fromRGB(30, 42, 68),
    BLUE    = Color3.fromRGB(59, 130, 246),
    BLUEDIM = Color3.fromRGB(37, 99, 235),
    CYAN    = Color3.fromRGB(34, 211, 238),
    GREEN   = Color3.fromRGB(34, 197, 94),
    RED     = Color3.fromRGB(239, 68, 68),
    AMBER   = Color3.fromRGB(245, 158, 11),
    TXT     = Color3.fromRGB(240, 244, 255),
    SUB     = Color3.fromRGB(124, 138, 168),
    ABU     = Color3.fromRGB(40, 52, 80),
}

-- [4] FONT ----------------------------------------------------------
local FONT_OK = pcall(function()
    return Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Regular)
end)
local cacheFont = {}
local function fnt(k)
    if cacheFont[k] then return cacheFont[k] end
    local v
    if FONT_OK then
        v = Font.new("rbxasset://fonts/families/Montserrat.json",
            (k == "bold") and Enum.FontWeight.Bold or Enum.FontWeight.Regular)
    else
        v = (k == "bold") and Enum.Font.GothamBold or Enum.Font.Gotham
    end
    cacheFont[k] = v
    return v
end
local TEKS_CLASS = {TextLabel = true, TextButton = true, TextBox = true}

-- [5] HELPER DASAR --------------------------------------------------
local rnd = math.random
local koneksi = {}
local function sambung(sig, fn)
    local c = sig:Connect(fn)
    table.insert(koneksi, c)
    return c
end
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
local SND_PING = "rbxasset://sounds/electronicpingshort.wav"
local SND_SNAP = "rbxasset://sounds/snap.mp3"

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- nomor otomatis: nomor terkecil yang belum dipakai (gap-fill)
local function nomorBebas(prefix, daftarNama)
    local dipakai = {}
    for _, nama in ipairs(daftarNama) do
        local n = tonumber(tostring(nama):match("^" .. prefix .. " (%d+)"))
        if n then dipakai[n] = true end
    end
    local n = 1
    while dipakai[n] do n += 1 end
    return n
end

-- [6] SCREENGUI -----------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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
    if ok and screenGui.Parent == t then terpasang = true break end
end
if not terpasang then
    warn("[RouteTools] GAGAL: tidak bisa memasang GUI.")
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

-- [7] UI HELPERS -----------------------------------------------------
local function ripple(btn, warna)
    btn.ClipsDescendants = true
    local c = buat("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(8, 8), BackgroundColor3 = warna or W.BLUE,
        BackgroundTransparency = 0.6, BorderSizePixel = 0,
    }, btn)
    buat("UICorner", {CornerRadius = UDim.new(1, 0)}, c)
    local target = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.4
    tween(c, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromOffset(target, target), BackgroundTransparency = 1})
    task.delay(0.45, function() c:Destroy() end)
end

local function efekTombol(btn, skala)
    local s = buat("UIScale", {Scale = 1}, btn)
    local target = skala or 1.05
    btn.MouseEnter:Connect(function()
        tween(s, TweenInfo.new(0.12), {Scale = target})
    end)
    btn.MouseLeave:Connect(function()
        tween(s, TweenInfo.new(0.12), {Scale = 1})
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

local function konfirmasiDuaKali(btn, teksAwal, aksi)
    local armed = false
    return function()
        if armed then
            armed = false
            btn.Text = teksAwal
            aksi()
        else
            armed = true
            btn.Text = "Yakin? Klik lagi"
            bunyi(SND_SNAP, 0.3, 0.7)
            task.delay(2.5, function()
                if armed and btn.Parent then
                    armed = false
                    btn.Text = teksAwal
                end
            end)
        end
    end
end

local function buatCard(parent, x, y, w, h)
    local card = buat("Frame", {
        Position = UDim2.new(0, x, 0, y), Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = W.CARD, BorderSizePixel = 0,
    }, parent)
    buat("UICorner", {CornerRadius = UDim.new(0, 12)}, card)
    buat("UIStroke", {Color = W.BORDER, Thickness = 1}, card)
    return card
end

local function buatSwitch(parent, pos, awalOn)
    local state = awalOn and true or false
    local sw = buat("TextButton", {
        Position = pos, Size = UDim2.fromOffset(42, 22),
        BackgroundColor3 = state and W.GREEN or W.ABU,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false,
    }, parent)
    buat("UICorner", {CornerRadius = UDim.new(1, 0)}, sw)
    local knob = buat("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, state and 23 or 3, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = W.TXT, BorderSizePixel = 0,
    }, sw)
    buat("UICorner", {CornerRadius = UDim.new(1, 0)}, knob)
    local api = {}
    api.btn = sw
    api.get = function() return state end
    api.set = function(v)
        state = v and true or false
        tween(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and W.GREEN or W.ABU})
        tween(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = UDim2.new(0, state and 23 or 3, 0.5, 0)})
    end
    return api
end

-- [8] PANEL UTAMA ----------------------------------------------------
local root = buat("Frame", {
    Size = UDim2.fromOffset(780, 520),
    Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
}, screenGui)
local rootScale = buat("UIScale", {Scale = 1}, root)

local panel = buat("Frame", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = W.BG1, BorderSizePixel = 0,
}, root)
buat("UICorner", {CornerRadius = UDim.new(0, 14)}, panel)
buat("UIStroke", {Color = W.BORDER, Thickness = 1}, panel)
buat("UIStroke", {Color = W.BLUEDIM, Thickness = 1, Transparency = 0.85}, panel)

local panelScale = buat("UIScale", {Scale = 1}, panel)

local function updateScale()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1366, 768)
    if vp.X < 860 then
        rootScale.Scale = math.clamp(vp.X / 860, 0.55, 1)
    else
        rootScale.Scale = 1
    end
end
updateScale()
local function pasangKamera()
    local cam = workspace.CurrentCamera
    if cam then
        cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
    end
end
pasangKamera()
sambung(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
    pasangKamera()
    updateScale()
end)

-- [9] SIDEBAR (2 NAV) ------------------------------------------------
local sidebar = buat("Frame", {
    Size = UDim2.new(0, 190, 1, 0), BackgroundColor3 = W.BG0, BorderSizePixel = 0,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 14)}, sidebar)
buat("Frame", {
    Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0),
    BackgroundColor3 = W.BORDER, BorderSizePixel = 0,
}, sidebar)

local logoDrag = buat("Frame", {
    Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 46),
    BackgroundTransparency = 1, Active = true,
}, sidebar)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, 15), Size = UDim2.new(1, -30, 0, 20),
    FontFace = fnt("bold"), RichText = true,
    Text = 'ROUTE<font color="#3B82F6">TOOLS</font>',
    TextColor3 = W.TXT, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
}, logoDrag)

local navBtns, navDots = {}, {}
local fungsiPilihTab -- SATU deklarasi

local function buatNav(urut, ikon, label)
    local b = buat("TextButton", {
        Position = UDim2.new(0, 12, 0, 58 + (urut - 1) * 50),
        Size = UDim2.new(1, -24, 0, 42),
        BackgroundColor3 = W.BG0, BorderSizePixel = 0,
        Text = "", AutoButtonColor = false,
    }, sidebar)
    buat("UICorner", {CornerRadius = UDim.new(0, 10)}, b)
    local ic = buat("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.fromOffset(20, 42),
        Font = Enum.Font.SourceSans, Text = ikon, TextSize = 14, TextColor3 = W.TXT,
    }, b)
    local lb = buat("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(1, -56, 1, 0),
        FontFace = fnt("bold"), Text = label, TextSize = 11,
        TextColor3 = W.SUB, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true,
    }, b)
    local dot = buat("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(6, 6), BackgroundColor3 = W.ABU, BorderSizePixel = 0,
    }, b)
    buat("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
    b.MouseButton1Click:Connect(function()
        ripple(b, W.BLUE)
        bunyi(SND_PING, 0.22, 1.15 + urut * 0.1)
        if fungsiPilihTab then fungsiPilihTab(urut) end
    end)
    navBtns[urut] = {btn = b, label = lb, ikon = ic}
    navDots[urut] = dot
end
buatNav(1, "⚙", "Tools")
buatNav(2, "📍", "Teleport")

local sidebarFooter = buat("TextLabel", {
    Position = UDim2.new(0, 18, 1, -120), Size = UDim2.new(1, -36, 0, 106),
    BackgroundTransparency = 1, FontFace = fnt("reg"),
    Text = "", TextColor3 = W.SUB, TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom,
    TextWrapped = true, RichText = true,
}, sidebar)

-- [10] HEADER KONTEN -------------------------------------------------
local konten = buat("Frame", {
    Position = UDim2.new(0, 190, 0, 0), Size = UDim2.new(1, -190, 1, 0),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, panel)

local headerDrag = buat("Frame", {
    Size = UDim2.new(1, 0, 0, 84), BackgroundTransparency = 1, Active = true,
}, konten)

local eyebrow = buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, 12), Size = UDim2.new(1, -180, 0, 12),
    FontFace = fnt("bold"), Text = "", TextColor3 = W.CYAN, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, headerDrag)
local judul = buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, 26), Size = UDim2.new(1, -180, 0, 28),
    FontFace = fnt("bold"), Text = "", TextColor3 = W.TXT, TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Left,
}, headerDrag)
local subjudul = buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, 56), Size = UDim2.new(1, -180, 0, 14),
    FontFace = fnt("reg"), Text = "", TextColor3 = W.SUB, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, headerDrag)

local pill = buat("Frame", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 14),
    Size = UDim2.fromOffset(140, 24), BackgroundColor3 = W.GREEN,
    BackgroundTransparency = 0.85, BorderSizePixel = 0,
}, headerDrag)
buat("UICorner", {CornerRadius = UDim.new(1, 0)}, pill)
local pillStroke = buat("UIStroke", {Color = W.GREEN, Thickness = 1, Transparency = 0.5}, pill)
local pillDot = buat("Frame", {
    Position = UDim2.new(0, 10, 0.5, -3), Size = UDim2.fromOffset(6, 6),
    BackgroundColor3 = W.GREEN, BorderSizePixel = 0,
}, pill)
buat("UICorner", {CornerRadius = UDim.new(1, 0)}, pillDot)
local pillLabel = buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(1, -28, 1, 0),
    FontFace = fnt("bold"), Text = "Script aktif", TextColor3 = W.GREEN,
    TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
}, pill)

local minBtn = buat("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0),
    Size = UDim2.fromOffset(22, 22), BackgroundColor3 = W.CARD, BorderSizePixel = 0,
    FontFace = fnt("bold"), Text = "–", TextColor3 = W.SUB, TextSize = 14,
    AutoButtonColor = false, ZIndex = 5,
}, panel)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, minBtn)
buat("UIStroke", {Color = W.BORDER, Thickness = 1}, minBtn)

buat("Frame", {
    Position = UDim2.new(0, 14, 0, 84), Size = UDim2.new(1, -28, 0, 1),
    BackgroundColor3 = W.BORDER, BorderSizePixel = 0,
}, konten)

-- [11] AREA KONTEN + FOOTER ------------------------------------------
local area = buat("Frame", {
    Position = UDim2.new(0, 14, 0, 92), Size = UDim2.new(1, -28, 1, -118),
    BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true,
}, konten)

local tabFrames = {}
for i = 1, 2 do
    tabFrames[i] = buat("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false,
    }, area)
end

local footerBar = buat("Frame", {
    Position = UDim2.new(0, 14, 1, -26), Size = UDim2.new(1, -28, 0, 18),
    BackgroundTransparency = 1,
}, konten)
local footDot = buat("Frame", {
    Position = UDim2.new(0, 0, 0.5, -2.5), Size = UDim2.fromOffset(5, 5),
    BackgroundColor3 = W.GREEN, BorderSizePixel = 0,
}, footerBar)
buat("UICorner", {CornerRadius = UDim.new(1, 0)}, footDot)
local footLeft = buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.6, 0, 1, 0),
    FontFace = fnt("reg"), Text = "", TextColor3 = W.SUB, TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, footerBar)
local footRight = buat("TextLabel", {
    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.4, 0, 1, 0),
    FontFace = fnt("reg"), Text = "", TextColor3 = W.SUB, TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Right,
}, footerBar)

-- [12] TOAST ---------------------------------------------------------
local function toast(teks, aksen)
    local t = buat("Frame", {
        AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -80),
        Size = UDim2.fromOffset(260, 32), BackgroundColor3 = W.CARD,
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 960,
    }, screenGui)
    buat("UICorner", {CornerRadius = UDim.new(0, 10)}, t)
    local st = buat("UIStroke", {Color = aksen or W.BLUE, Thickness = 1, Transparency = 1}, t)
    local lb = buat("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0),
        FontFace = fnt("bold"), Text = teks, TextColor3 = W.TXT,
        TextSize = 11, TextTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = true,
    }, t)
    local ti = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    tween(t, ti, {BackgroundTransparency = 0.05, Position = UDim2.new(0.5, 0, 1, -92)})
    tween(st, ti, {Transparency = 0.35})
    tween(lb, ti, {TextTransparency = 0})
    task.delay(1.6, function()
        local to = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(t, to, {BackgroundTransparency = 1, Position = UDim2.new(0.5, 0, 1, -80)})
        tween(st, to, {Transparency = 1})
        tween(lb, to, {TextTransparency = 1})
        task.delay(0.3, function() t:Destroy() end)
    end)
end

-- [13] IKON MINIMIZE + BADGE ------------------------------------------
local icon = buat("Frame", {
    Size = UDim2.fromOffset(36, 36),
    Position = UDim2.new(0, 10, 1, -10), AnchorPoint = Vector2.new(0, 1),
    BackgroundColor3 = W.BG0, BorderSizePixel = 0, Visible = false,
}, screenGui)
buat("UICorner", {CornerRadius = UDim.new(0, 10)}, icon)
buat("UIStroke", {Color = W.BLUE, Thickness = 1.5}, icon)
local iconScale = buat("UIScale", {Scale = 1}, icon)
local kotakPutih = buat("Frame", {
    Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0.5, -8, 0.5, -8),
    BackgroundColor3 = W.BLUE, BorderSizePixel = 0, Rotation = 18,
}, icon)
buat("UICorner", {CornerRadius = UDim.new(0, 3)}, kotakPutih)
local lubang = buat("Frame", {
    Size = UDim2.fromOffset(7, 7), Position = UDim2.new(0.5, -3.5, 0.5, -3.5),
    BackgroundColor3 = W.BG0, BorderSizePixel = 0,
}, kotakPutih)
buat("UICorner", {CornerRadius = UDim.new(0, 2)}, lubang)

icon.MouseEnter:Connect(function()
    tween(iconScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.15})
end)
icon.MouseLeave:Connect(function()
    tween(iconScale, TweenInfo.new(0.15), {Scale = 1})
end)

local badge = buat("TextLabel", {
    Position = UDim2.new(0, 10, 1, -56), Size = UDim2.fromOffset(130, 18),
    BackgroundColor3 = W.BG0, BackgroundTransparency = 0.15,
    BorderSizePixel = 0, Visible = false, ZIndex = 950,
    FontFace = fnt("bold"), Text = "", TextColor3 = W.CYAN, TextSize = 10,
}, screenGui)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, badge)
buat("UIStroke", {Color = W.BORDER, Thickness = 1}, badge)

-- [14] PERSISTENSI (lokasi saja) --------------------------------------
local fileOk = (type(writefile) == "function" and type(readfile) == "function")
local function idBaru() return tostring(os.time()) .. "-" .. tostring(rnd(100000, 999999)) end

local function bacaJSON(path)
    if not fileOk then return nil end
    local isi
    pcall(function() isi = readfile(path) end)
    if type(isi) ~= "string" or #isi == 0 then return nil end
    local data
    local ok = pcall(function() data = HttpService:JSONDecode(isi) end)
    if ok and type(data) == "table" then return data end
    pcall(function() writefile(path .. ".bak", isi) end)
    warn("[RouteTools] JSON korup, backup: " .. path .. ".bak")
    return nil
end

local function tulisJSON(path, data)
    if not fileOk then return end
    local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
    if ok and type(json) == "string" then
        local okTulis = pcall(function() writefile(path, json) end)
        if not okTulis then warn("[RouteTools] Gagal menulis: " .. path) end
    end
end

local lokasiTersimpan = {}
local function muatLokasi()
    local data = bacaJSON(FILE_LOKASI)
    if not data or type(data.games) ~= "table" then return end
    local entri = data.games[tostring(game.PlaceId)]
    if type(entri) ~= "table" then return end
    for _, e in ipairs(entri) do
        if type(e) == "table" and type(e.nama) == "string"
        and type(e.cf) == "table" and #e.cf >= 12 then
            local ok, cf = pcall(CFrame.new, table.unpack(e.cf, 1, 12))
            if ok and cf then
                table.insert(lokasiTersimpan, {
                    id = tostring(e.id or e.nama), nama = e.nama,
                    waktu = tostring(e.waktu or "?"), cframe = cf,
                })
            end
        end
    end
end
local function simpanLokasiKeFile()
    local data = bacaJSON(FILE_LOKASI)
    data = (type(data) == "table" and type(data.games) == "table") and data or {games = {}}
    local daftar = {}
    for _, l in ipairs(lokasiTersimpan) do
        table.insert(daftar, {id = l.id, nama = l.nama, waktu = l.waktu, cf = {l.cframe:GetComponents()}})
    end
    data.games[tostring(game.PlaceId)] = daftar
    tulisJSON(FILE_LOKASI, data)
end

muatLokasi()

-- [15] KARAKTER + TELEPORT -------------------------------------------
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
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function fxTeleport()
    bunyi("rbxasset://sounds/unsheath.wav", 0.4, 1.1)
    local fl = buat("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = W.BG0,
        BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 950,
    }, screenGui)
    tween(fl, TweenInfo.new(0.08), {BackgroundTransparency = 0.5})
    task.delay(0.1, function()
        tween(fl, TweenInfo.new(0.3), {BackgroundTransparency = 1})
        task.delay(0.35, function() fl:Destroy() end)
    end)
    local r = buat("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, ZIndex = 949,
    }, screenGui)
    buat("UICorner", {CornerRadius = UDim.new(1, 0)}, r)
    local rs = buat("UIStroke", {Color = W.BLUE, Thickness = 3}, r)
    tween(r, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(400, 400)})
    tween(rs, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
    task.delay(0.5, function() r:Destroy() end)
end

-- [16] STATE + FORWARD ------------------------------------------------
local speedOn, lightOn, hotkeyAktif = false, false, true
local speedValue = SPEED_DEFAULT
local origSpeed = nil

local updatePill, updateNavDots, updateSpeedUI, updateLightUI, perbaruiBadge
local refreshLokasi
local tabAktif = 1

-- [17] TAB 1: TOOLS ===================================================
local tab1 = tabFrames[1]
local scrollT1 = buat("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = W.BORDER,
    CanvasSize = UDim2.new(0, 0, 0, 400),
}, tab1)

local lebarKonten = 562
local halfW = math.floor((lebarKonten - 10) / 2)

-- kartu speedwalk
local cardSpeed = buatCard(scrollT1, 0, 0, halfW, 132)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(1, -100, 0, 16),
    FontFace = fnt("bold"), Text = "⚡ Speedwalk", TextColor3 = W.TXT, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, cardSpeed)
local speedPill = buat("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 9),
    Size = UDim2.fromOffset(72, 22), BackgroundColor3 = W.ABU, BorderSizePixel = 0,
    FontFace = fnt("bold"), Text = "OFF · Q", TextColor3 = W.SUB,
    TextSize = 10, AutoButtonColor = false,
}, cardSpeed)
buat("UICorner", {CornerRadius = UDim.new(1, 0)}, speedPill)
buat("UIStroke", {Color = W.BLUE, Thickness = 1, Transparency = 0.6}, speedPill)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 12),
    FontFace = fnt("reg"), Text = "Kecepatan berjalan saat fitur aktif",
    TextColor3 = W.SUB, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
}, cardSpeed)
local speedBig = buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 44), Size = UDim2.new(0, 120, 0, 26),
    FontFace = fnt("bold"), Text = "17.25", TextColor3 = W.CYAN, TextSize = 22,
    TextXAlignment = Enum.TextXAlignment.Left,
}, cardSpeed)
buat("TextLabel", {
    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -12, 0, 72), Size = UDim2.fromOffset(90, 14),
    FontFace = fnt("reg"), Text = "WalkSpeed", TextColor3 = W.SUB, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
}, cardSpeed)

local sliderBar = buat("Frame", {
    Position = UDim2.new(0, 14, 0, 84), Size = UDim2.new(1, -28, 0, 6),
    BackgroundColor3 = W.ABU, BorderSizePixel = 0,
}, cardSpeed)
buat("UICorner", {CornerRadius = UDim.new(1, 0)}, sliderBar)
local sliderFill = buat("Frame", {
    Size = UDim2.new(0.03, 0, 1, 0), BackgroundColor3 = W.BLUE, BorderSizePixel = 0,
}, sliderBar)
buat("UICorner", {CornerRadius = UDim.new(1, 0)}, sliderFill)
local sliderKnob = buat("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.03, 0, 0.5, 0),
    Size = UDim2.fromOffset(14, 14), BackgroundColor3 = W.BLUE, BorderSizePixel = 0,
    ZIndex = 2,
}, sliderBar)
buat("UICorner", {CornerRadius = UDim.new(1, 0)}, sliderKnob)
buat("UIStroke", {Color = W.TXT, Thickness = 1.5}, sliderKnob)

local skalaLabels = {{"17.00", 0}, {"20.00", 0.5}, {"25.00", 1}}
for i = 1, #skalaLabels do
    local lbl = skalaLabels[i][1]
    local xr  = skalaLabels[i][2]
    buat("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(xr, 0),
        Position = UDim2.new(xr, xr == 0 and 14 or (xr == 1 and -14 or 0), 0, 96),
        Size = UDim2.new(0, 40, 0, 10),
        FontFace = fnt("reg"), Text = lbl, TextColor3 = W.SUB, TextSize = 8,
        TextXAlignment = xr == 0 and Enum.TextXAlignment.Left
            or (xr == 1 and Enum.TextXAlignment.Right or Enum.TextXAlignment.Center),
    }, cardSpeed)
end

local function updateSliderVis(rel)
    rel = math.clamp(rel, 0, 1)
    sliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
    sliderFill.Size = UDim2.new(rel, 0, 1, 0)
end
updateSliderVis((SPEED_DEFAULT - SPEED_MIN) / (SPEED_MAX - SPEED_MIN))

-- kartu fullbright
local cardLight = buatCard(scrollT1, halfW + 10, 0, halfW, 132)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(1, -70, 0, 16),
    FontFace = fnt("bold"), Text = "☀ Fullbright Adaptif", TextColor3 = W.TXT, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, cardLight)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 12),
    FontFace = fnt("reg"), Text = "Siang nyaman, malam lebih terang",
    TextColor3 = W.SUB, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
}, cardLight)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 52), Size = UDim2.new(1, -110, 0, 14),
    FontFace = fnt("reg"), Text = "Status fitur", TextColor3 = W.TXT, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, cardLight)
local lightPill = buat("TextLabel", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 50),
    Size = UDim2.fromOffset(84, 20), BackgroundColor3 = W.ABU,
    BackgroundTransparency = 0.4, BorderSizePixel = 0,
    FontFace = fnt("bold"), Text = "NONAKTIF", TextColor3 = W.SUB, TextSize = 9,
}, cardLight)
buat("UICorner", {CornerRadius = UDim.new(1, 0)}, lightPill)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 78), Size = UDim2.new(1, -24, 0, 40),
    FontFace = fnt("reg"), TextWrapped = true,
    Text = "Menyesuaikan ClockTime secara halus. OFF mengembalikan Lighting semula.",
    TextColor3 = W.SUB, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
}, cardLight)
local lightSwitch = buatSwitch(cardLight, UDim2.new(1, -52, 0, 9), false)

-- kartu hotkey
local cardKey = buatCard(scrollT1, 0, 142, lebarKonten, 158)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(0, 200, 0, 16),
    FontFace = fnt("bold"), Text = "⌨ Hotkey", TextColor3 = W.TXT, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, cardKey)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 27), Size = UDim2.new(0, 320, 0, 12),
    FontFace = fnt("reg"), Text = "Hotkey aktif selama master switch menyala",
    TextColor3 = W.SUB, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
}, cardKey)
buat("TextLabel", {
    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -62, 0, 12), Size = UDim2.fromOffset(110, 16),
    FontFace = fnt("reg"), Text = "Master hotkey", TextColor3 = W.TXT, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
}, cardKey)
local masterSwitch = buatSwitch(cardKey, UDim2.new(1, -52, 0, 9), true)

local function hotkeyRow(parent, x, y, w, label, key)
    local row = buat("Frame", {
        Position = UDim2.new(0, x, 0, y), Size = UDim2.fromOffset(w, 28),
        BackgroundColor3 = W.CARD2, BorderSizePixel = 0,
    }, parent)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
    buat("UIStroke", {Color = W.BORDER, Thickness = 1}, row)
    buat("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -44, 1, 0),
        FontFace = fnt("reg"), Text = label, TextColor3 = W.TXT, TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    local cap = buat("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
        Size = UDim2.fromOffset(20, 20), BackgroundColor3 = W.BG0, BorderSizePixel = 0,
        FontFace = fnt("bold"), Text = key, TextColor3 = W.CYAN, TextSize = 11,
    }, row)
    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, cap)
    buat("UIStroke", {Color = W.BORDER, Thickness = 1}, cap)
end
local rowW = math.floor((lebarKonten - 24 - 8) / 2)
hotkeyRow(cardKey, 12, 42, rowW, "Buka / tutup GUI", "F")
hotkeyRow(cardKey, 12 + rowW + 8, 42, rowW, "Speedwalk", "Q")
hotkeyRow(cardKey, 12, 72, rowW, "Fullbright adaptif", "C")
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 106), Size = UDim2.new(1, -24, 0, 14),
    FontFace = fnt("reg"), Text = "Master OFF = Q/C mati sementara (F tetap jalan).",
    TextColor3 = W.SUB, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
}, cardKey)

-- kartu hapus script
local cardDel = buatCard(scrollT1, 0, 310, lebarKonten, 84)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(0, 300, 0, 16),
    FontFace = fnt("bold"), Text = "🗑 Hapus Script", TextColor3 = W.RED, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, cardDel)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 30), Size = UDim2.new(1, -150, 0, 46),
    FontFace = fnt("reg"), TextWrapped = true,
    Text = "Pulihkan WalkSpeed & Lighting, putus semua koneksi, lalu tutup GUI. Lokasi tersimpan tetap aman di file.",
    TextColor3 = W.SUB, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
}, cardDel)
local unloadBtn = buat("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(120, 34), BackgroundColor3 = W.RED, BorderSizePixel = 0,
    FontFace = fnt("bold"), Text = "Hapus Script", TextColor3 = W.TXT,
    TextSize = 11, AutoButtonColor = false,
}, cardDel)
buat("UICorner", {CornerRadius = UDim.new(0, 9)}, unloadBtn)

-- [18] TAB 2: TELEPORT ================================================
local tab2 = tabFrames[2]

local cardSimpan = buatCard(tab2, 0, 0, lebarKonten, 96)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(0, 240, 0, 16),
    FontFace = fnt("bold"), Text = "📍 Simpan Lokasi Baru", TextColor3 = W.TXT, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, cardSimpan)
local lokasiCounter = buat("TextLabel", {
    BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(160, 14),
    FontFace = fnt("reg"), Text = "0 lokasi tersimpan", TextColor3 = W.SUB, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
}, cardSimpan)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 12),
    FontFace = fnt("reg"), Text = "Beri nama agar lokasi mudah ditemukan.",
    TextColor3 = W.SUB, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
}, cardSimpan)
local nameBox = buat("TextBox", {
    Position = UDim2.new(0, 12, 0, 50), Size = UDim2.new(1, -128, 0, 32),
    BackgroundColor3 = W.BG0, BorderSizePixel = 0,
    FontFace = fnt("reg"), PlaceholderText = "Contoh: Base Camp",
    PlaceholderColor3 = W.SUB, Text = "", TextColor3 = W.TXT,
    TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
}, cardSimpan)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, nameBox)
local nameStroke = buat("UIStroke", {Color = W.BORDER, Thickness = 1}, nameBox)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10)}, nameBox)
local saveBtn = buat("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 50),
    Size = UDim2.fromOffset(104, 32), BackgroundColor3 = W.GREEN, BorderSizePixel = 0,
    FontFace = fnt("bold"), Text = "+ SIMPAN", TextColor3 = W.TXT,
    TextSize = 11, AutoButtonColor = false,
}, cardSimpan)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, saveBtn)

local cardDaftar = buatCard(tab2, 0, 104, lebarKonten, 294)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.new(0, 260, 0, 16),
    FontFace = fnt("bold"), Text = "Daftar Lokasi Teleport", TextColor3 = W.TXT, TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, cardDaftar)
buat("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 12),
    FontFace = fnt("reg"), Text = "Klik nama untuk ubah • TP untuk berpindah.",
    TextColor3 = W.SUB, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
}, cardDaftar)
local searchBox = buat("TextBox", {
    Position = UDim2.new(0, 12, 0, 48), Size = UDim2.new(1, -24, 0, 28),
    BackgroundColor3 = W.BG0, BorderSizePixel = 0,
    FontFace = fnt("reg"), PlaceholderText = "🔍  Cari lokasi...",
    PlaceholderColor3 = W.SUB, Text = "", TextColor3 = W.TXT,
    TextSize = 11, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
}, cardDaftar)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, searchBox)
local searchStroke = buat("UIStroke", {Color = W.BORDER, Thickness = 1}, searchBox)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10)}, searchBox)
local scrollLok = buat("ScrollingFrame", {
    Position = UDim2.new(0, 12, 0, 84), Size = UDim2.new(1, -24, 1, -94),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = W.BORDER,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, cardDaftar)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollLok)

-- [19] UPDATE STATUS UI -----------------------------------------------
updateSpeedUI = function()
    if speedOn then
        speedPill.Text = string.format("%.2f · Q", speedValue)
        speedPill.BackgroundColor3 = W.BLUEDIM
        speedPill.TextColor3 = W.TXT
    else
        speedPill.Text = "OFF · Q"
        speedPill.BackgroundColor3 = W.ABU
        speedPill.TextColor3 = W.SUB
    end
    speedBig.Text = string.format("%.2f", speedValue)
end

updateLightUI = function()
    if lightOn then
        lightPill.Text = "AKTIF · C"
        lightPill.BackgroundColor3 = W.GREEN
        lightPill.BackgroundTransparency = 0.75
        lightPill.TextColor3 = W.GREEN
    else
        lightPill.Text = "NONAKTIF"
        lightPill.BackgroundColor3 = W.ABU
        lightPill.BackgroundTransparency = 0.4
        lightPill.TextColor3 = W.SUB
    end
end

updateNavDots = function()
    navDots[1].BackgroundColor3 = W.GREEN
    navDots[2].BackgroundColor3 = W.BLUE
end

updatePill = function()
    local warna, teks
    if tabAktif == 1 then
        warna, teks = W.GREEN, "Script aktif"
    else
        warna, teks = W.GREEN, ("%d lokasi"):format(#lokasiTersimpan)
    end
    pillLabel.Text = teks
    pillLabel.TextColor3 = warna
    pill.BackgroundColor3 = warna
    pill.BackgroundTransparency = 0.85
    pillStroke.Color = warna
    pillDot.BackgroundColor3 = warna
end

perbaruiBadge = function()
    local bagian = {}
    if speedOn then table.insert(bagian, string.format("⚡ %.2f", speedValue)) end
    if lightOn then table.insert(bagian, "☀") end
    local teks = table.concat(bagian, "  ")
    badge.Text = teks
    badge.Visible = icon.Visible and teks ~= ""
end

local teksHeader = {
    [1] = {"TAB 1 · SETTINGS", "Tools", "Atur movement, pencahayaan, dan kontrol script."},
    [2] = {"TAB 2 · NAVIGATION", "Teleport", "Kelola dan teleport ke lokasi tersimpan."},
}
local teksSidebar = {
    [1] = "Atur kecepatan, pencahayaan, dan hotkey.\n\nTekan <b>F</b> untuk buka/tutup GUI.",
    [2] = "Simpan lokasi favorit, lalu TP kapan saja.\n\nKlik <b>nama</b> untuk mengubah nama lokasi.",
}
local teksFooter = {
    [1] = {"Semua fitur berjalan di client", "Config · per game"},
    [2] = {"Data tersimpan otomatis", FILE_LOKASI},
}

fungsiPilihTab = function(n)
    tabAktif = n
    for i = 1, 2 do
        tabFrames[i].Visible = (i == n)
        local nb = navBtns[i]
        if i == n then
            nb.btn.BackgroundColor3 = W.BLUEDIM
            nb.label.TextColor3 = W.TXT
            nb.ikon.TextColor3 = W.TXT
        else
            nb.btn.BackgroundColor3 = W.BG0
            nb.label.TextColor3 = W.SUB
            nb.ikon.TextColor3 = W.SUB
        end
    end
    local h = teksHeader[n]
    eyebrow.Text, judul.Text, subjudul.Text = h[1], h[2], h[3]
    sidebarFooter.Text = teksSidebar[n]
    local f = teksFooter[n]
    footLeft.Text, footRight.Text = f[1], f[2]
    updatePill()
    updateNavDots()
end

-- [20] SPEEDWALK --------------------------------------------------------
local function terapkanSpeed()
    local _, _, hum = getKarakter()
    if hum then
        hum.WalkSpeed = speedOn and speedValue or SPEED_NORMAL
    end
end

local function setSpeed(on)
    speedOn = on
    terapkanSpeed()
    updateSpeedUI()
    perbaruiBadge()
end

local sliderDrag = false
local function sliderDariX(xPos)
    local rel = (xPos - sliderBar.AbsolutePosition.X) / math.max(sliderBar.AbsoluteSize.X, 1)
    rel = math.clamp(rel, 0, 1)
    speedValue = SPEED_MIN + rel * (SPEED_MAX - SPEED_MIN)
    speedValue = math.floor(speedValue / SPEED_STEP + 0.5) * SPEED_STEP
    speedValue = math.clamp(speedValue, SPEED_MIN, SPEED_MAX)
    updateSliderVis((speedValue - SPEED_MIN) / (SPEED_MAX - SPEED_MIN))
    speedBig.Text = string.format("%.2f", speedValue)
    if speedOn then terapkanSpeed() end
    updateSpeedUI()
end
sliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then sliderDrag = true end
end)
sliderBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        sliderDrag = true
        sliderDariX(input.Position.X)
    end
end)
sambung(UserInputService.InputChanged, function(input)
    if sliderDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        sliderDariX(input.Position.X)
    end
end)
sambung(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then sliderDrag = false end
end)

speedPill.MouseButton1Click:Connect(function()
    ripple(speedPill, W.BLUE)
    setSpeed(not speedOn)
    bunyi(SND_PING, 0.3, speedOn and 1.2 or 0.9)
    toast(speedOn and string.format("⚡ Speedwalk ON: %.2f", speedValue)
        or string.format("⚡ OFF (kembali %.2f)", SPEED_NORMAL), W.BLUE)
end)
efekTombol(speedPill, 1.05)

-- [21] FULLBRIGHT -------------------------------------------------------
local lightOrig, lightProfil = nil, nil

local function profilLight()
    local jam = Lighting.ClockTime
    return (jam >= 6.25 and jam < 17.75) and "siang" or "malam"
end

local function terapkanProfil(mode)
    if not lightOrig then return end
    local ti = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    if mode == "siang" then
        tween(Lighting, ti, {
            Brightness = math.min(lightOrig.Brightness, 1),
            ExposureCompensation = -0.4,
            Ambient = Color3.fromRGB(88, 88, 100),
            OutdoorAmbient = Color3.fromRGB(118, 118, 130),
        })
    else
        tween(Lighting, ti, {
            Brightness = 3, ExposureCompensation = 0.35,
            Ambient = Color3.fromRGB(198, 198, 210),
            OutdoorAmbient = Color3.fromRGB(198, 198, 210),
            FogEnd = 100000,
        })
        Lighting.GlobalShadows = false
    end
end

local function setLight(on, dariKlik)
    lightOn = on
    if on then
        lightOrig = {
            Brightness = Lighting.Brightness,
            ExposureCompensation = Lighting.ExposureCompensation,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
        }
        lightProfil = profilLight()
        terapkanProfil(lightProfil)
        task.spawn(function()
            while lightOn and screenGui.Parent do
                task.wait(0.5)
                if not lightOn then break end
                local p = profilLight()
                if p ~= lightProfil then
                    lightProfil = p
                    terapkanProfil(p)
                    toast(p == "siang" and "☀ Siang: diredakan" or "🌙 Malam: diterangkan", W.AMBER)
                end
            end
        end)
    else
        if lightOrig then
            local ti = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            tween(Lighting, ti, {
                Brightness = lightOrig.Brightness,
                ExposureCompensation = lightOrig.ExposureCompensation,
                Ambient = lightOrig.Ambient,
                OutdoorAmbient = lightOrig.OutdoorAmbient,
                FogEnd = lightOrig.FogEnd,
            })
            Lighting.GlobalShadows = lightOrig.GlobalShadows
            lightOrig = nil
        end
        lightProfil = nil
    end
    lightSwitch.set(lightOn)
    updateLightUI()
    perbaruiBadge()
    if dariKlik then
        bunyi(SND_PING, 0.3, lightOn and 1.2 or 0.8)
        toast(lightOn and ("☀ Fullbright ON — " .. (lightProfil == "siang" and "mode siang" or "mode malam"))
            or "☀ Fullbright OFF (normal)", lightOn and W.AMBER or W.SUB)
    end
end

lightSwitch.btn.MouseButton1Click:Connect(function()
    setLight(not lightOn, true)
end)

-- [22] DAFTAR LOKASI ----------------------------------------------------
refreshLokasi = function()
    for _, c in ipairs(scrollLok:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local q = trim(searchBox.Text):lower()
    lokasiCounter.Text = ("%d lokasi tersimpan"):format(#lokasiTersimpan)
    if tabAktif == 2 then updatePill() end

    local urut = 0
    for _, lok in ipairs(lokasiTersimpan) do
        if q == "" or lok.nama:lower():find(q, 1, true) then
            urut += 1
            local item = buat("Frame", {
                Size = UDim2.new(1, -6, 0, 44), BackgroundColor3 = W.CARD2,
                BorderSizePixel = 0, LayoutOrder = urut,
            }, scrollLok)
            buat("UICorner", {CornerRadius = UDim.new(0, 9)}, item)
            buat("UIStroke", {Color = W.BORDER, Thickness = 1}, item)

            local nameEdit = buat("TextBox", {
                BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 4),
                Size = UDim2.new(1, -140, 0, 18), FontFace = fnt("bold"),
                Text = lok.nama, TextColor3 = W.TXT, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, item)
            buat("TextLabel", {
                BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 23),
                Size = UDim2.new(1, -140, 0, 12), FontFace = fnt("reg"),
                Text = tostring(lok.waktu or "?"), TextColor3 = W.SUB, TextSize = 9,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, item)

            nameEdit.Focused:Connect(function() nameEdit.BackgroundTransparency = 0.2 end)
            nameEdit.FocusLost:Connect(function()
                nameEdit.BackgroundTransparency = 1
                local baru = trim(nameEdit.Text)
                if baru ~= "" and baru ~= lok.nama then
                    lok.nama = baru
                    simpanLokasiKeFile()
                elseif baru == "" then
                    nameEdit.Text = lok.nama
                end
            end)

            local tpBtn = buat("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -46, 0.5, 0),
                Size = UDim2.fromOffset(52, 26), BackgroundColor3 = Color3.fromRGB(30, 64, 120),
                BorderSizePixel = 0, FontFace = fnt("bold"), Text = "◎ TP",
                TextColor3 = W.CYAN, TextSize = 10, AutoButtonColor = false,
            }, item)
            buat("UICorner", {CornerRadius = UDim.new(0, 7)}, tpBtn)
            tpBtn.MouseButton1Click:Connect(function()
                ripple(tpBtn, W.BLUE)
                teleportKe(lok.cframe)
                fxTeleport()
                toast("🚀 TP: " .. lok.nama, W.BLUE)
            end)

            local delBtn = buat("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(28, 26), BackgroundColor3 = Color3.fromRGB(60, 24, 30),
                BorderSizePixel = 0, Font = Enum.Font.SourceSans, Text = "🗑️",
                TextSize = 12, TextColor3 = W.RED, AutoButtonColor = false,
            }, item)
            buat("UICorner", {CornerRadius = UDim.new(0, 7)}, delBtn)
            delBtn.MouseButton1Click:Connect(konfirmasiDuaKali(delBtn, "🗑️", function()
                bunyi(SND_SNAP, 0.3, 0.7)
                for idx, l in ipairs(lokasiTersimpan) do
                    if l == lok then table.remove(lokasiTersimpan, idx) break end
                end
                simpanLokasiKeFile()
                toast("🗑️ Dihapus: " .. lok.nama, W.RED)
                refreshLokasi()
            end))
        end
    end

    if urut == 0 then
        local kosong = buat("TextLabel", {
            Size = UDim2.new(1, -6, 0, 60), BackgroundTransparency = 1,
            FontFace = fnt("reg"), TextWrapped = true,
            Text = q ~= "" and ('Tidak ada hasil untuk "' .. q .. '"')
                or "Belum ada lokasi. Isi nama lalu klik + SIMPAN.",
            TextColor3 = W.SUB, TextSize = 11,
        }, scrollLok)
        kosong.LayoutOrder = 999
    end
end

-- [23] KLIK-KLIK ----------------------------------------------------------
local function simpanLokasi()
    local _, hrp = getKarakter()
    if not hrp then
        toast("⚠ Karakter belum siap", W.RED)
        return
    end
    local nama = trim(nameBox.Text)
    if nama == "" then
        local daftarNama = {}
        for _, l in ipairs(lokasiTersimpan) do table.insert(daftarNama, l.nama) end
        nama = ("Lokasi %d"):format(nomorBebas("Lokasi", daftarNama))
    end
    table.insert(lokasiTersimpan, {
        id = idBaru(), nama = nama, waktu = os.date("%d/%m %H:%M"), cframe = hrp.CFrame,
    })
    simpanLokasiKeFile()
    nameBox.Text = ""
    nameBox:ReleaseFocus()
    refreshLokasi()
    scrollLok.CanvasPosition = Vector2.new(0, 1e6)
    bunyi(SND_SNAP, 0.4)
    toast(fileOk and ("💾 Tersimpan permanen: " .. nama) or ("💾 Tersimpan (sesi): " .. nama), W.GREEN)
end

saveBtn.MouseButton1Click:Connect(function()
    ripple(saveBtn, W.GREEN)
    simpanLokasi()
end)
efekTombol(saveBtn, 1.05)
nameBox.FocusLost:Connect(function(enter)
    if enter then simpanLokasi() end
end)
sambung(searchBox:GetPropertyChangedSignal("Text"), function()
    refreshLokasi()
end)
sorotInput(nameBox, nameStroke, 0.6)
sorotInput(searchBox, searchStroke, 0.6)

-- [24] UNLOAD ---------------------------------------------------------------
local sudahUnload = false
local function unloadScript()
    if sudahUnload then return end
    sudahUnload = true
    print("[RouteTools] Menghapus script…")
    local _, _, hum = getKarakter()
    if hum then
        hum.WalkSpeed = origSpeed or SPEED_NORMAL
    end
    if lightOn then setLight(false) end
    for _, c in ipairs(koneksi) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(koneksi)
    pcall(function() screenGui:Destroy() end)
    print("[RouteTools] Bye! 👋 (lokasi aman di file)")
end
unloadBtn.MouseButton1Click:Connect(konfirmasiDuaKali(unloadBtn, "Hapus Script", unloadScript))
efekTombol(unloadBtn, 1.03)

-- [25] MINIMIZE / BUKA / DRAG ------------------------------------------------
local sesiAnim = 0
local function minimizeGui()
    if not root.Visible then return end
    sesiAnim += 1
    local id = sesiAnim
    bunyi(SND_PING, 0.3, 0.75)
    icon.Visible = true
    iconScale.Scale = 0.4
    tween(iconScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
    perbaruiBadge()
    local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    tween(panelScale, ti, {Scale = 0.7})
    task.delay(0.2, function()
        if sesiAnim ~= id then return end
        root.Visible = false
        panelScale.Scale = 1
    end)
end

local function bukaGui()
    sesiAnim += 1
    bunyi(SND_PING, 0.35, 1.15)
    icon.Visible = false
    badge.Visible = false
    root.Visible = true
    panelScale.Scale = 0.75
    tween(panelScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
end

minBtn.MouseButton1Click:Connect(function()
    ripple(minBtn, W.BLUE)
    minimizeGui()
end)

local iconDown = nil
icon.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        iconDown = os.clock()
    end
end)
icon.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if iconDown and (os.clock() - iconDown) < 0.4 then
            bukaGui()
        end
        iconDown = nil
    end
end)

local function buatDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, target.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    sambung(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, math.round(startPos.X.Offset + delta.X),
                startPos.Y.Scale, math.round(startPos.Y.Offset + delta.Y))
        end
    end)
end
buatDraggable(logoDrag, root)
buatDraggable(headerDrag, root)

-- [26] HOTKEY -----------------------------------------------------------------
sambung(UserInputService.InputBegan, function(input, gameProcessed)
    if gameProcessed then return end
    local kc = input.KeyCode
    if kc == TOGGLE_KEY then
        if root.Visible then minimizeGui() else bukaGui() end
        return
    end
    if not hotkeyAktif then return end
    if kc == KEY_SPEED then
        setSpeed(not speedOn)
        bunyi(SND_PING, 0.3, speedOn and 1.2 or 0.9)
        toast(speedOn and string.format("⚡ ON: %.2f", speedValue)
            or string.format("⚡ OFF (%.2f)", SPEED_NORMAL), W.BLUE)
    elseif kc == KEY_LIGHT then
        setLight(not lightOn, true)
    end
end)

masterSwitch.btn.MouseButton1Click:Connect(function()
    hotkeyAktif = not hotkeyAktif
    masterSwitch.set(hotkeyAktif)
    bunyi(SND_PING, 0.3, hotkeyAktif and 1.2 or 0.8)
    toast(hotkeyAktif and "⌨ Hotkey AKTIF" or "⌨ Hotkey MATI (F tetap jalan)",
        hotkeyAktif and W.GREEN or W.RED)
end)

-- [27] RESPAWN ------------------------------------------------------------------
sambung(LocalPlayer.CharacterAdded, function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        if origSpeed == nil then origSpeed = hum.WalkSpeed end
        task.wait(0.2)
        hum.WalkSpeed = speedOn and speedValue or SPEED_NORMAL
    end
end)
do
    local _, _, hum0 = getKarakter()
    if hum0 then origSpeed = hum0.WalkSpeed end
end

-- [28] MULAI ---------------------------------------------------------------------
fungsiPilihTab(1)
updateSpeedUI()
updateLightUI()
refreshLokasi()
task.delay(0.15, bukaGui)

task.delay(1.2, function()
    if #lokasiTersimpan > 0 then
        toast("📂 " .. #lokasiTersimpan .. " lokasi dimuat", W.BLUE)
    elseif not fileOk then
        toast("⚠ File API tidak tersedia — data hanya sesi ini", W.RED)
    end
end)

print("[RouteTools] v6.3 LITE SIAP ✔ — F=GUI Q=SPEED C=CAHAYA")
print("[RouteTools] File: " .. FILE_LOKASI
    .. (fileOk and (" (PlaceId " .. game.PlaceId .. ")") or " — TIDAK TERSEDIA"))
