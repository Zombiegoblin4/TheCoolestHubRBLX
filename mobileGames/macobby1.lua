-- DirtLib laden
local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/dirt", true))()
local Table = {}

-- Window
local window = Lib:CreateWindow("TheCoolest Hub!")
window:Section("Automation")

-----------------------------------------------------
-- AUTO-COMPLETE BUTTON (41 checkpoints + retry logic)
-----------------------------------------------------
window:Button("Auto-Complete", function()
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    local folder = workspace:WaitForChild("Checkpoints")

    for i = 1, 41 do
        local cp = folder:FindFirstChild("Checkpoint " .. i)
        if not cp then
            warn("Checkpoint " .. i .. " niet gevonden.")
            continue
        end

        local success = false
        local attempts = 0

        repeat
            attempts += 1
            local targetPart

            if cp:IsA("Model") then
                targetPart = cp.PrimaryPart or cp:FindFirstChildWhichIsA("BasePart")
            elseif cp:IsA("BasePart") then
                targetPart = cp
            end

            if targetPart then
                hrp.CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
                success = true
            else
                warn("Checkpoint " .. cp.Name .. " heeft geen BasePart, poging " .. attempts)
            end

            task.wait(0.2)
        until success or attempts >= 10
    end

    window:String({string = "All 41 Checkpoints Completed! 😎🔥"})
end)
