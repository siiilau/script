--[[
    SILAU V1.3
    Fokus: movement dan visual untuk balapan.

    Perubahan V1.3:
    - Cahaya Auto: saat OFF, lighting kembali ke kondisi real game
      TERKINI. Perubahan lighting dari game sendiri (siang->malam, kabut,
      dsb.) terus dicatat selama ON; nilai real terakhir itulah yang
      dipulihkan, bukan snapshot saat tombol ON ditekan.
    - Hide Player + FX otomatis OFF saat mati/respawn — semua sembunyian
      karakter dan efek visual dipulihkan, tidak ada yang nyangkut.
    - Fitur hide kendaraan dihapus.

    Perubahan V1.2:
      v1.2: klasifikasi 4 lapis (nama part -> rantai weld -> peta
      attachment -> garis pinggang) + self-heal Heartbeat tiap 0,3 dtk.
      Rambut/topi/aksesoris atas tidak lolos; celana, kaki, dan sepatu
      tetap tampil.

    Perubahan V1.1:
    - Fix celana hilang, auto-cleanup saat dijalankan ulang, cache
      respawn dibersihkan, race condition Hide Player diperbaiki.

    Dihapus dari versi ini:
    - Animasi dan emote
    - Titik, benang/route, dan cloud
    - Panah deteksi pemain
    - Shiftlock Mobile

    Keybind:
    G = GUI
    Q = Speed
    J = Jump
    F = Moonwalk
    S = matikan Moonwalk
    LeftShift/RightShift = Shiftlock Tengah
    R = Hide Other Player + Effects
    T = Cahaya Auto
    K dua kali = Rejoin
]]--

print("[SILAU V1.3] load mulai...")

-- Jika script masih aktif dari sesi sebelumnya, bersihkan dulu supaya
-- tidak ada dua set keybind dan loop yang berjalan bersamaan.
pcall(function()
    if _G.__SILAU_V1_CLEANUP__ then _G.__SILAU_V1_CLEANUP__() end
end)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

if not RunService:IsClient() or not LocalPlayer then
    warn("[SILAU V1.3] harus dijalankan di client")
    return
end

--==============================================================
-- CONFIG
--==============================================================
local Config = {
    SpeedOff = 17.15,
    SpeedMin = 17.25,
    SpeedMax = 40,
    SpeedStep = 0.05,
    JumpMin = 51.25,
    JumpMax = 70,
    JumpStep = 0.05,
    ToggleKey = Enum.KeyCode.G,
    SpeedKey = Enum.KeyCode.Q,
    JumpKey = Enum.KeyCode.J,
    MoonKey = Enum.KeyCode.F,
    HideKey = Enum.KeyCode.R,
    LightKey = Enum.KeyCode.T,
    RespawnWait = 0.15,
}

local State = {
    Removed = false,
    SpeedOn = false,
    SpeedValue = 17.25,
    JumpOn = false,
    JumpValue = 51.25,
    MoonOn = false,
    CenterOn = false,
    HideOn = false,
    LightOn = false,
    LightweightOn = false,
}

local Connections = {}
local Tasks = {}
local Original = {
    JumpPower = nil,
    JumpHeight = nil,
    WalkSpeed = nil,
    AutoRotate = nil,
    UseJumpPower = nil,
    Lighting = nil,
    Terrain = nil,
}
local Character, Humanoid, RootPart

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(Connections, c)
    return c
end

local function cancelTask(key)
    if Tasks[key] then pcall(task.cancel, Tasks[key]); Tasks[key] = nil end
end

local ToastLabel -- dideklarasikan di sini agar notify() tidak bergantung pada variabel global.

local function notify(text, color)
    print("[SILAU] " .. tostring(text))
    if not ToastLabel or not ToastLabel.Parent then return end
    ToastLabel.Text = tostring(text)
    ToastLabel.TextColor3 = color or Color3.fromRGB(255,255,255)
    ToastLabel.Visible = true
    task.delay(1.8, function()
        if ToastLabel and ToastLabel.Parent then ToastLabel.Visible = false end
    end)
end

local function getCharacterParts()
    Character = LocalPlayer.Character
    Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
    return Character, Humanoid, RootPart
end

local function round2(v)
    return math.floor(v * 100 + 0.5) / 100
end

local function numberFrom(text)
    text = tostring(text or ""):gsub(",", ".")
    local n = tonumber(text)
    return n and round2(n) or nil
end

local function fmt(v)
    return string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "")
end

--==============================================================
-- CHARACTER / MOVEMENT
--==============================================================
local function captureJumpDefaults()
    if not Humanoid then return end
    -- Simpan nilai asli karakter agar cleanup mengembalikannya,
    -- bukan memakai nilai default dari Config.
    Original.WalkSpeed = Humanoid.WalkSpeed
    Original.AutoRotate = Humanoid.AutoRotate
    Original.UseJumpPower = Humanoid.UseJumpPower
    Original.JumpPower = Humanoid.JumpPower
    Original.JumpHeight = Humanoid.JumpHeight
end

local function restoreCharacterDefaults()
    if not Humanoid then return end
    if Original.WalkSpeed ~= nil then Humanoid.WalkSpeed = Original.WalkSpeed end
    if Original.AutoRotate ~= nil then Humanoid.AutoRotate = Original.AutoRotate end
end

local function applySpeed()
    if not Humanoid or Humanoid.Health <= 0 then return end
    -- Tidak ada bonus persentase dan tidak ada pengecekan/loop berenang.
    Humanoid.WalkSpeed = State.SpeedOn and State.SpeedValue or Config.SpeedOff
end

local function restoreJump()
    if not Humanoid then return end
    if Humanoid.UseJumpPower then
        if Original.JumpPower ~= nil then Humanoid.JumpPower = Original.JumpPower end
    else
        if Original.JumpHeight ~= nil then Humanoid.JumpHeight = Original.JumpHeight end
    end
end

local function applyJump()
    if not Humanoid or Humanoid.Health <= 0 then return end
    if Humanoid.UseJumpPower then
        if State.JumpOn then Humanoid.JumpPower = State.JumpValue else restoreJump() end
    else
        if State.JumpOn then Humanoid.JumpHeight = State.JumpValue else restoreJump() end
    end
end

local function setSpeed(v)
    if v ~= nil then
        if v < Config.SpeedMin or v > Config.SpeedMax then
            notify("Speed harus " .. Config.SpeedMin .. "–" .. Config.SpeedMax, Color3.fromRGB(255,180,80))
            return false
        end
        State.SpeedValue = round2(v)
    end
    applySpeed()
    return true
end

local function setJump(v)
    if v ~= nil then
        if v < Config.JumpMin or v > Config.JumpMax then
            notify("Jump harus " .. Config.JumpMin .. "–" .. Config.JumpMax, Color3.fromRGB(255,180,80))
            return false
        end
        State.JumpValue = round2(v)
    end
    applyJump()
    return true
end

local function toggleSpeed(v)
    State.SpeedOn = v == nil and not State.SpeedOn or v
    applySpeed()
    notify("S", State.SpeedOn and Color3.fromRGB(70,220,110) or Color3.fromRGB(235,70,70))
end

local function toggleJump(v)
    State.JumpOn = v == nil and not State.JumpOn or v
    applyJump()
    notify("J", State.JumpOn and Color3.fromRGB(70,220,110) or Color3.fromRGB(235,70,70))
end

local function stopCharacterFeatures()
    State.CenterOn = false
    State.MoonOn = false
    pcall(function() UIS.MouseBehavior = Enum.MouseBehavior.Default end)
    pcall(function() UIS.MouseIconEnabled = true end)
    pcall(function() UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.MovementRelative end)
    pcall(function() RunService:UnbindFromRenderStep("SILAU_CENTER") end)
    pcall(function() RunService:UnbindFromRenderStep("SILAU_MOON") end)
end

local function setCenter(v)
    State.CenterOn = v
    if v and Humanoid then
        if State.MoonOn then State.MoonOn = false end
        pcall(function() UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.CameraRelative end)
        pcall(function() UIS.MouseBehavior = Enum.MouseBehavior.LockCenter end)
        pcall(function() UIS.MouseIconEnabled = false end)
        RunService:BindToRenderStep("SILAU_CENTER", Enum.RenderPriority.Camera.Value + 1, function()
            if State.Removed or not State.CenterOn or not Humanoid or Humanoid.Health <= 0 then return end
            UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
        end)
    else
        pcall(function() RunService:UnbindFromRenderStep("SILAU_CENTER") end)
        pcall(function() UIS.MouseBehavior = Enum.MouseBehavior.Default end)
        pcall(function() UIS.MouseIconEnabled = true end)
        pcall(function() UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.MovementRelative end)
    end
    notify("ST", v and Color3.fromRGB(70,220,110) or Color3.fromRGB(235,70,70))
end

local function sedangDuduk(h)
    return h ~= nil and (h.SeatPart ~= nil or h.Sit == true)
end

local function setMoon(v)
    if State.MoonOn == v then return end
    State.MoonOn = v
    if v then
        -- Implementasi ini mengikuti Moonwalk dari script sumber:
        -- menghadap kamera hanya saat bergerak, putaran dibatasi, dan
        -- kendaraan tidak ikut dipaksa berputar saat sedang duduk.
        if State.CenterOn then setCenter(false) end
        if Humanoid then Humanoid.AutoRotate = false end
        pcall(function() RunService:UnbindFromRenderStep("SILAU_MOON") end)
        RunService:BindToRenderStep("SILAU_MOON", Enum.RenderPriority.Character.Value + 1, function(dt)
            local char = LocalPlayer.Character
            local h = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if h and sedangDuduk(h) then
                if not h.AutoRotate then h.AutoRotate = true end
                return
            end
            if h and h.AutoRotate then h.AutoRotate = false end
            if h and hrp and h.Health > 0 then
                local cam = Workspace.CurrentCamera
                if cam and h.MoveDirection.Magnitude > 0.01 then
                    local _, yawCam = cam.CFrame:ToOrientation()
                    local target = yawCam + math.pi
                    local _, yawSek = hrp.CFrame:ToOrientation()
                    local selisih = ((target - yawSek + math.pi) % (2 * math.pi)) - math.pi
                    local langkah = selisih * math.min(dt * 10, 1)
                    local maks = 12 * dt
                    if langkah > maks then langkah = maks elseif langkah < -maks then langkah = -maks end
                    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yawSek + langkah, 0)
                end
            end
        end)
    else
        pcall(function() RunService:UnbindFromRenderStep("SILAU_MOON") end)
        if Humanoid then Humanoid.AutoRotate = true end
    end
    notify("M", v and Color3.fromRGB(70,220,110) or Color3.fromRGB(235,70,70))
end

local function onCharacter(character)
    if not character:FindFirstChild("HumanoidRootPart") then
        character:WaitForChild("HumanoidRootPart", 5)
    end
    task.wait(Config.RespawnWait)
    if State.Removed then return end
    getCharacterParts()
    captureJumpDefaults()
    applySpeed()
    applyJump()
    -- Shiftlock Tengah dan Moonwalk sengaja selalu OFF saat mati/respawn.
    stopCharacterFeatures()
end

--==============================================================
-- VISUAL: HIDE OTHER PLAYER + ATTRIBUTES + EFFECTS
--==============================================================
local hiddenVisual = {}
local hiddenConnections = {}
local playerCharacterConnections = {}

local function isVisualObject(obj)
    return obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
        or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles")
        or obj:IsA("Highlight") or obj:IsA("PointLight") or obj:IsA("SpotLight")
        or obj:IsA("SurfaceLight") or obj:IsA("BillboardGui") or obj:IsA("SurfaceGui")
end

local function hideVisualObject(obj)
    if not obj or not obj.Parent then return end
    if isVisualObject(obj) then
        if hiddenVisual[obj] == nil then hiddenVisual[obj] = {kind="enabled", value=obj.Enabled} end
        pcall(function() obj.Enabled = false end)
    elseif obj:IsA("BasePart") then
        if hiddenVisual[obj] == nil then hiddenVisual[obj] = {kind="transparency", value=obj.LocalTransparencyModifier} end
        pcall(function() obj.LocalTransparencyModifier = 1 end)
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        if hiddenVisual[obj] == nil then hiddenVisual[obj] = {kind="property", value=obj.Transparency} end
        pcall(function() obj.Transparency = 1 end)
    end
end

local function hideOtherCharacter(char)
    if not char or char == Character then return end
    for _, obj in ipairs(char:GetDescendants()) do hideVisualObject(obj) end
    if not hiddenConnections[char] then
        hiddenConnections[char] = char.DescendantAdded:Connect(function(obj)
            if State.HideOn then hideVisualObject(obj) end
        end)
    end
end

local function restoreHiddenVisuals()
    for obj, data in pairs(hiddenVisual) do
        pcall(function()
            if obj.Parent then
                if data.kind == "enabled" then obj.Enabled = data.value
                elseif data.kind == "property" then obj.Transparency = data.value
                else obj.LocalTransparencyModifier = data.value end
            end
        end)
    end
    table.clear(hiddenVisual)
    for char, c in pairs(hiddenConnections) do pcall(function() c:Disconnect() end); hiddenConnections[char] = nil end
end

local function setHide(v)
    if State.HideOn == v then return end
    State.HideOn = v
    if v then
        for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer and plr.Character then hideOtherCharacter(plr.Character) end end
    else
        restoreHiddenVisuals()
    end
    notify("HDxFX", v and Color3.fromRGB(70,220,110) or Color3.fromRGB(235,70,70))
end

local function bindOtherPlayer(plr)
    if plr == LocalPlayer then return end
    local oldConn = playerCharacterConnections[plr]
    if oldConn then pcall(function() oldConn:Disconnect() end) end
    playerCharacterConnections[plr] = plr.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        if State.HideOn then hideOtherCharacter(char) end
    end)
    if State.HideOn and plr.Character then hideOtherCharacter(plr.Character) end
end

connect(Players.PlayerAdded, bindOtherPlayer)
for _, plr in ipairs(Players:GetPlayers()) do
    bindOtherPlayer(plr)
end
connect(Players.PlayerRemoving, function(plr)
    local conn = playerCharacterConnections[plr]
    if conn then pcall(function() conn:Disconnect() end); playerCharacterConnections[plr] = nil end
    local char = plr.Character
    if char then
        local charConn = hiddenConnections[char]
        if charConn then pcall(function() charConn:Disconnect() end); hiddenConnections[char] = nil end
    end
    -- Buang referensi objek yang sudah keluar agar cache tidak menumpuk.
    for obj in pairs(hiddenVisual) do
        if not obj.Parent then hiddenVisual[obj] = nil end
    end
end)

-- Saat mati (Died) dan saat respawn: Hide Other Player kembali OFF
-- otomatis — semua sembunyian karakter dan efek visual dipulihkan.
connect(LocalPlayer.CharacterAdded, function(char)
    if State.HideOn then setHide(false) end
    local h = char:WaitForChild("Humanoid", 5)
    if h then
        connect(h.Died, function()
            if State.HideOn then setHide(false) end
        end)
    end
end)

--==============================================================
-- VISUAL: LIGHTING
--==============================================================
local LIGHT_PROPS = { "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation", "FogEnd" }
local LightApplied = {} -- nilai terakhir yang kita terapkan sendiri

local function captureLighting()
    Original.Lighting = {
        ClockTime=Lighting.ClockTime, Brightness=Lighting.Brightness,
        Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient,
        ExposureCompensation=Lighting.ExposureCompensation, FogEnd=Lighting.FogEnd,
    }
    table.clear(LightApplied)
end

-- Selama ON, game bisa mengubah lighting-nya sendiri (siang->malam, kabut,
-- dsb.). Properti yang nilainya berbeda dari yang kita terapkan berarti
-- diubah game -> catat sebagai nilai REAL terbaru, supaya saat OFF cahaya
-- kembali ke kondisi real game saat itu, bukan snapshot waktu tombol ON.
local function syncRealLighting()
    if not Original.Lighting then return end
    for _, prop in ipairs(LIGHT_PROPS) do
        pcall(function()
            local cur = Lighting[prop]
            if cur ~= LightApplied[prop] then
                Original.Lighting[prop] = cur
            end
        end)
    end
end

local function applyLight()
    if not State.LightOn then return end
    local t = Lighting.ClockTime
    if t >= 18 or t < 6 then
        Lighting.Brightness = 2.5
        Lighting.Ambient = Color3.fromRGB(145,145,170)
        Lighting.OutdoorAmbient = Color3.fromRGB(125,125,150)
        Lighting.ExposureCompensation = 0.1
        if Lighting.FogEnd < 5000 then Lighting.FogEnd = 100000 end
    else
        Lighting.Brightness = 1.6
        Lighting.Ambient = Color3.fromRGB(115,115,125)
        Lighting.OutdoorAmbient = Color3.fromRGB(100,100,110)
        Lighting.ExposureCompensation = -0.15
    end
    for _, prop in ipairs(LIGHT_PROPS) do
        LightApplied[prop] = Lighting[prop]
    end
end

local function setLight(v)
    if State.LightOn == v then return end
    State.LightOn = v
    if v then
        -- Simpan kondisi pencahayaan/cuaca asli sebelum efek Auto aktif.
        captureLighting()
        applyLight()
    else
        -- Ambil dulu perubahan terakhir dari game, lalu pulihkan semuanya
        -- ke kondisi real game saat ini. ClockTime tidak pernah diubah
        -- fitur ini, jadi waktu/cuaca game tetap berjalan normal.
        syncRealLighting()
        if Original.Lighting then
            for prop, value in pairs(Original.Lighting) do
                if prop ~= "ClockTime" then
                    pcall(function() Lighting[prop] = value end)
                end
            end
        end
        table.clear(LightApplied)
    end
    notify("C", v and Color3.fromRGB(70,220,110) or Color3.fromRGB(235,70,70))
end

--==============================================================
-- VISUAL: LIGHTWEIGHT
--==============================================================
local lightweightOriginal = {}
local lightweightConns = {}
local lightweightGlobalShadows
local function keepRaceEffect(obj)
    local n = string.lower(obj.Name or "")
    return n:find("trail") or n:find("boost") or n:find("nitro") or n:find("finish") or n:find("checkpoint") or n:find("direction")
end
local function disableLightEffect(obj)
    if not State.LightweightOn or keepRaceEffect(obj) then return end
    local isEffect = obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("SunRaysEffect") or obj:IsA("ColorCorrectionEffect")
    if isEffect and lightweightOriginal[obj] == nil then
        lightweightOriginal[obj] = obj.Enabled
        obj.Enabled = false
    end
end
local function setLightweight(v)
    State.LightweightOn = v
    if v then
        lightweightGlobalShadows = Lighting.GlobalShadows
        for _, obj in ipairs(Workspace:GetDescendants()) do disableLightEffect(obj) end
        for _, obj in ipairs(Lighting:GetDescendants()) do disableLightEffect(obj) end
        lightweightConns[1] = connect(Workspace.DescendantAdded, function(obj) task.defer(disableLightEffect, obj) end)
        lightweightConns[2] = connect(Lighting.DescendantAdded, function(obj) task.defer(disableLightEffect, obj) end)
        Lighting.GlobalShadows = false
    else
        for obj, value in pairs(lightweightOriginal) do pcall(function() if obj.Parent then obj.Enabled = value end end) end
        table.clear(lightweightOriginal)
        for i, conn in pairs(lightweightConns) do pcall(function() conn:Disconnect() end); lightweightConns[i] = nil end
        if lightweightGlobalShadows ~= nil then Lighting.GlobalShadows = lightweightGlobalShadows end
        lightweightGlobalShadows = nil
    end
    notify("Lightweight " .. (v and "ON" or "OFF"))
end

--==============================================================
-- GUI
--==============================================================
local guiParent = (gethui and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
local old = guiParent:FindFirstChild("SILAU_V1")
if old then old:Destroy() end
local oldToast = guiParent:FindFirstChild("SILAU_V1_Notifications")
if oldToast then oldToast:Destroy() end
local Gui = Instance.new("ScreenGui")
Gui.Name = "SILAU_V1"; Gui.ResetOnSpawn = false; Gui.DisplayOrder = 10000; Gui.Parent = guiParent
local ToastGui = Instance.new("ScreenGui")
ToastGui.Name = "SILAU_V1_Notifications"; ToastGui.ResetOnSpawn = false; ToastGui.DisplayOrder = 11000; ToastGui.Parent = guiParent
local Scale = Instance.new("UIScale"); Scale.Parent = Gui
local Panel = Instance.new("Frame"); Panel.Name="Panel"; Panel.Size=UDim2.fromOffset(330,440); Panel.Position=UDim2.new(0,20,0.5,-220); Panel.BackgroundColor3=Color3.fromRGB(250,250,255); Panel.BorderSizePixel=0; Panel.Parent=Gui
Instance.new("UICorner", Panel).CornerRadius=UDim.new(0,12)
local panelStroke=Instance.new("UIStroke"); panelStroke.Color=Color3.fromRGB(124,58,237); panelStroke.Thickness=3; panelStroke.Parent=Panel
local panelGradient=Instance.new("UIGradient"); panelGradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(250,250,255)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(237,233,254)),ColorSequenceKeypoint.new(1,Color3.fromRGB(219,234,254))}); panelGradient.Rotation=35; panelGradient.Parent=Panel
local Header = Instance.new("TextButton"); Header.Text="⚡ S I L A U  V1.3 ⚡"; Header.Font=Enum.Font.GothamBold; Header.TextSize=18; Header.TextColor3=Color3.new(1,1,1); Header.BackgroundColor3=Color3.fromRGB(22,18,38); Header.Size=UDim2.new(1,0,0,44); Header.AutoButtonColor=false; Header.Parent=Panel
Instance.new("UICorner", Header).CornerRadius=UDim.new(0,12)
local headerGradient=Instance.new("UIGradient"); headerGradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(124,58,237)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(37,99,235)),ColorSequenceKeypoint.new(1,Color3.fromRGB(124,58,237))}); headerGradient.Rotation=15; headerGradient.Parent=Header
local TabBar=Instance.new("Frame"); TabBar.BackgroundTransparency=1; TabBar.Position=UDim2.fromOffset(8,52); TabBar.Size=UDim2.new(1,-16,0,30); TabBar.Parent=Panel
local Pages=Instance.new("Frame"); Pages.BackgroundTransparency=1; Pages.Position=UDim2.fromOffset(10,88); Pages.Size=UDim2.new(1,-20,1,-98); Pages.Parent=Panel
ToastLabel=Instance.new("TextLabel"); ToastLabel.Name="SILAU_Toast"; ToastLabel.AnchorPoint=Vector2.new(0.5,0); ToastLabel.Position=UDim2.new(0.5,0,0,8); ToastLabel.Size=UDim2.fromOffset(34,30); ToastLabel.BackgroundTransparency=1; ToastLabel.Font=Enum.Font.GothamBold; ToastLabel.TextSize=21; ToastLabel.TextColor3=Color3.new(1,1,1); ToastLabel.TextStrokeTransparency=0.35; ToastLabel.Visible=false; ToastLabel.ZIndex=100; ToastLabel.Parent=ToastGui
-- Notifikasi sengaja tanpa background/kotak: hanya simbol berwarna.

local function addButton(parent, text, callback, color)
    local b=Instance.new("TextButton"); b.Size=UDim2.new(1,0,0,32); b.BackgroundColor3=color or Color3.fromRGB(42,38,62); b.Text=text; b.Font=Enum.Font.GothamMedium; b.TextSize=13; b.TextColor3=Color3.new(1,1,1); b.AutoButtonColor=true; b.Parent=parent; Instance.new("UICorner",b).CornerRadius=UDim.new(0,7); b.MouseButton1Click:Connect(callback); return b
end
local function addInputRow(parent, label, initial, min, max, setter, getter)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,34); row.BackgroundColor3=Color3.fromRGB(37,33,55); row.Parent=parent; Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.Position=UDim2.fromOffset(8,0); l.Size=UDim2.new(0.35,0,1,0); l.Text=label; l.Font=Enum.Font.Gotham; l.TextSize=12; l.TextColor3=Color3.new(1,1,1); l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=row
    local box=Instance.new("TextBox"); box.Position=UDim2.new(0.36,0,0,5); box.Size=UDim2.new(0.42,0,0,24); box.Text=fmt(initial); box.Font=Enum.Font.Gotham; box.TextSize=12; box.TextColor3=Color3.new(1,1,1); box.BackgroundColor3=Color3.fromRGB(17,15,28); box.ClearTextOnFocus=false; box.Parent=row; Instance.new("UICorner",box).CornerRadius=UDim.new(0,5)
    local minus=Instance.new("TextButton"); minus.Text="−"; minus.Position=UDim2.new(0.80,0,0,5); minus.Size=UDim2.new(0.09,0,0,24); minus.Parent=row
    local plus=Instance.new("TextButton"); plus.Text="+"; plus.Position=UDim2.new(0.90,0,0,5); plus.Size=UDim2.new(0.09,0,0,24); plus.Parent=row
    local function refresh() box.Text=fmt(getter()) end
    minus.MouseButton1Click:Connect(function() local n=getter()-Config.SpeedStep; if label=="Jump" then n=getter()-Config.JumpStep end; if n>=min and n<=max then setter(round2(n)); refresh() else notify(label.." batas: "..min.."–"..max,Color3.fromRGB(255,180,80)) end end)
    plus.MouseButton1Click:Connect(function() local n=getter()+((label=="Jump") and Config.JumpStep or Config.SpeedStep); if n>=min and n<=max then setter(round2(n)); refresh() else notify(label.." batas: "..min.."–"..max,Color3.fromRGB(255,180,80)) end end)
    box.FocusLost:Connect(function() local n=numberFrom(box.Text); if n then if not setter(n) then refresh() end else refresh() end end)
    return row
end
local ToggleRows={}
local function refreshToggleLabels()
    for _,row in ipairs(ToggleRows) do
        if row.button and row.button.Parent then row.button.Text=row.text.."  ["..(row.getter() and "ON" or "OFF").."]" end
    end
end
local function toggleRow(parent, text, getter, setter)
    local b=addButton(parent, text.."  [OFF]", function() setter(not getter()); refreshToggleLabels() end)
    ToggleRows[#ToggleRows+1]={button=b,text=text,getter=getter}
    return b
end
local function makePage(name)
    local p=Instance.new("ScrollingFrame"); p.Name=name; p.Size=UDim2.fromScale(1,1); p.BackgroundTransparency=1; p.BorderSizePixel=0; p.ScrollBarThickness=3; p.Visible=false; p.CanvasSize=UDim2.new(); p.AutomaticCanvasSize=Enum.AutomaticSize.Y; p.Parent=Pages; local lay=Instance.new("UIListLayout"); lay.Padding=UDim.new(0,6); lay.Parent=p; return p
end
local Movement=makePage("Movement"); local Visual=makePage("Visual"); local System=makePage("System")
addInputRow(Movement,"Speed",State.SpeedValue,Config.SpeedMin,Config.SpeedMax,setSpeed,function() return State.SpeedValue end)
toggleRow(Movement,"Speed",function() return State.SpeedOn end,toggleSpeed)
addInputRow(Movement,"Jump",State.JumpValue,Config.JumpMin,Config.JumpMax,setJump,function() return State.JumpValue end)
toggleRow(Movement,"Jump",function() return State.JumpOn end,toggleJump)
toggleRow(Movement,"Shiftlock Tengah",function() return State.CenterOn end,setCenter)
toggleRow(Movement,"Moonwalk",function() return State.MoonOn end,setMoon)
toggleRow(Visual,"Hide Other Player + Effects",function() return State.HideOn end,setHide)
toggleRow(Visual,"Cahaya Auto",function() return State.LightOn end,setLight)
toggleRow(Visual,"Lightweight",function() return State.LightweightOn end,setLightweight)
addButton(System,"REJOIN SERVER [K×2]",function() TeleportService:Teleport(game.PlaceId,LocalPlayer) end,Color3.fromRGB(40,90,170))
local cleanup
local deleteArmed=false
local deleteButton
local function deleteScript()
    if not deleteArmed then
        deleteArmed=true
        deleteButton.Text="TEKAN LAGI UNTUK HAPUS"
        notify("Tekan Hapus Script sekali lagi untuk konfirmasi",Color3.fromRGB(255,180,80))
        task.delay(3,function()
            if deleteArmed and deleteButton and deleteButton.Parent then deleteArmed=false; deleteButton.Text="HAPUS SCRIPT" end
        end)
        return
    end
    deleteArmed=false
    cleanup()
end
deleteButton=addButton(System,"HAPUS SCRIPT",deleteScript,Color3.fromRGB(190,55,70))
local tabNames={"Movement","Visual","System"}; local tabs={}
for i,name in ipairs(tabNames) do local b=Instance.new("TextButton"); b.Text=name; b.Font=Enum.Font.GothamBold; b.TextSize=11; b.TextColor3=Color3.new(1,1,1); b.BackgroundColor3=Color3.fromRGB(60,50,90); b.Size=UDim2.new(1/3,-4,1,0); b.Position=UDim2.new((i-1)/3,((i-1)*2),0,0); b.Parent=TabBar; Instance.new("UICorner",b).CornerRadius=UDim.new(0,6); tabs[i]=b; b.MouseButton1Click:Connect(function() for j,p in ipairs({Movement,Visual,System}) do p.Visible=(j==i); tabs[j].BackgroundColor3=(j==i) and Color3.fromRGB(115,70,220) or Color3.fromRGB(60,50,90) end end) end
tabs[1].BackgroundColor3=Color3.fromRGB(115,70,220); Movement.Visible=true

-- Drag panel; posisi dipertahankan selama sesi saat G dipakai.
local dragging, dragStart, panelStart
Header.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true; dragStart=input.Position; panelStart=Panel.Position end end)
Header.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
connect(UIS.InputChanged, function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then local d=input.Position-dragStart; Panel.Position=UDim2.new(panelStart.X.Scale,panelStart.X.Offset+d.X,panelStart.Y.Scale,panelStart.Y.Offset+d.Y) end end)

--==============================================================
-- KEYBINDS / LOOPS / CLEANUP
--==============================================================
local visible=true
connect(UIS.InputBegan,function(input,processed)
    if processed or State.Removed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode==Config.ToggleKey then visible=not visible; Gui.Enabled=visible
    elseif input.KeyCode==Config.SpeedKey then toggleSpeed()
    elseif input.KeyCode==Config.JumpKey then toggleJump()
    elseif input.KeyCode==Config.MoonKey then setMoon(not State.MoonOn)
    elseif input.KeyCode==Enum.KeyCode.S then if State.MoonOn then setMoon(false) end
    elseif input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then setCenter(not State.CenterOn)
    elseif input.KeyCode==Config.HideKey then setHide(not State.HideOn)
    elseif input.KeyCode==Config.LightKey then setLight(not State.LightOn)
    elseif input.KeyCode==Enum.KeyCode.K then
        local now=os.clock(); if State.LastK and now-State.LastK<0.45 then State.LastK=nil; TeleportService:Teleport(game.PlaceId,LocalPlayer) else State.LastK=now; notify("Tekan K lagi untuk Rejoin",Color3.fromRGB(120,210,255)) end
    end
    refreshToggleLabels()
end)

connect(LocalPlayer.CharacterAdded,function(char) onCharacter(char) end)
getCharacterParts()
if not Humanoid and Character then
    -- Karakter belum selesai dimuat saat script dijalankan.
    Character:WaitForChild("Humanoid", 5)
    getCharacterParts()
end
if Humanoid then
    captureJumpDefaults(); applySpeed(); applyJump()
end
Tasks.Light = task.spawn(function() while not State.Removed do task.wait(2); if State.LightOn then syncRealLighting(); applyLight() end end end)

cleanup=function()
    if State.Removed then return end
    State.Removed=true
    cancelTask("Light")
    setCenter(false); setMoon(false); setHide(false); setLight(false); setLightweight(false)
    restoreJump()
    State.SpeedOn = false
    State.JumpOn = false
    restoreCharacterDefaults()
    for plr, conn in pairs(playerCharacterConnections) do
        pcall(function() conn:Disconnect() end)
        playerCharacterConnections[plr] = nil
    end
    for _,c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    table.clear(Connections)
    pcall(function() Gui:Destroy() end)
    pcall(function() ToastGui:Destroy() end)
    if _G.__SILAU_V1_CLEANUP__ == cleanup then
        _G.__SILAU_V1_CLEANUP__ = nil
    end
    print("[SILAU V1.3] unload selesai")
end

-- Dibuat dapat dipanggil oleh integrasi executor bila diperlukan.
_G.__SILAU_V1_CLEANUP__ = cleanup

print("[SILAU V1.3] siap — G GUI | Q speed | J jump | F moon | Shift tengah | R hide other player + effects | T cahaya | K×2 rejoin")
