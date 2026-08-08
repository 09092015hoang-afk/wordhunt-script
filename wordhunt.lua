-- =====================================================
-- WORD HUNT BATTLE - BẢN NÂNG CAO, SỬA LỖI SLIDER & CHỨC NĂNG
-- =====================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- ==================== WORDLIST ====================
local wordLibrary = {}
local wordlistLoaded = false

local function loadWordlist()
    local success, result = pcall(function()
        local raw = game:HttpGet("https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears.txt")
        if raw and #raw > 100 then
            wordLibrary = {}
            for word in string.gmatch(raw, "[%a]+") do
                local w = word:lower()
                if #w >= 3 then wordLibrary[w] = true end
            end
            wordlistLoaded = true
            print("✅ Đã tải " .. #wordLibrary .. " từ")
            return true
        end
        return false
    end)
    if not success or not result then
        local fallback = {
            "the","and","for","are","but","not","you","all","can","had","her","was","one","our","out","day",
            "get","has","him","his","how","its","may","new","now","old","see","two","way","who","boy","did",
            "yet","she","say","too","use","any","big","car","dog","eat","fly","god","hot","ice","job","key",
            "leg","man","net","own","put","run","six","top","use","van","war","yes","zoo","about","above","across",
            "act","active","add","afraid","after","again","age","ago","agree","air","all","alone","along","already",
            "always","am","among","an","animal","another","answer","any","anyone","anything","anywhere","appear"
        }
        for _, w in ipairs(fallback) do
            if #w >= 3 then wordLibrary[w] = true end
        end
        wordlistLoaded = true
        print("⚠️ Dùng wordlist dự phòng (" .. #wordLibrary .. " từ)")
    end
end
loadWordlist()

-- ==================== LẤY BẢNG 5x5 ====================
local function getBoard()
    local gui = player.PlayerGui
    if not gui then
        warn("❌ PlayerGui không tồn tại")
        return nil
    end
    
    local found = {}
    local allObjects = gui:GetDescendants()
    local count = 0
    
    for _, obj in ipairs(allObjects) do
        local isText = obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("ImageButton")
        if isText and obj.Visible then
            local txt = obj.Text
            if txt and #txt == 1 and txt:match("^[A-Za-z]$") then
                local pos = obj.AbsolutePosition
                if pos.X > 0 and pos.Y > 0 then
                    table.insert(found, {
                        letter = txt:upper(),
                        x = pos.X + obj.AbsoluteSize.X/2,
                        y = pos.Y + obj.AbsoluteSize.Y/2,
                        obj = obj
                    })
                    count = count + 1
                end
            end
        end
    end
    
    if count < 9 then
        warn("❌ Chỉ tìm thấy " .. count .. " ô chữ cái (cần >=9)")
        return nil
    end
    
    -- Sắp xếp theo hàng (y) rồi cột (x)
    table.sort(found, function(a, b)
        if math.abs(a.y - b.y) > 10 then
            return a.y < b.y
        else
            return a.x < b.x
        end
    end)
    
    -- Gom thành hàng
    local rows = {}
    local curRow = {found[1]}
    for i = 2, #found do
        if math.abs(found[i].y - found[i-1].y) > 10 then
            table.sort(curRow, function(a, b) return a.x < b.x end)
            table.insert(rows, curRow)
            curRow = {found[i]}
        else
            table.insert(curRow, found[i])
        end
    end
    table.sort(curRow, function(a, b) return a.x < b.x end)
    table.insert(rows, curRow)
    
    if #rows ~= 5 then
        warn("❌ Số hàng: " .. #rows .. " (cần 5)")
        return nil
    end
    for _, r in ipairs(rows) do
        if #r ~= 5 then
            warn("❌ Hàng có " .. #r .. " ô (cần 5)")
            return nil
        end
    end
    
    local grid = {}
    local objects = {}
    for r = 1, 5 do
        grid[r] = {}
        objects[r] = {}
        for c = 1, 5 do
            grid[r][c] = rows[r][c].letter
            objects[r][c] = rows[r][c].obj
        end
    end
    
    print("✅ Đã tìm thấy bảng 5x5")
    return grid, objects
end

-- ==================== DFS TÌM TỪ DÀI NHẤT ====================
local function findLongestWordPath(grid)
    local dirs = {
        {-1, -1}, {-1, 0}, {-1, 1},
        {0, -1},           {0, 1},
        {1, -1},  {1, 0},  {1, 1}
    }
    local bestPath = {}
    local bestWord = ""
    
    local function dfs(r, c, visited, path, word)
        if #path > 8 then return end
        local w = table.concat(word)
        if #w >= 3 and wordLibrary[w] and #w > #bestWord then
            bestWord = w
            bestPath = {table.unpack(path)}
        end
        for _, d in ipairs(dirs) do
            local nr, nc = r + d[1], c + d[2]
            if nr >= 1 and nr <= 5 and nc >= 1 and nc <= 5 and not visited[nr][nc] then
                visited[nr][nc] = true
                table.insert(path, {nr, nc})
                table.insert(word, grid[nr][nc])
                dfs(nr, nc, visited, path, word)
                table.remove(word)
                table.remove(path)
                visited[nr][nc] = false
            end
        end
    end
    
    for r = 1, 5 do
        for c = 1, 5 do
            local visited = {}
            for i = 1, 5 do visited[i] = {} end
            visited[r][c] = true
            dfs(r, c, visited, {{r, c}}, {grid[r][c]})
        end
    end
    
    return bestPath, bestWord
end

-- ==================== TẠO UI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WordHuntUI"
screenGui.Parent = player.PlayerGui
screenGui.ResetOnSpawn = false

-- Nút toggle
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 44, 0, 44)
toggleBtn.Position = UDim2.new(0, 10, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.Text = "🧩"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = screenGui
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 12)
toggleCorner.Parent = toggleBtn

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 400)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Parent = screenGui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 34)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 45, 65)
titleBar.BackgroundTransparency = 0.25
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -35, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🔤 WORD HUNT"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -32, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BackgroundTransparency = 0.4
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Kéo thả UI
local dragData = {startPos = nil, startMouse = nil}
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragData.startMouse = input.Position
        dragData.startPos = mainFrame.Position
    end
end)
titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragData.startMouse then
        local delta = input.Position - dragData.startMouse
        mainFrame.Position = UDim2.new(
            dragData.startPos.X.Scale, dragData.startPos.X.Offset + delta.X,
            dragData.startPos.Y.Scale, dragData.startPos.Y.Offset + delta.Y
        )
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragData.startMouse = nil
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- ==================== HÀM TẠO LABEL ====================
local function createLabel(parent, text, y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -18, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

-- ==================== SLIDER CỰC KỲ ỔN ĐỊNH ====================
local function createSlider(parent, y, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 26)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0.6, 0, 1, 0)
    slider.Position = UDim2.new(0, 0, 0, 0)
    slider.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    slider.BorderSizePixel = 0
    slider.Parent = frame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
    fill.BorderSizePixel = 0
    fill.Parent = slider

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.Parent = slider
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.35, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.65, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.Parent = frame

    local currentVal = default
    local dragging = false
    local dragConnection = nil

    local function update(val)
        val = math.clamp(val, min, max)
        currentVal = val
        local ratio = (val - min) / (max - min)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, -8, 0.5, -8)
        valueLabel.Text = string.format("%.1f", val)
        callback(val)
    end

    update(default)

    local function startDrag()
        if dragging then return end
        dragging = true
        if dragConnection then dragConnection:Disconnect() end
        dragConnection = RunService.Heartbeat:Connect(function()
            if not dragging then return end
            local mousePos = UserInputService:GetMouseLocation()
            local sliderPos = slider.AbsolutePosition
            local sliderSize = slider.AbsoluteSize
            if sliderSize.X <= 0 then return end
            local raw = (mousePos.X - sliderPos.X) / sliderSize.X
            local val = min + math.clamp(raw, 0, 1) * (max - min)
            update(val)
        end)
    end

    local function stopDrag()
        dragging = false
        if dragConnection then
            dragConnection:Disconnect()
            dragConnection = nil
        end
    end

    knob.MouseButton1Down:Connect(startDrag)
    knob.MouseButton1Up:Connect(stopDrag)
    knob.MouseLeave:Connect(function()
        if dragging then stopDrag() end
    end)

    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local sliderPos = slider.AbsolutePosition
            local sliderSize = slider.AbsoluteSize
            if sliderSize.X <= 0 then return end
            local raw = (mousePos.X - sliderPos.X) / sliderSize.X
            local val = min + math.clamp(raw, 0, 1) * (max - min)
            update(val)
            startDrag()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging then stopDrag() end
        end
    end)

    return update
end

-- ==================== BIẾN TRẠNG THÁI ====================
local arrowColor = Color3.fromRGB(255, 200, 50)
local arrowTransparency = 0.25
local arrowThickness = 4
local arrowBrightness = 1
local autoSpeed = 0.3
local autoRunning = false
local suggestMode = false
local currentSuggestion = {}
local stepIndex = 0
local arrowObjects = {}
local suggestionConnection = nil

-- ==================== VẼ MŨI TÊN ====================
local function clearArrows()
    for _, obj in ipairs(arrowObjects) do
        obj:Destroy()
    end
    arrowObjects = {}
end

local function drawArrow(fromObj, toObj, color, transp, thickness, bright)
    if not fromObj or not toObj then
        return
    end
    clearArrows()
    
    local fromPos = fromObj.AbsolutePosition + fromObj.AbsoluteSize / 2
    local toPos = toObj.AbsolutePosition + toObj.AbsoluteSize / 2
    local dx = toPos.X - fromPos.X
    local dy = toPos.Y - fromPos.Y
    local angle = math.atan2(dy, dx)
    local length = math.sqrt(dx * dx + dy * dy)
    
    if length < 5 then return end
    
    -- Vẽ đường thẳng
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0, length, 0, thickness)
    line.Position = UDim2.new(0, fromPos.X, 0, fromPos.Y - thickness / 2)
    line.Rotation = math.deg(angle)
    line.BackgroundColor3 = color * bright
    line.BackgroundTransparency = transp
    line.BorderSizePixel = 0
    line.Parent = screenGui
    table.insert(arrowObjects, line)
    
    -- Vẽ mũi tên (hình tam giác)
    local tipSize = 14
    local tip = Instance.new("Frame")
    tip.Size = UDim2.new(0, tipSize, 0, tipSize)
    tip.Position = UDim2.new(0, toPos.X - tipSize / 2, 0, toPos.Y - tipSize / 2)
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

-- ==================== CHỨC NĂNG GỢI Ý ====================
local function startSuggestion(path, word)
    if not path or #path < 2 then
        print("❌ Đường đi không hợp lệ")
        return
    end
    
    if suggestMode then
        clearArrows()
        if suggestionConnection then
            suggestionConnection:Disconnect()
            suggestionConnection = nil
        end
        suggestMode = false
    end
    
    suggestMode = true
    stepIndex = 1
    currentSuggestion = path
    
    local grid, objects = getBoard()
    if not grid then
        print("❌ Không tìm thấy bảng")
        suggestMode = false
        return
    end
    
    local function getObjectAt(r, c)
        if objects and objects[r] and objects[r][c] then
            return objects[r][c]
        end
        return nil
    end
    
    local function updateArrow()
        clearArrows()
        if stepIndex < #currentSuggestion then
            local r1, c1 = currentSuggestion[stepIndex][1], currentSuggestion[stepIndex][2]
            local r2, c2 = currentSuggestion[stepIndex + 1][1], currentSuggestion[stepIndex + 1][2]
            local obj1 = getObjectAt(r1, c1)
            local obj2 = getObjectAt(r2, c2)
            if obj1 and obj2 then
                drawArrow(obj1, obj2, arrowColor, arrowTransparency, arrowThickness, arrowBrightness)
                print("👉 Mũi tên từ ô (" .. r1 .. "," .. c1 .. ") đến (" .. r2 .. "," .. c2 .. ")")
            else
                print("⚠️ Không tìm thấy đối tượng tại ô (" .. r1 .. "," .. c1 .. ") hoặc (" .. r2 .. "," .. c2 .. ")")
            end
        else
            print("✅ Đã hoàn thành từ: " .. word)
        end
    end
    
    updateArrow()
    
    if suggestionConnection then
        suggestionConnection:Disconnect()
        suggestionConnection = nil
    end
    
    suggestionConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not suggestMode then return end
        if stepIndex >= #currentSuggestion then return end
        
        local mousePos = input.Position
        local r1, c1 = currentSuggestion[stepIndex][1], currentSuggestion[stepIndex][2]
        local obj = getObjectAt(r1, c1)
        
        if obj then
            local pos = obj.AbsolutePosition
            local size = obj.AbsoluteSize
            if mousePos.X >= pos.X and mousePos.X <= pos.X + size.X and
               mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y then
                stepIndex = stepIndex + 1
                print("✅ Đã bấm ô (" .. r1 .. "," .. c1 .. ") - Bước " .. stepIndex .. "/" .. #currentSuggestion)
                
                if stepIndex >= #currentSuggestion then
                    suggestMode = false
                    clearArrows()
                    suggestionConnection:Disconnect()
                    suggestionConnection = nil
                    print("🎉 HOÀN THÀNH TỪ: " .. word)
                else
                    updateArrow()
                end
            end
        end
    end)
end

-- ==================== CHỨC NĂNG TỰ ĐỘNG ====================
local function startAuto(path, word)
    if not path or #path < 2 then
        print("❌ Đường đi không hợp lệ")
        return
    end
    
    if autoRunning then
        autoRunning = false
        clearArrows()
        if suggestionConnection then
            suggestionConnection:Disconnect()
            suggestionConnection = nil
        end
        suggestMode = false
        print("⏹️ Dừng tự động")
        return
    end
    
    autoRunning = true
    local grid, objects = getBoard()
    if not grid then
        autoRunning = false
        print("❌ Không tìm thấy bảng")
        return
    end
    
    local function getObjectAt(r, c)
        if objects and objects[r] and objects[r][c] then
            return objects[r][c]
        end
        return nil
    end
    
    local index = 1
    
    local function clickNext()
        if not autoRunning or index > #path then
            autoRunning = false
            clearArrows()
            print("✅ Tự động hoàn thành: " .. word)
            return
        end
        
        local r, c = path[index][1], path[index][2]
        local obj = getObjectAt(r, c)
        if obj then
            local pos = obj.AbsolutePosition + obj.AbsoluteSize / 2
            UserInputService:SendMouseButtonEvent(pos.X, pos.Y, 0, true, 1)
            task.wait(0.06)
            UserInputService:SendMouseButtonEvent(pos.X, pos.Y, 0, false, 1)
            print("🖱️ Đã click ô (" .. r .. "," .. c .. ") - Bước " .. index .. "/" .. #path)
            
            index = index + 1
            
            if index <= #path then
                local r1, c1 = path[index - 1][1], path[index - 1][2]
                local r2, c2 = path[index][1], path[index][2]
                local obj1 = getObjectAt(r1, c1)
                local obj2 = getObjectAt(r2, c2)
                if obj1 and obj2 then
                    clearArrows()
                    drawArrow(obj1, obj2, arrowColor, arrowTransparency, arrowThickness, arrowBrightness)
                end
                task.wait(autoSpeed)
                clickNext()
            else
                clearArrows()
                autoRunning = false
                print("✅ Tự động hoàn thành: " .. word)
            end
        else
            print("❌ Không tìm thấy đối tượng tại ô (" .. r .. "," .. c .. ")")
            autoRunning = false
            clearArrows()
        end
    end
    
    if #path >= 2 then
        local r1, c1 = path[1][1], path[1][2]
        local r2, c2 = path[2][1], path[2][2]
        local obj1 = getObjectAt(r1, c1)
        local obj2 = getObjectAt(r2, c2)
        if obj1 and obj2 then
            drawArrow(obj1, obj2, arrowColor, arrowTransparency, arrowThickness, arrowBrightness)
        end
    end
    
    task.wait(0.4)
    clickNext()
end

-- ==================== XÂY DỰNG UI ĐIỀU KHIỂN ====================
local yPos = 38

-- Nút Gợi ý và Tự động
local suggestBtn = Instance.new("TextButton")
suggestBtn.Size = UDim2.new(0.43, -8, 0, 32)
suggestBtn.Position = UDim2.new(0.04, 0, 0, yPos)
suggestBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 255)
suggestBtn.Text = "🔍 GỢI Ý"
suggestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
suggestBtn.TextScaled = true
suggestBtn.Font = Enum.Font.GothamBold
suggestBtn.BorderSizePixel = 0
suggestBtn.Parent = mainFrame
local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0, 8)
sCorner.Parent = suggestBtn

local autoBtn = Instance.new("TextButton")
autoBtn.Size = UDim2.new(0.43, -8, 0, 32)
autoBtn.Position = UDim2.new(0.53, 0, 0, yPos)
autoBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
autoBtn.Text = "⚡ TỰ ĐỘNG"
autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
autoBtn.TextScaled = true
autoBtn.Font = Enum.Font.GothamBold
autoBtn.BorderSizePixel = 0
autoBtn.Parent = mainFrame
local aCorner = Instance.new("UICorner")
aCorner.CornerRadius = UDim.new(0, 8)
aCorner.Parent = autoBtn

yPos = yPos + 38

-- Các slider
createLabel(mainFrame, "⚡ Tốc độ (giây/bước)", yPos)
yPos = yPos + 22
local speedUpdate = createSlider(mainFrame, yPos, 0.1, 1.0, 0.3, function(val)
    autoSpeed = val
end)
yPos = yPos + 32

createLabel(mainFrame, "🎨 Màu mũi tên", yPos)
yPos = yPos + 22
local colorUpdate = createSlider(mainFrame, yPos, 0, 1, 0.5, function(val)
    arrowColor = Color3.fromHSV(val, 0.8, 0.8)
end)
yPos = yPos + 32

createLabel(mainFrame, "👁️ Độ mờ", yPos)
yPos = yPos + 22
local transpUpdate = createSlider(mainFrame, yPos, 0, 0.8, 0.25, function(val)
    arrowTransparency = val
end)
yPos = yPos + 32

createLabel(mainFrame, "☀️ Độ sáng", yPos)
yPos = yPos + 22
local brightUpdate = createSlider(mainFrame, yPos, 0.2, 1.0, 1.0, function(val)
    arrowBrightness = val
end)
yPos = yPos + 32

createLabel(mainFrame, "📏 Độ dày", yPos)
yPos = yPos + 22
local thickUpdate = createSlider(mainFrame, yPos, 1, 6, 4, function(val)
    arrowThickness = val
end)

-- ==================== XỬ LÝ SỰ KIỆN NÚT ====================
suggestBtn.MouseButton1Click:Connect(function()
    if autoRunning then
        print("⚠️ Đang chạy tự động, hãy dừng trước")
        return
    end
    
    print("🔍 Đang tìm bảng 5x5...")
    local grid, objects = getBoard()
    if not grid then
        print("❌ Không tìm thấy bảng 5x5")
        return
    end
    
    print("🔍 Đang tìm từ dài nhất...")
    local path, word = findLongestWordPath(grid)
    if not path or #path < 2 then
        print("❌ Không tìm thấy từ nào")
        return
    end
    
    print("✅ Tìm thấy: " .. word .. " (" .. #path .. " ô)")
    startSuggestion(path, word)
end)

autoBtn.MouseButton1Click:Connect(function()
    if autoRunning then
        autoRunning = false
        clearArrows()
        if suggestionConnection then
            suggestionConnection:Disconnect()
            suggestionConnection = nil
        end
        suggestMode = false
        print("⏹️ Dừng tự động")
        return
    end
    
    print("🔍 Đang tìm bảng 5x5...")
    local grid, objects = getBoard()
    if not grid then
        print("❌ Không tìm thấy bảng 5x5")
        return
    end
    
    print("🔍 Đang tìm từ dài nhất...")
    local path, word = findLongestWordPath(grid)
    if not path or #path < 2 then
        print("❌ Không tìm thấy từ nào")
        return
    end
    
    print("✅ Bắt đầu tự động: " .. word)
    startAuto(path, word)
end)

-- ==================== NÚT DEBUG KIỂM TRA BẢNG ====================
local debugBtn = Instance.new("TextButton")
debugBtn.Size = UDim2.new(0.2, 0, 0, 22)
debugBtn.Position = UDim2.new(0.04, 0, 0, yPos + 8)
debugBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
debugBtn.Text = "🔎 Test"
debugBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
debugBtn.TextScaled = true
debugBtn.Font = Enum.Font.GothamBold
debugBtn.BorderSizePixel = 0
debugBtn.Parent = mainFrame
local dCorner = Instance.new("UICorner")
dCorner.CornerRadius = UDim.new(0, 6)
dCorner.Parent = debugBtn

debugBtn.MouseButton1Click:Connect(function()
    print("=== KIỂM TRA BẢNG ===")
    local grid, objects = getBoard()
    if grid then
        print("✅ Bảng 5x5 tìm thấy:")
        for r = 1, 5 do
            local row = ""
            for c = 1, 5 do
                row = row .. grid[r][c] .. " "
            end
            print(row)
        end
        print("🔍 Đang tìm từ...")
        local path, word = findLongestWordPath(grid)
        if path and #path >= 2 then
            print("✅ Tìm thấy từ: " .. word)
        else
            print("❌ Không tìm thấy từ nào")
        end
    else
        print("❌ Không tìm thấy bảng 5x5")
    end
end)

print("✅ UI đã sẵn sàng!")
print("📌 Nhấn nút 🧩 để mở/đóng UI")
print("📌 Vào trận, nhấn 'GỢI Ý' để xem đường đi")
print("📌 Nhấn 'TỰ ĐỘNG' để tự động nối từ")
print("📌 Nút 'Test' để kiểm tra bảng và từ")