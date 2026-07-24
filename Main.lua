repeat wait() until game:IsLoaded()
-- 5.28
-- ========================================
-- Main Script - รวมทุกฟังก์ชันตามลำดับ
-- เพิ่ม: Toy Maker Tournament Mode
-- ========================================

-- ========================================
-- 0. Check PlayerGui (ต้องโหลดก่อนทุกอย่าง)
-- ========================================
do
    local Players = game:GetService("Players")

    local MINIMUM_GUI_COUNT = 50  -- จำนวน GUI ขั้นต่ำที่ต้องมี
    local MAX_WAIT_TIME = 30  -- รอสูงสุด 30 วินาที
    local CHECK_INTERVAL = 1  -- เช็คทุก 1 วินาที

    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)

    if not playerGui then
        warn("❌ PlayerGui not found - Kicking...")
        Players.LocalPlayer:Kick("PlayerGui failed to load. Please rejoin.")
        return
    end

    -- รอจนกว่า GUI จะโหลดครบ หรือครบเวลา 30 วิ
    local elapsedTime = 0

    while elapsedTime < MAX_WAIT_TIME do
        local guiCount = #playerGui:GetChildren()

        if guiCount >= MINIMUM_GUI_COUNT then
            break  -- โหลดสำเร็จ ให้รันสคริปต่อได้
        end

        task.wait(CHECK_INTERVAL)
        elapsedTime = elapsedTime + CHECK_INTERVAL
    end

    -- ถ้าครบ 30 วิแล้วยังโหลดไม่ครบ
    local finalCount = #playerGui:GetChildren()
    if finalCount < MINIMUM_GUI_COUNT then
        warn(string.format("❌ PlayerGui incomplete after %ds (%d/%d) - Kicking...", MAX_WAIT_TIME, finalCount, MINIMUM_GUI_COUNT))
        Players.LocalPlayer:Kick(string.format("PlayerGui failed to load properly (%d/%d). Please rejoin.", finalCount, MINIMUM_GUI_COUNT))
        return
    end
end

-- ========================================
-- Anti-AFK (โหลดก่อนอันแรก)
-- ========================================
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- VirtualUser Anti-AFK (Passive)
Players.LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Random Edge Click Anti-AFK (Active)
spawn(function()
    local camera = workspace.CurrentCamera

    while true do
        -- รอ random 30-60 วินาที
        task.wait(math.random(30, 60))

        pcall(function()
            local screenSize = camera.ViewportSize

            -- สุ่มมุมจอ
            local edges = {
                {x = 10, y = 10},                              -- มุมซ้ายบน
                {x = screenSize.X - 10, y = 10},              -- มุมขวาบน
                {x = 10, y = screenSize.Y - 10},              -- มุมซ้ายล่าง
                {x = screenSize.X - 10, y = screenSize.Y - 10}, -- มุมขวาล่าง
                {x = screenSize.X / 2, y = 10},               -- กลางบน
                {x = screenSize.X / 2, y = screenSize.Y - 10}, -- กลางล่าง
            }

            -- สุ่มเลือกมุม
            local edge = edges[math.random(1, #edges)]

            -- คลิก
            VirtualInputManager:SendMouseButtonEvent(edge.x, edge.y, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(edge.x, edge.y, 0, false, game, 0)
        end)
    end
end)

-- ========================================
-- CONFIG (รองรับ External Config)
-- ========================================
_G.Config = _G.Config or {}
local HORST_ENABLED = _G.Config.Horst == true
local GEM_TARGET = _G.Config.GemTarget  -- nil = ไม่ส่ง DONE
local UPDATE_INTERVAL = 30
local TOGGLE_RENDER3D = _G.Config.ToggleRender3D == true  -- ผูก Render3D กับ GUI toggle

-- Toy Maker Tournament Config
local GET_TOY_MAKER = _G.Config.GetToyMaker == true  -- false = ไม่ต้องทำอะไร
local TARGET_TRAIT_TOY_MAKER = _G.Config.TargetTraitToyMaker or {"Unbound", "Primordial", "Forsaken", "Draconic"}

-- Secret Unit Config
local CHANGE_ACC_SECRETS = _G.Config.Change_Acc_Secrets == true  -- true = ส่ง DONE หลัง Trait Reroll ของ Secret, false = ข้ามไปฟาร์มตามปกติ

-- Summon Config
local SUMMON_CONFIG = _G.Config.SummonUnits or {}
-- ถ้าเป็น string ให้แปลงเป็น table (ยกเว้น "auto" จะถูก override ภายหลัง)
if type(SUMMON_CONFIG) == "string" then
    if SUMMON_CONFIG:lower() == "auto" then
        SUMMON_CONFIG = {}  -- จะถูก override เป็น Secret + Mythic ภายหลัง
    else
        SUMMON_CONFIG = {SUMMON_CONFIG}  -- แปลง "Shadow" → {"Shadow"}
    end
end
local MYTHIC_UNITS = {"Cursed Student", "Elf Mage", "Flame Emperor", "Hollow", "Lady Giant", "Puppet", "Salmon Sorcerer", "String Demon"}
local SECRET_UNITS = {"Shadow"}
local hasSummonConfig = _G.Config.SummonUnits and (
    (type(_G.Config.SummonUnits) == "string" and _G.Config.SummonUnits ~= "") or
    (type(_G.Config.SummonUnits) == "table" and #_G.Config.SummonUnits > 0)
)

-- Trait Reroll Config
local TRAIT_REROLL_CONFIG = _G.Config.TraitReroll or {}
-- ตัวอย่าง:
-- _G.Config.TraitReroll = {
--     TargetUnit = "Ice Queen",                          -- ตัวที่ต้องการสุ่ม Trait
--     TargetTrait = {"Enlightenment", "Ultimate"}        -- Trait ที่ต้องการ (หลายตัว)
--     หรือ TargetTrait = "Enlightenment"                 -- Trait เดียว
--     หรือ TargetTrait = nil                             -- อะไรก็ได้ที่ไม่ใช่ None
--     หรือ TargetTrait = {}                              -- ไม่ต้องสุ่ม (ข้าม)
-- }

-- Priority List สำหรับเลือก Unit ที่จะสุ่ม Trait (ถ้า Config ตั้ง SummonUnits หลายตัว)
local TRAIT_REROLL_PRIORITY = {
    "Shadow",           -- Priority 1 (Secret)
    "Puppet",           -- Priority 2 (Mythic)
    "Cursed Student",   -- Priority 3 (Mythic)
    "Lady Giant",       -- Priority 4 (Mythic)
    "Elf Mage",         -- Priority 5 (Mythic)
    "Flame Emperor",    -- Priority 6 (Mythic)
    "Hollow",           -- Priority 7 (Mythic)
    "Salmon Sorcerer",  -- Priority 8 (Mythic)
    "String Demon"      -- Priority 9 (Mythic)
}

local function printStep(stepName)
    print(string.format("🔄 %s", stepName))
end

-- ฟังก์ชันเช็ค Banner ณ ตอนนี้ (Global scope)
local function checkCurrentBanner()
    local success, result = pcall(function()
        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))

        Nodes.TOGGLE_MENU:FireSelf("Summon", true)
        task.wait(2)

        local summonGui = Players.LocalPlayer.PlayerGui:FindFirstChild("Summon")
        if not summonGui then return {} end

        local foundUnits = {}
        local blacklist = {["Summon"]=true, ["Settings"]=true, ["Rates"]=true, ["Mythic Unit"]=true}

        for _, child in ipairs(summonGui:GetDescendants()) do
            if child:IsA("TextLabel") and child.Visible then
                local text = child.Text or child.ContentText or ""
                if text ~= "" and text:match("^[A-Z]") and #text >= 3 and #text < 30 then
                    if not blacklist[text] then
                        local hasFolder = false
                        local current = child.Parent
                        for i = 1, 5 do
                            if not current then break end
                            if current:IsA("Folder") then hasFolder = true; break end
                            current = current.Parent
                        end
                        if hasFolder and not foundUnits[text] then foundUnits[text] = true end
                    end
                end
            end
        end

        Nodes.TOGGLE_MENU:FireSelf("Summon", false)
        task.wait(0.5)

        local unitList = {}
        for unitName, _ in pairs(foundUnits) do table.insert(unitList, unitName) end
        return unitList
    end)
    return success and result or {}
end

-- ========================================
-- -1. Load Horst API (ถ้า Config เปิด)
-- ========================================
if HORST_ENABLED then
    printStep("Loading Horst API...")
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/HorstSpaceX/last_update/main/on_loaded.lua"))()
    end)

    if success then
        if GEM_TARGET then
        else
        end
    else
        warn("   ❌ Failed to load Horst API:", err)
        HORST_ENABLED = false
    end
    task.wait(1)
end

-- ========================================
-- 0. StatsGUI (โหลดก่อนอันแรก)
-- ========================================
printStep("Loading Stats GUI...")

-- ========================================
-- Global Flag สำหรับหยุดสคริปต์
-- ========================================
_G.ScriptShouldStop = false  -- ใช้ _G เพื่อให้เข้าถึงได้ทุกที่

local statsGuiSuccess, statsGuiError = pcall(function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))

    -- สร้าง ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "StatsDisplay"
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

    -- Stats
    local stats = {
        {name = "Gem", key = "Gem", color = Color3.fromRGB(194, 144, 90), order = 2},
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

        local statCorner = Instance.new("UICorner")
        statCorner.CornerRadius = UDim.new(0, 10)
        statCorner.Parent = statBox

        local statStroke = Instance.new("UIStroke")
        statStroke.Color = Color3.fromRGB(139, 90, 43)
        statStroke.Thickness = 3
        statStroke.Parent = statBox

        -- Container สำหรับ name และ value
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

        -- Name (ซ้าย)
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

        -- Colon (กลาง)
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

        -- Value (ขวา)
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

    -- ฟังก์ชันใส่ลูกน้ำ
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

    -- ฟังก์ชันดึงค่า Stats
    local function updateStats()
        local success, err = pcall(function()
            local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
            if not replica then
                error("Replica not found")
            end

            local data = replica.Data
            local itemData = data.ItemData
            if not itemData then
                error("ItemData not found")
            end

            -- Gem
            local gem = 0
            if itemData.Gem and type(itemData.Gem) == "table" and itemData.Gem.Amount then
                gem = itemData.Gem.Amount
            end
            statsLabels.Gem.Text = formatNumber(gem)

            -- Gold
            local gold = 0
            if itemData.Gold and type(itemData.Gold) == "table" and itemData.Gold.Amount then
                gold = itemData.Gold.Amount
            end
            statsLabels.Gold.Text = formatNumber(gold)

            -- Trait Reroll
            local traitReroll = 0
            if itemData.TraitReroll and type(itemData.TraitReroll) == "table" and itemData.TraitReroll.Amount then
                traitReroll = itemData.TraitReroll.Amount
            end
            statsLabels.TraitReroll.Text = formatNumber(traitReroll)
        end)

        if not success then
            warn("StatsGUI update error:", err)
        end
    end

    -- Update แบบ Real-time (ตรวจจับการเปลี่ยนแปลง + Error Handling)
    task.wait(2)
    updateStats()

    -- เก็บค่าเก่าเพื่อเปรียบเทียบ
    local lastGem = 0
    local lastGold = 0
    local lastTrait = 0
    local errorCount = 0
    local maxErrors = 5
    local checkCounter = 0

    -- Initialize ค่าเริ่มต้น
    local success = pcall(function()
        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
        if replica then
            local data = replica.Data
            local itemData = data.ItemData
            if itemData then
                lastGem = itemData.Gem and itemData.Gem.Amount or 0
                lastGold = itemData.Gold and itemData.Gold.Amount or 0
                lastTrait = itemData.TraitReroll and itemData.TraitReroll.Amount or 0
            end
        end
    end)

    -- เช็คทุก 0.5 วินาทีแทนทุกเฟรม (ลด CPU usage)
    spawn(function()
        while true do
            task.wait(0.5)  -- เช็คทุก 0.5 วินาที (ประหยัดสเปค)

            local success, err = pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if not replica then
                    error("Replica not found")
                end

                local data = replica.Data
                if not data then
                    error("Data not found")
                end

                local itemData = data.ItemData
                if not itemData then
                    error("ItemData not found")
                end

                -- ดึงค่าปัจจุบัน
                local currentGem = itemData.Gem and type(itemData.Gem) == "table" and itemData.Gem.Amount or 0
                local currentGold = itemData.Gold and type(itemData.Gold) == "table" and itemData.Gold.Amount or 0
                local currentTrait = itemData.TraitReroll and type(itemData.TraitReroll) == "table" and itemData.TraitReroll.Amount or 0

                -- เช็คว่าค่าเปลี่ยนหรือไม่
                if currentGem ~= lastGem or currentGold ~= lastGold or currentTrait ~= lastTrait then
                    -- อัพเดททันที
                    if currentGem ~= lastGem then
                        statsLabels.Gem.Text = formatNumber(currentGem)
                        lastGem = currentGem
                    end

                    if currentGold ~= lastGold then
                        statsLabels.Gold.Text = formatNumber(currentGold)
                        lastGold = currentGold
                    end

                    if currentTrait ~= lastTrait then
                        statsLabels.TraitReroll.Text = formatNumber(currentTrait)
                        lastTrait = currentTrait
                    end

                    -- Reset error count เมื่ออัพเดทสำเร็จ
                    errorCount = 0
                end
            end)

            -- Error Handling - ลอง retry
            if not success then
                errorCount = errorCount + 1

                if errorCount <= maxErrors then
                    warn(string.format("⚠️ StatsGUI error (%d/%d): %s - Retrying...", errorCount, maxErrors, tostring(err)))

                    -- พยายาม force update
                    task.spawn(function()
                        task.wait(0.5)
                        pcall(updateStats)
                    end)
                elseif errorCount == maxErrors + 1 then
                    warn(string.format("❌ StatsGUI failed after %d attempts - Will keep trying silently", maxErrors))
                end
            end
        end
    end)

    -- ========================================
    -- Toggle GUI with N key (+ Render3D ถ้าเปิด Config)
    -- ========================================
    local UserInputService = game:GetService("UserInputService")
    local isGuiVisible = true

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.N then
            isGuiVisible = not isGuiVisible
            mainFrame.Visible = isGuiVisible

            if TOGGLE_RENDER3D then
                if isGuiVisible then
                    game:GetService("RunService"):Set3dRenderingEnabled(false)
                else
                    game:GetService("RunService"):Set3dRenderingEnabled(true)
                end
            end
        end
    end)

    if TOGGLE_RENDER3D then
        game:GetService("RunService"):Set3dRenderingEnabled(false)
    end

    -- ========================================
    -- Horst Status Reporter (Real-time + Error Handling + ส่งทุก 30 วิ)
    -- ========================================
    if HORST_ENABLED then
        local doneSent = false
        local lastHorstGem = 0
        local lastHorstGold = 0
        local lastHorstTrait = 0
        local lastHorstLevel = 0
        local horstErrorCount = 0
        local maxHorstErrors = 5

        -- ฟังก์ชันส่ง Status (พร้อม Error Handling)
        local function sendHorstStatus()
            local success, err = pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if not replica then
                    error("Replica not found")
                end

                local data = replica.Data
                if not data then
                    error("Data not found")
                end

                local itemData = data.ItemData
                if not itemData then
                    error("ItemData not found")
                end

                -- ดึงข้อมูล Stats
                local level = data.Level or 0
                local gem = itemData.Gem and type(itemData.Gem) == "table" and itemData.Gem.Amount or 0
                local gold = itemData.Gold and type(itemData.Gold) == "table" and itemData.Gold.Amount or 0
                local trait = itemData.TraitReroll and type(itemData.TraitReroll) == "table" and itemData.TraitReroll.Amount or 0

                -- สร้าง Status Message
                local HttpService = game:GetService("HttpService")
                local json_data = {
                    Level = level,
                    Gem = gem,
                    Gold = gold,
                    Trait = trait
                }
                local encoded_json = HttpService:JSONEncode(json_data)

                local message = string.format("⭐ Level : %d • 💎 Gems : %s • 🪙 Gold : %s • 🎲 RR : %s",
                    level, formatNumber(gem), formatNumber(gold), formatNumber(trait))

                -- ส่ง Status Update
                if _G.Horst_SetDescription then
                    _G.Horst_SetDescription(message, encoded_json)
                    horstErrorCount = 0  -- Reset error count เมื่อส่งสำเร็จ
                end

                -- เช็คเป้าหมาย Gem (ถ้ามี GEM_TARGET)
                -- ⚠️ ข้ามการเช็คถ้ามี SummonUnits Config (ต้องให้ไปสุ่มก่อน)
                if GEM_TARGET and gem >= GEM_TARGET and not doneSent and not hasSummonConfig then
                    if _G.Horst_AccountChangeDone then
                        -- ส่ง Description ก่อน
                        if _G.Horst_SetDescription then
                            _G.Horst_SetDescription(message, encoded_json)
                        end

                        task.wait(5)  -- รอ 5 วิก่อนส่ง DONE

                        local ok, doneErr = pcall(_G.Horst_AccountChangeDone)
                        if ok then
                            doneSent = true
                            _G.ScriptShouldStop = true  -- ตั้งค่า flag หลังส่ง DONE
                            print("✅ GEM_TARGET reached (no summon config) - Script will stop...")
                        else
                            warn(string.format("❌ Failed to send DONE: %s", tostring(doneErr)))
                        end
                    else
                        warn("❌ Horst_AccountChangeDone function not found")
                    end
                end
            end)

            if not success then
                horstErrorCount = horstErrorCount + 1
                if horstErrorCount <= maxHorstErrors then
                    warn(string.format("⚠️ Horst error (%d/%d): %s - Retrying...", horstErrorCount, maxHorstErrors, tostring(err)))
                elseif horstErrorCount == maxHorstErrors + 1 then
                    warn(string.format("❌ Horst failed after %d attempts - Will keep trying silently", maxHorstErrors))
                end
            end
        end

        -- Initialize ค่าเริ่มต้น
        task.wait(1)
        local initSuccess = pcall(function()
            local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
            if replica then
                local data = replica.Data
                local itemData = data.ItemData
                if data and itemData then
                    lastHorstLevel = data.Level or 0
                    lastHorstGem = itemData.Gem and itemData.Gem.Amount or 0
                    lastHorstGold = itemData.Gold and itemData.Gold.Amount or 0
                    lastHorstTrait = itemData.TraitReroll and itemData.TraitReroll.Amount or 0
                end
            end
        end)

        -- ส่งรอบแรกทันที (แต่ไม่เช็ค GEM_TARGET ถ้ามี SummonUnits Config)
        -- ใช้ flag ชั่วคราวเพื่อข้าม GEM_TARGET check ในรอบแรก
        local skipFirstGemCheck = hasSummonConfig
        if skipFirstGemCheck then
            -- ถ้ามี SummonUnits Config ให้ส่งแค่ Description ไม่ตรวจสอบ GEM_TARGET
            local success = pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if replica and replica.Data and replica.Data.ItemData then
                    local data = replica.Data
                    local itemData = data.ItemData
                    local level = data.Level or 0
                    local gem = itemData.Gem and itemData.Gem.Amount or 0
                    local gold = itemData.Gold and itemData.Gold.Amount or 0
                    local trait = itemData.TraitReroll and itemData.TraitReroll.Amount or 0

                    local message = string.format("⭐ Level : %d • 💎 Gems : %s • 🪙 Gold : %s • 🎲 RR : %s",
                        level, formatNumber(gem), formatNumber(gold), formatNumber(trait))

                    if _G.Horst_SetDescription then
                        _G.Horst_SetDescription(message, "")
                    end
                end
            end)
        else
            -- ถ้าไม่มี SummonUnits Config ให้ทำงานปกติ (รวมเช็ค GEM_TARGET)
            sendHorstStatus()
        end

        -- Real-time update (เช็คทุก 1 วินาที แทน 0.3 วิ - ประหยัดสเปค)
        spawn(function()
            while HORST_ENABLED and not _G.ScriptShouldStop do
                task.wait(1)  -- เช็คทุก 1 วินาที (ประหยัดสเปค)

                local success, err = pcall(function()
                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                    if not replica then
                        error("Replica not found")
                    end

                    local data = replica.Data
                    if not data then
                        error("Data not found")
                    end

                    local itemData = data.ItemData
                    if not itemData then
                        error("ItemData not found")
                    end

                    local currentLevel = data.Level or 0
                    local currentGem = itemData.Gem and type(itemData.Gem) == "table" and itemData.Gem.Amount or 0
                    local currentGold = itemData.Gold and type(itemData.Gold) == "table" and itemData.Gold.Amount or 0
                    local currentTrait = itemData.TraitReroll and type(itemData.TraitReroll) == "table" and itemData.TraitReroll.Amount or 0

                    -- เช็คว่าค่าเปลี่ยนหรือไม่
                    if currentLevel ~= lastHorstLevel or currentGem ~= lastHorstGem or
                       currentGold ~= lastHorstGold or currentTrait ~= lastHorstTrait then

                        -- ส่ง update ทันที
                        sendHorstStatus()

                        -- บันทึกค่าใหม่
                        lastHorstLevel = currentLevel
                        lastHorstGem = currentGem
                        lastHorstGold = currentGold
                        lastHorstTrait = currentTrait
                    end
                end)

                if not success then
                    -- Silent retry - ไม่ warn เพราะจะลองใหม่ใน 1 วิ
                end
            end
        end)

        -- Fallback: ส่งทุก 30 วิ (กรณี real-time พลาด)
        spawn(function()
            while HORST_ENABLED and not _G.ScriptShouldStop do
                task.wait(UPDATE_INTERVAL)
                sendHorstStatus()
            end
        end)
    end
end)

if not statsGuiSuccess then
    warn("❌ StatsGUI failed to load:", statsGuiError)
end
task.wait(1)

-- Config (สามารถแก้ไขได้จาก loadstring)
_G.Config = _G.Config or {
    Disable3DRendering = false
}

-- ========================================
-- ฟังก์ชันเช็คแมพ - ต้องเช็คหลัง Stats GUI โหลดเสร็จ
-- ========================================
local function isInTargetMap()
    local success, result = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))

        -- Method 1: ใช้ Map Replicas (แม่นยำกว่า)
        local allMaps = Nodes.GET_ALL_MAP_REPLICAS:InvokeSelf()

        if allMaps then
            for mapID, mapReplica in pairs(allMaps) do
                local data = mapReplica.Data
                local parameters = data.Parameters or {}

                -- เช็คว่าเป็น SchoolGrounds Act 1 Story Mode
                if parameters.MapName == "SchoolGrounds" and
                   parameters.ActName == "Act 1" and
                   parameters.Gamemode == "Story" then
                    return true
                end
            end
        end

        return false
    end)
    return success and result
end

-- ฟังก์ชันเช็คว่าอยู่ใน Tournament (Toy Maker) หรือไม่
local function isInToyMakerTournament()
    local success, result = pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))

        -- ใช้ Map Replicas
        local allMaps = Nodes.GET_ALL_MAP_REPLICAS:InvokeSelf()

        if allMaps then
            for mapID, mapReplica in pairs(allMaps) do
                local data = mapReplica.Data
                local parameters = data.Parameters or {}

                -- เช็คว่าเป็น Tournament Mode (ทุก Act)
                if parameters.Gamemode == "Tournament" then
                    return true
                end
            end
        end

        return false
    end)
    return success and result
end

-- เช็คและรอ Wave รีเซ็ต
-- ========================================
-- ฟังก์ชัน RemoveLobbyMesh (ใช้ร่วมกันระหว่าง In-Game และ Lobby)
-- ========================================
local function applyPerformanceOptimizations()
    local Config = _G.Config

    local g = game
    local w = g.Workspace
    local l = g.Lighting
    local t = w.Terrain

    if Config.Disable3DRendering then
        local RunService = game:GetService("RunService")
        RunService:Set3dRenderingEnabled(false)
    end

    t.WaterWaveSize = 0
    t.WaterWaveSpeed = 0
    t.WaterReflectance = 0
    t.WaterTransparency = 0

    local Lighting = game:GetService("Lighting")
    Lighting.Brightness = 0
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.ColorShift_Bottom = Color3.fromRGB(128, 128, 128)
    Lighting.ColorShift_Top = Color3.fromRGB(128, 128, 128)
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.FogEnd = 9e9

    settings().Rendering.QualityLevel = "Level01"

    -- เช็ค Map ก่อน (เพราะเมื่ออยู่ในเกมให้ลบ Map ไม่ใช่ Lobby)
    local lobbyFolder = workspace:FindFirstChild("Lobby")
    local mapFolder = workspace:FindFirstChild("Map")

    if mapFolder then
        -- ลบ children ของ Map (เกมจะสร้าง folder ใหม่ถ้าลบทั้งก้อน)
        for _, obj in pairs(mapFolder:GetChildren()) do
            obj:Destroy()
        end

        -- สร้างพื้นล่องหนไว้ที่เท้าผู้เล่น
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local invisibleFloor = Instance.new("Part")
            invisibleFloor.Name = "InvisibleFloor"
            invisibleFloor.Size = Vector3.new(2000, 1, 2000)
            invisibleFloor.Position = rootPart.Position - Vector3.new(0, 5, 0)
            invisibleFloor.Anchored = true
            invisibleFloor.Transparency = 1
            invisibleFloor.CanCollide = true
            invisibleFloor.Material = Enum.Material.SmoothPlastic
            invisibleFloor.Parent = workspace
        end
    elseif lobbyFolder then
        for _, obj in pairs(lobbyFolder:GetChildren()) do
            obj:Destroy()
        end

        -- สร้างพื้นล่องหนสำหรับ Lobby
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos = player.Character.HumanoidRootPart.Position
            local floor = Instance.new("Part")
            floor.Name = "InvisibleFloor"
            floor.Size = Vector3.new(2000, 1, 2000)
            floor.Position = Vector3.new(pos.X, pos.Y - 3, pos.Z)
            floor.Anchored = true
            floor.Transparency = 1
            floor.CanCollide = true
            floor.Material = Enum.Material.SmoothPlastic
            floor.Parent = workspace
        end
    end

    for _, obj in pairs(Lighting:GetChildren()) do
        obj:Destroy()
    end

    local MaterialService = game:GetService("MaterialService")
    for _, obj in pairs(MaterialService:GetChildren()) do
        obj:Destroy()
    end

    for _, obj in pairs(workspace:GetDescendants()) do
        local success, err = pcall(function()
            if obj:IsA("Texture") or obj:IsA("Decal") then
                obj.Transparency = 1
            elseif obj:IsA("SurfaceAppearance") then
                obj:Destroy()
            elseif obj:IsA("Part") or obj:IsA("Union") or obj:IsA("CornerWedgePart") or obj:IsA("TrussPart") or obj:IsA("UnionOperation") then
                obj.Material = "Plastic"
                obj.Color = Color3.fromRGB(128, 128, 128)
                obj.Reflectance = 0
            elseif obj:IsA("MeshPart") then
                obj.Material = "Plastic"
                obj.Color = Color3.fromRGB(128, 128, 128)
                obj.Reflectance = 0
                obj.TextureID = ""
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Enabled = false
            elseif obj:IsA("Explosion") then
                obj.BlastPressure = 1
                obj.BlastRadius = 1
            elseif obj:IsA("Fire") or obj:IsA("SpotLight") or obj:IsA("Smoke") then
                obj.Enabled = false
            end
        end)
        if not success then
            print(string.format("⚠️ [Performance] Failed to modify %s (%s): %s", obj.Name, obj.ClassName, tostring(err)))
        end
    end

    for _, e in pairs(Lighting:GetChildren()) do
        if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
            e.Enabled = false
        end
    end

    for _, player in pairs(game.Players:GetPlayers()) do
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                pcall(function()
                    if part:IsA("Texture") or part:IsA("Decal") then
                        part.Transparency = 1
                    elseif part:IsA("MeshPart") then
                        part.TextureID = ""
                        part.Material = "Plastic"
                        part.Color = Color3.fromRGB(128, 128, 128)
                        part.Reflectance = 0
                    elseif part:IsA("BasePart") then
                        part.Material = "Plastic"
                        part.Color = Color3.fromRGB(128, 128, 128)
                        part.Reflectance = 0
                    elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
                        part.Enabled = false
                    elseif part:IsA("Fire") or part:IsA("SpotLight") or part:IsA("Smoke") then
                        part.Enabled = false
                    end
                end)
            end
        end
    end
end

-- ========================================
-- เช็คแมพหลังโหลด Stats GUI เสร็จแล้ว
-- ========================================
print("🔍 Checking current map...")

-- เช็ค flag ก่อนทำงานต่อ
if _G.ScriptShouldStop then
    print("⛔ Script stopped by DONE signal")
    return
end

-- ตอนนี้อยู่ในแมพหรือไม่
if isInTargetMap() then
    print("✅ In Story Mode (School Grounds - Act 1)")
    spawn(function()
        -- ปิด Tutorial popup (ถ้ามี)
        local function closeTutorial()
        local success = pcall(function()
            local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
            local prompt = playerGui:FindFirstChild("Prompt")
            if not prompt then return end

            local tutorialLabel = prompt.Frame.Frame.Folder.Frame.Frame.Frame.TextLabel
            if tutorialLabel then
                local text = tutorialLabel.ContentText or tutorialLabel.Text
                if text == "Tutorial" then
                    local closeButton = prompt.Frame.Frame.Folder.Frame:FindFirstChild("PrimaryButton")
                    if closeButton then
                        local GuiService = game:GetService("GuiService")
                        local VirtualInputManager = game:GetService("VirtualInputManager")

                        GuiService.SelectedCoreObject = nil
                        task.wait(0.1)

                        closeButton.Selectable = true
                        GuiService.SelectedCoreObject = closeButton
                        task.wait(0.1)

                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                        task.wait(0.2)
                        GuiService.SelectedCoreObject = nil

                        return
                    end
                end
            end
        end)
        if not success then
        end
    end

    closeTutorial()
    task.wait(0.5)

    -- ใช้ฟังก์ชัน Performance Optimization
    applyPerformanceOptimizations()


    -- ====================================
    -- ระบบวาง + อัพเกรด (เหมือน Path B)
    -- ====================================
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local ReplicaClient = require(Shared:WaitForChild("ReplicaClient"))

    -- ตัวแปรสำหรับเก็บ Connection และ State
    local currentConnection = nil
    local allPlacedIDs = {}

    local function getCurrentWave()
        -- Method 1: อ่านจาก Game Replica (ถูกต้อง - ยืนยันจาก CheckWave.lua)
        local success1, wave1 = pcall(function()
            local gameReplica = Nodes.GET_GAME_REPLICA:InvokeSelf()
            if gameReplica and gameReplica.Data and gameReplica.Data.Wave then
                return tonumber(gameReplica.Data.Wave) or 0
            end
            return nil
        end)

        if success1 and wave1 then
            return wave1
        end

        -- Method 2: Fallback - อ่านจาก GUI (พร้อม timeout)
        local success2, wave2 = pcall(function()
            local startTime = tick()
            local timeout = 3

            while tick() - startTime < timeout do
                local topHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("TopGameHUD")
                if topHUD then
                    local success, result = pcall(function()
                        local waveLabel = topHUD.Frame:GetChildren()[4].Frame.Frame.Frame.Frame.Frame.TextLabel
                        local text = waveLabel.ContentText or waveLabel.Text
                        return tonumber(string.match(text, "^(%d+)")) or 0
                    end)
                    if success and result then
                        return result
                    end
                end
                task.wait(0.5)
            end
            return nil
        end)

        if success2 and wave2 then
            warn("⚠️ Wave detection fallback to GUI (Game Replica failed)")
            return wave2
        end

        warn("⚠️ Wave detection failed - both Replica and GUI methods failed, returning 0")
        return 0
    end

    local function resetFarmingState()
        print("🔄 [resetFarmingState] Resetting state...")
        -- Disconnect connection เก่า (ถ้ามี)
        if currentConnection then
            pcall(function()
                currentConnection:Disconnect()
                print("   ✅ [resetFarmingState] Disconnected old connection")
            end)
            currentConnection = nil
        end

        -- ล้างข้อมูล Unit เก่า
        local oldCount = #allPlacedIDs
        allPlacedIDs = {}
        print(string.format("   🗑️ [resetFarmingState] Cleared %d old unit IDs", oldCount))
    end

    local function placeAndUpgrade()
        print("═══════════════════════════════════════")
        print("🎮 [placeAndUpgrade] Starting new phase")
        print("═══════════════════════════════════════")

        local DELAY_AFTER_PLACE = 1
        local AUTO_UPGRADE_PRIORITY = 1

        local function getCurrentMoney()
            -- Method 1: อ่านจาก Replica (เชื่อถือได้กว่า)
            local success, money = pcall(function()
                local replica = Nodes.GET_GAME_PLAYER_REPLICA:InvokeSelf()
                if replica and replica.Data and replica.Data.Yen then
                    return replica.Data.Yen
                end
                return nil
            end)

            if success and money then
                return money
            else
                warn("⚠️ [getCurrentMoney] Replica method failed, using GUI fallback")
            end

            -- Method 2: Fallback อ่านจาก GUI
            local success2, money2 = pcall(function()
                local bottomHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("BottomHUD")
                if not bottomHUD then return 0 end
                local moneyLabel = bottomHUD:GetChildren()[2]:GetChildren()[6].Frame.Frame.TextLabel
                local moneyText = moneyLabel.ContentText
                local cleaned = (moneyText:gsub("[^%d]", ""))
                return tonumber(cleaned) or 0
            end)

            if not success2 or not money2 or money2 == 0 then
                warn("❌ [getCurrentMoney] Both Replica and GUI methods failed")
            end
            return success2 and money2 or 0
        end

        local function getUnitCost(slot)
            local targetSlot = tonumber(slot)
            if not targetSlot then
                warn(string.format("❌ [getUnitCost] Invalid slot: %s", tostring(slot)))
                return 999999
            end

            local attempts = 0
            while attempts < 10 do  -- สูงสุด 10 ครั้ง (5 วินาที)
                local success, result, errorMsg = pcall(function()
                    local bottomHUD = Players.LocalPlayer.PlayerGui:FindFirstChild("BottomHUD")
                    if not bottomHUD then return nil, "BottomHUD not found" end

                    -- ใช้ pcall สำหรับ GetChildren เพื่อความปลอดภัย
                    local success1, children2 = pcall(function()
                        return bottomHUD:GetChildren()[2]
                    end)
                    if not success1 or not children2 then return nil, "Cannot access children[2]" end

                    local success2, children5 = pcall(function()
                        return children2:GetChildren()[5]
                    end)
                    if not success2 or not children5 then return nil, "Cannot access children[5]" end

                    local hotbarContainer = children5

                    for _, child in ipairs(hotbarContainer:GetChildren()) do
                        if child:IsA("TextButton") and child.LayoutOrder == targetSlot then
                            -- ใช้ FindFirstChild แทน direct access
                            local frame = child:FindFirstChild("Frame")
                            if not frame then return nil, "No Frame in button" end

                            local children = frame:GetChildren()
                            if children[3] and children[3]:IsA("Frame") then
                                local innerFrame = children[3]:FindFirstChild("Frame")
                                if innerFrame then
                                    local textLabel = innerFrame:FindFirstChild("TextLabel")
                                    if textLabel then
                                        local costText = textLabel.ContentText or textLabel.Text
                                        local cleaned = (costText:gsub("[^%d]", ""))
                                        local parsed = tonumber(cleaned)
                                        if parsed and parsed > 0 then
                                            return parsed, nil
                                        else
                                            return nil, "Failed to parse cost text: " .. costText
                                        end
                                    else
                                        return nil, "No TextLabel in innerFrame"
                                    end
                                else
                                    return nil, "No inner Frame in child[3]"
                                end
                            else
                                return nil, "No Frame at child[3]"
                            end
                        end
                    end
                    return nil, string.format("Slot %d not found in hotbar", targetSlot)
                end)

                if success and result then
                    return result
                elseif success and not result then
                    -- pcall สำเร็จแต่ไม่เจอราคา
                    if attempts == 0 then
                        warn(string.format("⚠️ [getUnitCost] Slot %s error: %s (attempt %d/10)", slot, tostring(errorMsg), attempts + 1))
                    end
                else
                    -- pcall ล้มเหลว
                    if attempts == 0 then
                        warn(string.format("⚠️ [getUnitCost] Slot %s pcall failed: %s (attempt %d/10)", slot, tostring(result), attempts + 1))
                    end
                end

                attempts = attempts + 1
                task.wait(0.5)
            end

            warn(string.format("⚠️ [getUnitCost] Failed to detect cost for slot %s after 10 attempts", slot))
            return 999999
        end

        print("🔍 [placeAndUpgrade] Getting Player Replica...")

        print("🔍 [placeAndUpgrade] Getting Player Replica...")
        local playerReplica = nil
        for i = 1, 5 do
            playerReplica = Nodes.GET_GAME_PLAYER_REPLICA:InvokeSelf()
            if playerReplica then
                print(string.format("✅ [placeAndUpgrade] Player Replica found (attempt %d/5)", i))
                break
            end
            warn(string.format("⚠️ [placeAndUpgrade] PlayerReplica not found - retry %d/5", i))
            task.wait(1)
        end

        if not playerReplica then
            warn("❌ [placeAndUpgrade] ไม่พบ Player Replica - aborting phase")
            return false
        end

        -- รีเซ็ต state ก่อนเริ่ม Phase ใหม่
        print("🔄 [placeAndUpgrade] Resetting farming state...")
        resetFarmingState()

        -- ดึง units ที่มีอยู่แล้วก่อนสร้าง connection
        print("📋 [placeAndUpgrade] Loading existing units...")
        pcall(function()
            local dependenciesModule = ReplicatedStorage:FindFirstChild("Dependencies")
            if dependenciesModule then
                local Dependencies = require(dependenciesModule)
                local GameUnits = Dependencies.GameUnits
                if GameUnits then
                    local existingCount = 0
                    for unitID, _ in pairs(GameUnits:get()) do
                        if not table.find(allPlacedIDs, unitID) then
                            table.insert(allPlacedIDs, unitID)
                            existingCount = existingCount + 1
                        end
                    end
                    print(string.format("   📊 [placeAndUpgrade] Loaded %d existing units", existingCount))
                end
            end
        end)

        -- สร้าง Connection ใหม่
        print("🔗 [placeAndUpgrade] Creating unit tracker connection...")
        currentConnection = ReplicaClient.OnNew("GameUnit", function(replica)
            local unitID = replica.Data.ID
            if unitID and not table.find(allPlacedIDs, unitID) then
                table.insert(allPlacedIDs, unitID)
                print(string.format("   🆕 [UnitTracker] New unit detected: %s", tostring(unitID)))
            end
        end)

        -- รอให้ connection พร้อม (แก้ race condition)
        print("⏳ [placeAndUpgrade] Waiting for connection to be ready...")
        task.wait(2)

        local function placeUnit(slot, cframe)
            -- Validate slot มี unit หรือไม่
            local cost = getUnitCost(slot)

            if cost == 0 then
                warn(string.format("❌ [PlaceUnit] Slot %s is empty or unavailable - skipping", slot))
                return false
            end

            local startCount = #allPlacedIDs

            -- เพิ่ม random offset 0.5 studs
            local randomX = (math.random() - 0.5) * 0.5
            local randomZ = (math.random() - 0.5) * 0.5
            local adjustedCFrame = cframe * CFrame.new(randomX, 0, randomZ)

            print(string.format("🔄 [PlaceUnit] Attempting to place Slot %s (Cost: %d, Money: %d)", slot, cost, getCurrentMoney()))

            local attempts = 0
            while attempts < 60 do
                local money = getCurrentMoney()

                -- ถ้า cost = 999999 (detect ไม่ได้) → บังคับวางเลย
                local shouldPlace = false
                if cost == 999999 then
                    warn(string.format("⚠️ [PlaceUnit] Cannot detect cost for slot %s - forcing placement", slot))
                    shouldPlace = true
                elseif money >= cost then
                    shouldPlace = true
                end

                if shouldPlace then

                    local success, err = pcall(function()
                        playerReplica:FireServer("PlaceGameUnit", slot, adjustedCFrame)
                    end)

                    if success then
                        task.wait(DELAY_AFTER_PLACE)

                        local waited = 0
                        while #allPlacedIDs <= startCount and waited < 5 do
                            task.wait(0.1)
                            waited = waited + 0.1
                        end

                        if #allPlacedIDs > startCount then
                            local newUnitID = allPlacedIDs[#allPlacedIDs]
                            print(string.format("   ✅ [PlaceUnit] Successfully placed Slot %s (Unit ID: %s)", slot, tostring(newUnitID)))
                            return true
                        else
                            warn(string.format("⚠️ [PlaceUnit] Place retry: Slot=%s, Cost=%d, Money=%d, Attempt=%d/60", slot, cost, money, attempts + 1))
                            attempts = attempts + 1
                            task.wait(1)
                        end
                    else
                        warn(string.format("❌ [PlaceUnit] FireServer failed: Slot=%s, Attempt=%d/60, Error=%s", slot, attempts + 1, tostring(err)))
                        attempts = attempts + 1
                        task.wait(1)
                    end
                else
                    if attempts % 10 == 0 then
                        print(string.format("⏳ [PlaceUnit] Waiting for money: Slot=%s, Need=%d, Have=%d, Attempt=%d/60", slot, cost, money, attempts + 1))
                    end
                    task.wait(1)
                    attempts = attempts + 1
                end
            end

            warn(string.format("❌ [PlaceUnit] Place timeout after 60 attempts: Slot=%s, Cost=%d", slot, cost))
            return false
        end

        print("🔄 [Phase] Starting placement sequence...")

        -- ฟังก์ชันเช็คชื่อ Unit จาก HotbarData (Replica)
        local function getUnitNameFromSlot(slot)
            local success, unitName = pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if not replica or not replica.Data or not replica.Data.HotbarData then
                    return nil
                end

                -- อ่าน fullKey จาก HotbarData
                local fullKey = replica.Data.HotbarData[slot] or replica.Data.HotbarData[tostring(slot)]
                if not fullKey then return nil end

                -- แยก internal name (format: "UnitName#uuid")
                local internalName = fullKey:match("^(.+)#") or fullKey

                -- แปลงเป็น Display Name
                local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)
                local unitInfo = UnitInfo[internalName]

                if unitInfo then
                    return unitInfo.DisplayName or internalName
                end

                return internalName
            end)

            if success and unitName then
                return unitName
            end
            return nil
        end

        -- เช็คว่า unit ที่ equip อยู่เป็นตัวที่วางได้แค่ 3 ตัวหรือไม่
        local PLACEMENT_LIMITED_UNITS = {"Greed", "Scissor", "Water Princess"}
        local equippedUnitName = getUnitNameFromSlot("2")  -- slot 2 คือ unit หลัก
        local isPlacementLimited = false

        if equippedUnitName then
            print(string.format("🔍 [Phase] Equipped unit in slot 2: %s", equippedUnitName))
            for _, limitedUnit in ipairs(PLACEMENT_LIMITED_UNITS) do
                if equippedUnitName == limitedUnit then
                    isPlacementLimited = true
                    print(string.format("⚠️ [Phase] Unit '%s' is placement-limited (max 3 units) - will skip Unit 4", equippedUnitName))
                    break
                end
            end
        else
            warn("⚠️ [Phase] Could not detect equipped unit name - will place all 4 units")
        end

        -- Phase 1-2: วาง 4 ตัว (หรือ 3 ตัวถ้าเป็น limited unit)
        local unit1ID = nil
        local startCount = #allPlacedIDs
        print("📍 [Phase 1] Placing Unit 1...")
        local success1 = placeUnit("2", CFrame.new(3077.4265136719, 1798.7340087891, 3330.8972167969))
        if success1 and #allPlacedIDs > startCount then
            unit1ID = allPlacedIDs[#allPlacedIDs]
            print(string.format("✅ [Phase 1] Unit 1 placed (ID: %s)", tostring(unit1ID)))
        else
            warn("❌ [Phase 1] Failed to place Unit 1 - aborting phase")
            return false
        end

        local upgradeUnits = {}

        startCount = #allPlacedIDs
        print("📍 [Phase 1] Placing Unit 2...")
        local success2 = placeUnit("2", CFrame.new(3092.5168457031, 1798.9315185547, 3367.4926757812))
        if success2 and #allPlacedIDs > startCount then
            table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
            print(string.format("✅ [Phase 1] Unit 2 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
        else
            warn("❌ [Phase 1] Failed to place Unit 2 - aborting phase")
            return false
        end

        startCount = #allPlacedIDs
        print("📍 [Phase 2] Placing Unit 3...")
        local success3 = placeUnit("2", CFrame.new(3092.3759765625, 1798.9315185547, 3370.3395996094))
        if success3 and #allPlacedIDs > startCount then
            table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
            print(string.format("✅ [Phase 2] Unit 3 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
        else
            warn("❌ [Phase 2] Failed to place Unit 3 - aborting phase")
            return false
        end

        -- Phase 2 Unit 4: ข้ามถ้าเป็น placement-limited unit
        if isPlacementLimited then
            print("⏭️ [Phase 2] Skipping Unit 4 (placement-limited unit equipped)")
        else
            startCount = #allPlacedIDs
            print("📍 [Phase 2] Placing Unit 4...")
            local success4 = placeUnit("2", CFrame.new(3092.3918457031, 1798.9315185547, 3373.3002929688))
            if success4 and #allPlacedIDs > startCount then
                table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
                print(string.format("✅ [Phase 2] Unit 4 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
            else
                warn("❌ [Phase 2] Failed to place Unit 4 - aborting phase")
                return false
            end
        end

        -- Phase 3: รอ 30 วิ
        print("⏳ [Phase 3] Waiting 30 seconds...")
        task.wait(30)

        -- Phase 4: ขาย Unit 1 + วาง Unit 5
        print("💰 [Phase 4] Selling Unit 1...")
        if unit1ID then
            local success, err = pcall(function()
                playerReplica:FireServer("SellGameUnit", unit1ID)
            end)
            if success then
                print(string.format("   ✅ [Phase 4] Sold Unit 1 (ID: %s)", tostring(unit1ID)))
            else
                warn(string.format("   ⚠️ [Phase 4] Failed to sell Unit 1 (ID=%s): %s", tostring(unit1ID), tostring(err)))
            end
            task.wait(0.5)
        else
            warn("⚠️ [Phase 4] unit1ID is nil - cannot sell Unit 1")
        end

        startCount = #allPlacedIDs
        print("📍 [Phase 4] Placing Unit 5...")
        local success5 = placeUnit("2", CFrame.new(3095.4975585938, 1798.7340087891, 3365.9299316406))
        if success5 and #allPlacedIDs > startCount then
            table.insert(upgradeUnits, allPlacedIDs[#allPlacedIDs])
            print(string.format("✅ [Phase 4] Unit 5 placed (ID: %s)", tostring(allPlacedIDs[#allPlacedIDs])))
        else
            warn("⚠️ [Phase 4] Failed to place Unit 5 - continuing with existing units...")
        end

        -- Phase 5: รอ 2 วิ
        print("⏳ [Phase 5] Waiting 2 seconds...")
        task.wait(2)

        -- Disconnect connection ใหม่ที่สร้างใน Phase นี้
        if currentConnection then
            currentConnection:Disconnect()
            currentConnection = nil
        end

        -- Phase 6: ตั้ง AutoUpgrade Priority
        print(string.format("🔧 [Phase 6] Setting AutoUpgrade priority for %d units...", #upgradeUnits))
        for i, unitID in ipairs(upgradeUnits) do
            local success, err = pcall(function()
                playerReplica:FireServer("ChangeGameUnitAutoUpgradePriority", unitID, AUTO_UPGRADE_PRIORITY)
            end)
            if success then
                print(string.format("   ✅ [Phase 6] Priority set for unit %d/%d (ID: %s)", i, #upgradeUnits, tostring(unitID)))
            else
                warn(string.format("   ⚠️ [Phase 6] Failed to set priority for unit %s: %s", tostring(unitID), tostring(err)))
            end
            task.wait(0.3)
        end

        print("✅ [Phase] All phases completed successfully")
        return true
    end

    -- Anti-AFK Walk Loop (เดินวนในแมพ)
    spawn(function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        task.wait(5)

        local waypoints = {
            Vector3.new(3089, 0, 3271),
            Vector3.new(3089, 0, 3350)
        }

        local currentWaypointIndex = 1

        while true do
            task.wait(0.1)

            if not isInTargetMap() then
                break
            end

            local character = player.Character
            if not character then
                task.wait(1)
                continue
            end

            local humanoid = character:FindFirstChild("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")

            if not humanoid or not hrp then
                task.wait(1)
                continue
            end

            local targetPos = waypoints[currentWaypointIndex]
            local distance = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude

            if distance > 5 then
                humanoid:MoveTo(Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z))
                task.wait(0.5)
            else
                currentWaypointIndex = currentWaypointIndex + 1
                if currentWaypointIndex > #waypoints then
                    currentWaypointIndex = 1
                end
                task.wait(0.5)
            end
        end
    end)

    -- Auto Claim Quest/Achievement Loop (ทุก 5 นาที)
    spawn(function()
        -- Claim ทันที 1 รอบก่อน
        pcall(function()
            local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
            if replica and replica.Data.QuestData then
                local questData = replica.Data.QuestData
                local claimCount = 0

                for categoryName, _ in pairs(questData) do
                    spawn(function()
                        pcall(function()
                            Nodes.QUEST_CLAIM_ALL_CATEGORY:FireServer(categoryName)
                            claimCount = claimCount + 1
                        end)
                    end)
                    task.wait(0.05)
                end

                task.wait(2)

                local VirtualInputManager = game:GetService("VirtualInputManager")
                for i = 1, 10 do
                    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
                    task.wait(0.1)
                end
            end
        end)

        -- วนลูปทุก 5 นาที
        while true do
            task.wait(300) -- 5 นาที

            pcall(function()
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                if replica and replica.Data.QuestData then
                    local questData = replica.Data.QuestData
                    local claimCount = 0

                    for categoryName, _ in pairs(questData) do
                        spawn(function()
                            pcall(function()
                                Nodes.QUEST_CLAIM_ALL_CATEGORY:FireServer(categoryName)
                                claimCount = claimCount + 1
                            end)
                        end)
                        task.wait(0.05)
                    end

                    task.wait(2)

                    local VirtualInputManager = game:GetService("VirtualInputManager")
                    for i = 1, 10 do
                        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
                        task.wait(0.05)
                        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
                        task.wait(0.1)
                    end
                else
                    warn("⚠️ Quest claim failed: Replica or QuestData not found")
                end
            end)
        end
    end)

    task.wait(5)

        -- ฟังก์ชันขาย Unit ทั้งหมด (เรียกก่อนเริ่ม Phase ใหม่)
        local function sellAllUnits()
            local soldCount = 0
            local failCount = 0

            print("🔄 [Wave Reset] Selling all existing units...")

            -- ดึง playerReplica ใหม่
            local playerReplica = Nodes.GET_GAME_PLAYER_REPLICA:InvokeSelf()
            if not playerReplica then
                warn("❌ [sellAllUnits] Failed to get playerReplica")
                return false
            end

            -- Method 1: ใช้ Dependencies.GameUnits (เร็วกว่า)
            local success1 = pcall(function()
                local dependenciesModule = ReplicatedStorage:FindFirstChild("Dependencies")
                if dependenciesModule then
                    local Dependencies = require(dependenciesModule)
                    local GameUnits = Dependencies.GameUnits
                    if GameUnits then
                        local units = GameUnits:get()
                        for unitID, _ in pairs(units) do
                            local sellSuccess, sellErr = pcall(function()
                                playerReplica:FireServer("SellGameUnit", unitID)
                            end)

                            if sellSuccess then
                                soldCount = soldCount + 1
                                print(string.format("   ✅ Sold unit ID: %s", tostring(unitID)))
                            else
                                failCount = failCount + 1
                                warn(string.format("   ⚠️ Failed to sell unit ID %s: %s", tostring(unitID), tostring(sellErr)))
                            end

                            task.wait(0.2)  -- หน่วงเล็กน้อยระหว่างขาย
                        end
                    end
                end
            end)

            if not success1 then
                warn("⚠️ Method 1 (Dependencies) failed - trying Method 2 (allPlacedIDs)")

                -- Method 2: Fallback ใช้ allPlacedIDs
                if #allPlacedIDs > 0 then
                    for _, unitID in ipairs(allPlacedIDs) do
                        local sellSuccess, sellErr = pcall(function()
                            playerReplica:FireServer("SellGameUnit", unitID)
                        end)

                        if sellSuccess then
                            soldCount = soldCount + 1
                            print(string.format("   ✅ Sold unit ID: %s", tostring(unitID)))
                        else
                            failCount = failCount + 1
                            warn(string.format("   ⚠️ Failed to sell unit ID %s: %s", tostring(unitID), tostring(sellErr)))
                        end

                        task.wait(0.2)
                    end
                end
            end

            print(string.format("✅ [Wave Reset] Sold %d units (Failed: %d)", soldCount, failCount))
            task.wait(1)

            return soldCount > 0 or failCount == 0
        end

        local isRunningPhase = false
        local lastWaveResetTime = 0
        local WAVE_RESET_COOLDOWN = 5  -- ป้องกัน trigger ซ้ำภายใน 5 วินาที

        print("🔄 [In-Game] Starting initial phase...")
        placeAndUpgrade()

        while true do
            task.wait(1)

            if isRunningPhase then
                continue
            end

            local currentWave = getCurrentWave()
            local currentTime = tick()

            if (currentWave == 0 or currentWave == 1) and (currentTime - lastWaveResetTime) >= WAVE_RESET_COOLDOWN then
                print(string.format("🔄 [Wave Reset] Detected at Wave %d - preparing new phase", currentWave))
                isRunningPhase = true
                lastWaveResetTime = currentTime
                task.wait(2)

                -- ขาย Unit เก่าทั้งหมดก่อนเริ่ม Phase ใหม่
                local sellSuccess = sellAllUnits()
                if not sellSuccess then
                    warn("⚠️ [Wave Reset] Sell failed but continuing with new phase")
                end

                -- เช็ค Banner ถ้ามี Summon Config และเงินเกิน 10000
                if hasSummonConfig and #SUMMON_CONFIG > 0 then
                    print("🔍 [Wave Reset] Checking banner for target units...")
                    local bannerCheckSuccess, bannerResult = pcall(function()
                        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                        if replica and replica.Data then
                            local itemData = replica.Data.ItemData
                            local gems = itemData and itemData.Gem and itemData.Gem.Amount or 0

                            print(string.format("   💎 Current Gems: %d", gems))

                            if gems >= 2500 then
                                print("   ✅ Gems >= 2500 - checking banner...")

                                -- เช็คว่าเป็น Secret unit หรือไม่
                                local isSecretUnit = false
                                for _, configUnit in ipairs(SUMMON_CONFIG) do
                                    for _, secretUnit in ipairs(SECRET_UNITS) do
                                        if configUnit == secretUnit then
                                            isSecretUnit = true
                                            print(string.format("   ℹ️ '%s' is a Secret unit - Banner always available", configUnit))
                                            break
                                        end
                                    end
                                    if isSecretUnit then break end
                                end

                                if isSecretUnit then
                                    -- Secret unit: ข้าม Banner check
                                    print(string.format("✅ [Wave Reset] Secret unit + gems >= 2500 → Rejoining..."))
                                    task.wait(1)

                                    pcall(function()
                                        game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer)
                                    end)
                                else
                                    -- Mythic unit: เช็ค Banner ตามปกติ
                                    local bannerUnits = {}
                                    local bannerSuccess = pcall(function()
                                        local startTime = tick()
                                        local timeout = 5

                                        while tick() - startTime < timeout do
                                            local units = checkCurrentBanner()
                                            if #units > 0 then
                                                bannerUnits = units
                                                return
                                            end
                                            task.wait(0.5)
                                        end
                                    end)

                                    if bannerSuccess and #bannerUnits > 0 then
                                        print(string.format("   📋 Banner units found: %s", table.concat(bannerUnits, ", ")))

                                        -- เช็คว่ามีตัวที่ต้องการหรือไม่
                                        local hasMatch = false
                                        local matchedUnit = nil
                                        for _, configUnit in pairs(SUMMON_CONFIG) do
                                            for _, bannerUnit in pairs(bannerUnits) do
                                                if configUnit == bannerUnit then
                                                    hasMatch = true
                                                    matchedUnit = configUnit
                                                    break
                                                end
                                            end
                                            if hasMatch then break end
                                        end

                                        if hasMatch then
                                            print(string.format("✅ [Wave Reset] Target unit '%s' found in banner + gems >= 2500 → Rejoining...", matchedUnit))
                                            task.wait(1)

                                            pcall(function()
                                                game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer)
                                            end)
                                            return  -- หยุดสคริปต์
                                        else
                                            warn("⚠️ [Wave Reset] No target units found in banner - continuing farming")
                                        end
                                    else
                                        warn("⚠️ [Wave Reset] Failed to check banner (timeout or error) - continuing farming")
                                    end
                                end
                            else
                                print(string.format("   ⏭️ Gems < 2500 - skipping banner check"))
                            end
                        else
                            warn("⚠️ [Wave Reset] Failed to get Replica for banner check")
                        end
                    end)

                    if not bannerCheckSuccess then
                        warn(string.format("⚠️ [Wave Reset] Banner check error: %s - continuing farming", tostring(bannerResult)))
                    end
                end

                print("🔄 [Wave Reset] Starting new phase...")
                local success = placeAndUpgrade()
                isRunningPhase = false

                if not success then
                    warn("⚠️ [Wave Reset] Phase failed - will retry on next wave reset")
                else
                    print("✅ [Wave Reset] Phase completed successfully")
                end
            end
        end
    end)

    -- หยุดที่นี่ - ไม่รัน Lobby scripts
    return
end

-- ========================================
-- TOY MAKER TOURNAMENT MODE
-- ========================================
if isInToyMakerTournament() then
    print("🏆 Detected Toy Maker Tournament - Starting 3 minute countdown...")

    -- ปิด Tutorial popup (ถ้ามี)
    local function closeTutorial()
        local success = pcall(function()
            local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
            local prompt = playerGui:FindFirstChild("Prompt")
            if not prompt then return end

            local tutorialLabel = prompt.Frame.Frame.Folder.Frame.Frame.Frame.TextLabel
            if tutorialLabel then
                local text = tutorialLabel.ContentText or tutorialLabel.Text
                if text == "Tutorial" then
                    local closeButton = prompt.Frame.Frame.Folder.Frame:FindFirstChild("PrimaryButton")
                    if closeButton then
                        local GuiService = game:GetService("GuiService")
                        local VirtualInputManager = game:GetService("VirtualInputManager")

                        GuiService.SelectedCoreObject = nil
                        task.wait(0.1)

                        closeButton.Selectable = true
                        GuiService.SelectedCoreObject = closeButton
                        task.wait(0.1)

                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                        task.wait(0.2)
                        GuiService.SelectedCoreObject = nil

                        print("✅ Tutorial closed")
                        return
                    end
                end
            end
        end)
        if not success then
            print("⚠️ Tutorial popup not found or already closed")
        end
    end

    closeTutorial()
    task.wait(0.5)

    local countdown = 160  -- 2:40 นาที
    while countdown > 0 do
        if countdown % 20 == 0 then  -- print ทุก 30 วิ
            print(string.format("⏱️ Time remaining: %d seconds", countdown))
        end
        task.wait(1)
        countdown = countdown - 1
    end

    print("✅ 2:40 minutes completed - Rejoining...")
    task.wait(1)

    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
    end)
    return
end

-- ========================================
-- LOBBY SCRIPTS (รันเฉพาะตอนไม่ได้อยู่ในแมพ)
-- ========================================

-- ========================================
-- 1. RemoveLobbyMesh.lua (Boost FPS)
-- ========================================
printStep("Removing Lobby Mesh...")

-- ใช้ฟังก์ชัน Performance Optimization
applyPerformanceOptimizations()

task.wait(1)

-- ========================================
-- 2. Settings.lua
-- ========================================
printStep("Applying Settings...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Nodes = require(ReplicatedStorage:WaitForChild("Nodes"))

local settings = {
    AutoSkipWaves = true,
    AutoVoteStart = true,
    AutoRetry = true,
    LowDetailMode = true,
    FastSummon = true,
    SummonMax = true,
    DisplayPinnedQuests = false,
    PathVisualizerEnabled = false,
    CameraShakeEnabled = false,
    OtherUnitsEnabled = false,
    OtherUnitVFXEnabled = false,
    OwnUnitVFXEnabled = false,
    AbilityVFXEnabled = false,
    UnitAuraEnabled = false,
    TraitAuraEnabled = false,
    BuffIndicatorsEnabled = false,
    DisplayUnitCircles = false,
    DisplayHealthBars = false,
    DisplayEnemyTags = false,
    DisplayEnemyStatusEffects = false,
    DisplayEnemyEffects = false,
    OtherCosmeticEnabled = false,
    OtherEmoteSFXEnabled = false,
    GlobalMessagesEnabled = false,
    DisplayUpdateLog = false,
    DamageIndicatorsEnabled = false,
    AutoPlacePhantoms = false,
    StrictPhantomPlacement = false
}

for settingName, value in pairs(settings) do
    task.spawn(function()
        pcall(function()
            Nodes.CLIENT_CHANGE_SETTING:FireServer(settingName, value)
        end)
    end)
    task.wait(0.5)
end

-- AutoSell Settings
task.wait(1)
local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
local Actions = require(FusionPackage.Actions)

-- เริ่มต้น: ขาย Rare + Epic เท่านั้น (ไม่ขาย Legendary)
for _, rarity in ipairs({"Rare", "Epic"}) do
    pcall(function()
        Actions.ToggleAutoSell("Standard", rarity, false, true)
    end)
    task.wait(0.3)
end

-- เปิดขาย Shiny units ทุก Rarity (Rare, Epic)
print("🔧 Enabling Shiny AutoSell...")
for _, rarity in ipairs({"Rare", "Epic"}) do
    pcall(function()
        -- Parameter 3 = true หมายถึง Shiny
        Actions.ToggleAutoSell("Standard", rarity, true, true)
    end)
    task.wait(0.3)
end

print("✅ AutoSell enabled: Rare, Epic (including Shiny)")
print("ℹ️ Legendary AutoSell will be enabled after obtaining Legendary units")

task.wait(1)

-- ========================================
-- 2.5. Trait Filter Setup
-- ========================================
printStep("Setting Trait Filters...")

do
    local TRAIT_CONFIG = {
        TargetTraits = {"Unbound", "Primordial", "Forsaken", "Draconic", "Investor"},
        ClearBeforeSet = false,
        FilterMode = false,
    }

    -- ล้าง filters (ถ้าต้องการ)
    if TRAIT_CONFIG.ClearBeforeSet then
        pcall(function() Nodes.CLIENT_CLEAR_TRAIT_FILTERS:Request() end)
        task.wait(0.3)
    end

    -- ตั้ง filters
    local success, fail = 0, 0
    for _, trait in ipairs(TRAIT_CONFIG.TargetTraits) do
        if pcall(function() Nodes.CLIENT_TOGGLE_TRAIT_FILTER:Request(trait, TRAIT_CONFIG.FilterMode) end) then
            success = success + 1
        else
            fail = fail + 1
        end
        task.wait(0.1)
    end

    -- แจ้งผลลัพธ์
    if fail == 0 then
        print(string.format("✅ Trait Filters: %d traits %s", success, TRAIT_CONFIG.FilterMode and "enabled" or "disabled"))
    else
        warn(string.format("⚠️ Trait Filters: %d success, %d failed", success, fail))
    end
end

task.wait(1)

-- ========================================
-- 3. AutoClaimStarter.lua
-- ========================================
printStep("Claiming Starter Unit...")

local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")

local TARGET_UNIT = "Carrot"

-- รอให้ Prompt โหลด
task.wait(2)

local playerGui = Players.LocalPlayer.PlayerGui
if playerGui:FindFirstChild("Prompt") then
    local success, folder = pcall(function()
        return playerGui.Prompt.Frame.Frame.Frame.Folder.Frame.Frame
    end)

    if not success or not folder then
        warn("⚠️ Starter Unit popup not found or already claimed - skipping")
        task.wait(2)
        return
    end

    -- หาปุ่มที่มีชื่อ Carrot
    for _, child in pairs(folder:GetChildren()) do
        if child:FindFirstChild("Folder") then
            local textLabel = child.Folder.Frame.Frame:FindFirstChild("TextLabel")
            if textLabel and (textLabel.ContentText == TARGET_UNIT or textLabel.Text == TARGET_UNIT) then
                -- กดปุ่มเลือกตัวละคร
                local button = child.Folder.Frame:FindFirstChild("TextButton")
                if button then
                    GuiService.SelectedCoreObject = nil
                    task.wait(0.1)

                    button.Selectable = true
                    GuiService.SelectedCoreObject = button
                    task.wait(0.1)

                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                    task.wait(0.2)
                    GuiService.SelectedCoreObject = nil

                    task.wait(0.5)

                    -- กดปุ่มยืนยัน
                    local confirmButton = playerGui.Prompt.Frame.Frame.Frame.Frame:FindFirstChild("PrimaryButton")
                    if confirmButton then
                        GuiService.SelectedCoreObject = nil
                        task.wait(0.1)

                        confirmButton.Selectable = true
                        GuiService.SelectedCoreObject = confirmButton
                        task.wait(0.1)

                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)

                        task.wait(0.2)
                        GuiService.SelectedCoreObject = nil

                        task.wait(0.5)

                        -- spam คลิกมุมซ้ายบน 5 รอบ
                        for i = 1, 5 do
                            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
                            task.wait(0.05)
                            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
                            task.wait(0.1)
                        end

                    end
                end
                break
            end
        end
    end
else
end

task.wait(1)

-- ========================================
-- 4. AutoClaimCalendar.lua
-- ========================================
printStep("Claiming Calendar Rewards...")

local START_DAY = 1
local END_DAY = 7

-- Claim ReleaseCalendar ทั้งหมดพร้อมกัน
for day = START_DAY, END_DAY do
    spawn(function()
        pcall(function()
            Nodes.CLAIM_CALENDAR:FireServer("ReleaseCalendar", day)
        end)
    end)
    task.wait(0.05)  -- หน่วงเล็กน้อย
end

task.wait(2)  -- รอให้ claim เสร็จ

-- Claim DailyRewards ทั้งหมดพร้อมกัน
for day = START_DAY, END_DAY do
    spawn(function()
        pcall(function()
            Nodes.CLAIM_CALENDAR:FireServer("DailyRewards", day)
        end)
    end)
    task.wait(0.05)  -- หน่วงเล็กน้อย
end

task.wait(2)  -- รอให้ claim เสร็จ

print("   ✅ Calendar rewards claimed!")

-- ปิด popup รวม
local VirtualInputManager = game:GetService("VirtualInputManager")
for i = 1, 10 do
    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
    task.wait(0.1)
end

task.wait(1)

-- ========================================
-- 4.5. Redeem Codes
-- ========================================
printStep("Redeeming Codes...")

do
    local CODES = {
        "HAPPYBDAYCOOP",
        "1MGROUP!",
        "100mvisits",
        "100K!",
        "30KLIKES!",
        "EXPEDITIONS",
        "AE#1",
        "wfade",
        "RELEASE",
    }

    local successCount = 0
    local failCount = 0

    -- Redeem ทุกโค้ดพร้อมกัน
    for i, code in ipairs(CODES) do
        spawn(function()
            local success, result = pcall(function()
                local request = Nodes.CLAIM_CODE:Request(code)
                request:Timeout(5)
                return request:Wait()
            end)

            if success and result and result.Success then
                successCount = successCount + 1
            else
                failCount = failCount + 1
            end
        end)
        task.wait(0.05)  -- หน่วงเล็กน้อย
    end

    -- รอให้ redeem เสร็จ
    task.wait(6)


    -- ปิด popup (ถ้ามี)
    local VirtualInputManager = game:GetService("VirtualInputManager")
    for i = 1, 10 do
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
        task.wait(0.1)
    end
end

task.wait(1)

-- ========================================
-- 4.6. Claim All Quests, Achievements & BattlePass
-- ========================================
printStep("Claiming All Quests, Achievements & BattlePass...")

do
    -- ดึง QuestData
    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
    if not replica or not replica.Data.QuestData then
        warn("   ⚠️ QuestData not found!")
    else
        local questData = replica.Data.QuestData
        local categories = {}

        -- เก็บ categories ทั้งหมด
        for categoryName, _ in pairs(questData) do
            table.insert(categories, categoryName)
        end


        -- Claim แต่ละ category พร้อมกัน
        local claimedCount = 0
        for _, categoryName in ipairs(categories) do
            spawn(function()
                pcall(function()
                    Nodes.QUEST_CLAIM_ALL_CATEGORY:FireServer(categoryName)
                    claimedCount = claimedCount + 1
                end)
            end)
            task.wait(0.05)
        end

        task.wait(2)
    end

    task.wait(1)

    -- Claim BattlePass
    local ReplicaClient = require(ReplicatedStorage.Shared.ReplicaClient)
    local battlepassClaimed = 0

    ReplicaClient.OnNew("BattlepassData", function(replica)
        if replica.Data and replica.Data.DataKey then
            local battlepassId = replica.Data.DataKey
            pcall(function()
                Nodes.CLAIM_ALL_BATTLEPASS_REWARDS:FireServer(battlepassId)
                battlepassClaimed = battlepassClaimed + 1
            end)
        end
    end)

    task.wait(2)

    if battlepassClaimed == 0 then
    end

    -- ปิด popup ที่อาจจะขึ้นมา
    local VirtualInputManager = game:GetService("VirtualInputManager")
    for i = 1, 20 do
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
        task.wait(0.1)
    end
end
task.wait(1)

-- ========================================
-- 5. เช็คตัวละครที่มีอยู่ + Summon System (Mythic/Secret)
-- ========================================

-- ========================================
-- 5.0. TOY MAKER CHECK (ก่อน Summon)
-- ========================================
if GET_TOY_MAKER then
    printStep("Checking for Toy Maker...")

    local function checkToyMaker()
        local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
        if not unitData then return nil, "None" end

        local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)

        for fullKey, data in pairs(unitData) do
            local internalName = fullKey:match("^(.+)#") or fullKey
            local unitInfo = UnitInfo[internalName]
            if unitInfo and unitInfo.DisplayName == "Toy Maker" then
                local currentTrait = data.Trait or "None"
                return fullKey, currentTrait
            end
        end
        return nil, "None"
    end

    local toyMakerKey, currentTrait = checkToyMaker()

    if toyMakerKey then
        -- มี Toy Maker แล้ว - เช็ค Trait
        print(string.format("✅ Found Toy Maker with Trait: %s", currentTrait))

        -- เช็คว่า Trait ตรงกับที่ต้องการหรือไม่
        local hasTargetTrait = false
        if type(TARGET_TRAIT_TOY_MAKER) == "table" then
            for _, targetTrait in ipairs(TARGET_TRAIT_TOY_MAKER) do
                if currentTrait == targetTrait then
                    hasTargetTrait = true
                    break
                end
            end
        elseif type(TARGET_TRAIT_TOY_MAKER) == "string" then
            hasTargetTrait = (currentTrait == TARGET_TRAIT_TOY_MAKER)
        end

        if hasTargetTrait then
            -- Trait ตรงแล้ว - ส่ง DONE
            print(string.format("✅ Toy Maker has target trait: %s", currentTrait))

            if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                local currentGems = replica and replica.Data.ItemData.Gem.Amount or 0
                local currentRR = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0

                _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ✅ %s", currentGems, currentRR, currentTrait))

                _G.ScriptShouldStop = true  -- ตั้งค่า flag ก่อนรอ

                task.wait(5)  -- รอ 5 วิก่อนส่ง DONE

                if GEM_TARGET then
                    if currentGems >= GEM_TARGET then
                        _G.Horst_AccountChangeDone()
                        print("✅ GEM_TARGET reached - Script will stop...")

                        -- Loop ส่ง Description ทันทีและทุก 5 วิหลัง DONE
                        while true do
                            pcall(function()
                                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ✅ %s", gems, rr, currentTrait))
                            end)
                            task.wait(5)
                        end
                    end
                else
                    _G.Horst_AccountChangeDone()
                    print("✅ Toy Maker has target trait - Script will stop...")

                    -- Loop ส่ง Description ทันทีและทุก 5 วิหลัง DONE
                    while true do
                        pcall(function()
                            local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                            local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                            local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                            _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ✅ %s", gems, rr, currentTrait))
                        end)
                        task.wait(5)
                    end
                end
            end
            return  -- หยุดสคริปต์
        else
            -- Trait ไม่ตรง - ต้องสุ่ม
            print(string.format("⚠️ Toy Maker trait '%s' is not target - attempting reroll...", currentTrait))

            -- ดึง Trait Reroll Count (ใช้วิธีเดียวกับ Trait Reroll System)
            local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
            local traitRerolls = 0
            if replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.TraitReroll then
                traitRerolls = replica.Data.ItemData.TraitReroll.Amount or 0
            end

            print(string.format("📊 Trait Rerolls available: %d", traitRerolls))

            if traitRerolls == 0 then
                -- หมด Reroll แล้ว - ส่ง DONE พร้อมสถานะ
                print(string.format("❌ Out of Trait Rerolls - Final Trait: %s", currentTrait))

                if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                    local currentGems = replica and replica.Data.ItemData.Gem.Amount or 0
                    local currentRR = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0

                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ❌ %s (Out of RR)", currentGems, currentRR, currentTrait))

                    _G.ScriptShouldStop = true  -- ตั้งค่า flag ก่อนรอ

                    task.wait(5)  -- รอ 5 วิก่อนส่ง DONE

                    if GEM_TARGET then
                        if currentGems >= GEM_TARGET then
                            _G.Horst_AccountChangeDone()
                            print("✅ GEM_TARGET reached - Script will stop...")

                            -- Loop ส่ง Description ทันทีและทุก 5 วิหลัง DONE
                            while true do
                                pcall(function()
                                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                    local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ❌ %s (Out of RR)", gems, rr, currentTrait))
                                end)
                                task.wait(5)
                            end
                        end
                    else
                        _G.Horst_AccountChangeDone()
                        print("✅ Toy Maker out of RR - Script will stop...")

                        -- Loop ส่ง Description ทันทีและทุก 5 วิหลัง DONE
                        while true do
                            pcall(function()
                                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ❌ %s (Out of RR)", gems, rr, currentTrait))
                            end)
                            task.wait(5)
                        end
                    end
                end
                return  -- หยุดสคริปต์
            end

            -- มี Reroll - เริ่มสุ่ม Trait
            print(string.format("🎲 Starting Trait Reroll for Toy Maker... (%d rerolls available)", traitRerolls))

            local rerollCount = 0
            local maxRerolls = traitRerolls

            while rerollCount < maxRerolls do
                -- สุ่ม Trait
                pcall(function()
                    Nodes.ROLL_UNIT_TRAIT:FireServer(toyMakerKey, currentTrait)
                end)
                task.wait(0.5)

                rerollCount = rerollCount + 1

                -- เช็ค Trait ใหม่
                local _, newTrait = checkToyMaker()
                currentTrait = newTrait

                -- เช็คว่าได้ Trait ที่ต้องการหรือไม่
                local gotTarget = false
                if type(TARGET_TRAIT_TOY_MAKER) == "table" then
                    for _, targetTrait in ipairs(TARGET_TRAIT_TOY_MAKER) do
                        if currentTrait == targetTrait then
                            gotTarget = true
                            break
                        end
                    end
                elseif type(TARGET_TRAIT_TOY_MAKER) == "string" then
                    gotTarget = (currentTrait == TARGET_TRAIT_TOY_MAKER)
                end

                if gotTarget then
                    print(string.format("✅ Toy Maker | Trait: %s | Used: %d | Left: %d", currentTrait, rerollCount, maxRerolls - rerollCount))

                    if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                        local currentGems = replica and replica.Data.ItemData.Gem.Amount or 0
                        local currentRR = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0

                        _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ✅ %s", currentGems, currentRR, currentTrait))

                        _G.ScriptShouldStop = true  -- ตั้งค่า flag ก่อนรอ เพื่อหยุด Stats GUI Loop

                        task.wait(5)  -- รอ 5 วิก่อนส่ง DONE

                        if GEM_TARGET then
                            if currentGems >= GEM_TARGET then
                                _G.Horst_AccountChangeDone()
                                print("✅ GEM_TARGET reached - Script will stop...")

                                -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                                while true do
                                    task.wait(5)
                                    pcall(function()
                                        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                        local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                        local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                        _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ✅ %s", gems, rr, currentTrait))
                                    end)
                                end
                            end
                        else
                            _G.Horst_AccountChangeDone()
                            print("✅ Toy Maker trait reroll succeeded - Script will stop...")

                            -- Loop ส่ง Description ทันทีและทุก 5 วิหลัง DONE
                            while true do
                                pcall(function()
                                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                    local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ✅ %s", gems, rr, currentTrait))
                                end)
                                task.wait(5)
                            end
                        end
                    end
                    return  -- หยุดสคริปต์
                end

                task.wait(0.1)
            end

            -- ใช้ Reroll หมดแล้ว
            print(string.format("⚠️ Toy Maker | Final Trait: %s | Used: %d (all rerolls)", currentTrait, rerollCount))

            if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                local currentGems = replica and replica.Data.ItemData.Gem.Amount or 0
                local currentRR = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0

                _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ❌ %s (Out of RR)", currentGems, currentRR, currentTrait))

                _G.ScriptShouldStop = true  -- ตั้งค่า flag ก่อนรอ

                task.wait(5)  -- รอ 5 วิก่อนส่ง DONE

                if GEM_TARGET then
                    if currentGems >= GEM_TARGET then
                        _G.Horst_AccountChangeDone()
                        print("✅ GEM_TARGET reached - Script will stop...")

                        -- Loop ส่ง Description ทันทีและทุก 5 วิหลัง DONE
                        while true do
                            pcall(function()
                                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ❌ %s (Out of RR)", gems, rr, currentTrait))
                            end)
                            task.wait(5)
                        end
                    end
                else
                    _G.Horst_AccountChangeDone()
                    print("✅ Toy Maker all rerolls used - Script will stop...")

                    -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                    while true do
                        task.wait(5)
                        pcall(function()
                            local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                            local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                            local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                            _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • Toy Maker • Trait: ❌ %s (Out of RR)", gems, rr, currentTrait))
                        end)
                    end
                end
            end
            return  -- หยุดสคริปต์
        end
    else
        -- ไม่มี Toy Maker - ไป Tournament
        print("❌ Toy Maker not found - Starting Tournament...")

        task.wait(1)

        -- เริ่ม Tournament
        local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
        local Actions = require(FusionPackage:WaitForChild("Actions"))

        local config = {
            MapName = "SchoolGrounds",
            ActName = "competitive",
            Difficulty = "Hard",
            Gamemode = "Tournament",
            TournamentId = "Release",
            MaxPlayers = 1
        }

        print("🏆 Starting Tournament...")
        Actions.PartyStartGame(config)

        task.wait(5)
        return  -- หยุดสคริปต์ - รอให้เข้าแมพ
    end
end

printStep("Checking Inventory...")

-- ลบฟังก์ชัน openInventory และ closeInventory เพราะไม่จำเป็นแล้ว
-- ใช้ Nodes.GET_DATA_VALUE:InvokeSelf("UnitData") โดยตรง

-- ฟังก์ชันเช็คว่ามี units ใน Inventory (พร้อม Trait)
local function checkInventoryForUnits(targetUnits, returnWithTrait)
    local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
    if not unitData then return {} end

    -- ถ้า targetUnits เป็น string ให้แปลงเป็น table
    if type(targetUnits) == "string" then
        targetUnits = {targetUnits}
    end

    local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)
    local foundUnits = {}

    for fullKey, data in pairs(unitData) do
        local internalName = fullKey:match("^(.+)#") or fullKey
        local unitInfo = UnitInfo[internalName]
        if unitInfo then
            local displayName = unitInfo.DisplayName or internalName
            for _, targetUnit in ipairs(targetUnits) do
                if displayName == targetUnit then
                    if returnWithTrait then
                        -- return พร้อม Trait และ Shiny
                        table.insert(foundUnits, {
                            name = displayName,
                            trait = data.Trait or "None",
                            fullKey = fullKey,
                            unitID = data.ID,
                            isShiny = data.Shiny or false
                        })
                    else
                        -- return แค่ชื่อ
                        table.insert(foundUnits, displayName)
                    end
                    break
                end
            end
        end
    end
    return foundUnits
end

-- ฟังก์ชันเลือกตัวที่จะสุ่ม Trait (Priority: None > Worst Trait)
local function selectBestUnitForReroll(units)
    if #units == 0 then return nil end
    if #units == 1 then return units[1] end

    -- Trait Priority (จากกากสุด → ดีสุด)
    local TRAIT_PRIORITY = {
        "Strength 1",    -- 1 (กากสุด)
        "Speed 1",       -- 2
        "Range 1",       -- 3
        "Enlightenment", -- 4
        "Strength 2",    -- 5
        "Speed 2",       -- 6
        "Range 2",       -- 7
        "Limit Breaker", -- 8
        "Precision 1",   -- 9
        "Precision 2",   -- 10
        "Bolt",          -- 11
        "Optics",        -- 12
        "Investor",      -- 13
        "Draconic",      -- 14
        "Forsaken",      -- 15
        "Primordial",    -- 16
        "Unbound"        -- 17 (ดีสุด)
    }

    -- สร้าง Trait → Priority Map
    local traitPriorityMap = {}
    for priority, traitName in ipairs(TRAIT_PRIORITY) do
        traitPriorityMap[traitName] = priority
    end

    -- แยก Shiny และ Non-Shiny
    local shinyUnits = {}
    local normalUnits = {}

    for _, unit in ipairs(units) do
        if unit.isShiny then
            table.insert(shinyUnits, unit)
        else
            table.insert(normalUnits, unit)
        end
    end

    -- ฟังก์ชันเลือกตัวที่ดีที่สุดจาก list
    local function selectFromList(list)
        if #list == 0 then return nil end
        if #list == 1 then return list[1] end

        -- แยกตัวที่ Trait = None
        local noneUnits = {}
        local withTraitUnits = {}

        for _, unit in ipairs(list) do
            if unit.trait == "None" then
                table.insert(noneUnits, unit)
            else
                table.insert(withTraitUnits, unit)
            end
        end

        -- ถ้ามีตัวที่ Trait = None → เลือกตัวแรก
        if #noneUnits > 0 then
            return noneUnits[1]
        end

        -- ถ้าไม่มี None → เลือกตัวที่ Trait กากสุด (priority ต่ำสุด)
        if #withTraitUnits > 0 then
            table.sort(withTraitUnits, function(a, b)
                local priorityA = traitPriorityMap[a.trait] or 999
                local priorityB = traitPriorityMap[b.trait] or 999
                return priorityA < priorityB  -- priority ต่ำกว่า = กากกว่า
            end)
            return withTraitUnits[1]
        end

        return list[1]
    end  -- ปิด selectFromList function

    -- เลือก Shiny ก่อน (ถ้ามี)
    if #shinyUnits > 0 then
        local selected = selectFromList(shinyUnits)
        if selected then return selected end
    end

    -- ถ้าไม่มี Shiny หรือเลือกไม่ได้ → เลือกตัวธรรมดา
    if #normalUnits > 0 then
        local selected = selectFromList(normalUnits)
        if selected then return selected end
    end

    -- Fallback (ไม่น่าเกิด)
    return units[1]
end  -- ปิด selectBestUnitForReroll function

-- ฟังก์ชันส่ง Horst Description
local function sendSummonStatus(foundUnits, isComplete)
    if not HORST_ENABLED or not _G.Horst_SetDescription then return end

    local secretUnits = {}
    local mythicUnits = {}
    local otherUnits = {}

    -- เก็บรายชื่อ units ที่ต้องการ (ถ้ามี config)
    local configUnitSet = {}
    if hasSummonConfig then
        for _, unit in ipairs(SUMMON_CONFIG) do
            configUnitSet[unit] = true
        end
    end

    for _, unit in ipairs(foundUnits) do
        local isSecret = false
        for _, secret in ipairs(SECRET_UNITS) do
            if unit == secret then
                table.insert(secretUnits, unit)
                isSecret = true
                break
            end
        end
        if not isSecret then
            for _, mythic in ipairs(MYTHIC_UNITS) do
                if unit == mythic then
                    -- ถ้ามี Config และตัวนี้ไม่ได้อยู่ใน Config → ใส่ Other
                    if hasSummonConfig and not configUnitSet[unit] then
                        table.insert(otherUnits, unit)
                    else
                        table.insert(mythicUnits, unit)
                    end
                    break
                end
            end
        end
    end

    local descParts = {}
    if #secretUnits > 0 then
        table.insert(descParts, "Secret: " .. table.concat(secretUnits, ", "))
    end
    if #mythicUnits > 0 then
        table.insert(descParts, "Mythic: " .. table.concat(mythicUnits, ", "))
    end
    if #otherUnits > 0 then
        table.insert(descParts, "Other: " .. table.concat(otherUnits, ", "))
    end

    if #descParts > 0 then
        local message = table.concat(descParts, " • ")
        pcall(function()
            _G.Horst_SetDescription(message, "")
        end)

        if isComplete and _G.Horst_AccountChangeDone then
            _G.ScriptShouldStop = true  -- ตั้งค่า flag ก่อนรอ

            task.wait(5)  -- รอ 5 วิก่อนส่ง DONE

            pcall(_G.Horst_AccountChangeDone)
            print("✅ Summon completed - Script will stop...")
        end
    end
end

-- เช็ค Summon Config
local shouldSummon = false
local hasTargetUnit = false
local autoSummonMode = false  -- ใหม่: โหมด auto summon

if hasSummonConfig then
    -- เช็คว่าเป็น "auto" mode หรือไม่
    if type(_G.Config.SummonUnits) == "string" and _G.Config.SummonUnits:lower() == "auto" then
        autoSummonMode = true
        -- Override SUMMON_CONFIG เป็น Mythic + Secret ทั้งหมด
        local allTargets = {}
        for _, unit in ipairs(SECRET_UNITS) do
            table.insert(allTargets, unit)
        end
        for _, unit in ipairs(MYTHIC_UNITS) do
            table.insert(allTargets, unit)
        end
        SUMMON_CONFIG = allTargets
    end

    -- เช็ค Level และ Gems
    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
    local level = replica and replica.Data and replica.Data.Level or 0
    local gems = replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.Gem and replica.Data.ItemData.Gem.Amount or 0

    -- 1. เช็ค Inventory ก่อนเสมอ (ไม่ว่า Gems จะพอหรือไม่)
    local foundInInventory = checkInventoryForUnits(SUMMON_CONFIG)

    if autoSummonMode then
        -- โหมด auto: ได้ตัวใดตัวหนึ่งก็พอ
        if #foundInInventory > 0 then
            sendSummonStatus(foundInInventory, true)
            hasTargetUnit = true
            print("✅ Found target unit in inventory - skipping summon")
        end
    else
        -- โหมดปกติ: ต้องได้ครบทุกตัว
        if #foundInInventory >= #SUMMON_CONFIG then
            sendSummonStatus(foundInInventory, true)
            hasTargetUnit = true
            print("✅ Found all target units in inventory - skipping summon")
        end
    end

    -- 2. ถ้ายังไม่มีตัว → พิจารณาว่าจะสุ่มหรือไม่
    if not hasTargetUnit then
        if level >= 10 and gems >= 2500 then
            -- มี Level และ Gems พอ → ไปสุ่ม
            -- เช็คว่าเป็น Secret unit หรือไม่
            local isSecretUnit = false
            for _, configUnit in ipairs(SUMMON_CONFIG) do
                for _, secretUnit in ipairs(SECRET_UNITS) do
                    if configUnit == secretUnit then
                        isSecretUnit = true
                        print(string.format("ℹ️ '%s' is a Secret unit - Banner always available", configUnit))
                        break
                    end
                end
                if isSecretUnit then break end
            end

            if isSecretUnit then
                -- Secret unit: ข้าม Banner check (มีเสมอ)
                shouldSummon = true

                if autoSummonMode then
                    -- ตั้ง AutoSell Legendary
                    local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
                    local Actions = require(FusionPackage.Actions)
                    pcall(function()
                        Actions.ToggleAutoSell("Standard", "Legendary", false, true)
                    end)
                end
            else
                -- Mythic unit: เช็ค Banner ตามปกติ
                local bannerUnits = checkCurrentBanner()

                local hasMatch = false
                for _, configUnit in pairs(SUMMON_CONFIG) do
                    for _, bannerUnit in pairs(bannerUnits) do
                        if configUnit == bannerUnit then
                            hasMatch = true
                            break
                        end
                    end
                    if hasMatch then break end
                end

                if hasMatch then
                    shouldSummon = true

                    if autoSummonMode then
                        -- ตั้ง AutoSell Legendary
                        local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
                        local Actions = require(FusionPackage.Actions)
                        pcall(function()
                            Actions.ToggleAutoSell("Standard", "Legendary", false, true)
                        end)
                    end
                else
                    if #foundInInventory > 0 then
                        sendSummonStatus(foundInInventory, false)
                    end
                end
            end
        else
            -- ไม่มีตัว + Gems ไม่พอ → เช็คว่ามี Mythic Fallback หรือไม่
            warn(string.format("⚠️ Target unit not found in inventory. Need to farm more gems. Level=%d, Gems=%d (require Level>=10 and Gems>=2500)", level, gems))

            -- เช็คว่า Config เป็น Secret unit หรือไม่
            local isSecretSummon = false
            for _, configUnit in ipairs(SUMMON_CONFIG) do
                for _, secretUnit in ipairs(SECRET_UNITS) do
                    if configUnit == secretUnit then
                        isSecretSummon = true
                        break
                    end
                end
                if isSecretSummon then break end
            end

            -- ถ้าเป็น Secret + Change_Acc_Secrets = true → Fallback ไป Mythic
            if isSecretSummon and CHANGE_ACC_SECRETS then
                print("ℹ️ Secret unit not found - checking for Mythic fallback...")

                -- เช็คว่ามี Mythic ใน Inventory หรือไม่
                local mythicFallback = checkInventoryForUnits(MYTHIC_UNITS)

                if #mythicFallback > 0 then
                    print(string.format("✅ Found Mythic fallback: %s", table.concat(mythicFallback, ", ")))
                    sendSummonStatus(mythicFallback, false)
                    hasTargetUnit = true
                    -- ไม่ตั้ง shouldSummon = true (ไม่ไปสุ่ม) แต่มี hasTargetUnit = true (ไป Trait Reroll)
                else
                    print("⚠️ No Mythic fallback found - will proceed to farming")
                    -- ไม่ตั้ง shouldSummon = true (จะข้ามไป Legendary Summon Loop และเข้าเกมฟาร์ม)
                end
            else
                print("ℹ️ Script will proceed to farming to collect gems...")
                -- ไม่ตั้ง shouldSummon = true (จะข้ามไป Legendary Summon Loop และเข้าเกมฟาร์ม)
            end
        end
    end
end

-- เช็คตัว Legendary (ถ้าไม่มี Summon Config หรือข้ามมาแล้ว)
-- แต่ไม่ override hasTargetUnit ถ้ามีค่าอยู่แล้ว (เช่น จาก Mythic Fallback)
if not shouldSummon and not hasTargetUnit then

    local function checkForTargetUnits()
        local targetUnits = {
            "The Hero",
            "Scissor",
            "Ice Queen",
            "Water Princess",
            "Forbidden Teacher",
            "Greed"
        }

        -- เช็คผ่าน UnitData โดยตรงแทนการอ่าน GUI
        local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
        if not unitData then
            return false
        end

        local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)

        -- เก็บชื่อที่เจอเพื่อ debug
        local foundUnits = {}
        local targetFound = false

        for fullKey, data in pairs(unitData) do
            local internalName = fullKey:match("^(.+)#") or fullKey
            local unitInfo = UnitInfo[internalName]

            if unitInfo then
                local displayName = unitInfo.DisplayName or internalName

                -- เก็บเพื่อ debug
                if not foundUnits[displayName] then
                    foundUnits[displayName] = true
                end

                -- เช็คว่าตรงกับ target unit หรือไม่
                for _, targetUnit in pairs(targetUnits) do
                    if displayName == targetUnit then
                        targetFound = true
                        break
                    end
                end

                if targetFound then
                    break
                end
            end
        end

        if not targetFound then
            -- แสดงตัวที่เจอทั้งหมด (เพื่อ debug)
            local count = 0
            for unitName, _ in pairs(foundUnits) do
                count = count + 1
                if count >= 10 then
                    break
                end
            end
        end

        return targetFound
    end

    -- เช็คตัวละครโดยตรง (ไม่ต้องเปิด Inventory)
    hasTargetUnit = checkForTargetUnits()
end

-- ========================================
-- 6. AutoSummon (สำหรับ Summon Config หรือ Legendary)
-- ========================================
if shouldSummon then
    printStep("Auto Summon (Mythic/Secret)...")

    -- ========================================
    -- 6.1 เช็คและตั้งค่า AutoSell Legendary ก่อนสุ่ม
    -- ========================================
    print("🔍 Checking for Legendary units before summon...")

    local LEGENDARY_UNITS = {
        "The Hero",
        "Scissor",
        "Ice Queen",
        "Water Princess",
        "Forbidden Teacher",
        "Greed"
    }

    local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
    local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)
    local hasLegendary = false

    if unitData then
        for fullKey, data in pairs(unitData) do
            local internalName = fullKey:match("^(.+)#") or fullKey
            local unitInfo = UnitInfo[internalName]

            if unitInfo then
                local displayName = unitInfo.DisplayName or internalName

                for _, legendaryUnit in ipairs(LEGENDARY_UNITS) do
                    if displayName == legendaryUnit then
                        hasLegendary = true
                        print(string.format("   ✅ Found Legendary: %s", displayName))
                        break
                    end
                end

                if hasLegendary then break end
            end
        end
    end

    if hasLegendary then
        print("🔧 Enabling Legendary AutoSell before summon (Non-Shiny + Shiny)...")

        local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
        local Actions = require(FusionPackage.Actions)

        -- เปิดขาย Legendary (Non-Shiny)
        pcall(function()
            Actions.ToggleAutoSell("Standard", "Legendary", false, true)
        end)
        task.wait(0.3)

        -- เปิดขาย Legendary (Shiny)
        pcall(function()
            Actions.ToggleAutoSell("Standard", "Legendary", true, true)
        end)
        task.wait(0.3)

        print("✅ Legendary AutoSell enabled before summon (including Shiny)")
    else
        print("ℹ️ No Legendary units found - Legendary AutoSell remains disabled")
    end

    task.wait(1)

    local BANNER_ID = "Standard"
    local AMOUNT_PER_SUMMON = 50  -- 50 gems ต่อรอบ (x10 summon)
    local GEMS_PER_ROUND = 2500   -- 1 รอบ = 50 ครั้ง = 2500 gems
    local summonCount = 0
    local MAX_SUMMONS = 100

    while summonCount < MAX_SUMMONS do
        -- เช็คว่าได้ตัวที่ต้องการก่อนสุ่ม (ทุกรอบ)
        local foundBeforeSummon = checkInventoryForUnits(SUMMON_CONFIG)

        if autoSummonMode then
            -- โหมด auto: ได้ตัวใดตัวหนึ่งก็พอ
            if #foundBeforeSummon > 0 then
                sendSummonStatus(foundBeforeSummon, true)
                hasTargetUnit = true
                print("✅ Found target unit before summon - skipping summon")
                break
            end
        else
            -- โหมดปกติ: ต้องได้ครบทุกตัว
            if #foundBeforeSummon >= #SUMMON_CONFIG then
                sendSummonStatus(foundBeforeSummon, true)
                hasTargetUnit = true
                print("✅ Found all target units before summon - skipping summon")
                break
            end
        end

        -- เช็คเงินก่อนสุ่ม
        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
        local gems = replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.Gem and replica.Data.ItemData.Gem.Amount or 0

        -- คำนวณจำนวนครั้งที่สุ่มได้ (ถ้าเหลือน้อยกว่า 2500)
        local maxSummons = math.floor(gems / AMOUNT_PER_SUMMON)

        if maxSummons <= 0 then
            warn(string.format("⚠️ Not enough gems for summon: %d (require %d)", gems, AMOUNT_PER_SUMMON))
            break
        end

        -- แสดงจำนวนรอบที่จะสุ่ม
        if gems < GEMS_PER_ROUND then
            print(string.format("ℹ️ Gems: %d (< 2500) - Can summon %d more times", gems, maxSummons))
        end

        summonCount = summonCount + 1

        pcall(function()
            Nodes.BANNER_SUMMON:FireServer(BANNER_ID, AMOUNT_PER_SUMMON)
        end)

        task.wait(0.3)

        -- ปิด popup
        for j = 1, 5 do
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
            task.wait(0.02)
        end

        task.wait(0.2)

        -- เช็คว่าได้ครบหรือยัง
        local foundInInventory = checkInventoryForUnits(SUMMON_CONFIG)

        if autoSummonMode then
            -- โหมด auto: ได้ตัวใดตัวหนึ่งก็พอ
            if #foundInInventory > 0 then
                sendSummonStatus(foundInInventory, true)
                hasTargetUnit = true
                break
            end
        else
            -- โหมดปกติ: ต้องได้ครบทุกตัว
            if #foundInInventory >= #SUMMON_CONFIG then
                sendSummonStatus(foundInInventory, true)
                hasTargetUnit = true
                break
            else
                -- แสดงตัวที่มีแล้ว
                if #foundInInventory > 0 then
                    sendSummonStatus(foundInInventory, false)
                end

                -- เช็คว่าเป็น Secret unit หรือไม่
                local isSecretUnit = false
                for _, configUnit in ipairs(SUMMON_CONFIG) do
                    for _, secretUnit in ipairs(SECRET_UNITS) do
                        if configUnit == secretUnit then
                            isSecretUnit = true
                            break
                        end
                    end
                    if isSecretUnit then break end
                end

                if isSecretUnit then
                    -- Secret unit: ข้าม Banner check (มีเสมอ)
                    -- ทำต่อ loop
                else
                    -- Mythic unit: เช็ค Banner ว่ายังมีตัวที่ต้องการอยู่หรือไม่
                    local bannerUnits = checkCurrentBanner()
                    local hasMatch = false
                    for _, configUnit in pairs(SUMMON_CONFIG) do
                        for _, bannerUnit in pairs(bannerUnits) do
                            if configUnit == bannerUnit then
                                hasMatch = true
                                break
                            end
                        end
                        if hasMatch then break end
                    end

                    if not hasMatch then
                        if #foundInInventory > 0 then
                            sendSummonStatus(foundInInventory, false)
                        end
                        warn("⚠️ Target units no longer in banner - stopping summon")
                        break
                    end
                end
            end
        end
    end

    if summonCount >= MAX_SUMMONS then
        local foundInInventory = checkInventoryForUnits(SUMMON_CONFIG)
        if #foundInInventory > 0 then
            sendSummonStatus(foundInInventory, false)
        end
        warn(string.format("⚠️ Reached max summons (%d)", MAX_SUMMONS))
    end

elseif not hasTargetUnit then
    printStep("Auto Summon (Legendary)...")

    local BANNER_ID = "Standard"
    local AMOUNT_PER_SUMMON = 50
    local DELAY = 2
    local summonCount = 0
    local MAX_SUMMONS = 100  -- จำกัดไว้ 100 รอบป้องกันวนไม่รู้จบ

    local function checkForTargetUnits()
        local targetUnits = {
            "The Hero",
            "Scissor",
            "Ice Queen",
            "Water Princess",
            "Forbidden Teacher",
            "Greed"
        }
        return #checkInventoryForUnits(targetUnits) > 0
    end

    while not hasTargetUnit and summonCount < MAX_SUMMONS do
        summonCount = summonCount + 1

        pcall(function()
            Nodes.BANNER_SUMMON:FireServer(BANNER_ID, AMOUNT_PER_SUMMON)
        end)

        task.wait(DELAY)

        -- spam คลิกมุมซ้ายบน 5 รอบ
        for j = 1, 5 do
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(10, 10, 0, false, game, 0)
            task.wait(0.1)
        end

        task.wait(2)

        -- เช็คว่าได้ target unit หรือยัง
        hasTargetUnit = checkForTargetUnits()

        if hasTargetUnit then
            warn("✅ Target Legendary unit found!")
        end
    end

    if not hasTargetUnit then
        warn(string.format("⚠️ Reached max summons (%d) without finding target unit", MAX_SUMMONS))
    end
else
end

-- ========================================
-- 6.5 Trait Reroll System (ถ้ามี Config)
-- ========================================
-- เช็คว่าควรทำ Trait Reroll หรือไม่
local shouldDoTraitReroll = false
local traitRerollTargetUnit = nil

-- Debug: แสดง Config
print("🔍 Trait Reroll Config:")
print(string.format("   TRAIT_REROLL_CONFIG exists: %s", tostring(TRAIT_REROLL_CONFIG ~= nil)))
if TRAIT_REROLL_CONFIG then
    print(string.format("   TargetUnit: %s", tostring(TRAIT_REROLL_CONFIG.TargetUnit)))
    print(string.format("   TargetTrait: %s", tostring(TRAIT_REROLL_CONFIG.TargetTrait)))
end
print(string.format("   hasTargetUnit: %s", tostring(hasTargetUnit)))

if TRAIT_REROLL_CONFIG and TRAIT_REROLL_CONFIG.TargetUnit then
    -- กรณีที่ 1: มี Config และได้ตัวที่ต้องการจาก Summon
    if hasTargetUnit then
        shouldDoTraitReroll = true
        traitRerollTargetUnit = TRAIT_REROLL_CONFIG.TargetUnit
    -- กรณีที่ 2: ไม่ได้ตัวที่ต้องการ แต่มี Mythic ใน Inventory (Fallback)
    elseif not hasTargetUnit and hasSummonConfig then
        printStep("Checking for fallback Mythic units...")

        -- เช็คว่ามี Mythic ใดๆ ที่ไม่ได้ตั้งใน SummonConfig
        local availableMythics = checkInventoryForUnits(MYTHIC_UNITS, true)

        if #availableMythics > 0 then
            -- เรียงตาม Priority
            table.sort(availableMythics, function(a, b)
                local priorityA = 999
                local priorityB = 999

                for i, unitName in ipairs(TRAIT_REROLL_PRIORITY) do
                    if a.name == unitName then priorityA = i end
                    if b.name == unitName then priorityB = i end
                end

                return priorityA < priorityB
            end)

            local fallbackUnit = availableMythics[1].name
            print(string.format("   Found fallback Mythic: %s", fallbackUnit))

            shouldDoTraitReroll = true
            traitRerollTargetUnit = fallbackUnit
        else
            warn("   ⚠️ No fallback Mythic units found")
        end
    end
end

if shouldDoTraitReroll and traitRerollTargetUnit then
    printStep("Checking Trait Reroll Config...")

    local targetUnitName = traitRerollTargetUnit
    local targetTrait = TRAIT_REROLL_CONFIG.TargetTrait

    -- เช็คว่า SUMMON_CONFIG เป็น Secret unit หรือไม่
    local isSecretSummon = false
    if hasSummonConfig and CHANGE_ACC_SECRETS then  -- ต้องเปิด Config ด้วย
        for _, configUnit in ipairs(SUMMON_CONFIG) do
            for _, secretUnit in ipairs(SECRET_UNITS) do
                if configUnit == secretUnit then
                    isSecretSummon = true
                    print(string.format("   ℹ️ Config targets Secret unit '%s' + Change_Acc_Secrets enabled - will send DONE after Trait Reroll", configUnit))
                    break
                end
            end
            if isSecretSummon then break end
        end
    end

    -- ถ้า TargetUnit เป็น "auto" → เลือกตาม Priority
    if targetUnitName == "auto" then
        if hasSummonConfig and hasTargetUnit then
            -- เลือกจาก SummonConfig ที่ได้
            local availableUnits = checkInventoryForUnits(SUMMON_CONFIG, true)

            if #availableUnits > 0 then
                -- เรียงตาม Priority
                table.sort(availableUnits, function(a, b)
                    local priorityA = 999
                    local priorityB = 999

                    for i, unitName in ipairs(TRAIT_REROLL_PRIORITY) do
                        if a.name == unitName then priorityA = i end
                        if b.name == unitName then priorityB = i end
                    end

                    return priorityA < priorityB
                end)

                targetUnitName = availableUnits[1].name
                print(string.format("   Auto-selected: %s (Priority)", targetUnitName))
            else
                -- ไม่เจอ Config units → ลอง Fallback ไป Mythic
                warn("   ⚠️ No summon config units found in inventory")

                -- ถ้าเป็น Secret Summon + Change_Acc_Secrets → ใช้ Mythic Fallback
                if isSecretSummon and CHANGE_ACC_SECRETS then
                    print("   ℹ️ Checking Mythic fallback for Trait Reroll...")
                    local mythicUnits = checkInventoryForUnits(MYTHIC_UNITS, true)

                    if #mythicUnits > 0 then
                        -- เรียงตาม Priority
                        table.sort(mythicUnits, function(a, b)
                            local priorityA = 999
                            local priorityB = 999

                            for i, unitName in ipairs(TRAIT_REROLL_PRIORITY) do
                                if a.name == unitName then priorityA = i end
                                if b.name == unitName then priorityB = i end
                            end

                            return priorityA < priorityB
                        end)

                        targetUnitName = mythicUnits[1].name
                        print(string.format("   ✅ Auto-selected Mythic fallback: %s (Priority)", targetUnitName))
                    else
                        targetUnitName = nil
                    end
                else
                    targetUnitName = nil
                end
            end
        else
            warn("   ⚠️ Cannot use 'auto' without SummonConfig or target unit")
            targetUnitName = nil
        end
    end

    if targetUnitName then
        -- เช็คว่ามีตัวที่ต้องการหรือไม่
        local unitsWithTrait = checkInventoryForUnits({targetUnitName}, true)

        if #unitsWithTrait > 0 then
            -- เลือกตัวที่ดีที่สุดสำหรับสุ่ม Trait (เลือก Shiny ก่อน)
            local unitInfo = selectBestUnitForReroll(unitsWithTrait)
            local currentTrait = unitInfo.trait

            print(string.format("   Selected unit: %s (Trait: %s, Shiny: %s, Full Key: %s)",
                unitInfo.name, currentTrait, tostring(unitInfo.isShiny or false), unitInfo.fullKey))

            -- เช็คว่ามี Trait ที่ต้องการแล้วหรือไม่
            local hasTargetTrait = false

            print(string.format("🔍 [Trait Check] Current Trait: %s, Target: %s (type: %s)",
                currentTrait, tostring(targetTrait), type(targetTrait)))

            if not targetTrait then
                -- nil = สุ่มแบบสุ่ม (ได้อะไรก็ได้ที่ไม่ใช่ None)
                hasTargetTrait = (currentTrait ~= "None")
                print(string.format("   Mode: Random (any except None), hasTargetTrait: %s", tostring(hasTargetTrait)))
            elseif type(targetTrait) == "table" then
                if #targetTrait == 0 then
                    -- {} = empty table → ไม่ต้องสุ่ม Trait
                    hasTargetTrait = true
                    print("   Mode: Empty table → Skip reroll")
                else
                    -- เช็คว่ามีใน list หรือไม่
                    print(string.format("   Mode: Table with %d traits: %s", #targetTrait, table.concat(targetTrait, ", ")))
                    for _, trait in ipairs(targetTrait) do
                        if currentTrait == trait then
                            hasTargetTrait = true
                            break
                        end
                    end
                    print(string.format("   Match found: %s", tostring(hasTargetTrait)))
                end
            else
                -- string เดียว
                hasTargetTrait = (currentTrait == targetTrait)
                print(string.format("   Mode: Single string, match: %s", tostring(hasTargetTrait)))
            end

            print(string.format("🔍 [Final Decision] hasTargetTrait: %s", tostring(hasTargetTrait)))

            if hasTargetTrait then
                -- มี Trait ที่ต้องการแล้ว → ข้ามการสุ่ม
                print(string.format("✅ %s already has target Trait: %s", targetUnitName, currentTrait))

                -- ส่ง Horst Description + DONE
                if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                    local currentGems = replica and replica.Data.ItemData.Gem.Amount or 0
                    local currentRR = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0

                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ✅ %s", currentGems, currentRR, targetUnitName, currentTrait))

                    _G.ScriptShouldStop = true  -- ตั้งค่า flag ก่อนรอ

                    task.wait(5)  -- รอ 5 วิก่อนส่ง DONE

                    -- ถ้า Config เป็น Secret unit → บังคับส่ง DONE
                    if isSecretSummon then
                        _G.Horst_AccountChangeDone()
                        print("✅ Secret unit Trait completed - Script will stop...")

                        -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                        while true do
                            pcall(function()
                                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ✅ %s", gems, rr, targetUnitName, currentTrait))
                            end)
                            task.wait(5)
                        end
                    end

                    if GEM_TARGET then
                        if currentGems >= GEM_TARGET then
                            _G.Horst_AccountChangeDone()
                            print("✅ GEM_TARGET reached - Script will stop...")

                            -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                            while true do
                                pcall(function()
                                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                    local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ✅ %s", gems, rr, targetUnitName, currentTrait))
                                end)
                                task.wait(5)
                            end
                        end
                    else
                        _G.Horst_AccountChangeDone()
                        print("✅ Trait Reroll completed - Script will stop...")

                        -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                        while true do
                            pcall(function()
                                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ✅ %s", gems, rr, targetUnitName, currentTrait))
                            end)
                            task.wait(5)
                        end
                    end
                end
            else
                -- ยังไม่มี Trait ที่ต้องการ → เริ่มสุ่ม
                printStep(string.format("Rerolling Trait for %s...", targetUnitName))

                -- เช็ค Trait Reroll จำนวน
                local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                local traitRerolls = 0
                if replica and replica.Data and replica.Data.ItemData and replica.Data.ItemData.TraitReroll then
                    traitRerolls = replica.Data.ItemData.TraitReroll.Amount or 0
                end

                if traitRerolls <= 0 then
                    warn("❌ No Trait Reroll items available")

                    -- ส่ง Horst Description + DONE (Out of RR)
                    if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                        local currentGems = replica and replica.Data.ItemData.Gem.Amount or 0
                        local currentRR = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0

                        _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ❌ %s (Out of RR)", currentGems, currentRR, targetUnitName, currentTrait))

                        _G.ScriptShouldStop = true  -- ตั้งค่า flag ก่อนรอ

                        task.wait(5)  -- รอ 5 วิก่อนส่ง DONE

                        -- ถ้า Config เป็น Secret unit → บังคับส่ง DONE
                        if isSecretSummon then
                            _G.Horst_AccountChangeDone()
                            print("✅ Secret unit (Out of RR) - Script will stop...")

                            -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                            while true do
                                pcall(function()
                                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                    local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ❌ %s (Out of RR)", gems, rr, targetUnitName, currentTrait))
                                end)
                                task.wait(5)
                            end
                        end

                        if GEM_TARGET then
                            if currentGems >= GEM_TARGET then
                                _G.Horst_AccountChangeDone()
                                print("✅ GEM_TARGET reached - Script will stop...")

                                -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                                while true do
                                    pcall(function()
                                        local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                        local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                        local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                        _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ❌ %s (Out of RR)", gems, rr, targetUnitName, currentTrait))
                                    end)
                                    task.wait(5)
                                end
                            end
                        else
                            _G.Horst_AccountChangeDone()
                            print("✅ Out of RR - Script will stop...")

                            -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                            while true do
                                pcall(function()
                                    local replica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replica and replica.Data.ItemData.Gem.Amount or 0
                                    local rr = replica and replica.Data.ItemData.TraitReroll and replica.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ❌ %s (Out of RR)", gems, rr, targetUnitName, currentTrait))
                                end)
                                task.wait(5)
                            end
                        end
                    end
                else
                -- ฟังก์ชันเช็ค Trait ปัจจุบันพร้อม retry
                local function getCurrentTrait(fullKey, maxRetries)
                    maxRetries = maxRetries or 10

                    for i = 1, maxRetries do
                        local success, result = pcall(function()
                            local newUnitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
                            if newUnitData and newUnitData[fullKey] then
                                return newUnitData[fullKey].Trait or "None"
                            end
                            return nil
                        end)

                        if success and result then
                            return result
                        end

                        if i < maxRetries then
                            task.wait(0.1)
                        end
                    end

                    return nil
                end

                -- เริ่มสุ่ม Trait
                local attempts = 0
                local success = false
                local finalTrait = currentTrait

                while attempts < traitRerolls do
                    -- เช็ค RR ปัจจุบันก่อนสุ่มแต่ละรอบ
                    local currentReplica = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                    local currentRR = 0
                    if currentReplica and currentReplica.Data and currentReplica.Data.ItemData and currentReplica.Data.ItemData.TraitReroll then
                        currentRR = currentReplica.Data.ItemData.TraitReroll.Amount or 0
                    end

                    if currentRR <= 0 then
                        print(string.format("⚠️ Out of RR during reroll (attempt %d/%d)", attempts, traitRerolls))
                        break
                    end

                    attempts = attempts + 1

                    -- กำหนด Trait ที่จะส่งไป
                    local traitToRoll = nil
                    if type(targetTrait) == "string" then
                        traitToRoll = targetTrait
                    end

                    -- สุ่ม Trait
                    local rollSuccess, rollError = pcall(function()
                        Nodes.ROLL_UNIT_TRAIT:FireServer(unitInfo.fullKey, traitToRoll)
                    end)

                    if not rollSuccess then
                        task.wait(0.1)
                        continue
                    end

                    task.wait(0.5)

                    -- เช็ค Trait ใหม่
                    local newTrait = getCurrentTrait(unitInfo.fullKey, 10)

                    if not newTrait then
                        task.wait(0.1)
                        continue
                    end

                    finalTrait = newTrait

                    -- ตรวจสอบว่าได้ Trait ที่ต้องการหรือไม่
                    local gotTargetTrait = false

                    if not targetTrait then
                        if newTrait ~= "None" then
                            gotTargetTrait = true
                        end
                    elseif type(targetTrait) == "table" then
                        for _, trait in ipairs(targetTrait) do
                            if newTrait == trait then
                                gotTargetTrait = true
                                break
                            end
                        end
                    else
                        if newTrait == targetTrait then
                            gotTargetTrait = true
                        end
                    end

                    if gotTargetTrait then
                        success = true
                        break
                    end

                    task.wait(0.1)
                end

                -- แสดงผลลัพธ์
                if success then
                    print(string.format("✅ %s | Trait: %s | Used: %d | Left: %d",
                        targetUnitName, finalTrait, attempts, traitRerolls - attempts))

                    -- สำเร็จ
                    if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                        local currentGems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                        local currentRR = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0

                        _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ✅ %s", currentGems, currentRR, targetUnitName, finalTrait))

                        _G.ScriptShouldStop = true  -- ตั้งค่า flag ก่อนรอ

                        task.wait(5)  -- รอ 5 วิก่อนส่ง DONE

                        -- ถ้า Config เป็น Secret unit → บังคับส่ง DONE
                        if isSecretSummon then
                            _G.Horst_AccountChangeDone()
                            print("✅ Secret unit Trait succeeded - Script will stop...")

                            -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                            while true do
                                pcall(function()
                                    local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                    local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ✅ %s", gems, rr, targetUnitName, finalTrait))
                                end)
                                task.wait(5)
                            end
                        end

                        if GEM_TARGET then
                            if currentGems >= GEM_TARGET then
                                _G.Horst_AccountChangeDone()
                                print("✅ GEM_TARGET reached - Script will stop...")

                                -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                                while true do
                                    pcall(function()
                                        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                        local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                        local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                        _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ✅ %s", gems, rr, targetUnitName, finalTrait))
                                    end)
                                    task.wait(5)
                                end
                            end
                        else
                            _G.Horst_AccountChangeDone()
                            print("✅ Trait Reroll succeeded - Script will stop...")

                            -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                            while true do
                                pcall(function()
                                    local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                    local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ✅ %s", gems, rr, targetUnitName, finalTrait))
                                end)
                                task.wait(5)
                            end
                        end
                    end
                else
                    -- ใช้หมด
                    print(string.format("⚠️ %s | Final Trait: %s | Used: %d (all rerolls)", targetUnitName, finalTrait, traitRerolls))

                    if HORST_ENABLED and _G.Horst_SetDescription and _G.Horst_AccountChangeDone then
                        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                        local currentGems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                        local currentRR = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0

                        _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ❌ %s (Out of RR)", currentGems, currentRR, targetUnitName, finalTrait))

                        _G.ScriptShouldStop = true  -- ตั้งค่า flag ก่อนรอ

                        task.wait(5)  -- รอ 5 วิก่อนส่ง DONE

                        -- ถ้า Config เป็น Secret unit → บังคับส่ง DONE
                        if isSecretSummon then
                            _G.Horst_AccountChangeDone()
                            print("✅ Secret unit (all rerolls used) - Script will stop...")

                            -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                            while true do
                                pcall(function()
                                    local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                    local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ❌ %s (Out of RR)", gems, rr, targetUnitName, finalTrait))
                                end)
                                task.wait(5)
                            end
                        end

                        if GEM_TARGET then
                            if currentGems >= GEM_TARGET then
                                _G.Horst_AccountChangeDone()
                                print("✅ GEM_TARGET reached - Script will stop...")

                                -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                                while true do
                                    pcall(function()
                                        local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                        local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                        local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                        _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ❌ %s (Out of RR)", gems, rr, targetUnitName, finalTrait))
                                    end)
                                    task.wait(5)
                                end
                            end
                        else
                            _G.Horst_AccountChangeDone()
                            print("✅ All rerolls used - Script will stop...")

                            -- Loop ส่ง Description ทุก 5 วิหลัง DONE
                            while true do
                                pcall(function()
                                    local replicaAfter = Nodes.GET_PLAYER_REPLICA:InvokeSelf()
                                    local gems = replicaAfter and replicaAfter.Data.ItemData.Gem.Amount or 0
                                    local rr = replicaAfter and replicaAfter.Data.ItemData.TraitReroll and replicaAfter.Data.ItemData.TraitReroll.Amount or 0
                                    _G.Horst_SetDescription(string.format("💎 Gems: %d • RR: %d • %s • Trait: ❌ %s (Out of RR)", gems, rr, targetUnitName, finalTrait))
                                end)
                                task.wait(5)
                            end
                        end
                    end
                end
                end  -- ปิด else ของ if traitRerolls <= 0
            end  -- ปิด if hasTargetTrait
        else
            warn(string.format("❌ Unit '%s' not found in inventory", targetUnitName))
        end  -- ปิด if #unitsWithTrait > 0
    end  -- ปิด if targetUnitName then

    task.wait(1)
end  -- ปิด if shouldDoTraitReroll and traitRerollTargetUnit

-- ========================================
-- 7. QuickEquip (ถ้ามีตัวที่ต้องการ)
-- ========================================
if hasTargetUnit then
    printStep("Quick Equip...")

    -- Get UnitData และ UnitInfo โดยตรง (ไม่ต้องปิด Inventory)
    local unitData = Nodes.GET_DATA_VALUE:InvokeSelf("UnitData")
    local UnitInfo = require(ReplicatedStorage.Shared.Information.Units)

    -- สร้าง displayNameMap (เลือก Shiny ก่อน)
    local displayNameMap = {}
    for fullKey, data in pairs(unitData) do
        local internalName = fullKey:match("^(.+)#") or fullKey
        local displayName = UnitInfo[internalName] and UnitInfo[internalName].DisplayName or internalName
        local lowerName = displayName:lower()
        local isShiny = data.Shiny or false

        -- เลือก Shiny ก่อน หรือถ้ายังไม่มีก็เอาตัวปกติ
        if not displayNameMap[lowerName] or isShiny then
            displayNameMap[lowerName] = fullKey
            if isShiny then
                print(string.format("   ✨ Found SHINY %s: %s", displayName, fullKey))
            end
        end
    end

    -- หา target unit ที่มีอยู่ (เลือกจาก Legendary List เท่านั้น - ไม่ว่าจะมี Config หรือไม่)
    local LEGENDARY_UNITS = {
        "Ice Queen",           -- Priority 1 (วางได้ 4 ตัว)
        "Forbidden Teacher",   -- Priority 2 (วางได้ 4 ตัว)
        "The Hero",           -- Priority 3 (วางได้ 4 ตัว)
        "Greed",              -- Priority 4 (วางได้ 3 ตัว)
        "Scissor",            -- Priority 5 (วางได้ 3 ตัว)
        "Water Princess"      -- Priority 6 (วางได้ 3 ตัว)
    }

    local foundTargetUnit = nil

    -- เช็คตามลำดับ Priority
    for _, targetUnit in ipairs(LEGENDARY_UNITS) do
        if displayNameMap[targetUnit:lower()] then
            foundTargetUnit = targetUnit
            break
        end
    end

    -- Unequip All ก่อน
    Nodes.UNIT_UNEQUIP_ALL:FireServer("Unit")
    task.wait(0.5)

    -- Equip Carrot ช่อง 1
    local carrotFullKey = displayNameMap["carrot"]
    if carrotFullKey then
        Nodes.UNIT_EQUIP:FireServer(carrotFullKey, "1")
        task.wait(0.3)
    else
        warn("❌ Carrot not found in inventory")
    end

    -- Equip target unit ช่อง 2
    if foundTargetUnit then
        local targetFullKey = displayNameMap[foundTargetUnit:lower()]
        if targetFullKey then
            Nodes.UNIT_EQUIP:FireServer(targetFullKey, "2")
            task.wait(0.3)
        end
    else
        warn("❌ No target unit to equip in slot 2")
    end

    task.wait(1)

    -- ========================================
    -- 8. auto_start_game.lua
    -- ========================================
    printStep("Starting Game...")

    local CONFIG = {
        MapName = "SchoolGrounds",
        ActName = "Act 1",
        Difficulty = "Hard",
        Gamemode = "Story"
    }

    local FusionPackage = ReplicatedStorage:WaitForChild("FusionPackage")
    local Actions = require(FusionPackage.Actions)
    Actions.PartyStartGame(CONFIG)

else
    warn("⚠️ Skipping equip and game start - no target unit found")
end
