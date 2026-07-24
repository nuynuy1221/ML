if not game:IsLoaded() then
    game.Loaded:Wait()
end

local repo = "https://raw.githubusercontent.com/nuynuy1221/AE/refs/heads/main/"
local index = "Index.txt"

local function fetch(url)
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        return response
    else
        warn("[Loader] Fetch failed:", url)
        return nil
    end
end

-- โหลดรายชื่อไฟล์จาก Index.txt
local fileList = fetch(repo .. index)
if not fileList then
    warn("[Loader] Unable to load Index!")
    return
end

local files = string.split(fileList, "\n")

for _, file in ipairs(files) do
    file = file:gsub("\r", "")
    if file ~= "" and file ~= index then
        local url = repo .. file
        print("[Loader] Loading:", url)

        local content = fetch(url)
        if content then
            local ok, err = pcall(function()
                loadstring(content)()
            end)

            if not ok then
                warn("[Loader Error]", file, err)
            end
        end
    end
end

print("[Loader] All scripts loaded.")
