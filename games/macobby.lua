local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Window = MacLib:Window({
    Title = "TheCoolest Hub!",
    Subtitle = "Ready To Be Cool 😎",
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

        for i = 1, 41 do
            local cp = folder:FindFirstChild("Checkpoint " .. i)
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
            Description = "All 41 Checkpoints Completed! 😎🔥",
            Lifetime = 5
        })
    end,
})
