-- // TheCoolest Hub — dirt UI version
-- Same functionality as the Maclib version, but using the "dirt" UI library.
-- API notes for dirt:
--   * Toggle/Slider/Dropdown/Bind/Box callbacks fire with NO argument.
--     Current state MUST be read from the options.location[flag] table.
--   * No tabs — everything lives in one window, separated by Window:Section().
--   * No Window:Notify / Window:Dialog — not used in this script anyway.


-- // ===== Tycoon Scanner — runs BEFORE UI lib loads =====
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local MyTycoon = nil        -- the Tycoon folder Instance (e.g. Workspace.Tycoon3)
local MyTycoonNumber = nil  -- integer extracted from the name (e.g. 3)

local function tycoonMatchesOwner(tycoonFolder)
    local owner = tycoonFolder:FindFirstChild("Owner")
    if not owner then return false end
    if owner:IsA("ObjectValue") and owner.Value == LocalPlayer then return true end
    if owner:IsA("ObjectValue") and owner.Value and owner.Value.Name == LocalPlayer.Name then return true end
    if owner:IsA("StringValue") and owner.Value == LocalPlayer.Name then return true end
    if tycoonFolder:GetAttribute("Owner") == LocalPlayer.Name then return true end
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
            warn(string.format("[Tycoon Scanner] No tycoon found for %s after 30s.", LocalPlayer.Name))
        end
    end)
end
-- // ===== End Tycoon Scanner =====


-- // ===== Load dirt UI library =====
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/dirt", true))()
local Table = {}  -- holds all flag values (dirt reads/writes state here)
local Window = Lib:CreateWindow("TheCoolest Hub!")


-- // ===== Auto Buy — button scanner =====
--   MyTycoon
--     └─ Purchases
--          └─ [RandomFolder]   e.g. "Hills"
--               └─ Buttons
--                    ├─ <button model w/ Purchase RF>     (root-level buttons)
--                    └─ <subfolder e.g. "Roads">
--                         └─ <button model w/ Purchase RF>  (nested buttons)
local function ScanPurchaseButtons()
    local buttons = {}
    if not MyTycoon then return buttons end
    local purchases = MyTycoon:FindFirstChild("Purchases")
    if not purchases then return buttons end
    for _, randomFolder in ipairs(purchases:GetChildren()) do
        if not randomFolder:IsA("Folder") then continue end
        local buttonsFolder = randomFolder:FindFirstChild("Buttons")
        if not buttonsFolder then continue end
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
local CachedButtons = nil
local CachedButtonsDirty = true

local function MarkButtonsDirty() CachedButtonsDirty = true end

local function AttachTreeChangeListeners()
    if not MyTycoon then return end
    local purchases = MyTycoon:FindFirstChild("Purchases")
    if not purchases then return end
    purchases.ChildAdded:Connect(MarkButtonsDirty)
    purchases.ChildRemoved:Connect(MarkButtonsDirty)
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

task.spawn(function()
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
Window:Section("Auto Buy")

local autoBuyRunning = false
local BUY_COOLDOWN   = 0.01

Window:Toggle("Auto Buy (Next) Button", { location = Table, flag = "AutoBuyNext" }, function()
    if Table["AutoBuyNext"] then
        if not MyTycoon then
            warn("[AutoBuy] No tycoon found.")
            return
        end
        autoBuyRunning = true
        print("[AutoBuy] Started.")

        task.spawn(function()
            while autoBuyRunning and Table["AutoBuyNext"] do
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
end)


-- // ===== Auto Upgrade — scanner =====
-- Path: MyTycoon.Purchases["Lemon Stand"]["Lemon Stand"]["Lemon Stand"] → descendant named "Upgrade"
local function ScanUpgradeButtons()
    local upgrades = {}
    if not MyTycoon then return upgrades end

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
Window:Section("Auto Upgrade")

local autoUpgradeRunning = false
local UPGRADE_COOLDOWN   = 0.01

Window:Toggle("Auto Upgrade", { location = Table, flag = "AutoUpgrade" }, function()
    if Table["AutoUpgrade"] then
        if not MyTycoon then
            warn("[AutoUpgrade] No tycoon found.")
            return
        end
        autoUpgradeRunning = true
        print("[AutoUpgrade] Started.")

        task.spawn(function()
            while autoUpgradeRunning and Table["AutoUpgrade"] do
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
end)


-- // ===== Auto Collect — Lemons from Trees =====
-- Trees at: Workspace (root) OR inside any Tycoon<digits>.Constant.Trees
-- Each tree model "LemonTree" → Fruit.ClickFruitPart.ClickDetector
local function FindAllLemonTrees()
    local trees = {}
    for _, child in ipairs(game.Workspace:GetChildren()) do
        if child.Name == "LemonTree" and child:IsA("Model") then
            table.insert(trees, child)
        end
    end
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

local function GetTreeClickDetectors(tree)
    local detectors = {}
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


-- // ===== Auto Collect — UI =====
Window:Section("Auto Collect")

local autoCollectLemonsRunning = false
local LEMON_COLLECT_COOLDOWN   = 0.01

Window:Toggle("Auto Collect Lemons From Trees", { location = Table, flag = "AutoCollectLemons" }, function()
    if Table["AutoCollectLemons"] then
        autoCollectLemonsRunning = true
        print("[AutoCollect/Lemons] Started.")

        task.spawn(function()
            local cachedDetectors = nil
            local lastRescan = 0

            while autoCollectLemonsRunning and Table["AutoCollectLemons"] do
                pcall(function()
                    if not cachedDetectors or (tick() - lastRescan) > 2 then
                        cachedDetectors = {}
                        for _, tree in ipairs(FindAllLemonTrees()) do
                            for _, det in ipairs(GetTreeClickDetectors(tree)) do
                                table.insert(cachedDetectors, det)
                            end
                        end
                        lastRescan = tick()
                    end

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
end)


-- // ===== Auto Collect — Cash Drops =====
-- game.Workspace.CashDrops.CashDrop*.<descendant with TouchInterest>
local autoCollectCashRunning = false
local CASH_RESCAN_INTERVAL   = 1.0

Window:Toggle("Auto Collect Cash Drops", { location = Table, flag = "AutoCollectCash" }, function()
    if Table["AutoCollectCash"] then
        autoCollectCashRunning = true
        print("[AutoCollect/Cash] Started.")

        task.spawn(function()
            local cachedDrops = nil
            local lastRescan  = 0

            while autoCollectCashRunning and Table["AutoCollectCash"] do
                pcall(function()
                    if not cachedDrops or (tick() - lastRescan) > CASH_RESCAN_INTERVAL then
                        cachedDrops = {}
                        local cashDropsFolder = game.Workspace:FindFirstChild("CashDrops")
                        if cashDropsFolder then
                            for _, drop in ipairs(cashDropsFolder:GetChildren()) do
                                if drop.Name:match("^CashDrop") then
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

                    for _, interest in ipairs(cachedDrops) do
                        if interest and interest.Parent then
                            pcall(function()
                                firetouchinterest(game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), interest.Parent, 0)
                            end)
                        end
                    end
                end)
                task.wait(0.05)
            end
            autoCollectCashRunning = false
            print("[AutoCollect/Cash] Stopped.")
        end)
    else
        autoCollectCashRunning = false
    end
end)


-- // ===== Performance Tab =====
Window:Section("Performance")

local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local UserSettingsSvc  = UserSettings and game:GetService("UserSettings") or nil
local UserGameSettings = nil
if UserSettingsSvc then
    local ok, settings = pcall(function()
        return UserSettingsSvc:GetService("UserGameSettings")
    end)
    if ok then UserGameSettings = settings end
end

Window:Toggle("Disable 3D Rendering", { location = Table, flag = "PerfDisable3D" }, function()
    local value = Table["PerfDisable3D"]
    local ok, err = pcall(function()
        RunService:Set3DRenderingEnabled(not value)
    end)
    if ok then
        print("[Perf] 3D Rendering:", value and "DISABLED (UI-only)" or "ENABLED")
    else
        warn("[Perf] Failed to toggle 3D rendering:", tostring(err))
    end
end)

Window:Toggle("Disable Global Shadows", { location = Table, flag = "PerfShadows" }, function()
    local value = Table["PerfShadows"]
    Lighting.GlobalShadows = not value
    print("[Perf] Global Shadows:", value and "DISABLED" or "ENABLED")
end)

Window:Toggle("Disable Particles", { location = Table, flag = "PerfParticles" }, function()
    local value = Table["PerfParticles"]
    local count = 0
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("ParticleEmitter") or desc:IsA("Trail") then
            desc.Enabled = not value
            count += 1
        end
    end
    print(string.format("[Perf] Particles %s | affected %d emitter(s)", value and "DISABLED" or "ENABLED", count))
end)

Window:Toggle("Disable Post-Processing", { location = Table, flag = "PerfPostFX" }, function()
    local value = Table["PerfPostFX"]
    local count = 0
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("PostEffect") then
            fx.Enabled = not value
            count += 1
        end
    end
    print(string.format("[Perf] Post-Processing %s | affected %d effect(s)", value and "DISABLED" or "ENABLED", count))
end)

Window:Slider("Graphics Quality Level", { location = Table, min = 1, max = 10, default = 10, precise = false, flag = "PerfQuality" }, function()
    local value = Table["PerfQuality"]
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
end)

Window:Slider("FPS Cap", { location = Table, min = 30, max = 360, default = 60, precise = false, flag = "PerfFPSCap" }, function()
    local value = Table["PerfFPSCap"]
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
end)

print("[TheCoolest Hub] dirt UI version loaded.")
