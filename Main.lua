repeat wait() until game:IsLoaded()
-- เช็คว่าอยู่ในแมพ Murder Mystery 2 หรือไม่
if game.PlaceId ~= 142823291 then
    return
end

print("Version 3.21")
-- Config (ตั้งได้จากภายนอก)
_G.Config = _G.Config or {}
local Config = _G.Config

-- ค่าพื้นฐาน
Config.Horst = Config.Horst ~= nil and Config.Horst or false
Config.ToggleRender3D = Config.ToggleRender3D ~= nil and Config.ToggleRender3D or false

-- ถ้าเปิด Horst ให้โหลด script
if Config.Horst then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()
end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- ตั้งค่า
local SPEED = 35
local DESCRIPTION_INTERVAL = 30 -- ส่ง Description ทุก 30 วิ
local lastDescriptionTime = 0
local questCompleted = false -- เช็คว่า Quest เสร็จหรือยัง

-- สร้าง ScreenGui สำหรับแสดง Quest Progress
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestStatsGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999999
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Frame หลัก
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.6, 0, 0.6, 0)
mainFrame.Position = UDim2.new(0.5, 0, 0.65, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(245, 235, 220)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Padding
local mainPadding = Instance.new("UIPadding")
mainPadding.PaddingTop = UDim.new(0.03, 0)
mainPadding.PaddingBottom = UDim.new(0.03, 0)
mainPadding.PaddingLeft = UDim.new(0.04, 0)
mainPadding.PaddingRight = UDim.new(0.04, 0)
mainPadding.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0.02, 0)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = mainFrame

-- ฟังก์ชันสร้าง Info Box (สำหรับ Summer Keys และ Coins)
local function createInfoBox(name, layoutOrder)
	local box = Instance.new("Frame")
	box.Name = name .. "Box"
	box.Size = UDim2.new(1, 0, 0.15, 0)
	box.BackgroundColor3 = Color3.fromRGB(194, 144, 90)
	box.BorderSizePixel = 0
	box.LayoutOrder = layoutOrder
	box.Parent = mainFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = box

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(139, 90, 43)
	stroke.Thickness = 3
	stroke.Parent = box

	local contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(1, 0, 1, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = box

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.03, 0)
	padding.PaddingRight = UDim.new(0.03, 0)
	padding.PaddingTop = UDim.new(0.1, 0)
	padding.PaddingBottom = UDim.new(0.1, 0)
	padding.Parent = contentFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.fromRGB(70, 45, 22)
	nameLabel.TextSize = 72
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = contentFrame

	local colonLabel = Instance.new("TextLabel")
	colonLabel.Size = UDim2.new(0.1, 0, 1, 0)
	colonLabel.Position = UDim2.new(0.4, 0, 0, 0)
	colonLabel.BackgroundTransparency = 1
	colonLabel.Text = ":"
	colonLabel.TextColor3 = Color3.fromRGB(70, 45, 22)
	colonLabel.TextSize = 72
	colonLabel.Font = Enum.Font.GothamBold
	colonLabel.TextScaled = true
	colonLabel.Parent = contentFrame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(0.5, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "..."
	valueLabel.TextColor3 = Color3.fromRGB(70, 45, 22)
	valueLabel.TextSize = 72
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextScaled = true
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = contentFrame

	return box, valueLabel
end

-- Username Box
local usernameBox = Instance.new("Frame")
usernameBox.Name = "UsernameBox"
usernameBox.Size = UDim2.new(1, 0, 0.15, 0)
usernameBox.BackgroundColor3 = Color3.fromRGB(139, 90, 43)
usernameBox.BorderSizePixel = 0
usernameBox.LayoutOrder = 1
usernameBox.Parent = mainFrame

local usernameCorner = Instance.new("UICorner")
usernameCorner.CornerRadius = UDim.new(0, 10)
usernameCorner.Parent = usernameBox

local usernameStroke = Instance.new("UIStroke")
usernameStroke.Color = Color3.fromRGB(70, 45, 22)
usernameStroke.Thickness = 3
usernameStroke.Parent = usernameBox

local usernameLabel = Instance.new("TextLabel")
usernameLabel.Size = UDim2.new(1, 0, 1, 0)
usernameLabel.BackgroundTransparency = 1
usernameLabel.Text = player.Name
usernameLabel.TextColor3 = Color3.fromRGB(245, 222, 179)
usernameLabel.TextSize = 80
usernameLabel.Font = Enum.Font.GothamBold
usernameLabel.TextScaled = true
usernameLabel.Parent = usernameBox

local usernamePadding = Instance.new("UIPadding")
usernamePadding.PaddingLeft = UDim.new(0.03, 0)
usernamePadding.PaddingRight = UDim.new(0.03, 0)
usernamePadding.PaddingTop = UDim.new(0.15, 0)
usernamePadding.PaddingBottom = UDim.new(0.15, 0)
usernamePadding.Parent = usernameLabel

-- Summer Keys Box
local summerKeysBox, summerKeysLabel = createInfoBox("Summer Keys", 2)

-- Coins Box
local coinsBox, coinsLabel = createInfoBox("Coins", 3)

-- Daily Quest Box
local dailyBox = Instance.new("Frame")
dailyBox.Name = "DailyBox"
dailyBox.Size = UDim2.new(1, 0, 0.18, 0)
dailyBox.BackgroundColor3 = Color3.fromRGB(194, 144, 90)
dailyBox.BorderSizePixel = 0
dailyBox.LayoutOrder = 4
dailyBox.Parent = mainFrame

local dailyCorner = Instance.new("UICorner")
dailyCorner.CornerRadius = UDim.new(0, 10)
dailyCorner.Parent = dailyBox

local dailyStroke = Instance.new("UIStroke")
dailyStroke.Color = Color3.fromRGB(139, 90, 43)
dailyStroke.Thickness = 3
dailyStroke.Parent = dailyBox

-- Container สำหรับ Daily Quest
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = dailyBox

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingLeft = UDim.new(0.03, 0)
contentPadding.PaddingRight = UDim.new(0.03, 0)
contentPadding.PaddingTop = UDim.new(0.1, 0)
contentPadding.PaddingBottom = UDim.new(0.1, 0)
contentPadding.Parent = contentFrame

-- Label "Daily"
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
nameLabel.Position = UDim2.new(0, 0, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Daily Quest"
nameLabel.TextColor3 = Color3.fromRGB(70, 45, 22)
nameLabel.TextSize = 72
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextScaled = true
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.Parent = contentFrame

-- Colon
local colonLabel = Instance.new("TextLabel")
colonLabel.Size = UDim2.new(0.1, 0, 1, 0)
colonLabel.Position = UDim2.new(0.4, 0, 0, 0)
colonLabel.BackgroundTransparency = 1
colonLabel.Text = ":"
colonLabel.TextColor3 = Color3.fromRGB(70, 45, 22)
colonLabel.TextSize = 72
colonLabel.Font = Enum.Font.GothamBold
colonLabel.TextScaled = true
colonLabel.Parent = contentFrame

-- Value Label (Progress)
local questLabel = Instance.new("TextLabel")
questLabel.Name = "QuestLabel"
questLabel.Size = UDim2.new(0.5, 0, 1, 0)
questLabel.Position = UDim2.new(0.5, 0, 0, 0)
questLabel.BackgroundTransparency = 1
questLabel.Text = "..."
questLabel.TextColor3 = Color3.fromRGB(70, 45, 22)
questLabel.TextSize = 72
questLabel.Font = Enum.Font.GothamBold
questLabel.TextScaled = true
questLabel.TextXAlignment = Enum.TextXAlignment.Right
questLabel.Parent = contentFrame

-- ฟังก์ชันอัปเดต Currency Labels
local function updateCurrencyLabels()
	local success = pcall(function()
		local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))

		-- อัปเดต Summer Keys
		local summerKeys = ProfileData.Materials.Owned["SummerKey2026"] or 0
		summerKeysLabel.Text = tostring(summerKeys)

		-- อัปเดต Coins
		local coins = ProfileData.Materials.Owned["Coins"] or 0
		coinsLabel.Text = tostring(coins)
	end)

	if not success then
		summerKeysLabel.Text = "..."
		coinsLabel.Text = "..."
	end
end

-- ฟังก์ชันอัปเดต Quest Label (คัดลอกจาก QuestChecker.lua)
local function updateQuestLabel()
    local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
    local EventInfoService = require(ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))

    local success, eventInfo = pcall(function()
        return EventInfoService:WaitForInitializedAsync()
    end)

    if not success then
        return false
    end

    local mainEvent = eventInfo:GetMainEvent()
    if not mainEvent then
        return false
    end

    local eventTitle = mainEvent.Title
    local questsData = ProfileData[eventTitle] and ProfileData[eventTitle].Quests

    if not questsData then
        return false
    end

    local eventQuests = mainEvent.EventStartInfo.Quests
    if not eventQuests then
        return false
    end

    -- วนลูปเช็คแต่ละ Quest Type
    for questType, questConfig in pairs(eventQuests) do
        local playerProgress = questsData[questType]
        if playerProgress then
            -- เช็คว่าเป็น Daily Quest (ไม่ใช่ DailyCoins)
            if questConfig.Quests and questConfig.Title and string.find(questConfig.Title, "DAILY") then
                local totalQuests = #questConfig.Quests

                -- เอา Quest ตัวสุดท้าย (Quest 6)
                if totalQuests >= 6 then
                    local quest = questConfig.Quests[6]
                    local currentProgress = playerProgress.Progress or 0
                    local targetAmount = quest.ChallengeAmount
                    local isCompleted = currentProgress >= targetAmount

                    -- อัปเดต GUI
                    questLabel.Text = string.format("%d/%d%s", currentProgress, targetAmount, isCompleted and " ✓" or "")

                    if isCompleted then
                        dailyBox.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
                    else
                        dailyBox.BackgroundColor3 = Color3.fromRGB(194, 144, 90)
                    end

                    return true
                end
            end
        end
    end

    return false
end

-- อัปเดต Quest Label ครั้งแรก
task.spawn(function()
    task.wait(2) -- รอให้ Event Data โหลดเสร็จ

    -- อัปเดต Currency Labels ครั้งแรก
    updateCurrencyLabels()

    local attempts = 0
    local maxAttempts = 10

    while attempts < maxAttempts do
        if updateQuestLabel() then
            break
        end
        attempts = attempts + 1
        task.wait(1)
    end
end)

-- Auto refresh ทุก 5 วินาที
task.spawn(function()
    while task.wait(5) do
        updateQuestLabel()
        updateCurrencyLabels()
    end
end)

-- Real-time Update - ดักจับ Event
pcall(function()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local EventsFolder = Remotes:WaitForChild("Events")

    for _, remote in ipairs(EventsFolder:GetChildren()) do
        local questProgressed = remote:FindFirstChild("EventQuestProgressed")
        if questProgressed then
            questProgressed.OnClientEvent:Connect(function(questType, newProgress)
                if questType == "Daily" then
                    updateQuestLabel()
                end
            end)
            break
        end
    end
end)

-- Real-time Update สำหรับ Currency
pcall(function()
    local Inventory = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Inventory")
    local inventoryChanged = Inventory:FindFirstChild("InventoryDataChanged")

    if inventoryChanged then
        inventoryChanged.Event:Connect(function(player, currencyName, newAmount)
            if currencyName == "SummerKey2026" or currencyName == "Coins" then
                updateCurrencyLabels()
            end
        end)
    end
end)

-- Toggle GUI with N key
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local isGuiVisible = true

-- ถ้าเปิด ToggleRender3D ให้ปิด Render3D ตอนเริ่มต้น (เพราะ GUI เปิดอยู่)
if Config.ToggleRender3D then
    RunService:Set3dRenderingEnabled(false)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.N then
        isGuiVisible = not isGuiVisible
        mainFrame.Visible = isGuiVisible

        -- ถ้าเปิด ToggleRender3D ให้เปิด/ปิด 3D Rendering ตาม GUI (กลับกัน)
        if Config.ToggleRender3D then
            RunService:Set3dRenderingEnabled(not isGuiVisible)
        end
    end
end)

print("✅ Quest Stats GUI Loaded - Press N to toggle")

-- ฟังก์ชันเช็ค Quest Status (return questProgress, questTarget, questDone)
local function checkQuestStatus()
    local questProgress = 0
    local questTarget = 960
    local questDone = false

    local success = pcall(function()
        local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
        local EventInfoService = require(ReplicatedStorage:WaitForChild("SharedServices"):WaitForChild("EventInfoService"))

        local eventInfo = EventInfoService:WaitForInitializedAsync()
        local mainEvent = eventInfo:GetMainEvent()

        if mainEvent then
            local eventTitle = mainEvent.Title
            local questsData = ProfileData[eventTitle] and ProfileData[eventTitle].Quests

            if questsData then
                local eventQuests = mainEvent.EventStartInfo.Quests
                if eventQuests then
                    -- หา Daily Quest จาก Title
                    for questType, questConfig in pairs(eventQuests) do
                        if questConfig.Title and string.find(questConfig.Title, "DAILY") then
                            local playerProgress = questsData[questType]
                            if playerProgress then
                                questProgress = playerProgress.Progress or 0

                                -- หา Quest Target สูงสุด
                                if questConfig.Quests then
                                    for _, quest in ipairs(questConfig.Quests) do
                                        if quest.ChallengeAmount > questTarget then
                                            questTarget = quest.ChallengeAmount
                                        end
                                    end
                                end

                                questDone = questProgress >= questTarget
                                break
                            end
                        end
                    end
                end
            end
        end
    end)

    if not success then
        warn("[DEBUG] checkQuestStatus Error")
        questProgress = 0
        questTarget = 960
        questDone = false
    end

    return questProgress, questTarget, questDone
end

-- ฟังก์ชันส่ง Description
local function sendDescription()
    -- เช็คว่าเปิด Horst หรือไม่
    if not Config.Horst then return end

    -- เช็คว่ามีฟังก์ชัน Horst หรือไม่
    if not _G.Horst_SetDescription then
        warn("[DEBUG] Horst_SetDescription not found")
        return
    end

    -- เช็ค Quest Progress
    local questProgress, questTarget, questDone = checkQuestStatus()

    -- เช็คจำนวน Summer Keys และ Coins
    local summerKeys = 0
    local coins = 0

    pcall(function()
        local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
        summerKeys = ProfileData.Materials.Owned["SummerKey2026"] or 0
        coins = ProfileData.Materials.Owned["Coins"] or 0
    end)

    -- เก็บรายการไอเทม
    local itemNames = {}
    local playerGui = player:FindFirstChild("PlayerGui")

    if playerGui then
        local mainGUI = playerGui:FindFirstChild("MainGUI")
        if mainGUI then
            local gameUI = mainGUI:FindFirstChild("Game")
            if gameUI then
                local inventory = gameUI:FindFirstChild("Inventory")
                if inventory then
                    local main = inventory:FindFirstChild("Main")
                    if main then
                        local weapons = main:FindFirstChild("Weapons")
                        if weapons then
                            local items = weapons:FindFirstChild("Items")
                            if items then
                                local container = items:FindFirstChild("Container")
                                if container then
                                    local current = container:FindFirstChild("Current")
                                    if current then
                                        local currentContainer = current:FindFirstChild("Container")
                                        if currentContainer then
                                            for _, item in ipairs(currentContainer:GetChildren()) do
                                                if item:IsA("Frame") or item:IsA("ImageLabel") then
                                                    local itemName = item:FindFirstChild("ItemName")
                                                    if itemName then
                                                        local label = itemName:FindFirstChild("Label")
                                                        if label and label.Text then
                                                            local name = label.Text
                                                            if name ~= "Default Gun" and name ~= "Default Knife" then
                                                                -- เช็คจำนวนของจากทุก TextLabel/TextButton ใน item frame
                                                                local amount = 1

                                                                -- วิธีที่ 1: เช็คจาก NewItem > Container > Amount
                                                                local newItem = item:FindFirstChild("NewItem")
                                                                if newItem then
                                                                    local newItemContainer = newItem:FindFirstChild("Container")
                                                                    if newItemContainer then
                                                                        local amountObj = newItemContainer:FindFirstChild("Amount")
                                                                        if amountObj and amountObj.Text then
                                                                            local numStr = string.match(amountObj.Text, "x?(%d+)")
                                                                            if numStr then
                                                                                amount = tonumber(numStr) or 1
                                                                            end
                                                                        end
                                                                    end
                                                                end

                                                                -- วิธีที่ 2: สแกนหาทุก TextLabel ใน item frame ที่มี pattern x2, x3
                                                                if amount == 1 then
                                                                    for _, child in ipairs(item:GetDescendants()) do
                                                                        if child:IsA("TextLabel") or child:IsA("TextButton") then
                                                                            if child.Text and string.match(child.Text, "x%d+") then
                                                                                local numStr = string.match(child.Text, "x(%d+)")
                                                                                if numStr then
                                                                                    amount = tonumber(numStr) or 1
                                                                                    break
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                end

                                                                -- บันทึกพร้อมจำนวน
                                                                if amount > 1 then
                                                                    table.insert(itemNames, name .. " x" .. amount)
                                                                else
                                                                    table.insert(itemNames, name)
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- ถ้า Quest เสร็จและยังไม่ส่ง DONE
    if questDone and not questCompleted then
        -- เช็คข้อมูลใหม่ทั้งหมดก่อนส่ง DONE (ห้ามใช้ค่าเก่า)
        local maxRetries = 10
        local retryCount = 0

        repeat
            task.wait(0.5)
            retryCount = retryCount + 1

            -- เช็ค Quest Status ใหม่
            questProgress, questTarget, questDone = checkQuestStatus()

            -- เช็คจำนวน Summer Keys และ Coins ใหม่
            summerKeys = 0
            coins = 0
            pcall(function()
                local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
                summerKeys = ProfileData.Materials.Owned["SummerKey2026"] or 0
                coins = ProfileData.Materials.Owned["Coins"] or 0
            end)

            -- เช็ค Inventory ใหม่
            itemNames = {}
            local playerGui = player:FindFirstChild("PlayerGui")
            if playerGui then
                local mainGUI = playerGui:FindFirstChild("MainGUI")
                if mainGUI then
                    local gameUI = mainGUI:FindFirstChild("Game")
                    if gameUI then
                        local inventory = gameUI:FindFirstChild("Inventory")
                        if inventory then
                            local main = inventory:FindFirstChild("Main")
                            if main then
                                local weapons = main:FindFirstChild("Weapons")
                                if weapons then
                                    local items = weapons:FindFirstChild("Items")
                                    if items then
                                        local container = items:FindFirstChild("Container")
                                        if container then
                                            local current = container:FindFirstChild("Current")
                                            if current then
                                                local currentContainer = current:FindFirstChild("Container")
                                                if currentContainer then
                                                    for _, item in ipairs(currentContainer:GetChildren()) do
                                                        if item:IsA("Frame") or item:IsA("ImageLabel") then
                                                            local itemName = item:FindFirstChild("ItemName")
                                                            if itemName then
                                                                local label = itemName:FindFirstChild("Label")
                                                                if label and label.Text then
                                                                    local name = label.Text
                                                                    if name ~= "Default Gun" and name ~= "Default Knife" then
                                                                        -- เช็คจำนวนของจากทุก TextLabel/TextButton ใน item frame
                                                                        local amount = 1

                                                                        -- วิธีที่ 1: เช็คจาก NewItem > Container > Amount
                                                                        local newItem = item:FindFirstChild("NewItem")
                                                                        if newItem then
                                                                            local newItemContainer = newItem:FindFirstChild("Container")
                                                                            if newItemContainer then
                                                                                local amountObj = newItemContainer:FindFirstChild("Amount")
                                                                                if amountObj and amountObj.Text then
                                                                                    local numStr = string.match(amountObj.Text, "x?(%d+)")
                                                                                    if numStr then
                                                                                        amount = tonumber(numStr) or 1
                                                                                    end
                                                                                end
                                                                            end
                                                                        end

                                                                        -- วิธีที่ 2: สแกนหาทุก TextLabel ใน item frame ที่มี pattern x2, x3
                                                                        if amount == 1 then
                                                                            for _, child in ipairs(item:GetDescendants()) do
                                                                                if child:IsA("TextLabel") or child:IsA("TextButton") then
                                                                                    if child.Text and string.match(child.Text, "x%d+") then
                                                                                        local numStr = string.match(child.Text, "x(%d+)")
                                                                                        if numStr then
                                                                                            amount = tonumber(numStr) or 1
                                                                                            break
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end

                                                                        -- บันทึกพร้อมจำนวน
                                                                        if amount > 1 then
                                                                            table.insert(itemNames, name .. " x" .. amount)
                                                                        else
                                                                            table.insert(itemNames, name)
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

        until (questDone and summerKeys > 0) or retryCount >= maxRetries

        -- ส่ง Description ก่อนส่ง DONE
        local currentDate = os.date("%d/%m/%y")
        local description = string.format(
            "🎮 MM2 • Summer Keys: %d • Coins: %d • Daily : %d/%d (%s) ✅",
            summerKeys,
            coins,
            questProgress,
            questTarget,
            currentDate
        )

        if #itemNames > 0 then
            description = description .. " • Inv : " .. table.concat(itemNames, ", ")
        end

        -- ส่ง Description ก่อน
        _G.Horst_SetDescription(description)

        -- รอให้ Description ส่งเสร็จก่อนส่ง DONE
        task.wait(7)

        -- ส่ง DONE
        _G.Horst_AccountChangeDone()
        questCompleted = true

        -- หลังส่ง DONE แล้ว ส่ง Description ทันทีและส่งต่อทุกๆ 3 วินาที (แยก thread)
        task.spawn(function()
            while true do
                sendDescription()
                task.wait(3)
            end
        end)

        return
    end

    -- ส่ง Description ปกติ (ยังไม่เสร็จ)
    local currentDate = os.date("%d/%m/%y")
    local description = string.format(
        "🎮 MM2 • Summer Keys: %d • Coins: %d • Daily : %d/%d (%s)%s",
        summerKeys,
        coins,
        questProgress,
        questTarget,
        currentDate,
        questDone and " ✅" or ""
    )

    if #itemNames > 0 then
        description = description .. " • Inv : " .. table.concat(itemNames, ", ")
    end

    -- ส่ง Description
    if _G.Horst_SetDescription then
        _G.Horst_SetDescription(description)
    end
end

-- ฟังก์ชัน Tween ไปยังตำแหน่ง
local function tweenToPosition(targetPosition)
    local distance = (humanoidRootPart.Position - targetPosition).Magnitude
    local duration = distance / SPEED

    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut
    )

    local tween = TweenService:Create(
        humanoidRootPart,
        tweenInfo,
        {CFrame = CFrame.new(targetPosition)}
    )

    tween:Play()
    tween.Completed:Wait()
end

-- ฟังก์ชันค้นหา CoinContainer ใน workspace
local function findCoinContainer()
    for _, parent in ipairs(workspace:GetChildren()) do
        local coinContainer = parent:FindFirstChild("CoinContainer")
        if coinContainer then
            return coinContainer
        end
    end
    return nil
end

-- ฟังก์ชันหาเหรียญที่ใกล้ที่สุด
local function findNearestCoin(coins)
    local nearestCoin = nil
    local shortestDistance = math.huge

    for _, coin in ipairs(coins) do
        if coin and coin.Parent and (coin:IsA("BasePart") or coin:IsA("Model")) then
            -- เช็คว่ามี TouchInterest หรือไม่ (ถ้าไม่มี = เก็บไปแล้ว)
            local hasTouchInterest = coin:FindFirstChild("TouchInterest") ~= nil

            if hasTouchInterest then
                local coinPos = coin:IsA("Model")
                    and coin:GetPivot().Position
                    or coin.Position

                local distance = (humanoidRootPart.Position - coinPos).Magnitude

                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestCoin = coin
                end
            end
        end
    end

    return nearestCoin, shortestDistance
end

-- ฟังก์ชันเปิดกล่อง Summer2026Box
local function openSummerBoxes()
    local success, error = pcall(function()
        local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
        local openCrate = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("OpenCrate")

        local boxesOpened = 0

        while true do
            -- เช็คจำนวน SummerKey2026 ปัจจุบัน
            local summerKeys = ProfileData.Materials.Owned["SummerKey2026"] or 0

            -- ถ้าน้อยกว่า 120 หยุดเปิด
            if summerKeys < 120 then
                break
            end

            -- เปิดกล่อง 1 รอบ (120 keys)
            local boxSuccess, boxResult = pcall(function()
                return openCrate:InvokeServer("Summer2026Box", "MysteryBox", "SummerKey2026")
            end)

            if boxSuccess and boxResult then
                boxesOpened = boxesOpened + 1

                -- อัปเดต GUI ทันที
                updateCurrencyLabels()
            else
                break
            end

            -- รอเล็กน้อยก่อนเปิดรอบถัดไป
            task.wait(1)
        end

        return boxesOpened
    end)

    if not success then
        warn("[DEBUG] openSummerBoxes Error:", tostring(error))
    end
end

-- เช็คจำนวนคนในเซิร์ฟเวอร์ตลอดเวลา ถ้าน้อยกว่า 5 คนให้เตะออกทันที (แยก thread)
task.spawn(function()
    while true do
        if #Players:GetPlayers() < 5 then
            player:Kick("Server has fewer than 5 players")
            break
        end
        task.wait(1)
    end
end)

-- ส่ง Description ครั้งแรกก่อนเริ่มลูป
sendDescription()
lastDescriptionTime = tick()

-- ลูปหลัก
while true do
    local success, result = pcall(function()
        -- เช็คและเปิดกล่อง Summer2026Box ถ้ามี SummerKey2026 >= 120
        local openSuccess, openError = pcall(function()
            local ProfileData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData"))
            local currentSummerKeys = ProfileData.Materials.Owned["SummerKey2026"] or 0

            if currentSummerKeys >= 120 then
                openSummerBoxes()
            end
        end)

        if not openSuccess then
            warn("[DEBUG] Box Opening Error:", tostring(openError))
        end

        -- เช็ค Quest Status ทุกรอบ
        local questProgress, questTarget, questDone = checkQuestStatus()

        -- ถ้าเจอว่า Quest เสร็จและยังไม่ส่ง DONE
        if questDone and not questCompleted then
            sendDescription()  -- ส่ง Description + DONE
        end

        -- เช็คว่าถึงเวลาส่ง Description ตามปกติหรือยัง (ทุก 30 วิ)
        -- ถ้าส่ง DONE ไปแล้ว ตัว task.spawn (ทุก 3 วิ) จะรับหน้าที่นี้ต่อ
        if not questCompleted and tick() - lastDescriptionTime >= DESCRIPTION_INTERVAL then
            sendDescription()
            lastDescriptionTime = tick()
        end

        -- อัปเดต character และ humanoidRootPart ใหม่ทุกรอบ
        character = player.Character or player.CharacterAdded:Wait()
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        -- หา MainGUI ใหม่ทุกรอบ (เพราะถูกลบ/สร้างใหม่ตอน teleport)
        local playerGui = player:WaitForChild("PlayerGui")
        local mainGUI = playerGui:WaitForChild("MainGUI", 10)

        if not mainGUI then
            wait(1)
            return
        end

        local gameUI = mainGUI:WaitForChild("Game", 10)
        if not gameUI then
            wait(1)
            return
        end

        -- เช็คว่าอยู่ใน Lobby หรือแมพฟาร์ม - ดูจาก EarnedXP.Visible
        local earnedXP = gameUI:WaitForChild("EarnedXP", 5)
        if not earnedXP then
            wait(1)
            return
        end

        -- เช็คเพิ่มเติมจาก Timer.XPText ว่าเปลี่ยนแปลงหรือไม่
        local timer = gameUI:FindFirstChild("Timer")
        local xpText = timer and timer:FindFirstChild("XPText")
        local lastXPText = xpText and xpText.Text or ""

        -- รอเล็กน้อยแล้วเช็คอีกครั้ง
        wait(0.5)
        local currentXPText = xpText and xpText.Text or ""
        local xpTextChanged = (lastXPText ~= currentXPText)

        local inGame = earnedXP.Visible or xpTextChanged

        if not inGame then
            -- Reset ทุกอย่างใน Lobby
            character = player.Character or player.CharacterAdded:Wait()
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            wait(1)
            return
        end

        -- อยู่ในแมพฟาร์ม - Reset ทุกอย่างใหม่
        character = player.Character or player.CharacterAdded:Wait()
        humanoidRootPart = character:WaitForChild("HumanoidRootPart")

        -- เช็คว่า CoinBags UI โหลดเสร็จหรือยัง
        local coinBags = gameUI:FindFirstChild("CoinBags")
        if not coinBags then
            wait(1)
            return
        end

        local container = coinBags:FindFirstChild("Container")
        if not container then
            wait(1)
            return
        end

        local coin = container:FindFirstChild("Coin")
        if not coin then
            wait(1)
            return
        end

        local currencyFrame = coin:FindFirstChild("CurrencyFrame")
        if not currencyFrame then
            wait(1)
            return
        end

        local icon = currencyFrame:FindFirstChild("Icon")
        if not icon then
            wait(1)
            return
        end

        local coinsText = icon:FindFirstChild("Coins")
        if not coinsText then
            wait(1)
            return
        end

        -- เช็คจำนวน Coin ก่อน
        local coinAmount = tonumber(coinsText.Text) or 0

        if coinAmount >= 40 then
                -- เต็มแล้ว - Reset ตัวละครเพื่อกลับ Lobby
                character:BreakJoints()
                wait(5)
            else
                -- ยังไม่เต็ม - ฟาร์มตามปกติ

                -- หา CoinContainer
                local coinContainer = findCoinContainer()

                if coinContainer then
                    -- ดึงเหรียญทั้งหมดภายใต้ CoinContainer
                    local coins = coinContainer:GetChildren()

                    if #coins > 0 then
                        -- หาเหรียญที่ใกล้ที่สุด
                        local nearestCoin, distance = findNearestCoin(coins)

                        if nearestCoin then
                            -- เช็คว่าเหรียญยังอยู่ก่อนไป
                            if nearestCoin.Parent then
                                local coinPos = nearestCoin:IsA("Model")
                                    and nearestCoin:GetPivot().Position
                                    or nearestCoin.Position

                                -- Tween ไปเก็บเหรียญ
                                tweenToPosition(coinPos)
                                wait(0.1)
                            end
                        end
                    end
                else
                    wait(2)
                end
            end
    end)

    if not success then
        warn("Error:", tostring(result))
        wait(2)
    end

    wait(0.5)
end
