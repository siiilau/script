--========================================================
-- UI STRUCTURE + THEME ONLY
--========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================================================
-- [1] THEME
--========================================================
local Theme = {
    Purple = Color3.fromRGB(124, 58, 237),
    PurpleLight = Color3.fromRGB(167, 139, 250),
    PurplePale = Color3.fromRGB(237, 233, 254),
    Blue = Color3.fromRGB(37, 99, 235),
    BlueLight = Color3.fromRGB(59, 130, 246),
    BluePale = Color3.fromRGB(219, 234, 254),
    Black = Color3.fromRGB(12, 10, 20),
    BlackSoft = Color3.fromRGB(22, 18, 38),
    White = Color3.fromRGB(255, 255, 255),
    WhiteSoft = Color3.fromRGB(250, 250, 255),
    GrayPale = Color3.fromRGB(243, 242, 250),
    GrayItem = Color3.fromRGB(246, 245, 252),
    GrayText = Color3.fromRGB(130, 125, 155),
    GrayDark = Color3.fromRGB(72, 72, 94),
    TextDark = Color3.fromRGB(28, 24, 46),
    Green = Color3.fromRGB(34, 197, 94),
    Red = Color3.fromRGB(239, 68, 68),
    Yellow = Color3.fromRGB(250, 204, 21),
}

local CONFIG = {
    Title = "⚡ BALAP UI ⚡",
    Width = 360,
    Height = 620,
    ToggleKey = Enum.KeyCode.G,
}

--========================================================
-- [2] HELPERS
--========================================================
local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
    }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Color = color or Theme.Purple,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    }, parent)
end

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        properties
    )
    animation:Play()
    return animation
end

local function addPadding(parent, left, right, top, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    }, parent)
end

local function addGradient(parent, colorA, colorB, rotation)
    return create("UIGradient", {
        Color = ColorSequence.new(colorA, colorB),
        Rotation = rotation or 0,
    }, parent)
end

--========================================================
-- [3] ROOT SCREEN GUI
--========================================================
local oldGui = PlayerGui:FindFirstChild("BalapStructureTheme")
if oldGui then
    oldGui:Destroy()
end

local screenGui = create("ScreenGui", {
    Name = "BalapStructureTheme",
    ResetOnSpawn = false,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

local root = create("Frame", {
    Name = "Root",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0.08, 0),
    Size = UDim2.fromOffset(CONFIG.Width, CONFIG.Height),
    BackgroundTransparency = 1,
}, screenGui)

local scale = create("UIScale", { Scale = 1 }, root)

local function fitPanel()
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize
    if not viewport or viewport.X <= 0 or viewport.Y <= 0 then
        return
    end

    local widthScale = (viewport.X - 20) / CONFIG.Width
    local heightScale = (viewport.Y * 0.9) / CONFIG.Height
    scale.Scale = math.clamp(math.min(widthScale, heightScale), 0.45, 1.2)
end

if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitPanel)
end
fitPanel()

--========================================================
-- [4] OUTER PANEL + HEADER
--========================================================
local outer = create("Frame", {
    Name = "Outer",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Theme.Black,
    BorderSizePixel = 0,
}, root)
corner(outer, 16)
local outerStroke = stroke(outer, Theme.Purple, 3, 0.1)
addGradient(outerStroke, Theme.Purple, Theme.BlueLight, 45)

local panel = create("Frame", {
    Name = "Panel",
    Position = UDim2.fromOffset(5, 5),
    Size = UDim2.new(1, -10, 1, -10),
    BackgroundColor3 = Theme.WhiteSoft,
    BorderSizePixel = 0,
}, outer)
corner(panel, 12)
stroke(panel, Theme.PurplePale, 1, 0.25)

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 48),
    BackgroundColor3 = Theme.BlackSoft,
    BorderSizePixel = 0,
    Active = true,
}, panel)
corner(header, 11)

create("Frame", {
    Name = "HeaderBottomFill",
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    BackgroundColor3 = Theme.BlackSoft,
    BorderSizePixel = 0,
}, panel)

local title = create("TextLabel", {
    Name = "Title",
    Position = UDim2.fromOffset(14, 0),
    Size = UDim2.new(1, -95, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = CONFIG.Title,
    TextColor3 = Theme.White,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local minimizeButton = create("TextButton", {
    Name = "MinimizeButton",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = Theme.Black,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    Text = "–",
    TextColor3 = Theme.White,
    TextSize = 18,
}, header)
corner(minimizeButton, 8)
stroke(minimizeButton, Theme.Purple, 1, 0.2)

local accent = create("Frame", {
    Name = "Accent",
    Position = UDim2.new(0, 0, 0, 48),
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = Theme.Purple,
    BorderSizePixel = 0,
}, panel)
addGradient(accent, Theme.Blue, Theme.PurpleLight, 0)

--========================================================
-- [5] TAB BAR
--========================================================
local tabBar = create("Frame", {
    Name = "TabBar",
    Position = UDim2.new(0, 8, 0, 58),
    Size = UDim2.new(1, -16, 0, 30),
    BackgroundTransparency = 1,
}, panel)

create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    Padding = UDim.new(0, 4),
}, tabBar)

local tabNames = {
    "MOVEMENT",
    "ANIMASI",
    "EMOTE",
    "TITIK",
    "SYSTEM",
}

local tabButtons = {}
local tabContents = {}
local activeTab = 1

local function createTabButton(name, index)
    local button = create("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(0.2, -4, 1, 0),
        BackgroundColor3 = index == 1 and Theme.PurpleLight or Theme.GrayPale,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = index == 1 and Theme.White or Theme.GrayText,
        TextScaled = true,
    }, tabBar)
    corner(button, 6)
    create("UITextSizeConstraint", { MaxTextSize = 10 }, button)
    tabButtons[index] = button
    return button
end

for index, name in ipairs(tabNames) do
    createTabButton(name, index)
end

local contentArea = create("Frame", {
    Name = "ContentArea",
    Position = UDim2.new(0, 10, 0, 94),
    Size = UDim2.new(1, -20, 1, -137),
    BackgroundTransparency = 1,
}, panel)

--========================================================
-- [6] GENERIC UI COMPONENTS
--========================================================
local function createSectionHeader(parent, text, order)
    return create("TextLabel", {
        LayoutOrder = order or 1,
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "▎" .. string.upper(text),
        TextColor3 = Theme.Purple,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function createToggle(parent, label, key, order)
    local row = create("Frame", {
        LayoutOrder = order or 1,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.GrayItem,
        BorderSizePixel = 0,
    }, parent)
    corner(row, 8)

    create("TextLabel", {
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -110, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = label,
        TextColor3 = Theme.TextDark,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    if key then
        local chip = create("TextLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -55, 0.5, 0),
            Size = UDim2.fromOffset(math.max(25, #key * 8 + 12), 21),
            BackgroundColor3 = Theme.BlackSoft,
            Font = Enum.Font.GothamBold,
            Text = key,
            TextColor3 = Theme.GrayText,
            TextSize = 11,
        }, row)
        corner(chip, 6)
    end

    local switch = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(38, 20),
        BackgroundColor3 = Theme.GrayDark,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
    }, row)
    corner(switch, 10)

    local knob = create("Frame", {
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
    }, switch)
    corner(knob, 10)

    switch.MouseButton1Click:Connect(function()
        -- Placeholder: hanya animasi visual, tidak menjalankan fitur apa pun.
        local on = switch.BackgroundColor3 == Theme.GrayDark
        switch.BackgroundColor3 = on and Theme.Green or Theme.GrayDark
        tween(knob, 0.15, {
            Position = on and UDim2.new(1, -17, 0, 3) or UDim2.fromOffset(3, 3),
        })
    end)

    return row
end

local function createActionButton(parent, text, color, order)
    local button = create("TextButton", {
        LayoutOrder = order or 1,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = color or Theme.Purple,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamBold,
        Text = text,
        TextColor3 = Theme.White,
        TextSize = 12,
    }, parent)
    corner(button, 8)
    button.MouseEnter:Connect(function()
        tween(button, 0.12, { BackgroundColor3 = Theme.BlueLight })
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.12, { BackgroundColor3 = color or Theme.Purple })
    end)
    button.MouseButton1Click:Connect(function()
        -- Placeholder visual saja.
        tween(button, 0.08, { Size = UDim2.new(1, -4, 0, 30) })
        task.delay(0.1, function()
            if button.Parent then
                tween(button, 0.12, { Size = UDim2.new(1, 0, 0, 32) })
            end
        end)
    end)
    return button
end

local function createPlaceholderPage(name, sections)
    local page = create("ScrollingFrame", {
        Name = name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Purple,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, contentArea)

    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    addPadding(page, 2, 2, 2, 8)

    local order = 0
    for _, section in ipairs(sections) do
        order += 1
        createSectionHeader(page, section.title, order)
        for _, item in ipairs(section.items or {}) do
            order += 1
            if item.kind == "toggle" then
                createToggle(page, item.text, item.key, order)
            elseif item.kind == "action" then
                createActionButton(page, item.text, item.color, order)
            else
                create("TextLabel", {
                    LayoutOrder = order,
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3 = Theme.GrayItem,
                    Font = Enum.Font.Gotham,
                    Text = item.text or "Placeholder",
                    TextColor3 = Theme.GrayText,
                    TextSize = 11,
                }, page)
            end
        end
    end

    tabContents[#tabContents + 1] = page
    return page
end

--========================================================
-- [7] TAB CONTENT: STRUCTURE ONLY
--========================================================
createPlaceholderPage("Movement", {
    { title = "PLAYER", items = {
        { kind = "toggle", text = "Speed", key = "Q" },
        { kind = "toggle", text = "JumpPower", key = "J" },
        { kind = "toggle", text = "Shiftlock Mobile", key = "C" },
        { kind = "toggle", text = "Shiftlock Tengah", key = "SHIFT" },
        { kind = "toggle", text = "Moonwalk", key = "F" },
    }},
    { title = "VISUAL", items = {
        { kind = "toggle", text = "Hide Player + Kendaraan", key = "R" },
        { kind = "toggle", text = "Hide Badan Atas", key = "Z" },
        { kind = "toggle", text = "Cahaya Auto", key = "T" },
    }},
    { title = "MAP", items = {
        { kind = "toggle", text = "Dinding Batas", key = "X" },
        { kind = "toggle", text = "Partikel / Bayangan / Efek", key = nil },
    }},
})

createPlaceholderPage("Animasi", {
    { title = "GAYA GERAK", items = {
        { kind = "toggle", text = "Animasi Kustom (master)", key = nil },
        { kind = "label", text = "IDLE     ASLI" },
        { kind = "label", text = "JALAN    ASLI" },
        { kind = "label", text = "LARI     ASLI" },
        { kind = "label", text = "LOMPAT   ASLI" },
        { kind = "label", text = "JATUH    ASLI" },
    }},
    { title = "AKSI", items = {
        { kind = "action", text = "↺ RESET SEMUA → ANIMASI ASLI", color = Theme.Red },
        { kind = "action", text = "🔄 RESET BASELINE", color = Theme.Blue },
    }},
})

createPlaceholderPage("Emote", {
    { title = "EMOTE CATALOG", items = {
        { kind = "label", text = "Cari emote..." },
        { kind = "action", text = "☆ FAVORIT SAJA", color = Theme.GrayDark },
        { kind = "action", text = "↻ LOOP: OFF", color = Theme.GrayDark },
        { kind = "label", text = "★ FAVORIT" },
        { kind = "label", text = "Baby Dance" },
        { kind = "label", text = "Beckon" },
        { kind = "label", text = "Dolphin Dance" },
        { kind = "label", text = "Fashion Spin" },
        { kind = "label", text = "Salute" },
    }},
})

createPlaceholderPage("Titik", {
    { title = "TITIK LOKAL", items = {
        { kind = "label", text = "Titik tersimpan: 0" },
        { kind = "action", text = "📍 MODE CTRL + KLIK: OFF", color = Theme.Green },
        { kind = "action", text = "➕ TAMBAH DARI POSISI SAYA", color = Theme.Blue },
        { kind = "action", text = "● TAMPILKAN / SEMBUNYIKAN", color = Theme.Purple },
        { kind = "action", text = "🗑 HAPUS SEMUA TITIK", color = Theme.Red },
        { kind = "action", text = "↻ URUTKAN TIANG TERDEKAT", color = Theme.Blue },
    }},
})

createPlaceholderPage("System", {
    { title = "INFO", items = {
        { kind = "label", text = "⚡ BALAP UI — STRUCTURE ONLY" },
        { kind = "label", text = "User: " .. LocalPlayer.Name },
        { kind = "label", text = "Device: GUI Preview" },
        { kind = "label", text = "Status: fitur belum dipasang" },
    }},
    { title = "AKSI", items = {
        { kind = "action", text = "🔁 REJOIN SERVER [PLACEHOLDER]", color = Theme.Blue },
        { kind = "action", text = "🗑️ HAPUS SCRIPT", color = Theme.Red },
    }},
})

--========================================================
-- [8] FOOTER
--========================================================
local footer = create("Frame", {
    Name = "Footer",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Theme.BlackSoft,
    BorderSizePixel = 0,
}, panel)
corner(footer, 10)

create("TextLabel", {
    Size = UDim2.fromScale(1, 0.55),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "⚡ B A L A P ⚡",
    TextColor3 = Theme.White,
    TextSize = 14,
}, footer)

create("TextLabel", {
    Position = UDim2.new(0, 0, 0.52, 0),
    Size = UDim2.new(1, 0, 0.48, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "G = buka/tutup GUI  •  UI STRUCTURE ONLY",
    TextColor3 = Theme.GrayText,
    TextSize = 9,
}, footer)

--========================================================
-- [9] TAB LOGIC + WINDOW CONTROL
--========================================================
local function selectTab(index)
    activeTab = index
    for i, button in ipairs(tabButtons) do
        local active = i == index
        button.BackgroundColor3 = active and Theme.PurpleLight or Theme.GrayPale
        button.TextColor3 = active and Theme.White or Theme.GrayText
    end
    for i, page in ipairs(tabContents) do
        page.Visible = i == index
    end
end

for index, button in ipairs(tabButtons) do
    button.MouseButton1Click:Connect(function()
        selectTab(index)
    end)
end

local minimized = false
minimizeButton.MouseButton1Click:Connect(function()
    minimized = true
    root.Visible = false
end)

local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = root.Position
    end
end)

header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart
    root.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if UserInputService:GetFocusedTextBox() then return end

    if input.KeyCode == CONFIG.ToggleKey then
        root.Visible = not root.Visible
        minimized = not root.Visible
    end
end)

selectTab(1)
root.Visible = true

print("[BALAP UI] Structure + theme loaded. Semua fitur masih placeholder.")
