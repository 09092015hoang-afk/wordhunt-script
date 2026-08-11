local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SIZE = 5

local CONFIG = {
    minLength = 3,
    maxLength = 25,
    scanInterval = 0.5
}

local VIP = true
local autoMode = false
local solving = false

local usedWords = {}

local remotes = ReplicatedStorage:WaitForChild("WordHuntRemotes")
local submitWord = remotes:WaitForChild("SubmitWord")
local getBoard = remotes:WaitForChild("GetBoard")

local directions = {
    {1, 0}, {-1, 0},
    {0, 1}, {0, -1},
    {1, 1}, {1, -1},
    {-1, 1}, {-1, -1}
}

local dictionary = {
    cat = true,
    dog = true,
    game = true,
    word = true,
    hunt = true,
    hello = true,
    world = true
}

local gui = Instance.new("ScreenGui")
gui.Name = "WordHuntVIP"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(240, 145)
frame.Position = UDim2.new(1, -260, 1, -180)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 2
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "👑 WORD HUNT VIP"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 30)
status.Position = UDim2.fromOffset(10, 35)
status.BackgroundTransparency = 1
status.Text = "VIP: ĐANG KIỂM TRA"
status.TextColor3 = Color3.new(1, 1, 1)
status.Font = Enum.Font.Gotham
status.TextSize = 14
status.Parent = frame

local autoButton = Instance.new("TextButton")
autoButton.Size = UDim2.new(1, -20, 0, 35)
autoButton.Position = UDim2.fromOffset(10, 68)
autoButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
autoButton.BorderSizePixel = 2
autoButton.Text = "AUTO: TẮT"
autoButton.TextColor3 = Color3.new(1, 1, 1)
autoButton.Font = Enum.Font.GothamBold
autoButton.TextSize = 15
autoButton.Parent = frame

local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.fromOffset(90, 28)
resetButton.Position = UDim2.fromOffset(10, 108)
resetButton.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
resetButton.BorderSizePixel = 1
resetButton.Text = "RESET"
resetButton.TextColor3 = Color3.new(1, 1, 1)
resetButton.Font = Enum.Font.GothamBold
resetButton.TextSize = 12
resetButton.Parent = frame

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.fromOffset(125, 28)
resultLabel.Position = UDim2.fromOffset(105, 108)
resultLabel.BackgroundTransparency = 1
resultLabel.Text = "Chưa có từ"
resultLabel.TextColor3 = Color3.new(1, 1, 1)
resultLabel.Font = Enum.Font.Gotham
resultLabel.TextSize = 12
resultLabel.Parent = frame

local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Word Hunt VIP",
            Text = text,
            Duration = 2
        })
    end)
end

local function setVIP(value)
    VIP = value

    if VIP then
        status.Text = "VIP: ĐÃ KÍCH HOẠT"
        status.TextColor3 = Color3.fromRGB(0, 255, 120)
    else
        status.Text = "VIP: CHƯA KÍCH HOẠT"
        status.TextColor3 = Color3.fromRGB(255, 80, 80)
        autoMode = false
        autoButton.Text = "AUTO: KHÓA"
    end
end

local function findWords(board)
    local found = {}

    local function dfs(row, col, word, visited)
        if #word > CONFIG.maxLength then
            return
        end

        if #word >= CONFIG.minLength
            and dictionary[word]
            and not usedWords[word] then

            found[word] = true
        end

        for _, direction in ipairs(directions) do
            local nr = row + direction[1]
            local nc = col + direction[2]

            if nr >= 1 and nr <= SIZE
                and nc >= 1 and nc <= SIZE then

                local key = nr .. ":" .. nc

                if not visited[key] then
                    visited[key] = true

                    dfs(
                        nr,
                        nc,
                        word .. board[nr][nc],
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

local function solve()
    if not VIP or not autoMode or solving then
        return
    end

    solving = true

    local ok, board = pcall(function()
        return getBoard:InvokeServer()
    end)

    if not ok or not board then
        solving = false
        return
    end

    local found = findWords(board)

    if #found > 0 then
        local best = found[1]

        usedWords[best] = true
        resultLabel.Text = best:upper()

        submitWord:FireServer(best)
    end

    solving = false
end

autoButton.MouseButton1Click:Connect(function()
    if not VIP then
        notify("Bạn chưa có VIP")
        return
    end

    autoMode = not autoMode
    autoButton.Text = autoMode and "AUTO: BẬT" or "AUTO: TẮT"

    if autoMode then
        notify("VIP Auto đã bật")
    else
        notify("VIP Auto đã tắt")
    end
end)

resetButton.MouseButton1Click:Connect(function()
    usedWords = {}
    resultLabel.Text = "Đã reset"
end)

submitWord.OnClientEvent:Connect(function(result, word, score)
    if result == "Accepted" then
        resultLabel.Text = word:upper() .. " +" .. score
    end
end)

setVIP(true)

autoMode = true
autoButton.Text = "AUTO: BẬT"

notify("VIP Solver sẵn sàng")

task.spawn(function()
    while task.wait(CONFIG.scanInterval) do
        if VIP and autoMode then
            solve()
        end
    end
end)