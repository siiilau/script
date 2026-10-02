--[[
    TELEPORT + FREE CAM TP (EXECUTOR)
    ─────────────────────────────────
    TAB 1 📍 LOKASI
      - Simpan posisi karakter + nama
      - Klik nama di daftar = teleport ke sana
      - Tersimpan di file lokal (per game), tidak hilang

    TAB 2 🎥 FREE CAM
      - Aktifkan toggle, terbang pakai free cam script kamu
      - Tekan [C] → karakter LANGSUNG teleport ke belakang kamera
      - Jarak di belakang kamera bisa diatur

    Tekan [F] = buka/tutup GUI
]]

local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Ganti tombol di sini kalau bentrok sama skill game
local TOGGLE_KEY  = Enum.KeyCode.F -- buka/tutup GUI
local FREECAM_KEY = Enum.KeyCode.C -- teleport ke kamera

-- Jarak karakter di belakang kamera (studs) — bisa diubah lewat GUI
local BEHIND_DISTANCE = 4

-- ========== FILE PENYIMPANAN ==========
local FOLDER = "TeleportSave"
local FILE   = FOLDER .. "/" .. tostring(game.PlaceId) .. ".json"

if not isfolder(FOLDER) then makefolder(FOLDER) end

local locations = {}

if isfile(FILE) then
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(FILE))
    end)
    if ok and type(data) == "table" then
        locations = data
    end
end

local function saveLocations()
    writefile(FILE, HttpService:JSONEncode(locations))
end

-- ========== HELPER ==========
local function getRoot()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getYaw(cf)
    local look = cf.LookVector
    return math.atan2(-look.X, -look.Z)
end

-- Teleport karakter ke sedikit di belakang kamera (khusus free cam)
local function teleportToCamera()
    local root = getRoot()
    local cam = workspace.CurrentCamera
    if not root or not cam then return false end

    local cf = cam.CFrame

    -- Arah "maju" kamera tapi datar (tanpa pitch), biar mundurnya horizontal
    local look = cf.LookVector
    local flat = Vector3.new(look.X, 0, look.Z)
    flat = (flat.Magnitude > 0.01) and flat.Unit or Vector3.new(0, 0, -1)

    -- Posisi = posisi kamera digeser ke belakang sejauh BEHIND_DISTANCE
    local pos = cf.Position - flat * BEHIND_DISTANCE

    root.CFrame = CFrame.new(pos) * CFrame.Angles(0, getYaw(cf), 0)
    return true
end

local function teleportTo(point)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(point.X, point.Y, point.Z)
    end
end

-- ========== GUI ==========
local parent = (gethui and gethui()) or game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "TeleportExecGui"
gui.ResetOnSpawn = false
gui.Parent = parent

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 380)
main.Position = UDim2.new(0, 20, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -35, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "📍 TELEPORT"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -28, 0, 4)
minimizeBtn.Text = "—"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 85)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 14
minimizeBtn.Parent = titleBar
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

-- ========== TAB ==========
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1, -20, 0, 28)
tabFrame.Position = UDim2.new(0, 10, 0, 40)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = main

local tab1Btn = Instance.new("TextButton")
tab1Btn.Size = UDim2.new(0.5, -4, 1, 0)
tab1Btn.Position = UDim2.new(0, 0, 0, 0)
tab1Btn.Text = "📍 Lokasi"
tab1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
tab1Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
tab1Btn.BorderSizePixel = 0
tab1Btn.Font = Enum.Font.GothamBold
tab1Btn.TextSize = 13
tab1Btn.Parent = tabFrame
Instance.new("UICorner", tab1Btn).CornerRadius = UDim.new(0, 6)

local tab2Btn = Instance.new("TextButton")
tab2Btn.Size = UDim2.new(0.5, -4, 1, 0)
tab2Btn.Position = UDim2.new(0.5, 4, 0, 0)
tab2Btn.Text = "🎥 Free Cam"
tab2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
tab2Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
tab2Btn.BorderSizePixel = 0
tab2Btn.Font = Enum.Font.GothamBold
tab2Btn.TextSize = 13
tab2Btn.Parent = tabFrame
Instance.new("UICorner", tab2Btn).CornerRadius = UDim.new(0, 6)

local page1 = Instance.new("Frame")
page1.Size = UDim2.new(1, -20, 1, -84)
page1.Position = UDim2.new(0, 10, 0, 74)
page1.BackgroundTransparency = 1
page1.Parent = main

local page2 = Instance.new("Frame")
page2.Size = UDim2.new(1, -20, 1, -84)
page2.Position = UDim2.new(0, 10, 0, 74)
page2.BackgroundTransparency = 1
page2.Visible = false
page2.Parent = main

local currentTab = 1
local function switchTab(tab)
    currentTab = tab
    page1.Visible = (tab == 1)
    page2.Visible = (tab == 2)
    tab1Btn.BackgroundColor3 = (tab == 1) and Color3.fromRGB(60, 60, 75) or Color3.fromRGB(35, 35, 42)
    tab2Btn.BackgroundColor3 = (tab == 2) and Color3.fromRGB(60, 60, 75) or Color3.fromRGB(35, 35, 42)
end

tab1Btn.MouseButton1Click:Connect(function() switchTab(1) end)
tab2Btn.MouseButton1Click:Connect(function() switchTab(2) end)

-- ========== TAB 1: LOKASI ==========
local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, 0, 0, 30)
nameBox.Position = UDim2.new(0, 0, 0, 0)
nameBox.PlaceholderText = "Nama lokasi..."
nameBox.Text = ""
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
nameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
nameBox.BorderSizePixel = 0
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 13
nameBox.ClearTextOnFocus = false
nameBox.Parent = page1
Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 6)

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, 0, 0, 28)
saveBtn.Position = UDim2.new(0, 0, 0, 36)
saveBtn.Text = "💾 SIMPAN POSISI SEKARANG"
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 75)
saveBtn.BorderSizePixel = 0
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 13
saveBtn.Parent = page1
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, 0, 1, -72)
listFrame.Position = UDim2.new(0, 0, 0, 70)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.Parent = page1

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = listFrame

local function refreshList()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for i, point in ipairs(locations) do
        local entry = Instance.new("Frame")
        entry.Size = UDim2.new(1, -6, 0, 28)
        entry.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        entry.BorderSizePixel = 0
        entry.Parent = listFrame
        Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)

        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(1, -30, 1, 0)
        tpBtn.BackgroundTransparency = 1
        tpBtn.Text = "⚡ " .. point.Name
        tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tpBtn.Font = Enum.Font.Gotham
        tpBtn.TextSize = 13
        tpBtn.TextXAlignment = Enum.TextXAlignment.Left
        tpBtn.TextTruncate = Enum.TextTruncate.AtEnd
        tpBtn.Parent = entry
        tpBtn.MouseButton1Click:Connect(function()
            teleportTo(point)
        end)

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 26, 1, 0)
        delBtn.Position = UDim2.new(1, -26, 0, 0)
        delBtn.BackgroundTransparency = 1
        delBtn.Text = "X"
        delBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 13
        delBtn.Parent = entry
        delBtn.MouseButton1Click:Connect(function()
            table.remove(locations, i)
            saveLocations()
            refreshList()
        end)
    end
end

local function saveCurrentPosition()
    local root = getRoot()
    if not root then return end

    local name = nameBox.Text
    if name == "" then
        name = "Titik " .. tostring(#locations + 1)
    end

    local pos = root.Position
    table.insert(locations, {
        Name = name,
        X = pos.X,
        Y = pos.Y,
        Z = pos.Z,
    })

    nameBox.Text = ""
    saveLocations()
    refreshList()
end

saveBtn.MouseButton1Click:Connect(saveCurrentPosition)
nameBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then saveCurrentPosition() end
end)

-- ========== TAB 2: FREE CAM ==========
local camTpEnabled = false

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, 0, 0, 44)
toggleBtn.Position = UDim2.new(0, 0, 0, 0)
toggleBtn.Text = "🎥 FREE CAM TP: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 60)
toggleBtn.BorderSizePixel = 0
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Parent = page2
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local tpNowBtn = Instance.new("TextButton")
tpNowBtn.Size = UDim2.new(1, 0, 0, 28)
tpNowBtn.Position = UDim2.new(0, 0, 0, 50)
tpNowBtn.Text = "⚡ TP Sekarang (sama dengan tekan C)"
tpNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpNowBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 140)
tpNowBtn.BorderSizePixel = 0
tpNowBtn.Font = Enum.Font.GothamBold
tpNowBtn.TextSize = 12
tpNowBtn.Parent = page2
Instance.new("UICorner", tpNowBtn).CornerRadius = UDim.new(0, 6)

-- ===== Pengaturan jarak di belakang kamera =====
local distRow = Instance.new("Frame")
distRow.Size = UDim2.new(1, 0, 0, 26)
distRow.Position = UDim2.new(0, 0, 0, 84)
distRow.BackgroundTransparency = 1
distRow.Parent = page2

local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(1, -60, 1, 0)
distLabel.BackgroundTransparency = 1
distLabel.Text = "↩ Jarak di belakang kamera:"
distLabel.TextColor3 = Color3.fromRGB(190, 190, 200)
distLabel.Font = Enum.Font.Gotham
distLabel.TextSize = 12
distLabel.TextXAlignment = Enum.TextXAlignment.Left
distLabel.Parent = distRow

local distBox = Instance.new("TextBox")
distBox.Size = UDim2.new(0, 50, 1, 0)
distBox.Position = UDim2.new(1, -50, 0, 0)
distBox.Text = tostring(BEHIND_DISTANCE)
distBox.PlaceholderText = "4"
distBox.TextColor3 = Color3.fromRGB(255, 255, 255)
distBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
distBox.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
distBox.BorderSizePixel = 0
distBox.Font = Enum.Font.GothamBold
distBox.TextSize = 13
distBox.ClearTextOnFocus = false
distBox.Parent = distRow
Instance.new("UICorner", distBox).CornerRadius = UDim.new(0, 6)

distBox.FocusLost:Connect(function()
    local n = tonumber(distBox.Text)
    if n then
        BEHIND_DISTANCE = math.clamp(n, 0, 100)
    end
    distBox.Text = tostring(BEHIND_DISTANCE)
end)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 1, -120)
infoLabel.Position = UDim2.new(0, 0, 0, 116)
infoLabel.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
infoLabel.BorderSizePixel = 0
infoLabel.TextColor3 = Color3.fromRGB(190, 190, 200)
infoLabel.TextSize = 12
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextWrapped = true
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Text = "  📋 CARA PAKAI\n  1. Nyalakan free cam script kamu\n  2. Aktifkan toggle FREE CAM TP\n  3. Terbang dengan kamera ke tujuan\n  4. Tekan [C] → karakter TP ke belakang kamera\n\n  Catatan:\n  • Karakter muncul sedikit di belakang layar\n  • Atur jaraknya di kotak \"Jarak\" (0-100)\n  • Karakter menghadap arah kamera\n  • Toggle OFF = tombol C kembali normal\n  • [F] = buka/tutup GUI ini"
infoLabel.Parent = page2
Instance.new("UICorner", infoLabel).CornerRadius = UDim.new(0, 6)

toggleBtn.MouseButton1Click:Connect(function()
    camTpEnabled = not camTpEnabled
    if camTpEnabled then
        toggleBtn.Text = "🎥 FREE CAM TP: ON (tekan C)"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 75)
    else
        toggleBtn.Text = "🎥 FREE CAM TP: OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(90, 60, 60)
    end
end)

tpNowBtn.MouseButton1Click:Connect(function()
    teleportToCamera()
end)

-- ========== KEYBIND (F = toggle GUI, C = TP kamera) ==========
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == TOGGLE_KEY then
        gui.Enabled = not gui.Enabled
    elseif input.KeyCode == FREECAM_KEY and camTpEnabled then
        teleportToCamera()
    end
end)

-- ========== DRAG GUI ==========
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ========== MINIMIZE ==========
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local show = not minimized
    tabFrame.Visible = show
    page1.Visible = show and (currentTab == 1)
    page2.Visible = show and (currentTab == 2)
    main.Size = minimized and UDim2.new(0, 260, 0, 34) or UDim2.new(0, 260, 0, 380)
end)

switchTab(1)
refreshList()
