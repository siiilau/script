--========================================================
--  BALAP V1.0 — TEMA: SILAU NEON (ungu/biru LED) — LOCAL ONLY
--
--  Ringkasan fitur aktif:
--    • Tab TITIK lokal: simpan titik, titik kecil, Ctrl + klik kiri, teleport lokal.
--    • Tab: MOVEMENT & VISUAL, ANIMASI, EMOTE, TITIK, dan SYSTEM.
--
--  Keybind:
--    G = buka/tutup GUI • Q = Speed • J = JumpPower • C = Shiftlock Mobile
--    LShift/RShift = Shiftlock Tengah • F = Moonwalk • R = Hide
--    T = Cahaya Auto • X = Dinding Batas • V = Panah Deteksi • K = Rejoin
--
--  Shiftlock Mobile, Moonwalk & Shiftlock Tengah otomatis OFF saat mati/respawn.
--========================================================
print("[BALAP V1.0] load mulai...")
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

local VERSI = "V1.0"
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
        -- Speed cycle 3 state (17.10 → 17.25 → 35 → balik OFF)
        SPEED_OFF   = 17.10,
        SPEED_ON_1  = 17.25,
        SPEED_ON_2  = 35,
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
        -- Animasi kustom (v1.5, tab ANIMASI): port ANIMASI BUNDLE V6
        -- v1.6: tanpa file config — tiap load selalu default (master OFF).
        EMOTE_TUNGGAK    = 0.25,  -- jeda dtk setelah spawn sebelum pasang gaya
        -- Panah Deteksi (keybind V): deteksi pemain lain di
        -- depan/belakang badan (ikut arah badan, bukan kamera).
        PANAH_JARAK = 100,  -- jarak deteksi TIAP arah (stud): 100 depan +
                            -- 100 belakang = cakupan penuh 200 stud
        PANAH_SUDUT = 0.383, -- batas dot LookVector: 0.383 = cos(67.5°)
                            -- -> depan & belakang 135 derajat penuh,
                            -- samping kiri/kanan 45 derajat bebas (hijau)
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
        Oranye    = Color3.fromRGB(249, 115, 22),
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
    -- v1.4: seed acak — kode loker tidak kembar antar device/eksekusi
    -- (executor biasanya sudah seed sendiri, tapi tidak semua)
    pcall(function()
        math.randomseed(os.time() + math.floor((os.clock() % 1) * 100000))
    end)
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
    local emoteSetMaster, emotePilihPreset, emoteRefreshGrid, emoteBukaChooser

    -- Forward declare untuk part2 (UI builder) — di-expose via buildUI()
    local tabBtns, kontenTabs, setTab
    local kontenMove, scrollMove
    local kontenAnim, scrollAnim
    local kontenEmote, scrollEmote
    local kontenTitik, scrollTitik
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

    -- [5a] TITIK LOKAL --------------------------------------------------
    -- Semua titik kecil hanya terlihat di sisi pengguna sendiri.
    local TITIK_FILE = "BALAP_TITIK.json"
    local TITIK = { poin = {}, aktif = false, tampilTitik = true, folder = nil }
    local titikRenderUI = function() end
    local titikStatusUI = function() end

    local function titikFolder()
        if TITIK.folder and TITIK.folder.Parent then return TITIK.folder end
        local f = Instance.new("Folder")
        f.Name = "BALAP_TITIK_MARKERS"
        f.Parent = Workspace
        TITIK.folder = f
        return f
    end
    local function titikSimpan()
        local data = {}
        for _, p in ipairs(TITIK.poin) do
            data[#data + 1] = {name = p.name, x = p.pos.X, y = p.pos.Y, z = p.pos.Z, nx = p.normal.X, ny = p.normal.Y, nz = p.normal.Z}
        end
        getgenv().BALAP_TITIK_DATA = data
        if type(writefile) == "function" then
            pcall(function() writefile(TITIK_FILE, HttpService:JSONEncode(data)) end)
        end
    end
    local function titikMuat()
        local data
        if type(readfile) == "function" and type(isfile) == "function" then
            pcall(function()
                if isfile(TITIK_FILE) then data = HttpService:JSONDecode(readfile(TITIK_FILE)) end
            end)
        end
        if type(data) ~= "table" then data = rawget(getgenv(), "BALAP_TITIK_DATA") end
        if type(data) == "table" then
            for _, v in ipairs(data) do
                local x, y, z = tonumber(v.x), tonumber(v.y), tonumber(v.z)
                local nx, ny, nz = tonumber(v.nx) or 0, tonumber(v.ny) or 1, tonumber(v.nz) or 0
                if x and y and z then
                    TITIK.poin[#TITIK.poin + 1] = {
                        name = tostring(v.name or ("Titik " .. (#TITIK.poin + 1))),
                        pos = Vector3.new(x, y, z),
                        normal = Vector3.new(nx, ny, nz),
                    }
                end
            end
        end
    end
    local function titikBersihkanDot()
        if TITIK.folder then
            for _, obj in ipairs(TITIK.folder:GetChildren()) do obj:Destroy() end
        end
    end
    local function titikBuatDot(p, nomor)
        local folder = titikFolder()
        local dot = Instance.new("Part")
        dot.Name = "Titik_" .. tostring(nomor)
        dot.Shape = Enum.PartType.Ball
        dot.Anchored = true
        dot.CanCollide = false
        dot.CanTouch = false
        dot.CanQuery = false
        dot.CastShadow = false
        dot.Material = Enum.Material.Neon
        dot.Color = Warna.Ungu2
        dot.Size = Vector3.new(0.44, 0.44, 0.44)
        local normal = p.normal or Vector3.new(0, 1, 0)
        if normal.Magnitude < 0.01 then normal = Vector3.new(0, 1, 0) end
        dot.Position = p.pos + normal.Unit * 0.025
        dot.Parent = folder
    end
    local function titikRefreshDot()
        titikBersihkanDot()
        if not TITIK.tampilTitik then return end
        for i, p in ipairs(TITIK.poin) do titikBuatDot(p, i) end
    end
    local function titikTambah(name, pos, normal)
        if typeof(pos) ~= "Vector3" then return false end
        normal = (typeof(normal) == "Vector3" and normal.Magnitude > 0.01) and normal.Unit or Vector3.new(0, 1, 0)
        name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then name = "Titik " .. (#TITIK.poin + 1) end
        TITIK.poin[#TITIK.poin + 1] = {name = name, pos = pos, normal = normal}
        titikSimpan()
        titikRefreshDot()
        titikRenderUI()
        titikStatusUI("Titik ditambahkan: " .. name)
        return true
    end
    local function titikHapus(nomor)
        if TITIK.poin[nomor] then
            local nama = TITIK.poin[nomor].name
            table.remove(TITIK.poin, nomor)
            titikSimpan(); titikRefreshDot(); titikRenderUI()
            titikStatusUI("Titik dihapus: " .. nama)
        end
    end
    local function titikTeleport(nomor)
        local p = TITIK.poin[nomor]
        local char = getChar()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not p or not hrp or (hum and hum.Health <= 0) then
            titikStatusUI("Karakter belum siap")
            return
        end
        hrp.CFrame = CFrame.new(p.pos + Vector3.new(0, 3, 0))
        titikStatusUI("Pindah ke: " .. p.name)
    end
    local function titikRaycast(origin, direction)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local filter = {}
        local char = getChar()
        if char then filter[#filter + 1] = char end
        if TITIK.folder then filter[#filter + 1] = TITIK.folder end
        params.FilterDescendantsInstances = filter
        return Workspace:Raycast(origin, direction, params)
    end
    local function titikKlikDunia()
        local mouse = LocalPlayer:GetMouse()
        if not mouse or not mouse.UnitRay then return end
        local ray = mouse.UnitRay
        local hit = titikRaycast(ray.Origin, ray.Direction * 2000)
        if hit then titikTambah(nil, hit.Position, hit.Normal) end
    end
    local function titikPosisiKarakter()
        local char = getChar()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local hit = titikRaycast(hrp.Position + Vector3.new(0, 3, 0), Vector3.new(0, -30, 0))
        if hit then return hit.Position, hit.Normal end
        return hrp.Position, Vector3.new(0, 1, 0)
    end
    titikMuat()
    titikRefreshDot()

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
        Text = "⚡ BALAP " .. VERSI .. " ⚡",
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
    -- [7a2d] MODUL ANIMASI (v1.5, tab ANIMASI) — port ANIMASI BUNDLE V6
    --   • Slot state (IDLE/WALK/RUN/SWIM/CLIMB/JUMP/FALL) bekerja dengan
    --     MENGGANTI ID animasi di script "Animate" bawaan karakter, lalu
    --     Animate di-restart. Hasilnya DIREPLIKASI: pemain lain juga
    --     melihat gaya baru (track dibuat script core Roblox, lolos).
    --   • Otomatis deteksi R15 / R6 (struktur Animate kedua rig diikuti).
    --   • Baseline (animasi asli game) dicatat tiap spawn -> RESET/OFF
    --     mengembalikan persis seperti semula.
    --   • Preset = 18 pack resmi Roblox (semua Creator.Id = 1).
    --   • Config (preset/master) permanen: BALAP_EMOTE.json.
    --   • Keybind G milik script standalone DIHAPUS — ikut GUI utama (G).
    -- ======================================================================
local EMOTE_PRESET = {
    idle  = {
        { n = "Astronaut", i15 = 891621366, i6 = 1090133099 },
        { n = "Bubbly", i15 = 910004836, i6 = 1018553897 },
        { n = "Cartoony", i15 = 742637544, i6 = 837011741 },
        { n = "Elder", i15 = 845397899, i6 = 892268340 },
        { n = "Knight", i15 = 657595757, i6 = 734327140 },
        { n = "Levitation", i15 = 616006778, i6 = 619542203 },
        { n = "Mage", i15 = 707742142, i6 = 754637456 },
        { n = "Ninja", i15 = 656117400, i6 = 658832408 },
        { n = "Oldschool", i15 = 5319828216, i6 = 5319922112 },
        { n = "Pirate", i15 = 750781874, i6 = 837024662 },
        { n = "Robot", i15 = 616088211, i6 = 619521748 },
        { n = "Rthro", i15 = 2510197257 },
        { n = "Stylish", i15 = 616136790, i6 = 619511648 },
        { n = "Superhero", i15 = 616111295, i6 = 619528125 },
        { n = "Toy", i15 = 782841498, i6 = 973771666 },
        { n = "Vampire", i15 = 1083445855, i6 = 1113742618 },
        { n = "Werewolf", i15 = 1083195517, i6 = 1113752682 },
        { n = "Zombie", i15 = 616158929, i6 = 619535834 },
    },
    walk  = {
        { n = "Astronaut", i15 = 891636393, i6 = 1090131576 },
        { n = "Bubbly", i15 = 910034870, i6 = 1018549681 },
        { n = "Cartoony", i15 = 742640026, i6 = 837010234 },
        { n = "Elder", i15 = 845403856, i6 = 892267099 },
        { n = "Knight", i15 = 657552124, i6 = 734326330 },
        { n = "Levitation", i15 = 616013216, i6 = 619544080 },
        { n = "Mage", i15 = 707897309, i6 = 754636298 },
        { n = "Ninja", i15 = 656121766, i6 = 658831143 },
        { n = "Oldschool", i15 = 5319847204, i6 = 5319909330 },
        { n = "Pirate", i15 = 750785693, i6 = 837023892 },
        { n = "Robot", i15 = 616095330, i6 = 619522849 },
        { n = "Rthro", i15 = 2510202577 },
        { n = "Stylish", i15 = 616146177, i6 = 619512767 },
        { n = "Superhero", i15 = 616122287, i6 = 619529601 },
        { n = "Toy", i15 = 782843345, i6 = 973767371 },
        { n = "Vampire", i15 = 1083473930, i6 = 1113741192 },
        { n = "Werewolf", i15 = 1083178339, i6 = 1113751657 },
        { n = "Zombie", i15 = 616168032, i6 = 619537468 },
    },
    run   = {
        { n = "Astronaut", i15 = 891636393, i6 = 1090130630 },
        { n = "Bubbly", i15 = 910025107, i6 = 1018548665 },
        { n = "Cartoony", i15 = 742638842, i6 = 837009922 },
        { n = "Elder", i15 = 845386501, i6 = 892265784 },
        { n = "Knight", i15 = 657564596, i6 = 734325948 },
        { n = "Levitation", i15 = 616010382, i6 = 619543231 },
        { n = "Mage", i15 = 707861613, i6 = 754635032 },
        { n = "Ninja", i15 = 656118852, i6 = 658830056 },
        { n = "Oldschool", i15 = 5319844329, i6 = 5319900634 },
        { n = "Pirate", i15 = 750783738, i6 = 837023444 },
        { n = "Robot", i15 = 616091570, i6 = 619522386 },
        { n = "Rthro", i15 = 2510198475 },
        { n = "Stylish", i15 = 616140816, i6 = 619512153 },
        { n = "Superhero", i15 = 616117076, i6 = 619528716 },
        { n = "Toy", i15 = 782842708, i6 = 973766674 },
        { n = "Vampire", i15 = 1083462077, i6 = 1113740510 },
        { n = "Werewolf", i15 = 1083216690, i6 = 1113750642 },
        { n = "Zombie", i15 = 616163682, i6 = 619536621 },
    },
    jump  = {
        { n = "Astronaut", i15 = 891627522, i6 = 1090132507 },
        { n = "Bubbly", i15 = 910016857, i6 = 1018553240 },
        { n = "Cartoony", i15 = 742637942, i6 = 837011171 },
        { n = "Elder", i15 = 845398858, i6 = 892267917 },
        { n = "Knight", i15 = 658409194, i6 = 734326930 },
        { n = "Levitation", i15 = 616008936, i6 = 619542888 },
        { n = "Mage", i15 = 707853694, i6 = 754637084 },
        { n = "Ninja", i15 = 656117878, i6 = 658832070 },
        { n = "Oldschool", i15 = 5319841935, i6 = 5319917561 },
        { n = "Pirate", i15 = 750782230, i6 = 837024350 },
        { n = "Robot", i15 = 616090535, i6 = 619522088 },
        { n = "Rthro", i15 = 2510197830 },
        { n = "Stylish", i15 = 616139451, i6 = 619511974 },
        { n = "Superhero", i15 = 616115533, i6 = 619528412 },
        { n = "Toy", i15 = 782847020, i6 = 973770652 },
        { n = "Vampire", i15 = 1083455352, i6 = 1113742359 },
        { n = "Werewolf", i15 = 1083218792, i6 = 1113752285 },
        { n = "Zombie", i15 = 616161997, i6 = 619536283 },
    },
    fall  = {
        { n = "Astronaut", i15 = 891617961, i6 = 1090132063 },
        { n = "Bubbly", i15 = 910001910, i6 = 1018552770 },
        { n = "Cartoony", i15 = 742637151, i6 = 837010685 },
        { n = "Elder", i15 = 845396048, i6 = 892267521 },
        { n = "Knight", i15 = 657600338, i6 = 734326679 },
        { n = "Levitation", i15 = 616005863, i6 = 619541867 },
        { n = "Mage", i15 = 707829716, i6 = 754636589 },
        { n = "Ninja", i15 = 656115606, i6 = 658831500 },
        { n = "Oldschool", i15 = 5319839762, i6 = 5319914476 },
        { n = "Pirate", i15 = 750780242, i6 = 837024147 },
        { n = "Robot", i15 = 616087089, i6 = 619521521 },
        { n = "Rthro", i15 = 2510195892 },
        { n = "Stylish", i15 = 616134815, i6 = 619511417 },
        { n = "Superhero", i15 = 616108001, i6 = 619527817 },
        { n = "Toy", i15 = 782846423, i6 = 973768058 },
        { n = "Vampire", i15 = 1083443587, i6 = 1113742092 },
        { n = "Werewolf", i15 = 1083189019, i6 = 1113751889 },
        { n = "Zombie", i15 = 616157476, i6 = 619535616 },
    },
    climb = {
        { n = "Astronaut", i15 = 891609353, i6 = 1090134016 },
        { n = "Bubbly", i15 = 909997997, i6 = 1018554668 },
        { n = "Cartoony", i15 = 742636889, i6 = 837013990 },
        { n = "Elder", i15 = 845392038, i6 = 892269341 },
        { n = "Knight", i15 = 658360781, i6 = 734329002 },
        { n = "Levitation", i15 = 616003713, i6 = 619541458 },
        { n = "Mage", i15 = 707826056, i6 = 754639239 },
        { n = "Ninja", i15 = 656114359, i6 = 658833139 },
        { n = "Oldschool", i15 = 5319816685, i6 = 5319931619 },
        { n = "Pirate", i15 = 750779899, i6 = 837025325 },
        { n = "Robot", i15 = 616086039, i6 = 619521311 },
        { n = "Rthro", i15 = 2510192778 },
        { n = "Stylish", i15 = 616133594, i6 = 619509955 },
        { n = "Superhero", i15 = 616104706, i6 = 619527470 },
        { n = "Toy", i15 = 782843869, i6 = 973773170 },
        { n = "Vampire", i15 = 1083439238, i6 = 1113743239 },
        { n = "Werewolf", i15 = 1083182000, i6 = 1113754738 },
        { n = "Zombie", i15 = 616156119, i6 = 619535091 },
    },
    swim  = {
        { n = "Astronaut", i15 = 891639666, i6 = 1090133583, i15b = 891663592 },
        { n = "Bubbly", i15 = 910028158, i6 = 1018554245, i15b = 910030921 },
        { n = "Cartoony", i15 = 742639220, i6 = 837012509, i15b = 742639812 },
        { n = "Elder", i15 = 845401742, i6 = 892268710, i15b = 845403127 },
        { n = "Knight", i15 = 657560551, i6 = 734327363, i15b = 657557095 },
        { n = "Levitation", i15 = 616011509, i6 = 619543721, i15b = 616012453 },
        { n = "Mage", i15 = 707876443, i6 = 754638471, i15b = 707894699 },
        { n = "Ninja", i15 = 656119721, i6 = 658832807, i15b = 656121397 },
        { n = "Oldschool", i15 = 5319850266, i6 = 5319927054, i15b = 5319852613 },
        { n = "Pirate", i15 = 750784579, i6 = 837025054, i15b = 750785176 },
        { n = "Robot", i15 = 616092998, i6 = 619522642, i15b = 616094091 },
        { n = "Rthro", i15 = 2510199791, i15b = 2510201162 },
        { n = "Stylish", i15 = 616143378, i6 = 619512450, i15b = 616144772 },
        { n = "Superhero", i15 = 616119360, i6 = 619529095, i15b = 616120861 },
        { n = "Toy", i15 = 782844582, i6 = 973772659, i15b = 782845186 },
        { n = "Vampire", i15 = 1083464683, i6 = 1113742944, i15b = 1083467779 },
        { n = "Werewolf", i15 = 1083222527, i6 = 1113752975, i15b = 1083225406 },
        { n = "Zombie", i15 = 616165109, i6 = 619537096, i15b = 616166655 },
    },
}


    -- BUNDLE + EMOTE CATALOG dari script kedua (data saja; tanpa loadstring,
    -- teleport, server-hop, trolling, atau sinkronisasi pemain lain).
local BUNDLE_ANIMATIONS = {
 Emotes = {Weight=9, Weight2=1},
 Stylish = {Idle = 616136790, Idle2=616138447, Idle3=886888594, Walk=616146177,Run=616140816,Jump=616139451,Climb=616133594,Fall=616134815, Swim=616143378, SwimIdle=616144772, Weight=9, Weight2=1},
 Zombie = {Idle = 616158929, Idle2=616160636, Idle3=885545458, Walk=616168032,Run=616163682,Jump=616161997,Climb=616156119,Fall=616157476, Swim=616165109, SwimIdle=616166655, Weight=9, Weight2=1},
 Robot = {Idle = 616088211, Idle2=616089559, Idle3=885531463, Walk=616095330,Run=616091570,Jump=616090535,Climb=616086039,Fall=616087089, Swim=616092998, SwimIdle=616094091, Weight=9, Weight2=1},
 Toy = {Idle = 782841498, Idle2=782845736, Idle3=980952228, Walk=782843345,Run=782842708,Jump=782847020,Climb=782843869,Fall=782846423, Swim=782844582, SwimIdle=782845186, Weight=9, Weight2=1},
 Cartoony = {Idle = 742637544, Idle2=742638445, Idle3=885477856, Walk=742640026,Run=742638842,Jump=742637942,Climb=742636889,Fall=742637151, Swim=742639220, SwimIdle=742639812, Weight=9, Weight2=1},
 Superhero = {Idle = 616111295, Idle2=616113536, Idle3=885535855, Walk=616122287,Run=616117076,Jump=616115533,Climb=616104706,Fall=616108001, Swim=616119360, SwimIdle=616120861, Weight=9, Weight2=1},
 Mage = {Idle = 707742142, Idle2=707855907, Idle3=885508740, Walk=707897309,Run=707861613,Jump=707853694,Climb=707826056,Fall=707829716, Swim=707876443, SwimIdle=707894699, Weight=9, Weight2=1},
 Levitation = {Idle = 616006778, Idle2=616008087, Idle3=886862142, Walk=616013216,Run=616010382,Jump=616008936,Climb=616003713,Fall=616005863, Swim=616011509, SwimIdle=616012453, Weight=9, Weight2=1},
 Vampire = {Idle = 1083445855, Idle2=1083450166, Idle3=1088037547, Walk=1083473930,Run=1083462077,Jump=1083455352,Climb=1083439238,Fall=1083443587, Swim=1083464683, SwimIdle=1083467779, Weight=9, Weight2=1},
 Elder = {Idle = 845397899, Idle2=845400520, Idle3=901160519, Walk=845403856,Run=845386501,Jump=845398858,Climb=845392038,Fall=845396048, Swim=845401742, SwimIdle=845403127, Weight=9, Weight2=1},
 Werewolf = {Idle = 1083195517, Idle2=1083214717, Idle3=1099492820, Walk=1083178339,Run=1083216690,Jump=1083218792,Climb=1083182000,Fall=1083189019, Swim=1083222527, SwimIdle=1083225406, Weight=9, Weight2=1},
 Knight = {Idle = 657595757, Idle2=657568135, Idle3=885499184, Walk=657552124,Run=657564596,Jump=658409194,Climb=658360781,Fall=657600338, Swim=657560551, SwimIdle=657557095, Weight=9, Weight2=1},
 Bold = {Idle = 16738333868, Idle2=16738334710, Idle3=16738335517, Walk=16738340646,Run=16738337225,Jump=16738336650,Climb=16738332169,Fall=16738333171, Swim=16738339158, SwimIdle=16738339817, Weight=9, Weight2=1},
 Astronaut = {Idle = 891621366, Idle2=891633237, Idle3=1047759695, Walk=891667138,Run=891636393,Jump=891627522,Climb=891609353,Fall=891617961, Swim=891639666, SwimIdle=891663592, Weight=9, Weight2=1},
 Bubbly = {Idle = 910004836, Idle2=910009958, Idle3=1018536639, Walk=910034870,Run=910025107,Jump=910016857,Climb=909997997,Fall=910001910, Swim=910028158, SwimIdle=910030921, Weight=9, Weight2=1},
 Pirate = {Idle = 750781874, Idle2=750782770, Idle3=885515365, Walk=750785693,Run=750783738,Jump=750782230,Climb=750779899,Fall=750780242, Swim=750784579, SwimIdle=750785176, Weight=9, Weight2=1},
 Rthro = {Idle = 2510196951, Idle2=2510197257, Idle3=3711062489, Walk=2510202577,Run=2510198475,Jump=2510197830,Climb=2510192778,Fall=2510195892, Swim=2510199791, SwimIdle=2510201162, Weight=9, Weight2=1},
 Ninja = {Idle=656117400, Idle2=656118341, Idle3=886742569, Walk=656121766, Run=656118852, Jump=656117878, Climb=656114359,Fall=656115606, Swim=656119721, SwimIdle=656121397, Weight=9, Weight2=1},
 Oldschool = {Idle=5319828216, Idle2=5319831086, Idle3=5392107832, Walk=5319847204, Run=5319844329, Jump=5319841935, Climb=5319816685, Fall=5319839762, Swim=5319850266, SwimIdle=5319852613, Weight=9, Weight2=1},
 Realistic = {Idle=17172918855, Idle2=17173014241, Idle3=17173014241, Walk=11600249883, Run=11600211410, Jump=11600210487, Climb=11600205519, Fall=11600206437, Swim=11600212676, SwimIdle=11600213505, Weight=9, Weight2=1},
 ['No Boundaries'] = {Idle=18747067405, Idle2=18747063918, Idle3=18747063918, Walk=18747074203, Run=18747070484, Jump=18747069148, Climb=18747060903,Fall=18747062535, Swim=18747073181, SwimIdle=18747071682, Weight=9, Weight2=1},
 ['NFL Animation'] = {Idle=92080889861410, Idle2=74451233229259, Idle3=80884010501210, Walk=110358958299415, Run=117333533048078, Jump=119846112151352, Climb=134630013742019,Fall=129773241321032, Swim=132697394189921, SwimIdle=79090109939093, Weight=9, Weight2=1},
 ['Adidas Aura'] = {Idle=110211186840347,Idle2=114191137265065,Idle3=99129837931148,Walk=83842218823011,Run=118320322718866,Jump=109996626521204,Climb=97824616490448,Fall=95603166884636,Swim=134530128383903,SwimIdle=94922130551805,Weight=9,Weight2=1},
 ['Adidas Sports'] = {Idle=18537376492, Idle2=18537371272, Idle3=18537374150, Walk=18537392113, Run=18537384940, Jump=18537380791, Climb=18537363391,Fall=18537367238, Swim=18537389531, SwimIdle=18537387180, Weight=9, Weight2=1},
 ['Adidas Community '] = {Idle=122257458498464, Idle2=102357151005774, Idle3=89262795687364, Walk=122150855457006, Run=82598234841035, Jump=75290611992385, Climb=88763136693023,Fall=98600215928904, Swim=133308483266208, SwimIdle=109346520324160, Weight=9, Weight2=1},
 ['Wickled Popular'] = {Idle=118832222982049, Idle2=76049494037641, Idle3=138255200176080, Walk=92072849924640, Run=72301599441680, Jump=104325245285198, Climb=131326830509784, Fall=121152442762481, Swim=99384245425157, SwimIdle=113199415118199, Weight=9, Weight2=1},
 ['Catwalk Glam'] = {Idle=133806214992291, Idle2=94970088341563, Idle3=87105332133518, Walk=109168724482748, Run=81024476153754, Jump=116936326516985, Climb=119377220967554,Fall=92294537340807, Swim=134591743181628, SwimIdle=98854111361360, Weight=9, Weight2=1},
 Princess = {Idle=941003647, Idle2=941013098, Idle3=1159195712, Walk=941028902, Run=941015281, Jump=0941008832, Climb=940996062, Fall=941000007, Swim=941018893, SwimIdle=941025398, Weight=9, Weight2=1},
 Confident = {Idle=1069977950, Idle2=1069987858, Idle3=1116160740, Walk=1070017263, Run=1070001516, Jump=1069984524, Climb=1069946257, Fall=1069973677, Swim=1070009914, SwimIdle=1070012133, Weight=9, Weight2=1},
 Popstar = {Idle=1212900985, Idle2=1150842221, Idle3=1239733474, Walk=1212980338, Run=1212980348, Jump=1212954642, Climb=1213044953, Fall=1212900995, Swim=1212852603, SwimIdle=1070012133, Weight=9, Weight2=1},
 Patrol = {Idle=1149612882, Idle2=1150842221, Idle3=1159573567, Walk=1151231493, Run=1150967949, Jump=1150944216, Climb=1148811837, Fall=1148863382, Swim=1151204998, SwimIdle=1151221899, Weight=9, Weight2=1},
 Sneaky = {Idle=1132473842, Idle2=1132477671, Idle3="None", Walk=1132510133, Run=1132494274, Jump=1132489853, Climb=1132461372, Fall=1132469004, Swim=1132500520, SwimIdle=1132506407, Weight=9, Weight2=1},
 Cowboy = {Idle=1014390418, Idle2=1014398616, Idle3=1159487651, Walk=1014421541, Run=1014401683, Jump=1014394726, Climb=1014380606, Fall=1014384571, Swim=1014406523, SwimIdle=1014411816, Weight=9, Weight2=1},
 Ghost = {Idle=616006778, Idle2=616008087, Idle3=616008087, Walk=616013216, Run=616013216, Jump=616008936, Climb=0, Fall=616005863, Swim=616011509, SwimIdle=616012453, Weight=9, Weight2=1},
 ['Ghost 2'] = {Idle=1151221899, Idle2=1151221899, Idle3="None", Walk=1151221899, Run=1151221899, Jump=1151221899, Climb=0, Fall=1151221899, Swim=16738339158, SwimIdle=1151221899, Weight=9, Weight2=1},
 ['Mr. Toilet'] = {Idle=4417977954, Idle2=4417978624, Idle3=4441285342, Walk=2510202577, Run=4417979645, Jump=2510197830, Climb=2510192778, Fall=2510195892, Swim=2510199791, SwimIdle=2510201162, Weight=9, Weight2=1},
 Udzal = {Idle=3303162274, Idle2=3303162549, Idle3=3710161342, Walk=3303162967, Run=3236836670, Jump=2510197830, Climb=2510192778, Fall=2510195892, Swim=2510199791, SwimIdle=2510201162, Weight=9, Weight2=1},
 ['Oinan Thickhoof'] = {Idle = 657595757, Idle2=657568135, Idle3=885499184, Walk=2510202577, Run=3236836670, Jump=2510197830, Climb=2510192778, Fall=2510195892, Swim=2510199791, SwimIdle=2510201162, Weight=9, Weight2=1},
 Borock = {Idle = 3293641938, Idle2=3293642554, Idle3=3710131919, Walk=2510202577, Run=3236836670, Jump=2510197830, Climb=2510192778, Fall=2510195892, Swim=2510199791, SwimIdle=2510201162, Weight=9, Weight2=1},
 ['Blocky Mech'] = {Idle=4417977954, Idle2=4417978624, Idle3=4441285342, Walk=2510202577, Run=4417979645, Jump=2510197830, Climb=2510192778, Fall=2510195892, Swim=2510199791, SwimIdle=2510201162, Weight=9, Weight2=1},
 ['Stylized Female'] = {Idle=4708191566, Idle2=4708192150, Idle3=121221, Walk=4708193840, Run=4708192705, Jump=4708188025, Climb=4708184253, Fall=4708186162, Swim=4708189360, SwimIdle=4708190607, Weight=9, Weight2=1},
 R15 = {Idle=4211217646, Idle2=4211218409, Idle3="None", Walk=4211223236, Run=4211220381, Jump=4211219390, Climb=4211214992, Fall=4211216152, Swim=4211221314, SwimIdle=4374694239, Weight=9, Weight2=1},
 Mocap = {Idle=913367814, Idle2=913373430, Idle3="None", Walk=913402848, Run=913376220, Jump=913370268, Climb=913362637, Fall=913365531, Swim=913384386, SwimIdle=913389285, Weight=9, Weight2=1},
 ['Wicked "Dancing Through Life"'] = {Idle=92849173543269,Idle2=132238900951109,Idle3=87867222929430,Walk=73718308412641,Run=135515454877967,Jump=78508480717326,Climb=129447497744818,Fall=78147885297412,Swim=110657013921774,SwimIdle=129183123083281,Weight=9,Weight2=1},
 Unboxed = {Idle=98281136301627,Idle2=138183121662404,Idle3=133117300343405,Walk=90478085024465,Run=134824450619865,Jump=121454505477205,Climb=121145883950231,Fall=94788218468396,Swim=105962919001086,SwimIdle=129126268464847,Weight=9,Weight2=1}
}



local EMOTE_CATALOG = {
	['Fashion'] = 3333331310; 
	["Baby Dance"] = 4265725525; 
	["Cha-Cha"] = 6862001787; 
	['Monkey'] = 3333499508; 
	['Shuffle'] = 4349242221; 
	["Top Rock"] = 3361276673; 
	["Around Town"] = 3303391864; 
	["Fancy Feet"] = 3333432454; 
	["Hype Dance"] = 3695333486; 
	['Bodybuilder'] = 3333387824; 
	['Idol'] = 4101966434;
	['Curtsy'] = 4555816777;
	['Happy'] = 4841405708;
	["Quiet Waves"] = 7465981288;
	['Sleep'] = 4686925579;
	["Floss Dance"] = 5917459365;
	['Shy'] = 3337978742;
	['Godlike'] = 3337994105;
	["Hero Landing"] = 5104344710;
	["High Wave"] = 5915690960;
	['Cower'] = 4940563117;
	['Bored'] = 5230599789;
	["Show Dem Wrists -KSI"] = 7198989668;
	['Celebrate'] = 3338097973;
	['Dash'] = 582855105;
	['Beckon'] = 5230598276;
	['Haha'] = 3337966527;
	["Lasso Turn - Tai Verdes"] = 7942896991;
	["Line Dance"] = 4049037604;
	['Shrug'] = 3334392772;
	['Point2'] = 3344585679;
	['Stadium'] = 3338055167;
	['Confused'] = 4940561610;
	['Side to Side'] = 3333136415;
	['Old Town Road Dance - Lil Nas X"'] = 5937560570;
	['Hello'] = 3344650532;
	['Dolphin Dance'] = 5918726674;
	['Samba'] = 6869766175;
	['Break Dance'] = 5915648917;
	["Hips Poppin' - Zara Larsson"] = 6797888062;
	['Wake Up Call - KSI'] = 7199000883;
	['Greatest'] = 3338042785;
	['On The Outside - Twenty One'] = 7422779536;
	['Boxing Punch - KSI'] = 7202863182;
	['Sad'] = 4841407203;
	['Flowing Breeze'] = 7465946930;
	['Twirl'] = 3334968680;
	['Jumping Wave'] = 4940564896;
	['HOLIDAY Dance - Lil Nas X (LNX)'] = 5937558680;
	['Take Me Under - Zara Larsson'] = 6797890377;
	['Shuffle'] = 4349242221;
	['Dizzy'] = 3361426436;
	["Dancing' Shoes - Twenty One"] = 7404878500;
	['Fashionable'] = 3333331310;
	['Fast Hands'] = 4265701731;
	['Tree'] = 4049551434;
	['Agree'] = 4841397952;
	['Power Blast'] = 4841403964;
	['Swoosh'] = 3361481910;
	['Jumping Cheer'] = 5895324424;
	['Disagree'] = 4841401869;
	['Rodeo Dance - Lil Nas X (LNX)'] = 5918728267;
	["It Ain't My Fault - Zara Larsson"] = 6797891807;
	['Rock On'] = 5915714366;
	['Block Partier'] = 6862022283;
	['Dorky Dance'] = 4212455378;
	['Zombie'] = 4210116953;
	['AOK - Tai Verdes'] = 7942885103;
	['T'] = 3338010159;
	['Cobra Arms - Tai   Verdes'] = 7942890105;
	['Panini Dance - Lil Nas X (LNX)'] = 5915713518;
	['Fishing'] = 3334832150;
	['Robot'] = 3338025566;
	['Around Town'] = 3303391864;
	['Saturday Dance - Twenty One'] = 7422807549;
	['Top Rock'] = 3361276673;
	['Keeping Time'] = 4555808220;
	['Air Dance'] = 4555782893;
	['Fancy Feet'] = 3333432454;
	['Rock Guitar - Royal Blood'] = 6532134724;
	["Borock's Rage"] = 3236842542;
	["Ud'zal's Summoning"] = 3303161675;
	['Y'] = 4349285876;
	['Swan Dance'] = 7465997989;
	['Louder'] = 3338083565;
	['Up and Down - Twenty One'] = 7422797678;
	['Swish'] = 3361481910;
	['Drummer Moves - Twenty One'] = 7422527690;
	['Sneaky'] = 3334424322;
	['Heisman Pose'] = 3695263073;
	['Jacks'] = 3338066331;
	['Cha-Cha 2'] = 3695322025;
	['BURBERRY LOLA ATTITUDE - NIMBUS'] = 10147821284;
	['BURBERRY LOLA  ATTITUDE - GEM'] = 10147815602;
	['BURBERRY LOLA ATTITUDE - HYDRO'] = 10147823318;
	['BURBERRY LOLA ATTITUDE - BLOOM'] = 10147817997;
	['Superhero Reveal'] = 3695373233;
	['Air Guitar'] = 3695300085;
	['Dismissive Wave'] = 3333272779;
	['Country Line  Dance - Lil Nas X'] = 5915712534;
	['Salute'] = 3333474484;
	['Applaud'] = 5915693819;
	['Get Out'] = 3333272779;
	['Hwaiting (화이팅)'] = 9527885267;
	['Annyeong (안녕)'] = 9527883498;
	['Bunny Hop'] = 4641985101;
	['Sandwich Dance'] = 4406555273;
	['Hyperfast  5G Dance Move'] = 9408617181;
	['Victory - 24kGoldn'] = 9178377686;
	['Tantrum'] = 5104341999;
	['Rock Star - Royal Blood'] = 10714400171;
	['Drum Solo - Royal Blood'] = 6532839007;
	['Drum Master - Royal Blood'] = 6531483720;
	['High Hands'] = 9710985298;
	['Tilt'] = 3334538554;
	['Gashina - SUNMI'] = 9527886709;
	['Chicken Dance'] = 4841399916;
	["You can't sit with us - Sunmi"] = 9983520970;
	["Frosty Flair - Tommy Hilfiger"] = 10214311282;
	["Floor Rock Freeze - Tommy Hilfiger"] = 10214314957;
	['Boom Boom Clap - George Ezra'] = 10370346995;
	['Cartwheel - George Ezra'] = 10370351535;
	['Chill Vibes - George Ezra'] = 10370353969; 
	['Sidekicks - George Ezra'] = 10370362157;
	['The Conductor - George Ezra'] = 10370359115;
	['Super Charge'] = 10478338114;
	['Swag Walk'] = 10478341260;
	['Mean Mug - Tommy Hilfiger'] = 10214317325;
	['V Pose - Tommy Hilfiger'] = 10214319518;
	['Uprise - Tommy Hilfiger'] = 10275008655;
	['2 Baddies Dance Move - NCT 127'] = 12259828678; 
	['Kick It Dance Move - NCT 127'] = 12259826609;
	['Sticker Dance Move - NCT 127'] = 12259825026;
	['Elton John - Rock Out'] = 11753474067;
	['Elton John - Heart Skip'] = 11309255148;
	['Elton John - Still Standing'] = 11444443576;
	['Elton John - Elevate'] = 11394033602;
	['Elton John - Cat Man'] = 11444441914;
	['Elton John - Piano Jump'] = 11453082181;
	['Alo Yoga Pose - Triangle'] = 12507084541;
	['Alo Yoga Pose - Warrior II'] = 12507083048;
	['Alo Yoga Pose - Lotus Position'] = 12507085924;
	['Alo Yoga Pose - Warrior II'] = 12507083048;
	['Alo Yoga Pose - Triangle'] = 12507084541;
	['TWICE-Moonlight-Sunrise'] = 12714233242;
	['TWICE-Set-Me-Free-Dance-1'] = 12714228341;
	['TWICE-Set-Me-Free-Dance-2'] = 12714231087;
	['Ay-Yo-Dance-Move-NCT-127'] = 12804157977;
	['TWICE-The-Feels'] = 12874447851;
	['Zombie'] = 10714089137;
	['Rise-Above-The-Chainsmokers'] = 12992262118;
	['TWICE-What-Is-Love'] = 13327655243;
	['Man-City-Bicycle-Kick'] = 13421057998;
	['TWICE-Fancy'] = 13520524517;
	['TWICE Pop by Nayeon'] = 13768941455;
	['Tommy - Archer'] = 13823324057;
	['TWICE-Pop-by-Nayeon'] = 13768941455;
	['Man City Backflip'] = 13694100677;
	['Man-City-Scorpion-Kick'] = 13694096724;
	['Arm Twist'] = 10713968716;
	['Tommy - Archer'] = 13823324057;
	['YUNGBLUD – HIGH KICK'] = 14022936101;
	['TWICE Like Ooh-Ahh'] = 14123781004;
	['Baby Queen - Air Guitar & Knee Slide'] = 14352335202;
	['Baby Queen - Dramatic Bow'] = 14352337694;
	['Baby Queen - Face Frame'] = 14352340648;
	['Baby Queen - Bouncy Twirl'] = 14352343065;
	['Baby Queen - Strut'] = 14352362059;
	['BLACKPINK Pink Venom - Get em Get em Get em'] = 14548619594;
	['BLACKPINK Pink Venom - I Bring the Pain Like…'] = 14548620495;
	['BLACKPINK Pink Venom - Straight to Ya Dome'] = 14548621256;
	['TWICE LIKEY'] = 14899979575;
	['TWICE Feel Special'] = 14899980745;
	['BLACKPINK Shut Down - Part 1'] = 14901306096;
	['BLACKPINK Shut Down - Part 2'] = 14901308987;
	["Bone Chillin' Bop"] = 15122972413;
	['Paris Hilton - Sliving For The Groove'] = 15392759696;
	['Paris Hilton - Iconic IT-Grrrl'] = 15392756794;
	['Paris Hilton - Checking My Angles'] = 15392752812;
	['BLACKPINK JISOO Flower'] = 15439354020;
	['BLACKPINK JENNIE You and Me'] = 15439356296;
	['Rock n Roll'] = 15505458452;
	['Air Guitar'] = 15505454268;
	['Victory Dance'] = 15505456446;
	['Flex Walk'] = 15505459811;
	['Olivia Rodrigo Head Bop'] = 15517864808;
	['Olivia Rodrigo good 4 u'] = 15517862739;
	['Olivia Rodrigo Fall Back to Float'] = 15549124879;
	["Nicki Minaj That's That Super Bass"] = 15571446961;
	['Nicki Minaj Boom Boom Boom'] = 15571448688;
	['Nicki Minaj Anaconda'] = 15571450952;
	['Nicki Minaj Starships'] = 15571453761;
	['Yungblud Happier Jump'] = 15609995579;
	['Festive Dance'] = 15679621440;
	['BLACKPINK LISA Money'] = 15679623052;
	['BLACKPINK ROSÉ On The Ground'] = 15679624464;
	['Imagine Dragons - “Bones” Dance'] = 15689279687;
	['GloRilla - "Tomorrow" Dance'] = 15689278184;
	['d4vd - Backflip'] = 15693621070;
	['ericdoa - dance'] = 15698402762;
	['Cuco - Levitate'] = 15698404340;
	['Mean Girls Dance Break'] = 15963314052;
	['Paris Hilton Sanasa'] = 16126469463;
	['BLACKPINK Ice Cream'] = 16181797368;
	['BLACKPINK Kill This Love'] = 16181798319;
	['TWICE I GOT YOU part 1'] = 16215030041;
	['TWICE I GOT YOU part 2'] = 16256203246;
	["Dave's Spin Move - Glass Animals"] = 16272432203;
	['Sol de Janeiro - Samba'] = 16270690701;
	['Beauty Touchdown'] = 16302968986;
	['Skadoosh Emote - Kung Fu Panda 4'] = 16371217304;
	['Jawny - Stomp'] = 16392075853;
	['Mae Stephens - Piano Hands'] = 16553163212;
	['BLACKPINK Boombayah Emote'] = 16553164850;
	['BLACKPINK DDU-DU DDU-DU'] = 16553170471;
	['HIPMOTION - Amaarae'] = 16572740012;
	['Mae Stephens – Arm Wave'] = 16584481352;
	['Wanna play?'] = 16646423316;
	['BLACKPINK-How-You-Like-That'] = 16874470507;
	['BLACKPINK - Lovesick Girls'] = 16874472321;
	['Mini Kong'] = 17000021306;
	["HUGO Let's Drive!"] = 17360699557;
	['Wisp - air guitar'] = 17370775305;
	['Vans Ollie'] = 18305395285;
	['Sturdy Dance - Ice Spice'] = 17746180844;
	['Shuffle'] = 17748314784;
	['Rolling Stones Guitar Strum'] = 18148804340;
	['Rock Out - Bebe Rexha'] = 18225053113;
	['SpongeBob Imaginaaation 🌈'] = 18443237526;
	['SpongeBob Dance'] = 18443245017;
	['Shrek Roar'] = 18524313628;
	['Team USA Breaking Emote'] = 18526288497;
	['NBA WNBA Fadeaway'] = 18526362841;
	['Vroom Vroom'] = 18526397037;
	['TMNT Dance'] = 18665811005;
	['Olympic Dismount'] = 18665825805;
    ["BLACKPINK As If It's Your Last"] = 18855536648;
    ["BLACKPINK Don't know what to do"] = 18855531354;
    ['TWICE ABCD by Nayeon'] = 18933706381;
    ['Charli xcx - Apple Dance'] = 18946844622;
	['The Zabb'] = 129470135909814;
	['Fashion Klossette - Runway my way'] = 80995190624232;
	['ALTÉGO - Couldn’t Care Less'] = 107875941017127;
	['Fashion Roadkill'] = 136831243854748;
	['Skibidi Toilet - Titan Speakerman Laser Spin'] = 134283166482394;
	['Chappell Roan HOT TO GO!'] = 85267023718407;
	['Secret Handshake Dance'] = 71243990877913;
	['KATSEYE - Touch'] = 135876612109535;
	['Fashion Spin'] = 131669256082047;
	['TWICE Strategy'] = 97311229290836;
	['NBA Monster Dunk'] = 132748833449150;
	['DearALICE - Ariana'] = 134318425949290;
	['The Weeknd Starboy Strut'] = 71105746210464;
	['The Weeknd Opening Night'] = 133110725387025;
	['Robot M3GAN'] = 125803725853577;  
	["M3GAN's Dance"] = 99649534578309;
	['Rasputin – Boney M.'] = 114872820353992;
	['Thanos Happy Jump - Squid Game'] = 97611664803614;
	['Young-hee Head Spin - Squid Game'] = 112011282168475;
	['TWICE Takedown'] = 140182843839424;
	['Stray Kids Walkin On Water'] = 125064469983655;
	['TWICE TAKEDOWN DANCE 2'] = 127104635954695;
}




    local EMOTE_FAV_FILE = "balap_emote_favorit.json"
    local EMOTE_SESSION = { favorites = {}, loop = false, track = nil, name = nil }
    local emoteMotionConn
    local emoteLoopUIRefresh = function() end
    local function emoteFavSave()
        getgenv().BALAP_EMOTE_FAVORITES = EMOTE_SESSION.favorites
        if type(writefile) == "function" then
            pcall(function()
                writefile(EMOTE_FAV_FILE, HttpService:JSONEncode(EMOTE_SESSION.favorites))
            end)
        end
    end
    local function emoteFavLoad()
        local data
        if type(readfile) == "function" and type(isfile) == "function" then
            pcall(function()
                if isfile(EMOTE_FAV_FILE) then
                    data = HttpService:JSONDecode(readfile(EMOTE_FAV_FILE))
                end
            end)
        end
        if type(data) ~= "table" then
            data = rawget(getgenv(), "BALAP_EMOTE_FAVORITES")
        end
        if type(data) == "table" then
            for k, v in pairs(data) do
                if v == true and EMOTE_CATALOG[k] then EMOTE_SESSION.favorites[k] = true end
            end
        end
    end
    emoteFavLoad()

    local function emoteStopTrack(disableLoop)
        if disableLoop then
            EMOTE_SESSION.loop = false
            pcall(emoteLoopUIRefresh)
        end
        if emoteMotionConn then emoteMotionConn:Disconnect(); emoteMotionConn = nil end
        local tr = EMOTE_SESSION.track
        EMOTE_SESSION.track = nil
        pcall(function() if tr then tr:Stop(0.12); tr:Destroy() end end)
    end
    local function emotePlay(name)
        local id = EMOTE_CATALOG[name]
        if not id then return false end
        local char = getChar()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:FindFirstChild("Animator"))
        if not animator then return false end
        emoteStopTrack()
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://" .. tostring(id)
        local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
        if not ok or not track then animation:Destroy(); return false end
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = EMOTE_SESSION.loop
        EMOTE_SESSION.track = track
        EMOTE_SESSION.name = name
        track.Stopped:Connect(function()
            if EMOTE_SESSION.track == track and not EMOTE_SESSION.loop then
                EMOTE_SESSION.track = nil
                pcall(function() animation:Destroy() end)
            end
        end)
        track:Play(0.12, 1, 1)
        local function stopForMovement(speed)
            if speed and speed > 0.05 then emoteStopTrack(true) end
        end
        emoteMotionConn = hum.Running:Connect(stopForMovement)
        local movementStates = {
            [Enum.HumanoidStateType.Jumping] = true,
            [Enum.HumanoidStateType.Freefall] = true,
            [Enum.HumanoidStateType.FallingDown] = true,
            [Enum.HumanoidStateType.Climbing] = true,
            [Enum.HumanoidStateType.Swimming] = true,
            [Enum.HumanoidStateType.Seated] = true,
        }
        local stateConn = hum.StateChanged:Connect(function(_, state)
            if movementStates[state] then emoteStopTrack(true) end
        end)
        -- stateConn ikut diputus oleh emoteStopTrack melalui motion connection cleanup.
        -- Simpan keduanya dalam registry agar tidak tertinggal saat script dihapus.
        catat(stateConn)
        return true
    end
    local function emoteSetLoop(v)
        EMOTE_SESSION.loop = v and true or false
        if EMOTE_SESSION.track then
            EMOTE_SESSION.track.Looped = EMOTE_SESSION.loop
        end
    end

    local function bundleSet(folder, ids)
        local char = getChar()
        local animate = char and char:FindFirstChild("Animate")
        if not animate then return end
        local f = animate:FindFirstChild(folder)
        if not f then return end
        local animations = {}
        for _, d in ipairs(f:GetDescendants()) do
            if d:IsA("Animation") then animations[#animations + 1] = d end
        end
        for i, d in ipairs(animations) do
            local id = ids[i] or ids[1]
            if id and tonumber(id) then d.AnimationId = "rbxassetid://" .. tostring(id) end
        end
    end
    local function applyBundle(name, silent)
        local b = BUNDLE_ANIMATIONS[name]
        local char = getChar()
        local animate = char and char:FindFirstChild("Animate")
        if not b or not animate then return false end
        -- Bundle penuh menggantikan preset slot per-gerakan yang sedang aktif.
        EMOTE.master = false
        State.EmoteOn = false
        if Switches["Emote"] then Switches["Emote"].set(false) end
        bundleSet("idle", {b.Idle, b.Idle2})
        bundleSet("walk", {b.Walk})
        bundleSet("run", {b.Run})
        bundleSet("jump", {b.Jump})
        bundleSet("climb", {b.Climb})
        bundleSet("fall", {b.Fall})
        bundleSet("swim", {b.Swim})
        bundleSet("swimidle", {b.SwimIdle})
        if b.Idle3 and animate:FindFirstChild("pose") then
            bundleSet("pose", {b.Idle3})
        end
        pcall(function()
            animate.Disabled = true
            task.wait()
            animate.Disabled = false
        end)
        if not silent then toast("Bundle aktif: " .. tostring(name), Warna.Ungu2) end
        return true
    end

    -- folder target di script Animate per slot
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

    local EMOTE = {
        -- v1.6: awal load SELALU OFF + semua slot ASLI (default).
        -- Pilihan gaya cuma hidup selama sesi — tidak dibaca/ditulis
        -- ke file lagi (BALAP_EMOTE.json lama diabaikan).
        master     = false,
        preset     = {},
        baseline   = {},
        rig        = "?",
    }
    local function emoteResolveSlot(k)
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
    local function emoteSimpan()
        -- v1.6: cadangan sesi saja (getgenv) — tanpa file.
        getgenv().BALAP_EMOTE_DATA = { master = EMOTE.master, preset = EMOTE.preset }
    end
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
    end
    emotePilihPreset = function(k, pi)
        if not SLOT_FOLDERS[k] then return end
        EMOTE.preset[k] = pi
        emoteSimpan()
        local char = getChar()
        if char then
            local id = nil
            if EMOTE.master then id = emoteResolveSlot(k) end
            emoteSetSlotId(k, char, id)
            emoteRestartAnimate()
        end
        if emoteRefreshGrid then emoteRefreshGrid() end
        local _, nama = emoteResolveSlot(k)
        toast("🎬 " .. slotLabel(k) .. ": " .. tostring(nama), Warna.Ungu2)
    end
    local emoteCharSudah = {}
    local function emoteInitCharacter(char)
        if not char or emoteCharSudah[char] then return end
        emoteCharSudah[char] = true
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
    -- v1.6: TANPA emoteMuat — tidak ada config yang dimuat, awal selalu
    -- master OFF + semua slot ASLI (default pabrik).
    State.EmoteOn = EMOTE.master
    catat(LocalPlayer.CharacterAdded:Connect(function(char)
        emoteStopTrack()
        emoteInitCharacter(char)
    end))
    task.spawn(function()
        task.wait(1.0)
        local char = getChar()
        if char then emoteInitCharacter(char) end
    end)
    print("[BALAP-EMOTE] siap — 7 slot • master "
    .. (EMOTE.master and "ON" or "OFF")
    .. " • aktif " .. emoteJumlahAktif() .. "/7")

    -- [7b] TAB BAR (4 TAB) ----------------------------------------------
    -- Bungkus dengan function untuk hemat local count (Luau limit 200)
    local function buildUI()
        tabBtns = {}
        local tabLabels = {"MOVEMENT & VISUAL", "ANIMASI", "EMOTE", "TITIK", "SYSTEM"}
        local tabColors = {Warna.Ungu2, Warna.Biru, Warna.Ungu2, Warna.Hijau2, Warna.AbuGelap}
        kontenTabs = {}
        for i, lbl in ipairs(tabLabels) do
            local tab = buat("TextButton", {
                Size = UDim2.new(1 / 5, -3.2, 0, 24),
                Position = UDim2.new((i - 1) * (1 / 5), 2.8 + (i - 1) * 1.4, 0, 50),
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

        -- [7e] KONTEN TAB 2: ANIMASI (v1.5 — pengganti tab TP) ----------------
        -- Port ANIMASI BUNDLE V6: 7 slot gaya gerak + 18 pack resmi Roblox.
        -- Ganti AnimationId di script "Animate" bawaan -> restart -> hasil
        -- DIREPLIKASI (pemain lain ikut melihat).
        -- v1.6: tanpa config — awal load selalu master OFF, semua slot ASLI.
        -- Logika slot ada di [7a2d]; di sini hanya UI + popup pilih gaya.
        kontenAnim = buat("Frame", {
            Position = UDim2.new(0, 0, 0, 80),
            Size = UDim2.new(1, 0, 1, -110),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        }, panel)
        scrollAnim = buat("ScrollingFrame", {
            Position = UDim2.new(0, 12, 0, 2),
            Size = UDim2.new(1, -24, 1, -6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Warna.Ungu2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, kontenAnim)
        buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollAnim)

        buatHeader(scrollAnim, "Gaya Gerak")
        buatToggleRow(scrollAnim, "⚡ Animasi Kustom (master)", nil, "Emote")

        -- status bar: rig + jumlah slot aktif
        local emoteStatus = buat("TextLabel", {
            BackgroundColor3 = Warna.AbuItem,
            Size = UDim2.new(1, 0, 0, 26),
            FontFace = fnt("med"),
            TextSize = 11,
            TextColor3 = Warna.AbuTeks,
            TextXAlignment = Enum.TextXAlignment.Center,
            Text = "Rig: mendeteksi... • klik slot = pilih gaya",
            LayoutOrder = nextOrder(),
        }, scrollAnim)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, emoteStatus)

        -- grid 3x3 slot gaya (klik = buka popup pilih gaya)
        local emoteSubs = {}
        local emoteGrid = buat("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 156),
            LayoutOrder = nextOrder(),
        }, scrollAnim)
        buat("UIGridLayout", {
            CellSize = UDim2.new(1 / 3, -4, 0, 48),
            CellPadding = UDim2.new(0, 4, 0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, emoteGrid)
        for i, s in ipairs(SLOT_LIST) do
            local b = buat("TextButton", {
                BackgroundColor3 = Warna.AbuItem, BorderSizePixel = 0,
                Text = "", AutoButtonColor = false, LayoutOrder = i,
            }, emoteGrid)
            buat("UICorner", {CornerRadius = UDim.new(0, 8)}, b)
            buat("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 6),
                Size = UDim2.new(1, 0, 0, 16),
                FontFace = fnt("bold"), TextSize = 12,
                TextColor3 = Warna.TeksGelap, Text = s.t,
            }, b)
            local sub = buat("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 4, 0, 24),
                Size = UDim2.new(1, -8, 0, 16),
                FontFace = fnt("reg"), TextSize = 10, TextScaled = true,
                TextColor3 = Warna.AbuTeks, Text = "ASLI",
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
            emoteStatus.Text = "Rig: " .. tostring(EMOTE.rig) .. " • " .. n .. "/7 slot gaya baru • "
            .. (EMOTE.master and "master ON" or "master OFF")
        end


        -- Konten EMOTE dipisahkan dari tab ANIMASI.
        kontenEmote = buat("Frame", {
            Position = UDim2.new(0, 0, 0, 80),
            Size = UDim2.new(1, 0, 1, -110),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        }, panel)
        scrollEmote = buat("ScrollingFrame", {
            Position = UDim2.new(0, 12, 0, 2),
            Size = UDim2.new(1, -24, 1, -6),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = Warna.Ungu2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, kontenEmote)
        buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollEmote)

        -- ===== EMOTE FAVORIT / LOOP (TAB EMOTE) =========================
        buatHeader(scrollAnim, "Emote Catalog")
        local emoteSearch = buat("TextBox", {
            BackgroundColor3 = Warna.Hitam2, Size = UDim2.new(1, 0, 0, 28),
            FontFace = fnt("reg"), TextSize = 12, TextColor3 = Warna.Putih,
            PlaceholderText = "Cari emote...", PlaceholderColor3 = Warna.AbuGelap,
            Text = "", ClearTextOnFocus = false, LayoutOrder = nextOrder(),
        }, scrollEmote)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, emoteSearch)
        local emoteTools = buat("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = nextOrder(),
        }, scrollEmote)
        local favOnly = false
        local favBtn = buat("TextButton", {
            BackgroundColor3 = Warna.Card2, Size = UDim2.new(0.48, 0, 1, 0),
            FontFace = fnt("bold"), TextSize = 11, TextColor3 = Warna.Putih,
            Text = "☆ FAVORIT SAJA", AutoButtonColor = false,
        }, emoteTools)
        buat("UICorner", {CornerRadius = UDim.new(0, 7)}, favBtn)
        local loopBtn = buat("TextButton", {
            BackgroundColor3 = Warna.Card2, Position = UDim2.new(0.52, 0, 0, 0),
            Size = UDim2.new(0.48, 0, 1, 0), FontFace = fnt("bold"), TextSize = 11,
            TextColor3 = Warna.Putih, Text = "↻ LOOP: OFF", AutoButtonColor = false,
        }, emoteTools)
        buat("UICorner", {CornerRadius = UDim.new(0, 7)}, loopBtn)
        local emoteListFrame = buat("ScrollingFrame", {
            BackgroundColor3 = Warna.AbuItem,
            -- Isi hampir seluruh area tab; daftar tetap bisa discroll.
            Size = UDim2.new(1, 0, 0, 500),
            BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
            LayoutOrder = nextOrder(),
        }, scrollEmote)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, emoteListFrame)
        buat("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, emoteListFrame)
        local emoteOrder = 0
        local function renderEmoteList()
            for _, c in ipairs(emoteListFrame:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            emoteOrder = 0
            local q = string.lower(emoteSearch.Text or "")
            local names = {}
            for name in pairs(EMOTE_CATALOG) do
                if (not favOnly or EMOTE_SESSION.favorites[name]) and (q == "" or string.find(string.lower(name), q, 1, true)) then
                    names[#names + 1] = name
                end
            end
            table.sort(names, function(a, b) return a:lower() < b:lower() end)
            for _, name in ipairs(names) do
                emoteOrder += 1
                local row = buat("TextButton", {
                    BackgroundColor3 = Warna.Card2, Size = UDim2.new(1, -6, 0, 27),
                    Text = "", AutoButtonColor = false, LayoutOrder = emoteOrder,
                }, emoteListFrame)
                buat("UICorner", {CornerRadius = UDim.new(0, 6)}, row)
                local label = buat("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0),
                    Size = UDim2.new(1, -55, 1, 0), FontFace = fnt("med"), TextSize = 11,
                    TextColor3 = Warna.Putih, TextXAlignment = Enum.TextXAlignment.Left, Text = name,
                }, row)
                local star = buat("TextButton", {
                    BackgroundTransparency = 1, Position = UDim2.new(1, -38, 0, 0),
                    Size = UDim2.fromOffset(32, 27), FontFace = fnt("bold"), TextSize = 16,
                    TextColor3 = Warna.Kuning, Text = EMOTE_SESSION.favorites[name] and "★" or "☆",
                    AutoButtonColor = false,
                }, row)
                star.MouseButton1Click:Connect(function()
                    EMOTE_SESSION.favorites[name] = not EMOTE_SESSION.favorites[name]
                    emoteFavSave(); renderEmoteList()
                end)
                row.MouseButton1Click:Connect(function()
                    if emotePlay(name) then toast("Emote: " .. name, Warna.Ungu2) end
                end)
            end
        end
        favBtn.MouseButton1Click:Connect(function()
            favOnly = not favOnly
            favBtn.Text = favOnly and "★ FAVORIT SAJA: ON" or "☆ FAVORIT SAJA"
            renderEmoteList()
        end)
        emoteLoopUIRefresh = function()
            if loopBtn and loopBtn.Parent then
                loopBtn.Text = EMOTE_SESSION.loop and "↻ LOOP: ON" or "↻ LOOP: OFF"
                loopBtn.BackgroundColor3 = EMOTE_SESSION.loop and Warna.Ungu or Warna.Card2
            end
        end
        loopBtn.MouseButton1Click:Connect(function()
            emoteSetLoop(not EMOTE_SESSION.loop)
            emoteLoopUIRefresh()
        end)
        emoteSearch:GetPropertyChangedSignal("Text"):Connect(renderEmoteList)
        renderEmoteList()

        -- RESET SEMUA — konfirmasi 2 langkah
        local armResetEmote = 0
        local btnResetEmote = buatActionRow(scrollAnim, "↺ RESET SEMUA → ANIMASI ASLI", Warna.Merah, function()
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
                end
                emoteSimpan()
                emoteTerapkanSemua()
                if emoteRefreshGrid then emoteRefreshGrid() end
                toast("Semua slot balik ke animasi ASLI", Warna.Merah)
            end
        end)

        -- catatan
        buat("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
            FontFace = fnt("reg"), TextSize = 10,
            TextColor3 = Warna.AbuTeks, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Bundle dan emote ini dipakai lokal untuk karakter kamu. "
            .. "Bundle gaya gerak dan katalog emote dari script kedua. "
            .. "Favorit tersimpan lokal; loop dapat dinyalakan dari tombol di atas. "
            .. "Bundle otomatis dipasang lagi setelah mati/respawn. v1.6: awal load "
            .. "selalu OFF + semua slot ASLI — nyalakan ⚡ master dulu, gaya pilihanmu "
            .. "aktif selama sesi saja (script dijalankan ulang = balik default).",
            LayoutOrder = nextOrder(),
        }, scrollAnim)

        -- ===== POPUP PILIH GAYA (overlay di panel, di atas semua tab) =====
        local chooserBackdrop = buat("TextButton", {
            Visible = false, ZIndex = 60,
            BackgroundColor3 = Warna.Hitam, BackgroundTransparency = 0.35,
            Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false,
        }, panel)
        local chooser = buat("Frame", {
            Visible = false, ZIndex = 61,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -30, 0, 330),
            BackgroundColor3 = Warna.Hitam2, BorderSizePixel = 0,
        }, panel)
        buat("UICorner", {CornerRadius = UDim.new(0, 12)}, chooser)
        buat("UIStroke", {Color = Warna.Ungu2, Thickness = 2}, chooser)
        local chooserJudul = buat("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 12, 0, 8),
            Size = UDim2.new(1, -64, 0, 18),
            FontFace = fnt("bold"), TextSize = 13,
            TextColor3 = Warna.Putih,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "PILIH GAYA",
        }, chooser)
        local chooserTutupBtn = buat("TextButton", {
            Position = UDim2.new(1, -34, 0, 6),
            Size = UDim2.fromOffset(28, 22),
            BackgroundColor3 = Warna.Merah,
            FontFace = fnt("bold"), TextSize = 12,
            TextColor3 = Warna.Putih, Text = "✕", AutoButtonColor = false,
        }, chooser)
        buat("UICorner", {CornerRadius = UDim.new(0, 6)}, chooserTutupBtn)
        local chooserList = buat("ScrollingFrame", {
            Position = UDim2.new(0, 10, 0, 30),
            Size = UDim2.new(1, -20, 1, -40),
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Warna.Ungu2,
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
            chooserJudul.Text = "GAYA " .. slotLabel(skey) .. "  (rig " .. rig .. ")"
            chooserOrder = 0
            for _, c in ipairs(chooserList:GetChildren()) do
                if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
            end
            local function tambahBar(teks, warna, bisa, cb)
                local br = buat("TextButton", {
                    Size = UDim2.new(1, -6, 0, 30),
                    BackgroundColor3 = bisa and Warna.Card2 or Warna.Hitam,
                    Text = "", AutoButtonColor = false,
                    LayoutOrder = chooserNext(),
                }, chooserList)
                buat("UICorner", {CornerRadius = UDim.new(0, 8)}, br)
                buat("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    FontFace = fnt("med"), TextSize = 12,
                    TextColor3 = warna,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Text = teks,
                }, br)
                br.MouseButton1Click:Connect(function()
                    if bisa then cb() else toast("Preset ini tidak untuk rig " .. rig, Warna.Kuning) end
                end)
            end
            tambahBar("ASLI — animasi default game" .. (aktifPi == 0 and "   ✓" or ""),
                Warna.Putih, true, function()
                emotePilihPreset(skey, 0)
                chooserBackdrop.Visible = false; chooser.Visible = false
            end)
            for pi, p in ipairs(EMOTE_PRESET[skey] or {}) do
                local id = (rig == "R6") and p.i6 or p.i15
                local tagRig = (p.i15 and p.i6 and "(R15+R6)") or (p.i15 and "(R15)") or "(R6)"
                local teks = p.n .. "  " .. tagRig
                if aktifPi == pi then teks = teks .. "   ✓" end
                if id then
                    tambahBar(teks, Warna.Ungu2, true, function()
                        emotePilihPreset(skey, pi)
                        chooserBackdrop.Visible = false; chooser.Visible = false
                    end)
                else
                    tambahBar(teks, Warna.AbuGelap, false, nil)
                end
            end
            chooserBackdrop.Visible = true
            chooser.Visible = true
        end
        chooserBackdrop.MouseButton1Click:Connect(function()
            chooserBackdrop.Visible = false
            chooser.Visible = false
        end)
        chooserTutupBtn.MouseButton1Click:Connect(function()
            chooserBackdrop.Visible = false
            chooser.Visible = false
        end)

        -- ===== TAB TITIK ================================================
        kontenTitik = buat("Frame", {
            Position = UDim2.new(0, 0, 0, 80), Size = UDim2.new(1, 0, 1, -110),
            BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
        }, panel)
        scrollTitik = buat("ScrollingFrame", {
            Position = UDim2.new(0, 12, 0, 2), Size = UDim2.new(1, -24, 1, -6),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
            ScrollBarImageColor3 = Warna.Hijau2, ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, kontenTitik)
        buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, scrollTitik)
        local titikOrder = 0
        local function titikNext() titikOrder += 1; return titikOrder end
        local titikStatus = buat("TextLabel", {
            BackgroundColor3 = Warna.AbuItem, Size = UDim2.new(1, 0, 0, 30),
            FontFace = fnt("med"), TextSize = 11, TextColor3 = Warna.TeksGelap,
            TextWrapped = true, Text = "Titik tersimpan: " .. #TITIK.poin,
            LayoutOrder = titikNext(),
        }, scrollTitik)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, titikStatus)
        buat("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, titikStatus)
        titikStatusUI = function(teks)
            if titikStatus and titikStatus.Parent then titikStatus.Text = teks .. " • Total: " .. #TITIK.poin end
        end
        local namaTitikBox = buat("TextBox", {
            BackgroundColor3 = Warna.Hitam2, Size = UDim2.new(1, 0, 0, 30),
            FontFace = fnt("reg"), TextSize = 12, TextColor3 = Warna.Putih,
            PlaceholderText = "Nama titik baru (opsional)", PlaceholderColor3 = Warna.AbuGelap,
            Text = "", ClearTextOnFocus = false, LayoutOrder = titikNext(),
        }, scrollTitik)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, namaTitikBox)
        local modeTitikBtn = buatActionRow(scrollTitik, "📍 MODE CTRL + KLIK: OFF", Warna.Hijau2, function() end)
        modeTitikBtn.LayoutOrder = titikNext()
        local function refreshModeTitik()
            modeTitikBtn.Text = TITIK.aktif and "📍 MODE CTRL + KLIK: ON" or "📍 MODE CTRL + KLIK: OFF"
            modeTitikBtn.BackgroundColor3 = TITIK.aktif and Warna.Hijau2 or Warna.Card2
        end
        modeTitikBtn.MouseButton1Click:Connect(function()
            TITIK.aktif = not TITIK.aktif; refreshModeTitik()
            titikStatusUI(TITIK.aktif and "Aktif: tahan CTRL lalu klik kiri permukaan dunia" or "Mode penempatan dimatikan")
        end)
        buatActionRow(scrollTitik, "➕ TAMBAH DARI POSISI SAYA", Warna.Biru, function()
            local pos, normal = titikPosisiKarakter()
            if pos then titikTambah(namaTitikBox.Text, pos, normal) else titikStatusUI("Karakter belum siap") end
            namaTitikBox.Text = ""
        end).LayoutOrder = titikNext()
        buatActionRow(scrollTitik, "● TITIK: TAMPILKAN / SEMBUNYIKAN", Warna.Ungu2, function()
            TITIK.tampilTitik = not TITIK.tampilTitik; titikRefreshDot()
            titikStatusUI(TITIK.tampilTitik and "Titik kecil ditampilkan" or "Titik kecil disembunyikan")
        end).LayoutOrder = titikNext()
        buatActionRow(scrollTitik, "🗑 HAPUS SEMUA TITIK", Warna.Merah, function()
            table.clear(TITIK.poin)
            titikSimpan()
            titikRefreshDot()
            titikRenderUI()
            titikStatusUI("Semua titik dihapus")
        end).LayoutOrder = titikNext()
        local titikList = buat("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = titikNext(),
        }, scrollTitik)
        buat("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, titikList)
        titikRenderUI = function()
            for _, obj in ipairs(titikList:GetChildren()) do
                if obj:IsA("Frame") then obj:Destroy() end
            end
            for i, point in ipairs(TITIK.poin) do
                local row = buat("Frame", {
                    BackgroundColor3 = Warna.AbuItem, Size = UDim2.new(1, 0, 0, 52), LayoutOrder = i,
                }, titikList)
                buat("UICorner", {CornerRadius = UDim.new(0, 8)}, row)
                local box = buat("TextBox", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 2),
                    Size = UDim2.new(1, -120, 0, 24), FontFace = fnt("med"), TextSize = 11,
                    TextColor3 = Warna.TeksGelap, TextXAlignment = Enum.TextXAlignment.Left,
                    Text = point.name, ClearTextOnFocus = false,
                }, row)
                box.FocusLost:Connect(function()
                    local nama = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
                    if nama ~= "" then point.name = nama; titikSimpan(); titikRefreshDot(); titikStatusUI("Nama titik diubah") else box.Text = point.name end
                end)
                local go = buat("TextButton", {
                    BackgroundColor3 = Warna.Biru, Position = UDim2.new(1, -108, 0, 5),
                    Size = UDim2.fromOffset(50, 28), FontFace = fnt("bold"), TextSize = 10,
                    TextColor3 = Warna.Putih, Text = "KE SANA", AutoButtonColor = false,
                }, row)
                buat("UICorner", {CornerRadius = UDim.new(0, 6)}, go)
                go.MouseButton1Click:Connect(function() titikTeleport(i) end)
                local del = buat("TextButton", {
                    BackgroundColor3 = Warna.Merah, Position = UDim2.new(1, -53, 0, 5),
                    Size = UDim2.fromOffset(45, 28), FontFace = fnt("bold"), TextSize = 10,
                    TextColor3 = Warna.Putih, Text = "HAPUS", AutoButtonColor = false,
                }, row)
                buat("UICorner", {CornerRadius = UDim.new(0, 6)}, del)
                del.MouseButton1Click:Connect(function() titikHapus(i) end)
            end
            titikStatusUI("Titik tersimpan: " .. #TITIK.poin)
        end
        titikRenderUI()
        buat("TextLabel", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 42),
            FontFace = fnt("reg"), TextSize = 10, TextColor3 = Warna.AbuTeks,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
            Text = "Aktifkan mode, lalu tahan CTRL + klik kiri pada tanah atau dinding untuk menempelkan titik kecil. Titik tidak melayang dan semua perpindahan hanya untuk karakter kamu.",
            LayoutOrder = titikNext(),
        }, scrollTitik)

        -- urutan kontenTabs = 1 MOVEMENT • 2 ANIMASI • 3 EMOTE • 4 TITIK • 5 SYSTEM
        table.insert(kontenTabs, kontenAnim)
        table.insert(kontenTabs, kontenEmote)
        table.insert(kontenTabs, kontenTitik)
        table.insert(kontenTabs, kontenSistem)

        buatHeader(scrollSistem, "Info")
        local infoUser = buat("TextLabel", {
            BackgroundColor3 = Warna.AbuItem,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            FontFace = fnt("med"),
            TextSize = 12,
            TextColor3 = Warna.TeksGelap,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Text = "⚡ BALAP v" .. VERSI .. "\n"
            .. "👤 User: " .. tostring(LocalPlayer.Name) .. " (" .. tostring(LocalPlayer.DisplayName) .. ")\n"
            .. "💻 Device: " .. (UserInputService.TouchEnabled and not UserInputService.MouseEnabled
                and "HP" or "PC"),
            LayoutOrder = nextOrder(),
        }, scrollSistem)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, infoUser)
        buat("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, infoUser)
        -- nama executor: cek global executor yang umum (tidak semua punya)
        do
            local executorTeks = "tidak dikenal"
            pcall(function()
                if type(identifyexecutor) == "function" then
                    executorTeks = tostring(identifyexecutor())
                elseif type(getexecutorname) == "function" then
                    executorTeks = tostring(getexecutorname())
                end
            end)
            infoUser.Text = infoUser.Text .. "\n🔧 Executor: " .. executorTeks
        end
        -- nama map: via MarketplaceService (bisa butuh waktu / gagal offline)
        task.spawn(function()
            local namaMap = tostring(game.Name)
            pcall(function()
                local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
                if info and info.Name and #info.Name > 0 then namaMap = info.Name end
            end)
            if infoUser and infoUser.Parent then
                infoUser.Text = infoUser.Text
                .. "\n🗺️ Map: " .. namaMap .. " (" .. tostring(game.PlaceId) .. ")"
            end
        end)
        -- FPS live: dihitung dari RenderStepped, angka bergerak tiap 0.5 dtk
        local infoFps = buat("TextLabel", {
            BackgroundColor3 = Warna.AbuItem,
            Size = UDim2.new(1, 0, 0, 26),
            FontFace = fnt("med"),
            TextSize = 12,
            TextColor3 = Warna.TeksGelap,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = "📊 FPS: mengukur...",
            LayoutOrder = nextOrder(),
        }, scrollSistem)
        buat("UICorner", {CornerRadius = UDim.new(0, 8)}, infoFps)
        buat("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8)}, infoFps)
        do
            local frames, cekTerakhir = 0, os.clock()
            catat(RunService.RenderStepped:Connect(function()
                frames += 1
                local now = os.clock()
                if now - cekTerakhir >= 0.5 then
                    local fps = math.floor(frames / (now - cekTerakhir) + 0.5)
                    frames = 0
                    cekTerakhir = now
                    if infoFps and infoFps.Parent then
                        infoFps.Text = "📊 FPS: " .. fps
                    end
                end
            end))
        end
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
            Text = "⌨ G = GUI   ✦   🏃 Q Speed ON/OFF (OFF 17.10, ON 17.25-35) • J Jump (51.25/65.25) • C Shift • LShift Tengah • F Moonwalk • V Panah   ✦   🎬 TAB ANIMASI • 💃 TAB EMOTE • 📍 TAB TITIK: CTRL + klik   ✦   🎨 R Hide • Hide Atas • T Cahaya 2-arah • X Dinding • LW   ✦   ☁ SYSTEM: input teks • SIMPAN/LOAD manual • load otomatis cuma 1x saat start   ✦   ⚙️ K×2 rejoin • Notif kanan atas",
            TextColor3 = Warna.AbuGelap,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, marqueeClip)
        table.insert(effTweens, tween(marquee, TweenInfo.new(24, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
        {Position = UDim2.fromOffset(-1600, 0)}))

        -- bracket pojok (dekorasi)
        local posisiDekorasi = {
            UDim2.new(0.5, 0, 0, 1),
            UDim2.new(0.5, 0, 1, -1),
            UDim2.new(0, 1, 0.5, 0),
            UDim2.new(1, -1, 0.5, 0),
        }
        for i, p in ipairs(posisiDekorasi) do
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

        -- ⚡ ANIMASI KUSTOM (v1.5, tab ANIMASI) — master semua slot gaya.
        -- emoteSetMaster mengurus state, apply, switch & toast sendiri.
        Setters.Emote = function(v, silent)
            emoteSetMaster(v, silent)
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
        -- samping 45 derajat = zona tenang. Loop task.wait(0.1) hemat; arah dihitung horizontal agar stabil.
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
                        local char = getChar()
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if char and hrp then
                            local myPos = hrp.Position
                            -- Deteksi depan/belakang memakai arah badan di bidang tanah.
                            -- Ketinggian pemain tidak boleh membuat hasil salah.
                            local look3 = hrp.CFrame.LookVector
                            local lookFlat = Vector3.new(look3.X, 0, look3.Z)
                            if lookFlat.Magnitude > 0.001 then lookFlat = lookFlat.Unit end
                            for _, pl in ipairs(Players:GetPlayers()) do
                                if pl ~= LocalPlayer then
                                    local c2 = pl.Character
                                    local h2 = c2 and c2:FindFirstChildOfClass("Humanoid")
                                    local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                                    if h2 and r2 and h2.Health > 0 then
                                        local rel = r2.Position - myPos
                                        local relFlat = Vector3.new(rel.X, 0, rel.Z)
                                        local d = relFlat.Magnitude
                                        if d > 0.5 and d <= CFG.PANAH_JARAK and lookFlat.Magnitude > 0.001 then
                                            local dot = lookFlat:Dot(relFlat.Unit)
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
            pcall(setFeature, "Hide", false, true)
            pcall(setFeature, "LW", false, true)
            pcall(setFeature, "Walls", false, true)
            pcall(setFeature, "Light", false, true)
            pcall(setFeature, "HideAtas", false, true)
            pcall(setFeature, "Panah", false, true)
            pcall(setFeature, "Emote", false, true)      -- v1.5: balik ke animasi asli
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
            pcall(emoteStopTrack)
            pcall(function() if TITIK.folder then TITIK.folder:Destroy(); TITIK.folder = nil end end)
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
            local hum = char:WaitForChild("Humanoid", 10)
            if not hum then return end
            -- v1.4: penanda respawn dipasang SETELAH Humanoid ketemu —
            -- dulu bisa terlewat (fitur tidak dipasang ulang) saat
            -- Humanoid lambat muncul di map baru yang berat
            initedChar = char
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

        -- [21a] PENEMPATAN TITIK: CTRL + KLIK KIRI ------------------------
        catat(UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or State.Removed or not TITIK.aktif then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1
                and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                or UserInputService:IsKeyDown(Enum.KeyCode.RightControl))
                and not UserInputService:GetFocusedTextBox() then
                titikKlikDunia()
            end
        end))

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
            -- (G/Q dst. tidak nyasar saat isi stepper / input teks)
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
                setFeature("Panah", not State.PanahOn)  -- Panah Deteksi
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
        print("[BALAP " .. VERSI .. "] SIAP ✔ — G = GUI | K×2 = rejoin")
        print("[BALAP] MOVE&VISUAL | ANIMASI | SYSTEM • Q speed • J jump • C shift • LShift tengah • F moon (S=off) • V panah • R hide • T cahaya • X dinding • K×2 rejoin • LOCAL ONLY")
        diagSet("BALAP " .. VERSI .. " SIAP - GUI akan terbuka sendiri", Color3.fromRGB(16, 185, 129))
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
    getgenv().BALAP_API = { Setters = Setters, State = State }  -- debug/otomasi + harness uji
end, function(e)
    local teks = tostring(e)
    print("==================================================")
    print("[BALAP " .. VERSI .. "] ERROR SAAT LOAD — kirim teks ini ke dev:")
    print(teks)
    pcall(function() print(debug.traceback("", 2)) end)
    print("==================================================")
    pcall(function()
        diagSet("ERROR LOAD: " .. teks:sub(1, 260), Color3.fromRGB(239, 68, 68))
    end)
end)
if not __BALAP_LOAD_OK__ then
    warn("[BALAP " .. VERSI .. "] Script GAGAL load — banner MERAH di layar berisi errornya.")
end
