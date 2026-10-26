--========================================================
--  BALAP v1.0.1 — 
--  TEMA: SILAU NEON (ungu/biru LED)
--
--  3 TAB:
--    1 🏃 GERAK  : Speed, Jump, Shiftlock, Moonwalk, Fall Resist, Anti-AFK
--    2 🎨 VISUAL : Hide, Hide Pemain Lain, Cahaya Auto 2 arah, Lightweight, Dinding Batas
--    3 ⚙️ SISTEM : reset, rejoin, hapus script
--
--  Keybind:
--    G = buka/tutup GUI (saat tutup = hilang total)
--    Q = Speed ON/OFF (nilai ON dipilih di panel: 17.25-21.25)
--    J = JumpPower (51.25 ⇄ 65.25)    C = Shiftlock Mobile
--    F = Moonwalk    B = Fall Resist (preset 5/20/50/75%)    R = Hide
--    T = Cahaya Auto (2 arah)    X = Dinding Batas
--    K = Rejoin (double-tap)
--    TP = via GUI (tab GERAK): simpan lokasi dgn nama bebas — permanen
--
--  v1.0.1: Moonwalk halus (putaran natural, CFG.MOON_TURN_MAX)
--========================================================
print("[BALAP v1.0.1] load mulai...")
-- [0] DIAGNOSTIK ON-SCREEN -----------------------------------------
-- Banner kecil pojok kiri: menunjukkan progres load. Kalau load GAGAL,
-- banner berubah MERAH dan menampilkan teks errornya di layar.
do
        local __dGui, __dLbl
        pcall(function()
                __dGui = Instance.new("ScreenGui")
                __dGui.Name = "BALAP_DIAG"
                __dGui.ResetOnSpawn = false
                __dGui.DisplayOrder = 1000000
                __dLbl = Instance.new("TextLabel")
                __dLbl.Size = UDim2.new(0, 480, 0, 38)
                __dLbl.Position = UDim2.new(0, 8, 0, 120)
                __dLbl.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
                __dLbl.BackgroundTransparency = 0.1
                __dLbl.BorderSizePixel = 0
                __dLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                __dLbl.Font = Enum.Font.GothamBold
                __dLbl.TextSize = 13
                __dLbl.TextWrapped = true
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
        function diagSet(teks, warna)
                print("[BALAP-DIAG] " .. tostring(teks))
                pcall(function()
                        if __dGui and __dGui.Parent and __dLbl then
                                __dLbl.Text = tostring(teks)
                                if warna then __dLbl.BackgroundColor3 = warna end
                        end
                end)
        end
end

local VERSI = "1.0.1"
local __BALAP_LOAD_OK__ = xpcall(function()
-- ================================================================
-- BODY DIBUNGKUS xpcall: kalau ada error apapun saat load, teks
-- error + nomor baris LANGSUNG tampil di layar (tidak hilang diam).
-- ================================================================

-- [1] PENGAMAN DASAR -----------------------------------------------
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
local VirtualUser      = game:GetService("VirtualUser")
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

-- ANTI DOUBLE-INSTANCE (TAKEOVER): eksekusi baru SELALU jalan & memasang
-- token baru; instance lama melihat token berganti / GUI-nya dihapus ->
-- unload sendiri (guard `if _G.__BALAP_MAIN__` lama bisa menolak versi
-- baru diam-diam atau membiarkan 2 instance jalan bersamaan).
local MY_TOKEN = {}
_G.__BALAP_TOKEN__ = MY_TOKEN
_G.__BALAP_MAIN__ = true  -- penanda lama, tetap dibersihkan unloadScript

-- [2] KONFIGURASI ---------------------------------------------------
-- Semua konstanta digabung ke dalam 1 table CFG untuk hemat local count
-- (Luau limit 200 local per function)
local CFG = {
    ICON_SIZE       = 36,
    TOGGLE_KEY      = Enum.KeyCode.G,
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
    -- Moonwalk (F): putaran NATURAL seperti badan orang berbalik arah biasa.
    --   MOON_TURN_MAX = kecepatan putar maks (rad/dtk). 8 = ±458°/dtk,
    --     putaran 180° selesai ±0.4 dtk. Lebih lambat? turunkan (mis. 5-6).
    --   MOON_SMOOTH = kelembutan mendarat & koreksi kecil (makin kecil makin lembut).
    --   Badan hanya berputar saat karakter BERGERAK; berdiri = diam total.
    MOON_TURN_MAX = 8,
    MOON_SMOOTH = 6,
    SND_PING   = "rbxasset://sounds/electronicpingshort.wav",
    SND_SNAP   = "rbxasset://sounds/snap.mp3",
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

diagSet("dasar OK — siapkan helper GUI...")
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
local effGradients, effTweens = {}, {}   -- registry efek neon utk Mode Hemat
local setFeature, togglePanel, resetAll, rejoin, unloadScript
local applySpeed, applyJump, updateJumpLabel
local RefreshSpeed, RefreshJump, JumpLabel, SpeedLabel, AfkLabel, FallLabel
local cfgFall, oLight, fallState, fallRay, lightConn, refreshFallPreset, PRESET_FALL

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
            if not State.HematOn then
                tween(obj, TweenInfo.new(interval * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {[prop] = colors[i]})
            end
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
    table.insert(effTweens, tween(stripe, TweenInfo.new(6 + i * 2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true),
        {Position = UDim2.new(0.3 * i + 0.25, 0, 0.5, 0)}))
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
    Text = "⚡ BALAP v1.0.1 ⚡",
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
State.MoonOn  = false  -- Moonwalk (F)
State.HideAtasOn = false  -- Hide Badan Atas (VISUAL, layar sendiri)
State.HematOn = false    -- Mode Hemat GUI
State.AfkOn   = true   -- Anti-AFK (port dari A, default ON)

-- ======================================================================
-- FALL RESIST V1.07 (port script standalone -- menggantikan Smart Fall
-- Assist model REFUND v1.7 yang ternyata visual-only: Health milik
-- server, tulisan HP dari client langsung tertimpa replikasi).
-- 1 angka: POTONGAN DEMAGE jatuh %, dipilih lewat 4 tombol preset.
-- Mekanisme: SILENT PULSE "Landed" 0.08 dtk + PLANNER kurva demage
-- (data tes user) -- fisika & kecepatan TIDAK disentuh, HP TIDAK
-- ditulis; damage server beneran berkurang karena hitungan tinggi
-- jatuh game tereset oleh pulse. TANPA batas tinggi (v1.07): semua
-- lompatan/jatuh diawasi & bisa langsung ke-trigger.
-- ======================================================================
PRESET_FALL = {
    { nama = "S.RINGAN", pct = 5  },
    { nama = "RINGAN",   pct = 20 },  -- DEFAULT
    { nama = "SEDANG",   pct = 50 },
    { nama = "BERAT",    pct = 75 },
}
cfgFall = {
    potongan = 20,        -- DEFAULT POTONGAN = 20% (RINGAN)
    idx      = 2,         -- preset terpilih: RINGAN
    VEL_MIN      = -10,   -- gerbang kecepatan turun (tercapai ~0.25 stud setelah mulai jatuh)
    BATAS_RIIL   = 30,    -- jatuh >= 30 stud = "riil" (pulse mengunci + notif); di bawah = sia-sia
    PULSE_DURASI = 0.08,  -- jendela pulse "Landed" (port SILENT PULSE v1.3)
    JEDA_RAY     = 0.10,  -- raycast tanah 10Hz saat jauh, tiap frame saat dekat (<60 stud)
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

-- State Fall Resist V1.07
fallState = {
    jatuh         = false, -- sedang terbangan (record aktif)
    apex          = 0,     -- titik tertinggi sejak freefall
    bentur        = false, -- LATCH per-record: 1x pulse per jatuh
    sejak         = 0,     -- os.clock() saat freefall mulai
    groundY       = nil,   -- cache ketinggian tanah (raycast)
    lastRay       = 0,
    conn          = nil,   -- koneksi Heartbeat (dipakai unloadScript)
    pulseSampai   = nil,   -- jendela pulse aktif sampai waktu ini
    sudahPulse    = false, -- LATCH global: 1x per jatuh RIIL (anti pantulan lereng)
    pulseHarmless = false, -- pulse terakhir cuma di jatuh kecil (sia-sia)
    tanahSejak    = nil,   -- re-arm stabil: menempel tanah >= 0.30 dtk
    hum           = nil,   -- humanoid pemilik record (anti record basi saat respawn)
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
buatToggleRow(scrollKing, "Moonwalk", "F", "Moon")
buatHeader(scrollKing, "Anti AFK")
local _, afkLbl = buatToggleRow(scrollKing, "👻 Anti-AFK (2 lapis)", nil, "Afk")
AfkLabel = afkLbl
-- ===== FALL RESIST V1.07 — toggle + 4 preset potongan demage =====
buatHeader(scrollKing, "Fall Resist")
local _, fallLbl = buatToggleRow(scrollKing, "Fall Resist", "B", "Fall")
FallLabel = fallLbl
local gridFall = buat("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 64),
    LayoutOrder = nextOrder(),
}, scrollKing)
buat("UIGridLayout", {
    CellSize = UDim2.new(0.5, -3, 0, 29),
    CellPadding = UDim2.new(0, 6, 0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, gridFall)
local presetFallBtns = {}
for i, p in ipairs(PRESET_FALL) do
    local b = buat("TextButton", {
        BackgroundColor3 = Warna.AbuItem,
        BorderSizePixel = 0,
        FontFace = fnt("bold"),
        TextSize = 10,
        TextColor3 = Warna.AbuTeks,
        Text = p.nama .. " " .. p.pct .. "%",
        AutoButtonColor = false,
        LayoutOrder = i,
    }, gridFall)
    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, b)
    presetFallBtns[i] = b
    b.MouseButton1Click:Connect(function()
        cfgFall.idx = i
        cfgFall.potongan = p.pct
        if refreshFallPreset then refreshFallPreset() end
        toast("Fall Resist: " .. p.nama .. " " .. p.pct .. "%", Warna.Biru)
    end)
end
refreshFallPreset = function()
    local pr = PRESET_FALL[cfgFall.idx or 2] or PRESET_FALL[2]
    if FallLabel and FallLabel.Parent then
        FallLabel.Text = "Fall Resist: "
            .. (State.FallOn and (pr.nama .. " " .. pr.pct .. "%") or "OFF")
    end
    for bi, bb in ipairs(presetFallBtns) do
        local aktif = (bi == cfgFall.idx)
        bb.BackgroundColor3 = aktif and Warna.Hijau or Warna.AbuItem
        bb.TextColor3 = aktif and Warna.HijauMuda or Warna.AbuTeks
    end
end
refreshFallPreset()

-- ===== TP — TELEPORT + SIMPAN LOKASI (nama bebas, permanen) ==========
-- Berdiri di tempat -> ketik nama -> 💾 SIMPAN -> muncul di daftar.
-- Tombol TP = teleport ke lokasi, X = hapus. Nama sama = update posisi.
-- Tersimpan di file BALAP_TP.json (folder Xeno) -> TETAP ADA walau
-- keluar game/rejoin. Executor tanpa writefile -> mode sesi (getgenv).
local TP_MAX     = 40
local TP_FILE    = "BALAP_TP.json"
local TP_LOKASI  = {}
local tpBisaFile = (type(writefile) == "function") and (type(readfile) == "function")

local function tpBulat(v)
    return math.floor(v * 100 + 0.5) / 100
end

local function tpTulisFile()
    getgenv().BALAP_TP_DATA = TP_LOKASI            -- cadangan sesi (re-execute)
    if not tpBisaFile then return end
    local data = {}
    for i = 1, #TP_LOKASI do
        local L = TP_LOKASI[i]
        data[i] = { nama = L.nama, x = tpBulat(L.x), y = tpBulat(L.y), z = tpBulat(L.z) }
    end
    local ok, err = pcall(function()
        writefile(TP_FILE, HttpService:JSONEncode(data))
    end)
    if not ok then warn("[BALAP-TP] gagal tulis file: " .. tostring(err)) end
end

local function tpMuat()
    local data
    if tpBisaFile then
        local ada = false
        pcall(function() ada = isfile(TP_FILE) end)
        if ada then
            pcall(function() data = HttpService:JSONDecode(readfile(TP_FILE)) end)
        end
    end
    if type(data) ~= "table" then
        data = rawget(getgenv(), "BALAP_TP_DATA")   -- fallback: sesi yang sama
    end
    if type(data) == "table" then
        for _, v in ipairs(data) do
            if type(v) == "table" and type(v.nama) == "string" and #v.nama > 0
                and type(v.x) == "number" and type(v.y) == "number" and type(v.z) == "number" then
                TP_LOKASI[#TP_LOKASI + 1] = { nama = v.nama, x = v.x, y = v.y, z = v.z }
            end
        end
    end
    getgenv().BALAP_TP_DATA = TP_LOKASI
    print("[BALAP-TP] muat " .. #TP_LOKASI .. " lokasi"
        .. (tpBisaFile and " (file: " .. TP_FILE .. ")" or " (mode SESI — executor tanpa writefile)"))
end
tpMuat()

buatHeader(scrollKing, "Teleport (TP)")

-- baris input: [nama bebas] [💾 SIMPAN]
local tpInputRow = buat("Frame", {
    BackgroundColor3 = Warna.AbuItem,
    Size = UDim2.new(1, 0, 0, 30),
    LayoutOrder = nextOrder(),
}, scrollKing)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, tpInputRow)
local tpInput = buat("TextBox", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0.5, -11),
    Size = UDim2.new(1, -118, 0, 22),
    FontFace = fnt("med"),
    TextSize = 11,
    TextColor3 = Warna.TeksGelap,
    PlaceholderText = "Nama lokasi (bebas)...",
    PlaceholderColor3 = Warna.AbuTeks,
    Text = "",
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
}, tpInputRow)
local tpSaveBtn = buat("TextButton", {
    BackgroundColor3 = Warna.Hijau,
    Position = UDim2.new(1, -100, 0.5, -11),
    Size = UDim2.new(0, 92, 0, 22),
    FontFace = fnt("bold"),
    TextSize = 10,
    TextColor3 = Warna.HijauMuda,
    Text = "SIMPAN",
    AutoButtonColor = false,
}, tpInputRow)
buat("UICorner", {CornerRadius = UDim.new(0, 6)}, tpSaveBtn)

-- daftar lokasi (membesar otomatis, ikut scroll tab GERAK)
local tpList = buat("Frame", {
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    LayoutOrder = nextOrder(),
}, scrollKing)
buat("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, tpList)

local function tpRefresh()
    for _, c in ipairs(tpList:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") or c:IsA("Frame") then c:Destroy() end
    end
    if #TP_LOKASI == 0 then
        buat("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            FontFace = fnt("reg"),
            TextSize = 10,
            TextColor3 = Warna.AbuTeks,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Belum ada lokasi — berdiri di tempat, ketik nama, tekan SIMPAN",
            LayoutOrder = 0,
        }, tpList)
        return
    end
    for i, L in ipairs(TP_LOKASI) do
        local row = buat("Frame", {
            BackgroundColor3 = Warna.AbuItem,
            Size = UDim2.new(1, 0, 0, 28),
            LayoutOrder = i,
        }, tpList)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
        buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -130, 1, 0),
            FontFace = fnt("med"),
            TextSize = 10,
            TextColor3 = Warna.TeksGelap,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = L.nama .. "  (" .. math.floor(L.y) .. "m)",
        }, row)
        local btnTp = buat("TextButton", {
            BackgroundColor3 = Warna.Biru,
            Position = UDim2.new(1, -88, 0.5, -10),
            Size = UDim2.new(0, 50, 0, 20),
            FontFace = fnt("bold"),
            TextSize = 10,
            TextColor3 = Warna.Putih,
            Text = "TP",
            AutoButtonColor = false,
        }, row)
        buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnTp)
        local btnHps = buat("TextButton", {
            BackgroundColor3 = Warna.Merah,
            Position = UDim2.new(1, -32, 0.5, -10),
            Size = UDim2.new(0, 26, 0, 20),
            FontFace = fnt("bold"),
            TextSize = 10,
            TextColor3 = Warna.Putih,
            Text = "X",
            AutoButtonColor = false,
        }, row)
        buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnHps)
        btnTp.MouseButton1Click:Connect(function()
            local _, hrp = getKarakter()
            if not hrp then toast("TP gagal — karakter belum ada", Warna.Merah) return end
            hrp.CFrame = CFrame.new(L.x, L.y + 3, L.z)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            print("[BALAP-TP] teleport ke '" .. L.nama .. "'")
            toast("TP: " .. L.nama, Warna.Biru)
        end)
        btnHps.MouseButton1Click:Connect(function()
            table.remove(TP_LOKASI, i)
            tpTulisFile()
            tpRefresh()
            print("[BALAP-TP] hapus '" .. L.nama .. "' (sisa " .. #TP_LOKASI .. ")")
            toast("Hapus: " .. L.nama, Warna.Merah)
        end)
    end
end

tpSaveBtn.MouseButton1Click:Connect(function()
    local nama = tostring(tpInput.Text):gsub("^%s+", ""):gsub("%s+$", "")
    if #nama == 0 then toast("Tulis dulu nama lokasinya", Warna.Kuning) return end
    local _, hrp = getKarakter()
    if not hrp then toast("Karakter belum ada — coba lagi", Warna.Merah) return end
    local p = hrp.Position
    for _, L in ipairs(TP_LOKASI) do
        if L.nama == nama then                    -- nama sama = update posisi
            L.x, L.y, L.z = p.X, p.Y, p.Z
            tpTulisFile()
            tpRefresh()
            tpInput.Text = ""
            print("[BALAP-TP] update '" .. nama .. "' (total " .. #TP_LOKASI .. ")")
            toast("Diperbarui: " .. nama, Warna.Hijau)
            return
        end
    end
    if #TP_LOKASI >= TP_MAX then toast("Penuh (max " .. TP_MAX .. " lokasi)", Warna.Kuning) return end
    TP_LOKASI[#TP_LOKASI + 1] = { nama = nama, x = p.X, y = p.Y, z = p.Z }
    tpTulisFile()
    tpRefresh()
    tpInput.Text = ""
    print("[BALAP-TP] simpan '" .. nama .. "' (total " .. #TP_LOKASI .. ")"
        .. (tpBisaFile and " -> file" or " -> SESI SAJA (executor tanpa writefile)"))
    toast("Tersimpan: " .. nama, Warna.Hijau)
end)

tpRefresh()

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
buatToggleRow(scrollVisual, "Hide Badan Atas (kaki tetap)", nil, "HideAtas")
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
    Size = UDim2.new(1, 0, 0, 90),
    FontFace = fnt("med"),
    TextSize = 11,
    TextColor3 = Warna.TeksGelap,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Text = "⚡ BALAP v1.0.1\n"
        .. "Script balapan gabungan — fitur dinding skrip lain melebur di sini\n"
        .. "3 TAB: 🏃 GERAK | 🎨 VISUAL | ⚙️ SISTEM\n"
        .. "TP: simpan lokasi (nama bebas) — tersimpan permanen\n"
        .. "Hide Atas (VISUAL) • Hemat GUI (SISTEM) • buka/tutup instan\n"
        .. "Keybind: G panel • Q speed • J jump • C shift • F moon\n"
        .. "B fall resist • R hide • T cahaya • X dinding • K×2 rejoin",
    LayoutOrder = nextOrder(),
}, scrollSistem)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, infoVersi)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, infoVersi)
buatHeader(scrollSistem, "Hemat")
buatToggleRow(scrollSistem, "🪶 Hemat GUI (neon & animasi)", nil, "Hemat")
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
    Size = UDim2.new(1, 0, 0, 132),
    FontFace = fnt("med"),
    TextSize = 11,
    TextColor3 = Warna.AbuTeks,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = true,
    Text = "Tema SILAU NEON (ungu/biru LED) ⚡\n"
        .. "Basis: SILAU BALAPAN v1.1 — 5 skrip digabung jadi 1\n"
        .. "v1.0.1: Moonwalk putaran natural (lembut & terukur)\n"
        .. "Fitur jatuh: FALL RESIST V1.07 — silent pulse + planner\n"
        .. "kurva demage, preset S.RINGAN 5% s/d BERAT 75%\n"
        .. "TP permanen via BALAP_TP.json • anti double-instance",
    LayoutOrder = nextOrder(),
}, scrollSistem)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, infoKredit)
buat("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, infoKredit)

end -- akhir buildUI()

-- Eksekusi buildUI() sekarang (panel, root, outer, Warna, buat sudah ada dari part1)
buildUI()
diagSet("GUI utama OK — bikin efek & notif...")

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
    Text = "⌨ G = GUI   ✦   🏃 Q Speed ON/OFF (nilai ON 17.25-21.25 di panel) • J Jump (51.25/65.25) • C Shift • F Moonwalk • B FallResist   ✦   🎨 R Hide • Hide Pemain Lain • T Cahaya 2-arah • X Dinding • LW   ✦   ⚙️ K×2 rejoin • Notif kanan atas",
    TextColor3 = Warna.AbuGelap,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
}, marqueeClip)
table.insert(effTweens, tween(marquee, TweenInfo.new(24, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    {Position = UDim2.fromOffset(-1600, 0)}))

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
            table.insert(effTweens, tween(l, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {Rotation = l.Rotation + rnd(16, 30) * (rnd(0, 1) == 0 and 1 or -1)}))
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
    if State.HematOn then return end
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
    if State.HematOn then return end
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
    if State.HematOn then
        -- mode hemat: tampil instan tanpa animasi
        t.Position = UDim2.new(1, 0, 0, 0)
        t.BackgroundTransparency = 0.05
        st.Transparency = 0.15
        dot.BackgroundTransparency = 0
        lb.TextTransparency = 0
        task.delay(1.6, function() t:Destroy() end)
        local listH = {}
        for _, c in ipairs(notifHolder:GetChildren()) do
            if c:IsA("Frame") and c.Name == "NoFade" then table.insert(listH, c) end
        end
        if #listH > 5 then listH[1]:Destroy() end
        return
    end
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
diagSet("efek OK — pasang logika fitur...")

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

-- MOONWALK (F) — badan TERKUNCI menghadap kamera/layar saat jalan.
-- Rotasi NATURAL: kecepatan putar dibatasi CFG.MOON_TURN_MAX (berjalan
-- konstan seperti badan berbalik arah biasa — tanpa sentakan awal), lalu
-- lerp sudut terpendek utk mendarat lembut (anti muter keliling).
Setters.Moon = function(v, silent)
    if State.MoonOn == v then return end
    State.MoonOn = v
    if v then
        local hum = getHum()
        if hum then hum.AutoRotate = false end
        RunService:BindToRenderStep("KS_MOONWALK", Enum.RenderPriority.Character.Value + 1, function(dt)
            local char = getChar()
            local h = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.Health > 0 then
                local cam = Workspace.CurrentCamera
                -- DIAM = TIDAK BEROTASI: badan hanya mengejar kamera saat
                -- karakter benar-benar bergerak (ada arah input). Berdiri
                -- tenang = badan tetap di arah terakhir, tidak berputar.
                if cam and h.MoveDirection.Magnitude > 0.01 then
                    local _, yawCam = cam.CFrame:ToOrientation()
                    -- putar 180 derajat = badan menghadap kamera
                    local target = yawCam + math.pi
                    -- NATURAL: langkah lerp + BATAS KECEPATAN PUTAR. Putaran
                    -- besar = kecepatan konstan (seperti orang berbalik arah),
                    -- putaran kecil = lerp lembut sampai target.
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

-- HIDE BADAN ATAS — sembunyikan KEPALA s/d BADAN & TANGAN milik
-- DIRI SENDIRI, hanya di layar sendiri (LocalTransparencyModifier).
-- Tetap tampil: pinggang ke bawah (celana) + kaki + sepatu.
-- klasifikasi 4 LAPIS (rambut/aksesoris atas sering lolos):
--   1) nama part tubuh standar (R15/R6) -> langsung diketahui
--   2) rantai weld/joint (Weld, WeldConstraint, Motor6D, AccessoryWeld)
--      sampai 6 hop -> part tubuh tempat menempel
--      (banyak rambut/topi modern pakai WeldConstraint)
--   3) peta attachment: attachment milik aksesoris dicocokkan ke attachment
--      part tubuh (cara resmi Roblox menentukan posisi aksesoris)
--   4) posisi dunia: di atas garis pinggang (HRP - 1 stud) = sembunyi,
--      di bawah = tampil (jaring pengaman rambut/topi tanpa weld)
--   Kalau semua gagal -> SEMBUNYI (ragu = sembunyi; yang tampil hanya
--   kaki/celana/sepatu sesuai permintaan).
-- Decal (muka, lensa, tekstur) di dalam part sembunyi ikut dihilangkan.
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
local function atasIkat(part, hop)   -- telusuri rantai weld/joint -> nama part tubuh
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
local function atasCariAcc(part)     -- naik lewat Parent, cari Accessory induk
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
    -- garis pinggang: HRP turun 1 stud (kaki/celana/sepatu di bawahnya tetap tampil)
    local batasY = nil
    pcall(function()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then batasY = hrp.Position.Y - 1.0 end
    end)
    -- peta attachment part tubuh: nama attachment -> part pemiliknya
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
                    local tubuh = atasIkat(d, 0)          -- lapis 2: rantai weld
                    if tubuh then
                        sembunyi = (ATAS_R15[tubuh] or ATAS_R6[tubuh]) and true or false
                    else
                        local acc = atasCariAcc(d)         -- lapis 3: peta attachment
                        local att = acc and acc:FindFirstChildWhichIsA("Attachment", true) or nil
                        local owner = att and petaIkat[att.Name] or nil
                        if owner then
                            sembunyi = (ATAS_R15[owner] or ATAS_R6[owner]) and true or false
                        else
                            local okP, pos = pcall(function() return d.Position end)
                            if okP and pos and batasY then  -- lapis 4: posisi vs garis pinggang
                                sembunyi = pos.Y > batasY
                            else
                                sembunyi = true             -- ragu = sembunyi
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
Setters.HideAtas = function(v, silent)
    if State.HideAtasOn == v then return end
    State.HideAtasOn = v
    if v then
        atasSapu(true)
        atasT = 0
        atasConn = RunService.Heartbeat:Connect(function(dt)
            if not State.HideAtasOn or State.Removed then return end
            atasT = atasT + dt
            if atasT >= 0.3 then
                atasT = 0
                atasSapu(true)   -- self-heal: reset part/respawn tertangani di sini
            end
        end)
    else
        if atasConn then atasConn:Disconnect() atasConn = nil end
        atasSapu(false)
    end
    syncNotify("HideAtas", v, silent, "Hide Badan Atas")
end

-- MODE HEMAT GUI — matikan efek neon & animasi berkelanjutan:
-- gradient LED di-nonaktifkan, tween infinity di-pause, konfeti/emoji burst
-- tidak jalan, toast tampil instan. Semua reversibel (Enabled/Pause-Play).
Setters.Hemat = function(v, silent)
    if State.HematOn == v then return end
    State.HematOn = v
    if v then
        for _, g in ipairs(effGradients) do pcall(function() g.Enabled = false end) end
        for _, tw in ipairs(effTweens) do pcall(function() tw:Pause() end) end
    else
        for _, g in ipairs(effGradients) do pcall(function() g.Enabled = true end) end
        for _, tw in ipairs(effTweens) do pcall(function() tw:Play() end) end
    end
    syncNotify("Hemat", v, silent, "Mode Hemat GUI")
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

-- ======================================================================
-- FALL RESIST V1.07 — fitur jatuh BARU (port script standalone)
-- Menggantikan Smart Fall Assist model REFUND v1.7.
-- ======================================================================
-- KENAPA DIGANTI: refund menulis hum.Health dari client — Health milik
-- server, tulisan client langsung tertimpa replikasi (hasil uji v1.6:
-- setting 1% nyatanya memotong 56%, 10%/30% hasilnya acak). Satu-satunya
-- mekanisme yang TERBUKTI REAL di server (bukti data uji user) adalah
-- pulsa state "Landed": game mengira kita sudah mendarat -> hitungan
-- tinggi jatuh server TERRESET -> demage dihitung dari sisa jatuh.
--
-- KURVA DEMAGE GAME (tracked stud -> demage, kalibrasi tes user H=60):
--   30->0 | 37.5->20 | 45->27 | 48->44 | 50->51 | 60->93 (ekstra 4.2/stud)
--
-- CARA KERJA (v1.07):
--   1. SEMUA lompatan/jatuh diawasi tiap frame — TANPA batas minimal.
--      Trigger bisa sedini ~0.25 stud setelah badan mulai turun.
--   2. PLANNER: tPlan = tinggi tracked yang menghasilkan demage target
--      (normal x (1 - potongan/100)). Pulse ditembak saat sisaJatuh <=
--      tPlan + margin dinamis (|velY|/60 — kompensasi kuantisasi frame).
--      Level ringan -> trigger hampir langsung di awal jatuh; level
--      berat -> menunggu posisi tepat dekat tanah (kalau semua langsung,
--      semua level jadi sama).
--   3. PULSE: jendela 0.08 dtk state dipaksa "Landed" tiap frame.
--      Fisika & kecepatan TIDAK diubah, HP TIDAK ditulis -> 100% natural.
--   4. Latch 2 lapis + re-arm pintar: pulse di lompatan kecil (<30 stud,
--      0 demage) TIDAK mengunci jatuh besar berikutnya; pulse jatuh riil
--      cuma 1x per terbangan (anti pantulan lereng, tanah stabil 0.30 dtk).
--   5. Notif hanya untuk jatuh riil >= 30 stud (anti spam saat hop).
-- ======================================================================

local KURVA = {
    { t = 30,   d = 0  },  -- ambang 0 demage (perkiraan)
    { t = 37.5, d = 20 },  -- tes 75%: pulse di 22.5 stud -> tracked 37.5 -> 20 dmg
    { t = 45,   d = 27 },  -- tes 50%: pulse di 15 stud   -> tracked 45   -> 27 dmg
    { t = 48,   d = 44 },  -- tes 20%: pulse di gerbang   -> tracked ~48  -> 44 dmg
    { t = 50,   d = 51 },  -- tes 5% : pulse di gerbang   -> tracked ~50  -> 51 dmg
    { t = 60,   d = 93 },  -- tanpa pulse                 -> tracked 60   -> 93 dmg
}
local SLOPE_EKSTRA = (93 - 51) / (60 - 50) -- 4.2 dmg/stud utk tracked > 60

-- demage dari tinggi tracked t (interpolar linear + ekstrapolasi)
local function fDmg(t)
    if t <= KURVA[1].t then return 0 end
    for i = 2, #KURVA do
        local a, b = KURVA[i - 1], KURVA[i]
        if t <= b.t then
            local f = (t - a.t) / (b.t - a.t)
            return a.d + f * (b.d - a.d)
        end
    end
    local b = KURVA[#KURVA]
    return b.d + (t - b.t) * SLOPE_EKSTRA
end

-- kebalikan fDmg: tinggi tracked yang menghasilkan demage d
local function fInv(d)
    if d <= 0 then return KURVA[1].t end
    for i = 2, #KURVA do
        local a, b = KURVA[i - 1], KURVA[i]
        if d <= b.d then
            local f = (d - a.d) / (b.d - a.d)
            return a.t + f * (b.t - a.t)
        end
    end
    local b = KURVA[#KURVA]
    return b.t + (d - b.d) / SLOPE_EKSTRA
end

local function resetFallRecord()
    fallState.jatuh         = false
    fallState.bentur        = false
    fallState.sudahPulse    = false
    fallState.pulseHarmless = false
    fallState.tanahSejak    = nil
end

Setters.Fall = function(v, silent)
    if State.FallOn == v then return end
    State.FallOn = v
    if v then
        if fallState.conn then return end  -- sudah jalan
        fallState.conn = RunService.Heartbeat:Connect(function()
            if not State.FallOn or State.Removed then return end
            local char, hrp, hum = getKarakter()  -- urutan benar: char, HRP, Humanoid
            if not hum or not hrp then return end

            -- anti record basi: ganti karakter (respawn) -> buang record lama
            if fallState.hum and fallState.hum ~= hum then
                resetFallRecord()
                fallState.pulseSampai = nil
                fallState.hum = nil
            end

            local now = os.clock()

            -- SILENT PULSE: selama jendela pulse, paksa state "Landed" tiap
            -- frame. Kecepatan & fisika jatuh TIDAK diubah sama sekali —
            -- game hanya menerima event mendarat (penghitung tinggi tereset).
            if fallState.pulseSampai and now < fallState.pulseSampai then
                pcall(function() hum:ChangeState(Enum.HumanoidStateType.Landed) end)
            end

            local vel = hrp.AssemblyLinearVelocity
            local st
            pcall(function() st = hum:GetState() end)

            if st == Enum.HumanoidStateType.Freefall and vel.Y < -4 then
                if not fallState.jatuh then
                    fallState.jatuh       = true
                    fallState.apex        = hrp.Position.Y
                    fallState.bentur      = false
                    fallState.sejak       = now
                    fallState.groundY     = nil
                    fallState.lastRay     = 0
                    fallState.pulseSampai = nil
                    fallState.hum         = hum
                end
                fallState.apex = math.max(fallState.apex, hrp.Position.Y)

                -- cache ketinggian tanah: 10Hz saat jauh, tiap frame saat dekat
                if vel.Y < cfgFall.VEL_MIN then
                    local dekat = (fallState.groundY ~= nil)
                        and (hrp.Position.Y - fallState.groundY) < 60
                    if dekat or (now - fallState.lastRay) >= cfgFall.JEDA_RAY then
                        fallState.lastRay = now
                        fallRay.FilterDescendantsInstances = char and {char} or {}
                        local r = Workspace:Raycast(hrp.Position, Vector3.new(0, -800, 0), fallRay)
                        if r then fallState.groundY = r.Position.Y else fallState.groundY = nil end
                    end
                end

                local tinggiTotal, sisaJatuh
                if fallState.groundY then
                    sisaJatuh   = hrp.Position.Y - fallState.groundY
                    tinggiTotal = fallState.apex - fallState.groundY
                end

                -- RE-ARM PINTAR: pulse sebelumnya cuma di jatuh kecil (sia-sia),
                -- tapi sekarang jatuhnya ternyata besar (mis. melangkah dari hop
                -- ke tepi jurang) -> buka latch per-record supaya pulse ulang
                -- tetap jalan di posisi tepat.
                if fallState.bentur and fallState.pulseHarmless
                and tinggiTotal and tinggiTotal >= cfgFall.BATAS_RIIL then
                    fallState.bentur        = false
                    fallState.pulseHarmless = false
                end

                -- =========================================================
                -- PLANNER KURVA DEMAGE (TANPA GERBANG — inti v1.07)
                -- Target: demage akhir ~= (100 - potongan)% x demage normal.
                -- tPlan = tinggi tracked yang menghasilkan demage target.
                -- Pulse ditembak saat sisa jatuh <= tPlan + margin dinamis
                -- (kecepatan/60 = jarak per frame, kompensasi kuantisasi).
                -- =========================================================
                if (not fallState.bentur) and vel.Y < cfgFall.VEL_MIN then
                    local picu = false
                    if cfgFall.potongan > 0 and tinggiTotal then
                        local dNormal = fDmg(tinggiTotal)
                        local dTarget = dNormal * (1 - cfgFall.potongan / 100)
                        local tPlan   = fInv(dTarget)
                        local margin  = math.abs(vel.Y) / 60
                        if sisaJatuh <= tPlan + margin then picu = true end
                    end
                    -- fallback: tanah tidak terdeteksi raycast (jatuh sangat dalam)
                    if (not picu) and cfgFall.potongan > 0 and (not tinggiTotal)
                    and (now - fallState.sejak) > 0.6 and vel.Y < -70 then
                        picu = true
                    end
                    if picu then
                        fallState.bentur = true -- latch per-record (anti pulse beruntun)
                        local riil = (tinggiTotal or 0) >= cfgFall.BATAS_RIIL
                        if riil then
                            fallState.sudahPulse = true -- latch global (anti pantulan lereng)
                            print(string.format(
                                "[BALAP-FALL] pulse Landed terkirim — potongan %d%% | H=%.0f stud",
                                cfgFall.potongan, tinggiTotal or 0))
                            toast("Fall Resist: reset senyap di udara (" .. cfgFall.potongan .. "%)",
                                Warna.Hijau2)
                        else
                            -- jatuh kecil (0 demage): pulse tetap jalan sesuai
                            -- permintaan (tiap lompatan langsung bisa trigger),
                            -- tapi tanpa notif & tidak mengunci jatuh besar
                            -- berikutnya.
                            fallState.pulseHarmless = true
                        end
                        fallState.pulseSampai = now + cfgFall.PULSE_DURASI
                    end
                end
            elseif fallState.jatuh then
                -- RE-ARM STABIL: sentuhan tanah sesaat (pantulan / menyenggol
                -- lereng) TIDAK menghidupkan ulang pemicu. Re-arm HANYA jika:
                -- (a) menempel tanah terus >= 0.30 dtk (mendarat beneran),
                -- (b) masuk air / duduk / panjat, atau (c) mati.
                if st == Enum.HumanoidStateType.Dead then
                    resetFallRecord()
                else
                    local okRe, tanah, selesaiMutlak = pcall(function()
                        return hum.FloorMaterial ~= Enum.Material.Air,
                            st == Enum.HumanoidStateType.Swimming
                            or st == Enum.HumanoidStateType.Seated
                            or st == Enum.HumanoidStateType.Climbing
                    end)
                    if okRe then
                        if selesaiMutlak then
                            resetFallRecord()
                        elseif tanah then
                            if not fallState.tanahSejak then
                                fallState.tanahSejak = now
                            end
                            if now - fallState.tanahSejak >= 0.30 then
                                resetFallRecord()
                            end
                        else
                            fallState.tanahSejak = nil -- udara lagi (pantulan)
                        end
                    end
                end
            end
        end)
    else
        if fallState.conn then
            fallState.conn:Disconnect()
            fallState.conn = nil
        end
        resetFallRecord()
        fallState.pulseSampai = nil -- jangan sisakan jendela pulse
        fallState.hum = nil
    end
    syncNotify("Fall", v, silent, "Fall Resist")
    if refreshFallPreset then refreshFallPreset() end
end

-- ANTI-AFK (port dari A) — toggle via Tab 1, sinkron dengan afkState
Setters.Afk = function(v, silent)
    State.AfkOn = v
    afkState.aktif = v
    if v then afkState.sudahIngatkan = false end
    afkStatusUpdate()
    syncNotify("Afk", v, silent, "Anti-AFK")
end

-- Q — Speed ON/OFF murni
-- Nilai ON (17.25 / 21.25, atau di antaranya) dipilih via stepper di Tab GERAK.
-- Keybind Q langsung panggil setFeature("Speed", ...) dari handler [21].

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
    setFeature("HideAtas", false, true)
    setFeature("Hemat", false, true)
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
    pcall(setFeature, "HideAtas", false, true)
    pcall(setFeature, "Hemat", false, true)
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

-- v1.2.3 WATCHDOG TAKEOVER: instance lama bunuh diri otomatis begitu ada
-- eksekusi BALAP yang lebih baru. Pemicu (cukup salah satu, cek tiap 0.5 dtk):
--   (1) _G.__BALAP_TOKEN__ bukan miliknya      -> executor share _G
--   (2) screenGui sudah dihapus eksekusi baru  -> executor isolasi _G
--       (sweep "BalapMain" di awal eksekusi baru yang menghapusnya)
-- Dulu ini penyebab siluman: Heartbeat Fall Assist instance lama tetap
-- mem-pulse dengan potongan 30%, walau GUI baru sudah diset 0%.
task.spawn(function()
    while not State.Removed do
        if _G.__BALAP_TOKEN__ ~= MY_TOKEN or not screenGui.Parent then
            pcall(function() unloadScript() end)
            break
        end
        task.wait(0.5)
    end
end)

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
-- GUI tampil & hilang INSTAN (tanpa animasi buka/tutup) — lebih ringan.
local function minimizeGui()
    if not root.Visible then return end
    bunyi(CFG.SND_PING, 0.3, 0.75)
    root.Visible = false
    root.Rotation = 0
    panelScale.Scale = 1
    fadeVal.Value = 0
end
local function bukaGui()
    bunyi(CFG.SND_PING, 0.35, 1.15)
    root.Visible = true
    root.Rotation = 0
    panelScale.Scale = 1
    fadeVal.Value = 0
    setFade(0)
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
    elseif input.KeyCode == Enum.KeyCode.F then
        setFeature("Moon", not State.MoonOn)
    elseif input.KeyCode == Enum.KeyCode.B then
        setFeature("Fall", not State.FallOn)
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
-- [22] MULAI ---------------------------------------------------------
afkStatusUpdate()
updateSpeedLabel()
setTab(1)  -- 🏃 GERAK jadi tab pertama
task.delay(0.15, function()
        local okG, errG = pcall(bukaGui)
        if not okG then
                diagSet("GUI gagal terbuka: " .. tostring(errG), Color3.fromRGB(239, 68, 68))
                warn("[BALAP] bukaGui error: " .. tostring(errG))
        end
end)
print("[BALAP v" .. VERSI .. "] SIAP ✔ — G = GUI | K×2 = rejoin")
print("[BALAP] GERAK | VISUAL | SISTEM • Q speed • J jump • C shift • F moon • B fallresist • R hide • T cahaya • X dinding • K×2 rejoin")
diagSet("BALAP v1.0.1 SIAP - GUI akan terbuka sendiri", Color3.fromRGB(16, 185, 129))
task.delay(7, function()
        local function hapusDiag()
                pcall(function()
                        local g = game:GetService("CoreGui"):FindFirstChild("BALAP_DIAG")
                        if g then g:Destroy() end
                end)
                pcall(function()
                        if gethui then
                                local g = gethui():FindFirstChild("BALAP_DIAG")
                                if g then g:Destroy() end
                        end
                end)
        end
        hapusDiag()
end)
end -- akhir initLogic()

-- Eksekusi initLogic() sekarang (UI + helpers sudah siap dari part1-4)
initLogic()
getgenv().BALAP_API = { Setters = Setters, State = State }  -- debug/otomasi + harness uji
end, function(e)
        local teks = tostring(e)
        print("==================================================")
        print("[BALAP v1.0.1] ERROR SAAT LOAD — kirim teks ini ke dev:")
        print(teks)
        pcall(function() print(debug.traceback("", 2)) end)
        print("==================================================")
        pcall(function()
                diagSet("ERROR LOAD: " .. teks:sub(1, 260), Color3.fromRGB(239, 68, 68))
        end)
end)
if not __BALAP_LOAD_OK__ then
        warn("[BALAP v1.0.1] Script GAGAL load — banner MERAH di layar berisi errornya.")
end
