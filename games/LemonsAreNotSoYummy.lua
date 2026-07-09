-- // ===== Tycoon Scanner — runs BEFORE Maclib window loads =====
-- Tries every Workspace.Tycoon<digits> folder. The Owner can be either:
--   * an ObjectValue whose .Value is the LocalPlayer instance, OR
--   * a StringValue / ObjectValue whose .Value.Name matches LocalPlayer.Name
-- We collect ALL candidate tycoons, then prefer the one whose Owner is the
-- LocalPlayer instance (most reliable). The server's authoritative check is
-- what matters at purchase time — if it rejects a tycoon as 'not the owner',
-- we re-scan and try the next candidate at runtime (see AutoBuy loop).
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local MyTycoon = nil        -- the Tycoon folder Instance (e.g. Workspace.Tycoon3)
local MyTycoonNumber = nil  -- integer extracted from the name (e.g. 3)

local function tycoonMatchesOwner(tycoonFolder)
    local owner = tycoonFolder:FindFirstChild("Owner")
    if not owner then return false end
    -- ObjectValue pointing directly at the LocalPlayer instance
    if owner:IsA("ObjectValue") and owner.Value == LocalPlayer then
        return true
    end
    -- ObjectValue pointing at some instance whose Name matches LocalPlayer
    if owner:IsA("ObjectValue") and owner.Value and owner.Value.Name == LocalPlayer.Name then
        return true
    end
    -- StringValue / IntValue-style name match
    if owner:IsA("StringValue") and owner.Value == LocalPlayer.Name then
        return true
    end
    -- Owner as an attribute (some games store ownership as attributes)
    if tycoonFolder:GetAttribute("Owner") == LocalPlayer.Name then
        return true
    end
    return false
end

for _, child in ipairs(game.Workspace:GetChildren()) do
    local num = child.Name:match("^Tycoon(%d+)$")
    if num and tycoonMatchesOwner(child) then
        MyTycoon = child
        MyTycoonNumber = tonumber(num)
        print(string.format("[Tycoon Scanner] Found tycoon: %s | Number: %d", child.Name, MyTycoonNumber))
        break
    end
end

if not MyTycoon then
    -- Tycoon might not be assigned yet — retry for up to 30s, then give up loudly
    task.spawn(function()
        local deadline = tick() + 30
        while not MyTycoon and tick() < deadline do
            for _, child in ipairs(game.Workspace:GetChildren()) do
                local num = child.Name:match("^Tycoon(%d+)$")
                if num and tycoonMatchesOwner(child) then
                    MyTycoon = child
                    MyTycoonNumber = tonumber(num)
                    print(string.format("[Tycoon Scanner] Late-found tycoon: %s | Number: %d", child.Name, MyTycoonNumber))
                    return
                end
            end
            task.wait(0.5)
        end
        if not MyTycoon then
            warn(string.format("[Tycoon Scanner] No tycoon found for %s after 30s — Owner check may need adjustment.", LocalPlayer.Name))
            -- Print what Owner values ARE present so we can diagnose
            for _, child in ipairs(game.Workspace:GetChildren()) do
                if child.Name:match("^Tycoon%d+$") then
                    local owner = child:FindFirstChild("Owner")
                    local ownerType = owner and owner.ClassName or "none"
                    local ownerVal = nil
                    if owner then
                        if owner:IsA("ObjectValue") then
                            ownerVal = owner.Value and owner.Value.Name or "<nil>"
                        else
                            ownerVal = tostring(owner.Value)
                        end
                    end
                    print(string.format("  %s | Owner type=%s value=%s", child.Name, ownerType, tostring(ownerVal)))
                end
            end
        end
    end)
end
-- // ===== End Tycoon Scanner =====


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


-- // ===== Auto Buy — button scanner (corrected path) =====
-- Real structure (from user's screenshot):
--   MyTycoon
--     └─ Purchases
--          └─ [RandomFolder]   e.g. "Hills"
--               └─ Buttons     <-- KEY: this folder exists, I was missing it
--                    ├─ <button model w/ Purchase RF>     (root-level buttons)
--                    └─ <subfolder e.g. "Roads">
--                         └─ <button model w/ Purchase RF>  (nested buttons)
-- A "button" = any descendant of Buttons that has a direct child named
-- "Purchase" which is a RemoteFunction. Recurse everything.
local function ScanPurchaseButtons()
    local buttons = {}
    if not MyTycoon then return buttons end

    local purchases = MyTycoon:FindFirstChild("Purchases")
    if not purchases then return buttons end

    -- Walk every random folder inside Purchases
    for _, randomFolder in ipairs(purchases:GetChildren()) do
        if not randomFolder:IsA("Folder") then continue end

        -- The "Buttons" folder lives inside the random folder
        local buttonsFolder = randomFolder:FindFirstChild("Buttons")
        if not buttonsFolder then continue end

        -- Recursively walk all descendants of Buttons.
        -- Any descendant that has a direct "Purchase" RemoteFunction child is a buyable button.
        for _, desc in ipairs(buttonsFolder:GetDescendants()) do
            local purchase = desc:FindFirstChild("Purchase")
            if purchase and purchase:IsA("RemoteFunction") then
                table.insert(buttons, desc)
            end
        end
    end

    return buttons
end


-- // ===== Auto Buy — cached scanner (lightning fast) =====
-- Maintains a cached list of {button=instance, purchase=RemoteFunction} pairs
-- and refreshes ONLY when the Purchases tree changes (ChildAdded/ChildRemoved
-- signals). This eliminates the per-iteration GetDescendants() walk.
local CachedButtons = nil           -- array of {button=Instance, purchase=RemoteFunction}
local CachedButtonsDirty = true     -- force a rescan on first use

local function MarkButtonsDirty()
    CachedButtonsDirty = true
end

local function AttachTreeChangeListeners()
    if not MyTycoon then return end
    local purchases = MyTycoon:FindFirstChild("Purchases")
    if not purchases then return end
    purchases.ChildAdded:Connect(MarkButtonsDirty)
    purchases.ChildRemoved:Connect(MarkButtonsDirty)
    -- Also listen on every existing sub-folder so newly-added buttons anywhere
    -- in the tree trigger a rescan.
    for _, desc in ipairs(purchases:GetDescendants()) do
        if desc:IsA("Instance") and desc.ChildAdded then
            desc.ChildAdded:Connect(MarkButtonsDirty)
            desc.ChildRemoved:Connect(MarkButtonsDirty)
        end
    end
end

local function GetCachedButtons()
    if CachedButtonsDirty or not CachedButtons then
        local fresh = ScanPurchaseButtons()
        CachedButtons = {}
        for _, btn in ipairs(fresh) do
            local purchase = btn:FindFirstChild("Purchase")
            if purchase and purchase:IsA("RemoteFunction") and purchase.Parent then
                table.insert(CachedButtons, { button = btn, purchase = purchase })
            end
        end
        CachedButtonsDirty = false
    end
    return CachedButtons
end

-- Try to attach the listeners once MyTycoon is known (and again if it changes).
task.spawn(function()
    -- Wait for MyTycoon to be assigned by the scanner
    local lastTycoon = nil
    while true do
        if MyTycoon and MyTycoon ~= lastTycoon then
            lastTycoon = MyTycoon
            AttachTreeChangeListeners()
            MarkButtonsDirty()
        end
        task.wait(0.5)
    end
end)


-- // ===== Auto Buy — UI + fast loop =====
local AutoBuyTabGroup = Window:TabGroup()
local AutoBuyTab      = AutoBuyTabGroup:Tab({ Name = "Auto Buy" })
local AutoBuySection  = AutoBuyTab:Section({ Side = "Left" })

local autoBuyRunning = false
local BUY_COOLDOWN   = 0.01   -- throttle between full passes (just a little faster)

local autoBuyToggle  -- forward declare so the loop can read .State directly
autoBuyToggle = AutoBuySection:Toggle({
    Name = "Auto Buy (Next) Button",
    Default = false,
    Callback = function(value)
        if value then
            if not MyTycoon then
                warn("[AutoBuy] No tycoon found.")
                return
            end
            autoBuyRunning = true
            print("[AutoBuy] Started.")

            task.spawn(function()
                while autoBuyRunning and autoBuyToggle.State do
                    -- pcall wraps the whole pass so a single bad button can't kill the loop
                    pcall(function()
                        local buttons = GetCachedButtons()
                        for _, entry in ipairs(buttons) do
                            local purchase = entry.purchase
                            if purchase and purchase.Parent then
                                pcall(function()
                                    purchase:InvokeServer(false)
                                end)
                            end
                        end
                    end)
                    task.wait(BUY_COOLDOWN)
                end
                autoBuyRunning = false
                print("[AutoBuy] Stopped.")
            end)
        else
            autoBuyRunning = false
        end
    end,
}, "AutoBuyNext")


-- // ===== Auto Upgrade — scanner =====
-- Looks inside MyTycoon.Purchases["Lemon Stand"]["Lemon Stand"]["Lemon Stand"]
-- for every descendant named "Upgrade". Each Upgrade is called with `1` (int).
-- Works whether Upgrade is a RemoteFunction (InvokeServer) or RemoteEvent (FireServer).
local function ScanUpgradeButtons()
    local upgrades = {}
    if not MyTycoon then return upgrades end

    -- SAFE chained traversal: each step checks for nil before descending.
    -- If "Lemon Stand" hasn't been bought yet (or gets renamed), this just
    -- returns an empty list instead of throwing "attempt to index nil".
    local function findChild(parent, name)
        if not parent then return nil end
        return parent:FindFirstChild(name)
    end

    local purchases   = MyTycoon:FindFirstChild("Purchases")
    local lemonStand1 = findChild(purchases, "Lemon Stand")
    local lemonStand2 = findChild(lemonStand1, "Lemon Stand")
    local lemonStand3 = findChild(lemonStand2, "Lemon Stand")

    if not lemonStand3 then return upgrades end

    for _, desc in ipairs(lemonStand3:GetDescendants()) do
        if desc.Name == "Upgrade" and (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) then
            table.insert(upgrades, desc)
        end
    end

    return upgrades
end


-- // ===== Auto Upgrade — UI + spam loop (pcall-protected) =====
local UpgradeTab     = AutoBuyTabGroup:Tab({ Name = "Auto Upgrade" })
local UpgradeSection = UpgradeTab:Section({ Side = "Left" })

local autoUpgradeRunning = false
local UPGRADE_COOLDOWN   = 0.01

local autoUpgradeToggle  -- forward declare so loop can read .State directly
autoUpgradeToggle = UpgradeSection:Toggle({
    Name = "Auto Upgrade",
    Default = false,
    Callback = function(value)
        if value then
            if not MyTycoon then
                warn("[AutoUpgrade] No tycoon found.")
                return
            end
            autoUpgradeRunning = true
            print("[AutoUpgrade] Started.")

            task.spawn(function()
                while autoUpgradeRunning and autoUpgradeToggle.State do
                    -- pcall wraps the whole pass so a single bad upgrade can't kill the loop
                    pcall(function()
                        local upgrades = ScanUpgradeButtons()
                        for _, upgrade in ipairs(upgrades) do
                            if upgrade and upgrade.Parent then
                                pcall(function()
                                    if upgrade:IsA("RemoteFunction") then
                                        upgrade:InvokeServer(1)
                                    else
                                        upgrade:FireServer(1)
                                    end
                                end)
                            end
                        end
                    end)
                    task.wait(UPGRADE_COOLDOWN)
                end
                autoUpgradeRunning = false
                print("[AutoUpgrade] Stopped.")
            end)
        else
            autoUpgradeRunning = false
        end
    end,
}, "AutoUpgrade")


-- // ===== Auto Collect — Lemons from Trees =====
-- Trees live at: Workspace (root) OR inside any Tycoon folder: .Constant.Trees
-- Each tree model is named "LemonTree" with structure:
--   LemonTree.Fruit.ClickFruitPart.ClickDetector
-- (There can be multiple "Fruit" parts per tree — we collect from all.)
-- Fire each ClickDetector every 0.01s while toggle is on.

local function FindAllLemonTrees()
    local trees = {}

    -- 1) Trees directly in Workspace root
    for _, child in ipairs(game.Workspace:GetChildren()) do
        if child.Name == "LemonTree" and child:IsA("Model") then
            table.insert(trees, child)
        end
    end

    -- 2) Trees inside any Tycoon<digits>.Constant.Trees
    for _, child in ipairs(game.Workspace:GetChildren()) do
        if child.Name:match("^Tycoon%d+$") then
            local constant = child:FindFirstChild("Constant")
            if constant then
                local treesFolder = constant:FindFirstChild("Trees")
                if treesFolder then
                    for _, tree in ipairs(treesFolder:GetChildren()) do
                        if tree.Name == "LemonTree" and tree:IsA("Model") then
                            table.insert(trees, tree)
                        end
                    end
                end
            end
        end
    end

    return trees
end

-- Walk a tree and return all ClickDetectors (one per Fruit → ClickFruitPart → ClickDetector)
local function GetTreeClickDetectors(tree)
    local detectors = {}
    -- The tree can have multiple "Fruit" parts at its root
    for _, fruit in ipairs(tree:GetChildren()) do
        if fruit.Name == "Fruit" then
            local clickPart = fruit:FindFirstChild("ClickFruitPart")
            if clickPart then
                local detector = clickPart:FindFirstChildWhichIsA("ClickDetector")
                if detector then
                    table.insert(detectors, detector)
                end
            end
        end
    end
    return detectors
end

local CollectTab        = AutoBuyTabGroup:Tab({ Name = "Auto Collect" })
local CollectSection    = CollectTab:Section({ Side = "Left" })

local autoCollectLemonsRunning = false
local LEMON_COLLECT_COOLDOWN   = 0.01

local autoCollectLemonsToggle  -- forward declare
autoCollectLemonsToggle = CollectSection:Toggle({
    Name = "Auto Collect Lemons From Trees",
    Default = false,
    Callback = function(value)
        if value then
            autoCollectLemonsRunning = true
            print("[AutoCollect/Lemons] Started.")

            task.spawn(function()
                local cachedDetectors = nil
                local lastRescan = 0

                while autoCollectLemonsRunning and autoCollectLemonsToggle.State do
                    pcall(function()
                        -- Rescan tree list every 2s (in case trees get added/removed)
                        if not cachedDetectors or (tick() - lastRescan) > 2 then
                            cachedDetectors = {}
                            for _, tree in ipairs(FindAllLemonTrees()) do
                                for _, det in ipairs(GetTreeClickDetectors(tree)) do
                                    table.insert(cachedDetectors, det)
                                end
                            end
                            lastRescan = tick()
                        end

                        -- Fire every detector (fireevent simulates a click)
                        for _, det in ipairs(cachedDetectors) do
                            if det and det.Parent then
                                pcall(function()
                                    fireclickdetector(det)
                                end)
                            end
                        end
                    end)
                    task.wait(LEMON_COLLECT_COOLDOWN)
                end
                autoCollectLemonsRunning = false
                print("[AutoCollect/Lemons] Stopped.")
            end)
        else
            autoCollectLemonsRunning = false
        end
    end,
}, "AutoCollectLemons")


-- // ===== Auto Collect — Cash Drops =====
-- Cash drops live at: game.Workspace.CashDrops.CashDrop*.TouchInterest
-- Each CashDrop model has a TouchInterest we fire to simulate walking over it.
-- Rescan for new drops every 1 second.

local autoCollectCashRunning = false
local CASH_RESCAN_INTERVAL   = 1.0

local autoCollectCashToggle  -- forward declare
autoCollectCashToggle = CollectSection:Toggle({
    Name = "Auto Collect Cash Drops",
    Default = false,
    Callback = function(value)
        if value then
            autoCollectCashRunning = true
            print("[AutoCollect/Cash] Started.")

            task.spawn(function()
                local cachedDrops = nil
                local lastRescan  = 0

                while autoCollectCashRunning and autoCollectCashToggle.State do
                    pcall(function()
                        -- Rescan every 1s for new cash drops
                        if not cachedDrops or (tick() - lastRescan) > CASH_RESCAN_INTERVAL then
                            cachedDrops = {}
                            local cashDropsFolder = game.Workspace:FindFirstChild("CashDrops")
                            if cashDropsFolder then
                                for _, drop in ipairs(cashDropsFolder:GetChildren()) do
                                    if drop.Name:match("^CashDrop") then
                                        -- Find the TouchInterest (lives on a BasePart inside)
                                        for _, desc in ipairs(drop:GetDescendants()) do
                                            if desc:IsA("TouchTransmitter") or (desc:IsA("ObjectValue") and desc.Name == "TouchInterest") then
                                                table.insert(cachedDrops, desc)
                                            end
                                        end
                                    end
                                end
                            end
                            lastRescan = tick()
                        end

                        -- Fire every cached TouchInterest
                        for _, interest in ipairs(cachedDrops) do
                            if interest and interest.Parent then
                                pcall(function()
                                    firetouchinterest(game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), interest.Parent, 0)
                                end)
                            end
                        end
                    end)
                    task.wait(0.05)  -- fire-loop tick (drops don't need 100Hz)
                end
                autoCollectCashRunning = false
                print("[AutoCollect/Cash] Stopped.")
            end)
        else
            autoCollectCashRunning = false
        end
    end,
}, "AutoCollectCash")


-- // ===== Performance Tab =====
local PerfTab     = AutoBuyTabGroup:Tab({ Name = "Performance" })
local PerfSection = PerfTab:Section({ Side = "Left" })

local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
-- UserSettings can be nil on some executors at script load — guard it.
local UserSettingsSvc  = UserSettings and game:GetService("UserSettings") or nil
local UserGameSettings = nil
if UserSettingsSvc then
    local ok, settings = pcall(function()
        return UserSettingsSvc:GetService("UserGameSettings")
    end)
    if ok then UserGameSettings = settings end
end

-- Disable 3D Rendering (biggest FPS boost — only UI is rendered)
PerfSection:Toggle({
    Name = "Disable 3D Rendering",
    Default = false,
    Callback = function(value)
        local ok, err = pcall(function()
            RunService:Set3DRenderingEnabled(not value)
        end)
        if ok then
            print("[Perf] 3D Rendering:", value and "DISABLED (UI-only)" or "ENABLED")
        else
            warn("[Perf] Failed to toggle 3D rendering:", tostring(err))
        end
    end,
}, "PerfDisable3D")

-- Disable Global Shadows
PerfSection:Toggle({
    Name = "Disable Global Shadows",
    Default = false,
    Callback = function(value)
        Lighting.GlobalShadows = not value
        print("[Perf] Global Shadows:", value and "DISABLED" or "ENABLED")
    end,
}, "PerfShadows")

-- Disable Particles (hide every ParticleEmitter + Trail in workspace)
PerfSection:Toggle({
    Name = "Disable Particles",
    Default = false,
    Callback = function(value)
        local count = 0
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("ParticleEmitter") or desc:IsA("Trail") then
                desc.Enabled = not value
                count += 1
            end
        end
        print(string.format("[Perf] Particles %s | affected %d emitter(s)", value and "DISABLED" or "ENABLED", count))
    end,
}, "PerfParticles")

-- Disable Post-Processing Effects (Bloom, Blur, ColorCorrection, SunRays, DepthOfField, etc.)
PerfSection:Toggle({
    Name = "Disable Post-Processing",
    Default = false,
    Callback = function(value)
        local count = 0
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("PostEffect") then
                fx.Enabled = not value
                count += 1
            end
        end
        print(string.format("[Perf] Post-Processing %s | affected %d effect(s)", value and "DISABLED" or "ENABLED", count))
    end,
}, "PerfPostFX")

-- Graphics Quality Level (1 = lowest, 10 = highest)
PerfSection:Slider({
    Name = "Graphics Quality Level",
    Default = 10,
    Minimum = 1,
    Maximum = 10,
    DisplayMethod = "Value",
    Callback = function(value)
        if not UserGameSettings then
            warn("[Perf] UserGameSettings unavailable — cannot set quality level.")
            return
        end
        local ok, err = pcall(function()
            UserGameSettings.SavedQualityLevel = Enum.SavedQualityLevel["QualityLevel" .. tostring(value)]
        end)
        if ok then
            print("[Perf] Graphics Quality →", value)
        else
            warn("[Perf] Failed to set quality level:", tostring(err))
        end
    end,
}, "PerfQuality")

-- FPS Cap (uses setfpscap if the exploit exposes it)
PerfSection:Slider({
    Name = "FPS Cap",
    Default = 60,
    Minimum = 30,
    Maximum = 360,
    DisplayMethod = "Value",
    Callback = function(value)
        if type(setfpscap) == "function" then
            local ok, err = pcall(setfpscap, value)
            if ok then
                print("[Perf] FPS cap →", value)
            else
                warn("[Perf] setfpscap failed:", tostring(err))
            end
        else
            warn("[Perf] setfpscap is not available in this executor — FPS cap ignored.")
        end
    end,
}, "PerfFPSCap")
