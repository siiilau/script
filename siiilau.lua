--[[=============================================================
    ⛓️Siiilau⚡ - Compact GUI Hub (satu panel, ± 6 x 10 cm)
    =============================================================
    Movement      : Speed & Swim [Q] (17.25, step 0.25)
                    Jump Power (52.25, step 0.25)
                    -> OFF = nilai asli DIPULIHKAN PENUH
                    Scooshlock (Crosshair)
    Player Display: Info Other Players [C]  (SELF-HEALING)
                      baris 1: DisplayName (@username) - putih
                      baris 2: WS 0,00 | JP 52,25 | SS 18,00 - biru
                      UKURAN SAMA, update REALTIME tiap 0.05 detik,
                      WS = kecepatan gerak real (diam = 0,00),
                      HANYA MUNCUL jika jarak <= 15 langkah
                      (stud) dari avatar utama, lebih jauh auto hide
                    Hitbox Players (kotak hijau LED, visual saja)
    Visual        : Hide Other Players [R] | Hide All Effects
                    Low Graphic Mode (+ remove fog)
    Environment   : Nilai Jam (step 15 menit) -> Brightness
                    otomatis mengikuti jam in-game
    Bottom        : Reset Script | Hapus Script / Keluar
    Hotkeys       : F (buka/tutup GUI) | Q | C | R
    Notifikasi    : Setiap fitur ON/OFF muncul notif kecil.
    Font          : Normal (Gotham) - terbaca di semua perangkat.
    ===============================================================]]

--═══════════════ KONFIG ═══════════════
local DEFAULT_SPEED = 17.25
local DEFAULT_JUMP  = 52.25
local STEP          = 0.25
local MAX_DIST      = 15    -- jarak maksimum (stud) info player terlihat; 1 langkah ≈ 1 stud
local INFO_INTERVAL = 0.05  -- update realtime WS/JP/SS tiap 0.05 detik

--═══════════════ LAYANAN & FONT ═══════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

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
-- format Indonesia: 2 digit di belakang KOMA -> "0,00", "52,25", "18,00"
local function fmt2(v)
    if type(v) ~= "number" or v ~= v then return "-" end
    return (string.format("%.2f", v):gsub("%.", ","))
end

--═══════════════ BRIGHTNESS <-> NILAI JAM ═══════════════
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
    Size = UDim2.fromOffset(240, 350),
    Position = UDim2.new(0.5, -120, 0.5, -175),
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

--═══════════════ NOTIFIKASI ON/OFF ═══════════════
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
        Size = UDim2.fromOffset(180, 24),
        BackgroundColor3 = bgColor,
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

--═══════════════ CROSSHAIR (SCOOSHLOCK) ═══════════════
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
    local lw = opts.value and (opts.toggle and -150 or -106) or -46
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

addSection("Visual")
local rHideP = addRow("Hide Other Players [R]", {toggle = true})
local rHideF = addRow("Hide All Effects",       {toggle = true})
local rLowG  = addRow("Low Graphic + No Fog",   {toggle = true})

addSection("Environment")
local rClock = addRow("Nilai Jam (Brightness)", {value = true})

--═══════════════ STATE ═══════════════
local S = {
    speedOn = false, speedValue = DEFAULT_SPEED,
    jumpOn = false,  jumpValue = DEFAULT_JUMP,
    crosshairOn = false, infoOn = false, hitboxOn = false,
    hidePlayersOn = false, hideFxOn = false, lowGfxOn = false,
    clockValue = Lighting.ClockTime,
}
local orig = {brightness = Lighting.Brightness, clockTime = Lighting.ClockTime}

local conns = {}
local function addConn(c) table.insert(conns, c) return c end
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

--═══════════════ MOVEMENT + RESTORE BENAR-BENAR KE ASLINYA ═══════════════
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

--═══════════════ INFO OTHER PLAYERS [C] - REALTIME 0.05s ═══════════════
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

-- WS = kecepatan gerak REAL dari velocity (diam = 0,00) | JP = jump power | SS = swim speed
local function getRealStats(char)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return 0, nil, nil end
    local ws = 0
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local v = root.AssemblyLinearVelocity
        ws = Vector3.new(v.X, 0, v.Z).Magnitude  -- real, tanpa pembulatan kasar
    end
    local ss, jp
    pcall(function() ss = hum.SwimSpeed end)
    pcall(function() jp = (hum.UseJumpPower and hum.JumpPower) or hum.JumpHeight end)
    return ws, ss, jp
end

local function attachInfo(plr, char)
    local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if not head then return nil end
    pcall(cleanupInfo, char)
    local bb = new("BillboardGui", {
        Name = "PH_Info", Adornee = head,
        Size = UDim2.fromOffset(220, 48),
        StudsOffset = Vector3.new(0, 2.9, 0),
        AlwaysOnTop = true, MaxDistance = 500,
    }, char)
    -- BARIS 1 & 2: UKURAN SAMA (TextSize 14, GothamBold, tinggi 22)
    local name = new("TextLabel", {
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
        Text = "WS 0,00 | JP - | SS -",
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, bb)
    return {bb = bb, stat = stat, char = char}
end

--═══════════════ HITBOX PLAYERS (VISUAL SAJA) ═══════════════
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

--═══════════════ SYNC DISPLAYS (dipanggil tiap 0.05s) ═══════════════
local function syncDisplays()
    local myRoot = getRoot()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                ---- INFO OVERHEAD (hanya jika jarak <= MAX_DIST) ----
                if S.infoOn then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local dist = math.huge
                    if myRoot and root then
                        dist = (root.Position - myRoot.Position).Magnitude
                    end
                    if dist <= MAX_DIST then
                        local ref = infoRefs[plr]
                        -- self-healing: buat ulang jika hilang/respawn
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
                            ref.bb.Enabled = true  -- dekat -> tampilkan
                            local ws, ss, jp = getRealStats(char)
                            ref.stat.Text = "WS " .. fmt2(ws) .. " | JP " .. fmt2(jp) .. " | SS " .. fmt2(ss)
                        end
                    else
                        -- jauh -> sembunyikan (tidak dihancurkan, agar cepat muncul lagi saat mendekat)
                        local ref = infoRefs[plr]
                        if ref and ref.bb.Parent then
                            ref.bb.Enabled = false
                        end
                    end
                elseif infoRefs[plr] or char:FindFirstChild("PH_Info") then
                    infoRefs[plr] = nil
                    pcall(cleanupInfo, char)
                end
                ---- HITBOX ----
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

--═══════════════ HIDE OTHER PLAYERS (LOKAL SAJA) ═══════════════
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
    if on then
        task.spawn(function()
            while S.hidePlayersOn do
                applyHide()
                task.wait(0.2)
            end
        end)
    else
        applyHide()
    end
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

--═══════════════ LOW GRAPHIC MODE (+ REMOVE FOG) ═══════════════
local savedGfx, gfxConn = {}, nil

local function setLowGfx(on)
    S.lowGfxOn = on
    if on then
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        savedGfx.shadows, savedGfx.fogStart, savedGfx.fogEnd = Lighting.GlobalShadows, Lighting.FogStart, Lighting.FogEnd
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
    else
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
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
    end
    styleToggle(rLowG.toggle, on)
    notify("Low Graphic Mode", on)
end

--═══════════════ NILAI JAM -> BRIGHTNESS ═══════════════
local lastClock = Lighting.ClockTime
local clockChangedByUs = false

local function applyAutoBrightness()
    pcall(function() Lighting.Brightness = brightnessFromTime(Lighting.ClockTime) end)
end

local function bumpClock(d)
    S.clockValue = (S.clockValue + d) % 24
    if S.clockValue < 0 then S.clockValue += 24 end
    rClock.val.Text = formatClock(S.clockValue)
    clockChangedByUs = true
    pcall(function() Lighting.ClockTime = S.clockValue end)
    lastClock = Lighting.ClockTime
    applyAutoBrightness()
end

--═══════════════ RESET SCRIPT ═══════════════
local function resetScript()
    silent = true
    setSpeed(false); setJump(false); setCrosshair(false)
    S.infoOn, S.hitboxOn = false, false
    syncDisplays()
    styleToggle(rInfo.toggle, false); styleToggle(rHit.toggle, false)
    setHidePlayers(false); setHideFx(false); setLowGfx(false)
    S.speedValue, S.jumpValue = DEFAULT_SPEED, DEFAULT_JUMP
    S.clockValue = orig.clockTime
    clockChangedByUs = false
    pcall(function() Lighting.ClockTime = orig.clockTime end)
    lastClock = Lighting.ClockTime
    rClock.val.Text = formatClock(lastClock)
    applyAutoBrightness()
    rSpeed.val.Text, rJump.val.Text = fmt(S.speedValue), fmt(S.jumpValue)
    main.Position = UDim2.new(0.5, -120, 0.5, -175)
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
    S.hidePlayersOn = false
    setHideFx(false); setLowGfx(false)
    applyHide()
    if clockChangedByUs then pcall(function() Lighting.ClockTime = orig.clockTime end) end
    pcall(function() Lighting.Brightness = orig.brightness end)
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
    gui:Destroy()
end

--═══════════════ WIRING TOMBOL ═══════════════
rSpeed.toggle.MouseButton1Click:Connect(function() setSpeed(not S.speedOn) end)
rJump.toggle.MouseButton1Click:Connect(function() setJump(not S.jumpOn) end)
rCross.toggle.MouseButton1Click:Connect(function() setCrosshair(not S.crosshairOn) end)
rInfo.toggle.MouseButton1Click:Connect(function()
    S.infoOn = not S.infoOn
    syncDisplays()
    styleToggle(rInfo.toggle, S.infoOn)
    notify("Info Other Players", S.infoOn)
end)
rHit.toggle.MouseButton1Click:Connect(function()
    S.hitboxOn = not S.hitboxOn
    syncDisplays()
    styleToggle(rHit.toggle, S.hitboxOn)
    notify("Hitbox Players", S.hitboxOn)
end)
rHideP.toggle.MouseButton1Click:Connect(function() setHidePlayers(not S.hidePlayersOn) end)
rHideF.toggle.MouseButton1Click:Connect(function() setHideFx(not S.hideFxOn) end)
rLowG.toggle.MouseButton1Click:Connect(function() setLowGfx(not S.lowGfxOn) end)

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

rSpeed.minus.MouseButton1Click:Connect(function() bumpSpeed(-STEP) end)
rSpeed.plus.MouseButton1Click:Connect(function() bumpSpeed(STEP) end)
rJump.minus.MouseButton1Click:Connect(function() bumpJump(-STEP) end)
rJump.plus.MouseButton1Click:Connect(function() bumpJump(STEP) end)
rClock.minus.MouseButton1Click:Connect(function() bumpClock(-STEP) end)
rClock.plus.MouseButton1Click:Connect(function() bumpClock(STEP) end)

resetBtn.MouseButton1Click:Connect(resetScript)
exitBtn.MouseButton1Click:Connect(unloadScript)

--═══════════════ HOTKEY (F = buka/tutup GUI) ═══════════════
addConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.F then
        main.Visible = not main.Visible
    elseif k == Enum.KeyCode.Q then
        setSpeed(not S.speedOn)
    elseif k == Enum.KeyCode.C then
        S.infoOn = not S.infoOn
        syncDisplays()
        styleToggle(rInfo.toggle, S.infoOn)
        notify("Info Other Players", S.infoOn)
    elseif k == Enum.KeyCode.R then
        setHidePlayers(not S.hidePlayersOn)
    end
end))

--═══════════════ DRAG GUI (title bar) ═══════════════
local dragging, dragStart, startPos = false, nil, nil
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
end))
addConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

--═══════════════ LOOP UTAMA ═══════════════
-- Tiap frame  : penjaga nilai Speed/Swim & Jump Power saat ON
-- Tiap 0.05s  : sync info player (WS/JP/SS realtime + jarak) & hitbox
-- Tiap 0.25s  : jam -> brightness otomatis
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
    if accDisp >= INFO_INTERVAL then    -- REALTIME 0.05 detik
        accDisp = 0
        syncDisplays()
    end
    accClock += dt
    if accClock >= 0.25 then
        accClock = 0
        local t = Lighting.ClockTime
        if math.abs(t - lastClock) > 0.003 then
            lastClock = t
            S.clockValue = t
            rClock.val.Text = formatClock(t)
            applyAutoBrightness()
        end
    end
end))

--═══════════════ REAPPLY SAAT RESPWN ═══════════════
addConn(LocalPlayer.CharacterAdded:Connect(function(char)
    if char:WaitForChild("Humanoid", 10) then
        task.wait(0.15)
        applyMovement()
    end
end))

addConn(Players.PlayerRemoving:Connect(function(plr)
    infoRefs[plr] = nil
end))

--═══════════════ INISIALISASI ═══════════════
rSpeed.val.Text = fmt(S.speedValue)
rJump.val.Text  = fmt(S.jumpValue)
rClock.val.Text = formatClock(S.clockValue)
