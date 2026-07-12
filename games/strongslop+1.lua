-- // Load Maclib
local MacLib = loadstring(game:HttpGet(
  "https://github.com/biggaboy212/Maclib/releases/latest/download/maclib.txt"))()

-- // Window (mandatory header — do not modify)
local Window = MacLib:Window({
    Title = "TheCoolest Hub!",
    Subtitle = "Ready To Be Cool 😎",
    Size = UDim2.fromOffset(868, 650),
    Keybind = Enum.KeyCode.LeftControl,
    AcrylicBlur = true,
})


-- // ===== Auto Clicker Tab =====
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function GetClickRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    local events = remotes:FindFirstChild("Events")
    if not events then return nil end
    local remote = events:FindFirstChild("ClickRemote")
    if remote and remote:IsA("RemoteEvent") then return remote end
    return nil
end

local MainTab     = Window:TabGroup()
local ClickerTab  = MainTab:Tab({ Name = "Auto Clicker" })
local ClickerSec  = ClickerTab:Section({ Side = "Left" })

local autoClickRunning  = false
local CLICK_COOLDOWN    = 0.01   -- seconds between clicks (super fast)

local autoClickToggle  -- forward declare so loop can read .State directly
autoClickToggle = ClickerSec:Toggle({
    Name = "Auto Clicker",
    Default = false,
    Callback = function(value)
        if value then
            autoClickRunning = true
            print("[AutoClicker] Started.")

            task.spawn(function()
                while autoClickRunning and autoClickToggle.State do
                    pcall(function()
                        local remote = GetClickRemote()
                        if remote then
                            remote:FireServer()
                        end
                    end)
                    task.wait(CLICK_COOLDOWN)
                end
                autoClickRunning = false
                print("[AutoClicker] Stopped.")
            end)
        else
            autoClickRunning = false
        end
    end,
}, "AutoClicker")


-- // ===== Punch Tab =====
local function GetDamageWallRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    local events = remotes:FindFirstChild("Events")
    if not events then return nil end
    local remote = events:FindFirstChild("DamageWall")
    if remote and remote:IsA("RemoteEvent") then return remote end
    return nil
end

local PunchTab = MainTab:Tab({ Name = "Punch" })
local PunchSec = PunchTab:Section({ Side = "Left" })

local autoPunchRunning = false
local PUNCH_COOLDOWN   = 0.01

local autoPunchToggle  -- forward declare
autoPunchToggle = PunchSec:Toggle({
    Name = "Auto-Punch Wall",
    Default = false,
    Callback = function(value)
        if value then
            autoPunchRunning = true
            print("[AutoPunch] Started.")

            task.spawn(function()
                while autoPunchRunning and autoPunchToggle.State do
                    pcall(function()
                        local remote = GetDamageWallRemote()
                        if remote then
                            remote:FireServer()
                        end
                    end)
                    task.wait(PUNCH_COOLDOWN)
                end
                autoPunchRunning = false
                print("[AutoPunch] Stopped.")
            end)
        else
            autoPunchRunning = false
        end
    end,
}, "AutoPunchWall")


-- // ===== Reset Tab =====
local function GetTeleportHomeRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    local events = remotes:FindFirstChild("Events")
    if not events then return nil end
    local remote = events:FindFirstChild("TeleportHome")
    if remote and remote:IsA("RemoteEvent") then return remote end
    return nil
end

local ResetTab = MainTab:Tab({ Name = "Reset" })
local ResetSec = ResetTab:Section({ Side = "Left" })

local autoResetRunning   = false
local resetSpeed         = 5   -- seconds between resets (slider-controlled)

-- Slider for reset speed (1-30 seconds)
ResetSec:Slider({
    Name = "Reset Speed (seconds)",
    Default = 5,
    Minimum = 1,
    Maximum = 30,
    DisplayMethod = "Value",
    Precision = 0,
    Callback = function(value)
        resetSpeed = value
    end,
}, "ResetSpeed")

local autoResetToggle  -- forward declare
autoResetToggle = ResetSec:Toggle({
    Name = "Auto Reset",
    Default = false,
    Callback = function(value)
        if value then
            autoResetRunning = true
            print("[AutoReset] Started.")

            task.spawn(function()
                while autoResetRunning and autoResetToggle.State do
                    pcall(function()
                        local remote = GetTeleportHomeRemote()
                        if remote then
                            remote:FireServer()
                        end
                    end)
                    task.wait(resetSpeed)
                end
                autoResetRunning = false
                print("[AutoReset] Stopped.")
            end)
        else
            autoResetRunning = false
        end
    end,
}, "AutoReset")
