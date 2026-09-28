--[[
    TELEPORT + SIMPAN LOKASI (EXECUTOR)
    - Lokasi disimpan ke file lokal, tidak hilang walau keluar game
    - Lokasi dipisah per game (per PlaceId)
    - Tekan RightShift untuk buka/tutup GUI
]]

local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

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

-- ========== KARAKTER & TELEPORT ==========
local function getRoot()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart", 5)
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
main.Size = UDim2.new(0, 260, 0, 330)
main.Position = UDim2.new(0, 20, 0.5, -165)
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

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, -20, 0, 30)
nameBox.Position = UDim2.new(0, 10, 0, 42)
nameBox.PlaceholderText = "Nama lokasi..."
nameBox.Text = ""
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
nameBox.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
nameBox.BorderSizePixel = 0
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 13
nameBox.ClearTextOnFocus = false
nameBox.Parent = main
Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 6)

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(1, -20, 0, 28)
saveBtn.Position = UDim2.new(0, 10, 0, 78)
saveBtn.Text = "💾 SIMPAN POSISI SEKARANG"
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 75)
saveBtn.BorderSizePixel = 0
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 13
saveBtn.Parent = main
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 6)

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, -20, 1, -122)
listFrame.Position = UDim2.new(0, 10, 0, 114)
listFrame.BackgroundTransparency = 1
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.Parent = main

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = listFrame

-- ========== DAFTAR LOKASI ==========
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

-- ========== SIMPAN POSISI ==========
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

-- ========== MINIMIZE & TOGGLE ==========
local minimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    nameBox.Visible = not minimized
    saveBtn.Visible = not minimized
    listFrame.Visible = not minimized
    main.Size = minimized and UDim2.new(0, 260, 0, 34) or UDim2.new(0, 260, 0, 330)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
    end
end)

refreshList()
