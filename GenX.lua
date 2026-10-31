local players = game:GetService("Players")
local player = players.LocalPlayer

local VirtualInputManager = game:GetService("VirtualInputManager")
local replicatedStorage = game:GetService("ReplicatedStorage")
local muscleEvent = player:WaitForChild("muscleEvent")
local leaderstats = player:WaitForChild("leaderstats")
local rebirthsStat = leaderstats:WaitForChild("Rebirths")
local displayName = player.DisplayName
local virtualUser = game:GetService("VirtualUser")
local lighting = game:GetService("Lighting")

local library = loadstring(game:HttpGet("https://codeberg.org/PRUEBACUENTAZEUS/PaidLib/raw/branch/main/M14Library.lua", true))()

local window = library:AddWindow("M1887 | Private Version - Boss Farming", {
	title_bar = { Color3.fromRGB(138, 138, 138), Color3.fromRGB(255, 255, 255) },
	title_bar_transparency = 0.3,
	background = { Color3.fromRGB(119, 119, 119), Color3.fromRGB(200, 200, 200) },
	background_transparency = 0.1,
	main_color = Color3.fromRGB(255, 255, 255),
	min_size = Vector2.new(400, 400),
	can_resize = true,
})

player.Idled:Connect(function()
	virtualUser:CaptureController()
	virtualUser:ClickButton2(Vector2.new())
end)

local function deleteAds()
	for _, portal in pairs(game:GetDescendants()) do
		if portal.Name == "RobloxForwardPortals" then
			portal:Destroy()
		end
	end
	if _G.ads then
		_G.ads:Disconnect()
	end

	_G.ads = game.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "RobloxForwardPortals" then
			descendant:Destroy()
		end
	end)
end
deleteAds()

-- Right here comes my beautiful pet dictionary and its equip funcs

local PETS = {
    ["Omega Overlord"] = {
        repSpeed = 20,
        strength = 0,
        durability = 0,
        rebirth = 0,
    },

	["Common Boss Pet"] = {
		repSpeed = 5,
		strength = 0,
		durability = 0,
		rebirth = 0,
	},
	["Rare Boss Pet"] = {
		repSpeed = 7,
		strength = 0,
		durability = 0,
		rebirth = 0,
	},
	["Epic Boss Pet"] = {
		repSpeed = 10,
		strength = 0,
		durability = 0,
		rebirth = 0,
	},
	["Rainbow Boss Pet"] = {
		repSpeed = 10,
		strength = 8,
		durability = 0,
		rebirth = 0,
	},
	["Legendary Boss Pet"] = {
		repSpeed = 10,
		strength = 8,
		durability = 0,
		rebirth = 0,
	},
	["Mythic Boss Pet"] = {
		repSpeed = 10,
		strength = 20,
		durability = 0,
		rebirth = 0,
	},
    ["Inferno Drake"] = {
        repSpeed = 40,
        strength = 0,
        durability = 0,
        rebirth = 0,
    },
}

local MAX_PET_SLOTS = 12
local TARGET_REP_SPEED = 100

local function unequipConfiguredPets()
    for _, folder in ipairs(lp.player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                services.replicatedstorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
end

local function equipConfiguredPet(pet)
    services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
end

local function getOwnedConfiguredPets()
    local ownedPets = {}

    for _, folder in ipairs(lp.player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                local config = PETS[pet.Name]
                if config then
                    table.insert(ownedPets, {
                        instance = pet,
                        name = pet.Name,
                        repSpeed = config.repSpeed or 0,
                        strength = config.strength or 0,
                        durability = config.durability or 0,
                        rebirth = config.rebirth or 0,
                    })
                end
            end
        end
    end

    return ownedPets
end

local function equipBestFarmingPets(isCurrent)
    unequipConfiguredPets()
    if isCurrent and not isCurrent() then return end

    local pets = getOwnedConfiguredPets()
    local equipped = {}
    local equippedCount = 0
    local currentRepSpeed = 0

    table.sort(pets, function(a, b)
        return a.repSpeed > b.repSpeed
    end)

    for _, pet in ipairs(pets) do
        if equippedCount >= MAX_PET_SLOTS or currentRepSpeed >= TARGET_REP_SPEED then
            break
        end

        if pet.repSpeed > 0 then
            equipConfiguredPet(pet.instance)
            equipped[pet.instance] = true
            equippedCount = equippedCount + 1
            currentRepSpeed = currentRepSpeed + pet.repSpeed
        end
    end

    local remainingPets = {}

    for _, pet in ipairs(pets) do
        if not equipped[pet.instance] then
            table.insert(remainingPets, pet)
        end
    end

    table.sort(remainingPets, function(a, b)
        local scoreA = a.strength + a.durability
        local scoreB = b.strength + b.durability
        return scoreA > scoreB
    end)

    for _, pet in ipairs(remainingPets) do
        if equippedCount >= MAX_PET_SLOTS then
            break
        end

        if pet.strength > 0 or pet.durability > 0 then
            equipConfiguredPet(pet.instance)
            equipped[pet.instance] = true
            equippedCount = equippedCount + 1
        end
    end

    return currentRepSpeed, equippedCount
end

local function equipBestRebirthPets(isCurrent)
    unequipConfiguredPets()
    if isCurrent and not isCurrent() then return end

    local pets = getOwnedConfiguredPets()

    table.sort(pets, function(a, b)
        return a.rebirth > b.rebirth
    end)

    local equippedCount = 0
    local totalRebirthMultiplier = 0

    for _, pet in ipairs(pets) do
        if equippedCount >= MAX_PET_SLOTS then
            break
        end

        if pet.rebirth > 0 then
            equipConfiguredPet(pet.instance)
            equippedCount = equippedCount + 1
            totalRebirthMultiplier = totalRebirthMultiplier + pet.rebirth
        end
    end

    return totalRebirthMultiplier, equippedCount
end

local rebirthTab = window:AddTab("Fast Rebirth")

local function formatNumber(num)
    if num >= 1e15 then return string.format("%.2fQa", num/1e15) end
    if num >= 1e12 then return string.format("%.2fT", num/1e12) end
    if num >= 1e9 then return string.format("%.2fB", num/1e9) end
    if num >= 1e6 then return string.format("%.2fM", num/1e6) end
    if num >= 1e3 then return string.format("%.2fK", num/1e3) end
    return string.format("%.0f", num)
end

local isRunning = false
local startTime = 0
local totalElapsed = 0
local initialRebirths = rebirthsStat.Value
local lastPaceUpdate = 0

local serverLabel = rebirthTab:AddLabel("ð Stats:")
serverLabel.TextSize = 17
local timeLabel = rebirthTab:AddLabel("0d 0h 0m 0s - Inactive")
local paceLabel = rebirthTab:AddLabel("Rebirth Pace: /Hour | /Day | /Week")
local averagePaceLabel = rebirthTab:AddLabel("Average Rebirth Pace: /Hour | /Day | /Week")

paceLabel.TextSize = 15
averagePaceLabel.TextSize = 15

timeLabel.TextSize = 15
timeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)

local rebirthsStatsLabel = rebirthTab:AddLabel("Rebirths: "..formatNumber(rebirthsStat.Value).." | Gained: 0")
rebirthsStatsLabel.TextSize = 15

local lastRebirthTime = tick()
local lastRebirthValue = rebirthsStat.Value

local function updateRebirthsLabel()
    local gained = rebirthsStat.Value - initialRebirths
    rebirthsStatsLabel.Text = string.format("Rebirths: %s | Gained: %s", 
                                           formatNumber(rebirthsStat.Value),
                                           formatNumber(gained))
end

local function updateUI(forceUpdate)
    local currentTime = tick()
    local elapsed = isRunning and (currentTime - startTime + totalElapsed) or totalElapsed
    
    local days = math.floor(elapsed / 86400)
    local hours = math.floor((elapsed % 86400) / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = math.floor(elapsed % 60)
    
    local statusText = isRunning and "Rebirthing" or (elapsed > 0 and "Rebirthing Paused" or "Fast Reb Inactive")
    timeLabel.Text = string.format("%dd %dh %dm %ds - %s", days, hours, minutes, seconds, statusText)
    
    if isRunning then
        timeLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
    elseif elapsed > 0 then
        timeLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
    else
        timeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
    end
end

local paceHistoryHour = {}
local paceHistoryDay = {}
local paceHistoryWeek = {}

local maxHistoryLength = 20

local rebirthCount = 0
local savedPaceHour = 0
local savedPaceDay = 0
local savedPaceWeek = 0
local savedAvgHour = 0
local savedAvgDay = 0
local savedAvgWeek = 0

local function calculatePaceOnRebirth()
    rebirthCount = rebirthCount + 1
    if rebirthCount < 2 then
        lastRebirthTime = tick()
        lastRebirthValue = rebirthsStat.Value
        return
    end

    if not isRunning then
        return
    end

    local now = tick()
    local gained = rebirthsStat.Value - lastRebirthValue

    if gained > 0 then
        local avgTimePerRebirth = (now - lastRebirthTime) / gained
        local paceHour = 3600 / avgTimePerRebirth
        local paceDay = 86400 / avgTimePerRebirth
        local paceWeek = 604800 / avgTimePerRebirth

        savedPaceHour = paceHour
        savedPaceDay = paceDay
        savedPaceWeek = paceWeek

        paceLabel.Text = string.format("Pace: %s / Hour | %s / Day | %s / Week",
            formatNumber(paceHour), formatNumber(paceDay), formatNumber(paceWeek))

        table.insert(paceHistoryHour, paceHour)
        table.insert(paceHistoryDay, paceDay)
        table.insert(paceHistoryWeek, paceWeek)

        if #paceHistoryHour > maxHistoryLength then
            table.remove(paceHistoryHour, 1)
            table.remove(paceHistoryDay, 1)
            table.remove(paceHistoryWeek, 1)
        end

        local function average(tbl)
            local sum = 0
            for _, v in ipairs(tbl) do
                sum = sum + v
            end
            return #tbl > 0 and (sum / #tbl) or 0
        end

        local avgHour = average(paceHistoryHour)
        local avgDay = average(paceHistoryDay)
        local avgWeek = average(paceHistoryWeek)

        savedAvgHour = avgHour
        savedAvgDay = avgDay
        savedAvgWeek = avgWeek

        averagePaceLabel.Text = string.format("Average Pace: %s / Hour | %s / Day | %s / Week",
            formatNumber(avgHour), formatNumber(avgDay), formatNumber(avgWeek))

        lastRebirthTime = now
        lastRebirthValue = rebirthsStat.Value
    end
end

rebirthsStat:GetPropertyChangedSignal("Value"):Connect(function()
    calculatePaceOnRebirth()
    updateRebirthsLabel()
end)

function unequipPets()
    for _, folder in pairs(lp.player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                services.replicatedstorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
            end
        end
    end
    task.wait(0.1)
end

function equipPetsByName(name)
    unequipPets()
    task.wait(0.1) -- Slightly increased to ensure server registers the unequip request
    
    -- Iterate through ALL rarity folders (Basic, Advanced, Rare, Unique, Epic, etc.)
    for _, folder in pairs(lp.player.petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                if pet.Name == name then
                    services.replicatedstorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
                end
            end
        end
    end
end

local function doRebirth()
    local rebirths = rebirthsStat.Value
    local strengthTarget = 5000 + (rebirths * 2550)
    
    while isRunning and player.leaderstats.Strength.Value < strengthTarget do
        local reps = player.MembershipType == Enum.MembershipType.Premium and 12 or 20
        for _ = 1, reps do
            muscleEvent:FireServer("rep")
        end
        task.wait(0.02)
    end
    
    if isRunning and player.leaderstats.Strength.Value >= strengthTarget then
        managePets("Tribal Overlord")
        task.wait(0.25)
        
        local before = rebirthsStat.Value
        repeat
            replicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
            task.wait(0.05)
        until rebirthsStat.Value > before or not isRunning
    end
end

local function fastRebirthLoop()
    while isRunning do
        managePets("Swift Samurai")
        doRebirth()
        task.wait(0.5)
    end
end

rebirthTab:AddLabel("")
rebirthTab:AddLabel("Rebirthing:").TextSize = 17

rebirthTab:AddSwitch("Fast Rebirth", function(state)
    isRunning = state
    
    if state then
        startTime = tick()
        if savedPaceHour > 0 then
            paceLabel.Text = string.format("Pace: %s / Hour | %s / Day | %s / Week",
                formatNumber(savedPaceHour), formatNumber(savedPaceDay), formatNumber(savedPaceWeek))
            averagePaceLabel.Text = string.format("Average Pace: %s / Hour | %s / Day | %s / Week",
                formatNumber(savedAvgHour), formatNumber(savedAvgDay), formatNumber(savedAvgWeek))
        end
        task.spawn(fastRebirthLoop)
    else
        totalElapsed = totalElapsed + (tick() - startTime)
        updateUI(true)
    end
end)

task.spawn(function()
    while true do
        updateUI(false)
        task.wait(0.1)
    end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local autoRebirthEnabled = false

-- Gamepass ID for Auto Rebirth in Muscle Legends
local AUTO_REBIRTH_GAMEPASS_ID = 2037308953 

----------------------------------------------------------------------
-- 1. Gamepass Ownership Hook (Client-Side Bypass)
----------------------------------------------------------------------
local oldUserOwnsGamePassAsync
oldUserOwnsGamePassAsync = hookfunction(MarketplaceService.UserOwnsGamePassAsync, function(self, userId, gamepassId)
    if userId == localPlayer.UserId and gamepassId == AUTO_REBIRTH_GAMEPASS_ID then
        return true
    end
    return oldUserOwnsGamePassAsync(self, userId, gamepassId)
end)

----------------------------------------------------------------------
-- 2. Visual UI Update Function
----------------------------------------------------------------------
local function updateVisuals(state)
    pcall(function()
        -- [Image 1 Bypass] Store UI Button
        local storeGui = playerGui:FindFirstChild("storeGui")
        if storeGui then
            local autoRebirthFrame = storeGui:FindFirstChild("gamepassesFrame", true) and storeGui.gamepassesFrame:FindFirstChild("Auto Rebirth", true)
            if autoRebirthFrame then
                local buyButton = autoRebirthFrame:FindFirstChild("buyButton") or autoRebirthFrame:FindFirstChild("buy")
                if buyButton then
                    local label = buyButton:FindFirstChildWhichIsA("TextLabel")
                    if label then
                        label.Text = state and "OWNED" or "R$599"
                    end
                end
            end
        end

        -- [Image 2 Bypass] Rebirth GUI "GET AUTO" Button
        local rebirthGui = playerGui:FindFirstChild("rebirthGui")
        if rebirthGui then
            local autoBtn = rebirthGui:FindFirstChild("autoButton", true) or rebirthGui:FindFirstChild("getAuto", true)
            if autoBtn then
                local btnText = autoBtn:FindFirstChildWhichIsA("TextLabel")
                if btnText then
                    btnText.Text = state and "AUTO ON" or "GET AUTO"
                end
                autoBtn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(0, 170, 0)
            end
        end

        -- [Image 3 Bypass] Settings GUI "Auto Rebirth" Switch
        local settingsGui = playerGui:FindFirstChild("settingsGui") or playerGui:FindFirstChild("settingsMenu")
        if settingsGui then
            local autoRebirthSetting = settingsGui:FindFirstChild("Auto Rebirth", true)
            if autoRebirthSetting then
                local statusLabel = autoRebirthSetting:FindFirstChild("statusLabel") or autoRebirthSetting:FindFirstChildWhichIsA("TextLabel")
                if statusLabel then
                    statusLabel.Text = state and "ON" or "OFF"
                    statusLabel.TextColor3 = state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end)
end

----------------------------------------------------------------------
-- 3. Script Toggles & Execution
----------------------------------------------------------------------

-- Auto Rebirth Gamepass Bypass & Toggle
rebirthTab:AddSwitch("Gamepass Auto Rebirth (Bypass Version)", function(state)
    autoRebirthEnabled = state
    
    -- Set Player Attributes
    localPlayer:SetAttribute("AutoRebirthEnabled", autoRebirthEnabled)
    localPlayer:SetAttribute("HasAutoRebirthGamepass", true)
    localPlayer:SetAttribute("autoRebirth", autoRebirthEnabled)

    -- Update UI elements (Store, Rebirth Frame, Settings)
    updateVisuals(autoRebirthEnabled)

    -- Auto Rebirth Loop
    if autoRebirthEnabled then
        task.spawn(function()
            while autoRebirthEnabled do
                pcall(function()
                    local rebirthRemote = ReplicatedStorage:FindFirstChild("rEvents") and ReplicatedStorage.rEvents:FindFirstChild("rebirthRemote")
                    if rebirthRemote then
                        rebirthRemote:InvokeServer("rebirthRequest")
                    end
                end)
                task.wait(0.01) -- Frequency check for rebirths
            end
        end)
    end
end)

local farmTab = window:AddTab("Fast Farm")

local strengthStat = leaderstats:WaitForChild("Strength")
local durabilityStat = player:WaitForChild("Durability")

farmTab:AddLabel("Stats:").TextSize = 17
local stopwatchLabel = farmTab:AddLabel("0d 0h 0m 0s - Fast Rep Inactive")
stopwatchLabel.TextSize = 15
stopwatchLabel.TextColor3 = Color3.fromRGB(255, 50, 50)

local projectedStrengthLabel = farmTab:AddLabel("Strength: /Hour | /Day | /Week")
projectedStrengthLabel.TextSize = 15
local averageStrengthLabel = farmTab:AddLabel("Average: /Hour | /Day | /Week")
averageStrengthLabel.TextSize = 15
farmTab:AddLabel("")
local projectedDurabilityLabel = farmTab:AddLabel("Dura: /Hour | /Day | /Week")
projectedDurabilityLabel.TextSize = 15
local averageDurabilityLabel = farmTab:AddLabel("Average: /Hour | /Day | /Week")
averageDurabilityLabel.TextSize = 15
farmTab:AddLabel("")

local strengthLabel = farmTab:AddLabel("Strength: " .. formatNumber(strengthStat.Value) .. " | Gained: 0")
strengthLabel.TextSize = 15
local durabilityLabel = farmTab:AddLabel("Durability: " .. formatNumber(durabilityStat.Value) .. " | Gained: 0")
durabilityLabel.TextSize = 15

local startTime = 0
local pausedElapsedTime = 0
local lastPauseTime = 0

local runFastRep = false
local trackingStarted = false

local strengthHistory = {}
local durabilityHistory = {}
local calculationInterval = 10

local initialStrength = strengthStat.Value
local initialDurability = durabilityStat.Value

local savedStrengthPerHour = 0
local savedStrengthPerDay = 0
local savedStrengthPerWeek = 0
local savedDurabilityPerHour = 0
local savedDurabilityPerDay = 0
local savedDurabilityPerWeek = 0

local savedAvgStrengthPerHour = 0
local savedAvgStrengthPerDay = 0
local savedAvgStrengthPerWeek = 0
local savedAvgDurabilityPerHour = 0
local savedAvgDurabilityPerDay = 0
local savedAvgDurabilityPerWeek = 0

task.spawn(function()
    local lastCalcTime = tick()
    while true do
        local currentTime = tick()
        local currentStrength = strengthStat.Value
        local currentDurability = durabilityStat.Value

        strengthLabel.Text = "Strength: " .. formatNumber(currentStrength) .. " | Gained: " .. formatNumber(currentStrength - initialStrength)
        durabilityLabel.Text = "Durability: " .. formatNumber(currentDurability) .. " | Gained: " .. formatNumber(currentDurability - initialDurability)

        if runFastRep then
            if not trackingStarted then
                trackingStarted = true
                startTime = currentTime
                strengthHistory = {}
                durabilityHistory = {}
                
                if savedStrengthPerHour > 0 then
                    projectedStrengthLabel.Text = "Strength: " .. formatNumber(savedStrengthPerHour) .. "/Hour | " .. formatNumber(savedStrengthPerDay) .. "/Day | " .. formatNumber(savedStrengthPerWeek) .. "/Week"
                    projectedDurabilityLabel.Text = "Dura: " .. formatNumber(savedDurabilityPerHour) .. "/Hour | " .. formatNumber(savedDurabilityPerDay) .. "/Day | " .. formatNumber(savedDurabilityPerWeek) .. "/Week"
                    averageStrengthLabel.Text = "Average: " .. formatNumber(savedAvgStrengthPerHour) .. "/Hour | " .. formatNumber(savedAvgStrengthPerDay) .. "/Day | " .. formatNumber(savedAvgStrengthPerWeek) .. "/Week"
                    averageDurabilityLabel.Text = "Average: " .. formatNumber(savedAvgDurabilityPerHour) .. "/Hour | " .. formatNumber(savedAvgDurabilityPerDay) .. "/Day | " .. formatNumber(savedAvgDurabilityPerWeek) .. "/Week"
                end
            end
            
            local elapsedTime = pausedElapsedTime + (currentTime - startTime)
            local days = math.floor(elapsedTime / (24 * 3600))
            local hours = math.floor((elapsedTime % (24 * 3600)) / 3600)
            local minutes = math.floor((elapsedTime % 3600) / 60)
            local seconds = math.floor(elapsedTime % 60)
            stopwatchLabel.Text = string.format("%dd %dh %dm %ds - Farming", days, hours, minutes, seconds)
            stopwatchLabel.TextColor3 = Color3.fromRGB(50, 255, 50)

            table.insert(strengthHistory, {time = currentTime, value = currentStrength})
            table.insert(durabilityHistory, {time = currentTime, value = currentDurability})

            while #strengthHistory > 0 and currentTime - strengthHistory[1].time > calculationInterval do
                table.remove(strengthHistory, 1)
            end
            while #durabilityHistory > 0 and currentTime - durabilityHistory[1].time > calculationInterval do
                table.remove(durabilityHistory, 1)
            end

            if currentTime - lastCalcTime >= calculationInterval then
                lastCalcTime = currentTime

                if #strengthHistory >= 2 then
                    local strengthDelta = strengthHistory[#strengthHistory].value - strengthHistory[1].value
                    local strengthPerSecond = strengthDelta / calculationInterval
                    savedStrengthPerHour = strengthPerSecond * 3600
                    savedStrengthPerDay = strengthPerSecond * 86400
                    savedStrengthPerWeek = strengthPerSecond * 604800
                    projectedStrengthLabel.Text = "Strength: " .. formatNumber(savedStrengthPerHour) .. "/Hour | " .. formatNumber(savedStrengthPerDay) .. "/Day | " .. formatNumber(savedStrengthPerWeek) .. "/Week"
                end

                if #durabilityHistory >= 2 then
                    local durabilityDelta = durabilityHistory[#durabilityHistory].value - durabilityHistory[1].value
                    local durabilityPerSecond = durabilityDelta / calculationInterval
                    savedDurabilityPerHour = durabilityPerSecond * 3600
                    savedDurabilityPerDay = durabilityPerSecond * 86400
                    savedDurabilityPerWeek = durabilityPerSecond * 604800
                    projectedDurabilityLabel.Text = "Dura: " .. formatNumber(savedDurabilityPerHour) .. "/Hour | " .. formatNumber(savedDurabilityPerDay) .. "/Day | " .. formatNumber(savedDurabilityPerWeek) .. "/Week"
                end

                local totalElapsed = pausedElapsedTime + (currentTime - startTime)
                if totalElapsed > 0 then
                    local avgStrengthPerSecond = (currentStrength - initialStrength) / totalElapsed
                    savedAvgStrengthPerHour = avgStrengthPerSecond * 3600
                    savedAvgStrengthPerDay = avgStrengthPerSecond * 86400
                    savedAvgStrengthPerWeek = avgStrengthPerSecond * 604800
                    averageStrengthLabel.Text = "Average: " .. formatNumber(savedAvgStrengthPerHour) .. "/Hour | " .. formatNumber(savedAvgStrengthPerDay) .. "/Day | " .. formatNumber(savedAvgStrengthPerWeek) .. "/Week"

                    local avgDurabilityPerSecond = (currentDurability - initialDurability) / totalElapsed
                    savedAvgDurabilityPerHour = avgDurabilityPerSecond * 3600
                    savedAvgDurabilityPerDay = avgDurabilityPerSecond * 86400
                    savedAvgDurabilityPerWeek = avgDurabilityPerSecond * 604800
                    averageDurabilityLabel.Text = "Average: " .. formatNumber(savedAvgDurabilityPerHour) .. "/Hour | " .. formatNumber(savedAvgDurabilityPerDay) .. "/Day | " .. formatNumber(savedAvgDurabilityPerWeek) .. "/Week"
                end
            end
        else
            if trackingStarted then
                trackingStarted = false
                pausedElapsedTime = pausedElapsedTime + (currentTime - startTime)
                local days = math.floor(pausedElapsedTime / (24 * 3600))
                local hours = math.floor((pausedElapsedTime % (24 * 3600)) / 3600)
                local minutes = math.floor((pausedElapsedTime % 3600) / 60)
                local seconds = math.floor(pausedElapsedTime % 60)
                
                if pausedElapsedTime > 0 then
                    stopwatchLabel.Text = string.format("%dd %dh %dm %ds - Farming Paused", days, hours, minutes, seconds)
                    stopwatchLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
                else
                    stopwatchLabel.Text = "0d 0h 0m 0s - Fast Rep Inactive"
                    stopwatchLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                end

                strengthHistory = {}
                durabilityHistory = {}
            end
        end

        task.wait(0.05)
    end
end)

farmTab:AddLabel("")
farmTab:AddLabel("Fast Farm:").TextSize = 17
local farmRunning = false
local repSpeed = 350
local pingControl = true

local networkStats = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]

local function getCurrentPing()
    return networkStats:GetValue()
end

local function getAdaptiveSpeed(ping)
    if ping < 80 then
        return 500
    elseif ping < 150 then
        return 300
    elseif ping < 250 then
        return 100
    else
        return 50
    end
end

farmTab.AddTextBox(farmTab, "Rep Speed:", function(inputText)
    local speedValue = tonumber(inputText)
    if speedValue then
        repSpeed = math.clamp(math.floor(speedValue), 1, 1000)
    end
end)

farmTab.AddSwitch(farmTab, "Controlled Speed", function(isEnabled)
    pingControl = isEnabled
end):Set(true)

local function startAutoRep()
    local lastPingUpdate = time()
    local currentPing = getCurrentPing()
    while farmRunning do
        if time() - lastPingUpdate > 0.5 then
            currentPing = getCurrentPing()
            lastPingUpdate = time()
        end
        local repsToFire = pingControl and getAdaptiveSpeed(currentPing) or repSpeed
        local delayBetweenBatches = math.clamp(currentPing / 2500, 0.001, 0.1)
        for repCount = 1, math.min(repsToFire, repSpeed) do
            muscleEvent:FireServer("rep")
            if repCount % 500 == 0 then
                task.wait(0)
            end
        end
        task.wait(delayBetweenBatches)
    end
end

farmTab.AddSwitch(farmTab, "Fast Rep", function(isEnabled)
    farmRunning = isEnabled
    if farmRunning then
        runFastRep = true
        task.spawn(startAutoRep)
    else 
        runFastRep = false
        task.cancel(startAutoRep)
    end
end)

farmTab:AddLabel("Recommended Speed 20-40").TextSize = 15
farmTab:AddLabel("Try Around!")

local settingsTab = window:AddTab("Misc")

settingsTab:AddLabel("Misc 1:").TextSize = 17

local running = false
local thread = nil

local sizeSwitch = settingsTab:AddSwitch("Set Size 2", function(bool)
    running = bool
    if running then
        thread = coroutine.create(function()
            while running do
                game:GetService("ReplicatedStorage").rEvents.changeSpeedSizeRemote:InvokeServer("changeSize", 2)
                wait(0.01)
            end
        end)
        coroutine.resume(thread)
    end
end)

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

local localPlayer = Players.LocalPlayer

local afkGui = nil
local afkConnection = nil
local disconnectConnection = nil
local promptConnection = nil

-- Ilagay ang AddSwitch sa itaas
settingsTab:AddSwitch("Anti-AFK", function(state)
    if state then
        -- Clean up any existing instances just in case
        if afkGui then afkGui:Destroy() end
        if afkConnection then afkConnection:Disconnect() end
        if disconnectConnection then disconnectConnection:Disconnect() end
        if promptConnection then promptConnection:Disconnect() end

        afkGui = Instance.new("ScreenGui")
        afkGui.Name = "AntiAFKGui"
        afkGui.ResetOnSpawn = false
        afkGui.Parent = localPlayer:WaitForChild("PlayerGui")

        local titleLabel = Instance.new("TextLabel", afkGui)
        titleLabel.Size = UDim2.new(0, 200, 0, 50)
        titleLabel.Position = UDim2.new(0.5, -100, 0, -50)
        titleLabel.Text = "ANTI AFK"
        titleLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 20
        titleLabel.BackgroundTransparency = 1
        titleLabel.TextTransparency = 1

        local timerLabel = Instance.new("TextLabel", afkGui)
        timerLabel.Size = UDim2.new(0, 200, 0, 30)
        timerLabel.Position = UDim2.new(0.5, -100, 0, -20)
        timerLabel.Text = "00:00:00"
        timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        timerLabel.Font = Enum.Font.GothamBold
        timerLabel.TextSize = 18
        timerLabel.BackgroundTransparency = 1
        timerLabel.TextTransparency = 1

        local startTime = tick()

        -- Timer update task
        task.spawn(function()
            while afkGui and afkGui.Parent do
                local elapsed = tick() - startTime
                local hours = math.floor(elapsed / 3600)
                local minutes = math.floor((elapsed % 3600) / 60)
                local seconds = math.floor(elapsed % 60)
                timerLabel.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
                task.wait(1)
            end
        end)

        -- Fade animation task with safety checks after yields
        task.spawn(function()
            while afkGui and afkGui.Parent do
                for n = 0, 1, 0.02 do
                    if not afkGui or not afkGui.Parent then break end
                    titleLabel.TextTransparency = 1 - n
                    timerLabel.TextTransparency = 1 - n
                    task.wait(0.015)
                end

                task.wait(1.5)

                for i = 0, 1, 0.02 do
                    if not afkGui or not afkGui.Parent then break end
                    titleLabel.TextTransparency = i
                    timerLabel.TextTransparency = i
                    task.wait(0.015)
                end

                task.wait(1)
            end
        end)

        -- Anti-AFK event connection
        afkConnection = localPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)

        -- Anti-Disconnect & Anti-Server Shutdown (Auto Reconnect)
        disconnectConnection = CoreGui:WaitForChild("RobloxPromptGui", 5)
        if disconnectConnection then
            local promptOverlay = CoreGui.RobloxPromptGui:FindFirstChild("promptOverlay")
            if promptOverlay then
                disconnectConnection = promptOverlay.ChildAdded:Connect(function(child)
                    if child.Name == "ErrorPrompt" then
                        local message = child:FindFirstChild("MessageArea", true)
                        if message and message:FindFirstChild("ErrorFrame") then
                            task.wait(2)
                            TeleportService:Teleport(game.PlaceId, localPlayer)
                        end
                    end
                end)
            end
        end

        -- Anti-Kick (Auto-dismiss error prompts kung sakaling lumabas)
        promptConnection = GuiService.ErrorMessageChanged:Connect(function()
            local promptOverlay = CoreGui:FindFirstChild("RobloxPromptGui")
            if promptOverlay then
                local errorPrompt = promptOverlay:FindFirstChild("ErrorPrompt", true)
                if errorPrompt then
                    TeleportService:Teleport(game.PlaceId, localPlayer)
                end
            end
        end)

        -- Send Notification gamit ang pcall para maiwasan ang crash kung sakaling di pa loaded ang CoreGui
        task.spawn(function()
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "M1887 | Anti-AFK";
                    Text = "Anti-AFK successfully loaded";
                    Icon = "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=79693252930451"; -- Pinalitan ko ang format ng asset ID para mas sigurado
                    Duration = 5;
                })
            end)
        end)

    else
        -- Kapag pinatay o in-off ang switch
        if afkGui then 
            afkGui:Destroy() 
            afkGui = nil 
        end
        if afkConnection then 
            afkConnection:Disconnect() 
            afkConnection = nil 
        end
        if disconnectConnection then
            if typeof(disconnectConnection) == "RBXScriptConnection" then
                disconnectConnection:Disconnect()
            end
            disconnectConnection = nil
        end
        if promptConnection then 
            promptConnection:Disconnect() 
            promptConnection = nil 
        end
    end
end):Set(true)

settingsTab:AddSwitch("Anti Knockback", function(Value)
    if Value then
        local playerName = game.Players.LocalPlayer.Name
        local rootPart = game.Workspace:FindFirstChild(playerName):FindFirstChild("HumanoidRootPart")
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.P = 1250
        bodyVelocity.Parent = rootPart
    else
        local playerName = game.Players.LocalPlayer.Name
        local rootPart = game.Workspace:FindFirstChild(playerName):FindFirstChild("HumanoidRootPart")
        local existingVelocity = rootPart:FindFirstChild("BodyVelocity")
        if existingVelocity and existingVelocity.MaxForce == Vector3.new(100000, 0, 100000) then
            existingVelocity:Destroy()
        end
    end
end):Set(true)

local posLocked = false
local lockedPosition = nil

local function lockPosition()
	if not posLocked or not lockedPosition then
		return
	end

	local currentCharacter = player.Character
	if not currentCharacter then
		return
	end

	local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local existingPosition = rootPart:FindFirstChild("PositionLocker")

	if existingPosition then
		existingPosition.Position = lockedPosition
	else
		local bodyPosition = Instance.new("BodyPosition")
		bodyPosition.Name = "PositionLocker"
		bodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bodyPosition.Position = lockedPosition
		bodyPosition.P = 100000
		bodyPosition.Parent = rootPart
	end
end

local function unlockPosition()
	local currentCharacter = player.Character
	if currentCharacter then
		local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local existingPosition = rootPart:FindFirstChild("PositionLocker")
			if existingPosition then
				existingPosition:Destroy()
			end
		end
	end
	lockedPosition = nil
end

local lockPositionSwitch = settingsTab:AddSwitch("Lock Position", function(bool)
	posLocked = bool

	if bool then
		local currentRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if currentRootPart then
			lockedPosition = currentRootPart.Position
		end
		lockPosition()
	else
		unlockPosition()
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	local rootPart = newCharacter:WaitForChild("HumanoidRootPart", 5)
	if posLocked and rootPart then
		lockedPosition = rootPart.Position
		lockPosition()
	end
end)

task.spawn(function()
	while true do
		if posLocked then
			lockPosition()
		end
		task.wait(0.1)
	end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local autoLiftEnabled = false

----------------------------------------------------------------------
-- Script Toggles & Execution
----------------------------------------------------------------------

-- Free Auto Lift Toggle
settingsTab:AddSwitch("Gamepass Auto Lift", function(state)
    autoLiftEnabled = state
    localPlayer:SetAttribute("AutoLiftEnabled", autoLiftEnabled)
    
    pcall(function()
        local autoLiftRemote = ReplicatedStorage:FindFirstChild("rEvents") and ReplicatedStorage.rEvents:FindFirstChild("autoLiftEvent")
        if autoLiftRemote then
            autoLiftRemote:FireServer(autoLiftEnabled)
        end
    end)
end)

local blockedFrames = {
	"strengthFrame",
	"durabilityFrame",
	"agilityFrame",
	"evilKarmaFrame",
	"goodKarmaFrame",
}

local frameSwitch = settingsTab:AddSwitch("Hide Stat Frames", function(bool)
	if bool then
		for _, name in ipairs(blockedFrames) do
			local frame = replicatedStorage:FindFirstChild(name)
			if frame and frame:IsA("GuiObject") then
				frame.Visible = false
			end
		end

		if not _G.frameMonitorConnection then
			_G.frameMonitorConnection = replicatedStorage.ChildAdded:Connect(function(child)
				for _, name in ipairs(blockedFrames) do
					if child.Name == name and child:IsA("GuiObject") then
						child.Visible = false
					end
				end
			end)
		end
	else
		for _, name in ipairs(blockedFrames) do
			local frame = replicatedStorage:FindFirstChild(name)
			if frame and frame:IsA("GuiObject") then
				frame.Visible = true
			end
		end

		if _G.frameMonitorConnection then
			_G.frameMonitorConnection:Disconnect()
			_G.frameMonitorConnection = nil
		end
	end
end)
frameSwitch:Set(false)

settingsTab:AddButton("Equip Best Pets", function()
    equipBestFarmingPets()
end)


settingsTab:AddButton("Anti Lag", function()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local lighting = game:GetService("Lighting")

    for _, gui in pairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            gui:Destroy()
        end
    end

    local function darkenSky()
        for _, v in pairs(lighting:GetChildren()) do
            if v:IsA("Sky") then
                v:Destroy()
            end
        end

        local darkSky = Instance.new("Sky")
        darkSky.Name = "DarkSky"
        darkSky.SkyboxBk = "rbxassetid://0"
        darkSky.SkyboxDn = "rbxassetid://0"
        darkSky.SkyboxFt = "rbxassetid://0"
        darkSky.SkyboxLf = "rbxassetid://0"
        darkSky.SkyboxRt = "rbxassetid://0"
        darkSky.SkyboxUp = "rbxassetid://0"
        darkSky.Parent = lighting

        lighting.Brightness = 0
        lighting.ClockTime = 0
        lighting.TimeOfDay = "00:00:00"
        lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        lighting.Ambient = Color3.new(0, 0, 0)
        lighting.FogColor = Color3.new(0, 0, 0)
        lighting.FogEnd = 100

        task.spawn(function()
            while true do
                wait(5)
                if not lighting:FindFirstChild("DarkSky") then
                    darkSky:Clone().Parent = lighting
                end
                lighting.Brightness = 0
                lighting.ClockTime = 0
                lighting.OutdoorAmbient = Color3.new(0, 0, 0)
                lighting.Ambient = Color3.new(0, 0, 0)
                lighting.FogColor = Color3.new(0, 0, 0)
                lighting.FogEnd = 100
            end
        end)
    end

    local function removeParticleEffects()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                obj:Destroy()
            end
        end
    end

    local function removeLightSources()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                obj:Destroy()
            end
        end
    end

    removeParticleEffects()
    removeLightSources()
    darkenSky()
end)
    
local PlayerData = {
    Backpack = player:WaitForChild("Backpack")
}

settingsTab:AddLabel("Misc 2:").TextSize = 17

local ProteinEggLabel = settingsTab:AddLabel("Protein Eggs Owned: 0")
ProteinEggLabel.TextSize = 14

task.spawn(function()
	while true do
		local proteinEggCount = 0
		local tropicalShakeCount = 0
		if PlayerData.Backpack then
			for _, item in ipairs(PlayerData.Backpack:GetChildren()) do
				if item.Name == "Protein Egg" then proteinEggCount = proteinEggCount + 1
				elseif item.Name == "Tropical Shake" then tropicalShakeCount = tropicalShakeCount + 1 end
			end
		end
		ProteinEggLabel.Text = "Protein Eggs: " .. proteinEggCount
		task.wait(7.5)
	end
end)

local ProteinEggBoostLabel = settingsTab:AddLabel("Protein Egg Boost: 00:00")
ProteinEggBoostLabel.TextSize = 14

local function formatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%02d:%02d", m, s)
end

task.spawn(function()
    while true do
        local boostTimersFolder = game.Players.LocalPlayer:FindFirstChild("boostTimersFolder")
        if boostTimersFolder then
            local boost = boostTimersFolder:FindFirstChild("Protein Egg")
            if boost and boost:IsA("IntValue") then
                local seconds = boost.Value
                ProteinEggBoostLabel.Text = "Protein Egg Timer: " .. formatTime(seconds)
            else
                ProteinEggBoostLabel.Text = "Protein Egg Timer: 00:00"
            end
        else
            ProteinEggBoostLabel.Text = "Protein Egg Timer: 00:00"
        end
        task.wait(0.5)
    end
end)

function eatEgg()
    settingsTab.character = lp.player.Character
    settingsTab.backpack = lp.player:FindFirstChild("Backpack")
    settingsTab.tool = (settingsTab.character and settingsTab.character:FindFirstChild("Protein Egg")) or (settingsTab.backpack and settingsTab.backpack:FindFirstChild("Protein Egg"))
    if settingsTab.tool then
        for _ = 1, 10 do
            services.muscleEvent:FireServer("proteinEgg", settingsTab.tool)
        end
    end
end

task.spawn(function()
    while true do
        if settingsTab.autoEgg then
            eatEgg()
            task.wait(0.5)
        else
            task.wait(1)
        end
    end
end)

local autoEggSwitch = settingsTab:AddSwitch("Eat Eggs", function(state)
    settingsTab.autoEgg = state
    if state then
        eatEgg()
    end
end):Set(false)

settingsTab.boostItemList = {
    "Tropical Shake",
    "Energy Shake",
    "Protein Bar",
    "TOUGH Bar",
    "Protein Shake",
    "ULTRA Shake",
    "Energy Bar",
}

settingsTab.boostActions = {
    ["Tropical Shake"] = "tropicalShake",
    ["Energy Shake"] = "energyShake",
    ["Protein Bar"] = "proteinBar",
    ["TOUGH Bar"] = "toughBar",
    ["Protein Shake"] = "proteinShake",
    ["ULTRA Shake"] = "ultraShake",
    ["Energy Bar"] = "energyBar",
}

settingsTab.eatAllBoostsRunning = false

task.spawn(function()
    while true do
        if settingsTab.eatAllBoostsRunning then
            settingsTab.boostItemIndex = 1
            while settingsTab.boostItemIndex <= #settingsTab.boostItemList do
                settingsTab.boostItemName = settingsTab.boostItemList[settingsTab.boostItemIndex]
                settingsTab.character = lp.player.Character
                settingsTab.backpack = lp.player:FindFirstChild("Backpack")
                settingsTab.boostTool = (settingsTab.character and settingsTab.character:FindFirstChild(settingsTab.boostItemName))
                    or (settingsTab.backpack and settingsTab.backpack:FindFirstChild(settingsTab.boostItemName))

                if settingsTab.boostTool then
                    settingsTab.boostUseIndex = 1
                    while settingsTab.boostUseIndex <= 10 do
                        services.muscleEvent:FireServer(settingsTab.boostActions[settingsTab.boostItemName], settingsTab.boostTool)
                        settingsTab.boostUseIndex = settingsTab.boostUseIndex + 1
                    end
                end

                settingsTab.boostItemIndex = settingsTab.boostItemIndex + 1
            end

            task.wait(0.1)
        else
            task.wait(1)
        end
    end
end)

settingsTab:AddSwitch("Eat All Boost (Except Egg)", function(state)
    settingsTab.eatAllBoostsRunning = state
end)

settingsTab.spinFortuneWheel = function()
    settingsTab.spinResult = table.pack(pcall(function()
        return game:GetService("ReplicatedStorage").rEvents.openFortuneWheelRemote:InvokeServer(
            "openFortuneWheel",
            "Fortune Wheel"
        )
    end))
end

local spinwheelSwitch = settingsTab:AddSwitch("Spin Fortune Wheel", function(bool)
    _G.AutoSpinWheel = bool
    
    if bool then
        task.spawn(function()
            settingsTab.rspin = game:GetService("ReplicatedStorage").rEvents.openFortuneWheelRemote
            settingsTab.chances = game:GetService("ReplicatedStorage").shared.catalogs.fortuneWheelChances["Fortune Wheel"]
            
            while _G.AutoSpinWheel do
                settingsTab.rspin:InvokeServer("openFortuneWheel", settingsTab.chances)
                task.wait(1)
            end
        end)
    end
end)

local statPetDropdown = settingsTab:AddDropdown("Perk Pet Equip", function(text)
	local petsFolder = game.Players.LocalPlayer.petsFolder
	for _, folder in pairs(petsFolder:GetChildren()) do
		if folder:IsA("Folder") then
			for _, pet in pairs(folder:GetChildren()) do
				game:GetService("ReplicatedStorage").rEvents.equipPetEvent:FireServer("unequipPet", pet)
			end
		end
	end
	task.wait(0.2)

	local petName = text
	local petsToEquip = {}

	for _, pet in pairs(game.Players.LocalPlayer.petsFolder.Unique:GetChildren()) do
		if pet.Name == petName then
			table.insert(petsToEquip, pet)
		end
	end

	for i = 1, math.min(8, #petsToEquip) do
		game:GetService("ReplicatedStorage").rEvents.equipPetEvent:FireServer("equipPet", petsToEquip[i])
		task.wait(0.1)
	end
end)
statPetDropdown:Add("Common Boss Pet")
statPetDropdown:Add("Rare Boss Pet")
statPetDropdown:Add("Epic Boss Pet")
statPetDropdown:Add("Legendary Boss Pet")
statPetDropdown:Add("Mythic Boss Pet")
statPetDropdown:Add("Rainbow Boss Pet")

local char = player.Character or player.CharacterAdded:wait()
local hrp = char:WaitForChild("HumanoidRootPart")

settingsTab:AddButton("Hallowed Lift",function()
    hrp.CFrame = CFrame.new(5432.12, 85.35, 5715.02)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end)

settingsTab:AddButton("Hallowed Squat",function()
    hrp.CFrame = CFrame.new(4812.03, 85.35, 5839.05)
    task.wait(0.2)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end)

local infoTab = window:AddTab("Info")
infoTab:Show()
infoTab:AddLabel("Made by BossKenzou").TextSize = 17
infoTab:AddLabel("TikTok: Kenzouu Warfreakkk!").TextSize = 17
infoTab:AddLabel("If you encounter a problem or suggestions, PM/DM on TikTok") .TextSize = 17
infoTab:AddButton("Copy TikTok Link", function()
    local link = "https://tiktok.com/@officialkenzouu"
    if setclipboard then
        setclipboard(link)
        game.StarterGui:SetCore("SendNotification", {
            Title = "Link Copied!";
            Text = "Pa follow na din ako, tutal na copy link mo na";
            Duration = 3;
        })
    else
        game.StarterGui:SetCore("SendNotification", {
            Title = "Error!";
            Text = "Clipboard not Supported.";
            Duration = 3;
        })
    end
end)
infoTab:AddLabel("")
local wLabel = infoTab:AddLabel("M1887 Private")
wLabel.TextSize = 30
wLabel.Font = Enum.Font.Arcade
