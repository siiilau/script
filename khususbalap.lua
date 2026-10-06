--[[=============================================================
    ⛓️Siiilau⚡ - ALL-IN-ONE HUB (v2.0 — 🏁 RACE EDITION LITE)
    =============================================================
    PERUBAHAN v2.0:
      - HAPUS TOTAL: Free Cam, TP Karakter→Kamera, TP Jarak Mundur,
        Kamera→Karakter, semua kode freecam (render/bind/mouse lock)
      - HAPUS TOTAL: TweenService, suara, ledSweep, efek kosmetik
        → 0 tween, 0 suara, 0 loop kosmetik seumur hidup script
      - UTUH: Speed&Swim[Q] | Jump Power | Hide Pemain+Kendaraan[R] |
        Hide All Effects | Low Graphic+No Fog | Auto Brightness[T] |
        Reset | Exit | Minimize | Drag
    HOTKEYS: F = GUI | Q = Speed | R = Hide Pemain+Kendaraan
             T = Auto Brightness
    ===============================================================]]

--═══════════════ KONFIG ═══════════════
local DEFAULT_SPEED = 17.25
local DEFAULT_JUMP  = 52.25
local STEP          = 0.25
local CLOCK_STEP    = 0.5
local LOCK_TIME     = true

-- 🏁 HIDE KENDARAAN SENTUH
local RADIUS_SENTUH = 20   -- jarak antar mobil dianggap "menyentuh" (studs)
local CEK_INTERVAL  = 0.4  -- jeda cek (detik)

local UKURAN_GUI = 0.8

--═══════════════ LAYANAN ═══════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[SiiilauHub] GAGAL: LocalPlayer belum ada. Masuk game dulu, lalu execute ulang.")
    return
end

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

--═══════════════ TEMA WARNA ═══════════════
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
    Putih     = Color3.fromRGB(255, 255, 255),
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

--═══════════════ GUI UTAMA (STATIS) ═══════════════
local main = new("Frame", {
    Size = UDim2.fromOffset(480, 620),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, BorderSizePixel = 0, Active = true,
    Visible = false,
}, gui)
local panelScale = new("UIScale", {Scale = UKURAN_GUI}, main)

local outer = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
    ClipsDescendants = true,
}, main)
new("UICorner", {CornerRadius = UDim.new(0, 18)}, outer)
new("UIStroke", {Color = C.Ungu, Thickness = 3}, outer)

local panel = new("Frame", {
    Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5),
    BackgroundColor3 = C.Hitam2, BorderSizePixel = 0,
    ClipsDescendants = true,
}, outer)
new("UICorner", {CornerRadius = UDim.new(0, 13)}, panel)
new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.55}, panel)

-- HEADER
local title = new("Frame", {
    Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.Hitam,
    BorderSizePixel = 0, Active = true, ClipsDescendants = true,
}, panel)
new("UICorner", {CornerRadius = UDim.new(0, 13)}, title)
new("Frame", {
    Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 36),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
}, panel)

new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -70, 1, 0), FontFace = fnt("judul"),
    Text = "⛓️ S I I L A U ⚡ 🏁", TextColor3 = C.Putih, TextSize = 24,
    TextXAlignment = Enum.TextXAlignment.Left,
}, title)

local minBtn = new("TextButton", {
    Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -40, 0.5, -14),
    BackgroundColor3 = C.Hitam2, BorderSizePixel = 0, AutoButtonColor = false,
    FontFace = fnt("bold"), Text = "–", TextColor3 = C.Putih, TextSize = 18,
}, title)
new("UICorner", {CornerRadius = UDim.new(0, 9)}, minBtn)
new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.3}, minBtn)

-- AREA SCROLL
local scroll = new("ScrollingFrame", {
    Position = UDim2.new(0, 10, 0, 56), Size = UDim2.new(1, -20, 1, -118),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 5, ScrollBarImageColor3 = C.Ungu2,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
new("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)

-- BAR BAWAH
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

local exitBtn = new("TextButton", {
    Size = UDim2.new(0.5, -12, 1, -16), Position = UDim2.new(0.5, 4, 0, 8),
    BackgroundColor3 = C.Hitam2, BorderSizePixel = 0, AutoButtonColor = false,
    FontFace = fnt("bold"), TextSize = 18, Text = "🗑️ Hapus / Keluar", TextColor3 = C.Merah,
}, bottom)
new("UICorner", {CornerRadius = UDim.new(0, 12)}, exitBtn)
new("UIStroke", {Color = C.Merah, Thickness = 2, Transparency = 0.6}, exitBtn)

--═══════════════ NOTIFIKASI (INSTAN) ═══════════════
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
    local teks  = (state == nil) and msg or (msg .. " " .. (state and "ON" or "OFF"))
    local n = new("TextLabel", {
        Size = UDim2.fromOffset(190, 24), BackgroundColor3 = C.Hitam2,
        BackgroundTransparency = 0.25, BorderSizePixel = 0,
        Text = " " .. teks, TextColor3 = C.UnguMuda, TextSize = 11,
        FontFace = fnt("semi"), TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = notifSeq, ZIndex = 60,
    }, notifHolder)
    new("UICorner", {CornerRadius = UDim.new(0, 7)}, n)
    new("UIStroke", {Color = aksen, Thickness = 1, Transparency = 0.55}, n)
    task.delay(1.5, function() n:Destroy() end)
end

--═══════════════ PEMBANGUN UI ═══════════════
local order = 0
local function addSection(text)
    order += 1
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
        LayoutOrder = order,
    }, scroll)
    new("TextLabel", {
        Size = UDim2.new(1, -10, 0, 26), Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1, Text = "▎ " .. text,
        FontFace = fnt("judul"), TextSize = 21, TextColor3 = C.Ungu2,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 4, 1, -4),
        BackgroundColor3 = C.Ungu, BorderSizePixel = 0,
    }, holder)
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

    new("Frame", {
        Size = UDim2.new(0, 3, 1, -18), Position = UDim2.new(0, 6, 0, 9),
        BackgroundColor3 = C.Ungu2, BorderSizePixel = 0,
    }, row)

    row.MouseEnter:Connect(function()
        row.BackgroundColor3 = C.BarisHov
        rowStroke.Transparency = 0.45
    end)
    row.MouseLeave:Connect(function()
        row.BackgroundColor3 = C.Baris
        rowStroke.Transparency = 0.78
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
    end

    if opts.toggle then
        ref.toggle = new("TextButton", {
            Size = UDim2.new(0, 68, 1, -16), Position = UDim2.new(1, -76, 0, 8),
            BackgroundColor3 = C.offBg, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "OFF", FontFace = fnt("bold"), TextSize = 17, TextColor3 = C.Abuk,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 10)}, ref.toggle)
        new("UIStroke", {Color = C.Ungu, Thickness = 1.5, Transparency = 0.6}, ref.toggle)
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
end

--═══════════════ ISI PANEL ═══════════════
addSection("MOVEMENT")
local rSpeed = addRow("🏃 Speed & Swim [Q]", {value = true, toggle = true})
local rJump  = addRow("🦘 Jump Power",       {value = true, toggle = true})

addSection("VISUAL")
local rHideP = addRow("🙈 Hide Pemain + Kendaraan [R]", {toggle = true})
local rHideF = addRow("✨ Hide All Effects",             {toggle = true})
local rLowG  = addRow("🌫️ Low Graphic + No Fog",        {toggle = true})
addHint("Mobil lawan menempel ≤ " .. RADIUS_SENTUH .. "m → hilang, menjauh → muncul")

addSection("ENVIRONMENT")
local rClock = addRow("🕒 Auto Brightness [T]", {value = true, toggle = true})

--═══════════════ STATE ═══════════════
local S = {
    speedOn = false, speedValue = DEFAULT_SPEED,
    jumpOn = false,  jumpValue = DEFAULT_JUMP,
    hidePlayersOn = false, hideFxOn = false, lowGfxOn = false,
    clockOn = false,
    clockValue = Lighting.ClockTime,
}

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

rSpeed.val.Text = fmt(S.speedValue)
rJump.val.Text  = fmt(S.jumpValue)
rClock.val.Text = formatClock(S.clockValue)

local function segarkanToggle()
    styleToggle(rSpeed.toggle, S.speedOn)
    styleToggle(rJump.toggle, S.jumpOn)
    styleToggle(rHideP.toggle, S.hidePlayersOn)
    styleToggle(rHideF.toggle, S.hideFxOn)
    styleToggle(rLowG.toggle, S.lowGfxOn)
    styleToggle(rClock.toggle, S.clockOn)
end

--═══════════════ MOVEMENT ═══════════════
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

--═══════════════ HIDE PEMAIN + KENDARAAN SENTUH (v4) ═══════════════
local hideLoopId = 0
local vehHidden  = {}   -- [Player] = kendaraan yang sedang disembunyikan
local savedDecal = {}   -- [Decal] = transparency asli
local R2 = RADIUS_SENTUH * RADIUS_SENTUH

local function setCharHidden(char, target)
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = target
        end
    end
end

local function kendaraanDariSeat(seat)
    local m = seat:FindFirstAncestorOfClass("Model")
    if m then
        while m.Parent and m.Parent ~= workspace and m.Parent:IsA("Model") do
            m = m.Parent
        end
        return m
    end
    return seat
end

local function scanKendaraan(v, target)
    local daftar
    if v:IsA("Model") then
        daftar = v:GetDescendants()
    else
        local ok, con = pcall(function() return v:GetConnectedParts(true) end)
        daftar = (ok and con) or {v}
    end
    for _, d in ipairs(daftar) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = target
        elseif d:IsA("Decal") or d:IsA("Texture") then
            if target == 1 then
                if savedDecal[d] == nil then
                    savedDecal[d] = d.Transparency
                    d.Transparency = 1
                end
            else
                local asli = savedDecal[d]
                if asli ~= nil then
                    d.Transparency = asli
                    savedDecal[d] = nil
                end
            end
        end
    end
end

local function cekKendaraan()
    local hum = getHum()
    local mySeat = hum and hum.SeatPart
    local myRef  = mySeat or (hum and hum.RootPart)
    if not myRef then return end
    local mx, mz = myRef.Position.X, myRef.Position.Z

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local hum2 = char and char:FindFirstChildOfClass("Humanoid")
            local seat = hum2 and hum2.SeatPart

            if seat and mySeat and seat.AssemblyRootPart == mySeat.AssemblyRootPart then
                -- 🚗 mobil yang AKU tumpangi / kendarai → SELALU TAMPIL
                if vehHidden[plr] then
                    pcall(scanKendaraan, vehHidden[plr], 0)
                    vehHidden[plr] = nil
                end
            elseif seat then
                local p = seat.Position
                local dx, dz = p.X - mx, p.Z - mz
                local sentuh = dx*dx + dz*dz <= R2
                if sentuh and not vehHidden[plr] then
                    local v = kendaraanDariSeat(seat)
                    vehHidden[plr] = v
                    pcall(scanKendaraan, v, 1)              -- menyentuh → hilang
                elseif not sentuh and vehHidden[plr] then
                    pcall(scanKendaraan, vehHidden[plr], 0) -- menjauh → muncul
                    vehHidden[plr] = nil
                end
            elseif vehHidden[plr] then
                pcall(scanKendaraan, vehHidden[plr], 0)
                vehHidden[plr] = nil
            end

            -- jaring pengaman (cuma BACA 1 properti / pemain):
            -- pemain respawn / baru join langsung ketutup lagi.
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and root.LocalTransparencyModifier ~= 1 then
                setCharHidden(char, 1)
            end
        end
    end
end

local function setHidePlayers(on)
    S.hidePlayersOn = on
    hideLoopId += 1
    local myId = hideLoopId

    if on then
        -- karakter pemain: sekali jalan
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                setCharHidden(plr.Character, 1)
            end
        end
        -- loop cek kendaraan (baca posisi saja; scan part HANYA saat ada perubahan)
        task.spawn(function()
            while S.hidePlayersOn and myId == hideLoopId and gui.Parent do
                pcall(cekKendaraan)
                task.wait(CEK_INTERVAL)
            end
        end)
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                setCharHidden(plr.Character, 0)
            end
        end
        for plr, v in pairs(vehHidden) do
            if v then pcall(scanKendaraan, v, 0) end
            vehHidden[plr] = nil
        end
        table.clear(savedDecal)
    end

    styleToggle(rHideP.toggle, on)
    notify("Hide Pemain + Kendaraan", on)
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
        addConn(fxConn)
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
        addConn(gfxConn)
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
        end
        S.clockOn = true
        applyLockedClock()
        task.spawn(function()
            while S.clockOn and gui.Parent do
                task.wait(1)
                if S.clockOn then applyLockedClock() end
            end
        end)
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

--═══════════════ RESET & KELUAR ═══════════════
local function matikanSemua()
    pcall(function() if S.hidePlayersOn then setHidePlayers(false) end end)
    pcall(function() if S.hideFxOn then setHideFx(false) end end)
    pcall(function() if S.lowGfxOn then setLowGfx(false) end end)
    pcall(function() if S.clockOn then setClock(false) end end)
    pcall(function() if S.speedOn then setSpeed(false) end end)
    pcall(function() if S.jumpOn then setJump(false) end end)
end

local function destroyAll()
    silent = true
    matikanSemua()
    silent = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    table.clear(conns)
    gui:Destroy()
end

local function resetSemua()
    silent = true
    matikanSemua()
    silent = false
    S.speedValue, S.jumpValue = DEFAULT_SPEED, DEFAULT_JUMP
    S.clockValue = Lighting.ClockTime
    rSpeed.val.Text = fmt(S.speedValue)
    rJump.val.Text  = fmt(S.jumpValue)
    rClock.val.Text = formatClock(S.clockValue)
    notify("Reset ke default ✓", true)
end

--═══════════════ WIRING TOMBOL ═══════════════
rSpeed.minus.MouseButton1Click:Connect(function()
    S.speedValue = math.max(1, S.speedValue - STEP)
    rSpeed.val.Text = fmt(S.speedValue)
    if S.speedOn then applyMovement() end
end)
rSpeed.plus.MouseButton1Click:Connect(function()
    S.speedValue += STEP
    rSpeed.val.Text = fmt(S.speedValue)
    if S.speedOn then applyMovement() end
end)
rSpeed.toggle.MouseButton1Click:Connect(function() setSpeed(not S.speedOn) end)

rJump.minus.MouseButton1Click:Connect(function()
    S.jumpValue = math.max(1, S.jumpValue - STEP)
    rJump.val.Text = fmt(S.jumpValue)
    if S.jumpOn then applyMovement() end
end)
rJump.plus.MouseButton1Click:Connect(function()
    S.jumpValue += STEP
    rJump.val.Text = fmt(S.jumpValue)
    if S.jumpOn then applyMovement() end
end)
rJump.toggle.MouseButton1Click:Connect(function() setJump(not S.jumpOn) end)

rHideP.toggle.MouseButton1Click:Connect(function() setHidePlayers(not S.hidePlayersOn) end)
rHideF.toggle.MouseButton1Click:Connect(function() setHideFx(not S.hideFxOn) end)
rLowG.toggle.MouseButton1Click:Connect(function() setLowGfx(not S.lowGfxOn) end)

rClock.minus.MouseButton1Click:Connect(function() bumpClock(-CLOCK_STEP) end)
rClock.plus.MouseButton1Click:Connect(function() bumpClock(CLOCK_STEP) end)
rClock.toggle.MouseButton1Click:Connect(function() setClock(not S.clockOn) end)

-- minimize (instan)
local function setMinimize(k)
    scroll.Visible = not k
    bottom.Visible = not k
    main.Size = k and UDim2.fromOffset(480, 58) or UDim2.fromOffset(480, 620)
end
minBtn.MouseButton1Click:Connect(function() setMinimize(scroll.Visible) end)

resetBtn.MouseButton1Click:Connect(resetSemua)
exitBtn.MouseButton1Click:Connect(destroyAll)

--═══════════════ DRAG GUI ═══════════════
do
    local dragging, dragStart, startPos = false, nil, nil
    title.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    addConn(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            local s = panelScale.Scale
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / s,
                startPos.Y.Scale, startPos.Y.Offset + d.Y / s)
        end
    end))
    addConn(UserInputService.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

--═══════════════ HOTKEYS ═══════════════
addConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local kc = input.KeyCode
    if kc == Enum.KeyCode.F then
        main.Visible = not main.Visible
    elseif kc == Enum.KeyCode.T then
        setClock(not S.clockOn)
    elseif kc == Enum.KeyCode.R then
        setHidePlayers(not S.hidePlayersOn)
    elseif kc == Enum.KeyCode.Q then
        setSpeed(not S.speedOn)
    end
end))

--═══════════════ FINALIZE ═══════════════
segarkanToggle()
main.Visible = true
notify("Siiilau ⚡ RACE LITE siap — F = buka/tutup", true)
