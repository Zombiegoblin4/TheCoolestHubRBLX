-- // TheCoolest Hub — dirt UI version

-- // Load dirt UI library
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/dirt", true))()
local Table = {}  -- holds all flag values (dirt reads/writes state here)
local Window = Lib:CreateWindow("TheCoolest Hub!")


-- // ===== Auto Clicker =====
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

Window:Section("Auto Clicker")

local autoClickRunning = false
local CLICK_COOLDOWN   = 0.01

Window:Toggle("Auto Clicker", { location = Table, flag = "AutoClicker" }, function()
    if Table["AutoClicker"] then
        autoClickRunning = true
        print("[AutoClicker] Started.")

        task.spawn(function()
            while autoClickRunning and Table["AutoClicker"] do
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
end)

print("[TheCoolest Hub] dirt UI version loaded.")


-- // ===== Punch =====
local function GetDamageWallRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    local events = remotes:FindFirstChild("Events")
    if not events then return nil end
    local remote = events:FindFirstChild("DamageWall")
    if remote and remote:IsA("RemoteEvent") then return remote end
    return nil
end

Window:Section("Punch")

local autoPunchRunning = false
local PUNCH_COOLDOWN   = 0.01

Window:Toggle("Auto-Punch Wall", { location = Table, flag = "AutoPunchWall" }, function()
    if Table["AutoPunchWall"] then
        autoPunchRunning = true
        print("[AutoPunch] Started.")

        task.spawn(function()
            while autoPunchRunning and Table["AutoPunchWall"] do
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
end)


-- // ===== Reset =====
local function GetTeleportHomeRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then return nil end
    local events = remotes:FindFirstChild("Events")
    if not events then return nil end
    local remote = events:FindFirstChild("TeleportHome")
    if remote and remote:IsA("RemoteEvent") then return remote end
    return nil
end

Window:Section("Reset")

local autoResetRunning = false
local resetSpeed       = 5

Window:Slider("Reset Speed (seconds)", { location = Table, min = 1, max = 30, default = 5, precise = false, flag = "ResetSpeed" }, function()
    resetSpeed = tonumber(Table["ResetSpeed"]) or 5
end)

Window:Toggle("Auto Reset", { location = Table, flag = "AutoReset" }, function()
    if Table["AutoReset"] then
        autoResetRunning = true
        print("[AutoReset] Started.")

        task.spawn(function()
            while autoResetRunning and Table["AutoReset"] do
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
end)
