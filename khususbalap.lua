--=====================================================================--
--  KING SILAU — Panel Utility (Client-side) v1.1
--  FIX: Speed OFF tidak bisa jalan (nilai asli tercatat 0)
--=====================================================================--

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local TeleportService  = game:GetService("TeleportService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Terrain     = Workspace:WaitForChild("Terrain")

--■ ANTI DOUBLE-RUN ----------------------------------------------------
if _G.__KING_SILAU__ then return end
_G.__KING_SILAU__ = true

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
do
    local old = PlayerGui:FindFirstChild("KING_SILAU_GUI")
    if old then old:Destroy() end
end

--■ STATE & NILAI ASLI --------------------------------------------------
local State = {
    SpeedOn = false, SpeedValue = 16,
    JumpOn  = false, JumpValue = 50, JumpHeightValue = 7.2,
    ShiftOn = false, IsSwimming = false,
    HideOn  = false,
    LWOn    = false,
    LightOn = false, LightMode = "Auto", ManualTime = 14, ManualBright = 2.5,
    WallsOn = false,
}
local Original = {} -- semua nilai asli disimpan di sini

--■ FORWARD -------------------------------------------------------------
local Setters, Switches = {}, {}
local setFeature, togglePanel, resetAll, rejoin, setLightMode
local applySpeed, applyJump, applyManualLight, updateJumpLabel
local RefreshSpeed, RefreshJump, JumpLabel

setFeature = function(name, v, silent)
    local f = Setters[name]
    if f then f(v, silent) end
end

--■ HELPER --------------------------------------------------------------
local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
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
-- FIX: hanya simpan nilai asli yang valid (> 0), jangan pernah 0
local function captureWalkSpeed(hum)
    if hum.WalkSpeed > 0 then Original.WalkSpeed = hum.WalkSpeed end
end

--■ TEMA ----------------------------------------------------------------
local C = {
    BG     = Color3.fromRGB(15, 15, 23),
    Card   = Color3.fromRGB(28, 28, 44),
    Card2  = Color3.fromRGB(40, 40, 62),
    Purple = Color3.fromRGB(140, 70, 255),
    Blue   = Color3.fromRGB(45, 140, 255),
    Text   = Color3.fromRGB(235, 235, 245),
    Sub    = Color3.fromRGB(150, 150, 175),
    Green  = Color3.fromRGB(60, 200, 110),
    Red    = Color3.fromRGB(235, 75, 75),
    Gray   = Color3.fromRGB(72, 72, 94),
}

local function new(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    inst.Parent = props.Parent
    return inst
end

local gui = new("ScreenGui", {
    Name = "KING_SILAU_GUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 9999, Parent = PlayerGui,
})

--■ NOTIFIKASI (atas tengah, auto hilang ±2 detik) -----------------------
local notifHolder = new("Frame", {
    BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.new(0, 360, 0, 400), Parent = gui,
})
new("UIListLayout", {Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = notifHolder})

local nOrder = 0
local function notify(text, on)
    nOrder += 1
    local f = new("Frame", {BackgroundColor3 = C.Card, Size = UDim2.new(0, 250, 0, 32), LayoutOrder = nOrder, Parent = notifHolder})
    new("UICorner", {CornerRadius = UDim.new(0, 8), Parent = f})
    new("UIStroke", {Color = on and C.Green or C.Red, Thickness = 1, Transparency = 0.5, Parent = f})
    local dot = new("Frame", {BackgroundColor3 = on and C.Green or C.Red, Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 10, 0.5, -4), Parent = f})
    new("UICorner", {CornerRadius = UDim.new(1, 0), Parent = dot})
    new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 26, 0, 0), Size = UDim2.new(1, -34, 1, 0), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = f})
    task.delay(2, function() f:Destroy() end)
end

local function sync(name, v, silent, label)
    local sw = Switches[name]
    if sw then sw.set(v) end
    if not silent then notify(label .. ": " .. (v and "ON" or "OFF"), v) end
end

--■ FPS COUNTER -----------------------------------------------------------
local fpsLabel = new("TextLabel", {
    BackgroundColor3 = C.BG, BackgroundTransparency = 0.35,
    Position = UDim2.new(0, 8, 1, -24), Size = UDim2.new(0, 68, 0, 16),
    Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.Sub, Text = "FPS: --", Parent = gui,
})
new("UICorner", {CornerRadius = UDim.new(0, 6), Parent = fpsLabel})
do
    local frames = 0
    RunService.RenderStepped:Connect(function() frames += 1 end)
    task.spawn(function()
        while true do
            task.wait(1)
            fpsLabel.Text = "FPS: " .. frames
            frames = 0
        end
    end)
end

--■ KOMPONEN GUI -----------------------------------------------------------
local scroll
local sOrder = 0
local function nextOrder() sOrder += 1 return sOrder end

local function corner(parent, r)
    return new("UICorner", {CornerRadius = UDim.new(0, r or 8), Parent = parent})
end

local function header(text)
    return new("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.Purple,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "▎" .. string.upper(text), LayoutOrder = nextOrder(), Parent = scroll,
    })
end

local function makeSwitch(parent)
    local sw = new("TextButton", {
        BackgroundColor3 = C.Gray, Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10), Text = "", AutoButtonColor = false, Parent = parent,
    })
    corner(sw, 10)
    local knob = new("Frame", {
        BackgroundColor3 = Color3.fromRGB(235, 235, 240), Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 3, 0.5, -7), Parent = sw,
    })
    corner(knob, 10)
    local api = {}
    function api.set(on)
        TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = on and C.Green or C.Gray}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {Position = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}):Play()
    end
    return sw, api
end

local function toggleRow(labelText, keyText, featureName)
    local row = new("Frame", {BackgroundColor3 = C.Card, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = nextOrder(), Parent = scroll})
    corner(row)
    local label = new("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -110, 1, 0),
        Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.Text,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        Text = labelText, Parent = row,
    })
    if keyText then
        local chip = new("TextLabel", {
            BackgroundColor3 = C.Card2, Size = UDim2.new(0, 22, 0, 20), Position = UDim2.new(1, -80, 0.5, -10),
            Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.Sub, Text = keyText, Parent = row,
        })
        corner(chip, 6)
    end
    local sw, api = makeSwitch(row)
    Switches[featureName] = api
    api.set(State[featureName .. "On"])
    sw.MouseButton1Click:Connect(function()
        setFeature(featureName, not State[featureName .. "On"])
    end)
    return row, label
end

local function stepperRow(getV, setV)
    local row = new("Frame", {BackgroundColor3 = C.Card, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = nextOrder(), Parent = scroll})
    corner(row)
    local minus = new("TextButton", {BackgroundColor3 = C.Card2, Size = UDim2.new(0, 32, 0, 22), Position = UDim2.new(0, 8, 0.5, -11), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.Text, Text = "-", AutoButtonColor = false, Parent = row})
    corner(minus, 6)
    local box = new("TextBox", {BackgroundColor3 = C.BG, Size = UDim2.new(1, -92, 0, 22), Position = UDim2.new(0, 46, 0.5, -11), Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = C.Text, Text = fmtNum(getV()), ClearTextOnFocus = false, Parent = row})
    corner(box, 6)
    local plus = new("TextButton", {BackgroundColor3 = C.Card2, Size = UDim2.new(0, 32, 0, 22), Position = UDim2.new(1, -40, 0.5, -11), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.Text, Text = "+", AutoButtonColor = false, Parent = row})
    corner(plus, 6)
    local function refresh() box.Text = fmtNum(getV()) end
    minus.MouseButton1Click:Connect(function() setV(clamp2(getV() - 0.25)); refresh() end)
    plus.MouseButton1Click:Connect(function() setV(clamp2(getV() + 0.25)); refresh() end)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then setV(clamp2(math.clamp(n, 0, 1000))) end
        refresh()
    end)
    return refresh
end

local function sliderRow(labelText, minV, maxV, getV, setV, fmt)
    local row = new("Frame", {BackgroundColor3 = C.Card, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = nextOrder(), Parent = scroll})
    corner(row)
    local label = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 4), Size = UDim2.new(1, -20, 0, 16), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = labelText, Parent = row})
    local bar = new("Frame", {BackgroundColor3 = C.Card2, Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 30), Parent = row})
    corner(bar, 3)
    local fill = new("Frame", {BackgroundColor3 = C.Purple, Size = UDim2.new(0.5, 0, 1, 0), Parent = bar})
    corner(fill, 3)
    local knob = new("Frame", {BackgroundColor3 = Color3.fromRGB(240, 240, 245), Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.5, -7, 0.5, -7), Parent = bar})
    corner(knob, 7)
    local function render()
        local a = math.clamp((getV() - minV) / (maxV - minV), 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, -7, 0.5, -7)
        label.Text = labelText .. ": " .. fmt(getV())
    end
    local dragging = false
    local function apply(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        setV(minV + (maxV - minV) * rel)
        render()
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            apply(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            apply(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    render()
end

local function actionRow(text, color, callback)
    local btn = new("TextButton", {BackgroundColor3 = color, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = nextOrder(), Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.Text, Text = text, AutoButtonColor = false, Parent = scroll})
    corner(btn)
    btn.MouseButton1Click:Connect(callback)
end

local function makeDraggable(obj, hit, onClick)
    local dragging, moved = false, false
    local dragStart, startPos
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            dragStart, startPos = input.Position, obj.Position
        end
    end)
    hit.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging and not moved and onClick then onClick() end
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) + math.abs(delta.Y) > 5 then moved = true end
            if moved then
                obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

--■ PANEL UTAMA -------------------------------------------------------------
local panel = new("Frame", {
    BackgroundColor3 = C.BG, Visible = false, Active = true,
    Position = UDim2.new(0.5, -160, 0.5, -215), Size = UDim2.new(0, 320, 0, 430), Parent = gui,
})
corner(panel, 12)
new("UIStroke", {Color = C.Purple, Thickness = 1.5, Transparency = 0.4, Parent = panel})
new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -60, 0, 40), Font = Enum.Font.GothamBlack, TextSize = 17, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = "KING SILAU", Parent = panel})
local grad = new("Frame", {BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(1, -24, 0, 2), Position = UDim2.new(0, 12, 0, 40), BorderSizePixel = 0, Parent = panel})
new("UIGradient", {Color = ColorSequence.new(C.Purple, C.Blue), Parent = grad})
local closeBtn = new("TextButton", {BackgroundColor3 = C.Card2, Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -34, 0, 7), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.Text, Text = "X", AutoButtonColor = false, Parent = panel})
corner(closeBtn, 6)
local titleHit = new("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -44, 0, 40), Parent = panel, Active = true})

scroll = new("ScrollingFrame", {
    BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 10, 0, 48),
    Size = UDim2.new(1, -20, 1, -58), CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarThickness = 4, ScrollBarImageColor3 = C.Purple, Parent = panel,
})
new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll})

togglePanel = function()
    panel.Visible = not panel.Visible
end
closeBtn.MouseButton1Click:Connect(function() panel.Visible = false end)

--■ TOMBOL MELAYANG (bisa digeser, tap = buka panel) -------------------------
local floatBtn = new("TextButton", {
    BackgroundColor3 = Color3.fromRGB(255, 255, 255), Size = UDim2.new(0, 46, 0, 46),
    Position = UDim2.new(0, 16, 0.5, -23), Font = Enum.Font.GothamBlack, TextSize = 15,
    TextColor3 = Color3.fromRGB(255, 255, 255), Text = "KS", AutoButtonColor = false, Parent = gui,
})
corner(floatBtn, 23)
new("UIGradient", {Color = ColorSequence.new(C.Purple, C.Blue), Parent = floatBtn})
new("UIStroke", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0.7, Parent = floatBtn})
makeDraggable(floatBtn, floatBtn, function() togglePanel() end)
makeDraggable(panel, titleHit)

--■ ISI PANEL ----------------------------------------------------------------
header("Player")
toggleRow("Speed", "Q", "Speed")
RefreshSpeed = stepperRow(
    function() return State.SpeedValue end,
    function(v)
        State.SpeedValue = v
        if State.SpeedOn then applySpeed() end
    end
)
local _, jumpLabel = toggleRow("JumpPower", nil, "Jump")
JumpLabel = jumpLabel
RefreshJump = stepperRow(
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
toggleRow("Shiftlock Mobile", "C", "Shift")

header("Visual")
toggleRow("Hide Player + Kendaraan", "R", "Hide")

header("Lightweight")
toggleRow("Partikel / Bayangan / Efek", nil, "LW")

header("Cahaya")
toggleRow("Cahaya", "T", "Light")
do
    local row = new("Frame", {BackgroundColor3 = C.Card, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = nextOrder(), Parent = scroll})
    corner(row)
    new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 80, 1, 0), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = "Mode", Parent = row})
    local bA = new("TextButton", {BackgroundColor3 = C.Purple, Size = UDim2.new(0, 56, 0, 22), Position = UDim2.new(1, -124, 0.5, -11), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.Text, Text = "AUTO", AutoButtonColor = false, Parent = row})
    corner(bA, 6)
    local bM = new("TextButton", {BackgroundColor3 = C.Card2, Size = UDim2.new(0, 64, 0, 22), Position = UDim2.new(1, -70, 0.5, -11), Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.Text, Text = "MANUAL", AutoButtonColor = false, Parent = row})
    corner(bM, 6)
    local function render()
        bA.BackgroundColor3 = State.LightMode == "Auto" and C.Purple or C.Card2
        bM.BackgroundColor3 = State.LightMode == "Manual" and C.Purple or C.Card2
    end
    bA.MouseButton1Click:Connect(function() setLightMode("Auto") render() end)
    bM.MouseButton1Click:Connect(function() setLightMode("Manual") render() end)
    render()
end
sliderRow("Jam (0-24)", 0, 24,
    function() return State.ManualTime end,
    function(v) State.ManualTime = v; applyManualLight() end,
    function(v) return string.format("%.1f", v) end
)
sliderRow("Tingkat Terang", 0, 10,
    function() return State.ManualBright end,
    function(v) State.ManualBright = v; applyManualLight() end,
    function(v) return string.format("%.1f", v) end
)

header("Map")
toggleRow("Dinding Batas", "X", "Walls")

header("Ekstra")
actionRow("RESET SCRIPT", C.Red, function() resetAll() end)
actionRow("REJOIN SERVER", C.Blue, function() rejoin() end)

--=====================================================================--
--  FITUR
--=====================================================================--

--■ CAHAYA -----------------------------------------------------------------
local lightThread
local lightChangedClock = false -- apakah KITA yang ubah jam (mode manual)?
local function captureLighting()
    if Original.ClockTime == nil then
        Original.ClockTime = Lighting.ClockTime
        Original.Brightness = Lighting.Brightness
        Original.Ambient = Lighting.Ambient
        Original.OutdoorAmbient = Lighting.OutdoorAmbient
    end
end
local function restoreLighting()
    if Original.Brightness ~= nil then Lighting.Brightness = Original.Brightness end
    if Original.Ambient ~= nil then Lighting.Ambient = Original.Ambient end
    if Original.OutdoorAmbient ~= nil then Lighting.OutdoorAmbient = Original.OutdoorAmbient end
    if lightChangedClock and Original.ClockTime ~= nil then
        Lighting.ClockTime = Original.ClockTime
        lightChangedClock = false
    end
end
applyManualLight = function()
    if State.LightOn and State.LightMode == "Manual" then
        captureLighting()
        Lighting.ClockTime = State.ManualTime
        Lighting.Brightness = State.ManualBright
        lightChangedClock = true
    end
end
local function applyAutoLight()
    captureLighting()
    local t = Lighting.ClockTime
    if t >= 18 or t < 6 then -- malam -> diterangin, tapi bukan maksimal
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.fromRGB(96, 96, 108)
        Lighting.OutdoorAmbient = Color3.fromRGB(96, 96, 108)
    else -- siang -> balik normal map (jam map TIDAK disentuh, aman untuk siklus siang-malam)
        restoreLighting()
    end
end
local function stopLightLoop()
    if lightThread then
        task.cancel(lightThread)
        lightThread = nil
    end
end
setLightMode = function(mode)
    if State.LightMode == mode then return end
    local wasManual = (State.LightMode == "Manual")
    State.LightMode = mode
    if State.LightOn then
        stopLightLoop()
        if wasManual then restoreLighting() end -- balikin jam dulu kalau tadi manual
        if mode == "Auto" then
            lightThread = task.spawn(function()
                while State.LightOn and State.LightMode == "Auto" do
                    applyAutoLight()
                    task.wait(5)
                end
            end)
        else
            applyManualLight()
        end
    end
    notify("Mode Cahaya: " .. string.upper(mode), true)
end

--■ SPEED & JUMP -------------------------------------------------------------
applySpeed = function()
    local hum = getHum()
    if not hum then return end
    local base
    if State.SpeedOn then
        base = State.SpeedValue
    else
        base = Original.WalkSpeed
        -- FIX UTAMA: jangan pernah pulihkan 0 -> itulah penyebab frozen saat OFF
        if not base or base <= 0 then base = 16 end
    end
    if State.ShiftOn and State.IsSwimming then
        base = base * 1.10 -- bonus air (bagian paket shiftlock)
    end
    hum.WalkSpeed = base
end
applyJump = function()
    local hum = getHum()
    if not hum then return end
    if hum.UseJumpPower then -- auto-deteksi JumpPower / JumpHeight
        hum.JumpPower = State.JumpOn and State.JumpValue or (Original.JumpPower or hum.JumpPower)
    else
        hum.JumpHeight = State.JumpOn and State.JumpHeightValue or (Original.JumpHeight or hum.JumpHeight)
    end
end
updateJumpLabel = function()
    local hum = getHum()
    if JumpLabel then
        JumpLabel.Text = (hum and hum.UseJumpPower) and "JumpPower" or "JumpHeight (auto)"
    end
    if RefreshJump then RefreshJump() end
end

Setters.Speed = function(v, silent)
    if State.SpeedOn == v then return end
    local hum = getHum()
    if v and hum then
        captureWalkSpeed(hum) -- catat nilai asli terbaru sebelum override
    end
    State.SpeedOn = v
    applySpeed()
    if not v then
        -- jaminan ekstra: 2 detik pertama setelah OFF, karakter PASTI bisa jalan
        task.spawn(function()
            for _ = 1, 8 do
                task.wait(0.25)
                if State.SpeedOn then return end
                local h = getHum()
                if h and h.WalkSpeed <= 0 then
                    h.WalkSpeed = (Original.WalkSpeed and Original.WalkSpeed > 0) and Original.WalkSpeed or 16
                end
            end
        end)
    end
    sync("Speed", v, silent, "Speed")
end
Setters.Jump = function(v, silent)
    if State.JumpOn == v then return end
    local hum = getHum()
    if v and hum then
        Original.JumpPower = hum.JumpPower
        Original.JumpHeight = hum.JumpHeight
        Original.UseJumpPower = hum.UseJumpPower
    end
    State.JumpOn = v
    applyJump()
    sync("Jump", v, silent, "JumpPower")
end

--■ SHIFTLOCK MOBILE ----------------------------------------------------------
Setters.Shift = function(v, silent)
    if State.ShiftOn == v then return end
    State.ShiftOn = v
    if v then
        local hum = getHum()
        if hum then hum.AutoRotate = false end
        RunService:BindToRenderStep("KS_SHIFTLOCK", Enum.RenderPriority.Character.Value + 1, function()
            local char = getChar()
            local h = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if h and root and h.Health > 0 then
                local cam = Workspace.CurrentCamera
                local _, yaw = cam.CFrame:ToOrientation()
                -- karakter selalu menghadap arah kamera + tetap tegak (termasuk saat berenang)
                root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
            end
        end)
    else
        RunService:UnbindFromRenderStep("KS_SHIFTLOCK")
        local hum = getHum()
        if hum then hum.AutoRotate = true end
        applySpeed() -- buang bonus air kalau sempat aktif
    end
    sync("Shift", v, silent, "Shiftlock Mobile")
end

--■ HIDE PLAYER + KENDARAAN -----------------------------------------------------
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
        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- nama ikut hilang
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

-- kendaraan: model bert-seat, ukuran wajar, radius 20 stud
local vehParts = {} -- [model] = { [part] = transparansi asli }
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
        if m:FindFirstChildWhichIsA("Humanoid", true) then return nil end -- karakter, skip
        if m:FindFirstChildWhichIsA("VehicleSeat", true) or m:FindFirstChildWhichIsA("Seat", true) then
            local s = m:GetExtentsSize()
            if math.max(s.X, s.Y, s.Z) <= 64 then return m end
            return nil -- kegedean (bagian map), skip
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
            p.Transparency = math.max(p.Transparency, 0.8) -- transparan 80%
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
    local root = getRoot()
    if not root then return end
    local char = getChar()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = char and {char} or {}
    local near = {}
    for _, part in ipairs(Workspace:GetPartBoundsInRadius(root.Position, 20, overlapParams)) do
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
        if State.HideOn then hideCharacter(char) end
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
    sync("Hide", v, silent, "Hide Player + Kendaraan")
end

--■ LIGHTWEIGHT ------------------------------------------------------------------
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
        Lighting.GlobalShadows = false -- bayangan off
        Original.WaterWaveSize = Terrain.WaterWaveSize
        Original.WaterWaveSpeed = Terrain.WaterWaveSpeed
        Terrain.WaterWaveSize = 0 -- gelombang air statis
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
    sync("LW", v, silent, "Lightweight")
end

--■ CAHAYA (toggle) ---------------------------------------------------------------
Setters.Light = function(v, silent)
    if State.LightOn == v then return end
    State.LightOn = v
    if v then
        stopLightLoop()
        if State.LightMode == "Auto" then
            lightThread = task.spawn(function()
                while State.LightOn and State.LightMode == "Auto" do
                    applyAutoLight()
                    task.wait(5)
                end
            end)
        else
            applyManualLight()
        end
    else
        stopLightLoop()
        restoreLighting()
    end
    sync("Light", v, silent, "Cahaya")
end

--■ DINDING BATAS -------------------------------------------------------------------
local wallOriginal = {}
local wallConn
local function isWallCandidate(part)
    if not part:IsA("BasePart") or part == Terrain then return false end
    if part.Transparency < 1 then return false end -- harus invisible
    if not part.CanCollide then return false end   -- harus solid (trigger/checkpoint gak ikut)
    local m = part:FindFirstAncestorOfClass("Model")
    if m and Players:GetPlayerFromCharacter(m) then return false end
    return true
end
local function wallify(part)
    if wallOriginal[part] then return end
    wallOriginal[part] = {Transparency = part.Transparency, Color = part.Color}
    part.Transparency = 0.35
    part.Color = Color3.fromRGB(205, 205, 205)
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
        table.clear(wallOriginal)
    end
    sync("Walls", v, silent, "Dinding Batas")
end

--■ RESET & REJOIN --------------------------------------------------------------------
resetAll = function()
    setFeature("Speed", false, true)
    setFeature("Jump", false, true)
    setFeature("Shift", false, true)
    setFeature("Hide", false, true)
    setFeature("LW", false, true)
    setFeature("Light", false, true)
    setFeature("Walls", false, true)
    State.SpeedValue, State.JumpValue, State.JumpHeightValue = 16, 50, 7.2
    if RefreshSpeed then RefreshSpeed() end
    if RefreshJump then RefreshJump() end
    notify("Reset: semua fitur OFF, nilai asli kembali", true)
end
rejoin = function()
    notify("Rejoin: balik ke server dalam 3 detik...", true)
    task.delay(3, function()
        local ok = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
        if not ok then
            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
        end
    end)
end

--■ KARAKTER: SIMPAN NILAI ASLI + PASANG ULANG SAAT RESPAWN ------------------------------
local initedChar
local function initCharacter(char)
    if initedChar == char then return end
    initedChar = char
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    captureWalkSpeed(hum) -- FIX: hanya simpan kalau valid (> 0)
    Original.JumpPower = hum.JumpPower
    Original.JumpHeight = hum.JumpHeight
    Original.UseJumpPower = hum.UseJumpPower
    updateJumpLabel()
    hum.StateChanged:Connect(function(_, newState)
        local swimming = (newState == Enum.HumanoidStateType.Swimming)
        if swimming ~= State.IsSwimming then
            State.IsSwimming = swimming
            if State.ShiftOn then applySpeed() end -- bonus air masuk/keluar otomatis
        end
    end)
    task.wait(0.25) -- tunggu game selesai set karakter
    captureWalkSpeed(hum) -- FIX: game bisa set speed asli belakangan, catat ulang
    if State.SpeedOn then applySpeed() end
    if State.JumpOn then applyJump() end
    if State.ShiftOn then hum.AutoRotate = false end
end
LocalPlayer.CharacterAdded:Connect(initCharacter)
task.spawn(function()
    local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    initCharacter(c)
end)

--■ WATCHER NILAI ASLI (inti fix Speed OFF) ---------------------------------------------
-- Selama fitur OFF, nilai asli game terus dicatat -> OFF/Reset selalu pulih ke nilai BENAR.
task.spawn(function()
    while true do
        task.wait(0.5)
        local hum = getHum()
        if hum then
            if not State.SpeedOn and not State.ShiftOn and hum.WalkSpeed > 0 then
                Original.WalkSpeed = hum.WalkSpeed
            end
            if not State.JumpOn then
                Original.JumpPower = hum.JumpPower
                Original.JumpHeight = hum.JumpHeight
                Original.UseJumpPower = hum.UseJumpPower
            end
        end
        if not State.LightOn then
            Original.ClockTime = Lighting.ClockTime
            Original.Brightness = Lighting.Brightness
            Original.Ambient = Lighting.Ambient
            Original.OutdoorAmbient = Lighting.OutdoorAmbient
        end
    end
end)

-- hook pemain lain (hide)
Players.PlayerAdded:Connect(playerHideHook)
for _, plr in ipairs(Players:GetPlayers()) do playerHideHook(plr) end
Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then unhideCharacter(plr.Character) end
end)

-- loop kendaraan (radius 20 stud)
task.spawn(function()
    while true do
        if State.HideOn then pcall(updateVehicles) end
        task.wait(0.3)
    end
end)

--■ KEYBIND PC ---------------------------------------------------------------------------
local lastK = 0
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end -- lagi ngetik di TextBox -> abaikan
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local k = input.KeyCode
    if k == Enum.KeyCode.F then
        togglePanel()
    elseif k == Enum.KeyCode.Q then
        setFeature("Speed", not State.SpeedOn)
    elseif k == Enum.KeyCode.T then
        setFeature("Light", not State.LightOn)
    elseif k == Enum.KeyCode.R then
        setFeature("Hide", not State.HideOn)
    elseif k == Enum.KeyCode.C then
        setFeature("Shift", not State.ShiftOn)
    elseif k == Enum.KeyCode.X then
        setFeature("Walls", not State.WallsOn)
    elseif k == Enum.KeyCode.K then
        local now = os.clock()
        if now - lastK < 0.45 then
            lastK = 0
            rejoin()
        else
            lastK = now
            notify("Tekan K sekali lagi untuk Rejoin", true)
        end
    end
end)

notify("KING SILAU v1.1 aktif — tekan F / tap tombol KS", true)
