-- TheCoolest Hub (DirtLib met MacLib‑stijl features)
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/dirt", true))()
local Table = {}

-- Window
local window = Lib:CreateWindow("TheCoolest Hub 😎")
window:Section("Automation")

-- Services / Remotes
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClickEvent   = Remotes:FindFirstChild("Clicker")
local AreaEvent    = Remotes:FindFirstChild("Area")
local RebirthEvent = Remotes:FindFirstChild("Rebirth")

-- Simple notify helper (creates a temporary ScreenGui notification)
local function notify(text, lifetime)
    lifetime = lifetime or 3
    local player = game.Players.LocalPlayer
    if not player then
        print(text)
        return
    end
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then
        print(text)
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "TheCoolestHubNotify"
    gui.ResetOnSpawn = false
    gui.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 50)
    frame.Position = UDim2.new(0.5, -150, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, -10)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    task.delay(lifetime, function()
        if gui and gui.Parent then
            gui:Destroy()
        end
    end)
end

-- Helper: maakt een value-based toggle die een event spamt met interval
local function makeEventToggle(sectionName, name, flagName, eventRemote, interval)
    local running = false
    window:Section(sectionName)

    window:Toggle(name, {location = Table, flag = flagName}, function(value)
        notify((value and "Enabled " or "Disabled ") .. name, 2)

        if not value then
            running = false
            return
        end

        if running then return end
        running = true

        task.spawn(function()
            while running do
                if eventRemote and eventRemote.FireServer then
                    pcall(function()
                        eventRemote:FireServer()
                    end)
                else
                    warn("Remote for " .. name .. " not found.")
                end

                task.wait(interval or 0.2)

                if not Table[flagName] then
                    running = false
                    break
                end
            end
        end)
    end)
end

-- Clicker
makeEventToggle("Clicker", "Auto Click", "AutoClick", ClickEvent, 0.1)

-- Areas
makeEventToggle("Areas", "Auto-Buy Areas", "AutoBuyAreas", AreaEvent, 0.2)

-- Rebirth
makeEventToggle("Rebirth", "Auto Rebirth", "AutoRebirth", RebirthEvent, 0.5)

-- Misc section (extra toggles / settings)
window:Section("Misc")
window:Toggle("Auto Click While Rebirthing", {location = Table, flag = "AutoClickWhileRebirth"}, function(value)
    notify((value and "Enabled " or "Disabled ") .. "Auto Click While Rebirthing", 2)
    -- voorbeeld: je kunt hier logica toevoegen die andere flags leest of aanpast
end)

-- Optional: overzichts‑notificatie bij load
notify("Modules geladen: Clicker, Areas, Rebirth, Misc", 4)
print("Modules geladen: Clicker, Areas, Rebirth, Misc ✅")
