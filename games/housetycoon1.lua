local player = game.Players.LocalPlayer
local Tycoons = game.Workspace:WaitForChild("Tycoons")

local MyPlot = nil

-- 🔍 Find your plot
for _, plot in ipairs(Tycoons:GetChildren()) do
    local valuesFolder = plot:FindFirstChild("Values")
    if valuesFolder then
        local ownerValue = valuesFolder:FindFirstChild("Owner")
        if ownerValue and ownerValue.Value == player.Name then
            MyPlot = plot
            break
        end
    end
end

if MyPlot then
    print("✅ Jouw plot gevonden:", MyPlot.Name)
else
    warn("❌ Geen plot gevonden voor speler:", player.Name)
end

-- Randomized subtitle quotes
local quotes = {
    "Keep grinding! im sure you will get at the end someday and even faster with Cool Powers :p",
    "oohhh you keep teleporting aye",
    "Grinding HAHA 😂 i'd rather cheat",
    "Keep letting those buttons teleport! let em do the work for ya"
}

-- Pick a random quote
local randomSubtitle = quotes[math.random(1, #quotes)]

local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Window = MacLib:Window({
    Title = "TheCoolest Hub!",
    Subtitle = randomSubtitle,
    Size = UDim2.fromOffset(868, 650),
    DragStyle = 1,
    DisabledWindowControls = {},
    ShowUserInfo = true,
    Keybind = Enum.KeyCode.LeftControl,
    AcrylicBlur = true,
})

local TabGroup = Window:TabGroup()

local TabTP = TabGroup:Tab({
    Name = "Automation",
    Image = "rbxassetid://8150337452"
})

local Section = TabTP:Section({
    Side = "Left"
})

-- ⭐ AUTO-BUY TOGGLE (MODELS ONLY)
Section:Toggle({
    Name = "Auto-Buy",
    Default = false,
    Callback = function(enabled)
        Window:Notify({
            Title = "TheCoolest Hub",
            Description = enabled and "Enabled Auto-Buy" or "Disabled Auto-Buy",
            Lifetime = 4
        })

        if not enabled then return end

        local char = player.Character or player.CharacterAdded:Wait()
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if not torso then return end

        local Buttons = MyPlot:WaitForChild("Buttons")
        local scanned = {}

        -- 🔁 Auto-Buy loop
        task.spawn(function()
            while enabled do
                for _, item in ipairs(Buttons:GetChildren()) do
                    if item:IsA("Model") and not scanned[item] then
                        scanned[item] = true

                        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        if part then
                            part.CFrame = torso.CFrame + Vector3.new(0, 2, 0)
                        end
                    end
                end

                task.wait(0.5)
            end
        end)
    end,
}, "AutoBuyToggle")
