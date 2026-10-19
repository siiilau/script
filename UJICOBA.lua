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

secLabel(UI.tabCAM, "Pengaturan", 5)
UI.speedSlider = makeSlider(UI.tabCAM, "KECEPATAN", 8, 90, CFG.Speed, function(v)
        return math.floor(v) .. " stud/s"
end, function(v)
        CFG.Speed = v
end, 6)
UI.fovSlider = makeSlider(UI.tabCAM, "FOV", 30, 105, CFG.FOV, function(v)
        return math.floor(v) .. "°"
end, function(v)
        CFG.FOV = v
end, 7)
UI.tempoSlider = makeSlider(UI.tabCAM, "CINE TEMPO", 3, 10, CFG.CineTempo, function(v)
        return string.format("%.1f s", v)
end, function(v)
        CFG.CineTempo = v
end, 8)

-- ═══════════════ ISI TAB TARGET ═══════════════
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, UI.tabTARGET)
pad(UI.tabTARGET, 2, 8, 0, 0)

UI.lockBtn = makePill(UI.tabTARGET, "T · LOCK TARGET TERDEKAT", 34, 1, function()
        toggleLock()
end)
UI.refreshBtn = makePill(UI.tabTARGET, "SEGARKAN DAFTAR", 28, 2, function()
        refreshTargetList()
end)
secLabel(UI.tabTARGET, "Pilih Manual", 3)

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
        LayoutOrder = 4,
        ZIndex = 6,
}, UI.tabTARGET)
corner(UI.tList, 12)
stroke(UI.tList, CFG.Neon2, 1, 0.7)
new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, UI.tList)
pad(UI.tList, 6, 6, 6, 6)

new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
        Font = Enum.Font.GothamMedium,
        Text = "Sinematik mengikuti: lock > pilihan > terdekat > diri sendiri",
        TextColor3 = CFG.TXT_DIM,
        TextSize = 10,
        TextWrapped = true,
        LayoutOrder = 5,
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
makePill(UI.tabSISTEM, "Z · AUTO TERANG (GELAP ke SIANG)", 32, 5, function()
        autoTerang()
end)
makeToggle(UI.tabSISTEM, "ANCHOR KARAKTER (FREE/PRO)", CFG.Anchor, function(state)
        CFG.Anchor = state
        setAnchorState()
end, 6)
makeToggle(UI.tabSISTEM, "LETTERBOX SINEMATIK", CFG.Letterbox, function(state)
        CFG.Letterbox = state
        applyLetterbox()
end, 7)

secLabel(UI.tabSISTEM, "Keybind", 8)
new("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 74),
        Font = Enum.Font.GothamMedium,
        Text = "1/2/3 · mode kamera      CapsLock · kamera bebas\nF · panel      M · mode foto      T · lock      C · teleport\nZ · terang      H · sembunyikan      K 2x · hapus script\nRMB · lihat      Scroll · zoom/FOV      Space 3x · turbo",
        TextColor3 = CFG.TXT_DIM,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = 9,
        ZIndex = 6,
}, UI.tabSISTEM)

local dangerBtn = makePill(UI.tabSISTEM, "K 2x · HAPUS SCRIPT", 32, 10, function()
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

secLabel(UI.tabFOTO, "Fokus Manual (Blur)", 5)
makeToggle(UI.tabFOTO, "FOKUS / BLUR AKTIF", false, function(state)
        S.foto.dof = state
end, 6)
makeSlider(UI.tabFOTO, "JARAK FOKUS", 2, 100, S.foto.focus, function(v)
        return math.floor(v) .. " stud"
end, function(v)
        S.foto.focus = v
end, 7)
makeSlider(UI.tabFOTO, "KEKUATAN BLUR", 0, 100, S.foto.blur, function(v)
        return math.floor(v) .. "%"
end, function(v)
        S.foto.blur = v
end, 8)

secLabel(UI.tabFOTO, "Ambil Foto", 9)
do
        local shotBtn = makePill(UI.tabFOTO, "●  AMBIL FOTO  (LAYAR BERSIH 5 DETIK)", 38, 10, function()
                takePhoto()
        end)
        shotBtn.TextSize = 12
        local g = grad(shotBtn, CFG.Neon1, CFG.Neon2, 0)
        g.Enabled = true
        shotBtn.TextColor3 = Color3.fromRGB(10, 10, 18)
end
makeToggle(UI.tabFOTO, "WATERMARK SIIILAUxCAMERAPRO", false, function(state)
        setWatermark(state)
end, 11)

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
        dur = dur or 3
        if not UI.notifBox then
                return
        end
        local n = new("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Size = UDim2.new(0, 236, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = CFG.BG,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = -os.clock(),
                ZIndex = 11,
        }, UI.notifBox)
        corner(n, 12)
        local st = stroke(n, CFG.Neon1, 1, 1)
        local t = new("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0, 0, 0, 0),
                Font = Enum.Font.GothamMedium,
                Text = text,
                TextColor3 = CFG.TXT,
                TextSize = 11,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTransparency = 1,
                ZIndex = 11,
        }, n)
        pad(n, 7, 9, 12, 12)
        local sc = new("UIScale", { Scale = 0.85 }, n)
        TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        TweenService:Create(n, TweenInfo.new(0.2), { BackgroundTransparency = 0.2 }):Play()
        TweenService:Create(t, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
        TweenService:Create(st, TweenInfo.new(0.2), { Transparency = 0.45 }):Play()
        task.delay(dur, function()
                TweenService:Create(n, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
                TweenService:Create(t, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
                TweenService:Create(st, TweenInfo.new(0.35), { Transparency = 1 }):Play()
                task.delay(0.4, function()
                        n:Destroy()
                end)
        end)
        -- batasi jumlah notifikasi
        local kids = {}
        for _, c in ipairs(UI.notifBox:GetChildren()) do
                if c:IsA("Frame") then
                        table.insert(kids, c)
                end
        end
        if #kids > 5 then
                kids[1]:Destroy()
        end
end

-- ═══════════════ VISIBILITAS UI ═══════════════
function applyUIVisibility()
        local vis = not S.uiHidden
        UI.panel.Visible = vis and S.panelOpen
        UI.notifBox.Visible = vis
        UI.shot.Visible = vis and (S.mode == "CINE")
        -- chip selalu tampil
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
        local on = (S.mode == "CINE") and CFG.Letterbox and (S.foto.ratio == "FULL")
        local target = on and 62 or 0
        local tw = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(UI.lbT, tw, { Size = UDim2.new(1, 0, 0, target) }):Play()
        TweenService:Create(UI.lbB, tw, { Size = UDim2.new(1, 0, 0, target) }):Play()
end

-- ═══════════════ CHIP STATUS ═══════════════
function updateChip()
        local txt, col
        if S.mode == "FREE" then
                txt, col = "FREE CAM", CFG.Neon1
        elseif S.mode == "PRO" then
                txt, col = "PRO CAM", CFG.Neon1
        elseif S.mode == "CINE" then
                txt, col = "CINEMATIC", CFG.Neon2
        else
                txt, col = "SIAP", CFG.TXT_DIM
        end
        if S.mode == "CINE" then
                local c = getSubjectChar()
                local pl = c and Players:GetPlayerFromCharacter(c)
                local nm = "?"
                if pl then
                        nm = (pl == LP) and "DIRI SENDIRI" or pl.Name
                end
                txt = txt .. " · " .. nm
        end
        if S.turbo then
                txt = txt .. " · TURBO"
        end
        UI.chipTxt.Text = "● " .. txt
        UI.chipStroke.Color = col
end

-- ═══════════════ ANCHOR ═══════════════
function setAnchorState()
        local want = CFG.Anchor and (S.mode == "FREE" or S.mode == "PRO")
        local hrp = getRoot(myChar())
        if hrp then
                hrp.Anchored = want
        end
end

-- ═══════════════ SUBJEK (TARGET) ═══════════════
function getSubjectChar()
        -- prioritas: lock > pilihan manual > terdekat > diri sendiri
        if S.locked and S.lockPlayer and S.lockPlayer.Parent then
                local c = S.lockPlayer.Character
                if c and c.Parent then
                        return c
                end
        end
        if S.selected and S.selected.Parent then
                local c = S.selected.Character
                if c and c.Parent then
                        return c
                end
        end
        local myRoot = getRoot(myChar())
        local origin = myRoot and myRoot.Position or workspace.CurrentCamera.CFrame.Position
        local best, bd
        for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LP then
                        local r = getRoot(pl.Character)
                        if r then
                                local d = (r.Position - origin).Magnitude
                                if not bd or d < bd then
                                        best, bd = pl, d
                                end
                        end
                end
        end
        if best then
                return best.Character
        end
        return myChar()
end

function toggleLock()
        if S.locked then
                S.locked = false
                S.lockPlayer = nil
                updateChip()
                refreshTargetList()
                if UI.updateLockBtn then
                        UI.updateLockBtn()
                end
                notify("Target lock: MATI")
                return
        end
        local myRoot = getRoot(myChar())
        local origin = myRoot and myRoot.Position or workspace.CurrentCamera.CFrame.Position
        local best, bd
        for _, pl in ipairs(Players:GetPlayers()) do
                if pl ~= LP then
                        local r = getRoot(pl.Character)
                        if r then
                                local d = (r.Position - origin).Magnitude
                                if not bd or d < bd then
                                        best, bd = pl, d
                                end
                        end
                end
        end
        if not best then
                notify("Tidak ada pemain lain di server")
                return
        end
        S.locked = true
        S.lockPlayer = best
        S.selected = best
        updateChip()
        refreshTargetList()
        if UI.updateLockBtn then
                UI.updateLockBtn()
        end
        notify("Locked: " .. best.Name .. " (" .. math.floor(bd) .. " stud)")
end

function updateLockBtn()
        if UI.lockBtn then
                if S.locked and S.lockPlayer then
                        UI.lockBtn.Text = "T · UNLOCK (" .. S.lockPlayer.Name .. ")"
                        UI.lockBtn.TextColor3 = CFG.Neon2
                else
                        UI.lockBtn.Text = "T · LOCK TARGET TERDEKAT"
                        UI.lockBtn.TextColor3 = CFG.TXT
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
                local isSel = (S.selected == row.pl) or (S.locked and S.lockPlayer == row.pl)
                local label = row.pl == LP and (row.pl.Name .. "  (kamu)") or row.pl.Name
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
                        S.selected = row.pl
                        updateChip()
                        refreshTargetList()
                end)
        end
end

-- ═══════════════ TELEPORT (C) ═══════════════
function doTeleport()
        local char = myChar()
        local hum, hrp = getHum(char), getRoot(char)
        if not (hum and hrp) then
                notify("Karakter belum siap")
                return
        end
        local cam = workspace.CurrentCamera
        local d = math.clamp(CFG.TeleDist, 0, 30)
        -- posisi di belakang layar (di belakang kamera)
        local pos = (cam.CFrame * CFrame.new(0, 0, d)).Position
        -- cari tanah (abaikan semua karakter pemain)
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

-- ═══════════════ AUTO TERANG (Z) ═══════════════
function autoTerang()
        local ct = Lighting.ClockTime
        local dark = ct < 6 or ct >= 18
        if not dark then
                notify("Sudah terang (" .. fmtClock(ct) .. ") — kondisi siang, tidak diubah")
                return
        end
        local target = 13.5
        local dFwd = (target - ct) % 24
        local dBack = dFwd - 24
        local delta
        if math.abs(dFwd) <= math.abs(dBack) then
                delta = dFwd
        else
                delta = dBack
        end
        local goal = ct + delta
        local tw = TweenService:Create(
                Lighting,
                TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
                { ClockTime = goal, Brightness = math.max(Lighting.Brightness, 3) }
        )
        tw:Play()
        notify("Auto terang: " .. fmtClock(ct) .. " ke " .. fmtClock(goal))
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
                        -- target lebih lebar: batang atas & bawah
                        local barH = (vp.Y - vp.X / R) / 2
                        UI.maskT.Size = UDim2.new(1, 0, 0, barH)
                        UI.maskB.Size = UDim2.new(1, 0, 0, barH)
                        UI.maskL.Size = UDim2.new(0, 0, 1, 0)
                        UI.maskR.Size = UDim2.new(0, 0, 1, 0)
                else
                        -- target lebih tinggi: batang kiri & kanan
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
        if S.foto.dof then
                -- fokus manual foto = prioritas tertinggi
                DOF.Enabled = true
                DOF.FocusDistance = S.foto.focus
                DOF.InFocusRadius = 5 + S.foto.blur * 0.05
                DOF.FarIntensity = 0.15 + (S.foto.blur / 100) * 0.65
                DOF.NearIntensity = (S.foto.blur / 100) * 0.4
        elseif S.mode == "CINE" and (S.cine.dofK or 0) > 0.02 then
                -- blur sinematik otomatis: cuma saat zoom in
                DOF.Enabled = true
                DOF.FocusDistance = S.cine.focusDist or 10
                DOF.InFocusRadius = 7
                DOF.FarIntensity = 0.22 + 0.25 * S.cine.dofK
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
        local els = { UI.panel, UI.notifBox, UI.shot, UI.chip }
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

-- ═══════════════ FREE CAM ═══════════════
local function freeUpdate(dt)
        local cf = CFrame.fromOrientation(math.rad(S.pitch), math.rad(S.yaw), 0)
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
        local spd = CFG.Speed * (S.turbo and 2.5 or 1) * (S.ctrlDown and 0.25 or 1)
        if move.Magnitude > 0.001 then
                move = move.Unit * spd
        end
        S.freeVel = expLerp(S.freeVel, move, dt, 9)
        S.freePos = S.freePos + S.freeVel * dt
        Camera.CFrame = CFrame.new(S.freePos) * cf
        Camera.FieldOfView = expLerp(Camera.FieldOfView, CFG.FOV, dt, 7)
end

-- ═══════════════ PRO CAM ═══════════════
local function proUpdate(dt)
        S.proDist = expLerp(S.proDist, S.proDistT, dt, 8)
        local root = getRoot(myChar())
        if root then
                local pivot = root.Position + Vector3.new(0, 1.5, 0)
                local cf = CFrame.fromOrientation(math.rad(-S.proPitch), math.rad(S.proYaw), 0)
                local pos = pivot + (cf * CFrame.new(0, 0, S.proDist)).Position
                Camera.CFrame = CFrame.lookAt(pos, pivot)
        end
        Camera.FieldOfView = expLerp(Camera.FieldOfView, CFG.FOV, dt, 7)
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

-- arah halus (mengikuti gerakan/ tatapan subjek tanpa patah)
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

-- konteks subjek untuk shot director
local function cineCtx()
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
                head = pos + Vector3.new(0, 1.6, 0),
        }
end

-- ═══════════════ LIBRARY SHOT (11 SHOT) ═══════════════
local SHOTS = {}

-- 1. CHASE LOW — kejar rendah dari belakang
SHOTS["CHASE LOW"] = {
        weights = { idle = 0.4, walk = 2.5, run = 4, vehicle = 5 },
        enter = function(ctx, P)
                P.d = rr(9, 14)
                P.h = rr(1.8, 3.2)
                P.fov = rr(60, 70)
                P.dir = ctx.moveDir
                seedSway(P, 1.3)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.2)
                local p = ctx.pos - dir * P.d + Vector3.new(0, P.h, 0) + sway(P, t, 0.14)
                return CFrame.lookAt(p, ctx.head + dir * 4), P.fov, closeDof(P.d, 4)
        end,
}

-- 2. WIDE SHOT — jauh & zoom out, estetik perjalanan
SHOTS["WIDE SHOT"] = {
        weights = { idle = 1.2, walk = 2, run = 3, vehicle = 4 },
        enter = function(ctx, P)
                P.d = rr(28, 42)
                P.h = rr(6, 10)
                P.fov = rr(52, 60)
                P.dir = ctx.moveDir
                seedSway(P, 0.7)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 1.6)
                local p = ctx.pos - dir * P.d + Vector3.new(0, P.h, 0) + sway(P, t, 0.3)
                return CFrame.lookAt(p, ctx.head + dir * 6), P.fov, 0
        end,
}

-- 3. SIDE TRACK — samping menyusul
SHOTS["SIDE TRACK"] = {
        weights = { idle = 1, walk = 4, run = 4, vehicle = 4 },
        enter = function(ctx, P)
                P.absd = rr(9, 14)
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

-- 4. FRONT PASS — kamera statis DI DEPAN, subjek lewat mendekat
SHOTS["FRONT PASS"] = {
        weights = { idle = 0.5, walk = 3.5, run = 2.5, vehicle = 3 },
        enter = function(ctx, P)
                P.approachDir = ctx.moveDir
                P.spot = ctx.pos + ctx.moveDir * rr(11, 17) + Vector3.new(0, rr(1.6, 2.6), 0)
                P.fov = rr(58, 70)
                P.cut = false
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                local rel = ctx.pos - P.spot
                local along = rel:Dot(P.approachDir)
                if along < -2.5 and not P.cut then
                        -- subjek sudah lewat kamera: potong lebih cepat
                        P.cut = true
                        S.cine.dur = math.min(S.cine.dur, S.cine.t + 0.12)
                end
                local p = P.spot + sway(P, t, 0.1)
                return CFrame.lookAt(p, ctx.head), P.fov, closeDof(rel.Magnitude, 5)
        end,
}

-- 5. CLOSE-UP — kamera DI DEPAN BADAN karakter
SHOTS["CLOSE-UP"] = {
        weights = { idle = 4, walk = 1.5, run = 0.4, vehicle = 0.3 },
        enter = function(ctx, P)
                P.dirMode = "look"
                P.d = rr(4.5, 7)
                P.hOff = rr(0.6, 1.4)
                P.fov = rr(34, 46)
                seedSway(P, 0.8)
        end,
        update = function(P, t, dt, ctx)
                local face = smoothDir(P, ctx, dt, 3)
                local p = ctx.pos + face * P.d + Vector3.new(0, P.hOff, 0) + sway(P, t, 0.07)
                return CFrame.lookAt(p, ctx.head), P.fov, 1
        end,
}

-- 6. LEAD AHEAD — kamera di depan menghadap balik
SHOTS["LEAD AHEAD"] = {
        weights = { idle = 0.5, walk = 3, run = 3.5, vehicle = 3.5 },
        enter = function(ctx, P)
                P.d = rr(12, 18)
                P.h = rr(2, 4)
                P.fov = rr(55, 63)
                seedSway(P, 1)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2.4)
                local p = ctx.pos + dir * P.d + Vector3.new(0, P.h, 0) + sway(P, t, 0.15)
                return CFrame.lookAt(p, ctx.head), P.fov, 0
        end,
}

-- 7. ORBIT 360 — putar penuh mengelilingi
SHOTS["ORBIT 360"] = {
        weights = { idle = 3.5, walk = 1.5, run = 1, vehicle = 1 },
        enter = function(ctx, P)
                P.r = rr(10, 17)
                P.h = rr(2, 5)
                P.ang = rr(0, math.pi * 2)
                P.spd = (math.random() < 0.5 and -1 or 1) * math.rad(rr(35, 65))
                P.fov = rr(55, 65)
                seedSway(P, 0.9)
        end,
        update = function(P, t, dt, ctx)
                P.ang = P.ang + P.spd * dt
                local p = ctx.pos + Vector3.new(math.cos(P.ang) * P.r, P.h, math.sin(P.ang) * P.r) + sway(P, t, 0.12)
                return CFrame.lookAt(p, ctx.head), P.fov, closeDof(P.r, 5)
        end,
}

-- 8. CRANE RISE — naik perlahan dari rendah ke tinggi
SHOTS["CRANE RISE"] = {
        weights = { idle = 3, walk = 2, run = 1.5, vehicle = 1.5 },
        enter = function(ctx, P)
                P.dir = ctx.moveDir
                P.d0 = rr(8, 12)
                P.d1 = P.d0 + rr(5, 9)
                P.h1 = rr(9, 15)
                P.fov0 = rr(58, 66)
                seedSway(P, 0.8)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 1.8)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local h = 1.6 + (P.h1 - 1.6) * k
                local p = ctx.pos - dir * d + Vector3.new(0, h, 0) + sway(P, t, 0.12)
                return CFrame.lookAt(p, ctx.head), P.fov0 - 10 * k, 0
        end,
}

-- 9. DOLLY PUSH — zoom in perlahan, blur muncul di akhir
SHOTS["DOLLY PUSH"] = {
        weights = { idle = 3, walk = 1.5, run = 0.5, vehicle = 0.5 },
        enter = function(ctx, P)
                P.dirMode = (math.random() < 0.55 and "look" or "move")
                P.front = (P.dirMode == "look")
                P.d0 = rr(16, 20)
                P.d1 = rr(6.5, 9)
                P.fov0 = rr(56, 66)
                P.fov1 = P.fov0 - rr(14, 20)
                seedSway(P, 0.7)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 1.8)
                local k = smoothstep(t / math.max(S.cine.dur, 0.1))
                local d = P.d0 + (P.d1 - P.d0) * k
                local sign = P.front and 1 or -1
                local p = ctx.pos + dir * d * sign + Vector3.new(0, 1.6 + 0.6 * (1 - k), 0) + sway(P, t, 0.08)
                return CFrame.lookAt(p, ctx.head), P.fov0 + (P.fov1 - P.fov0) * k, closeDof(d, 5)
        end,
}

-- 10. DUTCH TILT — miring dramatis
SHOTS["DUTCH TILT"] = {
        weights = { idle = 2, walk = 2, run = 1.5, vehicle = 1.5 },
        enter = function(ctx, P)
                P.absd = rr(6.5, 10)
                P.side = (math.random() < 0.5 and -1 or 1) * P.absd
                P.h = rr(1.6, 2.6)
                P.roll = (math.random() < 0.5 and -1 or 1) * math.rad(rr(8, 15))
                P.drift = (math.random() < 0.5 and -1 or 1) * rr(0.8, 1.7)
                P.fov = rr(46, 58)
                P.dir = ctx.moveDir
                seedSway(P, 1)
        end,
        update = function(P, t, dt, ctx)
                local dir = smoothDir(P, ctx, dt, 2)
                local perp = Vector3.new(-dir.Z, 0, dir.X)
                if perp.Magnitude > 0.001 then
                        perp = perp.Unit
                end
                local drift = perp * (t * P.drift)
                local p = ctx.pos + perp * P.side + Vector3.new(0, P.h, 0) + drift + sway(P, t, 0.12)
                local cf = CFrame.lookAt(p, ctx.head) * CFrame.Angles(0, 0, P.roll)
                return cf, P.fov, closeDof(P.absd, 4)
        end,
}

-- 11. TOP-DOWN — dari atas, berputar pelan
SHOTS["TOP-DOWN"] = {
        weights = { idle = 2.5, walk = 1.5, run = 1, vehicle = 1.5 },
        enter = function(ctx, P)
                P.h = rr(20, 32)
                P.offA = rr(0, math.pi * 2)
                P.offR = rr(3, 7)
                P.spin = (math.random() < 0.5 and -1 or 1) * math.rad(rr(6, 14))
                P.fov = rr(48, 58)
                seedSway(P, 0.6)
        end,
        update = function(P, t, dt, ctx)
                P.offA = P.offA + P.spin * dt
                local off = Vector3.new(math.cos(P.offA) * P.offR, 0, math.sin(P.offA) * P.offR)
                local p = ctx.pos + off + Vector3.new(0, P.h, 0)
                local lookTarget = ctx.pos + off * 0.3
                local cf = CFrame.lookAt(p, lookTarget)
                if math.abs(cf.LookVector.Y) > 0.995 then
                        cf = CFrame.lookAt(p, lookTarget + Vector3.new(0.001, 0, 0.001))
                end
                return cf, P.fov, 0
        end,
}

-- ═══════════════ PEMILIH SHOT ADAPTIF ═══════════════
local function pickShot()
        local ctx = cineCtx()
        local pool, total = {}, 0
        for name, def in pairs(SHOTS) do
                local w = def.weights[ctx.context] or 0
                if w > 0 and name ~= S.cine.lastName then
                        table.insert(pool, { name = name, w = w })
                        total = total + w
                end
        end
        if #pool == 0 then
                for name, def in pairs(SHOTS) do
                        local w = def.weights[ctx.context] or 0
                        if w > 0 then
                                table.insert(pool, { name = name, w = w })
                                total = total + w
                        end
                end
        end
        if #pool == 0 then
                return "ORBIT 360"
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

local function startShot()
        local ctx = cineCtx()
        local name = pickShot()
        local def = SHOTS[name]
        S.cine.name = name
        S.cine.lastName = name
        S.cine.def = def
        S.cine.t = 0
        S.cine.dur = math.clamp(CFG.CineTempo + rr(-1.2, 1.2), 2.5, 10)
        S.cine.char = ctx.char
        S.cine.P = {}
        if def and def.enter then
                def.enter(ctx, S.cine.P)
        end
        if UI.shotTxt then
                UI.shotTxt.Text = "● " .. name
        end
end

local function cineUpdate(dt)
        if not S.cine.def then
                startShot()
                if not S.cine.def then
                        return
                end
        end
        local ctx = cineCtx()
        if not ctx.root then
                return
        end
        S.cine.t = S.cine.t + dt
        if ctx.char ~= S.cine.char or S.cine.t >= S.cine.dur then
                startShot()
        end
        local cf, fov, dofK = S.cine.def.update(S.cine.P, S.cine.t, dt, ctx)
        -- breathing FOV halus biar hidup
        fov = fov + math.sin(os.clock() * 1.2) * 1.2
        Camera.CFrame = cf
        Camera.FieldOfView = fov
        S.cine.dofK = dofK or 0
        S.cine.focusDist = (Camera.CFrame.Position - ctx.head).Magnitude
end

-- ═══════════════ SPACE SINK + TURBO (3x TAP) ═══════════════
local function bindSpace()
        if boundSpace then
                return
        end
        boundSpace = true
        ContextActionService:BindAction("SIIILAU_SPACE", function(_, state)
                if state == Enum.UserInputState.Begin then
                        local now = os.clock()
                        if now - S.lastSpace < 0.5 then
                                S.spaceTaps = S.spaceTaps + 1
                        else
                                S.spaceTaps = 1
                        end
                        S.lastSpace = now
                        if S.spaceTaps >= 3 then
                                S.spaceTaps = 0
                                S.turbo = not S.turbo
                                if S.turbo then
                                        notify("TURBO ON — kecepatan x2.5")
                                else
                                        notify("TURBO OFF")
                                end
                                updateChip()
                        end
                        return Enum.ContextActionResult.Sink
                end
                return Enum.ContextActionResult.Pass
        end, false, Enum.KeyCode.Space)
end

local function unbindSpace()
        if not boundSpace then
                return
        end
        boundSpace = false
        pcall(function()
                ContextActionService:UnbindAction("SIIILAU_SPACE")
        end)
end

-- ═══════════════ GANTI MODE KAMERA ═══════════════
function setMode(m)
        if m ~= "NONE" and S.mode == m then
                -- tekan tombol mode yang sama = matikan
                m = "NONE"
        end
        if S.mode == "FREE" or S.mode == "PRO" then
                unbindSpace()
        end
        S.mode = m
        if m == "NONE" then
                Camera.CameraType = Enum.CameraType.Custom
                local hum = getHum(myChar())
                if hum then
                        Camera.CameraSubject = hum
                end
                Camera.FieldOfView = CFG.FOV
                setAnchorState()
                S.cine.def = nil
                S.cine.dofK = 0
                S.turbo = false
        elseif m == "FREE" then
                local camCF = workspace.CurrentCamera.CFrame
                S.freePos = camCF.Position
                S.yaw, S.pitch = lookYawPitch(camCF)
                S.freeVel = Vector3.new(0, 0, 0)
                S.turbo = false
                Camera.CameraType = Enum.CameraType.Scriptable
                setAnchorState()
                bindSpace()
                Camera.FieldOfView = CFG.FOV * 0.8 -- efek zoom-in pembuka
                notify("FREE CAM — WASD+QE gerak · RMB lihat · Scroll FOV · Space 3x turbo")
        elseif m == "PRO" then
                local py = lookYawPitch(workspace.CurrentCamera.CFrame)
                S.proYaw = py
                S.proPitch = 12
                S.proDist = 14
                S.proDistT = 14
                Camera.CameraType = Enum.CameraType.Scriptable
                setAnchorState()
                bindSpace()
                Camera.FieldOfView = CFG.FOV * 0.8
                notify("PRO CAM — RMB putar · Scroll zoom 4–80 stud")
        elseif m == "CINE" then
                Camera.CameraType = Enum.CameraType.Scriptable
                S.cine.def = nil
                setAnchorState() -- karakter bebas gerak, bisa difilmkan
                notify("CINEMATIC — shot otomatis + cut langsung · tempo " .. string.format("%.1f", CFG.CineTempo) .. "s")
        end
        refreshModeUI()
        updateChip()
        applyLetterbox()
        applyUIVisibility()
end

-- ═══════════════ INPUT KEYBIND ═══════════════
table.insert(CONNS, UserInputService.InputBegan:Connect(function(input, gp)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
                S.rmb = true
                pcall(function()
                        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                end)
                return
        end
        if gp then
                return
        end
        local kc = input.KeyCode
        if input.UserInputType == Enum.UserInputType.Keyboard and kc then
                keys[kc] = true
        end
        if kc == Enum.KeyCode.One then
                setMode("FREE")
        elseif kc == Enum.KeyCode.Two then
                setMode("PRO")
        elseif kc == Enum.KeyCode.Three then
                setMode("CINE")
        elseif kc == Enum.KeyCode.CapsLock then
                -- cuma nyalakan/matikan kamera bebas, tanpa efek lain
                if S.mode == "FREE" then
                        setMode("NONE")
                else
                        setMode("FREE")
                end
        elseif kc == Enum.KeyCode.F then
                togglePanel()
        elseif kc == Enum.KeyCode.M then
                -- MODE FOTO: buka panel + langsung ke tab FOTO
                if S.uiHidden then
                        toggleHideUI()
                end
                S.panelOpen = true
                UI.panel.Visible = true
                switchTab("FOTO")
                notify("MODE FOTO · atur filter, rasio & DoF lalu AMBIL FOTO")
        elseif kc == Enum.KeyCode.T then
                toggleLock()
        elseif kc == Enum.KeyCode.C then
                doTeleport()
        elseif kc == Enum.KeyCode.Z then
                autoTerang()
        elseif kc == Enum.KeyCode.H then
                toggleHideUI()
        elseif kc == Enum.KeyCode.K then
                local now = os.clock()
                if now - S.lastK < 2 then
                        unloadAll()
                else
                        S.lastK = now
                        notify("Tekan K sekali lagi untuk hapus script")
                end
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

-- RMB look + scroll zoom/FOV
table.insert(CONNS, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
                if S.rmb and (S.mode == "FREE" or S.mode == "PRO") then
                        local dx, dy = input.Delta.X, input.Delta.Y
                        if S.mode == "FREE" then
                                S.yaw = (S.yaw - dx * 0.28) % 360
                                S.pitch = math.clamp(S.pitch - dy * 0.28, -89, 89)
                        else
                                S.proYaw = (S.proYaw - dx * 0.28) % 360
                                S.proPitch = math.clamp(S.proPitch + dy * 0.25, -78, 78)
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
                        S.proDistT = math.clamp(S.proDistT - z * 2.5, 4, 80)
                end
        end
end))

-- ═══════════════ LOOP RENDER ═══════════════
table.insert(CONNS, RunService.RenderStepped:Connect(function(dt)
        Camera = workspace.CurrentCamera
        if S.mode == "FREE" then
                freeUpdate(dt)
        elseif S.mode == "PRO" then
                proUpdate(dt)
        elseif S.mode == "CINE" then
                cineUpdate(dt)
        end
        applyDof()
end))

-- ═══════════════ RESPAWN & PEMAIN KELUAR ═══════════════
table.insert(CONNS, LP.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if (S.mode == "FREE" or S.mode == "PRO") and CFG.Anchor then
                local r = getRoot(c)
                if r then
                        r.Anchored = true
                end
        end
        if S.mode == "NONE" then
                local hum = getHum(c)
                if hum and workspace.CurrentCamera.CameraSubject ~= hum then
                        workspace.CurrentCamera.CameraSubject = hum
                end
        end
end))

table.insert(CONNS, Players.PlayerRemoving:Connect(function(pl)
        if S.lockPlayer == pl then
                S.locked = false
                S.lockPlayer = nil
                updateChip()
                if UI.updateLockBtn then
                        UI.updateLockBtn()
                end
                notify("Target keluar — lock dilepas")
        end
        if S.selected == pl then
                S.selected = nil
        end
        refreshTargetList()
end))

-- rasio mask ikut resize layar (dan ikut kamera baru)
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
        for _, c in ipairs(CONNS) do
                pcall(function()
                        c:Disconnect()
                end)
        end
        table.clear(CONNS)
        unbindSpace()
        pcall(function()
                DOF:Destroy()
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
        end)
        pcall(function()
                local hrp = getRoot(myChar())
                if hrp then
                        hrp.Anchored = false
                end
        end)
        pcall(function()
                gui:Destroy()
        end)
        _G.SIIILAU_CAM_UNLOAD = nil
        print("[SIIILAUxCAMERAPRO] script dihapus — sampai jumpa!")
end
_G.SIIILAU_CAM_UNLOAD = unloadAll

-- ═══════════════ INISIALISASI ═══════════════
updateChip()
refreshTargetList()
refreshModeUI()
setFilter("OFF")
setRatio("FULL")
applyLetterbox()
applyUIVisibility()
notify("SIIILAUxCAMERAPRO v12 siap — tekan 1 / 2 / 3 buat pilih mode", 5)
