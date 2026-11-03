--═════════════════════════════════════════════════════════════════════════════
--  ⚡ F L E K S I B L E   v1.06  —  FOKUS TIMER
--─────────────────────────────────────────────────────────────────────────────
--  FITUR :
--   ⏱  TIMER PLAT     : V ke-1 = PLAT AWAL, V ke-2 = PLAT FINISH (auto
--                        bergantian); keluar dari plat awal → timer jalan,
--                        BALIK ke plat awal → timer DIRESET, sentuh plat
--                        finish → berhenti & hasil masuk tab hasil
--                        (menit:detik.sentidetik) + TERCEPAT + HUD WAKTU DI
--                        LAYAR (bisa digeser)  •  plat KECIL seukuran badan
--   ⚡  TELEPORT       : teleport cepat ke PLAT AWAL / titik start buat
--                        mengulang putaran tanpa lari jauh
--  KEYBIND :
--   F = buka / tutup GUI
--   V = pasang plat timer bergantian (awal → finish → putaran baru)
--   T = teleport ke plat awal (start)
--  v1.05 : FOKUS TIMER — fitur lain dihapus. ANTI-DUPLIKAT tetap aktif
--          (script tidak dimuat 2×)  +  tombol 🗑 HAPUS SCRIPT di tab INFO
--  v1.06 : HUD waktu HANYA muncul saat timer BERJALAN — tidak tampil saat
--          masih di kotak biru (plat awal) / saat timer sudah berhenti
--─────────────────────────────────────────────────────────────────────────────
--  Bekerja LOKAL (klien). Pengaturan, posisi plat, hasil timer & rekor
--  tercepat tersimpan otomatis di file FLEKSIBLE_v106.json (kalau executor
--  mendukung writefile). Data timer versi lama (v101–v105) otomatis
--  dipindahkan. Script tidak bisa dimuat dua kali; dihapus lewat tombol
--  HAPUS SCRIPT (tab INFO) atau getgenv().FLEKSIBLE_UNLOAD().
--═════════════════════════════════════════════════════════════════════════════

if not game:IsLoaded() then game.Loaded:Wait() end

local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UserInput = game:GetService("UserInputService")
local HttpSvc  = game:GetService("HttpService")

local pemain = Players.LocalPlayer
while not pemain do
    task.wait(0.2)
    pemain = Players.LocalPlayer
end

local typeof = typeof or type
local HIDUP  = true

local getgenv = typeof(getgenv) == "function" and getgenv or function() return _G end

--──────────────────── ANTI-DUPLIKAT (v1.06) ────────────────────────────────
--  Kalau FLEKSIBLE sudah jalan, JANGAN buat GUI lagi (tidak muncul dobel):
--  versi sama  → cukup tampilkan GUI yang lama + notifikasi;
--  versi beda  → yang lama otomatis di-unload lalu versi baru dimuat.
local INSTANS_LAMA = getgenv().FLEKSIBLE
if typeof(INSTANS_LAMA) == "table" and INSTANS_LAMA.versi then
    if INSTANS_LAMA.versi == "v1.06" then
        pcall(function()
            if typeof(INSTANS_LAMA.pesan) == "function" then
                INSTANS_LAMA.pesan("⚡ FLEKSIBLE sudah aktif — script tidak dimuat dua kali")
            end
            if typeof(INSTANS_LAMA.buka) == "function" then
                INSTANS_LAMA.buka()
            elseif typeof(INSTANS_LAMA.bukaTutup) == "function" then
                INSTANS_LAMA.bukaTutup()
            end
        end)
        print("[FLEKSIBLE] Sudah aktif (v1.06) — tidak dimuat ulang. Hapus dulu lewat tombol HAPUS SCRIPT / getgenv().FLEKSIBLE_UNLOAD().")
        return
    else
        pcall(function()
            if typeof(INSTANS_LAMA.unload) == "function" then
                INSTANS_LAMA.unload()
            end
        end)
        task.wait(0.05)
    end
end

--──────────────────────────────── TEMA ──────────────────────────────────────
local Warna = {
    latar  = Color3.fromRGB(13, 10, 26),
    panel  = Color3.fromRGB(21, 16, 42),
    panel2 = Color3.fromRGB(30, 23, 60),
    garis  = Color3.fromRGB(52, 40, 100),
    teks   = Color3.fromRGB(238, 234, 255),
    redup  = Color3.fromRGB(158, 150, 205),
    ungu   = Color3.fromRGB(168, 85, 247),
    biru   = Color3.fromRGB(64, 132, 255),
    sian   = Color3.fromRGB(46, 214, 236),
    pink   = Color3.fromRGB(236, 82, 175),
    hijau  = Color3.fromRGB(74, 222, 128),
    merah  = Color3.fromRGB(248, 104, 110),
    kuning = Color3.fromRGB(250, 204, 82),
    putih  = Color3.fromRGB(255, 255, 255),
}

local FNT  = Enum.Font.GothamBold
local FNT2 = Enum.Font.Gotham

--──────────────────────────────── UTIL ──────────────────────────────────────
local function clamp(v, a, b)
    if v < a then return a elseif v > b then return b end
    return v
end

-- format menit : detik . sentidetik  →  01:23.45
local function fmtWaktu(t)
    if type(t) ~= "number" then return "--:--.--" end
    local m  = math.floor(t / 60)
    local d  = math.floor(t % 60)
    local sd = math.floor((t * 100) % 100)
    return string.format("%02d:%02d.%02d", m, d, sd)
end

-- registry koneksi: daftar(k, conn) + putuskan(k)
local function reg(tabel, conn)
    table.insert(tabel, conn)
    return conn
end

local function putuskan(tabel)
    for i = #tabel, 1, -1 do
        pcall(function() tabel[i]:Disconnect() end)
        tabel[i] = nil
    end
end

--────────────────────────── INDUK GUI & TOAST ───────────────────────────────
local function indukGui()
    if typeof(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return pemain:WaitForChild("PlayerGui")
end

local guiToast = Instance.new("ScreenGui")
guiToast.Name = "FLEKSIBLE_Toast"
guiToast.ResetOnSpawn = false
guiToast.DisplayOrder = 60
guiToast.Parent = indukGui()

local wadahToast = Instance.new("Frame")
wadahToast.AnchorPoint = Vector2.new(1, 1)
wadahToast.Position = UDim2.new(1, -18, 1, -18)
wadahToast.Size = UDim2.new(0, 286, 0, 0)
wadahToast.BackgroundTransparency = 1
wadahToast.Parent = guiToast

local layoutToast = Instance.new("UIListLayout")
layoutToast.FillDirection = Enum.FillDirection.Vertical
layoutToast.VerticalAlignment = Enum.VerticalAlignment.Bottom
layoutToast.HorizontalAlignment = Enum.HorizontalAlignment.Right
layoutToast.Padding = UDim.new(0, 8)
layoutToast.SortOrder = Enum.SortOrder.LayoutOrder
layoutToast.Parent = wadahToast

local urutToast = 0

local kasihTahu
kasihTahu = function(pesan, warna)
    if not HIDUP then return end
    warna = warna or Warna.ungu

    -- batasi jumlah toast
    local jumlah = 0
    for _, c in ipairs(wadahToast:GetChildren()) do
        if c:IsA("Frame") then jumlah += 1 end
    end
    if jumlah > 4 then
        for _, c in ipairs(wadahToast:GetChildren()) do
            if c:IsA("Frame") then
                c:Destroy()
                break
            end
        end
    end

    urutToast += 1
    local kartu = Instance.new("Frame")
    kartu.BackgroundColor3 = Warna.panel
    kartu.BackgroundTransparency = 1
    kartu.Size = UDim2.new(1, 0, 0, 0)
    kartu.AutomaticSize = Enum.AutomaticSize.Y
    kartu.LayoutOrder = urutToast
    kartu.BorderSizePixel = 0

    local sudut = Instance.new("UICorner")
    sudut.CornerRadius = UDim.new(0, 10)
    sudut.Parent = kartu

    local st = Instance.new("UIStroke")
    st.Color = warna
    st.Thickness = 1.2
    st.Transparency = 1
    st.Parent = kartu

    local garisKiri = Instance.new("Frame")
    garisKiri.Size = UDim2.new(0, 4, 1, 0)
    garisKiri.Position = UDim2.new(0, 0, 0, 0)
    garisKiri.BackgroundColor3 = warna
    garisKiri.BorderSizePixel = 0
    garisKiri.Parent = kartu

    local sudutKiri = Instance.new("UICorner")
    sudutKiri.CornerRadius = UDim.new(0, 10)
    sudutKiri.Parent = garisKiri

    local teks = Instance.new("TextLabel")
    teks.BackgroundTransparency = 1
    teks.Position = UDim2.new(0, 14, 0, 9)
    teks.Size = UDim2.new(1, -24, 0, 0)
    teks.AutomaticSize = Enum.AutomaticSize.Y
    teks.Font = FNT2
    teks.TextSize = 13
    teks.TextColor3 = Warna.teks
    teks.TextTransparency = 1
    teks.TextWrapped = true
    teks.TextXAlignment = Enum.TextXAlignment.Left
    teks.Text = pesan
    teks.Parent = kartu

    kartu.Parent = wadahToast

    TweenSvc:Create(kartu, TweenInfo.new(0.22), { BackgroundTransparency = 0.08 }):Play()
    TweenSvc:Create(teks, TweenInfo.new(0.22), { TextTransparency = 0 }):Play()
    TweenSvc:Create(st, TweenInfo.new(0.22), { Transparency = 0.15 }):Play()

    task.delay(2.8, function()
        if not kartu.Parent then return end
        pcall(function()
            TweenSvc:Create(kartu, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
            TweenSvc:Create(teks, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            TweenSvc:Create(st, TweenInfo.new(0.3), { Transparency = 1 }):Play()
        end)
        task.delay(0.32, function()
            pcall(function() kartu:Destroy() end)
        end)
    end)
end

--──────────────────────────── PENGATURAN (CFG) ──────────────────────────────
local NAMA_FILE       = "FLEKSIBLE_v106.json"
local NAMA_FILE_LAMA1 = "FLEKSIBLE_v105.json"   -- dipindahkan kalau ada
local NAMA_FILE_LAMA2 = "FLEKSIBLE_v104.json"

local CFG = {
    versi = 106,
    timer = { tercepat = nil, hasil = {}, posawal = nil, posakhir = nil, hud = true },
}

local bisaFile = false
pcall(function()
    bisaFile = (typeof(writefile) == "function")
        and (typeof(readfile) == "function")
        and (typeof(isfile) == "function")
end)

local function muatCfg()
    if not bisaFile then return end
    pcall(function()
        local file = nil
        if isfile(NAMA_FILE) then
            file = NAMA_FILE
        elseif isfile(NAMA_FILE_LAMA1) then
            file = NAMA_FILE_LAMA1   -- pengaturan versi lama tetap terbaca
        elseif isfile(NAMA_FILE_LAMA2) then
            file = NAMA_FILE_LAMA2
        end
        if file then
            local data = HttpSvc:JSONDecode(readfile(file))
            if typeof(data) == "table" then
                for k, v in pairs(data) do
                    if type(v) == "table" and type(CFG[k]) == "table" then
                        for k2, v2 in pairs(v) do
                            CFG[k][k2] = v2
                        end
                    else
                        CFG[k] = v
                    end
                end
            end
        end
    end)
    if type(CFG.timer) ~= "table" then CFG.timer = { tercepat = nil, hasil = {}, posawal = nil, posakhir = nil, hud = true } end
    if type(CFG.timer.hasil) ~= "table" then CFG.timer.hasil = {} end

    --──── migrasi → v1.06 (fokus TIMER) ────
    -- buang pengaturan fitur lama — script sekarang hanya fitur timer
    CFG.tembus = nil
    CFG.terang = nil
    CFG.hitbox = nil
    CFG.versi = 106
end

local function simpanCfg()
    if not bisaFile or not HIDUP then return end
    pcall(function()
        writefile(NAMA_FILE, HttpSvc:JSONEncode(CFG))
    end)
end

local tokenSimpan = 0
local function simpanNanti()
    tokenSimpan += 1
    local tk = tokenSimpan
    task.delay(0.4, function()
        if tk == tokenSimpan then simpanCfg() end
    end)
end

muatCfg()


--═════════════════════════ FITUR : TIMER PLAT ═══════════════════════════════
--  Cara kerja (sesuai permintaan, v1.03 pasang BERGANTIAN):
--   1. Tekan V ke-1  → PLAT AWAL terpasang di titik awal
--   2. Tekan V ke-2  → PLAT FINISH otomatis terpasang di garis finis
--      (tekan V lagi = putaran baru: plat lama dihapus, kembali ke awal)
--   3. Keluar dari PLAT AWAL  → timer otomatis BERJALAN
--   4. BALIK ke PLAT AWAL saat timer jalan → timer otomatis DIRESET
--   5. Sampai / menyentuh PLAT FINISH → timer BERHENTI
--   6. Hasil otomatis masuk tab TIMER → mencatat waktu TERCEPAT
--      Format: menit:detik.sentidetik  (01:23.45)
--  v1.03: plat KECIL seukuran lingkaran badan (3 × 3 stud)
--  + TELEPORT cepat ke PLAT AWAL (tombol / keybind T)
--  + HUD waktu tampil DI LAYAR (bisa digeser) supaya waktu berjalan
--    kelihatan meski GUI ditutup.
--  v1.06: HUD waktu HANYA MUNCUL SAAT TIMER BERJALAN:
--   - masih di dalam kotak biru (plat awal)  → HUD TERSEMBUNYI
--   - keluar dari kotak biru (timer mulai)   → HUD MUNCUL
--   - timer berhenti / direset / dibatalkan  → HUD HILANG
--  Plat hanya visual lokal (CanCollide=false, tidak mengganggu jalan).
--═════════════════════════════════════════════════════════════════════════════

local perbaruiTimerUI  -- diisi di bagian UI
local renderHasil      -- diisi di bagian UI

local TM = {
    berikutnya = "awal",      -- plat yang dipasang saat tekan V berikutnya
    platAwal = nil,           -- { part = Instance, pos = Vector3 }
    platAkhir = nil,
    berjalan = false,
    mulaiT = 0,
    diDalam = false,          -- sedang berada di dalam plat awal
    hasil = {},               -- { { t = detik, j = jarak stud, w = os.time } }
    tercepat = nil,
    hud = CFG.timer.hud ~= false,
}

local function hancurkanPlat(jenis)
    local p = (jenis == "awal") and TM.platAwal or TM.platAkhir
    if p and p.part then
        pcall(function() p.part:Destroy() end)
    end
    if jenis == "awal" then
        TM.platAwal = nil
        CFG.timer.posawal = nil
    else
        TM.platAkhir = nil
        CFG.timer.posakhir = nil
    end
end

local function buatPlat(jenis, pos)
    local part = Instance.new("Part")
    part.Name = "FLX_PLAT_" .. string.upper(jenis)
    part.Size = Vector3.new(3, 0.25, 3)   -- v1.03: kecil, seukuran badan
    part.Position = pos
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Transparency = 0.35
    part.Material = Enum.Material.Neon
    part.Color = (jenis == "awal") and Warna.biru or Warna.pink

    local sudut = Instance.new("UICorner")
    sudut.CornerRadius = UDim.new(0, 6)
    sudut.Parent = part

    local bb = Instance.new("BillboardGui")
    bb.Name = "LabelPlat"
    bb.Size = UDim2.new(0, 120, 0, 26)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 200

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.fromScale(1, 1)
    tl.BackgroundTransparency = 1
    tl.Font = FNT
    tl.TextSize = 13
    tl.TextStrokeTransparency = 0.35
    tl.TextColor3 = (jenis == "awal") and Warna.sian or Warna.pink
    tl.Text = (jenis == "awal") and "▼ PLAT AWAL" or "PLAT FINISH ▲"
    tl.Parent = bb

    bb.Parent = part
    part.Parent = workspace
    return part
end

-- posisi kaki karakter (raycast ke bawah supaya plat nempel tanah)
local function posisiKaki()
    local ch = pemain.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { ch }
    local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -60, 0), params)
    if hit then
        return hit.Position + Vector3.new(0, 0.15, 0)
    end
    return Vector3.new(hrp.Position.X, hrp.Position.Y - 3.2, hrp.Position.Z)
end

local function pasangPlat(jenis)
    if not HIDUP then return false end
    local pos = posisiKaki()
    if not pos then
        kasihTahu("Karakter belum siap, coba lagi", Warna.merah)
        return false
    end
    local lain = (jenis == "awal") and TM.platAkhir or TM.platAwal
    if lain and lain.pos and ((lain.pos - pos).Magnitude < 5) then
        kasihTahu("Terlalu dekat dengan plat " .. (jenis == "awal" and "FINISH" or "AWAL") .. "!", Warna.merah)
        return false
    end
    hancurkanPlat(jenis)
    local part = buatPlat(jenis, pos)
    if jenis == "awal" then
        TM.platAwal = { part = part, pos = pos }
        CFG.timer.posawal = { x = pos.X, y = pos.Y, z = pos.Z }
        kasihTahu("🔵 Plat AWAL dipasang — sekarang ke garis FINISH, tekan V lagi", Warna.biru)
    else
        TM.platAkhir = { part = part, pos = pos }
        CFG.timer.posakhir = { x = pos.X, y = pos.Y, z = pos.Z }
        kasihTahu("🟣 Plat FINISH dipasang — keluar dari plat AWAL untuk mulai!", Warna.pink)
    end
    if TM.berjalan then
        TM.berjalan = false
        kasihTahu("Pengukuran dibatalkan (plat diganti)", Warna.kuning)
    end
    TM.diDalam = false
    simpanCfg()
    if perbaruiTimerUI then perbaruiTimerUI() end
    return true
end

-- apakah posisi berada di area plat kecil (radius 2 stud, tinggi 6 stud)
local function diDalam(plat, pos)
    if not plat or not plat.pos then return false end
    local d = plat.pos - pos
    if math.abs(d.Y) > 6 then return false end
    return (d.X * d.X + d.Z * d.Z) <= 4
end

local function rekamHasil(total)
    local jarak
    if TM.platAwal and TM.platAkhir then
        jarak = (TM.platAkhir.pos - TM.platAwal.pos).Magnitude
    end
    local entri = { t = math.floor(total * 100 + 0.5) / 100 }
    if jarak then
        entri.j = math.floor(jarak * 10 + 0.5) / 10
    end
    entri.w = os.time()

    table.insert(TM.hasil, 1, entri)
    while #TM.hasil > 12 do
        table.remove(TM.hasil)
    end

    if TM.tercepat == nil or entri.t < TM.tercepat then
        TM.tercepat = entri.t
        kasihTahu("🏆 TERCEPAT BARU!  " .. fmtWaktu(entri.t), Warna.kuning)
    else
        kasihTahu("🏁 FINISH — " .. fmtWaktu(entri.t), Warna.hijau)
    end

    CFG.timer.tercepat = TM.tercepat
    CFG.timer.hasil = TM.hasil
    simpanCfg()
    if renderHasil then renderHasil() end
end

-- satu langkah logika timer (dipanggil 20x per detik)
local function langkahTimer()
    local ch = pemain.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = hrp.Position

    if TM.platAwal and TM.platAkhir then
        if TM.berjalan then
            if diDalam(TM.platAkhir, pos) then
                local total = os.clock() - TM.mulaiT
                TM.berjalan = false
                rekamHasil(total)
            elseif diDalam(TM.platAwal, pos) then
                -- balik ke plat awal saat timer jalan → timer DIRESET (v1.03)
                TM.berjalan = false
                TM.diDalam = true
                TM.mulaiT = 0
                kasihTahu("⏱ Timer DIRESET — kamu balik ke plat AWAL", Warna.kuning)
            end
        else
            if diDalam(TM.platAwal, pos) then
                TM.diDalam = true
            elseif TM.diDalam then
                -- keluar dari plat awal → MULAI
                TM.diDalam = false
                TM.berjalan = true
                TM.mulaiT = os.clock()
                kasihTahu("⏱ TIMER BERJALAN — gaspol ke finish!", Warna.sian)
            end
        end
    end
end

task.spawn(function()
    while HIDUP do
        task.wait(0.05)
        local ok = pcall(langkahTimer)
        if ok and perbaruiTimerUI then
            pcall(perbaruiTimerUI)
        end
        if not ok then
            task.wait(0.5)
        end
    end
end)

local function hapusSemuaPlat(senyap)
    hancurkanPlat("awal")
    hancurkanPlat("akhir")
    TM.berjalan = false
    TM.diDalam = false
    TM.berikutnya = "awal"
    simpanCfg()
    if perbaruiTimerUI then perbaruiTimerUI() end
    if senyap ~= true then
        kasihTahu("🗑 Semua plat dihapus", Warna.kuning)
    end
end

local function ulangiSesi()
    TM.berjalan = false
    TM.diDalam = false
    if perbaruiTimerUI then perbaruiTimerUI() end
    kasihTahu("🔄 Sesi diulang — masuk lagi ke plat awal", Warna.biru)
end

-- v1.03: TELEPORT cepat ke PLAT AWAL / titik start (tombol & keybind T).
-- Karakter sendiri dipindahkan utuh dengan PivotTo — aman buat fisika.
local function teleportAwal()
    if not HIDUP then return false end
    if not (TM.platAwal and TM.platAwal.pos) then
        kasihTahu("Pasang PLAT AWAL dulu (tekan V)", Warna.merah)
        return false
    end
    local ch = pemain.Character
    if not ch or not ch.Parent then return false end
    local hm = ch:FindFirstChildOfClass("Humanoid")
    if hm and hm.Health <= 0 then return false end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local rot = hrp and hrp.CFrame.Rotation or CFrame.new()
    local pos = TM.platAwal.pos
    ch:PivotTo(CFrame.new(pos.X, pos.Y + 3, pos.Z) * rot)
    if TM.berjalan then
        TM.berjalan = false
        kasihTahu("Pengukuran dibatalkan (teleport ke awal)", Warna.kuning)
    end
    TM.diDalam = true
    if perbaruiTimerUI then perbaruiTimerUI() end
    kasihTahu("⚡ Teleport ke PLAT AWAL — keluar lagi dari plat untuk mulai", Warna.sian)
    return true
end

-- v1.03: pasang plat BERGANTIAN — tekan ke-1 = AWAL, ke-2 = FINISH,
-- tekan selanjutnya (kedua plat sudah lengkap) = putaran baru
local function pasangPlatBerikutnya()
    if not HIDUP then return false end
    local jenis = TM.berikutnya or "awal"
    if jenis == "awal" and TM.platAwal and TM.platAkhir then
        hapusSemuaPlat(true)   -- senyap: mulai putaran baru
        kasihTahu("🔄 Putaran baru — plat lama dihapus, pasang PLAT AWAL", Warna.kuning)
    end
    local ok = pasangPlat(jenis)
    if ok then
        TM.berikutnya = (jenis == "awal") and "akhir" or "awal"
        if perbaruiTimerUI then perbaruiTimerUI() end
    end
    return ok
end

--═════════════════════ HUD WAKTU DI LAYAR (v1.06) ═══════════════════════════
--  Kotak kecil di atas layar: waktu berjalan + tercepat. v1.06: muncul
--  HANYA saat timer berjalan — keluar kotak biru = muncul, timer berhenti
--  / balik ke kotak biru = hilang. Bisa digeser posisinya.

local kHud = {}

local guiHud = Instance.new("ScreenGui")
guiHud.Name = "FLEKSIBLE_TimerHUD"
guiHud.ResetOnSpawn = false
guiHud.DisplayOrder = 50
guiHud.Parent = indukGui()

local hudKartu = Instance.new("Frame")
hudKartu.Name = "KartuHud"
hudKartu.AnchorPoint = Vector2.new(0.5, 0)
hudKartu.Position = UDim2.new(0.5, 0, 0, 70)
hudKartu.Size = UDim2.new(0, 240, 0, 92)
hudKartu.BackgroundColor3 = Warna.latar
hudKartu.BackgroundTransparency = 0.1
hudKartu.BorderSizePixel = 0
hudKartu.Active = true
hudKartu.Parent = guiHud

local sudutHud = Instance.new("UICorner")
sudutHud.CornerRadius = UDim.new(0, 12)
sudutHud.Parent = hudKartu

local hudStroke = Instance.new("UIStroke")
hudStroke.Color = Warna.garis
hudStroke.Thickness = 1.4
hudStroke.Transparency = 0.15
hudStroke.Parent = hudKartu

local ledHud = Instance.new("Frame")
ledHud.Size = UDim2.new(1, -20, 0, 2)
ledHud.Position = UDim2.new(0, 10, 0, 7)
ledHud.BorderSizePixel = 0
ledHud.BackgroundColor3 = Warna.putih
ledHud.Parent = hudKartu

local sudutLedHud = Instance.new("UICorner")
sudutLedHud.CornerRadius = UDim.new(1, 0)
sudutLedHud.Parent = ledHud

local gradienLedHud = Instance.new("UIGradient")
gradienLedHud.Color = ColorSequence.new(Warna.ungu, Warna.sian)
gradienLedHud.Parent = ledHud

local hudStatus = Instance.new("TextLabel")
hudStatus.BackgroundTransparency = 1
hudStatus.Position = UDim2.new(0, 10, 0, 11)
hudStatus.Size = UDim2.new(1, -20, 0, 14)
hudStatus.Font = FNT
hudStatus.TextSize = 11
hudStatus.TextColor3 = Warna.redup
hudStatus.Text = "⏱ TIMER — pasang plat (tekan V)"
hudStatus.Parent = hudKartu

local hudWaktu = Instance.new("TextLabel")
hudWaktu.BackgroundTransparency = 1
hudWaktu.Position = UDim2.new(0, 0, 0, 25)
hudWaktu.Size = UDim2.new(1, 0, 0, 42)
hudWaktu.Font = FNT
hudWaktu.TextSize = 34
hudWaktu.TextColor3 = Warna.teks
hudWaktu.Text = "00:00.00"
hudWaktu.Parent = hudKartu

local hudInfo = Instance.new("TextLabel")
hudInfo.BackgroundTransparency = 1
hudInfo.Position = UDim2.new(0, 10, 1, -20)
hudInfo.Size = UDim2.new(1, -20, 0, 14)
hudInfo.Font = FNT2
hudInfo.TextSize = 10
hudInfo.TextColor3 = Warna.redup
hudInfo.Text = "🏆 --:--.--   •   AWAL ✖   FINISH ✖"
hudInfo.Parent = hudKartu

-- geser posisi HUD (drag)
local tarikHud = false
local asalTarikHud, posAwalHud

hudKartu.InputBegan:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
        tarikHud = true
        asalTarikHud = io.Position
        posAwalHud = hudKartu.Position
    end
end)

reg(kHud, UserInput.InputChanged:Connect(function(io)
    if tarikHud and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
        local d = io.Position - asalTarikHud
        hudKartu.Position = UDim2.new(
            posAwalHud.X.Scale, posAwalHud.X.Offset + d.X,
            posAwalHud.Y.Scale, posAwalHud.Y.Offset + d.Y
        )
    end
end))

reg(kHud, UserInput.InputEnded:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
        tarikHud = false
    end
end))

local function setHudTimer(nyala)
    TM.hud = (nyala == true)
    CFG.timer.hud = TM.hud
    -- v1.06: terlepas dari setelan, HUD tetap hanya tampil kalau timer jalan
    guiHud.Enabled = TM.hud and TM.berjalan
end

-- dipakai unload untuk membersihkan koneksi drag HUD
TM.putusHud = function()
    putuskan(kHud)
end
TM.guiHud = guiHud

-- v1.06: mulai TERSEMBUNYI — baru muncul saat timer benar-benar berjalan
-- (visibilitas disinkronkan perbaruiTimerUI setiap langkah timer)
guiHud.Enabled = false


--═════════════════════════════ ANTARMUKA (UI) ═══════════════════════════════

local KONEKSI_UI = {}

local gui = Instance.new("ScreenGui")
gui.Name = "FLEKSIBLE_v106"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = indukGui()

local utama = Instance.new("CanvasGroup")
utama.Name = "Utama"
utama.Size = UDim2.fromOffset(580, 436)
utama.Position = UDim2.new(0.5, -290, 0.5, -218)
utama.BackgroundColor3 = Warna.latar
utama.BorderSizePixel = 0
utama.Active = true
utama.Parent = gui

local sudutUtama = Instance.new("UICorner")
sudutUtama.CornerRadius = UDim.new(0, 16)
sudutUtama.Parent = utama

local strokeUtama = Instance.new("UIStroke")
strokeUtama.Color = Warna.ungu
strokeUtama.Thickness = 1.6
strokeUtama.Transparency = 0.25
strokeUtama.Parent = utama

-- garis LED gradien di atas
local ledAtas = Instance.new("Frame")
ledAtas.Size = UDim2.new(1, -28, 0, 3)
ledAtas.Position = UDim2.new(0, 14, 0, 10)
ledAtas.BorderSizePixel = 0
ledAtas.BackgroundColor3 = Warna.putih
ledAtas.Parent = utama

local sudutLed = Instance.new("UICorner")
sudutLed.CornerRadius = UDim.new(1, 0)
sudutLed.Parent = ledAtas

local gradienLed = Instance.new("UIGradient")
gradienLed.Color = ColorSequence.new(Warna.ungu, Warna.biru)
gradienLed.Parent = ledAtas

--────────────────────────────── BILAH JUDUL ─────────────────────────────────
local barJudul = Instance.new("Frame")
barJudul.Name = "BarJudul"
barJudul.Position = UDim2.new(0, 0, 0, 18)
barJudul.Size = UDim2.new(1, 0, 0, 44)
barJudul.BackgroundTransparency = 1
barJudul.Parent = utama

local judulTeks = Instance.new("TextLabel")
judulTeks.BackgroundTransparency = 1
judulTeks.Position = UDim2.new(0, 18, 0, 0)
judulTeks.Size = UDim2.new(0, 190, 1, 0)
judulTeks.Font = FNT
judulTeks.TextSize = 18
judulTeks.TextColor3 = Warna.teks
judulTeks.TextXAlignment = Enum.TextXAlignment.Left
judulTeks.Text = "⚡ FLEKSIBLE"
judulTeks.Parent = barJudul

local lencana = Instance.new("TextLabel")
lencana.BackgroundColor3 = Warna.ungu
lencana.Position = UDim2.new(0, 148, 0.5, -11)
lencana.Size = UDim2.new(0, 52, 0, 22)
lencana.Font = FNT
lencana.TextSize = 12
lencana.TextColor3 = Warna.putih
lencana.Text = "v1.06"
lencana.Parent = barJudul

local sudutLencana = Instance.new("UICorner")
sudutLencana.CornerRadius = UDim.new(0, 6)
sudutLencana.Parent = lencana

local tombolTutup = Instance.new("TextButton")
tombolTutup.AnchorPoint = Vector2.new(1, 0.5)
tombolTutup.Position = UDim2.new(1, -14, 0.5, 0)
tombolTutup.Size = UDim2.new(0, 34, 0, 26)
tombolTutup.BackgroundColor3 = Warna.panel2
tombolTutup.Font = FNT
tombolTutup.TextSize = 13
tombolTutup.TextColor3 = Warna.merah
tombolTutup.Text = "✕"
tombolTutup.AutoButtonColor = false
tombolTutup.Parent = barJudul

local sudutTutup = Instance.new("UICorner")
sudutTutup.CornerRadius = UDim.new(0, 8)
sudutTutup.Parent = tombolTutup

local strokeTutup = Instance.new("UIStroke")
strokeTutup.Color = Warna.garis
strokeTutup.Thickness = 1
strokeTutup.Parent = tombolTutup

--────────────────────────────── SERET (DRAG) ────────────────────────────────
local tarikGUI = false
local asalTarik, posAwalGUI

barJudul.InputBegan:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
        tarikGUI = true
        asalTarik = io.Position
        posAwalGUI = utama.Position
    end
end)

reg(KONEKSI_UI, UserInput.InputChanged:Connect(function(io)
    if tarikGUI and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
        local d = io.Position - asalTarik
        utama.Position = UDim2.new(
            posAwalGUI.X.Scale, posAwalGUI.X.Offset + d.X,
            posAwalGUI.Y.Scale, posAwalGUI.Y.Offset + d.Y
        )
    end
end))

reg(KONEKSI_UI, UserInput.InputEnded:Connect(function(io)
    if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
        tarikGUI = false
    end
end))

--───────────────────────────── REL TAB & KONTEN ─────────────────────────────
local rel = Instance.new("Frame")
rel.Position = UDim2.new(0, 12, 0, 70)
rel.Size = UDim2.new(0, 132, 1, -84)
rel.BackgroundTransparency = 1
rel.Parent = utama

local relLayout = Instance.new("UIListLayout")
relLayout.Padding = UDim.new(0, 7)
relLayout.SortOrder = Enum.SortOrder.LayoutOrder
relLayout.Parent = rel

local konten = Instance.new("Frame")
konten.Position = UDim2.new(0, 152, 0, 70)
konten.Size = UDim2.new(1, -164, 1, -84)
konten.BackgroundTransparency = 1
konten.Parent = utama

local daftarTab = {}

local function pilihTab(namaDipilih)
    for _, t in ipairs(daftarTab) do
        local aktif = (t.nama == namaDipilih)
        t.halaman.Visible = aktif
        t.tombol.BackgroundColor3 = aktif and Warna.panel2 or Warna.panel
        t.tombol.BackgroundTransparency = aktif and 0 or 0.35
        t.strokeT.Color = aktif and Warna.ungu or Warna.garis
        t.strokeT.Transparency = aktif and 0.1 or 0.5
        t.labelT.TextColor3 = aktif and Warna.teks or Warna.redup
    end
end

local function buatTab(ikon, nama)
    local tombol = Instance.new("TextButton")
    tombol.Size = UDim2.new(1, 0, 0, 42)
    tombol.BackgroundColor3 = Warna.panel
    tombol.BackgroundTransparency = 0.35
    tombol.Font = FNT
    tombol.TextSize = 13
    tombol.TextColor3 = Warna.redup
    tombol.Text = ""
    tombol.AutoButtonColor = false
    tombol.Parent = rel

    local sudut = Instance.new("UICorner")
    sudut.CornerRadius = UDim.new(0, 10)
    sudut.Parent = tombol

    local strokeT = Instance.new("UIStroke")
    strokeT.Color = Warna.garis
    strokeT.Thickness = 1
    strokeT.Transparency = 0.5
    strokeT.Parent = tombol

    local labelT = Instance.new("TextLabel")
    labelT.BackgroundTransparency = 1
    labelT.Position = UDim2.new(0, 12, 0, 0)
    labelT.Size = UDim2.new(1, -16, 1, 0)
    labelT.Font = FNT
    labelT.TextSize = 13
    labelT.TextColor3 = Warna.redup
    labelT.TextXAlignment = Enum.TextXAlignment.Left
    labelT.Text = ikon .. "  " .. nama
    labelT.Parent = tombol

    local halaman = Instance.new("ScrollingFrame")
    halaman.Size = UDim2.new(1, 0, 1, 0)
    halaman.BackgroundTransparency = 1
    halaman.BorderSizePixel = 0
    halaman.ScrollBarThickness = 3
    halaman.ScrollBarImageColor3 = Warna.ungu
    halaman.CanvasSize = UDim2.new(0, 0, 0, 0)
    halaman.AutomaticCanvasSize = Enum.AutomaticSize.Y
    halaman.Visible = false
    halaman.Parent = konten

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 2)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.Parent = halaman

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 7)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = halaman

    tombol.MouseButton1Click:Connect(function()
        pilihTab(nama)
    end)

    table.insert(daftarTab, {
        nama = nama, tombol = tombol, labelT = labelT,
        strokeT = strokeT, halaman = halaman,
    })
    return halaman
end

--────────────────────────────── BUKA / TUTUP ────────────────────────────────
local guiTerbuka = true
local animToken = 0

local function toggleGui()
    animToken += 1
    local tk = animToken
    guiTerbuka = not guiTerbuka
    if guiTerbuka then
        utama.Visible = true
        utama.GroupTransparency = 1
        TweenSvc:Create(utama, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { GroupTransparency = 0 }):Play()
    else
        TweenSvc:Create(utama, TweenInfo.new(0.15), { GroupTransparency = 1 }):Play()
        task.delay(0.16, function()
            if tk == animToken and not guiTerbuka then
                utama.Visible = false
            end
        end)
    end
end

tombolTutup.MouseButton1Click:Connect(function()
    toggleGui()
end)

--────────────────────────────── KOMPONEN BARIS ──────────────────────────────
local function baris(halaman, tinggi)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -14, 0, tinggi)
    f.BackgroundColor3 = Warna.panel
    f.BorderSizePixel = 0
    f.Parent = halaman

    local sudut = Instance.new("UICorner")
    sudut.CornerRadius = UDim.new(0, 10)
    sudut.Parent = f

    local st = Instance.new("UIStroke")
    st.Color = Warna.garis
    st.Thickness = 1
    st.Transparency = 0.35
    st.Parent = f
    return f
end

local function buatJudul(halaman, isi)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -14, 0, 20)
    l.BackgroundTransparency = 1
    l.Font = FNT
    l.TextSize = 12
    l.TextColor3 = Warna.ungu
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = "▎" .. string.upper(isi)
    l.Parent = halaman
    return l
end

local function buatInfo(halaman, isi)
    local wadah = Instance.new("Frame")
    wadah.Size = UDim2.new(1, -14, 0, 0)
    wadah.AutomaticSize = Enum.AutomaticSize.Y
    wadah.BackgroundTransparency = 1
    wadah.Parent = halaman

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -6, 0, 0)
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.BackgroundTransparency = 1
    l.Font = FNT2
    l.TextSize = 12
    l.TextColor3 = Warna.redup
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = isi
    l.Parent = wadah
    return wadah
end

-- toggle: baris penuh bisa diklik, saklar di kanan
local function buatToggle(halaman, teksUtama, teksSub, nilaiAwal, callback)
    local tinggi = teksSub and 52 or 44
    local b = baris(halaman, tinggi)

    local judul = Instance.new("TextLabel")
    judul.BackgroundTransparency = 1
    judul.Position = UDim2.new(0, 14, 0, teksSub and 9 or 0)
    judul.Size = UDim2.new(1, -110, 0, 16)
    judul.Font = FNT
    judul.TextSize = 13
    judul.TextColor3 = Warna.teks
    judul.TextXAlignment = Enum.TextXAlignment.Left
    judul.Text = teksUtama
    judul.Parent = b

    if teksSub then
        local sub = Instance.new("TextLabel")
        sub.BackgroundTransparency = 1
        sub.Position = UDim2.new(0, 14, 0, 27)
        sub.Size = UDim2.new(1, -110, 0, 14)
        sub.Font = FNT2
        sub.TextSize = 11
        sub.TextColor3 = Warna.redup
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Text = teksSub
        sub.Parent = b
    end

    local pil = Instance.new("Frame")
    pil.AnchorPoint = Vector2.new(1, 0.5)
    pil.Position = UDim2.new(1, -12, 0.5, 0)
    pil.Size = UDim2.new(0, 44, 0, 24)
    pil.BackgroundColor3 = Warna.panel2
    pil.Parent = b

    local sudutPil = Instance.new("UICorner")
    sudutPil.CornerRadius = UDim.new(1, 0)
    sudutPil.Parent = pil

    local strokePil = Instance.new("UIStroke")
    strokePil.Color = Warna.garis
    strokePil.Thickness = 1
    strokePil.Parent = pil

    local kenop = Instance.new("Frame")
    kenop.Size = UDim2.new(0, 18, 0, 18)
    kenop.Position = UDim2.new(0, 3, 0, 3)
    kenop.BackgroundColor3 = Warna.redup
    kenop.Parent = pil

    local sudutKenop = Instance.new("UICorner")
    sudutKenop.CornerRadius = UDim.new(1, 0)
    sudutKenop.Parent = kenop

    local nyala = (nilaiAwal == true)
    local function render()
        TweenSvc:Create(pil, TweenInfo.new(0.15),
            { BackgroundColor3 = nyala and Warna.ungu or Warna.panel2 }):Play()
        TweenSvc:Create(strokePil, TweenInfo.new(0.15),
            { Color = nyala and Warna.ungu or Warna.garis }):Play()
        TweenSvc:Create(kenop, TweenInfo.new(0.15),
            { Position = nyala and UDim2.new(0, 23, 0, 3) or UDim2.new(0, 3, 0, 3),
              BackgroundColor3 = nyala and Warna.putih or Warna.redup }):Play()
    end

    local klik = Instance.new("TextButton")
    klik.Size = UDim2.new(1, 0, 1, 0)
    klik.BackgroundTransparency = 1
    klik.Text = ""
    klik.AutoButtonColor = false
    klik.Parent = b

    klik.MouseButton1Click:Connect(function()
        nyala = not nyala
        render()
        callback(nyala)
    end)

    render()
    return { set = function(v) nyala = (v == true) render() end }
end

-- slider: label + nilai + lintasan geser
local function buatSlider(halaman, teks, minv, maxv, awal, fmtF, callback)
    local b = baris(halaman, 60)

    local judul = Instance.new("TextLabel")
    judul.BackgroundTransparency = 1
    judul.Position = UDim2.new(0, 14, 0, 8)
    judul.Size = UDim2.new(1, -130, 0, 16)
    judul.Font = FNT
    judul.TextSize = 13
    judul.TextColor3 = Warna.teks
    judul.TextXAlignment = Enum.TextXAlignment.Left
    judul.Text = teks
    judul.Parent = b

    local nilaiL = Instance.new("TextLabel")
    nilaiL.AnchorPoint = Vector2.new(1, 0)
    nilaiL.Position = UDim2.new(1, -14, 0, 8)
    nilaiL.Size = UDim2.new(0, 110, 0, 16)
    nilaiL.BackgroundTransparency = 1
    nilaiL.Font = FNT
    nilaiL.TextSize = 13
    nilaiL.TextColor3 = Warna.sian
    nilaiL.TextXAlignment = Enum.TextXAlignment.Right
    nilaiL.Text = ""
    nilaiL.Parent = b

    local track = Instance.new("Frame")
    track.Position = UDim2.new(0, 14, 0, 38)
    track.Size = UDim2.new(1, -28, 0, 6)
    track.BackgroundColor3 = Warna.panel2
    track.BorderSizePixel = 0
    track.Parent = b

    local sudutTrack = Instance.new("UICorner")
    sudutTrack.CornerRadius = UDim.new(1, 0)
    sudutTrack.Parent = track

    local isi = Instance.new("Frame")
    isi.Size = UDim2.fromScale(0.5, 1)
    isi.BackgroundColor3 = Warna.ungu
    isi.BorderSizePixel = 0
    isi.Parent = track

    local sudutIsi = Instance.new("UICorner")
    sudutIsi.CornerRadius = UDim.new(1, 0)
    sudutIsi.Parent = isi

    local kenop = Instance.new("Frame")
    kenop.AnchorPoint = Vector2.new(0.5, 0.5)
    kenop.Size = UDim2.new(0, 14, 0, 14)
    kenop.Position = UDim2.fromScale(0.5, 0.5)
    kenop.BackgroundColor3 = Warna.putih
    kenop.Parent = track

    local sudutKenop = Instance.new("UICorner")
    sudutKenop.CornerRadius = UDim.new(1, 0)
    sudutKenop.Parent = kenop

    local nilai = tonumber(awal) or minv

    local function render()
        local pct = clamp((nilai - minv) / (maxv - minv), 0, 1)
        isi.Size = UDim2.fromScale(pct, 1)
        kenop.Position = UDim2.fromScale(pct, 0.5)
        nilaiL.Text = fmtF(nilai)
    end

    local function aturDari(xAbs)
        local pct = clamp((xAbs - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local baru = minv + (maxv - minv) * pct
        baru = math.floor(baru * 100 + 0.5) / 100
        if baru ~= nilai then
            nilai = baru
            render()
            callback(nilai)
        end
    end

    local tarik = false
    -- input di seluruh baris supaya mudah disentuh di HP (track hanya 6px)
    b.InputBegan:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
            tarik = true
            aturDari(io.Position.X)
        end
    end)

    reg(KONEKSI_UI, UserInput.InputChanged:Connect(function(io)
        if tarik and (io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch) then
            aturDari(io.Position.X)
        end
    end))

    reg(KONEKSI_UI, UserInput.InputEnded:Connect(function(io)
        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
            if tarik then
                tarik = false
                simpanNanti()
            end
        end
    end))

    render()
    return {
        set = function(v)
            nilai = tonumber(v) or nilai
            render()
        end,
    }
end

-- tombol kecil di kanan baris
local function buatTombol(halaman, teksKiri, teksTombol, warnaTmb, callback)
    local b = baris(halaman, 44)

    local judul = Instance.new("TextLabel")
    judul.BackgroundTransparency = 1
    judul.Position = UDim2.new(0, 14, 0, 0)
    judul.Size = UDim2.new(1, -180, 1, 0)
    judul.Font = FNT
    judul.TextSize = 13
    judul.TextColor3 = Warna.teks
    judul.TextXAlignment = Enum.TextXAlignment.Left
    judul.Text = teksKiri
    judul.Parent = b

    local tmb = Instance.new("TextButton")
    tmb.AnchorPoint = Vector2.new(1, 0.5)
    tmb.Position = UDim2.new(1, -12, 0.5, 0)
    tmb.Size = UDim2.new(0, 150, 0, 28)
    tmb.BackgroundColor3 = warnaTmb or Warna.ungu
    tmb.Font = FNT
    tmb.TextSize = 12
    tmb.TextColor3 = Warna.putih
    tmb.Text = teksTombol
    tmb.AutoButtonColor = false
    tmb.Parent = b

    local sudut = Instance.new("UICorner")
    sudut.CornerRadius = UDim.new(0, 8)
    sudut.Parent = tmb

    tmb.MouseButton1Click:Connect(callback)
    return tmb
end

-- tombol selebar baris
local function buatTombolPenuh(halaman, teksTombol, warnaTmb, warnaTeks, callback)
    local b = baris(halaman, 40)
    b.BackgroundColor3 = warnaTmb or Warna.panel

    local tmb = Instance.new("TextButton")
    tmb.Size = UDim2.new(1, 0, 1, 0)
    tmb.BackgroundTransparency = 1
    tmb.Font = FNT
    tmb.TextSize = 13
    tmb.TextColor3 = warnaTeks or Warna.teks
    tmb.Text = teksTombol
    tmb.AutoButtonColor = false
    tmb.Parent = b

    tmb.MouseButton1Click:Connect(callback)
    return tmb
end


--════════════════════════════ ISI TAB-TAB ═══════════════════════════════════

--────────────────────────────── TAB : TIMER ─────────────────────────────────
local halTimer = buatTab("⏱", "TIMER")

buatJudul(halTimer, "Timer Balapan")

local kartu = Instance.new("Frame")
kartu.Size = UDim2.new(1, -14, 0, 118)
kartu.BackgroundColor3 = Warna.panel
kartu.BorderSizePixel = 0
kartu.Parent = halTimer

local sudutKartu = Instance.new("UICorner")
sudutKartu.CornerRadius = UDim.new(0, 12)
sudutKartu.Parent = kartu

local strokeKartu = Instance.new("UIStroke")
strokeKartu.Color = Warna.garis
strokeKartu.Thickness = 1
strokeKartu.Transparency = 0.35
strokeKartu.Parent = kartu

local statusL = Instance.new("TextLabel")
statusL.BackgroundTransparency = 1
statusL.Position = UDim2.new(0, 14, 0, 10)
statusL.Size = UDim2.new(1, -28, 0, 18)
statusL.Font = FNT
statusL.TextSize = 13
statusL.TextColor3 = Warna.kuning
statusL.TextXAlignment = Enum.TextXAlignment.Left
statusL.Text = "Keluar plat AWAL = mulai • balik ke AWAL = reset • T = teleport"
statusL.Parent = kartu

local waktuL = Instance.new("TextLabel")
waktuL.BackgroundTransparency = 1
waktuL.Position = UDim2.new(0, 0, 0, 32)
waktuL.Size = UDim2.new(1, 0, 0, 48)
waktuL.Font = FNT
waktuL.TextSize = 42
waktuL.TextColor3 = Warna.teks
waktuL.Text = "00:00.00"
waktuL.Parent = kartu

local legendL = Instance.new("TextLabel")
legendL.BackgroundTransparency = 1
legendL.Position = UDim2.new(0, 0, 1, -26)
legendL.Size = UDim2.new(1, 0, 0, 16)
legendL.Font = FNT2
legendL.TextSize = 11
legendL.TextColor3 = Warna.redup
legendL.Text = "menit : detik . sentidetik"
legendL.Parent = kartu

-- baris statistik: tercepat / terakhir / jarak
local barisStat = Instance.new("Frame")
barisStat.Size = UDim2.new(1, -14, 0, 56)
barisStat.BackgroundTransparency = 1
barisStat.Parent = halTimer

local layStat = Instance.new("UIListLayout")
layStat.FillDirection = Enum.FillDirection.Horizontal
layStat.Padding = UDim.new(0, 8)
layStat.SortOrder = Enum.SortOrder.LayoutOrder
layStat.Parent = barisStat

local function kotakStat(urutan, caption, warnaNilai)
    local k = Instance.new("Frame")
    k.Size = UDim2.new(1 / 3, -6, 1, 0)
    k.BackgroundColor3 = Warna.panel
    k.BorderSizePixel = 0
    k.LayoutOrder = urutan
    k.Parent = barisStat

    local s1 = Instance.new("UICorner")
    s1.CornerRadius = UDim.new(0, 10)
    s1.Parent = k

    local st1 = Instance.new("UIStroke")
    st1.Color = Warna.garis
    st1.Thickness = 1
    st1.Transparency = 0.35
    st1.Parent = k

    local cap = Instance.new("TextLabel")
    cap.BackgroundTransparency = 1
    cap.Position = UDim2.new(0, 0, 0, 8)
    cap.Size = UDim2.new(1, 0, 0, 12)
    cap.Font = FNT2
    cap.TextSize = 10
    cap.TextColor3 = Warna.redup
    cap.Text = caption
    cap.Parent = k

    local val = Instance.new("TextLabel")
    val.BackgroundTransparency = 1
    val.Position = UDim2.new(0, 0, 0, 24)
    val.Size = UDim2.new(1, 0, 0, 20)
    val.Font = FNT
    val.TextSize = 15
    val.TextColor3 = warnaNilai
    val.Text = "—"
    val.Parent = k
    return val
end

local statTercepat = kotakStat(1, "TERCEPAT 🏆", Warna.kuning)
local statTerakhir = kotakStat(2, "TERAKHIR", Warna.teks)
local statJarak    = kotakStat(3, "JARAK PLAT", Warna.sian)

-- HUD waktu di layar (bisa digeser) — v1.06: hanya tampil saat timer jalan
buatToggle(halTimer, "TAMPILAN DI LAYAR", "HUD waktu — hanya tampil saat timer BERJALAN; bisa digeser", CFG.timer.hud ~= false, function(v)
    setHudTimer(v)
    simpanNanti()
end)

-- status plat (pasang BERGANTIAN lewat V / tombol besar)
buatJudul(halTimer, "Plat — pasang bergantian")

local barisPlat = Instance.new("Frame")
barisPlat.Size = UDim2.new(1, -14, 0, 58)
barisPlat.BackgroundTransparency = 1
barisPlat.Parent = halTimer

local layPlat = Instance.new("UIListLayout")
layPlat.FillDirection = Enum.FillDirection.Horizontal
layPlat.Padding = UDim.new(0, 8)
layPlat.SortOrder = Enum.SortOrder.LayoutOrder
layPlat.Parent = barisPlat

local function kartuPlat(urutan, namaTeks, warna)
    local b = Instance.new("Frame")
    b.Size = UDim2.new(0.5, -4, 1, 0)
    b.BackgroundColor3 = Warna.panel
    b.BorderSizePixel = 0
    b.LayoutOrder = urutan
    b.Parent = barisPlat

    local sudut = Instance.new("UICorner")
    sudut.CornerRadius = UDim.new(0, 10)
    sudut.Parent = b

    local st = Instance.new("UIStroke")
    st.Color = Warna.garis
    st.Thickness = 1
    st.Transparency = 0.35
    st.Parent = b

    local t1 = Instance.new("TextLabel")
    t1.BackgroundTransparency = 1
    t1.Position = UDim2.new(0, 0, 0, 10)
    t1.Size = UDim2.new(1, 0, 0, 16)
    t1.Font = FNT
    t1.TextSize = 13
    t1.TextColor3 = warna
    t1.Text = namaTeks
    t1.Parent = b

    local t2 = Instance.new("TextLabel")
    t2.BackgroundTransparency = 1
    t2.Position = UDim2.new(0, 0, 0, 32)
    t2.Size = UDim2.new(1, 0, 0, 14)
    t2.Font = FNT2
    t2.TextSize = 11
    t2.TextColor3 = Warna.redup
    t2.Text = "✖ belum ada"
    t2.Parent = b

    return { stroke = st, label = t1, status = t2, nama = namaTeks }
end

local kartuAwal  = kartuPlat(1, "PLAT AWAL", Warna.sian)
local kartuAkhir = kartuPlat(2, "PLAT FINISH", Warna.pink)

buatTombolPenuh(halTimer, "📍  PASANG PLAT  (V)", Warna.ungu, Warna.putih, function()
    pasangPlatBerikutnya()
end)

buatTombolPenuh(halTimer, "⚡  TELEPORT KE PLAT AWAL  (T)", Warna.biru, Warna.putih, function()
    teleportAwal()
end)

local labelBerikutnya = Instance.new("TextLabel")
labelBerikutnya.Size = UDim2.new(1, -14, 0, 20)
labelBerikutnya.BackgroundTransparency = 1
labelBerikutnya.Font = FNT2
labelBerikutnya.TextSize = 12
labelBerikutnya.TextColor3 = Warna.sian
labelBerikutnya.Text = "▶ Tekan V / tombol di atas → pasang PLAT AWAL"
labelBerikutnya.Parent = halTimer

buatTombolPenuh(halTimer, "🔄  ULANGI SESI (kembali ke start)", Warna.panel, Warna.sian, function()
    ulangiSesi()
end)

buatTombolPenuh(halTimer, "🗑  HAPUS SEMUA PLAT", Warna.panel, Warna.merah, function()
    hapusSemuaPlat()
end)

-- hasil
buatJudul(halTimer, "Hasil")

local wadahHasil = Instance.new("Frame")
wadahHasil.Size = UDim2.new(1, -14, 0, 0)
wadahHasil.AutomaticSize = Enum.AutomaticSize.Y
wadahHasil.BackgroundTransparency = 1
wadahHasil.Parent = halTimer

local layHasil = Instance.new("UIListLayout")
layHasil.Padding = UDim.new(0, 5)
layHasil.SortOrder = Enum.SortOrder.LayoutOrder
layHasil.Parent = wadahHasil

renderHasil = function()
    for _, c in ipairs(wadahHasil:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    if #TM.hasil == 0 then
        local kosong = Instance.new("TextLabel")
        kosong.Size = UDim2.new(1, -14, 0, 34)
        kosong.BackgroundTransparency = 1
        kosong.Font = FNT2
        kosong.TextSize = 12
        kosong.TextColor3 = Warna.redup
        kosong.Text = "— belum ada hasil. Pasang plat, lalu keluar dari plat awal! —"
        kosong.Parent = wadahHasil
        return
    end

    for i, e in ipairs(TM.hasil) do
        local rekor = (e.t ~= nil and e.t == TM.tercepat)
        local r = Instance.new("Frame")
        r.Size = UDim2.new(1, -14, 0, 30)
        r.BackgroundColor3 = rekor and Warna.panel2 or Warna.panel
        r.BorderSizePixel = 0
        r.LayoutOrder = i
        r.Parent = wadahHasil

        local s = Instance.new("UICorner")
        s.CornerRadius = UDim.new(0, 8)
        s.Parent = r

        local st = Instance.new("UIStroke")
        st.Color = rekor and Warna.kuning or Warna.garis
        st.Thickness = rekor and 1.4 or 1
        st.Transparency = rekor and 0.1 or 0.35
        st.Parent = r

        local kiri = Instance.new("TextLabel")
        kiri.BackgroundTransparency = 1
        kiri.Position = UDim2.new(0, 12, 0, 0)
        kiri.Size = UDim2.new(0.6, 0, 1, 0)
        kiri.Font = FNT
        kiri.TextSize = 13
        kiri.TextColor3 = rekor and Warna.kuning or Warna.teks
        kiri.TextXAlignment = Enum.TextXAlignment.Left
        kiri.Text = (rekor and "🏆 " or "#" .. i .. "  ") .. fmtWaktu(e.t)
        kiri.Parent = r

        local kanan = Instance.new("TextLabel")
        kanan.BackgroundTransparency = 1
        kanan.AnchorPoint = Vector2.new(1, 0)
        kanan.Position = UDim2.new(1, -12, 0, 0)
        kanan.Size = UDim2.new(0.4, 0, 1, 0)
        kanan.Font = FNT2
        kanan.TextSize = 11
        kanan.TextColor3 = Warna.redup
        kanan.TextXAlignment = Enum.TextXAlignment.Right
        local ket = ""
        if e.j then ket = string.format("%.1f stud", e.j) end
        if e.w then ket = ket .. (ket ~= "" and "  •  " or "") .. os.date("%H:%M", e.w) end
        kanan.Text = ket
        kanan.Parent = r
    end
end

buatTombolPenuh(halTimer, "🧹  HAPUS HASIL & TERCEPAT", Warna.panel, Warna.redup, function()
    TM.hasil = {}
    TM.tercepat = nil
    CFG.timer.hasil = {}
    CFG.timer.tercepat = nil
    simpanCfg()
    renderHasil()
    kasihTahu("Hasil & rekor tercepat dihapus", Warna.kuning)
end)

buatInfo(halTimer, "CARA PAKAI: 1) Berdiri di titik awal → tekan V (PLAT AWAL kecil seukuran badan terpasang). 2) Berdiri di garis finis → tekan V lagi (PLAT FINISH otomatis). 3) Keluar dari plat AWAL → timer langsung jalan. 4) Sentuh PLAT FINISH → timer berhenti & hasil tercatat di sini, rekor TERCEPAT disorot. 5) BALIK ke plat AWAL saat timer jalan → timer otomatis DIRESET. Tekan T / tombol TELEPORT buat balik ke start cepat. Tekan V lagi = putaran baru (plat lama otomatis diganti). HUD waktu hanya muncul di layar SAAT TIMER BERJALAN (keluar plat AWAL = muncul; selesai / balik ke plat AWAL = hilang) dan bisa digeser.")

-- perbarui tampilan timer (dipanggil dari loop utama)
perbaruiTimerUI = function()
    if TM.berjalan then
        statusL.Text = "⏱ BERJALAN — sentuh plat FINISH untuk berhenti"
        statusL.TextColor3 = Warna.hijau
        waktuL.Text = fmtWaktu(os.clock() - TM.mulaiT)
        waktuL.TextColor3 = Warna.putih
    else
        if not (TM.platAwal and TM.platAkhir) then
            local kurang = TM.platAwal and "FINISH" or "AWAL"
            statusL.Text = "Tekan V untuk pasang PLAT " .. kurang
            statusL.TextColor3 = Warna.kuning
        elseif TM.diDalam then
            statusL.Text = "SIAP! Keluar dari plat AWAL → timer jalan"
            statusL.TextColor3 = Warna.hijau
        else
            statusL.Text = "Masuk dulu ke plat AWAL, lalu keluar untuk mulai"
            statusL.TextColor3 = Warna.redup
        end
        waktuL.Text = TM.hasil[1] and fmtWaktu(TM.hasil[1].t) or "00:00.00"
        waktuL.TextColor3 = Warna.teks
    end

    statTercepat.Text = TM.tercepat and fmtWaktu(TM.tercepat) or "—"
    statTerakhir.Text = TM.hasil[1] and fmtWaktu(TM.hasil[1].t) or "—"
    if TM.platAwal and TM.platAkhir then
        statJarak.Text = string.format("%.1f stud", (TM.platAkhir.pos - TM.platAwal.pos).Magnitude)
    else
        statJarak.Text = "—"
    end

    kartuAwal.status.Text = TM.platAwal and "✔ terpasang" or "✖ belum ada"
    kartuAwal.status.TextColor3 = TM.platAwal and Warna.hijau or Warna.merah
    kartuAkhir.status.Text = TM.platAkhir and "✔ terpasang" or "✖ belum ada"
    kartuAkhir.status.TextColor3 = TM.platAkhir and Warna.hijau or Warna.merah

    -- sorot plat yang dipasang BERIKUTNYA
    kartuAwal.stroke.Color = (TM.berikutnya == "awal") and Warna.sian or Warna.garis
    kartuAwal.stroke.Thickness = (TM.berikutnya == "awal") and 1.6 or 1
    kartuAwal.label.Text = ((TM.berikutnya == "awal") and "◉ " or "") .. kartuAwal.nama
    kartuAkhir.stroke.Color = (TM.berikutnya == "akhir") and Warna.pink or Warna.garis
    kartuAkhir.stroke.Thickness = (TM.berikutnya == "akhir") and 1.6 or 1
    kartuAkhir.label.Text = ((TM.berikutnya == "akhir") and "◉ " or "") .. kartuAkhir.nama

    labelBerikutnya.Text = (TM.berikutnya == "awal")
        and "▶ Tekan V / tombol di atas → pasang PLAT AWAL 🔵"
        or  "▶ Tekan V / tombol di atas → pasang PLAT FINISH 🟣"
    labelBerikutnya.TextColor3 = (TM.berikutnya == "awal") and Warna.sian or Warna.pink

    -- HUD waktu di layar — v1.06: HANYA muncul saat timer berjalan.
    -- Masih di kotak biru (plat awal) / timer berhenti → HUD otomatis hilang.
    local hudTampil = TM.hud and TM.berjalan
    if guiHud.Enabled ~= hudTampil then
        guiHud.Enabled = hudTampil
    end
    if hudTampil then
        hudWaktu.Text = waktuL.Text
        hudStatus.Text = "⏱ BERJALAN — gaspol ke PLAT FINISH!"
        hudStatus.TextColor3 = Warna.hijau
        hudStroke.Color = Warna.hijau
        hudInfo.Text = string.format("🏆 %s   •   AWAL %s   FINISH %s",
            TM.tercepat and fmtWaktu(TM.tercepat) or "--:--.--",
            TM.platAwal and "✔" or "✖",
            TM.platAkhir and "✔" or "✖")
    end
end

--────────────────────────────── TAB : INFO ──────────────────────────────────
local halInfo = buatTab("ℹ", "INFO")

buatJudul(halInfo, "Tentang")
buatInfo(halInfo, "⚡ FLEKSIBLE v1.06 — FOKUS TIMER: pasang PLAT AWAL (V ke-1) & PLAT FINISH (V ke-2), keluar dari plat awal → timer jalan, balik ke plat awal → timer DIRESET, sentuh plat finish → berhenti & hasil tercatat (menit:detik.sentidetik) + rekor TERCEPAT. Teleport cepat ke start (T). HUD waktu hanya muncul saat timer berjalan & bisa digeser. Satu script, satu fitur, ringan — semua berjalan lokal.")

buatJudul(halInfo, "Keybind")

local function barisKeybind(huruf, keterangan, warna)
    local b = baris(halInfo, 40)

    local lencanaK = Instance.new("Frame")
    lencanaK.Position = UDim2.new(0, 12, 0.5, -12)
    lencanaK.Size = UDim2.new(0, 32, 0, 24)
    lencanaK.BackgroundColor3 = warna or Warna.ungu
    lencanaK.BorderSizePixel = 0
    lencanaK.Parent = b

    local s = Instance.new("UICorner")
    s.CornerRadius = UDim.new(0, 6)
    s.Parent = lencanaK

    local tK = Instance.new("TextLabel")
    tK.Size = UDim2.new(1, 0, 1, 0)
    tK.BackgroundTransparency = 1
    tK.Font = FNT
    tK.TextSize = 14
    tK.TextColor3 = Warna.putih
    tK.Text = huruf
    tK.Parent = lencanaK

    local ket = Instance.new("TextLabel")
    ket.BackgroundTransparency = 1
    ket.Position = UDim2.new(0, 56, 0, 0)
    ket.Size = UDim2.new(1, -68, 1, 0)
    ket.Font = FNT
    ket.TextSize = 13
    ket.TextColor3 = Warna.teks
    ket.TextXAlignment = Enum.TextXAlignment.Left
    ket.Text = keterangan
    ket.Parent = b
end

barisKeybind("F", "Buka / tutup GUI", Warna.ungu)
barisKeybind("V", "Plat timer bergantian: 1× = AWAL, 2× = FINISH, 3× = putaran baru", Warna.biru)
barisKeybind("T", "Teleport ke PLAT AWAL (titik start)", Warna.sian)

buatJudul(halInfo, "Catatan")
buatInfo(halInfo, "• Semua fitur bersifat lokal (klien), aman untuk pengalamanmu sendiri.\n• Pengaturan, posisi plat, hasil timer & rekor tercepat tersimpan otomatis di FLEKSIBLE_v106.json (data versi lama otomatis dipindahkan).\n• GUI hanya bisa dibuka/ditutup dengan F (atau tombol ✕).\n• Script tidak bisa dimuat dua kali — kalau dijalankan lagi saat masih aktif, cukup GUI-nya yang muncul.\n• HUD timer hanya muncul saat timer berjalan: keluar dari plat AWAL → muncul, selesai / balik ke plat AWAL → otomatis hilang.\n• HUD timer bisa digeser: tahan & seret kotak waktunya.")

--──── HAPUS SCRIPT — bersihkan semuanya (unload) ────
--  hapusScript diisi di bagian akhir script (fungsi unload asli)
local hapusScript

buatJudul(halInfo, "Keluar")

local tekanHapusTerakhir = 0
buatTombolPenuh(halInfo, "🗑  HAPUS SCRIPT  (hapus semua fitur)", Warna.merah, Warna.putih, function()
    local skrg = os.clock()
    if skrg - tekanHapusTerakhir > 3 then
        tekanHapusTerakhir = skrg
        kasihTahu("Tekan SEKALI LAGI (dalam 3 detik) untuk konfirmasi hapus", Warna.kuning)
        return
    end
    tekanHapusTerakhir = 0
    if typeof(hapusScript) == "function" then
        hapusScript()
    end
end)

buatInfo(halInfo, "Menghapus script = GUI, HUD waktu & plat timer dibersihkan dan semua pengaturan tersimpan. Bisa juga lewat: getgenv().FLEKSIBLE_UNLOAD()")


--══════════════════════ KEYBIND & INISIALISASI ══════════════════════════════
--  F = buka / tutup GUI
--  V = pasang plat timer bergantian (1×=AWAL, 2×=FINISH, 3×=putaran baru)
--  T = teleport ke plat awal (start)
--═════════════════════════════════════════════════════════════════════════════

reg(KONEKSI_UI, UserInput.InputBegan:Connect(function(io, proses)
    if proses then return end
    if io.KeyCode == Enum.KeyCode.F then
        toggleGui()
    elseif io.KeyCode == Enum.KeyCode.V then
        pasangPlatBerikutnya()
    elseif io.KeyCode == Enum.KeyCode.T then
        teleportAwal()
    end
end))

--──────────────────── pulihkan plat & hasil dari penyimpanan ─────────────────
if typeof(CFG.timer.posawal) == "table" and type(CFG.timer.posawal.x) == "number" then
    local p = Vector3.new(CFG.timer.posawal.x, CFG.timer.posawal.y, CFG.timer.posawal.z)
    pcall(function()
        TM.platAwal = { part = buatPlat("awal", p), pos = p }
    end)
end
if typeof(CFG.timer.posakhir) == "table" and type(CFG.timer.posakhir.x) == "number" then
    local p = Vector3.new(CFG.timer.posakhir.x, CFG.timer.posakhir.y, CFG.timer.posakhir.z)
    pcall(function()
        TM.platAkhir = { part = buatPlat("akhir", p), pos = p }
    end)
end

local hasilBersih = {}
for _, e in ipairs(CFG.timer.hasil) do
    if typeof(e) == "table" and type(e.t) == "number" then
        table.insert(hasilBersih, e)
    end
end
TM.hasil = hasilBersih
CFG.timer.hasil = hasilBersih
TM.tercepat = type(CFG.timer.tercepat) == "number" and CFG.timer.tercepat or nil

renderHasil()
pilihTab("TIMER")

--────────────────────────────── API & UNLOAD ────────────────────────────────
local function bongkar()
    if not HIDUP then return end
    HIDUP = false
    putuskan(KONEKSI_UI)
    hancurkanPlat("awal")
    hancurkanPlat("akhir")
    simpanCfg()
    pcall(function() if TM.putusHud then TM.putusHud() end end)
    pcall(function() if TM.guiHud then TM.guiHud:Destroy() end end)
    pcall(function() gui:Destroy() end)
    pcall(function() guiToast:Destroy() end)
    getgenv().FLEKSIBLE = nil
    getgenv().FLEKSIBLE_UNLOAD = nil
    print("[FLEKSIBLE] v1.06 dimatikan & dibersihkan.")
end

hapusScript = bongkar   -- v1.06: dipakai tombol 🗑 HAPUS SCRIPT di tab INFO

getgenv().FLEKSIBLE = {
    versi = "v1.06",
    bukaTutup = toggleGui,
    buka = function()
        if not guiTerbuka then toggleGui() end
    end,
    pesan = kasihTahu,
    pasangPlat = pasangPlatBerikutnya,
    teleport = teleportAwal,
    unload = bongkar,
}
getgenv().FLEKSIBLE_UNLOAD = bongkar

kasihTahu("⚡ FLEKSIBLE v1.06 siap — F = GUI, V = plat, T = teleport ke start", Warna.ungu)
print("[FLEKSIBLE] v1.06 dimuat. Keybind: F = GUI, V = plat bergantian, T = teleport ke awal.")
