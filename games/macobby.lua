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

        local checkpointsFolder = workspace:WaitForChild("Checkpoints")

        --------------------------------------------------------------------
        -- Maak PartyTpLOLZ (eenmalig, of gebruik bestaande)
        --------------------------------------------------------------------
        local partyPart = workspace:FindFirstChild("PartyTpLOLZ")
        if not partyPart then
            partyPart = Instance.new("Part")
            partyPart.Name = "PartyTpLOLZ"
            partyPart.Size = Vector3.new(0.9824609756469727, 9.059999465942383, 6.266468524932861)
            partyPart.CFrame = CFrame.new(
                -50.533123, 63.970047, -687.191406,
                0, 0, 1,
                0, 1, 0,
                -1, 0, 0
            )
            partyPart.Anchored = true
            partyPart.CanCollide = true
            partyPart.Parent = workspace
        end

        --------------------------------------------------------------------
        -- Loop door checkpoints
        --------------------------------------------------------------------
        for i = 1, 41 do
            local targetPart = nil

            ----------------------------------------------------
            -- SPECIAL CASE: Checkpoint 37 → PartyTpLOLZ
            ----------------------------------------------------
            if i == 37 then
                targetPart = partyPart

            ----------------------------------------------------
            -- NORMAAL: Checkpoints 1–41 → workspace.Checkpoints
            ----------------------------------------------------
            else
                local cp = checkpointsFolder:FindFirstChild("Checkpoint " .. i)
                if not cp then
                    warn("Checkpoint " .. i .. " niet gevonden.")
                    continue
                end

                if cp:IsA("Model") then
                    targetPart = cp.PrimaryPart or cp:FindFirstChildWhichIsA("BasePart")
                elseif cp:IsA("BasePart") then
                    targetPart = cp
                end

                if not targetPart then
                    warn("Checkpoint " .. i .. " heeft geen BasePart.")
                    continue
                end
            end

            ----------------------------------------------------
            -- TELEPORT LOGIC
            ----------------------------------------------------
            local success = false
            local attempts = 0

            repeat
                attempts += 1

                if targetPart:IsA("BasePart") then
                    hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                    success = true
                else
                    warn("TeleportPart voor " .. i .. " is geen BasePart, poging " .. attempts)
                end

                task.wait(0.2)
            until success or attempts >= 10

            ----------------------------------------------------
            -- SPECIAL WAIT AFTER TELEPORT (Checkpoint 37)
            ----------------------------------------------------
            if i == 37 then
                task.wait(5)
            end
        end

        Window:Notify({
            Title = "TheCoolest Hub",
            Description = "All 41 Checkpoints Completed! 😎🔥",
            Lifetime = 5
        })
    end,
})
