--[[
	CHUYỂN THỂ TỪ MEGA WORD SEARCH PRO -> WORD HUNT BATTLE
	- Thay cơ chế lấy chữ từ console sang quét trực tiếp bảng chữ cái trên GUI.
	- Tự động tìm tất cả từ có thể tạo ra từ ma trận, ưu tiên từ dài nhất.
	- Hỗ trợ nhập bằng cách click vào các ô hoặc gõ vào ô nhập (tùy game).
	- Giữ nguyên hệ thống từ điển, GUI điều khiển, phân trang, tự động gõ.
	- Tất cả chú thích bằng tiếng Việt.
--]]

print("[WORD HUNT BATTLE PRO] Đang khởi tạo...")

-- DỊCH VỤ =====================================================================
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- CẤU HÌNH ====================================================================
local CONFIG = {
    typingSpeed = 0.12,              -- Tốc độ gõ (giây/ký tự)
    minLength = 3,                   -- Độ dài từ tối thiểu
    maxLength = 15,                  -- Độ dài từ tối đa
    boardContainerName = "Board",    -- Tên của Frame chứa bảng chữ (có thể thay đổi)
    letterObjectType = "TextLabel",  -- Loại object chứa chữ (TextLabel hoặc TextButton)
    scanInterval = 0.5,              -- Tần suất quét bảng (giây)
    autoSubmit = true,               -- Tự động gửi từ tìm được hay không
}

-- Từ điển bỏ qua (common words)
local commonWords = {
    ["the"] = true, ["and"] = true, ["a"] = true, ["an"] = true,
    ["is"] = true, ["it"] = true, ["to"] = true, ["of"] = true,
    ["in"] = true, ["for"] = true, ["on"] = true, ["with"] = true,
    ["as"] = true, ["at"] = true, ["by"] = true, ["or"] = true,
}

-- URL từ điển (dự phòng)
local DICTIONARY_URLS = {
    "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_dictionary.json",
    "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears.txt"
}

-- BIẾN TOÀN CỤC ===============================================================
local allWords = {}
local usedWords = {}
local lastWordTime = 0
local topWords = {}
local selectedIndex = 1
local currentPage = 1
local currentBoardLetters = {}  -- Ma trận 2D chữ cái hiện tại
local boardDimensions = { rows = 0, cols = 0 }
local autoMode = false          -- Bật/tắt chế độ tự động tìm từ
local bestFoundWord = ""

-- GUI ĐIỀU KHIỂN ==============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WordHuntBattlePro"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local scaleFactor = 0.75
local marginX, marginY = 20, 20

-- Ô nhập (dùng để hiển thị chữ đã chọn hoặc nhập thủ công)
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0, 540 * scaleFactor, 0, 90 * scaleFactor)
searchBox.Position = UDim2.new(1, -540*scaleFactor - marginX, 1, -90*scaleFactor - marginY)
searchBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
searchBox.BorderColor3 = Color3.fromRGB(0, 255, 255)
searchBox.BorderSizePixel = 4
searchBox.TextColor3 = Color3.fromRGB(0, 255, 255)
searchBox.PlaceholderText = "⏳ Đang tải từ điển..."
searchBox.Font = Enum.Font.GothamBold
searchBox.TextSize = 36 * scaleFactor
searchBox.ClearTextOnFocus = false
searchBox.TextEditable = true
searchBox.Parent = screenGui

-- Nút bật/tắt chế độ tự động
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

-- Nút TROLL (chọn từ dài nhất)
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

-- Khung kết quả
local resultsFrame = Instance.new("Frame")
resultsFrame.Size = UDim2.new(0, 540 * scaleFactor, 0, 400 * scaleFactor)
resultsFrame.Position = UDim2.new(1, -540*scaleFactor - marginX, 1, -490*scaleFactor - marginY)
resultsFrame.BackgroundTransparency = 1
resultsFrame.Parent = screenGui

-- Hộp chọn
local selectionBox = Instance.new("Frame")
selectionBox.BackgroundTransparency = 0.5
selectionBox.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
selectionBox.BorderSizePixel = 2
selectionBox.Visible = false
selectionBox.Parent = resultsFrame

-- Mũi tên phân trang
local arrowMargin = 5
local leftArrow = Instance.new("TextButton")
leftArrow.Size = UDim2.new(0, 40*scaleFactor, 0, 40*scaleFactor)
leftArrow.Text = "<"
leftArrow.Font = Enum.Font.GothamBold
leftArrow.TextSize = 32*scaleFactor
leftArrow.BackgroundColor3 = Color3.fromRGB(15,15,15)
leftArrow.TextColor3 = Color3.fromRGB(0,255,150)
leftArrow.Parent = screenGui
leftArrow.Position = UDim2.new(0, searchBox.AbsolutePosition.X, 0, searchBox.AbsolutePosition.Y - 40*scaleFactor - arrowMargin)

local rightArrow = leftArrow:Clone()
rightArrow.Text = ">"
rightArrow.Parent = screenGui
rightArrow.Position = UDim2.new(0, searchBox.AbsolutePosition.X + 50*scaleFactor, 0, searchBox.AbsolutePosition.Y - 40*scaleFactor - arrowMargin)

-- HỆ THỐNG THÔNG BÁO ==========================================================
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
                searchBox.PlaceholderText = "Nhập từ hoặc bật tự động"
                notify("✅ Đã tải từ điển (" .. #allWords .. " từ)")
                return true
            end
        else
            warn("[CẢNH BÁO] Nguồn #" .. i .. " thất bại, thử nguồn khác...")
        end
    end
    warn("[LỖI] Tất cả nguồn từ điển đều thất bại")
    searchBox.PlaceholderText = "❌ Không có từ điển"
    notify("❌ Tải từ điển thất bại")
    return false
end

-- TẠO NHÃN TỪ ================================================================
local function createWordLabel(parent, text, size, offsetY)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, size + 5)
    lbl.Position = UDim2.new(0, 0, 0, offsetY)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(0, 255, 150)
    lbl.Font = Enum.Font.Arcade
    lbl.TextSize = size
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.Text = text
    lbl.Parent = parent
    return lbl
end

-- CHỨC NĂNG GÕ TỰ ĐỘNG ========================================================
local function autoTypeWord(word, currentInput)
    local remaining = word:sub(#currentInput + 1)
    task.spawn(function()
        local cam = workspace.CurrentCamera
        local size = cam.ViewportSize
        local x, y = size.X/2, size.Y/2
        
        -- Click 3 lần để bôi đen (nếu cần)
        for _ = 1,3 do
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            task.wait(0.05)
        end

        -- Gõ các ký tự còn lại
        for c in remaining:upper():gmatch(".") do
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[c], false, game)
            task.wait(CONFIG.typingSpeed)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[c], false, game)
        end

        -- Nhấn Enter để gửi
        task.wait(0.15)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)
end

-- HIỂN THỊ PHÂN TRANG =========================================================
local function displayPage()
    for _, c in ipairs(resultsFrame:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end

    local startIdx = (currentPage-1)*CONFIG.wordsPerPage + 1
    local endIdx = math.min(currentPage*CONFIG.wordsPerPage, #topWords)
    
    for i = startIdx, endIdx do
        local size = (i == startIdx) and 68*scaleFactor or 33*scaleFactor
        local offsetY = (i == startIdx) and 0 or 68*scaleFactor + (i-startIdx-1)*33*scaleFactor
        local lbl = createWordLabel(resultsFrame, topWords[i]:upper(), size, offsetY)

        lbl.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local word = topWords[i]
                if word then
                    usedWords[word] = true
                    notify("✅ Đã chọn: " .. word)
                    autoTypeWord(word, searchBox.Text)
                    searchBox.Text = ""
                    selectionBox.Visible = false
                end
            end
        end)
    end

    if endIdx-startIdx+1 > 0 then
        local firstLabel = resultsFrame:GetChildren()[1]
        if firstLabel and firstLabel:IsA("TextLabel") then
            selectionBox.Position = firstLabel.Position
            selectionBox.Size = firstLabel.Size
            selectionBox.Visible = true
        end
    else
        selectionBox.Visible = false
    end
end

-- HÀM QUÉT BẢNG CHỮ CÁI TỪ GUI ================================================
local function scanBoard()
    -- Tìm container bảng (theo tên cấu hình)
    local boardContainer = playerGui:FindFirstChild(CONFIG.boardContainerName)
    if not boardContainer then
        -- Thử tìm bất kỳ Frame nào có nhiều TextLabel con
        for _, child in ipairs(playerGui:GetChildren()) do
            if child:IsA("Frame") then
                local count = 0
                for _, sub in ipairs(child:GetChildren()) do
                    if sub:IsA(CONFIG.letterObjectType) and #sub.Text == 1 then
                        count = count + 1
                    end
                end
                if count >= 9 then -- Ít nhất 3x3
                    boardContainer = child
                    break
                end
            end
        end
    end
    
    if not boardContainer then
        -- Không tìm thấy bảng
        return false
    end

    -- Lấy tất cả các ô chữ
    local letters = {}
    for _, obj in ipairs(boardContainer:GetChildren()) do
        if obj:IsA(CONFIG.letterObjectType) and #obj.Text == 1 then
            table.insert(letters, {
                char = obj.Text:upper(),
                position = obj.Position,
                object = obj
            })
        end
    end

    if #letters == 0 then return false end

    -- Sắp xếp theo vị trí để tạo ma trận (giả sử bố cục lưới đều nhau)
    table.sort(letters, function(a, b)
        if math.abs(a.position.Y.Offset - b.position.Y.Offset) < 5 then
            return a.position.X.Offset < b.position.X.Offset
        end
        return a.position.Y.Offset < b.position.Y.Offset
    end)

    -- Xác định số hàng và cột (giả định lưới đều)
    local rows, cols = 0, 0
    local yPositions = {}
    for _, l in ipairs(letters) do
        local y = l.position.Y.Offset
        if not yPositions[y] then
            yPositions[y] = true
            rows = rows + 1
        end
    end
    cols = math.floor(#letters / rows)

    -- Xây dựng ma trận
    local matrix = {}
    local idx = 1
    for r = 1, rows do
        local row = {}
        for c = 1, cols do
            if idx <= #letters then
                table.insert(row, letters[idx].char)
                idx = idx + 1
            else
                table.insert(row, "")
            end
        end
        table.insert(matrix, row)
    end

    boardDimensions.rows = rows
    boardDimensions.cols = cols
    currentBoardLetters = matrix
    return true
end

-- THUẬT TOÁN TÌM TỪ TRÊN BẢNG (DFS) ==========================================
local function findWordsOnBoard(matrix, wordsDict)
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

-- CẬP NHẬT TỪ HÀNG ĐẦU DỰA TRÊN CHỮ NHẬP (GIỮ CHỨC NĂNG CŨ) ================
local function updateTopWords(input)
    topWords = {}
    input = input:lower()
    if input == "" then
        selectionBox.Visible = false
        for _, c in ipairs(resultsFrame:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        return
    end

    for _, w in ipairs(allWords) do
        if w:sub(1, #input) == input and w ~= input and not usedWords[w] then
            table.insert(topWords, w)
        end
    end

    table.sort(topWords, function(a, b)
        return #a > #b
    end)

    currentPage = 1
    displayPage()
end

-- TỰ ĐỘNG CHỌN TỪ TỐT NHẤT ====================================================
local function autoSelectBestWord()
    if not scanBoard() then
        notify("⚠️ Không tìm thấy bảng chữ cái!")
        return
    end

    -- Tạo dict nhanh từ allWords
    local wordDict = {}
    for _, w in ipairs(allWords) do
        wordDict[w] = true
    end

    local found = findWordsOnBoard(currentBoardLetters, wordDict)
    if #found == 0 then
        notify("😅 Không tìm thấy từ nào hợp lệ!")
        return
    end

    -- Sắp xếp theo độ dài giảm dần, chọn từ dài nhất chưa dùng
    table.sort(found, function(a, b)
        if #a == #b then
            return a < b
        end
        return #a > #b
    end)

    local bestWord = found[1]
    if bestWord then
        usedWords[bestWord] = true
        bestFoundWord = bestWord
        searchBox.Text = bestWord:upper()
        notify("🤖 Tự động tìm thấy: " .. bestWord:upper())
        if CONFIG.autoSubmit then
            autoTypeWord(bestWord, "")
            searchBox.Text = ""
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
        task.spawn(autoSelectBestWord)
    else
        autoButton.Text = "🔴 TỰ ĐỘNG TẮT"
        autoButton.TextColor3 = Color3.fromRGB(255, 0, 0)
        autoButton.BorderColor3 = Color3.fromRGB(255, 0, 0)
        notify("❌ Chế độ tự động tắt")
    end
end)

trollButton.MouseButton1Click:Connect(function()
    -- Chọn từ dài nhất hiện có trên bảng (có thể dùng lại autoSelectBestWord nhưng ép gửi)
    if not scanBoard() then
        notify("⚠️ Không tìm thấy bảng chữ!")
        return
    end
    local wordDict = {}
    for _, w in ipairs(allWords) do wordDict[w] = true end
    local found = findWordsOnBoard(currentBoardLetters, wordDict)
    if #found == 0 then
        notify("😅 Không có từ nào!")
        return
    end
    table.sort(found, function(a,b) return #a > #b end)
    local trollWord = found[1]
    usedWords[trollWord] = true
    notify("😈 TROLL: " .. trollWord:upper())
    autoTypeWord(trollWord, "")
    searchBox.Text = ""
end)

resetButton.MouseButton1Click:Connect(function()
    usedWords = {}
    lastWordTime = 0
    notify("🔄 Đã reset danh sách từ đã dùng")
    print("[RESET] Đã xóa danh sách đã dùng")
end)

-- PHÂN TRANG
leftArrow.MouseButton1Click:Connect(function()
    if currentPage > 1 then
        currentPage = currentPage - 1
        displayPage()
    end
end)

rightArrow.MouseButton1Click:Connect(function()
    if currentPage < math.ceil(#topWords/CONFIG.wordsPerPage) then
        currentPage = currentPage + 1
        displayPage()
    end
end)

-- SỰ KIỆN TEXTBOX
searchBox.Focused:Connect(function()
    searchBox.Text = ""
    selectionBox.Visible = false
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateTopWords(searchBox.Text)
end)

-- VÒNG LẶP TỰ ĐỘNG QUÉT VÀ TÌM TỪ (nếu bật chế độ) ==========================
task.spawn(function()
    while task.wait(CONFIG.scanInterval) do
        if autoMode then
            autoSelectBestWord()
        end
    end
end)

-- KHỞI ĐỘNG ==================================================================
task.spawn(function()
    if loadDictionary() then
        print("[WORD HUNT BATTLE PRO – SẴN SÀNG]")
        notify("🚀 Sẵn sàng! " .. #allWords .. " từ đã tải")
        -- Thử quét bảng lần đầu
        if scanBoard() then
            print("[THÔNG TIN] Đã phát hiện bảng " .. boardDimensions.rows .. "x" .. boardDimensions.cols)
        else
            print("[CẢNH BÁO] Không tìm thấy bảng, hãy cấu hình CONFIG.boardContainerName")
        end
    end
end)