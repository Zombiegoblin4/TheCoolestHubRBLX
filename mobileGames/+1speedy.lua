-- TheCoolest Hub (DirtLib Edition)
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/dirt",true))()

local Table = {}
local window = Lib:CreateWindow("TheCoolest Hub — DirtLib Edition")

local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer

---------------------------------------------------------------------
-- ⭐ SECTION: WINS
---------------------------------------------------------------------
window:Section("Wins")

---------------------------------------------------------------------
-- ⭐ TELEPORT PATHS (MULTI-STEP)
---------------------------------------------------------------------
local TeleportPaths = {
    ["+1 Wins"] = {
        CFrame.new(0.448354244, 8.9534626, 66.9333267),
        CFrame.new(-16.4241066, 8.95346165, 281.383453)
    },

    ["+3 Wins"] = {
        CFrame.new(0.448354244, 8.9534626, 66.9333267),
        CFrame.new(-2.4241066, 8.95346165, 294.383453),
        CFrame.new(62.2836075, 8.95346165, 424.541962),
        CFrame.new(-16.9603615, 8.95346069, 506.055542)
    },

    ["+10 Wins"] = {
        CFrame.new(0.448354244, 8.9534626, 66.9333267),
        CFrame.new(4.03963852, 8.95346069, 506.055542),
        CFrame.new(20.200552, 8.9534626, 563.247253),
        CFrame.new(18.7471104, 77.2423477, 745.637268),
        CFrame.new(-15.9055004, 77.2423477, 773.520691)
    },

    ["+20 Wins"] = {
        CFrame.new(0.448354244, 8.9534626, 66.9333267),
        CFrame.new(-2.4241066, 8.95346165, 294.383453),
        CFrame.new(62.2836075, 8.95346165, 424.541962),
        CFrame.new(4.03963852, 8.95346069, 506.055542),
        CFrame.new(20.200552, 8.9534626, 563.247253),
        CFrame.new(18.7471104, 77.2423477, 745.637268),
        CFrame.new(-0.702917993, 77.2423477, 780.10553),
        CFrame.new(2.03941607, 76.1579056, 874.557312),
        CFrame.new(12.8119507, 76.1418381, 927.611206),
        CFrame.new(55.7196579, 77.237236, 936.754089),
        CFrame.new(101.35228, 77.1432037, 940.840149),
        CFrame.new(102.300911, 76.6698837, 1003.48895),
        CFrame.new(50.4059677, 79.0943832, 1002.68396),
        CFrame.new(2.94973636, 78.2667389, 1006.54535),
        CFrame.new(0.600398004, 78.3115463, 1057.80042),
        CFrame.new(-13.8807974, 77.242363, 1108.8833)
    },

    ["+50 Wins"] = {
        CFrame.new(0.448354244, 8.9534626, 66.9333267),
        CFrame.new(-2.4241066, 8.95346165, 294.383453),
        CFrame.new(62.2836075, 8.95346165, 424.541962),
        CFrame.new(4.03963852, 8.95346069, 506.055542),
        CFrame.new(20.200552, 8.9534626, 563.247253),
        CFrame.new(18.7471104, 77.2423477, 745.637268),
        CFrame.new(-0.702917993, 77.2423477, 780.10553),
        CFrame.new(2.03941607, 76.1579056, 874.557312),
        CFrame.new(12.8119507, 76.1418381, 927.611206),
        CFrame.new(55.7196579, 77.237236, 936.754089),
        CFrame.new(101.35228, 77.1432037, 940.840149),
        CFrame.new(102.300911, 76.6698837, 1003.48895),
        CFrame.new(50.4059677, 79.0943832, 1002.68396),
        CFrame.new(2.94973636, 78.2667389, 1006.54535),
        CFrame.new(2.94973636, 78.2667389, 1102.54541),
        CFrame.new(2.11920166, 77.242363, 1108.8833),
        CFrame.new(1.74295521, 77.242363, 1375.38599),
        CFrame.new(-14.5092411, 77.242363, 1408.6582)
    }
}

local selectedPath = "+1 Wins"

---------------------------------------------------------------------
-- ⭐ DROPDOWN: SELECT WIN PATH
---------------------------------------------------------------------
window:Dropdown("Select Win Path", {
    location = Table,
    flag = "WinPath",
    list = {"+1 Wins", "+3 Wins", "+10 Wins", "+20 Wins", "+50 Wins"}
}, function()
    selectedPath = Table["WinPath"]
    print("Selected:", selectedPath)
end)

---------------------------------------------------------------------
-- ⭐ AUTO-FARM WINS (MULTI-STEP TWEEN)
---------------------------------------------------------------------
window:Toggle("Auto-Farm Wins", {location = Table, flag = "AutoFarmWins"}, function()
    local state = Table["AutoFarmWins"]
    print("Auto-Farm Wins:", state)

    if not state then return end

    task.spawn(function()
        while Table["AutoFarmWins"] do
            task.wait(0.3)

            local char = player.Character
            if not char then continue end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            local path = TeleportPaths[selectedPath]
            if not path then continue end

            for _, targetCFrame in ipairs(path) do
                local tween = TweenService:Create(
                    hrp,
                    TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    {CFrame = targetCFrame}
                )
                tween:Play()
                tween.Completed:Wait()
                task.wait(0.1)
            end
        end
    end)
end)
