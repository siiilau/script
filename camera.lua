--[[
        ═══════════════════════════════════════════════
          CAMERA · v1.0.8  —  ALL-IN-ONE CINEMATIC CAMERA
          CINEMATIC + FOTO (v12) · FREE/PRO + TARGET LOCK (v11) · RACE CAM
        ═══════════════════════════════════════════════
          1/2/3/4  = FREE · PRO · CINEMATIC · RACE (tekan lagi = mati)
          CapsLock = MASTER keybind kamera ON/OFF (F·Z·K·J tetap hidup)
          F = panel · M = mode foto · T = lock target · C = teleport layar
          Z = cahaya auto · J = gerak/beku patung · H = sembunyikan UI
          K 2x = hapus script · RMB = lihat sekeliling · Scroll = FOV/zoom
          Space tahan = turbo (FREE) · Ctrl = slow cinematic (FREE)
          v1.0.8 — TRANSISI SHOT CINE CUT LANGSUNG (blur antar shot OFF)
          LENSA CINE diatur sendiri: slider MIN & MAX di panel (30-100°),
          default 30-70° · shot jauh: DRONE · PULL REVEAL · TELE SNIPER
          TANPA notifikasi popup sama sekali — status jalan: console eksekutor
          Efek client-side · aman di-execute ulang (auto bersihkan versi lama)
        ═══════════════════════════════════════════════
]]

-- ═══════════════ ANTI DUPLIKAT ═══════════════
if _G.CAMERA_V101_UNLOAD then
        pcall(_G.CAMERA_V101_UNLOAD)
end
if _G.SIIILAU_CAM_UNLOAD then
        pcall(_G.SIIILAU_CAM_UNLOAD) -- bersihkan sisa versi lama (SIIILAU)
end
task.wait(0.05)

-- v1.0.8: DEBUG breadcrumb — muncul di CONSOLE eksekutor (bukan di layar game)
local DBGWARN = true -- ubah ke false kalau tidak mau log console
local function dbg(tag)
        if DBGWARN then
                warn("[CAM v1.0.8] " .. tag)
        end
end
dbg("1: script mulai dijalankan")

-- ═══════════════ SERVICES ═══════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ═══════════════ KONFIG & TEMA NEON ═══════════════
local CFG = {
        Speed     = 45,   -- kecepatan free cam (stud/s)
        FOV       = 70,   -- FOV free/pro cam
        TeleDist  = 7,    -- jarak teleport di belakang layar (langkah)
        CineTempo = 5.5,  -- durasi rata-rata tiap shot sinematik (detik)
        CineSoft  = 14,   -- kelembutan koreksi anti-temboss DALAM shot: kamera menyusul posisi aman tanpa menyentak
        DistDekat = 0.8,  -- pengali jarak shot saat subjek diam/pelan (kamera mendekat — sinematik)
        DistJauh  = 1.45, -- pengali jarak shot saat lari/ngebut (kamera menjauh otomatis — lega)
        CrowdRadius = 24, -- radius deteksi kerumunan → pilih shot WIDE & kamera mundur otomatis
        Letterbox = true, -- letterbox bioskop otomatis di SEMUA mode kamera
        AntiClip  = true, -- anti-temboss: CINE/RACE penuh (dinding+tanah) · FREE/PRO tanah saja (dinding bebas, anti getar)
        CRPass    = true, -- CINE/RACE: benda KECIL bisa ditembus kamera (plang kayu, papan, karakter lain, mobil) — dinding besar tetap menahan
        CRSmall   = 4,    -- sisi terpanjang < ini (stud) = benda kecil → kamera bisa melewatinya
        CRThin    = 1.1,  -- benda pipih (sisi tengah < ini: papan/plang/tiang/kabel) → tetap bisa ditembus walau agak panjang
        Anchor    = true,  -- karakter beku TOTAL saat kamera/CapsLock on (toggle SISTEM)
        Smoothness    = 0.12,  -- kehalusan gerak free cam (makin kecil = makin responsif)
        FreeLook      = 0.045, -- FREE: kelembutan gerakan mouse RMB (putaran larut, anti sentak)
        ProVelH       = 0.16,  -- PRO: kelembutan ikut LAJU horizontal (feed-forward — maju konstan = mulus penuh)
        ProLook       = 0.05,  -- PRO: kelembutan gerakan mouse RMB (putaran kamera anti sentak)
        ProZoom       = 0.14,  -- PRO: kelembutan scroll zoom (jarak berubah larut, tidak melompat)
        ProPos        = 0.08,  -- PRO: kelembutan posisi kamera akhir (koreksi tanah ikut larut, tak terlihat)
        ProFinal      = 0.035, -- PRO: penghalus rotasi terakhir (jaring pengaman anti getar 1 frame)
        TurboMult     = 3,     -- pengali kecepatan turbo (tahan Space)
        SlowMult      = 0.25,  -- pengali kecepatan slow (Ctrl)
        ModeBlend     = 0.5,   -- masuk / pindah antar mode kamera (1/2/3/4)
        ExitBlend     = 0.45,  -- keluar mode: balik ke kamera normal dgn glide halus
        ShotBlur      = 0,     -- CUT LANGSUNG antar shot (v1.0.8; bisa dinyalakan lagi di panel SISTEM)
        LensPool      = true,  -- FOV tiap shot bervariasi (bobot cerdas) — dibatasi slider LENSA CINE
        CineFovMin    = 30,    -- LENSA CINE MIN (slider 30-100°) — v1.0.8
        CineFovMax    = 70,    -- LENSA CINE MAX (slider 30-100°) — v1.0.8
        FarShots      = true,  -- shot jarak jauh 30-120 stud (drone · tele sniper) aktif
        MouseSens     = 0.25,  -- sensitivitas RMB look
        SelfFlyDist   = 8,     -- jarak kamera mendarat di belakang karakter (KE KARAKTER)
        SelfFlyHeight = 2.4,   -- tinggi kamera di atas kepala (KE KARAKTER)
        AimYDamp      = 1.3,   -- FREE: damping aim vertikal (makin besar = makin lembut, boleh sedikit terlambat)
        ProSnap       = 12,    -- PRO: batas kejar cepat kalau selisih besar (>40 = teleport, langsung ikut)
        ProVelV       = 0.32,  -- PRO: kelembutan laju vertikal (lompat/jatuh terasa melayang lembut)
        ProVelYMax    = 42,    -- PRO: batas laju vertikal yang diikuti (jatuh mendadak tak menjatuhkan kamera)
        ProErr        = 0.30,  -- PRO: koreksi selisih posisi standar (sangat lembut, tak terlihat)
        ProErrFast    = 0.10,  -- PRO: koreksi saat selisih besar (kejar cepat TANPA lompatan)
        JamMalamMulai   = 18,     -- jam mulai malam
        JamMalamAkhir   = 6,      -- jam akhir malam
        ClockTerangi    = 14,     -- ClockTime target saat malam diterangi
        BrightTerangi   = 2.5,    -- Brightness target saat malam
        AmbientTerangi  = Color3.fromRGB(140, 140, 165),
        ClockAntiSilau  = 17.5,   -- ClockTime target saat siang (senja lembut)
        BrightAntiSilau = 1.6,    -- Brightness target saat siang (anti silau)
        AmbientLembut   = Color3.fromRGB(110, 110, 120),
        FogBuka         = 100000, -- buka fog gelap saat cahaya auto nyala
        CineStabG = 4.5,  -- stabilizer vertikal sinematik saat grounded (makin kecil = makin lembut)
        CineStabA = 1.1,  -- stabilizer saat di udara (lompat/jatuh → kamera mengikuti pelan & halus)
        Neon1   = Color3.fromRGB(0, 255, 240),  -- cyan
        Neon2   = Color3.fromRGB(255, 45, 170), -- magenta
        BG      = Color3.fromRGB(12, 12, 24),
        BGCard  = Color3.fromRGB(20, 20, 38),
        TXT     = Color3.fromRGB(236, 236, 255),
        TXT_DIM = Color3.fromRGB(132, 134, 168),
        DANGER  = Color3.fromRGB(255, 72, 96),
}

-- ═══════════════ STATE ═══════════════
local S = {
        mode = "NONE", -- NONE | FREE | PRO | CINE
        master = false,       -- CapsLock MASTER fitur kamera: false = keybind kamera mati (F/Z/K/J tetap hidup)
        gerakMode = nil,      -- tombol J: nil = otomatis · "GERAK" = boleh jalan · "BEKU" = diam total
        lastMode = "NONE",    -- mode terakhir yang dipakai
        panelOpen = true,
        uiHidden = false,
        rmb = false,
        ctrlDown = false,
        turbo = false,
        lastK = 0,
        freePos = Vector3.new(0, 0, 0),
        freeVel = Vector3.new(0, 0, 0),
        aimY = nil,
        fly = nil,
        yaw = 0,
        pitch = -0.14,
        yawT = 0,            -- TARGET yaw dari mouse (dihaluskan ke yaw aktual — anti sentak)
        pitchT = -0.14,      -- TARGET pitch dari mouse
        proYaw = 0,
        proPitch = 0.24,
        proDist = 14,
        proPos = nil,
        proPivot = nil,
        proGlide = nil,
        proYawT = 0,         -- TARGET yaw dari mouse RMB (dihaluskan — sumber hentakan dicabut)
        proPitchT = 0.24,    -- TARGET pitch dari mouse RMB
        proDistT = 14,       -- TARGET jarak dari scroll zoom (dihaluskan — zoom larut)
        proPivotVel = Vector3.new(0, 0, 0), -- LAJU pivot tersimulasi (feed-forward — inti kehalusan PRO)
        proCF = nil,         -- CFrame terakhir → penghalus rotasi terakhir
        locked = false,
        lockPlayer = nil,
        selected = nil,
        lockMode = "TERDEKAT", -- TERDEKAT | AUTO | PILIH
        cineStabY = nil,
        cineStabChar = nil,
        fotoFocus = nil,
        cine = {
                def = nil,
                name = "",
                P = {},
                t = 0,
                dur = 5,
                lastName = "",
                char = nil,
                dofK = 0,
                focusDist = 10,
                smCf = nil,      -- pose terhalus terakhir (koreksi dinding tak menyentak DALAM shot)
                distK = nil,     -- pengali jarak adaptif (diam = dekat · ngebut = jauh), dihaluskan
        },
        race = {
                def = nil,
                name = "",
                P = {},
                t = 0,
                dur = 5,
                lastName = "",
                char = nil,
                dofK = 0,
                focusDist = 10,
                lastFwd = nil,
                turn = 0,
                smCf = nil,      -- koreksi dinding lembut DALAM shot balap
                distK = nil,     -- pengali jarak adaptif balap (pelan = dekat · ngebut = jauh)
        },
        foto = {
                filter = "OFF",
                dof = false,
                focus = 14,
                blur = 65,
                ratio = "FULL",
                wm = false,
        },
        fotoAktif = false, -- layer MODE FOTO (M) aktif → letterbox ikut tampil
        lightOn = false,
        lightPernahAktif = false,
        lightConn = nil,   -- loop penjaga cahaya
        oLight = nil,      -- nilai lighting asli (disimpan saat ON)
        savedCam = nil,
        trans = nil,         -- mesin blending perpindahan mode (update 0.3)
        exitGlide = nil,     -- glide halus balik ke kamera normal saat mode off
        shooting = false,
}

local keys = {}        -- status tombol gerak
local unloadDone = false -- guard anchor: berhenti saat script sudah dihapus
local CONNS = {}       -- koneksi (dibersihkan saat unload)
local boundSpace = false
local UI = {}          -- referensi elemen UI
local DOF              -- DepthOfFieldEffect (dipakai cine + foto)
local DOF_TRANS        -- DepthOfFieldEffect transisi defokus antar shot (update 0.4)
local PHOTO_CC         -- ColorCorrectionEffect (filter foto)
local PHOTO_BLOOM      -- BloomEffect (filter tertentu)

-- ═══════════════ DEKLARASI MAJU ═══════════════
local notify, flash, setAnchorState, updateChip, applyLetterbox, applyDof
local applyUIVisibility, togglePanel, toggleHideUI
local setMode, toggleLock, doTeleport, toggleCahaya, matikanCahaya, goToSelf, resetScript, unloadAll
local getSubjectChar, refreshTargetList, refreshModeUI, updateLockBtn
local setFilter, setRatio, takePhoto, setWatermark
local updateRatioMasks
local findNearestPlayer, lockPick, lockAutoToggle, setMaster, toggleGerak

-- ═══════════════ UTIL ═══════════════
local function flat(v)
        return Vector3.new(v.X, 0, v.Z)
end

local function flatUnit(v)
        local f = flat(v)
        if f.Magnitude < 0.01 then
                return Vector3.new(0, 0, 0)
        end
        return f.Unit
end

local function rotY(v, a)
        local c, s = math.cos(a), math.sin(a)
        return Vector3.new(v.X * c + v.Z * s, 0, -v.X * s + v.Z * c)
end

local function expLerp(a, b, dt, k)
        return a + (b - a) * (1 - math.exp(-k * dt))
end

local function rr(a, b)
        return a + math.random() * (b - a)
end

local function getCharOf(p)
        if p and p.Parent then
                return p.Character
        end
        return nil
end

local function getRoot(c)
        if c then
                return c:FindFirstChild("HumanoidRootPart")
        end
        return nil
end

local function getHum(c)
        if c then
                return c:FindFirstChildOfClass("Humanoid")
        end
        return nil
end

local function myChar()
        return LP.Character
end

local function closeDof(d, range)
        return math.clamp((13 - d) / (range or 4), 0, 1)
end

-- ═══════════════ POST EFFECTS (client-side) ═══════════════
DOF = Instance.new("DepthOfFieldEffect")
DOF.Name = "CAMERA_DOF"
DOF.Enabled = false
DOF.NearIntensity = 0
DOF.FarIntensity = 0.35
DOF.FocusDistance = 12
DOF.InFocusRadius = 7
DOF.Parent = Lighting

PHOTO_CC = Instance.new("ColorCorrectionEffect")
PHOTO_CC.Name = "CAMERA_FOTO_CC"
PHOTO_CC.Enabled = false
PHOTO_CC.Parent = Lighting

PHOTO_BLOOM = Instance.new("BloomEffect")
PHOTO_BLOOM.Name = "CAMERA_FOTO_BLOOM"
PHOTO_BLOOM.Enabled = false
PHOTO_BLOOM.Intensity = 0.3
PHOTO_BLOOM.Size = 24
PHOTO_BLOOM.Threshold = 0.85
PHOTO_BLOOM.Parent = Lighting

-- v1.0.8 FIX: hanya properti DepthOfFieldEffect yang ASLI di Roblox —
-- 2 properti DOF tidak resmi dihapus (penyebab v1.0.4-6 mati total sebelum GUI)
DOF_TRANS = Instance.new("DepthOfFieldEffect")
pcall(function()
        DOF_TRANS.Name = "CAMERA_DOF_TRANS"
        DOF_TRANS.Enabled = false
        DOF_TRANS.NearIntensity = 0
        DOF_TRANS.FarIntensity = 0
        DOF_TRANS.FocusDistance = 0.05
        DOF_TRANS.FocusDistanceRange = NumberRange.new(0, 0)
        DOF_TRANS.InFocusRadius = 0
end)
DOF_TRANS.Parent = Lighting
dbg("2: efek lighting siap")

-- ═══════════════ GUI ROOT ═══════════════
local function findGuiParent()
        local cands = {}
        local okH, hui = pcall(function()
                if type(gethui) == "function" then
                        return gethui()
                end
                return nil
        end)
        if okH and hui then
                table.insert(cands, hui)
        end
        local okC, cg = pcall(function()
                return game:GetService("CoreGui")
        end)
        if okC and cg then
                table.insert(cands, cg)
        end
        table.insert(cands, LP:WaitForChild("PlayerGui"))
        for _, par in ipairs(cands) do
                local probe = Instance.new("Folder")
                local ok = pcall(function()
                        probe.Parent = par
                end)
                probe:Destroy()
                if ok then
                        return par
                end
        end
        return LP:WaitForChild("PlayerGui")
end

do
        local names = { "CAMERA_v1_0_1", "SIIILAU_v1_01", "SIIILAUxCAMERAPRO", "SIIILAU_GALAXY_CAM" }
        local cands = {}
        local okH, hui = pcall(function()
                if type(gethui) == "function" then
                        return gethui()
                end
                return nil
        end)
        if okH and hui then
                table.insert(cands, hui)
        end
        local okC, cg = pcall(function()
                return game:GetService("CoreGui")
        end)
        if okC and cg then
                table.insert(cands, cg)
        end
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then
                table.insert(cands, pg)
        end
        for _, par in ipairs(cands) do
                for _, n in ipairs(names) do
                        local old = par:FindFirstChild(n)
                        if old then
                                old:Destroy()
                        end
                end
        end
end

local gui = Instance.new("ScreenGui")
gui.Name = "CAMERA_v1_0_1"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = findGuiParent()

-- ═══════════════ HELPER UI NEON ═══════════════
local function new(cls, props, parent)
        local o = Instance.new(cls)
        if props then
                for k, v in pairs(props) do
                        o[k] = v
                end
        end
        if parent then
                o.Parent = parent
        end
        return o
end

local function corner(o, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r or 12)
        c.Parent = o
        return c
end

local function stroke(o, col, th, tr)
        local s = Instance.new("UIStroke")
        s.Color = col or CFG.Neon1
        s.Thickness = th or 1
        s.Transparency = tr or 0.35
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = o
        return s
end

local function grad(o, c1, c2, rot)
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new(c1 or CFG.Neon1, c2 or CFG.Neon2)
        g.Rotation = rot or 0
        g.Parent = o
        return g
end

local function pad(o, t, b, l, r)
        local p = Instance.new("UIPadding")
        p.PaddingTop = UDim.new(0, t or 0)
        p.PaddingBottom = UDim.new(0, b or 0)
        p.PaddingLeft = UDim.new(0, l or 0)
        p.PaddingRight = UDim.new(0, r or 0)
        p.Parent = o
        return p
end

-- ═══════════════ OVERLAY DASAR ═══════════════
UI.lbT = new("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        ZIndex = 3,
}, gui)

UI.lbB = new("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 0),
        ZIndex = 3,
}, gui)

UI.maskT = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 0), ZIndex = 4 }, gui)
UI.maskB = new("Frame", { AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 0), ZIndex = 4 }, gui)
UI.maskL = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), ZIndex = 4 }, gui)
UI.maskR = new("Frame", { AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(1, 0, 0, 0), ZIndex = 4 }, gui)

UI.flash = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 60,
}, gui)

UI.notifBox = new("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.new(0, 236, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 11,
}, gui)
new("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
}, UI.notifBox)

UI.wm = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -10, 1, -10),
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = CFG.BG,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = " CAMERA v1.0.8 ",
        TextColor3 = CFG.TXT,
        TextSize = 10,
        Visible = false,
        ZIndex = 20,
}, gui)
corner(UI.wm, 999)
stroke(UI.wm, CFG.Neon1, 1, 0.5)

-- ═══════════════ PANEL UTAMA ═══════════════
UI.panel = new("Frame", {
        Position = UDim2.new(0, 16, 0.5, -215),
        Size = UDim2.new(0, 340, 0, 430),
        BackgroundColor3 = CFG.BG,
        BackgroundTransparency = 0.16,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 5,
}, gui)
corner(UI.panel, 18)
UI.panelStroke = stroke(UI.panel, CFG.Neon1, 1.4, 0.22)
do
        local g = grad(UI.panelStroke, CFG.Neon1, CFG.Neon2, 35)
        g.Enabled = true
end

UI.head = new("Frame", {
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 54),
        BackgroundTransparency = 1,
        Active = true,
        ZIndex = 6,
}, UI.panel)

UI.title = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 8),
        Size = UDim2.new(1, -60, 0, 22),
        Font = Enum.Font.GothamBlack,
        Text = "CAMERA<font color=\"#FF2DAA\"> v1.0.8</font>",
        RichText = true,
        TextColor3 = CFG.TXT,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
}, UI.head)

UI.sub = new("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 31),
        Size = UDim2.new(1, -60, 0, 14),
        Font = Enum.Font.GothamMedium,
        Text = "v1.0.8 · 1/2/3/4 = MODE",
        TextColor3 = CFG.TXT_DIM,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
}, UI.head)

UI.minBtn = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 12),
        Size = UDim2.new(0, 30, 0, 30),
        BackgroundColor3 = CFG.BGCard,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "–",
        TextColor3 = CFG.TXT,
        TextSize = 16,
        ZIndex = 7,
}, UI.head)
corner(UI.minBtn, 999)
stroke(UI.minBtn, CFG.Neon2, 1, 0.4)

UI.tabs = new("Frame", {
        Position = UDim2.new(0, 12, 0, 56),
        Size = UDim2.new(1, -24, 0, 28),
        BackgroundTransparency = 1,
        ZIndex = 6,
}, UI.panel)
new("UIListLayout", {
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
}, UI.tabs)

UI.body = new("ScrollingFrame", {
        Position = UDim2.new(0, 0, 0, 92),
        Size = UDim2.new(1, 0, 1, -92),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CFG.Neon1,
        ZIndex = 6,
}, UI.panel)

UI.foot = new("TextLabel", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, -6),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        Text = "F panel · H sembunyikan · K 2x hapus",
        TextColor3 = CFG.TXT_DIM,
        TextSize = 9,
        TextTransparency = 0.15,
        ZIndex = 6,
}, UI.panel)

UI.tabCAM = new("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        ZIndex = 6,
}, UI.body)
UI.tabTARGET = new("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 2,
        ZIndex = 6,
}, UI.body)
UI.tabSISTEM = new("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 3,
        ZIndex = 6,
}, UI.body)
UI.tabFOTO = new("Frame", {
        Size = UDim2.new(1, -20, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
        LayoutOrder = 4,
        ZIndex = 6,
}, UI.body)
-- ═══════════════ WIDGET UI ═══════════════
local function secLabel(parent, txt, order)
        return new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                Font = Enum.Font.GothamBold,
                Text = "— " .. string.upper(txt),
                TextColor3 = CFG.TXT_DIM,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = order or 1,
                ZIndex = 6,
        }, parent)
end

local function makePill(parent, txt, h, order, onTap)
        local b = new("TextButton", {
                Size = UDim2.new(1, 0, 0, h or 32),
                BackgroundColor3 = CFG.BGCard,
                BackgroundTransparency = 0.15,
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                Text = txt,
                TextColor3 = CFG.TXT,
                TextSize = 12,
                AutoButtonColor = true,
                LayoutOrder = order or 1,
                ZIndex = 6,
        }, parent)
        corner(b, 999)
        stroke(b, CFG.Neon1, 1, 0.55)
        if onTap then
                b.MouseButton1Click:Connect(onTap)
        end
        return b
end

local function makeToggle(parent, label, default, onSet, order)
        local b = makePill(parent, label .. "   ·   " .. (default and "ON" or "OFF"), 32, order, nil)
        local st = b:FindFirstChildOfClass("UIStroke")
        local state = default
        if not state then
                b.TextColor3 = CFG.TXT_DIM
                st.Color = CFG.TXT_DIM
        end
        b.MouseButton1Click:Connect(function()
                state = not state
                b.Text = label .. "   ·   " .. (state and "ON" or "OFF")
                b.TextColor3 = state and CFG.TXT or CFG.TXT_DIM
                st.Color = state and CFG.Neon1 or CFG.TXT_DIM
                onSet(state)
        end)
        return b
end

local function makeSlider(parent, label, minv, maxv, default, fmt, onSet, order)
        local box = new("Frame", {
                Size = UDim2.new(1, 0, 0, 44),
                BackgroundTransparency = 1,
                LayoutOrder = order or 1,
                ZIndex = 6,
        }, parent)
        new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.62, 0, 0, 14),
                Position = UDim2.new(0, 2, 0, 0),
                Font = Enum.Font.GothamBold,
                Text = label,
                TextColor3 = CFG.TXT,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6,
        }, box)
        local val = new("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -2, 0, 0),
                Size = UDim2.new(0.36, 0, 0, 14),
                Font = Enum.Font.GothamBold,
                Text = fmt(default),
                TextColor3 = CFG.Neon1,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 6,
        }, box)
        local track = new("Frame", {
                Position = UDim2.new(0, 0, 0, 26),
                Size = UDim2.new(1, 0, 0, 6),
                BackgroundColor3 = Color3.fromRGB(32, 32, 56),
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
                Active = true,
                ZIndex = 6,
        }, box)
        corner(track, 999)
        local fill = new("Frame", {
                Size = UDim2.new((default - minv) / (maxv - minv), 0, 1, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 6,
        }, track)
        corner(fill, 999)
        grad(fill, CFG.Neon1, CFG.Neon2, 0)
        local knob = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((default - minv) / (maxv - minv), 0, 0.5, 0),
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 7,
        }, track)
        corner(knob, 999)
        stroke(knob, CFG.Neon1, 1.5, 0.1)

        local handle
        local function setFromX(x)
                local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                handle.Set(minv + (maxv - minv) * a)
        end
        handle = {
                Set = function(v, silent)
                        v = math.clamp(v, minv, maxv)
                        local a = (v - minv) / (maxv - minv)
                        fill.Size = UDim2.new(a, 0, 1, 0)
                        knob.Position = UDim2.new(a, 0, 0.5, 0)
                        val.Text = fmt(v)
                        if not silent then
                                onSet(v)
                        end
                end,
        }
        local dragging = false
        track.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        setFromX(i.Position.X)
                end
        end)
        track.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        setFromX(i.Position.X)
                end
        end)
        table.insert(CONNS, UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                end
        end))
        return handle
end

-- ═══════════════ ISI TAB CAM ═══════════════
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, UI.tabCAM)
pad(UI.tabCAM, 2, 8, 0, 0)

secLabel(UI.tabCAM, "Mode Kamera", 1)

UI.modeBtns = {}
local modeDefs = {
        { id = "FREE", label = "1 · FREE CAM" },
        { id = "PRO",  label = "2 · PRO CAM" },
        { id = "CINE", label = "3 · CINEMATIC" },
        { id = "RACE", label = "4 · RACE CAM" },
}
for i, m in ipairs(modeDefs) do
        local b = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = CFG.BGCard,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                Text = "",
                TextSize = 12,
                AutoButtonColor = true,
                LayoutOrder = 1 + i,
                ZIndex = 6,
        }, UI.tabCAM)
        corner(b, 12)
        local st = stroke(b, CFG.Neon1, 1, 0.55)
        local g = grad(b, CFG.Neon1, CFG.Neon2, 0)
        g.Enabled = false
        local t = new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -24, 1, 0),
                Position = UDim2.new(0, 12, 0, 0),
                Font = Enum.Font.GothamBold,
                Text = m.label,
                TextColor3 = CFG.TXT,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 7,
        }, b)
        b.MouseButton1Click:Connect(function()
                setMode(m.id)
        end)
        UI.modeBtns[m.id] = { btn = b, grad = g, st = st, txt = t }
end

UI.selfBtn = makePill(UI.tabCAM, "◉  KE KARAKTER UTAMA", 32, 5, function()
        goToSelf()
end)

secLabel(UI.tabCAM, "Pengaturan", 6)
UI.speedSlider = makeSlider(UI.tabCAM, "KECEPATAN", 8, 90, CFG.Speed, function(v)
        return math.floor(v) .. " stud/s"
end, function(v)
        CFG.Speed = v
end, 7)
UI.fovSlider = makeSlider(UI.tabCAM, "FOV", 30, 105, CFG.FOV, function(v)
        return math.floor(v) .. "°"
end, function(v)
        CFG.FOV = v
end, 8)
UI.tempoSlider = makeSlider(UI.tabCAM, "CINE TEMPO", 3, 10, CFG.CineTempo, function(v)
        return string.format("%.1f s", v)
end, function(v)
        CFG.CineTempo = v
end, 9)
UI.fovMinSlider = makeSlider(UI.tabCAM, "LENSA CINE MIN (FOV)", 30, 100, CFG.CineFovMin, function(v)
        return math.floor(v) .. "°"
end, function(v)
        CFG.CineFovMin = v
        if CFG.CineFovMax < v then
                CFG.CineFovMax = v
                UI.fovMaxSlider.Set(v, true)
        end
end, 10)
UI.fovMaxSlider = makeSlider(UI.tabCAM, "LENSA CINE MAX (FOV)", 30, 100, CFG.CineFovMax, function(v)
        return math.floor(v) .. "°"
end, function(v)
        CFG.CineFovMax = v
        if CFG.CineFovMin > v then
                CFG.CineFovMin = v
                UI.fovMinSlider.Set(v, true)
        end
end, 11)

-- ═══════════════ ISI TAB TARGET ═══════════════
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, UI.tabTARGET)
pad(UI.tabTARGET, 2, 8, 0, 0)

UI.lockBtn = makePill(UI.tabTARGET, "T · LOCK TERDEKAT DARI KAMERA / UNLOCK", 34, 1, function()
        toggleLock()
end)
UI.autoBtn = makePill(UI.tabTARGET, "AUTO LOCK · OFF", 32, 2, function()
        lockAutoToggle()
end)
UI.refreshBtn = makePill(UI.tabTARGET, "SEGARKAN DAFTAR", 28, 3, function()
        refreshTargetList()
end)
secLabel(UI.tabTARGET, "Pilih Sendiri (klik pemain)", 4)

UI.tList = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 170),
        BackgroundColor3 = CFG.BGCard,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = CFG.Neon2,
        LayoutOrder = 5,
        ZIndex = 6,
}, UI.tabTARGET)
corner(UI.tList, 12)
stroke(UI.tList, CFG.Neon2, 1, 0.7)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, UI.tList)
pad(UI.tList, 6, 6, 6, 6)

new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40),
        Font = Enum.Font.GothamMedium,
        Text = "PRO & SINEMATIK ikut: lock > pilihan > terdekat (dari KAMERA) > diri sendiri.\nT = lock pemain terdekat dari KAMERA · AUTO LOCK pindah sendiri kalau target hilang.\nBlur foto fokus otomatis ke avatar target.",
        TextColor3 = CFG.TXT_DIM,
        TextSize = 10,
        TextWrapped = true,
        LayoutOrder = 6,
        ZIndex = 6,
}, UI.tabTARGET)

-- ═══════════════ ISI TAB SISTEM ═══════════════
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, UI.tabSISTEM)
pad(UI.tabSISTEM, 2, 8, 0, 0)

secLabel(UI.tabSISTEM, "Teleport", 1)
makePill(UI.tabSISTEM, "C · TELEPORT KE BELAKANG LAYAR", 32, 2, function()
        doTeleport()
end)
UI.teleSlider = makeSlider(UI.tabSISTEM, "JARAK TELEPORT", 0, 30, CFG.TeleDist, function(v)
        return math.floor(v + 0.5) .. " langkah"
end, function(v)
        CFG.TeleDist = v
end, 3)

secLabel(UI.tabSISTEM, "Utilitas", 4)
UI.waktuBtn = makePill(UI.tabSISTEM, "Z · CAHAYA AUTO (2 ARAH) · OFF", 32, 5, function()
        toggleCahaya()
end)
UI.gerakBtn = makePill(UI.tabSISTEM, "J · GERAK ⇄ BEKU KARAKTER", 32, 6, function()
        toggleGerak()
end)
makeToggle(UI.tabSISTEM, "BEKUKAN KARAKTER (KAMERA/MASTER)", CFG.Anchor, function(state)
        CFG.Anchor = state
        setAnchorState()
end, 7)
makeToggle(UI.tabSISTEM, "LETTERBOX SINEMATIK (SEMUA MODE)", CFG.Letterbox, function(state)
        CFG.Letterbox = state
        applyLetterbox()
end, 8)
makeToggle(UI.tabSISTEM, "KAMERA ANTI-TEMBOSS (FREE/PRO TANAH SAJA)", CFG.AntiClip, function(state)
        CFG.AntiClip = state
end, 9)
makeToggle(UI.tabSISTEM, "CINE · TRANSISI BLUR ANTAR SHOT", CFG.ShotBlur > 0, function(state)
        CFG.ShotBlur = state and 0.2 or 0
        if not state then
                DOF_TRANS.Enabled = false
        end
end, 10)
makeToggle(UI.tabSISTEM, "CINE · VARIASI LENSA (BOBOT CERDAS)", CFG.LensPool, function(state)
        CFG.LensPool = state
end, 11)
makeToggle(UI.tabSISTEM, "CINE · SHOT JAUH 30-120 STUD (DRONE/TELE)", CFG.FarShots, function(state)
        CFG.FarShots = state
end, 12)

secLabel(UI.tabSISTEM, "Keybind", 13)
new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 86),
        Font = Enum.Font.GothamMedium,
        Text = "CapsLock · MASTER kamera (OFF = keybind kamera mati)\n1/2/3/4 mode · M foto · T lock · C teleport · H hide UI\nF panel · Z cahaya · K 2x hapus · J gerak⇄beku (mandiri)\nRMB lihat · Scroll zoom/FOV · Space (tahan) turbo\nCtrl slow cinematic (FREE)",
        TextColor3 = CFG.TXT_DIM,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = 14,
        ZIndex = 6,
}, UI.tabSISTEM)

makePill(UI.tabSISTEM, "↻  RESET SCRIPT (BALIK KE DEFAULT)", 32, 12, function()
        resetScript()
end)

local dangerBtn = makePill(UI.tabSISTEM, "K 2x · HAPUS SCRIPT", 32, 13, function()
        unloadAll()
end)
dangerBtn.TextColor3 = CFG.DANGER
dangerBtn:FindFirstChildOfClass("UIStroke").Color = CFG.DANGER

-- ═══════════════ ISI TAB FOTO ═══════════════
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, UI.tabFOTO)
pad(UI.tabFOTO, 2, 8, 0, 0)

secLabel(UI.tabFOTO, "Filter Warna", 1)
UI.filterBtns = {}
do
        local wrap = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 2,
                ZIndex = 6,
        }, UI.tabFOTO)
        new("UIGridLayout", {
                CellSize = UDim2.new(0.5, -4, 0, 26),
                CellPadding = UDim2.new(0, 4, 0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
        }, wrap)
        local FILTERS = {
                { id = "OFF",     label = "ASLI" },
                { id = "TEAL",    label = "TEAL&ORANGE" },
                { id = "GOLDEN",  label = "GOLDEN HOUR" },
                { id = "NEON",    label = "NEON NIGHT" },
                { id = "VINTAGE", label = "VINTAGE" },
                { id = "BW",      label = "HITAM PUTIH" },
                { id = "VIVID",   label = "VIVID" },
                { id = "DREAMY",  label = "DREAMY" },
        }
        for i, f in ipairs(FILTERS) do
                local b = new("TextButton", {
                        BackgroundColor3 = CFG.BGCard,
                        BackgroundTransparency = 0.2,
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        Text = f.label,
                        TextColor3 = CFG.TXT,
                        TextSize = 10,
                        AutoButtonColor = true,
                        LayoutOrder = i,
                        ZIndex = 6,
                }, wrap)
                corner(b, 999)
                stroke(b, CFG.Neon1, 1, 0.65)
                b.MouseButton1Click:Connect(function()
                        setFilter(f.id)
                end)
                UI.filterBtns[f.id] = b
        end
end

secLabel(UI.tabFOTO, "Rasio Frame", 2)
UI.ratioBtns = {}
do
        local row = new("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 4,
                ZIndex = 6,
        }, UI.tabFOTO)
        new("UIGridLayout", {
                CellSize = UDim2.new(1 / 3, -4, 0, 24),
                CellPadding = UDim2.new(0, 4, 0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
        }, row)
        local RATIOS = {
                { id = "FULL", label = "BEBAS" },
                { id = "21:9", label = "21:9 SINEMA" },
                { id = "16:9", label = "16:9" },
                { id = "4:5",  label = "4:5 IG" },
                { id = "1:1",  label = "1:1" },
                { id = "9:16", label = "9:16 TIKTOK" },
        }
        for i, r in ipairs(RATIOS) do
                local b = new("TextButton", {
                        BackgroundColor3 = CFG.BGCard,
                        BackgroundTransparency = 0.2,
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        Text = r.label,
                        TextColor3 = CFG.TXT,
                        TextSize = 10,
                        AutoButtonColor = true,
                        LayoutOrder = i,
                        ZIndex = 6,
                }, row)
                corner(b, 999)
                stroke(b, CFG.Neon2, 1, 0.65)
                b.MouseButton1Click:Connect(function()
                        setRatio(r.id)
                end)
                UI.ratioBtns[r.id] = b
        end
end

secLabel(UI.tabFOTO, "Blur Otomatis (Fokus Target)", 5)
makeToggle(UI.tabFOTO, "BLUR OTOMATIS · ON/OFF", false, function(state)
        S.foto.dof = state
        if state then
                notify("Blur ON — fokus otomatis ke avatar target lock (T)")
        end
end, 6)
new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
        Font = Enum.Font.GothamMedium,
        Text = "Fokus mengikuti avatar target lock (T) / subjek kamera.\nSlider bawah cuma dipakai kalau tidak ada target.",
        TextColor3 = CFG.TXT_DIM,
        TextSize = 10,
        TextWrapped = true,
        LayoutOrder = 7,
        ZIndex = 6,
}, UI.tabFOTO)
makeSlider(UI.tabFOTO, "FALLBACK FOKUS (TANPA TARGET)", 2, 100, S.foto.focus, function(v)
        return math.floor(v) .. " stud"
end, function(v)
        S.foto.focus = v
end, 8)
makeSlider(UI.tabFOTO, "KEKUATAN BLUR", 0, 100, S.foto.blur, function(v)
        return math.floor(v) .. "%"
end, function(v)
        S.foto.blur = v
end, 9)

secLabel(UI.tabFOTO, "Ambil Foto", 10)
do
        local shotBtn = makePill(UI.tabFOTO, "●  AMBIL FOTO  (LAYAR BERSIH 5 DETIK)", 38, 11, function()
                takePhoto()
        end)
        shotBtn.TextSize = 12
        local g = grad(shotBtn, CFG.Neon1, CFG.Neon2, 0)
        g.Enabled = true
        shotBtn.TextColor3 = Color3.fromRGB(10, 10, 18)
end
makeToggle(UI.tabFOTO, "WATERMARK CAMERA", false, function(state)
        setWatermark(state)
end, 12)

-- ═══════════════ TAB BAR + LOGIKA TAB ═══════════════
UI.tabBtns = {}
local tabDefs = {
        { id = "CAM",    f = UI.tabCAM },
        { id = "TARGET", f = UI.tabTARGET },
        { id = "SISTEM", f = UI.tabSISTEM },
        { id = "FOTO",   f = UI.tabFOTO },
}
local activeTab = "CAM"

local function switchTab(id)
        activeTab = id
        for _, td in ipairs(tabDefs) do
                td.f.Visible = (td.id == id)
                local tb = UI.tabBtns[td.id]
                if tb then
                        tb.grad.Enabled = (td.id == id)
                        tb.txt.TextColor3 = (td.id == id) and Color3.fromRGB(12, 12, 20) or CFG.TXT_DIM
                        tb.st.Transparency = (td.id == id) and 0.15 or 0.65
                end
        end
        if id == "TARGET" then
                refreshTargetList()
        end
end

for i, td in ipairs(tabDefs) do
        local b = new("TextButton", {
                Size = UDim2.new(0, 73, 0, 28),
                BackgroundColor3 = CFG.BGCard,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                Text = td.id,
                TextColor3 = CFG.TXT_DIM,
                TextSize = 11,
                AutoButtonColor = true,
                LayoutOrder = i,
                ZIndex = 6,
        }, UI.tabs)
        corner(b, 999)
        local st = stroke(b, CFG.Neon1, 1, 0.65)
        local g = grad(b, CFG.Neon1, CFG.Neon2, 0)
        g.Enabled = false
        UI.tabBtns[td.id] = { btn = b, grad = g, st = st, txt = b }
        b.MouseButton1Click:Connect(function()
                switchTab(td.id)
        end)
end
switchTab("CAM")

-- ═══════════════ REFRESH UI MODE ═══════════════
function refreshModeUI()
        for id, mb in pairs(UI.modeBtns) do
                local active = (S.mode == id)
                mb.grad.Enabled = active
                mb.txt.TextColor3 = active and Color3.fromRGB(12, 12, 20) or CFG.TXT
                mb.st.Transparency = active and 0.1 or 0.55
        end
end

-- ═══════════════ TOMBOL LIPAT PANEL ═══════════════
do
        local minimized = false
        UI.minBtn.MouseButton1Click:Connect(function()
                minimized = not minimized
                UI.body.Visible = not minimized
                UI.tabs.Visible = not minimized
                UI.foot.Visible = not minimized
                UI.panel.Size = minimized and UDim2.new(0, 340, 0, 58) or UDim2.new(0, 340, 0, 430)
                UI.minBtn.Text = minimized and "+" or "–"
        end)
end

-- ═══════════════ DRAG PANEL (HEADER) ═══════════════
do
        local dragging = false
        local dragStart, startPos
        UI.head.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        dragStart = input.Position
                        startPos = UI.panel.Position
                end
        end)
        table.insert(CONNS, UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local d = input.Position - dragStart
                        UI.panel.Position = UDim2.new(
                                startPos.X.Scale, startPos.X.Offset + d.X,
                                startPos.Y.Scale, startPos.Y.Offset + d.Y
                        )
                end
        end))
        table.insert(CONNS, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                end
        end))
end

-- ═══════════════ NOTIFIKASI ═══════════════
function notify(text, dur)
        -- v1.0.8: semua notifikasi dimatikan — tidak ada popup apa pun
end

-- ═══════════════ VISIBILITAS UI ═══════════════
function applyUIVisibility()
        local vis = not S.uiHidden
        UI.panel.Visible = vis and S.panelOpen
        UI.notifBox.Visible = vis
end

function togglePanel()
        S.panelOpen = not S.panelOpen
        UI.panel.Visible = S.panelOpen and not S.uiHidden
end

function toggleHideUI()
        S.uiHidden = not S.uiHidden
        applyUIVisibility()
        notify(S.uiHidden and "UI disembunyikan — tekan H untuk munculkan" or "UI dimunculkan")
end

-- ═══════════════ FLASH & LETTERBOX ═══════════════
function flash()
        UI.flash.BackgroundTransparency = 0.9
        TweenService:Create(UI.flash, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
end

function applyLetterbox()
        local modeOn = (S.mode ~= "NONE") or S.fotoAktif
        local on = modeOn and CFG.Letterbox and (S.foto.ratio == "FULL")
        local target = on and 62 or 0
        local tw = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(UI.lbT, tw, { Size = UDim2.new(1, 0, 0, target) }):Play()
        TweenService:Create(UI.lbB, tw, { Size = UDim2.new(1, 0, 0, target) }):Play()
end

-- ═══════════════ CHIP STATUS (DIHAPUS) ═══════════════
function updateChip()
        return
end

-- ═══════════════ KARAKTER BEKU PATUNG (OTOMATIS + TOMBOL J) ═══════════════
local BEKU = {
        on = false,
        char = nil,      -- karakter yang sedang dibekukan (deteksi respawn)
        saved = nil,     -- WalkSpeed / Jump / AutoRotate asli
        animOff = false, -- status Disabled script "Animate" sebelum dibekukan
        tracks = {},     -- [track] = {Speed, Pos} nilai asli sebelum dibekukan
        conns = {},      -- koneksi sementara selama beku
}

local function dapatAnimator(c, hum)
        if hum then
                local a = hum:FindFirstChildOfClass("Animator")
                if a then
                        return a
                end
        end
        if c then
                return c:FindFirstChildOfClass("Animator")
        end
        return nil
end

local function bekukanSemuaTrack()
        local c = myChar()
        if not (c and c.Parent) then
                return
        end
        local anim = dapatAnimator(c, getHum(c))
        if not anim then
                return
        end
        for _, tr in ipairs(anim:GetPlayingAnimationTracks()) do
                if not BEKU.tracks[tr] then
                        BEKU.tracks[tr] = { Speed = tr.Speed, Pos = tr.TimePosition }
                        table.insert(BEKU.conns, tr.Stopped:Connect(function()
                                if not BEKU.on or not BEKU.tracks[tr] then
                                        return
                                end
                                pcall(function()
                                        tr:Play(0)
                                        tr.TimePosition = BEKU.tracks[tr].Pos
                                        tr:AdjustSpeed(0)
                                end)
                        end))
                end
                tr:AdjustSpeed(0) -- pose berhenti PERSIS di frame ini
        end
end

local function nolkanKecepatan(c)
        for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                        p.AssemblyLinearVelocity = Vector3.zero
                        p.AssemblyAngularVelocity = Vector3.zero
                end
        end
end

local function putuskanBeku()
        for _, cn in ipairs(BEKU.conns) do
                pcall(function()
                        cn:Disconnect()
                end)
        end
        table.clear(BEKU.conns)
end

local function bekukanKarakter()
        local c = myChar()
        if not (c and c.Parent) then
                return
        end
        if BEKU.on and BEKU.char == c then
                return -- karakter ini sudah dibekukan
        end
        if BEKU.on then
                putuskanBeku() -- respawn: karakter lama tiada, bersihkan sisa beku
                table.clear(BEKU.tracks)
                BEKU.saved = nil
                BEKU.on = false
        end
        local hrp = getRoot(c)
        if not hrp then
                return
        end
        local hum = getHum(c)
        BEKU.on = true
        BEKU.char = c

        hrp.Anchored = true

        if hum then
                BEKU.saved = {
                        Walk = hum.WalkSpeed,
                        Jump = hum.UseJumpPower and hum.JumpPower or hum.JumpHeight,
                        UseJP = hum.UseJumpPower,
                        Rot = hum.AutoRotate,
                }
                hum.WalkSpeed = 0
                hum.AutoRotate = false
                if hum.UseJumpPower then
                        hum.JumpPower = 0
                else
                        hum.JumpHeight = 0
                end
        end

        local animScript = c:FindFirstChild("Animate")
        if animScript and animScript:IsA("LocalScript") then
                BEKU.animOff = animScript.Disabled
                animScript.Disabled = true
        else
                BEKU.animOff = nil
        end

        nolkanKecepatan(c)

        bekukanSemuaTrack()

        local anim = dapatAnimator(c, hum)
        if anim then
                table.insert(BEKU.conns, anim.AnimationPlayed:Connect(function(tr)
                        if not BEKU.tracks[tr] then
                                BEKU.tracks[tr] = { Speed = tr.Speed, Pos = 0 }
                        end
                        tr:AdjustSpeed(0)
                end))
        end

        table.insert(BEKU.conns, RunService.Heartbeat:Connect(function()
                if not BEKU.on then
                        return
                end
                local ch = myChar()
                if not (ch and ch.Parent and getRoot(ch)) then
                        return
                end
                nolkanKecepatan(ch)
                local anim2 = dapatAnimator(ch, getHum(ch))
                if anim2 then
                        for _, tr in ipairs(anim2:GetPlayingAnimationTracks()) do
                                if tr.Speed ~= 0 then
                                        tr:AdjustSpeed(0)
                                end
                        end
                end
        end))
end

local function lebaskanKarakter()
        if not BEKU.on then
                return
        end
        BEKU.on = false
        putuskanBeku()
        local c = myChar()
        local hrp = getRoot(c)
        local hum = getHum(c)
        if BEKU.char == c then
                for tr in pairs(BEKU.tracks) do
                        pcall(function()
                                if tr then
                                        tr:Stop(0)
                                end
                        end)
                end
                local animScript = c:FindFirstChild("Animate")
                if animScript and BEKU.animOff ~= nil then
                        animScript.Disabled = BEKU.animOff
                end
                if hum and BEKU.saved then
                        pcall(function()
                                hum.WalkSpeed = BEKU.saved.Walk
                                hum.AutoRotate = BEKU.saved.Rot
                                if BEKU.saved.UseJP then
                                        hum.JumpPower = BEKU.saved.Jump
                                else
                                        hum.JumpHeight = BEKU.saved.Jump
                                end
                        end)
                end
        end
        table.clear(BEKU.tracks)
        BEKU.saved = nil
        BEKU.char = nil
        BEKU.animOff = false
        if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.Anchored = false
        end
end

local function hitungBeku()
        if S.gerakMode == "GERAK" then
                return false -- J: boleh jalan walau kamera/master aktif
        end
        if S.gerakMode == "BEKU" then
                return S.mode ~= "RACE" -- J: beku patung walau master off / toggle SISTEM off
        end
        if not CFG.Anchor then
                return false -- sistem beku dimatikan lewat toggle SISTEM
        end
        return (S.master or S.mode ~= "NONE") and S.mode ~= "RACE"
end

function setAnchorState()
        if unloadDone then
                return
        end
        local want = hitungBeku()
        if want then
                bekukanKarakter()
        elseif BEKU.on then
                lebaskanKarakter()
        else
                local hrp = getRoot(myChar())
                if hrp and hrp.Anchored then
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.Anchored = false
                end
        end
end

function toggleGerak()
        S.gerakMode = (BEKU.on or hitungBeku()) and "GERAK" or "BEKU"
        setAnchorState()
        if S.gerakMode == "GERAK" then
                notify("GERAK — karakter bisa jalan lagi (J lagi = bekukan)", 1.8)
        else
                notify("BEKU — PATUNG: diam total, pose terkunci di frame ini (J lagi = gerak)", 2.2)
        end
end

-- ═══════════════ SUBJEK (TARGET) ═══════════════
function findNearestPlayer()
        local origin = workspace.CurrentCamera.CFrame.Position
        local best, bd
        for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LP then
                        local c = pl.Character
                        local r = getRoot(c)
                        local h = c and getHum(c) or nil
                        if r and h and h.Health > 0 then
                                local d = (r.Position - origin).Magnitude
                                if not bd or d < bd then
                                        best, bd = pl, d
                                end
                        end
                end
        end
        return best, bd
end

local function aliveCharOf(pl)
        if pl and pl.Parent then
                local c = pl.Character
                local h = c and getHum(c) or nil
                if c and c.Parent and h and h.Health > 0 then
                        return c
                end
        end
        return nil
end

function getSubjectChar()
        if S.locked then
                local c = aliveCharOf(S.lockPlayer)
                if c then
                        return c
                end
        end
        local c = aliveCharOf(S.selected)
        if c then
                return c
        end
        local best = findNearestPlayer()
        if best then
                return best.Character
        end
        return myChar()
end

function toggleLock()
        if not S.master then
                notify("CAPSLOCK OFF — tekan CapsLock dulu untuk pakai fitur kamera", 2)
                return
        end
        if S.locked then
                S.locked = false
                S.lockPlayer = nil
                updateChip()
                refreshTargetList()
                if UI.updateLockBtn then
                        UI.updateLockBtn()
                end
                notify("Target lock: MATI", 1.2)
                return
        end
        local best, bd = findNearestPlayer()
        if not best then
                notify("Tidak ada pemain lain di server")
                return
        end
        S.locked = true
        S.lockMode = "TERDEKAT"
        S.lockPlayer = best
        S.selected = best
        updateChip()
        refreshTargetList()
        if UI.updateLockBtn then
                UI.updateLockBtn()
        end
        notify("Locked (terdekat dari kamera): " .. best.Name .. " (" .. math.floor(bd) .. " stud)", 1.4)
end

function lockAutoToggle()
        if not S.master then
                notify("CAPSLOCK OFF — tekan CapsLock dulu untuk pakai fitur kamera", 2)
                return
        end
        if S.locked and S.lockMode == "AUTO" then
                S.locked = false
                S.lockPlayer = nil
                updateChip()
                refreshTargetList()
                if UI.updateLockBtn then
                        UI.updateLockBtn()
                end
                notify("AUTO LOCK: OFF", 1.2)
                return
        end
        local best = findNearestPlayer()
        if not best then
                notify("Tidak ada pemain lain di server")
                return
        end
        S.locked = true
        S.lockMode = "AUTO"
        S.lockPlayer = best
        S.selected = best
        updateChip()
        refreshTargetList()
        if UI.updateLockBtn then
                UI.updateLockBtn()
        end
        notify("AUTO LOCK: ON → " .. best.Name .. " (pindah sendiri kalau target hilang)", 1.4)
end

function lockPick(pl)
        if not pl or pl == LP then
                S.locked = false
                S.lockPlayer = nil
                notify("Lock dilepas", 1.2)
        else
                S.locked = true
                S.lockMode = "PILIH"
                S.lockPlayer = pl
                S.selected = pl
                notify("Lock (pilih sendiri): " .. pl.Name, 1.4)
        end
        updateChip()
        refreshTargetList()
        if UI.updateLockBtn then
                UI.updateLockBtn()
        end
end

function updateLockBtn()
        if UI.lockBtn then
                if S.locked and S.lockPlayer then
                        UI.lockBtn.Text = "T · UNLOCK (" .. S.lockPlayer.Name .. ")"
                        UI.lockBtn.TextColor3 = CFG.Neon2
                else
                        UI.lockBtn.Text = "T · LOCK TERDEKAT DARI KAMERA / UNLOCK"
                        UI.lockBtn.TextColor3 = CFG.TXT
                end
        end
        if UI.autoBtn then
                local on = S.locked and S.lockMode == "AUTO"
                local nm = (on and S.lockPlayer) and S.lockPlayer.Name or ""
                UI.autoBtn.Text = on and ("AUTO LOCK · ON → " .. nm) or "AUTO LOCK · OFF"
                UI.autoBtn.TextColor3 = on and CFG.Neon1 or CFG.TXT
                local st = UI.autoBtn:FindFirstChildOfClass("UIStroke")
                if st then
                        st.Transparency = on and 0.1 or 0.55
                end
        end
end
UI.updateLockBtn = updateLockBtn

function refreshTargetList()
        if not UI.tList then
                return
        end
        for _, ch in ipairs(UI.tList:GetChildren()) do
                if ch:IsA("TextButton") then
                        ch:Destroy()
                end
        end
        local myRoot = getRoot(myChar())
        local origin = myRoot and myRoot.Position or workspace.CurrentCamera.CFrame.Position
        local rows = {}
        for _, pl in ipairs(Players:GetPlayers()) do
                local r = getRoot(pl.Character)
                local d = r and math.floor((r.Position - origin).Magnitude) or -1
                table.insert(rows, { pl = pl, d = d })
        end
        table.sort(rows, function(a, b)
                if a.pl == LP then
                        return false
                end
                if b.pl == LP then
                        return true
                end
                if a.d < 0 then
                        return false
                end
                if b.d < 0 then
                        return true
                end
                return a.d < b.d
        end)
        for i, row in ipairs(rows) do
                local isLock = (S.locked and S.lockPlayer == row.pl)
                local isSel = isLock or (S.selected == row.pl)
                local label = row.pl == LP and (row.pl.Name .. "  (kamu)") or row.pl.Name
                if isLock then
                        label = "● " .. label
                end
                local distTxt = row.d >= 0 and (row.d .. "m") or "-"
                local b = new("TextButton", {
                        Size = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3 = isSel and CFG.BG or CFG.BGCard,
                        BackgroundTransparency = isSel and 0.05 or 0.3,
                        BorderSizePixel = 0,
                        Font = Enum.Font.GothamBold,
                        Text = "",
                        TextSize = 11,
                        AutoButtonColor = true,
                        LayoutOrder = i,
                        ZIndex = 7,
                }, UI.tList)
                corner(b, 8)
                local st = stroke(b, isSel and CFG.Neon1 or CFG.Neon2, 1, isSel and 0.15 or 0.8)
                new("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.62, 0, 1, 0),
                        Position = UDim2.new(0, 10, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Text = label,
                        TextColor3 = isSel and CFG.Neon1 or CFG.TXT,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 7,
                }, b)
                new("TextLabel", {
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2.new(1, 0),
                        Size = UDim2.new(0.3, 0, 1, 0),
                        Position = UDim2.new(1, -10, 0, 0),
                        Font = Enum.Font.GothamBold,
                        Text = distTxt,
                        TextColor3 = CFG.TXT_DIM,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex = 7,
                }, b)
                b.MouseButton1Click:Connect(function()
                        lockPick(row.pl)
                end)
        end
end

-- ═══════════════ TELEPORT (C) ═══════════════
function doTeleport()
        if not S.master then
                notify("CAPSLOCK OFF — tekan CapsLock dulu untuk pakai fitur kamera", 2)
                return
        end
        local char = myChar()
        local hum, hrp = getHum(char), getRoot(char)
        if not (hum and hrp) then
                notify("Karakter belum siap")
                return
        end
        local cam = workspace.CurrentCamera
        local d = math.clamp(CFG.TeleDist, 0, 30)
        local pos = (cam.CFrame * CFrame.new(0, 0, d)).Position
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local exclude = {}
        for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Character then
                        table.insert(exclude, pl.Character)
                end
        end
        params.FilterDescendantsInstances = exclude
        local ray = workspace:Raycast(pos + Vector3.new(0, 40, 0), Vector3.new(0, -240, 0), params)
        local y
        if ray then
                local lift
                if hum.RigType == Enum.HumanoidRigType.R6 then
                        lift = 3.1
                else
                        lift = (hum.HipHeight or 2) + hrp.Size.Y * 0.5 + 0.1
                end
                y = ray.Position.Y + lift
        else
                y = pos.Y
        end
        local look = cam.CFrame.LookVector
        local yaw = math.deg(math.atan2(-look.X, -look.Z))
        flash()
        char:PivotTo(CFrame.new(pos.X, y, pos.Z) * CFrame.fromOrientation(0, math.rad(yaw), 0))
        hrp.Anchored = true
        task.delay(0.15, function()
                setAnchorState()
        end)
        notify("Teleport di belakang layar " .. math.floor(d + 0.5) .. " langkah")
end

-- ═══════════════ CAHAYA AUTO 2 ARAH (Z) ═══════════════
local function apakahMalam()
        local t = Lighting.ClockTime
        return t >= CFG.JamMalamMulai or t < CFG.JamMalamAkhir
end

local function targetCahaya()
        if apakahMalam() then
                return CFG.ClockTerangi, CFG.BrightTerangi, CFG.AmbientTerangi
        end
        return CFG.ClockAntiSilau, CFG.BrightAntiSilau, CFG.AmbientLembut
end

local function langkahCahaya()
        local jamTarget, brightTarget, ambientTarget = targetCahaya()
        local jam0 = Lighting.ClockTime
        local delta = jamTarget - jam0
        if delta > 12 then delta = delta - 24 elseif delta < -12 then delta = delta + 24 end
        local bright0 = Lighting.Brightness
        local ambient0 = Lighting.Ambient
        local out0 = Lighting.OutdoorAmbient
        local jumlah = 22
        for i = 1, jumlah do
                if not S.lightOn or unloadDone then return end
                local a = i / jumlah
                pcall(function()
                        Lighting.ClockTime = (jam0 + delta * a) % 24
                        Lighting.Brightness = bright0 + (brightTarget - bright0) * a
                        Lighting.Ambient = ambient0:Lerp(ambientTarget, a)
                        Lighting.OutdoorAmbient = out0:Lerp(ambientTarget, a)
                end)
                task.wait(0.05)
        end
        pcall(function()
                Lighting.ClockTime = jamTarget % 24
                Lighting.Brightness = brightTarget
                Lighting.Ambient = ambientTarget
                Lighting.OutdoorAmbient = ambientTarget
        end)
end

function matikanCahaya(silent)
        if not S.lightOn then
                return
        end
        S.lightOn = false
        if S.lightConn then
                task.cancel(S.lightConn)
                S.lightConn = nil
        end
        pcall(function()
                if S.oLight then
                        Lighting.ClockTime = S.oLight.ClockTime
                        Lighting.Brightness = S.oLight.Brightness
                        Lighting.Ambient = S.oLight.Ambient
                        Lighting.OutdoorAmbient = S.oLight.OutdoorAmbient
                        Lighting.ExposureCompensation = S.oLight.ExposureCompensation
                        Lighting.FogEnd = S.oLight.FogEnd
                end
        end)
        if UI.waktuBtn then
                UI.waktuBtn.Text = "Z · CAHAYA AUTO (2 ARAH) · OFF"
        end
        if not silent then
                notify("CAHAYA AUTO OFF — lighting asli dikembalikan")
        end
        updateChip()
end

function toggleCahaya()
        if S.lightOn then
                matikanCahaya(false)
                return
        end
        S.lightOn = true
        S.lightPernahAktif = true
        S.oLight = {
                Brightness = Lighting.Brightness,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                ClockTime = Lighting.ClockTime,
                ExposureCompensation = Lighting.ExposureCompensation,
                FogEnd = Lighting.FogEnd,
        }
        if Lighting.FogEnd < 5000 then
                Lighting.FogEnd = CFG.FogBuka
        end
        if S.lightConn then
                task.cancel(S.lightConn)
        end
        S.lightConn = task.spawn(function()
                while S.lightOn and not unloadDone do
                        langkahCahaya()
                        local tunggu = 0
                        while tunggu < 2 and S.lightOn and not unloadDone do
                                task.wait(0.25)
                                tunggu = tunggu + 0.25
                        end
                end
        end)
        if UI.waktuBtn then
                UI.waktuBtn.Text = "Z · CAHAYA AUTO (2 ARAH) · ON"
        end
        notify("CAHAYA AUTO ON — malam diterangi · siang dilembutkan")
        updateChip()
end

-- ═══════════════ KE KARAKTER UTAMA (kamera terbang balik) ═══════════════
function goToSelf()
        if S.mode ~= "FREE" and S.mode ~= "PRO" then
                notify("Aktifkan kamera dulu (1 / 2) untuk pindah ke karakter")
                return
        end
        local root = getRoot(myChar())
        if not root then
                notify("Karakter belum siap")
                return
        end
        local head = root.Position + Vector3.new(0, 1.5, 0)
        if S.mode == "FREE" then
                local look = CFrame.fromOrientation(S.pitch, S.yaw, 0).LookVector
                local f = Vector3.new(look.X, 0, look.Z)
                if f.Magnitude > 0.05 then
                        f = f.Unit
                else
                        f = Vector3.new(0, 0, -1)
                end
                local destPos = head - f * CFG.SelfFlyDist + Vector3.new(0, CFG.SelfFlyHeight, 0)
                local dir = head - destPos
                local toYaw = math.atan2(-dir.X, -dir.Z)
                local toPitch = math.clamp(math.asin(math.clamp(dir.Unit.Y, -1, 1)), -1.45, 1.45)
                local dist = (destPos - S.freePos).Magnitude
                S.fly = {
                        t = 0,
                        dur = math.clamp(0.6 + dist / 150, 0.6, 2.4),
                        fromPos = S.freePos,
                        toPos = destPos,
                        fromYaw = S.yaw,
                        toYaw = toYaw,
                        fromPitch = S.pitch,
                        toPitch = toPitch,
                }
                S.freeVel = Vector3.new(0, 0, 0)
                S.aimY = nil
        else
                local dist = (head - (S.proPivot or head)).Magnitude
                S.proGlide = {
                        t = 0,
                        dur = math.clamp(0.5 + dist / 120, 0.5, 2.0),
                        fromPivot = S.proPivot or head,
                }
        end
        flash()
        notify("Kamera pindah ke karakter utama")
end

-- ═══════════════ RESET SCRIPT ═══════════════
function resetScript()
        S.gerakMode = nil -- J balik ke aturan otomatis
        if S.mode ~= "NONE" then
                setMode("NONE")
        end
        setAnchorState() -- pastikan status beku sesuai aturan terbaru
        matikanCahaya(true)
        S.locked = false
        S.lockPlayer = nil
        S.selected = nil
        CFG.Speed = 45
        CFG.FOV = 70
        CFG.TeleDist = 7
        if UI.speedSlider then
                UI.speedSlider.Set(45)
        end
        if UI.fovSlider then
                UI.fovSlider.Set(70)
        end
        if UI.teleSlider then
                UI.teleSlider.Set(7)
        end
        CFG.CineFovMin = 30
        CFG.CineFovMax = 70
        if UI.fovMinSlider then
                UI.fovMinSlider.Set(30)
        end
        if UI.fovMaxSlider then
                UI.fovMaxSlider.Set(70)
        end
        setFilter("OFF")
        setRatio("FULL")
        updateChip()
        refreshTargetList()
        if UI.updateLockBtn then
                UI.updateLockBtn()
        end
        flash()
        notify("Script di-RESET ke pengaturan awal")
end

-- ═══════════════ LAYER FOTO ═══════════════
local FILTER_PRESETS = {
        TEAL    = { Tint = Color3.fromRGB(255, 236, 214), Sat = 0.18,  Con = 0.12,  Bri = -0.01, Bloom = nil },
        GOLDEN  = { Tint = Color3.fromRGB(255, 214, 170), Sat = 0.22,  Con = 0.06,  Bri = 0.02,  Bloom = nil },
        NEON    = { Tint = Color3.fromRGB(214, 224, 255), Sat = 0.35,  Con = 0.18,  Bri = -0.04, Bloom = nil },
        VINTAGE = { Tint = Color3.fromRGB(255, 238, 205), Sat = -0.25, Con = 0.02,  Bri = 0.03,  Bloom = nil },
        BW      = { Tint = Color3.fromRGB(255, 255, 255), Sat = -1,    Con = 0.15,  Bri = 0,     Bloom = nil },
        VIVID   = { Tint = Color3.fromRGB(255, 255, 255), Sat = 0.45,  Con = 0.15,  Bri = 0.01,  Bloom = 0.15 },
        DREAMY  = { Tint = Color3.fromRGB(255, 228, 240), Sat = 0.12,  Con = -0.05, Bri = 0.06,  Bloom = 0.35 },
}

function setFilter(id)
        S.foto.filter = id
        if id == "OFF" then
                PHOTO_CC.Enabled = false
                PHOTO_BLOOM.Enabled = false
        else
                local f = FILTER_PRESETS[id]
                if f then
                        PHOTO_CC.Enabled = true
                        PHOTO_CC.TintColor = f.Tint
                        PHOTO_CC.Saturation = f.Sat
                        PHOTO_CC.Contrast = f.Con
                        PHOTO_CC.Brightness = f.Bri
                        if f.Bloom then
                                PHOTO_BLOOM.Enabled = true
                                PHOTO_BLOOM.Intensity = f.Bloom
                        else
                                PHOTO_BLOOM.Enabled = false
                        end
                end
        end
        for fid, btn in pairs(UI.filterBtns) do
                local st = btn:FindFirstChildOfClass("UIStroke")
                if fid == id then
                        st.Transparency = 0.05
                        btn.TextColor3 = CFG.Neon1
                else
                        st.Transparency = 0.65
                        btn.TextColor3 = CFG.TXT
                end
        end
end

local RATIO_VALUES = {
        ["21:9"] = 21 / 9,
        ["16:9"] = 16 / 9,
        ["4:5"]  = 4 / 5,
        ["1:1"]  = 1,
        ["9:16"] = 9 / 16,
}

function updateRatioMasks()
        local id = S.foto.ratio
        local cam = workspace.CurrentCamera
        local vp = cam.ViewportSize
        if id == "FULL" then
                UI.maskT.Size = UDim2.new(1, 0, 0, 0)
                UI.maskB.Size = UDim2.new(1, 0, 0, 0)
                UI.maskL.Size = UDim2.new(0, 0, 1, 0)
                UI.maskR.Size = UDim2.new(0, 0, 1, 0)
        else
                local R = RATIO_VALUES[id]
                local va = vp.X / vp.Y
                if R > va then
                        local barH = (vp.Y - vp.X / R) / 2
                        UI.maskT.Size = UDim2.new(1, 0, 0, barH)
                        UI.maskB.Size = UDim2.new(1, 0, 0, barH)
                        UI.maskL.Size = UDim2.new(0, 0, 1, 0)
                        UI.maskR.Size = UDim2.new(0, 0, 1, 0)
                else
                        local barW = (vp.X - vp.Y * R) / 2
                        UI.maskT.Size = UDim2.new(1, 0, 0, 0)
                        UI.maskB.Size = UDim2.new(1, 0, 0, 0)
                        UI.maskL.Size = UDim2.new(0, barW, 1, 0)
                        UI.maskR.Size = UDim2.new(0, barW, 1, 0)
                end
        end
        applyLetterbox()
end

function setRatio(id)
        S.foto.ratio = id
        updateRatioMasks()
        for rid, btn in pairs(UI.ratioBtns) do
                local st = btn:FindFirstChildOfClass("UIStroke")
                if rid == id then
                        st.Transparency = 0.05
                        btn.TextColor3 = CFG.Neon2
                else
                        st.Transparency = 0.65
                        btn.TextColor3 = CFG.TXT
                end
        end
        if id ~= "FULL" then
                notify("Rasio " .. id .. " aktif")
        end
end

function setWatermark(state)
        S.foto.wm = state
        UI.wm.Visible = state
end

function applyDof()
        if S.mode ~= "CINE" and DOF_TRANS.Enabled then
                DOF_TRANS.Enabled = false -- transisi defokus hanya di CINE
        end
        if S.foto.dof then
                DOF.Enabled = true
                local want = S.foto.focus
                local r = getRoot(getSubjectChar())
                if r then
                        want = (Camera.CFrame.Position - r.Position).Magnitude
                end
                if not S.fotoFocus then
                        S.fotoFocus = want
                end
                S.fotoFocus = S.fotoFocus + (want - S.fotoFocus) * 0.3
                DOF.FocusDistance = S.fotoFocus
                DOF.InFocusRadius = 6 + S.foto.blur * 0.06
                DOF.FarIntensity = 0.15 + (S.foto.blur / 100) * 0.65
                DOF.NearIntensity = (S.foto.blur / 100) * 0.4
        elseif S.mode == "CINE" and (S.cine.dofK or 0) > 0.02 then
                DOF.Enabled = true
                DOF.FocusDistance = S.cine.focusDist or 10
                DOF.InFocusRadius = 7
                DOF.FarIntensity = 0.22 + 0.25 * S.cine.dofK
                DOF.NearIntensity = 0
        elseif S.mode == "RACE" and (S.race.dofK or 0) > 0.02 then
                DOF.Enabled = true
                DOF.FocusDistance = S.race.focusDist or 10
                DOF.InFocusRadius = 7
                DOF.FarIntensity = 0.22 + 0.25 * S.race.dofK
                DOF.NearIntensity = 0
        else
                DOF.Enabled = false
        end
end

function takePhoto()
        if S.shooting then
                return
        end
        S.shooting = true
        notify("Layar bersih 5 detik — ambil screenshotmu!", 2)
        local els = { UI.panel, UI.notifBox }
        local states = {}
        for i, el in ipairs(els) do
                states[i] = el.Visible
                el.Visible = false
        end
        task.delay(5, function()
                for i, el in ipairs(els) do
                        el.Visible = states[i]
                end
                S.shooting = false
        end)
end

-- ═══════════════ KAMERA ANTI-TEMBOSS (DINDING / TANAH / OBJEK) ═══════════════
local camRay = RaycastParams.new()
camRay.FilterType = Enum.RaycastFilterType.Exclude
camRay.FilterDescendantsInstances = { workspace.CurrentCamera }
camRay.IgnoreWater = true

local CLIP_SAFE = 0.4   -- jarak aman kamera dari permukaan (stud)
local lastFreePos = nil -- posisi free cam frame sebelumnya (anti temboss saat terbang)

function refreshCamFilter()
        if unloadDone then
                return
        end
        local list = { workspace.CurrentCamera }
        for _, pl in ipairs(Players:GetPlayers()) do
                if pl.Character then
                        table.insert(list, pl.Character)
                end
        end
        local myc = myChar()
        if myc then
                table.insert(list, myc)
                local hum = myc:FindFirstChildOfClass("Humanoid")
                local seat = hum and hum.SeatPart or nil
                if seat then
                        local veh = seat:FindFirstAncestorOfClass("Model")
                        if veh then
                                table.insert(list, veh)
                        end
                end
        end
        local subj = getSubjectChar()
        if subj and subj.Parent then
                table.insert(list, subj)
                local shum = subj:FindFirstChildOfClass("Humanoid")
                local sseat = shum and shum.SeatPart or nil
                if sseat then
                        local sveh = sseat:FindFirstAncestorOfClass("Model")
                        if sveh then
                                table.insert(list, sveh)
                        end
                end
        end
        camRay.FilterDescendantsInstances = list
end

local siTembusCache = setmetatable({}, { __mode = "k" })
local function siTembus(inst)
        local c = siTembusCache[inst]
        if c ~= nil then
                return c
        end
        local ok = false
        if inst and inst:IsA("BasePart") then
                local m = inst:FindFirstAncestorOfClass("Model")
                local hop = 0
                while m and hop < 4 do
                        if m:FindFirstChildOfClass("Humanoid") or m:FindFirstChildOfClass("VehicleSeat") then
                                ok = true
                                break
                        end
                        hop = hop + 1
                        m = m:FindFirstAncestorOfClass("Model")
                end
                if not ok then
                        local s = inst.Size
                        local a, b, cc = s.X, s.Y, s.Z
                        if a > b then a, b = b, a end
                        if b > cc then b, cc = cc, b end
                        if a > b then a, b = b, a end
                        ok = cc < CFG.CRSmall or b < CFG.CRThin
                end
        end
        siTembusCache[inst] = ok
        return ok
end

local function castClear(from, dirUnit, dist)
        local origin, remaining = from, dist
        for _ = 1, 12 do
                local hit = workspace:Raycast(origin, dirUnit * remaining, camRay)
                if not hit then
                        return nil
                end
                if hit.Instance.CanCollide and not (CFG.CRPass and siTembus(hit.Instance)) then
                        return hit
                end
                local step = (hit.Position - origin).Magnitude + 0.15
                origin = hit.Position + dirUnit * 0.15
                remaining = remaining - step
                if remaining <= 0.2 then
                        return nil
                end
        end
        return nil
end

local function castGround(from, dirUnit, dist)
        local origin, remaining = from, dist
        for _ = 1, 4 do
                local hit = workspace:Raycast(origin, dirUnit * remaining, camRay)
                if not hit then
                        return nil
                end
                if hit.Instance.CanCollide and hit.Normal.Y > 0.55 then
                        return hit
                end
                local step = (hit.Position - origin).Magnitude + 0.15
                origin = hit.Position + dirUnit * 0.15
                remaining = remaining - step
                if remaining <= 0.2 then
                        return nil
                end
        end
        return nil
end

local function groundOnly(prevPos, pos)
        if not CFG.AntiClip or not prevPos then
                return pos
        end
        local v = pos - prevPos
        local d = v.Magnitude
        if d > 0.05 then
                local hit = castGround(prevPos, v.Unit, d)
                if hit then
                        local nd = math.max((hit.Position - prevPos).Magnitude - 0.15, 0.05)
                        pos = prevPos + v.Unit * nd
                end
        end
        return pos
end

local function floorGuard(pos)
        if not CFG.AntiClip then
                return pos
        end
        local clr = 0.3
        local hit = workspace:Raycast(pos, Vector3.new(0, -2.5, 0), camRay)
        if hit and hit.Instance.CanCollide and hit.Normal.Y > 0.55 then
                if pos.Y - hit.Position.Y < clr then
                        pos = Vector3.new(pos.X, hit.Position.Y + clr, pos.Z)
                end
                return pos
        end
        hit = workspace:Raycast(pos, Vector3.new(0, 3, 0), camRay)
        if hit and hit.Instance.CanCollide and hit.Normal.Y < -0.55 then
                pos = Vector3.new(pos.X, hit.Position.Y + clr, pos.Z)
        end
        return pos
end

local function safeOrbit(focusPos, wantPos)
        if not CFG.AntiClip then
                return wantPos
        end
        local v = wantPos - focusPos
        local d = v.Magnitude
        if d > 1 then
                local hit = castClear(focusPos, v.Unit, d)
                if hit then
                        local nd = math.max((hit.Position - focusPos).Magnitude - CLIP_SAFE, 1)
                        return focusPos + v.Unit * nd
                end
        end
        return wantPos
end

local function freeClip(pos)
        local out = groundOnly(lastFreePos, pos)
        lastFreePos = out
        return out
end

-- ═══════════════ FREE CAM (mesin v11: halus + terbang + anti menggeleng) ═══════════════
local function lerpAngle(a, b, t)
        local diff = (b - a) % (2 * math.pi)
        if diff > math.pi then
                diff = diff - 2 * math.pi
        end
        return a + diff * t
end

local function freeUpdate(dt)
        local alpha = 1 - math.exp(-dt / CFG.Smoothness)
        local la = 1 - math.exp(-dt / CFG.FreeLook)
        S.yaw = lerpAngle(S.yaw, S.yawT, la)
        S.pitch = S.pitch + (S.pitchT - S.pitch) * la
        if S.fly then
                local f = S.fly
                f.t = math.min(f.t + dt, f.dur)
                local k0 = math.clamp(f.t / f.dur, 0, 1)
                local k = k0 * k0 * (3 - 2 * k0)
                S.freePos = f.fromPos:Lerp(f.toPos, k)
                lastFreePos = S.freePos -- penerbangan disengaja: lewati clip, lanjutkan setelah mendarat
                S.yaw = lerpAngle(f.fromYaw, f.toYaw, k)
                S.pitch = f.fromPitch + (f.toPitch - f.fromPitch) * k
                S.yawT = S.yaw   -- sinkron target: saat mendarat tidak ada sentakan sisa
                S.pitchT = S.pitch
                Camera.CFrame = CFrame.fromOrientation(S.pitch, S.yaw, 0) + S.freePos
                if f.t >= f.dur then
                        S.fly = nil
                end
        else
                local cf = CFrame.fromOrientation(S.pitch, S.yaw, 0)
                local f, r = cf.LookVector, cf.RightVector
                local move = Vector3.new(0, 0, 0)
                if keys[Enum.KeyCode.W] then
                        move = move + f
                end
                if keys[Enum.KeyCode.S] then
                        move = move - f
                end
                if keys[Enum.KeyCode.A] then
                        move = move - r
                end
                if keys[Enum.KeyCode.D] then
                        move = move + r
                end
                if keys[Enum.KeyCode.E] then
                        move = move + Vector3.new(0, 1, 0)
                end
                if keys[Enum.KeyCode.Q] then
                        move = move - Vector3.new(0, 1, 0)
                end
                local spd = CFG.Speed * (S.turbo and CFG.TurboMult or 1) * (S.ctrlDown and CFG.SlowMult or 1)
                if move.Magnitude > 0.001 then
                        move = move.Unit * spd
                end
                S.freeVel = S.freeVel:Lerp(move, alpha)
                S.freePos = floorGuard(freeClip(S.freePos + S.freeVel * dt)) -- dinding bebas · tanah ditahan + dijaga tak masuk lantai
                if S.locked and S.lockPlayer then
                        local c = S.lockPlayer.Character
                        local h = c and getHum(c) or nil
                        local tr = (c and c.Parent and h and h.Health > 0) and c:FindFirstChild("HumanoidRootPart") or nil
                        if tr then
                                local tp = tr.Position + Vector3.new(0, 1.5, 0)
                                if not S.aimY then
                                        S.aimY = tp.Y
                                end
                                local ay = 1 - math.exp(-dt / CFG.AimYDamp)
                                S.aimY = S.aimY + (tp.Y - S.aimY) * ay
                                local dir = Vector3.new(tp.X, S.aimY, tp.Z) - S.freePos
                                if dir.Magnitude > 0.1 then
                                        local lv = dir.Unit
                                        local ty = math.atan2(-lv.X, -lv.Z)
                                        local tpi = math.clamp(math.asin(math.clamp(lv.Y, -1, 1)), -1.45, 1.45)
                                        S.yawT = lerpAngle(S.yawT, ty, alpha * 0.55)
                                        S.pitchT = S.pitchT + (tpi - S.pitchT) * alpha * 0.55
                                end
                        end
                else
                        S.aimY = nil
                end
                Camera.CFrame = CFrame.fromOrientation(S.pitch, S.yaw, 0) + S.freePos
        end
        Camera.FieldOfView = Camera.FieldOfView + (CFG.FOV - Camera.FieldOfView) * alpha
end

-- ═══════════════ PRO CAM (mesin super halus: input → pivot → posisi → rotasi, semua dihaluskan) ═══════════════
local function proUpdate(dt)
        local char = getSubjectChar()
        local root = getRoot(char)
        if not root then
                return
        end
        local la = 1 - math.exp(-dt / CFG.ProLook)
        S.proYaw = lerpAngle(S.proYaw, S.proYawT, la)
        S.proPitch = S.proPitch + (S.proPitchT - S.proPitch) * la
        local za = 1 - math.exp(-dt / CFG.ProZoom)
        S.proDist = S.proDist + (S.proDistT - S.proDist) * za
        local vel = root.AssemblyLinearVelocity
        local targetPivot = root.Position + Vector3.new(0, 1.5, 0)
        if S.proGlide then
                local g = S.proGlide
                g.t = math.min(g.t + dt, g.dur)
                local k0 = math.clamp(g.t / g.dur, 0, 1)
                local k = k0 * k0 * (3 - 2 * k0)
                S.proPivot = g.fromPivot:Lerp(targetPivot, k)
                S.proPivotVel = Vector3.new(0, 0, 0)
                if g.t >= g.dur then
                        S.proGlide = nil
                end
        else
                if not S.proPivot then
                        S.proPivot = targetPivot
                        S.proPivotVel = Vector3.new(0, 0, 0)
                end
                local gap = (targetPivot - S.proPivot).Magnitude
                if gap > 40 then
                        S.proPivot = targetPivot
                        S.proPivotVel = Vector3.new(0, 0, 0)
                        S.proPos = nil
                        S.proCF = nil
                end
                local aH = 1 - math.exp(-dt / CFG.ProVelH)
                local aV = 1 - math.exp(-dt / CFG.ProVelV)
                local vy = math.clamp(vel.Y, -CFG.ProVelYMax, CFG.ProVelYMax)
                local pv = S.proPivotVel or Vector3.new(0, 0, 0)
                S.proPivotVel = Vector3.new(
                        pv.X + (vel.X - pv.X) * aH,
                        pv.Y + (vy - pv.Y) * aV,
                        pv.Z + (vel.Z - pv.Z) * aH
                )
                S.proPivot = S.proPivot + S.proPivotVel * dt
                local err = targetPivot - S.proPivot
                local eH = math.sqrt(err.X * err.X + err.Z * err.Z)
                local kH = math.clamp(eH / CFG.ProSnap, 0, 1)
                local kV = math.clamp(math.abs(err.Y) / CFG.ProSnap, 0, 1)
                local tauH = CFG.ProErr * (1 - (1 - CFG.ProErrFast / CFG.ProErr) * kH)
                local tauV = CFG.ProErr * (1.7 - 1.3 * kV)
                local aEH = 1 - math.exp(-dt / tauH)
                local aEV = 1 - math.exp(-dt / tauV)
                S.proPivot = Vector3.new(
                        S.proPivot.X + err.X * aEH,
                        S.proPivot.Y + err.Y * aEV,
                        S.proPivot.Z + err.Z * aEH
                )
        end
        local rot = CFrame.fromOrientation(S.proPitch, S.proYaw, 0)
        local desiredPos = S.proPivot + rot:VectorToWorldSpace(Vector3.new(0, 0, S.proDist))
        desiredPos = groundOnly(S.proPos or desiredPos, desiredPos) -- ANTI-TEMBOSS TANAH
        desiredPos = floorGuard(desiredPos)
        if S.proPos then
                S.proPos = expLerp(S.proPos, desiredPos, dt, 1 / CFG.ProPos)
                S.proPos = floorGuard(S.proPos)
        else
                S.proPos = desiredPos
        end
        local wantCF = CFrame.lookAt(S.proPos, S.proPivot)
        if S.proCF then
                Camera.CFrame = S.proCF:Lerp(wantCF, 1 - math.exp(-dt / CFG.ProFinal))
        else
                Camera.CFrame = wantCF
        end
        S.proCF = Camera.CFrame
        Camera.FieldOfView = Camera.FieldOfView + (CFG.FOV - Camera.FieldOfView) * (1 - math.exp(-dt / 0.25))
end

-- ═══════════════ SHOT DIRECTOR (CINEMATIC) ═══════════════
local function seedSway(P, f)
        P.swf = f or 1.1
        P.swp1 = rr(0, math.pi * 2)
        P.swp2 = rr(0, math.pi * 2)
end

local function sway(P, t, amp)
        return Vector3.new(
                math.sin(t * P.swf + P.swp1) * amp,
                math.sin(t * P.swf * 0.77 + P.swp2) * amp * 0.6,
                math.sin(t * P.swf * 0.53 + P.swp1 * 1.7) * amp * 0.4
        )
end

local function smoothstep(k)
        k = math.clamp(k, 0, 1)
        return k * k * (3 - 2 * k)
end

local function smoothDir(P, ctx, dt, k)
        local cur = (P.dirMode == "look") and ctx.look or ctx.moveDir
        if P.dir then
                local alpha = 1 - math.exp(-(k or 2.5) * dt)
                P.dir = P.dir + (cur - P.dir) * alpha
                if P.dir.Magnitude < 0.05 then
                        P.dir = cur
                end
                if P.dir.Magnitude > 0.001 then
                        P.dir = P.dir.Unit
                end
        else
                P.dir = cur
        end
        return P.dir
end

local function cineCtx(dt)
        local char = getSubjectChar()
        local root = getRoot(char)
        local hum = getHum(char)
        local pos = workspace.CurrentCamera.CFrame.Position
        local speed = 0
        local moveDir = Vector3.new(0, 0, -1)
        local look = Vector3.new(0, 0, -1)
        if root then
                pos = root.Position
                local vel = root.AssemblyLinearVelocity
                speed = flat(vel).Magnitude
                look = flatUnit(root.CFrame.LookVector)
                local md = flatUnit(hum and hum.MoveDirection or Vector3.new(0, 0, 0))
                if speed > 2 then
                        moveDir = flatUnit(vel)
                elseif md.Magnitude > 0.05 then
                        moveDir = md
                else
                        moveDir = look
                end
                if S.cineStabChar ~= root then
                        S.cineStabChar = root
                        S.cineStabY = pos.Y
                end
                if dt then
                        local grounded = (hum == nil) or (hum.FloorMaterial ~= Enum.Material.Air)
                        local kY = grounded and CFG.CineStabG or CFG.CineStabA
                        S.cineStabY = expLerp(S.cineStabY, pos.Y, dt, kY)
                else
                        S.cineStabY = pos.Y
                end
                pos = Vector3.new(pos.X, S.cineStabY, pos.Z)
        end
        local seated = (hum ~= nil) and (hum.SeatPart ~= nil)
        local context
        if seated then
                context = "vehicle"
        elseif speed < 2.2 then
                context = "idle"
        elseif speed < 15 then
                context = "walk"
        else
                context = "run"
        end
        local wantK = CFG.DistDekat + (CFG.DistJauh - CFG.DistDekat) * math.clamp(speed / 26, 0, 1)
        if dt then
                if not S.cine.distK then
                        S.cine.distK = wantK
                end
                S.cine.distK = expLerp(S.cine.distK, wantK, dt, 0.8)
        end
        return {
                char = char,
                root = root,
                hum = hum,
                pos = pos,
                speed = speed,
                moveDir = moveDir,
                look = look,
                seated = seated,
                context = context,
                distK = S.cine.distK or wantK,
                head = pos + Vector3.new(0, 1.6, 0),
        }
end

-- ═══════════════ LIBRARY SHOT CINEMATIC (21 SHOT · 2 KATEGORI · PENUH GERAKAN) ═══════════════
local SHOTS = {}

SHOTS["REVEAL SHOT"] = {
        cat = "BOTH",
        face = "BELAKANG", -- kamera di belakang, mundur memperkenalkan subjek
        weights = { idle = 4, walk = 3, run = 2.5, vehicle = 2.5 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.d0 = rr(16, 22) * P.dm
                P.d1 = P.d0 + rr(12, 18) * P.dm
                P.h0 = rr(1, 1.6)
                P.h1 = rr(3.5, 6)
                P.fov = rr(50, 58)
                seedSway(P, 0.7)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 1.6)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local h = P.h0 + (P.h1 - P.h0) * k
                local p = ctx.pos - dir * d + Vector3.new(0, h, 0) + sway(P, t, 0.14)
                return CFrame.lookAt(p, ctx.head + dir * 4), P.fov - 6 * k, 0
        end,
}

SHOTS["WIDE GROUND-LEVEL SHOT"] = {
        cat = "WIDE",
        face = "BELAKANG", -- dari belakang, memperlihatkan lokasi
        weights = { idle = 4.5, walk = 3.5, run = 3, vehicle = 3 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.d = rr(30, 42) * P.dm
                P.h = rr(0.7, 1.4)
                P.fov = rr(55, 64)
                seedSway(P, 0.6)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 1.4)
                local d = math.max(P.d - t * 0.6, 22 * P.dm) -- dorongan maju halus (tetap bergerak)
                local p = ctx.pos - dir * d + Vector3.new(0, P.h, 0) + sway(P, t, 0.12)
                return CFrame.lookAt(p, ctx.head + dir * 8), P.fov, 0
        end,
}

SHOTS["SIDE TRACK"] = {
        cat = "BOTH",
        face = "SAMPING", -- bergerak dari samping
        weights = { idle = 1, walk = 4, run = 4, vehicle = 3 },
        enter = function(ctx, P)
                P.absd = rr(14, 20) * P.dm
                P.side = (math.random() < 0.5 and -1 or 1) * P.absd
                P.h = rr(1.5, 2.8)
                P.fov = rr(58, 66)
                P.dir = ctx.moveDir
                seedSway(P, 1.1)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2)
                local perp = Vector3.new(-dir.Z, 0, dir.X) * P.side
                local p = ctx.pos + perp + Vector3.new(0, P.h, 0) + sway(P, t, 0.15)
                return CFrame.lookAt(p, ctx.head), P.fov, closeDof(P.absd, 5)
        end,
}

SHOTS["EYE-LEVEL TRACK"] = {
        cat = "CLOSE",
        face = "DEPAN", -- kamera di depan, sejajar mata
        weights = { idle = 1.5, walk = 3.5, run = 3, vehicle = 2.5 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.d = rr(10, 14) * P.dm
                P.side = rr(-2.2, 2.2)
                P.h = 1.55
                P.fov = rr(48, 56)
                seedSway(P, 1)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.2)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local p = ctx.pos + dir * P.d + perp * P.side + Vector3.new(0, P.h, 0) + sway(P, t, 0.1)
                return CFrame.lookAt(p, ctx.head), P.fov, closeDof(P.d, 5)
        end,
}

SHOTS["LOW ANGLE HERO"] = {
        cat = "CLOSE",
        face = "DEPAN", -- super rendah dari depan
        weights = { idle = 2.5, walk = 2.5, run = 2, vehicle = 1.5 },
        enter = function(ctx, P)
                P.dirMode = "look"
                P.d0 = rr(13, 17) * P.dm
                P.d1 = rr(8, 11) * P.dm
                P.h = rr(0.5, 1.1)
                P.fov = rr(50, 60)
                P.dir = ctx.look
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                local face = smoothDir(P, ctx, dt, 2.2)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local p = ctx.pos + face * d + Vector3.new(0, P.h, 0) + sway(P, t, 0.08)
                return CFrame.lookAt(p, ctx.head + Vector3.new(0, 0.4, 0)), P.fov, closeDof(d, 4)
        end,
}

SHOTS["LEAD AHEAD"] = {
        cat = "BOTH",
        face = "DEPAN", -- di depan bergerak mundur menghadap subjek
        weights = { idle = 1, walk = 3.5, run = 4, vehicle = 3.5 },
        enter = function(ctx, P)
                P.d = rr(18, 26) * P.dm
                P.h = rr(2, 4)
                P.fov = rr(55, 63)
                P.dir = ctx.moveDir
                seedSway(P, 1)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.4)
                local p = ctx.pos + dir * P.d + Vector3.new(0, P.h, 0) + sway(P, t, 0.15)
                return CFrame.lookAt(p, ctx.head), P.fov, 0
        end,
}

SHOTS["SLOW ORBIT 180"] = {
        cat = "BOTH",
        face = "SAMPING", -- mengitari lewat samping
        weights = { idle = 3.5, walk = 2, run = 1.5, vehicle = 2 },
        enter = function(ctx, P)
                P.r = rr(13, 19) * P.dm
                P.h = rr(1.6, 3.2)
                P.ang = rr(0, math.pi * 2)
                P.spd = (math.random() < 0.5 and -1 or 1) * math.rad(rr(22, 38)) -- pelan ≈ 180°
                P.fov = rr(52, 62)
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                P.ang = P.ang + P.spd * dt
                local p = ctx.pos + Vector3.new(math.cos(P.ang) * P.r, P.h, math.sin(P.ang) * P.r) + sway(P, t, 0.12)
                return CFrame.lookAt(p, ctx.head), P.fov, closeDof(P.r, 5)
        end,
}

SHOTS["FRONT THREE-QUARTER PUSH-IN"] = {
        cat = "CLOSE",
        face = "DEPAN", -- mendekat dari sudut depan samping
        weights = { idle = 3, walk = 2, run = 1.2, vehicle = 1 },
        enter = function(ctx, P)
                P.dirMode = "look"
                P.dir = ctx.look
                P.ang = rr(0.5, 0.95) -- 28°-55° dari depan
                P.side = (math.random() < 0.5 and -1 or 1)
                P.d0 = rr(15, 19) * P.dm
                P.d1 = rr(9, 12) * P.dm
                P.h = rr(1.1, 2)
                P.fov = rr(42, 52)
                seedSway(P, 0.7)
        end,
        update = function(P, t, dt, ctx)
                local face = smoothDir(P, ctx, dt, 2)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local dir3q = rotY(face, P.ang * P.side)
                local p = ctx.pos + dir3q * d + Vector3.new(0, P.h, 0) + sway(P, t, 0.08)
                return CFrame.lookAt(p, ctx.head), P.fov, closeDof(d, 4)
        end,
}

SHOTS["REAR CHASE LOW"] = {
        cat = "CLOSE",
        face = "BELAKANG", -- kejar rendah dari belakang
        weights = { idle = 0.6, walk = 3, run = 4, vehicle = 4 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.d = rr(11, 15) * P.dm
                P.h = rr(1, 1.8)
                P.fov = rr(56, 64)
                seedSway(P, 1.3)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.6)
                local p = ctx.pos - dir * P.d + Vector3.new(0, P.h, 0) + sway(P, t, 0.16)
                return CFrame.lookAt(p, ctx.head + dir * 4), P.fov, closeDof(P.d, 4)
        end,
}

SHOTS["RACK FOCUS CLOSE-UP"] = {
        cat = "CLOSE",
        face = "DEPAN", -- dekat wajah dari depan
        weights = { idle = 2.5, walk = 1, run = 0.2, vehicle = 0.2 },
        dmK = 0.45, -- close-up: ikut kondisi tapi dijaga tetap dekat
        enter = function(ctx, P)
                P.dirMode = "look"
                P.d = rr(5, 7) * P.dm
                P.hOff = rr(0.5, 1.2)
                P.side = rr(-1.6, 1.6)
                P.fov = rr(30, 38)
                seedSway(P, 0.7)
        end,
        update = function(P, t, dt, ctx)
                local face = smoothDir(P, ctx, dt, 3)
                local perp = Vector3.new(-face.Z, 0, face.X)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local p = ctx.pos + face * P.d + perp * P.side * (k - 0.5) + Vector3.new(0, P.hOff, 0) + sway(P, t, 0.05)
                return CFrame.lookAt(p, ctx.head), P.fov, 1
        end,
}

SHOTS["FOREGROUND WIPE"] = {
        cat = "BOTH",
        face = "DEPAN", -- menyapu di depan subjek
        weights = { idle = 2.5, walk = 2, run = 1.5, vehicle = 1.5 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.dF = rr(7, 10) * P.dm
                P.xs = rr(7, 11) * P.dm
                P.sign = (math.random() < 0.5 and -1 or 1)
                P.h = rr(1.2, 2)
                P.fov = rr(50, 60)
                P.cut = false
                seedSway(P, 0.8)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local k = math.clamp(t / math.max(S.cine.dur, 0.1), 0, 1)
                local lateral = (k * 2 - 1) * P.xs * P.sign
                if not P.cut and math.abs(lateral) > P.xs * 0.92 then
                        P.cut = true
                        S.cine.dur = math.min(S.cine.dur, S.cine.t + 0.15)
                end
                local p = ctx.pos + dir * P.dF + perp * lateral + Vector3.new(0, P.h, 0) + sway(P, t, 0.06)
                return CFrame.lookAt(p, ctx.head), P.fov, 0.85
        end,
}

SHOTS["DOLLY PULL-OUT"] = {
        cat = "BOTH",
        face = "BELAKANG", -- menjauh perlahan dari belakang
        weights = { idle = 3, walk = 2.5, run = 2, vehicle = 2.5 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.d0 = rr(9, 13) * P.dm
                P.d1 = P.d0 + rr(16, 26) * P.dm
                P.h0 = 1.4
                P.h1 = rr(2.5, 4.5)
                P.fov0 = rr(44, 52)
                P.fov1 = P.fov0 + rr(8, 14)
                seedSway(P, 0.6)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 1.8)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local h = P.h0 + (P.h1 - P.h0) * k
                local p = ctx.pos - dir * d + Vector3.new(0, h, 0) + sway(P, t, 0.1)
                return CFrame.lookAt(p, ctx.head), P.fov0 + (P.fov1 - P.fov0) * k, closeDof(d, 5)
        end,
}

SHOTS["CRANE DOWN FRONT"] = {
        cat = "BOTH",
        face = "DEPAN", -- kran turun dari atas depan ke sejajar mata
        weights = { idle = 2.5, walk = 2.5, run = 1.5, vehicle = 2 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.d0 = rr(16, 20) * P.dm
                P.d1 = rr(11, 14) * P.dm
                P.h0 = rr(6, 9)
                P.h1 = rr(1.4, 2)
                P.fov = rr(48, 56)
                seedSway(P, 0.7)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 1.8)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local h = P.h0 + (P.h1 - P.h0) * k
                local p = ctx.pos + dir * d + Vector3.new(0, h, 0) + sway(P, t, 0.08)
                return CFrame.lookAt(p, ctx.head), P.fov, closeDof(d, 5)
        end,
}

SHOTS["CRASH ZOOM PUSH"] = {
        cat = "CLOSE",
        face = "DEPAN", -- dorongan cepat dari depan
        weights = { idle = 2, walk = 2.5, run = 1.5, vehicle = 1.5 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.side = rr(-2.5, 2.5)
                P.d0 = rr(19, 24) * P.dm
                P.d1 = rr(6.5, 8.5) * P.dm
                P.fov0 = rr(58, 64)
                P.fov1 = rr(42, 48)
                P.h = rr(1.2, 2)
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.4)
                local k = smoothstep(t / math.max(S.cine.dur * 0.55, 0.1))
                local kF = smoothstep(t / math.max(S.cine.dur * 0.8, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local fov = P.fov0 + (P.fov1 - P.fov0) * kF
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local p = ctx.pos + dir * d + perp * P.side * (1 - k) + Vector3.new(0, P.h, 0) + sway(P, t, 0.07)
                return CFrame.lookAt(p, ctx.head), fov, closeDof(d, 4)
        end,
}

SHOTS["WHIP ARC PASS"] = {
        cat = "BOTH",
        face = "SAMPING", -- sapuan melengkung lewat samping-depan
        weights = { idle = 1.5, walk = 2.5, run = 3, vehicle = 2.5 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.sign = (math.random() < 0.5 and -1 or 1)
                P.sideA = rr(8.5, 12) * P.dm
                P.bulge = rr(2, 4) -- arc mendekat ke subjek di tengah sapuan
                P.a0 = rr(-9, -6) -- mulai dari belakang samping
                P.a1 = rr(10, 14) -- berakhir di depan samping
                P.h = rr(1.4, 2.4)
                P.fov = rr(54, 62)
                seedSway(P, 0.8)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.6)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local along = P.a0 + (P.a1 - P.a0) * k
                local side = P.sign * (P.sideA + math.sin(k * math.pi) * P.bulge)
                local p = ctx.pos + dir * along + perp * side + Vector3.new(0, P.h, 0) + sway(P, t, 0.08)
                return CFrame.lookAt(p, ctx.head), P.fov, closeDof(math.abs(side), 6)
        end,
}

SHOTS["FOLLOW CRANE RISE"] = {
        cat = "BOTH",
        face = "BELAKANG", -- dari belakang, kran naik pelan
        weights = { idle = 1.5, walk = 3, run = 3.5, vehicle = 3 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.d0 = rr(10, 14) * P.dm
                P.d1 = P.d0 + rr(4, 8) * P.dm
                P.h0 = rr(1.4, 2)
                P.h1 = rr(4.5, 7)
                P.fov = rr(52, 60)
                seedSway(P, 0.8)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local h = P.h0 + (P.h1 - P.h0) * k
                local p = ctx.pos - dir * d + Vector3.new(0, h, 0) + sway(P, t, 0.1)
                return CFrame.lookAt(p, ctx.head + dir * 5), P.fov, 0
        end,
}

SHOTS["DOLLY ZOOM VERTIGO"] = {
        cat = "CLOSE",
        face = "DEPAN", -- dari depan, jarak & FOV saling mengunci
        weights = { idle = 2.5, walk = 1.5, run = 0.8, vehicle = 0.8 },
        enter = function(ctx, P)
                P.dirMode = "look"
                P.dir = ctx.look
                P.fov0 = rr(32, 36)
                P.fov1 = rr(56, 62)
                P.kSize = 5.2 -- konstanta ukuran: d * tan(fov/2) tetap → subjek tak berubah besar
                P.hOff = rr(0.8, 1.6)
                P.side = rr(-1.5, 1.5)
                seedSway(P, 0.6)
        end,
        update = function(P, t, dt, ctx)
                local face = smoothDir(P, ctx, dt, 2)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local fov = P.fov0 + (P.fov1 - P.fov0) * k
                local d = P.kSize / math.tan(math.rad(fov * 0.5)) -- subjek ukurannya TETAP di frame
                local perp = Vector3.new(-face.Z, 0, face.X)
                local p = ctx.pos + face * d + perp * P.side + Vector3.new(0, P.hOff, 0) + sway(P, t, 0.05)
                return CFrame.lookAt(p, ctx.head), fov, closeDof(d, 4)
        end,
}

SHOTS["SPIRAL ASCEND ORBIT"] = {
        cat = "BOTH",
        face = "SAMPING", -- mengitari lewat samping sambil naik
        weights = { idle = 2.5, walk = 2, run = 1.5, vehicle = 1.5 },
        enter = function(ctx, P)
                P.r0 = rr(14, 18) * P.dm
                P.r1 = rr(9, 12) * P.dm
                P.h0 = rr(1, 1.8)
                P.h1 = rr(5, 7.5)
                P.ang = rr(0, math.pi * 2)
                P.spd = (math.random() < 0.5 and -1 or 1) * math.rad(rr(42, 56))
                P.fov = rr(50, 58)
                seedSway(P, 0.8)
        end,
        update = function(P, t, dt, ctx)
                P.ang = P.ang + P.spd * dt
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local r = P.r0 + (P.r1 - P.r0) * k
                local h = P.h0 + (P.h1 - P.h0) * k
                local p = ctx.pos + Vector3.new(math.cos(P.ang) * r, h, math.sin(P.ang) * r) + sway(P, t, 0.09)
                return CFrame.lookAt(p, ctx.head), P.fov - 4 * k, closeDof(r, 5)
        end,
}

SHOTS["ORBIT 360 TURBO"] = {
        cat = "BOTH",
        face = "SAMPING", -- mengitari penuh lewat samping
        weights = { idle = 3, walk = 2, run = 1.5, vehicle = 1.5 },
        enter = function(ctx, P)
                P.r = rr(12, 17) * P.dm
                P.h = rr(1.6, 3)
                P.wav = rr(0.6, 1.2) -- gelombang naik-turun lembut
                P.ang = rr(0, math.pi * 2)
                P.spd = (math.random() < 0.5 and -1 or 1) * math.rad(rr(52, 68))
                P.fov = rr(52, 60)
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                P.ang = P.ang + P.spd * dt
                local h = P.h + math.sin(t * 1.3) * P.wav
                local p = ctx.pos + Vector3.new(math.cos(P.ang) * P.r, h, math.sin(P.ang) * P.r) + sway(P, t, 0.1)
                return CFrame.lookAt(p, ctx.head), P.fov, closeDof(P.r, 5)
        end,
}

SHOTS["DUTCH TILT REVEAL"] = {
        cat = "BOTH",
        face = "BELAKANG", -- dari belakang, kamera miring lalu melurus
        weights = { idle = 2, walk = 2.5, run = 2.5, vehicle = 2 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.d0 = rr(13, 17) * P.dm
                P.d1 = rr(8.5, 11) * P.dm
                P.h0 = rr(1.2, 1.8)
                P.h1 = rr(2.8, 4.2)
                P.roll0 = math.rad(rr(7, 10)) * (math.random() < 0.5 and -1 or 1)
                P.fov = rr(50, 58)
                seedSway(P, 0.8)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local h = P.h0 + (P.h1 - P.h0) * k
                local p = ctx.pos - dir * d + Vector3.new(0, h, 0) + sway(P, t, 0.09)
                local cf = CFrame.lookAt(p, ctx.head + dir * 3) * CFrame.Angles(0, 0, P.roll0 * (1 - k))
                return cf, P.fov, 0
        end,
}

SHOTS["S-CURVE FLYBY"] = {
        cat = "BOTH",
        face = "BELAKANG", -- berakhir di belakang (mulai dari depan samping)
        weights = { idle = 0.8, walk = 2, run = 3, vehicle = 3 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.sign = (math.random() < 0.5 and -1 or 1)
                P.a0 = rr(14, 18) * P.dm  -- mulai di depan
                P.a1 = -rr(10, 14) * P.dm -- berakhir di belakang
                P.sideA = rr(9, 13) * P.dm
                P.bulge = rr(3, 5) -- menyelip DEKAT subjek di tengah lintasan (kurva-S)
                P.h0 = rr(1.4, 2)
                P.h1 = rr(2.2, 3.2)
                P.fov = rr(54, 62)
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.4)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local along = P.a0 + (P.a1 - P.a0) * k
                local side = P.sign * (P.sideA - math.sin(k * math.pi) * P.bulge) -- kurva-S
                local h = P.h0 + (P.h1 - P.h0) * k
                local p = ctx.pos + dir * along + perp * side + Vector3.new(0, h, 0) + sway(P, t, 0.09)
                return CFrame.lookAt(p, ctx.head), P.fov, closeDof(math.abs(side), 6)
        end,
}

-- ═══════════════ DETEKSI KERUMUNAN & PEMILIH SHOT ═══════════════
local function crowdCount(root)
        if not root then
                return 0
        end
        local origin = root.Position
        local n = 0
        local seen = {}
        for _, pl in ipairs(Players:GetPlayers()) do
                local c = pl.Character
                if c then
                        seen[c] = true
                        if pl ~= LP then
                                local r = getRoot(c)
                                if r and (r.Position - origin).Magnitude <= CFG.CrowdRadius then
                                        n = n + 1
                                end
                        end
                end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Model") and not seen[obj] then
                        local hum = obj:FindFirstChildOfClass("Humanoid")
                        local r = getRoot(obj)
                        if hum and hum.Health > 0 and r and (r.Position - origin).Magnitude <= CFG.CrowdRadius then
                                n = n + 1
                        end
                end
        end
        return n
end

local FACE_W = { DEPAN = 0.6, SAMPING = 0.2, BELAKANG = 0.2 }
local FACE_ORDER = { "DEPAN", "SAMPING", "BELAKANG" }
local RACE_W = { ["ATAS SAMPING"] = 0.5, ["ATAS DEPAN"] = 0.2, SAMPING = 0.1, BELAKANG = 0.1, DEKAT = 0.1 }
local RACE_ORDER = { "ATAS SAMPING", "ATAS DEPAN", "SAMPING", "BELAKANG", "DEKAT" }
local function pickFaceShot(lib, bobotFn, last, W, ORDER)
        W = W or FACE_W
        ORDER = ORDER or FACE_ORDER
        local groups, gtot = {}, {}
        for _, g in ipairs(ORDER) do
                groups[g] = {}
                gtot[g] = 0
        end
        for name, def in pairs(lib) do
                local w = bobotFn(name, def) or 0
                if w > 0 and name ~= last then
                        local g = def.face or ORDER[1]
                        if not groups[g] then
                                g = ORDER[1]
                        end
                        table.insert(groups[g], { name = name, w = w })
                        gtot[g] = gtot[g] + w
                end
        end
        local avail, atot = {}, 0
        for _, g in ipairs(ORDER) do
                if gtot[g] > 0 then
                        avail[g] = W[g] -- pakai bobot yang dikirim pemanggil (CINE=FACE_W · RACE=RACE_W)
                        atot = atot + W[g]
                end
        end
        if atot <= 0 then
                return nil
        end
        local roll = math.random() * atot
        local chosen = nil
        for _, g in ipairs(ORDER) do
                if avail[g] then
                        roll = roll - avail[g]
                        if roll <= 0 then
                                chosen = g
                                break
                        end
                end
        end
        chosen = chosen or ORDER[1]
        local pool, total = groups[chosen], gtot[chosen]
        if #pool == 0 or total <= 0 then
                return nil
        end
        local r2 = math.random() * total
        for _, it in ipairs(pool) do
                r2 = r2 - it.w
                if r2 <= 0 then
                        return it.name
                end
        end
        return pool[1].name
end

local function pickShot(cat)
        local ctx = cineCtx()
        local name = pickFaceShot(SHOTS, function(n, def)
                if not (def.cat == cat or def.cat == "BOTH") then
                        return 0
                end
                if def.far and not CFG.FarShots then
                        return 0 -- shot jauh dimatikan lewat panel
                end
                return def.weights[ctx.context] or 0
        end, S.cine.lastName, FACE_W, FACE_ORDER)
        if name then
                return name
        end
        local pool, total = {}, 0
        for name2, def in pairs(SHOTS) do
                local w = (def.cat == cat or def.cat == "BOTH") and (def.weights[ctx.context] or 0) or 0
                if def.far and not CFG.FarShots then
                        w = 0
                end
                if w > 0 then
                        table.insert(pool, { name = name2, w = w })
                        total = total + w
                end
        end
        if #pool == 0 then
                return "SLOW ORBIT 180"
        end
        local roll = math.random() * total
        for _, it in ipairs(pool) do
                roll = roll - it.w
                if roll <= 0 then
                        return it.name
                end
        end
        return pool[1].name
end

-- ═══════════════ UPDATE 0.4: TRANSISI DEFOKUS + SHOT JARAK JAUH ═══════════════
local function transBlur(k)
        if not DOF_TRANS then
                return
        end
        DOF_TRANS.Enabled = k > 0.01
        DOF_TRANS.FocusDistance = 0.05
        DOF_TRANS.InFocusRadius = 0
        DOF_TRANS.NearIntensity = 2.2 * k
        DOF_TRANS.FarIntensity = 5 * k
end

SHOTS["ESTABLISHING DRONE"] = {
        cat = "BOTH",
        face = "DEPAN",
        far = true, -- ikut gate CFG.FarShots (panel)
        weights = { idle = 2.2, walk = 1.2, run = 1.6, vehicle = 2.4 },
        dmK = 0.3,
        enter = function(ctx, P)
                P.dir = ctx.look
                P.d = math.clamp(rr(40, 120) * math.max(math.min(P.dm, 1.4), 1), 35, 120)
                P.h = math.clamp(P.d * rr(0.22, 0.42), 12, 55)
                P.side = rr(-1, 1) * math.max(P.d * 0.22, 8)
                P.fov = rr(65, 85)
                P.noLens = true -- fov drone sudah didesain, tidak dilencengkan lens pool
                seedSway(P, 0.5)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 1.2)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local k = t / math.max(S.cine.dur, 0.1)
                local side = P.side * (0.55 + 0.45 * math.sin(k * math.pi))
                local p = ctx.pos + dir * P.d + perp * side + Vector3.new(0, P.h, 0) + sway(P, t, 0.14)
                return CFrame.lookAt(p, ctx.head), P.fov, 0
        end,
}

SHOTS["AERIAL PULL REVEAL"] = {
        cat = "BOTH",
        face = "BELAKANG",
        far = true,
        weights = { idle = 1.6, walk = 1, run = 1.2, vehicle = 2 },
        dmK = 0.3,
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.d0 = math.clamp(rr(25, 40) * math.max(math.min(P.dm, 1.3), 1), 22, 48)
                P.d1 = math.clamp(P.d0 * rr(2.4, 3.2), 70, 120)
                P.h0 = rr(5, 9)
                P.h1 = math.clamp(P.h0 * rr(3, 5), 24, 60)
                P.fov = rr(58, 72)
                P.noLens = true
                seedSway(P, 0.6)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 1.5)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local h = P.h0 + (P.h1 - P.h0) * k
                local p = ctx.pos - dir * d + Vector3.new(0, h, 0) + sway(P, t, 0.1)
                return CFrame.lookAt(p, ctx.head + dir * 4), P.fov, 0
        end,
}

SHOTS["TELE SNIPER"] = {
        cat = "CLOSE",
        face = "DEPAN",
        far = true,
        weights = { idle = 2, walk = 1.2, run = 0.8, vehicle = 1.4 },
        dmK = 0.3,
        enter = function(ctx, P)
                P.dir = ctx.look
                P.d = math.clamp(rr(30, 90) * math.max(math.min(P.dm, 1.2), 1), 30, 90)
                P.h = rr(-0.5, 3)
                P.side = rr(-2.5, 2.5)
                P.fov = rr(26, 34)
                P.noLens = true
                seedSway(P, 0.4)
        end,
        update = function(P, t, dt, ctx)
                local face = smoothDir(P, ctx, dt, 1.8)
                local perp = Vector3.new(-face.Z, 0, face.X)
                local p = ctx.pos + face * P.d + perp * P.side + Vector3.new(0, P.h, 0) + sway(P, t, 0.05)
                return CFrame.lookAt(p, ctx.head), P.fov, 0
        end,
}

local function startShot()
        local ctx = cineCtx()
        local crowd = crowdCount(ctx.root)
        local cat = (crowd >= 2) and "WIDE" or "CLOSE"
        local name = pickShot(cat)
        local def = SHOTS[name]
        S.cine.name = name
        S.cine.lastName = name
        S.cine.def = def
        S.cine.t = 0
        S.cine.dur = math.clamp(CFG.CineTempo + rr(-1.2, 1.2), 2.5, 10)
        S.cine.char = ctx.char
        S.cine.crowd = crowd
        local raw = math.min((ctx.distK or 1) * (1 + math.min(crowd, 6) * 0.12), 2.1)
        S.cine.P = { crowd = crowd, dm = 1 + (raw - 1) * (def.dmK or 1), wide = (cat == "WIDE") }
        S.cine.lens = nil
        if CFG.LensPool then
                local roll = math.random() * 100
                local lens
                if roll < 20 then
                        lens = { fov = rr(28, 40), dm = 0.85 }
                elseif roll < 60 then
                        lens = { fov = rr(45, 60), dm = 1 }
                elseif roll < 90 then
                        lens = { fov = rr(75, 95), dm = 1.5 }
                else
                        lens = { fov = rr(105, 120), dm = 2.1 }
                end
                if cat == "CLOSE" and lens.dm > 1 then
                        lens = { fov = rr(30, 55), dm = 0.9 }
                end
                S.cine.lens = lens
                S.cine.P.dm = math.clamp(S.cine.P.dm * lens.dm, 0.5, 3.2)
        end
        S.cine.smCf = nil
        S.cine.bankYaw = nil -- reset yaw banking: cut baru tidak memicu tendangan miring
        if def and def.enter then
                def.enter(ctx, S.cine.P)
        end
        local L = S.cine.lens
        if L and S.cine.P and not (S.cine.P.fov0 and S.cine.P.fov1) and not S.cine.P.noLens then
                local f = S.cine.P.fov
                if f then
                        S.cine.P.fov = math.clamp(f + (L.fov - f) * 0.8, 26, 120)
                end
        end
        if (CFG.ShotBlur or 0) > 0.01 then
                S.cine.blurT = 0
                S.cine.blurDur = math.max(CFG.ShotBlur, 0.1)
        else
                S.cine.blurT = nil
        end
end

local function cineUpdate(dt)
        if not S.cine.def then
                startShot()
                if not S.cine.def then
                        return
                end
        end
        local ctx = cineCtx(dt)
        if not ctx.root then
                return
        end
        S.cine.t = S.cine.t + dt
        if (CFG.ShotBlur or 0) > 0.01 and (S.cine.dur - S.cine.t) < 0.08 then
                transBlur(math.clamp(1 - (S.cine.dur - S.cine.t) / 0.08, 0, 1))
        end
        if ctx.char ~= S.cine.char or S.cine.t >= S.cine.dur then
                startShot()
        end
        if S.cine.blurT then
                S.cine.blurT = S.cine.blurT + dt
                local bk = math.clamp(1 - S.cine.blurT / S.cine.blurDur, 0, 1)
                if bk <= 0 then
                        S.cine.blurT = nil
                        DOF_TRANS.Enabled = false
                else
                        transBlur(bk * bk * (3 - 2 * bk))
                end
        end
        local cf, fov, dofK = S.cine.def.update(S.cine.P, S.cine.t, dt, ctx)
        fov = fov + math.sin(os.clock() * 1.2) * 1.2
        local p = safeOrbit(ctx.head, cf.Position)
        p = floorGuard(p) -- jaga tak menempel / masuk lantai (segala kondisi)
        if p ~= cf.Position then
                cf = CFrame.new(p) * cf.Rotation
        end
        if S.cine.smCf then
                cf = S.cine.smCf:Lerp(cf, 1 - math.exp(-CFG.CineSoft * dt))
        end
        S.cine.smCf = cf
        Camera.CFrame = cf
        local yawNow = math.atan2(-cf.LookVector.X, -cf.LookVector.Z)
        local dYaw = yawNow - (S.cine.bankYaw or yawNow)
        if dYaw > math.pi then
                dYaw = dYaw - 2 * math.pi
        elseif dYaw < -math.pi then
                dYaw = dYaw + 2 * math.pi
        end
        S.cine.bankYaw = yawNow
        local bankT = math.clamp((dYaw / math.max(dt, 0.001)) * 5, -7, 7) -- derajat, ikut laju sapuan
        S.cine.bank = (S.cine.bank or 0) + (bankT - (S.cine.bank or 0)) * math.min(1, dt * 5)
        local nafas = math.sin(os.clock() * 0.7) * 1.6
        Camera.CFrame = Camera.CFrame * CFrame.Angles(0, 0, math.rad((S.cine.bank or 0) + nafas))
        Camera.FieldOfView = math.clamp(fov, CFG.CineFovMin, CFG.CineFovMax) -- v1.0.8: rentang lensa diatur user
        S.cine.dofK = dofK or 0
        S.cine.focusDist = (Camera.CFrame.Position - ctx.head).Magnitude
end

-- ═══════════════ RACE CAM — MODE 4 (NAIK KENDARAAN) ═══════════════
local RSHOTS = {}

RSHOTS["LOW REAR CHASE"] = {
        face = "BELAKANG", -- kejaran rendah dari belakang
        pick = function(ctx) return 3 + ctx.spk * 4 end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.d = rr(17, 24) * P.dm
                P.h = rr(-0.6, 0.6)
                P.fov = rr(58, 66)
                seedSway(P, 1.3)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.8)
                local fov = P.fov + ctx.spk * 18
                local p = ctx.pos - dir * (P.d + ctx.spk * 6) + Vector3.new(0, P.h, 0) + sway(P, t, 0.16)
                return CFrame.lookAt(p, ctx.pos + dir * 6), fov, closeDof(P.d, 5)
        end,
}

RSHOTS["FRONT LEAD SHOT"] = {
        face = "ATAS DEPAN", -- DEPAN ATAS: agak tinggi di depan, mundur menghadap kendaraan
        dmK = 0.5, -- depan atas: ikut kondisi tapi dijaga tidak terlalu jauh/tinggi
        pick = function(ctx) return 2.5 + ctx.spk * 2 end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.d = rr(17, 24) * P.dm
                P.h = rr(2.8, 5.2) * P.dm
                P.fov = rr(52, 60)
                seedSway(P, 1)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.4)
                local p = ctx.pos + dir * (P.d + ctx.spk * 3) + Vector3.new(0, P.h, 0) + sway(P, t, 0.14)
                return CFrame.lookAt(p, ctx.pos + dir * 2), P.fov + ctx.spk * 8, 0
        end,
}

RSHOTS["SIDE-BY-SIDE TRACK"] = {
        face = "SAMPING", -- sejajar di samping kendaraan
        pick = function(ctx) return 3 + ctx.spk * 2 end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.side = (math.random() < 0.5 and -1 or 1) * rr(15, 21) * P.dm
                P.lead = rr(2, 5)
                P.h = rr(0.4, 1.4)
                P.fov = rr(56, 64)
                seedSway(P, 1.1)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.2)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local p = ctx.pos + perp * P.side + dir * P.lead + Vector3.new(0, P.h, 0) + sway(P, t, 0.14)
                return CFrame.lookAt(p, ctx.pos + dir * 2), P.fov, closeDof(math.abs(P.side), 6)
        end,
}

RSHOTS["LOW FRONT THREE-QUARTER"] = {
        face = "SAMPING", -- sudut rendah depan samping (grup samping), agresif
        pick = function(ctx) return 3 - ctx.spk * 1.5 end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.ang = rr(0.45, 0.9) -- 26°-52° dari depan
                P.side = (math.random() < 0.5 and -1 or 1)
                P.d0 = rr(13, 18) * P.dm
                P.h = rr(-0.4, 0.4)
                P.fov = rr(44, 54)
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2)
                local k = smoothstep(t / math.max(S.race.dur, 0.1))
                local d = P.d0 - k * 2.5 -- dorongan pelan mendekat
                local dir3q = rotY(dir, P.ang * P.side)
                local p = ctx.pos + dir3q * d + Vector3.new(0, P.h, 0) + sway(P, t, 0.1)
                return CFrame.lookAt(p, ctx.pos), P.fov, closeDof(d, 5)
        end,
}

RSHOTS["PASS-BY SHOT"] = {
        face = "SAMPING", -- kamera diam di tepi samping lintasan
        pick = function(ctx) return (ctx.speed < 8) and 0 or 3.5 end,
        enter = function(ctx, P)
                local vdir = (ctx.speed > 1) and flatUnit(ctx.vel) or ctx.fwd
                local right = Vector3.new(-vdir.Z, 0, vdir.X)
                P.spot = ctx.pos + vdir * ctx.speed * rr(1.1, 1.8) + right * (math.random() < 0.5 and -1 or 1) * rr(9, 14) * P.dm + Vector3.new(0, rr(1.2, 2.6), 0)
                P.fov = rr(50, 58)
                P.cut = false
                seedSway(P, 0.5)
        end,
        update = function(P, t, dt, ctx)
                local rel = ctx.pos - P.spot
                local vdir = (ctx.speed > 1) and flatUnit(ctx.vel) or ctx.fwd
                if not P.cut and rel:Dot(vdir) < -3 then
                        P.cut = true -- kendaraan sudah lewat: potong
                        S.race.dur = math.min(S.race.dur, S.race.t + 0.12)
                end
                local p = P.spot + sway(P, t, 0.08)
                return CFrame.lookAt(p, ctx.pos), P.fov, 0
        end,
}

RSHOTS["PANNING CORNER SHOT"] = {
        face = "SAMPING", -- kamera diam di sisi luar tikungan
        pick = function(ctx) return (math.abs(ctx.turn) > 0.3) and 4.5 or 0.4 end,
        enter = function(ctx, P)
                local side = (ctx.turn > 0 and 1 or -1) -- sisi luar tikungan
                P.spot = ctx.pos + ctx.right * side * rr(15, 21) * P.dm + ctx.fwd * rr(2, 6) + Vector3.new(0, rr(1.5, 3), 0)
                P.fov = rr(48, 58)
                seedSway(P, 0.5)
        end,
        update = function(P, t, dt, ctx)
                local p = P.spot + sway(P, t, 0.08)
                return CFrame.lookAt(p, ctx.pos), P.fov, 0
        end,
}

RSHOTS["OVERTAKE SHOT"] = {
        face = "ATAS SAMPING", -- samping atas (kanan/kiri), sapuan belakang atas → depan atas
        dmK = 0.5, -- samping atas: ikut kondisi tapi dijaga tidak terlalu jauh
        pick = function(ctx) return 2 + ctx.spk * 2.5 end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.side = (math.random() < 0.5 and -1 or 1) * rr(8, 13) * P.dm
                P.h = rr(4, 6) * P.dm
                P.fov = rr(56, 64)
                seedSway(P, 1.2)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.4)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local k = smoothstep(t / math.max(S.race.dur, 0.1))
                local along = -18 + 36 * k -- dari belakang → depan (sapuan lebih lebar)
                local p = ctx.pos + dir * along + perp * P.side + Vector3.new(0, P.h, 0) + sway(P, t, 0.12)
                return CFrame.lookAt(p, ctx.pos + dir * 2), P.fov + ctx.spk * 6, closeDof(math.abs(along), 6)
        end,
}

RSHOTS["WHEEL & TIRE CLOSE-UP"] = {
        face = "DEKAT", -- DEKAT kendaraan: roda & detail dari depan samping
        pick = function(ctx) return math.max(2.5 - ctx.spk * 1.2, 0.6) end,
        dmK = 0.4, -- close-up roda: ikut kondisi tapi dijaga tetap dekat
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.ang = rr(0.6, 1.1)
                P.side = (math.random() < 0.5 and -1 or 1)
                P.d = rr(6, 8) * P.dm
                P.h = rr(-1.3, -0.7) -- setinggi roda
                P.fov = rr(34, 44)
                seedSway(P, 0.8)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.6)
                local dirW = rotY(dir, P.ang * P.side)
                local p = ctx.pos + dirW * P.d + Vector3.new(0, P.h, 0) + sway(P, t, 0.05)
                return CFrame.lookAt(p, ctx.pos - Vector3.new(0, 0.8, 0)), P.fov, 1
        end,
}

RSHOTS["HIGH MOUNT TRACK"] = {
        face = "ATAS SAMPING", -- samping atas kanan/kiri (grup utama 50%)
        pick = function(ctx) return 3.2 end,
        dmK = 0.6, -- high mount: ikut kondisi tapi tetap agak jauh & tinggi
        enter = function(ctx, P)
                P.dir = ctx.fwd
                local kanan = (math.random() < 0.5)
                local tigaEmpat = (math.random() < 0.5)
                P.along = tigaEmpat and rr(7, 12) * P.dm or rr(1, 4) * P.dm
                P.side = (kanan and 1 or -1) * rr(8, 12) * P.dm
                P.h = rr(4.5, 6.5) * P.dm
                P.fov = rr(48, 58)
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.2)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local p = ctx.pos + dir * P.along + perp * P.side + Vector3.new(0, P.h, 0) + sway(P, t, 0.1)
                return CFrame.lookAt(p, ctx.pos + dir * 3), P.fov, 0
        end,
}

RSHOTS["DRIFT ARC SHOT"] = {
        face = "SAMPING", -- melengkung mengitari kendaraan
        pick = function(ctx) return ctx.drift and 6 or ((math.abs(ctx.turn) > 0.25) and 2.5 or 0.5) end,
        enter = function(ctx, P)
                P.r = rr(15, 20) * P.dm
                P.ang = math.atan2(ctx.fwd.Z, ctx.fwd.X) -- mulai searah kendaraan
                P.spin = (ctx.turn >= 0 and 1 or -1) * math.rad(rr(24, 40))
                P.h = rr(1.5, 3)
                P.fov = rr(52, 62)
                seedSway(P, 1)
        end,
        update = function(P, t, dt, ctx)
                P.ang = P.ang + P.spin * dt
                local fov = P.fov + ctx.spk * 6
                local p = ctx.pos + Vector3.new(math.cos(P.ang) * P.r, P.h, math.sin(P.ang) * P.r) + sway(P, t, 0.12)
                return CFrame.lookAt(p, ctx.pos), fov, closeDof(P.r, 6)
        end,
}

RSHOTS["SKYLINE CRANE TRACK"] = {
        face = "ATAS SAMPING", -- samping atas kanan/kiri, sangat tinggi (kran/drone)
        dmK = 0.6,
        pick = function(ctx) return 2.6 + ctx.spk * 1.5 end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.side = (math.random() < 0.5 and 1 or -1) * rr(9, 14) * P.dm
                P.along = rr(2, 8)
                P.h = rr(8, 11) * P.dm
                P.fov = rr(46, 54)
                seedSway(P, 0.7)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local p = ctx.pos + dir * P.along + perp * P.side + Vector3.new(0, P.h, 0) + sway(P, t, 0.1)
                return CFrame.lookAt(p, ctx.pos + dir * 5), P.fov, 0
        end,
}

RSHOTS["TOP-DOWN SWEEP"] = {
        face = "ATAS SAMPING", -- samping atas kanan/kiri, menyapu turun
        dmK = 0.6,
        pick = function(ctx) return 2.2 + ctx.spk end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.side = (math.random() < 0.5 and 1 or -1) * rr(8, 12) * P.dm
                P.along = rr(4, 9)
                P.h0 = rr(7.5, 9.5) * P.dm
                P.h1 = rr(3, 4) * P.dm
                P.fov = rr(48, 56)
                seedSway(P, 0.8)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.2)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local k = smoothstep(t / math.max(S.race.dur, 0.1))
                local h = P.h0 + (P.h1 - P.h0) * k
                local p = ctx.pos + dir * P.along + perp * P.side + Vector3.new(0, h, 0) + sway(P, t, 0.08)
                return CFrame.lookAt(p, ctx.pos + dir * 2), P.fov, 0
        end,
}

RSHOTS["CHOPPER SWAY"] = {
        face = "ATAS SAMPING", -- samping atas kanan/kiri, melayang gaya helikopter
        dmK = 0.6,
        pick = function(ctx) return 2.4 end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.side = (math.random() < 0.5 and 1 or -1) * rr(9, 13) * P.dm
                P.along = rr(0, 5)
                P.h = rr(4.5, 6.5) * P.dm
                P.osf = rr(0.5, 0.8) -- frekuensi naik-turun (kali 2π)
                P.osp = rr(0.8, 1.4) -- amplitudo naik-turun
                P.ph = rr(0, math.pi * 2)
                P.fov = rr(50, 58)
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.1)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local h = P.h + math.sin(t * P.osf * math.pi * 2 + P.ph) * P.osp
                local p = ctx.pos + dir * P.along + perp * P.side + Vector3.new(0, h, 0) + sway(P, t, 0.09)
                return CFrame.lookAt(p, ctx.pos + dir * 3), P.fov, 0
        end,
}

RSHOTS["DRONE FRONT HIGH"] = {
        face = "ATAS DEPAN", -- depan atas: drone menghadap ke bawah dari depan
        dmK = 0.5,
        pick = function(ctx) return 2 + ctx.spk * 1.5 end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.d = rr(16, 22) * P.dm
                P.h = rr(5, 8) * P.dm
                P.fov = rr(50, 58)
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.2)
                local p = ctx.pos + dir * P.d + Vector3.new(0, P.h, 0) + sway(P, t, 0.1)
                return CFrame.lookAt(p, ctx.pos + dir * 4), P.fov, 0
        end,
}

RSHOTS["HIGH REAR CRANE"] = {
        face = "BELAKANG", -- belakang atas: kran tinggi mengekor
        dmK = 0.55,
        pick = function(ctx) return 2.5 + ctx.spk * 2 end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.d = rr(18, 26) * P.dm
                P.h = rr(3.5, 5.5) * P.dm
                P.fov = rr(52, 60)
                seedSway(P, 1)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.4)
                local p = ctx.pos - dir * P.d + Vector3.new(0, P.h, 0) + sway(P, t, 0.11)
                return CFrame.lookAt(p, ctx.pos + dir * 8), P.fov + ctx.spk * 6, 0
        end,
}

RSHOTS["EXHAUST & SPOILER"] = {
        face = "DEKAT", -- menempel di belakang bawah kendaraan: knalpot & spoiler
        dmK = 0.4,
        pick = function(ctx) return math.max(2 - ctx.spk * 0.8, 0.5) end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.ang = rr(2.35, 2.75) -- sudut belakang 3/4 (rad dari depan)
                P.side = (math.random() < 0.5 and 1 or -1)
                P.d = rr(5.5, 7.5) * P.dm
                P.h = rr(-1.1, -0.4)
                P.fov = rr(36, 46)
                seedSway(P, 0.7)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.5)
                local dirB = rotY(dir, P.ang * P.side)
                local p = ctx.pos + dirB * P.d + Vector3.new(0, P.h, 0) + sway(P, t, 0.05)
                return CFrame.lookAt(p, ctx.pos - Vector3.new(0, 0.4, 0)), P.fov, 1
        end,
}

RSHOTS["WINDOW GLIDE"] = {
        face = "DEKAT", -- menempel sejajar jendela samping (dekat kendaraan)
        dmK = 0.4,
        pick = function(ctx) return math.max(1.8 - ctx.spk * 0.6, 0.5) end,
        enter = function(ctx, P)
                P.dir = ctx.fwd
                P.side = (math.random() < 0.5 and 1 or -1) * rr(4.5, 6.5) * P.dm
                P.lead = rr(0, 2)
                P.h = rr(0.5, 1.3)
                P.fov = rr(40, 50)
                seedSway(P, 0.8)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.6)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                local p = ctx.pos + perp * P.side + dir * P.lead + Vector3.new(0, P.h, 0) + sway(P, t, 0.06)
                return CFrame.lookAt(p, ctx.pos + Vector3.new(0, 0.6, 0)), P.fov, 1
        end,
}

local function raceCtx(dt)
        local char = getSubjectChar()
        local hum = getHum(char)
        if not (hum and hum.SeatPart) then
                char = myChar()
                hum = getHum(char)
        end
        local root = getRoot(char)
        local seat = hum and hum.SeatPart or nil
        local pos = workspace.CurrentCamera.CFrame.Position
        local speed = 0
        local vel = Vector3.zero
        local fwd = Vector3.new(0, 0, -1)
        if root then
                pos = root.Position
                vel = root.AssemblyLinearVelocity
                speed = vel.Magnitude
                if seat and seat.Parent then
                        fwd = flatUnit(seat.CFrame.LookVector)
                end
                if fwd.Magnitude < 0.05 then
                        fwd = (speed > 1) and flatUnit(vel) or flatUnit(root.CFrame.LookVector)
                end
                if fwd.Magnitude < 0.05 then
                        fwd = Vector3.new(0, 0, -1)
                end
                if S.cineStabChar ~= root then
                        S.cineStabChar = root
                        S.cineStabY = pos.Y
                end
                if dt then
                        local grounded = (hum == nil) or (hum.FloorMaterial ~= Enum.Material.Air)
                        local kY = grounded and CFG.CineStabG or CFG.CineStabA
                        S.cineStabY = expLerp(S.cineStabY, pos.Y, dt, kY)
                else
                        S.cineStabY = pos.Y
                end
                pos = Vector3.new(pos.X, S.cineStabY, pos.Z)
        end
        local right = Vector3.new(-fwd.Z, 0, fwd.X)
        local lat = vel:Dot(right)
        local turn = S.race.turn or 0
        if dt and S.race.lastFwd then
                local lf = S.race.lastFwd
                local dot = math.clamp(lf:Dot(fwd), -1, 1)
                local ang = math.asin(math.clamp(lf:Cross(fwd).Y, -1, 1))
                if dot < 0 then
                        ang = (ang >= 0) and (math.pi - ang) or (-math.pi - ang)
                end
                local inst = ang / math.max(dt, 0.001)
                turn = turn + (inst - turn) * math.min(1, dt * 6)
        end
        S.race.turn = turn
        if fwd.Magnitude > 0.05 then
                S.race.lastFwd = fwd
        end
        local wantK = CFG.DistDekat + (CFG.DistJauh - CFG.DistDekat) * math.clamp(speed / 34, 0, 1)
        if dt then
                if not S.race.distK then
                        S.race.distK = wantK
                end
                S.race.distK = expLerp(S.race.distK, wantK, dt, 0.8)
        end
        return {
                char = char,
                root = root,
                hum = hum,
                seat = seat,
                pos = pos,
                vel = vel,
                speed = speed,
                fwd = fwd,
                right = right,
                turn = turn,
                lat = lat,
                drift = (speed > 10) and (math.abs(lat) > math.max(speed * 0.3, 6)),
                spk = math.clamp((speed - 6) / 34, 0, 1),
                distK = S.race.distK or wantK,
                look = fwd,  -- kompatibel dengan smoothDir
                moveDir = fwd,
                head = pos + Vector3.new(0, 1.2, 0),
        }
end

local function racePick(ctx)
        local name = pickFaceShot(RSHOTS, function(n, def)
                return def.pick(ctx) or 0
        end, S.race.lastName, RACE_W, RACE_ORDER)
        if name then
                return name
        end
        local pool, total = {}, 0
        for name2, def in pairs(RSHOTS) do
                local w = def.pick(ctx) or 0
                if w > 0 then
                        table.insert(pool, { name = name2, w = w })
                        total = total + w
                end
        end
        if #pool == 0 then
                return "LOW REAR CHASE"
        end
        local roll = math.random() * total
        for _, it in ipairs(pool) do
                roll = roll - it.w
                if roll <= 0 then
                        return it.name
                end
        end
        return pool[1].name
end

local function startRaceShot()
        local ctx = raceCtx()
        local name = racePick(ctx)
        local def = RSHOTS[name]
        S.race.name = name
        S.race.lastName = name
        S.race.def = def
        S.race.t = 0
        S.race.dur = math.clamp(CFG.CineTempo + rr(-1, 1.2), 2.5, 9)
        S.race.char = ctx.char
        S.race.P = { dm = 1 + ((ctx.distK or 1) - 1) * (def.dmK or 1) }
        S.race.smCf = nil
        if def and def.enter then
                def.enter(ctx, S.race.P)
        end
end

local function raceUpdate(dt)
        local ctx = raceCtx(dt)
        if not ctx.root or not ctx.seat then
                setMode("NONE")
                notify("Keluar kendaraan — RACE CAM OFF", 1.6)
                return
        end
        if not S.race.def then
                startRaceShot()
                if not S.race.def then
                        return
                end
        end
        S.race.t = S.race.t + dt
        if ctx.char ~= S.race.char or S.race.t >= S.race.dur then
                startRaceShot()
        end
        local cf, fov, dofK = S.race.def.update(S.race.P, S.race.t, dt, ctx)
        fov = fov + math.sin(os.clock() * 1.2) * 1.2
        local p = safeOrbit(ctx.pos, cf.Position)
        p = floorGuard(p) -- jaga tak menempel / masuk lantai
        if p ~= cf.Position then
                cf = CFrame.new(p) * cf.Rotation
        end
        if S.race.smCf then
                cf = S.race.smCf:Lerp(cf, 1 - math.exp(-CFG.CineSoft * dt))
        end
        S.race.smCf = cf
        Camera.CFrame = cf
        Camera.FieldOfView = fov
        S.race.dofK = dofK or 0
        S.race.focusDist = (Camera.CFrame.Position - ctx.pos).Magnitude
end

-- ═══════════════ SPACE (TAHAN) = TURBO + ANTI LOMPAT ═══════════════
local function bindSpace()
        if boundSpace then
                return
        end
        boundSpace = true
        ContextActionService:BindAction("CAMERA_TURBO", function(_, state)
                if state == Enum.UserInputState.Begin then
                        if S.mode == "FREE" and not UserInputService:GetFocusedTextBox() then
                                S.turbo = true
                                updateChip()
                                return Enum.ContextActionResult.Sink
                        end
                elseif state == Enum.UserInputState.End then
                        if S.turbo then
                                S.turbo = false
                                updateChip()
                        end
                end
                return Enum.ContextActionResult.Pass
        end, false, Enum.KeyCode.Space)
end

local function unbindSpace()
        if not boundSpace then
                return
        end
        boundSpace = false
        S.turbo = false
        pcall(function()
                ContextActionService:UnbindAction("CAMERA_TURBO")
        end)
end

-- ═══════════════ GANTI MODE KAMERA ═══════════════
-- ═══════════════ UPDATE 0.3: MESIN PERPINDAHAN HALUS ═══════════════
local function mulaiTransisi()
        if (CFG.ModeBlend or 0) > 0 then
                S.trans = {
                        from = Camera.CFrame,
                        fromFov = Camera.FieldOfView,
                        t = 0,
                        dur = math.max(CFG.ModeBlend, 0.05),
                }
        end
end

function setMode(m)
        if m ~= "NONE" and not S.master then
                notify("CAPSLOCK OFF — tekan CapsLock dulu untuk pakai fitur kamera", 2)
                return
        end
        if m ~= "NONE" and S.mode == m then
                m = "NONE"
        end
        if m == "RACE" then
                local hum = getHum(getSubjectChar())
                if not (hum and hum.SeatPart) then
                        hum = getHum(myChar())
                end
                if not (hum and hum.SeatPart) then
                        notify("RACE CAM butuh kendaraan — naik mobil/heli/perahu dulu", 1.6)
                        return
                end
        end
        if m ~= "NONE" then
                S.lastMode = m
        end
        if S.mode == "NONE" and m ~= "NONE" then
                S.savedCam = { CFrame = workspace.CurrentCamera.CFrame }
        end
        if S.mode == "FREE" or S.mode == "PRO" then
                unbindSpace()
        end
        S.mode = m
        lastFreePos = nil -- jejak anti-temboss free cam direset tiap ganti mode
        S.exitGlide = nil -- perpindahan baru: glide balik ke kamera normal dibatalkan
        refreshCamFilter()
        if m == "NONE" then
                notify("KAMERA MODE OFF", 1.2)
                S.fly = nil
                S.proGlide = nil
                S.turbo = false
                setAnchorState()
                S.cine.def = nil
                S.cine.dofK = 0
                if S.savedCam then
                        local sc = S.savedCam
                        S.savedCam = nil
                        local hrpX = getRoot(myChar())
                        if hrpX and (CFG.ExitBlend or 0) > 0 then
                                Camera.CameraType = Enum.CameraType.Scriptable
                                S.exitGlide = {
                                        from = Camera.CFrame,
                                        fromFov = Camera.FieldOfView,
                                        rot = sc.CFrame - sc.CFrame.Position, -- rotasi saja
                                        rel = sc.CFrame.Position - hrpX.Position,
                                        cf = sc.CFrame,
                                        t = 0,
                                        dur = math.max(CFG.ExitBlend, 0.05),
                                }
                        else
                                Camera.CameraType = Enum.CameraType.Scriptable
                                Camera.CFrame = sc.CFrame
                                task.defer(function()
                                        Camera.CameraType = Enum.CameraType.Custom
                                        local hum = getHum(myChar())
                                        if hum then
                                                Camera.CameraSubject = hum
                                        end
                                        Camera.FieldOfView = CFG.FOV
                                end)
                        end
                else
                        Camera.CameraType = Enum.CameraType.Custom
                        local hum = getHum(myChar())
                        if hum then
                                Camera.CameraSubject = hum
                        end
                        Camera.FieldOfView = CFG.FOV
                end
        elseif m == "FREE" then
                local camCF = workspace.CurrentCamera.CFrame
                local look = camCF.LookVector
                S.freePos = camCF.Position
                S.yaw = math.atan2(-look.X, -look.Z)
                S.pitch = math.asin(math.clamp(look.Y, -1, 1))
                S.yawT = S.yaw     -- sinkron target mouse: tidak ada putaran sisa
                S.pitchT = S.pitch
                S.freeVel = Vector3.new(0, 0, 0)
                S.aimY = nil
                S.fly = nil
                S.turbo = false
                Camera.CameraType = Enum.CameraType.Scriptable
                mulaiTransisi() -- update 0.3: dilebur dari tampilan terakhir
                setAnchorState()
                bindSpace()
                notify("FREE CAM — WASD+QE gerak · RMB lihat · Scroll FOV · tahan Space turbo", 1.4)
        elseif m == "PRO" then
                local camCF = workspace.CurrentCamera.CFrame
                local look = camCF.LookVector
                S.proYaw = math.atan2(-look.X, -look.Z)
                S.proPitch = math.clamp(math.asin(math.clamp(look.Y, -1, 1)), -1.35, 1.35)
                S.proYawT = S.proYaw  -- sinkron target mouse & zoom: tanpa sentakan awal
                S.proPitchT = S.proPitch
                local subjRoot = getRoot(getSubjectChar())
                if subjRoot then
                        S.proPivot = subjRoot.Position + Vector3.new(0, 1.5, 0)
                        S.proDist = math.clamp((camCF.Position - S.proPivot).Magnitude, 6, 70)
                else
                        S.proPivot = nil
                        S.proDist = 14
                end
                S.proDistT = S.proDist
                S.proPos = camCF.Position
                S.proCF = nil
                S.proPivotVel = Vector3.new(0, 0, 0)
                S.proGlide = nil
                Camera.CameraType = Enum.CameraType.Scriptable
                mulaiTransisi() -- update 0.3: dilebur dari tampilan terakhir
                setAnchorState()
                bindSpace()
                notify("PRO CAM — RMB putar (halus) · Scroll zoom 4–80 (larut)", 1.4)
        elseif m == "CINE" then
                Camera.CameraType = Enum.CameraType.Scriptable
                mulaiTransisi() -- update 0.3: shot pertama dilebur dari tampilan terakhir
                S.cine.def = nil
                S.cine.smCf = nil
                setAnchorState() -- karakter beku total, biar shot tetap rapi
                notify("CINEMATIC — 21 shot penuh gerakan · cut antar shot gaya film · 60% depan · 20% samping · 20% belakang · tempo " .. string.format("%.1f", CFG.CineTempo) .. "s · nembus benda kecil", 1.4)
        elseif m == "RACE" then
                Camera.CameraType = Enum.CameraType.Scriptable
                mulaiTransisi() -- update 0.3: shot pertama dilebur dari tampilan terakhir
                S.race.def = nil
                S.race.lastName = ""
                S.race.turn = 0
                S.race.lastFwd = nil
                S.race.smCf = nil
                setAnchorState() -- RACE tidak beku: kamu tetap menyetir selagi kamera merekam
                notify("RACE CAM — 17 shot · 50% samping atas · 20% depan atas · 10% samping · 10% belakang · 10% dekat · cut gaya film · nembus benda kecil", 1.4)
        end
        refreshModeUI()
        updateChip()
        applyLetterbox()
        applyUIVisibility()
end

-- ═══════════════ CAPSLOCK = MASTER SEMUA FITUR KAMERA ═══════════════
function setMaster(on)
        S.master = on and true or false
        S.uiHidden = false
        if S.master then
                S.gerakMode = nil -- sesi filming baru: kembali ke aturan otomatis (beku)
                setAnchorState()
                applyUIVisibility()
                notify("CAPSLOCK ON — keybind kamera AKTIF (1/2/3/4 · M · T · C)", 2.2)
        else
                if S.mode ~= "NONE" then
                        setMode("NONE") -- matikan mode kamera + kembalikan kamera semula
                end
                if S.fotoAktif then
                        S.fotoAktif = false
                        applyLetterbox()
                end
                S.foto.dof = false -- efek layar aktif ikut dibersihkan (blur foto)
                setFilter("OFF")
                setRatio("FULL")
                setWatermark(false)
                if S.locked then
                        S.locked = false
                        S.lockPlayer = nil
                        refreshTargetList()
                        if UI.updateLockBtn then
                                UI.updateLockBtn()
                        end
                end
                S.rmb = false
                S.turbo = false
                S.ctrlDown = false
                S.gerakMode = nil -- balik ke aturan otomatis (master off = bebas gerak)
                setAnchorState()
                applyUIVisibility()
                pcall(function()
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end)
                notify("CAPSLOCK OFF — keybind kamera MATI (F · Z · K · J tetap hidup)", 2.4)
        end
end

-- ═══════════════ INPUT KEYBIND ═══════════════
table.insert(CONNS, UserInputService.InputBegan:Connect(function(input, gp)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
                if S.mode == "FREE" or S.mode == "PRO" then
                        S.rmb = true
                        pcall(function()
                                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                        end)
                end
                return
        end
        if gp then
                return
        end
        local kc = input.KeyCode
        if input.UserInputType == Enum.UserInputType.Keyboard and kc then
                keys[kc] = true
                if kc == Enum.KeyCode.W or kc == Enum.KeyCode.S or kc == Enum.KeyCode.A
                        or kc == Enum.KeyCode.D or kc == Enum.KeyCode.Q or kc == Enum.KeyCode.E then
                        S.fly = nil -- gerak manual membatalkan terbang otomatis
                end
        end
        if kc == Enum.KeyCode.CapsLock then
                setMaster(not S.master)
                return
        end
        if kc == Enum.KeyCode.Z then
                toggleCahaya()
                return
        end
        if kc == Enum.KeyCode.F then
                togglePanel()
                return
        end
        if kc == Enum.KeyCode.J then
                toggleGerak()
                return
        end
        if kc == Enum.KeyCode.K then
                local now = os.clock()
                if now - S.lastK < 2 then
                        unloadAll()
                else
                        S.lastK = now
                        notify("Tekan K sekali lagi untuk hapus script")
                end
                return
        end
        if not S.master then
                return
        end
        if kc == Enum.KeyCode.One then
                setMode("FREE")
        elseif kc == Enum.KeyCode.Two then
                setMode("PRO")
        elseif kc == Enum.KeyCode.Three then
                setMode("CINE")
        elseif kc == Enum.KeyCode.Four then
                setMode("RACE")
        elseif kc == Enum.KeyCode.M then
                S.fotoAktif = not S.fotoAktif
                if S.fotoAktif then
                        if S.uiHidden then
                                toggleHideUI()
                        end
                        S.panelOpen = true
                        UI.panel.Visible = true
                        switchTab("FOTO")
                end
                applyLetterbox()
                notify(S.fotoAktif and "MODE FOTO ON — letterbox bioskop aktif (M lagi = mati)" or "MODE FOTO OFF", 1.4)
        elseif kc == Enum.KeyCode.T then
                toggleLock()
        elseif kc == Enum.KeyCode.C then
                doTeleport()
        elseif kc == Enum.KeyCode.H then
                toggleHideUI()
        elseif kc == Enum.KeyCode.LeftControl then
                S.ctrlDown = true
        end
end))

table.insert(CONNS, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
                S.rmb = false
                pcall(function()
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end)
        end
        if input.KeyCode then
                keys[input.KeyCode] = nil
                if input.KeyCode == Enum.KeyCode.LeftControl then
                        S.ctrlDown = false
                end
        end
end))

table.insert(CONNS, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
                if S.rmb and (S.mode == "FREE" or S.mode == "PRO") then
                        local dx, dy = input.Delta.X, input.Delta.Y
                        local sens = CFG.MouseSens * 0.02
                        if S.mode == "FREE" then
                                S.fly = nil
                                S.yawT = S.yawT - dx * sens -- TARGET saja: aktual dihaluskan di freeUpdate (anti sentak)
                                S.pitchT = math.clamp(S.pitchT - dy * sens, -1.45, 1.45)
                        else
                                S.proYawT = S.proYawT - dx * sens -- TARGET: dihaluskan proUpdate (anti hentakan)
                                S.proPitchT = math.clamp(S.proPitchT - dy * sens, -1.35, 1.35)
                        end
                end
        elseif input.UserInputType == Enum.UserInputType.MouseWheel then
                local z = input.Position.Z
                if S.mode == "FREE" then
                        CFG.FOV = math.clamp(CFG.FOV - z * 3, 30, 105)
                        if UI.fovSlider then
                                UI.fovSlider.Set(CFG.FOV)
                        end
                elseif S.mode == "PRO" then
                        S.proDistT = math.clamp(S.proDistT - z * 2.5, 4, 80) -- TARGET: zoom larut di proUpdate
                end
        end
end))

-- ═══════════════ LOOP RENDER ═══════════════
local lockCheck = 0
local camFilterCheck = 0
table.insert(CONNS, RunService.RenderStepped:Connect(function(dt)
        dt = math.min(dt, 0.066) -- PENTING: dt dipatok — kamera tidak melompat setelah lag/spike
        Camera = workspace.CurrentCamera
        if os.clock() - camFilterCheck > 0.5 then
                camFilterCheck = os.clock()
                refreshCamFilter()
        end
        if S.locked and os.clock() - lockCheck > 0.5 then
                lockCheck = os.clock()
                local c = S.lockPlayer and S.lockPlayer.Parent and S.lockPlayer.Character or nil
                local h = c and getHum(c) or nil
                if not (c and h and h.Health > 0) then
                        if S.lockMode == "AUTO" then
                                local best = findNearestPlayer()
                                if best then
                                        S.lockPlayer = best
                                        S.selected = best
                                        notify("AUTO LOCK → " .. best.Name, 1.2)
                                        updateChip()
                                        refreshTargetList()
                                        if UI.updateLockBtn then
                                                UI.updateLockBtn()
                                        end
                                end
                        else
                                S.locked = false
                                S.lockPlayer = nil
                                notify("Target hilang — lock dilepas", 1.4)
                                updateChip()
                                refreshTargetList()
                                if UI.updateLockBtn then
                                        UI.updateLockBtn()
                                end
                        end
                end
        end
        if S.mode == "FREE" then
                freeUpdate(dt)
        elseif S.mode == "PRO" then
                proUpdate(dt)
        elseif S.mode == "CINE" then
                cineUpdate(dt)
        elseif S.mode == "RACE" then
                raceUpdate(dt)
        end
        -- ═══ UPDATE 0.3: PERPINDAHAN MODE SUPER HALUS ═══
        if S.trans then
                local tr = S.trans
                tr.t = tr.t + dt
                local a = math.min(tr.t / tr.dur, 1)
                local e = a * a * (3 - 2 * a) -- smoothstep: lembut di awal & akhir
                Camera.CFrame = tr.from:Lerp(Camera.CFrame, e)
                Camera.FieldOfView = tr.fromFov + (Camera.FieldOfView - tr.fromFov) * e
                if a >= 1 then
                        S.trans = nil
                end
        end
        if S.exitGlide then
                local g = S.exitGlide
                g.t = g.t + dt
                local a = math.min(g.t / g.dur, 1)
                local e = a * a * (3 - 2 * a)
                local hrpE = getRoot(myChar())
                if hrpE then
                        g.cf = CFrame.new(hrpE.Position + g.rel) * g.rot -- ikut karakter
                end
                Camera.CFrame = g.from:Lerp(g.cf, e)
                Camera.FieldOfView = g.fromFov + (CFG.FOV - g.fromFov) * e
                if a >= 1 then
                        S.exitGlide = nil
                        Camera.CameraType = Enum.CameraType.Custom
                        local humE = getHum(myChar())
                        if humE then
                                Camera.CameraSubject = humE
                        end
                        Camera.FieldOfView = CFG.FOV
                end
        end
        applyDof()
end))

-- ═══════════════ RESPAWN & PEMAIN KELUAR ═══════════════
table.insert(CONNS, LP.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        setAnchorState() -- respawn: langsung beku lagi kalau kamera masih aktif
        if S.mode == "NONE" then
                local hum = getHum(c)
                if hum and workspace.CurrentCamera.CameraSubject ~= hum then
                        workspace.CurrentCamera.CameraSubject = hum
                end
        end
end))

table.insert(CONNS, Players.PlayerRemoving:Connect(function(pl)
        if S.lockPlayer == pl then
                if S.lockMode == "AUTO" then
                        local best = findNearestPlayer()
                        if best then
                                S.lockPlayer = best
                                S.selected = best
                                notify("AUTO LOCK → " .. best.Name)
                        else
                                S.locked = false
                                S.lockPlayer = nil
                                notify("Target keluar — tidak ada pemain lain")
                        end
                else
                        S.locked = false
                        S.lockPlayer = nil
                        notify("Target keluar — lock dilepas")
                end
                updateChip()
                if UI.updateLockBtn then
                        UI.updateLockBtn()
                end
        end
        if S.selected == pl then
                S.selected = nil
        end
        refreshTargetList()
end))

table.insert(CONNS, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateRatioMasks))
table.insert(CONNS, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Camera = workspace.CurrentCamera
        if Camera then
                updateRatioMasks()
                table.insert(CONNS, Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateRatioMasks))
        end
end))

-- ═══════════════ UNLOAD ═══════════════
function unloadAll()
        unloadDone = true
        for _, c in ipairs(CONNS) do
                pcall(function()
                        c:Disconnect()
                end)
        end
        table.clear(CONNS)
        unbindSpace()
        pcall(function()
                ContextActionService:UnbindAction("CAMERA_TURBO")
                ContextActionService:UnbindAction("CAMERA_SPACE")
                ContextActionService:UnbindAction("SIIILAU_TURBO") -- sisa versi lama
        end)
        pcall(function()
                if S.lightConn then
                        task.cancel(S.lightConn)
                        S.lightConn = nil
                end
                if S.lightPernahAktif and S.oLight then
                        Lighting.ClockTime = S.oLight.ClockTime
                        Lighting.Brightness = S.oLight.Brightness
                        Lighting.Ambient = S.oLight.Ambient
                        Lighting.OutdoorAmbient = S.oLight.OutdoorAmbient
                        Lighting.ExposureCompensation = S.oLight.ExposureCompensation
                        Lighting.FogEnd = S.oLight.FogEnd
                end
        end)
        pcall(function()
                DOF:Destroy()
                DOF_TRANS:Destroy()
                PHOTO_CC:Destroy()
                PHOTO_BLOOM:Destroy()
        end)
        pcall(function()
                Camera.CameraType = Enum.CameraType.Custom
                local hum = getHum(myChar())
                if hum then
                        Camera.CameraSubject = hum
                end
                Camera.FieldOfView = 70
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end)
        pcall(function()
                lebaskanKarakter() -- pulihkan animasi & kontrol gerak yang dibekukan
                S.trans = nil
                S.exitGlide = nil
        end)
        pcall(function()
                local hrp = getRoot(myChar())
                if hrp then
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.Anchored = false
                end
        end)
        pcall(function()
                gui:Destroy()
        end)
        _G.CAMERA_V101_UNLOAD = nil
        _G.SIIILAU_CAM_UNLOAD = nil
        print("[CAMERA v1.0.8] script dihapus — sampai jumpa!")
end
_G.CAMERA_V101_UNLOAD = unloadAll

-- ═══════════════ INISIALISASI ═══════════════
setAnchorState()
updateChip()
refreshTargetList()
refreshModeUI()
setFilter("OFF")
setRatio("FULL")
dbg("3: gui & keybind selesai")
applyLetterbox()
applyUIVisibility()
dbg("4: SEMUA SIAP — tekan F untuk buka panel")
