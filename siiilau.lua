--[[=============================================================
    ⛓️Siiilau⚡ - ALL-IN-ONE HUB (MERGED v2.2)
    =============================================================
    MOVEMENT      : Speed & Swim [Q] (17.25, step 0.25)
                    Jump Power (52.25, step 0.25)
                    Scooshlock (Crosshair)
    PLAYER DISPLAY: Info Other Players [C] (maks 100 stud, ringan)
                    Hitbox Players (visual)
    CAMERA        : FREE CAM [CAPS LOCK]
                    WASD = gerak | Q/E = turun/naik
                    Space = cepat | Mouse = arah (saat GUI tertutup)
                    Auto Pagi [T] | Kamera->Karakter [G]
                    TP Karakter->Kamera [C] (toggle dulu)
                    TP Jarak Mundur : BISA DIATUR (+/-)
                    -> 0 = tepat di kamera, makin besar = makin
                       jauh di BELAKANG kamera (karakter tak menutupi view)
    LOKASI        : simpan / TP / hapus (DataStore opsional,
                    butuh server script "FreecamLokasiServer")
    VISUAL        : Hide Other Players [R] | Hide All Effects
                    Low Graphic + No Fog
    ENVIRONMENT   : Jam (Brightness) step 15 menit, ON/OFF snapshot
    HOTKEYS       : F=GUI | CAPSLOCK=Freecam | T=Pagi | G=KeKarakter
                    C=TP Kamera (atau Info Players saat freecam OFF)
                    Q=Speed (saat freecam OFF) | R=Hide Players
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
    JAM_PAGI           = 7,
    INTERVAL_STREAM    = 1,
    DURASI_EFEK_MATI   = 0.6,
    TP_INSTAN          = true,
    JARAK_TP_MIN       = 6,
    TINGGI_TP_MIN      = 8,
    MELUNCUR_KECEPATAN = 600,
    MELUNCUR_MAX       = 0.08,
    JARAK_BELAKANG     = 10,
    TINGGI_KAMERA      = 4,
    SUDUT_TP           = -15,
    MAKS_LOKASI        = 50,

    -- BARU v2.2 : TP karakter ke kamera
    TP_JARAK_MUNDUR    = 3,     -- default jarak di belakang kamera (stud)
    TP_JARAK_STEP      = 0.5,   -- perubahan per klik +/-
    TP_JARAK_MIN       = 0,     -- 0 = tepat di posisi kamera
    TP_JARAK_MAKS      = 100,
}
local NAMA_BIND = "SiiilauFreecamRender"

--═══════════════ LAYANAN & FONT ═══════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local camera            = Workspace.CurrentCamera

local FONT_TITLE = Enum.Font.GothamBold
local FONT_MAIN  = Enum.Font.Gotham
local FONT_BTN   = Enum.Font.GothamBold

--═══════════════ TEMA WARNA ═══════════════
local C = {
    bg      = Color3.fromRGB(16, 8, 30),
    panel   = Color3.fromRGB(31, 15, 54),
    panelD  = Color3.fromRGB(20, 9, 36),
    purple  = Color3.fromRGB(150, 60, 240),
    purpleD = Color3.fromRGB(88, 30, 150),
    white   = Color3.fromRGB(255, 255, 255),
    text    = Color3.fromRGB(235, 228, 255),
    dim     = Color3.fromRGB(155, 135, 200),
    blue    = Color3.fromRGB(0, 145, 255),
    blueBrt = Color3.fromRGB(60, 190, 255),
    green   = Color3.fromRGB(0, 255, 90),
    red     = Color3.fromRGB(255, 70, 70),
    black   = Color3.fromRGB(8, 4, 16),
    offBg   = Color3.fromRGB(42, 24, 68),
}

local function new(class, props, parent)
    local inst = Instance.new(class)
    if props then for k, v in pairs(props) do inst[k] = v end end
    inst.Parent = parent
    return inst
end
local function fmt(v) return string.format("%.2f", v) end
local function fmt2(v)
    if type(v) ~= "number" or v ~= v then return "0,00" end
    return (string.format("%.2f", v):gsub("%.", ","))
end

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

--═══════════════ GUI DASAR ═══════════════
local gui = new("ScreenGui", {Name = "SiiilauHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
pcall(function() gui.Parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local main = new("Frame", {
    Size = UDim2.fromOffset(240, 400),
    Position = UDim2.new(0.5, -120, 0.5, -200),
    BackgroundColor3 = C.bg, BorderSizePixel = 0, Active = true,
}, gui)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, main)
new("UIStroke", {Color = C.purple, Thickness = 1, Transparency = 0.25}, main)

local title = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.purpleD, BorderSizePixel = 0}, main)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, title)
new("Frame", {Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = C.purpleD, BorderSizePixel = 0}, title)
new("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    Text = "⛓️Siiilau⚡", Font = FONT_TITLE, TextSize = 13, TextColor3 = C.white,
}, title)

local scroll = new("ScrollingFrame", {
    Position = UDim2.new(0, 5, 0, 29), Size = UDim2.new(1, -10, 1, -64),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = C.purple,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)

local bottom = new("Frame", {Position = UDim2.new(0, 0, 1, -30), Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.panelD, BorderSizePixel = 0}, main)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, bottom)
local resetBtn = new("TextButton", {
    Size = UDim2.new(0.5, -7, 1, -10), Position = UDim2.new(0, 4, 0, 5),
    BackgroundColor3 = C.blue, BorderSizePixel = 0, Font = FONT_BTN, TextSize = 10,
    Text = "Reset Script", TextColor3 = C.white,
}, bottom)
new("UICorner", {CornerRadius = UDim.new(0, 7)}, resetBtn)
local exitBtn = new("TextButton", {
    Size = UDim2.new(0.5, -7, 1, -10), Position = UDim2.new(0.5, 3, 0, 5),
    BackgroundColor3 = C.black, BorderSizePixel = 0, Font = FONT_BTN, TextSize = 10,
    Text = "Hapus / Keluar", TextColor3 = C.red,
}, bottom)
new("UICorner", {CornerRadius = UDim.new(0, 7)}, exitBtn)
new("UIStroke", {Color = C.red, Thickness = 1, Transparency = 0.6}, exitBtn)

--═══════════════ NOTIFIKASI ═══════════════
local notifHolder = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 45),
    Size = UDim2.fromOffset(260, 320),
    BackgroundTransparency = 1, ZIndex = 60,
}, gui)
new("UIListLayout", {
    Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, notifHolder)

local notifSeq, silent = 0, false
local function notify(msg, state)
    if silent then return end
    notifSeq += 1
    local bgColor = (state == true) and C.blue or (state == false) and C.purpleD or C.purple
    local txt = (state == nil) and msg or (msg .. (state and " : ON" or " : OFF"))
    local n = new("TextLabel", {
        Size = UDim2.fromOffset(180, 24), BackgroundColor3 = bgColor,
        Font = FONT_BTN, TextSize = 11, TextColor3 = C.white,
        Text = txt, LayoutOrder = notifSeq, ZIndex = 60,
    }, notifHolder)
    new("UICorner", {CornerRadius = UDim.new(0, 8)}, n)
    new("UIStroke", {Color = C.purple, Thickness = 1, Transparency = 0.4}, n)
    task.spawn(function()
        n.BackgroundTransparency, n.TextTransparency = 1, 1
        TweenService:Create(n, TweenInfo.new(0.18), {BackgroundTransparency = 0.1, TextTransparency = 0}):Play()
        task.wait(1.3)
        TweenService:Create(n, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
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
    new("Frame", {BackgroundColor3 = C.green, BorderSizePixel = 0, ZIndex = 50,
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
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1,
        Text = "• " .. text, Font = FONT_TITLE, TextSize = 11,
        TextColor3 = C.purple, TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order,
    }, scroll)
end
local function addHint(text)
    order += 1
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1,
        Text = text, Font = FONT_MAIN, TextSize = 8, TextColor3 = C.dim,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = order,
    }, scroll)
end

local function addRow(labelText, opts)
    opts = opts or {}
    order += 1
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = C.panel,
        BorderSizePixel = 0, LayoutOrder = order,
    }, scroll)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, row)

    local ref = {row = row}
    local vshift = opts.toggle and 0 or 44
    local lw = -46
    if opts.value then lw = opts.toggle and -150 or -106 end
    ref.label = new("TextLabel", {
        Size = UDim2.new(1, lw, 1, 0), Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1, Text = labelText,
        Font = FONT_MAIN, TextSize = 9, TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    if opts.value then
        ref.minus = new("TextButton", {
            Size = UDim2.new(0, 14, 1, -8), Position = UDim2.new(1, -142 + vshift, 0, 4),
            BackgroundColor3 = C.purpleD, BorderSizePixel = 0,
            Text = "-", Font = FONT_BTN, TextSize = 11, TextColor3 = C.white,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 5)}, ref.minus)
        ref.val = new("TextLabel", {
            Size = UDim2.new(0, 40, 1, -8), Position = UDim2.new(1, -126 + vshift, 0, 4),
            BackgroundColor3 = C.black, BorderSizePixel = 0,
            Text = "--", Font = FONT_MAIN, TextSize = 9, TextColor3 = C.white,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 5)}, ref.val)
        ref.plus = new("TextButton", {
            Size = UDim2.new(0, 14, 1, -8), Position = UDim2.new(1, -84 + vshift, 0, 4),
            BackgroundColor3 = C.purpleD, BorderSizePixel = 0,
            Text = "+", Font = FONT_BTN, TextSize = 11, TextColor3 = C.white,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 5)}, ref.plus)
    end

    if opts.action then
        ref.action = new("TextButton", {
            Size = UDim2.new(0, 34, 1, -8), Position = UDim2.new(1, -38, 0, 4),
            BackgroundColor3 = C.blue, BorderSizePixel = 0,
            Text = opts.action, Font = FONT_BTN, TextSize = 9, TextColor3 = C.white,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 5)}, ref.action)
    end

    if opts.toggle then
        ref.toggle = new("TextButton", {
            Size = UDim2.new(0, 34, 1, -8), Position = UDim2.new(1, -38, 0, 4),
            BackgroundColor3 = C.offBg, BorderSizePixel = 0,
            Text = "OFF", Font = FONT_BTN, TextSize = 9, TextColor3 = C.dim,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 5)}, ref.toggle)
    end
    return ref
end

local function styleToggle(btn, on)
    btn.Text = on and "ON" or "OFF"
    btn.BackgroundColor3 = on and C.blue or C.offBg
    btn.TextColor3 = on and C.white or C.dim
end

--═══════════════ ISI PANEL ═══════════════
addSection("Movement")
local rSpeed = addRow("Speed & Swim [Q]", {value = true, toggle = true})
local rJump  = addRow("Jump Power",       {value = true, toggle = true})
local rCross = addRow("Scooshlock (Crosshair)", {toggle = true})

addSection("Player Display")
local rInfo = addRow("Info Other Players [C]", {toggle = true})
local rHit  = addRow("Hitbox Players",          {toggle = true})

addSection("Camera / Freecam")
local rFree    = addRow("Free Cam [CAPS LOCK]",    {toggle = true})
local rPagi    = addRow("Auto Pagi [T]",           {toggle = true})
local rTpKam   = addRow("TP Karakter->Kamera [C]", {toggle = true})
local rTpJarak = addRow("TP Jarak Mundur",         {value = true})   -- BARU v2.2
local rKeKar   = addRow("Kamera -> Karakter [G]",  {action = "GO"})
local rKeKam   = addRow("Karakter -> Kamera",      {action = "TP"})
addHint("WASD gerak • QE turun/naik • Space cepat")
addHint("Jarak mundur: 0 = tepat di kamera")

addSection("Lokasi (Freecam)")
order += 1
local rowLok = new("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = C.panel, BorderSizePixel = 0, LayoutOrder = order}, scroll)
new("UICorner", {CornerRadius = UDim.new(0, 6)}, rowLok)
local kotakNama = new("TextBox", {
    Size = UDim2.new(1, -58, 1, -8), Position = UDim2.new(0, 6, 0, 4),
    BackgroundColor3 = C.black, BorderSizePixel = 0, Text = "",
    PlaceholderText = "Nama lokasi...", PlaceholderColor3 = C.dim,
    TextColor3 = C.white, Font = FONT_MAIN, TextSize = 9,
    ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
}, rowLok)
new("UICorner", {CornerRadius = UDim.new(0, 5)}, kotakNama)
local btnSimpanLok = new("TextButton", {
    Size = UDim2.new(0, 48, 1, -8), Position = UDim2.new(1, -52, 0, 4),
    BackgroundColor3 = C.green, BorderSizePixel = 0,
    Font = FONT_BTN, TextSize = 9, TextColor3 = C.black, Text = "SIMPAN",
}, rowLok)
new("UICorner", {CornerRadius = UDim.new(0, 5)}, btnSimpanLok)

order += 1
local statusLok = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1,
    Font = FONT_MAIN, TextSize = 8, TextColor3 = C.dim,
    Text = "Memeriksa penyimpanan...", TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = order,
}, scroll)

addSection("Visual")
local rHideP = addRow("Hide Other Players [R]", {toggle = true})
local rHideF = addRow("Hide All Effects",       {toggle = true})
local rLowG  = addRow("Low Graphic + No Fog",   {toggle = true})

addSection("Environment")
local rClock = addRow("Jam (Brightness)", {value = true, toggle = true})

--═══════════════ STATE ═══════════════
local S = {
    speedOn = false, speedValue = DEFAULT_SPEED,
    jumpOn = false,  jumpValue = DEFAULT_JUMP,
    crosshairOn = false, infoOn = false, hitboxOn = false,
    hidePlayersOn = false, hideFxOn = false, lowGfxOn = false,
    clockOn = false, clockTouched = false,
    clockValue = Lighting.ClockTime,
    tpJarakMundur = CONFIG.TP_JARAK_MUNDUR,   -- BARU v2.2
}
local orig = {brightness = Lighting.Brightness, clockTime = Lighting.ClockTime}

local conns = {}
local function addConn(c) table.insert(conns, c) return c end
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- freecam state
local freecamAktif, autoPagiAktif, tpKameraAktif = false, false, false
local adaPosisiTersimpan = false
local fcTarget = Vector3.zero
local yaw, pitch = 0, 0
local posNow = Vector3.zero
local yawNow, pitchNow = 0, 0
local tombolTekan = {}
local threadStream = nil

local koneksiJalanDiTempat = nil
local posisiKunci, rotasiKunci = nil, nil
local kunciY = false
local cfVisual = nil
local meluncur = false
local cfAsal, cfTujuan = nil, nil
local waktuMulai, durasiMeluncur = 0, 0

local efekKoreksi, tweenEfek = nil, nil
local hitamPutihAktif = false

local daftarLokasi = {}
local remoteLokasi = nil

--═══════════════ MOVEMENT ═══════════════
local savedHum = {}

local function captureHum(h)
    if savedHum[h] then return end
    local rec = {ws = h.WalkSpeed, ujp = h.UseJumpPower, jp = h.JumpPower, ss = nil, jh = nil}
    pcall(function() rec.ss = h.SwimSpeed end)
    pcall(function() rec.jh = h.JumpHeight end)
    savedHum[h] = rec
end

local function restoreHum(h)
    local rec = savedHum[h]
    if not rec then return end
    pcall(function()
        h.WalkSpeed    = rec.ws
        h.UseJumpPower = rec.ujp
        h.JumpPower    = rec.jp
        if rec.jh then h.JumpHeight = rec.jh end
        if rec.ss then h.SwimSpeed  = rec.ss end
    end)
    savedHum[h] = nil
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
        TextColor3 = C.white, TextStrokeTransparency = 0.25,
        Text = plr.DisplayName .. " (@" .. plr.Name .. ")",
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, bb)
    local stat = new("TextLabel", {
        Position = UDim2.new(0, 0, 0, 23), Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = C.blueBrt, TextStrokeTransparency = 0.3,
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
                Size = part.Size, Color3 = C.green, Transparency = 0.6,
                AlwaysOnTop = true, ZIndex = 2,
            }, part)
        end
    end
    pcall(function()
        new("Highlight", {
            Name = "PH_Glow", Parent = char, FillTransparency = 1,
            OutlineColor = C.green, OutlineTransparency = 0.35,
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

--═══════════════ JAM TERKUNCI [ON/OFF] ═══════════════
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
    notify("Jam / Brightness", S.clockOn)
end

local function bumpClock(d)
    S.clockValue = (S.clockValue + d) % 24
    if S.clockValue < 0 then S.clockValue += 24 end
    rClock.val.Text = formatClock(S.clockValue)
    if autoPagiAktif then
        autoPagiAktif = false
        styleToggle(rPagi.toggle, false)
    end
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

local function netralkanFisika(root, humanoid)
    if not root then return end
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if humanoid then
        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
            if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)
    end
end

local function requestStream(pos)
    if Workspace.StreamingEnabled then
        task.spawn(function()
            pcall(function() LocalPlayer:RequestStreamAroundAsync(pos) end)
        end)
    end
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
    return true
end

--═══════════════ JALAN DI TEMPAT ═══════════════
local function mulaiJalanDiTempat()
    if koneksiJalanDiTempat then return end

    local root = dapatkanRoot()
    if root then
        posisiKunci = root.Position
        rotasiKunci = root.CFrame - root.CFrame.Position
        cfVisual    = root.CFrame
    end
    kunciY   = false
    meluncur = false

    local humanoid = getHum()
    if humanoid then
        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            humanoid.Jump = false
        end)
    end

    koneksiJalanDiTempat = RunService.Stepped:Connect(function()
        local r = dapatkanRoot()
        if not r then return end
        local hum = getHum()

        if hum and hum.SeatPart then
            posisiKunci = r.Position
            rotasiKunci = r.CFrame - r.CFrame.Position
            cfVisual    = r.CFrame
            return
        end

        if meluncur then
            local t  = math.clamp((os.clock() - waktuMulai) / durasiMeluncur, 0, 1)
            local e  = t * t * (3 - 2 * t)
            local cf = cfAsal:Lerp(cfTujuan, e)
            r.CFrame = cf
            netralkanFisika(r, hum)
            cfVisual = cf
            if t >= 1 then
                meluncur    = false
                kunciY      = true
                posisiKunci = cfTujuan.Position
                rotasiKunci = cfTujuan - cfTujuan.Position
            end
            return
        end

        if not posisiKunci then
            posisiKunci = r.Position
            rotasiKunci = r.CFrame - r.CFrame.Position
            cfVisual    = r.CFrame
            kunciY      = false
        end

        local dx = r.Position.X - posisiKunci.X
        local dz = r.Position.Z - posisiKunci.Z
        local teleport =
            (dx * dx + dz * dz) >= (CONFIG.JARAK_TP_MIN * CONFIG.JARAK_TP_MIN)
            or math.abs(r.Position.Y - posisiKunci.Y) >= CONFIG.TINGGI_TP_MIN

        if teleport then
            local tujuan = cfTegak(r.CFrame)
            if CONFIG.TP_INSTAN then
                r.CFrame = tujuan
                netralkanFisika(r, hum)
                kunciY      = true
                posisiKunci = tujuan.Position
                rotasiKunci = tujuan - tujuan.Position
                cfVisual    = tujuan
            else
                cfAsal   = cfVisual or cfTegak(r.CFrame)
                cfTujuan = tujuan
                local jarak = (cfTujuan.Position - cfAsal.Position).Magnitude
                durasiMeluncur = math.min(jarak / CONFIG.MELUNCUR_KECEPATAN, CONFIG.MELUNCUR_MAX)
                waktuMulai = os.clock()
                meluncur   = true
                r.CFrame = cfAsal
                netralkanFisika(r, hum)
            end
            return
        end

        local cfBaru
        if kunciY then
            cfBaru = CFrame.new(posisiKunci) * rotasiKunci
            netralkanFisika(r, hum)
        else
            cfBaru = CFrame.new(posisiKunci.X, r.Position.Y, posisiKunci.Z) * rotasiKunci
            posisiKunci = Vector3.new(posisiKunci.X, r.Position.Y, posisiKunci.Z)
        end
        r.CFrame = cfBaru
        cfVisual = cfBaru
    end)
end

local function hentikanJalanDiTempat()
    if koneksiJalanDiTempat then
        koneksiJalanDiTempat:Disconnect()
        koneksiJalanDiTempat = nil
    end
    posisiKunci = nil
    rotasiKunci = nil
    cfVisual    = nil
    kunciY      = false
    meluncur    = false
    cfAsal      = nil
    cfTujuan    = nil

    local humanoid = getHum()
    if humanoid then
        pcall(function()
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        end)
    end
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
    netralkanFisika(root, humanoid)

    if freecamAktif then
        kunciY      = true
        posisiKunci = cf.Position
        rotasiKunci = cf - cf.Position
        cfVisual    = cf
        meluncur    = false
    end

    requestStream(cf.Position)
    return true
end

-- [C] TP ke kamera + JARAK MUNDUR BISA DIATUR
-- Karakter diletakkan di belakang kamera sejauh S.tpJarakMundur stud,
-- menghadap ke arah yang sama dengan kamera.
local function teleportKeKamera(manual)
    if not freecamAktif then return false end
    if not manual and not tpKameraAktif then return false end

    local cfKamera = camera.CFrame
    local look     = cfKamera.LookVector

    -- hitung posisi MUNDUR dari kamera (berlawanan arah pandang)
    local posisi = cfKamera.Position - look * S.tpJarakMundur

    -- karakter tegak, menghadap arah pandang kamera (didatar)
    local tujuan = cfTegak(CFrame.lookAt(posisi, posisi + look))

    return teleportKarakter(tujuan)
end

local function teleportKeLokasi(index)
    local data = daftarLokasi[index]
    if not data then return false end

    local rotasi
    local root = dapatkanRoot()
    if root then
        local tegak = cfTegak(root.CFrame)
        rotasi = tegak - tegak.Position
    else
        rotasi = CFrame.new()
    end

    return teleportKarakter(CFrame.new(Vector3.new(data.x, data.y, data.z)) * rotasi)
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

--═══════════════ UPDATE KAMERA (TIAP FRAME) ═══════════════
local function updateFreecam(dt)
    camera.CameraType = Enum.CameraType.Scriptable
    if main.Visible then
        UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseBehavior    = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
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

    mulaiJalanDiTempat()

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

    hentikanJalanDiTempat()

    camera.CameraType = Enum.CameraType.Custom
    local humanoid = getHum()
    if humanoid then
        pcall(function() camera.CameraSubject = humanoid end)
    end

    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end

local function perbaruiTombol()
    styleToggle(rFree.toggle,  freecamAktif)
    styleToggle(rPagi.toggle,  autoPagiAktif)
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

local function setAutoPagi(aktif)
    autoPagiAktif = aktif
    local wasSilent = silent
    silent = true
    if aktif then
        S.clockValue = CONFIG.JAM_PAGI
        rClock.val.Text = formatClock(S.clockValue)
        setClock(true)
    else
        setClock(false)
    end
    silent = wasSilent
    styleToggle(rPagi.toggle, aktif)
    notify("Auto Pagi", aktif)
end

--═══════════════ LOKASI TERSIMPAN ═══════════════
local perbaruiDaftar
local simpanKeServer

local function setStatusLok(t)
    statusLok.Text = t
end

local function buatBarisLokasi(i, data)
    order += 1
    local baris = new("Frame", {
        Name = "LokRow", Size = UDim2.new(1, 0, 0, 20),
        BackgroundColor3 = C.panelD, BorderSizePixel = 0, LayoutOrder = order,
    }, scroll)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, baris)

    new("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1, Font = FONT_MAIN, TextSize = 9,
        TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Text = data.n,
    }, baris)

    local bTp = new("TextButton", {
        Size = UDim2.new(0, 30, 1, -6), Position = UDim2.new(1, -40, 0, 3),
        BackgroundColor3 = C.blue, BorderSizePixel = 0,
        Font = FONT_BTN, TextSize = 9, TextColor3 = C.white, Text = "TP",
    }, baris)
    new("UICorner", {CornerRadius = UDim.new(0, 5)}, bTp)

    local bHapus = new("TextButton", {
        Size = UDim2.new(0, 18, 1, -6), Position = UDim2.new(1, -19, 0, 3),
        BackgroundColor3 = C.red, BorderSizePixel = 0,
        Font = FONT_BTN, TextSize = 9, TextColor3 = C.white, Text = "✕",
    }, baris)
    new("UICorner", {CornerRadius = UDim.new(0, 5)}, bHapus)

    bTp.MouseButton1Click:Connect(function()
        if teleportKeLokasi(i) then
            notify("TP: " .. data.n)
        else
            notify("Karakter tidak ada", false)
        end
    end)

    bHapus.MouseButton1Click:Connect(function()
        table.remove(daftarLokasi, i)
        perbaruiDaftar()
        simpanKeServer()
    end)
end

perbaruiDaftar = function()
    for _, anak in ipairs(scroll:GetChildren()) do
        if anak:IsA("Frame") and anak.Name == "LokRow" then
            anak:Destroy()
        end
    end
    for i, data in ipairs(daftarLokasi) do
        buatBarisLokasi(i, data)
    end
end

simpanKeServer = function()
    if not remoteLokasi then
        setStatusLok("⚠ Tanpa server script — hanya sesi ini")
        return
    end
    setStatusLok("Menyimpan...")
    local salinan = {}
    for i, v in ipairs(daftarLokasi) do
        salinan[i] = { n = v.n, x = v.x, y = v.y, z = v.z }
    end
    task.spawn(function()
        local ok, hasil = pcall(function()
            return remoteLokasi:InvokeServer("simpan", salinan)
        end)
        if ok and hasil == true then
            setStatusLok("✓ Tersimpan permanen")
        else
            setStatusLok("✗ Gagal menyimpan ke server")
        end
    end)
end

btnSimpanLok.MouseButton1Click:Connect(function()
    local pos
    if freecamAktif then
        pos = posNow
    else
        local root = dapatkanRoot()
        if not root then
            notify("Karakter tidak ditemukan", false)
            return
        end
        pos = root.Position
    end

    if #daftarLokasi >= CONFIG.MAKS_LOKASI then
        setStatusLok("✗ Maksimal " .. CONFIG.MAKS_LOKASI .. " lokasi")
        return
    end

    local nama = kotakNama.Text
    if nama == "" then
        nama = "Lokasi " .. tostring(#daftarLokasi + 1)
    end

    table.insert(daftarLokasi, { n = nama, x = pos.X, y = pos.Y, z = pos.Z })
    kotakNama.Text = ""
    perbaruiDaftar()
    simpanKeServer()
end)

--═══════════════ RESET SCRIPT ═══════════════
local function resetScript()
    silent = true
    setSpeed(false); setJump(false); setCrosshair(false)
    setFreecam(false)
    setTpKamera(false)
    setAutoPagi(false)
    S.infoOn, S.hitboxOn = false, false
    syncDisplays()
    styleToggle(rInfo.toggle, false); styleToggle(rHit.toggle, false)
    setHidePlayers(false); setHideFx(false); setLowGfx(false)
    S.speedValue, S.jumpValue = DEFAULT_SPEED, DEFAULT_JUMP
    S.tpJarakMundur = CONFIG.TP_JARAK_MUNDUR
    rTpJarak.val.Text = fmt(S.tpJarakMundur)
    S.clockValue = orig.clockTime
    if S.clockTouched then
        pcall(function() Lighting.ClockTime = orig.clockTime end)
        pcall(function() Lighting.Brightness = orig.brightness end)
        S.clockTouched = false
    end
    rClock.val.Text = formatClock(S.clockValue)
    rSpeed.val.Text, rJump.val.Text = fmt(S.speedValue), fmt(S.jumpValue)
    main.Position = UDim2.new(0.5, -120, 0.5, -200)
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
    autoPagiAktif = false
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
local dragging, dragStart, startPos = false, nil, nil

--═══════════════ WIRING TOMBOL ═══════════════
rSpeed.toggle.MouseButton1Click:Connect(function() setSpeed(not S.speedOn) end)
rJump.toggle.MouseButton1Click:Connect(function() setJump(not S.jumpOn) end)
rCross.toggle.MouseButton1Click:Connect(function() setCrosshair(not S.crosshairOn) end)
rInfo.toggle.MouseButton1Click:Connect(toggleInfoPlayers)
rHit.toggle.MouseButton1Click:Connect(function()
    S.hitboxOn = not S.hitboxOn
    syncDisplays()
    styleToggle(rHit.toggle, S.hitboxOn)
    notify("Hitbox Players", S.hitboxOn)
end)
rFree.toggle.MouseButton1Click:Connect(function() setFreecam(not freecamAktif) end)
rPagi.toggle.MouseButton1Click:Connect(function() setAutoPagi(not autoPagiAktif) end)
rTpKam.toggle.MouseButton1Click:Connect(function() setTpKamera(not tpKameraAktif) end)
rHideP.toggle.MouseButton1Click:Connect(function() setHidePlayers(not S.hidePlayersOn) end)
rHideF.toggle.MouseButton1Click:Connect(function() setHideFx(not S.hideFxOn) end)
rLowG.toggle.MouseButton1Click:Connect(function() setLowGfx(not S.lowGfxOn) end)
rClock.toggle.MouseButton1Click:Connect(function() setClock(not S.clockOn) end)

rKeKar.action.MouseButton1Click:Connect(function()
    if kameraKeKarakter() then
        notify("Kamera -> Karakter")
    else
        notify("Nyalakan Free Cam dulu", false)
    end
end)
rKeKam.action.MouseButton1Click:Connect(function()
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
-- BARU v2.2 : atur jarak mundur TP ke kamera
local function bumpTpJarak(d)
    S.tpJarakMundur = math.clamp(S.tpJarakMundur + d, CONFIG.TP_JARAK_MIN, CONFIG.TP_JARAK_MAKS)
    rTpJarak.val.Text = fmt(S.tpJarakMundur)
end

rSpeed.minus.MouseButton1Click:Connect(function() bumpSpeed(-STEP) end)
rSpeed.plus.MouseButton1Click:Connect(function() bumpSpeed(STEP) end)
rJump.minus.MouseButton1Click:Connect(function() bumpJump(-STEP) end)
rJump.plus.MouseButton1Click:Connect(function() bumpJump(STEP) end)
rTpJarak.minus.MouseButton1Click:Connect(function() bumpTpJarak(-CONFIG.TP_JARAK_STEP) end)
rTpJarak.plus.MouseButton1Click:Connect(function() bumpTpJarak(CONFIG.TP_JARAK_STEP) end)
rClock.minus.MouseButton1Click:Connect(function() bumpClock(-STEP) end)
rClock.plus.MouseButton1Click:Connect(function() bumpClock(STEP) end)

resetBtn.MouseButton1Click:Connect(resetScript)
exitBtn.MouseButton1Click:Connect(unloadScript)

--═══════════════ HOTKEY ═══════════════
addConn(UserInputService.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.Keyboard and not gp then
        tombolTekan[input.KeyCode] = true
    end
    if gp then return end

    local k = input.KeyCode
    if k == Enum.KeyCode.F then
        main.Visible = not main.Visible
    elseif k == Enum.KeyCode.CapsLock then
        setFreecam(not freecamAktif)
    elseif k == Enum.KeyCode.T then
        setAutoPagi(not autoPagiAktif)
    elseif k == Enum.KeyCode.G then
        if not kameraKeKarakter() then
            notify("Nyalakan Free Cam dulu", false)
        end
    elseif k == Enum.KeyCode.C then
        if freecamAktif then
            if tpKameraAktif then
                teleportKeKamera()
            else
                notify("TP ke Kamera OFF (aktifkan dulu)", false)
            end
        else
            toggleInfoPlayers()
        end
    elseif k == Enum.KeyCode.Q and not freecamAktif then
        setSpeed(not S.speedOn)
    elseif k == Enum.KeyCode.R then
        setHidePlayers(not S.hidePlayersOn)
    end
end))

addConn(UserInputService.InputEnded:Connect(function(input)
    tombolTekan[input.KeyCode] = nil
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

addConn(UserInputService.WindowFocusReleased:Connect(function()
    table.clear(tombolTekan)
end))

--═══════════════ DRAG GUI + MOUSE LOOK ═══════════════
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, main.Position
    end
end)
addConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    and freecamAktif and not main.Visible then
        local delta = input.Delta
        yaw   = yaw   - delta.X * CONFIG.SENSITIVITAS_MOUSE
        pitch = math.clamp(pitch - delta.Y * CONFIG.SENSITIVITAS_MOUSE, -CONFIG.BATAS_PITCH, CONFIG.BATAS_PITCH)
    end
end))

--═══════════════ LOOP UTAMA ═══════════════
local accDisp, accClock = 0, 0
addConn(RunService.Heartbeat:Connect(function(dt)
    if S.speedOn or S.jumpOn then
        local h = getHum()
        if h then
            if S.speedOn then
                if h.WalkSpeed ~= S.speedValue then h.WalkSpeed = S.speedValue end
                pcall(function()
                    if h.SwimSpeed ~= S.speedValue then h.SwimSpeed = S.speedValue end
                end)
            end
            if S.jumpOn then
                pcall(function()
                    if not h.UseJumpPower then h.UseJumpPower = true end
                    if h.JumpPower ~= S.jumpValue then h.JumpPower = S.jumpValue end
                end)
            end
        end
    end
    accDisp += dt
    if accDisp >= INFO_INTERVAL then
        accDisp = 0
        syncDisplays()
    end
    accClock += dt
    if accClock >= 0.25 then
        accClock = 0
        if S.clockOn then
            applyLockedClock()
        end
    end
end))

--═══════════════ MATI / RESPAWN ═══════════════
local function pantauKarakter(karakter)
    task.spawn(function()
        local humanoid = karakter:WaitForChild("Humanoid", 10)
        if humanoid then
            humanoid.Died:Connect(function()
                setFreecam(false)
                setHitamPutih(true)
            end)
        end
    end)
end

addConn(LocalPlayer.CharacterAdded:Connect(function(char)
    setFreecam(false)
    setHitamPutih(false)
    for h in pairs(savedHum) do
        if h.Parent ~= char then restoreHum(h) end
    end
    pantauKarakter(char)
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 10)
        if hum and not freecamAktif then
            pcall(function() camera.CameraSubject = hum end)
        end
        task.wait(0.15)
        if S.speedOn or S.jumpOn then applyMovement() end
    end)
end))

if LocalPlayer.Character then
    pantauKarakter(LocalPlayer.Character)
end

addConn(Players.PlayerRemoving:Connect(function(plr)
    infoRefs[plr] = nil
end))

--═══════════════ JAGA REFERENSI KAMERA ═══════════════
addConn(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Workspace.CurrentCamera then
        camera = Workspace.CurrentCamera
        if freecamAktif then
            pcall(function() camera.CameraType = Enum.CameraType.Scriptable end)
        end
    end
end))

--═══════════════ INISIALISASI ═══════════════
rSpeed.val.Text    = fmt(S.speedValue)
rJump.val.Text     = fmt(S.jumpValue)
rTpJarak.val.Text  = fmt(S.tpJarakMundur)
rClock.val.Text    = formatClock(S.clockValue)
perbaruiTombol()
main.Visible = true

-- muat lokasi tersimpan dari server (DataStore, opsional)
task.spawn(function()
    remoteLokasi = ReplicatedStorage:WaitForChild("FreecamLokasiRemote", 10)
    if remoteLokasi then
        local ok, data = pcall(function()
            return remoteLokasi:InvokeServer("muat")
        end)
        if ok and type(data) == "table" then
            daftarLokasi = data
            setStatusLok("✓ " .. #daftarLokasi .. " lokasi dimuat")
        else
            setStatusLok("✗ Gagal memuat lokasi")
        end
    else
        setStatusLok("⚠ Tanpa server script — simpan hanya sesi ini")
    end
    perbaruiDaftar()
end)
