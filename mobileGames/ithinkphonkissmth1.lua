local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/dirt", true))()
local Table = {}
local window = Lib:CreateWindow("TheCoolest Hub 😎")

----------------------------------------------------
-- CLICKER SECTION
----------------------------------------------------
window:Section("Clicker")

local ClickEvent = game:GetService("ReplicatedStorage").Remotes.Clicker
local autoClickRunning = false

window:Toggle("Auto Click", {location = Table, flag = "AutoClick"}, function(value)
    print((value and "Enabled Auto Click" or "Disabled Auto Click"))

    if not value then
        autoClickRunning = false
        return
    end

    if autoClickRunning then return end
    autoClickRunning = true

    task.spawn(function()
        while autoClickRunning do
            ClickEvent:FireServer()
            task.wait(0.1)
            if not Table["AutoClick"] then
                autoClickRunning = false
                break
            end
        end
    end)
end)

----------------------------------------------------
-- AREAS SECTION
----------------------------------------------------
window:Section("Areas")

local AreaEvent = game:GetService("ReplicatedStorage").Remotes.Area
local autoAreaRunning = false

window:Toggle("Auto-Buy Areas", {location = Table, flag = "AutoBuyAreas"}, function(value)
    print((value and "Enabled Auto-Buy Areas" or "Disabled Auto-Buy Areas"))

    if not value then
        autoAreaRunning = false
        return
    end

    if autoAreaRunning then return end
    autoAreaRunning = true

    task.spawn(function()
        while autoAreaRunning do
            AreaEvent:FireServer()
            task.wait(0.2)
            if not Table["AutoBuyAreas"] then
                autoAreaRunning = false
                break
            end
        end
    end)
end)

----------------------------------------------------
-- REBIRTH SECTION
----------------------------------------------------
window:Section("Rebirth")

local RebirthEvent = game:GetService("ReplicatedStorage").Remotes.Rebirth
local autoRebirthRunning = false

window:Toggle("Auto Rebirth", {location = Table, flag = "AutoRebirth"}, function(value)
    print((value and "Enabled Auto Rebirth" or "Disabled Auto Rebirth"))

    if not value then
        autoRebirthRunning = false
        return
    end

    if autoRebirthRunning then return end
    autoRebirthRunning = true

    task.spawn(function()
        while autoRebirthRunning do
            RebirthEvent:FireServer()
            task.wait(0.5)
            if not Table["AutoRebirth"] then
                autoRebirthRunning = false
                break
            end
        end
    end)
end)

----------------------------------------------------
-- MISC SECTION
----------------------------------------------------
window:Section("Misc")

window:Toggle("Auto Click While Rebirthing", {location = Table, flag = "AutoClickWhileRebirth"}, function(value)
    print((value and "Enabled Auto Click While Rebirthing" or "Disabled Auto Click While Rebirthing"))
end)

print("Modules geladen: Clicker, Areas, Rebirth, Misc ✅")
