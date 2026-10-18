--========================================================
--  TRAINING SCRIPT v1.0.0 — "OOB LATIHAN"
--  Khusus untuk latihan di oob/obby tertentu.
--
--  FITUR:
--   🌗 Auto Terang  : toggle siang ⇄ malam (keybind B)
--                     - jika siang → jadi malam
--                     - jika malam → jadi siang
--   🏃 SpeedWalk    : keybind Q — cycle 17.25 / 21.25
--   🦘 JumpPower    : keybind J — cycle 51.2 / 65.25
--
--  CATATAN:
--   - TP + Simpan Lokasi sudah ada di script TeleportGui
--     (gunakan GUI itu, keybind F = buka/tutup).
--   - Script ini TIDAK konflik dengan TeleportGui.
--========================================================

local VERSI = "1.0.0"

-- [1] PENGAMAN DASAR ----------------------------------
local RunService = game:GetService("RunService")
if not RunService:IsClient() then
    warn("[TrainingScript] GAGAL: harus jalan di CLIENT (executor / LocalScript), bukan server!")
    return
end
if not game:IsLoaded() then game.Loaded:Wait() end

local Players           = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local Lighting           = game:GetService("Lighting")
local TweenService       = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
if not LocalPlayer then
    warn("[TrainingScript] GAGAL: LocalPlayer belum ada. Masuk ke game dulu, lalu execute ulang.")
    return
end

-- [2] KONFIGURASI — ubah di sini kalau mau ------------
local SPEED_OPTIONS  = { 17.25, 21.25 }   -- cycle WalkSpeed (keybind Q)
local JUMP_OPTIONS   = { 51.2,  65.25 }   -- cycle JumpPower (keybind J)

local KEY_SPEED  = Enum.KeyCode.Q   -- cycle WalkSpeed
local KEY_JUMP   = Enum.KeyCode.J   -- cycle JumpPower
local KEY_BRIGHT = Enum.KeyCode.B   -- toggle siang ⇄ malam

local SIANG_CLOCK       = 12   -- ClockTime saat siang
local MALAM_CLOCK       = 0    -- ClockTime saat malam
local BRIGHTNESS_SIANG  = 2.5
local BRIGHTNESS_MALAM  = 0.3

local TOAST_DURASI = 1.8

-- [3] STATE --------------------------------------------
local state = {
    speedIdx    = 1,
    jumpIdx     = 1,
    paksaSiang  = nil,  -- nil = ikut game, true = paksa siang, false = paksa malam
}

-- [4] TOAST / NOTIF ------------------------------------
local function hapusToastLama()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    for _, g in ipairs(pg:GetChildren()) do
        if g.Name == "TrainingToastGui" then g:Destroy() end
    end
end

local function toast(teks, warna)
    warna = warna or Color3.fromRGB(124, 58, 237)
    print("[Training] " .. teks)
    hapusToastLama()
    pcall(function()
        local pg = LocalPlayer:WaitForChild("PlayerGui")
        local sg = Instance.new("ScreenGui")
        sg.Name = "TrainingToastGui"
        sg.ResetOnSpawn = false
        sg.DisplayOrder = 9998
        sg.IgnoreGuiInset = true
        sg.Parent = pg

        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0)
        f.Position = UDim2.new(0.5, 0, 0, 12)
        f.Size = UDim2.new(0, 320, 0, 36)
        f.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
        f.BackgroundTransparency = 0.05
        f.BorderSizePixel = 0
        f.Parent = sg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = f

        local stroke = Instance.new("UIStroke")
        stroke.Color = warna
        stroke.Thickness = 1.5
        stroke.Transparency = 0.1
        stroke.Parent = f

        local lb = Instance.new("TextLabel")
        lb.BackgroundTransparency = 1
        lb.Position = UDim2.new(0, 10, 0, 0)
        lb.Size = UDim2.new(1, -20, 1, 0)
        lb.Font = Enum.Font.GothamBold
        lb.Text = teks
        lb.TextColor3 = Color3.fromRGB(255, 255, 255)
        lb.TextSize = 14
        lb.TextTruncate = Enum.TextTruncate.AtEnd
        lb.Parent = f

        local sc = Instance.new("UIScale")
        sc.Scale = 0.5
        sc.Parent = f

        TweenService:Create(sc, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(f, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 0.05}):Play()

        task.delay(TOAST_DURASI, function()
            if not sg.Parent then return end
            TweenService:Create(f, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {BackgroundTransparency = 1}):Play()
            TweenService:Create(stroke, TweenInfo.new(0.28), {Transparency = 1}):Play()
            TweenService:Create(lb, TweenInfo.new(0.28), {TextTransparency = 1}):Play()
            TweenService:Create(sc, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 1.15}):Play()
            task.delay(0.32, function() sg:Destroy() end)
        end)
    end)
end

-- [5] HELPER KARAKTER ----------------------------------
local function getHum()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- [6] SPEEDWALK (keybind Q) -----------------------------
local function applySpeed()
    local hum = getHum()
    if not hum then return end
    pcall(function() hum.WalkSpeed = SPEED_OPTIONS[state.speedIdx] end)
end

local function cycleSpeed()
    state.speedIdx = state.speedIdx % #SPEED_OPTIONS + 1
    applySpeed()
    toast(string.format("🏃 WalkSpeed: %.2f", SPEED_OPTIONS[state.speedIdx]),
        Color3.fromRGB(37, 99, 235))
end

-- [7] JUMP POWER (keybind J) ----------------------------
local function applyJump()
    local hum = getHum()
    if not hum then return end
    pcall(function()
        hum.UseJumpPower = true
        hum.JumpPower = JUMP_OPTIONS[state.jumpIdx]
    end)
end

local function cycleJump()
    state.jumpIdx = state.jumpIdx % #JUMP_OPTIONS + 1
    applyJump()
    toast(string.format("🦘 JumpPower: %.2f", JUMP_OPTIONS[state.jumpIdx]),
        Color3.fromRGB(34, 197, 94))
end

-- [8] AUTO TERANG (SIANG ⇄ MALAM, keybind B) -----------
local function applyBrightness()
    if state.paksaSiang == nil then return end
    local targetTime = state.paksaSiang and SIANG_CLOCK or MALAM_CLOCK
    local targetBrt = state.paksaSiang and BRIGHTNESS_SIANG or BRIGHTNESS_MALAM
    pcall(function()
        TweenService:Create(Lighting, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {ClockTime = targetTime, Brightness = targetBrt}):Play()
    end)
end

local function toggleBrightness()
    local currentHour = Lighting.ClockTime or 12
    -- Deteksi: 06:00 - 17:59 dianggap siang
    local saatIniSiang = (currentHour >= 6 and currentHour < 18)
    if saatIniSiang then
        state.paksaSiang = false  -- siang → malam
    else
        state.paksaSiang = true   -- malam → siang
    end
    applyBrightness()
    toast(state.paksaSiang and "🌞 Siang (ClockTime 12)" or "🌙 Malam (ClockTime 0)",
        Color3.fromRGB(250, 204, 21))
end

-- [9] AUTO RE-APPLY SAAT RESPAWN ------------------------
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)
    applySpeed()
    applyJump()
    applyBrightness()  -- kalau game reset Lighting, tetap dipaksa sesuai state
end)

-- Initial apply setelah load
task.spawn(function()
    task.wait(1)
    applySpeed()
    applyJump()
end)

-- [10] KEYBINDS ----------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == KEY_SPEED then
        cycleSpeed()
    elseif input.KeyCode == KEY_JUMP then
        cycleJump()
    elseif input.KeyCode == KEY_BRIGHT then
        toggleBrightness()
    end
end)

-- [11] INFO STARTUP ------------------------------------
print("[TrainingScript v" .. VERSI .. "] SIAP ✔ — khusus latihan oob")
print("[TrainingScript] Keybind:")
print("  Q = cycle WalkSpeed (17.25 / 21.25)")
print("  J = cycle JumpPower (51.2 / 65.25)")
print("  B = toggle siang ⇄ malam (auto-detect)")
print("[TrainingScript] TP + Simpan Lokasi ada di script TeleportGui (keybind F).")
