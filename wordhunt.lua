-- [[ Script Executor Delta - Word Hunt 5x5 ]]
-- Màu: nền đen (#000000), chữ xám đen (#333333), khung xám (#555555)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/your-library/source.lua"))()
local Window = Library:CreateWindow("Word Hunt 5x5", Vector2.new(100, 100), Enum.KeyCode.Insert)

-- Biến toàn cục
local Grid = {}
local AdjacentWords = {}
local WordList = {}
local isMinimized = false

-- Tải danh sách từ từ link Google 10000 từ (không thề)
local function LoadWordList()
    local url = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa-no-swears.txt"
    local success, data = pcall(function()
        return game:HttpGet(url)
    end)
    if success and data then
        for word in string.gmatch(data, "[%a]+") do
            if #word >= 3 then
                WordList[word:lower()] = true
            end
        end
    else
        -- Fallback mở rộng: 200+ từ 3-7 ký tự
        local fallback = {
            "ace","act","add","age","ago","aid","aim","air","all","and","ant","any","ape","arc","are","ark","arm","art","ash","ask","ate","awe","axe","bad","bag","ban","bar","bat","bay","bed","bee","bet","bid","big","bin","bit","bow","box","boy","bud","bug","bun","bus","but","buy","cab","cam","cap","car","cat","cop","cow","cry","cub","cup","cur","cut","dad","dam","day","den","dew","did","die","dig","dim","dip","doe","dog","dot","dry","dub","dud","due","dug","dun","duo","dye","ear","eat","eel","egg","end","era","eve","ewe","eye","fan","far","fat","fax","fed","fee","few","fig","fin","fir","fit","fix","fly","for","fox","fry","fun","fur","gag","gap","gas","gel","gin","gnu","goa","god","got","gum","gun","gut","guy","had","has","hat","hay","hen","her","hew","hex","hid","him","hip","his","hit","hog","hop","hot","how","hub","hue","hug","huh","hum","hut","ice","icy","ill","imp","ink","inn","ion","ire","irk","its","ivy","jab","jag","jam","jar","jaw","jay","jet","job","jog","jot","joy","jug","jut","keg","ken","key","kid","kin","kit","lab","lad","lag","lap","law","lay","lea","let","lid","lip","lot","low","mad","man","mar","mat","maw","max","may","men","met","mid","mix","mob","mod","mom","mop","mow","mud","mug","net","new","nil","nip","nit","nod","nor","not","now","oak","oar","oat","odd","ode","off","oft","ohm","oil","old","one","opt","orb","ore","our","out","owe","owl","own","pad","pal","pan","pap","par","pat","paw","pay","pea","peg","pen","pep","per","pet","pie","pig","pin","pit","ply","pod","pop","pot","pow","pro","pry","pub","pug","pun","pus","put","rag","ram","ran","rap","rat","raw","ray","red","ref","rep","rib","rid","rig","rim","rip","rob","rod","roe","rot","row","rub","rug","rum","run","rut","rye","sac","sad","sag","sap","sat","saw","sea","set","sew","she","shy","sin","sip","sir","sis","sit","six","ski","sky","sly","sob","sod","son","sot","sow","soy","spa","spy","sty","sub","sue","sum","sun","tab","tad","tag","tan","tap","tar","tax","tea","ten","the","thy","tin","tip","toe","ton","too","top","tot","tow","try","two","urn","use","van","vat","vet","vex","via","vie","vim","vow","wad","wag","war","was","wax","way","web","wed","wet","who","why","win","wit","woe","wok","won","woo","wow","wry","yak","yam","yap","yaw","yea","yes","yet","you","zap","zen","zig","zip","zoo"
        }
        for _, w in ipairs(fallback) do
            WordList[w] = true
        end
    end
end
LoadWordList()

-- Hàm kiểm tra ô kề (8 hướng)
local function GetAdjacent(pos)
    local x, y = pos[1], pos[2]
    local directions = {
        {-1,-1},{-1,0},{-1,1},
        {0,-1},        {0,1},
        {1,-1}, {1,0}, {1,1}
    }
    local result = {}
    for _, d in ipairs(directions) do
        local nx, ny = x + d[1], y + d[2]
        if nx >= 1 and nx <= 5 and ny >= 1 and ny <= 5 then
            table.insert(result, {nx, ny})
        end
    end
    return result
end

-- Hàm DFS tìm từ
local function FindWordsFromCell(startX, startY)
    local found = {}
    local visited = {}
    local function dfs(x, y, currentWord, path)
        if #currentWord > 7 then return end
        if WordList[currentWord] and #currentWord >= 3 then
            table.insert(found, {word = currentWord, path = path})
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

-- Tạo Menu chính
local MainTab = Window:CreateTab("Nhập lưới", Enum.KeyCode.One)
local SubTab = Window:CreateTab("Kết quả", Enum.KeyCode.Two)

-- Khung nhập ô 5x5 (màu đen, chữ xám đen)
local GridFrame = MainTab:CreateFrame("gridFrame", Vector2.new(10, 10), Vector2.new(380, 380))
GridFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
GridFrame.BorderColor3 = Color3.fromRGB(85, 85, 85)

local Cells = {}
for i = 1, 5 do
    Grid[i] = {}
    for j = 1, 5 do
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 60, 0, 60)
        box.Position = UDim2.new(0, (j-1)*70 + 10, 0, (i-1)*70 + 10)
        box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        box.BorderColor3 = Color3.fromRGB(85, 85, 85)
        box.TextColor3 = Color3.fromRGB(51, 51, 51)
        box.Text = ""
        box.PlaceholderText = "?"
        box.Font = Enum.Font.SourceSansBold
        box.TextSize = 24
        box.Parent = GridFrame
        Cells[#Cells+1] = box
        Grid[i][j] = ""
        box:GetPropertyChangedSignal("Text"):Connect(function()
            local val = string.sub(box.Text, 1, 1):lower()
            if val:match("%a") then
                Grid[i][j] = val
                box.Text = val
            else
                Grid[i][j] = ""
                box.Text = ""
            end
        end)
    end
end

-- Nút tính toán
local CalcBtn = MainTab:CreateButton("Tính từ kề", Vector2.new(10, 420), Vector2.new(380, 40))
CalcBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
CalcBtn.TextColor3 = Color3.fromRGB(51, 51, 51)
CalcBtn.Text = "▶ TÍNH TOÁN"
CalcBtn.MouseButton1Click:Connect(function()
    AdjacentWords = {}
    for i = 1, 5 do
        for j = 1, 5 do
            if Grid[i][j] ~= "" then
                local words = FindWordsFromCell(i, j)
                for _, w in ipairs(words) do
                    table.insert(AdjacentWords, {
                        word = w.word,
                        start = {i, j},
                        path = w.path
                    })
                end
            end
        end
    end
    -- Sắp xếp từ dài nhất trước
    table.sort(AdjacentWords, function(a, b)
        return #a.word > #b.word
    end)
    -- Hiển thị kết quả trên SubTab
    SubTab:Clear()
    local ResultFrame = SubTab:CreateFrame("resultFrame", Vector2.new(10, 10), Vector2.new(380, 400))
    ResultFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    ResultFrame.BorderColor3 = Color3.fromRGB(85, 85, 85)
    
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, -10, 1, -10)
    Scroll.Position = UDim2.new(0, 5, 0, 5)
    Scroll.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Scroll.BorderColor3 = Color3.fromRGB(85, 85, 85)
    Scroll.CanvasSize = UDim2.new(0, 0, 0, #AdjacentWords * 30)
    Scroll.Parent = ResultFrame
    
    local y = 0
    for _, item in ipairs(AdjacentWords) do
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 25)
        lbl.Position = UDim2.new(0, 5, 0, y)
        lbl.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
        lbl.BorderColor3 = Color3.fromRGB(51, 51, 51)
        lbl.TextColor3 = Color3.fromRGB(51, 51, 51)
        lbl.Text = item.word .. " (ô " .. item.start[1] .. "," .. item.start[2] .. ")"
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 18
        lbl.Parent = Scroll
        y = y + 30
    end
    Scroll.CanvasSize = UDim2.new(0, 0, 0, y)
end)

-- Nút thu gọn (toggle)
local MinimizeBtn = Window:CreateButton("_", Vector2.new(440, 10), Vector2.new(30, 30))
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MinimizeBtn.TextColor3 = Color3.fromRGB(51, 51, 51)
MinimizeBtn.Text = "−"
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    Window:SetVisible(not isMinimized)
    if isMinimized then
        MinimizeBtn.Text = "+"
        Window.Size = Vector2.new(480, 50)
    else
        MinimizeBtn.Text = "−"
        Window.Size = Vector2.new(480, 520)
    end
end)

-- Khởi tạo cửa sổ
Window:SetVisible(true)