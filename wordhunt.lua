local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local wordLibrary = {}

local function loadWordlist()
    local success, result = pcall(function()
        local raw = game:HttpGet("https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears.txt")
        if raw and #raw > 100 then
            wordLibrary = {}
            for word in string.gmatch(raw, "[%a]+") do
                local w = word:lower()
                if #w >= 3 then wordLibrary[w] = true end
            end
            print("✅ Da tai " .. #wordLibrary .. " tu")
            return true
        end
        return false
    end)
    if not success or not result then
        local fallback = {"the","and","for","are","but","not","you","all","can","had","her","was","one","our","out","day","get","has","him","his","how","its","may","new","now","old","see","two","way","who","boy","did","yet","she","say","too","use"}
        for _, w in ipairs(fallback) do
            if #w >= 3 then wordLibrary[w] = true end
        end
        print("⚠️ Dung wordlist du phong (" .. #wordLibrary .. " tu)")
    end
end

local function getBoard()
    local gui = player and player.PlayerGui
    if not gui then return nil end
    local allText = {}
    for _, obj in ipairs(gui:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
            local text = obj.Text
            if text and #text == 1 and text:match("^[A-Za-z]$") then
                local pos = obj.AbsolutePosition
                if pos.X > 0 and pos.Y > 0 then
                    table.insert(allText, {letter = text:upper(), x = pos.X + obj.AbsoluteSize.X/2, y = pos.Y + obj.AbsoluteSize.Y/2, obj = obj})
                end
            end
        end
    end
    if #allText < 9 then return nil end
    table.sort(allText, function(a,b)
        if math.abs(a.y - b.y) > 10 then return a.y < b.y else return a.x < b.x end
    end)
    local rows = {}
    local curRow = {allText[1]}
    for i = 2, #allText do
        if math.abs(allText[i].y - allText[i-1].y) > 10 then
            table.sort(curRow, function(a,b) return a.x < b.x end)
            table.insert(rows, curRow)
            curRow = {allText[i]}
        else
            table.insert(curRow, allText[i])
        end
    end
    table.sort(curRow, function(a,b) return a.x < b.x end)
    table.insert(rows, curRow)
    if #rows ~= 5 then return nil end
    for _, r in ipairs(rows) do if #r ~= 5 then return nil end end
    local grid = {}
    for r=1,5 do grid[r] = {} end
    for r=1,5 do for c=1,5 do grid[r][c] = rows[r][c].letter end end
    return grid, rows
end

local function findLongestWordPath(grid)
    local dirs = {{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}}
    local bestPath, bestWord = {}, ""
    local function dfs(r,c,visited,path,word)
        if #path > 8 then return end
        local w = table.concat(word)
        if #w >= 3 and wordLibrary[w] and #w > #bestWord then
            bestWord = w
            bestPath = {table.unpack(path)}
        end
        for _, d in ipairs(dirs) do
            local nr, nc = r+d[1], c+d[2]
            if nr>=1 and nr<=5 and nc>=1 and nc<=5 and not visited[nr][nc] then
                visited[nr][nc] = true
                table.insert(path, {nr,nc})
                table.insert(word, grid[nr][nc])
                dfs(nr,nc,visited,path,word)
                table.remove(word)
                table.remove(path)
                visited[nr][nc] = false
            end
        end
    end
    for r=1,5 do for c=1,5 do
        local visited = {}
        for i=1,5 do visited[i] = {} end
        visited[r][c] = true
        dfs(r,c,visited,{{r,c}},{grid[r][c]})
    end end
    return bestPath, bestWord
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WordHuntUI"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 460)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -230)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🧩 WORD HUNT BATTLE"
titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BackgroundTransparency = 0.7
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local drag = {startPos = nil, startMouse = nil}
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag.startMouse = input.Position
        drag.startPos = mainFrame.Position
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and drag.startMouse then
        local delta = input.Position - drag.startMouse
        mainFrame.Position = UDim2.new(drag.startPos.X.Scale, drag.startPos.X.Offset + delta.X, drag.startPos.Y.Scale, drag.startPos.Y.Offset + delta.Y)
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        drag.startMouse = nil
    end
end)

local function createLabel(parent, text, y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 24)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220,220,230)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function createSlider(parent, y, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 28)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0.7, 0, 1, 0)
    slider.Position = UDim2.new(0.15, 0, 0, 0)
    slider.BackgroundColor3 = Color3.fromRGB(80,80,100)
    slider.BorderSizePixel = 0
    slider.Parent = frame
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    fill.BorderSizePixel = 0
    fill.Parent = slider
    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.Parent = slider
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.15, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.85, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(255,255,255)
    valueLabel.TextScaled = true
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.Parent = frame
    local function update(val)
        val = math.clamp(val, min, max)
        local ratio = (val - min) / (max - min)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, -8, 0.5, -8)
        valueLabel.Text = string.format("%.1f", val)
        callback(val)
    end
    update(default)
    knob.MouseButton1Down:Connect(function()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local mousePos = UserInputService:GetMouseLocation()
            local framePos = slider.AbsolutePosition
            local frameSize = slider.AbsoluteSize
            local raw = (mousePos.X - framePos.X) / frameSize.X
            local val = min + math.clamp(raw, 0, 1) * (max - min)
            update(val)
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
            end
        end)
    end)
    return update
end

local arrowColor = Color3.fromRGB(255, 200, 50)
local arrowTransparency = 0.3
local arrowThickness = 3
local arrowBrightness = 1
local autoSpeed = 0.3
local autoRunning = false
local suggestMode = false
local currentSuggestion = {}
local stepIndex = 0
local arrowObjects = {}

local function clearArrows()
    for _, obj in ipairs(arrowObjects) do obj:Destroy() end
    arrowObjects = {}
end

local function drawArrow(fromObj, toObj, color, transp, thickness, bright)
    if not fromObj or not toObj then return end
    clearArrows()
    local fromPos = fromObj.AbsolutePosition + fromObj.AbsoluteSize/2
    local toPos = toObj.AbsolutePosition + toObj.AbsoluteSize/2
    local dx, dy = toPos.X - fromPos.X, toPos.Y - fromPos.Y
    local angle = math.atan2(dy, dx)
    local length = math.sqrt(dx*dx + dy*dy)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, length, 0, thickness)
    line.Position = UDim2.new(0, fromPos.X, 0, fromPos.Y - thickness/2)
    line.Rotation = math.deg(angle)
    line.BackgroundColor3 = color * bright
    line.BackgroundTransparency = transp
    line.BorderSizePixel = 0
    line.Parent = screenGui
    table.insert(arrowObjects, line)
    local tipSize = 12
    local tip = Instance.new("Frame")
    tip.Size = UDim2.new(0, tipSize, 0, tipSize)
    tip.Position = UDim2.new(0, toPos.X - tipSize/2, 0, toPos.Y - tipSize/2)
    tip.Rotation = math.deg(angle) + 45
    tip.BackgroundColor3 = color * bright
    tip.BackgroundTransparency = transp
    tip.BorderSizePixel = 0
    tip.Parent = screenGui
    local tipCorner = Instance.new("UICorner")
    tipCorner.CornerRadius = UDim.new(0, 2)
    tipCorner.Parent = tip
    table.insert(arrowObjects, tip)
end

local function startSuggestion(path, word)
    if not path or #path < 2 then return end
    suggestMode = true
    stepIndex = 1
    currentSuggestion = path
    local grid, objects = getBoard()
    if not grid then suggestMode = false return end
    local function getObjectAt(r,c)
        if objects and objects[r] and objects[r][c] then
            return objects[r][c].obj
        end
        return nil
    end
    local function updateArrow()
        clearArrows()
        if stepIndex < #currentSuggestion then
            local r1,c1 = currentSuggestion[stepIndex][1], currentSuggestion[stepIndex][2]
            local r2,c2 = currentSuggestion[stepIndex+1][1], currentSuggestion[stepIndex+1][2]
            local obj1 = getObjectAt(r1,c1)
            local obj2 = getObjectAt(r2,c2)
            if obj1 and obj2 then
                drawArrow(obj1, obj2, arrowColor, arrowTransparency, arrowThickness, arrowBrightness)
            end
        end
    end
    updateArrow()
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local r1,c1 = currentSuggestion[stepIndex][1], currentSuggestion[stepIndex][2]
            local obj = getObjectAt(r1,c1)
            if obj then
                local pos = obj.AbsolutePosition
                local size = obj.AbsoluteSize
                if mousePos.X >= pos.X and mousePos.X <= pos.X + size.X and mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y then
                    stepIndex = stepIndex + 1
                    if stepIndex >= #currentSuggestion then
                        suggestMode = false
                        clearArrows()
                        connection:Disconnect()
                        print("✅ " .. word)
                    else
                        updateArrow()
                    end
                end
            end
        end
    end)
end

local function startAuto(path, word)
    if not path or #path < 2 then return end
    autoRunning = true
    local grid, objects = getBoard()
    if not grid then autoRunning = false return end
    local function getObjectAt(r,c)
        if objects and objects[r] and objects[r][c] then
            return objects[r][c].obj
        end
        return nil
    end
    local index = 1
    local function clickNext()
        if not autoRunning or index > #path then
            autoRunning = false
            clearArrows()
            print("✅ Auto done: " .. word)
            return
        end
        local r,c = path[index][1], path[index][2]
        local obj = getObjectAt(r,c)
        if obj then
            local pos = obj.AbsolutePosition + obj.AbsoluteSize/2
            UserInputService:SendMouseButtonEvent(pos.X, pos.Y, 0, true, 1)
            task.wait(0.05)
            UserInputService:SendMouseButtonEvent(pos.X, pos.Y, 0, false, 1)
            index = index + 1
            if index <= #path then
                local r1,c1 = path[index-1][1], path[index-1][2]
                local r2,c2 = path[index][1], path[index][2]
                local obj1 = getObjectAt(r1,c1)
                local obj2 = getObjectAt(r2,c2)
                if obj1 and obj2 then
                    clearArrows()
                    drawArrow(obj1, obj2, arrowColor, arrowTransparency, arrowThickness, arrowBrightness)
                end
                task.wait(autoSpeed)
                clickNext()
            else
                clearArrows()
                autoRunning = false
                print("✅ Auto done: " .. word)
            end
        end
    end
    if #path >= 2 then
        local r1,c1 = path[1][1], path[1][2]
        local r2,c2 = path[2][1], path[2][2]
        local obj1 = getObjectAt(r1,c1)
        local obj2 = getObjectAt(r2,c2)
        if obj1 and obj2 then
            drawArrow(obj1, obj2, arrowColor, arrowTransparency, arrowThickness, arrowBrightness)
        end
    end
    task.wait(0.3)
    clickNext()
end

loadWordlist()

local yPos = 45

local suggestBtn = Instance.new("TextButton")
suggestBtn.Size = UDim2.new(0.4, -10, 0, 32)
suggestBtn.Position = UDim2.new(0.05, 0, 0, yPos)
suggestBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
suggestBtn.Text = "🔍 Gợi ý"
suggestBtn.TextColor3 = Color3.fromRGB(255,255,255)
suggestBtn.TextScaled = true
suggestBtn.Font = Enum.Font.GothamBold
suggestBtn.BorderSizePixel = 0
suggestBtn.Parent = mainFrame
local suggestCorner = Instance.new("UICorner")
suggestCorner.CornerRadius = UDim.new(0, 8)
suggestCorner.Parent = suggestBtn

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0.4, -10, 0, 32)
autoBtn.Position = UDim2.new(0.55, 0, 0, yPos)
autoBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
autoBtn.Text = "⚡ Tự động"
autoBtn.TextColor3 = Color3.fromRGB(255,255,255)
autoBtn.TextScaled = true
autoBtn.Font = Enum.Font.GothamBold
autoBtn.BorderSizePixel = 0
autoBtn.Parent = mainFrame
local autoCorner = Instance.new("UICorner")
autoCorner.CornerRadius = UDim.new(0, 8)
autoCorner.Parent = autoBtn

yPos = yPos + 40

createLabel(mainFrame, "⚡ Tốc độ nối (giây/bước)", yPos)
yPos = yPos + 24
local speedUpdate = createSlider(mainFrame, yPos, 0.1, 1.0, 0.3, function(val) autoSpeed = val end)
yPos = yPos + 36

createLabel(mainFrame, "🎨 Màu mũi tên", yPos)
yPos = yPos + 24
local colorUpdate = createSlider(mainFrame, yPos, 0, 1, 0.5, function(val) arrowColor = Color3.fromHSV(val, 0.8, 0.8) end)
yPos = yPos + 36

createLabel(mainFrame, "👁️ Độ mờ", yPos)
yPos = yPos + 24
local transpUpdate = createSlider(mainFrame, yPos, 0, 0.8, 0.3, function(val) arrowTransparency = val end)
yPos = yPos + 36

createLabel(mainFrame, "☀️ Độ sáng", yPos)
yPos = yPos + 24
local brightUpdate = createSlider(mainFrame, yPos, 0.2, 1.0, 1.0, function(val) arrowBrightness = val end)
yPos = yPos + 36

createLabel(mainFrame, "📏 Độ dày", yPos)
yPos = yPos + 24
local thickUpdate = createSlider(mainFrame, yPos, 1, 6, 3, function(val) arrowThickness = val end)

suggestBtn.MouseButton1Click:Connect(function()
    if autoRunning then return end
    local grid, objects = getBoard()
    if not grid then print("❌ Không tìm thấy bảng 5x5") return end
    local path, word = findLongestWordPath(grid)
    if not path or #path < 2 then
        print("❌ Không tìm thấy từ nào")
        return
    end
    print("✅ " .. word .. " (" .. #path .. " ô)")
    startSuggestion(path, word)
end)

autoBtn.MouseButton1Click:Connect(function()
    if autoRunning then
        autoRunning = false
        clearArrows()
        print("⏹️ Dừng")
        return
    end
    local grid, objects = getBoard()
    if not grid then print("❌ Không tìm thấy bảng 5x5") return end
    local path, word = findLongestWordPath(grid)
    if not path or #path < 2 then
        print("❌ Không tìm thấy từ nào")
        return
    end
    print("✅ Auto: " .. word)
    startAuto(path, word)
end)

print("✅ UI ready")
