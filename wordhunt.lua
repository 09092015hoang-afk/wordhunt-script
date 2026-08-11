local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

local Window = Rayfield:CreateWindow({
   Name = "Word Hunt Solver",
   LoadingTitle = "Đang tải...",
   LoadingSubtitle = "by palofsc",
   ConfigurationSaving = {
      Enabled = false
   },
   Discord = {
      Enabled = false
   },
   KeySystem = false
})

local Tab = Window:CreateTab("Chính", 4483362458)
local Toggle = Tab:CreateToggle({
   Name = "Tự động giải",
   CurrentValue = false,
   Flag = "AutoSolve",
   Callback = function(Value)
       _G.AutoSolve = Value
       if Value then
           task.spawn(function() vongLapGiai() end)
       end
   end,
})

local function log(msg)
   print("[WordHuntSolver] " .. tostring(msg))
end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local TU_DIEN_URL = "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_dictionary.json"
local MAX_DO_DAI_TU = 12
local SAI_SO = 10

local trieCache = nil

local function taiTuDien()
    local thanhCong, duLieu = pcall(function()
        return game:HttpGet(TU_DIEN_URL)
    end)
    if not thanhCong then
        log("Không tải được từ điển, dùng danh sách dự phòng.")
        return {"the","be","to","of","and","a","in","that","have","i","it","for","not","on","with","he","as","you","do","at","this","but","his","by","from","they","we","her","she","or","an","will","my","one","all","would","there","their","what","so","up","out","if","about","who","get","which","go","me","when","make","can","like","time","no","just","him","know","take","people","into","year","your","good","some","could","them","see","other","than","then","now","look","only","come","its","over","think","also","back","after","use","two","how","our","work","first","well","way","even","new","want","because","any","these","give","day","most","us"}
    end
    local ok, json = pcall(function()
        return HttpService:JSONDecode(duLieu)
    end)
    if not ok then
        log("Parse JSON thất bại, dùng danh sách dự phòng.")
        return {"the","be","to","of","and","a","in","that","have","i","it","for","not","on","with","he","as","you","do","at","this","but","his","by","from","they","we","her","she","or","an","will","my","one","all","would","there","their","what","so","up","out","if","about","who","get","which","go","me","when","make","can","like","time","no","just","him","know","take","people","into","year","your","good","some","could","them","see","other","than","then","now","look","only","come","its","over","think","also","back","after","use","two","how","our","work","first","well","way","even","new","want","because","any","these","give","day","most","us"}
    end
    local tuDien = {}
    for tu, _ in pairs(json) do
        tu = tostring(tu):lower()
        if #tu >= 2 and #tu <= MAX_DO_DAI_TU and tu:match("^[a-z]+$") then
            table.insert(tuDien, tu)
        end
    end
    return tuDien
end

local function xayDungTrie(tuDien)
    local trie = {con = {}, ketThuc = false}
    for _, tu in ipairs(tuDien) do
        local nut = trie
        for i = 1, #tu do
            local kyTu = tu:sub(i, i)
            if not nut.con[kyTu] then
                nut.con[kyTu] = {con = {}, ketThuc = false}
            end
            nut = nut.con[kyTu]
        end
        nut.ketThuc = true
    end
    return trie
end

local function quetBangChu()
    local cacO = {}
    local cacGui = {}
    local function timScreenGui(cha)
        for _, con in ipairs(cha:GetChildren()) do
            if con:IsA("ScreenGui") then
                table.insert(cacGui, con)
            end
            timScreenGui(con)
        end
    end
    timScreenGui(game)
    pcall(function() table.insert(cacGui, Players.LocalPlayer:WaitForChild("PlayerGui")) end)
    pcall(function() table.insert(cacGui, CoreGui) end)

    for _, gui in ipairs(cacGui) do
        for _, con in ipairs(gui:GetDescendants()) do
            if con:IsA("TextLabel") or con:IsA("TextButton") or con:IsA("ImageButton") then
                local kyTu = nil
                if con:IsA("TextLabel") or con:IsA("TextButton") then
                    kyTu = con.Text
                end
                if not kyTu then
                    local label = con:FindFirstChildOfClass("TextLabel")
                    if label then kyTu = label.Text end
                end
                if kyTu and #kyTu == 1 and kyTu:match("%a") then
                    local vt = con.AbsolutePosition
                    local kt = con.AbsoluteSize
                    table.insert(cacO, {
                        nut = con,
                        kyTu = kyTu:lower(),
                        x = vt.X + kt.X/2,
                        y = vt.Y + kt.Y/2,
                        w = kt.X,
                        h = kt.Y
                    })
                end
            end
        end
    end

    local loc = {}
    for _, o in ipairs(cacO) do
        local trung = false
        for _, o2 in ipairs(loc) do
            if math.abs(o.x - o2.x) < 20 and math.abs(o.y - o2.y) < 20 then
                trung = true
                break
            end
        end
        if not trung then
            table.insert(loc, o)
        end
    end
    return loc
end

local function xayDungLuoi(cacO)
    if #cacO == 0 then return nil, nil, 0, 0 end
    table.sort(cacO, function(a, b) return a.y < b.y end)
    local hang = {}
    local hienTai = {cacO[1]}
    local yCuoi = cacO[1].y
    for i = 2, #cacO do
        if math.abs(cacO[i].y - yCuoi) < (cacO[i].h/2 + SAI_SO) then
            table.insert(hienTai, cacO[i])
        else
            table.insert(hang, hienTai)
            hienTai = {cacO[i]}
            yCuoi = cacO[i].y
        end
    end
    table.insert(hang, hienTai)

    for _, h in ipairs(hang) do
        table.sort(h, function(a, b) return a.x < b.x end)
    end

    local soHang = #hang
    local soCot = #hang[1]
    for _, h in ipairs(hang) do
        if #h > soCot then soCot = #h end
    end

    local luoi = {}
    local nut = {}
    for i = 1, soHang do
        luoi[i] = {}
        nut[i] = {}
        for j = 1, soCot do
            if hang[i][j] then
                luoi[i][j] = hang[i][j].kyTu
                nut[i][j] = hang[i][j].nut
            else
                luoi[i][j] = ""
                nut[i][j] = nil
            end
        end
    end
    return luoi, nut, soHang, soCot
end

local function timTatCaTu(luoi, soHang, soCot, trie)
    local ketQua = {}
    local daTham = {}
    local duongDi = {}
    local huong = {
        {-1,-1}, {-1,0}, {-1,1},
        {0,-1},          {0,1},
        {1,-1},  {1,0},  {1,1}
    }
    local function dfs(dong, cot, nutTrie, doDai)
        if doDai > MAX_DO_DAI_TU then return end
        local kyTu = luoi[dong][cot]
        if kyTu == "" then return end
        local nutMoi = nutTrie.con[kyTu]
        if not nutMoi then return end
        daTham[dong][cot] = true
        duongDi[doDai] = {dong, cot}
        if nutMoi.ketThuc then
            local tu = ""
            for i = 1, doDai do
                local d, c = duongDi[i][1], duongDi[i][2]
                tu = tu .. luoi[d][c]
            end
            if not ketQua[tu] or doDai > #ketQua[tu].duongDi then
                ketQua[tu] = {tu = tu, duongDi = {}}
                for i = 1, doDai do
                    table.insert(ketQua[tu].duongDi, {dong = duongDi[i][1], cot = duongDi[i][2]})
                end
            end
        end
        for _, dir in ipairs(huong) do
            local nd, nc = dong + dir[1], cot + dir[2]
            if nd >= 1 and nd <= soHang and nc >= 1 and nc <= soCot and not daTham[nd][nc] and luoi[nd][nc] ~= "" then
                dfs(nd, nc, nutMoi, doDai + 1)
            end
        end
        daTham[dong][cot] = false
    end

    for d = 1, soHang do
        daTham[d] = {}
    end
    for d = 1, soHang do
        for c = 1, soCot do
            if luoi[d][c] ~= "" then
                dfs(d, c, trie, 1)
            end
        end
    end

    local ds = {}
    for _, v in pairs(ketQua) do table.insert(ds, v) end
    table.sort(ds, function(a, b) return #a.tu > #b.tu end)
    return ds
end

local function timNutGui()
    for _, gui in ipairs({CoreGui, Players.LocalPlayer:WaitForChild("PlayerGui")}) do
        for _, con in ipairs(gui:GetDescendants()) do
            if con:IsA("TextButton") then
                local t = con.Text:lower()
                if t:find("submit") or t:find("enter") or t:find("send") or t:find("done") then
                    return con
                end
            end
        end
    end
    return nil
end

local function guiTu(nutGrid, duongDi)
    for _, buoc in ipairs(duongDi) do
        local btn = nutGrid[buoc.dong][buoc.cot]
        if btn and btn.Visible and btn.Active then
            pcall(function() btn:FireClick() end)
            local kn = getconnections(btn.MouseButton1Click)
            if kn and #kn > 0 then
                for _, k in ipairs(kn) do
                    pcall(function() k:Fire() end)
                end
            end
        end
        task.wait(0.02)
    end
    local nutGui = timNutGui()
    if nutGui then
        pcall(function() nutGui:FireClick() end)
    end
    task.wait(0.1)
end

local function vongLapGiai()
    while _G.AutoSolve do
        local cacO = quetBangChu()
        if #cacO < 4 then
            task.wait(1)
            goto tiepTuc
        end
        local luoi, nutGrid, soHang, soCot = xayDungLuoi(cacO)
        if not luoi or soHang < 2 or soCot < 2 then
            task.wait(1)
            goto tiepTuc
        end
        local hash = ""
        for i = 1, soHang do
            for j = 1, soCot do
                hash = hash .. (luoi[i][j] or "?")
            end
        end
        if not trieCache then
            local tuDien = taiTuDien()
            trieCache = xayDungTrie(tuDien)
        end
        local cacTu = timTatCaTu(luoi, soHang, soCot, trieCache)
        for _, duLieu in ipairs(cacTu) do
            if not _G.AutoSolve then break end
            guiTu(nutGrid, duLieu.duongDi)
        end
        while _G.AutoSolve do
            task.wait(1)
            local oMoi = quetBangChu()
            local lMoi, _, hMoi, cMoi = xayDungLuoi(oMoi)
            local hashMoi = ""
            for i = 1, (hMoi or 0) do
                for j = 1, (cMoi or 0) do
                    hashMoi = hashMoi .. (lMoi and lMoi[i] and lMoi[i][j] or "?")
                end
            end
            if hashMoi ~= hash and #hashMoi > 0 then
                break
            end
        end
        ::tiepTuc::
        task.wait(0.1)
    end
end

log("Script đã sẵn sàng. Hãy bật Toggle để bắt đầu.")