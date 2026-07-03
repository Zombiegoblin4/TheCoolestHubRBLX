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
local TabClicker = TabGroup:Tab({ Name = "Clicker", Image = "rbxassetid://8150337452" })
local TabAreas   = TabGroup:Tab({ Name = "Areas",   Image = "rbxassetid://8150337452" })
local TabRebirth = TabGroup:Tab({ Name = "Rebirth", Image = "rbxassetid://8150337452" })
local TabMisc    = TabGroup:Tab({ Name = "Misc",    Image = "rbxassetid://8150337452" })

-- Sections
local SectionClick = TabClicker:Section({ Side = "Left" })
local SectionAreas = TabAreas:Section({ Side = "Left" })
local SectionReb   = TabRebirth:Section({ Side = "Left" })
local SectionMisc  = TabMisc:Section({ Side = "Left" })

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

            -- stop direct als value false
            if not value then
                running = false
                return
            end

            -- voorkom dubbele loops
            if running then return end
            running = true

            task.spawn(function()
                while running do
                    -- event call
                    pcall(function()
                        eventRemote:FireServer()
                    end)

                    task.wait(interval or 0.2)

                    -- check of toggle uitgezet is (value is callback local; if user toggles off, callback runs and sets running=false)
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

-- Rebirth tab (je zei dat je zelf Rebirth toevoegde)
makeEventToggle(SectionReb, "Auto Rebirth",   "AutoRebirthToggle", RebirthEvent, 0.5)

-- Misc: voorbeeld extra toggles of instellingen
SectionMisc:Toggle({
    Name = "Auto Click While Rebirthing",
    Default = false,
    Callback = function(value)
        Window:Notify({
            Title = "TheCoolest Hub",
            Description = (value and "Enabled " or "Disabled ") .. "Auto Click While Rebirthing",
            Lifetime = 3
        })
        -- voorbeeld: je kunt hier logica toevoegen die andere flags leest of aanpast
    end,
}, "AutoClickWhileRebirth")

-- Optioneel: overzichts‑notificatie bij load
Window:Notify({
    Title = "TheCoolest Hub",
    Description = "Modules geladen: Clicker, Areas, Rebirth, Misc",
    Lifetime = 4
})
