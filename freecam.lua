--[[
    ═══════════════════════════════════════════════
      FREECAM + AUTO PAGI  •  LocalScript
      Letakkan di: StarterPlayer > StarterPlayerScripts
    ═══════════════════════════════════════════════
    KONTROL:
      F        : buka/tutup menu
      R        : freecam ON/OFF
      W A S D  : maju / kiri / mundur / kanan
      Q / E    : turun / naik
      SPACE    : percepat kamera (tahan)
      MOUSE    : mengarahkan kamera
      T        : auto pagi ON/OFF

    100% CLIENT-SIDE:
      • Karakter tidak dipindahkan sama sekali
      • Tidak ada data gerakan yang dikirim ke server
      • Kursor mouse disembunyikan saat freecam terbang
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")

local player = Players.LocalPlayer

-- ============================== KONFIGURASI ==============================
local CONFIG = {
    KEY_MENU     = Enum.KeyCode.F,
    KEY_FCAM     = Enum.KeyCode.R,
    KEY_MORNING  = Enum.KeyCode.T, -- auto pagi ON/OFF

    BASE_SPEED   = 60,     -- kecepatan normal kamera (studs/detik)
    BOOST_MULT   = 3,      -- pengali saat SPACE ditahan
    MOVE_SMOOTH  = 5,      -- akselerasi/deselerasi sinematik
    ROT_SMOOTH   = 14,     -- kehalusan rotasi mouse
    MOUSE_SENS   = 0.0022, -- sensitivitas mouse
    MAX_PITCH    = math.pi / 2 - 0.05,

    MORNING_HOUR = 7,      -- AUTO PAGI -> 07:00

    STREAM_INTERVAL = 0.5, -- frekuensi request dunia di posisi kamera (detik)
}

local BIND_NAME = "SimpleFreecam"
local RENDER_PRIORITY = Enum.RenderPriority.Last.Value + 100

-- ================================= STATE =================================
local panel
local fcamActive = false

local pos, vel = Vector3.zero, Vector3.zero
local yaw, pitch             = 0, 0
local targetYaw, targetPitch = 0, 0
local savedCamType, savedCamSubject
local savedFreecam = nil
local frozenHrp, frozenPrev = nil, nil
local morningConn = nil
local streamAccum = 0

-- ================================ HELPERS ================================
local function smoothNum(c, t, rate, dt)
    return c + (t - c) * (1 - math.exp(-rate * dt))
end

local controls
do
    local ok, pm = pcall(function()
        return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    end)
    if ok and pm then
        local ok2, c = pcall(function() return pm:GetControls() end)
        if ok2 then controls = c end
    end
end

-- Bekukan avatar di posisi awal (client-only; server hanya melihat pemain diam)
local function freezeCharacter(freeze)
    if freeze then
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if hrp and frozenHrp ~= hrp then
            if frozenHrp and frozenHrp.Parent then
                pcall(function() frozenHrp.Anchored = frozenPrev end)
            end
            frozenHrp, frozenPrev = hrp, hrp.Anchored
            hrp.Anchored = true
        end
    else
        if frozenHrp then
            if frozenHrp.Parent then
                pcall(function() frozenHrp.Anchored = frozenPrev end)
            end
            frozenHrp, frozenPrev = nil, nil
        end
    end
end

-- ================================ FREECAM ================================
local function onRenderStep(dt)
    dt = math.min(dt, 0.1)
    local cam = workspace.CurrentCamera
    if not cam then return end

    cam.CameraType = Enum.CameraType.Scriptable

    -- Mouse: terkunci saat freecam jalan & menu tertutup, bebas saat menu terbuka
    UserInputService.MouseBehavior = panel.Visible
        and Enum.MouseBehavior.Default
        or  Enum.MouseBehavior.LockCenter

    -- ★ Kursor disembunyikan saat terbang, muncul lagi saat menu terbuka
    UserInputService.MouseIconEnabled = panel.Visible

    yaw   = smoothNum(yaw,   targetYaw,   CONFIG.ROT_SMOOTH, dt)
    pitch = smoothNum(pitch, targetPitch, CONFIG.ROT_SMOOTH, dt)

    local basis = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += basis.LookVector  end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= basis.LookVector  end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= basis.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += basis.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir -= Vector3.yAxis     end
    if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir += Vector3.yAxis     end

    local speed = CONFIG.BASE_SPEED
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        speed *= CONFIG.BOOST_MULT
    end

    local targetVel = (dir.Magnitude > 0) and (dir.Unit * speed) or Vector3.zero
    vel  = vel:Lerp(targetVel, 1 - math.exp(-CONFIG.MOVE_SMOOTH * dt))
    pos += vel * dt

    -- Roll selalu 0 → tanpa shake/tilt
    cam.CFrame = CFrame.new(pos) * basis

    -- Dunia di sekitar kamera dimuat via API resmi (karakter tetap diam)
    streamAccum += dt
    if streamAccum >= CONFIG.STREAM_INTERVAL then
        streamAccum = 0
        if workspace.StreamingEnabled then
            pcall(function()
                player:RequestStreamAroundAsync(pos)
            end)
        end
    end
end

local function startFreeCam()
    if fcamActive then return end
    fcamActive = true

    local cam = workspace.CurrentCamera
    if cam then
        if savedFreecam then
            -- Lanjut dari posisi terakhir freecam
            pos   = savedFreecam.pos
            yaw   = savedFreecam.yaw
            pitch = savedFreecam.pitch
        else
            pos = cam.CFrame.Position
            pitch, yaw = cam.CFrame:ToEulerAnglesYXZ()
        end
        savedCamType    = cam.CameraType
        savedCamSubject = cam.CameraSubject
    end
    targetPitch, targetYaw = pitch, yaw
    vel = Vector3.zero
    streamAccum = CONFIG.STREAM_INTERVAL

    if controls then pcall(function() controls:Disable() end) end
    freezeCharacter(true)

    RunService:BindToRenderStep(BIND_NAME, RENDER_PRIORITY, onRenderStep)
end

local function stopFreeCam()
    if not fcamActive then return end
    fcamActive = false

    RunService:UnbindFromRenderStep(BIND_NAME)

    savedFreecam = { pos = pos, yaw = yaw, pitch = pitch }

    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true -- ★ kembalikan kursor

    freezeCharacter(false)
    if controls then pcall(function() controls:Enable() end) end

    local cam = workspace.CurrentCamera
    if cam then
        cam.CameraType = savedCamType or Enum.CameraType.Custom
        if savedCamSubject then
            pcall(function() cam.CameraSubject = savedCamSubject end)
        end
    end
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local cam = workspace.CurrentCamera
    if fcamActive and cam then
        cam.CameraType = Enum.CameraType.Scriptable
    end
end)

-- Respawn: matikan freecam agar kamera kembali ke avatar & reset posisi
player.CharacterAdded:Connect(function()
    if fcamActive then stopFreeCam() end
    savedFreecam = nil
end)

-- =============================== AUTO PAGI ===============================
local function setAutoMorning(on)
    if on then
        Lighting.ClockTime = CONFIG.MORNING_HOUR
        morningConn = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
            -- Paksa tetap 07:00 meski server ubah waktu (siang/sore/malam)
            if Lighting.ClockTime ~= CONFIG.MORNING_HOUR then
                Lighting.ClockTime = CONFIG.MORNING_HOUR
            end
        end)
    else
        if morningConn then
            morningConn:Disconnect()
            morningConn = nil
        end
    end
end

-- ================================== GUI ==================================
local gui = Instance.new("ScreenGui")
gui.Name = "SimpleFreeCamGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(252, 156)
panel.Position = UDim2.new(0, 14, 0, 14)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(70, 70, 95)
panelStroke.Thickness = 1
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "  FREECAM"
title.Parent = panel

local content = Instance.new("Frame")
content.Position = UDim2.new(0, 0, 0, 30)
content.Size = UDim2.new(1, 0, 1, -30)
content.BackgroundTransparency = 1
content.Parent = panel

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = content

local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 6)
contentPad.Parent = content

local function makeToggle(name, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -24, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(52, 52, 64)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(235, 235, 240)
    btn.Text = name .. "  •  OFF"
    btn.LayoutOrder = order
    btn.AutoButtonColor = true
    btn.Parent = content

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local state = false
    local function refresh()
        btn.Text = name .. "  •  " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(38, 140, 74) or Color3.fromRGB(52, 52, 64)
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        refresh()
        callback(state)
    end)

    return {
        get = function() return state end,
        set = function(v)
            if v == state then return end
            state = v
            refresh()
            callback(state)
        end,
    }
end

local tFreeCam = makeToggle("FREE CAM", 1, function(on)
    if on then
        panel.Visible = false -- langsung kontrol; tekan F untuk buka menu lagi
        startFreeCam()
    else
        stopFreeCam()
    end
end)

local tMorning = makeToggle("AUTO PAGI (07:00)", 2, setAutoMorning)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -24, 0, 30)
hint.BackgroundTransparency = 1
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextColor3 = Color3.fromRGB(150, 150, 165)
hint.TextWrapped = true
hint.LayoutOrder = 3
hint.Text = "WASD gerak • Q/E turun/naik • SPACE boost\nR freecam • T auto pagi • F menu"
hint.Parent = content

-- Geser panel: tahan judul lalu tarik
local dragging, dragStart, startPos = false, nil, nil
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging, dragStart, startPos = true, input.Position, panel.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ================================= INPUT =================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == CONFIG.KEY_MENU then
        panel.Visible = not panel.Visible
    elseif input.KeyCode == CONFIG.KEY_FCAM then
        tFreeCam.set(not tFreeCam.get())
    elseif input.KeyCode == CONFIG.KEY_MORNING then
        tMorning.set(not tMorning.get())
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not fcamActive or panel.Visible then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        targetYaw  -= input.Delta.X * CONFIG.MOUSE_SENS
        targetPitch = math.clamp(
            targetPitch - input.Delta.Y * CONFIG.MOUSE_SENS,
            -CONFIG.MAX_PITCH, CONFIG.MAX_PITCH)
    end
end)
