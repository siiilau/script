--========================================================
--  EMOT V1.03 —
--  TEMA: SILAU NEON (ungu/biru LED)
--
--  CHANGELOG v1.03 (EMOT — daftar EMOT dirapikan):
--    • kartu "PACK ANIMASI ROBLOX (18 PACK • 126 ANIMASI)" DIHAPUS
--      dari daftar EMOT (permintaan user) — animasi bundle pack bukan
--      emote, jadi tidak perlu ada di daftar main langsung
--    • 18 pack TETAP ADA sebagai preset 7 slot gaya gerak — klik slot
--      IDLE/JALAN/LARI/... untuk memakai gaya pack (tidak berubah)
--    • EMOTE_DAFTAR kini hanya berisi 80 EMOTE ROBLOX (7 gratis +
--      73 berbayar) — klik = main langsung, TANPA perlu membeli
--    • identitas: EMOT V1.02 → EMOT V1.03
--
--  CHANGELOG v1.02 (EMOT — katalog penuh buatan Roblox):
--    • EMOTE_PRESET = 18 pack resmi Roblox (i15 = docs teruji v1.3,
--      i6 = isi bundle katalog) — 10-pack uji v1.01 dihapus
--      (4 hijau naik ke daftar, 6 komunitas 🔴 dipensiunkan)
--    • EMOTE_DAFTAR diisi 126 animasi pack + 80 EMOTE ROBLOX
--      (7 gratis + 73 berbayar) — klik = main, TANPA perlu membeli
--    • kolom "ID/BUNDLE → SLOT", kartu "EMOTE KUSTOM" (tempel ID),
--      tombol ✎ GANTI NAMA & popup rename DIHAPUS — semua ID kini
--      bawaan Roblox, tidak ada input manual lagi
--    • identitas: EMOT V1.01 → EMOT V1.02
--
--  CHANGELOG v1.01 (EMOT — pengujian 10 pack):
--    • EMOTE_PRESET diisi 10 pack uji kiriman user (4 Roblox 🟢 +
--      6 komunitas 🔴 untuk uji aturan RESTRICTED langsung di lapangan)
--    • pack klasik Roblox = entri 2 rig: i15 (varian R15 teruji v1.3)
--      + i6 (varian R6 isi bundle) → jalan di karakter R15 maupun R6
--    • identitas script: BALAP v1.4 → EMOT V1.01 (banner, diag, log)
--
--  CHANGELOG v1.4 (tab ANIMASI):
--    • TAB 2 ANIMASI — terbagi 2 kartu:
--      ANIMASI : 7 slot gaya gerak (IDLE JALAN LARI RENANG MANJAT LOMPAT
--                JATUH) + kolom ID/BUNDLE → slot + reset semua
--      EMOT    : daftar emot main langsung + Stop + emote
--                kustom ID/BUNDLE dengan NAMA tersimpan (✎ ganti nama)
--    • daftar preset & emot DIKOSONGKAN (permintaan user) — struktur
--      slot & kolom ID tetap; isi ulang saat daftar animasi sudah ada
--    • ID kustom otomatis DICEK dulu (PAKAI): salah angka? bukan animasi?
--      bukan milik Roblox/dev game? — semuanya diberi tahu lewat notif
--    • ID BUNDLE katalog emote: animasi di dalamnya diekstrak otomatis
--      (AssetService:GetBundleDetailsAsync) — ID kustom ikut menyimpan
--      NAMA aset (otomatis dari Roblox, bisa diganti lewat ✎)
--    • gaya jalan/lari/dll TERLIHAT OLEH PEMAIN LAIN (animasi karakter
--      dijalankan client & direplikasi ke server)
--    • mati/respawn = baseline dicatat ulang + gaya dipasang otomatis
--    • SEMUA kode MOVEMENT & VISUAL 100% ASLI v1.3 — tidak disentuh
--    • tab TITIK & TP DIHAPUS — script lebih ramping
--    • ☁ SINKRON ganti tugas: menyinkronkan CONFIG EMOTE lintas device
--      (kode loker balap-xxxx-xxxx • per-slot terbaru menang • tanpa
--      tombstone) • config emote permanen di BALAP_EMOTE.json
--
--  3 TAB:
--    1 MOVEMENT & VISUAL : Speed (Q), JumpPower (J), Shiftlock Mobile (C),
--                          Shiftlock Tengah (LShift/RShift), Moonwalk (F/S),
--                          Hide Player (R), Hide Badan Atas, Cahaya Auto (T),
--                          Lightweight, Dinding Batas (X), Panah Deteksi (V)
--    2 ANIMASI : kartu ANIMASI = 7 slot gaya gerak (klik slot = pilih
--                gaya dari 18 pack resmi Roblox); kartu EMOT = 80
--                emote Roblox main langsung + Stop;
--                master ON/OFF, reset semua
--    3 SYSTEM  : ☁ SINKRON (config emote lintas device), rejoin (K×2),
--                hapus script
--
--  Keybind:
--    G = buka/tutup GUI (saat tutup = hilang total)
--    Q = Speed ON/OFF (nilai ON dipilih di panel: 17.25-21.25)
--    J = JumpPower (51.25 ⇄ 65.25)    C = Shiftlock Mobile
--    LShift/RShift = Shiftlock Tengah (kamera tengah, kursor lingkaran mini)
--    F = Moonwalk (saat aktif, tekan S = langsung OFF)    R = Hide
--    P = (kosong)
--    T = Cahaya Auto (2 arah)    X = Dinding Batas
--    V = Panah Deteksi (100 stud tiap arah, depan/belakang 135°:
--        ↑ MERAH = ada pemain DI DEPAN badan, ↓ MERAH = DI BELAKANG;
--        samping 45° bebas + kosong = hijau; toggle di tab 1)
--    K = Rejoin (double-tap)
--    EMOTE = via GUI tab 2 • ☁ SINKRON = tab SYSTEM
--
--  Shiftlock Mobile, Moonwalk & Shiftlock Tengah otomatis OFF saat
--  mati/respawn. Config emote & kode sync tersimpan permanen di device.
--
--  CATATAN EMOTE: SEMUA animasi di script ini (18 pack + 80 emote)
--  milik akun Roblox (id=1) → lolos aturan Roblox (per Jul 2025 aset
--  Animation = RESTRICTED) dan bisa di-load di game mana pun TANPA
--  membeli. Kolom input ID manual DIHAPUS di v1.02 — tidak ada ID
--  pihak ketiga yang bisa ditolak. Game dengan sistem animasi sendiri
--  (Animate diubah dev game) mungkin mengabaikan gaya kustom.
--========================================================
print("[EMOT v1.03] load mulai...")

-- [0] DIAGNOSTIK ON-SCREEN -----------------------------------------
-- Banner kecil pojok kiri: menunjukkan progres load. Kalau load GAGAL,
-- banner berubah MERAH dan menampilkan teks errornya di layar.
local diagSet   -- v1.3: local file (dulu global function — bocor _G)
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
        __dLbl.Text = "EMOT: memulai..."
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
    diagSet = function(teks, warna)
        print("[BALAP-DIAG] " .. tostring(teks))
        pcall(function()
            if __dGui and __dGui.Parent and __dLbl then
                __dLbl.Text = tostring(teks)
                if warna then __dLbl.BackgroundColor3 = warna end
            end
        end)
    end
end

local VERSI = "1.03"
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
        -- Moonwalk (F): putaran cepat + hentakan ke arah tujuan.
        --   MOON_TURN_MAX = kecepatan putar maks (rad/dtk; 12 ≈ ±688°/dtk)
        --   MOON_SMOOTH   = kekerasan kunci/pendaratan
        --   Berputar hanya saat karakter bergerak; berdiri = diam total.
        MOON_TURN_MAX = 12,
        MOON_SMOOTH = 10,
        -- Shiftlock Tengah: kamera persis di TENGAH karakter & TIDAK diubah —
        -- yang digeser ke bawah cuma letak lingkaran kursornya (SLT_DOT_Y)
        SLT_WAKTU   = 0.25,  -- durasi transisi halus kamera (detik)
        SLT_DOT     = 7,     -- ukuran lingkaran kursor (px, mini biar ga ganggu)
        SLT_DOT_Y   = 0.60,  -- letak vertikal lingkaran: 0.5 = tengah layar,
        -- makin besar makin ke bawah (0.60 = bawah pinggang)
        -- ANIMASI (tab ANIMASI): 7 slot gaya gerak + kartu EMOT.
        --   EMOTE_FILE  = config permanen (pilihan preset + ID kustom)
        --   EMOTE_TUNGGAK = jeda setelah Animate siap sebelum gaya dipasang
        EMOTE_FILE     = "BALAP_EMOTE.json",
        EMOTE_TUNGGAK  = 0.25,
        -- Panah Deteksi (keybind V): deteksi pemain lain di
        -- depan/belakang badan (ikut arah badan, bukan kamera).
        PANAH_JARAK = 100,  -- jarak deteksi TIAP arah (stud): 100 depan +
                            -- 100 belakang = cakupan penuh 200 stud
        PANAH_SUDUT = 0.383, -- batas dot LookVector: 0.383 = cos(67.5°)
                            -- -> depan & belakang 135 derajat penuh,
                            -- samping kiri/kanan 45 derajat bebas (hijau)
        -- ☁ SINKRON: config emote lintas device via textdb.dev (gratis,
        -- tanpa blokir executor; BUKAN HttpService Roblox jadi tidak
        -- kelihatan oleh server game)
        SYNC_FILE          = "BALAP_SYNC.json", -- kode loker (permanen)
        SYNC_URL           = "https://textdb.dev/api/data/", -- .. kode
        SYNC_UNGGAH_JEDA   = 30,    -- dtk tunda upload setelah perubahan terakhir
        SYNC_UNDUH_TIAP    = 180,   -- dtk antar unduhan berkala (3 menit)
        SWIM_BONUS         = 1.025, -- berenang + Shiftlock Tengah: speed aktif × 1.025
        -- UI RESPONSIF: panel menyesuaikan ukuran layar otomatis.
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
    -- format jarak utk daftar TP & titik
    local function fmtJarak(d)
        if d >= 1000 then return string.format("%.2fkm", d / 1000) end
        return string.format("%.1fm", d)
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
    -- Forward declare modul ☁ SINKRON + EMOTE (didefinisikan di [7a]/[7a3])
    local syncTandai, syncRefreshKartu
    local emoteSetMaster, emotePilihPreset, emoteRefreshGrid, emoteCekId

    -- Forward declare untuk part2 (UI builder) — di-expose via buildUI()
    local tabBtns, kontenTabs, setTab
    local kontenMove, scrollMove
    local kontenEmote, scrollEmote
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
    local root = buat("Frame", {
        Size = UDim2.fromOffset(CFG.UI_LEBAR, CFG.UI_TINGGI),
        Position = UDim2.new(0.5, 0, 0.10, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Visible = false,
    }, screenGui)
    local panelScale = buat("UIScale", {Scale = 1}, root)
    -- fitScale = skala otomatis "pas layar". Dihitung ulang tiap
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
    -- v1.3: fitPanel ikut kamera AKTIF — kalau game mengganti CurrentCamera
    -- (respawn di beberapa game), listener ViewportSize dipasang ulang.
    local camConn
    local function ikatKamera()
        if camConn then camConn:Disconnect() camConn = nil end
        local cam = Workspace.CurrentCamera
        if cam then
            camConn = catat(cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel))
            fitPanel()
        end
    end
    catat(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(ikatKamera))
    ikatKamera()
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
        Text = "⚡ EMOT V1.03 ⚡",
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
        setTab(3)
    end)

    -- ======================================================================
    -- [7a] MODUL ANIMASI — 7 SLOT GAYA GERAK + EMOT (tab ANIMASI)
    --   • Slot state (IDLE/WALK/RUN/SWIM/CLIMB/JUMP/FALL) bekerja
    --     dengan MENGGANTI ID animasi di script "Animate" bawaan karakter,
    --     lalu Animate di-restart. Hasilnya DIREPLIKASI: pemain lain juga
    --     melihat gaya baru kamu.
    --   • DANCE = overlay emote via Animator (loop sampai bergerak/mati).
    --   • Otomatis deteksi R15 / R6 (struktur Animate kedua rig diikuti).
    --   • Baseline (animasi asli game) dicatat tiap spawn → RESET/OFF
    --     mengembalikan persis seperti semula.
    --   • Preset = 18 pack resmi Roblox (semua 🟢) — R15 dari docs
    --     Roblox (preset v1.3 teruji) + R6 dari isi bundle katalog.
    --   • Config (preset/kustom/master) permanen: BALAP_EMOTE.json.
    -- Sumber ID: create.roblox.com/docs/animation/using (tabel katalog)
    --   + bundle katalog Roblox (scan otomatis 11 Nov 2025).
    -- ======================================================================
local EMOTE_PRESET = {
    -- ===== 18 PACK RESMI ROBLOX — semua milik akun Roblox =====
    -- 🟢 Semua ID = animasi milik Roblox (id=1) → lolos aturan RESTRICTED
    --    Jul 2025 dan jalan di semua game (terbukti: 4 pack hijau v1.01).
    -- i15 = varian R15 (docs Roblox 'Catalog animations', preset v1.3
    --    teruji in-game) • i6 = varian R6 (isi bundle katalog Roblox) →
    --    pilihan tampil R15+R6 di chooser. Rthro = R15 saja (tanpa i6).
    -- swim: i15b = swim idle R15; tanpa i15b → swimidle ikut ID swim.
    idle  = {
        { n = "Astronaut", i15 = 891621366, i6 = 1090133099 },        -- 🟢 Roblox R$500
        { n = "Bubbly", i15 = 910004836, i6 = 1018553897 },        -- 🟢 Roblox R$300
        { n = "Cartoony", i15 = 742637544, i6 = 837011741 },        -- 🟢 Roblox R$300
        { n = "Elder", i15 = 845397899, i6 = 892268340 },        -- 🟢 Roblox R$300
        { n = "Knight", i15 = 657595757, i6 = 734327140 },        -- 🟢 Roblox R$500
        { n = "Levitation", i15 = 616006778, i6 = 619542203 },        -- 🟢 Roblox R$1000
        { n = "Mage", i15 = 707742142, i6 = 754637456 },        -- 🟢 Roblox R$300
        { n = "Ninja", i15 = 656117400, i6 = 658832408 },        -- 🟢 Roblox R$750
        { n = "Oldschool", i15 = 5319828216, i6 = 5319922112 },        -- 🟢 Roblox R$300
        { n = "Pirate", i15 = 750781874, i6 = 837024662 },        -- 🟢 Roblox R$750
        { n = "Robot", i15 = 616088211, i6 = 619521748 },        -- 🟢 Roblox R$300
        { n = "Rthro", i15 = 2510197257 },        -- 🟢 Roblox GRATIS
        { n = "Stylish", i15 = 616136790, i6 = 619511648 },        -- 🟢 Roblox R$300
        { n = "Superhero", i15 = 616111295, i6 = 619528125 },        -- 🟢 Roblox R$300
        { n = "Toy", i15 = 782841498, i6 = 973771666 },        -- 🟢 Roblox R$300
        { n = "Vampire", i15 = 1083445855, i6 = 1113742618 },        -- 🟢 Roblox R$500
        { n = "Werewolf", i15 = 1083195517, i6 = 1113752682 },        -- 🟢 Roblox R$500
        { n = "Zombie", i15 = 616158929, i6 = 619535834 },        -- 🟢 Roblox R$500
    },
    walk  = {
        { n = "Astronaut", i15 = 891636393, i6 = 1090131576 },        -- 🟢 Roblox R$500
        { n = "Bubbly", i15 = 910034870, i6 = 1018549681 },        -- 🟢 Roblox R$300
        { n = "Cartoony", i15 = 742640026, i6 = 837010234 },        -- 🟢 Roblox R$300
        { n = "Elder", i15 = 845403856, i6 = 892267099 },        -- 🟢 Roblox R$300
        { n = "Knight", i15 = 657552124, i6 = 734326330 },        -- 🟢 Roblox R$500
        { n = "Levitation", i15 = 616013216, i6 = 619544080 },        -- 🟢 Roblox R$1000
        { n = "Mage", i15 = 707897309, i6 = 754636298 },        -- 🟢 Roblox R$300
        { n = "Ninja", i15 = 656121766, i6 = 658831143 },        -- 🟢 Roblox R$750
        { n = "Oldschool", i15 = 5319847204, i6 = 5319909330 },        -- 🟢 Roblox R$300
        { n = "Pirate", i15 = 750785693, i6 = 837023892 },        -- 🟢 Roblox R$750
        { n = "Robot", i15 = 616095330, i6 = 619522849 },        -- 🟢 Roblox R$300
        { n = "Rthro", i15 = 2510202577 },        -- 🟢 Roblox GRATIS
        { n = "Stylish", i15 = 616146177, i6 = 619512767 },        -- 🟢 Roblox R$300
        { n = "Superhero", i15 = 616122287, i6 = 619529601 },        -- 🟢 Roblox R$300
        { n = "Toy", i15 = 782843345, i6 = 973767371 },        -- 🟢 Roblox R$300
        { n = "Vampire", i15 = 1083473930, i6 = 1113741192 },        -- 🟢 Roblox R$500
        { n = "Werewolf", i15 = 1083178339, i6 = 1113751657 },        -- 🟢 Roblox R$500
        { n = "Zombie", i15 = 616168032, i6 = 619537468 },        -- 🟢 Roblox R$500
    },
    run   = {
        { n = "Astronaut", i15 = 891636393, i6 = 1090130630 },        -- 🟢 Roblox R$500
        { n = "Bubbly", i15 = 910025107, i6 = 1018548665 },        -- 🟢 Roblox R$300
        { n = "Cartoony", i15 = 742638842, i6 = 837009922 },        -- 🟢 Roblox R$300
        { n = "Elder", i15 = 845386501, i6 = 892265784 },        -- 🟢 Roblox R$300
        { n = "Knight", i15 = 657564596, i6 = 734325948 },        -- 🟢 Roblox R$500
        { n = "Levitation", i15 = 616010382, i6 = 619543231 },        -- 🟢 Roblox R$1000
        { n = "Mage", i15 = 707861613, i6 = 754635032 },        -- 🟢 Roblox R$300
        { n = "Ninja", i15 = 656118852, i6 = 658830056 },        -- 🟢 Roblox R$750
        { n = "Oldschool", i15 = 5319844329, i6 = 5319900634 },        -- 🟢 Roblox R$300
        { n = "Pirate", i15 = 750783738, i6 = 837023444 },        -- 🟢 Roblox R$750
        { n = "Robot", i15 = 616091570, i6 = 619522386 },        -- 🟢 Roblox R$300
        { n = "Rthro", i15 = 2510198475 },        -- 🟢 Roblox GRATIS
        { n = "Stylish", i15 = 616140816, i6 = 619512153 },        -- 🟢 Roblox R$300
        { n = "Superhero", i15 = 616117076, i6 = 619528716 },        -- 🟢 Roblox R$300
        { n = "Toy", i15 = 782842708, i6 = 973766674 },        -- 🟢 Roblox R$300
        { n = "Vampire", i15 = 1083462077, i6 = 1113740510 },        -- 🟢 Roblox R$500
        { n = "Werewolf", i15 = 1083216690, i6 = 1113750642 },        -- 🟢 Roblox R$500
        { n = "Zombie", i15 = 616163682, i6 = 619536621 },        -- 🟢 Roblox R$500
    },
    jump  = {
        { n = "Astronaut", i15 = 891627522, i6 = 1090132507 },        -- 🟢 Roblox R$500
        { n = "Bubbly", i15 = 910016857, i6 = 1018553240 },        -- 🟢 Roblox R$300
        { n = "Cartoony", i15 = 742637942, i6 = 837011171 },        -- 🟢 Roblox R$300
        { n = "Elder", i15 = 845398858, i6 = 892267917 },        -- 🟢 Roblox R$300
        { n = "Knight", i15 = 658409194, i6 = 734326930 },        -- 🟢 Roblox R$500
        { n = "Levitation", i15 = 616008936, i6 = 619542888 },        -- 🟢 Roblox R$1000
        { n = "Mage", i15 = 707853694, i6 = 754637084 },        -- 🟢 Roblox R$300
        { n = "Ninja", i15 = 656117878, i6 = 658832070 },        -- 🟢 Roblox R$750
        { n = "Oldschool", i15 = 5319841935, i6 = 5319917561 },        -- 🟢 Roblox R$300
        { n = "Pirate", i15 = 750782230, i6 = 837024350 },        -- 🟢 Roblox R$750
        { n = "Robot", i15 = 616090535, i6 = 619522088 },        -- 🟢 Roblox R$300
        { n = "Rthro", i15 = 2510197830 },        -- 🟢 Roblox GRATIS
        { n = "Stylish", i15 = 616139451, i6 = 619511974 },        -- 🟢 Roblox R$300
        { n = "Superhero", i15 = 616115533, i6 = 619528412 },        -- 🟢 Roblox R$300
        { n = "Toy", i15 = 782847020, i6 = 973770652 },        -- 🟢 Roblox R$300
        { n = "Vampire", i15 = 1083455352, i6 = 1113742359 },        -- 🟢 Roblox R$500
        { n = "Werewolf", i15 = 1083218792, i6 = 1113752285 },        -- 🟢 Roblox R$500
        { n = "Zombie", i15 = 616161997, i6 = 619536283 },        -- 🟢 Roblox R$500
    },
    fall  = {
        { n = "Astronaut", i15 = 891617961, i6 = 1090132063 },        -- 🟢 Roblox R$500
        { n = "Bubbly", i15 = 910001910, i6 = 1018552770 },        -- 🟢 Roblox R$300
        { n = "Cartoony", i15 = 742637151, i6 = 837010685 },        -- 🟢 Roblox R$300
        { n = "Elder", i15 = 845396048, i6 = 892267521 },        -- 🟢 Roblox R$300
        { n = "Knight", i15 = 657600338, i6 = 734326679 },        -- 🟢 Roblox R$500
        { n = "Levitation", i15 = 616005863, i6 = 619541867 },        -- 🟢 Roblox R$1000
        { n = "Mage", i15 = 707829716, i6 = 754636589 },        -- 🟢 Roblox R$300
        { n = "Ninja", i15 = 656115606, i6 = 658831500 },        -- 🟢 Roblox R$750
        { n = "Oldschool", i15 = 5319839762, i6 = 5319914476 },        -- 🟢 Roblox R$300
        { n = "Pirate", i15 = 750780242, i6 = 837024147 },        -- 🟢 Roblox R$750
        { n = "Robot", i15 = 616087089, i6 = 619521521 },        -- 🟢 Roblox R$300
        { n = "Rthro", i15 = 2510195892 },        -- 🟢 Roblox GRATIS
        { n = "Stylish", i15 = 616134815, i6 = 619511417 },        -- 🟢 Roblox R$300
        { n = "Superhero", i15 = 616108001, i6 = 619527817 },        -- 🟢 Roblox R$300
        { n = "Toy", i15 = 782846423, i6 = 973768058 },        -- 🟢 Roblox R$300
        { n = "Vampire", i15 = 1083443587, i6 = 1113742092 },        -- 🟢 Roblox R$500
        { n = "Werewolf", i15 = 1083189019, i6 = 1113751889 },        -- 🟢 Roblox R$500
        { n = "Zombie", i15 = 616157476, i6 = 619535616 },        -- 🟢 Roblox R$500
    },
    climb = {
        { n = "Astronaut", i15 = 891609353, i6 = 1090134016 },        -- 🟢 Roblox R$500
        { n = "Bubbly", i15 = 909997997, i6 = 1018554668 },        -- 🟢 Roblox R$300
        { n = "Cartoony", i15 = 742636889, i6 = 837013990 },        -- 🟢 Roblox R$300
        { n = "Elder", i15 = 845392038, i6 = 892269341 },        -- 🟢 Roblox R$300
        { n = "Knight", i15 = 658360781, i6 = 734329002 },        -- 🟢 Roblox R$500
        { n = "Levitation", i15 = 616003713, i6 = 619541458 },        -- 🟢 Roblox R$1000
        { n = "Mage", i15 = 707826056, i6 = 754639239 },        -- 🟢 Roblox R$300
        { n = "Ninja", i15 = 656114359, i6 = 658833139 },        -- 🟢 Roblox R$750
        { n = "Oldschool", i15 = 5319816685, i6 = 5319931619 },        -- 🟢 Roblox R$300
        { n = "Pirate", i15 = 750779899, i6 = 837025325 },        -- 🟢 Roblox R$750
        { n = "Robot", i15 = 616086039, i6 = 619521311 },        -- 🟢 Roblox R$300
        { n = "Rthro", i15 = 2510192778 },        -- 🟢 Roblox GRATIS
        { n = "Stylish", i15 = 616133594, i6 = 619509955 },        -- 🟢 Roblox R$300
        { n = "Superhero", i15 = 616104706, i6 = 619527470 },        -- 🟢 Roblox R$300
        { n = "Toy", i15 = 782843869, i6 = 973773170 },        -- 🟢 Roblox R$300
        { n = "Vampire", i15 = 1083439238, i6 = 1113743239 },        -- 🟢 Roblox R$500
        { n = "Werewolf", i15 = 1083182000, i6 = 1113754738 },        -- 🟢 Roblox R$500
        { n = "Zombie", i15 = 616156119, i6 = 619535091 },        -- 🟢 Roblox R$500
    },
    swim  = {
        { n = "Astronaut", i15 = 891639666, i6 = 1090133583, i15b = 891663592 },        -- 🟢 Roblox R$500
        { n = "Bubbly", i15 = 910028158, i6 = 1018554245, i15b = 910030921 },        -- 🟢 Roblox R$300
        { n = "Cartoony", i15 = 742639220, i6 = 837012509, i15b = 742639812 },        -- 🟢 Roblox R$300
        { n = "Elder", i15 = 845401742, i6 = 892268710, i15b = 845403127 },        -- 🟢 Roblox R$300
        { n = "Knight", i15 = 657560551, i6 = 734327363, i15b = 657557095 },        -- 🟢 Roblox R$500
        { n = "Levitation", i15 = 616011509, i6 = 619543721, i15b = 616012453 },        -- 🟢 Roblox R$1000
        { n = "Mage", i15 = 707876443, i6 = 754638471, i15b = 707894699 },        -- 🟢 Roblox R$300
        { n = "Ninja", i15 = 656119721, i6 = 658832807, i15b = 656121397 },        -- 🟢 Roblox R$750
        { n = "Oldschool", i15 = 5319850266, i6 = 5319927054, i15b = 5319852613 },        -- 🟢 Roblox R$300
        { n = "Pirate", i15 = 750784579, i6 = 837025054, i15b = 750785176 },        -- 🟢 Roblox R$750
        { n = "Robot", i15 = 616092998, i6 = 619522642, i15b = 616094091 },        -- 🟢 Roblox R$300
        { n = "Rthro", i15 = 2510199791, i15b = 2510201162 },        -- 🟢 Roblox GRATIS
        { n = "Stylish", i15 = 616143378, i6 = 619512450, i15b = 616144772 },        -- 🟢 Roblox R$300
        { n = "Superhero", i15 = 616119360, i6 = 619529095, i15b = 616120861 },        -- 🟢 Roblox R$300
        { n = "Toy", i15 = 782844582, i6 = 973772659, i15b = 782845186 },        -- 🟢 Roblox R$300
        { n = "Vampire", i15 = 1083464683, i6 = 1113742944, i15b = 1083467779 },        -- 🟢 Roblox R$500
        { n = "Werewolf", i15 = 1083222527, i6 = 1113752975, i15b = 1083225406 },        -- 🟢 Roblox R$500
        { n = "Zombie", i15 = 616165109, i6 = 619537096, i15b = 616166655 },        -- 🟢 Roblox R$500
    },
}

-- emote MAIN LANGSUNG (kartu EMOT) — EMOT V1.03: 80 EMOTE ROBLOX
-- (7 gratis + 73 berbayar — semua bisa dimainkan TANPA membeli,
-- pemiliknya akun Roblox). Kartu "PACK ANIMASI ROBLOX" (126 animasi
-- bundle) DIHAPUS di v1.03 (permintaan user) — animasi pack kini
-- hanya preset slot gaya gerak (EMOTE_PRESET), bukan emote.
-- Entri { g = "..." } = judul kelompok (bukan tombol).
-- Format tombol: { n = "Nama", i15 = ID_R15, i6 = ID_R6_opsional }
local EMOTE_DAFTAR = {
    { g = "EMOTE ROBLOX (80 EMOTE)" },
    { n = "Salute", i15 = 3360689775 },
    { n = "Applaud", i15 = 5915779043 },
    { n = "Tilt", i15 = 3360692915 },
    { n = "Sad", i15 = 4849502101 },
    { n = "Hello", i15 = 3576686446 },
    { n = "Shrug", i15 = 3576968026 },
    { n = "Point2", i15 = 3576823880 },
    { n = "Stadium", i15 = 3360686498 },
    { n = "Bored", i15 = 5230661597 },
    { n = "Monkey", i15 = 3716636630 },
    { n = "Sleep", i15 = 4689362868 },
    { n = "Curtsy", i15 = 4646306583 },
    { n = "Happy", i15 = 4849499887 },
    { n = "Floss Dance", i15 = 5917570207 },
    { n = "Hero Landing", i15 = 5104377791 },
    { n = "Greatest", i15 = 3762654854 },
    { n = "Shy", i15 = 3576717965 },
    { n = "Zombie", i15 = 4212496830 },
    { n = "Godlike", i15 = 3823158750 },
    { n = "Haha", i15 = 4102315500 },
    { n = "Quiet Waves", i15 = 7466046574 },
    { n = "Bodybuilder", i15 = 3994130516 },
    { n = "Fashionable", i15 = 3576745472 },
    { n = "Cower", i15 = 4940597758 },
    { n = "Chappell Roan HOT TO GO!", i15 = 79312439851071 },
    { n = "Dizzy", i15 = 3934986896 },
    { n = "Line Dance", i15 = 4049646104 },
    { n = "High Wave", i15 = 5915776835 },
    { n = "Beckon", i15 = 5230615437 },
    { n = "Jumping Wave", i15 = 4940602656 },
    { n = "Baby Dance", i15 = 4272484885 },
    { n = "Show Dem Wrists - KSI", i15 = 7202898984 },
    { n = "Rock On", i15 = 5915782672 },
    { n = "Celebrate", i15 = 3994127840 },
    { n = "Wake Up Call - KSI", i15 = 7202900159 },
    { n = "Dolphin Dance", i15 = 5938365243 },
    { n = "Confused", i15 = 4940592718 },
    { n = "Samba", i15 = 6869813008 },
    { n = "Fast Hands", i15 = 4272351660 },
    { n = "Boxing Punch - KSI", i15 = 7202896732 },
    { n = "Shuffle", i15 = 4391208058 },
    { n = "Agree", i15 = 4849487550 },
    { n = "Cha Cha", i15 = 6865013133 },
    { n = "Dancin' Shoes - Twenty One Pilots", i15 = 7405123844 },
    { n = "Around Town", i15 = 3576747102 },
    { n = "Power Blast", i15 = 4849497510 },
    { n = "Disagree", i15 = 4849495710 },
    { n = "Side to Side", i15 = 3762641826 },
    { n = "Dorky Dance", i15 = 4212499637 },
    { n = "Break Dance", i15 = 5915773992 },
    { n = "Twirl", i15 = 3716633898 },
    { n = "T", i15 = 3576719440 },
    { n = "Robot", i15 = 3576721660 },
    { n = "Flowing Breeze", i15 = 7466047578 },
    { n = "Tree", i15 = 4049634387 },
    { n = "Top Rock", i15 = 3570535774 },
    { n = "Fishing", i15 = 3994129128 },
    { n = "Jumping Cheer", i15 = 5895009708 },
    { n = "Y", i15 = 4391211308 },
    { n = "Keeping Time", i15 = 4646306072 },
    { n = "Tantrum", i15 = 5104374556 },
    { n = "Shrek Roar", i15 = 18524331128 },
    { n = "Saturday Dance - Twenty One Pilots", i15 = 7422833723 },
    { n = "Get Out", i15 = 3934984583 },
    { n = "Drum Solo - Royal Blood", i15 = 6532844183 },
    { n = "Rock Guitar - Royal Blood", i15 = 6532155086 },
    { n = "Fancy Feet", i15 = 3934988903 },
    { n = "Air Dance", i15 = 4646302011 },
    { n = "Block Partier", i15 = 6865011755 },
    { n = "Louder", i15 = 3576751796 },
    { n = "Sneaky", i15 = 3576754235 },
    { n = "Jacks", i15 = 3570649048 },
    { n = "Rock Star - Royal Blood", i15 = 6533100850 },
    { n = "On The Outside - Twenty One Pilots", i15 = 7422841700 },
    { n = "Swan Dance", i15 = 7466048475 },
    { n = "Idol", i15 = 4102317848 },
    { n = "Up and Down - Twenty One Pilots", i15 = 7422843994 },
    { n = "Drummer Moves - Twenty One Pilots", i15 = 7422838770 },
    { n = "Drum Master - Royal Blood", i15 = 6531538868 },
    { n = "Swish", i15 = 3821527813 },
}

    -- folder target di script Animate per slot (7 slot: idle s/d swim)
    local SLOT_FOLDERS = {
        idle  = { "idle" },
        walk  = { "walk" },
        run   = { "run" },
        jump  = { "jump" },
        fall  = { "fall" },
        climb = { "climb" },
        swim  = { "swim", "swimidle" },
    }

    local SLOT_LIST = {
        { k = "idle",  t = "IDLE"   },
        { k = "walk",  t = "JALAN"  },
        { k = "run",   t = "LARI"   },
        { k = "swim",  t = "RENANG" },
        { k = "climb", t = "MANJAT" },
        { k = "jump",  t = "LOMPAT" },
        { k = "fall",  t = "JATUH"  },
    }
    local SLOT_BY_KEY = {}
    for i, s in ipairs(SLOT_LIST) do SLOT_BY_KEY[s.k] = i end
    local function slotLabel(k)
        local sv = SLOT_LIST[SLOT_BY_KEY[k]]
        return sv and sv.t or string.upper(k)
    end

    -- kustom v2 = { id = ID yg ditempel, anim = ID animasi yg dipakai,
    -- nama = nama tampil }. Config lama (string angka) dinormalkan.
    local function emoteNormKustom(v)
        if type(v) == "string" and #v > 0 and #v <= 24 and v:match("^%d+$") then
            return { id = v, anim = v, nama = v }
        end
        if type(v) == "table" and type(v.id) == "string"
            and #v.id > 0 and #v.id <= 24 and v.id:match("^%d+$") then
            local anim = (type(v.anim) == "string" and #v.anim <= 24
                          and v.anim:match("^%d+$")) and v.anim or v.id
            local nama = tostring(v.nama or v.id)
            if #nama > 40 then nama = nama:sub(1, 40) end
            return { id = v.id, anim = anim, nama = nama }
        end
        return nil
    end

    local function emoteKKey(v)
        if type(v) == "table" then
            return tostring(v.id) .. "|" .. tostring(v.anim) .. "|" .. tostring(v.nama)
        end
        return "s|" .. tostring(v)
    end

    local EMOTE = {
        master     = true,   -- master toggle (ikut disinkron)
        preset     = {},     -- [slotKey] = index preset (0 = ASLI, -1 = kustom)
        kustom     = {},     -- [slotKey] = { id, anim, nama } (kustom v2)
        baseline   = {},     -- [slotKey] = { [Animation] = idAsli } (runtime)
        danceTrack = nil,
        danceTrackJudul = nil,
        kustomEmote = nil,   -- { id, anim, nama } — emote kustom kartu EMOT
        rig        = "?",    -- "R15" / "R6" / "?"
        bisaFile   = (type(writefile) == "function") and (type(readfile) == "function")
                     and (type(isfile) == "function"),
    }

    -- ---- resolve slot -> (id | nil, namaGaya) ----
    local function emoteResolveSlot(k)
        local kv = EMOTE.kustom[k]
        if type(kv) == "table" and kv.anim then
            return "rbxassetid://" .. kv.anim, ("★ " .. tostring(kv.nama or kv.id))
        end
        local pi = EMOTE.preset[k] or 0
        local p = (EMOTE_PRESET[k] or {})[pi]
        if pi == 0 or not p then return nil, "ASLI" end
        local utama = (EMOTE.rig == "R6") and p.i6 or p.i15
        if not utama then return nil, p.n .. " (beda rig)" end
        return "rbxassetid://" .. utama, p.n
    end

    local function emoteJumlahAktif()
        local n = 0
        for _, s in ipairs(SLOT_LIST) do
            if emoteResolveSlot(s.k) then n = n + 1 end
        end
        return n
    end

    -- ---- simpan / muat config (permanen + cadangan sesi) ----
    local function emoteSimpan()
        getgenv().BALAP_EMOTE_DATA = {
            master = EMOTE.master, preset = EMOTE.preset,
            kustom = EMOTE.kustom, kustomEmote = EMOTE.kustomEmote,
        }
        if not EMOTE.bisaFile then return end
        pcall(function()
            writefile(CFG.EMOTE_FILE, HttpService:JSONEncode({
                v      = 1,
                master = EMOTE.master,
                preset = EMOTE.preset,
                kustom = EMOTE.kustom,
                kustomEmote = EMOTE.kustomEmote,
                waktu  = os.time(),
            }))
        end)
    end

    local function emoteMuat()
        local data
        if EMOTE.bisaFile then
            local ada = false
            pcall(function() ada = isfile(CFG.EMOTE_FILE) end)
            if ada then
                local ok, isi = pcall(readfile, CFG.EMOTE_FILE)
                if ok and type(isi) == "string" then
                    pcall(function() data = HttpService:JSONDecode(isi) end)
                end
            end
        end
        if type(data) ~= "table" then
            data = rawget(getgenv(), "BALAP_EMOTE_DATA")  -- fallback sesi yang sama
        end
        if type(data) == "table" then
            EMOTE.master = (data.master ~= false)
            if type(data.preset) == "table" then
                for k, v in pairs(data.preset) do
                    if SLOT_BY_KEY[k] and type(v) == "number" and v == math.floor(v) and v >= -1 and v <= 30 then
                        EMOTE.preset[k] = v
                    end
                end
            end
            if type(data.kustom) == "table" then
                for k, v in pairs(data.kustom) do
                    local nv = emoteNormKustom(v)
                    if SLOT_BY_KEY[k] and nv then
                        EMOTE.kustom[k] = nv
                    end
                end
            end
            if type(data.kustomEmote) == "table" then
                EMOTE.kustomEmote = emoteNormKustom(data.kustomEmote)
            end
        end
        -- buang pilihan preset yang menunjuk daftar preset yang sudah
        -- tidak ada (mis. daftar dikosongkan) → slot balik ke ASLI
        for k, v in pairs(EMOTE.preset) do
            if v > 0 and not (EMOTE_PRESET[k] or {})[v] then
                EMOTE.preset[k] = nil
            end
        end
        print("[BALAP-EMOTE] muat config: master=" .. tostring(EMOTE.master)
        .. " • preset=" .. (function() local n = 0 for _ in pairs(EMOTE.preset) do n = n + 1 end return n end)()
        .. " • kustom=" .. (function() local n = 0 for _ in pairs(EMOTE.kustom) do n = n + 1 end return n end)()
        .. (EMOTE.bisaFile and (" (file: " .. CFG.EMOTE_FILE .. ")") or " (mode SESI — executor tanpa writefile)"))
    end

    -- ---- deteksi rig + baseline ----
    local function emoteDeteksiRig(char)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            if hum.RigType == Enum.HumanoidRigType.R15 then EMOTE.rig = "R15"
            elseif hum.RigType == Enum.HumanoidRigType.R6 then EMOTE.rig = "R6" end
        end
        return EMOTE.rig
    end

    local function emoteCaptureBaseline(char)
        local a = char and char:FindFirstChild("Animate")
        if not a then return end
        for k, folders in pairs(SLOT_FOLDERS) do
            if #folders > 0 then
                local simpan = {}
                for _, fname in ipairs(folders) do
                    local f = a:FindFirstChild(fname)
                    if f then
                        for _, an in ipairs(f:GetDescendants()) do
                            if an:IsA("Animation") then simpan[an] = an.AnimationId end
                        end
                    end
                end
                EMOTE.baseline[k] = simpan
            end
        end
    end

    -- ---- pasang / pulihkan satu slot ----
    local function emoteSetSlotId(k, char, id)
        local a = char and char:FindFirstChild("Animate")
        if not a then return false end
        local folders = SLOT_FOLDERS[k]
        if not folders or #folders == 0 then return false end
        local idB = nil
        if id and k == "swim" then
            local p = (EMOTE_PRESET[k] or {})[EMOTE.preset[k] or 0]
            if p then idB = p.i15b end
        end
        for _, fname in ipairs(folders) do
            local f = a:FindFirstChild(fname)
            if f then
                local target = id
                if target and fname == "swimidle" then
                    target = (idB and EMOTE.rig ~= "R6") and ("rbxassetid://" .. idB) or id
                end
                for _, an in ipairs(f:GetDescendants()) do
                    if an:IsA("Animation") then
                        if target then
                            an.AnimationId = target
                        else
                            local asli = EMOTE.baseline[k] and EMOTE.baseline[k][an]
                            if asli then an.AnimationId = asli end
                        end
                    end
                end
            end
        end
        return true
    end

    -- restart Animate = baca ulang semua AnimationId (cache track dibuang)
    local function emoteRestartAnimate()
        local char = getChar()
        local a = char and char:FindFirstChild("Animate")
        if not a then return end
        pcall(function()
            a.Disabled = true
            task.wait()
            a.Disabled = false
        end)
    end

    -- ---- EMOTE OVERLAY (main langsung — kartu EMOT) ----
    local function emoteDanceStop()
        local t = EMOTE.danceTrack
        EMOTE.danceTrack = nil
        if t then
            pcall(function() t:Stop(0.2) end)
            pcall(function() t:Destroy() end)
        end
    end

    local function emoteMainkan(idAnim, judul)
        if not idAnim then return end
        if EMOTE.danceTrack and EMOTE.danceTrackJudul == judul then
            emoteDanceStop()   -- ketuk emote yang sama = stop
            return
        end
        emoteDanceStop()
        local id = idAnim
        local char = getChar()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = hum
        end
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        local okTrack, track = pcall(function() return animator:LoadAnimation(anim) end)
        if not okTrack or not track then
            toast("🎭 Emote gagal load (ID tidak boleh dipakai game ini)", Warna.Kuning)
            return
        end
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = true
        EMOTE.danceTrack = track
        EMOTE.danceTrackJudul = judul
        track:Play(0.15)
        -- pengawas: dance stop otomatis saat bergerak / lompat / renang / mati
        task.spawn(function()
            while EMOTE.danceTrack == track do
                local c = getChar()
                local h = c and c:FindFirstChildOfClass("Humanoid")
                if not h or h.Health <= 0 then break end
                local st = h:GetState()
                if h.MoveDirection.Magnitude > 0.05
                    or st == Enum.HumanoidStateType.Jumping
                    or st == Enum.HumanoidStateType.Freefall
                    or st == Enum.HumanoidStateType.Swimming
                    or st == Enum.HumanoidStateType.Climbing then
                    emoteDanceStop()
                    break
                end
                task.wait(0.1)
            end
        end)
    end

    local function emoteTerapkanSemua(char)
        char = char or getChar()
        if not char then return end
        if not char:FindFirstChild("Animate") then return end
        for _, s in ipairs(SLOT_LIST) do
            local k = s.k
            local id = nil
            if EMOTE.master then id = emoteResolveSlot(k) end
            emoteSetSlotId(k, char, id)
        end
        emoteRestartAnimate()
    end

    -- ---- API utama (dipakai UI / Setters / sync) ----
    emoteSetMaster = function(on, silent)
        on = on and true or false
        if EMOTE.master == on and State.EmoteOn == on then return end
        EMOTE.master = on
        State.EmoteOn = on
        emoteSimpan()
        emoteTerapkanSemua()
        if not silent then
            if on then
                toast("⚡ Animasi kustom ON — gaya pilihanmu aktif", Warna.Hijau)
            else
                toast("⚡ Animasi kustom OFF — balik ke animasi game", Warna.Kuning)
            end
        end
        if Switches["Emote"] then Switches["Emote"].set(on) end
        if emoteRefreshGrid then emoteRefreshGrid() end
        syncTandai()
    end

    emotePilihPreset = function(k, pi, kv)
        if not SLOT_FOLDERS[k] then return end
        if kv then
            EMOTE.kustom[k] = kv        -- { id, anim, nama }
            EMOTE.preset[k] = -1
        else
            EMOTE.preset[k] = pi
            if pi ~= -1 then EMOTE.kustom[k] = nil end
        end
        emoteSimpan()
        local char = getChar()
        if char then
            local id = nil
            if EMOTE.master then id = emoteResolveSlot(k) end
            emoteSetSlotId(k, char, id)
            emoteRestartAnimate()
        end
        if emoteRefreshGrid then emoteRefreshGrid() end
        syncTandai()
        local _, nama = emoteResolveSlot(k)
        toast("🎬 " .. slotLabel(k) .. ": " .. tostring(nama), Warna.Ungu2)
    end

    -- ---- CEK ID KUSTOM — jelaskan KENAPA sebuah ID bisa / tidak bisa ----
    --  Aturan Roblox (per Jul 2025, aset Animation = RESTRICTED): sebuah
    --  game hanya boleh memuat animasi milik Roblox (userId 1), milik
    --  pembuat game itu sendiri (game.CreatorId), atau aset yang secara
    --  eksplisit diberi izin ke game tsb. Selain itu → gagal dimuat.
    --  Hasil cek: cb(okeh, pesanNotif, namaAset)
    emoteCekId = function(id, cb)
        task.spawn(function()
            local num = tonumber(id)
            local okI, info = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(num)
            end)
            local tipe = (okI and type(info) == "table") and tonumber(info.AssetTypeId) or nil
            local nama = (okI and type(info) == "table" and info.Name)
                and tostring(info.Name) or ("ID " .. tostring(id))
            -- 1) BUNDLE katalog? ekstrak animasi di dalamnya (AssetService)
            if tipe ~= Enum.AssetType.Animation.Value then
                local okB, b = pcall(function()
                    return game:GetService("AssetService"):GetBundleDetailsAsync(num)
                end)
                local items = nil
                if okB and type(b) == "table" then
                    items = b.Items or (type(b.BundleInfo) == "table" and b.BundleInfo.Items) or nil
                end
                if type(items) == "table" then
                    local idAnim = nil
                    for _, it in ipairs(items) do
                        if type(it) == "table" and it.Type == "Animation" and tonumber(it.Id) then
                            idAnim = tostring(it.Id)
                            if type(it.Name) == "string" and #it.Name > 1 then nama = tostring(it.Name) end
                            break
                        end
                    end
                    if idAnim then
                        -- pastikan animasi bundle benar2 bisa dimuat game ini
                        local bisa = false
                        pcall(function()
                            local a = Instance.new("Animation")
                            a.AnimationId = "rbxassetid://" .. idAnim
                            local st
                            game:GetService("ContentProvider"):PreloadAsync({ a }, function(_, st2) st = st2 end)
                            bisa = (st == Enum.AssetFetchStatus.Success)
                        end)
                        if bisa then
                            cb(true, "OK — bundle '" .. nama .. "' → animasi siap",
                                { nama = nama, anim = idAnim, tipe = "bundle" })
                        else
                            cb(false, "Bundle '" .. nama .. "' DITOLAK game ini "
                                .. "(animasinya bukan milik Roblox/dev game)")
                        end
                        return
                    end
                end
            end
            if not okI or type(info) ~= "table" then
                cb(false, "ID " .. tostring(id) .. " tidak dikenal Roblox — cek angkanya lagi")
                return
            end
            if tipe ~= Enum.AssetType.Animation.Value then
                cb(false, "Bukan animasi (" .. nama .. ") — halamannya harus bertipe Animation atau Bundle emote")
                return
            end
            local cr = (type(info.Creator) == "table") and info.Creator or {}
            local cTipe = tostring(cr.CreatorType or info.CreatorType or "?")
            local cId = tonumber(cr.TargetId or cr.Id or info.CreatorTargetId)
            local milikRoblox = (cTipe == "User" and cId == 1)
            local milikGame = (cId ~= nil and cTipe == tostring(game.CreatorType)
                               and cId == game.CreatorId)
            if milikRoblox or milikGame then
                cb(true, "OK — animasi resmi (" .. nama .. ") bisa dimuat",
                    { nama = nama, anim = tostring(id), tipe = "anim" })
                return
            end
            local pemilik = tostring(cr.Name or "pengguna lain")
            -- mungkin dev game memberi izin khusus ke aset ini → cek beneran
            local bisa = false
            pcall(function()
                local a = Instance.new("Animation")
                a.AnimationId = "rbxassetid://" .. tostring(id)
                local st
                game:GetService("ContentProvider"):PreloadAsync({ a }, function(_, st2) st = st2 end)
                bisa = (st == Enum.AssetFetchStatus.Success)
            end)
            if bisa then
                cb(true, "OK — game ini punya izin khusus (" .. nama .. ")",
                    { nama = nama, anim = tostring(id), tipe = "anim" })
            else
                cb(false, "Animasi '" .. nama .. "' milik " .. pemilik
                    .. " → DITOLAK game ini. Harus milik Roblox / dev game")
            end
        end)
    end

    -- ---- pasang ulang otomatis tiap spawn ----    -- ---- pasang ulang otomatis tiap spawn ----
    local emoteCharSudah = {}

    local function emoteInitCharacter(char)
        if not char or emoteCharSudah[char] then return end
        emoteCharSudah[char] = true
        EMOTE.danceTrack, EMOTE.danceTrackJudul = nil, nil
        task.spawn(function()
            local a = char:WaitForChild("Animate", 15)
            if not a then return end
            task.wait(CFG.EMOTE_TUNGGAK)
            if State.Removed or not char.Parent then return end
            emoteDeteksiRig(char)
            emoteCaptureBaseline(char)
            emoteTerapkanSemua(char)
            if emoteRefreshGrid then emoteRefreshGrid() end
        end)
    end

    emoteMuat()
    catat(LocalPlayer.CharacterAdded:Connect(function(char) emoteInitCharacter(char) end))
    task.spawn(function()
        task.wait(1.0)
        local char = getChar()
        if char then emoteInitCharacter(char) end
    end)
    local emoteHitung = 0
    for _, p in ipairs(EMOTE_DAFTAR) do if p.n then emoteHitung = emoteHitung + 1 end end
    print("[BALAP-ANIMASI] siap — 7 slot gaya gerak + " .. emoteHitung .. " emote • master "
    .. (EMOTE.master and "ON" or "OFF")
    .. " • aktif " .. emoteJumlahAktif() .. "/7")

    -- ======================================================================
    -- ☁ SINKRON — CONFIG EMOTE lintas device
    -- Layanan : textdb.dev — gratis, tanpa login, TANPA blokir executor
    --           (jsonblob.com diblokir Cloudflare, sudah diganti sejak v1.3)
    -- Kode    : balap-xxxx-xxxx — dibaca manusia, mudah diketik. Selalu
    --           tampil di kartu ☁ SINKRON (tab SYSTEM) + tombol SALIN.
    --           Device lain bergabung lewat MASUKKAN KODE. GANTI KODE =
    --           loker baru.
    -- Isi sync: CONFIG EMOTE saja — master ON/OFF + pilihan preset per
    --           slot + ID kustom per slot (7 slot) + emote kustom.
    --           (speed/jump/dll) TIDAK ikut.
    -- Merge   : per-slot TERBARU MENANG. Slot yang tidak disentuh device
    --           lain tetap milik device ini. Tidak ada tombstone — config
    --           hanya config kecil, tidak mungkin "bangkit dari kubur".
    -- Ritme   : upload ditunda 30 dtk setelah perubahan terakhir •
    --           download saat load + tiap 3 menit • anti ping-pong.
    -- Offline : diam + toast sekali, config aman di lokal, retry otomatis.
    -- File    : BALAP_SYNC.json (kode loker, tersimpan permanen).
    -- ======================================================================
    local SYNC = {
        kode          = nil,   -- ID loker (contoh: balap-7k2m-9xq4)
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

    -- ---- file BALAP_SYNC.json: kode loker ----
    local function syncSimpanFile()
        getgenv().BALAP_SYNC_DATA = { kode = SYNC.kode }
        if not EMOTE.bisaFile then return end
        pcall(function()
            writefile(CFG.SYNC_FILE, HttpService:JSONEncode({
                kode  = SYNC.kode,
                dari  = SYNC.labelPerangkat,
                waktu = os.time(),
            }))
        end)
    end

    local function syncMuatFile()
        local data
        if EMOTE.bisaFile then
            local ada = false
            pcall(function() ada = isfile(CFG.SYNC_FILE) end)
            if ada then
                pcall(function() data = HttpService:JSONDecode(readfile(CFG.SYNC_FILE)) end)
            end
        end
        if type(data) ~= "table" then
            data = rawget(getgenv(), "BALAP_SYNC_DATA")
        end
        if type(data) == "table" and type(data.kode) == "string" then
            local k = data.kode:lower()
            if k:match("^%d+$") then
                -- kode lama (jsonblob, sudah mati) -> abaikan
            elseif #k >= 6 and #k <= 40 and k:match("^[a-z0-9%-]+$") then
                SYNC.kode = k
            end
        end
        print("[BALAP-SYNC] muat file: kode=" .. tostring(SYNC.kode or "-"))
    end
    syncMuatFile()

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
            local n = emoteJumlahAktif()
            if not SYNC.bisaHttp then
                ui.info.Text = ("%d/7 slot • executor tanpa HTTP — sync nonaktif"):format(n)
            else
                local kodeTeks = SYNC.kode and ("Kode: " .. SYNC.kode) or "Kode: belum dibuat"
                ui.info.Text = ("%d/7 slot • %s • %s"):format(n, EMOTE.rig, kodeTeks)
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
                toast("☁ offline — config aman di lokal", Warna.Kuning)
            end
        else
            SYNC.offSudahToast = false
        end
        syncRefreshKartu()
    end

    syncTandai = function()
        syncSimpanFile()
        SYNC.pending = true
        SYNC.waktuUbah = os.clock()
        SYNC.status = "kirim"
        syncRefreshKartu()
    end

    -- ---- payload & validasi ----
    local function syncPayload()
        return {
            v      = 2,
            master = EMOTE.master,
            preset = EMOTE.preset,
            kustom = EMOTE.kustom,
            kustomEmote = EMOTE.kustomEmote,
            dari   = SYNC.labelPerangkat,
            waktu  = os.time(),
        }
    end

    -- validasi struktur data cloud (anti sabotase — kode bisa tersebar)
    local function syncValidasi(data)
        if type(data) ~= "table" or data.v ~= 2 then return nil end
        local function ambilPreset()
            local t = {}
            if type(data.preset) ~= "table" then return t end
            local n = 0
            for k, v in pairs(data.preset) do
                if SLOT_BY_KEY[k] and type(v) == "number" and v == math.floor(v)
                    and v >= -1 and v <= 30 then
                    t[k] = v
                    n = n + 1
                    if n > 24 then return nil end
                end
            end
            return t
        end
        local function ambilKustom()
            local t = {}
            if type(data.kustom) ~= "table" then return t end
            local n = 0
            for k, v in pairs(data.kustom) do
                local nv = emoteNormKustom(v)
                if SLOT_BY_KEY[k] and nv then
                    t[k] = nv
                    n = n + 1
                    if n > 24 then return nil end
                end
            end
            return t
        end
        local preset = ambilPreset()
        if preset == nil then return nil end
        local kustom = ambilKustom()
        if kustom == nil then return nil end
        return {
            master = data.master == true,
            preset = preset,
            kustom = kustom,
            kustomEmote = emoteNormKustom(data.kustomEmote),
            dari   = type(data.dari) == "string" and data.dari:sub(1, 60) or "?",
            waktu  = tonumber(data.waktu) or 0,
        }
    end

    -- ---- merge cloud -> lokal (per-slot terbaru menang) ----
    local function syncMerge(cloud)
        local berubah = 0
        local rincian = {}
        if cloud.master ~= EMOTE.master then
            berubah = berubah + 1
            rincian[#rincian + 1] = cloud.master and "master ON" or "master OFF"
            emoteSetMaster(cloud.master, true)   -- set master + pasang ulang + UI + simpan
        end
        for k, v in pairs(cloud.preset) do
            if (EMOTE.preset[k] or 0) ~= v then
                EMOTE.preset[k] = v
                berubah = berubah + 1
                rincian[#rincian + 1] = k
            end
            if v ~= -1 and EMOTE.kustom[k] then
                EMOTE.kustom[k] = nil   -- kustom dibuang di device lain
                berubah = berubah + 1
            end
        end
        for k, v in pairs(cloud.kustom) do
            if emoteKKey(EMOTE.kustom[k]) ~= emoteKKey(v) then
                EMOTE.kustom[k] = v
                EMOTE.preset[k] = -1
                berubah = berubah + 1
                rincian[#rincian + 1] = k .. " (kustom)"
            end
        end
        if type(cloud.kustomEmote) == "table"
            and emoteKKey(EMOTE.kustomEmote) ~= emoteKKey(cloud.kustomEmote) then
            EMOTE.kustomEmote = cloud.kustomEmote
            berubah = berubah + 1
            rincian[#rincian + 1] = "emote kustom"
        end
        if berubah > 0 then
            emoteSimpan()
            emoteTerapkanSemua()                 -- gaya baru langsung tampil
            if emoteRefreshGrid then emoteRefreshGrid() end
        end
        return berubah, rincian
    end

    local function syncRingkas(rincian)
        local maks = 4
        local b = {}
        for i, r in ipairs(rincian) do
            if i > maks then
                b[#b + 1] = "..."
                break
            end
            b[#b + 1] = r
        end
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
                ["User-Agent"]   = "Mozilla/5.0 (BALAP v1.4)",
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
    -- (teruji sejak v1.3: payload besar lolos utuh).
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
            -- loker ada tapi belum berisi -> tandai biar diisi config lokal
            if not SYNC.kosongSudah then
                SYNC.kosongSudah = true
                toast("☁ loker kosong — config device ini akan diunggah", Warna.Kuning)
            end
            SYNC.pending = true
            sukses = true
        elseif type(cloud) == "table" then
            SYNC.lastDari = cloud.dari
            local berubah, rincian = syncMerge(cloud)
            if berubah > 0 then
                toast("☁ dari cloud: " .. syncRingkas(rincian), Warna.Biru)
                syncTandai()   -- gabungan terbaru diunggah balik sekali
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
            -- loker kosong / isinya sampah -> isi ulang dengan config lokal
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
            local w0 = SYNC.waktuUbah    -- anti balapan: syncTandai saat POST jalan
            local teks = HttpService:JSONEncode(syncPayload())
            if teks == SYNC.lastPayload and SYNC.waktuUbah == w0 then
                SYNC.pending = false      -- isinya sama -> jangan upload ulang
                syncSimpanFile()
                sukses = true
            else
                local put = syncHttp("POST", CFG.SYNC_URL .. SYNC.kode, syncBodyForm(teks))
                if put and (put.code == 200 or put.code == 201) then
                    SYNC.lastPayload = teks
                    if SYNC.waktuUbah == w0 then
                        SYNC.pending = false  -- bersih; kalau berubah, antrean lanjut
                    end
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
            syncTandai()   -- config device ini ikut digabung ke loker
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

    -- ganti kode = buat loker baru berisi config sekarang
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

    -- set ulang cloud = samakan cloud dengan device ini
    -- (penyelamat kalau data cloud kacau)
    local function syncSetUlang()
        if SYNC.sibuk or State.Removed or not SYNC.kode then return end
        SYNC.sibuk = true
        SYNC.status = "kirim"
        syncRefreshKartu()
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
            task.wait(2.5)                 -- beri waktu GUI & config lokal siap
            if State.Removed then return end
            if SYNC.kode then
                syncUnduh()
                -- rekonsiliasi sesi: perubahan lokal yang belum sempat
                -- terunggah (script ditutup < 30 dtk setelah ubah -> pending
                -- hilang) dipastikan terunggah di awal sesi.
                if not SYNC.pending then
                    SYNC.pending = true
                    SYNC.waktuUbah = os.clock() - CFG.SYNC_UNGGAH_JEDA
                end
            else
                syncBuatLoker()
            end
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
        -- kedip kuning saat kirim/terima (status dot berwarna)
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

    -- [7b] TAB BAR (3 TAB) ----------------------------------------------
    -- Bungkus dengan function untuk hemat local count (Luau limit 200)
    local function buildUI()
        tabBtns = {}
        local tabLabels = {"MOVEMENT & VISUAL", "ANIMASI", "SYSTEM"}
        local tabColors = {Warna.Ungu2, Warna.Kuning, Warna.AbuGelap}
        kontenTabs = {}
        for i, lbl in ipairs(tabLabels) do
            local tab = buat("TextButton", {
                Size = UDim2.new(1 / 3, -4, 0, 24),
                Position = UDim2.new((i - 1) * (1 / 3), 4.5 + (i - 1) * 1.6, 0, 50),
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
                local n = angkaDari(box.Text)  -- v1.3: terima "17,25" (koma)
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
        State.EmoteOn  = EMOTE.master  -- Master Animasi Kustom (tab ANIMASI, ikut config tersimpan)
        State.HideAtasOn = false  -- Hide Badan Atas (VISUAL, layar sendiri)
        State.PanahOn = false    -- Panah Deteksi (V)

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
        buatToggleRow(scrollMove, "Panah Deteksi (depan/belakang)", "V", "Panah")
        buatHeader(scrollMove, "Lightweight")
        buatToggleRow(scrollMove, "Partikel / Bayangan / Efek", nil, "LW")
        buatHeader(scrollMove, "Map")
        buatToggleRow(scrollMove, "Dinding Batas", "X", "Walls")

        -- [7g] KONTEN TAB 3: SYSTEM -----------------------------------------
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


        -- [7e] KONTEN TAB 2: ANIMASI ------------------------------------------
        -- Kartu 1 ANIMASI: 7 slot gaya gerak (klik slot -> popup gaya)
        -- Kartu 2 EMOT   : daftar emote main langsung + kustom ID/bundle
        kontenEmote = buat("Frame", {
            Position = UDim2.new(0, 0, 0, 80),
            Size = UDim2.new(1, 0, 1, -110),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        }, panel)
        table.insert(kontenTabs, kontenEmote)
        scrollEmote = buat("ScrollingFrame", {
            Position = UDim2.new(0, 12, 0, 2),
            Size = UDim2.new(1, -24, 1, -6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Warna.Ungu,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, kontenEmote)
        buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollEmote)

        -- master toggle (ON = semua gaya kustom aktif, OFF = default game)
        buatToggleRow(scrollEmote, "⚡ Animasi Kustom (master)", nil, "Emote")

        -- status kecil: rig + jumlah slot aktif
        local emoteStatus = buat("TextLabel", {
            BackgroundColor3 = Warna.AbuItem,
            Size = UDim2.new(1, 0, 0, 26),
            FontFace = fnt("med"),
            TextSize = 11,
            TextColor3 = Warna.AbuTeks,
            TextXAlignment = Enum.TextXAlignment.Center,
            Text = "Rig: mendeteksi... • klik slot = pilih gaya",
            LayoutOrder = nextOrder(),
        }, scrollEmote)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, emoteStatus)

        -- grid 3x3 slot
        local emoteGrid = buat("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 156),
            LayoutOrder = nextOrder(),
        }, scrollEmote)
        buat("UIGridLayout", {
            CellSize = UDim2.new(1 / 3, -4, 0, 48),
            CellPadding = UDim2.new(0, 4, 0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, emoteGrid)
        local emoteSubs = {}
        local emoteBukaChooser  -- forward declare (didefinisikan di bawah)
        local emoteBukaRename   -- popup ganti nama (kustom slot / emote)
        local emoteRefreshEmot  -- refresh tanda ▶ daftar emote (kartu EMOT)
        local lbKustomEmot      -- baris ★ emote kustom
        for i, s in ipairs(SLOT_LIST) do
            local b = buat("TextButton", {
                BackgroundColor3 = Warna.AbuItem,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = i,
            }, emoteGrid)
            buat("UICorner", {CornerRadius = UDim.new(0, 8)}, b)
            buat("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 6),
                Size = UDim2.new(1, 0, 0, 16),
                FontFace = fnt("bold"),
                TextSize = 12,
                TextColor3 = Warna.TeksGelap,
                Text = s.t,
            }, b)
            local sub = buat("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 4, 0, 24),
                Size = UDim2.new(1, -8, 0, 16),
                FontFace = fnt("reg"),
                TextSize = 10,
                TextScaled = true,
                TextColor3 = Warna.AbuTeks,
                Text = "ASLI",
            }, b)
            buat("UITextSizeConstraint", {MaxTextSize = 10}, sub)
            efekTombol(b, 1.05)
            local skey = s.k
            b.MouseButton1Click:Connect(function()
                ripple(b, Warna.Putih)
                if emoteBukaChooser then emoteBukaChooser(skey) end
            end)
            emoteSubs[s.k] = sub
        end

        -- refresh grid + status (dipanggil modul emote & sync)
        emoteRefreshGrid = function()
            for _, s in ipairs(SLOT_LIST) do
                local sub = emoteSubs[s.k]
                if sub then
                    local id, nama = emoteResolveSlot(s.k)
                    if EMOTE.master and id then
                        sub.Text = tostring(nama)
                        sub.TextColor3 = Warna.Ungu
                    else
                        sub.Text = "ASLI"
                        sub.TextColor3 = Warna.AbuTeks
                    end
                end
            end
            local n = emoteJumlahAktif()
            local rigTeks = tostring(EMOTE.rig)
            local masterTeks = EMOTE.master and "master ON" or "master OFF"
            emoteStatus.Text = "Rig: " .. rigTeks .. " • " .. n .. "/7 slot gaya baru • " .. masterTeks
        end

        -- ===== kolom ID/BUNDLE → SLOT DIHAPUS (v1.02) =====
        -- Semua ID sekarang bawaan Roblox (ada di PRESET & DAFTAR);
        -- tidak ada lagi input ID manual untuk slot.
        -- --------------------------------------------------------------
        -- RESET SEMUA — konfirmasi 2 langkah (3 dtk)
        local armResetEmote = 0
        local btnResetEmote
        btnResetEmote = buatActionRow(scrollEmote, "↺ RESET SEMUA → ANIMASI ASLI", Warna.Merah, function()
            local now = os.clock()
            if now - armResetEmote > 3 then
                armResetEmote = now
                btnResetEmote.Text = "⚠️ YAKIN? TEKAN LAGI"
                toast("Semua slot balik ke animasi ASLI — tekan lagi", Warna.Kuning)
                task.delay(3, function()
                    if btnResetEmote.Parent and btnResetEmote.Text ~= "↺ RESET SEMUA → ANIMASI ASLI" then
                        btnResetEmote.Text = "↺ RESET SEMUA → ANIMASI ASLI"
                    end
                end)
            else
                armResetEmote = 0
                btnResetEmote.Text = "↺ RESET SEMUA → ANIMASI ASLI"
                for _, s in ipairs(SLOT_LIST) do
                    EMOTE.preset[s.k] = nil
                    EMOTE.kustom[s.k] = nil
                end
                emoteSimpan()
                emoteDanceStop()
                emoteTerapkanSemua()
                if emoteRefreshGrid then emoteRefreshGrid() end
                syncTandai()
                toast("Semua slot balik ke animasi ASLI", Warna.Merah)
            end
        end)

        -- ===== kartu 2: EMOT — main langsung =====
        buatHeader(scrollEmote, "EMOT — MAIN SEKARANG")
        local emotLbl = {}
        for i, p in ipairs(EMOTE_DAFTAR) do
            if p.g then
                buatHeader(scrollEmote, p.g)
            else
                local tag = (p.i15 and p.i6 and " (R15+R6)") or (p.i15 and " (R15)") or " (R6)"
                local lb = buatActionRow(scrollEmote, p.n .. tag, Warna.Biru, function()
                    local id = (EMOTE.rig == "R6") and p.i6 or p.i15
                    if not id then
                        toast("Emote " .. p.n .. " untuk rig " .. (p.i6 and "R6" or "R15") .. " saja", Warna.Kuning)
                        return
                    end
                    emoteMainkan("rbxassetid://" .. id, p.n)
                    emoteRefreshEmot()
                end)
                emotLbl[i] = lb
            end
        end
        -- 🪑 Duduk dihapus (permintaan user) — ⏹ STOP tetap ada untuk
        -- menghentikan emote yang sedang main.
        buatActionRow(scrollEmote, "⏹ STOP EMOTE", Warna.Merah, function()
            emoteDanceStop()
            emoteRefreshEmot()
            toast("⏹ Emote dihentikan", Warna.Kuning)
        end)

        -- ===== kartu EMOTE KUSTOM DIHAPUS (v1.02) =====
        -- Tempel ID kustom & ganti nama dihapus — daftar sudah diisi
        -- 80 emote resmi Roblox.
        -- --------------------------------------------------------------
        emoteRefreshEmot = function()
            for i, p in ipairs(EMOTE_DAFTAR) do
                local lb = emotLbl[i]
                if lb then
                    local aktif = EMOTE.danceTrack and (EMOTE.danceTrackJudul == p.n)
                    lb.Text = (aktif and "▶ " or "") .. p.n
                        .. ((p.i15 and p.i6 and " (R15+R6)") or (p.i15 and " (R15)") or " (R6)")
                end
            end
        end
        emoteRefreshEmot()
        -- catatan kecil
        buat("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
            FontFace = fnt("reg"),
            TextSize = 10,
            TextColor3 = Warna.AbuTeks,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Kartu ANIMASI: gaya gerak terlihat juga oleh pemain lain. Kartu EMOT: main langsung, berhenti sendiri saat bergerak. Semua animasi milik Roblox — jalan di game mana pun tanpa membeli.",
            LayoutOrder = nextOrder(),
        }, scrollEmote)

        -- ===== POPUP PILIH GAYA (overlay di panel) =====
        local chooserBackdrop = buat("TextButton", {
            Visible = false,
            ZIndex = 48,
            BackgroundColor3 = Warna.Hitam,
            BackgroundTransparency = 0.35,
            Size = UDim2.new(1, 0, 1, 0),
            Text = "",
            AutoButtonColor = false,
        }, panel)
        local chooser = buat("Frame", {
            Visible = false,
            ZIndex = 49,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -30, 0, 330),
            BackgroundColor3 = Warna.Hitam2,
            BorderSizePixel = 0,
        }, panel)
        buat("UICorner", {CornerRadius = UDim.new(0, 12)}, chooser)
        buat("UIStroke", {Color = Warna.Ungu2, Thickness = 2}, chooser)
        local chooserJudul = buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 8),
            Size = UDim2.new(1, -64, 0, 18),
            ZIndex = 50,
            FontFace = fnt("bold"),
            TextSize = 13,
            TextColor3 = Warna.Putih,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "PILIH GAYA",
        }, chooser)
        local chooserTutupBtn = buat("TextButton", {
            Position = UDim2.new(1, -34, 0, 6),
            Size = UDim2.fromOffset(28, 22),
            ZIndex = 50,
            BackgroundColor3 = Warna.Merah,
            FontFace = fnt("bold"),
            TextSize = 12,
            TextColor3 = Warna.Putih,
            Text = "✕",
            AutoButtonColor = false,
        }, chooser)
        buat("UICorner", {CornerRadius = UDim.new(0, 6)}, chooserTutupBtn)
        local chooserList = buat("ScrollingFrame", {
            Position = UDim2.new(0, 10, 0, 30),
            Size = UDim2.new(1, -20, 1, -40),
            ZIndex = 50,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Warna.Ungu2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, chooser)
        buat("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, chooserList)
        local chooserOrder = 0
        local function chooserNext() chooserOrder = chooserOrder + 1 return chooserOrder end

        emoteBukaChooser = function(skey)
            if not SLOT_FOLDERS[skey] then return end
            local rig = EMOTE.rig
            local aktifPi = EMOTE.preset[skey] or 0
            local aktifKustom = EMOTE.kustom[skey]
            chooserJudul.Text = "GAYA " .. slotLabel(skey) .. "  (rig " .. rig .. ")"
            chooserOrder = 0
            for _, c in ipairs(chooserList:GetChildren()) do
                if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
            end
            -- baris pilihan
            local function tambahBar(teks, warna, bisa, cb)
                local br = buat("TextButton", {
                    Size = UDim2.new(1, -6, 0, 30),
                    BackgroundColor3 = bisa and Warna.Card2 or Warna.Hitam,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 50,
                    LayoutOrder = chooserNext(),
                }, chooserList)
                buat("UICorner", {CornerRadius = UDim.new(0, 8)}, br)
                buat("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    ZIndex = 50,
                    FontFace = fnt("med"),
                    TextSize = 12,
                    TextColor3 = warna,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Text = teks,
                }, br)
                br.MouseButton1Click:Connect(function()
                    if bisa then cb() else toast("Preset ini tidak untuk rig " .. rig, Warna.Kuning) end
                end)
            end
            -- 1) ASLI
            tambahBar("ASLI — animasi default game" .. (aktifPi == 0 and not aktifKustom and "   ✓" or ""),
                Warna.Putih, true, function()
                emotePilihPreset(skey, 0)
                chooserBackdrop.Visible = false
                chooser.Visible = false
            end)
            -- 2) preset resmi
            for pi, p in ipairs(EMOTE_PRESET[skey] or {}) do
                local id = (rig == "R6") and p.i6 or p.i15
                local tagRig = (p.i15 and p.i6 and "(R15+R6)") or (p.i15 and "(R15)") or "(R6)"
                local teks = p.n .. "  " .. tagRig
                if aktifPi == pi and not aktifKustom then teks = teks .. "   ✓" end
                if id then
                    tambahBar(teks, Warna.Ungu2, true, function()
                        emotePilihPreset(skey, pi)
                        chooserBackdrop.Visible = false
                        chooser.Visible = false
                    end)
                else
                    tambahBar(teks .. "  ✕", Warna.AbuTeks, false, nil)
                end
            end
            chooserBackdrop.Visible = true
            chooser.Visible = true
        end
        chooserTutupBtn.MouseButton1Click:Connect(function()
            chooserBackdrop.Visible = false
            chooser.Visible = false
        end)
        chooserBackdrop.MouseButton1Click:Connect(function()
            chooserBackdrop.Visible = false
            chooser.Visible = false
        end)

        -- ===== popup GANTI NAMA dihapus (v1.02 — tidak ada lagi nama
        -- kustom yang bisa diganti) =====

        -- urutan kontenTabs = urutan tab: 1 MOVEMENT & VISUAL • 2 EMOTE • 3 SYSTEM
        table.insert(kontenTabs, kontenSistem)

        -- ===== kartu ☁ SINKRON — config emote lintas device (tab SYSTEM) =====
        local kartuSync = buat("Frame", {
            BackgroundColor3 = Warna.Card2,
            Size = UDim2.new(1, 0, 0, 102),
            LayoutOrder = nextOrder(),
        }, scrollSistem)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, kartuSync)
        buat("UIStroke", {Color = Warna.Ungu2, Thickness = 1, Transparency = 0.55}, kartuSync)
        buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 5),
            Size = UDim2.new(1, -30, 0, 15),
            FontFace = fnt("bold"),
            TextSize = 12,
            TextColor3 = Warna.BiruMuda,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "☁ SINKRON — config emote lintas device",
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
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, -- tinggi ikut isi teks (anti teks keluar frame)
            FontFace = fnt("med"),
            TextSize = 12,
            TextColor3 = Warna.TeksGelap,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Text = "⚡ EMOT V1.03\n"
            .. "TAB 1 MOVEMENT & VISUAL: Speed (Q) • Jump (J)\n"
            .. "Shiftlock (C) • Shiftlock Tengah (LShift) • Moonwalk (F, S = OFF)\n"
            .. "Hide (R) • Hide Atas • Cahaya Auto (T) • Lightweight\n"
            .. "Dinding Batas (X) • Panah Deteksi (V): ↑ merah = ada pemain\n"
            .. "di depan badan, ↓ merah = di belakang (100 stud tiap arah,\n"
            .. "samping 45° bebas = hijau)\n"
            .. "TAB 2 ANIMASI: kartu gaya gerak — 7 slot (IDLE JALAN LARI\n"
            .. "RENANG MANJAT LOMPAT JATUH), klik slot = pilih gaya (ASLI /\n"
            .. "18 pack resmi Roblox). Kartu EMOT: 80 emote Roblox main\n"
            .. "langsung + Stop.\n"
            .. "Gaya jalan/lari/dll terlihat juga pemain lain; DANCE stop\n"
            .. "otomatis saat bergerak; gaya dipasang ulang setelah respawn.\n"
            .. "TAB 3 SYSTEM: ☁ SINKRON — config emote lintas device,\n"
            .. "salin kode ke device lain (MASUKKAN KODE untuk nyambung)\n"
            .. "Rejoin (K×2) • Hapus Script\n"
            .. "Shift/Moonwalk/Tengah otomatis OFF saat mati/respawn",
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
            Text = "⌨ G = GUI   ✦   🏃 Q Speed ON/OFF (nilai ON 17.25-21.25) • J Jump (51.25/65.25) • C Shift • LShift Tengah • F Moonwalk • V Panah   ✦   🎭 TAB ANIMASI: 7 gaya gerak + EMOT main langsung + ID/bundle kustom   ✦   🎨 R Hide • Hide Atas • T Cahaya 2-arah • X Dinding • LW   ✦   ☁ config emote tersinkron — kode di tab SYSTEM   ✦   ⚙️ K×2 rejoin • Notif kanan atas",
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

        -- [13] (v1.3) sistem FADE PER-ELEMEN dihapus — sudah mati sejak
        -- buka/tutup GUI jadi instan (kumpulkanFade tidak pernah dipanggil),
        -- cuma numpuk kode & koneksi.

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
            -- bonus berenang HANYA saat Shiftlock Tengah aktif —
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

        -- CEK KENDARAAN — dipakai Shiftlock Mobile & Moonwalk.
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
                -- v1.3: unbind dulu — bind ganda = error + state ON tanpa efek
                pcall(function() RunService:UnbindFromRenderStep("KS_SHIFTLOCK") end)
                RunService:BindToRenderStep("KS_SHIFTLOCK", Enum.RenderPriority.Character.Value + 1, function()
                    local char = getChar()
                    local h = char and char:FindFirstChildOfClass("Humanoid")
                    local r = char and char:FindFirstChild("HumanoidRootPart")
                    -- naik kendaraan = TANPA EFEK: jangan sentuh CFrame
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
                -- v1.3: unbind dulu — bind ganda = error + state ON tanpa efek
                pcall(function() RunService:UnbindFromRenderStep("KS_MOONWALK") end)
                RunService:BindToRenderStep("KS_MOONWALK", Enum.RenderPriority.Character.Value + 1, function(dt)
                    local char = getChar()
                    local h = char and char:FindFirstChildOfClass("Humanoid")
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    -- naik kendaraan = TANPA EFEK: badan tidak dipaksa
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

        -- SHIFTLOCK TENGAH — port "SHIFT LOCK TENGAH v2"
        -- Kamera TIDAK diubah sama sekali (CameraOffset tetap di-tween ke
        -- Vector3.zero). Yang digeser cuma LETAK lingkaran kursor:
        -- panah komputer disembunyikan (MouseIconEnabled false) dan diganti
        -- lingkaran mini (CFG.SLT_DOT px) yang letaknya digeser ke bawah layar
        -- (CFG.SLT_DOT_Y, default 0.60 = sekitar pinggang/bawah badan karakter),
        -- kecil biar ga ganggu. Mekanisme native: MouseBehavior.LockCenter +
        -- RotationType.CameraRelative dijaga tiap frame via RenderStep (Camera+1).
        -- Toggle: LShift / RShift / switch GUI. Auto OFF saat mati/respawn
        -- (matikanGerak) + saling menonaktif dgn Shiftlock Mobile & Moonwalk.
        local sltTween, sltTweening, sltOffsetAsli = nil, false, nil
        local sltDotGui, sltDot  -- lingkaran kursor mini
        local sltUGS
        pcall(function() sltUGS = UserSettings():GetService("UserGameSettings") end)
        -- lingkaran kursor mini, letaknya digeser ke bawah layar
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
                -- sembunyikan panah komputer, tampilkan lingkaran mini
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
                -- panah komputer balik, lingkaran disembunyikan
                pcall(function() UserInputService.MouseIconEnabled = true end)
                sltDotHide()
            end
            applySpeed()   -- bonus berenang langsung menyesuaikan / pulih
            syncNotify("Tengah", v, silent, "Shiftlock Tengah")
        end

        -- MASTER EMOTE (tab ANIMASI) — ON = gaya kustom aktif, OFF = default game.
        -- Dipanggil toggle tab ANIMASI & sync (merge config cloud).
        Setters.Emote = function(v, silent)
            emoteSetMaster(v, silent)   -- toast spesifik ada di emoteSetMaster
            syncNotify("Emote", v, true, "Animasi Kustom")  -- silent: anti dobel toast
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
            catat(plr.CharacterAdded:Connect(function(char)  -- v1.3: ter-catat
                task.wait(0.4)
                if State.HideOn and not State.Removed then hideCharacter(char) end
            end))
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

        -- PANAH DETEKSI (keybind V) — dua panah kecil di sisi KANAN layar:
        -- ↑ = MERAH kalau ada karakter lain DI DEPAN badan (ikut arah
        -- badan / LookVector HRP, BUKAN kamera), ↓ = MERAH kalau ada DI
        -- BELAKANG; hijau = kosong. Jarak 100 stud tiap arah (cakupan 200
        -- stud), depan & belakang 135 derajat (PANAH_SUDUT = cos 67.5°),
        -- samping 45 derajat = zona tenang. Loop task.wait(0.1) hemat.
        local panahGui, panahAtas, panahBawah, panahConn
        local PANAH_MERAH = Color3.fromRGB(255, 64, 64)
        local PANAH_HIJAU = Color3.fromRGB(64, 255, 100)
        Setters.Panah = function(v, silent)
            if State.PanahOn == v then return end
            State.PanahOn = v
            if v then
                if not panahGui or not panahGui.Parent then
                    panahGui = Instance.new("ScreenGui")
                    panahGui.Name = "BALAP_PANAH"
                    panahGui.ResetOnSpawn = false
                    panahGui.IgnoreGuiInset = true
                    panahGui.DisplayOrder = 9000
                    -- pasang ke tempat aman (gethui/CoreGui/PlayerGui),
                    -- buang sisa panah lama dulu
                    local kandidatP = {}
                    pcall(function() if gethui then table.insert(kandidatP, gethui()) end end)
                    pcall(function() table.insert(kandidatP, game:GetService("CoreGui")) end)
                    pcall(function() table.insert(kandidatP, LocalPlayer:WaitForChild("PlayerGui")) end)
                    for _, t in ipairs(kandidatP) do
                        pcall(function()
                            local lama = t:FindFirstChild("BALAP_PANAH")
                            if lama and lama ~= panahGui then lama:Destroy() end
                        end)
                    end
                    for _, t in ipairs(kandidatP) do
                        local ok = pcall(function() panahGui.Parent = t end)
                        if ok and panahGui.Parent == t then break end
                    end
                    local function buatPanah(txt, posY)
                        local t = Instance.new("TextLabel")
                        t.Name = (txt == "↑") and "PanahDepan" or "PanahBelakang"
                        t.BackgroundTransparency = 1
                        t.AnchorPoint = Vector2.new(1, 0)
                        t.Position = UDim2.new(1, -12, 0.5, posY)
                        t.Size = UDim2.new(0, 44, 0, 44)
                        t.Font = Enum.Font.GothamBlack
                        t.Text = txt
                        t.TextSize = 34
                        t.TextColor3 = PANAH_HIJAU
                        t.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        t.TextStrokeTransparency = 0.15
                        t.Parent = panahGui
                        return t
                    end
                    panahAtas = buatPanah("↑", -58)   -- ATAS = DEPAN badan
                    panahBawah = buatPanah("↓", 14)   -- di bawahnya = BELAKANG
                end
                panahGui.Enabled = true
                if panahConn then task.cancel(panahConn) end
                panahConn = task.spawn(function()
                    while State.PanahOn and not State.Removed do
                        task.wait(0.1)
                        local merahA, merahB = false, false
                        local char, hrp = getKarakter()
                        if char and hrp then
                            local myPos = hrp.Position
                            local look = hrp.CFrame.LookVector
                            for _, pl in ipairs(Players:GetPlayers()) do
                                if pl ~= LocalPlayer then
                                    local c2 = pl.Character
                                    local h2 = c2 and c2:FindFirstChildOfClass("Humanoid")
                                    local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                                    if h2 and r2 and h2.Health > 0 then
                                        local rel = r2.Position - myPos
                                        local d = rel.Magnitude
                                        if d > 0.5 and d <= CFG.PANAH_JARAK then
                                            local dot = look:Dot(rel / d)
                                            if dot >= CFG.PANAH_SUDUT then
                                                merahA = true  -- depan 135°
                                            elseif dot <= -CFG.PANAH_SUDUT then
                                                merahB = true  -- belakang 135°
                                            end -- sisanya samping 45° → tetap hijau
                                        end
                                    end
                                end
                            end
                        end
                        if panahAtas and panahAtas.Parent then
                            panahAtas.TextColor3 = merahA and PANAH_MERAH or PANAH_HIJAU
                        end
                        if panahBawah and panahBawah.Parent then
                            panahBawah.TextColor3 = merahB and PANAH_MERAH or PANAH_HIJAU
                        end
                    end
                end)
            else
                if panahConn then task.cancel(panahConn) panahConn = nil end
                if panahGui then pcall(function() panahGui:Destroy() end) panahGui = nil end
                panahAtas, panahBawah = nil, nil
            end
            syncNotify("Panah", v, silent, "Panah Deteksi")
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
        unloadScript = function(tenang)   -- v1.3: tenang = takeover, cleanup ringan
            if State.Removed then return end
            State.Removed = true
            -- 1) Matikan semua fitur (restore visual, kendaraan, dinding, cahaya)
            pcall(setFeature, "Speed", false, true)
            pcall(setFeature, "Jump", false, true)
            pcall(setFeature, "Shift", false, true)
            pcall(setFeature, "Moon", false, true)
            pcall(setFeature, "Tengah", false, true)
            pcall(setFeature, "Emote", false, true)
            pcall(setFeature, "Hide", false, true)
            pcall(setFeature, "LW", false, true)
            pcall(setFeature, "Walls", false, true)
            pcall(setFeature, "Light", false, true)
            pcall(setFeature, "HideAtas", false, true)
            pcall(setFeature, "Panah", false, true)
            -- 2) Unbind semua RenderStep binding (selalu)
            pcall(function() RunService:UnbindFromRenderStep("KS_SHIFTLOCK") end)
            pcall(function() RunService:UnbindFromRenderStep("KS_MOONWALK") end)
            pcall(function() RunService:UnbindFromRenderStep("KS_TENGAH") end)
            pcall(function()
                if sltDotGui then sltDotGui:Destroy() end
                sltDotGui, sltDot = nil, nil
            end)
            -- v1.3: reset mouse HANYA saat hapus manual. Saat takeover
            -- (tenang), instance baru bisa saja sudah memasang Tengah /
            -- lingkaran kursor sendiri — jangan ditimpa.
            if not tenang then
                pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
                pcall(function()
                    UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.MovementRelative
                end)
                pcall(function() UserInputService.MouseIconEnabled = true end)
            end
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
            -- 6) Reset karakter: WalkSpeed, JumpPower, JumpHeight, AutoRotate.
            --    v1.3: balik ke nilai "OFF" versi script (konsisten dgn label
            --    GUI), bukan 16/50/7.2 bawaan. Skip saat takeover (tenang) —
            --    jangan menimpa nilai yang baru dipasang instance baru.
            if not tenang then
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        local h = char:FindFirstChildOfClass("Humanoid")
                        if h then
                            h.WalkSpeed = CFG.SPEED_OFF
                            if h.UseJumpPower then
                                h.JumpPower = CFG.OFF_JUMP
                            else
                                h.JumpHeight = CFG.OFF_JUMP_H
                            end
                            h.AutoRotate = true
                        end
                    end
                end)
            end
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

        -- WATCHDOG TAKEOVER: instance lama bunuh diri otomatis begitu ada
        -- eksekusi BALAP yang lebih baru. Pemicu (cukup salah satu, cek tiap 0.5 dtk):
        --   (1) _G.__BALAP_TOKEN__ bukan miliknya      -> executor share _G
        --   (2) screenGui sudah dihapus eksekusi baru  -> executor isolasi _G
        --       (sweep "BalapMain" di awal eksekusi baru yang menghapusnya)
        -- Dulu ini penyebab siluman: Heartbeat Fall Assist instance lama tetap
        -- mem-pulse dengan potongan 30%, walau GUI baru sudah diset 0%.
        task.spawn(function()
            while not State.Removed do
                if _G.__BALAP_TOKEN__ ~= MY_TOKEN or not screenGui.Parent then
                    -- v1.3: kalau pemicunya TOKEN DIGANTI (ada eksekusi baru),
                    -- unload "tenang" — cleanup ringan yang tidak menimpa
                    -- instance baru. GUI hilang tanpa penerus = bersih total.
                    local adaPenerus = (_G.__BALAP_TOKEN__ ~= MY_TOKEN)
                    pcall(function() unloadScript(adaPenerus) end)
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
            -- Shiftlock, Moonwalk & Shiftlock Tengah OTOMATIS OFF saat mati/
            -- respawn. Dua lapis: langsung saat humanoid mati (Died) +
            -- jaga-jaga saat spawn baru (karakter diganti tanpa event Died).
            local function matikanGerak()
                local ada = State.ShiftOn or State.MoonOn or State.TengahOn
                -- v1.3: silent = tanpa toast per fitur (dulu 3 toast sekaligus)
                if State.ShiftOn then setFeature("Shift", false, true) end
                if State.MoonOn then setFeature("Moon", false, true) end
                if State.TengahOn then setFeature("Tengah", false, true) end
                if ada and not State.Removed then
                    toast("Shiftlock/Moonwalk OFF (mati/respawn)", Warna.Kuning)
                end
            end
            matikanGerak()
            catat(hum.Died:Connect(matikanGerak))
            catat(hum.StateChanged:Connect(function(_, newState)  -- v1.3: ter-catat
                local swimming = (newState == Enum.HumanoidStateType.Swimming)
                if swimming ~= State.IsSwimming then
                    State.IsSwimming = swimming
                    -- bonus berenang ikut Shiftlock Tengah; pulih otomatis
                    applySpeed()
                end
            end))
            task.wait(0.25)
            if State.Removed then return end
            if State.SpeedOn then applySpeed() end
            if State.JumpOn then applyJump() end
        end
        catat(LocalPlayer.CharacterAdded:Connect(initCharacter))  -- v1.3: ter-catat
        task.spawn(function()
            local c = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            initCharacter(c)
        end)
        catat(Players.PlayerAdded:Connect(playerHideHook))  -- v1.3: ter-catat
        for _, plr in ipairs(Players:GetPlayers()) do playerHideHook(plr) end
        catat(Players.PlayerRemoving:Connect(function(plr)
            if plr.Character then unhideCharacter(plr.Character) end
        end))
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
        end
        local function bukaGui()
            fitPanel()   -- pastikan skala pas layar setiap kali dibuka
            bunyi(CFG.SND_PING, 0.35, 1.15)
            root.Visible = true
            root.Rotation = 0
            panelScale.Scale = 1
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
            -- MOONWALK: tekan S = moonwalk langsung OFF. Tombol S adalah tombol
            -- gerak bawaan (gameProcessed selalu true) — pengecekannya
            -- ditaruh SEBELUM guard gameProcessed (tetap tidak jalan saat
            -- mengetik di kotak teks / chat).
            if input.KeyCode == Enum.KeyCode.S
                and not UserInputService:GetFocusedTextBox()
                and not State.Removed and State.MoonOn then
                setFeature("Moon", false)
                return
            end
            if gameProcessed then return end
            if State.Removed then return end
            -- jangan picu hotkey saat sedang mengetik di kotak teks
            -- (G/Q dst. tidak nyasar saat isi nama TP / stepper / kode sync)
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
                setFeature("Panah", not State.PanahOn)  -- Panah Deteksi (titik murni tombol GUI)
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
        -- [21b] MESIN ☁ SINKRON — mulai setelah semua siap
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
        print("[EMOT v" .. VERSI .. "] SIAP ✔ — G = GUI | K×2 = rejoin")
        print("[EMOT] MOVE&VISUAL | ANIMASI | SYSTEM • Q speed • J jump • C shift • LShift tengah • F moon (S=off) • V panah • R hide • T cahaya • X dinding • K×2 rejoin • ☁ sync config emote di tab SYSTEM")
        diagSet("EMOT V1.03 SIAP - GUI akan terbuka sendiri", Color3.fromRGB(16, 185, 129))
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
    print("[EMOT v1.03] ERROR SAAT LOAD — kirim teks ini ke dev:")
    print(teks)
    pcall(function() print(debug.traceback("", 2)) end)
    print("==================================================")
    pcall(function()
        diagSet("ERROR LOAD: " .. teks:sub(1, 260), Color3.fromRGB(239, 68, 68))
    end)
end)
if not __BALAP_LOAD_OK__ then
    warn("[EMOT v1.03] Script GAGAL load — banner MERAH di layar berisi errornya.")
end
