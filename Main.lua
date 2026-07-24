repeat wait() until game:IsLoaded()
-- 11.03
-- Main Script - Manhwa Legends Auto Farm
-- รวมทุกฟีเจอร์: GUI → เช็คแมพ → ลบแมพ → Settings → Claim → สุ่ม → Equip → เข้าเล่น

repeat task.wait() until game:IsLoaded()

-- ════════════════════════════════════════════════════════
-- Config
-- ════════════════════════════════════════════════════════
_G.Config = _G.Config or {}
local Config = {
    Horst = _G.Config.Horst == true,                     -- เปิด/ปิด Horst API (ต้องเป็น true เท่านั้น)
    GemTarget = _G.Config.GemTarget or 50000,           -- เป้าหมาย Gems (ทำงานต่อเมื่อ Horst = true)
    ToggleRender3D = _G.Config.ToggleRender3D or false  -- เปิด/ปิด 3D Rendering
}

-- โหลด Horst API (เฉพาะเมื่อ Horst = true)
if Config.Horst then
    print("📡 Loading Horst API...")
    local horstLoaded = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()
    end)
    if horstLoaded then
        print("   ✅ Horst API loaded")
    else
        warn("   ❌ Failed to load Horst API")
        Config.Horst = false  -- ปิด Horst ถ้าโหลดไม่สำเร็จ
    end
    task.wait(1)
else
    print("📡 Horst API disabled")
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎮 Manhwa Legends Auto Farm")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

-- ════════════════════════════════════════════════════════
-- [1] Create Stats GUI
-- ════════════════════════════════════════════════════════
print("📊 [1/8] Creating Stats GUI...")
pcall(function()
    local RunService = game:GetService("RunService")
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Charm = require(ReplicatedStorage.Packages.Charm)
    local Atoms = require(ReplicatedStorage.Modules.Atoms)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatsDisplay"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999999
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

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
    usernameLabel.Text = LocalPlayer.Name
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

    -- Stats
    local stats = {
        {name = "Gem", key = "Gems", color = Color3.fromRGB(194, 144, 90), order = 2},
        {name = "Gold", key = "Gold", color = Color3.fromRGB(210, 180, 140), order = 3},
        {name = "Trait", key = "TraitReroll", color = Color3.fromRGB(222, 184, 135), order = 4}
    }

    local statsLabels = {}

    for _, stat in ipairs(stats) do
        local statBox = Instance.new("Frame")
        statBox.Name = stat.key .. "Box"
        statBox.Size = UDim2.new(1, 0, 0.18, 0)
        statBox.BackgroundColor3 = stat.color
        statBox.BorderSizePixel = 0
        statBox.LayoutOrder = stat.order
        statBox.Parent = mainFrame

        -- CONTINUE_MARKER_GUI_1
        local statCorner = Instance.new("UICorner")
        statCorner.CornerRadius = UDim.new(0, 10)
        statCorner.Parent = statBox

        local statStroke = Instance.new("UIStroke")
        statStroke.Color = Color3.fromRGB(139, 90, 43)
        statStroke.Thickness = 3
        statStroke.Parent = statBox

        local contentFrame = Instance.new("Frame")
        contentFrame.Size = UDim2.new(1, 0, 1, 0)
        contentFrame.BackgroundTransparency = 1
        contentFrame.Parent = statBox

        local contentPadding = Instance.new("UIPadding")
        contentPadding.PaddingLeft = UDim.new(0.03, 0)
        contentPadding.PaddingRight = UDim.new(0.03, 0)
        contentPadding.PaddingTop = UDim.new(0.1, 0)
        contentPadding.PaddingBottom = UDim.new(0.1, 0)
        contentPadding.Parent = contentFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = stat.name
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

        statsLabels[stat.key] = valueLabel
    end

    -- Sugar Hub Box
    local sugarBox = Instance.new("Frame")
    sugarBox.Name = "SugarBox"
    sugarBox.Size = UDim2.new(1, 0, 0.15, 0)
    sugarBox.BackgroundColor3 = Color3.fromRGB(139, 90, 43)
    sugarBox.BorderSizePixel = 0
    sugarBox.LayoutOrder = 5
    sugarBox.Parent = mainFrame

    local sugarCorner = Instance.new("UICorner")
    sugarCorner.CornerRadius = UDim.new(0, 10)
    sugarCorner.Parent = sugarBox

    local sugarStroke = Instance.new("UIStroke")
    sugarStroke.Color = Color3.fromRGB(70, 45, 22)
    sugarStroke.Thickness = 3
    sugarStroke.Parent = sugarBox

    local sugarLabel = Instance.new("TextLabel")
    sugarLabel.Size = UDim2.new(1, 0, 1, 0)
    sugarLabel.BackgroundTransparency = 1
    sugarLabel.Text = "Sugar Hub"
    sugarLabel.TextColor3 = Color3.fromRGB(245, 222, 179)
    sugarLabel.TextSize = 80
    sugarLabel.Font = Enum.Font.GothamBold
    sugarLabel.TextScaled = true
    sugarLabel.Parent = sugarBox

    local sugarPadding = Instance.new("UIPadding")
    sugarPadding.PaddingLeft = UDim.new(0.03, 0)
    sugarPadding.PaddingRight = UDim.new(0.03, 0)
    sugarPadding.PaddingTop = UDim.new(0.15, 0)
    sugarPadding.PaddingBottom = UDim.new(0.15, 0)
    sugarPadding.Parent = sugarLabel

    -- CONTINUE_MARKER_GUI_2
    local function formatNumber(num)
        local formatted = tostring(num)
        local k
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if k == 0 then
                break
            end
        end
        return formatted
    end

    local function updateStats()
        pcall(function()
            local attributes = Charm.peek(Atoms.Attributes)
            if not attributes then return end

            statsLabels.Gems.Text = formatNumber(tonumber(attributes.Gems) or 0)
            statsLabels.Gold.Text = formatNumber(tonumber(attributes.Gold) or 0)

            local traitReroll = 0
            pcall(function()
                local data = Atoms.Data()
                if data and data.MaterialsInventory then
                    traitReroll = tonumber(data.MaterialsInventory["Trait Reroll"]) or 0
                end
            end)
            statsLabels.TraitReroll.Text = formatNumber(traitReroll)
        end)
    end

    task.wait(2)
    updateStats()

    local lastGems = 0
    local lastGold = 0
    local lastTrait = 0

    pcall(function()
        local attributes = Charm.peek(Atoms.Attributes)
        if attributes then
            lastGems = tonumber(attributes.Gems) or 0
            lastGold = tonumber(attributes.Gold) or 0
        end
        local data = Atoms.Data()
        if data and data.MaterialsInventory then
            lastTrait = tonumber(data.MaterialsInventory["Trait Reroll"]) or 0
        end
    end)

    spawn(function()
        while true do
            task.wait(0.5)
            pcall(function()
                local attributes = Charm.peek(Atoms.Attributes)
                if not attributes then return end

                local currentGems = tonumber(attributes.Gems) or 0
                local currentGold = tonumber(attributes.Gold) or 0
                local currentTrait = 0

                pcall(function()
                    local data = Atoms.Data()
                    if data and data.MaterialsInventory then
                        currentTrait = tonumber(data.MaterialsInventory["Trait Reroll"]) or 0
                    end
                end)

                if currentGems ~= lastGems then
                    statsLabels.Gems.Text = formatNumber(currentGems)
                    lastGems = currentGems
                end
                if currentGold ~= lastGold then
                    statsLabels.Gold.Text = formatNumber(currentGold)
                    lastGold = currentGold
                end
                if currentTrait ~= lastTrait then
                    statsLabels.TraitReroll.Text = formatNumber(currentTrait)
                    lastTrait = currentTrait
                end
            end)
        end
    end)

    local UserInputService = game:GetService("UserInputService")
    local isGuiVisible = true
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.N then
            isGuiVisible = not isGuiVisible
            mainFrame.Visible = isGuiVisible

            -- Toggle 3D Rendering
            if Config.ToggleRender3D then
                if isGuiVisible then
                    RunService:Set3dRenderingEnabled(false)  -- GUI เปิด = 3D ปิด
                else
                    RunService:Set3dRenderingEnabled(true)   -- GUI ปิด = 3D เปิด
                end
            end
        end
    end)

    -- ตั้งค่า 3D Rendering เริ่มต้น
    if Config.ToggleRender3D then
        RunService:Set3dRenderingEnabled(false)  -- เริ่มต้นปิด 3D (GUI เปิดอยู่)
    end
end)
print("   ✅ Stats GUI created")
task.wait(2)


-- ════════════════════════════════════════════════════════
-- [2] Check Map
-- ════════════════════════════════════════════════════════
print("🗺️  [2/8] Checking current map...")

local function getMapInfo()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local mapName = ""

    for _, child in pairs(playerGui:GetChildren()) do
        if child.Name == "REACTMAIN" then
            for _, gui in pairs(child:GetDescendants()) do
                if (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Name == "locationName" then
                    mapName = gui.Text
                    break
                end
            end
        end
    end

    return mapName
end

local currentMap = getMapInfo()
local isInMap = currentMap ~= "" and currentMap ~= "Lobby"

if isInMap then
    print(string.format("   ✅ In Map: %s", currentMap))
else
    print("   ✅ In Lobby")
end

-- ════════════════════════════════════════════════════════
-- [3] Remove Map & Create Floor
-- ════════════════════════════════════════════════════════

if not isInMap then
    -- LOBBY MODE
    print("🧹 [3/8] Removing lobby objects...")

    local lobbyObjects = {
        workspace.Debris,
        workspace.InvisParts,
        workspace.Unsorted,
        workspace.VFX,
    }

    for _, obj in ipairs(lobbyObjects) do
        if obj then
            pcall(function() obj:Destroy() end)
        end
    end

    if workspace:FindFirstChild("Holder") then
        -- ลบ children ภายใน Map folders (เก็บ folder ไว้)
        if workspace.Holder:FindFirstChild("Map") then
            local mapFolders = {
                "AFK", "Challenges", "FoodTruck", "Guilds",
                "Lobby", "Milestones", "Raids", "Story",
                "Subway", "Upgrade", "Workshop", "Summon"
            }

            for _, folderName in ipairs(mapFolders) do
                pcall(function()
                    local folder = workspace.Holder.Map:FindFirstChild(folderName)
                    if folder then
                        for _, obj in pairs(folder:GetChildren()) do
                            obj:Destroy()
                        end
                    end
                end)
            end

            -- LeaderBoard - ลบทุกอย่างยกเว้น Screens
            pcall(function()
                local leaderBoard = workspace.Holder.Map:FindFirstChild("LeaderBoard")
                if leaderBoard then
                    for _, obj in pairs(leaderBoard:GetChildren()) do
                        if obj.Name ~= "Screens" then
                            obj:Destroy()
                        end
                    end
                end
            end)
        end

        -- ลบ folders อื่นๆ ทั้งหมด
        local holderObjects = {
            workspace.Holder.InvisibleWalls,
            workspace.Holder.MISC,
            workspace.Holder.MiscNPC,
            workspace.Holder.MovingParts,
            workspace.Holder.NPCs,
        }

        for _, obj in ipairs(holderObjects) do
            if obj then
                pcall(function() obj:Destroy() end)
            end
        end
    end

    -- Remove Terrain children
    pcall(function()
        for _, obj in pairs(workspace.Terrain:GetChildren()) do
            obj:Destroy()
        end
    end)

    -- Remove Lighting children
    pcall(function()
        for _, obj in pairs(game:GetService("Lighting"):GetChildren()) do
            obj:Destroy()
        end
    end)

    -- Remove MaterialService children
    pcall(function()
        for _, obj in pairs(game:GetService("MaterialService"):GetChildren()) do
            obj:Destroy()
        end
    end)

    -- Create invisible floor
    print("   Creating invisible floor...")
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        local floor = Instance.new("Part")
        floor.Name = "InvisibleFloor"
        floor.Size = Vector3.new(5000, 1, 5000)
        floor.Position = hrp.Position - Vector3.new(0, 5, 0)
        floor.Anchored = true
        floor.Transparency = 1
        floor.CanCollide = true
        floor.Parent = workspace
    end

    print("   ✅ Lobby cleanup complete")

    -- ════════════════════════════════════════════════════════
    -- [4] Apply Settings
    -- ════════════════════════════════════════════════════════
    print("⚙️  [4/8] Applying settings...")

    task.wait(1)
    local ClientNetwork = require(ReplicatedStorage:WaitForChild("Networks"):WaitForChild("ClientNetwork"))

    local settings = {
        {name = "AutoStart", value = true},
        {name = "SkipWaves", value = true},
        {name = "SkipSummon", value = true},
        {name = "DisableGlobalMessages", value = true},
        {name = "HideKeybindHints", value = true},
        {name = "HideOtherUnits", value = true},
        {name = "UnitsVisibility", value = true},
        {name = "LowDetail", value = true},
        {name = "DepthField", value = false},
        {name = "DisableEffects", value = true},
        {name = "DisableDamage", value = true},
        {name = "DisableTags", value = true},
    }

    for _, setting in ipairs(settings) do
        pcall(function()
            ClientNetwork.Player.ChangeSetting.Fire(setting.name, setting.value)
        end)
        task.wait(0.1)
    end

    print("   ✅ Settings applied")

    -- ════════════════════════════════════════════════════════
    -- [5] Claim All
    -- ════════════════════════════════════════════════════════
    print("🎁 [5/8] Claiming rewards...")

    task.wait(1)
    local Atoms = require(ReplicatedStorage.Modules.Atoms)

    -- Claim Battlepass (ใช้ UpdateBattlepass)
    pcall(function()
        ClientNetwork.Player.UpdateBattlepass.Invoke({
            action = "ClaimAll"
        }):timeout(10):await()
    end)

    task.wait(0.5)

    -- Update Indexes
    pcall(function()
        if ClientNetwork.Player.UpdateIndexes then
            ClientNetwork.Player.UpdateIndexes.Fire()
        end
    end)

    task.wait(0.5)

    -- Claim Index Level Rewards
    pcall(function()
        local currentLevel = Atoms.IndexLevel and Atoms.IndexLevel()
        local lastClaimedLevel = Atoms.LastClaimedLevelIndex and Atoms.LastClaimedLevelIndex()

        if currentLevel and lastClaimedLevel and currentLevel > lastClaimedLevel then
            pcall(function()
                ClientNetwork.Player.ClaimIndex.Invoke()
            end)
        end
    end)

    task.wait(0.5)

    -- Claim Achievements
    pcall(function()
        local achievements = Atoms.Achievements and Atoms.Achievements()
        if achievements and type(achievements) == "table" then
            local categories = {"Normal", "Limited", "Event", "Story", "Special"}

            for _, category in ipairs(categories) do
                local catAchievements = achievements[category]
                if type(catAchievements) == "table" then
                    for achId, ach in pairs(catAchievements) do
                        if type(ach) == "table" then
                            local claimed = ach.claimed or ach.Claimed or false

                            -- เช็ค Achievement แบบมี Tasks (รับ task แยก)
                            if ach.Tasks and type(ach.Tasks) == "table" then
                                for taskId, task in pairs(ach.Tasks) do
                                    if type(task) == "table" then
                                        local taskClaimed = task.Claimed or false
                                        local taskCompleted = task.Completed or false

                                        -- รับ task ที่เสร็จแล้วแต่ยังไม่ได้รับ
                                        if taskCompleted and not taskClaimed then
                                            local Players = game:GetService("Players")
                                            local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 1)

                                            if playerGui then
                                                local tasksFolder = playerGui:FindFirstChild("LeftUI")
                                                    and playerGui.LeftUI:FindFirstChild("Achievements")
                                                    and playerGui.LeftUI.Achievements:FindFirstChild("Tasks")

                                                if tasksFolder then
                                                    for _, taskTemplate in ipairs(tasksFolder:GetChildren()) do
                                                        if taskTemplate:IsA("TextButton") or taskTemplate:IsA("ImageButton") then
                                                            local taskTitle = taskTemplate:FindFirstChild("TaskTitle")
                                                            if taskTitle then
                                                                local hasText, titleText = pcall(function() return taskTitle.Text end)
                                                                if hasText and titleText and titleText:match(taskId) then
                                                                    pcall(function()
                                                                        for _, connection in pairs(getconnections(taskTemplate.MouseButton1Click)) do
                                                                            connection:Fire()
                                                                        end
                                                                    end)
                                                                    task.wait(0.1)

                                                                    -- กดมุมบนซ้าย 5 ครั้งเพื่อปิด popup
                                                                    local VirtualInputManager = game:GetService("VirtualInputManager")
                                                                    for i = 1, 5 do
                                                                        pcall(function()
                                                                            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
                                                                            task.wait(0.05)
                                                                            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
                                                                            task.wait(0.05)
                                                                        end)
                                                                    end
                                                                    break
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            task.wait(0.2)
                                        end
                                    end
                                end
                            else
                                -- Achievement แบบไม่มี Tasks
                                local completed = ach.Completed or ach.Complete or false

                                if completed and not claimed then
                                    pcall(function()
                                        ClientNetwork.Player.ClaimAchievement.Invoke(achId)
                                    end)
                                    task.wait(0.1)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    task.wait(0.5)

    -- Claim Daily Login
    pcall(function()
        local data = Atoms.Data and Atoms.Data()
        if data and data.DailyRewards then
            local dailyRewards = data.DailyRewards
            local currentDay = dailyRewards.Day

            if type(currentDay) == "number" and not dailyRewards.Completed then
                local claimed = dailyRewards.Claimed or {}
                local nextTime = tonumber(dailyRewards.NextDailyTime) or 0
                local serverTime = workspace:GetServerTimeNow()

                -- เช็คว่าวันนี้ยังไม่ได้รับและเวลาพร้อมแล้ว
                if not claimed[currentDay] and serverTime >= nextTime then
                    print(string.format("   🎁 Claiming Daily Login Day %d...", currentDay))
                    pcall(function()
                        ClientNetwork.Player.ClaimLogin.Invoke(currentDay)
                    end)
                    task.wait(0.3)
                end
            end
        end
    end)

    -- Claim Quests
    pcall(function()
        local quests = Atoms.Quests and Atoms.Quests()
        if quests and type(quests) == "table" then
            local categories = {"Daily", "Weekly", "Infinite", "Special"}

            for _, category in ipairs(categories) do
                local catQuests = quests[category]
                if type(catQuests) == "table" then
                    for questId, quest in pairs(catQuests) do
                        if type(quest) == "table" and not quest.claimed and not quest.hidden then
                            local canClaim = false
                            local progress = quest.progress or 0
                            local target = 1

                            if type(progress) == "number" then
                                canClaim = progress >= target
                            elseif type(progress) == "table" then
                                canClaim = true
                            end

                            if canClaim then
                                pcall(function()
                                    ClientNetwork.Player.ClaimQuest.Invoke(category, questId)
                                end)
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end
    end)

    print("   ✅ Rewards claimed")

    -- Redeem Codes
    pcall(function()
        local codes = {"Release", "SorryForDelay", "ThanksForPatience", "DelayLegends", "OneLastDelay"}
        print("   🎫 Redeeming codes...")

        for i, code in ipairs(codes) do
            pcall(function()
                print(string.format("      [%d/%d] Redeeming: %s", i, #codes, code))
                ClientNetwork.Player.RedeemCode.Invoke(code)
            end)
            task.wait(5)  -- รอ 2 วิระหว่างโค้ด
        end

        print("   ✅ Codes redeemed")
    end)

    -- ════════════════════════════════════════════════════════
    -- [6] Check & Summon Units
    -- ════════════════════════════════════════════════════════
    print("🎲 [6/8] Checking required units...")

    local requiredUnits = {"Irina Vladimirov", "Gino", "Gyoteng"}
    local hasAllUnits = false

    local function checkUnits()
        local success, result = pcall(function()
            local inventory = Atoms.UnitsInventory and Atoms.UnitsInventory()
            if not inventory or type(inventory) ~= "table" then
                return false
            end

            for _, unitName in ipairs(requiredUnits) do
                local found = false
                for _, unit in pairs(inventory) do
                    if type(unit) == "table" and unit.Name == unitName then
                        found = true
                        break
                    end
                end
                if not found then
                    return false
                end
            end
            return true
        end)

        return success and result or false
    end

    hasAllUnits = checkUnits()

    if not hasAllUnits then
        print("   ⚠️  Missing units - starting summon...")

        local attempts = 0

        while not hasAllUnits do
            attempts = attempts + 1
            print(string.format("   🎰 Summoning 1x (Attempt %d)...", attempts))
            pcall(function()
                ClientNetwork.Player.Summon.Invoke(1)
            end)
            task.wait(0.3)
            hasAllUnits = checkUnits()
        end

        print(string.format("   ✅ All units obtained after %d attempts", attempts))
    else
        print("   ✅ All units already owned")
    end

    -- ════════════════════════════════════════════════════════
    -- [7] Unequip & Equip Units
    -- ════════════════════════════════════════════════════════
    print("🎯 [7/8] Equipping units...")

    task.wait(1)

    -- Unequip all
    pcall(function()
        ClientNetwork.Player.UnequipAll.Fire(nil)
    end)

    task.wait(0.5)

    -- Equip required units (เลือก Level สูงสุด)
    local success, inventory = pcall(function()
        return Atoms.UnitsInventory and Atoms.UnitsInventory()
    end)

    if success and inventory and type(inventory) == "table" then
        for _, unitName in ipairs(requiredUnits) do
            local bestUnit = nil
            local bestLevel = -1

            -- หาตัวที่ Level สูงสุด
            for unitId, unit in pairs(inventory) do
                if type(unit) == "table" and unit.Name == unitName then
                    local level = unit.Level or 0
                    if level > bestLevel then
                        bestLevel = level
                        bestUnit = unitId
                    end
                end
            end

            -- Equip ตัวที่ดีที่สุด
            if bestUnit then
                pcall(function()
                    ClientNetwork.Player.EquipUnit.Fire(bestUnit)
                end)
                task.wait(0.1)
            end
        end
    end

    print("   ✅ Units equipped")

    -- ════════════════════════════════════════════════════════
    -- [8] Create Party & Join Map
    -- ════════════════════════════════════════════════════════
    print("🚪 [8/8] Creating party & joining map...")

    task.wait(1)

    local PartyCreate = ReplicatedStorage.Party.Remotes.Party_Create
    local PartyReady = ReplicatedStorage.Party.Remotes.Party_Ready
    local PartyStart = ReplicatedStorage.Party.Remotes.Party_Start

    local config = {
        Map = "Elven Forest",
        SubMode = "Story",
        UseMatchmaking = false,
        Act = "1",
        Mode = "Story",
        Difficulty = "Hard",
        Privacy = "Public"
    }

    local success, errorMsg, data = PartyCreate:InvokeServer(config)

    if success then
        print("   ✅ Party created:", data and data.PartyId or "No ID")

        local readySuccess, readyError = PartyReady:InvokeServer(true)
        if readySuccess then
            print("   ✅ Ready status set")
        else
            warn("   ⚠️ Failed to set ready:", readyError or "Unknown error")
        end

        task.wait(1)

        local startSuccess, startError = PartyStart:InvokeServer()
        if startSuccess then
            print("   ✅ Game started")
        else
            warn("   ⚠️ Failed to start:", startError or "Need more players")
        end
    else
        warn("   ⚠️ Failed to create party:", errorMsg or "Unknown error")
    end

    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ Lobby setup complete - waiting for map load...")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

else
    -- IN-MAP MODE
    print("🧹 [3/8] Removing in-game objects...")

    -- Remove workspace objects (keep essential)
    pcall(function()
        for _, obj in pairs(workspace:GetChildren()) do
            local keep = obj.Name == "Camera" or obj.Name == "Terrain" or
                        obj.Name == "RespawnPart" or obj.Name == "ColorblindLabel" or
                        obj.Name == "Holder"

            if not keep then
                obj:Destroy()
            end
        end
    end)

    -- Remove Map children only
    if workspace:FindFirstChild("Holder") then
        local holder = workspace.Holder
        if holder:FindFirstChild("Map") then
            pcall(function()
                -- Remove all children of Map
                for _, obj in pairs(holder.Map:GetChildren()) do
                    obj:Destroy()
                end
            end)
        end
    end

    -- Remove MaterialService children
    pcall(function()
        for _, obj in pairs(game:GetService("MaterialService"):GetChildren()) do
            obj:Destroy()
        end
    end)

    print("   ✅ Map cleanup complete")

    -- ════════════════════════════════════════════════════════
    -- Horst Description Sender
    -- ════════════════════════════════════════════════════════
    if Config.Horst and _G.Horst_SetDescription then
        print("📡 Setting up Horst status sender...")

        local Charm = require(ReplicatedStorage.Packages.Charm)
        local Atoms = require(ReplicatedStorage.Modules.Atoms)
        local HttpService = game:GetService("HttpService")

        local function sendDescription()
            local success, result = pcall(function()
                local attributes = Charm.peek(Atoms.Attributes)
                if attributes then
                    local level = attributes.Level or 0
                    local gems = attributes.Gems or 0
                    local gold = attributes.Gold or 0

                    -- ดึง Trait Reroll
                    local traitReroll = 0
                    pcall(function()
                        local data = Atoms.Data()
                        if data and data.MaterialsInventory then
                            traitReroll = data.MaterialsInventory["Trait Reroll"] or 0
                        end
                    end)

                    -- Format message
                    local msg = string.format(
                        "⭐ Level %d | 💎 Gems %s | 💰 Gold %s | 🔄 RR %d",
                        level,
                        tostring(gems):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""),
                        tostring(gold):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""),
                        traitReroll
                    )

                    -- Encode JSON data
                    local json_data = {
                        Level = level,
                        Gems = gems,
                        Gold = gold,
                        TraitReroll = traitReroll
                    }
                    local encoded_json = HttpService:JSONEncode(json_data)

                    -- ส่ง Status Update พร้อม JSON
                    _G.Horst_SetDescription(msg, encoded_json)
                    print("   📤 Status sent:", msg)

                    -- เช็คเป้าหมาย (เฉพาะเมื่อ Horst เปิดอยู่)
                    if gems >= Config.GemTarget and _G.Horst_AccountChangeDone then
                        -- ส่ง description ก่อนส่ง DONE
                        _G.Horst_SetDescription(msg, encoded_json)

                        task.wait(15)  -- รอ 15 วิก่อนส่ง DONE

                        local ok, err = pcall(_G.Horst_AccountChangeDone)
                        if ok then
                            print(string.format("   ✅ Gem target reached! (%d/%d) - Account marked DONE", gems, Config.GemTarget))
                            return true  -- สำเร็จ
                        else
                            warn("   ❌ Failed to mark done:", err)
                        end
                    end
                end
            end)

            return success and result
        end

        -- ส่งทันที 1 รอบ
        local isDone = sendDescription()

        -- ส่งทุก 30 วินาที (ถ้ายังไม่ DONE)
        if not isDone then
            task.spawn(function()
                while task.wait(30) do
                    local done = sendDescription()
                    if done then
                        break  -- หยุดส่งถ้า DONE แล้ว
                    end
                end
            end)
        end
    elseif Config.Horst and not _G.Horst_SetDescription then
        warn("⚠️  Horst API enabled but _G.Horst_SetDescription not found!")
    end

    -- ════════════════════════════════════════════════════════
    -- [4-7] Skip (already in map)
    -- ════════════════════════════════════════════════════════
    print("⏭️  [4-7/8] Skipping (already in map)")

    -- ════════════════════════════════════════════════════════
    -- [8] Start Auto Retry Loop
    -- ════════════════════════════════════════════════════════
    print("🔄 [8/8] Starting auto retry...")

    task.wait(2)
    local ClientNetwork = require(ReplicatedStorage:WaitForChild("Networks"):WaitForChild("ClientNetwork"))

    spawn(function()
        while task.wait(5) do
            pcall(function()
                ClientNetwork.Player.Vote.Fire("Retry")
            end)
        end
    end)

    print("   ✅ Auto retry enabled")

    -- ════════════════════════════════════════════════════════
    -- Start Auto Farm
    -- ════════════════════════════════════════════════════════
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🚀 Starting Auto Farm...")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

    task.wait(2)

    -- ════════════════════════════════════════════════════════
    -- AUTO FARM CODE (ฝังจาก AutoFarm.lua)
    -- ════════════════════════════════════════════════════════

    local Atoms = require(ReplicatedStorage.Modules.Atoms)
    local ClientNetwork = require(ReplicatedStorage.Networks.ClientNetwork)

    -- Config
    local INITIAL_UNITS = {
        {name = "Irina Vladimirov", positions = {
            CFrame.new(-119.774254, 4.96331406, 84.4705963, -0.763562441, 0, -0.645734191, 0, 1, 0, 0.645734191, -0, -0.763562441),
            CFrame.new(-122.066879, 4.81113291, 84.1920547, -0.63436532, 0, -0.77303344, 0, 1, 0, 0.77303344, -0, -0.63436532),
            CFrame.new(-122.042007, 4.82000828, 82.1143265, -0.635893583, 0, -0.771776974, 0, 1, 0, 0.771776974, -0, -0.635893583),
            CFrame.new(-119.979752, 4.83409548, 82.2088776, -0.727462292, 0, -0.686147928, 0, 1, 0, 0.686147928, -0, -0.727462292)
        }},
        {name = "Gino", positions = {
            CFrame.new(-120.973129, 5.00879955, 86.3342361, -0.675218105, 0, -0.737618506, 0, 1, 0, 0.737618506, -0, -0.675218105),
            CFrame.new(-124.242935, 4.68392944, 84.9944077, -0.488479853, -0, -0.872575223, 0, 1, -0, 0.872575223, 0, -0.488479853),
            CFrame.new(-124.033661, 4.69273758, 82.8928986, -0.512774229, 0, -0.858523309, 0, 1, 0, 0.858523309, -0, -0.512774229),
            CFrame.new(-118.851219, 5.06564522, 86.4092255, -0.814989805, 0, -0.579475582, 0, 1, 0, 0.579475582, -0, -0.814989805)
        }},
        {name = "Gyoteng", positions = {
            CFrame.new(-97.932869, 4.32317924, 98.673996, -0.679522753, 0, -0.733654618, 0, 1, 0, 0.733654618, -0, -0.679522753),
            CFrame.new(-95.6349564, 4.43077087, 100.779037, -0.570931435, 0, -0.820997775, 0, 1, 0, 0.820997775, -0, -0.570931435),
            CFrame.new(-95.9012985, 4.43076897, 98.6109619, -0.681987166, 0, -0.731363952, 0, 1, 0, 0.731363952, -0, -0.681987166),
            CFrame.new(-97.7523651, 4.3406415, 100.843811, -0.633184671, 0, -0.774000585, 0, 1, 0, 0.774000585, -0, -0.633184671)
        }}
    }

    local REPLACEMENT_POSITIONS = {
        CFrame.new(-92.1280594, 4.38949394, 102.769608, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        CFrame.new(-93.7554092, 4.43076897, 98.3832474, 1, 0, 0, 0, 1, 0, 0, 0, 1),
        CFrame.new(-94.8104019, 4.42980194, 102.872177, -0.897651434, 0, -0.44070667, 0, 1, 0, 0.44070667, -0, -0.897651434),
        CFrame.new(-93.6753082, 4.43076706, 101.179253, -0.986574411, 0, -0.163313642, 0, 1, 0, 0.163313642, -0, -0.986574411)
    }

    -- Helper Functions
    local function getWave()
        local success, wave = pcall(function()
            local match = Atoms.Match and Atoms.Match()
            return match and match.Wave or 0
        end)
        return success and wave or 0
    end

    local function findUnitId(unitName)
        local success, result = pcall(function()
            local equipping = Atoms.EquippingUnits and Atoms.EquippingUnits()
            if not equipping then return nil end

            for slot = 1, 6 do
                local unitId = equipping[slot]
                if unitId then
                    local unitData = Atoms.UnitsInventory and Atoms.UnitsInventory()[unitId]
                    if unitData and unitData.Name == unitName then
                        return unitId
                    end
                end
            end
        end)
        return success and result or nil
    end

    local function getMoney()
        local success, money = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            for _, child in pairs(playerGui:GetChildren()) do
                if child.Name == "REACTMAIN" then
                    local stats = child:FindFirstChild("stats")
                    if stats then
                        local currency = stats:FindFirstChild("currency")
                        if currency then
                            local wonContainer = currency:FindFirstChild("wonContainer")
                            if wonContainer then
                                local unitPrice = wonContainer:FindFirstChild("unitPrice")
                                if unitPrice then
                                    local text = tostring(unitPrice.Text)
                                    local cleaned = text:gsub("₩", ""):gsub(",", ""):gsub("%s+", "")
                                    return tonumber(cleaned) or 0
                                end
                            end
                        end
                    end
                end
            end
            return 0
        end)
        return success and money or 0
    end

    -- CONTINUE_MARKER_AUTOFARM_1
    local function getUnitCost(unitName)
        local success, cost = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            for _, child in pairs(playerGui:GetChildren()) do
                if child.Name == "REACTMAIN" then
                    local slots = child:FindFirstChild("Slots")
                    if slots then
                        local slotHolder = slots:FindFirstChild("slotHolder")
                        if slotHolder then
                            for i = 1, 6 do
                                local slot = slotHolder:FindFirstChild("HotbarSlot" .. i)
                                if slot then
                                    local main = slot:FindFirstChild("Main")
                                    if main then
                                        local nameLabel = main:FindFirstChild("UnitName")
                                        local costLabel = main:FindFirstChild("CostPrice")

                                        if nameLabel and costLabel and nameLabel.Text == unitName then
                                            local cleanedCost = tostring(costLabel.Text):gsub("₩", ""):gsub(",", ""):gsub("%s+", "")
                                            return tonumber(cleanedCost) or 0
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return 0
        end)
        return success and cost or 0
    end

    local function placeUnit(unitId, unitName, cframe)
        local cost = getUnitCost(unitName)
        if cost > 0 then
            local currentMoney = getMoney()
            while currentMoney < cost do
                task.wait(0.5)
                currentMoney = getMoney()
            end
        end

        local success, result = pcall(function()
            return ClientNetwork.Player.PlaceUnit.Invoke(cframe, unitId):timeout(5):await()
        end)

        if success and result then
            task.wait(0.2)
            local holder = workspace:FindFirstChild("Holder")
            if holder then
                local clientUnits = holder:FindFirstChild("ClientUnits")
                if clientUnits then
                    local units = clientUnits:GetChildren()
                    if #units > 0 then
                        local newest = units[#units]
                        local uuid = newest:GetAttribute("ID")
                        return true, uuid
                    end
                end
            end
            return true, nil
        end
        return false, nil
    end

    local function enableAutoUpgrade(unitUUID)
        local success, err = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            local unitManager = playerGui:FindFirstChild("UnitManager")
            if not unitManager then return false end

            local scrollingFrame = unitManager.Frame.clip.scrollingFrame
            local unitPanel = scrollingFrame:FindFirstChild(unitUUID)
            if not unitPanel then return false end

            local buttonList = unitPanel:FindFirstChild("ButtonList")
            if not buttonList then return false end

            local button = buttonList:FindFirstChild("AutoUpgradeButton")
            if not button then return false end

            if button:IsA("GuiButton") then
                pcall(function() button.Activated:Fire() end)
                task.wait(0.05)
                pcall(function() button.MouseButton1Click:Fire() end)
                task.wait(0.05)
                pcall(function()
                    for _, conn in pairs(getconnections(button.MouseButton1Click)) do
                        conn:Fire()
                    end
                end)
            end

            return true
        end)
        return success
    end

    -- CONTINUE_MARKER_AUTOFARM_2
    local function sellUnit(unitUUID)
        local success = pcall(function()
            local playerGui = LocalPlayer.PlayerGui
            local unitManager = playerGui:FindFirstChild("UnitManager")
            if not unitManager then return false end

            local scrollingFrame = unitManager.Frame.clip.scrollingFrame
            local unitPanel = scrollingFrame:FindFirstChild(unitUUID)
            if not unitPanel then return false end

            local button = unitPanel:FindFirstChild("sellButton")
            if not button then return false end

            if button:IsA("GuiButton") then
                pcall(function() button.Activated:Fire() end)
                task.wait(0.05)
                pcall(function() button.MouseButton1Click:Fire() end)
                task.wait(0.05)
                pcall(function()
                    for _, conn in pairs(getconnections(button.MouseButton1Click)) do
                        conn:Fire()
                    end
                end)
            end

            return true
        end)
        return success
    end

    local function getPlacedUnits()
        local units = {}
        local success = pcall(function()
            local holder = workspace:FindFirstChild("Holder")
            if not holder then return end

            local clientUnits = holder:FindFirstChild("ClientUnits")
            if not clientUnits then return end

            for _, unit in ipairs(clientUnits:GetChildren()) do
                local uuid = unit:GetAttribute("ID")
                if uuid then
                    table.insert(units, {
                        name = unit.Name,
                        uuid = uuid,
                        instance = unit
                    })
                end
            end
        end)
        return units
    end

    -- Main Logic
    print("Waiting for Wave 0...")
    pcall(function()
        while getWave() ~= 0 do
            task.wait(1)
        end
    end)

    print("Wave 0 detected, placing units...")

    local placedUUIDs = {}
    for _, unitConfig in ipairs(INITIAL_UNITS) do
        pcall(function()
            print("Placing " .. unitConfig.name)
            local unitId = findUnitId(unitConfig.name)

            if not unitId then
                warn("Unit not found: " .. unitConfig.name)
                return
            end

            for _, cframe in ipairs(unitConfig.positions) do
                local success, uuid = placeUnit(unitId, unitConfig.name, cframe)
                if success and uuid then
                    table.insert(placedUUIDs, uuid)
                    task.wait(0.3)
                end
            end
        end)
    end

    print("Units placed, enabling auto upgrade...")
    task.wait(1)

    for _, uuid in ipairs(placedUUIDs) do
        pcall(function()
            enableAutoUpgrade(uuid)
            task.wait(0.1)
        end)
    end

    print("Auto upgrade enabled, waiting for Wave 15...")

    pcall(function()
        while getWave() < 15 do
            task.wait(1)
        end
    end)

    print("Wave 15 reached, countdown 15s...")
    task.wait(15)

    print("Selling Irina units...")

    pcall(function()
        local placedUnits = getPlacedUnits()
        for _, unit in ipairs(placedUnits) do
            if unit.name == "Irina Vladimirov" then
                sellUnit(unit.uuid)
                task.wait(0.2)
            end
        end
    end)

    print("Placing new Irina positions...")
    task.wait(1)

    pcall(function()
        local irinaId = findUnitId("Irina Vladimirov")
        if irinaId then
            local newIrinaUUIDs = {}
            for _, cframe in ipairs(REPLACEMENT_POSITIONS) do
                local success, uuid = placeUnit(irinaId, "Irina Vladimirov", cframe)
                if success and uuid then
                    table.insert(newIrinaUUIDs, uuid)
                    task.wait(0.3)
                end
            end

            print("Enabling auto upgrade for new Irina...")
            task.wait(1)

            for _, uuid in ipairs(newIrinaUUIDs) do
                enableAutoUpgrade(uuid)
                task.wait(0.1)
            end
        end
    end)

    print("Auto Farm Complete")
end

print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ Main Script Complete")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
