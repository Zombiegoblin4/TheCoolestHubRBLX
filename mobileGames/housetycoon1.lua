-- 📌 Player + Tycoon Scan
local player = game.Players.LocalPlayer
local Tycoons = game.Workspace:WaitForChild("Tycoons")

local MyPlot = nil

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

-- 📌 DirtLib laden
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/dirt", true))()
local Table = {}

-- 📌 Window
local window = Lib:CreateWindow("TheCoolest Hub!")
window:Section("Automation")

-----------------------------------------------------
-- ⭐ AUTO-BUY TOGGLE (MODELS ONLY)
-----------------------------------------------------
window:Toggle("Auto-Buy", {
    location = Table,
    flag = "AutoBuy",
    default = false
}, function(enabled)

    window:String({string = enabled and "Enabled Auto-Buy" or "Disabled Auto-Buy"})

    if not enabled then return end

    local char = player.Character or player.CharacterAdded:Wait()
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not torso then return end

    local Buttons = MyPlot:WaitForChild("Buttons")
    local scanned = {}

    -- 🔁 Auto-Buy loop
    task.spawn(function()
        while Table["AutoBuy"] do
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
end)
