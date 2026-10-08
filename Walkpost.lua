--[[═══════════════════════════════════════════════
    🛠️ ALAT BANTU LATIHAN v3.0
    ─────────────────────────────────────────────
    👁️ DINDING INVISIBLE [T]
       dinding tersembunyi dibuat terlihat:
       🔴 merah = pembatas • 🟢 hijau = platform
    🚧 TRAFFIC POST [G]
       pasang post di titik A → otomatis muncul
       garis lurus ke post terdekat (titik B).
       Susun post di tikungan = panduan jalur
       tercepat, biar gak melebar saat balapan.
    💾 AUTO-SAVE
       post otomatis tersimpan ke file executor
       → load otomatis saat script dijalankan lagi
    🔁 REJOIN [R]
       keluar & masuk server yang sama, post aman

    HOTKEY: F=GUI  T=Dinding  G=Post  Z=Undo  X=Hapus  R=Rejoin
    ═══════════════════════════════════════════════]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local function getRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

--═════════ KONFIG ═════════
-- dinding
local MAX_SHELL, TRANS_MIN, UKURAN_MIN = 400, 0.95, 3
local KATA_NAMA = {"invisible", "barrier", "block", "wall", "border", "gate", "hidden"}
-- traffic post
local MAX_POST  = 150     -- batas post
local MAX_LINE  = 750     -- di atas ini = dianggap segmen baru (gak disambung)
local JARAK_MIN_POST = 2  -- post terlalu rapat ditolak
-- save
local FILE_SAVE = "ABL_posts.json"

--═════════ WARNA ═════════
local BG      = Color3.fromRGB(15, 18, 28)
local BARIS   = Color3.fromRGB(30, 36, 52)
local HOVER   = Color3.fromRGB(46, 54, 78)
local ACCENT  = Color3.fromRGB(34, 211, 238)   -- cyan
local UNGU    = Color3.fromRGB(167, 139, 250)
local TEKS    = Color3.fromRGB(235, 240, 250)
local MERAH   = Color3.fromRGB(248, 113, 113)
local HIJAU   = Color3.fromRGB(74, 222, 128)

--═════════ FOLDER + KONEKSI ═════════
local folderShell = Instance.new("Folder")
folderShell.Name, folderShell.Parent = "_ABL_shell", workspace

local folderPost = Instance.new("Folder")
folderPost.Name, folderPost.Parent = "_ABL_post", workspace

local conns = {}
local function addConn(c) table.insert(conns, c) return c end

--═════════ GUI ═════════
local gui = Instance.new("ScreenGui")
gui.Name = "AlatBantuLatihan"; gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(310, 286)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = BG
main.BorderSizePixel = 0; main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)
local st = Instance.new("UIStroke", main)
st.Color, st.Thickness, st.Transparency = ACCENT, 1.5, 0.55

local judul = Instance.new("TextLabel", main)
judul.Size = UDim2.new(1, -24, 0, 34); judul.Position = UDim2.new(0, 12, 0, 0)
judul.BackgroundTransparency = 1; judul.Text = "🛠️ ALAT BANTU LATIHAN"
judul.TextSize = 16; judul.Font = Enum.Font.GothamBold
judul.TextColor3 = TEKS; judul.TextXAlignment = Enum.TextXAlignment.Left

local garisJudul = Instance.new("Frame", main)
garisJudul.Size = UDim2.new(1, -24, 0, 2); garisJudul.Position = UDim2.new(0, 12, 0, 33)
garisJudul.BackgroundColor3 = ACCENT; garisJudul.BorderSizePixel = 0
local grad = Instance.new("UIGradient", garisJudul)
grad.Color = ColorSequence.new(ACCENT, UNGU)

local function buatTombol(teks, posisi, ukuran, warnaTeks)
    local b = Instance.new("TextButton", main)
    b.Size = ukuran or UDim2.new(1, -24, 0, 34)
    b.Position = posisi
    b.BackgroundColor3 = BARIS; b.BorderSizePixel = 0
    b.TextColor3 = warnaTeks or TEKS; b.TextSize = 14
    b.Font = Enum.Font.GothamBold; b.Text = teks
    b.AutoButtonColor = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = HOVER}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = BARIS}):Play()
    end)
    return b
end

local btnWall = buatTombol("👁️ Dinding Invisible [T]: OFF", UDim2.new(0, 12, 0, 42))
local btnPost = buatTombol("🚧 Pasang Traffic Post [G]",     UDim2.new(0, 12, 0, 82))
local btnUndo = buatTombol("↩️ Undo [Z]",  UDim2.new(0, 12, 0, 122), UDim2.new(0.5, -18, 0, 34))
local btnBersihPost = buatTombol("🗑️ Hapus Post [X]", UDim2.new(0.5, 6, 0, 122), UDim2.new(0.5, -18, 0, 34))
local btnRejoin = buatTombol("🔁 Rejoin [R] — post aman", UDim2.new(0, 12, 0, 162), nil, UNGU)

local lblStatus = Instance.new("TextLabel", main)
lblStatus.Size = UDim2.new(1, -24, 0, 34); lblStatus.Position = UDim2.new(0, 12, 0, 202)
lblStatus.BackgroundColor3 = Color3.fromRGB(8, 10, 16); lblStatus.BorderSizePixel = 0
lblStatus.TextColor3 = Color3.fromRGB(170, 180, 200); lblStatus.TextSize = 12
lblStatus.Font = Enum.Font.Gotham; lblStatus.Text = "🚧 0 post"
lblStatus.TextTruncate = Enum.TextTruncate.AtEnd
Instance.new("UICorner", lblStatus).CornerRadius = UDim.new(0, 10)

local btnReset = buatTombol("🔄 Reset", UDim2.new(0, 12, 1, -44), UDim2.new(0.5, -18, 0, 34), ACCENT)
local btnExit  = buatTombol("❌ Keluar", UDim2.new(0.5, 6, 1, -44), UDim2.new(0.5, -18, 0, 34), MERAH)

local function status(msg) lblStatus.Text = msg end

--═════════ 💾 PENYIMPANAN (executor file system) ═════════
local posts = {}          -- {model, ball, label, pos, line, len}
local totalPanjang = 0

local hasFS = (typeof(writefile) == "function" and typeof(readfile) == "function")
local TAG_FS = hasFS and "" or " • ⚠️ tak tersimpan"

local function simpanPost()
    if not hasFS then return end
    local data = {}
    for _, p in ipairs(posts) do
        table.insert(data, {
            x = p.pos.X, y = p.pos.Y, z = p.pos.Z,
            l = p.len, h = p.line ~= nil,
        })
    end
    pcall(function()
        writefile(FILE_SAVE, HttpService:JSONEncode(data))
    end)
end

local function hapusFile()
    if not hasFS then return end
    pcall(function()
        if typeof(isfile) == "function" and isfile(FILE_SAVE) then
            delfile(FILE_SAVE)
        end
    end)
end

--═════════ 👁️ DINDING INVISIBLE ═════════
local espOn = false
local shellPairs = {}
local scanId = 0   -- pembatal scan saat toggle cepat

local function kandidatWall(p)
    if not p:IsA("BasePart") then return false end
    if p == workspace.Terrain then return false end
    if not p.CanCollide then return false end
    local mencurigakan = p.Transparency >= TRANS_MIN
    if not mencurigakan then
        local n = string.lower(p.Name)
        for _, kata in ipairs(KATA_NAMA) do
            if string.find(n, kata, 1, true) then mencurigakan = true break end
        end
    end
    if not mencurigakan then return false end
    local s = p.Size
    if math.max(s.X, s.Y, s.Z) < UKURAN_MIN then return false end
    if math.min(s.X, s.Y, s.Z) < 0.05 then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and p:IsDescendantOf(plr.Character) then return false end
    end
    return true
end

local function adalahPlatform(p)
    return p.CFrame.UpVector:Dot(Vector3.yAxis) >= 0.6 and p.Size.Y <= 6
end

local function bersihkanShell()
    for _, data in ipairs(shellPairs) do
        pcall(function() data.shell:Destroy() end)
    end
    shellPairs = {}
end

local function scanDinding()
    scanId += 1
    local id = scanId
    bersihkanShell()
    status("🔍 memindai…")
    task.spawn(function()
        local kandidat = {}
        local n = 0
        for _, p in ipairs(workspace:GetDescendants()) do
            if kandidatWall(p) and not p:IsDescendantOf(folderShell) then
                table.insert(kandidat, p)
            end
            n += 1
            if n % 3000 == 0 then task.wait() end -- anti-freeze di map besar
        end
        if id ~= scanId then return end -- scan dibatalkan / esp dimatikan

        local root = getRoot()
        local pos = root and root.Position or Vector3.zero
        table.sort(kandidat, function(a, b)
            return (a.Position - pos).Magnitude < (b.Position - pos).Magnitude
        end)

        local nD, nP = 0, 0
        for i, p in ipairs(kandidat) do
            if i > MAX_SHELL then break end
            if id ~= scanId then bersihkanShell() return end
            if p.Parent then
                local plat = adalahPlatform(p)
                local shell = Instance.new("Part")
                shell.Anchored, shell.CanCollide = true, false
                shell.CanQuery, shell.CanTouch, shell.CastShadow = false, false, false
                shell.Material = Enum.Material.Neon
                shell.Color = plat and HIJAU or MERAH
                shell.Transparency = plat and 0.5 or 0.65
                shell.Size = p.Size + Vector3.new(0.1, 0.1, 0.1)
                shell.CFrame = p.CFrame
                shell.Parent = folderShell
                table.insert(shellPairs, {part = p, shell = shell, lastCF = p.CFrame})
                if plat then nP += 1 else nD += 1 end
            end
        end
        if espOn and id == scanId then
            status(("🔴 %d dinding • 🟢 %d platform"):format(nD, nP))
        end
    end)
end

local function setEsp(on)
    espOn = on
    if not on then scanId += 1 end -- batalkan scan yang sedang berjalan
    btnWall.Text = "👁️ Dinding Invisible [T]: " .. (on and "ON" or "OFF")
    btnWall.BackgroundColor3 = on and ACCENT or BARIS
    btnWall.TextColor3 = on and Color3.fromRGB(8, 12, 20) or TEKS
    if on then scanDinding() else bersihkanShell(); status(statusPost()) end
end

addConn(RunService.Heartbeat:Connect(function(dt)
    if espOn and #shellPairs > 0 then
        shellPairs.akum = (shellPairs.akum or 0) + dt
        if shellPairs.akum >= 0.12 then
            shellPairs.akum = 0
            for i = #shellPairs, 1, -1 do
                local data = shellPairs[i]
                if data.part.Parent then
                    if data.part.CFrame ~= data.lastCF then
                        data.lastCF = data.part.CFrame
                        data.shell.CFrame = data.part.CFrame
                        data.shell.Size = data.part.Size + Vector3.new(0.1, 0.1, 0.1)
                    end
                else
                    data.shell:Destroy()
                    table.remove(shellPairs, i)
                end
            end
        end
    end
end))

-- rescan otomatis setelah respawn biar hasil tetap fresh
addConn(LocalPlayer.CharacterAdded:Connect(function()
    if espOn then
        task.wait(0.5)
        if espOn then scanDinding() end
    end
end))

--═════════ 🚧 TRAFFIC POST ═════════
local function filterRacikan()
    local list = {folderPost, folderShell}
    local char = LocalPlayer.Character
    if char then table.insert(list, char) end
    local hum = getHum()
    local seat = hum and hum.SeatPart
    if seat then
        local v = seat:FindFirstAncestorOfClass("Model")
        if v then table.insert(list, v) end
    end
    return list
end

local function proyeksiTanah(pos)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = filterRacikan()
    local hit = workspace:Raycast(pos, Vector3.new(0, -30, 0), params)
    if hit then return Vector3.new(pos.X, hit.Position.Y, pos.Z) end
    return Vector3.new(pos.X, pos.Y - 2.5, pos.Z)
end

local function statusPost(tambahan)
    if #posts == 0 then return "🚧 0 post" .. TAG_FS end
    return ("🚧 %d post • jalur ±%d m%s%s"):format(
        #posts, math.floor(totalPanjang + 0.5), tambahan or "", TAG_FS)
end

local function perbaruiNomor()
    for i, p in ipairs(posts) do p.label.Text = tostring(i) end
end

local function buatGaris(a, b)
    local jarak = (b - a).Magnitude
    if jarak < 1 then return nil, 0 end
    local up = math.abs((b - a).Unit.Y) > 0.99 and Vector3.xAxis or Vector3.yAxis
    local p = Instance.new("Part")
    p.Anchored, p.CanCollide = true, false
    p.CanQuery, p.CanTouch, p.CastShadow = false, false, false
    p.Material = Enum.Material.Neon
    p.Color = ACCENT
    p.Transparency = 0.45
    p.Size = Vector3.new(0.3, 0.3, jarak)
    p.CFrame = CFrame.lookAt((a + b) * 0.5, b, up) -- aman utk garis vertikal
    p.Parent = folderPost
    return p, jarak
end

-- inti pembuatan post — dipakai placePost & muatPost
local function buatPostDi(pos, pakaiGaris)
    local model = Instance.new("Model"); model.Name = "_post"

    local pole = Instance.new("Part")
    pole.Anchored, pole.CanCollide = true, false
    pole.CanQuery, pole.CanTouch, pole.CastShadow = false, false, false
    pole.Material = Enum.Material.SmoothPlastic
    pole.Color = Color3.fromRGB(200, 210, 230)
    pole.Size = Vector3.new(0.35, 3, 0.35)
    pole.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0))
    pole.Parent = model

    local ball = Instance.new("Part")
    ball.Anchored, ball.CanCollide = true, false
    ball.CanQuery, ball.CanTouch, ball.CastShadow = false, false, false
    ball.Shape = Enum.PartType.Ball
    ball.Material = Enum.Material.Neon
    ball.Color = ACCENT
    ball.Size = Vector3.new(1.3, 1.3, 1.3)
    ball.CFrame = CFrame.new(pos + Vector3.new(0, 3.65, 0))
    ball.Parent = model

    local bb = Instance.new("BillboardGui", ball)
    bb.Size = UDim2.fromOffset(44, 28)
    bb.StudsOffset = Vector3.new(0, 1.1, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    local t = Instance.new("TextLabel", bb)
    t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold; t.TextScaled = true
    t.TextColor3 = TEKS; t.TextStrokeTransparency = 0.35
    t.Text = tostring(#posts + 1)
    model.Parent = folderPost

    -- cari post terdekat → sambung garis
    local terdekat, jarakMin
    for _, p in ipairs(posts) do
        local d = (p.pos - pos).Magnitude
        if not jarakMin or d < jarakMin then terdekat, jarakMin = p, d end
    end

    if pakaiGaris == nil then -- auto (pemasangan baru)
        pakaiGaris = (terdekat ~= nil and jarakMin <= MAX_LINE)
    end

    local rec = {model = model, ball = ball, label = t, pos = pos, line = nil, len = 0}
    local segmenBaru = false
    if pakaiGaris and terdekat and jarakMin <= MAX_LINE then
        rec.line, rec.len = buatGaris(terdekat.ball.Position, ball.Position)
    elseif terdekat then
        segmenBaru = true
    end

    table.insert(posts, rec)
    totalPanjang += rec.len
    return segmenBaru
end

local function placePost()
    local root = getRoot()
    if not root then status("⚠️ karakter belum ada") return end
    if #posts >= MAX_POST then status("⚠️ maksimal " .. MAX_POST .. " post") return end

    local pos = proyeksiTanah(root.Position)
    for _, p in ipairs(posts) do
        if (p.pos - pos).Magnitude < JARAK_MIN_POST then
            status("⚠️ terlalu dekat post lain")
            return
        end
    end

    local segmenBaru = buatPostDi(pos)
    perbaruiNomor()
    simpanPost()
    status(statusPost(segmenBaru and " • segmen baru" or " • 💾"))
end

local function undoPost()
    local rec = table.remove(posts)
    if not rec then status("tidak ada post untuk di-undo") return end
    if rec.line then pcall(function() rec.line:Destroy() end) end
    pcall(function() rec.model:Destroy() end)
    totalPanjang = 0
    for _, p in ipairs(posts) do totalPanjang += p.len end
    perbaruiNomor()
    simpanPost()
    status(statusPost(" • 💾"))
end

local function bersihkanPost()
    folderPost:ClearAllChildren()
    posts = {}
    totalPanjang = 0
    hapusFile()
    status(statusPost())
end

-- 💾 muat post dari sesi sebelumnya
local function muatPost()
    if not hasFS then return end
    local ok, isi = pcall(readfile, FILE_SAVE)
    if not ok or not isi or isi == "" then return end
    local okD, data = pcall(function() return HttpService:JSONDecode(isi) end)
    if not okD or typeof(data) ~= "table" then return end

    for _, d in ipairs(data) do
        if #posts >= MAX_POST then break end
        if typeof(d.x) == "number" and typeof(d.y) == "number" and typeof(d.z) == "number" then
            buatPostDi(Vector3.new(d.x, d.y, d.z), d.h == true)
        end
    end
    perbaruiNomor()
    if #posts > 0 then status(statusPost(" • dimuat 💾")) end
end

--═════════ 🔁 REJOIN ═════════
local function rejoin()
    simpanPost()
    status("💾 tersimpan • 🔄 rejoin…")
    local pid, jid = game.PlaceId, game.JobId
    task.delay(0.8, function()
        local ok = pcall(function()
            if jid ~= nil and jid ~= "" then
                TeleportService:TeleportToPlaceInstance(pid, jid, LocalPlayer) -- server sama
            else
                TeleportService:Teleport(pid, LocalPlayer)
            end
        end)
        if not ok then status("⚠️ rejoin gagal — coba lagi") end
    end)
end

--═════════ 🔄 RESET & ❌ KELUAR ═════════
btnReset.MouseButton1Click:Connect(function()
    setEsp(false)
    bersihkanPost() -- reset total: post + file ikut terhapus
    status("reset ✓")
end)

btnExit.MouseButton1Click:Connect(function()
    simpanPost() -- post tetap tersimpan walau tool dihapus
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    table.clear(conns)
    pcall(function() folderShell:Destroy() end)
    pcall(function() folderPost:Destroy() end)
    gui:Destroy()
    print("🗑️ Alat Bantu Latihan dihapus — post tersimpan di " .. FILE_SAVE)
end)

--═════════ WIRING + HOTKEY ═════════
btnWall.MouseButton1Click:Connect(function() setEsp(not espOn) end)
btnPost.MouseButton1Click:Connect(placePost)
btnUndo.MouseButton1Click:Connect(undoPost)
btnBersihPost.MouseButton1Click:Connect(bersihkanPost)
btnRejoin.MouseButton1Click:Connect(rejoin)

addConn(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    local k = input.KeyCode
    if     k == Enum.KeyCode.F then main.Visible = not main.Visible
    elseif k == Enum.KeyCode.T then setEsp(not espOn)
    elseif k == Enum.KeyCode.G then placePost()
    elseif k == Enum.KeyCode.Z then undoPost()
    elseif k == Enum.KeyCode.X then bersihkanPost()
    elseif k == Enum.KeyCode.R then rejoin()
    end
end))

--═════════ 🖐️ DRAG (geser dari bar judul) ═════════
judul.Active = true
do
    local dragging, dragStart, startPos = false, nil, nil
    judul.InputBegan:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, main.Position
        end
    end)
    addConn(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local d = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    addConn(UserInputService.InputEnded:Connect(function(input)
        local t = input.UserInputType
        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

--═════════ START ═════════
muatPost()
print("✅ Alat Bantu Latihan v3.0 siap! F=GUI T=Dinding G=Post Z=Undo X=Hapus R=Rejoin")
