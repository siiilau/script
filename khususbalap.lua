--[[═════════════════════════════════════════
    ⛓️ Siiilau⚡ — RACE LITE v1.0.0 (🎥 TAB RUTE)
    Rekam ultra-halus (0.01s / 0.5 stud) → belokan
    sekecil apapun tercatat. Garis tampil di-smooth
    (mulus, tipis, transparan, tidak ganggu pandangan)
    Rekam diri/pemain → isi nama → simpan
    GABUNG CERDAS: titik temu / jembatan otomatis
    HOTKEYS: F=GUI Q=Speed R=Hide T=Bright
             K=Rekam Diri L=Rekam Player
    ═════════════════════════════════════════]]

--═══════════════ KONFIG ═══════════════
local DEFAULT_SPEED = 17.25
local DEFAULT_JUMP  = 52.25
local STEP          = 0.25
local CLOCK_STEP    = 0.5
local LOCK_TIME     = true

local RADIUS_SENTUH = 20
local CEK_INTERVAL  = 0.4
local UKURAN_GUI    = 0.8

-- 🎥 REKAM RUTE (ULTRA HALUS)
local REC_INTERVAL     = 0.01   -- cek posisi tiap 0.01 detik
local REC_MIN_JARAK    = 0.5    -- titik baru tiap 0.5 stud (sangat detail)
local MAX_TITIK        = 30000  -- batas titik per file (data, bukan part)
local DRAFT_TIAP       = 500    -- auto-save draft tiap N titik
local JARAK_LOMPAT     = 60     -- teleport > ini = garis putus

-- ✏️ TAMPILAN GARIS (halus & tidak mengganggu)
local LINE_TEBAL       = 0.05   -- tipis
local LINE_TRANS       = 0.7   -- semi transparan (0=padat, 1=hilang)
local SMPL_ANGLE       = 8      -- derajat: belokan ≥ ini wajib digambar
local SMPL_MAX_SEG     = 12     -- part maksimal 12 stud (ikut kontur tanah)
local CHAIKIN_ITER     = 1      -- iterasi pelicin kurva (0=mati, 1=halus, 2=sangat halus)
local PREVIEW_BELOK    = 15     -- (preview live saat merekam)
local PREVIEW_MAX      = 12

-- 🔗 GABUNG
local GABUNG_MIN_JARAK = 5

--═══════════════ LAYANAN ═══════════════
if not game:IsLoaded() then game.Loaded:Wait() end

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[SiiilauHub] GAGAL: LocalPlayer belum ada.")
    return
end

-- ---- FILE SYSTEM (hardened) ----
local genv = {}
pcall(function() genv = getgenv() or {} end)
if type(genv) ~= "table" then genv = {} end

local function ambilFungsi(nama)
    local ok, v = pcall(function() return _G[nama] end)
    if ok and type(v) == "function" then return v end
    v = genv[nama]
    if type(v) == "function" then return v end
    local ok2, f2 = pcall(function() return getfenv()[nama] end)
    if ok2 and type(f2) == "function" then return f2 end
    local ok3, s = pcall(function() return syn end)
    if ok3 and type(s) == "table" and type(s[nama]) == "function" then return s[nama] end
    return nil
end

local wf   = ambilFungsi("writefile")
local rf   = ambilFungsi("readfile")
local isf  = ambilFungsi("isfile")
local lf   = ambilFungsi("listfiles")
local mf   = ambilFungsi("makefolder")
local delf = ambilFungsi("delfile")
local isfo = ambilFungsi("isfolder")

local FOLDER     = "SiiilauHub_Rute"
local DRAFT_PATH = FOLDER .. "/_draft.json"

local function pastikanFolder()
    if not wf then return end
    local ada = false
    if isfo then
        local ok, hasil = pcall(isfo, FOLDER)
        ada = (ok and hasil == true)
    end
    if not ada and mf then pcall(mf, FOLDER) end
end

local FS_OK = false
do
    if wf and rf then
        pastikanFolder()
        local pathTes = FOLDER .. "/_tes.txt"
        local okw = pcall(wf, pathTes, "ok")
        local okr, isi = pcall(rf, pathTes)
        if okw and okr and isi == "ok" then FS_OK = true end
        if delf then pcall(delf, pathTes) end
    end
end

local conns = {}
local function addConn(c) table.insert(conns, c) return c end

--═══════════════ SCREENGUI ═══════════════
local gui = Instance.new("ScreenGui")
gui.Name = "SiiilauHub"
gui.ResetOnSpawn = false
gui.DisplayOrder = 9999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.OnTopOfCoreBlur = true end)

local kandidatParent = {}
pcall(function() if gethui then table.insert(kandidatParent, gethui()) end end)
pcall(function() table.insert(kandidatParent, game:GetService("CoreGui")) end)
pcall(function() table.insert(kandidatParent, LocalPlayer:WaitForChild("PlayerGui")) end)

for _, t in ipairs(kandidatParent) do
    pcall(function()
        local lama = t:FindFirstChild("SiiilauHub")
        if lama then lama:Destroy() end
    end)
end

local terpasang = false
for _, t in ipairs(kandidatParent) do
    local ok = pcall(function() gui.Parent = t end)
    if ok and gui.Parent == t then terpasang = true break end
end
if not terpasang then
    warn("[SiiilauHub] GAGAL: tidak bisa memasang GUI.")
    return
end

--═══════════════ FONT ═══════════════
local FONT_OK = pcall(function()
    return Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Regular)
end)
local cacheFont = {}
local function fnt(k)
    if cacheFont[k] then return cacheFont[k] end
    local v
    if FONT_OK then
        local fam = {
            judul = "rbxasset://fonts/families/Bangers.json",
            bold  = "rbxasset://fonts/families/Montserrat.json",
            semi  = "rbxasset://fonts/families/Montserrat.json",
            med   = "rbxasset://fonts/families/Montserrat.json",
        }
        local wts = {
            judul = Enum.FontWeight.Regular,
            bold  = Enum.FontWeight.Bold,
            semi  = Enum.FontWeight.SemiBold,
            med   = Enum.FontWeight.Medium,
        }
        v = Font.new(fam[k], wts[k])
    else
        local legacy = {
            judul = Enum.Font.Bangers,
            bold  = Enum.Font.GothamBold,
            semi  = Enum.Font.GothamSemibold,
            med   = Enum.Font.GothamMedium,
        }
        v = legacy[k]
    end
    cacheFont[k] = v
    return v
end
local TEKS_CLASS = {TextLabel = true, TextButton = true, TextBox = true}

--═══════════════ TEMA ═══════════════
local C = {
    Hitam     = Color3.fromRGB(12, 10, 20),
    Hitam2    = Color3.fromRGB(22, 18, 38),
    Baris     = Color3.fromRGB(28, 24, 48),
    BarisHov  = Color3.fromRGB(41, 34, 72),
    offBg     = Color3.fromRGB(42, 24, 68),
    Ungu      = Color3.fromRGB(124, 58, 237),
    Ungu2     = Color3.fromRGB(167, 139, 250),
    UnguMuda  = Color3.fromRGB(237, 233, 254),
    UnguD     = Color3.fromRGB(88, 30, 150),
    Biru      = Color3.fromRGB(37, 99, 235),
    Biru2     = Color3.fromRGB(59, 130, 246),
    Putih     = Color3.fromRGB(255, 255, 255),
    Merah     = Color3.fromRGB(239, 68, 68),
    Hijau     = Color3.fromRGB(74, 222, 128),
    Cyan      = Color3.fromRGB(34, 211, 238),
    Abuk      = Color3.fromRGB(160, 155, 185),
    AbuTeks   = Color3.fromRGB(130, 125, 155),
}

--═══════════════ HELPER ═══════════════
local function new(class, props, parent)
    local inst = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k == "FontFace" and TEKS_CLASS[class] and not FONT_OK then
                inst.Font = v
            else
                inst[k] = v
            end
        end
    end
    inst.Parent = parent
    return inst
end
local function fmt(v) return string.format("%.2f", v) end

local function brightnessFromTime(t)
    local d = math.clamp(math.sin((t - 6) / 12 * math.pi), 0, 1)
    return 0.5 + d * 2.5
end
local function formatClock(t)
    t = t % 24
    local h = math.floor(t)
    local m = math.floor((t - h) * 60 + 0.5)
    if m == 60 then h, m = h + 1, 0 end
    if h == 24 then h = 0 end
    return string.format("%02d:%02d", h, m)
end

--═══════════════ GUI UTAMA ═══════════════
local main = new("Frame", {
    Size = UDim2.fromOffset(480, 620),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, BorderSizePixel = 0, Active = true,
    Visible = false,
}, gui)
local panelScale = new("UIScale", {Scale = UKURAN_GUI}, main)

local outer = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
    ClipsDescendants = true,
}, main)
new("UICorner", {CornerRadius = UDim.new(0, 18)}, outer)
new("UIStroke", {Color = C.Ungu, Thickness = 3}, outer)

local panel = new("Frame", {
    Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5),
    BackgroundColor3 = C.Hitam2, BorderSizePixel = 0,
    ClipsDescendants = true,
}, outer)
new("UICorner", {CornerRadius = UDim.new(0, 13)}, panel)
new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.55}, panel)

local title = new("Frame", {
    Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.Hitam,
    BorderSizePixel = 0, Active = true, ClipsDescendants = true,
}, panel)
new("UICorner", {CornerRadius = UDim.new(0, 13)}, title)
new("Frame", {
    Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 36),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
}, panel)

new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0),
    Size = UDim2.new(1, -70, 1, 0), FontFace = fnt("judul"),
    Text = "⛓️ S I I L A U ⚡ 🏁", TextColor3 = C.Putih, TextSize = 24,
    TextXAlignment = Enum.TextXAlignment.Left,
}, title)

local minBtn = new("TextButton", {
    Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -40, 0.5, -14),
    BackgroundColor3 = C.Hitam2, BorderSizePixel = 0, AutoButtonColor = false,
    FontFace = fnt("bold"), Text = "–", TextColor3 = C.Putih, TextSize = 18,
}, title)
new("UICorner", {CornerRadius = UDim.new(0, 9)}, minBtn)
new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.3}, minBtn)

-- TAB BAR
local tabBar = new("Frame", {
    Position = UDim2.new(0, 10, 0, 50), Size = UDim2.new(1, -20, 0, 32),
    BackgroundTransparency = 1, BorderSizePixel = 0,
}, panel)
new("UIListLayout", {Padding = UDim.new(0, 6), FillDirection = Enum.FillDirection.Horizontal}, tabBar)

local function buatTabBtn(teks)
    local b = new("TextButton", {
        Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = C.Hitam2,
        BorderSizePixel = 0, AutoButtonColor = false,
        Text = teks, FontFace = fnt("bold"), TextSize = 15, TextColor3 = C.Abuk,
    }, tabBar)
    new("UICorner", {CornerRadius = UDim.new(0, 10)}, b)
    new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.6}, b)
    return b
end
local tabMenuBtn = buatTabBtn("⚙️ MENU")
local tabRuteBtn = buatTabBtn("🎥 RUTE")

local scrollMain = new("ScrollingFrame", {
    Position = UDim2.new(0, 10, 0, 86), Size = UDim2.new(1, -20, 1, -146),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 5, ScrollBarImageColor3 = C.Ungu2,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
new("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, scrollMain)

local scrollRute = new("ScrollingFrame", {
    Position = UDim2.new(0, 10, 0, 86), Size = UDim2.new(1, -20, 1, -146),
    BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
    ScrollBarThickness = 5, ScrollBarImageColor3 = C.Ungu2,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, panel)
new("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, scrollRute)

local bottom = new("Frame", {
    Position = UDim2.new(0, 0, 1, -56), Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
    ClipsDescendants = true,
}, panel)
new("UICorner", {CornerRadius = UDim.new(0, 13)}, bottom)
new("Frame", {
    Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -64),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
}, panel)

local resetBtn = new("TextButton", {
    Size = UDim2.new(0.5, -12, 1, -16), Position = UDim2.new(0, 8, 0, 8),
    BackgroundColor3 = C.Biru, BorderSizePixel = 0, AutoButtonColor = false,
    FontFace = fnt("bold"), TextSize = 18, Text = "🔄 Reset Script", TextColor3 = C.Putih,
}, bottom)
new("UICorner", {CornerRadius = UDim.new(0, 12)}, resetBtn)

local exitBtn = new("TextButton", {
    Size = UDim2.new(0.5, -12, 1, -16), Position = UDim2.new(0.5, 4, 0, 8),
    BackgroundColor3 = C.Hitam2, BorderSizePixel = 0, AutoButtonColor = false,
    FontFace = fnt("bold"), TextSize = 18, Text = "🗑️ Hapus / Keluar", TextColor3 = C.Merah,
}, bottom)
new("UICorner", {CornerRadius = UDim.new(0, 12)}, exitBtn)
new("UIStroke", {Color = C.Merah, Thickness = 2, Transparency = 0.6}, exitBtn)

--═══════════════ NOTIFIKASI ═══════════════
local notifHolder = new("Frame", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -10, 0, 10),
    Size = UDim2.fromOffset(240, 500),
    BackgroundTransparency = 1, ZIndex = 60,
}, gui)
new("UIListLayout", {
    Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Right,
}, notifHolder)

local notifSeq, silent = 0, false
local function notify(msg, state)
    if silent then return end
    notifSeq += 1
    local aksen = (state == true) and C.Biru2 or (state == false) and C.Merah or C.Ungu2
    local teks  = (state == nil) and msg or (msg .. " " .. (state and "ON" or "OFF"))
    local n = new("TextLabel", {
        Size = UDim2.fromOffset(190, 24), BackgroundColor3 = C.Hitam2,
        BackgroundTransparency = 0.25, BorderSizePixel = 0,
        Text = " " .. teks, TextColor3 = C.UnguMuda, TextSize = 11,
        FontFace = fnt("semi"), TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = notifSeq, ZIndex = 60,
    }, notifHolder)
    new("UICorner", {CornerRadius = UDim.new(0, 7)}, n)
    new("UIStroke", {Color = aksen, Thickness = 1, Transparency = 0.55}, n)
    task.delay(1.8, function() n:Destroy() end)
end

--═══════════════ PEMBANGUN UI ═══════════════
local order = 0
local function addSection(parent, text)
    order += 1
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
        LayoutOrder = order,
    }, parent)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -10, 0, 26), Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1, Text = "▎ " .. text,
        FontFace = fnt("judul"), TextSize = 21, TextColor3 = C.Ungu2,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)
    new("Frame", {
        Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 4, 1, -4),
        BackgroundColor3 = C.Ungu, BorderSizePixel = 0,
    }, holder)
    return lbl
end
local function addHint(parent, text)
    order += 1
    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = "💡 " .. text, FontFace = fnt("med"), TextSize = 14, TextColor3 = C.AbuTeks,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        LayoutOrder = order,
    }, parent)
end

local function addRow(parent, labelText, opts)
    opts = opts or {}
    order += 1
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.Baris,
        BorderSizePixel = 0, LayoutOrder = order,
        ClipsDescendants = true,
    }, parent)
    new("UICorner", {CornerRadius = UDim.new(0, 12)}, row)
    local rowStroke = new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.78}, row)

    new("Frame", {
        Size = UDim2.new(0, 3, 1, -18), Position = UDim2.new(0, 6, 0, 9),
        BackgroundColor3 = C.Ungu2, BorderSizePixel = 0,
    }, row)

    row.MouseEnter:Connect(function()
        row.BackgroundColor3 = C.BarisHov
        rowStroke.Transparency = 0.45
    end)
    row.MouseLeave:Connect(function()
        row.BackgroundColor3 = C.Baris
        rowStroke.Transparency = 0.78
    end)

    local ref = {row = row}
    local vshift = opts.toggle and 0 or 88
    local lw = -92
    if opts.value then lw = opts.toggle and -300 or -212 end
    ref.label = new("TextLabel", {
        Size = UDim2.new(1, lw, 1, 0), Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1, Text = labelText,
        FontFace = fnt("semi"), TextSize = 17, TextColor3 = C.UnguMuda,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    if opts.value then
        ref.minus = new("TextButton", {
            Size = UDim2.new(0, 28, 1, -16), Position = UDim2.new(1, -284 + vshift, 0, 8),
            BackgroundColor3 = C.UnguD, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "-", FontFace = fnt("bold"), TextSize = 22, TextColor3 = C.Putih,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 10)}, ref.minus)

        ref.val = new("TextLabel", {
            Size = UDim2.new(0, 80, 1, -16), Position = UDim2.new(1, -252 + vshift, 0, 8),
            BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
            Text = "--", FontFace = fnt("bold"), TextSize = 17, TextColor3 = C.UnguMuda,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 10)}, ref.val)
        new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.5}, ref.val)

        ref.plus = new("TextButton", {
            Size = UDim2.new(0, 28, 1, -16), Position = UDim2.new(1, -168 + vshift, 0, 8),
            BackgroundColor3 = C.UnguD, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "+", FontFace = fnt("bold"), TextSize = 22, TextColor3 = C.Putih,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 10)}, ref.plus)
    end

    if opts.toggle then
        ref.toggle = new("TextButton", {
            Size = UDim2.new(0, 68, 1, -16), Position = UDim2.new(1, -76, 0, 8),
            BackgroundColor3 = C.offBg, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "OFF", FontFace = fnt("bold"), TextSize = 17, TextColor3 = C.Abuk,
        }, row)
        new("UICorner", {CornerRadius = UDim.new(0, 10)}, ref.toggle)
        new("UIStroke", {Color = C.Ungu, Thickness = 1.5, Transparency = 0.6}, ref.toggle)
    end
    return ref
end

local function addBtnRow(parent, text)
    order += 1
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.Baris,
        BorderSizePixel = 0, LayoutOrder = order, AutoButtonColor = false,
        Text = text, FontFace = fnt("semi"), TextSize = 16, TextColor3 = C.UnguMuda,
    }, parent)
    new("UICorner", {CornerRadius = UDim.new(0, 12)}, btn)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = C.BarisHov end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.Baris end)
    return btn
end

local function styleToggle(btn, on)
    btn.Text = on and "ON" or "OFF"
    btn.BackgroundColor3 = on and C.Biru or C.offBg
    btn.TextColor3 = on and C.Putih or C.Abuk
    local st = btn:FindFirstChildOfClass("UIStroke")
    if st then
        st.Color = on and C.Biru2 or C.Ungu
        st.Transparency = on and 0.1 or 0.6
    end
end

--═══════════════ ISI TAB MENU ═══════════════
addSection(scrollMain, "MOVEMENT")
local rSpeed = addRow(scrollMain, "🏃 Speed & Swim [Q]", {value = true, toggle = true})
local rJump  = addRow(scrollMain, "🦘 Jump Power",       {value = true, toggle = true})

addSection(scrollMain, "VISUAL")
local rHideP = addRow(scrollMain, "🙈 Hide Pemain + Kendaraan [R]", {toggle = true})
local rHideF = addRow(scrollMain, "✨ Hide All Effects",             {toggle = true})
local rLowG  = addRow(scrollMain, "🌫️ Low Graphic + No Fog",        {toggle = true})
addHint(scrollMain, "Mobil lawan menempel ≤ " .. RADIUS_SENTUH .. "m → hilang, menjauh → muncul")

addSection(scrollMain, "ENVIRONMENT")
local rClock = addRow(scrollMain, "🕒 Auto Brightness [T]", {value = true, toggle = true})

--═══════════════ ISI TAB RUTE ═══════════════
addSection(scrollRute, "🎥 REKAM DIRI")
local rRekam  = addRow(scrollRute, "🔴 Rekam Rute [K]", {value = true, toggle = true})
local rVisAll = addRow(scrollRute, "👁️ Tampil Semua Garis", {toggle = true})
addHint(scrollRute, "Rekam ultra-halus (0.01s). Belokan kecil tercatat, garis smooth.")

addSection(scrollRute, "🎯 REKAM PEMAIN LAIN")
order += 1
local rowTarget = new("Frame", {
    Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.Baris,
    BorderSizePixel = 0, LayoutOrder = order, ClipsDescendants = true,
}, scrollRute)
new("UICorner", {CornerRadius = UDim.new(0, 12)}, rowTarget)
new("Frame", {
    Size = UDim2.new(0, 3, 1, -18), Position = UDim2.new(0, 6, 0, 9),
    BackgroundColor3 = C.Ungu2, BorderSizePixel = 0,
}, rowTarget)

new("TextLabel", {
    Size = UDim2.new(0, 90, 1, 0), Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1, Text = "🎯 Target:",
    FontFace = fnt("semi"), TextSize = 16, TextColor3 = C.UnguMuda,
    TextXAlignment = Enum.TextXAlignment.Left,
}, rowTarget)

local prevBtn = new("TextButton", {
    Size = UDim2.fromOffset(30, 32), Position = UDim2.new(1, -216, 0, 7),
    BackgroundColor3 = C.UnguD, BorderSizePixel = 0, AutoButtonColor = false,
    Text = "◀", FontFace = fnt("bold"), TextSize = 14, TextColor3 = C.Putih,
}, rowTarget)
new("UICorner", {CornerRadius = UDim.new(0, 9)}, prevBtn)

local namaTargetLbl = new("TextLabel", {
    Size = UDim2.new(0, 140, 1, -14), Position = UDim2.new(1, -182, 0, 7),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
    Text = "— pilih —", FontFace = fnt("bold"), TextSize = 14, TextColor3 = C.UnguMuda,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, rowTarget)
new("UICorner", {CornerRadius = UDim.new(0, 9)}, namaTargetLbl)
new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.5}, namaTargetLbl)

local nextBtn = new("TextButton", {
    Size = UDim2.fromOffset(30, 32), Position = UDim2.new(1, -38, 0, 7),
    BackgroundColor3 = C.UnguD, BorderSizePixel = 0, AutoButtonColor = false,
    Text = "▶", FontFace = fnt("bold"), TextSize = 14, TextColor3 = C.Putih,
}, rowTarget)
new("UICorner", {CornerRadius = UDim.new(0, 9)}, nextBtn)

local rRekamP = addRow(scrollRute, "🔴 Rekam Player [L]", {value = true, toggle = true})
local rSpec   = addRow(scrollRute, "📷 Spectate Kamera",   {toggle = true})
addHint(scrollRute, "Pilih ◀▶ → dia nyetir → stop → isi nama → Simpan")

addSection(scrollRute, "🔗 GABUNG FILE")
order += 1
local rowGabung = new("Frame", {
    Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = C.Baris,
    BorderSizePixel = 0, LayoutOrder = order, ClipsDescendants = true,
}, scrollRute)
new("UICorner", {CornerRadius = UDim.new(0, 12)}, rowGabung)
local namaBox = new("TextBox", {
    Size = UDim2.new(1, -116, 1, -14), Position = UDim2.new(0, 8, 0, 7),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
    Text = "Gabungan", PlaceholderText = "Nama file gabungan…",
    PlaceholderColor3 = C.Abuk, ClearTextOnFocus = false,
    FontFace = fnt("semi"), TextSize = 15, TextColor3 = C.UnguMuda,
    TextXAlignment = Enum.TextXAlignment.Left,
}, rowGabung)
do
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = namaBox
end
new("UICorner", {CornerRadius = UDim.new(0, 10)}, namaBox)
new("UIStroke", {Color = C.Ungu, Thickness = 1, Transparency = 0.5}, namaBox)
local gabungBtn = new("TextButton", {
    Size = UDim2.new(0, 100, 1, -14), Position = UDim2.new(1, -108, 0, 7),
    BackgroundColor3 = C.Biru, BorderSizePixel = 0, AutoButtonColor = false,
    Text = "🔗 Gabung", FontFace = fnt("bold"), TextSize = 14, TextColor3 = C.Putih,
}, rowGabung)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, gabungBtn)

local tpPilihBtn = addBtnRow(scrollRute, "📌 TP ke Akhir File Terpilih")

addSection(scrollRute, "📂 FILE RUTE")
local secFileLabel = addSection(scrollRute, "(0)")
addHint(scrollRute, "Urutan klik = urutan sambung. Tabrakan→titik temu, gap→jembatan otomatis")

--═══════════════ STATE ═══════════════
local S = {
    speedOn = false, speedValue = DEFAULT_SPEED,
    jumpOn = false,  jumpValue = DEFAULT_JUMP,
    hidePlayersOn = false, hideFxOn = false, lowGfxOn = false,
    clockOn = false,
    clockValue = Lighting.ClockTime,
    rekamOn = false, rekamPOn = false, specOn = false, visAll = false,
}

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

rSpeed.val.Text = fmt(S.speedValue)
rJump.val.Text  = fmt(S.jumpValue)
rClock.val.Text = formatClock(S.clockValue)
rRekam.val.Text  = "0 pt"
rRekamP.val.Text = "0 pt"

local function segarkanToggle()
    styleToggle(rSpeed.toggle, S.speedOn)
    styleToggle(rJump.toggle, S.jumpOn)
    styleToggle(rHideP.toggle, S.hidePlayersOn)
    styleToggle(rHideF.toggle, S.hideFxOn)
    styleToggle(rLowG.toggle, S.lowGfxOn)
    styleToggle(rClock.toggle, S.clockOn)
    styleToggle(rRekam.toggle, S.rekamOn)
    styleToggle(rRekamP.toggle, S.rekamPOn)
    styleToggle(rSpec.toggle, S.specOn)
    styleToggle(rVisAll.toggle, S.visAll)
end

--═══════════════ MOVEMENT ═══════════════
local savedHum = {}
local FALLBACK_WS  = 16
local lastWsNormal = 16

local function captureHum(h)
    if savedHum[h] then return end
    local ws0 = h.WalkSpeed
    if ws0 == nil or ws0 < 1 then
        ws0 = (lastWsNormal >= 1) and lastWsNormal or FALLBACK_WS
    elseif not S.speedOn then
        lastWsNormal = ws0
    end
    local jp0 = h.JumpPower
    if jp0 == nil or jp0 < 1 then jp0 = 50 end
    local rec = {ws = ws0, ujp = h.UseJumpPower, jp = jp0, ss = nil, jh = nil}
    pcall(function() rec.ss = h.SwimSpeed end)
    pcall(function() rec.jh = h.JumpHeight end)
    savedHum[h] = rec
end

local function restoreHum(h)
    local rec = savedHum[h]
    if not rec then return end
    pcall(function() h.WalkSpeed    = rec.ws  end)
    pcall(function() h.UseJumpPower = rec.ujp end)
    pcall(function() h.JumpPower    = rec.jp  end)
    if rec.jh then pcall(function() h.JumpHeight = rec.jh end) end
    if rec.ss then pcall(function() h.SwimSpeed  = rec.ss end) end
    savedHum[h] = nil
    if h.WalkSpeed < 1 then
        pcall(function()
            h.WalkSpeed = (rec.ws and rec.ws >= 1) and rec.ws or FALLBACK_WS
        end)
    end
end

local jagaId = 0
local function jagaGerak(durasi)
    jagaId += 1
    local myId = jagaId
    task.spawn(function()
        local t0 = os.clock()
        while os.clock() - t0 < (durasi or 3) and myId == jagaId do
            if not gui.Parent then return end
            if S.speedOn then return end
            local h = getHum()
            if h and h.Health > 0 and not h.SeatPart and h.WalkSpeed < 1 then
                pcall(function()
                    h.WalkSpeed = (lastWsNormal >= 1) and lastWsNormal or FALLBACK_WS
                end)
            end
            task.wait(0.25)
        end
    end)
end

local function applyMovement()
    local h = getHum()
    if not h then return end
    if S.speedOn or S.jumpOn then captureHum(h) end
    if S.speedOn then
        h.WalkSpeed = S.speedValue
        pcall(function() h.SwimSpeed = S.speedValue end)
    end
    if S.jumpOn then
        pcall(function()
            h.UseJumpPower = true
            h.JumpPower = S.jumpValue
        end)
    end
end

local function setSpeed(on)
    S.speedOn = on
    if on then
        applyMovement()
    else
        local h = getHum()
        if h then restoreHum(h) end
        if S.jumpOn then applyMovement() end
        jagaGerak(3)
    end
    styleToggle(rSpeed.toggle, on)
    notify("Speed & Swim", on)
end

local function setJump(on)
    S.jumpOn = on
    if on then
        applyMovement()
    else
        local h = getHum()
        if h then restoreHum(h) end
        if S.speedOn then applyMovement() end
        jagaGerak(3)
    end
    styleToggle(rJump.toggle, on)
    notify("Jump Power", on)
end

--═══════════════ HIDE PEMAIN + KENDARAAN ═══════════════
local hideLoopId = 0
local vehHidden  = {}
local savedDecal = {}
local R2 = RADIUS_SENTUH * RADIUS_SENTUH

local function setCharHidden(char, target)
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = target
        end
    end
end

local function kendaraanDariSeat(seat)
    local m = seat:FindFirstAncestorOfClass("Model")
    if m then
        while m.Parent and m.Parent ~= workspace and m.Parent:IsA("Model") do
            m = m.Parent
        end
        return m
    end
    return seat
end

local function scanKendaraan(v, target)
    local daftar
    if v:IsA("Model") then
        daftar = v:GetDescendants()
    else
        local ok, con = pcall(function() return v:GetConnectedParts(true) end)
        daftar = (ok and con) or {v}
    end
    for _, d in ipairs(daftar) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = target
        elseif d:IsA("Decal") or d:IsA("Texture") then
            if target == 1 then
                if savedDecal[d] == nil then
                    savedDecal[d] = d.Transparency
                    d.Transparency = 1
                end
            else
                local asli = savedDecal[d]
                if asli ~= nil then
                    d.Transparency = asli
                    savedDecal[d] = nil
                end
            end
        end
    end
end

local function cekKendaraan()
    local hum = getHum()
    local mySeat = hum and hum.SeatPart
    local myRef  = mySeat or (hum and hum.RootPart)
    if not myRef then return end
    local mx, mz = myRef.Position.X, myRef.Position.Z

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local hum2 = char and char:FindFirstChildOfClass("Humanoid")
            local seat = hum2 and hum2.SeatPart

            if seat and mySeat and seat.AssemblyRootPart == mySeat.AssemblyRootPart then
                if vehHidden[plr] then
                    pcall(scanKendaraan, vehHidden[plr], 0)
                    vehHidden[plr] = nil
                end
            elseif seat then
                local p = seat.Position
                local dx, dz = p.X - mx, p.Z - mz
                local sentuh = dx*dx + dz*dz <= R2
                if sentuh and not vehHidden[plr] then
                    local v = kendaraanDariSeat(seat)
                    vehHidden[plr] = v
                    pcall(scanKendaraan, v, 1)
                elseif not sentuh and vehHidden[plr] then
                    pcall(scanKendaraan, vehHidden[plr], 0)
                    vehHidden[plr] = nil
                end
            elseif vehHidden[plr] then
                pcall(scanKendaraan, vehHidden[plr], 0)
                vehHidden[plr] = nil
            end

            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root and root.LocalTransparencyModifier ~= 1 then
                setCharHidden(char, 1)
            end
        end
    end
end

local function setHidePlayers(on)
    S.hidePlayersOn = on
    hideLoopId += 1
    local myId = hideLoopId

    if on then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                setCharHidden(plr.Character, 1)
            end
        end
        task.spawn(function()
            while S.hidePlayersOn and myId == hideLoopId and gui.Parent do
                pcall(cekKendaraan)
                task.wait(CEK_INTERVAL)
            end
        end)
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                setCharHidden(plr.Character, 0)
            end
        end
        for plr, v in pairs(vehHidden) do
            if v then pcall(scanKendaraan, v, 0) end
            vehHidden[plr] = nil
        end
        table.clear(savedDecal)
    end

    styleToggle(rHideP.toggle, on)
    notify("Hide Pemain + Kendaraan", on)
end

--═══════════════ HIDE ALL EFFECTS ═══════════════
local FX_CLASSES = {
    ParticleEmitter = "Enabled", Fire = "Enabled", Smoke = "Enabled",
    Sparkles = "Enabled", Beam = "Enabled", Trail = "Enabled",
    PointLight = "Enabled", SpotLight = "Enabled", SurfaceLight = "Enabled",
}
local savedFx, fxConn = {}, nil

local function disableFx(inst)
    local prop = FX_CLASSES[inst.ClassName]
    if prop and savedFx[inst] == nil then
        pcall(function()
            savedFx[inst] = {prop = prop, value = inst[prop]}
            inst[prop] = false
        end)
    end
end

local function setHideFx(on)
    S.hideFxOn = on
    if on then
        for _, d in ipairs(workspace:GetDescendants()) do disableFx(d) end
        fxConn = workspace.DescendantAdded:Connect(disableFx)
        addConn(fxConn)
    else
        if fxConn then fxConn:Disconnect() fxConn = nil end
        for inst, data in pairs(savedFx) do
            pcall(function() inst[data.prop] = data.value end)
        end
        savedFx = {}
    end
    styleToggle(rHideF.toggle, on)
    notify("Hide All Effects", on)
end

--═══════════════ LOW GRAPHIC ═══════════════
local savedGfx, gfxConn = {}, nil
local savedQuality, gfxApplied = nil, false

local function setLowGfx(on)
    S.lowGfxOn = on
    if on then
        gfxApplied = true
        savedQuality = nil
        pcall(function() savedQuality = settings().Rendering.QualityLevel end)
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        savedGfx.shadows = Lighting.GlobalShadows
        savedGfx.fogStart, savedGfx.fogEnd = Lighting.FogStart, Lighting.FogEnd
        Lighting.GlobalShadows = false
        Lighting.FogStart, Lighting.FogEnd = 9e9, 9e9
        pcall(function()
            savedGfx.deco = workspace.Terrain.Decoration
            workspace.Terrain.Decoration = false
            savedGfx.wave = workspace.Terrain.WaterWaveSize
            workspace.Terrain.WaterWaveSize = 0
            savedGfx.refl = workspace.Terrain.WaterReflectance
            workspace.Terrain.WaterReflectance = 0
        end)
        for _, d in ipairs(Lighting:GetDescendants()) do
            if d:IsA("PostEffect") then savedGfx[d] = d.Enabled; d.Enabled = false end
        end
        gfxConn = Lighting.ChildAdded:Connect(function(d)
            if S.lowGfxOn and d:IsA("PostEffect") then savedGfx[d] = d.Enabled; d.Enabled = false end
        end)
        addConn(gfxConn)
    elseif gfxApplied then
        pcall(function()
            if savedQuality ~= nil then
                settings().Rendering.QualityLevel = savedQuality
            else
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            end
        end)
        if savedGfx.shadows  ~= nil then Lighting.GlobalShadows = savedGfx.shadows end
        if savedGfx.fogStart ~= nil then Lighting.FogStart = savedGfx.fogStart end
        if savedGfx.fogEnd   ~= nil then Lighting.FogEnd = savedGfx.fogEnd end
        pcall(function()
            if savedGfx.deco ~= nil then workspace.Terrain.Decoration = savedGfx.deco end
            if savedGfx.wave ~= nil then workspace.Terrain.WaterWaveSize = savedGfx.wave end
            if savedGfx.refl ~= nil then workspace.Terrain.WaterReflectance = savedGfx.refl end
        end)
        for d, v in pairs(savedGfx) do
            if typeof(d) == "Instance" then pcall(function() d.Enabled = v end) end
        end
        savedGfx = {}
        if gfxConn then gfxConn:Disconnect() gfxConn = nil end
        gfxApplied = false
    end
    styleToggle(rLowG.toggle, on)
    notify("Low Graphic Mode", on)
end

--═══════════════ AUTO BRIGHTNESS ═══════════════
local clockSnap = nil

local function applyLockedClock()
    pcall(function() Lighting.Brightness = brightnessFromTime(S.clockValue) end)
    if LOCK_TIME then
        pcall(function() Lighting.ClockTime = S.clockValue end)
    end
end

local function setClock(on)
    if on then
        if not S.clockOn then
            clockSnap = {ct = Lighting.ClockTime, br = Lighting.Brightness}
        end
        S.clockOn = true
        applyLockedClock()
        task.spawn(function()
            while S.clockOn and gui.Parent do
                task.wait(1)
                if S.clockOn then applyLockedClock() end
            end
        end)
    else
        S.clockOn = false
        if clockSnap then
            pcall(function() Lighting.ClockTime = clockSnap.ct end)
            pcall(function() Lighting.Brightness = clockSnap.br end)
            clockSnap = nil
        end
    end
    styleToggle(rClock.toggle, S.clockOn)
    notify("Auto Brightness", S.clockOn)
end

local function bumpClock(d)
    S.clockValue = (S.clockValue + d) % 24
    if S.clockValue < 0 then S.clockValue += 24 end
    rClock.val.Text = formatClock(S.clockValue)
    if not S.clockOn then
        setClock(true)
    else
        applyLockedClock()
    end
end

--═══════════════ 🎥 RUTE: PENYIMPANAN ═══════════════
local daftarFile = {}
local pilihan    = {}

local function sanitize(n)
    n = tostring(n or "")
    n = n:gsub("[^%w%-_%. ]", "")
    n = n:gsub("%s+", "_")
    if n == "" then n = "rute" end
    return n
end

local function pathDari(nama)
    return FOLDER .. "/" .. sanitize(nama) .. ".json"
end

local function hitungPanjang(pts)
    local L = 0
    for i = 2, #pts do L += (pts[i] - pts[i-1]).Magnitude end
    return L
end

local function namaUnik(base)
    base = (base == "" and "Gabungan") or base
    local n, i = base, 1
    while true do
        local bentrok = false
        for _, f in ipairs(daftarFile) do
            if f.nama == n then bentrok = true break end
        end
        if not bentrok and not (FS_OK and isf and isf(pathDari(n))) then return n end
        i += 1
        n = base .. " (" .. i .. ")"
    end
end

local function titikKeArray(pts)
    local arr = {}
    for _, t in ipairs(pts) do
        table.insert(arr, {
            math.floor(t.X * 100 + 0.5) / 100,
            math.floor(t.Y * 100 + 0.5) / 100,
            math.floor(t.Z * 100 + 0.5) / 100,
        })
    end
    return arr
end

local function simpanFile(f)
    if not FS_OK then
        notify("⚠️ Executor tak dukung file — data hilang saat keluar", false)
        return
    end
    pastikanFolder()
    local data = {
        v = 1, nama = f.nama, tgl = f.tgl,
        panjang = math.floor(f.panjang * 10 + 0.5) / 10,
        gab = f.gabungan or nil,
        n = #f.titik,
        titik = titikKeArray(f.titik),
    }
    local ok = pcall(wf, f.path, HttpService:JSONEncode(data))
    if not ok then
        notify("⚠️ Gagal menulis file: " .. f.nama, false)
    end
end

local function simpanDraft(pts)
    if not FS_OK then return end
    pastikanFolder()
    local data = {nama = "_draft", titik = titikKeArray(pts)}
    pcall(wf, DRAFT_PATH, HttpService:JSONEncode(data))
end

local function hapusDraft()
    if FS_OK and delf and isf then
        local o, ada = pcall(isf, DRAFT_PATH)
        if o and ada then pcall(delf, DRAFT_PATH) end
    end
end

local function tambahFile(nama, titik, gabungan)
    local f = {
        nama = nama, titik = titik,
        panjang = hitungPanjang(titik),
        tgl = os.date("%d/%m %H:%M"),
        vis = false, gabungan = gabungan or false,
        path = pathDari(nama),
    }
    table.insert(daftarFile, f)
    simpanFile(f)
    return f
end

local function muatFileTersimpan()
    if not FS_OK then return 0 end
    local jumlah = 0

    local function muatSatu(path, namaFallback)
        local okr, isi = pcall(rf, path)
        if not (okr and type(isi) == "string") then return false end
        local okd, data = pcall(function() return HttpService:JSONDecode(isi) end)
        if not (okd and type(data) == "table" and type(data.titik) == "table") then return false end
        local titik = {}
        for _, t in ipairs(data.titik) do
            if type(t) == "table" and t[1] and t[2] and t[3] then
                table.insert(titik, Vector3.new(t[1], t[2], t[3]))
            end
        end
        if #titik < 2 then return false end
        local namaFile = path:match("[/\\]([^/\\]+)$") or namaFallback
        namaFile = namaFile:gsub("%.json$", "")
        tambahFile(data.nama or namaFile, titik, data.gab == true)
        return true
    end

    if isf then
        local ok, ada = pcall(isf, DRAFT_PATH)
        if ok and ada then
            if muatSatu(DRAFT_PATH, "Draft") then
                jumlah += 1
                notify("💾 Draft rekaman terselamatkan ✓", true)
            end
            if delf then pcall(delf, DRAFT_PATH) end
        end
    end

    if type(lf) == "function" then
        local ok, files = pcall(lf, FOLDER)
        if ok and type(files) == "table" then
            for _, path in ipairs(files) do
                if type(path) == "string" and string.sub(path, -5) == ".json" and path ~= DRAFT_PATH then
                    if isf then
                        local o, ada = pcall(isf, path)
                        if o and ada then
                            if muatSatu(path, "rute") then jumlah += 1 end
                        end
                    else
                        if muatSatu(path, "rute") then jumlah += 1 end
                    end
                end
            end
        end
    end
    return jumlah
end

--═══════════════ 🎥 RUTE: GARIS 3D ═══════════════
local rekamFolder = Instance.new("Folder")
rekamFolder.Name = "_SiiilauRekam"
rekamFolder.Parent = workspace

local rootFolderGaris = Instance.new("Folder")
rootFolderGaris.Name = "_SiiilauRuteFiles"
rootFolderGaris.Parent = workspace

local function buatSegmen(parent, a, b, warna, tebal)
    local jarak = (b - a).Magnitude
    if jarak < 0.15 then return end
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Material = Enum.Material.Neon
    p.Color = warna
    p.Transparency = LINE_TRANS
    p.Size = Vector3.new(tebal or LINE_TEBAL, tebal or LINE_TEBAL, jarak)
    p.CFrame = CFrame.lookAt((a + b) * 0.5, b)
    p.Parent = parent
end

local function buatMarker(parent, pos, warna, teks)
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Shape = Enum.PartType.Ball
    p.Material = Enum.Material.Neon
    p.Color = warna
    p.Transparency = 0.4
    p.Size = Vector3.new(2, 2, 2)
    p.CFrame = CFrame.new(pos)
    p.Parent = parent
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(150, 24)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 3000
    bb.Parent = p
    local t = Instance.new("TextLabel")
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.TextScaled = true
    t.TextColor3 = warna
    t.TextStrokeTransparency = 0.4
    t.Text = teks
    t.Parent = bb
end

local function proyeksiTanah(p, char)
    char = char or LocalPlayer.Character
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local f = {rekamFolder, rootFolderGaris}
    if char then table.insert(f, char) end
    local h = char and char:FindFirstChildOfClass("Humanoid")
    local seat = h and h.SeatPart
    if seat then
        local ok, v = pcall(kendaraanDariSeat, seat)
        if ok and v then table.insert(f, v) end
    end
    params.FilterDescendantsInstances = f
    local hit = workspace:Raycast(p + Vector3.new(0, 1, 0), Vector3.new(0, -14, 0), params)
    if hit then
        return Vector3.new(p.X, hit.Position.Y + LINE_TEBAL * 0.5 + 0.05, p.Z)
    end
    return p - Vector3.new(0, 2.5, 0)
end

-- ---- ✏️ PIPELINE GARIS HALUS ----
-- 1) Simplifikasi: jalan lurus diringkas, SEMUA belokan (≥ SMPL_ANGLE°) dijaga
local function sederhanakanJalur(pts)
    if #pts <= 2 then return pts end
    local hasil = {pts[1]}
    for i = 2, #pts - 1 do
        local prev = hasil[#hasil]
        local cur  = pts[i]
        local nxt  = pts[i + 1]
        local d1 = cur - prev
        local d2 = nxt - cur
        if d1.Magnitude > 0.01 and d2.Magnitude > 0.01 then
            local dot = math.clamp(d1.Unit:Dot(d2.Unit), -1, 1)
            local sudut = math.deg(math.acos(dot))
            if sudut >= SMPL_ANGLE or (nxt - prev).Magnitude >= SMPL_MAX_SEG then
                table.insert(hasil, cur)
            end
        end
    end
    table.insert(hasil, pts[#pts])
    return hasil
end

-- 2) Chaikin: sudut patah dibulatkan jadi kelokan mulus
local function chaikin(pts)
    if #pts < 3 then return pts end
    local out = {pts[1]}
    for i = 1, #pts - 1 do
        local a, b = pts[i], pts[i + 1]
        table.insert(out, a:Lerp(b, 0.25))
        table.insert(out, a:Lerp(b, 0.75))
    end
    table.insert(out, pts[#pts])
    return out
end

-- 3) Render: buat part tipis antar titik hasil pelician
local function renderJalurHalus(parent, pts, warna)
    if #pts < 2 then return end
    local ringkas = sederhanakanJalur(pts)
    local halus = ringkas
    for _ = 1, CHAIKIN_ITER do
        halus = chaikin(halus)
    end
    for i = 2, #halus do
        buatSegmen(parent, halus[i-1], halus[i], warna)
    end
end

local function setVisFile(f, vis)
    f.vis = vis
    if vis then
        if not f.folder or not f.folder.Parent then
            f.folder = Instance.new("Folder")
            f.folder.Name = "_r_" .. sanitize(f.nama)
            f.folder.Parent = rootFolderGaris
            renderJalurHalus(f.folder, f.titik, f.gabungan and C.Cyan or C.Ungu2)
            buatMarker(f.folder, f.titik[1], C.Biru2, "START")
            buatMarker(f.folder, f.titik[#f.titik], f.gabungan and C.Cyan or C.Hijau, "END ▸ " .. f.nama)
        end
    else
        if f.folder then f.folder:Destroy() f.folder = nil end
    end
end

--═══════════════ 🎥 RUTE: DAFTAR FILE (UI) ═══════════════
local renderDaftar -- forward

local function togglePilih(f)
    local pos = table.find(pilihan, f)
    if pos then
        table.remove(pilihan, pos)
    else
        table.insert(pilihan, f)
    end
    renderDaftar()
end

renderDaftar = function()
    for _, c in ipairs(scrollRute:GetChildren()) do
        if c:GetAttribute("itemFile") then c:Destroy() end
    end
    secFileLabel.Text = "▎ 📂 FILE (" .. #daftarFile .. ") • dipilih: " .. #pilihan

    if #daftarFile == 0 then
        order += 1
        local kosong = new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1,
            Text = "belum ada file — rekam dulu 🔴",
            FontFace = fnt("med"), TextSize = 14, TextColor3 = C.AbuTeks,
            LayoutOrder = order,
        }, scrollRute)
        kosong:SetAttribute("itemFile", true)
        return
    end

    for _, f in ipairs(daftarFile) do
        order += 1
        local posPilih = table.find(pilihan, f)
        local item = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.Baris,
            BorderSizePixel = 0, AutoButtonColor = false,
            LayoutOrder = order, Text = "",
        }, scrollRute)
        item:SetAttribute("itemFile", true)
        new("UICorner", {CornerRadius = UDim.new(0, 12)}, item)
        new("UIStroke", {
            Color = posPilih and C.Hijau or C.Ungu,
            Thickness = posPilih and 2 or 1,
            Transparency = posPilih and 0.1 or 0.78,
        }, item)

        item.MouseEnter:Connect(function() item.BackgroundColor3 = C.BarisHov end)
        item.MouseLeave:Connect(function() item.BackgroundColor3 = C.Baris end)

        local labelNama = posPilih and ("✅" .. posPilih .. " " .. f.nama) or f.nama
        if f.gabungan then labelNama = "🔗 " .. labelNama end

        new("TextLabel", {
            Size = UDim2.new(1, -130, 0, 22), Position = UDim2.new(0, 12, 0, 4),
            BackgroundTransparency = 1, Text = labelNama,
            FontFace = fnt("semi"), TextSize = 15, TextColor3 = posPilih and C.Hijau or C.UnguMuda,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, item)
        new("TextLabel", {
            Size = UDim2.new(1, -130, 0, 16), Position = UDim2.new(0, 12, 0, 26),
            BackgroundTransparency = 1,
            Text = #f.titik .. " titik • " .. math.floor(f.panjang + 0.5) .. "m • " .. f.tgl,
            FontFace = fnt("med"), TextSize = 11, TextColor3 = C.AbuTeks,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, item)

        local visBtn = new("TextButton", {
            Size = UDim2.fromOffset(30, 32), Position = UDim2.new(1, -112, 0, 8),
            BackgroundColor3 = f.vis and C.Biru or C.UnguD,
            BorderSizePixel = 0, AutoButtonColor = false,
            Text = "👁", TextSize = 16, TextColor3 = C.Putih, FontFace = fnt("bold"),
        }, item)
        new("UICorner", {CornerRadius = UDim.new(0, 9)}, visBtn)

        local tpBtn = new("TextButton", {
            Size = UDim2.fromOffset(30, 32), Position = UDim2.new(1, -76, 0, 8),
            BackgroundColor3 = C.UnguD, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "📌", TextSize = 16, TextColor3 = C.Putih, FontFace = fnt("bold"),
        }, item)
        new("UICorner", {CornerRadius = UDim.new(0, 9)}, tpBtn)

        local delBtn = new("TextButton", {
            Size = UDim2.fromOffset(30, 32), Position = UDim2.new(1, -40, 0, 8),
            BackgroundColor3 = C.UnguD, BorderSizePixel = 0, AutoButtonColor = false,
            Text = "🗑", TextSize = 16, TextColor3 = C.Merah, FontFace = fnt("bold"),
        }, item)
        new("UICorner", {CornerRadius = UDim.new(0, 9)}, delBtn)

        item.MouseButton1Click:Connect(function() togglePilih(f) end)
        visBtn.MouseButton1Click:Connect(function()
            setVisFile(f, not f.vis)
            renderDaftar()
        end)
        tpBtn.MouseButton1Click:Connect(function()
            local root = getRoot()
            if not root then notify("Karakter belum ada / respawn dulu", false) return end
            local h = getHum()
            if h then pcall(function() h.Sit = false end) end
            local p = f.titik[#f.titik]
            root.CFrame = CFrame.new(p + Vector3.new(0, 6, 0))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            notify("📌 TP ke END ▸ " .. f.nama, true)
        end)
        delBtn.MouseButton1Click:Connect(function()
            local pos = table.find(pilihan, f)
            if pos then table.remove(pilihan, pos) end
            if f.folder then f.folder:Destroy() f.folder = nil end
            if FS_OK and delf and isf then
                local o, ada = pcall(isf, f.path)
                if o and ada then pcall(delf, f.path) end
            end
            for i, x in ipairs(daftarFile) do
                if x == f then table.remove(daftarFile, i) break end
            end
            renderDaftar()
            notify("🗑 Hapus: " .. f.nama, false)
        end)
    end
end

--═══════════════ 💾 DIALOG ISI NAMA ═══════════════
local modalBg = new("TextButton", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.Hitam, BackgroundTransparency = 0.45,
    BorderSizePixel = 0, Text = "", AutoButtonColor = false,
    Visible = false, ZIndex = 100,
}, gui)

local kartu = new("Frame", {
    Size = UDim2.fromOffset(360, 210),
    Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = C.Hitam2, BorderSizePixel = 0, Active = true, ZIndex = 101,
}, modalBg)
new("UICorner", {CornerRadius = UDim.new(0, 16)}, kartu)
new("UIStroke", {Color = C.Ungu, Thickness = 2}, kartu)

new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 34), Position = UDim2.new(0, 10, 0, 10),
    BackgroundTransparency = 1, Text = "💾 SIMPAN REKAMAN",
    FontFace = fnt("judul"), TextSize = 22, TextColor3 = C.Ungu2, ZIndex = 101,
}, kartu)

new("TextLabel", {
    Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0, 10, 0, 46),
    BackgroundTransparency = 1, Text = "Tulis nama file biar gampang dicari saat gabung:",
    FontFace = fnt("med"), TextSize = 13, TextColor3 = C.AbuTeks, ZIndex = 101,
}, kartu)

local namaSaveBox = new("TextBox", {
    Size = UDim2.new(1, -40, 0, 44), Position = UDim2.new(0, 20, 0, 72),
    BackgroundColor3 = C.Hitam, BorderSizePixel = 0,
    Text = "", PlaceholderText = "contoh: Tikungan Jembatan…",
    PlaceholderColor3 = C.Abuk, ClearTextOnFocus = false,
    FontFace = fnt("semi"), TextSize = 16, TextColor3 = C.UnguMuda,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101,
}, kartu)
do
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.Parent = namaSaveBox
end
new("UICorner", {CornerRadius = UDim.new(0, 10)}, namaSaveBox)
new("UIStroke", {Color = C.Ungu, Thickness = 1.5}, namaSaveBox)

local buangBtn = new("TextButton", {
    Size = UDim2.new(0, 150, 0, 42), Position = UDim2.new(0, 20, 1, -56),
    BackgroundColor3 = C.offBg, BorderSizePixel = 0, AutoButtonColor = false,
    Text = "🗑️ Buang", FontFace = fnt("bold"), TextSize = 15, TextColor3 = C.Merah, ZIndex = 101,
}, kartu)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, buangBtn)
new("UIStroke", {Color = C.Merah, Thickness = 1.5, Transparency = 0.5}, buangBtn)

local simpanBtn = new("TextButton", {
    Size = UDim2.new(0, 150, 0, 42), Position = UDim2.new(1, -170, 1, -56),
    BackgroundColor3 = C.Biru, BorderSizePixel = 0, AutoButtonColor = false,
    Text = "✅ Simpan", FontFace = fnt("bold"), TextSize = 15, TextColor3 = C.Putih, ZIndex = 101,
}, kartu)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, simpanBtn)

local pendingSave = nil

local function tutupDialog()
    modalBg.Visible = false
    pendingSave = nil
end

local function lakukanSimpan()
    if not pendingSave then tutupDialog() return end
    local nama = namaSaveBox.Text
    nama = nama:gsub("^%s+", ""):gsub("%s+$", "")
    if nama == "" then nama = pendingSave.default end
    nama = namaUnik(nama)
    local f = tambahFile(nama, pendingSave.titik, false)
    rekamFolder:ClearAllChildren()
    setVisFile(f, true)
    renderDaftar()
    hapusDraft()
    notify("✅ Tersimpan: " .. nama .. " (" .. #f.titik .. " titik • " .. math.floor(f.panjang + 0.5) .. "m)", true)
    tutupDialog()
end

local function lakukanBuang()
    if pendingSave then
        hapusDraft()
        rekamFolder:ClearAllChildren()
        notify("🗑️ Rekaman dibuang", false)
    end
    tutupDialog()
end

local function bukaDialogSimpan(defaultNama, titik)
    pendingSave = {default = defaultNama, titik = titik}
    namaSaveBox.Text = defaultNama
    modalBg.Visible = true
    notify("⏹ Stop! Isi nama lalu Simpan 💾", true)
end

simpanBtn.MouseButton1Click:Connect(lakukanSimpan)
buangBtn.MouseButton1Click:Connect(lakukanBuang)
namaSaveBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then lakukanSimpan() end
end)

--═══════════════ 🔗 GABUNG CERDAS ═══════════════
local GABUNG_MATCH  = 8
local GABUNG_TIGHT  = 4
local GABUNG_DEDUPE = 2.5

local function gabungDuaJalur(A, B)
    if #A == 0 then
        local hasil = {}
        for i = 1, #B do hasil[i] = B[i] end
        return hasil, false
    end

    local jA, dMin
    for i = 1, #A do
        local d = (A[i] - B[1]).Magnitude
        if not dMin or d < dMin then dMin, jA = d, i end
    end

    local hasil = {}
    for i = 1, #A do hasil[i] = A[i] end

    if dMin and dMin <= GABUNG_MATCH then
        local k = 1
        while (jA + k - 1) <= #A and k <= #B
          and (A[jA + k - 1] - B[k]).Magnitude <= GABUNG_TIGHT do
            k += 1
        end
        local last = hasil[#hasil]
        for i = k, #B do
            if (B[i] - last).Magnitude >= GABUNG_DEDUPE then
                table.insert(hasil, B[i])
                last = B[i]
            end
        end
        return hasil, true
    else
        local awal, akhir = A[#A], B[1]
        local jarak = (akhir - awal).Magnitude
        local langkah = math.max(2, math.floor(jarak / GABUNG_MIN_JARAK))
        for s = 1, langkah - 1 do
            table.insert(hasil, awal:Lerp(akhir, s / langkah))
        end
        local last = hasil[#hasil]
        for i = 1, #B do
            if (B[i] - last).Magnitude >= GABUNG_DEDUPE then
                table.insert(hasil, B[i])
                last = B[i]
            end
        end
        return hasil, false
    end
end

--═══════════════ 🎥 RUTE: REKAM / TP / GABUNG ═══════════════
local rekamId = 0
local rekamPts, lastPt = {}, nil
local rekamMati = false

local setRekamP -- forward

-- state preview live (incremental, hemat part saat merekam)
local pvLast, pvDir = nil, nil

local function previewLive(parent, gp, warna)
    if not pvLast then
        pvLast, pvDir = gp, nil
        return
    end
    local d = gp - pvLast
    local mag = d.Magnitude
    if mag < 0.2 then return end
    local dirBaru = d.Unit
    local belok = 0
    if pvDir then
        belok = math.deg(math.acos(math.clamp(pvDir:Dot(dirBaru), -1, 1)))
    end
    if (pvDir == nil) or belok >= PREVIEW_BELOK or mag >= PREVIEW_MAX then
        buatSegmen(parent, pvLast, gp, warna)
        pvLast, pvDir = gp, dirBaru
    end
end

-- rebuild preview pakai pipeline halus (dipanggil saat stop, sebelum dialog)
local function rebuildPreviewHalus(pts)
    rekamFolder:ClearAllChildren()
    renderJalurHalus(rekamFolder, pts, C.Merah)
    buatMarker(rekamFolder, pts[1], C.Biru2, "START")
    buatMarker(rekamFolder, pts[#pts], C.Hijau, "END (preview)")
end

local function setRekam(on)
    if on and modalBg.Visible then
        notify("Selesaikan simpan rekaman dulu 💾", false)
        return
    end
    if on and S.rekamPOn then setRekamP(false) end
    S.rekamOn = on
    rekamId += 1
    local myId = rekamId

    if on then
        rekamFolder:ClearAllChildren()
        rekamPts, lastPt = {}, nil
        rekamMati = false
        pvLast, pvDir = nil, nil
        rRekam.val.Text = "0 pt"
        notify("🔴 Merekam ultra-halus… nyetir jalurmu!", true)
        task.spawn(function()
            while S.rekamOn and myId == rekamId and gui.Parent do
                local h = getHum()
                if h and h.Health <= 0 then
                    rekamMati = true
                    task.defer(function()
                        if S.rekamOn and myId == rekamId then setRekam(false) end
                    end)
                    break
                end
                local root = getRoot()
                if root then
                    local p = root.Position
                    if not lastPt then
                        lastPt = p
                        local gp = proyeksiTanah(p)
                        table.insert(rekamPts, gp)
                        previewLive(rekamFolder, gp, C.Merah)
                        buatMarker(rekamFolder, gp, C.Merah, "AWAL REKAM")
                    else
                        local jarak = (p - lastPt).Magnitude
                        if jarak >= REC_MIN_JARAK then
                            local gp = proyeksiTanah(p)
                            table.insert(rekamPts, gp)
                            lastPt = p
                            previewLive(rekamFolder, gp, C.Merah)
                            rRekam.val.Text = #rekamPts .. " pt"
                            if #rekamPts % DRAFT_TIAP == 0 then simpanDraft(rekamPts) end
                            if #rekamPts >= MAX_TITIK then
                                task.defer(function()
                                    if S.rekamOn and myId == rekamId then setRekam(false) end
                                end)
                                break
                            end
                        end
                    end
                end
                task.wait(REC_INTERVAL)
            end
        end)
    else
        if #rekamPts >= 2 then
            local titik = {}
            for _, t in ipairs(rekamPts) do table.insert(titik, t) end
            rebuildPreviewHalus(titik) -- garis final smooth terlihat saat menamai
            local saran = namaUnik("Mentah")
            bukaDialogSimpan(saran, titik)
            if rekamMati then
                notify("💀 Mati — garis tetap ada, isi nama → Simpan", false)
            end
        else
            notify("Rekam dibatalkan (titik terlalu sedikit)", false)
            hapusDraft()
            rekamFolder:ClearAllChildren()
            rekamPts, lastPt = {}, nil
            pvLast, pvDir = nil, nil
        end
    end

    styleToggle(rRekam.toggle, on)
end

-- ---- TARGET PICKER ----
local targetIdx = 1
local targetPlr = nil

local function daftarPemainLain()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(list, plr) end
    end
    return list
end

local function updateTargetLabel()
    local list = daftarPemainLain()
    if #list == 0 then
        targetPlr = nil
        namaTargetLbl.Text = "tidak ada"
        return
    end
    if targetIdx < 1 or targetIdx > #list then targetIdx = 1 end
    targetPlr = list[targetIdx]
    namaTargetLbl.Text = targetPlr.DisplayName
end

local function applySpectate()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if S.specOn and targetPlr and targetPlr.Character then
        local hum2 = targetPlr.Character:FindFirstChildOfClass("Humanoid")
        if hum2 and cam.CameraSubject ~= hum2 then
            pcall(function() cam.CameraSubject = hum2 end)
        end
    end
end

local specId = 0
local function setSpec(on)
    S.specOn = on
    specId += 1
    local myId = specId
    if on then
        applySpectate()
        notify("📷 Spectate: " .. (targetPlr and targetPlr.DisplayName or "?"), true)
        task.spawn(function()
            while S.specOn and myId == specId and gui.Parent do
                applySpectate()
                task.wait(0.5)
            end
        end)
    else
        local cam = workspace.CurrentCamera
        local h = getHum()
        if cam and h then pcall(function() cam.CameraSubject = h end) end
        notify("📷 Spectate", false)
    end
    styleToggle(rSpec.toggle, on)
end

-- ---- REKAM PEMAIN LAIN ----
local rekamPId = 0
local rekamPPts, lastPPt = {}, nil
local rekamPTarget, rekamPNama = nil, "?"
local pvPLast, pvPDir = nil, nil

local function getRootDari(plr)
    local c = plr and plr.Character
    if not c then return nil, nil end
    local hum2 = c:FindFirstChildOfClass("Humanoid")
    if hum2 and hum2.Health <= 0 then return nil, hum2 end
    local seat = hum2 and hum2.SeatPart
    if seat then return seat, hum2 end
    return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart, hum2
end

setRekamP = function(on)
    if on and modalBg.Visible then
        notify("Selesaikan simpan rekaman dulu 💾", false)
        return
    end
    if on then
        if S.rekamOn then setRekam(false) end
        if not targetPlr then
            notify("Pilih target dulu (◀ ▶)", false)
            return
        end
    end
    S.rekamPOn = on
    rekamPId += 1
    local myId = rekamPId

    if on then
        rekamFolder:ClearAllChildren()
        rekamPPts, lastPPt = {}, nil
        pvPLast, pvPDir = nil, nil
        rekamPTarget = targetPlr
        rekamPNama   = targetPlr.Name
        rRekamP.val.Text = "0 pt"
        notify("🔴 Rekam " .. targetPlr.DisplayName .. "…", true)
        task.spawn(function()
            while S.rekamPOn and myId == rekamPId and gui.Parent do
                if not rekamPTarget or not rekamPTarget.Parent then
                    task.defer(function()
                        if S.rekamPOn and myId == rekamPId then setRekamP(false) end
                    end)
                    break
                end
                local root, hum2 = getRootDari(rekamPTarget)
                if root and (not hum2 or hum2.Health > 0) then
                    local p = root.Position
                    if not lastPPt then
                        lastPPt = p
                        local gp = proyeksiTanah(p, rekamPTarget.Character)
                        table.insert(rekamPPts, gp)
                        previewLive(rekamFolder, gp, C.Merah)
                        buatMarker(rekamFolder, gp, C.Merah, "AWAL: " .. rekamPTarget.DisplayName)
                    else
                        local jarak = (p - lastPPt).Magnitude
                        if jarak >= REC_MIN_JARAK then
                            local gp = proyeksiTanah(p, rekamPTarget.Character)
                            if jarak < JARAK_LOMPAT then
                                table.insert(rekamPPts, gp)
                                previewLive(rekamFolder, gp, C.Merah)
                                rRekamP.val.Text = #rekamPPts .. " pt"
                            else
                                -- respawn/teleport: reset acuan preview
                                pvPLast, pvPDir = gp, nil
                            end
                            lastPPt = p
                            if #rekamPPts % DRAFT_TIAP == 0 and #rekamPPts > 0 then simpanDraft(rekamPPts) end
                            if #rekamPPts >= MAX_TITIK then
                                task.defer(function()
                                    if S.rekamPOn and myId == rekamPId then setRekamP(false) end
                                end)
                                break
                            end
                        end
                    end
                end
                task.wait(REC_INTERVAL)
            end
        end)
    else
        if #rekamPPts >= 2 then
            local titik = {}
            for _, t in ipairs(rekamPPts) do table.insert(titik, t) end
            rebuildPreviewHalus(titik)
            local saran = namaUnik("P-" .. rekamPNama)
            bukaDialogSimpan(saran, titik)
        else
            notify("Rekam player dibatalkan (titik kurang)", false)
            hapusDraft()
            rekamFolder:ClearAllChildren()
            rekamPPts, lastPPt = {}, nil
            pvPLast, pvPDir = nil, nil
        end
    end

    styleToggle(rRekamP.toggle, on)
end

local function tampilSemua(on)
    for _, f in ipairs(daftarFile) do
        setVisFile(f, on)
    end
    renderDaftar()
    notify("Semua garis", on)
end

local function gabungTerpilih()
    if #pilihan < 2 then
        notify("Pilih minimal 2 file (klik nama file-nya, urut!)", false)
        return
    end
    local nama = namaBox.Text
    nama = nama:gsub("^%s+", ""):gsub("%s+$", "")
    if nama == "" then nama = "Gabungan" end
    nama = namaUnik(nama)

    local titik = {}
    for _, t in ipairs(pilihan[1].titik) do table.insert(titik, t) end
    local nTemu, nJembatan = 0, 0
    for i = 2, #pilihan do
        local hasil, temu = gabungDuaJalur(titik, pilihan[i].titik)
        titik = hasil
        if temu then nTemu += 1 else nJembatan += 1 end
    end
    if #titik < 2 then
        notify("Gagal gabung: titik kurang", false)
        return
    end

    local f = tambahFile(nama, titik, true)
    setVisFile(f, true)
    table.clear(pilihan)
    renderDaftar()
    local detail = ""
    if nTemu > 0 then detail = detail .. " • temu:" .. nTemu end
    if nJembatan > 0 then detail = detail .. " • jembatan:" .. nJembatan end
    notify("🔗 " .. nama .. " (" .. #titik .. " titik • " .. math.floor(f.panjang + 0.5) .. "m" .. detail .. ")", true)
end

local function tpKeTerpilih()
    if #pilihan == 0 then
        notify("Pilih file dulu (klik nama file-nya)", false)
        return
    end
    local f = pilihan[1]
    local root = getRoot()
    if not root then notify("Karakter belum ada / respawn dulu", false) return end
    local h = getHum()
    if h then pcall(function() h.Sit = false end) end
    local p = f.titik[#f.titik]
    root.CFrame = CFrame.new(p + Vector3.new(0, 6, 0))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    notify("📌 TP ke END ▸ " .. f.nama, true)
end

--═══════════════ RESET & KELUAR ═══════════════
local function matikanSemua()
    pcall(function() if S.rekamOn  then setRekam(false)  end end)
    pcall(function() if S.rekamPOn then setRekamP(false) end end)
    pcall(function() if S.specOn   then setSpec(false)   end end)
    pcall(function() if S.hidePlayersOn then setHidePlayers(false) end end)
    pcall(function() if S.hideFxOn then setHideFx(false) end end)
    pcall(function() if S.lowGfxOn then setLowGfx(false) end end)
    pcall(function() if S.clockOn  then setClock(false)  end end)
    pcall(function() if S.speedOn  then setSpeed(false)  end end)
    pcall(function() if S.jumpOn   then setJump(false)   end end)
end

local function destroyAll()
    silent = true
    matikanSemua()
    silent = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    table.clear(conns)
    pcall(function() rekamFolder:Destroy() end)
    pcall(function() rootFolderGaris:Destroy() end)
    gui:Destroy()
end

local function resetSemua()
    silent = true
    matikanSemua()
    silent = false
    S.speedValue, S.jumpValue = DEFAULT_SPEED, DEFAULT_JUMP
    S.clockValue = Lighting.ClockTime
    rSpeed.val.Text = fmt(S.speedValue)
    rJump.val.Text  = fmt(S.jumpValue)
    rClock.val.Text = formatClock(S.clockValue)
    notify("Reset ke default ✓ (file rute tetap aman)", true)
end

--═══════════════ WIRING TOMBOL ═══════════════
rSpeed.minus.MouseButton1Click:Connect(function()
    S.speedValue = math.max(1, S.speedValue - STEP)
    rSpeed.val.Text = fmt(S.speedValue)
    if S.speedOn then applyMovement() end
end)
rSpeed.plus.MouseButton1Click:Connect(function()
    S.speedValue += STEP
    rSpeed.val.Text = fmt(S.speedValue)
    if S.speedOn then applyMovement() end
end)
rSpeed.toggle.MouseButton1Click:Connect(function() setSpeed(not S.speedOn) end)

rJump.minus.MouseButton1Click:Connect(function()
    S.jumpValue = math.max(1, S.jumpValue - STEP)
    rJump.val.Text = fmt(S.jumpValue)
    if S.jumpOn then applyMovement() end
end)
rJump.plus.MouseButton1Click:Connect(function()
    S.jumpValue += STEP
    rJump.val.Text = fmt(S.jumpValue)
    if S.jumpOn then applyMovement() end
end)
rJump.toggle.MouseButton1Click:Connect(function() setJump(not S.jumpOn) end)

rHideP.toggle.MouseButton1Click:Connect(function() setHidePlayers(not S.hidePlayersOn) end)
rHideF.toggle.MouseButton1Click:Connect(function() setHideFx(not S.hideFxOn) end)
rLowG.toggle.MouseButton1Click:Connect(function() setLowGfx(not S.lowGfxOn) end)

rClock.minus.MouseButton1Click:Connect(function() bumpClock(-CLOCK_STEP) end)
rClock.plus.MouseButton1Click:Connect(function() bumpClock(CLOCK_STEP) end)
rClock.toggle.MouseButton1Click:Connect(function() setClock(not S.clockOn) end)

rRekam.toggle.MouseButton1Click:Connect(function() setRekam(not S.rekamOn) end)
rRekamP.toggle.MouseButton1Click:Connect(function() setRekamP(not S.rekamPOn) end)
rSpec.toggle.MouseButton1Click:Connect(function() setSpec(not S.specOn) end)
rVisAll.toggle.MouseButton1Click:Connect(function()
    S.visAll = not S.visAll
    tampilSemua(S.visAll)
end)
gabungBtn.MouseButton1Click:Connect(gabungTerpilih)
tpPilihBtn.MouseButton1Click:Connect(tpKeTerpilih)

prevBtn.MouseButton1Click:Connect(function()
    if S.rekamPOn then notify("Stop rekam dulu untuk ganti target", false) return end
    local list = daftarPemainLain()
    if #list == 0 then return end
    targetIdx = (targetIdx - 2) % #list + 1
    updateTargetLabel()
    applySpectate()
end)
nextBtn.MouseButton1Click:Connect(function()
    if S.rekamPOn then notify("Stop rekam dulu untuk ganti target", false) return end
    local list = daftarPemainLain()
    if #list == 0 then return end
    targetIdx = targetIdx % #list + 1
    updateTargetLabel()
    applySpectate()
end)

addConn(Players.PlayerAdded:Connect(function()
    task.defer(updateTargetLabel)
end))
addConn(Players.PlayerRemoving:Connect(function()
    task.defer(updateTargetLabel)
end))

resetBtn.MouseButton1Click:Connect(resetSemua)
exitBtn.MouseButton1Click:Connect(destroyAll)

-- TAB + MINIMIZE
local tabAktif, minimized = false, false

local function applyLayout()
    scrollMain.Visible = (not minimized) and (not tabAktif)
    scrollRute.Visible = (not minimized) and tabAktif
    tabBar.Visible = not minimized
    bottom.Visible = not minimized
    main.Size = minimized and UDim2.fromOffset(480, 58) or UDim2.fromOffset(480, 620)
end

local function pilihTab(rute)
    tabAktif = rute
    tabMenuBtn.BackgroundColor3 = not rute and C.Ungu or C.Hitam2
    tabMenuBtn.TextColor3 = not rute and C.Putih or C.Abuk
    tabRuteBtn.BackgroundColor3 = rute and C.Ungu or C.Hitam2
    tabRuteBtn.TextColor3 = rute and C.Putih or C.Abuk
    applyLayout()
end
tabMenuBtn.MouseButton1Click:Connect(function() pilihTab(false) end)
tabRuteBtn.MouseButton1Click:Connect(function() pilihTab(true) end)

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    applyLayout()
end)

--═══════════════ DRAG GUI ═══════════════
do
    local dragging, dragStart, startPos = false, nil, nil
    title.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    addConn(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            local s = panelScale.Scale
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / s,
                startPos.Y.Scale, startPos.Y.Offset + d.Y / s)
        end
    end))
    addConn(UserInputService.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

--═══════════════ HOTKEYS ═══════════════
addConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local kc = input.KeyCode
    if kc == Enum.KeyCode.F then
        main.Visible = not main.Visible
    elseif kc == Enum.KeyCode.T then
        setClock(not S.clockOn)
    elseif kc == Enum.KeyCode.R then
        setHidePlayers(not S.hidePlayersOn)
    elseif kc == Enum.KeyCode.Q then
        setSpeed(not S.speedOn)
    elseif kc == Enum.KeyCode.K then
        setRekam(not S.rekamOn)
    elseif kc == Enum.KeyCode.L then
        setRekamP(not S.rekamPOn)
    end
end))

--═══════════════ FINALIZE ═══════════════
updateTargetLabel()
local jumlahDimuat = muatFileTersimpan()
renderDaftar()
segarkanToggle()
pilihTab(false)
main.Visible = true
notify("Siiilau ⚡ v1.0.0 siap", true)
if jumlahDimuat > 0 then
    notify("📂 " .. jumlahDimuat .. " file rute dimuat ✓", true)
end
if FS_OK then
    notify("💾 Tersimpan permanen ✓", true)
else
    notify("⚠️ Executor tak dukung file", false)
end
