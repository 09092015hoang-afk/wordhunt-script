--[[
    WORD HUNT BATTLE – TỰ ĐỘNG NỐI TỪ HOÀN TOÀN
    - Quét bảng chữ cái tự động.
    - Dùng DFS tìm tất cả từ có thể tạo thành.
    - Chọn từ dài nhất chưa dùng, tự động gửi.
    - Hỗ trợ cả gõ phím và click chuột (cấu hình).
    - Loại bỏ ô nhập thủ công, chỉ giữ nút điều khiển.
--]]

print("[WORD HUNT BATTLE PRO] Khởi tạo...")

-- DỊCH VỤ =====================================================================
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- CẤU HÌNH ====================================================================
local CONFIG = {
    typingSpeed = 0.12,              -- Tốc độ gõ (giây/ký tự)
    minLength = 3,                   -- Độ dài từ tối thiểu
    maxLength = 15,                  -- Độ dài từ tối đa
    boardContainerName = "Board",    -- Tên Frame chứa bảng (có thể thay đổi)
    letterObjectType = "TextLabel",  -- Loại object chứa chữ (TextLabel hoặc TextButton)
    scanInterval = 0.8,              -- Tần suất quét bảng (giây)
    autoSubmit = true,               -- Tự động gửi từ tìm được
    useMouseClick = false,           -- true: click vào ô, false: gõ phím
}

-- Từ điển bỏ qua
local commonWords = {
    ["the"] = true, ["and"] = true, ["a"] = true, ["an"] = true,
    ["is"] = true, ["it"] = true, ["to"] = true, ["of"] = true,
    ["in"] = true, ["for"] = true, ["on"] = true, ["with"] = true,
    ["as"] = true, ["at"] = true, ["by"] = true, ["or"] = true,
}

-- URL từ điển
local DICTIONARY_URLS = {
    "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_dictionary.json",
    "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears.txt"
}

-- BIẾN TOÀN CỤC ===============================================================
local allWords = {}
local usedWords = {}
local autoMode = false
local letterObjects = {}          -- Lưu các đối tượng ô chữ để click
local boardMatrix = {}            -- Ma trận chữ cái 2D
local boardRows, boardCols = 0, 0

-- GUI ĐIỀU KHIỂN ==============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WordHuntBattlePro"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local scaleFactor = 0.75
local marginX, marginY = 20, 20

-- Nút bật/tắt tự động
local autoButton = Instance.new("TextButton")
autoButton.Size = UDim2.new(0, 200 * scaleFactor, 0, 50 * scaleFactor)
autoButton.Position = UDim2.new(1, -200*scaleFactor - marginX, 1, -150*scaleFactor - marginY)
autoButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
autoButton.BorderColor3 = Color3.fromRGB(255, 0, 0)
autoButton.BorderSizePixel = 3
autoButton.TextColor3 = Color3.fromRGB(255, 0, 0)
autoButton.Font = Enum.Font.GothamBold
autoButton.TextSize = 20 * scaleFactor
autoButton.Text = "🔴 TỰ ĐỘNG TẮT"
autoButton.Parent = screenGui

-- Nút TROLL (chọn từ dài nhất và gửi ngay)
local trollButton = Instance.new("TextButton")
trollButton.Size = UDim2.new(0, 120 * scaleFactor, 0, 50 * scaleFactor)
trollButton.Position = UDim2.new(1, -330*scaleFactor - marginX, 1, -150*scaleFactor - marginY)
trollButton.BackgroundColor3 = Color3.fromRGB(50, 10, 50)
trollButton.BorderColor3 = Color3.fromRGB(255, 0, 255)
trollButton.BorderSizePixel = 3
trollButton.TextColor3 = Color3.fromRGB(255, 0, 255)
trollButton.Font = Enum.Font.GothamBold
trollButton.TextSize = 20 * scaleFactor
trollButton.Text = "😈 TROLL"
trollButton.Parent = screenGui

-- Nút Reset danh sách đã dùng
local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(0, 120 * scaleFactor, 0, 50 * scaleFactor)
resetButton.Position = UDim2.new(1, -460*scaleFactor - marginX, 1, -150*scaleFactor - marginY)
resetButton.BackgroundColor3 = Color3.fromRGB(50, 50, 10)
resetButton.BorderColor3 = Color3.fromRGB(255, 255, 0)
resetButton.BorderSizePixel = 3
resetButton.TextColor3 = Color3.fromRGB(255, 255, 0)
resetButton.Font = Enum.Font.GothamBold
resetButton.TextSize = 20 * scaleFactor
resetButton.Text = "🔄 RESET"
resetButton.Parent = screenGui

-- THÔNG BÁO ===================================================================
local function notify(message)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Word Hunt Pro",
            Text = message,
            Duration = 3
        })
    end)
end

-- TẢI TỪ ĐIỂN =================================================================
local function loadFromJSON(content)
    local success, wordsJson = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    if not success then return false end
    for word, _ in pairs(wordsJson) do
        local len = #word
        if len >= CONFIG.minLength and len <= CONFIG.maxLength and not commonWords[word:lower()] then
            table.insert(allWords, word:lower())
        end
    end
    return true
end

local function loadFromText(content)
    for word in content:gmatch("[^\r\n]+") do
        local len = #word
        if len >= CONFIG.minLength and len <= CONFIG.maxLength and not commonWords[word:lower()] then
            table.insert(allWords, word:lower())
        end
    end
    return #allWords > 0
end

local function loadDictionary()
    print("[THÔNG TIN] Đang tải từ điển...")
    notify("Đang tải từ điển...")
    for i, url in ipairs(DICTIONARY_URLS) do
        local ok, content = pcall(function()
            return game:HttpGet(url)
        end)
        if ok then
            local loaded = false
            if content:match("^%s*{") then
                loaded = loadFromJSON(content)
            else
                loaded = loadFromText(content)
            end
            if loaded then
                print("[✓] Đã tải " .. #allWords .. " từ từ nguồn #" .. i)
                notify("✅ Đã tải từ điển (" .. #allWords .. " từ)")
                return true
            end
        else
            warn("[CẢNH BÁO] Nguồn #" .. i .. " thất bại, thử nguồn khác...")
        end
    end
    warn("[LỖI] Tất cả nguồn từ điển đều thất bại")
    notify("❌ Tải từ điển thất bại")
    return false
end

-- QUÉT BẢNG CHỮ CÁI ===========================================================
local function scanBoard()
    -- Tìm container bảng
    local boardContainer = nil
    for _, child in ipairs(playerGui:GetChildren()) do
        if child:IsA("Frame") and child.Name == CONFIG.boardContainerName then
            boardContainer = child
            break
        end
    end
    if not boardContainer then
        -- Dò tìm tự động
        for _, child in ipairs(playerGui:GetChildren()) do
            if child:IsA("Frame") then
                local count = 0
                local objs = {}
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA(CONFIG.letterObjectType) and #sub.Text == 1 then
                        count = count + 1
                        table.insert(objs, sub)
                    end
                end
                if count >= 9 then
                    boardContainer = child
                    letterObjects = objs
                    break
                end
            end
        end
    else
        letterObjects = {}
        for _, sub in ipairs(boardContainer:GetChildren()) do
            if sub:IsA(CONFIG.letterObjectType) and #sub.Text == 1 then
                table.insert(letterObjects, sub)
            end
        end
    end

    if not boardContainer or #letterObjects == 0 then
        return false
    end

    -- Sắp xếp theo vị trí (hàng trước, cột sau)
    table.sort(letterObjects, function(a, b)
        local ay, ax = a.AbsolutePosition.Y, a.AbsolutePosition.X
        local by, bx = b.AbsolutePosition.Y, b.AbsolutePosition.X
        if math.abs(ay - by) < 5 then
            return ax < bx
        end
        return ay < by
    end)

    -- Xác định số hàng và cột
    local rows, cols = 0, 0
    local lastY = nil
    for _, obj in ipairs(letterObjects) do
        local y = obj.AbsolutePosition.Y
        if not lastY or math.abs(y - lastY) > 5 then
            rows = rows + 1
            lastY = y
        end
    end
    cols = math.floor(#letterObjects / rows)
    if cols == 0 then cols = 1 end

    -- Xây dựng ma trận
    local matrix = {}
    local idx = 1
    for r = 1, rows do
        local row = {}
        for c = 1, cols do
            if idx <= #letterObjects then
                table.insert(row, letterObjects[idx].Text:upper())
            else
                table.insert(row, "")
            end
            idx = idx + 1
        end
        table.insert(matrix, row)
    end

    boardRows = rows
    boardCols = cols
    boardMatrix = matrix
    return true
end

-- THUẬT TOÁN DFS TÌM TỪ =======================================================
local function findAllWords(matrix, wordsDict)
    local found = {}
    local rows = #matrix
    local cols = #matrix[1]
    local visited = {}
    local directions = {
        {1,0},{-1,0},{0,1},{0,-1},
        {1,1},{1,-1},{-1,1},{-1,-1}
    }

    local function dfs(r, c, path, word)
        if #word > CONFIG.maxLength then return end
        if #word >= CONFIG.minLength and wordsDict[word] and not usedWords[word] then
            table.insert(found, word)
        end
        for _, d in ipairs(directions) do
            local nr, nc = r + d[1], c + d[2]
            if nr >= 1 and nr <= rows and nc >= 1 and nc <= cols then
                local key = nr .. "," .. nc
                if not visited[key] then
                    visited[key] = true
                    dfs(nr, nc, path .. matrix[nr][nc], word .. matrix[nr][nc])
                    visited[key] = nil
                end
            end
        end
    end

    for r = 1, rows do
        for c = 1, cols do
            visited = {}
            visited[r .. "," .. c] = true
            dfs(r, c, matrix[r][c], matrix[r][c])
        end
    end

    return found
end

-- HÀM GỬI TỪ (BÀN PHÍM) ======================================================
local function typeWordKeyboard(word)
    task.spawn(function()
        -- Click vào trung tâm màn hình để focus ô nhập (nếu cần)
        local cam = workspace.CurrentCamera
        local size = cam.ViewportSize
        local x, y = size.X/2, size.Y/2
        for _ = 1,3 do
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            task.wait(0.05)
        end

        -- Gõ từ
        for c in word:upper():gmatch(".") do
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[c], false, game)
            task.wait(CONFIG.typingSpeed)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[c], false, game)
        end

        -- Nhấn Enter
        task.wait(0.15)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)
end

-- HÀM GỬI TỪ (CLICK CHUỘT VÀO Ô) ============================================
local function clickLetters(word, objects)
    task.spawn(function()
        local usedIdx = {}
        for i = 1, #word do
            local char = word:sub(i,i):upper()
            for idx, obj in ipairs(objects) do
                if not usedIdx[idx] and obj.Text == char then
                    local pos = obj.AbsolutePosition
                    local size = obj.AbsoluteSize
                    local cx = pos.X + size.X/2
                    local cy = pos.Y + size.Y/2
                    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                    usedIdx[idx] = true
                    task.wait(0.1)
                    break
                end
            end
        end
        -- Gửi bằng Enter (nếu game yêu cầu)
        task.wait(0.2)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)
end

-- CHỌN VÀ GỬI TỪ TỐT NHẤT ====================================================
local function selectAndSendBestWord()
    if not scanBoard() then
        notify("⚠️ Không tìm thấy bảng chữ cái!")
        return
    end

    local wordDict = {}
    for _, w in ipairs(allWords) do
        wordDict[w] = true
    end

    local found = findAllWords(boardMatrix, wordDict)
    if #found == 0 then
        -- Không có từ mới, thông báo và tạm dừng một chút
        notify("😅 Không tìm thấy từ mới nào!")
        return
    end

    -- Sắp xếp: ưu tiên từ dài nhất, nếu bằng thì alphabet
    table.sort(found, function(a, b)
        if #a == #b then
            return a < b
        end
        return #a > #b
    end)

    local best = found[1]
    usedWords[best] = true
    notify("🤖 Tự động: " .. best:upper())

    if CONFIG.autoSubmit then
        if CONFIG.useMouseClick then
            clickLetters(best, letterObjects)
        else
            typeWordKeyboard(best)
        end
    end
end

-- SỰ KIỆN NÚT ================================================================
autoButton.MouseButton1Click:Connect(function()
    autoMode = not autoMode
    if autoMode then
        autoButton.Text = "🟢 TỰ ĐỘNG BẬT"
        autoButton.TextColor3 = Color3.fromRGB(0, 255, 0)
        autoButton.BorderColor3 = Color3.fromRGB(0, 255, 0)
        notify("✅ Chế độ tự động bật")
        -- Chạy ngay lần đầu
        task.spawn(selectAndSendBestWord)
    else
        autoButton.Text = "🔴 TỰ ĐỘNG TẮT"
        autoButton.TextColor3 = Color3.fromRGB(255, 0, 0)
        autoButton.BorderColor3 = Color3.fromRGB(255, 0, 0)
        notify("❌ Chế độ tự động tắt")
    end
end)

trollButton.MouseButton1Click:Connect(function()
    if not scanBoard() then
        notify("⚠️ Không tìm thấy bảng!")
        return
    end
    local wordDict = {}
    for _, w in ipairs(allWords) do wordDict[w] = true end
    local found = findAllWords(boardMatrix, wordDict)
    if #found == 0 then
        notify("😅 Không có từ nào!")
        return
    end
    table.sort(found, function(a,b) return #a > #b end)
    local trollWord = found[1]
    usedWords[trollWord] = true
    notify("😈 TROLL: " .. trollWord:upper())
    if CONFIG.useMouseClick then
        clickLetters(trollWord, letterObjects)
    else
        typeWordKeyboard(trollWord)
    end
end)

resetButton.MouseButton1Click:Connect(function()
    usedWords = {}
    notify("🔄 Đã reset danh sách từ đã dùng")
end)

-- VÒNG LẶP TỰ ĐỘNG ===========================================================
task.spawn(function()
    while task.wait(CONFIG.scanInterval) do
        if autoMode then
            selectAndSendBestWord()
        end
    end
end)

-- KHỞI ĐỘNG ==================================================================
task.spawn(function()
    if loadDictionary() then
        print("[WORD HUNT BATTLE PRO – SẴN SÀNG]")
        notify("🚀 Sẵn sàng! " .. #allWords .. " từ đã tải")
        scanBoard()
    end
end)