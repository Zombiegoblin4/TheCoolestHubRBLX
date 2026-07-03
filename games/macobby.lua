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

        -- Alle TeleportParts folders
        local tpFolders = {}
        if workspace:FindFirstChild("TeleportParts") then
            tpFolders = workspace.TeleportParts:GetChildren()
        end

        for i = 1, 41 do
            local targetPart = nil

            ----------------------------------------------------
            -- SPECIAL CASE: Checkpoint 37 → TeleportPart8
            ----------------------------------------------------
            if i == 37 then
                local tpName = "TeleportPart8"

                -- Zoek TeleportPart8 in ALLE TeleportParts folders
                for _, folder in ipairs(tpFolders) do
                    local found = folder:FindFirstChild(tpName)
                    if found then
                        targetPart = found
                        break
                    end
                end

                if not targetPart then
                    warn("TeleportPart8 niet gevonden in TeleportParts folders.")
                    continue
                end

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
                    hrp.CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
                    success = true
                else
                    warn("TeleportPart voor " .. i .. " is geen BasePart, poging " .. attempts)
                end

                task.wait(0.2)
            until success or attempts >= 10
        end

        Window:Notify({
            Title = "TheCoolest Hub",
            Description = "All 41 Checkpoints Completed! 😎🔥",
            Lifetime = 5
        })
    end,
})
