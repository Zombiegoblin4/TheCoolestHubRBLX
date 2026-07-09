-- Game + Platform Detection
local placeId = game.PlaceId
local universeId = game.GameId

local UIS = game:GetService("UserInputService")
local isPC = UIS.KeyboardEnabled
local isMobile = UIS.TouchEnabled

-- Helper: load correct script
local function loadGame(pcURL, mobileURL)
    if isPC then
        loadstring(game:HttpGet(pcURL))()
    elseif isMobile then
        loadstring(game:HttpGet(mobileURL))()
    else
        loadstring(game:HttpGet(pcURL))() -- fallback
    end
end

-- GAME ROUTER
if placeId == 72165087146441 or universeId == 72165087146441 then
    loadGame(
        "https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/games/Easy-Fun-Obby-575-Stages.lua",
        "https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/mobileGames/Easy-Fun-Obby-575-Stages.lua"
    )

elseif placeId == 17732590459 or universeId == 17732590459 then
    loadGame(
        "https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/games/macobby.lua",
        "https://github.com/Zombiegoblin4/TheCoolestHubRBLX/raw/refs/heads/main/mobileGames/macobby1.lua"
    )

elseif placeId == 3571215756 or universeId == 3571215756 then
    loadGame(
        "https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/games/housetycoon1.lua",
        "https://github.com/Zombiegoblin4/TheCoolestHubRBLX/raw/refs/heads/main/mobileGames/housetycoon1.lua"
    )

elseif placeId == 107645101488133 or universeId == 107645101488133 then
    loadGame(
        "https://github.com/Zombiegoblin4/TheCoolestHubRBLX/raw/refs/heads/main/games/needohTowerW1.lua",
        "https://github.com/Zombiegoblin4/TheCoolestHubRBLX/raw/refs/heads/main/mobileGames/needohtowerW1.lua"
    )

elseif placeId == 92728557730774 or universeId == 92728557730774 then
    loadGame(
        "https://github.com/Zombiegoblin4/TheCoolestHubRBLX/raw/refs/heads/main/games/phonkyphonkclicker1.lua",
        "https://github.com/Zombiegoblin4/TheCoolestHubRBLX/raw/refs/heads/main/mobileGames/ithinkphonkissmth1.lua"
    )
    
elseif placeId == 95082159892680 or universeId == 95082159892680 then
    loadGame(
        "https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/games/%2B1speedy.lua",
        "https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/mobileGames/%2B1speedy.lua"
    )

elseif placeId == 11674754725 or universeId == 11674754725 then
    loadGame(
        "https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/games/R6EHGui.lua",
        "https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/games/R6EHGui.lua"
    )

elseif placeId == 79268393072444 or universeId == 79268393072444 then
    loadGame(
        "https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/games/LemonsAreNotSoYummy.lua",
        "https://raw.githubusercontent.com/Zombiegoblin4/TheCoolestHubRBLX/refs/heads/main/mobileGames/LemonsSuck.lua"
    )
    
else
    --------------------------------------------------------------------
    -- Unsupported Game GUI (PC/Mobile)
    --------------------------------------------------------------------
    local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "UnsupportedGameUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Unsupported Game"
    title.TextColor3 = Color3.fromRGB(255, 80, 80)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -20, 0, 50)
    desc.Position = UDim2.new(0, 10, 0, 45)
    desc.BackgroundTransparency = 1
    desc.Text = "This game is not supported by TheCoolest Hub."
    desc.TextColor3 = Color3.fromRGB(220, 220, 220)
    desc.TextScaled = true
    desc.Font = Enum.Font.Gotham
    desc.Parent = frame

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
