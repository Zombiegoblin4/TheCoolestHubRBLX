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
    Name = "Teleportation",
    Image = "rbxassetid://132362529799492"
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

        local folder = game.Workspace:WaitForChild("Checkpoints")

        local index = 1
        local reachedEnd = false

        while true do
            local cp = folder:FindFirstChild(tostring(index))
            if not cp then
                reachedEnd = true
                break
            end

            if cp:IsA("Model") then
                local pp = cp.PrimaryPart or cp:FindFirstChildWhichIsA("BasePart")
                if pp then
                    hrp.CFrame = pp.CFrame + Vector3.new(0, 2, 0)
                else
                    warn("Checkpoint " .. cp.Name .. " heeft geen BasePart om naar te teleporteren.")
                end
            elseif cp:IsA("BasePart") then
                hrp.CFrame = cp.CFrame + Vector3.new(0, 2, 0)
            end

            index += 1
            task.wait(0.1)
        end

        -- Notify wanneer klaar
        if reachedEnd then
            Window:Notify({
                Title = "TheCoolest Hub",
                Description = "All Checkpoints Completed! 😎🔥",
                Lifetime = 5
            })
        end
    end,
})

Section:Slider({
    Name = "Teleport to Stage",
    Default = 1,
    Minimum = 1,
    Maximum = 575,
    DisplayMethod = "Value",
    Callback = function(Value)
        -- Rond de slider waarde af naar een integer
        local Stage = math.floor(Value + 0.5)

        local player = game.Players.LocalPlayer
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")

        local folder = game.Workspace:WaitForChild("Checkpoints")
        local cp = folder:FindFirstChild(tostring(Stage))

        if cp then
            local tpPart

            if cp:IsA("Model") then
                tpPart = cp.PrimaryPart or cp:FindFirstChildWhichIsA("BasePart")
            elseif cp:IsA("BasePart") then
                tpPart = cp
            end

            if tpPart then
                hrp.CFrame = tpPart.CFrame + Vector3.new(0, 2, 0)
            else
                Window:Notify({
                    Title = "Teleportation",
                    Description = "Stage " .. Stage .. " heeft geen teleporteerbare part.",
                    Lifetime = 4
                })
            end
        else
            Window:Notify({
                Title = "Teleportation",
                Description = "Stage " .. Stage .. " bestaat niet.",
                Lifetime = 4
            })
        end
    end,
}, "StageTPSlider")
