local player = game:GetService("Players").LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui")
if not playerGui then
    playerGui = Instance.new("PlayerGui")
    playerGui.Parent = player
end

local oldGui = playerGui:FindFirstChild("WordHuntGUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WordHuntGUI"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 480)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = MainFrame
MainFrame.Parent = screenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "WORD HUNT 5x5"
Title.TextColor3 = Color3.fromRGB(255, 200, 100)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.TextScaled = true
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 35, 0, 35)
MinimizeBtn.Position = UDim2.new(1, -80, 0, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.TextScaled = true
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = MainFrame

local GridFrame = Instance.new("Frame")
GridFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
GridFrame.Position = UDim2.new(0.05, 0, 0.12, 0)
GridFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
GridFrame.BackgroundTransparency = 0.4
local gridCorner = Instance.new("UICorner")
gridCorner.CornerRadius = UDim.new(0, 8)
gridCorner.Parent = GridFrame
GridFrame.Parent = MainFrame

local Grid = {}
local Cells = {}
for i = 1, 5 do
    Grid[i] = {}
    for j = 1, 5 do
        local box = Instance.new("TextBox")
        local size = 60
        local spacing = 10
        box.Size = UDim2.new(0, size, 0, size)
        box.Position = UDim2.new(0, (j-1)*(size+spacing) + spacing, 0, (i-1)*(size+spacing) + spacing)
        box.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
        box.BackgroundTransparency = 0.2
        box.BorderSizePixel = 0
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 6)
        boxCorner.Parent = box
        box.TextColor3 = Color3.fromRGB(51, 51, 51)
        box.Text = ""
        box.PlaceholderText = "?"
        box.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
        box.Font = Enum.Font.GothamBold
        box.TextSize = 32
        box.ClipsDescendants = true
        box.Parent = GridFrame
        table.insert(Cells, box)
        Grid[i][j] = ""
        
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local val = string.sub(box.Text, 1, 1):upper()
            if val:match("%a") then
                Grid[i][j] = val:lower()
                box.Text = val
                box.TextColor3 = Color3.fromRGB(200, 200, 200)
            else
                Grid[i][j] = ""
                box.Text = ""
                box.TextColor3 = Color3.fromRGB(51, 51, 51)
            end
        end)
    end
end

local CalcBtn = Instance.new("TextButton")
CalcBtn.Size = UDim2.new(0.8, 0, 0, 40)
CalcBtn.Position = UDim2.new(0.1, 0, 0.86, 0)
CalcBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
CalcBtn.Text = "▶ TÍNH TOÁN"
CalcBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CalcBtn.TextScaled = true
CalcBtn.Font = Enum.Font.GothamBold
local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = CalcBtn
CalcBtn.Parent = MainFrame

local ResultFrame = Instance.new("ScrollingFrame")
ResultFrame.Size = UDim2.new(0.9, 0, 0.45, 0)
ResultFrame.Position = UDim2.new(0.05, 0, 0.12, 0)
ResultFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
ResultFrame.BackgroundTransparency = 0.4
ResultFrame.BorderSizePixel = 0
ResultFrame.Visible = false
local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 8)
resultCorner.Parent = ResultFrame
ResultFrame.Parent = MainFrame

local WordList = {}
local fallback = {
    "ace","act","add","age","ago","aid","aim","air","all","and","ant","any","ape","arc","are","ark","arm","art","ash","ask","ate","awe","axe","bad","bag","ban","bar","bat","bay","bed","bee","bet","bid","big","bin","bit","bow","box","boy","bud","bug","bun","bus","but","buy","cab","cam","cap","car","cat","cop","cow","cry","cub","cup","cur","cut","dad","dam","day","den","dew","did","die","dig","dim","dip","doe","dog","dot","dry","dub","dud","due","dug","dun","duo","dye","ear","eat","eel","egg","end","era","eve","ewe","eye","fan","far","fat","fax","fed","fee","few","fig","fin","fir","fit","fix","fly","for","fox","fry","fun","fur","gag","gap","gas","gel","gin","gnu","goa","god","got","gum","gun","gut","guy","had","has","hat","hay","hen","her","hew","hex","hid","him","hip","his","hit","hog","hop","hot","how","hub","hue","hug","huh","hum","hut","ice","icy","ill","imp","ink","inn","ion","ire","irk","its","ivy","jab","jag","jam","jar","jaw","jay","jet","job","jog","jot","joy","jug","jut","keg","ken","key","kid","kin","kit","lab","lad","lag","lap","law","lay","lea","let","lid","lip","lot","low","mad","man","mar","mat","maw","max","may","men","met","mid","mix","mob","mod","mom","mop","mow","mud","mug","net","new","nil","nip","nit","nod","nor","not","now","oak","oar","oat","odd","ode","off","oft","ohm","oil","old","one","opt","orb","ore","our","out","owe","owl","own","pad","pal","pan","pap","par","pat","paw","pay","pea","peg","pen","pep","per","pet","pie","pig","pin","pit","ply","pod","pop","pot","pow","pro","pry","pub","pug","pun","pus","put","rag","ram","ran","rap","rat","raw","ray","red","ref","rep","rib","rid","rig","rim","rip","rob","rod","roe","rot","row","rub","rug","rum","run","rut","rye","sac","sad","sag","sap","sat","saw","sea","set","sew","she","shy","sin","sip","sir","sis","sit","six","ski","sky","sly","sob","sod","son","sot","sow","soy","spa","spy","sty","sub","sue","sum","sun","tab","tad","tag","tan","tap","tar","tax","tea","ten","the","thy","tin","tip","toe","ton","too","top","tot","tow","try","two","urn","use","van","vat","vet","vex","via","vie","vim","vow","wad","wag","war","was","wax","way","web","wed","wet","who","why","win","wit","woe","wok","won","woo","wow","wry","yak","yam","yap","yaw","yea","yes","yet","you","zap","zen","zig","zip","zoo"
}
for _, w in ipairs(fallback) do
    WordList[w] = true
end

pcall(function()
    local url = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears.txt"
    local data = game:HttpGet(url)
    for word in string.gmatch(data, "[%a]+") do
        if #word >= 3 then
            WordList[word:lower()] = true
        end
    end
end)

local function GetAdjacent(pos)
    local x, y = pos[1], pos[2]
    local dirs = {{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}}
    local result = {}
    for _, d in ipairs(dirs) do
        local nx, ny = x + d[1], y + d[2]
        if nx >= 1 and nx <= 5 and ny >= 1 and ny <= 5 then
            table.insert(result, {nx, ny})
        end
    end
    return result
end

local function FindWordsFromCell(startX, startY)
    local found = {}
    local visited = {}
    local function dfs(x, y, currentWord, path)
        if #currentWord > 7 then return end
        if WordList[currentWord] and #currentWord >= 3 then
            local pathCopy = {}
            for _, p in ipairs(path) do
                table.insert(pathCopy, {p[1], p[2]})
            end
            table.insert(found, {word = currentWord, path = pathCopy})
        end
        local neighbors = GetAdjacent({x, y})
        for _, n in ipairs(neighbors) do
            local nx, ny = n[1], n[2]
            local key = nx .. "," .. ny
            if not visited[key] then
                visited[key] = true
                local newWord = currentWord .. Grid[nx][ny]
                table.insert(path, {nx, ny})
                dfs(nx, ny, newWord, path)
                table.remove(path)
                visited[key] = nil
            end
        end
    end
    visited[startX .. "," .. startY] = true
    dfs(startX, startY, Grid[startX][startY], {{startX, startY}})
    return found
end

CalcBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(ResultFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    local allWords = {}
    for i = 1, 5 do
        for j = 1, 5 do
            if Grid[i][j] ~= "" then
                local words = FindWordsFromCell(i, j)
                for _, w in ipairs(words) do
                    table.insert(allWords, {
                        word = w.word,
                        start = {i, j}
                    })
                end
            end
        end
    end
    
    table.sort(allWords, function(a, b)
        if #a.word ~= #b.word then
            return #a.word > #b.word
        end
        return a.word < b.word
    end)
    
    GridFrame.Visible = false
    CalcBtn.Visible = false
    ResultFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 420, 0, 520)
    
    local y = 0
    local seen = {}
    for _, item in ipairs(allWords) do
        if not seen[item.word] then
            seen[item.word] = true
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 0, 28)
            lbl.Position = UDim2.new(0, 5, 0, y)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(51, 51, 51)
            lbl.Text = item.word .. "  (ô " .. item.start[1] .. "," .. item.start[2] .. ")"
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 18
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = ResultFrame
            y = y + 30
        end
    end
    ResultFrame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end)

local isMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 420, 0, 40)
        MinimizeBtn.Text = "+"
        GridFrame.Visible = false
        CalcBtn.Visible = false
        ResultFrame.Visible = false
    else
        MainFrame.Size = UDim2.new(0, 420, 0, 480)
        MinimizeBtn.Text = "−"
        GridFrame.Visible = true
        CalcBtn.Visible = true
        ResultFrame.Visible = false
    end
end)

local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print("Word Hunt 5x5 da chay")