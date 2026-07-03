-- 1: 72165087146441
local placeId = game.PlaceId
local universeId = game.GameId

if placeId == 72165087146441 or universeId == 72165087146441 then
  loadstring(game:HttpGet("https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/games/Easy-Fun-Obby-575-Stages.lua"))()
elseif placeId == 17732590459 or universeId == 17732590459 then
  loadstring(game:HttpGet("https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/games/macobby.lua"))()
elseif placeId == 3571215756 or universeId == 3571215756 then
  loadstring(game:HttpGet("https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/games/housetycoon1.lua"))()
elseif placeId == 107645101488133 or universeId == 107645101488133 then
  loadstring(game:HttpGet("https://github.com/Zombiegoblin4/TheCoolestHubRBLX/raw/refs/heads/main/games/needohTowerW1.lua"))()
else
    -- Make ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "UnsupportedGameUI"
    gui.ResetOnSpawn = false
    gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Main frame
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Unsupported Game"
    title.TextColor3 = Color3.fromRGB(255, 80, 80)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    -- Description
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -20, 0, 50)
    desc.Position = UDim2.new(0, 10, 0, 45)
    desc.BackgroundTransparency = 1
    desc.Text = "This game is not supported by TheCoolest Hub."
    desc.TextColor3 = Color3.fromRGB(220, 220, 220)
    desc.TextScaled = true
    desc.Font = Enum.Font.Gotham
    desc.Parent = frame

    -- OK Button
    local ok = Instance.new("TextButton")
    ok.Size = UDim2.new(0, 120, 0, 35)
    ok.Position = UDim2.new(0.5, -60, 1, -45)
    ok.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ok.Text = "OK"
    ok.TextColor3 = Color3.fromRGB(255, 255, 255)
    ok.TextScaled = true
    ok.Font = Enum.Font.GothamBold
    ok.Parent = frame

    ok.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
end
