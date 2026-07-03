-- ============================================================
-- TheCoolestHub - Premium Roblox Luau Window UI Library
-- ============================================================
-- Usage:
--   local CoolGui = loadstring(game:HttpGet("YOUR_URL_HERE"))()
--   local Window = CoolGui:CreateWindow({ Name = "TheCoolestHub", Color = Color3.fromRGB(0, 140, 255) })
--   local Tab = Window:CreateTab("TabName")
--   local Section = Tab:CreateSection("SectionName")
--   Section:CreateToggle("Toggle Name", false, function(val) print(val) end)
--   Section:CreateSlider("Slider Name", 0, 100, 50, function(val) print(val) end)
--   Section:CreateButton("Button Name", function() print("Clicked!") end)
--   Section:CreateDropdown("Dropdown Name", {"Opt1","Opt2","Opt3"}, function(val) print(val) end)
--   Section:CreateKeybind("Keybind Name", Enum.KeyCode.E, function(key) print(key) end)
--   Section:CreateLabel("Label text here")
--   Section:CreateColorPicker("ColorPicker Name", Color3.fromRGB(255,0,0), function(col) print(col) end)
--   Section:CreateTextBox("TextBox Name", "Placeholder...", function(text) print(text) end)
--   Section:CreateTinyToggle("Compact Toggle", false, function(val) print(val) end)
--   Section:CreateParagraph("Title", "Body text here")
--   Section:CreateSeparator()
--   CoolGui:Notify("Title", "Message", 4)
--   CoolGui:CreateWatermark({ Text = "TheCoolestHub v1.0" })
--   CoolGui:QuickPrompt("Title", "Placeholder", function(text) print(text) end)
-- ============================================================

local TheCoolestHub = {}
TheCoolestHub.__index = TheCoolestHub
TheCoolestHub.Flags = {}
TheCoolestHub.Windows = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Theme Defaults
local Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    Topbar = Color3.fromRGB(28, 28, 35),
    TabBar = Color3.fromRGB(25, 25, 32),
    Tab = Color3.fromRGB(35, 35, 45),
    TabHover = Color3.fromRGB(45, 45, 58),
    TabActive = Color3.fromRGB(50, 50, 65),
    Section = Color3.fromRGB(30, 30, 38),
    Element = Color3.fromRGB(38, 38, 50),
    ElementHover = Color3.fromRGB(48, 48, 62),
    TextPrimary = Color3.fromRGB(230, 230, 240),
    TextSecondary = Color3.fromRGB(160, 160, 180),
    TextDisabled = Color3.fromRGB(100, 100, 120),
    Border = Color3.fromRGB(50, 50, 65),
    ToggleOff = Color3.fromRGB(60, 60, 75),
    SliderTrack = Color3.fromRGB(40, 40, 55),
    DropdownBg = Color3.fromRGB(35, 35, 48),
    DropdownHover = Color3.fromRGB(50, 50, 65),
    InputBg = Color3.fromRGB(32, 32, 42),
    Shadow = Color3.fromRGB(0, 0, 0),
}

-- Utility Functions
local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function Tween(object, properties, duration, style, direction)
    local tween = TweenService:Create(object, TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), properties)
    tween:Play()
    return tween
end

local function FormatNumber(num)
    if type(num) == "number" then
        if num == math.floor(num) then
            return tostring(math.floor(num))
        else
            return string.format("%.1f", num)
        end
    end
    return tostring(num)
end

local function Color3ToHex(color)
    return string.format("#%02X%02X%02X", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
end

local function HexToColor3(hex)
    hex = hex:gsub("#", "")
    if #hex >= 6 then
        return Color3.fromRGB(tonumber(hex:sub(1, 2), 16) or 0, tonumber(hex:sub(3, 4), 16) or 0, tonumber(hex:sub(5, 6), 16) or 0)
    end
    return Color3.fromRGB(255, 255, 255)
end

local function Create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            local ok, err = pcall(function() inst[k] = v end)
            if not ok and k ~= "ClipsDescendants" then
                warn("TheCoolestHub: Failed to set " .. tostring(k) .. " on " .. class .. ": " .. tostring(err))
            end
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = parent
    return corner
end

local function AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

-- ============================================================
-- NOTIFICATION SYSTEM
-- ============================================================
function TheCoolestHub:Notify(title, text, duration)
    duration = duration or 4

    local screenGui = Create("ScreenGui", { Name = "TCH_Notif_" .. tick(), DisplayOrder = 999, ResetOnSpawn = false }, CoreGui)

    local notifFrame = Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = Theme.Topbar,
        Size = UDim2.new(0, 320, 0, 70),
        Position = UDim2.new(1, -340, 1, -90),
        BorderSizePixel = 0,
    }, screenGui)
    AddCorner(notifFrame, 8)
    AddStroke(notifFrame, Theme.Border, 1)

    local accent = Create("Frame", {
        BackgroundColor3 = self._lastColor or Color3.fromRGB(0, 140, 255),
        Size = UDim2.new(0, 4, 0.85, 0),
        Position = UDim2.new(0, 0, 0.075, 0),
        BorderSizePixel = 0,
    }, notifFrame)
    AddCorner(accent, 8)

    Create("TextLabel", {
        Text = title or "TheCoolestHub",
        TextColor3 = Theme.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 16, 0, 10),
    }, notifFrame)

    Create("TextLabel", {
        Text = text or "",
        TextColor3 = Theme.TextSecondary,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 16, 0, 34),
        TextWrapped = true,
    }, notifFrame)

    Tween(notifFrame, { Position = UDim2.new(0.5, -160, 1, -90) }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.delay(duration, function()
        Tween(notifFrame, { Position = UDim2.new(1, 340, 1, -90) }, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.5, function()
            screenGui:Destroy()
        end)
    end)
end

-- ============================================================
-- WINDOW CREATION
-- ============================================================
function TheCoolestHub:CreateWindow(config)
    config = config or {}
    local windowName = config.Name or "TheCoolestHub"
    local accentColor = config.Color or Color3.fromRGB(0, 140, 255)
    local windowSize = config.Size or UDim2.new(0, 520, 0, 420)

    self._lastColor = accentColor

    local ScreenGui = Create("ScreenGui", {
        Name = "TheCoolestHub_" .. windowName,
        DisplayOrder = 100,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, CoreGui)

    -- Main Window Frame
    local WindowFrame = Create("Frame", {
        Name = "MainWindow",
        BackgroundColor3 = Theme.Background,
        Size = windowSize,
        Position = UDim2.new(0.5, -windowSize.X.Offset / 2, 0.5, -windowSize.Y.Offset / 2),
        BorderSizePixel = 0,
    }, ScreenGui)
    WindowFrame.ClipsDescendants = true
    AddCorner(WindowFrame, 10)
    AddStroke(WindowFrame, Theme.Border, 1)

    -- Shadow
    Create("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        ZIndex = 0,
    }, WindowFrame)

    -- Topbar
    local Topbar = Create("Frame", {
        Name = "Topbar",
        BackgroundColor3 = Theme.Topbar,
        Size = UDim2.new(1, 0, 0, 42),
        BorderSizePixel = 0,
        ZIndex = 5,
    }, WindowFrame)
    AddCorner(Topbar, 10)

    -- Fix bottom corners of topbar
    Create("Frame", {
        BackgroundColor3 = Theme.Topbar,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BorderSizePixel = 0,
        ZIndex = 4,
    }, Topbar)

    -- Accent line
    Create("Frame", {
        BackgroundColor3 = accentColor,
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 6,
    }, Topbar)

    -- Title
    Create("TextLabel", {
        Text = windowName,
        TextColor3 = Theme.TextPrimary,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    }, Topbar)

    -- Minimize Button
    local MinBtn = Create("TextButton", {
        Text = "\226\128\148",
        TextColor3 = Theme.TextSecondary,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -66, 0, 5),
        ZIndex = 7,
    }, Topbar)

    -- Close Button
    local CloseBtn = Create("TextButton", {
        Text = "\195\151",
        TextColor3 = Color3.fromRGB(255, 80, 80),
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(1, -32, 0, 5),
        ZIndex = 7,
    }, Topbar)

    MinBtn.MouseEnter:Connect(function() Tween(MinBtn, { TextColor3 = Theme.TextPrimary }, 0.2) end)
    MinBtn.MouseLeave:Connect(function() Tween(MinBtn, { TextColor3 = Theme.TextSecondary }, 0.2) end)
    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, { BackgroundTransparency = 0.85, BackgroundColor3 = Color3.fromRGB(255, 60, 60) }, 0.2) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, { BackgroundTransparency = 1 }, 0.2) end)

    -- Body
    local Body = Create("Frame", {
        Name = "Body",
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(1, 0, 1, -42),
        Position = UDim2.new(0, 0, 0, 42),
        BorderSizePixel = 0,
    }, WindowFrame)

    -- Left Tab Bar
    local TabBar = Create("Frame", {
        Name = "TabBar",
        BackgroundColor3 = Theme.TabBar,
        Size = UDim2.new(0, 130, 1, 0),
        BorderSizePixel = 0,
    }, Body)

    Create("Frame", {
        BackgroundColor3 = Theme.Border,
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BorderSizePixel = 0,
    }, TabBar)

    local TabLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, TabBar)

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    }, TabBar)

    -- Right content area
    local ContentFrame = Create("Frame", {
        Name = "Content",
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(1, -130, 1, 0),
        Position = UDim2.new(0, 130, 0, 0),
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, Body)

    -- Make draggable
    MakeDraggable(WindowFrame, Topbar)

    -- Minimize
    local isMinimized = false
    local contentSize = Body.Size
    MinBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            Tween(Body, { Size = UDim2.new(1, 0, 0, 0) }, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        else
            Tween(Body, { Size = contentSize }, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end)

    -- Window visibility state
    local isWindowOpen = true
    local ToggleBtn -- forward declare for closure access

    -- Circular toggle button (top-right of screen, always visible)
    ToggleBtn = Create("ImageButton", {
        Name = "TCH_Toggle",
        BackgroundColor3 = accentColor,
        BackgroundTransparency = 0.3,
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(1, -58, 0, 14),
        AnchorPoint = Vector2.new(0, 0),
        BorderSizePixel = 0,
        ZIndex = 200,
        Image = "rbxassetid://3926305904",
        ImageColor3 = Color3.fromRGB(255, 255, 255),
        ImageTransparency = 0,
        ScaleType = Enum.ScaleType.Fit,
    }, ScreenGui)
    AddCorner(ToggleBtn, 22)

    local ToggleGlow = Instance.new("UIStroke")
    ToggleGlow.Color = accentColor
    ToggleGlow.Thickness = 2
    ToggleGlow.Transparency = 0.3
    ToggleGlow.Parent = ToggleBtn

    local ToggleLabel = Create("TextLabel", {
        Text = "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 201,
    }, ToggleBtn)

    local function hideWindow()
        isWindowOpen = false
        Tween(WindowFrame, { Size = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        ToggleLabel.Text = windowName:sub(1, 1)
        Tween(ToggleBtn, { BackgroundTransparency = 0 }, 0.25)
        pcall(function() ToggleBtn.ImageTransparency = 1 end)
    end

    local function showWindow()
        isWindowOpen = true
        WindowFrame.Size = UDim2.new(0, 0, 0, 0)
        Tween(WindowFrame, { Size = windowSize }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        ToggleLabel.Text = ""
        Tween(ToggleBtn, { BackgroundTransparency = 0.3 }, 0.25)
        pcall(function() ToggleBtn.ImageTransparency = 0 end)
    end

    -- Close (hides window, toggle button stays)
    CloseBtn.MouseButton1Click:Connect(hideWindow)

    ToggleBtn.MouseEnter:Connect(function()
        Tween(ToggleBtn, { BackgroundTransparency = 0 }, 0.2)
    end)
    ToggleBtn.MouseLeave:Connect(function()
        if isWindowOpen then
            Tween(ToggleBtn, { BackgroundTransparency = 0.3 }, 0.2)
        end
    end)

    ToggleBtn.MouseButton1Click:Connect(function()
        if isWindowOpen then
            hideWindow()
        else
            showWindow()
        end
    end)

    -- Window State
    local windowData = {
        ScreenGui = ScreenGui,
        WindowFrame = WindowFrame,
        Body = Body,
        TabBar = TabBar,
        TabLayout = TabLayout,
        ContentFrame = ContentFrame,
        accentColor = accentColor,
        tabs = {},
        currentTab = nil,
        tabCount = 0,
    }

    table.insert(self.Windows, windowData)

    -- ============================================================
    -- TAB CREATION
    -- ============================================================
    function windowData:CreateTab(tabName)
        self.tabCount = self.tabCount + 1
        local tabIndex = self.tabCount

        local TabButton = Create("TextButton", {
            Name = "Tab_" .. tabName,
            Text = tabName,
            TextColor3 = Theme.TextSecondary,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            BackgroundColor3 = Theme.Tab,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 34),
            LayoutOrder = tabIndex,
            AutoButtonColor = false,
        }, self.TabBar)
        AddCorner(TabButton, 6)

        -- Active indicator
        local TabIndicator = Create("Frame", {
            BackgroundColor3 = self.accentColor,
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 3, 0.2, 0),
            BorderSizePixel = 0,
            Visible = false,
        }, TabButton)
        AddCorner(TabIndicator, 2)

        -- Tab content
        local TabContent = Create("Frame", {
            Name = "TabContent_" .. tabName,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            Visible = false,
            ClipsDescendants = true,
        }, self.ContentFrame)

        local TabScroll = Create("ScrollingFrame", {
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.TextSecondary,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = TabContent,
        })

        Create("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
        }, TabScroll)

        local ContentLayout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        }, TabScroll)

        TabButton.MouseEnter:Connect(function()
            if self.currentTab ~= TabContent then
                Tween(TabButton, { BackgroundColor3 = Theme.TabHover }, 0.2)
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if self.currentTab ~= TabContent then
                Tween(TabButton, { BackgroundColor3 = Theme.Tab }, 0.2)
            end
        end)

        local function selectTab()
            for _, tab in pairs(self.tabs) do
                Tween(tab.button, { BackgroundColor3 = Theme.Tab, TextColor3 = Theme.TextSecondary }, 0.25)
                tab.indicator.Visible = false
                tab.content.Visible = false
            end
            Tween(TabButton, { BackgroundColor3 = Theme.TabActive, TextColor3 = Theme.TextPrimary }, 0.25)
            TabIndicator.Visible = true
            TabContent.Visible = true
            self.currentTab = TabContent
        end

        TabButton.MouseButton1Click:Connect(selectTab)

        local tabData = {
            button = TabButton,
            indicator = TabIndicator,
            content = TabContent,
            scroll = TabScroll,
            layout = ContentLayout,
            sectionCount = 0,
        }

        table.insert(self.tabs, tabData)

        -- Auto-select first tab
        if #self.tabs == 1 then
            selectTab()
        end

        -- ============================================================
        -- SECTION CREATION
        -- ============================================================
        function tabData:CreateSection(sectionName)
            self.sectionCount = self.sectionCount + 1

            local SectionFrame = Create("Frame", {
                Name = "Section_" .. sectionName,
                BackgroundColor3 = Theme.Section,
                Size = UDim2.new(1, 0, 0, 28),
                BorderSizePixel = 0,
                LayoutOrder = self.sectionCount * 100,
            }, self.scroll)
            AddCorner(SectionFrame, 6)
            AddStroke(SectionFrame, Theme.Border, 0.5)

            Create("TextLabel", {
                Text = sectionName,
                TextColor3 = self.accentColor or Color3.fromRGB(0, 140, 255),
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -20, 0, 28),
                Position = UDim2.new(0, 12, 0, 0),
            }, SectionFrame)

            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
            }, SectionFrame)

            Create("UIPadding", {
                PaddingTop = UDim.new(0, 32),
                PaddingLeft = UDim.new(0, 4),
                PaddingRight = UDim.new(0, 4),
                PaddingBottom = UDim.new(0, 4),
            }, SectionFrame)

            local elementCount = 0
            local sectionAPI = {}

            -- ========================================================
            -- TOGGLE
            -- ========================================================
            function sectionAPI:CreateToggle(name, default, callback)
                elementCount = elementCount + 1
                TheCoolestHub.Flags[name] = default or false

                local ToggleFrame = Create("Frame", {
                    Name = "Toggle_" .. name,
                    BackgroundColor3 = Theme.Element,
                    Size = UDim2.new(1, 0, 0, 36),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                }, SectionFrame)
                AddCorner(ToggleFrame, 6)

                Create("TextLabel", {
                    Text = name,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -54, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                }, ToggleFrame)

                local ToggleOuter = Create("Frame", {
                    BackgroundColor3 = Theme.ToggleOff,
                    Size = UDim2.new(0, 38, 0, 20),
                    Position = UDim2.new(1, -46, 0.5, -10),
                    BorderSizePixel = 0,
                }, ToggleFrame)
                AddCorner(ToggleOuter, 10)

                local ToggleInner = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(180, 180, 190),
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 2, 0.5, -8),
                    BorderSizePixel = 0,
                }, ToggleOuter)
                AddCorner(ToggleInner, 8)

                local function setToggle(val)
                    TheCoolestHub.Flags[name] = val
                    if val then
                        Tween(ToggleOuter, { BackgroundColor3 = accentColor }, 0.25)
                        Tween(ToggleInner, { Position = UDim2.new(0, 20, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    else
                        Tween(ToggleOuter, { BackgroundColor3 = Theme.ToggleOff }, 0.25)
                        Tween(ToggleInner, { Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(180, 180, 190) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    end
                    if callback then task.spawn(callback, val) end
                end

                if default then
                    ToggleOuter.BackgroundColor3 = accentColor
                    ToggleInner.Position = UDim2.new(0, 20, 0.5, -8)
                    ToggleInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                end

                ToggleFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        setToggle(not TheCoolestHub.Flags[name])
                    end
                end)

                ToggleFrame.MouseEnter:Connect(function()
                    Tween(ToggleFrame, { BackgroundColor3 = Theme.ElementHover }, 0.2)
                end)
                ToggleFrame.MouseLeave:Connect(function()
                    Tween(ToggleFrame, { BackgroundColor3 = Theme.Element }, 0.2)
                end)

                return { Set = setToggle, Get = function() return TheCoolestHub.Flags[name] end }
            end

            -- ========================================================
            -- SLIDER
            -- ========================================================
            function sectionAPI:CreateSlider(name, min, max, default, callback)
                elementCount = elementCount + 1
                local currentValue = default or min
                TheCoolestHub.Flags[name] = currentValue

                local SliderFrame = Create("Frame", {
                    Name = "Slider_" .. name,
                    BackgroundColor3 = Theme.Element,
                    Size = UDim2.new(1, 0, 0, 52),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                }, SectionFrame)
                AddCorner(SliderFrame, 6)

                local SliderName = Create("TextLabel", {
                    Text = name,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.65, -8, 0, 20),
                    Position = UDim2.new(0, 12, 0, 6),
                }, SliderFrame)

                local SliderValue = Create("TextLabel", {
                    Text = FormatNumber(currentValue),
                    TextColor3 = accentColor,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.35, 0, 0, 20),
                    Position = UDim2.new(0.65, 0, 0, 6),
                }, SliderFrame)

                local SliderTrack = Create("Frame", {
                    BackgroundColor3 = Theme.SliderTrack,
                    Size = UDim2.new(1, -24, 0, 8),
                    Position = UDim2.new(0, 12, 0, 34),
                    BorderSizePixel = 0,
                }, SliderFrame)
                AddCorner(SliderTrack, 4)

                local SliderFill = Create("Frame", {
                    BackgroundColor3 = accentColor,
                    Size = UDim2.new(((default or min) - min) / (max - min), 0, 1, 0),
                    BorderSizePixel = 0,
                }, SliderTrack)
                AddCorner(SliderFill, 4)

                Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(1, -7, 0.5, -7),
                    BorderSizePixel = 0,
                    ZIndex = 3,
                    Name = "Handle",
                }, SliderFill)
                AddCorner(SliderFill.Handle, 7)

                local sliding = false

                local function updateSlider(input)
                    local relX = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
                    local value = min + (max - min) * relX
                    value = math.floor(value * 10) / 10
                    currentValue = value
                    TheCoolestHub.Flags[name] = value
                    SliderValue.Text = FormatNumber(value)
                    Tween(SliderFill, { Size = UDim2.new(relX, 0, 1, 0) }, 0.05)
                    if callback then task.spawn(callback, value) end
                end

                SliderTrack.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        updateSlider(input)
                    end
                end)

                SliderFill.Handle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input)
                    end
                end)

                SliderFrame.MouseEnter:Connect(function()
                    Tween(SliderFrame, { BackgroundColor3 = Theme.ElementHover }, 0.2)
                end)
                SliderFrame.MouseLeave:Connect(function()
                    Tween(SliderFrame, { BackgroundColor3 = Theme.Element }, 0.2)
                end)

                return {
                    Set = function(val)
                        currentValue = val
                        TheCoolestHub.Flags[name] = val
                        SliderValue.Text = FormatNumber(val)
                        Tween(SliderFill, { Size = UDim2.new(math.clamp((val - min) / (max - min), 0, 1), 0, 1, 0) }, 0.15)
                    end,
                    Get = function() return currentValue end
                }
            end

            -- ========================================================
            -- BUTTON
            -- ========================================================
            function sectionAPI:CreateButton(name, callback)
                elementCount = elementCount + 1

                local ButtonFrame = Create("TextButton", {
                    Name = "Button_" .. name,
                    Text = name,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    BackgroundColor3 = Theme.Element,
                    Size = UDim2.new(1, 0, 0, 34),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                    AutoButtonColor = false,
                }, SectionFrame)
                AddCorner(ButtonFrame, 6)
                AddStroke(ButtonFrame, accentColor, 1)

                ButtonFrame.MouseEnter:Connect(function()
                    Tween(ButtonFrame, { BackgroundColor3 = accentColor, TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.25)
                end)
                ButtonFrame.MouseLeave:Connect(function()
                    Tween(ButtonFrame, { BackgroundColor3 = Theme.Element, TextColor3 = Theme.TextPrimary }, 0.25)
                end)

                ButtonFrame.MouseButton1Click:Connect(function()
                    Tween(ButtonFrame, { BackgroundTransparency = 0.3 }, 0.1)
                    Tween(ButtonFrame, { BackgroundTransparency = 0 }, 0.15)
                    if callback then task.spawn(callback) end
                end)

                return ButtonFrame
            end

            -- ========================================================
            -- DROPDOWN / POPOUT
            -- ========================================================
            function sectionAPI:CreateDropdown(name, options, callback)
                elementCount = elementCount + 1
                TheCoolestHub.Flags[name] = nil
                local isOpen = false
                local maxVisible = 5

                local DropdownFrame = Create("Frame", {
                    Name = "Dropdown_" .. name,
                    BackgroundColor3 = Theme.Element,
                    Size = UDim2.new(1, 0, 0, 34),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                    ClipsDescendants = true,
                }, SectionFrame)
                AddCorner(DropdownFrame, 6)

                local DropdownLabel = Create("TextLabel", {
                    Text = name,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, DropdownFrame)

                local ArrowLabel = Create("TextLabel", {
                    Text = "\226\149\190",
                    TextColor3 = Theme.TextSecondary,
                    TextSize = 14,
                    Font = Enum.Font.GothamBold,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 26, 1, 0),
                    Position = UDim2.new(1, -26, 0, 0),
                }, DropdownFrame)

                local OptionsContainer = Create("Frame", {
                    Name = "Options",
                    BackgroundColor3 = Theme.DropdownBg,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 1, 2),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                }, DropdownFrame)
                AddCorner(OptionsContainer, 6)
                AddStroke(OptionsContainer, Theme.Border, 0.5)

                Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 1),
                }, OptionsContainer)

                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 2),
                    PaddingBottom = UDim.new(0, 2),
                }, OptionsContainer)

                local function buildOptions(opts)
                    for _, child in pairs(OptionsContainer:GetChildren()) do
                        if child:IsA("TextButton") then child:Destroy() end
                    end
                    for i, opt in ipairs(opts) do
                        local OptBtn = Create("TextButton", {
                            Text = opt,
                            TextColor3 = TheCoolestHub.Flags[name] == opt and accentColor or Theme.TextSecondary,
                            TextSize = 11,
                            Font = Enum.Font.Gotham,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 28),
                            LayoutOrder = i,
                            AutoButtonColor = false,
                        }, OptionsContainer)

                        OptBtn.MouseEnter:Connect(function()
                            Tween(OptBtn, { BackgroundTransparency = 0.7, TextColor3 = Theme.TextPrimary }, 0.15)
                        end)
                        OptBtn.MouseLeave:Connect(function()
                            if TheCoolestHub.Flags[name] ~= opt then
                                Tween(OptBtn, { BackgroundTransparency = 1, TextColor3 = Theme.TextSecondary }, 0.15)
                            end
                        end)

                        OptBtn.MouseButton1Click:Connect(function()
                            TheCoolestHub.Flags[name] = opt
                            DropdownLabel.Text = name .. ": " .. opt
                            DropdownLabel.TextColor3 = accentColor
                            for _, child in pairs(OptionsContainer:GetChildren()) do
                                if child:IsA("TextButton") then
                                    Tween(child, { TextColor3 = child.Text == opt and accentColor or Theme.TextSecondary }, 0.15)
                                end
                            end
                            isOpen = false
                            Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, 34) }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            Tween(OptionsContainer, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                            Tween(ArrowLabel, { Rotation = 0 }, 0.25)
                            if callback then task.spawn(callback, opt) end
                        end)
                    end
                end

                buildOptions(options)

                DropdownFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isOpen = not isOpen
                        if isOpen then
                            local visible = math.min(#options, maxVisible)
                            local dropHeight = visible * 28 + 4
                            Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, 34 + dropHeight) }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            Tween(OptionsContainer, { BackgroundTransparency = 0, Size = UDim2.new(1, -2, 0, dropHeight - 4) }, 0.25)
                            Tween(ArrowLabel, { Rotation = 180 }, 0.25)
                        else
                            Tween(DropdownFrame, { Size = UDim2.new(1, 0, 0, 34) }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            Tween(OptionsContainer, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                            Tween(ArrowLabel, { Rotation = 0 }, 0.25)
                        end
                    end
                end)

                DropdownFrame.MouseEnter:Connect(function()
                    Tween(DropdownFrame, { BackgroundColor3 = Theme.ElementHover }, 0.2)
                end)
                DropdownFrame.MouseLeave:Connect(function()
                    Tween(DropdownFrame, { BackgroundColor3 = Theme.Element }, 0.2)
                end)

                return {
                    Refresh = function(newOptions)
                        options = newOptions
                        buildOptions(newOptions)
                    end
                }
            end

            -- ========================================================
            -- KEYBIND
            -- ========================================================
            function sectionAPI:CreateKeybind(name, defaultKey, callback)
                elementCount = elementCount + 1
                local currentKey = defaultKey or Enum.KeyCode.None
                local isListening = false
                TheCoolestHub.Flags[name] = currentKey

                local KeybindFrame = Create("Frame", {
                    Name = "Keybind_" .. name,
                    BackgroundColor3 = Theme.Element,
                    Size = UDim2.new(1, 0, 0, 36),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                }, SectionFrame)
                AddCorner(KeybindFrame, 6)

                Create("TextLabel", {
                    Text = name,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -110, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                }, KeybindFrame)

                local KeyButton = Create("TextButton", {
                    Text = currentKey.Name == "None" and "..." or currentKey.Name,
                    TextColor3 = accentColor,
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    BackgroundColor3 = Theme.SliderTrack,
                    Size = UDim2.new(0, 90, 0, 24),
                    Position = UDim2.new(1, -100, 0.5, -12),
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                }, KeybindFrame)
                AddCorner(KeyButton, 5)

                KeyButton.MouseButton1Click:Connect(function()
                    isListening = not isListening
                    if isListening then
                        KeyButton.Text = "[ ... ]"
                        KeyButton.TextColor3 = Color3.fromRGB(255, 100, 100)
                    end
                end)

                UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then return end
                    if isListening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            isListening = false
                            currentKey = input.KeyCode
                            TheCoolestHub.Flags[name] = currentKey
                            KeyButton.Text = currentKey.Name
                            KeyButton.TextColor3 = accentColor
                            if callback then task.spawn(callback, currentKey) end
                        end
                    else
                        if input.KeyCode == currentKey and callback then
                            task.spawn(callback, currentKey)
                        end
                    end
                end)

                KeybindFrame.MouseEnter:Connect(function()
                    Tween(KeybindFrame, { BackgroundColor3 = Theme.ElementHover }, 0.2)
                end)
                KeybindFrame.MouseLeave:Connect(function()
                    Tween(KeybindFrame, { BackgroundColor3 = Theme.Element }, 0.2)
                end)

                return {
                    Set = function(key)
                        currentKey = key
                        TheCoolestHub.Flags[name] = key
                        KeyButton.Text = key.Name
                        KeyButton.TextColor3 = accentColor
                    end,
                    Get = function() return currentKey end
                }
            end

            -- ========================================================
            -- LABEL
            -- ========================================================
            function sectionAPI:CreateLabel(text)
                elementCount = elementCount + 1

                local LabelFrame = Create("Frame", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 24),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                }, SectionFrame)

                local LabelText = Create("TextLabel", {
                    Text = text,
                    TextColor3 = Theme.TextSecondary,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                    TextWrapped = true,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, LabelFrame)

                return { Set = function(newText) LabelText.Text = newText end }
            end

            -- ========================================================
            -- COLOR PICKER
            -- ========================================================
            function sectionAPI:CreateColorPicker(name, defaultColor, callback)
                elementCount = elementCount + 1
                local currentColor = defaultColor or Color3.fromRGB(255, 255, 255)
                TheCoolestHub.Flags[name] = currentColor
                local isOpen = false

                local CPFrame = Create("Frame", {
                    Name = "ColorPicker_" .. name,
                    BackgroundColor3 = Theme.Element,
                    Size = UDim2.new(1, 0, 0, 36),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                    ClipsDescendants = true,
                }, SectionFrame)
                AddCorner(CPFrame, 6)

                Create("TextLabel", {
                    Text = name,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -54, 1, 0),
                    Position = UDim2.new(0, 12, 0, 0),
                }, CPFrame)

                local ColorPreview = Create("Frame", {
                    BackgroundColor3 = currentColor,
                    Size = UDim2.new(0, 30, 0, 20),
                    Position = UDim2.new(1, -40, 0.5, -10),
                    BorderSizePixel = 0,
                }, CPFrame)
                AddCorner(ColorPreview, 5)
                AddStroke(ColorPreview, Theme.Border, 1)

                local CPDropdown = Create("Frame", {
                    BackgroundColor3 = Theme.DropdownBg,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 1, 2),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                }, CPFrame)
                AddCorner(CPDropdown, 6)
                AddStroke(CPDropdown, Theme.Border, 0.5)

                -- Hex input
                local HexInput = Create("TextBox", {
                    Text = Color3ToHex(currentColor),
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    PlaceholderText = "#RRGGBB",
                    PlaceholderColor3 = Theme.TextDisabled,
                    BackgroundColor3 = Theme.InputBg,
                    Size = UDim2.new(1, -20, 0, 26),
                    Position = UDim2.new(0, 10, 0, 8),
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                }, CPDropdown)
                AddCorner(HexInput, 5)

                -- RGB channel sliders
                local channels = {
                    { label = "R", color = Color3.fromRGB(255, 80, 80), offset = 42 },
                    { label = "G", color = Color3.fromRGB(80, 255, 80), offset = 64 },
                    { label = "B", color = Color3.fromRGB(80, 80, 255), offset = 86 },
                }

                local channelSliders = {}

                for _, ch in ipairs(channels) do
                    local row = Create("Frame", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -20, 0, 16),
                        Position = UDim2.new(0, 10, 0, ch.offset),
                    }, CPDropdown)

                    Create("TextLabel", {
                        Text = ch.label,
                        TextColor3 = ch.color,
                        TextSize = 10,
                        Font = Enum.Font.GothamBold,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 14, 1, 0),
                    }, row)

                    local track = Create("Frame", {
                        BackgroundColor3 = Theme.SliderTrack,
                        Size = UDim2.new(1, -52, 0, 8),
                        Position = UDim2.new(0, 18, 0.5, -4),
                        BorderSizePixel = 0,
                    }, row)
                    AddCorner(track, 4)

                    local fill = Create("Frame", {
                        BackgroundColor3 = ch.color,
                        Size = UDim2.new(0.5, 0, 1, 0),
                        BorderSizePixel = 0,
                    }, track)
                    AddCorner(fill, 4)

                    local valLbl = Create("TextLabel", {
                        Text = "128",
                        TextColor3 = Theme.TextPrimary,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 28, 1, 0),
                        Position = UDim2.new(1, -28, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Right,
                    }, row)

                    channelSliders[ch.label] = { track = track, fill = fill, valLbl = valLbl, sliding = false }
                end

                -- Set initial values
                local function syncSlidersToColor()
                    local r = math.floor(currentColor.R * 255)
                    local g = math.floor(currentColor.G * 255)
                    local b = math.floor(currentColor.B * 255)
                    channelSliders.R.fill.Size = UDim2.new(r / 255, 0, 1, 0)
                    channelSliders.R.valLbl.Text = tostring(r)
                    channelSliders.G.fill.Size = UDim2.new(g / 255, 0, 1, 0)
                    channelSliders.G.valLbl.Text = tostring(g)
                    channelSliders.B.fill.Size = UDim2.new(b / 255, 0, 1, 0)
                    channelSliders.B.valLbl.Text = tostring(b)
                end
                syncSlidersToColor()

                local function updateColorFromSliders()
                    local r = tonumber(channelSliders.R.valLbl.Text) or 0
                    local g = tonumber(channelSliders.G.valLbl.Text) or 0
                    local b = tonumber(channelSliders.B.valLbl.Text) or 0
                    currentColor = Color3.fromRGB(
                        math.clamp(r, 0, 255),
                        math.clamp(g, 0, 255),
                        math.clamp(b, 0, 255)
                    )
                    TheCoolestHub.Flags[name] = currentColor
                    ColorPreview.BackgroundColor3 = currentColor
                    HexInput.Text = Color3ToHex(currentColor)
                    if callback then task.spawn(callback, currentColor) end
                end

                -- Wire channel sliders
                for _, ch in ipairs(channels) do
                    local s = channelSliders[ch.label]
                    s.track.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            s.sliding = true
                            local rel = math.clamp((input.Position.X - s.track.AbsolutePosition.X) / s.track.AbsoluteSize.X, 0, 1)
                            local v = math.floor(rel * 255)
                            s.fill.Size = UDim2.new(rel, 0, 1, 0)
                            s.valLbl.Text = tostring(v)
                            updateColorFromSliders()
                        end
                    end)
                end

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        for _, ch in ipairs(channels) do
                            channelSliders[ch.label].sliding = false
                        end
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        for _, ch in ipairs(channels) do
                            local s = channelSliders[ch.label]
                            if s.sliding then
                                local rel = math.clamp((input.Position.X - s.track.AbsolutePosition.X) / s.track.AbsoluteSize.X, 0, 1)
                                local v = math.floor(rel * 255)
                                s.fill.Size = UDim2.new(rel, 0, 1, 0)
                                s.valLbl.Text = tostring(v)
                                updateColorFromSliders()
                            end
                        end
                    end
                end)

                HexInput.FocusLost:Connect(function()
                    local hex = HexInput.Text
                    if hex:sub(1, 1) == "#" then hex = hex:sub(2) end
                    if #hex == 6 then
                        currentColor = HexToColor3(hex)
                        TheCoolestHub.Flags[name] = currentColor
                        ColorPreview.BackgroundColor3 = currentColor
                        syncSlidersToColor()
                        if callback then task.spawn(callback, currentColor) end
                    end
                end)

                -- Toggle open/close
                CPFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        isOpen = not isOpen
                        if isOpen then
                            Tween(CPFrame, { Size = UDim2.new(1, 0, 0, 160) }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            Tween(CPDropdown, { BackgroundTransparency = 0, Size = UDim2.new(1, 0, 0, 118) }, 0.25)
                        else
                            Tween(CPFrame, { Size = UDim2.new(1, 0, 0, 36) }, 0.25)
                            Tween(CPDropdown, { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0) }, 0.2)
                        end
                    end
                end)

                CPFrame.MouseEnter:Connect(function() Tween(CPFrame, { BackgroundColor3 = Theme.ElementHover }, 0.2) end)
                CPFrame.MouseLeave:Connect(function() Tween(CPFrame, { BackgroundColor3 = Theme.Element }, 0.2) end)

                return {
                    Set = function(col)
                        currentColor = col
                        TheCoolestHub.Flags[name] = col
                        ColorPreview.BackgroundColor3 = col
                        HexInput.Text = Color3ToHex(col)
                        syncSlidersToColor()
                    end,
                    Get = function() return currentColor end
                }
            end

            -- ========================================================
            -- TEXT BOX
            -- ========================================================
            function sectionAPI:CreateTextBox(name, placeholder, callback)
                elementCount = elementCount + 1

                local TBFrame = Create("Frame", {
                    Name = "TextBox_" .. name,
                    BackgroundColor3 = Theme.Element,
                    Size = UDim2.new(1, 0, 0, 58),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                }, SectionFrame)
                AddCorner(TBFrame, 6)

                Create("TextLabel", {
                    Text = name,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -16, 0, 22),
                    Position = UDim2.new(0, 12, 0, 4),
                }, TBFrame)

                local InputBox = Create("TextBox", {
                    Text = "",
                    PlaceholderText = placeholder or "Type here...",
                    PlaceholderColor3 = Theme.TextDisabled,
                    TextColor3 = Theme.TextPrimary,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    BackgroundColor3 = Theme.InputBg,
                    Size = UDim2.new(1, -20, 0, 24),
                    Position = UDim2.new(0, 10, 0, 28),
                    BorderSizePixel = 0,
                    ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, TBFrame)
                AddCorner(InputBox, 5)
                AddStroke(InputBox, Theme.Border, 0.5)

                local inputPad = Create("UIPadding", {
                    PaddingLeft = UDim.new(0, 8),
                }, InputBox)

                InputBox.FocusLost:Connect(function(enter)
                    if enter and callback then task.spawn(callback, InputBox.Text) end
                end)

                InputBox.Focused:Connect(function()
                    Tween(InputBox, { BackgroundColor3 = Color3.fromRGB(42, 42, 58) }, 0.2)
                end)
                InputBox.FocusLost:Connect(function()
                    Tween(InputBox, { BackgroundColor3 = Theme.InputBg }, 0.2)
                end)

                TBFrame.MouseEnter:Connect(function() Tween(TBFrame, { BackgroundColor3 = Theme.ElementHover }, 0.2) end)
                TBFrame.MouseLeave:Connect(function() Tween(TBFrame, { BackgroundColor3 = Theme.Element }, 0.2) end)

                return {
                    Set = function(text) InputBox.Text = text end,
                    Get = function() return InputBox.Text end,
                    Clear = function() InputBox.Text = "" end
                }
            end

            -- ========================================================
            -- TINY TOGGLE (compact inline)
            -- ========================================================
            function sectionAPI:CreateTinyToggle(name, default, callback)
                elementCount = elementCount + 1
                TheCoolestHub.Flags["tiny_" .. name] = default or false

                local TTFrame = Create("Frame", {
                    Name = "TinyToggle_" .. name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 22),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                }, SectionFrame)

                Create("TextLabel", {
                    Text = name,
                    TextColor3 = Theme.TextSecondary,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -38, 1, 0),
                    Position = UDim2.new(0, 4, 0, 0),
                }, TTFrame)

                local TTDot = Create("Frame", {
                    BackgroundColor3 = Theme.ToggleOff,
                    Size = UDim2.new(0, 28, 0, 14),
                    Position = UDim2.new(1, -32, 0.5, -7),
                    BorderSizePixel = 0,
                }, TTFrame)
                AddCorner(TTDot, 7)

                local TTDotInner = Create("Frame", {
                    BackgroundColor3 = Color3.fromRGB(160, 160, 175),
                    Size = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(0, 2, 0.5, -5),
                    BorderSizePixel = 0,
                }, TTDot)
                AddCorner(TTDotInner, 5)

                local function setVal(val)
                    TheCoolestHub.Flags["tiny_" .. name] = val
                    if val then
                        Tween(TTDot, { BackgroundColor3 = accentColor }, 0.2)
                        Tween(TTDotInner, { Position = UDim2.new(0, 16, 0.5, -5), BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    else
                        Tween(TTDot, { BackgroundColor3 = Theme.ToggleOff }, 0.2)
                        Tween(TTDotInner, { Position = UDim2.new(0, 2, 0.5, -5), BackgroundColor3 = Color3.fromRGB(160, 160, 175) }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    end
                    if callback then task.spawn(callback, val) end
                end

                if default then
                    TTDot.BackgroundColor3 = accentColor
                    TTDotInner.Position = UDim2.new(0, 16, 0.5, -5)
                    TTDotInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                end

                TTFrame.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        setVal(not TheCoolestHub.Flags["tiny_" .. name])
                    end
                end)

                return { Set = setVal, Get = function() return TheCoolestHub.Flags["tiny_" .. name] end }
            end

            -- ========================================================
            -- SEPARATOR
            -- ========================================================
            function sectionAPI:CreateSeparator()
                elementCount = elementCount + 1
                Create("Frame", {
                    BackgroundColor3 = Theme.Border,
                    Size = UDim2.new(1, -8, 0, 1),
                    Position = UDim2.new(0, 4, 0, 0),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                    BackgroundTransparency = 0.5,
                }, SectionFrame)
            end

            -- ========================================================
            -- PARAGRAPH (multiline label)
            -- ========================================================
            function sectionAPI:CreateParagraph(title, text)
                elementCount = elementCount + 1

                local PFrame = Create("Frame", {
                    BackgroundColor3 = Theme.Element,
                    Size = UDim2.new(1, 0, 0, 0),
                    BorderSizePixel = 0,
                    LayoutOrder = elementCount,
                    AutomaticSize = Enum.AutomaticSize.Y,
                }, SectionFrame)
                AddCorner(PFrame, 6)

                Create("UIPadding", {
                    PaddingTop = UDim.new(0, 8),
                    PaddingBottom = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 12),
                    PaddingRight = UDim.new(0, 12),
                }, PFrame)

                if title and title ~= "" then
                    Create("TextLabel", {
                        Text = title,
                        TextColor3 = accentColor,
                        TextSize = 12,
                        Font = Enum.Font.GothamBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 16),
                    }, PFrame)
                end

                local PText = Create("TextLabel", {
                    Text = text or "",
                    TextColor3 = Theme.TextSecondary,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                }, PFrame)

                return { Set = function(newText) PText.Text = newText end }
            end

            return sectionAPI
        end

        return tabData
    end

    self:Notify("TheCoolestHub", "Loaded successfully!", 3)
    return windowData
end

-- ============================================================
-- WATERMARK
-- ============================================================
function TheCoolestHub:CreateWatermark(config)
    config = config or {}
    local text = config.Text or "TheCoolestHub v1.0"

    local Gui = Create("ScreenGui", { Name = "TCH_Watermark", DisplayOrder = 998, ResetOnSpawn = false }, CoreGui)

    local WMFrame = Create("Frame", {
        BackgroundColor3 = Theme.Topbar,
        Size = UDim2.new(0, 200, 0, 28),
        Position = UDim2.new(0, 10, 0, 10),
        BorderSizePixel = 0,
    }, Gui)
    AddCorner(WMFrame, 6)
    AddStroke(WMFrame, Theme.Border, 1)

    Create("TextLabel", {
        Text = text,
        TextColor3 = Theme.TextPrimary,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, WMFrame)

    return WMFrame
end

-- ============================================================
-- QUICK PROMPT (modal dialog)
-- ============================================================
function TheCoolestHub:QuickPrompt(title, placeholder, callback)
    local Gui = Create("ScreenGui", { Name = "TCH_QuickPrompt", DisplayOrder = 997, ResetOnSpawn = false }, CoreGui)

    local Blur = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, 0, 1, 0),
    }, Gui)

    local Prompt = Create("Frame", {
        BackgroundColor3 = Theme.Background,
        Size = UDim2.new(0, 350, 0, 160),
        Position = UDim2.new(0.5, -175, 0.5, -80),
        BorderSizePixel = 0,
    }, Gui)
    AddCorner(Prompt, 10)
    AddStroke(Prompt, Theme.Border, 1)

    Create("TextLabel", {
        Text = title or "Prompt",
        TextColor3 = Theme.TextPrimary,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 12),
    }, Prompt)

    local PInput = Create("TextBox", {
        Text = "",
        PlaceholderText = placeholder or "Enter value...",
        PlaceholderColor3 = Theme.TextDisabled,
        TextColor3 = Theme.TextPrimary,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        BackgroundColor3 = Theme.InputBg,
        Size = UDim2.new(1, -32, 0, 36),
        Position = UDim2.new(0, 16, 0, 52),
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    }, Prompt)
    AddCorner(PInput, 6)

    local PSubmit = Create("TextButton", {
        Text = "Submit",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        BackgroundColor3 = self._lastColor or Color3.fromRGB(0, 140, 255),
        Size = UDim2.new(1, -32, 0, 32),
        Position = UDim2.new(0, 16, 0, 100),
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, Prompt)
    AddCorner(PSubmit, 6)

    local function closePrompt()
        Tween(Prompt, { BackgroundTransparency = 1 }, 0.2)
        Tween(Blur, { BackgroundTransparency = 1 }, 0.2)
        task.delay(0.25, function() Gui:Destroy() end)
    end

    PSubmit.MouseButton1Click:Connect(function()
        if callback then task.spawn(callback, PInput.Text) end
        closePrompt()
    end)

    Blur.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            closePrompt()
        end
    end)

    return { Gui = Gui, Input = PInput }
end

return TheCoolestHub
