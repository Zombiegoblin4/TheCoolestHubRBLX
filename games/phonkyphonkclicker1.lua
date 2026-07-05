-- TheCoolest Hub (georganiseerd)
local MacLib = loadstring(game:HttpGet("https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

local Window = MacLib:Window({
    Title = "TheCoolest Hub!",
    Subtitle = "Ready To Be Cool 😎",
    Size = UDim2.fromOffset(868, 650),
    Keybind = Enum.KeyCode.LeftControl,
    AcrylicBlur = true,
})

local TabGroup = Window:TabGroup()

-- Tabs
local TabClicker = TabGroup:Tab({ Name = "Clicker",       Image = "rbxassetid://8150337452" })
local TabAreas   = TabGroup:Tab({ Name = "Areas",         Image = "rbxassetid://8150337452" })
local TabRebirth = TabGroup:Tab({ Name = "Rebirth",       Image = "rbxassetid://8150337452" })
local TabMisc    = TabGroup:Tab({ Name = "Misc",          Image = "rbxassetid://8150337452" })
local TabCollect = TabGroup:Tab({ Name = "Collecting",    Image = "rbxassetid://8150337452" })

-- Sections (FIXED: Side = "Left")
local SectionClick = TabClicker:Section({ Side = "Left" })
local SectionAreas = TabAreas:Section({ Side = "Left" })
local SectionReb   = TabRebirth:Section({ Side = "Left" })
local SectionMisc  = TabMisc:Section({ Side = "Left" })
local SectionCollect = TabCollect:Section({ Side = "Left" }) -- FIXED

-- Universal tab
local TabUniversal = TabGroup:Tab({ Name = "Universal", Image = "rbxassetid://8150337452" })
local SectionUniversal = TabUniversal:Section({ Side = "Left" })

-- Remote events
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClickEvent  = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Clicker")
local AreaEvent   = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Area")
local RebirthEvent= ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Rebirth")

-- Helper: maakt een value-based toggle die een event spamt met interval
local function makeEventToggle(section, name, flagName, eventRemote, interval)
    local running = false

    section:Toggle({
        Name = name,
        Default = false,
        Callback = function(value)
            Window:Notify({
                Title = "TheCoolest Hub",
                Description = (value and "Enabled " or "Disabled ") .. name,
                Lifetime = 3
            })

            if not value then
                running = false
                return
            end

            if running then return end
            running = true

            task.spawn(function()
                while running do
                    pcall(function()
                        eventRemote:FireServer()
                    end)

                    task.wait(interval or 0.2)

                    if not running then break end
                end
            end)
        end,
    }, flagName)
end

-- Clicker tab
makeEventToggle(SectionClick, "Auto Click",    "AutoClickToggle",   ClickEvent, 0.1)

-- Areas tab
makeEventToggle(SectionAreas, "Auto-Buy Areas", "AutoBuyAreasToggle", AreaEvent, 0.2)

-- Rebirth tab
makeEventToggle(SectionReb, "Auto Rebirth",   "AutoRebirthToggle", RebirthEvent, 0.5)

-- Misc
SectionMisc:Toggle({
    Name = "Auto Click While Rebirthing",
    Default = false,
    Callback = function(value)
        Window:Notify({
            Title = "TheCoolest Hub",
            Description = (value and "Enabled " or "Disabled ") .. "Auto Click While Rebirthing",
            Lifetime = 3
        })
    end,
}, "AutoClickWhileRebirth")

---------------------------------------------------------------------
-- ⭐ ULTRA FAST AUTO-COLLECT GIFTS ⭐
---------------------------------------------------------------------
do
    local running = false

    SectionCollect:Toggle({
        Name = "Auto-Collect Gifts",
        Default = false,
        Callback = function(value)
            running = value

            Window:Notify({
                Title = "TheCoolest Hub",
                Description = (value and "Enabled Auto-Collect Gifts" or "Disabled Auto-Collect Gifts"),
                Lifetime = 3
            })

            if not value then return end

            task.spawn(function()
                while running do
                    local giftsFolder = workspace:FindFirstChild("Gifts")
                    if giftsFolder then
                        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                        if hrp then
                            for _, gift in ipairs(giftsFolder:GetChildren()) do
                                if gift:IsA("BasePart") then
                                    pcall(function()
                                        hrp.CFrame = gift.CFrame + Vector3.new(0, 2, 0)
                                    end)

                                    task.wait(0.05)
                                end
                            end
                        end
                    end

                    task.wait(0.05)
                end
            end)
        end,
    }, "AutoCollectGiftsToggle")
end

---------------------------------------------------------------------
-- ⭐ UNIVERSAL MOVEMENT CONTROLS ⭐
---------------------------------------------------------------------

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")

-- WalkSpeed
SectionUniversal:Slider({
    Name = "WalkSpeed",
    Default = 16,
    Minimum = 0,
    Maximum = 200,
    DisplayMethod = "Value",
    Callback = function(value)
        humanoid.WalkSpeed = value
    end,
}, "WalkSpeedSlider")

-- JumpPower
SectionUniversal:Slider({
    Name = "JumpPower",
    Default = 50,
    Minimum = 0,
    Maximum = 300,
    DisplayMethod = "Value",
    Callback = function(value)
        humanoid.JumpPower = value
    end,
}, "JumpPowerSlider")

---------------------------------------------------------------------
-- ⭐ FLY SYSTEM ⭐ (smooth + safe)
---------------------------------------------------------------------

local flying = false
local flySpeed = 3

SectionUniversal:Toggle({
    Name = "Fly",
    Default = false,
    Callback = function(value)
        flying = value

        Window:Notify({
            Title = "TheCoolest Hub",
            Description = (value and "Enabled Fly" or "Disabled Fly"),
            Lifetime = 3
        })

        if not value then
            -- reset physics
            pcall(function()
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end)
            return
        end

        task.spawn(function()
            local hrp = char:WaitForChild("HumanoidRootPart")

            while flying do
                task.wait()

                local move = Vector3.zero
                local keys = game:GetService("UserInputService")

                if keys:IsKeyDown(Enum.KeyCode.W) then
                    move = move + hrp.CFrame.LookVector
                end
                if keys:IsKeyDown(Enum.KeyCode.S) then
                    move = move - hrp.CFrame.LookVector
                end
                if keys:IsKeyDown(Enum.KeyCode.A) then
                    move = move - hrp.CFrame.RightVector
                end
                if keys:IsKeyDown(Enum.KeyCode.D) then
                    move = move + hrp.CFrame.RightVector
                end
                if keys:IsKeyDown(Enum.KeyCode.Space) then
                    move = move + Vector3.new(0, 1, 0)
                end
                if keys:IsKeyDown(Enum.KeyCode.LeftShift) then
                    move = move - Vector3.new(0, 1, 0)
                end

                if move.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + (move.Unit * flySpeed)
                end
            end
        end)
    end,
}, "FlyToggle")

-- Load notification
Window:Notify({
    Title = "TheCoolest Hub",
    Description = "Sucsessfully loaded!",
    Lifetime = 4
})
