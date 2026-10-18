--========================================================
--  TRAINING SCRIPT v2.0.0 — "OOB LATIHAN" (VISIBLE HUD)
--  HUD panel SELALU TAMPIL di pojok kanan atas.
--
--  FITUR:
--   🌗 Auto Terang  : toggle siang ⇄ malam (keybind B / klik tombol)
--                     - kalau sekarang siang → jadi malam
--                     - kalau sekarang malam → jadi siang
--   🏃 SpeedWalk    : keybind Q — cycle 17.25 / 21.25 (klik tombol juga bisa)
--   🦘 JumpPower    : keybind J — cycle 51.2 / 65.25 (klik tombol juga bisa)
--
--  CARA PAKAI:
--   1. Execute script ini di executor.
--   2. Panel muncul di pojok kanan atas (bisa di-drag).
--   3. Klik tombol atau tekan Q / J / B.
--   4. RightShift = hide/show HUD.
--
--  KOMPATIBEL dengan script TeleportGui (keybind F untuk TP+save).
--  JALAN BARENG — tidak konflik.
--========================================================

local VERSI = "2.0.0"

-- [1] PENGAMAN DASAR ----------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
    warn("[TrainingScript] GAGAL: harus jalan di CLIENT (executor / LocalScript), bukan server!")
    return
end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local TweenService      = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
if not LocalPlayer then
    warn("[TrainingScript] GAGAL: LocalPlayer belum ada. Masuk ke game dulu, lalu execute ulang.")
    return
end

-- [2] KONFIGURASI — ubah di sini kalau mau ------------
local SPEED_OPTIONS = { 17.25, 21.25 }    -- cycle WalkSpeed (keybind Q)
local JUMP_OPTIONS  = { 51.2,  65.25 }    -- cycle JumpPower (keybind J)

local KEY_SPEED       = Enum.KeyCode.Q          -- cycle WalkSpeed
local KEY_JUMP        = Enum.KeyCode.J          -- cycle JumpPower
local KEY_BRIGHT      = Enum.KeyCode.B          -- toggle siang ⇄ malam
local KEY_TOGGLE_HUD  = Enum.KeyCode.RightShift -- hide/show HUD

local SIANG_CLOCK       = 12   -- ClockTime saat siang
local MALAM_CLOCK       = 0    -- ClockTime saat malam
local BRIGHTNESS_SIANG  = 2.5
local BRIGHTNESS_MALAM  = 0.3

-- [3] STATE --------------------------------------------
local state = {
    speedIdx   = 1,
    jumpIdx    = 1,
    paksaSiang = nil,   -- nil = ikut game, true = paksa siang, false = paksa malam
    hudVisible = true,
}

-- [4] WARNA --------------------------------------------
local Warna = {
    Ungu     = Color3.fromRGB(124, 58, 237),
    UnguMuda = Color3.fromRGB(237, 233, 254),
    Biru     = Color3.fromRGB(37, 99, 235),
    Biru2    = Color3.fromRGB(59, 130, 246),
    BiruMuda = Color3.fromRGB(219, 234, 254),
    Hitam    = Color3.fromRGB(12, 10, 20),
    Hitam2   = Color3.fromRGB(22, 18, 38),
    Putih    = Color3.fromRGB(255, 255, 255),
    AbuTeks  = Color3.fromRGB(160, 155, 185),
    Merah    = Color3.fromRGB(239, 68, 68),
    Hijau    = Color3.fromRGB(34, 197, 94),
    HijauMuda= Color3.fromRGB(187, 247, 208),
    Kuning   = Color3.fromRGB(250, 204, 21),
}

-- [5] FONT HELPER (dengan fallback aman) --------------
local FONT_OK = pcall(function()
    return Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Regular)
end)

local function fnt(jenis)
    if FONT_OK then
        local fams = {
            bold = "rbxasset://fonts/families/Montserrat.json",
            semi = "rbxasset://fonts/families/Montserrat.json",
            med  = "rbxasset://fonts/families/Montserrat.json",
            reg  = "rbxasset://fonts/families/Montserrat.json",
        }
        local wts = {
            bold = Enum.FontWeight.Bold,
            semi = Enum.FontWeight.SemiBold,
            med  = Enum.FontWeight.Medium,
            reg  = Enum.FontWeight.Regular,
        }
        return Font.new(fams[jenis], wts[jenis])
    else
        local legacy = {
            bold = Enum.Font.GothamBold,
            semi = Enum.Font.GothamSemibold,
            med  = Enum.Font.GothamMedium,
            reg  = Enum.Font.Gotham,
        }
        return legacy[jenis]
    end
end

-- [6] HELPER BUAT INSTANCE -----------------------------
local function buat(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k == "FontFace" and not FONT_OK then
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

-- [7] SCREENGUI — pasang di parent aman ---------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TrainingScriptHUD"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9998
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() screenGui.OnTopOfCoreBlur = true end)
pcall(function() screenGui.IgnoreGuiInset = true end)

local function pasangGui()
    local kandidat = {}
    pcall(function() if gethui then table.insert(kandidat, gethui()) end end)
    pcall(function() table.insert(kandidat, game:GetService("CoreGui")) end)
    pcall(function() table.insert(kandidat, LocalPlayer:WaitForChild("PlayerGui", 5)) end)
    for _, t in ipairs(kandidat) do
        if t then
            -- hapus duplikat
            pcall(function()
                local lama = t:FindFirstChild("TrainingScriptHUD")
                if lama and lama ~= screenGui then lama:Destroy() end
            end)
            local ok = pcall(function() screenGui.Parent = t end)
            if ok and screenGui.Parent == t then return true end
        end
    end
    return false
end

if not pasangGui() then
    warn("[TrainingScript] GAGAL: tidak bisa memasang GUI. Executor mungkin terbatas — coba executor lain (Synapse/Krnl/Fluxus/Script-Ware).")
    return
end

-- [8] HUD PANEL ---------------------------------------
local hud = buat("Frame", {
    Size = UDim2.fromOffset(228, 178),
    Position = UDim2.new(1, -240, 0, 12),
    BackgroundColor3 = Warna.Hitam2,
    BorderSizePixel = 0,
    Active = true,
}, screenGui)
buat("UICorner", {CornerRadius = UDim.new(0, 12)}, hud)
buat("UIStroke", {Color = Warna.Ungu, Thickness = 2}, hud)
buat("UIScale", {Scale = 1}, hud)

local hudScale = hud:FindFirstChildOfClass("UIScale")

-- animasi muncul
hudScale.Scale = 0.5
hud.BackgroundTransparency = 0.5
tween(hudScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
tween(hud, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})

-- Header
local hudHeader = buat("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    BackgroundColor3 = Warna.Hitam,
    BorderSizePixel = 0,
}, hud)
buat("UICorner", {CornerRadius = UDim.new(0, 12)}, hudHeader)
buat("Frame", {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.new(0, 0, 0, 16),
    BackgroundColor3 = Warna.Hitam,
    BorderSizePixel = 0,
}, hud)

local hudTitle = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 0),
    Size = UDim2.new(1, -40, 1, 0),
    FontFace = fnt("bold"),
    Text = "🏃 TRAINING OOB",
    TextColor3 = Warna.UnguMuda,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, hudHeader)

-- close / minimize button
local hudClose = buat("TextButton", {
    Size = UDim2.fromOffset(22, 22),
    Position = UDim2.new(1, -26, 0.5, -11),
    BackgroundColor3 = Warna.Merah,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "–",
    TextColor3 = Warna.Putih,
    TextSize = 14,
    AutoButtonColor = false,
}, hudHeader)
buat("UICorner", {CornerRadius = UDim.new(0, 7)}, hudClose)

-- Speed button
local speedBtn = buat("TextButton", {
    Size = UDim2.fromOffset(100, 34),
    Position = UDim2.new(0, 8, 0, 38),
    BackgroundColor3 = Warna.Biru,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🏃 17.25",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, hud)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, speedBtn)
buat("UIStroke", {Color = Warna.Biru2, Thickness = 1, Transparency = 0.4}, speedBtn)

-- Jump button
local jumpBtn = buat("TextButton", {
    Size = UDim2.fromOffset(100, 34),
    Position = UDim2.new(1, -108, 0, 38),
    BackgroundColor3 = Warna.Hijau,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🦘 51.2",
    TextColor3 = Warna.Putih,
    TextSize = 12,
    AutoButtonColor = false,
}, hud)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, jumpBtn)
buat("UIStroke", {Color = Warna.HijauMuda, Thickness = 1, Transparency = 0.4}, jumpBtn)

-- Brightness button (full width)
local brightBtn = buat("TextButton", {
    Size = UDim2.new(1, -16, 0, 34),
    Position = UDim2.new(0, 8, 0, 80),
    BackgroundColor3 = Warna.Kuning,
    BorderSizePixel = 0,
    FontFace = fnt("bold"),
    Text = "🌞 Auto Terang",
    TextColor3 = Warna.Hitam,
    TextSize = 12,
    AutoButtonColor = false,
}, hud)
buat("UICorner", {CornerRadius = UDim.new(0, 8)}, brightBtn)
buat("UIStroke", {Color = Warna.Kuning, Thickness = 1, Transparency = 0.4}, brightBtn)

-- Info / status text
local infoLabel = buat("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 8, 0, 122),
    Size = UDim2.new(1, -16, 0, 48),
    FontFace = fnt("reg"),
    Text = "💡 Q=Speed   J=Jump   B=Terang\n    RightShift = hide/show HUD\n    Klik tombol juga bisa!",
    TextColor3 = Warna.AbuTeks,
    TextSize = 10,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
}, hud)

-- [9] DRAGGABLE HUD -----------------------------------
local dragging, dragStart, startPos = false, nil, nil
hudHeader.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, hud.Position
    end
end)
hudHeader.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        hud.Position = UDim2.new(
            startPos.X.Scale, math.round(startPos.X.Offset + delta.X),
            startPos.Y.Scale, math.round(startPos.Y.Offset + delta.Y)
        )
    end
end)

-- [10] TOAST ------------------------------------------
local function toast(teks, warna)
    warna = warna or Warna.Ungu
    print("[Training] " .. teks)
    pcall(function()
        -- Hapus toast lama
        for _, g in ipairs(screenGui:GetChildren()) do
            if g.Name == "ToastFrame" then g:Destroy() end
        end
        local f = buat("Frame", {
            Name = "ToastFrame",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 0, 60),
            Size = UDim2.new(0, 300, 0, 32),
            BackgroundColor3 = Warna.Hitam,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
        }, screenGui)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, f)
        buat("UIStroke", {Color = warna, Thickness = 1.5, Transparency = 0.1}, f)
        local lb = buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            FontFace = fnt("bold"),
            Text = teks,
            TextColor3 = Warna.Putih,
            TextSize = 13,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, f)
        local sc = buat("UIScale", {Scale = 0.5}, f)
        tween(sc, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
        task.delay(1.6, function()
            if not f.Parent then return end
            tween(f, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
            tween(lb, TweenInfo.new(0.25), {TextTransparency = 1})
            tween(sc, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 1.15})
            task.delay(0.3, function() f:Destroy() end)
        end)
    end)
end

-- [11] HELPER KARAKTER --------------------------------
local function getHum()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- [12] SPEEDWALK --------------------------------------
local function applySpeed()
    local hum = getHum()
    if not hum then return end
    pcall(function() hum.WalkSpeed = SPEED_OPTIONS[state.speedIdx] end)
end

-- [13] JUMP POWER -------------------------------------
local function applyJump()
    local hum = getHum()
    if not hum then return end
    pcall(function()
        hum.UseJumpPower = true
        hum.JumpPower = JUMP_OPTIONS[state.jumpIdx]
    end)
end

-- [14] BRIGHTNESS -------------------------------------
local function applyBrightness()
    if state.paksaSiang == nil then return end
    local targetTime = state.paksaSiang and SIANG_CLOCK or MALAM_CLOCK
    local targetBrt = state.paksaSiang and BRIGHTNESS_SIANG or BRIGHTNESS_MALAM
    pcall(function()
        tween(Lighting, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {ClockTime = targetTime, Brightness = targetBrt})
    end)
end

-- [15] UPDATE UI --------------------------------------
local function updateUI()
    if speedBtn and speedBtn.Parent then
        speedBtn.Text = string.format("🏃 %.2f", SPEED_OPTIONS[state.speedIdx])
    end
    if jumpBtn and jumpBtn.Parent then
        jumpBtn.Text = string.format("🦘 %.2f", JUMP_OPTIONS[state.jumpIdx])
    end
    if brightBtn and brightBtn.Parent then
        if state.paksaSiang == nil then
            brightBtn.Text = "🌞 Auto Terang"
            brightBtn.TextColor3 = Warna.Hitam
        elseif state.paksaSiang then
            brightBtn.Text = "🌞 Paksa Siang"
            brightBtn.TextColor3 = Warna.Hitam
        else
            brightBtn.Text = "🌙 Paksa Malam"
            brightBtn.TextColor3 = Warna.Putih
        end
    end
end

-- [16] CYCLE / TOGGLE ---------------------------------
local function cycleSpeed()
    state.speedIdx = state.speedIdx % #SPEED_OPTIONS + 1
    applySpeed()
    updateUI()
    toast(string.format("🏃 WalkSpeed: %.2f", SPEED_OPTIONS[state.speedIdx]), Warna.Biru)
end

local function cycleJump()
    state.jumpIdx = state.jumpIdx % #JUMP_OPTIONS + 1
    applyJump()
    updateUI()
    toast(string.format("🦘 JumpPower: %.2f", JUMP_OPTIONS[state.jumpIdx]), Warna.Hijau)
end

local function toggleBrightness()
    local currentHour = Lighting.ClockTime or 12
    local saatIniSiang = (currentHour >= 6 and currentHour < 18)
    if saatIniSiang then
        state.paksaSiang = false   -- siang → malam
    else
        state.paksaSiang = true    -- malam → siang
    end
    applyBrightness()
    updateUI()
    toast(state.paksaSiang and "🌞 Paksa Siang (ClockTime 12)" or "🌙 Paksa Malam (ClockTime 0)", Warna.Kuning)
end

-- [17] AUTO RE-APPLY SAAT RESPAWN --------------------
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)
    applySpeed()
    applyJump()
    applyBrightness()
end)

-- Initial apply setelah load
task.spawn(function()
    task.wait(1)
    applySpeed()
    applyJump()
    updateUI()
end)

-- [18] BUTTON CLICKS ---------------------------------
speedBtn.MouseButton1Click:Connect(function() cycleSpeed() end)
jumpBtn.MouseButton1Click:Connect(function() cycleJump() end)
brightBtn.MouseButton1Click:Connect(function() toggleBrightness() end)
hudClose.MouseButton1Click:Connect(function()
    state.hudVisible = not state.hudVisible
    hud.Visible = state.hudVisible
end)

-- [19] HOVER EFFECTS ---------------------------------
local function hoverEffect(btn, target)
    target = target or 1.06
    local sc = buat("UIScale", {Scale = 1}, btn)
    btn.MouseEnter:Connect(function()
        tween(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = target})
    end)
    btn.MouseLeave:Connect(function()
        tween(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
    end)
    btn.MouseButton1Down:Connect(function()
        tween(sc, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = target * 0.9})
    end)
    btn.MouseButton1Up:Connect(function()
        tween(sc, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = target})
    end)
end
hoverEffect(speedBtn)
hoverEffect(jumpBtn)
hoverEffect(brightBtn)
hoverEffect(hudClose, 1.1)

-- [20] KEYBINDS --------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == KEY_SPEED then
        cycleSpeed()
    elseif input.KeyCode == KEY_JUMP then
        cycleJump()
    elseif input.KeyCode == KEY_BRIGHT then
        toggleBrightness()
    elseif input.KeyCode == KEY_TOGGLE_HUD then
        state.hudVisible = not state.hudVisible
        hud.Visible = state.hudVisible
    end
end)

-- [21] INFO STARTUP -----------------------------------
print("==================================================")
print("[TrainingScript v" .. VERSI .. "] SIAP ✔ — khusus latihan oob")
print("[TrainingScript] HUD tampil di pojok kanan atas.")
print("[TrainingScript] Keybind:")
print("  Q = cycle WalkSpeed (17.25 / 21.25)")
print("  J = cycle JumpPower (51.2 / 65.25)")
print("  B = toggle siang ⇄ malam (auto-detect)")
print("  RightShift = hide/show HUD")
print("[TrainingScript] Klik tombol di HUD juga bisa!")
print("[TrainingScript] TP + Simpan Lokasi pakai TeleportGui (keybind F).")
print("==================================================")
