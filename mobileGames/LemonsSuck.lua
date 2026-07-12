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


-- // ===== Auto Buy — UI + fast loop (real-time attribute checks) =====
Window:Section("Auto Buy")

local autoBuyRunning = false
local BUY_COOLDOWN   = 0.05   -- slightly slower to reduce spam

-- Weak table: once a button is Purchased, we blacklist it forever.
local PurchasedBlacklist = setmetatable({}, { __mode = "k" })

-- Per-button retry cooldown: prevents spamming the same button.
local ButtonCooldowns = setmetatable({}, { __mode = "k" })
local BUTTON_COOLDOWN_TIME = 3.0

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
                    local now = tick()

                    for _, entry in ipairs(buttons) do
                        local btn      = entry.button
                        local purchase = entry.purchase

                        if not btn or not btn.Parent then continue end
                        if not purchase or not purchase.Parent then continue end
                        if PurchasedBlacklist[btn] then continue end

                        -- Skip if on cooldown
                        local readyAt = ButtonCooldowns[btn] or 0
                        if now < readyAt then continue end

                        -- Attribute checks
                        local isPurchased = false
                        local isHidden    = false

                        if btn:GetAttribute("Purchased") == true then isPurchased = true end
                        if btn:GetAttribute("Shown")    == false then isHidden    = true end

                        if not isPurchased and not isHidden then
                            for _, desc in ipairs(btn:GetDescendants()) do
                                if desc:GetAttribute("Purchased") == true then isPurchased = true break end
                                if desc:GetAttribute("Shown")    == false then isHidden    = true break end
                            end
                        end

                        if isPurchased then
                            PurchasedBlacklist[btn] = true
                            continue
                        end
                        if isHidden then continue end

                        -- Fire and set cooldown
                        pcall(function()
                            purchase:InvokeServer(false)
                        end)
                        ButtonCooldowns[btn] = now + BUTTON_COOLDOWN_TIME
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


-- // ===== Auto Upgrade — scanner (generic, works for any theme) =====
-- Pattern: MyTycoon.Purchases.<Theme>.<Theme>.<Theme>.Upgrade
local function ScanUpgradeButtons()
    local upgrades = {}
    if not MyTycoon then return upgrades end

    local purchases = MyTycoon:FindFirstChild("Purchases")
    if not purchases then return upgrades end

    for _, theme1 in ipairs(purchases:GetChildren()) do
        if theme1:IsA("Folder") or theme1:IsA("Model") then
            local theme2 = theme1:FindFirstChild(theme1.Name)
            if theme2 then
                local theme3 = theme2:FindFirstChild(theme2.Name)
                if theme3 then
                    for _, desc in ipairs(theme3:GetDescendants()) do
                        if desc.Name == "Upgrade" and (desc:IsA("RemoteFunction") or desc:IsA("RemoteEvent")) then
                            table.insert(upgrades, desc)
                        end
                    end
                end
            end
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

-- Get the player's torso part (works for both R6 and R15)
local function GetPlayerTorso()
    local char = LocalPlayer.Character
    if not char then return nil end
    -- HumanoidRootPart exists in both R6 and R15 — use it as primary
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp end
    -- R6 fallback
    local torso = char:FindFirstChild("Torso")
    if torso then return torso end
    -- R15 fallbacks
    local upperTorso = char:FindFirstChild("UpperTorso")
    if upperTorso then return upperTorso end
    local lowerTorso = char:FindFirstChild("LowerTorso")
    if lowerTorso then return lowerTorso end
    return nil
end


-- // ===== Auto Collect — UI =====
Window:Section("Auto Collect")

-- Lemon collect speed (seconds between collecting from each tree)
local LemonCollectSpeed = 0.5

Window:Slider("Lemon Collect Speed", { location = Table, min = 0.05, max = 3, default = 0.5, precise = true, flag = "LemonCollectSpeed" }, function()
    LemonCollectSpeed = tonumber(Table["LemonCollectSpeed"]) or 0.5
end)

local autoCollectLemonsRunning = false

Window:Toggle("Auto Collect Lemons From Trees", { location = Table, flag = "AutoCollectLemons" }, function()
    if Table["AutoCollectLemons"] then
        autoCollectLemonsRunning = true
        print("[AutoCollect/Lemons] Started.")

        task.spawn(function()
            while autoCollectLemonsRunning and Table["AutoCollectLemons"] do
                pcall(function()
                    local trees = FindAllLemonTrees()
                    local torso = GetPlayerTorso()
                    local originalCFrame = torso and torso.CFrame or nil

                    -- Process trees ONE AT A TIME: teleport → 0.5s settle → collect all fruit → next tree
                    for _, tree in ipairs(trees) do
                        if not (autoCollectLemonsRunning and Table["AutoCollectLemons"]) then break end

                        local detectors = GetTreeClickDetectors(tree)
                        if #detectors == 0 then continue end  -- no fruit on this tree, skip

                        -- Teleport to the tree (use first detector's part as anchor)
                        local anchorPart = detectors[1].Parent
                        if torso and anchorPart and anchorPart:IsA("BasePart") then
                            pcall(function()
                                torso.CFrame = anchorPart.CFrame + Vector3.new(0, 3, 0)
                            end)
                        end

                        -- 0.5s settle delay (anti-epileptic)
                        task.wait(0.5)
                        if not (autoCollectLemonsRunning and Table["AutoCollectLemons"]) then break end

                        -- Collect every fruit on this tree
                        for _, det in ipairs(detectors) do
                            if det and det.Parent then
                                pcall(function()
                                    fireclickdetector(det)
                                end)
                            end
                        end

                        -- Wait the user-configured speed before moving to the next tree
                        task.wait(LemonCollectSpeed)
                    end

                    -- Restore original position after this full pass
                    if torso and originalCFrame then
                        pcall(function()
                            torso.CFrame = originalCFrame
                        end)
                    end
                end)
                -- Small idle wait before next full tree pass
                task.wait(0.1)
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

                    -- TELEPORT-BEFORE-COLLECT: teleport player torso to each
                    -- cash drop's position before firing the touch interest.
                    local torso = GetPlayerTorso()
                    local originalCFrame = torso and torso.CFrame or nil

                    for _, interest in ipairs(cachedDrops) do
                        if interest and interest.Parent and interest.Parent:IsA("BasePart") then
                            -- Teleport torso to the cash drop part
                            if torso then
                                pcall(function()
                                    torso.CFrame = interest.Parent.CFrame + Vector3.new(0, 3, 0)
                                end)
                                task.wait()  -- 1 frame so game registers position
                            end
                            pcall(function()
                                firetouchinterest(torso, interest.Parent, 0)
                            end)
                        end
                    end

                    -- Restore original position after collecting all drops
                    if torso and originalCFrame then
                        pcall(function()
                            torso.CFrame = originalCFrame
                        end)
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


-- // ===== Clicker — Income Streams =====
-- Each toggle fires MyTycoon.Remotes.WakeIncomeStream:InvokeServer(streamName)
Window:Section("Clicker")

local INCOME_STREAMS = {
    { label = "Lemon Trading",   name = "LemonTrading" },
    { label = "Lemon Stand",     name = "LemonStand" },
    { label = "Lemon Depot",     name = "LemonDepot" },
    { label = "LemonX",          name = "LemonX" },
    { label = "Lemon Republic",  name = "LemonRepublic" },
}

local CLICKER_COOLDOWN = 0.5
local activeStreams = {}

local function GetWakeIncomeStream()
    if not MyTycoon then return nil end
    local remotes = MyTycoon:FindFirstChild("Remotes")
    if not remotes then return nil end
    local remote = remotes:FindFirstChild("WakeIncomeStream")
    if remote and remote:IsA("RemoteFunction") then return remote end
    return nil
end

for _, stream in ipairs(INCOME_STREAMS) do
    local streamName = stream.name
    local streamLabel = stream.label

    Window:Toggle(streamLabel, { location = Table, flag = "Clicker_" .. streamName }, function()
        if Table["Clicker_" .. streamName] then
            activeStreams[streamName] = true
            print(string.format("[Clicker] %s started.", streamLabel))
            task.spawn(function()
                while activeStreams[streamName] and Table["Clicker_" .. streamName] do
                    local remote = GetWakeIncomeStream()
                    if remote then
                        pcall(function()
                            remote:InvokeServer(streamName)
                        end)
                    end
                    task.wait(CLICKER_COOLDOWN)
                end
                activeStreams[streamName] = false
                print(string.format("[Clicker] %s stopped.", streamLabel))
            end)
        else
            activeStreams[streamName] = false
        end
    end)
end

-- "Fire All Streams" toggle
local fireAllRunning = false
Window:Toggle("Fire All Streams", { location = Table, flag = "Clicker_FireAll" }, function()
    if Table["Clicker_FireAll"] then
        fireAllRunning = true
        print("[Clicker] Fire All started.")
        task.spawn(function()
            while fireAllRunning and Table["Clicker_FireAll"] do
                local remote = GetWakeIncomeStream()
                if remote then
                    for _, stream in ipairs(INCOME_STREAMS) do
                        pcall(function()
                            remote:InvokeServer(stream.name)
                        end)
                    end
                end
                task.wait(CLICKER_COOLDOWN)
            end
            fireAllRunning = false
            print("[Clicker] Fire All stopped.")
        end)
    else
        fireAllRunning = false
    end
end)


-- // ===== Phone Offers =====
-- Listens for MyTycoon.Remotes.PhoneOffer.OnClientEvent firing with `true`.
-- When it fires, waits 3 seconds, then calls PhoneOffer:FireServer("Accept").
Window:Section("Phone Offers")

local autoPhoneOffersRunning = false
local phoneOfferConnection = nil

Window:Toggle("Auto Accept Phone Offers", { location = Table, flag = "AutoPhoneOffers" }, function()
    if Table["AutoPhoneOffers"] then
        autoPhoneOffersRunning = true
        print("[PhoneOffers] Started.")

        task.spawn(function()
            -- Keep trying to attach the listener
            while autoPhoneOffersRunning and Table["AutoPhoneOffers"] do
                if MyTycoon then
                    local remotes = MyTycoon:FindFirstChild("Remotes")
                    if remotes then
                        local phoneOffer = remotes:FindFirstChild("PhoneOffer")
                        if phoneOffer and phoneOffer:IsA("RemoteEvent") then
                            if phoneOfferConnection then
                                pcall(function() phoneOfferConnection:Disconnect() end)
                            end
                            phoneOfferConnection = phoneOffer.OnClientEvent:Connect(function(accepted)
                                if not autoPhoneOffersRunning or not Table["AutoPhoneOffers"] then return end
                                if accepted == true then
                                    print("[PhoneOffers] Phone offer received! Waiting 3s before accepting...")
                                    task.delay(3, function()
                                        if not autoPhoneOffersRunning or not Table["AutoPhoneOffers"] then return end
                                        if not MyTycoon then return end
                                        local remotes2 = MyTycoon:FindFirstChild("Remotes")
                                        if remotes2 then
                                            local phoneOffer2 = remotes2:FindFirstChild("PhoneOffer")
                                            if phoneOffer2 and phoneOffer2:IsA("RemoteEvent") then
                                                pcall(function()
                                                    phoneOffer2:FireServer("Accept")
                                                end)
                                                print("[PhoneOffers] Accept sent!")
                                            end
                                        end
                                    end)
                                end
                            end)
                            print("[PhoneOffers] Listening for phone offers on", phoneOffer:GetFullName())
                            while autoPhoneOffersRunning and Table["AutoPhoneOffers"] do
                                task.wait(0.5)
                            end
                            if phoneOfferConnection then
                                pcall(function() phoneOfferConnection:Disconnect() end)
                                phoneOfferConnection = nil
                            end
                            return
                        end
                    end
                end
                task.wait(1)
            end
            autoPhoneOffersRunning = false
            if phoneOfferConnection then
                pcall(function() phoneOfferConnection:Disconnect() end)
                phoneOfferConnection = nil
            end
            print("[PhoneOffers] Stopped.")
        end)
    else
        autoPhoneOffersRunning = false
        if phoneOfferConnection then
            pcall(function() phoneOfferConnection:Disconnect() end)
            phoneOfferConnection = nil
        end
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
