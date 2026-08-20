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

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 600)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BorderColor3 = Color3.fromRGB(85, 85, 85)
mainFrame.BorderSizePixel = 2
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
title.BorderColor3 = Color3.fromRGB(85, 85, 85)
title.TextColor3 = Color3.fromRGB(51, 51, 51)
title.Text = "WORD HUNT 5x5"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 22
title.Parent = mainFrame

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
minimizeBtn.Position = UDim2.new(1, -40, 0, 0)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
minimizeBtn.BorderColor3 = Color3.fromRGB(85, 85, 85)
minimizeBtn.TextColor3 = Color3.fromRGB(51, 51, 51)
minimizeBtn.Text = "−"
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 22
minimizeBtn.Parent = mainFrame

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        mainFrame.Size = UDim2.new(0, 500, 0, 40)
        minimizeBtn.Text = "+"
        gridFrame.Visible = false
        calcBtn.Visible = false
        resultFrame.Visible = false
    else
        mainFrame.Size = UDim2.new(0, 500, 0, 600)
        minimizeBtn.Text = "−"
        gridFrame.Visible = true
        calcBtn.Visible = true
    end
end)

local gridFrame = Instance.new("Frame")
gridFrame.Size = UDim2.new(0, 460, 0, 400)
gridFrame.Position = UDim2.new(0, 20, 0, 45)
gridFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
gridFrame.BorderColor3 = Color3.fromRGB(85, 85, 85)
gridFrame.BorderSizePixel = 1
gridFrame.Parent = mainFrame

local Grid = {}
for i = 1, 5 do
    Grid[i] = {}
    for j = 1, 5 do
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 75, 0, 70)
        box.Position = UDim2.new(0, (j-1)*80 + 10, 0, (i-1)*75 + 10)
        box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        box.BorderColor3 = Color3.fromRGB(85, 85, 85)
        box.BorderSizePixel = 2
        box.TextColor3 = Color3.fromRGB(51, 51, 51)
        box.Text = ""
        box.PlaceholderText = "?"
        box.Font = Enum.Font.SourceSansBold
        box.TextSize = 32
        box.ClipsDescendants = true
        box.Parent = gridFrame
        Grid[i][j] = ""
        
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local val = string.sub(box.Text, 1, 1):upper()
            if val:match("%a") then
                Grid[i][j] = val:lower()
                box.Text = val
            else
                Grid[i][j] = ""
                box.Text = ""
            end
        end)
    end
end

local calcBtn = Instance.new("TextButton")
calcBtn.Size = UDim2.new(0, 460, 0, 45)
calcBtn.Position = UDim2.new(0, 20, 0, 455)
calcBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
calcBtn.BorderColor3 = Color3.fromRGB(85, 85, 85)
calcBtn.BorderSizePixel = 2
calcBtn.TextColor3 = Color3.fromRGB(51, 51, 51)
calcBtn.Text = "▶ TÍNH TOÁN"
calcBtn.Font = Enum.Font.SourceSansBold
calcBtn.TextSize = 20
calcBtn.Parent = mainFrame

local resultFrame = Instance.new("Frame")
resultFrame.Size = UDim2.new(0, 460, 0, 400)
resultFrame.Position = UDim2.new(0, 20, 0, 510)
resultFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
resultFrame.BorderColor3 = Color3.fromRGB(85, 85, 85)
resultFrame.BorderSizePixel = 1
resultFrame.Visible = false
resultFrame.Parent = mainFrame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -10)
scroll.Position = UDim2.new(0, 5, 0, 5)
scroll.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scroll.BorderColor3 = Color3.fromRGB(85, 85, 85)
scroll.BorderSizePixel = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = resultFrame

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

calcBtn.MouseButton1Click:Connect(function()
    for _, child in ipairs(scroll:GetChildren()) do
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
    
    resultFrame.Visible = true
    mainFrame.Size = UDim2.new(0, 500, 0, 920)
    
    local y = 0
    local seen = {}
    for _, item in ipairs(allWords) do
        if not seen[item.word] then
            seen[item.word] = true
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -10, 0, 28)
            lbl.Position = UDim2.new(0, 5, 0, y)
            lbl.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
            lbl.BorderColor3 = Color3.fromRGB(51, 51, 51)
            lbl.BorderSizePixel = 1
            lbl.TextColor3 = Color3.fromRGB(51, 51, 51)
            lbl.Text = item.word .. "  (ô " .. item.start[1] .. "," .. item.start[2] .. ")"
            lbl.Font = Enum.Font.SourceSans
            lbl.TextSize = 18
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = scroll
            y = y + 30
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end)

print("Word Hunt 5x5 da chay")