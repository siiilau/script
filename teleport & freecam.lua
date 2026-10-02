--==============================================================================
--  FREE CAM + AUTO PAGI + EFEK MATI + TELEPORT  •  LocalScript  (V 1.00.01)
--  Tempatkan di : StarterPlayer ▸ StarterPlayerScripts
--
--  KONTROL :
--   [F]       Buka / tutup menu
--   [X]       Freecam ON / OFF
--   [T]       Auto Pagi ON / OFF
--   [G]       Kamera menuju karakter (manual, opsional)
--   [C]       Teleport karakter ke posisi kamera
--             (syarat: tab KAM TP = ON dan Freecam aktif)
--   [W A S D] Gerakkan kamera (karakter jalan di tempat)
--   [Q] / [E] Turun / naik
--   [Space]   Tahan untuk mempercepat kamera
--   Mouse     Mengarahkan kamera
--   Drag judul menu untuk memindahkan panel
--
--  TAB MENU :
--   • KONTROL : freecam, auto pagi, kamera ke karakter
--   • LOKASI  : simpan / teleport / hapus lokasi
--               -> PERMANEN lewat DataStore (butuh server script
--                  "FreecamLokasiServer" di ServerScriptService)
--   • KAM TP  : toggle ON/OFF teleport-ke-kamera + keybind [C]
--
--  LOGIKA :
--   • Karakter jalan di tempat saat freecam aktif (tidak dibekukan).
--   • TELEPORT DARI GAME : instan, di udara = melayang, kamera tak disentuh.
--   • TELEPORT MANUAL (LOKASI / [C]) : karakter langsung pindah & melayang
--     di titik tujuan; kamera freecam TIDAK ikut bergerak.
--   • Mati -> layar hitam putih. Respawn -> normal kembali (kecuali Auto Pagi).
--==============================================================================

--================================ SERVIS ======================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")
local Workspace          = game:GetService("Workspace")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

--============================== PEMAIN ========================================
local player    = Players.LocalPlayer
local camera    = Workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

--============================ KONFIGURASI =====================================
local CONFIG = {
    KECEPATAN_NORMAL   = 30,
    KECEPATAN_CEPAT    = 85,
    SENSITIVITAS_MOUSE = 0.25,
    BATAS_PITCH        = 85,
    KEHALUSAN          = 10,
    JAM_PAGI           = 7,
    INTERVAL_STREAM    = 1,
    DURASI_EFEK_MATI   = 0.6,

    TP_INSTAN     = true,
    JARAK_TP_MIN  = 6,
    TINGGI_TP_MIN = 8,

    MELUNCUR_KECEPATAN = 600,
    MELUNCUR_MAX       = 0.08,

    JARAK_BELAKANG = 10,
    TINGGI_KAMERA  = 4,
    SUDUT_TP       = -15,

    MAKS_LOKASI        = 50,   -- batas jumlah lokasi tersimpan
}

local NAMA_BIND = "FreecamUpdate"

--============================= STATUS =========================================
local menuTerbuka   = true
local freecamAktif  = false
local autoPagiAktif = false
local tpKameraAktif = false          -- [TAB KAM TP] toggle teleport-ke-kamera

local adaPosisiTersimpan = false
local fcTarget           = Vector3.zero
local yaw, pitch         = 0, 0
local posNow             = Vector3.zero
local yawNow, pitchNow   = 0, 0

local tombolTekan  = {}
local koneksiJam   = nil
local threadStream = nil

-- jalan di tempat + teleport
local koneksiJalanDiTempat = nil
local posisiKunci          = nil
local rotasiKunci          = nil
local kunciY               = false
local cfVisual             = nil
local meluncur             = false
local cfAsal, cfTujuan     = nil, nil
local waktuMulai           = 0
local durasiMeluncur       = 0

-- efek hitam putih
local efekKoreksi     = nil
local tweenEfek       = nil
local hitamPutihAktif = false

-- lokasi tersimpan + sinkronisasi server
local daftarLokasi   = {}
local remoteLokasi   = nil
local perbaruiDaftar -- didefinisikan di bagian GUI
local simpanKeServer -- didefinisikan di bagian GUI

local perbaruiTombol -- didefinisikan di bagian GUI

--============================ HELPER KARAKTER =================================
local function dapatkanRoot()
    local karakter = player.Character
    return karakter and karakter:FindFirstChild("HumanoidRootPart")
end

local function dapatkanHumanoid()
    local karakter = player.Character
    return karakter and karakter:FindFirstChildOfClass("Humanoid")
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
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end

--=============== KAMERA MENUJU KARAKTER (MANUAL - TOMBOL [G]) =================
local function kameraKeKarakter()
    if not freecamAktif then return end
    local root = dapatkanRoot()
    if not root then return end

    local look = root.CFrame.LookVector
    fcTarget = root.Position
        + Vector3.new(0, CONFIG.TINGGI_KAMERA, 0)
        - look * CONFIG.JARAK_BELAKANG

    yaw   = math.deg(math.atan2(-look.X, -look.Z))
    pitch = math.clamp(CONFIG.SUDUT_TP, -CONFIG.BATAS_PITCH, CONFIG.BATAS_PITCH)
    yawNow, pitchNow = yaw, pitch

    if Workspace.StreamingEnabled then
        task.spawn(function()
            pcall(function()
                player:RequestStreamAroundAsync(fcTarget)
            end)
        end)
    end
end

--================== JALAN DI TEMPAT + TELEPORT SECEPAT CAHAYA =================
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

    local humanoid = dapatkanHumanoid()
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        humanoid.Jump = false
    end

    koneksiJalanDiTempat = RunService.Stepped:Connect(function()
        local r = dapatkanRoot()
        if not r then return end
        local humanoid = dapatkanHumanoid()

        -- [A] sedang duduk -> ikuti saja
        if humanoid and humanoid.SeatPart then
            posisiKunci = r.Position
            rotasiKunci = r.CFrame - r.CFrame.Position
            cfVisual    = r.CFrame
            return
        end

        -- [B] FALLBACK luncur super cepat (TP_INSTAN = false)
        if meluncur then
            local t  = math.clamp((os.clock() - waktuMulai) / durasiMeluncur, 0, 1)
            local e  = t * t * (3 - 2 * t)
            local cf = cfAsal:Lerp(cfTujuan, e)

            r.CFrame = cf
            netralkanFisika(r, humanoid)
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

        -- [C] DETEKSI TELEPORT dari game/script lain
        local dx = r.Position.X - posisiKunci.X
        local dz = r.Position.Z - posisiKunci.Z
        local teleport =
            (dx * dx + dz * dz) >= (CONFIG.JARAK_TP_MIN * CONFIG.JARAK_TP_MIN)
            or math.abs(r.Position.Y - posisiKunci.Y) >= CONFIG.TINGGI_TP_MIN

        if teleport then
            local tujuan = cfTegak(r.CFrame)

            if CONFIG.TP_INSTAN then
                r.CFrame = tujuan
                netralkanFisika(r, humanoid)
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
                netralkanFisika(r, humanoid)
            end
            return
        end

        -- [D] NORMAL : kunci posisi & rotasi (jalan di tempat)
        local cfBaru
        if kunciY then
            cfBaru = CFrame.new(posisiKunci) * rotasiKunci
            netralkanFisika(r, humanoid)
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

    local humanoid = dapatkanHumanoid()
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
    end
end

--=========== TELEPORT MANUAL (LOKASI TERSIMPAN & KAMERA [C]) ==================
-- Karakter langsung dipindah, melayang di titik tujuan,
-- kamera freecam tidak disentuh.
local function teleportKarakter(cf)
    local root = dapatkanRoot()
    if not root then return false end

    local humanoid = dapatkanHumanoid()
    if humanoid and humanoid.SeatPart then
        humanoid.Sit = false
    end

    root.CFrame = cf
    netralkanFisika(root, humanoid)

    if freecamAktif then
        kunciY      = true                       -- melayang di titik tujuan
        posisiKunci = cf.Position
        rotasiKunci = cf - cf.Position
        cfVisual    = cf
        meluncur    = false
    end

    if Workspace.StreamingEnabled then
        task.spawn(function()
            pcall(function()
                player:RequestStreamAroundAsync(cf.Position)
            end)
        end)
    end
    return true
end

-- [C] teleport ke posisi kamera freecam
local function teleportKeKamera()
    if not (tpKameraAktif and freecamAktif) then return end
    teleportKarakter(cfTegak(camera.CFrame))
end

-- teleport ke lokasi tersimpan
local function teleportKeLokasi(index)
    local data = daftarLokasi[index]
    if not data then return end

    local rotasi
    local root = dapatkanRoot()
    if root then
        local tegak = cfTegak(root.CFrame)
        rotasi = tegak - tegak.Position
    else
        rotasi = CFrame.new()
    end

    local cf = CFrame.new(Vector3.new(data.x, data.y, data.z)) * rotasi
    teleportKarakter(cf)
end

--====================== EFEK HITAM PUTIH (SAAT MATI) ==========================
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

--====================== UPDATE KAMERA (TIAP FRAME) ============================
local function updateFreecam(dt)
    camera.CameraType = Enum.CameraType.Scriptable
    if menuTerbuka then
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

--========================== MENGAKTIFKAN FREECAM ==============================
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

    RunService:BindToRenderStep(NAMA_BIND, Enum.RenderPriority.Camera.Value + 1, updateFreecam)

    threadStream = task.spawn(function()
        while freecamAktif do
            if Workspace.StreamingEnabled then
                pcall(function()
                    player:RequestStreamAroundAsync(posNow)
                end)
            end
            task.wait(CONFIG.INTERVAL_STREAM)
        end
    end)
end

--========================== MENGHENTIKAN FREECAM ==============================
local function hentikanFreecam()
    if not freecamAktif then return end
    freecamAktif = false

    pcall(function()
        RunService:UnbindFromRenderStep(NAMA_BIND)
    end)

    if threadStream then
        pcall(task.cancel, threadStream)
        threadStream = nil
    end

    hentikanJalanDiTempat()

    camera.CameraType = Enum.CameraType.Custom
    local humanoid = dapatkanHumanoid()
    if humanoid then
        camera.CameraSubject = humanoid
    end

    UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end

--=========================== TOGGLE FREECAM ===================================
local function setFreecam(aktif)
    if aktif then
        mulaiFreecam()
    else
        hentikanFreecam()
    end
    perbaruiTombol()
end

--============================ FITUR AUTO PAGI =================================
local function setAutoPagi(aktif)
    autoPagiAktif = aktif
    if aktif then
        Lighting.ClockTime = CONFIG.JAM_PAGI
        koneksiJam = Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
            if autoPagiAktif and Lighting.ClockTime ~= CONFIG.JAM_PAGI then
                Lighting.ClockTime = CONFIG.JAM_PAGI
            end
        end)
    else
        if koneksiJam then
            koneksiJam:Disconnect()
            koneksiJam = nil
        end
    end
    perbaruiTombol()
end

--=========================== TOGGLE TP KE KAMERA ==============================
local function setTpKamera(aktif)
    tpKameraAktif = aktif
    perbaruiTombol()
end

--============================== MENU (GUI) ====================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "FreecamMenuGui"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder   = 100
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Name             = "Panel"
panel.Size             = UDim2.fromOffset(260, 360)
panel.Position         = UDim2.fromOffset(20, 20)
panel.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
panel.BorderSizePixel  = 0
panel.Active           = true
panel.Parent           = screenGui

local panelSudut = Instance.new("UICorner")
panelSudut.CornerRadius = UDim.new(0, 10)
panelSudut.Parent = panel

local panelGaris = Instance.new("UIStroke")
panelGaris.Color     = Color3.fromRGB(90, 90, 130)
panelGaris.Thickness = 1.5
panelGaris.Parent    = panel

--Judul (drag)
local judul = Instance.new("TextButton")
judul.Name             = "Judul"
judul.Size             = UDim2.new(1, 0, 0, 34)
judul.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
judul.BorderSizePixel  = 0
judul.Text             = "MENU KONTROL"
judul.TextColor3       = Color3.fromRGB(235, 235, 245)
judul.Font             = Enum.Font.GothamBold
judul.TextSize         = 14
judul.AutoButtonColor  = false
judul.Parent           = panel

local judulSudut = Instance.new("UICorner")
judulSudut.CornerRadius = UDim.new(0, 10)
judulSudut.Parent = judul

--------------------------- TAB BAR ---------------------------
local tabBar = Instance.new("Frame")
tabBar.Name                   = "TabBar"
tabBar.Position               = UDim2.new(0, 10, 0, 38)
tabBar.Size                   = UDim2.new(1, -20, 0, 26)
tabBar.BackgroundTransparency = 1
tabBar.Parent                 = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding       = UDim.new(0, 4)
tabLayout.Parent        = tabBar

local WARNA_TAB_AKTIF    = Color3.fromRGB(70, 110, 170)
local WARNA_TAB_NONAKTIF = Color3.fromRGB(40, 40, 60)

local function buatTab(nama, teks)
    local b = Instance.new("TextButton")
    b.Name             = nama
    b.Size             = UDim2.new(1 / 3, -3, 1, 0)
    b.BackgroundColor3 = WARNA_TAB_NONAKTIF
    b.BorderSizePixel  = 0
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 11
    b.TextColor3       = Color3.fromRGB(180, 180, 200)
    b.Text             = teks
    b.AutoButtonColor  = false
    b.Parent           = tabBar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b
    return b
end

local tabKontrol = buatTab("TabKontrol", "KONTROL")
local tabLokasi  = buatTab("TabLokasi",  "LOKASI")
local tabKam     = buatTab("TabKam",     "KAM TP")

--------------------------- HALAMAN ---------------------------
local function buatHalaman(nama)
    local f = Instance.new("Frame")
    f.Name                   = nama
    f.Position               = UDim2.new(0, 10, 0, 72)
    f.Size                   = UDim2.new(1, -20, 1, -80)
    f.BackgroundTransparency = 1
    f.Parent                 = panel
    return f
end

local halamanKontrol = buatHalaman("HalamanKontrol")
local halamanLokasi  = buatHalaman("HalamanLokasi")
local halamanKam     = buatHalaman("HalamanKam")

local function pilihTab(nama)
    halamanKontrol.Visible = (nama == "KONTROL")
    halamanLokasi.Visible  = (nama == "LOKASI")
    halamanKam.Visible     = (nama == "KAMTP")

    tabKontrol.BackgroundColor3 = (nama == "KONTROL") and WARNA_TAB_AKTIF or WARNA_TAB_NONAKTIF
    tabLokasi.BackgroundColor3  = (nama == "LOKASI")  and WARNA_TAB_AKTIF or WARNA_TAB_NONAKTIF
    tabKam.BackgroundColor3     = (nama == "KAMTP")   and WARNA_TAB_AKTIF or WARNA_TAB_NONAKTIF

    tabKontrol.TextColor3 = (nama == "KONTROL") and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,200)
    tabLokasi.TextColor3  = (nama == "LOKASI")  and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,200)
    tabKam.TextColor3     = (nama == "KAMTP")   and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,200)
end

tabKontrol.MouseButton1Click:Connect(function() pilihTab("KONTROL") end)
tabLokasi.MouseButton1Click:Connect(function()  pilihTab("LOKASI")  end)
tabKam.MouseButton1Click:Connect(function()     pilihTab("KAMTP")   end)

--------------------------- HALAMAN : KONTROL ---------------------------
local tombolFreecam = Instance.new("TextButton")
tombolFreecam.Name             = "TombolFreecam"
tombolFreecam.Size             = UDim2.new(1, 0, 0, 36)
tombolFreecam.Position         = UDim2.new(0, 0, 0, 0)
tombolFreecam.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
tombolFreecam.BorderSizePixel  = 0
tombolFreecam.Font             = Enum.Font.GothamBold
tombolFreecam.TextSize         = 14
tombolFreecam.TextColor3       = Color3.fromRGB(255, 255, 255)
tombolFreecam.Parent           = halamanKontrol

local freecamSudut = Instance.new("UICorner")
freecamSudut.CornerRadius = UDim.new(0, 8)
freecamSudut.Parent = tombolFreecam

local tombolPagi = tombolFreecam:Clone()
tombolPagi.Name     = "TombolPagi"
tombolPagi.Position = UDim2.new(0, 0, 0, 42)
tombolPagi.Parent   = halamanKontrol

local tombolKeKarakter = tombolFreecam:Clone()
tombolKeKarakter.Name             = "TombolKeKarakter"
tombolKeKarakter.Position         = UDim2.new(0, 0, 0, 84)
tombolKeKarakter.Text             = "KAMERA ➜ KARAKTER  [G]"
tombolKeKarakter.BackgroundColor3 = Color3.fromRGB(70, 110, 170)
tombolKeKarakter.Parent           = halamanKontrol

local petunjuk = Instance.new("TextLabel")
petunjuk.Name                   = "Petunjuk"
petunjuk.Size                   = UDim2.new(1, 0, 0, 60)
petunjuk.Position               = UDim2.new(0, 0, 0, 128)
petunjuk.BackgroundTransparency = 1
petunjuk.Font                   = Enum.Font.Gotham
petunjuk.TextSize               = 11
petunjuk.TextColor3             = Color3.fromRGB(160, 160, 180)
petunjuk.TextWrapped            = true
petunjuk.Text                   = "F: Menu • X: Freecam • T: Pagi • G: Ke Karakter • C: TP Kamera\nWASD: Gerak • QE: Naik/Turun • Space: Cepat"
petunjuk.Parent                 = halamanKontrol

--------------------------- HALAMAN : LOKASI ---------------------------
local kotakNama = Instance.new("TextBox")
kotakNama.Name              = "KotakNama"
kotakNama.Size              = UDim2.new(1, 0, 0, 30)
kotakNama.BackgroundColor3  = Color3.fromRGB(36, 36, 52)
kotakNama.BorderSizePixel   = 0
kotakNama.PlaceholderText   = "Nama lokasi..."
kotakNama.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
kotakNama.Text              = ""
kotakNama.TextColor3        = Color3.fromRGB(235, 235, 245)
kotakNama.Font              = Enum.Font.Gotham
kotakNama.TextSize          = 13
kotakNama.ClearTextOnFocus  = false
kotakNama.Parent            = halamanLokasi

local kotakSudut = Instance.new("UICorner")
kotakSudut.CornerRadius = UDim.new(0, 8)
kotakSudut.Parent = kotakNama

local tombolSimpanLokasi = Instance.new("TextButton")
tombolSimpanLokasi.Name             = "TombolSimpanLokasi"
tombolSimpanLokasi.Size             = UDim2.new(1, 0, 0, 30)
tombolSimpanLokasi.Position         = UDim2.new(0, 0, 0, 36)
tombolSimpanLokasi.BackgroundColor3 = Color3.fromRGB(46, 155, 90)
tombolSimpanLokasi.BorderSizePixel  = 0
tombolSimpanLokasi.Font             = Enum.Font.GothamBold
tombolSimpanLokasi.TextSize         = 13
tombolSimpanLokasi.TextColor3       = Color3.fromRGB(255, 255, 255)
tombolSimpanLokasi.Text             = "💾 SIMPAN LOKASI"
tombolSimpanLokasi.Parent           = halamanLokasi

local simpanSudut = Instance.new("UICorner")
simpanSudut.CornerRadius = UDim.new(0, 8)
simpanSudut.Parent = tombolSimpanLokasi

local statusSinkron = Instance.new("TextLabel")
statusSinkron.Name                   = "StatusSinkron"
statusSinkron.Size                   = UDim2.new(1, 0, 0, 14)
statusSinkron.Position               = UDim2.new(0, 0, 0, 70)
statusSinkron.BackgroundTransparency = 1
statusSinkron.Font                   = Enum.Font.Gotham
statusSinkron.TextSize               = 10
statusSinkron.TextColor3             = Color3.fromRGB(160, 160, 180)
statusSinkron.TextXAlignment         = Enum.TextXAlignment.Left
statusSinkron.Text                   = "Memeriksa penyimpanan..."
statusSinkron.Parent                 = halamanLokasi

local daftarScroll = Instance.new("ScrollingFrame")
daftarScroll.Name                   = "DaftarLokasi"
daftarScroll.Position               = UDim2.new(0, 0, 0, 88)
daftarScroll.Size                   = UDim2.new(1, 0, 1, -88)
daftarScroll.BackgroundColor3       = Color3.fromRGB(28, 28, 40)
daftarScroll.BorderSizePixel        = 0
daftarScroll.ScrollBarThickness     = 4
daftarScroll.ScrollingDirection     = Enum.ScrollingDirection.Y
daftarScroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
daftarScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
daftarScroll.ClipsDescendants       = true
daftarScroll.Parent                 = halamanLokasi

local daftarSudut = Instance.new("UICorner")
daftarSudut.CornerRadius = UDim.new(0, 8)
daftarSudut.Parent = daftarScroll

local daftarLayout = Instance.new("UIListLayout")
daftarLayout.Padding    = UDim.new(0, 4)
daftarLayout.SortOrder  = Enum.SortOrder.LayoutOrder
daftarLayout.Parent     = daftarScroll

local daftarPadding = Instance.new("UIPadding")
daftarPadding.PaddingTop    = UDim.new(0, 4)
daftarPadding.PaddingBottom = UDim.new(0, 4)
daftarPadding.PaddingLeft   = UDim.new(0, 2)
daftarPadding.PaddingRight  = UDim.new(0, 2)
daftarPadding.Parent        = daftarScroll

local function setStatus(teks)
    statusSinkron.Text = teks
end

local function buatBarisLokasi(index, data)
    local baris = Instance.new("Frame")
    baris.Size             = UDim2.new(1, -4, 0, 28)
    baris.BackgroundColor3 = Color3.fromRGB(44, 44, 62)
    baris.BorderSizePixel  = 0
    baris.LayoutOrder      = index
    baris.Parent           = daftarScroll

    local barisSudut = Instance.new("UICorner")
    barisSudut.CornerRadius = UDim.new(0, 6)
    barisSudut.Parent = baris

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -84, 1, 0)
    lbl.Position         = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 12
    lbl.TextColor3       = Color3.fromRGB(220, 220, 235)
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.TextTruncate     = Enum.TextTruncate.AtEnd
    lbl.Text             = data.n
    lbl.Parent           = baris

    local bTp = Instance.new("TextButton")
    bTp.Size             = UDim2.new(0, 40, 1, -8)
    bTp.Position         = UDim2.new(1, -76, 0, 4)
    bTp.BackgroundColor3 = Color3.fromRGB(46, 155, 90)
    bTp.BorderSizePixel  = 0
    bTp.Font             = Enum.Font.GothamBold
    bTp.TextSize         = 11
    bTp.TextColor3       = Color3.fromRGB(255, 255, 255)
    bTp.Text             = "TP"
    bTp.Parent           = baris

    local bTpSudut = Instance.new("UICorner")
    bTpSudut.CornerRadius = UDim.new(0, 5)
    bTpSudut.Parent = bTp

    bTp.MouseButton1Click:Connect(function()
        teleportKeLokasi(index)
    end)

    local bHapus = Instance.new("TextButton")
    bHapus.Size             = UDim2.new(0, 24, 1, -8)
    bHapus.Position         = UDim2.new(1, -28, 0, 4)
    bHapus.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
    bHapus.BorderSizePixel  = 0
    bHapus.Font             = Enum.Font.GothamBold
    bHapus.TextSize         = 11
    bHapus.TextColor3       = Color3.fromRGB(255, 255, 255)
    bHapus.Text             = "✕"
    bHapus.Parent           = baris

    local bHapusSudut = Instance.new("UICorner")
    bHapusSudut.CornerRadius = UDim.new(0, 5)
    bHapusSudut.Parent = bHapus

    bHapus.MouseButton1Click:Connect(function()
        table.remove(daftarLokasi, index)
        perbaruiDaftar()
        simpanKeServer()
    end)
end

perbaruiDaftar = function()
    for _, anak in ipairs(daftarScroll:GetChildren()) do
        if anak:IsA("Frame") then
            anak:Destroy()
        end
    end
    for i, data in ipairs(daftarLokasi) do
        buatBarisLokasi(i, data)
    end
end

simpanKeServer = function()
    if not remoteLokasi then
        setStatus("⚠ Server script belum terpasang — hanya sesi ini")
        return
    end
    setStatus("Menyimpan...")

    local salinan = {}
    for i, v in ipairs(daftarLokasi) do
        salinan[i] = { n = v.n, x = v.x, y = v.y, z = v.z }
    end

    task.spawn(function()
        local ok, hasil = pcall(function()
            return remoteLokasi:InvokeServer("simpan", salinan)
        end)
        if ok and hasil == true then
            setStatus("✓ Tersimpan permanen")
        else
            setStatus("✗ Gagal menyimpan ke server")
        end
    end)
end

tombolSimpanLokasi.MouseButton1Click:Connect(function()
    local pos
    if freecamAktif then
        pos = posNow                                  -- simpan posisi kamera
    else
        local root = dapatkanRoot()
        if not root then
            setStatus("✗ Karakter tidak ditemukan")
            return
        end
        pos = root.Position                           -- simpan posisi karakter
    end

    if #daftarLokasi >= CONFIG.MAKS_LOKASI then
        setStatus("✗ Maksimal " .. CONFIG.MAKS_LOKASI .. " lokasi")
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

--------------------------- HALAMAN : KAM TP ---------------------------
local tombolTpKamera = Instance.new("TextButton")
tombolTpKamera.Name             = "TombolTpKamera"
tombolTpKamera.Size             = UDim2.new(1, 0, 0, 36)
tombolTpKamera.Position         = UDim2.new(0, 0, 0, 0)
tombolTpKamera.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
tombolTpKamera.BorderSizePixel  = 0
tombolTpKamera.Font             = Enum.Font.GothamBold
tombolTpKamera.TextSize         = 14
tombolTpKamera.TextColor3       = Color3.fromRGB(255, 255, 255)
tombolTpKamera.Parent           = halamanKam

local tpSudut = Instance.new("UICorner")
tpSudut.CornerRadius = UDim.new(0, 8)
tpSudut.Parent = tombolTpKamera

local penjelasanKam = Instance.new("TextLabel")
penjelasanKam.Name                   = "Penjelasan"
penjelasanKam.Size                   = UDim2.new(1, 0, 0, 80)
penjelasanKam.Position               = UDim2.new(0, 0, 0, 44)
penjelasanKam.BackgroundTransparency = 1
penjelasanKam.Font                   = Enum.Font.Gotham
penjelasanKam.TextSize               = 11
penjelasanKam.TextColor3             = Color3.fromRGB(160, 160, 180)
penjelasanKam.TextWrapped            = true
penjelasanKam.TextXAlignment         = Enum.TextXAlignment.Left
penjelasanKam.TextYAlignment         = Enum.TextYAlignment.Top
penjelasanKam.Text                   = "ON + Freecam aktif → tekan [C] untuk memindahkan karakter ke posisi kamera.\n\nJika titik berada di udara, karakter akan melayang di situ. Kamera tidak ikut bergerak."
penjelasanKam.Parent                 = halamanKam

tombolTpKamera.MouseButton1Click:Connect(function()
    setTpKamera(not tpKameraAktif)
end)

--=========================== STATUS TOMBOL ====================================
function perbaruiTombol()
    if freecamAktif then
        tombolFreecam.Text             = "FREE CAM : ON"
        tombolFreecam.BackgroundColor3 = Color3.fromRGB(46, 155, 90)
    else
        tombolFreecam.Text             = "FREE CAM : OFF"
        tombolFreecam.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
    end

    if autoPagiAktif then
        tombolPagi.Text             = "AUTO PAGI : ON"
        tombolPagi.BackgroundColor3 = Color3.fromRGB(46, 155, 90)
    else
        tombolPagi.Text             = "AUTO PAGI : OFF"
        tombolPagi.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
    end

    if tpKameraAktif then
        tombolTpKamera.Text             = "TP KE KAMERA [C] : ON"
        tombolTpKamera.BackgroundColor3 = Color3.fromRGB(46, 155, 90)
    else
        tombolTpKamera.Text             = "TP KE KAMERA [C] : OFF"
        tombolTpKamera.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
    end
end

tombolFreecam.MouseButton1Click:Connect(function()
    setFreecam(not freecamAktif)
end)

tombolPagi.MouseButton1Click:Connect(function()
    setAutoPagi(not autoPagiAktif)
end)

tombolKeKarakter.MouseButton1Click:Connect(function()
    kameraKeKarakter()
end)

--========================== MENGGESER MENU ====================================
local sedangGeser     = false
local titikSentuh     = nil
local posisiPanelAwal = nil

judul.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        sedangGeser     = true
        titikSentuh     = input.Position
        posisiPanelAwal = panel.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                sedangGeser = false
            end
        end)
    end
end)

--========================= MEMBACA INPUT ======================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if not gameProcessed then
        tombolTekan[input.KeyCode] = true
    end

    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F then
        menuTerbuka = not menuTerbuka
        screenGui.Enabled = menuTerbuka
    elseif input.KeyCode == Enum.KeyCode.X then
        setFreecam(not freecamAktif)
    elseif input.KeyCode == Enum.KeyCode.T then
        setAutoPagi(not autoPagiAktif)
    elseif input.KeyCode == Enum.KeyCode.G then
        kameraKeKarakter()
    elseif input.KeyCode == Enum.KeyCode.C then
        teleportKeKamera()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        tombolTekan[input.KeyCode] = nil
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if sedangGeser
    and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - titikSentuh
        panel.Position = UDim2.new(
            posisiPanelAwal.X.Scale, posisiPanelAwal.X.Offset + delta.X,
            posisiPanelAwal.Y.Scale, posisiPanelAwal.Y.Offset + delta.Y
        )
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
    and freecamAktif and not menuTerbuka then
        local delta = input.Delta
        yaw   = yaw   - delta.X * CONFIG.SENSITIVITAS_MOUSE
        pitch = math.clamp(pitch - delta.Y * CONFIG.SENSITIVITAS_MOUSE, -CONFIG.BATAS_PITCH, CONFIG.BATAS_PITCH)
    end
end)

UserInputService.WindowFocusReleased:Connect(function()
    table.clear(tombolTekan)
end)

--====================== TANGANI MATI / RESPAWN ================================
local function pantauKarakter(karakter)
    local humanoid = karakter:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.Died:Connect(function()
            setFreecam(false)
            setHitamPutih(true)
        end)
    end
end

player.CharacterAdded:Connect(function(karakter)
    setFreecam(false)
    setHitamPutih(false)
    pantauKarakter(karakter)
end)

if player.Character then
    pantauKarakter(player.Character)
end

--====================== JAGA REFERENSI KAMERA =================================
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Workspace.CurrentCamera then
        camera = Workspace.CurrentCamera
        if freecamAktif then
            camera.CameraType = Enum.CameraType.Scriptable
        end
    end
end)

--=========================== INISIALISASI =====================================
pilihTab("KONTROL")
perbaruiDaftar()
screenGui.Enabled = menuTerbuka
perbaruiTombol()

-- muat lokasi tersimpan dari server (DataStore)
task.spawn(function()
    remoteLokasi = ReplicatedStorage:WaitForChild("FreecamLokasiRemote", 10)

    if remoteLokasi then
        local ok, data = pcall(function()
            return remoteLokasi:InvokeServer("muat")
        end)
        if ok and type(data) == "table" then
            daftarLokasi = data
            setStatus("✓ " .. #daftarLokasi .. " lokasi dimuat")
        else
            setStatus("✗ Gagal memuat lokasi")
        end
    else
        setStatus("⚠ Tanpa server script — simpan hanya sesi ini")
    end
    perbaruiDaftar()
end)
