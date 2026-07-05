-- Randomized subtitle quotes
local quotes = {
    "Keep grinding! im sure you will get at the end someday and even faster with Cool Powers :p",
    "oohhh you keep teleporting aye",
    "Grinding HAHA 😂 i'd rather cheat",
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

Section:Button({
    Name = "Auto-Complete",
    Callback = function()
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
            until success or attempts >= 10  -- tries up to 10 times per checkpoint
        end

        Window:Notify({
            Title = "TheCoolest Hub",
            Description = "All 35 Checkpoints Completed! 😎🔥",
            Lifetime = 5
        })
    end,
})

Section:Toggle({
    Name = "Auto-Farm Wins",
    Default = false,
    Callback = function(enabled)
        Window:Notify({
            Title = "TheCoolest Hub",
            Description = enabled and "Enabled Auto-Farm Wins" or "Disabled Auto-Farm Wins",
            Lifetime = 4
        })

        if not enabled then return end

        local Event = game:GetService("ReplicatedStorage").Remotes.ResetProgress
        local player = game.Players.LocalPlayer
        local folder = workspace:WaitForChild("Checkpoints")

        task.spawn(function()
            while enabled do

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
                Window:Notify({
                    Title = "TheCoolest Hub",
                    Description = "Farmed 35 stages! Restarting...",
                    Lifetime = 3
                })

                task.wait(1)
            end
        end)
    end,
}, "AutoFarmWinsToggle")
