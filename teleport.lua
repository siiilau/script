--==============================================================================
--  FREE CAM + AUTO PAGI + EFEK MATI  •  LocalScript  (REVISI 4)
--  Tempatkan di : StarterPlayer ▸ StarterPlayerScripts
--
--  KONTROL :
--   [F]       Buka / tutup menu
--   [R]       Freecam ON / OFF
--   [T]       Auto Pagi ON / OFF
--   [G]       Kamera menuju karakter (manual saja, opsional)
--   [W A S D] Gerakkan kamera (karakter jalan di tempat)
--   [Q] / [E] Turun / naik
--   [Space]   Tahan untuk mempercepat kamera
--   Mouse     Mengarahkan kamera
--   Drag judul menu untuk memindahkan panel
--
--  LOGIKA REVISI :
--   • Karakter jalan di tempat saat freecam aktif (tidak dibekukan).
--   • TELEPORT SECEPAT CAHAYA :
--       - karakter langsung pindah di frame yang sama (tanpa jeda/luncur)
--       - kalau tujuan TP di udara, karakter MELAYANG di situ dan tetap
--         jalan di tempat (tidak jatuh, tidak ada animasi jatuh)
--       - kamera freecam TIDAK ikut bergerak (tetap kendali pemain)
--   • Mati    -> layar berubah hitam putih.
--   • Respawn -> semua efek & fitur kembali normal (kecuali Auto Pagi).
--==============================================================================

--================================ SERVIS ======================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")

--============================== PEMAIN ========================================
local player    = Players.LocalPlayer
local camera    = Workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

--============================ KONFIGURASI =====================================
local CONFIG = {
    KECEPATAN_NORMAL   = 30,     -- kecepatan kamera biasa (studs/detik)
    KECEPATAN_CEPAT    = 85,     -- kecepatan saat menahan Space
    SENSITIVITAS_MOUSE = 0.25,   -- kepekaan rotasi mouse
    BATAS_PITCH        = 85,     -- batas pandangan atas/bawah (derajat)
    KEHALUSAN          = 10,     -- makin besar = makin responsif (smoothing)
    JAM_PAGI           = 7,      -- jam dunia saat Auto Pagi aktif
    INTERVAL_STREAM    = 1,      -- jeda permintaan streaming (detik)
    DURASI_EFEK_MATI   = 0.6,    -- durasi transisi hitam putih (detik)

    -- [TELEPORT SECEPAT CAHAYA]
    TP_INSTAN     = true,        -- true  : langsung pindah di frame itu juga
                                 -- false : luncur super cepat (nyaris tak terlihat)
    JARAK_TP_MIN  = 6,           -- lompatan horizontal (studs) = dianggap TP
    TINGGI_TP_MIN = 8,           -- lompatan vertikal  (studs) = dianggap TP

    -- (hanya dipakai jika TP_INSTAN = false)
    MELUNCUR_KECEPATAN = 600,    -- studs/detik (super cepat)
    MELUNCUR_MAX       = 0.08,   -- batas durasi luncur (detik) -> nyaris instan

    -- [G] posisi kamera saat tombol manual dipakai
    JARAK_BELAKANG = 10,
    TINGGI_KAMERA  = 4,
    SUDUT_TP       = -15,
}

local NAMA_BIND = "FreecamUpdate"

--============================= STATUS =========================================
local menuTerbuka   = true        -- menu tampil saat script dimulai
local freecamAktif  = false
local autoPagiAktif = false

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
local posisiKunci          = nil   -- titik kunci (X/Z selalu ; XYZ saat melayang)
local rotasiKunci          = nil   -- rotasi kunci (CFrame rotasi murni)
local kunciY               = false -- true = melayang (kunci tinggi juga)
local cfVisual             = nil   -- CFrame visual terakhir karakter
local meluncur             = false -- fallback luncur super cepat
local cfAsal, cfTujuan     = nil, nil
local waktuMulai           = 0
local durasiMeluncur       = 0

-- efek hitam putih
local efekKoreksi     = nil
local tweenEfek       = nil
local hitamPutihAktif = false

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

-- CFrame dengan posisi + rotasi tegak (yaw saja) — dipakai untuk tujuan TP
local function cfTegak(cf)
    local look = cf.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    if flat.Magnitude < 0.001 then
        flat = Vector3.new(0, 0, -1)
    end
    return CFrame.lookAt(cf.Position, cf.Position + flat.Unit)
end

-- netralkan gravitasi & cegah animasi jatuh (dipakai saat melayang / TP)
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
-- Karakter TIDAK di-anchor. Posisi horizontal & rotasinya dikembalikan ke
-- titik awal setiap langkah fisika (jalan di tempat).
--
-- SAAT TELEPORT (oleh game/script lain) :
--   [1] SECEPAT CAHAYA : karakter langsung pindah di frame yang sama,
--       tanpa jeda, tanpa luncuran
--   [2] tujuan di udara -> karakter MELAYANG tepat di titik itu :
--       tinggi ikut dikunci, gravitasi dinetralkan, animasi tetap normal
--   [3] kamera freecam TIDAK disentuh sama sekali

local function mulaiJalanDiTempat()
    if koneksiJalanDiTempat then return end

    -- catat titik kunci dari posisi karakter saat ini (jika sudah ada)
    local root = dapatkanRoot()
    if root then
        posisiKunci = root.Position
        rotasiKunci = root.CFrame - root.CFrame.Position
        cfVisual    = root.CFrame
    end
    kunciY   = false
    meluncur = false

    -- cegah lompatan agar karakter "hanya berjalan" di tempat
    local humanoid = dapatkanHumanoid()
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        humanoid.Jump = false
    end

    koneksiJalanDiTempat = RunService.Stepped:Connect(function()
        local r = dapatkanRoot()
        if not r then return end
        local humanoid = dapatkanHumanoid()

        -- [A] sedang duduk (kursi / TP pad) -> ikuti saja, jangan dikunci
        if humanoid and humanoid.SeatPart then
            posisiKunci = r.Position
            rotasiKunci = r.CFrame - r.CFrame.Position
            cfVisual    = r.CFrame
            return
        end

        -- [B] FALLBACK : luncur super cepat (hanya jika TP_INSTAN = false)
        if meluncur then
            local t  = math.clamp((os.clock() - waktuMulai) / durasiMeluncur, 0, 1)
            local e  = t * t * (3 - 2 * t)          -- smoothstep
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

        -- karakter baru muncul saat freecam aktif -> kunci posisinya sekarang
        if not posisiKunci then
            posisiKunci = r.Position
            rotasiKunci = r.CFrame - r.CFrame.Position
            cfVisual    = r.CFrame
            kunciY      = false
        end

        -- [C] DETEKSI TELEPORT (lompatan posisi sekali jalan)
        local dx = r.Position.X - posisiKunci.X
        local dz = r.Position.Z - posisiKunci.Z
        local teleport =
            (dx * dx + dz * dz) >= (CONFIG.JARAK_TP_MIN * CONFIG.JARAK_TP_MIN)
            or math.abs(r.Position.Y - posisiKunci.Y) >= CONFIG.TINGGI_TP_MIN

        if teleport then
            local tujuan = cfTegak(r.CFrame)

            if CONFIG.TP_INSTAN then
                ------------------------------------------------------------
                -- SECEPAT CAHAYA : langsung pindah di frame ini juga.
                -- Tidak ada jeda, tidak ada peralihan, tidak ada efek.
                ------------------------------------------------------------
                r.CFrame = tujuan
                netralkanFisika(r, humanoid)

                -- kunci penuh di titik TP (kalaupun di udara -> melayang)
                kunciY      = true
                posisiKunci = tujuan.Position
                rotasiKunci = tujuan - tujuan.Position
                cfVisual    = tujuan
            else
                ------------------------------------------------------------
                -- OPSIONAL : luncur super cepat (nyaris tak terlihat)
                ------------------------------------------------------------
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
            -- melayang : kunci tinggi juga -> tetap di udara, tidak jatuh
            cfBaru = CFrame.new(posisiKunci) * rotasiKunci
            netralkanFisika(r, humanoid)
        else
            -- di tanah : Y mengikuti fisika agar tetap berdiri dengan benar
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

    -- aktifkan kembali lompatan & jatuh (karakter berjalan normal lagi)
    local humanoid = dapatkanHumanoid()
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
    end
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

--============================== MENU (GUI) ====================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "FreecamMenuGui"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder   = 100
screenGui.Parent         = playerGui

local panel = Instance.new("Frame")
panel.Name             = "Panel"
panel.Size             = UDim2.fromOffset(230, 210)
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

local tombolFreecam = Instance.new("TextButton")
tombolFreecam.Name             = "TombolFreecam"
tombolFreecam.Size             = UDim2.new(1, -20, 0, 36)
tombolFreecam.Position         = UDim2.new(0, 10, 0, 44)
tombolFreecam.BackgroundColor3 = Color3.fromRGB(150, 70, 70)
tombolFreecam.BorderSizePixel  = 0
tombolFreecam.Font             = Enum.Font.GothamBold
tombolFreecam.TextSize         = 14
tombolFreecam.TextColor3       = Color3.fromRGB(255, 255, 255)
tombolFreecam.Parent           = panel

local freecamSudut = Instance.new("UICorner")
freecamSudut.CornerRadius = UDim.new(0, 8)
freecamSudut.Parent = tombolFreecam

local tombolPagi = tombolFreecam:Clone()
tombolPagi.Name     = "TombolPagi"
tombolPagi.Position = UDim2.new(0, 10, 0, 88)
tombolPagi.Parent   = panel

local tombolKeKarakter = tombolFreecam:Clone()
tombolKeKarakter.Name             = "TombolKeKarakter"
tombolKeKarakter.Position         = UDim2.new(0, 10, 0, 132)
tombolKeKarakter.Text             = "KAMERA ➜ KARAKTER  [G]"
tombolKeKarakter.BackgroundColor3 = Color3.fromRGB(70, 110, 170)
tombolKeKarakter.Parent           = panel

local petunjuk = Instance.new("TextLabel")
petunjuk.Name                   = "Petunjuk"
petunjuk.Size                   = UDim2.new(1, -20, 0, 30)
petunjuk.Position               = UDim2.new(0, 10, 1, -34)
petunjuk.BackgroundTransparency = 1
petunjuk.Font                   = Enum.Font.Gotham
petunjuk.TextSize               = 11
petunjuk.TextColor3             = Color3.fromRGB(160, 160, 180)
petunjuk.TextWrapped            = true
petunjuk.Text                   = "F: Menu • R: Freecam • T: Pagi • G: Ke Karakter"
petunjuk.Parent                 = panel

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
    tombolTekan[input.KeyCode] = true

    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F then
        menuTerbuka = not menuTerbuka
        screenGui.Enabled = menuTerbuka
    elseif input.KeyCode == Enum.KeyCode.R then
        setFreecam(not freecamAktif)
    elseif input.KeyCode == Enum.KeyCode.T then
        setAutoPagi(not autoPagiAktif)
    elseif input.KeyCode == Enum.KeyCode.G then
        kameraKeKarakter()
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
screenGui.Enabled = menuTerbuka
perbaruiTombol()
