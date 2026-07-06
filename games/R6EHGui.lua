--// THECOOLEST HUB – EMOTE MINI-GAME (Grid + Search + Rounded)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Event = ReplicatedStorage:WaitForChild("Events"):WaitForChild("EmoteSyncNotifier")
local EmoteFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Emotes")

--// Collect emote names
local EmoteNames = {}
for _, config in ipairs(EmoteFolder:GetChildren()) do
    table.insert(EmoteNames, config.Name)
end

--// Create GUI
local gui = Instance.new("ScreenGui")
gui.Name = "EmoteHub"
gui.ResetOnSpawn = false
gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 450)
frame.Position = UDim2.new(0.5, -200, 0.5, -225)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 10)

--// Title bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.Text = "TheCoolest Custom R6EH Gui!"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

local titleCorner = Instance.new("UICorner", title)
titleCorner.CornerRadius = UDim.new(0, 10)

--// Close button
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 35, 0, 35)
close.Position = UDim2.new(1, -35, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.Font = Enum.Font.GothamBold
close.TextSize = 18
close.Parent = frame

local closeCorner = Instance.new("UICorner", close)
closeCorner.CornerRadius = UDim.new(0, 10)

close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

--// Draggable logic
local UIS = game:GetService("UserInputService")
local dragging, dragStart, startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

--// Search bar
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -20, 0, 30)
searchBox.Position = UDim2.new(0, 10, 0, 45)
searchBox.PlaceholderText = "Search emote..."
searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 16
searchBox.Parent = frame

local searchCorner = Instance.new("UICorner", searchBox)
searchCorner.CornerRadius = UDim.new(0, 8)

--// Scrolling grid
local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -20, 1, -120)
list.Position = UDim2.new(0, 10, 0, 80)
list.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#EmoteNames / 2) * 40)
list.ScrollBarThickness = 6
list.BackgroundTransparency = 1
list.Parent = frame

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0.5, -5, 0, 35)
grid.CellPadding = UDim2.new(0, 5, 0, 5)
grid.Parent = list

--// Create emote buttons
local buttons = {}

local function createButtons(filter)
    for _, btn in ipairs(buttons) do
        btn:Destroy()
    end
    buttons = {}

    for _, emoteName in ipairs(EmoteNames) do
        if filter == "" or string.find(string.lower(emoteName), string.lower(filter)) then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 0, 0, 35)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Text = emoteName
            btn.Parent = list

            local btnCorner = Instance.new("UICorner", btn)
            btnCorner.CornerRadius = UDim.new(0, 6)

            btn.MouseButton1Click:Connect(function()
                Event:FireServer("PlayEmote", emoteName)
            end)

            table.insert(buttons, btn)
        end
    end
end

createButtons("")

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    createButtons(searchBox.Text)
end)

--// Stop button
local stop = Instance.new("TextButton")
stop.Size = UDim2.new(1, -20, 0, 40)
stop.Position = UDim2.new(0, 10, 1, -45)
stop.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
stop.TextColor3 = Color3.fromRGB(255, 255, 255)
stop.Font = Enum.Font.GothamBold
stop.TextSize = 18
stop.Text = "STOP EMOTE"
stop.Parent = frame

local stopCorner = Instance.new("UICorner", stop)
stopCorner.CornerRadius = UDim.new(0, 10)

stop.MouseButton1Click:Connect(function()
    Event:FireServer("PlayEmote", "")
end)
