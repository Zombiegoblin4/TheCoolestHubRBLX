-- 📌 DirtLib laden
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/dirt", true))()
local Table = {}

-- 📌 Window
local window = Lib:CreateWindow("TheCoolest Hub!")
window:Section("Automation")

-----------------------------------------------------
-- ⭐ AUTO-COMPLETE (1 → 35) MET RETRY LOGIC
-----------------------------------------------------
window:Button("Auto-Complete", function()
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local folder = workspace:WaitForChild("Checkpoints")

    for i = 1, 35 do
        local cp = folder:FindFirstChild(i)
        if not cp then
            warn("Checkpoint " .. i .. " niet gevonden.")
            continue
        end

        local success = false
        local attempts = 0

        repeat
            attempts += 1
            local targetPart

            if cp:IsA("Model") then
                targetPart = cp.PrimaryPart or cp:FindFirstChildWhichIsA("BasePart")
            elseif cp:IsA("BasePart") then
                targetPart = cp
            end

            if targetPart then
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
                success = true
            else
                warn("Checkpoint " .. cp.Name .. " heeft geen BasePart, poging " .. attempts)
            end

            task.wait(0.2)
        until success or attempts >= 10
    end

    window:String({string = "All 35 Checkpoints Completed! 😎🔥"})
end)

-----------------------------------------------------
-- ⭐ AUTO-FARM WINS (RESET + LOOP)
-----------------------------------------------------
window:Toggle("Auto-Farm Wins", {
    location = Table,
    flag = "AutoFarmWins",
    default = false
}, function(enabled)

    window:String({string = enabled and "Enabled Auto-Farm Wins" or "Disabled Auto-Farm Wins"})

    if not enabled then return end

    local Event = game:GetService("ReplicatedStorage").Remotes.ResetProgress
    local player = game.Players.LocalPlayer
    local folder = workspace:WaitForChild("Checkpoints")

    task.spawn(function()
        while Table["AutoFarmWins"] do

            --------------------------------------------------------------------
            -- 🔄 ALWAYS RELOAD CHARACTER + HRP (fixes breaking after 1 run)
            --------------------------------------------------------------------
            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")

            --------------------------------------------------------------------
            -- 1️⃣ COMPLETE 1 → 35 (normal speed)
            --------------------------------------------------------------------
            for i = 1, 35 do
                local cp = folder:FindFirstChild(i)
                if cp then
                    local part = cp:IsA("Model")
                        and (cp.PrimaryPart or cp:FindFirstChildWhichIsA("BasePart"))
                        or cp:IsA("BasePart") and cp

                    if part then
                        hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
                    end
                end

                task.wait(0.02)
            end

            --------------------------------------------------------------------
            -- 2️⃣ RESET PROGRESS ONCE
            --------------------------------------------------------------------
            Event:FireServer()
            task.wait(0.2)

            --------------------------------------------------------------------
            -- 🔄 RELOAD CHARACTER AGAIN AFTER RESET
            --------------------------------------------------------------------
            char = player.Character or player.CharacterAdded:Wait()
            hrp = char:WaitForChild("HumanoidRootPart")

            --------------------------------------------------------------------
            -- 3️⃣ LOOP FOREVER UNTIL TOGGLE IS OFF
            --------------------------------------------------------------------
            window:String({string = "Farmed 35 stages! Restarting..."})

            task.wait(1)
        end
    end)
end)
