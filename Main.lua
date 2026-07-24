repeat wait() until game:IsLoaded()
-- 8.48
-- Main Script - Manhwa Legends Auto Farm
-- รวมทุกฟีเจอร์: GUI → เช็คแมพ → ลบแมพ → Settings → Claim → สุ่ม → Equip → เข้าเล่น

repeat task.wait() until game:IsLoaded()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎮 Manhwa Legends Auto Farm")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

-- ════════════════════════════════════════════════════════
-- [1] Load Stats GUI
-- ════════════════════════════════════════════════════════
print("📊 [1/8] Loading Stats GUI...")
local guiSuccess = pcall(function()
    loadstring(game:HttpGetAsync("file:///" .. "C:\\Users\\fearg\\Desktop\\Claude\\Manhwa Legends\\StatsGUI.lua"))()
end)
if not guiSuccess then
    pcall(function()
        dofile("C:\\Users\\fearg\\Desktop\\Claude\\Manhwa Legends\\StatsGUI.lua")
    end)
end
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
        local holderObjects = {
            workspace.Holder.InvisibleWalls,
            workspace.Holder.MISC,
            workspace.Holder.Map,
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
        {name = "LowDetail", value = true},
        {name = "DisableEffects", value = true},
        {name = "DisableDamage", value = true},
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

    pcall(function()
        if ClientNetwork.Player.ClaimAllBattlepass then
            ClientNetwork.Player.ClaimAllBattlepass.Invoke()
        end
    end)

    pcall(function()
        if ClientNetwork.Player.UpdateIndexes then
            ClientNetwork.Player.UpdateIndexes.Fire()
        end
    end)

    print("   ✅ Rewards claimed")

    -- ════════════════════════════════════════════════════════
    -- [6] Check & Summon Units
    -- ════════════════════════════════════════════════════════
    print("🎲 [6/8] Checking required units...")

    local requiredUnits = {"Irina Vladimirov", "Gino", "Gyoteng"}
    local hasAllUnits = false

    local function checkUnits()
        local success, result = pcall(function()
            local inventory = Atoms.Inventory and Atoms.Inventory()
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

        local maxAttempts = 50
        local attempts = 0

        while not hasAllUnits and attempts < maxAttempts do
            attempts = attempts + 1
            print(string.format("   🎰 Summoning 10x (Attempt %d/%d)...", attempts, maxAttempts))
            pcall(function()
                ClientNetwork.Player.Summon.Invoke("Standard", 10)
            end)
            task.wait(3)
            hasAllUnits = checkUnits()
        end

        if hasAllUnits then
            print("   ✅ All units obtained")
        else
            warn("   ⚠️  Could not obtain all units after max attempts")
        end
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
        for i = 1, 6 do
            ClientNetwork.Player.UnequipUnit.Fire(i)
            task.wait(0.1)
        end
    end)

    task.wait(0.5)

    -- Equip required units
    local success, inventory = pcall(function()
        return Atoms.Inventory and Atoms.Inventory()
    end)

    if success and inventory and type(inventory) == "table" then
        local slot = 1
        for _, unitName in ipairs(requiredUnits) do
            for unitId, unit in pairs(inventory) do
                if type(unit) == "table" and unit.Name == unitName then
                    pcall(function()
                        ClientNetwork.Player.EquipUnit.Fire(unitId, slot)
                    end)
                    slot = slot + 1
                    task.wait(0.2)
                    break
                end
            end
        end
    end

    print("   ✅ Units equipped")

    -- ════════════════════════════════════════════════════════
    -- [8] Create Party & Join Map
    -- ════════════════════════════════════════════════════════
    print("🚪 [8/8] Creating party & joining map...")

    task.wait(1)

    pcall(function()
        ClientNetwork.Player.CreateParty.Fire("Story", "Act 1", "Elven Forest", "Easy")
    end)

    task.wait(2)

    pcall(function()
        ClientNetwork.Player.StartGame.Fire()
    end)

    print("   ✅ Joining map...")
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ Lobby setup complete - waiting for map load...")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

else
    -- IN-MAP MODE
    print("🧹 [3/8] Removing in-game objects...")

    -- Keep only essential objects
    for _, obj in pairs(workspace:GetChildren()) do
        local keep = obj.Name == "Camera" or obj.Name == "Terrain" or
                    obj.Name == "RespawnPart" or obj.Name == "ColorblindLabel" or
                    obj.Name == "Holder"

        if not keep then
            pcall(function() obj:Destroy() end)
        end
    end

    if workspace:FindFirstChild("Holder") then
        for _, obj in pairs(workspace.Holder:GetChildren()) do
            local keep = obj.Name == "Players" or obj.Name == "PreSpawn"
            if not keep then
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

    print("   ✅ Map cleanup complete")

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
                ClientNetwork.Controller.VoteRetry.Fire()
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

    local farmSuccess = pcall(function()
        loadstring(game:HttpGetAsync("file:///" .. "C:\\Users\\fearg\\Desktop\\Claude\\Manhwa Legends\\AutoFarm.lua"))()
    end)

    if not farmSuccess then
        pcall(function()
            dofile("C:\\Users\\fearg\\Desktop\\Claude\\Manhwa Legends\\AutoFarm.lua")
        end)
    end
end

print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ Main Script Complete")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
