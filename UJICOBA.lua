--[[
        ═══════════════════════════════════════════════════════════════════
          SIIILAUxCAMERAPRO  ·  v12 NEON EDITION
          Cinematic Camera Suite — FREE / PRO / CINEMATIC / FOTO
        ═══════════════════════════════════════════════════════════════════
          KEYBINDS :
            1        = FREE CAM            (tekan lagi = mati)
            2        = PRO CAM             (tekan lagi = mati)
            3        = CINEMATIC MODE      (tekan lagi = mati)
            CapsLock = nyalakan / matikan kamera bebas (tanpa efek lain)
            F        = buka / tutup panel
            M        = buka MODE FOTO (langsung ke tab FOTO)
            T        = lock target terdekat / unlock
            C        = teleport ke belakang layar
            Z        = auto terang (cuma jalan kalau gelap)
            H        = sembunyikan semua UI (chip tetap ada)
            K (2x)   = hapus script
            RMB      = lihat sekeliling (FREE / PRO)
            Scroll   = FOV (FREE) / zoom 4-80 (PRO)
            Space 3x = turbo  ·  Ctrl = slow (FREE)
          MODE FOTO (layer, aktif di mode kamera manapun):
            Filter warna · rasio frame · fokus/blur manual · ambil foto
          CATATAN :
            • Semua efek client-side — cuma terlihat di layar kamu
            • Aman di-execute ulang kapan saja (auto bersihkan versi lama)
        ═══════════════════════════════════════════════════════════════════
]]

-- ═══════════════ ANTI DUPLIKAT ═══════════════
if _G.SIIILAU_CAM_UNLOAD then
        pcall(_G.SIIILAU_CAM_UNLOAD)
end
task.wait(0.05)

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
        Letterbox = true, -- letterbox otomatis saat mode sinematik
        Anchor    = true, -- anchor karakter saat FREE/PRO aktif
        -- palet neon
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
        panelOpen = true,
        uiHidden = false,
        -- input
        rmb = false,
        ctrlDown = false,
        turbo = false,
        spaceTaps = 0,
        lastSpace = 0,
        lastK = 0,
        -- free cam
        freePos = Vector3.new(0, 0, 0),
        freeVel = Vector3.new(0, 0, 0),
        yaw = 0,
        pitch = -8,
        -- pro cam
        proYaw = 0,
        proPitch = 14,
        proDist = 14,
        proDistT = 14,
        -- target
        locked = false,
        lockPlayer = nil,
        selected = nil,
        -- cinematic director
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
        },
        -- layer foto
        foto = {
                filter = "OFF",
                dof = false,
                focus = 14,
                blur = 65,
                ratio = "FULL",
                wm = false,
        },
        shooting = false,
}

local keys = {}        -- status tombol gerak
local CONNS = {}       -- koneksi (dibersihkan saat unload)
local boundSpace = false
local UI = {}          -- referensi elemen UI
local DOF              -- DepthOfFieldEffect (dipakai cine + foto)
local PHOTO_CC         -- ColorCorrectionEffect (filter foto)
local PHOTO_BLOOM      -- BloomEffect (filter tertentu)

-- ═══════════════ DEKLARASI MAJU ═══════════════
local notify, flash, setAnchorState, updateChip, applyLetterbox, applyDof
local applyUIVisibility, togglePanel, toggleHideUI
local setMode, toggleLock, doTeleport, autoTerang, unloadAll
local getSubjectChar, refreshTargetList, refreshModeUI, updateLockBtn
local setFilter, setRatio, takePhoto, setWatermark, fmtClock
local updateRatioMasks

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

local function lookYawPitch(cf)
        local l = cf.LookVector
        local yaw = math.deg(math.atan2(-l.X, -l.Z))
        local pitch = math.deg(math.asin(math.clamp(l.Y, -1, 1)))
        return yaw, pitch
end

local function fmtClock(ct)
        local h = math.floor(ct)
        local m = math.floor((ct - h) * 60)
        return string.format("%02d:%02d", h, m)
end

-- blur sinematik cuma muncul saat jarak dekat (zoom in)
local function closeDof(d, range)
        return math.clamp((13 - d) / (range or 4), 0, 1)
end

-- ═══════════════ POST EFFECTS (client-side) ═══════════════
DOF = Instance.new("DepthOfFieldEffect")
DOF.Name = "SIIILAU_DOF"
DOF.Enabled = false
DOF.NearIntensity = 0
DOF.FarIntensity = 0.35
DOF.FocusDistance = 12
DOF.InFocusRadius = 7
DOF.Parent = Lighting

PHOTO_CC = Instance.new("ColorCorrectionEffect")
PHOTO_CC.Name = "SIIILAU_FOTO_CC"
PHOTO_CC.Enabled = false
PHOTO_CC.Parent = Lighting

PHOTO_BLOOM = Instance.new("BloomEffect")
PHOTO_BLOOM.Name = "SIIILAU_FOTO_BLOOM"
PHOTO_BLOOM.Enabled = false
PHOTO_BLOOM.Intensity = 0.3
PHOTO_BLOOM.Size = 24
PHOTO_BLOOM.Threshold = 0.85
PHOTO_BLOOM.Parent = Lighting

-- ═══════════════ GUI ROOT ═══════════════
-- cari induk GUI yang bisa ditulis (executor / CoreGui / PlayerGui)
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

-- bersihkan GUI versi lama
do
        local names = { "SIIILAUxCAMERAPRO", "SIIILAU_GALAXY_CAM" }
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
gui.Name = "SIIILAUxCAMERAPRO"
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
-- letterbox sinematik (62px, selalu ada tapi tinggi 0 saat mati)
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

-- mask rasio foto (4 batang hitam)
UI.maskT = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 0), ZIndex = 4 }, gui)
UI.maskB = new("Frame", { AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 0), ZIndex = 4 }, gui)
UI.maskL = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), ZIndex = 4 }, gui)
UI.maskR = new("Frame", { AnchorPoint = Vector2.new(1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(1, 0, 0, 0), ZIndex = 4 }, gui)

-- flash transisi
UI.flash = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 60,
}, gui)

-- chip status (kiri atas, selalu tampil walau UI hidden)
UI.chip = new("Frame", {
        Position = UDim2.new(0, 14, 0, 14),
        Size = UDim2.new(0, 0, 0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = CFG.BG,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        ZIndex = 10,
}, gui)
corner(UI.chip, 999)
UI.chipStroke = stroke(UI.chip, CFG.Neon1, 1, 0.35)
pad(UI.chip, 0, 0, 12, 12)
UI.chipTxt = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.GothamBold,
        Text = "● SIIILAU · SIAP",
        TextColor3 = CFG.TXT,
        TextSize = 12,
        ZIndex = 10,
}, UI.chip)

-- label shot sinematik (kanan atas, kecil)
UI.shot = new("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.new(0, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = CFG.BG,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10,
}, gui)
corner(UI.shot, 999)
stroke(UI.shot, CFG.Neon2, 1, 0.3)
pad(UI.shot, 0, 0, 10, 10)
UI.shotTxt = new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Font = Enum.Font.GothamBold,
        Text = "● SHOT",
        TextColor3 = CFG.TXT,
        TextSize = 11,
        ZIndex = 10,
}, UI.shot)
do
        local g = grad(UI.shotTxt, CFG.Neon1, CFG.Neon2, 0)
        g.Enabled = true
end

-- kotak notifikasi (kanan, di bawah label shot)
UI.notifBox = new("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 48),
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

-- watermark foto (opsional)
UI.wm = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -10, 1, -10),
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = CFG.BG,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = " SIIILAUxCAMERAPRO ",
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

-- header (judul + tombol lipat) — area drag
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
        Text = "SIIILAU<font color=\"#FF2DAA\">x</font>CAMERAPRO",
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
        Text = "v12 · NEON EDITION · 1/2/3 = MODE",
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

-- baris tab
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

-- badan panel (scrollable)
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

-- footer hint
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

-- frame tab (dibuat di part 3, direferensikan di sini)
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
