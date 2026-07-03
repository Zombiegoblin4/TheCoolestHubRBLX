-- DirtLib laden
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/dirt", true))()
local Table = {}

-- Window
local window = Lib:CreateWindow("TheCoolest Hub!")
window:Section("Teleportation")

-----------------------------------------------------
-- AUTO-COMPLETE BUTTON
-----------------------------------------------------
window:Button("Auto-Complete", function()
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local folder = game.Workspace:WaitForChild("Checkpoints")

    local index = 1
    local reachedEnd = false

    while true do
        local cp = folder:FindFirstChild(tostring(index))
        if not cp then
            reachedEnd = true
            break
        end

        if cp:IsA("Model") then
            local pp = cp.PrimaryPart or cp:FindFirstChildWhichIsA("BasePart")
            if pp then
                hrp.CFrame = pp.CFrame + Vector3.new(0, 2, 0)
            else
                warn("Checkpoint " .. cp.Name .. " heeft geen BasePart om naar te teleporteren.")
            end
        elseif cp:IsA("BasePart") then
            hrp.CFrame = cp.CFrame + Vector3.new(0, 2, 0)
        end

        index += 1
        task.wait(0.1)
    end

    if reachedEnd then
        window:String({string = "All Checkpoints Completed! 😎🔥"})
    end
end)

-----------------------------------------------------
-- TELEPORT SLIDER
-----------------------------------------------------
window:Slider("Teleport to Stage", {
    location = Table,
    flag = "StageTP",
    min = 1,
    max = 575,
    default = 1,
    precise = false
}, function(Value)

    local Stage = math.floor(Value + 0.5)

    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local folder = game.Workspace:WaitForChild("Checkpoints")
    local cp = folder:FindFirstChild(tostring(Stage))

    if cp then
        local tpPart

        if cp:IsA("Model") then
            tpPart = cp.PrimaryPart or cp:FindFirstChildWhichIsA("BasePart")
        elseif cp:IsA("BasePart") then
            tpPart = cp
        end

        if tpPart then
            hrp.CFrame = tpPart.CFrame + Vector3.new(0, 2, 0)
        else
            window:String({string = "Stage " .. Stage .. " heeft geen teleporteerbare part."})
        end
    else
        window:String({string = "Stage " .. Stage .. " bestaat niet."})
    end
end)

-----------------------------------------------------
-- OPTIONAL: SEARCH BAR (zoals in jouw voorbeeld)
-----------------------------------------------------
window:Search(Color3.fromRGB(255, 0, 255))
