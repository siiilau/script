--[[
    ╔══════════════════════════════════════════════════╗
    ║        SIIILAU GALAXY CINEMATIC CAM v11          ║
    ║        FREE CAM • PROFESSIONAL CAMERA            ║
    ║  + Teleport (C) • Stabil PRO & FREE cam          ║
    ║  + Auto Pagi (Z) • T = target lock ON/OFF        ║
    ║  + RESET script • K = HAPUS script (tekan 2x)    ║
    ║  Karakter otomatis diam saat kamera aktif        ║
    ╚══════════════════════════════════════════════════╝
    R = Free Cam | G = Cam Pro | T = target lock ON/OFF
    Z = auto pagi | C = teleport | F = panel | H = hide UI
    K = HAPUS script (tekan 2x)
    WASD + Q/E = gerak | RMB = lihat/orbit | Scroll = FOV/zoom
    Space = turbo | Ctrl = slow cinematic
]]

--// ================================================== SERVICES
local Players              = game:GetService("Players")
local RunService           = game:GetService("RunService")
local UserInputService     = game:GetService("UserInputService")
local TweenService         = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local Lighting             = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

--// ================================================== KONFIGURASI
local CAMERA_SPEED               = 32
local CINEMATIC_SPEED_MULTIPLIER = 0.25
local TURBO_SPEED_MULTIPLIER     = 3
local MOUSE_SENSITIVITY          = 0.25
local SMOOTHNESS                 = 0.12

local FREECAM_KEY     = Enum.KeyCode.R  -- toggle Free Cam
local PRO_KEY         = Enum.KeyCode.G  -- toggle Professional Camera
local PANEL_KEY       = Enum.KeyCode.F
local TARGET_LOCK_KEY = Enum.KeyCode.T  -- target lock ON/OFF (auto terdekat dari kamera)
local MORNING_KEY     = Enum.KeyCode.Z  -- auto pagi 06:45 (toggle)
local TURBO_KEY       = Enum.KeyCode.Space
local SLOW_KEY        = Enum.KeyCode.LeftControl
local HIDE_UI_KEY     = Enum.KeyCode.H
local TELEPORT_KEY    = Enum.KeyCode.C
local UNLOAD_KEY      = Enum.KeyCode.K  -- HAPUS script (tekan 2x = konfirmasi)

local MORNING_TIME                = 6.75 -- 06:45 pagi
local MORNING_TRANSITION          = 1.8  -- detik transisi waktu (smooth)
local ENABLE_LETTERBOX            = true -- bar sinematik hitam atas/bawah
local TELEPORT_BEHIND_DISTANCE    = 5    -- jarak default spawn di belakang kamera (stud)
local AUTO_ANCHOR                 = true -- karakter otomatis diam saat kamera aktif

-- Pindah ke karakter utama (tombol panel)
local SELF_FLY_DIST    = 8    -- jarak kamera mendarat di belakang karakter (FREE)
local SELF_FLY_HEIGHT  = 2.4  -- ketinggian kamera di atas kepala (FREE)

-- Stabilisasi vertikal (anti ikut lompat target/karakter)
local PRO_Y_DAMPING      = 0.9  -- PRO cam: damping pivot vertikal (detik)
local FREE_AIM_Y_DAMPING = 0.8  -- FREE cam: damping aim vertikal saat target lock (detik)
local PRO_SNAP_DISTANCE  = 12   -- snap jika subjek pindah jauh (respawn/teleport)

local RENDER_STEP_NAME = "SIIILAU_CAM_UPDATE"

-- Nilai default (dipakai fitur RESET)
local DEFAULT_FOV   = 70
local DEFAULT_SPEED = CAMERA_SPEED
local DEFAULT_TP    = TELEPORT_BEHIND_DISTANCE

--// ================================================== RE-EXECUTION CLEANUP
pcall(function() if _G.SIIILAU_CAM_UNLOAD then _G.SIIILAU_CAM_UNLOAD() end end)
pcall(function() RunService:UnbindFromRenderStep(RENDER_STEP_NAME) end)
pcall(function() ContextActionService:UnbindAction("SIIILAU_TURBO") end)
do
    local containers = {}
    pcall(function() if gethui then table.insert(containers, gethui()) end end)
    table.insert(containers, game:FindFirstChildOfClass("CoreGui"))
    table.insert(containers, LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    for _, c in ipairs(containers) do
        if c then
            local old = c:FindFirstChild("SIIILAU_GALAXY_CAM")
            if old then old:Destroy() end
        end
    end
end

--// ================================================== TEMA & HELPERS
local THEME = {
    BG     = Color3.fromRGB(9, 9, 16),
    BG2    = Color3.fromRGB(15, 15, 26),
    BG3    = Color3.fromRGB(24, 24, 40),
    PURPLE = Color3.fromRGB(168, 85, 247),
    BLUE   = Color3.fromRGB(79, 124, 255),
    CYAN   = Color3.fromRGB(125, 211, 252),
    PINK   = Color3.fromRGB(255, 92, 138),
    GOLD   = Color3.fromRGB(255, 200, 90),
    WHITE  = Color3.fromRGB(242, 242, 255),
    GREY   = Color3.fromRGB(140, 140, 170),
    LINE   = Color3.fromRGB(45, 45, 70),
}

local function create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    return inst
end
local function add(parent, class, props)
    local inst = create(class, props)
    inst.Parent = parent
    return inst
end
local function corner(parent, r)
    return add(parent, "UICorner", {CornerRadius = UDim.new(0, r or 10)})
end

local function makeStyledButton(parent, pos, size, text, onClick)
    local btn = add(parent, "TextButton", {Position = pos, Size = size,
        BackgroundColor3 = THEME.BG2, Text = "", AutoButtonColor = false})
    corner(btn, 9)
    local st = add(btn, "UIStroke", {Color = Color3.fromRGB(60,60,95), Thickness = 1, Transparency = 0.45})
    local grad = add(btn, "UIGradient", {Enabled = false, Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(88,48,180), Color3.fromRGB(40,70,190)),
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.25), NumberSequenceKeypoint.new(1,0.45)})})
    local lbl = add(btn, "TextLabel", {Position = UDim2.new(0,12,0,0), Size = UDim2.new(1,-24,1,0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = THEME.GREY,
        TextXAlignment = Enum.TextXAlignment.Left, Text = text})
    if onClick then btn.MouseButton1Click:Connect(onClick) end
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.BG3}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = THEME.BG2}):Play()
    end)
    return {btn = btn, stroke = st, grad = grad, label = lbl}
end

-- forward declarations
local setMode, updateStatus, applyTab, resetScript, requestUnload

--// ================================================== ROOT GUI
local gui = create("ScreenGui", {
    Name = "SIIILAU_GALAXY_CAM", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 9999,
})
do
    local ok = pcall(function()
        local hui = gethui and gethui()
        gui.Parent = hui or game:GetService("CoreGui")
    end)
    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

--// ================================================== LETTERBOX (bar sinematik)
local lbTop = add(gui, "Frame", {BackgroundColor3 = Color3.new(0,0,0), BorderSizePixel = 0,
    Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,0)})
local lbBottom = add(gui, "Frame", {BackgroundColor3 = Color3.new(0,0,0), BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,0,1,0), Size = UDim2.new(1,0,0,0)})

--// ================================================== FLASH TRANSISI
local flashFrame = add(gui, "Frame", {BackgroundColor3 = Color3.fromRGB(185,145,255),
    BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1,1)})
local function flash(color, peak)
    flashFrame.BackgroundColor3 = color or Color3.fromRGB(185,145,255)
    local t1 = TweenService:Create(flashFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = peak or 0.55})
    local t2 = TweenService:Create(flashFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {BackgroundTransparency = 1})
    t1:Play()
    t1.Completed:Once(function() t2:Play() end)
end

--// ================================================== STATE
local state = {
    cameraActive = false,
    mode = "FREE", -- "FREE" | "PRO"
    targetLock = false,
    target = nil,         -- Player (LocalPlayer = diri sendiri)
    morning = false,      -- auto pagi aktif
    -- freecam
    pos = Vector3.new(), yaw = 0, pitch = 0, vel = Vector3.zero,
    aimY = nil,           -- tinggi aim ter-damping (stabil anti lompat)
    fly = nil,            -- animasi terbang ke karakter utama
    -- pro (dengan stabilisasi vertikal)
    orbitDist = 14, orbitYaw = 0, orbitPitch = -0.15, proPos = nil, proPivot = nil,
    proGlide = nil,       -- animasi glide pivot ke karakter utama
    -- teleport
    tpDistance = TELEPORT_BEHIND_DISTANCE,
    -- ui / input
    panelVisible = true, uiHidden = false,
    turbo = false, slow = false, rmb = false, keys = {},
    baseSpeed = CAMERA_SPEED, fov = 70,
}
local savedCamera = nil
local savedClockTime = nil
local clockTween = nil
local connections = {}
local alive = true
local activeTab = "CAM"

--// ================================================== HELPERS MATEMATIKA & KARAKTER
local function lerpAngle(a, b, t)
    local diff = (b - a) % (2 * math.pi)
    if diff > math.pi then diff -= 2 * math.pi end
    return a + diff * t
end
local function smoothstep(t)
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end
local function getRootOf(plr)
    local c = plr and plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
-- Subjek kamera: HANYA karakter yang dipilih saat lock aktif.
-- Jika karakter target belum ada (respawn), kembalikan nil → kamera
-- MENAHAN frame terakhir (tidak loncat ke karakter lain).
local function getSubjectRoot()
    if state.targetLock and state.target then
        return getRootOf(state.target)
    end
    return getRootOf(LocalPlayer)
end
-- Pemain terdekat DARI POSISI KAMERA
local function getNearestPlayerFromCamera()
    local origin = Camera.CFrame.Position
    local best, bd = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local r = getRootOf(plr)
            if r then
                local d = (r.Position - origin).Magnitude
                if d < bd then best, bd = plr, d end
            end
        end
    end
    return best
end
local function getMyOrigin()
    local r = getRootOf(LocalPlayer)
    return (r and r.Position) or Camera.CFrame.Position
end

--// ================================================== ANCHOR OTOMATIS (kamera aktif = karakter diam)
local function applyAutoAnchor()
    local root = getRootOf(LocalPlayer)
    if root then
        if state.cameraActive and AUTO_ANCHOR then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.Anchored = true
        else
            root.Anchored = false
        end
    end
end

--// ================================================== NOTIFIKASI
local notifContainer = add(gui, "Frame", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-14,0,14),
    Size = UDim2.new(0,270,0,500), BackgroundTransparency = 1})
add(notifContainer, "UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Right})
local notifOrder = 0
local function notify(text, kind)
    notifOrder += 1
    local color = (kind == "success" and THEME.CYAN) or (kind == "error" and THEME.PINK) or THEME.BLUE
    local f = add(notifContainer, "Frame", {LayoutOrder = notifOrder, Size = UDim2.new(1,0,0,38),
        BackgroundColor3 = THEME.BG2, BackgroundTransparency = 1})
    corner(f, 10)
    local st = add(f, "UIStroke", {Color = color, Thickness = 1.2, Transparency = 1})
    local bar = add(f, "Frame", {Size = UDim2.new(0,3,1,-12), Position = UDim2.new(0,8,0,6),
        BackgroundColor3 = color, BackgroundTransparency = 1, BorderSizePixel = 0})
    local lbl = add(f, "TextLabel", {Position = UDim2.new(0,20,0,0), Size = UDim2.new(1,-28,1,0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = THEME.WHITE, TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextTruncate = Enum.TextTruncate.AtEnd})
    local tin = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(f, tin, {BackgroundTransparency = 0.12}):Play()
    TweenService:Create(st, tin, {Transparency = 0.25}):Play()
    TweenService:Create(lbl, tin, {TextTransparency = 0}):Play()
    TweenService:Create(bar, tin, {BackgroundTransparency = 0}):Play()
    task.delay(2.6, function()
        if not f.Parent then return end
        local tout = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(f, tout, {BackgroundTransparency = 1}):Play()
        TweenService:Create(st, tout, {Transparency = 1}):Play()
        TweenService:Create(lbl, tout, {TextTransparency = 1}):Play()
        TweenService:Create(bar, tout, {BackgroundTransparency = 1}):Play()
        task.delay(0.32, function() f:Destroy() end)
    end)
end

--// ================================================== AUTO PAGI (Z) — jam 06:45
local function tweenClockTo(target, duration)
    if clockTween then clockTween:Cancel() clockTween = nil end
    local startT = Lighting.ClockTime
    if target - startT > 12 then target -= 24 elseif startT - target > 12 then target += 24 end
    clockTween = TweenService:Create(Lighting,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {ClockTime = target})
    clockTween:Play()
end
local function setMorning(on, silent)
    if on == state.morning then return end
    state.morning = on
    if on then
        savedClockTime = Lighting.ClockTime
        tweenClockTo(MORNING_TIME, MORNING_TRANSITION)
        if not silent then notify("Auto Pagi ON — 06:45 ☀", "success") end
    else
        tweenClockTo(savedClockTime or 14, 1.2)
        if not silent then notify("Auto Pagi OFF — waktu dikembalikan", "info") end
    end
    if updateStatus then updateStatus() end
end

--// ================================================== TARGET LOCK
-- T (keybind)  : ON = langsung pilih pemain terdekat dari KAMERA, OFF = lepas
-- Panel (klik) : manual — diri sendiri, auto lock, atau daftar player
local function targetName(plr)
    return (plr == LocalPlayer) and "DIRI SENDIRI" or ("@" .. plr.Name)
end
local function selectTarget(plr)
    state.target = plr
    state.targetLock = true
    notify("Target lock → " .. targetName(plr), "success")
    if updateStatus then updateStatus() end
end
local function selectAutoTarget()
    local best = getNearestPlayerFromCamera()
    if best then
        selectTarget(best)
    else
        notify("Tidak ada pemain lain di sekitar kamera", "error")
    end
end
local function toggleTargetLock()
    if state.targetLock then
        state.targetLock = false
        state.target = nil
        state.aimY = nil
        notify("Target lock OFF", "info")
    else
        local best = getNearestPlayerFromCamera()
        if best then
            state.target = best
            state.targetLock = true
            notify("Target lock ON → " .. targetName(best) .. " (terdekat dari kamera)", "success")
        else
            notify("Tidak ada pemain lain di sekitar kamera", "error")
        end
    end
    if updateStatus then updateStatus() end
end

--// ================================================== TOMBOL — KE KARAKTER UTAMA (panel)
-- FREE : kamera terbang smooth ke belakang karakter, menghadap dia
-- PRO  : orbit di-recenter halus ke karakter utama
local function goToSelf()
    if not state.cameraActive then
        notify("Aktifkan kamera dulu (R / G) untuk pindah ke karakter", "error")
        return
    end
    local root = getRootOf(LocalPlayer)
    if not root then
        notify("Karakter belum siap", "error")
        return
    end
    state.target = LocalPlayer
    state.targetLock = false -- pindah posisi kamera, bukan lock aim

    local head = root.Position + Vector3.new(0, 1.5, 0)

    if state.mode == "FREE" then
        local lookCf = CFrame.fromOrientation(0, state.yaw, 0)
        local flat = Vector3.new(lookCf.LookVector.X, 0, lookCf.LookVector.Z)
        flat = (flat.Magnitude > 0.05) and flat.Unit or Vector3.new(0, 0, -1)
        local destPos = head - flat * SELF_FLY_DIST + Vector3.new(0, SELF_FLY_HEIGHT, 0)
        local dir = head - destPos
        local toYaw = math.atan2(-dir.X, -dir.Z)
        local toPitch = math.clamp(math.asin(math.clamp(dir.Unit.Y, -1, 1)), -1.45, 1.45)
        local dist = (destPos - state.pos).Magnitude
        state.fly = {
            t = 0,
            dur = math.clamp(0.6 + dist / 150, 0.6, 2.4),
            fromPos = state.pos, toPos = destPos,
            fromYaw = state.yaw, toYaw = toYaw,
            fromPitch = state.pitch, toPitch = toPitch,
        }
        state.vel = Vector3.zero
        state.aimY = nil
    elseif state.mode == "PRO" then
        local dist = (head - (state.proPivot or head)).Magnitude
        state.proGlide = {
            t = 0,
            dur = math.clamp(0.5 + dist / 120, 0.5, 2.0),
            fromPivot = state.proPivot or head,
        }
    end

    flash(THEME.BLUE, 0.5)
    notify("Kamera pindah ke karakter utama ✓", "success")
    if updateStatus then updateStatus() end
end

--// ================================================== TELEPORT VIA KAMERA (C)
local function teleportToCamera()
    if not state.cameraActive then
        notify("Aktifkan kamera dulu (R / G) untuk teleport", "error")
        return
    end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then
        notify("Karakter tidak siap untuk teleport", "error")
        return
    end
    local cf = Camera.CFrame
    local dist = state.tpDistance
    local spawnPos = cf.Position - cf.LookVector * dist -- di belakang kamera

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local hit = workspace:Raycast(spawnPos + Vector3.new(0, 4, 0), Vector3.new(0, -220, 0), params)
    local lift = (hum.RigType == Enum.HumanoidRigType.R6) and 3 or (hum.HipHeight + root.Size.Y * 0.5)
    if hit then
        spawnPos = hit.Position + Vector3.new(0, lift + 0.2, 0)
    end

    local flat = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
    flat = (flat.Magnitude > 0.05) and flat.Unit or Vector3.new(0, 0, -1)

    hum.Sit = false
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = CFrame.lookAt(spawnPos, spawnPos + flat)
    -- anchor tidak diubah: saat kamera aktif karakter tetap diam di lokasi baru

    flash(THEME.CYAN, 0.55)
    notify(("Teleport ✓ %d stud di belakang kamera"):format(math.floor(dist + 0.5)), "success")
end

--// ================================================== PANEL UTAMA
local panel = add(gui, "Frame", {Position = UDim2.new(0,20,0.5,-241), Size = UDim2.fromOffset(330,481),
    BackgroundColor3 = THEME.BG, BackgroundTransparency = 1, Active = true})
corner(panel, 14)
add(panel, "UIStroke", {Color = THEME.PURPLE, Thickness = 1.5, Transparency = 0.35})
add(panel, "UIGradient", {Rotation = 115, Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20,16,38)),
    ColorSequenceKeypoint.new(0.5, THEME.BG),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12,14,30))})})
do
    local target = panel.Position
    panel.Position = target + UDim2.fromOffset(0,26)
    TweenService:Create(panel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = target, BackgroundTransparency = 0.05}):Play()
end

-- header (drag)
local header = add(panel, "Frame", {Size = UDim2.new(1,0,0,42), BackgroundTransparency = 1, Active = true})
local titleGrad = add(header, "TextLabel", {Position = UDim2.new(0,14,0,5), Size = UDim2.new(1,-60,0,20),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 15, TextColor3 = Color3.new(1,1,1),
    TextXAlignment = Enum.TextXAlignment.Left, Text = "✦ SIIILAU GALAXY"})
add(titleGrad, "UIGradient", {Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, THEME.PURPLE), ColorSequenceKeypoint.new(0.35, THEME.BLUE),
    ColorSequenceKeypoint.new(0.7, THEME.CYAN), ColorSequenceKeypoint.new(1, THEME.PINK)})})
TweenService:Create(titleGrad.UIGradient, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true),
    {Offset = Vector2.new(1,0)}):Play()
add(header, "TextLabel", {Position = UDim2.new(0,15,0,24), Size = UDim2.new(1,-60,0,14), BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.GREY,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "CINEMATIC CAM • Videography Suite"})
for i = 1, 7 do
    add(header, "Frame", {Position = UDim2.new(0, 150 + (i * 21) % 150, 0, 6 + (i * 13) % 28),
        Size = UDim2.fromOffset(2,2), BackgroundColor3 = (i % 3 == 0) and THEME.CYAN or THEME.WHITE,
        BackgroundTransparency = 0.4 + (i % 4) * 0.12, BorderSizePixel = 0})
end
local minBtn = add(header, "TextButton", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-10,0,8),
    Size = UDim2.fromOffset(26,26), BackgroundColor3 = THEME.BG3, Text = "—", Font = Enum.Font.GothamBold,
    TextSize = 14, TextColor3 = THEME.GREY, AutoButtonColor = true})
corner(minBtn, 8)
add(minBtn, "UIStroke", {Color = THEME.LINE, Thickness = 1, Transparency = 0.4})

--// ================================================== TAB BAR
local tabBar = add(panel, "Frame", {Position = UDim2.new(0,0,0,42), Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1})
local TAB_DEFS = { {id="CAM", text="◧  CAM"}, {id="TARGET", text="⌖  TARGET"}, {id="SISTEM", text="⚙  SISTEM"} }
local tabButtons = {}
for i, def in ipairs(TAB_DEFS) do
    local tb = makeStyledButton(tabBar, UDim2.new(0, 12 + (i-1)*102, 0, 2), UDim2.fromOffset(100,30), def.text)
    tabButtons[def.id] = tb
    tb.btn.MouseButton1Click:Connect(function() applyTab(def.id) end)
end

local function divider(parent, y)
    add(parent, "Frame", {Position = UDim2.new(0,12,0,y), Size = UDim2.new(1,-24,0,1),
        BackgroundColor3 = THEME.LINE, BackgroundTransparency = 0.4, BorderSizePixel = 0})
end

local tab1 = add(panel, "Frame", {Position = UDim2.new(0,0,0,80), Size = UDim2.new(1,0,0,397), BackgroundTransparency = 1})
local tab2 = add(panel, "Frame", {Position = UDim2.new(0,0,0,80), Size = UDim2.new(1,0,0,397),
    BackgroundTransparency = 1, Visible = false})
local tab3 = add(panel, "Frame", {Position = UDim2.new(0,0,0,80), Size = UDim2.new(1,0,0,397),
    BackgroundTransparency = 1, Visible = false})

--// ================================================== TAB 1 — CAMERA
local MODE_NAMES = { FREE = "FREE CAM", PRO = "PROFESSIONAL CAM" }
local MODE_KEYS  = { FREE = "R", PRO = "G" }
local MODE_DEFS = { {id="FREE", text="◈  FREE CAM  [R]"}, {id="PRO", text="◎  PROFESSIONAL CAM  [G]"} }
local modeButtons = {}
for i, def in ipairs(MODE_DEFS) do
    modeButtons[def.id] = makeStyledButton(tab1, UDim2.new(0,12,0,4 + (i-1)*38), UDim2.new(1,-24,0,34), def.text,
        function() setMode(def.id) end)
end

divider(tab1, 82)
local statusDot = add(tab1, "Frame", {Position = UDim2.new(0,16,0,98), Size = UDim2.fromOffset(9,9),
    BackgroundColor3 = THEME.GREY, BorderSizePixel = 0})
corner(statusDot, 5)
TweenService:Create(statusDot, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {BackgroundTransparency = 0.55}):Play()
local statusText = add(tab1, "TextLabel", {Position = UDim2.new(0,32,0,90), Size = UDim2.new(1,-44,0,26),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = THEME.GREY,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "○ STANDBY — FREE CAM"})

divider(tab1, 122)
-- pindah ke karakter utama (tombol)
local selfBtn = makeStyledButton(tab1, UDim2.new(0,12,0,128), UDim2.new(1,-24,0,30), "◉  KE KARAKTER UTAMA",
    function() goToSelf() end)

-- teleport via kamera (C)
local tpBtn = makeStyledButton(tab1, UDim2.new(0,12,0,162), UDim2.new(1,-24,0,30), "⇱  TELEPORT KE KAMERA  [C]",
    function() teleportToCamera() end)
local tpDistLabel = add(tpBtn.btn, "TextLabel", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-12,0,0),
    Size = UDim2.fromOffset(80,30), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
    TextColor3 = THEME.CYAN, TextXAlignment = Enum.TextXAlignment.Right, Text = TELEPORT_BEHIND_DISTANCE .. " stud"})

-- auto pagi (Z)
local morningBtn = makeStyledButton(tab1, UDim2.new(0,12,0,196), UDim2.new(1,-24,0,30), "☀  AUTO PAGI 06:45  [Z]",
    function() setMorning(not state.morning) end)
local morningState = add(morningBtn.btn, "TextLabel", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-12,0,0),
    Size = UDim2.fromOffset(80,30), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
    TextColor3 = THEME.PINK, TextXAlignment = Enum.TextXAlignment.Right, Text = "OFF"})

divider(tab1, 232)
--// ================================================== SLIDER
local activeSliderFn = nil
local function makeSlider(parent, y, label, min, max, initial, callback)
    local holder = add(parent, "Frame", {Position = UDim2.new(0,12,0,y), Size = UDim2.new(1,-24,0,34), BackgroundTransparency = 1})
    add(holder, "TextLabel", {Size = UDim2.new(0.7,0,0,14), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
        TextSize = 10, TextColor3 = THEME.GREY, TextXAlignment = Enum.TextXAlignment.Left, Text = label})
    local valLbl = add(holder, "TextLabel", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0),
        Size = UDim2.new(0.3,0,0,14), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = THEME.CYAN, TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(initial)})
    local track = add(holder, "Frame", {Position = UDim2.new(0,0,0,20), Size = UDim2.new(1,0,0,6), BackgroundColor3 = THEME.BG3})
    corner(track, 6)
    local fill = add(track, "Frame", {Size = UDim2.new(0.5,0,1,0), BackgroundColor3 = THEME.PURPLE, BorderSizePixel = 0})
    corner(fill, 6)
    add(fill, "UIGradient", {Color = ColorSequence.new(THEME.PURPLE, THEME.CYAN)})
    local knob = add(holder, "Frame", {AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.new(0.5,0,0,23),
        Size = UDim2.fromOffset(12,12), BackgroundColor3 = THEME.WHITE, BorderSizePixel = 0})
    corner(knob, 6)
    add(knob, "UIStroke", {Color = THEME.PURPLE, Thickness = 1.5, Transparency = 0.2})
    local function setVisual(v)
        local pct = math.clamp((v - min) / (max - min), 0, 1)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0, 23)
        valLbl.Text = tostring(math.floor(v + 0.5))
    end
    local function fromX(x)
        local pct = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = min + (max - min) * pct
        setVisual(v)
        callback(v)
    end
    track.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            activeSliderFn = fromX
            fromX(io.Position.X)
        end
    end)
    setVisual(initial)
    return { Set = setVisual }
end
local speedSlider = makeSlider(tab1, 238, "KECEPATAN KAMERA", 8, 90, CAMERA_SPEED, function(v) state.baseSpeed = v end)
local fovSlider = makeSlider(tab1, 276, "FIELD OF VIEW", 30, 105, 70, function(v) state.fov = v end)
local tpSlider = makeSlider(tab1, 314, "JARAK TELEPORT (BELAKANG KAMERA)", 0, 30, TELEPORT_BEHIND_DISTANCE,
    function(v)
        state.tpDistance = v
        tpDistLabel.Text = math.floor(v + 0.5) .. " stud"
    end)

divider(tab1, 354)
add(tab1, "TextLabel", {Position = UDim2.new(0,14,0,360), Size = UDim2.new(1,-28,0,50), BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.GREY, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
    Text = "R = Free Cam • G = Cam Pro • T = target lock ON/OFF\nZ = auto pagi • C = teleport kamera • F = panel • H = hide UI\nWASD + Q/E gerak • RMB tahan = lihat/orbit • Scroll = FOV/zoom\nSpace = turbo • Ctrl = slow • K = HAPUS script (tekan 2x)"})

--// ================================================== TAB 2 — TARGET LOCK
local lockBtn = makeStyledButton(tab2, UDim2.new(0,12,0,4), UDim2.new(1,-24,0,36), "⌖  TARGET LOCK  [T]  •  OFF",
    function() toggleTargetLock() end)
local lockState = add(lockBtn.btn, "TextLabel", {AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,-12,0,0),
    Size = UDim2.fromOffset(70,36), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
    TextColor3 = THEME.PINK, TextXAlignment = Enum.TextXAlignment.Right, Text = "OFF"})

divider(tab2, 46)
add(tab2, "TextLabel", {Position = UDim2.new(0,14,0,52), Size = UDim2.new(1,-28,0,12), BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.GREY,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "PILIH MANUAL — klik untuk langsung lock"})

-- opsi 1: diri sendiri (manual)
local selfLockBtn = makeStyledButton(tab2, UDim2.new(0,12,0,68), UDim2.new(1,-24,0,30), "1 ◉  DIRI SENDIRI",
    function() selectTarget(LocalPlayer) end)
-- opsi 2: auto lock terdekat dari kamera (manual)
makeStyledButton(tab2, UDim2.new(0,12,0,102), UDim2.new(1,-24,0,30), "2 ◎  AUTO LOCK — TERDEKAT DARI KAMERA",
    function() selectAutoTarget() end)

divider(tab2, 138)
add(tab2, "TextLabel", {Position = UDim2.new(0,14,0,144), Size = UDim2.new(1,-28,0,12), BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.GREY,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "3 ▤  DAFTAR PLAYER — URUT TERDEKAT DARI KAMU"})
local listFrame = add(tab2, "ScrollingFrame", {Position = UDim2.new(0,12,0,160), Size = UDim2.new(1,-24,0,174),
    BackgroundColor3 = THEME.BG2, BackgroundTransparency = 0.25, BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageColor3 = THEME.PURPLE, CanvasSize = UDim2.new(0,0,0,0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y})
corner(listFrame, 9)
add(listFrame, "UIListLayout", {Padding = UDim.new(0,3), SortOrder = Enum.SortOrder.LayoutOrder})
add(listFrame, "UIPadding", {PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4),
    PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6)})

divider(tab2, 340)
add(tab2, "TextLabel", {Position = UDim2.new(0,14,0,346), Size = UDim2.new(1,-28,0,46), BackgroundTransparency = 1,
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = THEME.GREY, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
    Text = "T = ON (auto pilih terdekat dari KAMERA) / OFF\nKlik opsi/daftar di atas = lock manual ke pilihan itu\nAim vertikal ter-damping — target lompat-lompat\nkamera tetap stabil, tidak ikut menggeleng"})

--// ================================================== TARGET LIST (urut terdekat)
local listOrder = 0
local function makeListEntry(text, isSel, onClick)
    listOrder += 1
    local btn = add(listFrame, "TextButton", {LayoutOrder = listOrder, Size = UDim2.new(1,0,0,20),
        BackgroundColor3 = isSel and THEME.BG3 or THEME.BG2, BackgroundTransparency = isSel and 0 or 0.35,
        Text = "", AutoButtonColor = false})
    corner(btn, 6)
    local dot = add(btn, "Frame", {Position = UDim2.new(0,7,0.5,-2.5), Size = UDim2.fromOffset(5,5),
        BackgroundColor3 = isSel and THEME.CYAN or THEME.GREY, BorderSizePixel = 0})
    corner(dot, 4)
    add(btn, "TextLabel", {Position = UDim2.new(0,18,0,0), Size = UDim2.new(1,-24,1,0), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = isSel and THEME.CYAN or THEME.WHITE,
        TextXAlignment = Enum.TextXAlignment.Left, Text = text, TextTruncate = Enum.TextTruncate.AtEnd})
    btn.MouseButton1Click:Connect(onClick)
end
local function refreshTargets()
    local savedScroll = listFrame.CanvasPosition
    for _, c in ipairs(listFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    listOrder = 0
    local origin = getMyOrigin()
    local sorted = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local r = getRootOf(plr)
        local d = r and (r.Position - origin).Magnitude or math.huge
        table.insert(sorted, {plr = plr, dist = d})
    end
    table.sort(sorted, function(a, b)
        if a.dist == b.dist then return a.plr.Name < b.plr.Name end
        return a.dist < b.dist
    end)
    for _, item in ipairs(sorted) do
        local plr = item.plr
        local isSel = (state.targetLock and state.target == plr)
        local distTxt = (item.dist < math.huge) and ("  •" .. math.floor(item.dist + 0.5) .. "st") or "  •?"
        makeListEntry(plr.DisplayName .. " (@" .. plr.Name .. ")" .. (plr == LocalPlayer and " •you" or "") .. distTxt,
            isSel, function() selectTarget(plr) end)
    end
    listFrame.CanvasPosition = savedScroll
end

--// ================================================== TAB 3 — SISTEM (RESET / HAPUS SCRIPT)
local resetBtn = makeStyledButton(tab3, UDim2.new(0,12,0,6), UDim2.new(1,-24,0,44),
    "↻  RESET SCRIPT", function() resetScript() end)
resetBtn.label.TextSize = 14

local unloadBtn = makeStyledButton(tab3, UDim2.new(0,12,0,58), UDim2.new(1,-24,0,44),
    "✕  HAPUS / UNLOAD SCRIPT  [K]", function()
        if _G.SIIILAU_CAM_UNLOAD then _G.SIIILAU_CAM_UNLOAD() end
    end)
unloadBtn.stroke.Color = THEME.PINK
unloadBtn.stroke.Transparency = 0.15
unloadBtn.label.TextColor3 = THEME.PINK
unloadBtn.label.TextSize = 14

divider(tab3, 112)
add(tab3, "TextLabel", {Position = UDim2.new(0,14,0,120), Size = UDim2.new(1,-28,0,150),
    BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = THEME.GREY,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
    Text = "↻ RESET SCRIPT\n• Matikan kamera & kembalikan kontrol karakter\n• Target lock, auto pagi, FOV, kecepatan,\n  jarak teleport → semua balik ke default\n\n✕ HAPUS SCRIPT [K]\n• Script benar-benar dihapus dari game\n• GUI hilang, kamera & karakter dikembalikan\n• Tekan K 2x untuk konfirmasi (anti salah tekan)"})

--// ================================================== CHIP STATUS (muncul saat UI disembunyikan)
local chip = add(gui, "Frame", {AnchorPoint = Vector2.new(0,1), Position = UDim2.new(0,14,1,-14),
    Size = UDim2.fromOffset(220,26), BackgroundColor3 = THEME.BG, BackgroundTransparency = 0.25, Visible = false})
corner(chip, 13)
add(chip, "UIStroke", {Color = THEME.PURPLE, Thickness = 1, Transparency = 0.4})
local chipDot = add(chip, "Frame", {Position = UDim2.new(0,10,0.5,-3), Size = UDim2.fromOffset(6,6),
    BackgroundColor3 = THEME.GREY, BorderSizePixel = 0})
corner(chipDot, 4)
local chipLabel = add(chip, "TextLabel", {Position = UDim2.new(0,22,0,0), Size = UDim2.new(1,-30,1,0),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = THEME.WHITE,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "✦ SIIILAU", TextTruncate = Enum.TextTruncate.AtEnd})

--// ================================================== TAB SWITCH
applyTab = function(t)
    activeTab = t
    tab1.Visible = (t == "CAM")
    tab2.Visible = (t == "TARGET")
    tab3.Visible = (t == "SISTEM")
    for id, tb in pairs(tabButtons) do
        local sel = (id == t)
        tb.stroke.Color = sel and THEME.PURPLE or Color3.fromRGB(60,60,95)
        tb.stroke.Transparency = sel and 0.1 or 0.45
        tb.stroke.Thickness = sel and 2 or 1
        tb.grad.Enabled = sel
        tb.label.TextColor3 = sel and THEME.WHITE or THEME.GREY
    end
    if t == "TARGET" then refreshTargets() end
end

--// ================================================== STATUS
updateStatus = function()
    local active = state.cameraActive
    statusText.Text = active and ("●  LIVE — " .. MODE_NAMES[state.mode]) or ("○  STANDBY — " .. MODE_NAMES[state.mode])
    statusText.TextColor3 = active and THEME.CYAN or THEME.GREY
    statusDot.BackgroundColor3 = active and THEME.CYAN or THEME.GREY
    for id, mb in pairs(modeButtons) do
        local sel = state.mode == id
        mb.stroke.Color = sel and THEME.PURPLE or Color3.fromRGB(60,60,95)
        mb.stroke.Transparency = sel and 0.1 or 0.45
        mb.stroke.Thickness = sel and 2 or 1
        mb.grad.Enabled = sel
        mb.label.TextColor3 = sel and THEME.WHITE or THEME.GREY
    end
    local selName = (state.targetLock and state.target) and targetName(state.target) or "OFF"
    lockBtn.label.Text = "⌖  TARGET LOCK  [T]  •  " .. selName
    lockState.Text = state.targetLock and "ON" or "OFF"
    lockState.TextColor3 = state.targetLock and THEME.CYAN or THEME.PINK
    local selfSel = state.targetLock and state.target == LocalPlayer
    selfLockBtn.stroke.Color = selfSel and THEME.PURPLE or Color3.fromRGB(60,60,95)
    selfLockBtn.stroke.Transparency = selfSel and 0.1 or 0.45
    selfLockBtn.stroke.Thickness = selfSel and 2 or 1
    selfLockBtn.grad.Enabled = selfSel
    selfLockBtn.label.TextColor3 = selfSel and THEME.WHITE or THEME.GREY
    morningState.Text = state.morning and "ON" or "OFF"
    morningState.TextColor3 = state.morning and THEME.GOLD or THEME.PINK
    chipLabel.Text = "✦ SIIILAU • " .. MODE_NAMES[state.mode]
        .. (active and " • LIVE" or " • STANDBY")
        .. (state.targetLock and state.target and (" → " .. targetName(state.target)) or "")
        .. (state.morning and " • PAGI" or "")
    chipDot.BackgroundColor3 = active and THEME.CYAN or THEME.GREY
    refreshTargets()
end

--// ================================================== UI VISIBILITY
local function applyVisibility()
    panel.Visible = state.panelVisible and not state.uiHidden
    chip.Visible = state.uiHidden
    notifContainer.Visible = not state.uiHidden
end

-- tombol minimize panel
minBtn.MouseButton1Click:Connect(function()
    state.panelVisible = false
    applyVisibility()
end)

--// ================================================== VISUAL KAMERA (letterbox)
local function applyCameraVisuals()
    local lbH = state.cameraActive and ENABLE_LETTERBOX and 62 or 0
    local info = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(lbTop, info, {Size = UDim2.new(1,0,0,lbH)}):Play()
    TweenService:Create(lbBottom, info, {Size = UDim2.new(1,0,0,lbH)}):Play()
    applyVisibility()
end

--// ================================================== INIT MODE DARI KAMERA SAAT INI
local function initModeFromCamera()
    state.fly = nil
    state.proGlide = nil
    state.aimY = nil
    local cf = Camera.CFrame
    local look = cf.LookVector
    if state.mode == "FREE" then
        state.pos = cf.Position
        state.yaw = math.atan2(-look.X, -look.Z)
        state.pitch = math.asin(math.clamp(look.Y, -1, 1))
        state.vel = Vector3.zero
    elseif state.mode == "PRO" then
        local subj = getSubjectRoot()
        state.orbitYaw = math.atan2(-look.X, -look.Z)
        state.orbitPitch = math.clamp(math.asin(math.clamp(look.Y, -1, 1)), -1.35, 1.35)
        if subj then
            state.proPivot = subj.Position + Vector3.new(0, 1.5, 0)
            state.orbitDist = math.clamp((cf.Position - state.proPivot).Magnitude, 6, 70)
        else
            state.proPivot = nil
            state.orbitDist = 14
        end
        state.proPos = cf.Position
    end
end

--// ================================================== START / STOP KAMERA
local function startCamera(mode)
    if state.cameraActive then return end
    state.mode = mode
    state.cameraActive = true

    savedCamera = {
        Type = Camera.CameraType,
        Subject = Camera.CameraSubject,
        FOV = Camera.FieldOfView,
        CFrame = Camera.CFrame,
    }

    initModeFromCamera()
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.FieldOfView = math.clamp(state.fov * 0.8, 15, 110)

    applyAutoAnchor() -- karakter otomatis diam selama kamera aktif
    applyCameraVisuals()
    flash(Color3.fromRGB(185,145,255), 0.5)
    notify(MODE_NAMES[mode] .. " started — karakter diam", "success")
    updateStatus()
end

local function stopCamera()
    if not state.cameraActive then return end
    state.cameraActive = false
    state.turbo = false
    state.slow = false
    state.rmb = false
    state.keys = {}
    state.fly = nil
    state.proGlide = nil
    state.aimY = nil

    local saved = savedCamera
    savedCamera = nil
    if saved then
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = saved.CFrame
        task.defer(function()
            Camera.CameraType = saved.Type
            Camera.CameraSubject = saved.Subject
            Camera.FieldOfView = saved.FOV
        end)
    end

    applyAutoAnchor() -- karakter bebas bergerak lagi
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true

    applyCameraVisuals()
    flash(Color3.fromRGB(90,90,140), 0.65)
    notify("Camera stopped — karakter bebas bergerak", "info")
    updateStatus()
end

--// ================================================== TOGGLE & SWITCH MODE (R / G)
local function activateCamera(mode)
    if state.cameraActive then
        if state.mode == mode then
            stopCamera()
        else
            state.mode = mode
            initModeFromCamera()
            applyCameraVisuals()
            notify("Switched — " .. MODE_NAMES[mode], "info")
            updateStatus()
        end
    else
        startCamera(mode)
    end
end

--// ================================================== SET MODE (panel)
setMode = function(m)
    if state.mode == m and state.cameraActive then
        notify("Mode sudah aktif: " .. MODE_NAMES[m], "info")
        return
    end
    if state.cameraActive then
        activateCamera(m)
    else
        state.mode = m
        notify("Mode dipilih: " .. MODE_NAMES[m] .. " — tekan [" .. MODE_KEYS[m] .. "]", "info")
        updateStatus()
    end
end

--// ================================================== RESET SCRIPT (balik ke default)
resetScript = function()
    if state.cameraActive then stopCamera() end
    if state.morning then setMorning(false, true) end
    state.targetLock = false
    state.target = nil
    state.aimY = nil
    state.baseSpeed = DEFAULT_SPEED
    state.fov = DEFAULT_FOV
    state.tpDistance = DEFAULT_TP
    state.mode = "FREE"
    speedSlider.Set(DEFAULT_SPEED)
    fovSlider.Set(DEFAULT_FOV)
    tpSlider.Set(DEFAULT_TP)
    applyAutoAnchor()
    flash(THEME.GOLD, 0.5)
    notify("Script di-RESET ke pengaturan awal ✓", "success")
    updateStatus()
end

--// ================================================== UNLOAD
local function unload()
    alive = false
    pcall(function() if state.cameraActive then stopCamera() end end)
    pcall(function()
        if clockTween then clockTween:Cancel() end
        if state.morning and savedClockTime then Lighting.ClockTime = savedClockTime end
    end)
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep(RENDER_STEP_NAME) end)
    pcall(function() ContextActionService:UnbindAction("SIIILAU_TURBO") end)
    pcall(function() gui:Destroy() end)
    _G.SIIILAU_CAM_UNLOAD = nil
end
_G.SIIILAU_CAM_UNLOAD = unload

--// ================================================== KONFIRMASI UNLOAD (anti salah tekan)
local unloadArmed = false
requestUnload = function()
    if unloadArmed then
        unload()
    else
        unloadArmed = true
        notify("Tekan [K] LAGI dalam 2 detik utk konfirmasi HAPUS", "error")
        task.delay(2, function() unloadArmed = false end)
    end
end

--// ================================================== DRAG PANEL
local dragging = false
local dragStartPos, panelStartPos
table.insert(connections, header.InputBegan:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = io.Position
        panelStartPos = panel.Position
    end
end))

--// ================================================== INPUT (dibuat SEKALI saja)
local MOVE_KEYS = { W = true, A = true, S = true, D = true, Q = true, E = true }

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        state.rmb = true
        return
    end
    if input.UserInputType ~= Enum.UserInputType.Keyboard or gpe then return end
    local kc = input.KeyCode
    if kc == PANEL_KEY then
        if state.uiHidden then
            state.uiHidden = false
            state.panelVisible = true
        else
            state.panelVisible = not state.panelVisible
        end
        applyVisibility()
    elseif kc == FREECAM_KEY then
        activateCamera("FREE")
    elseif kc == PRO_KEY then
        activateCamera("PRO")
    elseif kc == TARGET_LOCK_KEY then
        toggleTargetLock()
    elseif kc == MORNING_KEY then
        setMorning(not state.morning)
    elseif kc == TELEPORT_KEY then
        teleportToCamera()
    elseif kc == UNLOAD_KEY then
        requestUnload()
    elseif kc == HIDE_UI_KEY then
        state.uiHidden = not state.uiHidden
        applyVisibility()
    elseif kc == SLOW_KEY then
        state.slow = true
    elseif MOVE_KEYS[kc.Name] then
        state.keys[kc.Name] = true
        state.fly = nil -- gerak manual membatalkan terbang otomatis
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        state.rmb = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        local kc = input.KeyCode
        if kc == SLOW_KEY then
            state.slow = false
        elseif MOVE_KEYS[kc.Name] then
            state.keys[kc.Name] = false
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        activeSliderFn = nil
    end
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local pos = input.Position
        if dragging then
            local d = pos - dragStartPos
            panel.Position = UDim2.new(panelStartPos.X.Scale, panelStartPos.X.Offset + d.X,
                panelStartPos.Y.Scale, panelStartPos.Y.Offset + d.Y)
        elseif activeSliderFn then
            activeSliderFn(pos.X)
        elseif state.rmb and state.cameraActive then
            local dx, dy = input.Delta.X, input.Delta.Y
            local sens = MOUSE_SENSITIVITY * 0.02
            if state.mode == "FREE" then
                state.fly = nil
                state.yaw -= dx * sens
                state.pitch = math.clamp(state.pitch - dy * sens, -1.45, 1.45)
            elseif state.mode == "PRO" then
                state.orbitYaw -= dx * sens
                state.orbitPitch = math.clamp(state.orbitPitch - dy * sens, -1.35, 1.35)
            end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseWheel and state.cameraActive then
        local scroll = (input.Position.Z ~= 0) and input.Position.Z or input.Delta.Z
        if state.mode == "FREE" then
            state.fov = math.clamp(state.fov - scroll * 2, 20, 110)
            fovSlider.Set(state.fov)
        elseif state.mode == "PRO" then
            state.orbitDist = math.clamp(state.orbitDist - scroll * 1.5, 4, 80)
        end
    end
end))

--// ================================================== SINK SPACE (turbo + cegah lompat saat FREE aktif)
ContextActionService:BindAction("SIIILAU_TURBO", function(_, inputState)
    if inputState == Enum.UserInputState.Begin then
        if state.cameraActive and state.mode == "FREE" and not UserInputService:GetFocusedTextBox() then
            state.turbo = true
            return Enum.ContextActionResult.Sink
        end
    elseif inputState == Enum.UserInputState.End then
        state.turbo = false
    end
    return Enum.ContextActionResult.Pass
end, false, TURBO_KEY)

--// ================================================== RENDER LOOP (dibuat SEKALI saja)
RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
    local wantLock = state.cameraActive and state.rmb
    if wantLock then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
    end

    if not state.cameraActive then return end

    if state.mode == "FREE" then
        local alpha = 1 - math.exp(-dt / SMOOTHNESS)

        if state.fly then
            -- terbang smooth ke karakter utama (tombol panel)
            local f = state.fly
            f.t = math.min(f.t + dt, f.dur)
            local k = smoothstep(f.t / f.dur)
            state.pos = f.fromPos:Lerp(f.toPos, k)
            state.yaw = lerpAngle(f.fromYaw, f.toYaw, k)
            state.pitch = f.fromPitch + (f.toPitch - f.fromPitch) * k
            if f.t >= f.dur then state.fly = nil end
        else
            local speed = state.baseSpeed
            if state.slow then
                speed *= CINEMATIC_SPEED_MULTIPLIER
            elseif state.turbo then
                speed *= TURBO_SPEED_MULTIPLIER
            end
            local cf = CFrame.fromOrientation(state.pitch, state.yaw, 0)
            local move = Vector3.zero
            if state.keys.W then move += cf.LookVector end
            if state.keys.S then move -= cf.LookVector end
            if state.keys.D then move += cf.RightVector end
            if state.keys.A then move -= cf.RightVector end
            if state.keys.E then move += Vector3.new(0,1,0) end
            if state.keys.Q then move -= Vector3.new(0,1,0) end
            if move.Magnitude > 0 then move = move.Unit end
            state.vel = state.vel:Lerp(move * speed, alpha)
            state.pos += state.vel * dt

            -- ★ target lock: aim halus ke karakter terpilih,
            --   vertikal DI-DAMPING → target lompat tidak membuat kamera menggeleng
            if state.targetLock then
                local r = getRootOf(state.target)
                if r then
                    local tp = r.Position + Vector3.new(0, 1.5, 0)
                    if not state.aimY then state.aimY = tp.Y end
                    local ay = 1 - math.exp(-dt / FREE_AIM_Y_DAMPING)
                    state.aimY += (tp.Y - state.aimY) * ay
                    local dir = Vector3.new(tp.X, state.aimY, tp.Z) - state.pos
                    if dir.Magnitude > 0.1 then
                        local lv = dir.Unit
                        local ty = math.atan2(-lv.X, -lv.Z)
                        local tpi = math.clamp(math.asin(math.clamp(lv.Y, -1, 1)), -1.45, 1.45)
                        state.yaw = lerpAngle(state.yaw, ty, alpha * 0.55)
                        state.pitch += (tpi - state.pitch) * alpha * 0.55
                    end
                end
            else
                state.aimY = nil
            end
        end
        Camera.CFrame = CFrame.fromOrientation(state.pitch, state.yaw, 0) + state.pos
        Camera.FieldOfView += (state.fov - Camera.FieldOfView) * alpha

    elseif state.mode == "PRO" then
        local subj = getSubjectRoot()
        if subj then
            local alpha = 1 - math.exp(-dt / (SMOOTHNESS * 1.6))
            local targetPivot = subj.Position + Vector3.new(0, 1.5, 0)

            if state.proGlide then
                -- glide halus ke karakter utama (bypass snap)
                local g = state.proGlide
                g.t = math.min(g.t + dt, g.dur)
                local k = smoothstep(g.t / g.dur)
                state.proPivot = g.fromPivot:Lerp(targetPivot, k)
                if g.t >= g.dur then state.proGlide = nil end
            else
                if not state.proPivot then state.proPivot = targetPivot end
                if (targetPivot - state.proPivot).Magnitude > PRO_SNAP_DISTANCE then
                    state.proPivot = targetPivot
                    state.proPos = nil
                end
                -- STABILISASI: horizontal normal, vertikal di-damping berat
                local ax = 1 - math.exp(-dt / (SMOOTHNESS * 1.2))
                local ay = 1 - math.exp(-dt / PRO_Y_DAMPING)
                state.proPivot = Vector3.new(
                    state.proPivot.X + (targetPivot.X - state.proPivot.X) * ax,
                    state.proPivot.Y + (targetPivot.Y - state.proPivot.Y) * ay,
                    state.proPivot.Z + (targetPivot.Z - state.proPivot.Z) * ax
                )
            end

            local rot = CFrame.fromOrientation(state.orbitPitch, state.orbitYaw, 0)
            local desiredPos = state.proPivot + rot:VectorToWorldSpace(Vector3.new(0, 0, state.orbitDist))
            state.proPos = state.proPos and state.proPos:Lerp(desiredPos, math.clamp(alpha * 1.5, 0, 1)) or desiredPos
            local desiredCf = CFrame.lookAt(state.proPos, state.proPivot)
            Camera.CFrame = Camera.CFrame:Lerp(desiredCf, math.clamp(alpha * 1.5, 0, 1))
            Camera.FieldOfView += (state.fov - Camera.FieldOfView) * alpha
        end
    end
end)

--// ================================================== EVENT PLAYERS / CHARACTER / CAMERA
table.insert(connections, Players.PlayerAdded:Connect(function() task.defer(refreshTargets) end))
table.insert(connections, Players.PlayerRemoving:Connect(function(plr)
    if state.targetLock and state.target == plr then
        state.target = nil
        state.targetLock = false
        state.aimY = nil
        notify("Target keluar game — lock dilepas", "error")
        updateStatus()
    end
    task.defer(refreshTargets)
end))

-- respawn / karakter baru: anchor ulang jika kamera aktif
table.insert(connections, LocalPlayer.CharacterAdded:Connect(function()
    task.defer(function()
        applyAutoAnchor()
        refreshTargets()
    end)
end))

-- kamera diganti game (cutscene dll): ikuti kamera baru
table.insert(connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        Camera = workspace.CurrentCamera
    end
end))

--// ================================================== INIT
applyTab("CAM")
updateStatus()
notify("SIIILAU Galaxy Cam siap — tekan [F] untuk panel", "success")
