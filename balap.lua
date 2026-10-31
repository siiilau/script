--========================================================
--  BALAP v1.5 —
--  TEMA: SILAU NEON (ungu/biru LED)
--
--  4 TAB:
--    1 MOVEMENT & VISUAL : Speed, Jump, Shiftlock Mobile, Shiftlock Tengah,
--                          Moonwalk, Hide Player +Kendaraan, Hide Badan Atas,
--                          Cahaya Auto, Lightweight, Dinding Batas
--    2 TITIK   : tiang checkpoint + daftar titik (tersimpan permanen)
--    3 TP      : simpan / rename / hapus lokasi teleport + urut terdekat
--    4 SYSTEM  : ☁ SINKRON (kode lintas device), rejoin, hapus script
--
--  Keybind:
--    G = buka/tutup GUI (saat tutup = hilang total)
--    Q = Speed ON/OFF (nilai ON dipilih di panel: 17.25-21.25)
--    J = JumpPower (51.25 ⇄ 65.25)    C = Shiftlock Mobile
--    LShift/RShift = Shiftlock Tengah (kamera tengah, kursor lingkaran mini)
--    F = Moonwalk    R = Hide
--    T = Cahaya Auto (2 arah)    X = Dinding Batas
--    V = Tambah titik di posisi karakter (tanpa buka GUI)
--    K = Rejoin (double-tap)
--    TP = via GUI (tab TP): simpan lokasi dgn nama bebas — permanen
--
--  v1.5 (HAPUS FITUR):
--    • Fitur Lompat Udara (Air Jump, v1.3) DIHAPUS total: toggle +
--      stepper "Lompatan ekstra" di tab MOVEMENT & VISUAL, keybind B,
--      mesin JumpRequest (lompatan ekstra di udara) & polling reset
--      mendaratnya. Tombol B kembali bebas (tidak dipakai fitur lain).
--      Fitur lain & semua data tersimpan 100% tidak berubah.
--  v1.4 (PERBAIKAN):
--    • FIX KENDARAAN — Moonwalk (F) & Shiftlock Mobile (C) sekarang
--      TIDAK BEREFEK SAMA SEKALI saat naik kendaraan (mobil, motor,
--      seat apa pun). Dulu mesinnya tetap memaksa badan menghadap
--      kamera padahal badan sudah "menyatu" dgn kendaraan (weld),
--      jadi MOBIL/MOTOR ikut terpaku ke arah kamera / ikut dibalik
--      saat jalan. Sekarang: duduk di kendaraan = kedua mesin berhenti
--      total (tidak sentuh CFrame) + AutoRotate dikembalikan sementara
--      ke bawaan game, jadi kendaraan dikendarai 100% normal. Turun
--      dari kendaraan = efeknya balik OTOMATIS (toggle tetap ON,
--      tidak perlu dimatikan-pasang lagi). Shiftlock Tengah, fitur
--      lain & semua data tersimpan tidak disentuh sama sekali.
--  v1.3 (FITUR BARU):
--    • LOMPAT UDARA (Air Jump) — fitur baru di tab MOVEMENT & VISUAL.
--      Toggle di panel + keybind B (slot B memang dikosongkan sejak
--      v1.2). Saat DI UDARA, tekan lompat lagi (spasi PC / tombol
--      lompat HP) untuk lompatan ekstra — kekuatannya mengikuti
--      JumpPower/JumpHeight aktif (setting J). Jumlah lompatan ekstra
--      diatur stepper "Lompatan ekstra" (1-3, default 1 = double jump).
--      Reset otomatis saat mendarat/respawn • anti-spam 0.25 dtk •
--      tidak aktif saat berenang / duduk di kendaraan.
--    • Fitur lain, semua data tersimpan (penanda_titik.json,
--      BALAP_TP.json, BALAP_SYNC.json) & keybind lain 100% tidak berubah.
--  v1.2 (HAPUS FITUR):
--    • Fitur Fall Resist DIHAPUS total: toggle + stepper di tab
--      MOVEMENT & VISUAL, keybind B, mesin pulse "Landed" (Heartbeat),
--      kurva demage, raycast tanah, dan semua teks/notif terkait.
--      Tombol B sekarang bebas (tidak dipakai fitur lain).
--      Fitur & keybind lain 100% tidak berubah.
--  v1.1 (RAPIKAN KODE + UI LEBAR & PAS LAYAR):
--    • Panel RESPONSIF — skala otomatis mengikuti layar (HP potret/lanskap
--      atau PC): layar besar tampil LEBAR (sampai 1.25x), layar kecil
--      menyusut sendiri supaya tidak ada bagian yang keluar layar.
--      Atur lewat CFG: UI_LEBAR / UI_TINGGI / UI_SCALE_MIN / UI_SCALE_MAX.
--    • Teks DIPERBESAR di seluruh UI (tab, label, tombol, daftar, notif).
--    • Anti teks nyasar keluar frame: daftar titik & status sinkron pakai
--      TextScaled (mengecil sendiri kalau teks panjang), tab di-wrap 2
--      baris, banner diag dapat ClipsDescendants + tinggi ekstra, kartu
--      info dilebarkan.
--    • Kode dirapikan: indentasi konsisten 4 spasi, struktur & komentar
--      dirapiin tanpa mengubah logika; 5 helper tak terpakai dihapus
--      (angkaDari, nomorBebas, idBaru, sorotInput, gayaToggle).
--      FITUR & CARA PAKAI 100% SAMA.
--  v1.0 (rilis restrukturisasi — lanjutan dari BALAP v1.3.5):
--    • TAB BARU: 1 MOVEMENT & VISUAL (gerak + visual dilebur jadi satu),
--      2 TITIK, 3 TP (tab sendiri), 4 SYSTEM
--    • Kartu ☁ SINKRON pindah ke tab SYSTEM; tombol ☁ di header membuka
--      tab SYSTEM. Mesin sync (textdb.dev, merge, tombstone) TIDAK diubah.
--    • Fall Resist: 4 tombol preset diganti STEPPER bebas 0-75% (pola
--      seperti Speed: -/+ 0.25 atau ketik sendiri). 0% = tanpa potongan
--      (pulse tidak ditembakkan, damage normal).
--    • Versi di-reset menjadi v1.0
--  Riwayat versi lama (sebelum reset ke v1.0):
--
--  v1.0.1: Moonwalk halus (putaran natural, CFG.MOON_TURN_MAX)
--  v1.1.0: Anti-AFK / Reset / Hemat GUI / Hide Pemain Lain dihapus
--          Shiftlock & Moonwalk OTOMATIS OFF saat mati / respawn
--  v1.2.0: FITUR BARU — Shiftlock Tengah (LShift/RShift): kamera persis di
--          TENGAH karakter (CameraOffset 0), kursor bawaan komputer,
--          transisi halus. Shiftlock/Moonwalk/Tengah saling menonaktifkan.
--  v1.3.0: TAB BARU 📍 TITIK — penanda checkpoint: tiang neon bernomor +
--          daftar teleport, tiang bisa hide/show, titik TERSIMPAN PERMANEN
--          (file penanda_titik.json — titik dari script lama ikut kebaca)
--  v1.3.1: Tiang TANPA nomor — muncul tiang polos saja (nomor di atas
--          tiang dihapus; daftar di tab tetap ada urutannya)
--  v1.3.2: Shiftlock Tengah — titik bidik TURUN ke pinggang/bawah badan
--          (CFG.SLT_TURUN) + kursor jadi lingkaran mini (panah komputer
--          disembunyikan)
--  v1.3.3: Kamera TIDAK diubah (efek kamera v1.3.2 dibatalkan) — cuma LETAK
--          lingkaran kursor digeser ke bawah (CFG.SLT_DOT_Y, 0.5 = tengah)
--  v1.3.4: ☁ SINKRON — TP & titik ikut tersinkron LINTAS DEVICE via
--          jsonblob.com (gratis, tanpa login). Kode sync angka dibuat
--          otomatis, selalu tampil di kartu ☁ SINKRON (tab TITIK) +
--          tombol SALIN. MASUKKAN KODE = nyambung ke device lain,
--          GANTI KODE = buat loker baru. Merge pintar: TP per nama,
--          titik <1 stud = dianggap kembar, DAFTAR HAPUS ikut
--          tersinkron (max 200) supaya hapusan tidak "bangkit" lagi.
--          Upload jeda 30 dtk • download saat load + tiap 3 menit •
--          offline = diam, data aman di lokal, retry otomatis.
--          Lain-lain: fix hotkey saat mengetik • V = tambah titik •
--          rename TP (✎) • jarak + urut terdekat • hapus semua =
--          konfirmasi 2 langkah • Speed OFF 17.15 • berenang saat
--          Shiftlock Tengah aktif = speed aktif × 1.025
--  v1.3.5: FIX SYNC — jsonblob.com ternyata MEMBLOKIR request dari
--          executor (Cloudflare anti-bot, balasan 403) sehingga kode
--          tidak pernah terbentuk ("Kode belum dibuat"). Layanan
--          diganti ke textdb.dev — sudah diuji: tulis/baca/update OK,
--          payload 320KB aman, tanpa blokir. BONUS: kode sync sekarang
--          bisa dibaca manusia (contoh: balap-7k2m-9xq4) — dulu cuma
--          bisa angka. Cara pakai tidak berubah sama sekali.
--========================================================
print("[BALAP v1.5] load mulai...")
-- [0] DIAGNOSTIK ON-SCREEN -----------------------------------------
-- Banner kecil pojok kiri: menunjukkan progres load. Kalau load GAGAL,
-- banner berubah MERAH dan menampilkan teks errornya di layar.
do
    local __dGui, __dLbl
    pcall(function()
        __dGui = Instance.new("ScreenGui")
        __dGui.Name = "BALAP_DIAG"
        __dGui.ResetOnSpawn = false
        __dGui.DisplayOrder = 1000000
        __dLbl = Instance.new("TextLabel")
        __dLbl.Size = UDim2.new(0, 480, 0, 70)
        __dLbl.Position = UDim2.new(0, 8, 0, 120)
        __dLbl.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
        __dLbl.BackgroundTransparency = 0.1
        __dLbl.BorderSizePixel = 0
        __dLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        __dLbl.Font = Enum.Font.GothamBold
        __dLbl.TextSize = 14
        __dLbl.TextWrapped = true
        __dLbl.ClipsDescendants = true
        __dLbl.Text = "BALAP: memulai..."
        __dLbl.Parent = __dGui
        local cr = Instance.new("UICorner")
        cr.CornerRadius = UDim.new(0, 8)
        cr.Parent = __dLbl
        local dipasang = false
        pcall(function() if gethui then __dGui.Parent = gethui(); dipasang = true end end)
        if not dipasang then
            pcall(function() __dGui.Parent = game:GetService("CoreGui"); dipasang = true end)
        end
        if not dipasang then
            pcall(function()
                __dGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
                dipasang = true
            end)
        end
    end)
    function diagSet(teks, warna)
        print("[BALAP-DIAG] " .. tostring(teks))
        pcall(function()
            if __dGui and __dGui.Parent and __dLbl then
                __dLbl.Text = tostring(teks)
                if warna then __dLbl.BackgroundColor3 = warna end
            end
        end)
    end
end

local VERSI = "1.5"
local __BALAP_LOAD_OK__ = xpcall(function()
    -- ================================================================
    -- BODY DIBUNGKUS xpcall: kalau ada error apapun saat load, teks
    -- error + nomor baris LANGSUNG tampil di layar (tidak hilang diam).
    -- ================================================================

    -- [1] PENGAMAN DASAR -----------------------------------------------
    local RunService = game:GetService("RunService")
    if not RunService:IsClient() then
        warn("[BALAP] GAGAL: harus jalan di CLIENT (executor / LocalScript), bukan server!")
        return
    end
    if not game:IsLoaded() then
        diagSet("menunggu game load... (nyangkut di sini = game belum selesai load)")
        game.Loaded:Wait()
    end
    local Players          = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local TweenService     = game:GetService("TweenService")
    local HttpService      = game:GetService("HttpService")
    local TeleportService  = game:GetService("TeleportService")
    local Lighting         = game:GetService("Lighting")
    local Workspace        = game:GetService("Workspace")
    diagSet("menunggu LocalPlayer...")
    local LocalPlayer = Players.LocalPlayer or Players:WaitForChild("LocalPlayer", 15)
    if not LocalPlayer then
        warn("[BALAP] GAGAL: LocalPlayer belum ada.")
        diagSet("GAGAL: LocalPlayer tidak ada (dapat nil)", Color3.fromRGB(239, 68, 68))
        return
    end
    diagSet("cek Terrain...")
    local Terrain = Workspace:FindFirstChildOfClass("Terrain") or Workspace:WaitForChild("Terrain", 10)
    if not Terrain then
        warn("[BALAP] Terrain tidak ketemu (10 dtk) — lanjut tanpa Terrain.")
        diagSet("Terrain tidak ketemu — lanjut tanpa Terrain")
    end

    -- ANTI DOUBLE-INSTANCE (TAKEOVER): eksekusi baru SELALU jalan & memasang
    -- token baru; instance lama melihat token berganti / GUI-nya dihapus ->
    -- unload sendiri (guard `if _G.__BALAP_MAIN__` lama bisa menolak versi
    -- baru diam-diam atau membiarkan 2 instance jalan bersamaan).
    local MY_TOKEN = {}
    _G.__BALAP_TOKEN__ = MY_TOKEN
    _G.__BALAP_MAIN__ = true  -- penanda lama, tetap dibersihkan unloadScript

    -- [2] KONFIGURASI ---------------------------------------------------
    -- Semua konstanta digabung ke dalam 1 table CFG untuk hemat local count
    -- (Luau limit 200 local per function)
    local CFG = {
        ICON_SIZE       = 36,
        TOGGLE_KEY      = Enum.KeyCode.G,
        LED_TEXT        = "⚡ B A L A P ⚡",
        SOUND_ON        = true,
        FX_LEVEL        = 1,
        -- Speed cycle 3 state (17.15 → 17.25 → 21.25 → balik OFF)
        SPEED_OFF   = 17.15,
        SPEED_ON_1  = 17.25,
        SPEED_ON_2  = 21.25,
        -- Jump: OFF 51.25 ⇄ ON 65.25 (kondisional UseJumpPower / JumpHeight)
        OFF_JUMP    = 51.25,
        ON_JUMP     = 65.25,
        OFF_JUMP_H  = 6.69,
        ON_JUMP_H   = 8.50,
        -- Moonwalk (F): putaran CEPAT + HENTAKAN — badan dibalikkan kencang
        --   lalu mengunci tegas di arah tujuan (bukan melayang lambat).
        --   MOON_TURN_MAX = kecepatan putar maks (rad/dtk). 12 = ±688°/dtk,
        --     putaran 180° selesai ±0.25 dtk. Lebih kencang? naikkan (mis. 15).
        --   MOON_SMOOTH = kekerasan kunci/pendaratan (makin besar makin hentak).
        --   Badan hanya berputar saat karakter BERGERAK; berdiri = diam total.
        MOON_TURN_MAX = 12,
        MOON_SMOOTH = 10,
        -- Shiftlock Tengah (v1.2.0): kamera persis di TENGAH karakter.
        -- v1.3.3: kamera TIDAK diubah sama sekali — yang digeser ke bawah cuma
        --         letak lingkaran kursornya (posisi diatur SLT_DOT_Y)
        SLT_WAKTU   = 0.25,  -- durasi transisi halus kamera (detik)
        SLT_DOT     = 7,     -- ukuran lingkaran kursor (px, mini biar ga ganggu)
        SLT_DOT_Y   = 0.60,  -- letak vertikal lingkaran: 0.5 = tengah layar,
        -- makin besar makin ke bawah (0.60 = bawah pinggang)
        -- Penanda Titik (tab TITIK, v1.3.0): tiang checkpoint + teleport
        TITIK_WARNA    = Color3.fromRGB(255, 200, 40), -- kuning neon tiang
        TITIK_TINGGI   = 1.5,   -- tinggi tiang (stud)
        TITIK_DIAMETER = 0.3,   -- diameter tiang (stud)
        TITIK_FILE     = "penanda_titik.json", -- sama dgn script standalone lama
        -- ☁ SINKRON (v1.3.5): TP + titik lintas device via textdb.dev
        -- (jsonblob.com diblokir Cloudflare untuk request executor -> 403)
        SYNC_FILE          = "BALAP_SYNC.json", -- kode sync + daftar hapus
        SYNC_URL           = "https://textdb.dev/api/data/", -- .. kode
        SYNC_TOMBSTONE_MAX = 200,   -- batas daftar hapus yang ikut disinkron
        SYNC_UNGGAH_JEDA   = 30,    -- dtk tunda upload setelah perubahan terakhir
        SYNC_UNDUH_TIAP    = 180,   -- dtk antar unduhan berkala (3 menit)
        TITIK_MAX          = 5000,  -- cap keras titik (praktis unlimited, anti crash)
        SWIM_BONUS         = 1.025, -- berenang + Shiftlock Tengah: speed aktif × 1.025
        -- UI RESPONSIF (v1.1): panel menyesuaikan ukuran layar otomatis.
        -- Layar besar -> panel tampil lebih besar (sampai UI_SCALE_MAX),
        -- layar kecil -> menyusut sendiri (sampai UI_SCALE_MIN) supaya
        -- tidak ada bagian panel/teks yang keluar dari layar.
        UI_LEBAR     = 360,  -- lebar dasar panel (px)
        UI_TINGGI    = 720,  -- tinggi dasar panel (px)
        UI_SCALE_MIN = 0.45, -- skala minimum (layar sangat kecil)
        UI_SCALE_MAX = 1.25, -- skala maksimum (layar besar = lebih besar)
        SND_PING   = "rbxasset://sounds/electronicpingshort.wav",
        SND_SNAP   = "rbxasset://sounds/snap.mp3",
    }
    -- shorthand alias untuk konstanta yang dipakai banyak (tetap hemat local)
    local Warna = {
        Ungu      = Color3.fromRGB(124, 58, 237),
        Ungu2     = Color3.fromRGB(167, 139, 250),
        UnguMuda  = Color3.fromRGB(237, 233, 254),
        Biru      = Color3.fromRGB(37, 99, 235),
        Biru2     = Color3.fromRGB(59, 130, 246),
        BiruMuda  = Color3.fromRGB(219, 234, 254),
        Hitam     = Color3.fromRGB(12, 10, 20),
        Hitam2    = Color3.fromRGB(22, 18, 38),
        Putih     = Color3.fromRGB(255, 255, 255),
        PutihLap  = Color3.fromRGB(250, 250, 255),
        AbuMuda   = Color3.fromRGB(243, 242, 250),
        AbuItem   = Color3.fromRGB(246, 245, 252),
        TeksGelap = Color3.fromRGB(28, 24, 46),
        AbuTeks   = Color3.fromRGB(130, 125, 155),
        AbuGelap  = Color3.fromRGB(160, 155, 185),
        Merah     = Color3.fromRGB(239, 68, 68),
        MerahMuda = Color3.fromRGB(254, 202, 202),
        Hijau     = Color3.fromRGB(34, 197, 94),
        Hijau2    = Color3.fromRGB(16, 185, 129),
        HijauMuda = Color3.fromRGB(187, 247, 208),
        Kuning    = Color3.fromRGB(250, 204, 21),
        Gray      = Color3.fromRGB(72, 72, 94),
        Card2     = Color3.fromRGB(40, 40, 62),
    }

    -- [3] FONT KOMPATIBEL -----------------------------------------------
    local FONT_OK = pcall(function()
        return Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Regular)
    end)

    -- cacheFont di-inline ke dalam closure fnt untuk hemat local count
    local fnt
    do
        local cache = {}
        fnt = function(k)
            if cache[k] then return cache[k] end
            local v
            if FONT_OK then
                local fam = {
                    judul = "rbxasset://fonts/families/Bangers.json",
                    bold  = "rbxasset://fonts/families/Montserrat.json",
                    semi  = "rbxasset://fonts/families/Montserrat.json",
                    med   = "rbxasset://fonts/families/Montserrat.json",
                    reg   = "rbxasset://fonts/families/Montserrat.json",
                }
                local wts = {
                    judul = Enum.FontWeight.Regular,
                    bold  = Enum.FontWeight.Bold,
                    semi  = Enum.FontWeight.SemiBold,
                    med   = Enum.FontWeight.Medium,
                    reg   = Enum.FontWeight.Regular,
                }
                v = Font.new(fam[k], wts[k])
            else
                local legacy = {
                    judul = Enum.Font.Bangers,
                    bold  = Enum.Font.GothamBold,
                    semi  = Enum.Font.GothamSemibold,
                    med   = Enum.Font.GothamMedium,
                    reg   = Enum.Font.Gotham,
                }
                v = legacy[k]
            end
            cache[k] = v
            return v
        end
    end

    -- [4] HELPER --------------------------------------------------------
    local rnd = math.random
    local function buat(class, props, parent)
        local obj = Instance.new(class)
        local isTextClass = (class == "TextLabel" or class == "TextButton" or class == "TextBox")
        for k, v in pairs(props) do
            if k == "FontFace" and isTextClass and not FONT_OK then
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
    local function angkaDari(teks)
        local v = tostring(teks):gsub(",", ".")
        return tonumber((v:gsub("[^%d%.]", "")))
    end
    local function clamp2(v) return math.floor(v * 100 + 0.5) / 100 end
    local function fmtNum(v)
        v = clamp2(v)
        if v % 1 == 0 then return tostring(math.floor(v)) end
        local s = string.format("%.2f", v)
        s = s:gsub("0+$", "")
        s = s:gsub("%.$", "")
        return s
    end
    -- format jarak utk daftar TP & titik (v1.3.4)
    local function fmtJarak(d)
        if d >= 1000 then return string.format("%.2fkm", d / 1000) end
        return string.format("%.1fm", d)
    end
    local function nomorBebas(prefix, daftarNama)
        local pakai = {}
        for _, nama in ipairs(daftarNama) do
            local n = tonumber(nama:match("^" .. prefix .. " (%d+)$"))
            if n then pakai[n] = true end
        end
        local n = 1
        while pakai[n] do n += 1 end
        return n
    end
    local function idBaru()
        return tostring(os.time()) .. "-" .. tostring(rnd(100000, 999999))
    end

    diagSet("dasar OK — siapkan helper GUI...")
    -- [4b] REGISTRY KONEKSI & FORWARD DECLARE ---------------------------
    local semuaKoneksi = {}
    local function catat(conn)
        table.insert(semuaKoneksi, conn)
        return conn
    end
    local function putuskan(conn)
        local i = table.find(semuaKoneksi, conn)
        if i then table.remove(semuaKoneksi, i) end
        pcall(function() conn:Disconnect() end)
    end
    local State = { Removed = false }
    local Original = {}
    local Setters, Switches = {}, {}
    local effGradients, effTweens = {}, {}   -- registry efek neon (internal FX)
    local setFeature, togglePanel, rejoin, unloadScript
    local applySpeed, applyJump, updateJumpLabel
    local RefreshSpeed, RefreshJump, JumpLabel, SpeedLabel
    local oLight, lightConn

    -- Forward declare untuk part3 (FX/footer/icon) — di-expose via buildFX()
    local konfeti, emojiBurst, pusatDiRoot, toast
    local kumpulkanFade, setFade, fadeVal
    -- Forward declare data TP + modul ☁ SINKRON (didefinisikan di [7a3])
    local TP_MAX, TP_FILE, TP_LOKASI, tpBisaFile
    local tpBulat, tpTulisFile, tpMuat, tpRefresh
    local syncTandai, syncCatatHapusTp, syncCatatHapusTiang
    local syncBuangHapusTp, syncBuangHapusTiang, syncRefreshKartu

    -- Forward declare untuk part2 (UI builder) — di-expose via buildUI()
    local tabBtns, kontenTabs, setTab
    local kontenMove, scrollMove
    local kontenTitik, scrollTitik
    local kontenTP, scrollTP
    local kontenSistem, scrollSistem
    setFeature = function(name, v, silent)
        local f = Setters[name]
        if f then f(v, silent) end
    end
    local function getChar() return LocalPlayer.Character end
    local function getHum()
        local c = getChar()
        return c and c:FindFirstChildOfClass("Humanoid")
    end
    local function getKarakter()
        local char = LocalPlayer.Character
        if not char then return nil end
        return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
    end

    -- [5] EFEK LED & UI HELPER ------------------------------------------
    local function ledSweep(inst, base, bandA, bandB, dur)
        local g = buat("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.00, base),
                ColorSequenceKeypoint.new(0.40, base),
                ColorSequenceKeypoint.new(0.47, bandA),
                ColorSequenceKeypoint.new(0.54, bandB),
                ColorSequenceKeypoint.new(0.61, base),
                ColorSequenceKeypoint.new(1.00, base),
            }),
            Offset = Vector2.new(-1, 0),
        }, inst)
        local tw = tween(g, TweenInfo.new(dur or 2.4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
        {Offset = Vector2.new(1, 0)})
        table.insert(effGradients, g)
        table.insert(effTweens, tw)
        return g
    end
    local function cycleColor(obj, prop, colors, interval)
        task.spawn(function()
            local i = 1
            while obj.Parent do
                tween(obj, TweenInfo.new(interval * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {[prop] = colors[i]})
                task.wait(interval)
                if not obj.Parent then break end
                i = i % #colors + 1
            end
        end)
    end
    local function buatDraggable(handle, target, onClickIfClick)
        local dragging, dragStart, startPos, jarak = false, nil, nil, 0
        catat(handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos, jarak = true, input.Position, target.Position, 0
            end
        end))
        catat(handle.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                if dragging and onClickIfClick and jarak < 6 then onClickIfClick() end
                dragging = false
            end
        end))
        catat(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                jarak = math.abs(delta.X) + math.abs(delta.Y)
                target.Position = UDim2.new(
                startPos.X.Scale, math.round(startPos.X.Offset + delta.X),
                startPos.Y.Scale, math.round(startPos.Y.Offset + delta.Y)
                )
            end
        end))
    end
    local function ripple(btn, warna)
        btn.ClipsDescendants = true
        local c = buat("Frame", {
            Name = "NoFade",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.fromOffset(8, 8),
            BackgroundColor3 = warna or Warna.Putih,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
        }, btn)
        buat("UICorner", {CornerRadius = UDim.new(1, 0)}, c)
        local target = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.4
        tween(c, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromOffset(target, target), BackgroundTransparency = 1})
        task.delay(0.5, function() c:Destroy() end)
    end
    local function efekTombol(btn, skalaHover)
        local s = buat("UIScale", {Scale = 1}, btn)
        local target = skalaHover or 1.06
        btn.MouseEnter:Connect(function()
            tween(s, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = target})
        end)
        btn.MouseLeave:Connect(function()
            tween(s, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
        end)
        btn.MouseButton1Down:Connect(function()
            tween(s, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = target * 0.9})
        end)
        btn.MouseButton1Up:Connect(function()
            tween(s, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = target})
        end)
    end
    local function sorotInput(box, stroke, rest)
        box.Focused:Connect(function()
            tween(stroke, TweenInfo.new(0.15), {Transparency = 0})
        end)
        box.FocusLost:Connect(function()
            tween(stroke, TweenInfo.new(0.2), {Transparency = rest})
        end)
    end
    local function gayaToggle(btn, on)
        btn.BackgroundColor3 = on and Warna.Hijau or Warna.Merah
        btn.BackgroundTransparency = on and 0.78 or 0.82
        btn.TextColor3 = on and Warna.HijauMuda or Warna.MerahMuda
    end

    -- [6] SCREENGUI -----------------------------------------------------
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BalapMain"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 9999
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() screenGui.OnTopOfCoreBlur = true end)
    local kandidatParent = {}
    pcall(function() if gethui then table.insert(kandidatParent, gethui()) end end)
    pcall(function() table.insert(kandidatParent, game:GetService("CoreGui")) end)
    pcall(function() table.insert(kandidatParent, LocalPlayer:WaitForChild("PlayerGui")) end)
    for _, t in ipairs(kandidatParent) do
        pcall(function()
            local lama = t:FindFirstChild("BalapMain")
            if lama then lama:Destroy() end
        end)
    end
    local terpasang = false
    for _, t in ipairs(kandidatParent) do
        local ok = pcall(function() screenGui.Parent = t end)
        if ok and screenGui.Parent == t then
            terpasang = true
            break
        end
    end
    if not terpasang then
        warn("[BALAP] GAGAL: tidak bisa memasang GUI.")
        return
    end
    local function bunyi(id, vol, pitch)
        if not CFG.SOUND_ON then return end
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume = vol or 0.35
        s.PlaybackSpeed = pitch or 1
        s.Parent = screenGui
        s:Play()
        task.delay(3, function() s:Destroy() end)
    end

    -- [7] BANGUN UI: ROOT + OUTER + PANEL -------------------------------
    local screenFx = buat("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 900,
    }, screenGui)
    -- screenFx akan di-akses lintas part (untuk FX overlay teleport)
    local root = buat("Frame", {
        Size = UDim2.fromOffset(CFG.UI_LEBAR, CFG.UI_TINGGI),
        Position = UDim2.new(0.5, 0, 0.10, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
    }, screenGui)
    local panelScale = buat("UIScale", {Scale = 1}, root)
    -- fitScale = skala otomatis "pas layar" (v1.1). Dihitung ulang tiap
    -- ukuran layar berubah (putar HP, resize jendela). panelScale tetap
    -- dipakai minimize/buka GUI, jadi keduanya saling mengali.
    local fitScale = buat("UIScale", {Scale = 1}, root)
    local function fitPanel()
        local cam = Workspace.CurrentCamera
        local vp = cam and cam.ViewportSize
        if not vp or vp.X <= 0 or vp.Y <= 0 then return end
        local s = math.min(
            (vp.X - 16) / CFG.UI_LEBAR,
            (vp.Y * 0.90 - 6) / CFG.UI_TINGGI
        )
        fitScale.Scale = math.clamp(s, CFG.UI_SCALE_MIN, CFG.UI_SCALE_MAX)
    end
    pcall(function()
        catat(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel))
    end)
    fitPanel()
    local outer = buat("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Warna.Hitam,
        BorderSizePixel = 0,
    }, root)
    buat("UICorner", {CornerRadius = UDim.new(0, 16)}, outer)
    local borderStroke = buat("UIStroke", {Color = Warna.Ungu, Thickness = 3}, outer)
    local borderGrad = buat("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Warna.Ungu),
            ColorSequenceKeypoint.new(0.25, Warna.Biru),
            ColorSequenceKeypoint.new(0.50, Warna.Ungu2),
            ColorSequenceKeypoint.new(0.75, Warna.Biru2),
            ColorSequenceKeypoint.new(1.00, Warna.Ungu),
        }),
    }, borderStroke)
    table.insert(effTweens, tween(borderGrad, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = 360}))
    local ring2Stroke = buat("UIStroke", {Color = Warna.Putih, Thickness = 1, Transparency = 0.45}, outer)
    local ring2Grad = buat("UIGradient", {Color = ColorSequence.new(Warna.Ungu2, Warna.Biru2)}, ring2Stroke)
    table.insert(effTweens, tween(ring2Grad, TweenInfo.new(3.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = -360}))
    local panel = buat("Frame", {
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundColor3 = Warna.PutihLap,
        BorderSizePixel = 0,
    }, outer)
    buat("UICorner", {CornerRadius = UDim.new(0, 11)}, panel)
    buat("UIStroke", {Color = Warna.UnguMuda, Thickness = 1, Transparency = 0.35}, panel)
    ledSweep(panel, Warna.PutihLap, Warna.Putih, Warna.BiruMuda, 5)
    local partBox = buat("Frame", {
        Name = "NoFade",
        Position = UDim2.new(0, 4, 0, 50),
        Size = UDim2.new(1, -8, 1, -84),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, panel)
    for i = 1, 3 do
        local stripe = buat("Frame", {
            Name = "NoFade",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.3 * i, 0, 0.5, 0),
            Size = UDim2.fromOffset(26, 580),
            Rotation = 24,
            BackgroundColor3 = i % 2 == 0 and Warna.UnguMuda or Warna.BiruMuda,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
        }, partBox)
        table.insert(effTweens, tween(stripe, TweenInfo.new(6 + i * 2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true),
        {Position = UDim2.new(0.3 * i + 0.25, 0, 0.5, 0)}))
    end
    local header = buat("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Warna.Hitam2,
        BorderSizePixel = 0,
        Active = true,
    }, panel)
    buat("UICorner", {CornerRadius = UDim.new(0, 11)}, header)
    buat("Frame", {
        Size = UDim2.new(1, 0, 0, 11),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = Warna.Hitam2,
        BorderSizePixel = 0,
    }, panel)
    local title = buat("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -104, 1, 0),
        FontFace = fnt("judul"),
        Text = "⚡ BALAP v1.5 ⚡",
        TextColor3 = Warna.Putih,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, header)
    ledSweep(title, Warna.Putih, Warna.Ungu2, Warna.Biru2, 2.2)
    local titleGlow = buat("UIStroke", {Name = "NoFade", Color = Warna.Ungu2, Thickness = 1, Transparency = 0.35}, title)
    task.spawn(function()
        while title.Parent do
            tween(titleGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.75})
            task.wait(0.8)
            if not title.Parent then break end
            tween(titleGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.35})
            task.wait(0.8)
        end
    end)
    local minBtn = buat("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -40, 0.5, -14),
        BackgroundColor3 = Warna.Hitam,
        BorderSizePixel = 0,
        FontFace = fnt("bold"),
        Text = "–",
        TextColor3 = Warna.Putih,
        TextSize = 18,
        AutoButtonColor = false,
    }, header)
    buat("UICorner", {CornerRadius = UDim.new(0, 9)}, minBtn)
    buat("UIStroke", {Color = Warna.Ungu, Thickness = 1, Transparency = 0.3}, minBtn)
    local accent = buat("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 0, 46),
        BorderSizePixel = 0,
    }, panel)
    ledSweep(accent, Warna.Biru, Warna.Putih, Warna.Ungu2, 2.6)
    -- ☁ mini di header: warna = status sinkron, klik = buka tab SYSTEM
    local btnCloud = buat("TextButton", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(1, -72, 0.5, -12),
        BackgroundTransparency = 1,
        FontFace = fnt("bold"),
        Text = "☁",
        TextColor3 = Warna.AbuGelap,
        TextSize = 15,
        AutoButtonColor = false,
    }, header)
    btnCloud.MouseButton1Click:Connect(function()
        ripple(btnCloud, Warna.Ungu2)
        setTab(4)
    end)

    -- [7a2] MODUL PENANDA TITIK (tab TITIK, v1.3.0) ---------------------
    -- Port standalone "PENANDA TITIK" ke dalam GUI BALAP:
    --   • Tiang neon kuning polos TANPA nomor, nempel tanah (raycast ke bawah)
    --   • Daftar titik: klik = teleport, X = hapus titik itu
    --   • TERSIMPAN PERMANEN: writefile penanda_titik.json (nama file SAMA
    --     dgn script lama -> titik lama otomatis kebaca). Executor tanpa
    --     writefile -> cadangan getgenv (selamat saat re-execute).
    --   • Tiang bisa hide/show via switch "Tampilkan Tiang"
    local titikList       = {}
    local titikFolder     = nil   -- Folder berisi tiang di Workspace
    local titikHolder     = nil   -- frame daftar titik di tab TITIK (di-buildUI)
    local titikLabelJumlah = nil
    local titikRefreshDaftar -- forward declare (didefinisikan di bawah)
    local titikBisaFile   = (type(writefile) == "function") and (type(readfile) == "function")
    and (type(isfile) == "function")

    local function titikSimpan()
        getgenv().BALAP_TITIK_DATA = titikList        -- cadangan sesi (re-execute)
        if not titikBisaFile then return false end
        local data = {}
        for i = 1, #titikList do
            local p = titikList[i]
            data[i] = { x = p.X, y = p.Y, z = p.Z }
        end
        local ok, err = pcall(function()
            writefile(CFG.TITIK_FILE, HttpService:JSONEncode(data))
        end)
        if not ok then warn("[BALAP-TITIK] gagal simpan: " .. tostring(err)) return false end
        return true
    end

    local function titikMuat()
        local data, ada = nil, false
        if titikBisaFile then
            pcall(function() ada = isfile(CFG.TITIK_FILE) end)
            if ada then
                local ok, isi = pcall(readfile, CFG.TITIK_FILE)
                if ok and type(isi) == "string" then
                    pcall(function() data = HttpService:JSONDecode(isi) end)
                end
            end
        end
        if not data then
            data = rawget(getgenv(), "BALAP_TITIK_DATA")  -- fallback: sesi yang sama
        end
        if type(data) == "table" then
            for _, e in ipairs(data) do
                if type(e) == "table" and e.x and e.y and e.z then
                    titikList[#titikList + 1] = Vector3.new(e.x, e.y, e.z)
                end
            end
        end
        getgenv().BALAP_TITIK_DATA = titikList
        print("[BALAP-TITIK] muat " .. #titikList .. " titik"
        .. (titikBisaFile and " (file: " .. CFG.TITIK_FILE .. ")" or " (mode SESI — executor tanpa writefile)"))
    end

    local function titikBuatTiang(index, pos)
        buat("Part", {
            Name = "Titik_" .. index,
            Shape = Enum.PartType.Cylinder,
            Size = Vector3.new(CFG.TITIK_TINGGI, CFG.TITIK_DIAMETER, CFG.TITIK_DIAMETER),
            CFrame = CFrame.new(pos.X, pos.Y + CFG.TITIK_TINGGI / 2, pos.Z)
            * CFrame.Angles(0, 0, math.rad(90)),
            Anchored = true,
            CanCollide = false,
            CanTouch = false,
            CanQuery = false,
            CastShadow = false,
            Material = Enum.Material.Neon,
            Color = CFG.TITIK_WARNA,
        }, titikFolder)
        -- v1.3.1: TANPA nomor — muncul tiang polos saja
    end

    -- render ulang semua tiang (dipakai juga Setters.Tiang saat toggle)
    local function titikRender()
        if titikFolder then titikFolder:Destroy() titikFolder = nil end
        if not State.TiangOn then return end
        if #titikList == 0 then return end
        titikFolder = Instance.new("Folder")
        titikFolder.Name = "BALAP_TitikPenanda"
        titikFolder.Parent = Workspace
        for i, pos in ipairs(titikList) do
            titikBuatTiang(i, pos)
        end
    end

    local function titikTeleport(pos)
        local char = getChar()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then toast("Karakter tidak ketemu!", Warna.Merah) return end
        bunyi(CFG.SND_PING, 0.3, 1.1)
        hrp.CFrame = CFrame.new(pos.X, pos.Y + 3.5, pos.Z)
    end

    local function titikTambahDiSini()
        local char = getChar()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then toast("Karakter tidak ketemu!", Warna.Merah) return end
        if #titikList >= CFG.TITIK_MAX then
            toast("Penuh (max " .. CFG.TITIK_MAX .. " titik)", Warna.Kuning)
            return
        end
        -- cari tanah di bawah kaki biar tiang nempel lantai
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { char }
        local hit = Workspace:Raycast(hrp.Position, Vector3.new(0, -100, 0), params)
        local groundY = hit and hit.Position.Y or (hrp.Position.Y - 3)
        local pos = Vector3.new(clamp2(hrp.Position.X), clamp2(groundY), clamp2(hrp.Position.Z))
        -- anti titik kembar (v1.3.4): ada titik < 1 stud -> tolak
        for _, p in ipairs(titikList) do
            local dx, dy, dz = p.X - pos.X, p.Y - pos.Y, p.Z - pos.Z
            if dx*dx + dy*dy + dz*dz < 1 then
                toast("titik sudah ada di sini", Warna.Kuning)
                return
            end
        end
        syncBuangHapusTiang(pos)   -- titik dipasang lagi -> hapus tombstone lamanya
        titikList[#titikList + 1] = pos
        titikSimpan()
        titikRender()
        titikRefreshDaftar()
        syncTandai()
        toast("+ Titik #" .. #titikList .. " ditambahkan"
        .. (titikBisaFile and " (tersimpan)" or " (sesi saja)"), Warna.Hijau)
    end

    local function titikHapusSemua()
        if #titikList == 0 then toast("Belum ada titik", Warna.Kuning) return end
        for _, p in ipairs(titikList) do syncCatatHapusTiang(p) end  -- tombstone ikut sync
        table.clear(titikList)
        titikSimpan()
        titikRender()
        titikRefreshDaftar()
        syncTandai()
        toast("Semua titik dihapus", Warna.Merah)
    end

    -- gambar ulang daftar titik di tab TITIK (v1.3.4: + jarak & sync)
    titikRefreshDaftar = function()
        if not titikHolder then return end
        for _, c in ipairs(titikHolder:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        local char = getChar()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        for i, pos in ipairs(titikList) do
            local idx = i
            local item = buat("TextButton", {
                Name = "TitikItem_" .. idx,
                Size = UDim2.new(1, -6, 0, 26),
                BackgroundColor3 = Warna.AbuItem,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = idx,
            }, titikHolder)
            buat("UICorner", {CornerRadius = UDim.new(0, 6)}, item)
            efekTombol(item, 1.02)
            local teks
            if hrp then
                teks = ("%d.  (%s)  (%.1f, %.1f, %.1f)"):format(
                idx, fmtJarak((pos - hrp.Position).Magnitude), pos.X, pos.Y, pos.Z)
            else
                teks = ("%d.  (%.1f, %.1f, %.1f)"):format(idx, pos.X, pos.Y, pos.Z)
            end
            local lbl = buat("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 8, 0, 0),
                Size = UDim2.new(1, -40, 1, 0),
                FontFace = fnt("med"),
                TextScaled = true,
                TextColor3 = Warna.TeksGelap,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = teks,
            }, item)
            buat("UITextSizeConstraint", {MaxTextSize = 13}, lbl)
            local hx = buat("TextButton", {
                Size = UDim2.new(0, 22, 0, 22),
                Position = UDim2.new(1, -26, 0.5, -11),
                BackgroundColor3 = Warna.Merah,
                FontFace = fnt("bold"),
                TextSize = 12,
                TextColor3 = Warna.Putih,
                Text = "X",
                AutoButtonColor = false,
            }, item)
            buat("UICorner", {CornerRadius = UDim.new(0, 6)}, hx)
            hx.MouseButton1Click:Connect(function()
                syncCatatHapusTiang(pos)   -- tombstone: hapusan tidak bangkit dari cloud
                table.remove(titikList, idx)
                titikSimpan()
                titikRender()
                titikRefreshDaftar()
                syncTandai()
                toast("Titik " .. idx .. " dihapus", Warna.Merah)
            end)
            item.MouseButton1Click:Connect(function()
                titikTeleport(pos)
            end)
        end
        if titikLabelJumlah then
            titikLabelJumlah.Text = ("Total: %d titik • klik item = teleport"):format(#titikList)
        end
        syncRefreshKartu()
    end

    -- [7a3] DATA TP + MODUL ☁ SINKRON (v1.3.4) ---------------------------
    -- Data TP dipindah keluar buildUI supaya modul sync bisa mengaksesnya.
    TP_MAX     = 40
    TP_FILE    = "BALAP_TP.json"
    TP_LOKASI  = {}
    tpBisaFile = (type(writefile) == "function") and (type(readfile) == "function")

    tpBulat = function(v)
        return math.floor(v * 100 + 0.5) / 100
    end

    tpTulisFile = function()
        getgenv().BALAP_TP_DATA = TP_LOKASI            -- cadangan sesi (re-execute)
        if not tpBisaFile then return end
        local data = {}
        for i = 1, #TP_LOKASI do
            local L = TP_LOKASI[i]
            data[i] = { nama = L.nama, x = tpBulat(L.x), y = tpBulat(L.y), z = tpBulat(L.z) }
        end
        local ok, err = pcall(function()
            writefile(TP_FILE, HttpService:JSONEncode(data))
        end)
        if not ok then warn("[BALAP-TP] gagal tulis file: " .. tostring(err)) end
    end

    tpMuat = function()
        local data
        if tpBisaFile then
            local ada = false
            pcall(function() ada = isfile(TP_FILE) end)
            if ada then
                pcall(function() data = HttpService:JSONDecode(readfile(TP_FILE)) end)
            end
        end
        if type(data) ~= "table" then
            data = rawget(getgenv(), "BALAP_TP_DATA")   -- fallback: sesi yang sama
        end
        if type(data) == "table" then
            for _, v in ipairs(data) do
                if type(v) == "table" and type(v.nama) == "string" and #v.nama > 0
                    and type(v.x) == "number" and type(v.y) == "number" and type(v.z) == "number" then
                    TP_LOKASI[#TP_LOKASI + 1] = { nama = v.nama, x = v.x, y = v.y, z = v.z }
                end
            end
        end
        getgenv().BALAP_TP_DATA = TP_LOKASI
        print("[BALAP-TP] muat " .. #TP_LOKASI .. " lokasi"
        .. (tpBisaFile and " (file: " .. TP_FILE .. ")" or " (mode SESI — executor tanpa writefile)"))
    end
    tpMuat()

    -- ======================================================================
    -- ☁ SINKRON (v1.3.5) — TP + titik lintas device
    -- Layanan : textdb.dev — gratis, tanpa login, TANPA blokir executor.
    --           (jsonblob.com diblokir Cloudflare utk request executor ->
    --           selalu 403; itulah sebabnya v1.3.4 gagal membentuk kode)
    -- Kode    : balap-xxxx-xxxx — dibaca manusia, mudah diketik. Selalu
    --           tampil di kartu ☁ SINKRON (tab TITIK) + tombol SALIN.
    --           Device lain bergabung lewat MASUKKAN KODE. GANTI KODE =
    --           loker baru.
    -- Isi sync: HANYA titik tiang + TP (pengaturan tidak ikut).
    -- Merge   : TP per nama (nama sama = posisi di-update) • titik per
    --           posisi (< 1 stud = kembar, ditolak) • DAFTAR HAPUS ikut
    --           tersinkron (max 200) — hapusan tidak bangkit lagi.
    -- Ritme   : upload ditunda 30 dtk setelah perubahan terakhir •
    --           download saat load + tiap 3 menit • anti ping-pong.
    -- Offline : diam + toast sekali, data aman di lokal, retry otomatis.
    -- File    : BALAP_SYNC.json (kode + daftar hapus, tersimpan permanen).
    -- ======================================================================
    local SYNC = {
        kode          = nil,   -- ID loker (contoh: balap-7k2m-9xq4)
        hapus         = {},    -- tombstone: {t="tp", n=nama} / {t="tiang", x,y,z}
        bisaHttp      = false,
        sibuk         = false, -- mutex: cuma 1 operasi jaringan
        pending       = false, -- ada perubahan menunggu diunggah
        status        = "load",-- load | ok | kirim | terima | offline
        labelPerangkat = "",
        lastDari      = "",    -- device pengirim terakhir (dari cloud)
        lastPayload   = nil,   -- teks payload terakhir (anti ping-pong)
        waktuUbah     = 0,
        waktuUnduh    = 0,
        waktuCoba     = 0,
        offSudahToast = false,
        kosongSudah   = false, -- toast "loker kosong" cukup sekali
        ui            = nil,   -- diisi buildUI (kartu status)
    }

    -- label perangkat: "PC (NamaRoblox)" / "HP (NamaRoblox)"
    do
        local hp = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
        SYNC.labelPerangkat = (hp and "HP" or "PC") .. " (" .. tostring(LocalPlayer.Name or "?") .. ")"
    end

    -- deteksi fungsi HTTP executor (bertingkat; BUKAN HttpService Roblox
    -- jadi tidak kelihatan oleh server game)
    local syncReq = nil
    do
        local kandidat = {
            function() if type(request) == "function" then return request end end,
            function() if type(http_request) == "function" then return http_request end end,
            function() if type(syn) == "table" and type(syn.request) == "function" then return syn.request end end,
            function() if type(http) == "table" and type(http.request) == "function" then return http.request end end,
        }
        for _, c in ipairs(kandidat) do
            local ok, f = pcall(c)
            if ok and type(f) == "function" then
                syncReq = f
                break
            end
        end
    end
    SYNC.bisaHttp = (syncReq ~= nil)
    if not SYNC.bisaHttp then
        print("[BALAP-SYNC] executor tidak punya HTTP request — sinkron nonaktif (fitur lain normal)")
    end

    -- ---- file BALAP_SYNC.json: kode + daftar hapus ----
    local function syncSimpanFile()
        getgenv().BALAP_SYNC_DATA = { kode = SYNC.kode, hapus = SYNC.hapus }
        if not titikBisaFile then return end
        pcall(function()
            writefile(CFG.SYNC_FILE, HttpService:JSONEncode({
                kode  = SYNC.kode,
                hapus = SYNC.hapus,
                dari  = SYNC.labelPerangkat,
                waktu = os.time(),
            }))
        end)
    end

    local function syncMuatFile()
        local data
        if titikBisaFile then
            local ada = false
            pcall(function() ada = isfile(CFG.SYNC_FILE) end)
            if ada then
                pcall(function() data = HttpService:JSONDecode(readfile(CFG.SYNC_FILE)) end)
            end
        end
        if type(data) ~= "table" then
            data = rawget(getgenv(), "BALAP_SYNC_DATA")
        end
        if type(data) == "table" then
            if type(data.kode) == "string" then
                local k = data.kode:lower()
                if k:match("^%d+$") then
                    -- kode lama v1.3.4 (jsonblob, sudah mati) -> abaikan
                elseif #k >= 6 and #k <= 40 and k:match("^[a-z0-9%-]+$") then
                    SYNC.kode = k
                end
            end
            if type(data.hapus) == "table" then
                for _, h in ipairs(data.hapus) do
                    if type(h) == "table" and h.t == "tp" and type(h.n) == "string" and #h.n > 0 then
                        SYNC.hapus[#SYNC.hapus + 1] = { t = "tp", n = h.n }
                    elseif type(h) == "table" and h.t == "tiang"
                        and type(h.x) == "number" and type(h.y) == "number" and type(h.z) == "number" then
                        SYNC.hapus[#SYNC.hapus + 1] = { t = "tiang", x = h.x, y = h.y, z = h.z }
                    end
                end
            end
        end
        print("[BALAP-SYNC] muat file: kode=" .. tostring(SYNC.kode or "-")
        .. " • daftar hapus=" .. #SYNC.hapus)
    end
    syncMuatFile()

    -- ---- daftar hapus (tombstone) ----
    local function syncPotongHapus()
        while #SYNC.hapus > CFG.SYNC_TOMBSTONE_MAX do
            table.remove(SYNC.hapus, 1)   -- buang yang tertua
        end
    end
    local function syncHapusTpAda(nama)
        for _, h in ipairs(SYNC.hapus) do
            if h.t == "tp" and h.n == nama then return true end
        end
        return false
    end
    -- titik dianggap terhapus kalau ada tombstone < 1 stud darinya
    local function syncHapusTiangAda(px, py, pz)
        for _, h in ipairs(SYNC.hapus) do
            if h.t == "tiang" then
                local dx, dy, dz = h.x - px, h.y - py, h.z - pz
                if dx*dx + dy*dy + dz*dz < 1 then return true end
            end
        end
        return false
    end
    syncCatatHapusTp = function(nama)
        if syncHapusTpAda(nama) then return end
        SYNC.hapus[#SYNC.hapus + 1] = { t = "tp", n = nama }
        syncPotongHapus()
    end
    syncCatatHapusTiang = function(pos)
        if syncHapusTiangAda(pos.X, pos.Y, pos.Z) then return end
        SYNC.hapus[#SYNC.hapus + 1] = { t = "tiang", x = clamp2(pos.X), y = clamp2(pos.Y), z = clamp2(pos.Z) }
        syncPotongHapus()
    end
    syncBuangHapusTp = function(nama)
        for i = #SYNC.hapus, 1, -1 do
            local h = SYNC.hapus[i]
            if h.t == "tp" and h.n == nama then table.remove(SYNC.hapus, i) end
        end
    end
    syncBuangHapusTiang = function(pos)
        for i = #SYNC.hapus, 1, -1 do
            local h = SYNC.hapus[i]
            if h.t == "tiang" then
                local dx, dy, dz = h.x - pos.X, h.y - pos.Y, h.z - pos.Z
                if dx*dx + dy*dy + dz*dz < 1 then table.remove(SYNC.hapus, i) end
            end
        end
    end

    -- ---- kartu status (UI dibangun di buildUI) ----
    syncRefreshKartu = function()
        local ui = SYNC.ui
        if not ui then return end
        local warna = Warna.AbuGelap
        if SYNC.status == "ok" then warna = Warna.Hijau2
        elseif SYNC.status == "kirim" or SYNC.status == "terima" then warna = Warna.Kuning end
        if ui.dot then ui.dot.BackgroundColor3 = warna end
        if ui.ikon then ui.ikon.TextColor3 = warna end
        if ui.info then
            if not SYNC.bisaHttp then
                ui.info.Text = ("%d TP • %d titik • executor tanpa HTTP — sync nonaktif")
                :format(#TP_LOKASI, #titikList)
            else
                local kodeTeks = SYNC.kode and ("Kode: " .. SYNC.kode) or "Kode: belum dibuat"
                ui.info.Text = ("%d TP • %d titik • %s"):format(#TP_LOKASI, #titikList, kodeTeks)
            end
        end
        if ui.dari then
            if SYNC.lastDari ~= "" then
                ui.dari.Text = "terakhir disimpan dari: " .. SYNC.lastDari
            elseif SYNC.kode then
                ui.dari.Text = "cloud siap — salin kode ke device lain"
            else
                ui.dari.Text = "menyambung ke cloud (butuh internet)..."
            end
        end
    end

    local function syncSetStatus(s)
        SYNC.status = s
        if s == "offline" then
            if not SYNC.offSudahToast then
                SYNC.offSudahToast = true
                toast("☁ offline — data aman di lokal", Warna.Kuning)
            end
        else
            SYNC.offSudahToast = false
        end
        syncRefreshKartu()
    end

    syncTandai = function()
        syncSimpanFile()               -- tombstone langsung aman di file
        SYNC.pending = true
        SYNC.waktuUbah = os.clock()
        SYNC.status = "kirim"
        syncRefreshKartu()
    end

    -- ---- payload & validasi ----
    local function syncPayload()
        local tp = {}
        for i = 1, #TP_LOKASI do
            local L = TP_LOKASI[i]
            tp[i] = { n = L.nama, x = tpBulat(L.x), y = tpBulat(L.y), z = tpBulat(L.z) }
        end
        local tg = {}
        for i = 1, #titikList do
            local p = titikList[i]
            tg[i] = { x = clamp2(p.X), y = clamp2(p.Y), z = clamp2(p.Z) }
        end
        return {
            v     = 1,
            tp    = tp,
            tiang = tg,
            hapus = SYNC.hapus,
            dari  = SYNC.labelPerangkat,
            waktu = os.time(),
        }
    end

    -- validasi struktur data cloud (anti sabotase — kode bisa tersebar)
    local function syncValidasi(data)
        if type(data) ~= "table" or data.v ~= 1 then return nil end
        if type(data.tp) ~= "table" or type(data.tiang) ~= "table"
            or type(data.hapus) ~= "table" then return nil end
        local function num(v)
            return type(v) == "number" and v == v and math.abs(v) < 100000
        end
        local tp = {}
        for _, e in ipairs(data.tp) do
            if type(e) == "table" and type(e.n) == "string" and #e.n > 0 and #e.n <= 60
                and num(e.x) and num(e.y) and num(e.z) then
                tp[#tp + 1] = { n = e.n, x = e.x, y = e.y, z = e.z }
            end
        end
        local tg = {}
        for _, e in ipairs(data.tiang) do
            if type(e) == "table" and num(e.x) and num(e.y) and num(e.z) then
                tg[#tg + 1] = { x = e.x, y = e.y, z = e.z }
            end
        end
        local hp = {}
        for _, e in ipairs(data.hapus) do
            if type(e) == "table" and e.t == "tp" and type(e.n) == "string" and #e.n > 0 and #e.n <= 60 then
                hp[#hp + 1] = { t = "tp", n = e.n }
            elseif type(e) == "table" and e.t == "tiang" and num(e.x) and num(e.y) and num(e.z) then
                hp[#hp + 1] = { t = "tiang", x = e.x, y = e.y, z = e.z }
            end
        end
        if #tp > 5000 or #tg > 5000 or #hp > 500 then return nil end
        return {
            tp = tp, tiang = tg, hapus = hp,
            dari  = type(data.dari) == "string" and data.dari:sub(1, 60) or "?",
            waktu = tonumber(data.waktu) or 0,
        }
    end

    -- ---- merge cloud -> lokal (dipakai saat unduh & sebelum unggah) ----
    local function syncMerge(cloud)
        local nTambahTp, nUpdateTp, nTambahTg, nHapusTp, nHapusTg = 0, 0, 0, 0, 0
        local hapusSebelum = #SYNC.hapus
        -- 1) gabungkan daftar hapus (union dua arah)
        for _, h in ipairs(cloud.hapus) do
            if h.t == "tp" then
                if not syncHapusTpAda(h.n) then SYNC.hapus[#SYNC.hapus + 1] = h end
            else
                if not syncHapusTiangAda(h.x, h.y, h.z) then SYNC.hapus[#SYNC.hapus + 1] = h end
            end
        end
        syncPotongHapus()
        -- 2) terapkan hapusan ke data lokal
        for i = #TP_LOKASI, 1, -1 do
            if syncHapusTpAda(TP_LOKASI[i].nama) then
                table.remove(TP_LOKASI, i)
                nHapusTp += 1
            end
        end
        for i = #titikList, 1, -1 do
            if syncHapusTiangAda(titikList[i].X, titikList[i].Y, titikList[i].Z) then
                table.remove(titikList, i)
                nHapusTg += 1
            end
        end
        -- 3) terima data cloud yang lolos daftar hapus
        for _, c in ipairs(cloud.tp) do
            if not syncHapusTpAda(c.n) then
                local ketemu = false
                for _, L in ipairs(TP_LOKASI) do
                    if L.nama == c.n then
                        ketemu = true
                        if tpBulat(L.x) ~= tpBulat(c.x) or tpBulat(L.y) ~= tpBulat(c.y)
                            or tpBulat(L.z) ~= tpBulat(c.z) then
                            L.x, L.y, L.z = c.x, c.y, c.z   -- nama sama = posisi di-update
                            nUpdateTp += 1
                        end
                        break
                    end
                end
                if not ketemu and #TP_LOKASI < TP_MAX then
                    TP_LOKASI[#TP_LOKASI + 1] = { nama = c.n, x = c.x, y = c.y, z = c.z }
                    nTambahTp += 1
                end
            end
        end
        for _, c in ipairs(cloud.tiang) do
            if not syncHapusTiangAda(c.x, c.y, c.z) then
                local kembar = false
                for _, p in ipairs(titikList) do
                    local dx, dy, dz = p.X - c.x, p.Y - c.y, p.Z - c.z
                    if dx*dx + dy*dy + dz*dz < 1 then
                        kembar = true
                        break
                    end
                end
                if not kembar and #titikList < CFG.TITIK_MAX then
                    titikList[#titikList + 1] = Vector3.new(c.x, c.y, c.z)
                    nTambahTg += 1
                end
            end
        end
        -- 4) simpan & gambar ulang bila ada yang berubah
        local berubah = nTambahTp + nUpdateTp + nTambahTg + nHapusTp + nHapusTg
        + (#SYNC.hapus - hapusSebelum)
        if berubah > 0 then
            titikSimpan()
            tpTulisFile()
            titikRender()
            titikRefreshDaftar()
            tpRefresh()
        end
        return berubah, {
            tambahTp = nTambahTp, updateTp = nUpdateTp, tambahTg = nTambahTg,
            hapusTp = nHapusTp, hapusTg = nHapusTg,
        }
    end

    local function syncRingkas(d)
        local b = {}
        if d.tambahTg > 0 then b[#b + 1] = "+" .. d.tambahTg .. " titik" end
        if d.tambahTp > 0 then b[#b + 1] = "+" .. d.tambahTp .. " TP" end
        if d.updateTp > 0 then b[#b + 1] = d.updateTp .. " TP diperbarui" end
        if d.hapusTp + d.hapusTg > 0 then b[#b + 1] = (d.hapusTp + d.hapusTg) .. " terhapus" end
        return table.concat(b, ", ")
    end

    -- ---- HTTP wrapper (format beda-beda antar executor) ----
    local function syncHttp(method, url, body)
        if not syncReq then return nil end
        local opts = {
            Url     = url,
            Method  = method,
            Headers = {
                -- textdb.dev: tulis = form, baca = biasa
                ["Content-Type"] = body and "application/x-www-form-urlencoded"
                or "text/plain",
                -- UA netral: beberapa jaringan menolak request tanpa User-Agent
                ["User-Agent"]   = "Mozilla/5.0 (BALAP v1.3.5)",
            },
        }
        if body then opts.Body = body end
        local ok, resp = pcall(syncReq, opts)
        if not ok or type(resp) ~= "table" then return nil end
        return {
            code    = tonumber(resp.StatusCode or resp.code or resp.Code or resp.status),
            body    = resp.Body or resp.body,
            headers = resp.Headers or resp.headers or {},
        }
    end

    -- textdb.dev: tulis = POST "__data=<json>" (form), baca = GET balik
    -- teks "__data=<json>" juga. Kode %XX biar aman lewat parser form
    -- (sudah diuji: payload 320KB lolos 100% utuh).
    local function syncUrlEncode(s)
        return (s:gsub("[^%w%-_%.~]", function(c)
            return string.format("%%%02X", string.byte(c))
        end))
    end

    local function syncBodyForm(teks)
        return "__data=" .. syncUrlEncode(teks)
    end

    -- kode baru: balap-xxxx-xxxx — tanpa o/0/i/l biar tidak ketukar
    local function syncKodeBaru()
        local abjad = "abcdefghjkmnpqrstuvwxyz23456789"
        local function rnd4()
            local a = {}
            for _ = 1, 4 do
                local n = math.random(#abjad)
                a[#a + 1] = abjad:sub(n, n)
            end
            return table.concat(a)
        end
        return "balap-" .. rnd4() .. "-" .. rnd4()
    end

    -- isi loker dari balasan GET: buang awalan "__data=" (7 karakter)
    local function syncIsiDariBody(body)
        if type(body) ~= "string" then return nil end
        local isi = body:match("^%s*__data=(.-)%s*$")
        if isi == nil then isi = body:gsub("^%s+", ""):gsub("%s+$", "") end
        return isi
    end

    -- ambil + validasi isi loker:
    --   tabel  = data siap merge
    --   "kosong" = kode ada tapi belum ada isinya
    --   "rusak"  = isinya bukan data BALAP
    --   nil      = jaringan / layanan gagal
    local function syncAmbilCloud(kode)
        local hasil = syncHttp("GET", CFG.SYNC_URL .. kode)
        if not (hasil and hasil.code == 200) then return nil end
        local isi = syncIsiDariBody(hasil.body)
        if isi == nil then return nil end
        if isi == "" then return "kosong" end
        local data
        pcall(function() data = HttpService:JSONDecode(isi) end)
        return data and syncValidasi(data) or "rusak"
    end

    -- buat loker baru (device pertama kali / belum punya kode)
    local function syncBuatLoker()
        if SYNC.sibuk or State.Removed or SYNC.kode then return end
        SYNC.sibuk = true
        SYNC.status = "kirim"
        syncRefreshKartu()
        local teks = HttpService:JSONEncode(syncPayload())
        local kode = syncKodeBaru()   -- kode dipilih sendiri, langsung dipakai
        local hasil = syncHttp("POST", CFG.SYNC_URL .. kode, syncBodyForm(teks))
        if hasil and (hasil.code == 200 or hasil.code == 201) then
            SYNC.kode = kode
            SYNC.lastPayload = teks
            SYNC.pending = false
            SYNC.lastDari = SYNC.labelPerangkat
            SYNC.waktuUnduh = os.clock()
            syncSimpanFile()
            syncSetStatus("ok")
            toast("☁ Loker cloud siap — kode: " .. kode, Warna.Hijau)
            print("[BALAP-SYNC] loker dibuat: " .. kode)
        else
            SYNC.waktuCoba = os.clock()
            syncSetStatus("offline")
        end
        SYNC.sibuk = false
    end

    -- unduh + merge (dipanggil saat load & tiap 3 menit)
    local function syncUnduh()
        if SYNC.sibuk or State.Removed or not SYNC.kode then return end
        SYNC.sibuk = true
        SYNC.status = "terima"
        syncRefreshKartu()
        local sukses = false
        local cloud = syncAmbilCloud(SYNC.kode)
        if cloud == "kosong" then
            -- loker ada tapi belum berisi -> tandai biar diisi data lokal
            if not SYNC.kosongSudah then
                SYNC.kosongSudah = true
                toast("☁ loker kosong — data device ini akan diunggah", Warna.Kuning)
            end
            SYNC.pending = true
            sukses = true
        elseif type(cloud) == "table" then
            SYNC.lastDari = cloud.dari
            local berubah, rincian = syncMerge(cloud)
            if berubah > 0 then
                toast("☁ dari cloud: " .. syncRingkas(rincian), Warna.Biru)
                syncTandai()   -- tombstone gabungan diunggah balik sekali
            end
            sukses = true
        elseif cloud == "rusak" then
            SYNC.offSudahToast = true   -- toast offline kembar tidak perlu
            toast("☁ data cloud tidak valid — diabaikan", Warna.Merah)
        end
        if sukses then
            syncSetStatus(SYNC.pending and "kirim" or "ok")
        else
            syncSetStatus("offline")
        end
        SYNC.waktuUnduh = sukses and os.clock()
        or (os.clock() - CFG.SYNC_UNDUH_TIAP + 20)   -- gagal: coba lagi 20 dtk
        SYNC.sibuk = false
    end

    -- unggah = unduh -> merge -> POST (supaya tidak menimpa device lain)
    local function syncUnggah()
        if SYNC.sibuk or State.Removed or not SYNC.kode then return end
        SYNC.sibuk = true
        SYNC.status = "kirim"
        syncRefreshKartu()
        local sukses = false
        local bolehUpload = false
        local cloud = syncAmbilCloud(SYNC.kode)
        if cloud == nil then
            -- jaringan gagal -> tunggu siklus berikutnya
        elseif cloud == "kosong" or cloud == "rusak" then
            -- loker kosong / isinya sampah -> isi ulang dengan data lokal
            if cloud == "rusak" then
                SYNC.offSudahToast = true
                toast("☁ data cloud tidak valid — diisi ulang dari device ini", Warna.Merah)
            end
            bolehUpload = true
        else
            SYNC.lastDari = cloud.dari
            local berubah, rincian = syncMerge(cloud)
            if berubah > 0 then
                toast("☁ dari cloud: " .. syncRingkas(rincian), Warna.Biru)
            end
            bolehUpload = true
        end
        if bolehUpload then
            local teks = HttpService:JSONEncode(syncPayload())
            if teks == SYNC.lastPayload then
                SYNC.pending = false      -- isinya sama -> jangan upload ulang
                syncSimpanFile()
                sukses = true
            else
                local put = syncHttp("POST", CFG.SYNC_URL .. SYNC.kode, syncBodyForm(teks))
                if put and (put.code == 200 or put.code == 201) then
                    SYNC.lastPayload = teks
                    SYNC.pending = false
                    SYNC.lastDari = SYNC.labelPerangkat
                    SYNC.kosongSudah = false
                    syncSimpanFile()
                    sukses = true
                    print("[BALAP-SYNC] terkirim (" .. #teks .. " byte)")
                end
            end
        end
        if sukses then
            syncSetStatus("ok")
        else
            syncSetStatus("offline")
        end
        SYNC.sibuk = false
    end

    -- bergabung ke loker milik device lain (MASUKKAN KODE)
    local function syncPakaiKode(kodeMasuk)
        if SYNC.sibuk or State.Removed then return end
        local kodeBaru = tostring(kodeMasuk):lower()
        kodeBaru = kodeBaru:gsub("^%s+", "")
        kodeBaru = kodeBaru:gsub("%s+$", "")
        if #kodeBaru < 6 or #kodeBaru > 40 or not kodeBaru:match("^[a-z0-9%-]+$") then
            toast("Kode: huruf kecil/angka/tanda - (contoh: balap-7k2m-9xq4)", Warna.Kuning)
            return
        end
        SYNC.sibuk = true
        SYNC.status = "terima"
        syncRefreshKartu()
        local cloud = syncAmbilCloud(kodeBaru)
        if type(cloud) == "table" then
            SYNC.kode = kodeBaru
            SYNC.lastPayload = nil
            SYNC.lastDari = cloud.dari
            SYNC.kosongSudah = false
            syncSimpanFile()
            local berubah, rincian = syncMerge(cloud)
            if berubah > 0 then
                toast("☁ dari cloud: " .. syncRingkas(rincian), Warna.Biru)
            end
            syncTandai()   -- data device ini ikut digabung ke loker
            syncSetStatus("ok")
            toast("☁ Tersambung ke loker " .. kodeBaru, Warna.Hijau)
            print("[BALAP-SYNC] pakai kode: " .. kodeBaru)
            SYNC.sibuk = false
            return
        end
        SYNC.sibuk = false
        if cloud == "kosong" then
            toast("☁ Kode tidak ditemukan — loker masih kosong (cek ketikan)", Warna.Merah)
        else
            syncSetStatus("offline")
            toast("☁ Kode tidak valid / tidak bisa dijangkau", Warna.Merah)
        end
    end

    -- ganti kode = buat loker baru berisi data sekarang
    local function syncGantiKode()
        if SYNC.sibuk or State.Removed then return end
        SYNC.sibuk = true
        SYNC.status = "kirim"
        syncRefreshKartu()
        local teks = HttpService:JSONEncode(syncPayload())
        local kodeBaru = syncKodeBaru()
        local hasil = syncHttp("POST", CFG.SYNC_URL .. kodeBaru, syncBodyForm(teks))
        if hasil and (hasil.code == 200 or hasil.code == 201) then
            SYNC.kode = kodeBaru
            SYNC.lastPayload = teks
            SYNC.pending = false
            SYNC.lastDari = SYNC.labelPerangkat
            SYNC.kosongSudah = false
            syncSimpanFile()
            syncSetStatus("ok")
            toast("☁ Kode baru siap: " .. kodeBaru, Warna.Hijau)
            print("[BALAP-SYNC] kode diganti: " .. kodeBaru)
        else
            syncSetStatus("offline")
            toast("☁ Gagal ganti kode (offline?) — kode lama tetap", Warna.Kuning)
        end
        SYNC.sibuk = false
    end

    -- set ulang cloud = samakan cloud dengan device ini + kosongkan
    -- daftar hapus (penyelamat kalau data cloud kacau)
    local function syncSetUlang()
        if SYNC.sibuk or State.Removed or not SYNC.kode then return end
        SYNC.sibuk = true
        SYNC.status = "kirim"
        syncRefreshKartu()
        local cadanganHapus = SYNC.hapus
        SYNC.hapus = {}
        local teks = HttpService:JSONEncode(syncPayload())
        local put = syncHttp("POST", CFG.SYNC_URL .. SYNC.kode, syncBodyForm(teks))
        if put and (put.code == 200 or put.code == 201) then
            SYNC.lastPayload = teks
            SYNC.pending = false
            SYNC.lastDari = SYNC.labelPerangkat
            syncSimpanFile()
            syncSetStatus("ok")
            toast("☁ Cloud disamakan dengan device ini", Warna.Hijau)
        else
            SYNC.hapus = cadanganHapus   -- gagal: kembalikan daftar hapus
            syncSetStatus("offline")
            toast("☁ Set ulang gagal (offline?) — coba lagi", Warna.Kuning)
        end
        SYNC.sibuk = false
    end

    -- mesin sync: dipanggil dari initLogic setelah semua siap
    local function syncMulai()
        syncRefreshKartu()
        if not SYNC.bisaHttp then return end
        print("[BALAP-SYNC] mesin jalan — kode: " .. tostring(SYNC.kode or "belum ada"))
        task.spawn(function()
            task.wait(2.5)                 -- beri waktu GUI & data lokal siap
            if State.Removed then return end
            if SYNC.kode then syncUnduh() else syncBuatLoker() end
            while not State.Removed do
                task.wait(1)
                if State.Removed then break end
                local now = os.clock()
                if not SYNC.kode then
                    if now - SYNC.waktuCoba >= 60 then syncBuatLoker() end
                else
                    if now - SYNC.waktuUnduh >= CFG.SYNC_UNDUH_TIAP then
                        syncUnduh()
                        now = os.clock()
                    end
                    if SYNC.pending and not SYNC.sibuk
                        and now - SYNC.waktuUbah >= CFG.SYNC_UNGGAH_JEDA then
                        syncUnggah()
                    end
                end
            end
        end)
        -- kedip kuning saat kirim/terima (status titik berwarna)
        task.spawn(function()
            while not State.Removed do
                local ui = SYNC.ui
                if ui and ui.dot and ui.dot.Parent then
                    if SYNC.status == "kirim" or SYNC.status == "terima" then
                        ui.dot.BackgroundTransparency =
                        (math.floor(os.clock() * 2.5) % 2 == 0) and 0 or 0.55
                    else
                        ui.dot.BackgroundTransparency = 0
                    end
                end
                task.wait(0.2)
            end
        end)
    end

    -- [7b] TAB BAR (4 TAB) ----------------------------------------------
    -- Bungkus dengan function untuk hemat local count (Luau limit 200)
    local function buildUI()
        tabBtns = {}
        local tabLabels = {"MOVEMENT & VISUAL", "TITIK", "TP", "SYSTEM"}
        local tabColors = {Warna.Ungu2, Warna.Kuning, Warna.Biru, Warna.AbuGelap}
        kontenTabs = {}
        for i, lbl in ipairs(tabLabels) do
            local tab = buat("TextButton", {
                Size = UDim2.new(1 / 4, -3.6, 0, 24),
                Position = UDim2.new((i - 1) * (1 / 4), 3.2 + (i - 1) * 1.6, 0, 50),
                BackgroundColor3 = (i == 1) and tabColors[i] or Warna.AbuMuda,
                BorderSizePixel = 0,
                FontFace = fnt("bold"),
                Text = lbl,
                TextWrapped = true,
                TextColor3 = (i == 1) and Warna.Putih or Warna.AbuTeks,
                TextScaled = true,
                AutoButtonColor = false,
            }, panel)
            buat("UICorner", {CornerRadius = UDim.new(0, 6)}, tab)
            buat("UITextSizeConstraint", {MaxTextSize = 11}, tab)
            efekTombol(tab, 1.04)
            table.insert(tabBtns, tab)
        end
        setTab = function(n)
            for i, t in ipairs(tabBtns) do
                local aktif = (i == n)
                t.BackgroundColor3 = aktif and tabColors[i] or Warna.AbuMuda
                t.TextColor3 = aktif and Warna.Putih or Warna.AbuTeks
            end
            for i, k in ipairs(kontenTabs) do
                k.Visible = (i == n)
            end
            bunyi(CFG.SND_PING, 0.2, 1.0 + 0.1 * n)
        end
        for i, t in ipairs(tabBtns) do
            local idx = i
            t.MouseButton1Click:Connect(function()
                ripple(t, Warna.Putih)
                setTab(idx)
            end)
        end

        -- [7c] KONTEN TAB 1: MOVEMENT & VISUAL ------------------------------------------
        kontenMove = buat("Frame", {
            Position = UDim2.new(0, 0, 0, 80),
            Size = UDim2.new(1, 0, 1, -110),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        }, panel)
        table.insert(kontenTabs, kontenMove)
        scrollMove = buat("ScrollingFrame", {
            Position = UDim2.new(0, 12, 0, 2),
            Size = UDim2.new(1, -24, 1, -6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Warna.Ungu,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, kontenMove)
        buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollMove)
        local sOrder = 0
        local function nextOrder() sOrder += 1 return sOrder end

        -- ===== baris generik (dipakai semua tab) =====
        local function buatHeader(parent, text)
            return buat("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 18),
                FontFace = fnt("bold"),
                TextSize = 12,
                TextColor3 = Warna.Ungu,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "▎" .. string.upper(text),
                LayoutOrder = nextOrder(),
            }, parent)
        end
        local function buatToggleRow(parent, labelText, keyText, featureName)
            local row = buat("Frame", {
                BackgroundColor3 = Warna.AbuItem,
                Size = UDim2.new(1, 0, 0, 32),
                LayoutOrder = nextOrder(),
            }, parent)
            buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
            local label = buat("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -110, 1, 0),
                FontFace = fnt("med"),
                TextSize = 13,
                TextColor3 = Warna.TeksGelap,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = labelText,
            }, row)
            if keyText then
                -- lebar chip keybind menyesuaikan teks (1 huruf = 22px, "Shift" lebih lebar)
                local cw = math.max(24, 14 + #keyText * 8)
                local chip = buat("TextLabel", {
                    BackgroundColor3 = Warna.Card2,
                    Size = UDim2.new(0, cw, 0, 20),
                    Position = UDim2.new(1, -58 - cw, 0.5, -10),
                    FontFace = fnt("bold"),
                    TextSize = 12,
                    TextColor3 = Warna.AbuGelap,
                    Text = keyText,
                }, row)
                buat("UICorner", {CornerRadius = UDim.new(0, 6)}, chip)
            end
            local sw = buat("TextButton", {
                BackgroundColor3 = Warna.Gray,
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10),
                Text = "",
                AutoButtonColor = false,
            }, row)
            buat("UICorner", {CornerRadius = UDim.new(0, 10)}, sw)
            local knob = buat("Frame", {
                BackgroundColor3 = Color3.fromRGB(235, 235, 240),
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, 3, 0.5, -7),
            }, sw)
            buat("UICorner", {CornerRadius = UDim.new(0, 10)}, knob)
            local api = {}
            function api.set(on)
                tween(sw, TweenInfo.new(0.15), {BackgroundColor3 = on and Warna.Hijau or Warna.Gray})
                tween(knob, TweenInfo.new(0.15), {
                    Position = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                })
            end
            Switches[featureName] = api
            api.set(State[featureName .. "On"])
            sw.MouseButton1Click:Connect(function()
                setFeature(featureName, not State[featureName .. "On"])
            end)
            return row, label
        end
        local function buatStepperRow(parent, labelText, getV, setV)
            local row = buat("Frame", {
                BackgroundColor3 = Warna.AbuItem,
                Size = UDim2.new(1, 0, 0, 30),
                LayoutOrder = nextOrder(),
            }, parent)
            buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
            if labelText then
                buat("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0, 100, 1, 0),
                    FontFace = fnt("med"),
                    TextSize = 12,
                    TextColor3 = Warna.TeksGelap,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = labelText,
                }, row)
            end
            local minus = buat("TextButton", {
                BackgroundColor3 = Warna.Card2,
                Size = UDim2.new(0, 32, 0, 22),
                Position = UDim2.new(0, labelText and 110 or 8, 0.5, -11),
                FontFace = fnt("bold"),
                TextSize = 16,
                TextColor3 = Warna.Putih,
                Text = "-",
                AutoButtonColor = false,
            }, row)
            buat("UICorner", {CornerRadius = UDim.new(0, 6)}, minus)
            local box = buat("TextBox", {
                BackgroundColor3 = Warna.Hitam2,
                Size = UDim2.new(1, labelText and -192 or -92, 0, 22),
                Position = UDim2.new(0, labelText and 148 or 46, 0.5, -11),
                FontFace = fnt("reg"),
                TextSize = 14,
                TextColor3 = Warna.Putih,
                Text = fmtNum(getV()),
                ClearTextOnFocus = false,
            }, row)
            buat("UICorner", {CornerRadius = UDim.new(0, 6)}, box)
            local plus = buat("TextButton", {
                BackgroundColor3 = Warna.Card2,
                Size = UDim2.new(0, 32, 0, 22),
                Position = UDim2.new(1, -40, 0.5, -11),
                FontFace = fnt("bold"),
                TextSize = 16,
                TextColor3 = Warna.Putih,
                Text = "+",
                AutoButtonColor = false,
            }, row)
            buat("UICorner", {CornerRadius = UDim.new(0, 6)}, plus)
            local function refresh() box.Text = fmtNum(getV()) end
            local function notifChange()
                if labelText then
                    toast(labelText .. ": " .. fmtNum(getV()), Warna.Biru)
                end
            end
            minus.MouseButton1Click:Connect(function() setV(clamp2(getV() - 0.25)); refresh(); notifChange() end)
            plus.MouseButton1Click:Connect(function() setV(clamp2(getV() + 0.25)); refresh(); notifChange() end)
            box.FocusLost:Connect(function()
                local n = tonumber(box.Text)
                if n then setV(clamp2(math.clamp(n, 0, 1000))) end
                refresh()
                notifChange()
            end)
            return refresh
        end
        local function buatActionRow(parent, text, color, callback)
            local btn = buat("TextButton", {
                BackgroundColor3 = color,
                Size = UDim2.new(1, 0, 0, 30),
                LayoutOrder = nextOrder(),
                FontFace = fnt("bold"),
                TextSize = 13,
                TextColor3 = Warna.Putih,
                Text = text,
                AutoButtonColor = false,
            }, parent)
            buat("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
            btn.MouseButton1Click:Connect(callback)
            efekTombol(btn, 1.03)
            return btn
        end

        -- ===== init State (dibuat SEBELUM baris toggle) =====
        State.SpeedOn = false
        State.SpeedValue = CFG.SPEED_ON_1
        State.JumpOn  = false
        State.JumpValue = CFG.ON_JUMP
        State.JumpHeightValue = CFG.ON_JUMP_H
        State.ShiftOn = false
        State.IsSwimming = false
        State.HideOn  = false
        State.LWOn    = false
        State.WallsOn = false
        State.LightOn = false
        State.MoonOn  = false  -- Moonwalk (F)
        State.TengahOn = false -- Shiftlock Tengah (LShift/RShift)
        State.TiangOn  = true  -- Tiang Penanda (tab TITIK, default TAMPIL)
        State.HideAtasOn = false  -- Hide Badan Atas (VISUAL, layar sendiri)

        -- Original Lighting (untuk restore saat cahaya dimatikan)
        oLight = {
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            ClockTime = Lighting.ClockTime,
            ExposureCompensation = Lighting.ExposureCompensation,
            FogEnd = Lighting.FogEnd,
        }

        lightConn = nil

        -- ===== baris TAB 1: MOVEMENT & VISUAL =====
        buatHeader(scrollMove, "Player")
        local _, speedLbl = buatToggleRow(scrollMove, "Speed (Q): OFF (" .. fmtNum(CFG.SPEED_OFF) .. ")", "Q", "Speed")
        SpeedLabel = speedLbl
        -- Nilai ON dipilih via stepper: rentang 17.25 - 21.25 (Q = ON/OFF saja)
        RefreshSpeed = buatStepperRow(
        scrollMove,
        "Speed",
        function() return State.SpeedValue end,
        function(v)
            State.SpeedValue = math.clamp(v, CFG.SPEED_ON_1, CFG.SPEED_ON_2)
            if State.SpeedOn then applySpeed() end
            if SpeedLabel and SpeedLabel.Parent then
                SpeedLabel.Text = "Speed (Q): " .. (State.SpeedOn and fmtNum(State.SpeedValue) or ("OFF (" .. fmtNum(CFG.SPEED_OFF) .. ")"))
            end
        end
        )
        local _, jumpLabelRow = buatToggleRow(scrollMove, "JumpPower", "J", "Jump")
        JumpLabel = jumpLabelRow
        RefreshJump = buatStepperRow(
        scrollMove,
        "Jump",
        function()
            local hum = getHum()
            if hum and hum.UseJumpPower == false then return State.JumpHeightValue end
            return State.JumpValue
        end,
        function(v)
            local hum = getHum()
            if hum and hum.UseJumpPower == false then State.JumpHeightValue = v else State.JumpValue = v end
            if State.JumpOn then applyJump() end
        end
        )
        buatToggleRow(scrollMove, "Shiftlock Mobile", "C", "Shift")
        buatToggleRow(scrollMove, "Shiftlock Tengah", "Shift", "Tengah")
        buatToggleRow(scrollMove, "Moonwalk", "F", "Moon")

        -- ===== VISUAL (dilebur dari tab VISUAL lama ke tab 1) =====
        buatHeader(scrollMove, "Visual")
        buatToggleRow(scrollMove, "Hide Player + Kendaraan", "R", "Hide")
        buatToggleRow(scrollMove, "Hide Badan Atas (kaki tetap)", nil, "HideAtas")
        buatToggleRow(scrollMove, "Cahaya Auto (2 arah)", "T", "Light")
        buatHeader(scrollMove, "Lightweight")
        buatToggleRow(scrollMove, "Partikel / Bayangan / Efek", nil, "LW")
        buatHeader(scrollMove, "Map")
        buatToggleRow(scrollMove, "Dinding Batas", "X", "Walls")

        -- [7g] KONTEN TAB 4: SYSTEM -----------------------------------------
        kontenSistem = buat("Frame", {
            Position = UDim2.new(0, 0, 0, 80),
            Size = UDim2.new(1, 0, 1, -110),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        }, panel)
        scrollSistem = buat("ScrollingFrame", {
            Position = UDim2.new(0, 12, 0, 2),
            Size = UDim2.new(1, -24, 1, -6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Warna.Ungu,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, kontenSistem)
        buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollSistem)

        -- [7f] KONTEN TAB 2: TITIK ------------------------------------------
        kontenTitik = buat("Frame", {
            Position = UDim2.new(0, 0, 0, 80),
            Size = UDim2.new(1, 0, 1, -110),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        }, panel)
        scrollTitik = buat("ScrollingFrame", {
            Position = UDim2.new(0, 12, 0, 2),
            Size = UDim2.new(1, -24, 1, -6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Warna.Kuning,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, kontenTitik)
        buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollTitik)

        buatHeader(scrollTitik, "Tiang Penanda")
        buatToggleRow(scrollTitik, "Tampilkan Tiang", nil, "Tiang")
        buatActionRow(scrollTitik, "📍 + TAMBAH TITIK DI SINI", Warna.Hijau, function()
            titikTambahDiSini()
        end)
        -- HAPUS SEMUA — konfirmasi 2 langkah (rawan kepencet kalau 1 tekan)
        local armTg = 0
        local btnHapusTgSemua = buatActionRow(scrollTitik, "🗑️ HAPUS SEMUA TITIK", Warna.Merah, function()
            local now = os.clock()
            if now - armTg > 3 then
                armTg = now
                btnHapusTgSemua.Text = "⚠️ YAKIN? TEKAN LAGI (3 dtk)"
                toast("Tekan LAGI dalam 3 dtk — semua titik terhapus", Warna.Merah)
                task.delay(3, function()
                    if btnHapusTgSemua.Parent and btnHapusTgSemua.Text ~= "🗑️ HAPUS SEMUA TITIK" then
                        btnHapusTgSemua.Text = "🗑️ HAPUS SEMUA TITIK"
                    end
                end)
            else
                armTg = 0
                btnHapusTgSemua.Text = "🗑️ HAPUS SEMUA TITIK"
                titikHapusSemua()
            end
        end)
        buatActionRow(scrollTitik, "⇅ URUTKAN TITIK TERDEKAT", Warna.Biru, function()
            local _, hrp = getKarakter()
            if not hrp then toast("Karakter belum ada", Warna.Merah) return end
            if #titikList < 2 then toast("Butuh minimal 2 titik", Warna.Kuning) return end
            table.sort(titikList, function(a, b)
                local da = (a.X - hrp.Position.X)^2 + (a.Y - hrp.Position.Y)^2 + (a.Z - hrp.Position.Z)^2
                local db = (b.X - hrp.Position.X)^2 + (b.Y - hrp.Position.Y)^2 + (b.Z - hrp.Position.Z)^2
                return da < db
            end)
            titikSimpan()
            titikRender()
            titikRefreshDaftar()
            toast("Titik diurutkan dari yang terdekat", Warna.Biru)
        end)
        buatHeader(scrollTitik, "Daftar Titik")
        titikHolder = buat("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = nextOrder(),
        }, scrollTitik)
        buat("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, titikHolder)
        titikLabelJumlah = buat("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            FontFace = fnt("med"),
            TextSize = 11,
            TextColor3 = Warna.AbuTeks,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Total: 0 titik • klik item = teleport",
            LayoutOrder = nextOrder(),
        }, scrollTitik)
        -- muat data lama (file / getgenv) lalu render pertama
        titikMuat()
        titikRender()
        titikRefreshDaftar()

        -- [7e] KONTEN TAB 3: TP ---------------------------------------------
        kontenTP = buat("Frame", {
            Position = UDim2.new(0, 0, 0, 80),
            Size = UDim2.new(1, 0, 1, -110),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        }, panel)
        scrollTP = buat("ScrollingFrame", {
            Position = UDim2.new(0, 12, 0, 2),
            Size = UDim2.new(1, -24, 1, -6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Warna.Biru,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, kontenTP)
        buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollTP)

        -- ===== TP — TELEPORT + SIMPAN LOKASI (nama bebas, permanen) ==========
        -- Berdiri di tempat -> ketik nama -> 💾 SIMPAN -> muncul di daftar.
        -- Tombol TP = teleport, ✎ = rename (posisi tetap), X = hapus.
        -- Daftar menampilkan JARAK dari posisi sekarang + bisa diurutkan
        -- dari terdekat. Data TP (TP_MAX/TP_FILE/TP_LOKASI/tpTulisFile)
        -- didefinisikan di [7a3] bersama modul ☁ SINKRON. Perubahan TP
        -- otomatis masuk antrean sinkron cloud (syncTandai).

        buatHeader(scrollTP, "Teleport (TP)")

        -- baris input: [nama bebas] [💾 SIMPAN]
        local tpInputRow = buat("Frame", {
            BackgroundColor3 = Warna.AbuItem,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = nextOrder(),
        }, scrollTP)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, tpInputRow)
        local tpInput = buat("TextBox", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0.5, -11),
            Size = UDim2.new(1, -118, 0, 22),
            FontFace = fnt("med"),
            TextSize = 12,
            TextColor3 = Warna.TeksGelap,
            PlaceholderText = "Nama lokasi (bebas)...",
            PlaceholderColor3 = Warna.AbuTeks,
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
        }, tpInputRow)
        local tpSaveBtn = buat("TextButton", {
            BackgroundColor3 = Warna.Hijau,
            Position = UDim2.new(1, -100, 0.5, -11),
            Size = UDim2.new(0, 92, 0, 22),
            FontFace = fnt("bold"),
            TextSize = 11,
            TextColor3 = Warna.HijauMuda,
            Text = "SIMPAN",
            AutoButtonColor = false,
        }, tpInputRow)
        buat("UICorner", {CornerRadius = UDim.new(0, 6)}, tpSaveBtn)

        -- daftar lokasi (membesar otomatis, ikut scroll tab GERAK)
        local tpList = buat("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = nextOrder(),
        }, scrollTP)
        buat("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, tpList)

        local tpRenameIdx = nil   -- indeks TP yang sedang direname (✎)
        local function jarakMeter(x, y, z)
            local char = getChar()
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return nil end
            local dx, dy, dz = x - hrp.Position.X, y - hrp.Position.Y, z - hrp.Position.Z
            return math.sqrt(dx*dx + dy*dy + dz*dz)
        end

        tpRefresh = function()
            for _, c in ipairs(tpList:GetChildren()) do
                if c:IsA("TextButton") or c:IsA("TextLabel") or c:IsA("Frame") then c:Destroy() end
            end
            if #TP_LOKASI == 0 then
                buat("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18),
                    FontFace = fnt("reg"),
                    TextSize = 11,
                    TextColor3 = Warna.AbuTeks,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = "Belum ada lokasi — berdiri di tempat, ketik nama, tekan SIMPAN",
                    LayoutOrder = 0,
                }, tpList)
                syncRefreshKartu()
                return
            end
            for i, L in ipairs(TP_LOKASI) do
                if i == tpRenameIdx then
                    -- ===== MODE RENAME (v1.3.4): [nama baru] [SIMPAN] [✕] =====
                    local row = buat("Frame", {
                        BackgroundColor3 = Warna.BiruMuda,
                        Size = UDim2.new(1, 0, 0, 28),
                        LayoutOrder = i,
                    }, tpList)
                    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
                    local box = buat("TextBox", {
                        BackgroundColor3 = Warna.Putih,
                        Position = UDim2.new(0, 8, 0.5, -10),
                        Size = UDim2.new(1, -128, 0, 20),
                        FontFace = fnt("med"),
                        TextSize = 11,
                        TextColor3 = Warna.TeksGelap,
                        Text = L.nama,
                        ClearTextOnFocus = false,
                        TextXAlignment = Enum.TextXAlignment.Left,
                    }, row)
                    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, box)
                    local btnOk = buat("TextButton", {
                        BackgroundColor3 = Warna.Hijau,
                        Position = UDim2.new(1, -92, 0.5, -10),
                        Size = UDim2.new(0, 54, 0, 20),
                        FontFace = fnt("bold"),
                        TextSize = 10,
                        TextColor3 = Warna.HijauMuda,
                        Text = "SIMPAN",
                        AutoButtonColor = false,
                    }, row)
                    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnOk)
                    local btnNo = buat("TextButton", {
                        BackgroundColor3 = Warna.Merah,
                        Position = UDim2.new(1, -32, 0.5, -10),
                        Size = UDim2.new(0, 26, 0, 20),
                        FontFace = fnt("bold"),
                        TextSize = 11,
                        TextColor3 = Warna.Putih,
                        Text = "✕",
                        AutoButtonColor = false,
                    }, row)
                    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnNo)
                    btnOk.MouseButton1Click:Connect(function()
                        local namaBaru = tostring(box.Text):gsub("^%s+", ""):gsub("%s+$", "")
                        if #namaBaru == 0 then toast("Tulis dulu nama barunya", Warna.Kuning) return end
                        if namaBaru ~= L.nama then
                            for j, O in ipairs(TP_LOKASI) do
                                if j ~= i and O.nama == namaBaru then
                                    toast("Nama '" .. namaBaru .. "' sudah dipakai", Warna.Kuning)
                                    return
                                end
                            end
                        end
                        local lama = L.nama
                        L.nama = namaBaru          -- posisi (x,y,z) TETAP
                        tpRenameIdx = nil
                        if namaBaru ~= lama then
                            syncCatatHapusTp(lama)        -- nama lama = dihapus di cloud
                            syncBuangHapusTp(namaBaru)    -- nama baru = tambahan baru
                            tpTulisFile()
                            syncTandai()
                        else
                            tpTulisFile()
                        end
                        tpRefresh()
                        toast("Diubah: " .. lama .. " → " .. namaBaru, Warna.Hijau)
                    end)
                    btnNo.MouseButton1Click:Connect(function()
                        tpRenameIdx = nil
                        tpRefresh()
                    end)
                else
                    local jarak = jarakMeter(L.x, L.y, L.z)
                    local row = buat("Frame", {
                        BackgroundColor3 = Warna.AbuItem,
                        Size = UDim2.new(1, 0, 0, 28),
                        LayoutOrder = i,
                    }, tpList)
                    buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
                    buat("TextLabel", {
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 10, 0, 0),
                        Size = UDim2.new(1, -150, 1, 0),
                        FontFace = fnt("med"),
                        TextSize = 11,
                        TextColor3 = Warna.TeksGelap,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        Text = L.nama .. (jarak and ("  (" .. fmtJarak(jarak) .. ")") or ""),
                    }, row)
                    local btnRen = buat("TextButton", {
                        BackgroundColor3 = Warna.Card2,
                        Position = UDim2.new(1, -94, 0.5, -10),
                        Size = UDim2.new(0, 22, 0, 20),
                        FontFace = fnt("bold"),
                        TextSize = 12,
                        TextColor3 = Warna.Putih,
                        Text = "✎",
                        AutoButtonColor = false,
                    }, row)
                    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnRen)
                    local btnTp = buat("TextButton", {
                        BackgroundColor3 = Warna.Biru,
                        Position = UDim2.new(1, -68, 0.5, -10),
                        Size = UDim2.new(0, 40, 0, 20),
                        FontFace = fnt("bold"),
                        TextSize = 11,
                        TextColor3 = Warna.Putih,
                        Text = "TP",
                        AutoButtonColor = false,
                    }, row)
                    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnTp)
                    local btnHps = buat("TextButton", {
                        BackgroundColor3 = Warna.Merah,
                        Position = UDim2.new(1, -32, 0.5, -10),
                        Size = UDim2.new(0, 26, 0, 20),
                        FontFace = fnt("bold"),
                        TextSize = 11,
                        TextColor3 = Warna.Putih,
                        Text = "X",
                        AutoButtonColor = false,
                    }, row)
                    buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnHps)
                    btnRen.MouseButton1Click:Connect(function()
                        tpRenameIdx = i
                        tpRefresh()
                    end)
                    btnTp.MouseButton1Click:Connect(function()
                        local _, hrp = getKarakter()
                        if not hrp then toast("TP gagal — karakter belum ada", Warna.Merah) return end
                        hrp.CFrame = CFrame.new(L.x, L.y + 3, L.z)
                        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        print("[BALAP-TP] teleport ke '" .. L.nama .. "'")
                        toast("TP: " .. L.nama, Warna.Biru)
                    end)
                    btnHps.MouseButton1Click:Connect(function()
                        syncCatatHapusTp(L.nama)   -- tombstone: tidak bangkit dari cloud
                        table.remove(TP_LOKASI, i)
                        tpTulisFile()
                        tpRefresh()
                        syncTandai()
                        print("[BALAP-TP] hapus '" .. L.nama .. "' (sisa " .. #TP_LOKASI .. ")")
                        toast("Hapus: " .. L.nama, Warna.Merah)
                    end)
                end
            end
            syncRefreshKartu()
        end

        tpSaveBtn.MouseButton1Click:Connect(function()
            local nama = tostring(tpInput.Text):gsub("^%s+", ""):gsub("%s+$", "")
            if #nama == 0 then toast("Tulis dulu nama lokasinya", Warna.Kuning) return end
            local _, hrp = getKarakter()
            if not hrp then toast("Karakter belum ada — coba lagi", Warna.Merah) return end
            local p = hrp.Position
            for _, L in ipairs(TP_LOKASI) do
                if L.nama == nama then                    -- nama sama = update posisi
                    L.x, L.y, L.z = p.X, p.Y, p.Z
                    tpTulisFile()
                    tpRefresh()
                    tpInput.Text = ""
                    syncTandai()
                    print("[BALAP-TP] update '" .. nama .. "' (total " .. #TP_LOKASI .. ")")
                    toast("Diperbarui: " .. nama, Warna.Hijau)
                    return
                end
            end
            if #TP_LOKASI >= TP_MAX then toast("Penuh (max " .. TP_MAX .. " lokasi)", Warna.Kuning) return end
            syncBuangHapusTp(nama)   -- dipasang lagi -> hapus tombstone lamanya
            TP_LOKASI[#TP_LOKASI + 1] = { nama = nama, x = p.X, y = p.Y, z = p.Z }
            tpTulisFile()
            tpRefresh()
            tpInput.Text = ""
            syncTandai()
            print("[BALAP-TP] simpan '" .. nama .. "' (total " .. #TP_LOKASI .. ")"
            .. (tpBisaFile and " -> file" or " -> SESI SAJA (executor tanpa writefile)"))
            toast("Tersimpan: " .. nama, Warna.Hijau)
        end)

        tpRefresh()

        -- ⇅ urutkan TP dari terdekat + hapus semua TP (konfirmasi 2 langkah)
        local armTp = 0
        buatActionRow(scrollTP, "⇅ URUTKAN TP TERDEKAT", Warna.Biru, function()
            local _, hrp = getKarakter()
            if not hrp then toast("Karakter belum ada", Warna.Merah) return end
            if #TP_LOKASI < 2 then toast("Butuh minimal 2 TP", Warna.Kuning) return end
            table.sort(TP_LOKASI, function(a, b)
                local da = (a.x - hrp.Position.X)^2 + (a.y - hrp.Position.Y)^2 + (a.z - hrp.Position.Z)^2
                local db = (b.x - hrp.Position.X)^2 + (b.y - hrp.Position.Y)^2 + (b.z - hrp.Position.Z)^2
                return da < db
            end)
            tpTulisFile()
            tpRefresh()
            toast("TP diurutkan dari yang terdekat", Warna.Biru)
        end)
        local btnHapusTpSemua = buatActionRow(scrollTP, "🗑️ HAPUS SEMUA TP", Warna.Merah, function()
            local now = os.clock()
            if now - armTp > 3 then
                armTp = now
                btnHapusTpSemua.Text = "⚠️ YAKIN? TEKAN LAGI (3 dtk)"
                toast("Tekan LAGI dalam 3 dtk — semua TP terhapus", Warna.Merah)
                task.delay(3, function()
                    if btnHapusTpSemua.Parent and btnHapusTpSemua.Text ~= "🗑️ HAPUS SEMUA TP" then
                        btnHapusTpSemua.Text = "🗑️ HAPUS SEMUA TP"
                    end
                end)
            else
                armTp = 0
                btnHapusTpSemua.Text = "🗑️ HAPUS SEMUA TP"
                if #TP_LOKASI == 0 then toast("Belum ada TP", Warna.Kuning) return end
                for _, L in ipairs(TP_LOKASI) do syncCatatHapusTp(L.nama) end
                table.clear(TP_LOKASI)
                tpTulisFile()
                tpRefresh()
                syncTandai()
                toast("Semua TP dihapus", Warna.Merah)
            end
        end)

        -- urutan kontenTabs = urutan tab: 1 MOVEMENT & VISUAL • 2 TITIK • 3 TP • 4 SYSTEM
        table.insert(kontenTabs, kontenTitik)
        table.insert(kontenTabs, kontenTP)
        table.insert(kontenTabs, kontenSistem)

        -- ===== kartu ☁ SINKRON — status sinkronisasi cloud (pindahan dari tab TITIK ke tab SYSTEM) =====
        local kartuSync = buat("Frame", {
            BackgroundColor3 = Warna.Card2,
            Size = UDim2.new(1, 0, 0, 102),
            LayoutOrder = nextOrder(),
        }, scrollSistem)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, kartuSync)
        buat("UIStroke", {Color = Warna.Ungu2, Thickness = 1, Transparency = 0.55}, kartuSync)
        local syncJudul = buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 5),
            Size = UDim2.new(1, -30, 0, 15),
            FontFace = fnt("bold"),
            TextSize = 12,
            TextColor3 = Warna.BiruMuda,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "☁ SINKRON — TP + titik lintas device",
        }, kartuSync)
        local syncDot = buat("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -9, 0, 8),
            Size = UDim2.fromOffset(9, 9),
            BackgroundColor3 = Warna.AbuGelap,
            BorderSizePixel = 0,
        }, kartuSync)
        buat("UICorner", {CornerRadius = UDim.new(1, 0)}, syncDot)
        local syncInfo = buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 22),
            Size = UDim2.new(1, -20, 0, 14),
            FontFace = fnt("med"),
            TextScaled = true,
            TextColor3 = Warna.Putih,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Text = "menyambung ke cloud...",
        }, kartuSync)
        buat("UITextSizeConstraint", {MaxTextSize = 11}, syncInfo)
        local syncDari = buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 37),
            Size = UDim2.new(1, -20, 0, 12),
            FontFace = fnt("reg"),
            TextScaled = true,
            TextColor3 = Warna.AbuGelap,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Text = "menyambung ke cloud (butuh internet)...",
        }, kartuSync)
        buat("UITextSizeConstraint", {MaxTextSize = 10}, syncDari)
        -- baris input kode (disembunyikan; muncul saat MASUKKAN KODE)
        local syncRowInput = buat("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 53),
            Size = UDim2.new(1, -20, 0, 24),
            Visible = false,
        }, kartuSync)
        local boxKode = buat("TextBox", {
            BackgroundColor3 = Warna.Hitam2,
            Size = UDim2.new(1, -76, 1, 0),
            FontFace = fnt("med"),
            TextSize = 11,
            TextColor3 = Warna.Putih,
            PlaceholderText = "Tempel / ketik kode (balap-xxxx-xxxx)...",
            PlaceholderColor3 = Warna.AbuTeks,
            Text = "",
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, syncRowInput)
        buat("UICorner", {CornerRadius = UDim.new(0, 6)}, boxKode)
        local btnPakaiKode = buat("TextButton", {
            BackgroundColor3 = Warna.Hijau,
            Position = UDim2.new(1, -70, 0, 0),
            Size = UDim2.new(0, 46, 1, 0),
            FontFace = fnt("bold"),
            TextSize = 10,
            TextColor3 = Warna.HijauMuda,
            Text = "PAKAI",
            AutoButtonColor = false,
        }, syncRowInput)
        buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnPakaiKode)
        local btnBatalKode = buat("TextButton", {
            BackgroundColor3 = Warna.Merah,
            Position = UDim2.new(1, -20, 0, 0),
            Size = UDim2.new(0, 20, 1, 0),
            FontFace = fnt("bold"),
            TextSize = 11,
            TextColor3 = Warna.Putih,
            Text = "✕",
            AutoButtonColor = false,
        }, syncRowInput)
        buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnBatalKode)
        -- baris tombol utama
        local syncRowTombol = buat("Frame", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 53),
            Size = UDim2.new(1, -20, 0, 24),
        }, kartuSync)
        local btnSalinKode = buat("TextButton", {
            BackgroundColor3 = Warna.Biru,
            Size = UDim2.new(0, 150, 1, 0),
            FontFace = fnt("bold"),
            TextSize = 10,
            TextColor3 = Warna.Putih,
            Text = "⧉ SALIN KODE",
            AutoButtonColor = false,
        }, syncRowTombol)
        buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnSalinKode)
        efekTombol(btnSalinKode, 1.03)
        local btnMasukKode = buat("TextButton", {
            BackgroundColor3 = Warna.Card2,
            Position = UDim2.new(0, 156, 0, 0),
            Size = UDim2.new(0, 150, 1, 0),
            FontFace = fnt("bold"),
            TextSize = 10,
            TextColor3 = Warna.Ungu2,
            Text = "MASUKKAN KODE",
            AutoButtonColor = false,
        }, syncRowTombol)
        buat("UICorner", {CornerRadius = UDim.new(0, 6)}, btnMasukKode)
        efekTombol(btnMasukKode, 1.03)
        local btnGantiKode = buat("TextButton", {
            BackgroundColor3 = Warna.AbuItem,
            Position = UDim2.new(0, 10, 0, 81),
            Size = UDim2.new(0, 150, 0, 16),
            FontFace = fnt("bold"),
            TextSize = 9,
            TextColor3 = Warna.AbuTeks,
            Text = "GANTI KODE (loker baru)",
            AutoButtonColor = false,
        }, kartuSync)
        buat("UICorner", {CornerRadius = UDim.new(0, 5)}, btnGantiKode)
        local btnResetCloud = buat("TextButton", {
            BackgroundColor3 = Warna.AbuItem,
            Position = UDim2.new(0, 166, 0, 81),
            Size = UDim2.new(0, 150, 0, 16),
            FontFace = fnt("bold"),
            TextSize = 9,
            TextColor3 = Warna.AbuTeks,
            Text = "SET ULANG CLOUD",
            AutoButtonColor = false,
        }, kartuSync)
        buat("UICorner", {CornerRadius = UDim.new(0, 5)}, btnResetCloud)
        SYNC.ui = { dot = syncDot, ikon = btnCloud, info = syncInfo, dari = syncDari }

        local function modeInputKode(on)
            syncRowTombol.Visible = not on
            syncRowInput.Visible = on
            if on then pcall(function() boxKode:CaptureFocus() end) end
        end
        btnSalinKode.MouseButton1Click:Connect(function()
            if not SYNC.kode then
                toast("Kode belum ada — tunggu internet / pakai MASUKKAN KODE", Warna.Kuning)
                return
            end
            local ok = pcall(function() setclipboard(SYNC.kode) end)
            if ok then
                toast("Kode disalin: " .. SYNC.kode, Warna.Hijau)
            else
                toast("Gagal salin — kode: " .. SYNC.kode, Warna.Kuning)
            end
        end)
        btnMasukKode.MouseButton1Click:Connect(function() modeInputKode(true) end)
        btnBatalKode.MouseButton1Click:Connect(function()
            boxKode.Text = ""
            modeInputKode(false)
        end)
        btnPakaiKode.MouseButton1Click:Connect(function()
            local kode = tostring(boxKode.Text):gsub("^%s+", ""):gsub("%s+$", "")
            if not kode:match("^[a-zA-Z0-9%-]+$") then
                toast("Kode: huruf kecil/angka/tanda - (contoh: balap-7k2m-9xq4)", Warna.Kuning)
                return
            end
            boxKode.Text = ""
            modeInputKode(false)
            syncPakaiKode(kode)
        end)
        boxKode.FocusLost:Connect(function(enter)
            if enter then
                local kode = tostring(boxKode.Text):gsub("^%s+", ""):gsub("%s+$", "")
                if kode:match("^[a-zA-Z0-9%-]+$") then
                    boxKode.Text = ""
                    modeInputKode(false)
                    syncPakaiKode(kode)
                end
            end
        end)
        -- GANTI KODE — konfirmasi 2 langkah (3 dtk)
        local armGanti = 0
        btnGantiKode.MouseButton1Click:Connect(function()
            local now = os.clock()
            if now - armGanti > 3 then
                armGanti = now
                btnGantiKode.Text = "⚠️ YAKIN? TEKAN LAGI"
                btnGantiKode.BackgroundColor3 = Warna.Merah
                btnGantiKode.TextColor3 = Warna.Putih
                toast("Kode baru = loker baru — tekan lagi untuk konfirmasi", Warna.Kuning)
                task.delay(3, function()
                    if btnGantiKode.Parent and btnGantiKode.Text ~= "GANTI KODE (loker baru)" then
                        btnGantiKode.Text = "GANTI KODE (loker baru)"
                        btnGantiKode.BackgroundColor3 = Warna.AbuItem
                        btnGantiKode.TextColor3 = Warna.AbuTeks
                    end
                end)
            else
                armGanti = 0
                btnGantiKode.Text = "GANTI KODE (loker baru)"
                btnGantiKode.BackgroundColor3 = Warna.AbuItem
                btnGantiKode.TextColor3 = Warna.AbuTeks
                if not SYNC.kode then toast("Belum punya kode — tunggu loker dibuat", Warna.Kuning) return end
                syncGantiKode()
            end
        end)
        -- SET ULANG CLOUD — konfirmasi 2 langkah (3 dtk)
        local armReset = 0
        btnResetCloud.MouseButton1Click:Connect(function()
            local now = os.clock()
            if now - armReset > 3 then
                armReset = now
                btnResetCloud.Text = "⚠️ YAKIN? TEKAN LAGI"
                btnResetCloud.BackgroundColor3 = Warna.Merah
                btnResetCloud.TextColor3 = Warna.Putih
                toast("Cloud akan disamakan dengan device ini — tekan lagi", Warna.Kuning)
                task.delay(3, function()
                    if btnResetCloud.Parent and btnResetCloud.Text ~= "SET ULANG CLOUD" then
                        btnResetCloud.Text = "SET ULANG CLOUD"
                        btnResetCloud.BackgroundColor3 = Warna.AbuItem
                        btnResetCloud.TextColor3 = Warna.AbuTeks
                    end
                end)
            else
                armReset = 0
                btnResetCloud.Text = "SET ULANG CLOUD"
                btnResetCloud.BackgroundColor3 = Warna.AbuItem
                btnResetCloud.TextColor3 = Warna.AbuTeks
                if not SYNC.kode then toast("Belum ada cloud untuk diset ulang", Warna.Kuning) return end
                syncSetUlang()
            end
        end)
        syncRefreshKartu()

        buatHeader(scrollSistem, "Info")
        local infoVersi = buat("TextLabel", {
            BackgroundColor3 = Warna.AbuItem,
            Size = UDim2.new(1, 0, 0, 190),
            FontFace = fnt("med"),
            TextSize = 12,
            TextColor3 = Warna.TeksGelap,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Text = "⚡ BALAP v1.5\n"
            .. "TAB 1 MOVEMENT & VISUAL: Speed (Q) • Jump (J)\n"
            .. "Shiftlock (C) • Shiftlock Tengah (LShift) • Moonwalk (F)\n"
            .. "Hide (R) • Hide Atas\n"
            .. "Cahaya Auto (T) • Lightweight • Dinding Batas (X)\n"
            .. "TAB 2 TITIK: tiang checkpoint + daftar • V = +titik cepat\n"
            .. "TAB 3 TP: simpan/rename/hapus/urut terdekat\n"
            .. "TAB 4 SYSTEM: ☁ SINKRON — kode di kartu SYSTEM,\n"
            .. "salin ke device lain (MASUKKAN KODE untuk nyambung)\n"
            .. "Rejoin (K×2) • Hapus Script\n"
            .. "Shift/Moonwalk/Tengah otomatis OFF saat mati/respawn\n"
            .. "v1.4: Moonwalk & Shiftlock Mobile tidak berefek saat\n"
            .. "naik kendaraan — turun dari kendaraan, efek balik sendiri",
            LayoutOrder = nextOrder(),
        }, scrollSistem)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, infoVersi)
        buat("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, infoVersi)
        buatHeader(scrollSistem, "Aksi")
        buatActionRow(scrollSistem, "🔁 REJOIN SERVER  [K×2]", Warna.Biru, function() rejoin() end)
        buatActionRow(scrollSistem, "🗑️ HAPUS SCRIPT", Warna.Merah, function()
            if not _G.__KS_DELETE_ARMED__ then
                _G.__KS_DELETE_ARMED__ = true
                bunyi(CFG.SND_SNAP, 0.3, 0.8)
                toast("Tekan HAPUS sekali lagi untuk konfirmasi", Warna.Merah)
                task.delay(3, function() _G.__KS_DELETE_ARMED__ = nil end)
            else
                _G.__KS_DELETE_ARMED__ = nil
                unloadScript()
            end
        end)

    end -- akhir buildUI()

    -- Eksekusi buildUI() sekarang (panel, root, outer, Warna, buat sudah ada dari part1)
    buildUI()
    diagSet("GUI utama OK — bikin efek & notif...")

    -- [8] FOOTER + LED + MARQUEE ---------------------------------------
    -- Bungkus dengan function untuk hemat local count (Luau limit 200)
    local function buildFX()
        local footer = buat("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.new(0, 0, 1, -30),
            BackgroundColor3 = Warna.Hitam2,
            BorderSizePixel = 0,
        }, panel)
        buat("UICorner", {CornerRadius = UDim.new(0, 11)}, footer)
        buat("Frame", {
            Size = UDim2.new(1, 0, 0, 11),
            Position = UDim2.new(0, 0, 1, -41),
            BackgroundColor3 = Warna.Hitam2,
            BorderSizePixel = 0,
        }, panel)
        ledSweep(footer, Warna.Hitam2, Warna.Ungu, Warna.Biru, 3.2)
        local ledLabel = buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 17),
            FontFace = fnt("judul"),
            Text = CFG.LED_TEXT,
            TextColor3 = Warna.Putih,
            TextSize = 15,
        }, footer)
        local ledGlow = buat("UIStroke", {Name = "NoFade", Color = Warna.Ungu2, Thickness = 1, Transparency = 0.4}, ledLabel)
        cycleColor(ledLabel, "TextColor3", {Warna.Putih, Warna.Ungu2, Warna.Biru2, Warna.Ungu2}, 0.4)
        task.spawn(function()
            while ledGlow.Parent do
                tween(ledGlow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.8})
                task.wait(0.5)
                if not ledGlow.Parent then break end
                tween(ledGlow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.2})
                task.wait(0.5)
            end
        end)
        local marqueeClip = buat("Frame", {
            Position = UDim2.new(0, 6, 0, 17),
            Size = UDim2.new(1, -12, 0, 13),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
        }, footer)
        local marquee = buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(360, 0),
            Size = UDim2.fromOffset(1600, 13),
            FontFace = fnt("med"),
            Text = "⌨ G = GUI   ✦   🏃 Q Speed ON/OFF (nilai ON 17.25-21.25) • J Jump (51.25/65.25) • C Shift • LShift Tengah • F Moonwalk • V +Titik   ✦   📍 TAB TITIK: tiang + daftar titik   ✦   🌍 TAB TP: simpan/rename/urut terdekat   ✦   🎨 R Hide • Hide Atas • T Cahaya 2-arah • X Dinding • LW   ✦   ☁ kode sinkron di tab SYSTEM   ✦   ⚙️ K×2 rejoin • Notif kanan atas",
            TextColor3 = Warna.AbuGelap,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, marqueeClip)
        table.insert(effTweens, tween(marquee, TweenInfo.new(24, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
        {Position = UDim2.fromOffset(-1600, 0)}))

        -- bracket pojok (dekorasi)
        local posisiTitik = {
            UDim2.new(0.5, 0, 0, 1),
            UDim2.new(0.5, 0, 1, -1),
            UDim2.new(0, 1, 0.5, 0),
            UDim2.new(1, -1, 0.5, 0),
        }
        for i, p in ipairs(posisiTitik) do
            local d = buat("Frame", {
                Name = "NoFade",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = p,
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = Warna.Ungu2,
                BorderSizePixel = 0,
                ZIndex = 3,
            }, outer)
            buat("UICorner", {CornerRadius = UDim.new(1, 0)}, d)
            cycleColor(d, "BackgroundColor3", {Warna.Putih, Warna.Ungu2, Warna.Biru2, Warna.Ungu}, 0.6 * i + 0.3)
        end
        local function bracket(ax, ay, px, py, warna)
            local bar1 = buat("Frame", {Name = "NoFade", AnchorPoint = Vector2.new(ax, ay),
                Position = UDim2.new(px, ax == 1 and -8 or 8, py, ay == 1 and -8 or 8),
                Size = UDim2.fromOffset(14, 3), BackgroundColor3 = warna, BorderSizePixel = 0, ZIndex = 3}, outer)
            local bar2 = buat("Frame", {Name = "NoFade", AnchorPoint = Vector2.new(ax, ay),
                Position = UDim2.new(px, ax == 1 and -3 or 3, py, ay == 1 and -3 or 3),
                Size = UDim2.fromOffset(3, 14), BackgroundColor3 = warna, BorderSizePixel = 0, ZIndex = 3}, outer)
            return {bar1, bar2}
        end
        local semuaBracket = {
            bracket(0, 0, 0, 0, Warna.Ungu2),
            bracket(1, 0, 1, 0, Warna.Biru2),
            bracket(0, 1, 0, 1, Warna.Biru2),
            bracket(1, 1, 1, 1, Warna.Ungu2),
        }
        task.spawn(function()
            while outer.Parent do
                for i, pasang in ipairs(semuaBracket) do
                    for _, b in ipairs(pasang) do
                        tween(b, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {BackgroundTransparency = (i % 2 == 0) and 0.7 or 0.1})
                    end
                end
                task.wait(0.62)
                if not outer.Parent then break end
                for i, pasang in ipairs(semuaBracket) do
                    for _, b in ipairs(pasang) do
                        tween(b, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {BackgroundTransparency = (i % 2 == 0) and 0.1 or 0.7})
                    end
                end
                task.wait(0.62)
            end
        end)

        -- [9] PARTIKEL AMBIENT ----------------------------------------------
        local emojiAmbient = {"✨", "⚡", "💜", "💙", "⭐", "💫", "🔹", "🌟"}
        task.spawn(function()
            while partBox.Parent do
                if CFG.FX_LEVEL == 1 and root.Visible then
                    local x0 = rnd(6, 94) / 100
                    local l = buat("TextLabel", {
                        Name = "NoFade",
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(x0, 0, 1.05, 0),
                        Size = UDim2.fromOffset(20, 20),
                        BackgroundTransparency = 1,
                        Font = Enum.Font.SourceSans,
                        Text = emojiAmbient[rnd(1, #emojiAmbient)],
                        TextSize = rnd(11, 17),
                        TextColor3 = Warna.Putih,
                        TextTransparency = 1,
                        Rotation = rnd(-15, 15),
                    }, partBox)
                    local dur = rnd(28, 46) / 10
                    tween(l, TweenInfo.new(0.35), {TextTransparency = 0.55})
                    tween(l, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {Position = UDim2.new(x0 + rnd(-6, 6) / 100, 0, -0.08, 0)})
                    table.insert(effTweens, tween(l, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                    {Rotation = l.Rotation + rnd(16, 30) * (rnd(0, 1) == 0 and 1 or -1)}))
                    task.delay(dur - 0.4, function()
                        if l.Parent then tween(l, TweenInfo.new(0.4), {TextTransparency = 1}) end
                    end)
                    task.delay(dur + 0.1, function() l:Destroy() end)
                    task.wait(rnd(4, 8) / 10)
                else
                    task.wait(0.8)
                end
            end
        end)
        task.spawn(function()
            while header.Parent do
                task.wait(rnd(6, 14) / 10)
                if not header.Parent then break end
                local s = buat("TextLabel", {
                    Name = "NoFade",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(rnd(5, 90) / 100, 0, rnd(20, 80) / 100, 0),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSans,
                    Text = rnd(0, 1) == 0 and "✦" or "✨",
                    TextSize = rnd(9, 13),
                    TextColor3 = Warna.Putih,
                    TextTransparency = 1,
                    ZIndex = 2,
                }, header)
                tween(s, TweenInfo.new(0.2), {TextTransparency = 0.1})
                task.delay(0.35, function()
                    if s.Parent then tween(s, TweenInfo.new(0.35), {TextTransparency = 1}) end
                end)
                task.delay(0.75, function() s:Destroy() end)
            end
        end)

        -- [10] BURST FX -----------------------------------------------------
        local paletKonfeti = {Warna.Ungu, Warna.Ungu2, Warna.Biru, Warna.Biru2, Warna.Putih, Warna.Hijau2}
        konfeti = function(parent, pos, n)
            for _ = 1, n do
                local c = buat("Frame", {
                    Name = "NoFade",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = pos,
                    Size = UDim2.fromOffset(rnd(5, 9), rnd(5, 9)),
                    BackgroundColor3 = paletKonfeti[rnd(1, #paletKonfeti)],
                    BorderSizePixel = 0,
                    Rotation = rnd(0, 360),
                    ZIndex = 800,
                }, parent)
                local sudut = rnd(1, 360) * math.pi / 180
                local jarak = rnd(60, 150)
                local dur = rnd(55, 85) / 100
                tween(c, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(pos.X.Scale, pos.X.Offset + math.cos(sudut) * jarak,
                    pos.Y.Scale, pos.Y.Offset + math.sin(sudut) * jarak + 30),
                    Rotation = c.Rotation + rnd(180, 540),
                    BackgroundTransparency = 1,
                })
                task.delay(dur + 0.05, function() c:Destroy() end)
            end
        end
        emojiBurst = function(parent, pos, daftar, n)
            for _ = 1, n do
                local l = buat("TextLabel", {
                    Name = "NoFade",
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = pos,
                    Size = UDim2.fromOffset(24, 24),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.SourceSans,
                    Text = daftar[rnd(1, #daftar)],
                    TextSize = rnd(14, 22),
                    Rotation = rnd(-20, 20),
                    ZIndex = 801,
                }, parent)
                local sudut = rnd(1, 360) * math.pi / 180
                local jarak = rnd(70, 160)
                local dur = rnd(60, 90) / 100
                tween(l, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(pos.X.Scale, pos.X.Offset + math.cos(sudut) * jarak,
                    pos.Y.Scale, pos.Y.Offset + math.sin(sudut) * jarak - 40),
                    Rotation = l.Rotation + rnd(-180, 180),
                    TextTransparency = 1,
                })
                task.delay(dur + 0.05, function() l:Destroy() end)
            end
        end
        pusatDiRoot = function(gui)
            local sz = gui.AbsoluteSize
            return UDim2.new(0, gui.AbsolutePosition.X - root.AbsolutePosition.X + sz.X / 2,
            0, gui.AbsolutePosition.Y - root.AbsolutePosition.Y + sz.Y / 2)
        end

        -- [12] TOAST — KANAN ATAS LAYAR (stack vertikal) -------------------
        local notifHolder = buat("Frame", {
            Name = "NotifHolder",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -10, 0, 10),
            Size = UDim2.fromOffset(280, 400),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ZIndex = 980,
        }, screenGui)
        buat("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Top,
        }, notifHolder)
        local notifCounter = 0
        toast = function(teks, aksen)
            notifCounter += 1
            local t = buat("Frame", {
                Name = "NoFade",
                AnchorPoint = Vector2.new(1, 0),
                Size = UDim2.fromOffset(270, 32),
                BackgroundColor3 = Warna.Putih,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 981,
                LayoutOrder = notifCounter,
            }, notifHolder)
            buat("UICorner", {CornerRadius = UDim.new(0, 10)}, t)
            local st = buat("UIStroke", {Color = aksen or Warna.Ungu, Thickness = 1, Transparency = 1}, t)
            -- dot indikator warna
            local dot = buat("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 8, 0.5, 0),
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = aksen or Warna.Ungu,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, t)
            buat("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
            local lb = buat("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 22, 0, 0),
                Size = UDim2.new(1, -28, 1, 0),
                FontFace = fnt("semi"),
                Text = teks,
                TextColor3 = Warna.TeksGelap,
                TextSize = 13,
                TextTransparency = 1,
                TextTruncate = Enum.TextTruncate.AtEnd,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, t)
            -- animasi masuk: slide dari kanan + fade in
            t.Position = UDim2.new(1, 20, 0, 0)  -- start offset right
            local ti = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            tween(t,   ti, {BackgroundTransparency = 0.05, Position = UDim2.new(1, 0, 0, 0)})
            tween(st,  ti, {Transparency = 0.15})
            tween(dot, ti, {BackgroundTransparency = 0})
            tween(lb,  ti, {TextTransparency = 0})
            task.delay(1.6, function()
                local to = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                tween(t,   to, {BackgroundTransparency = 1, Position = UDim2.new(1, 20, 0, 0)})
                tween(st,  to, {Transparency = 1})
                tween(dot, to, {BackgroundTransparency = 1})
                tween(lb,  to, {TextTransparency = 1})
                task.delay(0.3, function() t:Destroy() end)
            end)
            -- batasi max 5 notif tampil
            local list = {}
            for _, c in ipairs(notifHolder:GetChildren()) do
                if c:IsA("Frame") and c.Name == "NoFade" then table.insert(list, c) end
            end
            if #list > 5 then
                list[1]:Destroy()
            end
        end

        -- [13] FADE PER-ELEMEN ----------------------------------------------
        local elemenFade = {}
        fadeVal = Instance.new("NumberValue")
        pcall(function() fadeVal.Parent = screenGui end)
        kumpulkanFade = function()
            table.clear(elemenFade)
            local daftar = outer:GetDescendants()
            table.insert(daftar, outer)
            for _, obj in ipairs(daftar) do
                if obj.Name ~= "NoFade" then
                    if obj:IsA("Frame") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
                        if obj.BackgroundTransparency < 1 then
                            table.insert(elemenFade, {obj, "BackgroundTransparency", obj.BackgroundTransparency})
                        end
                        if (obj:IsA("TextLabel") or obj:IsA("TextBox")) and obj.TextTransparency < 1 then
                            table.insert(elemenFade, {obj, "TextTransparency", obj.TextTransparency})
                        end
                    elseif obj:IsA("UIStroke") and obj.Transparency < 1 then
                        table.insert(elemenFade, {obj, "Transparency", obj.Transparency})
                    end
                end
            end
        end
        setFade = function(t)
            for _, e in ipairs(elemenFade) do
                e[1][e[2]] = e[3] + (1 - e[3]) * t
            end
        end
        fadeVal.Changed:Connect(setFade)

    end -- akhir buildFX()

    -- Eksekusi buildFX() sekarang (panel, root, outer sudah ada dari part1)
    buildFX()
    diagSet("efek OK — pasang logika fitur...")

    -- [14] LOGIKA UTAMA -------------------------------------------------
    -- Bungkus part logika dengan function untuk hemat local count (Luau limit 200)
    local function initLogic()

        -- [18] LOGIKA KING ---------------------------------------------------
        -- SPEED & JUMP
        applySpeed = function()
            local hum = getHum()
            if not hum then return end
            local base = State.SpeedOn and State.SpeedValue or CFG.SPEED_OFF
            -- v1.3.4: bonus berenang HANYA saat Shiftlock Tengah aktif —
            -- speed aktif × 1.025 (di darat & saat Tengah OFF = tanpa efek)
            if State.TengahOn and State.IsSwimming then
                base = base * CFG.SWIM_BONUS
            end
            hum.WalkSpeed = base
        end
        applyJump = function()
            local hum = getHum()
            if not hum then return end
            if hum.UseJumpPower then
                hum.JumpPower = State.JumpOn and State.JumpValue or CFG.OFF_JUMP
            else
                hum.JumpHeight = State.JumpOn and State.JumpHeightValue or CFG.OFF_JUMP_H
            end
        end
        updateJumpLabel = function()
            local hum = getHum()
            if JumpLabel then
                JumpLabel.Text = (hum and hum.UseJumpPower) and "JumpPower" or "JumpHeight (auto)"
            end
            if RefreshJump then RefreshJump() end
        end

        -- label Speed menampilkan nilai state saat ini (ON/OFF, nilai via stepper)
        local function updateSpeedLabel()
            if SpeedLabel and SpeedLabel.Parent then
                SpeedLabel.Text = "Speed (Q): "
                .. (State.SpeedOn and fmtNum(State.SpeedValue) or ("OFF (" .. fmtNum(CFG.SPEED_OFF) .. ")"))
            end
        end
        local function syncNotify(name, v, silent, label)
            local sw = Switches[name]
            if sw then sw.set(v) end
            if not silent then
                toast(label .. ": " .. (v and "ON" or "OFF"), v and Warna.Hijau or Warna.Merah)
            end
        end
        Setters.Speed = function(v, silent)
            if State.SpeedOn == v then return end
            State.SpeedOn = v
            applySpeed()
            updateSpeedLabel()
            if not v then
                task.spawn(function()
                    for _ = 1, 8 do
                        task.wait(0.25)
                        if State.SpeedOn or State.Removed then return end
                        local h = getHum()
                        if h and h.WalkSpeed ~= CFG.SPEED_OFF then
                            h.WalkSpeed = CFG.SPEED_OFF
                        end
                    end
                end)
            end
            syncNotify("Speed", v, silent, "Speed")
        end
        Setters.Jump = function(v, silent)
            if State.JumpOn == v then return end
            State.JumpOn = v
            applyJump()
            if not v then
                task.spawn(function()
                    for _ = 1, 8 do
                        task.wait(0.25)
                        if State.JumpOn or State.Removed then return end
                        local h = getHum()
                        if h then
                            if h.UseJumpPower and h.JumpPower ~= CFG.OFF_JUMP then
                                h.JumpPower = CFG.OFF_JUMP
                            elseif not h.UseJumpPower and h.JumpHeight ~= CFG.OFF_JUMP_H then
                                h.JumpHeight = CFG.OFF_JUMP_H
                            end
                        end
                    end
                end)
            end
            syncNotify("Jump", v, silent, "JumpPower")
        end

        -- [v1.4] CEK KENDARAAN — dipakai Shiftlock Mobile & Moonwalk.
        -- Duduk di Seat/VehicleSeat apa pun (mobil/motor/kursi) = badan
        -- "menyatu" dgn kendaraan lewat weld. Kalau mesin tetap memaksa
        -- hrp.CFrame menghadap kamera, yang ikut terpaku/terputar justru
        -- KENDARAANNYA (mobil muter sendiri / terpaku ke arah kamera).
        -- Solusi: selama duduk, kedua mesin DIAM TOTAL (tidak sentuh
        -- CFrame) + AutoRotate dikembalikan sementara ke bawaan game.
        -- Turun dari kendaraan = efek jalan lagi otomatis (toggle tetap
        -- ON, tanpa perlu matikan-pasang ulang).
        local function sedangDuduk(h)
            return h ~= nil and (h.SeatPart ~= nil or h.Sit == true)
        end

        -- SHIFTLOCK MOBILE
        Setters.Shift = function(v, silent)
            if State.ShiftOn == v then return end
            State.ShiftOn = v
            if v then
                -- anti bentrok orientasi: Shiftlock Tengah dimatikan dulu
                if State.TengahOn then setFeature("Tengah", false, true) end
                local hum = getHum()
                if hum then hum.AutoRotate = false end
                RunService:BindToRenderStep("KS_SHIFTLOCK", Enum.RenderPriority.Character.Value + 1, function()
                    local char = getChar()
                    local h = char and char:FindFirstChildOfClass("Humanoid")
                    local r = char and char:FindFirstChild("HumanoidRootPart")
                    -- [v1.4] naik kendaraan = TANPA EFEK: jangan sentuh CFrame
                    -- sama sekali, AutoRotate dikembalikan sementara ke bawaan
                    -- game supaya kendaraan dikendarai 100% normal
                    if h and sedangDuduk(h) then
                        if not h.AutoRotate then h.AutoRotate = true end
                        return
                    end
                    -- jaga AutoRotate tetap OFF saat jalan kaki (mis. script
                    -- game menghidupkan lagi setelah turun kendaraan)
                    if h and h.AutoRotate then h.AutoRotate = false end
                    if h and r and h.Health > 0 then
                        local cam = Workspace.CurrentCamera
                        local _, yaw = cam.CFrame:ToOrientation()
                        r.CFrame = CFrame.new(r.Position) * CFrame.Angles(0, yaw, 0)
                    end
                end)
            else
                RunService:UnbindFromRenderStep("KS_SHIFTLOCK")
                local hum = getHum()
                if hum then hum.AutoRotate = true end
                applySpeed()
            end
            syncNotify("Shift", v, silent, "Shiftlock Mobile")
        end

        -- MOONWALK (F) — badan TERKUNCI menghadap kamera/layar saat jalan.
        -- Rotasi CEPAT + HENTAKAN: kecepatan putar dibatasi CFG.MOON_TURN_MAX
        -- (balik badan kencang), lalu kunci tegas ke arah target via lerp sudut
        -- terpendek dgn kekerasan CFG.MOON_SMOOTH (anti muter keliling).
        Setters.Moon = function(v, silent)
            if State.MoonOn == v then return end
            State.MoonOn = v
            if v then
                -- anti bentrok orientasi: Shiftlock Tengah dimatikan dulu
                if State.TengahOn then setFeature("Tengah", false, true) end
                local hum = getHum()
                if hum then hum.AutoRotate = false end
                RunService:BindToRenderStep("KS_MOONWALK", Enum.RenderPriority.Character.Value + 1, function(dt)
                    local char = getChar()
                    local h = char and char:FindFirstChildOfClass("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    -- [v1.4] naik kendaraan = TANPA EFEK: badan tidak dipaksa
                    -- menghadap kamera, jadi mobil/motor tidak ikut dibalik
                    -- 180° / terpaku ke arah kamera saat digas
                    if h and sedangDuduk(h) then
                        if not h.AutoRotate then h.AutoRotate = true end
                        return
                    end
                    if h and h.AutoRotate then h.AutoRotate = false end
                    if h and hrp and h.Health > 0 then
                        local cam = Workspace.CurrentCamera
                        -- DIAM = TIDAK BEROTASI: badan hanya mengejar kamera saat
                        -- karakter benar-benar bergerak (ada arah input). Berdiri
                        -- tenang = badan tetap di arah terakhir, tidak berputar.
                        if cam and h.MoveDirection.Magnitude > 0.01 then
                            local _, yawCam = cam.CFrame:ToOrientation()
                            -- putar 180 derajat = badan menghadap kamera
                            local target = yawCam + math.pi
                            -- CEPAT + HENTAKAN: putar kencang dgn batas kecepatan,
                            -- lalu kunci tegas ke target (lerp sudut terpendek).
                            local _, yawSek = hrp.CFrame:ToOrientation()
                            local selisih = ((target - yawSek + math.pi) % (2 * math.pi)) - math.pi
                            local langkah = selisih * math.min(dt * CFG.MOON_SMOOTH, 1)
                            local maks = CFG.MOON_TURN_MAX * dt
                            if langkah > maks then langkah = maks elseif langkah < -maks then langkah = -maks end
                            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yawSek + langkah, 0)
                        end
                    end
                end)
            else
                RunService:UnbindFromRenderStep("KS_MOONWALK")
                local hum = getHum()
                if hum then hum.AutoRotate = true end
            end
            syncNotify("Moon", v, silent, "Moonwalk")
        end

        -- SHIFTLOCK TENGAH (v1.2.0, revisi v1.3.3) — port "SHIFT LOCK TENGAH v2"
        -- Kamera TIDAK diubah sama sekali (CameraOffset tetap di-tween ke
        -- Vector3.zero seperti v1.2.0). Yang digeser cuma LETAK lingkaran kursor:
        -- panah komputer disembunyikan (MouseIconEnabled false) dan diganti
        -- lingkaran mini (CFG.SLT_DOT px) yang letaknya digeser ke bawah layar
        -- (CFG.SLT_DOT_Y, default 0.60 = sekitar pinggang/bawah badan karakter),
        -- kecil biar ga ganggu. Mekanisme native: MouseBehavior.LockCenter +
        -- RotationType.CameraRelative dijaga tiap frame via RenderStep (Camera+1).
        -- Toggle: LShift / RShift / switch GUI. Auto OFF saat mati/respawn
        -- (matikanGerak) + saling menonaktif dgn Shiftlock Mobile & Moonwalk.
        local sltTween, sltTweening, sltOffsetAsli = nil, false, nil
        local sltDotGui, sltDot  -- lingkaran kursor mini (revisi v1.3.2/v1.3.3)
        local sltUGS
        pcall(function() sltUGS = UserSettings():GetService("UserGameSettings") end)
        -- [v1.3.2/v1.3.3] lingkaran kursor mini, letaknya digeser ke bawah layar
        local function sltDotShow()
            if sltDot then sltDot.Visible = true return end
            sltDotGui = buat("ScreenGui", {
                Name = "BALAP_TengahDot",
                ResetOnSpawn = false,
                DisplayOrder = 99999,
                IgnoreGuiInset = true, -- skala Y dihitung dari seluruh layar
            })
            sltDot = buat("Frame", {
                Name = "Lingkaran",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, CFG.SLT_DOT_Y), -- digeser ke bawah
                Size = UDim2.fromOffset(CFG.SLT_DOT, CFG.SLT_DOT),
                BackgroundColor3 = Warna.Putih,
                BackgroundTransparency = 0.1,
                BorderSizePixel = 0,
            }, sltDotGui)
            buat("UICorner", {CornerRadius = UDim.new(1, 0)}, sltDot) -- jadi lingkaran
            buat("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1,
                Transparency = 0.35}, sltDot)
            -- pasang ke tempat aman (gethui/CoreGui/PlayerGui), buang sisa lama dulu
            local kandidat = {}
            pcall(function() if gethui then table.insert(kandidat, gethui()) end end)
            pcall(function() table.insert(kandidat, game:GetService("CoreGui")) end)
            pcall(function() table.insert(kandidat, LocalPlayer:WaitForChild("PlayerGui")) end)
            for _, t in ipairs(kandidat) do
                pcall(function()
                    local lama = t:FindFirstChild("BALAP_TengahDot")
                    if lama and lama ~= sltDotGui then lama:Destroy() end
                end)
            end
            for _, t in ipairs(kandidat) do
                local ok = pcall(function() sltDotGui.Parent = t end)
                if ok and sltDotGui.Parent == t then break end
            end
        end
        local function sltDotHide()
            if sltDot then sltDot.Visible = false end
        end
        Setters.Tengah = function(v, silent)
            if State.TengahOn == v then return end
            State.TengahOn = v
            if v then
                -- anti bentrok: matikan Shiftlock Mobile & Moonwalk dulu
                if State.ShiftOn then setFeature("Shift", false, true) end
                if State.MoonOn then setFeature("Moon", false, true) end
                local hum = getHum()
                if hum then
                    sltOffsetAsli = hum.CameraOffset  -- simpan offset asli game
                    sltTweening = true
                    if sltTween then sltTween:Cancel() end
                    sltTween = TweenService:Create(hum,
                    TweenInfo.new(CFG.SLT_WAKTU, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {CameraOffset = Vector3.zero})
                    sltTween:Play()
                    sltTween.Completed:Connect(function() sltTweening = false end)
                end
                pcall(function() RunService:UnbindFromRenderStep("KS_TENGAH") end)
                RunService:BindToRenderStep("KS_TENGAH", Enum.RenderPriority.Camera.Value + 1, function()
                    local h = getHum()
                    if h and h.Health > 0 then
                        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                        if sltUGS then
                            pcall(function() sltUGS.RotationType = Enum.RotationType.CameraRelative end)
                        end
                        -- jaga offset tetap 0 setelah tween selesai (kamera standar)
                        if not sltTweening and h.CameraOffset ~= Vector3.zero then
                            h.CameraOffset = Vector3.zero
                        end
                    end
                end)
                -- v1.3.2: sembunyikan panah komputer, tampilkan lingkaran mini
                pcall(function() UserInputService.MouseIconEnabled = false end)
                sltDotShow()
            else
                pcall(function() RunService:UnbindFromRenderStep("KS_TENGAH") end)
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                if sltUGS then
                    pcall(function() sltUGS.RotationType = Enum.RotationType.MovementRelative end)
                end
                if sltTween then sltTween:Cancel() end
                local hum = getHum()
                if hum and sltOffsetAsli then hum.CameraOffset = sltOffsetAsli end
                sltOffsetAsli = nil
                -- v1.3.2: panah komputer balik, lingkaran disembunyikan
                pcall(function() UserInputService.MouseIconEnabled = true end)
                sltDotHide()
            end
            applySpeed()   -- v1.3.4: bonus berenang langsung menyesuaikan / pulih
            syncNotify("Tengah", v, silent, "Shiftlock Tengah")
        end

        -- TIANG PENANDA (tab TITIK) — tampilkan/sembunyikan tiang checkpoint.
        -- Daftar titik & data file TIDAK ikut hilang, cuma tiangnya yang dihide.
        Setters.Tiang = function(v, silent)
            if State.TiangOn == v then return end
            State.TiangOn = v
            if v then
                titikRender()
            else
                if titikFolder then titikFolder:Destroy() titikFolder = nil end
            end
            syncNotify("Tiang", v, silent, "Tampilkan Tiang")
        end

        -- HIDE PLAYER + KENDARAAN
        local hiddenParts, hiddenBB, hiddenHumans, hiddenCharConns = {}, {}, {}, {}
        local function hideApplyTo(obj)
            if (obj:IsA("BasePart") or obj:IsA("Decal")) and hiddenParts[obj] == nil then
                hiddenParts[obj] = obj.Transparency
                obj.Transparency = 1
            elseif obj:IsA("BillboardGui") and hiddenBB[obj] == nil then
                hiddenBB[obj] = obj.Enabled
                obj.Enabled = false
            end
        end
        local function hideCharacter(char)
            if hiddenCharConns[char] then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hiddenHumans[hum] = hum.DisplayDistanceType
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            end
            for _, obj in ipairs(char:GetDescendants()) do hideApplyTo(obj) end
            hiddenCharConns[char] = char.DescendantAdded:Connect(hideApplyTo)
        end
        local function unhideCharacter(char)
            local conn = hiddenCharConns[char]
            if conn then conn:Disconnect() hiddenCharConns[char] = nil end
        end
        local function unhideAll()
            for obj, t in pairs(hiddenParts) do
                pcall(function() if obj.Parent then obj.Transparency = t end end)
            end
            table.clear(hiddenParts)
            for obj, e in pairs(hiddenBB) do
                pcall(function() if obj.Parent then obj.Enabled = e end end)
            end
            table.clear(hiddenBB)
            for hum, d in pairs(hiddenHumans) do
                pcall(function() if hum.Parent then hum.DisplayDistanceType = d end end)
            end
            table.clear(hiddenHumans)
            for char in pairs(hiddenCharConns) do unhideCharacter(char) end
        end
        local vehParts = {}
        local overlapParams = OverlapParams.new()
        local function isMyStuff(model)
            local char = getChar()
            if not char then return false end
            if model == char or char:IsDescendantOf(model) then return true end
            local hum = getHum()
            if hum and hum.SeatPart then
                if hum.SeatPart:FindFirstAncestorOfClass("Model") == model then return true end
            end
            return false
        end
        local function vehicleModelFromPart(part)
            local m = part:FindFirstAncestorOfClass("Model")
            while m do
                if m:FindFirstChildWhichIsA("Humanoid", true) then return nil end
                if m:FindFirstChildWhichIsA("VehicleSeat", true) or m:FindFirstChildWhichIsA("Seat", true) then
                    local s = m:GetExtentsSize()
                    if math.max(s.X, s.Y, s.Z) <= 64 then return m end
                    return nil
                end
                m = m:FindFirstAncestorOfClass("Model")
            end
            return nil
        end
        local function applyVehicleHide(model)
            local set = vehParts[model]
            if not set then set = {} vehParts[model] = set end
            for _, p in ipairs(model:GetDescendants()) do
                if p:IsA("BasePart") and set[p] == nil then
                    set[p] = p.Transparency
                    p.Transparency = math.max(p.Transparency, 0.8)
                end
            end
        end
        local function restoreVehicle(model)
            local set = vehParts[model]
            if not set then return end
            vehParts[model] = nil
            for p, t in pairs(set) do
                pcall(function() if p.Parent then p.Transparency = t end end)
            end
        end
        local function updateVehicles()
            local char = getChar()
            local r = char and char:FindFirstChild("HumanoidRootPart")
            if not r then return end
            overlapParams.FilterType = Enum.RaycastFilterType.Exclude
            overlapParams.FilterDescendantsInstances = char and {char} or {}
            local near = {}
            for _, part in ipairs(Workspace:GetPartBoundsInRadius(r.Position, 20, overlapParams)) do
                local m = vehicleModelFromPart(part)
                if m and not isMyStuff(m) then near[m] = true end
            end
            for m in pairs(near) do applyVehicleHide(m) end
            for m in pairs(vehParts) do
                if not near[m] then restoreVehicle(m) end
            end
        end
        local function restoreAllVehicles()
            for m in pairs(vehParts) do restoreVehicle(m) end
        end
        local function playerHideHook(plr)
            if plr == LocalPlayer then return end
            plr.CharacterAdded:Connect(function(char)
                task.wait(0.4)
                if State.HideOn and not State.Removed then hideCharacter(char) end
            end)
            if plr.Character and State.HideOn then hideCharacter(plr.Character) end
        end
        Setters.Hide = function(v, silent)
            if State.HideOn == v then return end
            State.HideOn = v
            if v then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then hideCharacter(plr.Character) end
                end
            else
                unhideAll()
                restoreAllVehicles()
            end
            syncNotify("Hide", v, silent, "Hide Player + Kendaraan")
        end

        -- HIDE BADAN ATAS — sembunyikan KEPALA s/d BADAN & TANGAN milik
        -- DIRI SENDIRI, hanya di layar sendiri (LocalTransparencyModifier).
        -- Tetap tampil: pinggang ke bawah (celana) + kaki + sepatu.
        -- klasifikasi 4 LAPIS (rambut/aksesoris atas sering lolos):
        --   1) nama part tubuh standar (R15/R6) -> langsung diketahui
        --   2) rantai weld/joint (Weld, WeldConstraint, Motor6D, AccessoryWeld)
        --      sampai 6 hop -> part tubuh tempat menempel
        --      (banyak rambut/topi modern pakai WeldConstraint)
        --   3) peta attachment: attachment milik aksesoris dicocokkan ke attachment
        --      part tubuh (cara resmi Roblox menentukan posisi aksesoris)
        --   4) posisi dunia: di atas garis pinggang (HRP - 1 stud) = sembunyi,
        --      di bawah = tampil (jaring pengaman rambut/topi tanpa weld)
        --   Kalau semua gagal -> SEMBUNYI (ragu = sembunyi; yang tampil hanya
        --   kaki/celana/sepatu sesuai permintaan).
        -- Decal (muka, lensa, tekstur) di dalam part sembunyi ikut dihilangkan.
        local atasConn, atasT = nil, 0
        local atasDecalOrig = {}
        local ATAS_R15 = {
            Head = true, UpperTorso = true,
            LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
            RightUpperArm = true, RightLowerArm = true, RightHand = true,
        }
        local ATAS_R6 = { Head = true, Torso = true, ["Left Arm"] = true, ["Right Arm"] = true }
        local BADAN_KENAL = {
            Head = true, UpperTorso = true, LowerTorso = true,
            LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
            RightUpperArm = true, RightLowerArm = true, RightHand = true,
            LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
            RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
            Torso = true, ["Left Arm"] = true, ["Right Arm"] = true,
            ["Left Leg"] = true, ["Right Leg"] = true, HumanoidRootPart = true,
        }
        local function atasIkat(part, hop)   -- telusuri rantai weld/joint -> nama part tubuh
            if hop > 6 then return nil end
            for _, w in ipairs(part:GetChildren()) do
                if w:IsA("Motor6D") or w:IsA("Weld") or w:IsA("AccessoryWeld") or w:IsA("WeldConstraint") then
                    local lain = (w.Part0 == part) and w.Part1 or w.Part0
                    if lain then
                        if BADAN_KENAL[lain.Name] then return lain.Name end
                        local r = atasIkat(lain, hop + 1)
                        if r then return r end
                    end
                end
            end
            return nil
        end
        local function atasCariAcc(part)     -- naik lewat Parent, cari Accessory induk
            local p = part.Parent
            local hop = 0
            while p and hop < 4 do
                if p:IsA("Accessory") then return p end
                p = p.Parent
                hop = hop + 1
            end
            return nil
        end
        local function atasSapu(on)
            local char = LocalPlayer.Character
            if not char then return end
            -- garis pinggang: HRP turun 1 stud (kaki/celana/sepatu di bawahnya tetap tampil)
            local batasY = nil
            pcall(function()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then batasY = hrp.Position.Y - 1.0 end
            end)
            -- peta attachment part tubuh: nama attachment -> part pemiliknya
            local petaIkat = {}
            for _, bp in ipairs(char:GetDescendants()) do
                pcall(function()
                    if bp:IsA("BasePart") and BADAN_KENAL[bp.Name] then
                        for _, c in ipairs(bp:GetChildren()) do
                            if c:IsA("Attachment") then petaIkat[c.Name] = bp.Name end
                        end
                    end
                end)
            end
            for _, d in ipairs(char:GetDescendants()) do
                pcall(function()
                    if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                        local sembunyi = false
                        if BADAN_KENAL[d.Name] then
                            sembunyi = (ATAS_R15[d.Name] or ATAS_R6[d.Name]) and true or false
                        else
                            local tubuh = atasIkat(d, 0)          -- lapis 2: rantai weld
                            if tubuh then
                                sembunyi = (ATAS_R15[tubuh] or ATAS_R6[tubuh]) and true or false
                            else
                                local acc = atasCariAcc(d)         -- lapis 3: peta attachment
                                local att = acc and acc:FindFirstChildWhichIsA("Attachment", true) or nil
                                local owner = att and petaIkat[att.Name] or nil
                                if owner then
                                    sembunyi = (ATAS_R15[owner] or ATAS_R6[owner]) and true or false
                                else
                                    local okP, pos = pcall(function() return d.Position end)
                                    if okP and pos and batasY then  -- lapis 4: posisi vs garis pinggang
                                        sembunyi = pos.Y > batasY
                                    else
                                        sembunyi = true             -- ragu = sembunyi
                                    end
                                end
                            end
                        end
                        if on then
                            if sembunyi then
                                d.LocalTransparencyModifier = 1
                                for _, c in ipairs(d:GetDescendants()) do
                                    if c:IsA("Decal") then
                                        if atasDecalOrig[c] == nil then atasDecalOrig[c] = c.Transparency end
                                        c.Transparency = 1
                                    end
                                end
                            end
                        else
                            d.LocalTransparencyModifier = 0
                        end
                    end
                end)
            end
            if not on then
                for c, tr in pairs(atasDecalOrig) do
                    pcall(function() if c.Parent then c.Transparency = tr end end)
                end
                table.clear(atasDecalOrig)
            end
        end
        Setters.HideAtas = function(v, silent)
            if State.HideAtasOn == v then return end
            State.HideAtasOn = v
            if v then
                atasSapu(true)
                atasT = 0
                atasConn = RunService.Heartbeat:Connect(function(dt)
                    if not State.HideAtasOn or State.Removed then return end
                    atasT = atasT + dt
                    if atasT >= 0.3 then
                        atasT = 0
                        atasSapu(true)   -- self-heal: reset part/respawn tertangani di sini
                    end
                end)
            else
                if atasConn then atasConn:Disconnect() atasConn = nil end
                atasSapu(false)
            end
            syncNotify("HideAtas", v, silent, "Hide Badan Atas")
        end

        -- LIGHTWEIGHT (Partikel / Bayangan / Efek)
        local lwEffects, lwConns = {}, {}
        local function lwDisable(obj)
            local dis = obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
            or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("PostEffect")
            if dis and lwEffects[obj] == nil then
                lwEffects[obj] = obj.Enabled
                obj.Enabled = false
            end
        end
        Setters.LW = function(v, silent)
            if State.LWOn == v then return end
            State.LWOn = v
            if v then
                Original.GlobalShadows = Lighting.GlobalShadows
                Lighting.GlobalShadows = false
                Original.WaterWaveSize = Terrain.WaterWaveSize
                Original.WaterWaveSpeed = Terrain.WaterWaveSpeed
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                for _, obj in ipairs(Workspace:GetDescendants()) do lwDisable(obj) end
                for _, obj in ipairs(Lighting:GetDescendants()) do lwDisable(obj) end
                table.insert(lwConns, Workspace.DescendantAdded:Connect(function(obj) task.defer(lwDisable, obj) end))
                table.insert(lwConns, Lighting.DescendantAdded:Connect(function(obj) task.defer(lwDisable, obj) end))
            else
                if Original.GlobalShadows ~= nil then Lighting.GlobalShadows = Original.GlobalShadows end
                if Original.WaterWaveSize ~= nil then Terrain.WaterWaveSize = Original.WaterWaveSize end
                if Original.WaterWaveSpeed ~= nil then Terrain.WaterWaveSpeed = Original.WaterWaveSpeed end
                for obj, e in pairs(lwEffects) do
                    pcall(function() if obj.Parent then obj.Enabled = e end end)
                end
                table.clear(lwEffects)
                for _, c in ipairs(lwConns) do c:Disconnect() end
                table.clear(lwConns)
            end
            syncNotify("LW", v, silent, "Lightweight")
        end

        -- DINDING BATAS (upgrade: lihat dinding tak terlihat -> jalur tipis gampang dicari)
        -- Dinding invisible (CanCollide + nyaris transparan) dibikin kelihatan:
        --   isi abu gelap tembus pandang (60%) + garis tepi, jadi dinding se tipis
        --   apa pun tetap kebaca dari jauh. Tanpa bikin part baru -> tetap ringan.
        local wallOriginal = {}
        local wallBoxes = {}   -- part -> SelectionBox (garis tepi)
        local wallConn
        local WALL_ISI  = Color3.fromRGB(70, 70, 70)    -- isi abu gelap
        local WALL_TEPI = Color3.fromRGB(150, 150, 150) -- garis tepi abu sedang
        local function isWallCandidate(part)
            if not part:IsA("BasePart") or part == Terrain then return false end
            if part.Transparency < 0.95 then return false end  -- tangkap juga yang "hampir" tak terlihat
            if not part.CanCollide then return false end
            local m = part:FindFirstAncestorOfClass("Model")
            if m and Players:GetPlayerFromCharacter(m) then return false end
            return true
        end
        local function wallify(part)
            if wallOriginal[part] then return end
            wallOriginal[part] = {Transparency = part.Transparency, Color = part.Color}
            part.Transparency = 0.6
            part.Color = WALL_ISI
            pcall(function()
                local box = Instance.new("SelectionBox")
                box.Adornee = part
                box.LineThickness = 0.05
                box.Color3 = WALL_TEPI
                box.SurfaceTransparency = 1
                box.Visible = true
                box.Parent = part   -- ikut terhapus otomatis kalau part-nya dihancurkan game
                wallBoxes[part] = box
            end)
        end
        Setters.Walls = function(v, silent)
            if State.WallsOn == v then return end
            State.WallsOn = v
            if v then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if isWallCandidate(obj) then wallify(obj) end
                end
                wallConn = Workspace.DescendantAdded:Connect(function(obj)
                    task.defer(function()
                        if State.WallsOn and isWallCandidate(obj) then wallify(obj) end
                    end)
                end)
            else
                if wallConn then wallConn:Disconnect() wallConn = nil end
                for part, d in pairs(wallOriginal) do
                    pcall(function()
                        if part.Parent then
                            part.Transparency = d.Transparency
                            part.Color = d.Color
                        end
                    end)
                end
                for _, box in pairs(wallBoxes) do
                    pcall(function() box:Destroy() end)
                end
                table.clear(wallOriginal)
                table.clear(wallBoxes)
            end
            syncNotify("Walls", v, silent, "Dinding Batas")
        end

        -- CAHAYA AUTO DUA ARAH (baru v2.0 — pengganti Auto Terang lama dari E)
        -- Malam (< 6 atau >= 18) → terangi   : ClockTime ≈ 14, Brightness naik ≈ 2.5, fog gelap dibuka
        -- Siang                  → gelapkan  : ClockTime ≈ 17.5 (senja lembut), Brightness ≈ 1.6 (anti-silau)
        -- Loop penjaga tiap ~2 detik; saat OFF semua nilai asli di-restore.
        local CAHAYA = {
            JAM_MALAM_MULAI  = 18,
            JAM_MALAM_AKHIR  = 6,
            CLOCK_TERANGI    = 14,
            BRIGHT_TERANGI   = 2.5,
            AMBIENT_TERANGI  = Color3.fromRGB(140, 140, 165),
            CLOCK_ANTISILAU  = 17.5,
            BRIGHT_ANTISILAU = 1.6,
            AMBIENT_LEMBUT   = Color3.fromRGB(110, 110, 120),
            FOG_BUKA         = 100000,
        }
        local lightPernahAktif = false
        local function apakahMalam()
            local t = Lighting.ClockTime
            return t >= CAHAYA.JAM_MALAM_MULAI or t < CAHAYA.JAM_MALAM_AKHIR
        end
        local function targetCahaya()
            if apakahMalam() then
                return CAHAYA.CLOCK_TERANGI, CAHAYA.BRIGHT_TERANGI, CAHAYA.AMBIENT_TERANGI
            end
            return CAHAYA.CLOCK_ANTISILAU, CAHAYA.BRIGHT_ANTISILAU, CAHAYA.AMBIENT_LEMBUT
        end

        -- ClockTime wrap 0-24: jangan di-tween mentah — step bertahap via loop task.wait
        local function langkahCahaya()
            local jamTarget, brightTarget, ambientTarget = targetCahaya()
            local jam0 = Lighting.ClockTime
            local delta = jamTarget - jam0
            if delta > 12 then delta -= 24 elseif delta < -12 then delta += 24 end
            local bright0 = Lighting.Brightness
            local ambient0 = Lighting.Ambient
            local out0 = Lighting.OutdoorAmbient
            local jumlah = 22
            for i = 1, jumlah do
                if not State.LightOn or State.Removed then return end
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
        Setters.Light = function(v, silent)
            if State.LightOn == v then return end
            State.LightOn = v
            if v then
                lightPernahAktif = true
                -- capture original first (ClockTime/Brightness/Exposure/FogEnd disimpan semua)
                oLight.Brightness = Lighting.Brightness
                oLight.Ambient = Lighting.Ambient
                oLight.OutdoorAmbient = Lighting.OutdoorAmbient
                oLight.ClockTime = Lighting.ClockTime
                oLight.ExposureCompensation = Lighting.ExposureCompensation
                oLight.FogEnd = Lighting.FogEnd
                -- turunkan fog gelap bila ada (biar malam yang diterangi tidak berkabut)
                if Lighting.FogEnd < 5000 then
                    Lighting.FogEnd = CAHAYA.FOG_BUKA
                end
                if lightConn then task.cancel(lightConn) end
                lightConn = task.spawn(function()
                    while State.LightOn and not State.Removed do
                        langkahCahaya()
                        -- loop penjaga: tiap ~2 detik cek ClockTime lagi
                        -- (kalau game mengubah jam ke malam saat ON → otomatis diterangi lagi,
                        --  kalau ke siang terik → digelapkan sedikit lagi)
                        local tunggu = 0
                        while tunggu < 2 and State.LightOn and not State.Removed do
                            task.wait(0.25)
                            tunggu += 0.25
                        end
                    end
                end)
            else
                if lightConn then task.cancel(lightConn) lightConn = nil end
                pcall(function()
                    Lighting.ClockTime = oLight.ClockTime
                    Lighting.Brightness = oLight.Brightness
                    Lighting.Ambient = oLight.Ambient
                    Lighting.OutdoorAmbient = oLight.OutdoorAmbient
                    Lighting.ExposureCompensation = oLight.ExposureCompensation
                    Lighting.FogEnd = oLight.FogEnd
                end)
            end
            syncNotify("Light", v, silent, "Cahaya Auto")
        end

        -- Q — Speed ON/OFF murni
        -- Nilai ON (17.25 / 21.25, atau di antaranya) dipilih via stepper di Tab GERAK.
        -- Keybind Q langsung panggil setFeature("Speed", ...) dari handler [21].

        -- REJOIN
        rejoin = function()
            toast("🔁 Rejoin: balik ke server dalam 3 detik...", Warna.Biru)
            task.delay(3, function()
                local ok = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end)
                if not ok then
                    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
                end
            end)
        end

        -- HAPUS SCRIPT — BERSIH TOTAL, TIDAK ADA YANG TERTINGGAL
        unloadScript = function()
            if State.Removed then return end
            State.Removed = true
            -- 1) Matikan semua fitur (restore visual, kendaraan, dinding, cahaya)
            pcall(setFeature, "Speed", false, true)
            pcall(setFeature, "Jump", false, true)
            pcall(setFeature, "Shift", false, true)
            pcall(setFeature, "Moon", false, true)
            pcall(setFeature, "Tengah", false, true)
            pcall(setFeature, "Tiang", false, true)
            pcall(setFeature, "Hide", false, true)
            pcall(setFeature, "LW", false, true)
            pcall(setFeature, "Walls", false, true)
            pcall(setFeature, "Light", false, true)
            pcall(setFeature, "HideAtas", false, true)
            -- 2) Unbind semua RenderStep binding
            pcall(function() RunService:UnbindFromRenderStep("KS_SHIFTLOCK") end)
            pcall(function() RunService:UnbindFromRenderStep("KS_MOONWALK") end)
            pcall(function() RunService:UnbindFromRenderStep("KS_TENGAH") end)
            pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
            pcall(function()
                UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.MovementRelative
            end)
            pcall(function() UserInputService.MouseIconEnabled = true end)
            pcall(function()
                if sltDotGui then sltDotGui:Destroy() end
                sltDotGui, sltDot = nil, nil
            end)
            -- 3) Cancel semua task/thread yang masih jalan
            if lightConn then pcall(function() task.cancel(lightConn) end) lightConn = nil end
            -- 3) Disconnect SEMUA event yang di-catat lewat catat()
            for _, c in ipairs(semuaKoneksi) do
                pcall(function() c:Disconnect() end)
            end
            table.clear(semuaKoneksi)
            -- 4) Restore Lighting ke kondisi awal (hanya kalau Cahaya pernah ON)
            pcall(function()
                if lightPernahAktif and oLight then
                    Lighting.ClockTime = oLight.ClockTime
                    Lighting.Brightness = oLight.Brightness
                    Lighting.Ambient = oLight.Ambient
                    Lighting.OutdoorAmbient = oLight.OutdoorAmbient
                    Lighting.ExposureCompensation = oLight.ExposureCompensation
                    Lighting.FogEnd = oLight.FogEnd
                end
            end)
            -- 5) Restore Terrain water (kalau LW pernah diaktifkan)
            pcall(function()
                if Original then
                    if Original.GlobalShadows ~= nil then Lighting.GlobalShadows = Original.GlobalShadows end
                    if Original.WaterWaveSize ~= nil then Terrain.WaterWaveSize = Original.WaterWaveSize end
                    if Original.WaterWaveSpeed ~= nil then Terrain.WaterWaveSpeed = Original.WaterWaveSpeed end
                end
            end)
            -- 6) Reset karakter: WalkSpeed, JumpPower, JumpHeight, AutoRotate
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local h = char:FindFirstChildOfClass("Humanoid")
                    if h then
                        h.WalkSpeed = 16
                        if h.UseJumpPower then
                            h.JumpPower = 50
                        else
                            h.JumpHeight = 7.2
                        end
                        h.AutoRotate = true
                    end
                end
            end)
            -- 7) Hapus ScreenGui (parent dari semua UI: panel, notif, footer, dll)
            pcall(function() if screenGui then screenGui:Destroy() end end)
            -- 8) Clear global flag supaya script bisa di-execute lagi
            _G.__BALAP_MAIN__ = nil
            _G.__KS_DELETE_ARMED__ = nil
            -- 9) Destroy script itu sendiri (kalau via LocalScript)
            pcall(function()
                if script and script.Parent then
                    script.Disabled = true
                    script:Destroy()
                end
            end)
            print("[BALAP] Script dihapus total — semua dibersihkan ✔")
        end

        -- v1.2.3 WATCHDOG TAKEOVER: instance lama bunuh diri otomatis begitu ada
        -- eksekusi BALAP yang lebih baru. Pemicu (cukup salah satu, cek tiap 0.5 dtk):
        --   (1) _G.__BALAP_TOKEN__ bukan miliknya      -> executor share _G
        --   (2) screenGui sudah dihapus eksekusi baru  -> executor isolasi _G
        --       (sweep "BalapMain" di awal eksekusi baru yang menghapusnya)
        -- Dulu ini penyebab siluman: Heartbeat Fall Assist instance lama tetap
        -- mem-pulse dengan potongan 30%, walau GUI baru sudah diset 0%.
        task.spawn(function()
            while not State.Removed do
                if _G.__BALAP_TOKEN__ ~= MY_TOKEN or not screenGui.Parent then
                    pcall(function() unloadScript() end)
                    break
                end
                task.wait(0.5)
            end
        end)

        -- KARAKTER: PASANG ULANG SAAT RESPAWN
        local initedChar
        local function initCharacter(char)
            if State.Removed then return end
            if initedChar == char then return end
            initedChar = char
            local hum = char:WaitForChild("Humanoid", 10)
            if not hum then return end
            updateJumpLabel()
            -- REVISI v1.1.0 + v1.2.0: Shiftlock, Moonwalk & Shiftlock Tengah
            -- OTOMATIS OFF saat mati/respawn. Dua lapis: langsung saat humanoid
            -- mati (Died) + jaga-jaga saat spawn baru (karakter diganti tanpa
            -- event Died sempat jalan).
            local function matikanGerak()
                if State.ShiftOn then setFeature("Shift", false) end
                if State.MoonOn then setFeature("Moon", false) end
                if State.TengahOn then setFeature("Tengah", false) end
            end
            matikanGerak()
            catat(hum.Died:Connect(matikanGerak))
            hum.StateChanged:Connect(function(_, newState)
                local swimming = (newState == Enum.HumanoidStateType.Swimming)
                if swimming ~= State.IsSwimming then
                    State.IsSwimming = swimming
                    -- v1.3.4: bonus berenang ikut Shiftlock Tengah; pulih otomatis
                    applySpeed()
                end
            end)
            task.wait(0.25)
            if State.Removed then return end
            if State.SpeedOn then applySpeed() end
            if State.JumpOn then applyJump() end
        end
        LocalPlayer.CharacterAdded:Connect(initCharacter)
        task.spawn(function()
            local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            initCharacter(c)
        end)
        Players.PlayerAdded:Connect(playerHideHook)
        for _, plr in ipairs(Players:GetPlayers()) do playerHideHook(plr) end
        Players.PlayerRemoving:Connect(function(plr)
            if plr.Character then unhideCharacter(plr.Character) end
        end)
        task.spawn(function()
            while not State.Removed do
                if State.HideOn then pcall(updateVehicles) end
                task.wait(0.3)
            end
        end)

        -- [19] BUKA / TUTUP GUI ---------------------------------------------
        -- GUI tampil & hilang INSTAN (tanpa animasi buka/tutup) — lebih ringan.
        local function minimizeGui()
            if not root.Visible then return end
            bunyi(CFG.SND_PING, 0.3, 0.75)
            root.Visible = false
            root.Rotation = 0
            panelScale.Scale = 1
            fadeVal.Value = 0
        end
        local function bukaGui()
            fitPanel()   -- v1.1: pastikan skala pas layar setiap kali dibuka
            bunyi(CFG.SND_PING, 0.35, 1.15)
            root.Visible = true
            root.Rotation = 0
            panelScale.Scale = 1
            fadeVal.Value = 0
            setFade(0)
        end
        togglePanel = function()
            if root.Visible then minimizeGui() else bukaGui() end
        end

        -- [20] KONEKSI UI ----------------------------------------------------
        minBtn.MouseButton1Click:Connect(function()
            ripple(minBtn, Warna.Ungu2)
            minimizeGui()
        end)
        buatDraggable(header, root)

        -- [21] KEYBIND -------------------------------------------------------
        local lastK = 0
        catat(UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if State.Removed then return end
            -- v1.3.4 FIX: jangan picu hotkey saat sedang mengetik di kotak teks
            -- (G/Q dst. tidak lagi nyasar saat isi nama TP / stepper / kode sync)
            if UserInputService:GetFocusedTextBox() then return end
            if input.KeyCode == CFG.TOGGLE_KEY then
                togglePanel()
            elseif input.KeyCode == Enum.KeyCode.Q then
                setFeature("Speed", not State.SpeedOn)
            elseif input.KeyCode == Enum.KeyCode.J then
                setFeature("Jump", not State.JumpOn)
            elseif input.KeyCode == Enum.KeyCode.C then
                setFeature("Shift", not State.ShiftOn)
            elseif input.KeyCode == Enum.KeyCode.F then
                setFeature("Moon", not State.MoonOn)
            elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
                setFeature("Tengah", not State.TengahOn)
            elseif input.KeyCode == Enum.KeyCode.R then
                setFeature("Hide", not State.HideOn)
            elseif input.KeyCode == Enum.KeyCode.T then
                setFeature("Light", not State.LightOn)
            elseif input.KeyCode == Enum.KeyCode.X then
                setFeature("Walls", not State.WallsOn)
            elseif input.KeyCode == Enum.KeyCode.V then
                titikTambahDiSini()   -- v1.3.4: + titik cepat, tanpa buka GUI
            elseif input.KeyCode == Enum.KeyCode.K then
                local now = os.clock()
                if now - lastK < 0.45 then
                    lastK = 0
                    rejoin()
                else
                    lastK = now
                    toast("Tekan K sekali lagi untuk Rejoin", Warna.Biru)
                end
            end
        end))

        diagSet("keybind OK — finalisasi...")
        -- [21b] MESIN ☁ SINKRON (v1.3.5) — mulai setelah semua siap
        syncMulai()
        -- [22] MULAI ---------------------------------------------------------
        updateSpeedLabel()
        setTab(1)  -- 🏃 GERAK jadi tab pertama
        task.delay(0.15, function()
            local okG, errG = pcall(bukaGui)
            if not okG then
                diagSet("GUI gagal terbuka: " .. tostring(errG), Color3.fromRGB(239, 68, 68))
                warn("[BALAP] bukaGui error: " .. tostring(errG))
            end
        end)
        print("[BALAP v" .. VERSI .. "] SIAP ✔ — G = GUI | K×2 = rejoin")
        print("[BALAP] MOVE&VISUAL | TITIK | TP | SYSTEM • Q speed • J jump • C shift • LShift tengah • F moon • V titik • R hide • T cahaya • X dinding • K×2 rejoin • ☁ sync di tab SYSTEM")
        diagSet("BALAP v1.5 SIAP - GUI akan terbuka sendiri", Color3.fromRGB(16, 185, 129))
        task.delay(7, function()
            local function hapusDiag()
                pcall(function()
                    local g = game:GetService("CoreGui"):FindFirstChild("BALAP_DIAG")
                    if g then g:Destroy() end
                end)
                pcall(function()
                    if gethui then
                        local g = gethui():FindFirstChild("BALAP_DIAG")
                        if g then g:Destroy() end
                    end
                end)
            end
            hapusDiag()
        end)
    end -- akhir initLogic()

    -- Eksekusi initLogic() sekarang (UI + helpers sudah siap dari part1-4)
    initLogic()
    getgenv().BALAP_API = { Setters = Setters, State = State, Sync = SYNC }  -- debug/otomasi + harness uji
end, function(e)
    local teks = tostring(e)
    print("==================================================")
    print("[BALAP v1.5] ERROR SAAT LOAD — kirim teks ini ke dev:")
    print(teks)
    pcall(function() print(debug.traceback("", 2)) end)
    print("==================================================")
    pcall(function()
        diagSet("ERROR LOAD: " .. teks:sub(1, 260), Color3.fromRGB(239, 68, 68))
    end)
end)
if not __BALAP_LOAD_OK__ then
    warn("[BALAP v1.5] Script GAGAL load — banner MERAH di layar berisi errornya.")
end
