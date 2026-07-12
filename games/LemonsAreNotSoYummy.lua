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


-- // ===== Auto Buy — UI + fast loop (real-time attribute checks) =====
local AutoBuyTabGroup = Window:TabGroup()
local AutoBuyTab      = AutoBuyTabGroup:Tab({ Name = "Auto Buy" })
local AutoBuySection  = AutoBuyTab:Section({ Side = "Left" })

local autoBuyRunning = false
local BUY_COOLDOWN   = 0.05   -- throttle between full passes (slightly slower to reduce spam)

-- Weak table: once a button is Purchased, we blacklist it forever and never
-- check its attributes again. Weak keys mean destroyed buttons get GC'd.
local PurchasedBlacklist = setmetatable({}, { __mode = "k" })

-- Per-button retry cooldown: after firing InvokeServer on a button, wait this
-- long before trying it again. Prevents spamming the same button.
local ButtonCooldowns = setmetatable({}, { __mode = "k" })
local BUTTON_COOLDOWN_TIME = 3.0    -- seconds between retries on the same button

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
                    pcall(function()
                        local buttons = GetCachedButtons()
                        local now = tick()

                        for _, entry in ipairs(buttons) do
                            local btn      = entry.button
                            local purchase = entry.purchase

                            -- Skip destroyed buttons
                            if not btn or not btn.Parent then continue end
                            if not purchase or not purchase.Parent then continue end

                            -- Skip blacklisted (already purchased)
                            if PurchasedBlacklist[btn] then continue end

                            -- Skip if on cooldown (prevents spamming the same button)
                            local readyAt = ButtonCooldowns[btn] or 0
                            if now < readyAt then continue end

                            -- Real-time attribute checks on button root + descendants
                            --   Purchased == true → blacklist & skip forever
                            --   Shown == false    → skip (explicitly hidden)
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

                            -- Fire InvokeServer and set cooldown
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
    end,
}, "AutoBuyNext")


-- // ===== Auto Upgrade — scanner (generic, works for any theme) =====
-- Pattern: MyTycoon.Purchases.<Theme>.<Theme>.<Theme>.Upgrade
-- Where <Theme> can be "Lemon Stand", "Lemon Depot", "LemonX", "Lemon Republic", etc.
-- We scan Purchases for ANY folder, then check if it has a child with the same
-- name, and THAT has a child with the same name (3x nested). Inside the 3rd level,
-- we find any descendant named "Upgrade" (RemoteFunction or RemoteEvent).
local function ScanUpgradeButtons()
    local upgrades = {}
    if not MyTycoon then return upgrades end

    local purchases = MyTycoon:FindFirstChild("Purchases")
    if not purchases then return upgrades end

    -- Iterate every direct child of Purchases (these are the theme folders)
    for _, theme1 in ipairs(purchases:GetChildren()) do
        if theme1:IsA("Folder") or theme1:IsA("Model") then
            -- Look for a child with the same name (2nd level)
            local theme2 = theme1:FindFirstChild(theme1.Name)
            if theme2 then
                -- Look for a child with the same name (3rd level)
                local theme3 = theme2:FindFirstChild(theme2.Name)
                if theme3 then
                    -- Found the 3x nested theme folder! Find all Upgrade remotes inside.
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

local CollectTab        = AutoBuyTabGroup:Tab({ Name = "Auto Collect" })
local CollectSection    = CollectTab:Section({ Side = "Left" })

-- Lemon collect speed (seconds between collecting from each tree)
local LemonCollectSpeed = 0.5

-- Slider for the collect speed (lower = faster tree-to-tree, more epileptic)
local lemonSpeedSlider
lemonSpeedSlider = CollectSection:Slider({
    Name = "Lemon Collect Speed",
    Default = 0.5,
    Minimum = 0.05,
    Maximum = 3,
    DisplayMethod = "Value",
    Precision = 2,
    Callback = function(value)
        LemonCollectSpeed = value
    end,
}, "LemonCollectSpeed")

local autoCollectLemonsRunning = false

local autoCollectLemonsToggle  -- forward declare
autoCollectLemonsToggle = CollectSection:Toggle({
    Name = "Auto Collect Lemons From Trees",
    Default = false,
    Callback = function(value)
        if value then
            autoCollectLemonsRunning = true
            print("[AutoCollect/Lemons] Started.")

            task.spawn(function()
                while autoCollectLemonsRunning and autoCollectLemonsToggle.State do
                    pcall(function()
                        local trees = FindAllLemonTrees()
                        local torso = GetPlayerTorso()
                        local originalCFrame = torso and torso.CFrame or nil

                        -- Process trees ONE AT A TIME: teleport → 0.5s settle → collect all fruit → next tree
                        for _, tree in ipairs(trees) do
                            if not (autoCollectLemonsRunning and autoCollectLemonsToggle.State) then break end

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
                            if not (autoCollectLemonsRunning and autoCollectLemonsToggle.State) then break end

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
    end,
}, "AutoCollectLemons")


-- // ===== Auto Collect — Cash Drops =====
-- Cash drops live at: game.Workspace.CashDrops.CashDrop*.TouchInterest
-- Each CashDrop model has a TouchInterest we fire to simulate walking over it.
-- Rescan for new drops every 1 second.
-- TELEPORT-BEFORE-COLLECT: teleport player torso to each drop before firing.

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


-- // ===== Clicker Tab — Income Streams =====
-- Each toggle fires MyTycoon.Remotes.WakeIncomeStream:InvokeServer(streamName)
-- on a loop while enabled. "Fire All" hits every stream at once.
local ClickerTab     = AutoBuyTabGroup:Tab({ Name = "Clicker" })
local ClickerSection = ClickerTab:Section({ Side = "Left" })

-- Known income stream names (add more as discovered via Cobalt)
local INCOME_STREAMS = {
    { label = "Lemon Trading",   name = "LemonTrading" },
    { label = "Lemon Stand",     name = "LemonStand" },
    { label = "Lemon Depot",     name = "LemonDepot" },
    { label = "LemonX",          name = "LemonX" },
    { label = "Lemon Republic",  name = "LemonRepublic" },
}

local CLICKER_COOLDOWN = 0.5  -- seconds between fires per stream

-- Track which streams are active
local activeStreams = {}  -- streamName -> true/false

-- Helper: find the WakeIncomeStream remote on the player's tycoon
local function GetWakeIncomeStream()
    if not MyTycoon then return nil end
    local remotes = MyTycoon:FindFirstChild("Remotes")
    if not remotes then return nil end
    local remote = remotes:FindFirstChild("WakeIncomeStream")
    if remote and remote:IsA("RemoteFunction") then return remote end
    return nil
end

-- Create a toggle for each income stream
for _, stream in ipairs(INCOME_STREAMS) do
    local streamName = stream.name
    local streamLabel = stream.label

    ClickerSection:Toggle({
        Name = streamLabel,
        Default = false,
        Callback = function(value)
            if value then
                activeStreams[streamName] = true
                print(string.format("[Clicker] %s started.", streamLabel))
                task.spawn(function()
                    while activeStreams[streamName] do
                        local remote = GetWakeIncomeStream()
                        if remote then
                            pcall(function()
                                remote:InvokeServer(streamName)
                            end)
                        end
                        task.wait(CLICKER_COOLDOWN)
                    end
                    print(string.format("[Clicker] %s stopped.", streamLabel))
                end)
            else
                activeStreams[streamName] = false
            end
        end,
    }, "Clicker_" .. streamName)
end

-- "Fire All Streams" toggle — activates every stream at once
ClickerSection:Divider()

local fireAllRunning = false
ClickerSection:Toggle({
    Name = "Fire All Streams",
    Default = false,
    Callback = function(value)
        if value then
            fireAllRunning = true
            print("[Clicker] Fire All started.")
            task.spawn(function()
                while fireAllRunning do
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
                print("[Clicker] Fire All stopped.")
            end)
        else
            fireAllRunning = false
        end
    end,
}, "Clicker_FireAll")


-- // ===== Phone Offers Tab =====
-- Listens for MyTycoon.Remotes.PhoneOffer.OnClientEvent firing with `true`.
-- When it fires, waits 3 seconds, then calls PhoneOffer:FireServer("Accept").
local PhoneTab     = AutoBuyTabGroup:Tab({ Name = "Phone Offers" })
local PhoneSection = PhoneTab:Section({ Side = "Left" })

local autoPhoneOffersRunning = false
local phoneOfferConnection = nil

local autoPhoneOffersToggle  -- forward declare
autoPhoneOffersToggle = PhoneSection:Toggle({
    Name = "Auto Accept Phone Offers",
    Default = false,
    Callback = function(value)
        if value then
            if not MyTycoon then
                warn("[PhoneOffers] No tycoon found.")
                return
            end
            autoPhoneOffersRunning = true
            print("[PhoneOffers] Started.")

            task.spawn(function()
                -- Keep trying to attach the listener (MyTycoon might change or Remotes might not exist yet)
                while autoPhoneOffersRunning and autoPhoneOffersToggle.State do
                    if MyTycoon then
                        local remotes = MyTycoon:FindFirstChild("Remotes")
                        if remotes then
                            local phoneOffer = remotes:FindFirstChild("PhoneOffer")
                            if phoneOffer and phoneOffer:IsA("RemoteEvent") then
                                -- Disconnect old connection if re-attaching
                                if phoneOfferConnection then
                                    pcall(function() phoneOfferConnection:Disconnect() end)
                                end
                                phoneOfferConnection = phoneOffer.OnClientEvent:Connect(function(accepted)
                                    if not autoPhoneOffersRunning or not autoPhoneOffersToggle.State then return end
                                    -- Only accept if the offer is `true` (an incoming offer)
                                    if accepted == true then
                                        print("[PhoneOffers] Phone offer received! Waiting 3s before accepting...")
                                        task.delay(3, function()
                                            if not autoPhoneOffersRunning or not autoPhoneOffersToggle.State then return end
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
                                -- Wait until toggle is turned off, then disconnect
                                while autoPhoneOffersRunning and autoPhoneOffersToggle.State do
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
                    task.wait(1)  -- retry every 1s until PhoneOffer is found
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
    end,
}, "AutoPhoneOffers")


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
