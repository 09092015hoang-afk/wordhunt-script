local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SIZE = 5

local CONFIG = {
    minLength = 3,
    maxLength = 25,
    scanInterval = 0.8,
    boardName = "Board",
    letterType = "TextLabel"
}

local VIP = true
local autoMode = VIP
local isSolving = false

local allWords = {}
local usedWords = {}

local directions = {
    {1, 0}, {-1, 0},
    {0, 1}, {0, -1},
    {1, 1}, {1, -1},
    {-1, 1}, {-1, -1}
}

local commonWords = {
    the = true, and = true, a = true, an = true,
    is = true, it = true, to = true, of = true,
    in = true, for = true, on = true, with = true,
    as = true, at = true, by = true, or = true
}

local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Word Hunt Pro",
            Text = text,
            Duration = 3
        })
    end)
end

local function loadJSON(content)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if not ok then
        return false
    end

    for word in pairs(data) do
        word = word:lower()

        if #word >= CONFIG.minLength
            and #word <= CONFIG.maxLength
            and not commonWords[word] then

            allWords[word] = true
        end
    end

    return true
end

local function loadText(content)
    local count = 0

    for word in content:gmatch("[^\r\n]+") do
        word = word:lower()

        if #word >= CONFIG.minLength
            and #word <= CONFIG.maxLength
            and not commonWords[word] then

            if not allWords[word] then
                allWords[word] = true
                count += 1
            end
        end
    end

    return count > 0
end

local function loadDictionary()
    allWords = {}

    local urls = {
        "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_dictionary.json",
        "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears.txt"
    }

    for _, url in ipairs(urls) do
        local ok, content = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and content then
            local loaded

            if content:match("^%s*{") then
                loaded = loadJSON(content)
            else
                loaded = loadText(content)
            end

            if loaded then
                local count = 0

                for _ in pairs(allWords) do
                    count += 1
                end

                notify("Đã tải " .. count .. " từ")
                return true
            end
        end
    end

    notify("Không tải được từ điển")
    return false
end

local function getBoard()
    local board = playerGui:FindFirstChild(CONFIG.boardName, true)

    if not board then
        return nil
    end

    local objects = {}

    for _, obj in ipairs(board:GetChildren()) do
        if obj:IsA(CONFIG.letterType) and #obj.Text == 1 then
            objects[#objects + 1] = obj
        end
    end

    if #objects ~= SIZE * SIZE then
        return nil
    end

    table.sort(objects, function(a, b)
        local ay = a.AbsolutePosition.Y
        local by = b.AbsolutePosition.Y

        if math.abs(ay - by) < 5 then
            return a.AbsolutePosition.X < b.AbsolutePosition.X
        end

        return ay < by
    end)

    local matrix = {}

    for row = 1, SIZE do
        matrix[row] = {}

        for col = 1, SIZE do
            local index = (row - 1) * SIZE + col
            matrix[row][col] = objects[index].Text:lower()
        end
    end

    return matrix
end

local function findAllWords(board)
    local found = {}

    local function dfs(row, col, word, visited)
        if #word > CONFIG.maxLength then
            return
        end

        if #word >= CONFIG.minLength
            and allWords[word]
            and not usedWords[word] then

            found[word] = true
        end

        for _, direction in ipairs(directions) do
            local newRow = row + direction[1]
            local newCol = col + direction[2]

            if newRow >= 1
                and newRow <= SIZE
                and newCol >= 1
                and newCol <= SIZE then

                local key = newRow .. ":" .. newCol

                if not visited[key] then
                    visited[key] = true

                    dfs(
                        newRow,
                        newCol,
                        word .. board[newRow][newCol],
                        visited
                    )

                    visited[key] = nil
                end
            end
        end
    end

    for row = 1, SIZE do
        for col = 1, SIZE do
            local visited = {}
            visited[row .. ":" .. col] = true

            dfs(
                row,
                col,
                board[row][col],
                visited
            )
        end
    end

    local result = {}

    for word in pairs(found) do
        result[#result + 1] = word
    end

    table.sort(result, function(a, b)
        if #a == #b then
            return a < b
        end

        return #a > #b
    end)

    return result
end

local function solveBoard()
    if not VIP or not autoMode or isSolving then
        return
    end

    isSolving = true

    local ok, err = pcall(function()
        local board = getBoard()

        if not board then
            return
        end

        local words = findAllWords(board)

        if #words == 0 then
            return
        end

        local bestWord = words[1]

        usedWords[bestWord] = true

        print("[WORD HUNT] " .. bestWord:upper())

        notify("Tìm thấy: " .. bestWord:upper())

        -- Game của bạn xử lý bestWord tại đây.
        -- Ví dụ:
        -- SubmitWord:FireServer(bestWord)
    end)

    if not ok then
        warn("[WORD HUNT ERROR]", err)
    end

    isSolving = false
end

local function reset()
    usedWords = {}
    notify("Đã reset danh sách từ")
end

task.spawn(function()
    if not loadDictionary() then
        return
    end

    if VIP then
        autoMode = true
        notify("VIP TEST đã bật")
    end

    while task.wait(CONFIG.scanInterval) do
        if VIP and autoMode then
            solveBoard()
        end
    end
end)