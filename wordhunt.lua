-- Script Word Hunt Battle Solver cho Delta Executor - Tự tạo UI và quét bảng 5x5
-- Đảm bảo UI luôn hiển thị, quét toàn bộ đối tượng, tối ưu cho bảng 5x5
-- Tác giả: palofsc

local TIENTO = "[WHS] "
local function log(...) print(TIENTO .. table.concat({...}, " ")) end

-- Khởi tạo dịch vụ
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- Cấu hình
local TU_DIEN_URL = "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_dictionary.json"
local MAX_DO_DAI_TU = 10
local SAI_SO_VI_TRI = 15

-- ==================== GIAO DIỆN (TỰ TẠO, KHÔNG DÙNG THƯ VIỆN NGOÀI) ====================
local manHinh, nutChinh, trangThai, hienThiSoO

local function taoGiaoDien()
    -- Thử gắn vào CoreGui trước
    local success, err = pcall(function()
        manHinh = Instance.new("ScreenGui")
        manHinh.Name = "WHS_GUI"
        manHinh.ResetOnSpawn = false
        manHinh.Parent = CoreGui
    end)
    if not success or not manHinh then
        -- Fallback: gắn vào PlayerGui
        pcall(function()
            manHinh = Instance.new("ScreenGui")
            manHinh.Name = "WHS_GUI"
            manHinh.ResetOnSpawn = false
            manHinh.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
    if not manHinh then
        log("Không thể tạo ScreenGui, script sẽ chạy nền không có giao diện.")
        return
    end

    local khung = Instance.new("Frame")
    khung.Size = UDim2.new(0, 200, 0, 100)
    khung.Position = UDim2.new(0, 10, 0, 10)
    khung.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    khung.BorderSizePixel = 0
    khung.Parent = manHinh

    nutChinh = Instance.new("TextButton")
    nutChinh.Size = UDim2.new(0, 180, 0, 40)
    nutChinh.Position = UDim2.new(0, 10, 0, 10)
    nutChinh.Text = "Tự động giải: TẮT"
    nutChinh.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    nutChinh.TextColor3 = Color3.new(1, 1, 1)
    nutChinh.Font = Enum.Font.SourceSansBold
    nutChinh.TextSize = 16
    nutChinh.Parent = khung

    trangThai = Instance.new("TextLabel")
    trangThai.Size = UDim2.new(0, 180, 0, 20)
    trangThai.Position = UDim2.new(0, 10, 0, 55)
    trangThai.Text = "Sẵn sàng"
    trangThai.BackgroundTransparency = 1
    trangThai.TextColor3 = Color3.new(1, 1, 1)
    trangThai.Font = Enum.Font.SourceSans
    trangThai.TextSize = 14
    trangThai.Parent = khung

    hienThiSoO = Instance.new("TextLabel")
    hienThiSoO.Size = UDim2.new(0, 180, 0, 20)
    hienThiSoO.Position = UDim2.new(0, 10, 0, 75)
    hienThiSoO.Text = "Ô: 0 | Lưới: ?x?"
    hienThiSoO.BackgroundTransparency = 1
    hienThiSoO.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    hienThiSoO.Font = Enum.Font.SourceSans
    hienThiSoO.TextSize = 12
    hienThiSoO.Parent = khung

    log("Giao diện đã sẵn sàng.")
end

-- ==================== TỪ ĐIỂN VÀ TRIE ====================
local function taiTuDien()
    local ok, duLieu = pcall(function() return game:HttpGet(TU_DIEN_URL) end)
    if not ok then
        log("Không tải được từ điển, dùng danh sách dự phòng.")
        return {"the","be","to","of","and","a","in","that","have","i","it","for","not","on","with","he","as","you","do","at","this","but","his","by","from","they","we","her","she","or","an","will","my","one","all","would","there","their","what","so","up","out","if","about","who","get","which","go","me","when","make","can","like","time","no","just","him","know","take","people","into","year","your","good","some","could","them","see","other","than","then","now","look","only","come","its","over","think","also","back","after","use","two","how","our","work","first","well","way","even","new","want","because","any","these","give","day","most","us"}
    end
    local ok2, json = pcall(function() return HttpService:JSONDecode(duLieu) end)
    if not ok2 then
        log("Parse JSON thất bại, dùng dự phòng.")
        return {"the","be","to","of","and","a","in","that","have","i","it","for","not","on","with","he","as","you","do","at"}
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
            local ch = tu:sub(i, i)
            if not nut.con[ch] then
                nut.con[ch] = {con = {}, ketThuc = false}
            end
            nut = nut.con[ch]
        end
        nut.ketThuc = true
    end
    return trie
end

-- ==================== QUÉT BẢNG (TẤT CẢ CÁC LOẠI GUI) ====================
local function quetBangChu()
    local cacO = {}
    -- Danh sách các đối tượng gốc để quét
    local roots = {}
    -- Thêm tất cả ScreenGui từ game, CoreGui, PlayerGui
    for _, child in ipairs(game:GetChildren()) do
        if child:IsA("ScreenGui") then table.insert(roots, child) end
        -- Đôi khi bảng nằm trong SurfaceGui, BillboardGui, ...
        pcall(function()
            for _, sub in ipairs(child:GetDescendants()) do
                if sub:IsA("SurfaceGui") or sub:IsA("BillboardGui") or sub:IsA("ScreenGui") then
                    table.insert(roots, sub)
                end
            end
        end)
    end
    pcall(function() table.insert(roots, CoreGui) end)
    pcall(function() table.insert(roots, Players.LocalPlayer:WaitForChild("PlayerGui")) end)

    for _, root in ipairs(roots) do
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    local kyTu = nil
                    -- Lấy text trực tiếp nếu có
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                        kyTu = obj.Text
                    end
                    -- Nếu không, tìm TextLabel con
                    if not kyTu then
                        local label = obj:FindFirstChildOfClass("TextLabel")
                        if label then kyTu = label.Text end
                    end
                    -- Nếu vẫn không, thử qua thuộc tính Image (không)
                    if kyTu and #kyTu == 1 and kyTu:match("%a") then
                        local vt = obj.AbsolutePosition
                        local kt = obj.AbsoluteSize
                        table.insert(cacO, {
                            nut = obj,
                            kyTu = kyTu:lower(),
                            x = vt.X + kt.X/2,
                            y = vt.Y + kt.Y/2,
                            w = kt.X,
                            h = kt.Y
                        })
                    end
                end
            end
        end)
    end

    -- Loại bỏ trùng lặp (các ô có cùng vị trí)
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

    -- In debug số lượng ô tìm thấy
    if #loc > 0 then
        log("Tìm thấy " .. #loc .. " ô chữ.")
    end
    return loc
end

-- Xây dựng lưới từ danh sách ô
local function xayDungLuoi(cacO)
    if #cacO == 0 then return nil, nil, 0, 0 end
    -- Sắp xếp theo y
    table.sort(cacO, function(a, b) return a.y < b.y end)
    local hang = {}
    local hienTai = {cacO[1]}
    local yCuoi = cacO[1].y
    for i = 2, #cacO do
        if math.abs(cacO[i].y - yCuoi) < (cacO[i].h/2 + SAI_SO_VI_TRI) then
            table.insert(hienTai, cacO[i])
        else
            table.insert(hang, hienTai)
            hienTai = {cacO[i]}
            yCuoi = cacO[i].y
        end
    end
    table.insert(hang, hienTai)

    -- Sắp xếp mỗi hàng theo x
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

-- ==================== TÌM TỪ ====================
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

-- Tìm nút gửi (submit button)
local function timNutGui()
    local roots = {}
    pcall(function() table.insert(roots, CoreGui) end)
    pcall(function() table.insert(roots, Players.LocalPlayer:WaitForChild("PlayerGui")) end)
    for _, root in ipairs(roots) do
        for _, con in ipairs(root:GetDescendants()) do
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

-- Gửi từ bằng cách click các ô theo đường đi
local function guiTu(nutGrid, duongDi)
    for _, buoc in ipairs(duongDi) do
        local btn = nutGrid[buoc.dong][buoc.cot]
        if btn and btn.Visible and btn.Active then
            pcall(function() btn:FireClick() end)
            -- fallback
            local kn = getconnections(btn.MouseButton1Click)
            if kn and #kn > 0 then
                for _, k in ipairs(kn) do
                    pcall(function() k:Fire() end)
                end
            end
        end
        wait(0.02) -- wait đơn giản thay vì task.wait
    end
    local nutGui = timNutGui()
    if nutGui then
        pcall(function() nutGui:FireClick() end)
    end
    wait(0.1)
end

-- ==================== VÒNG LẶP CHÍNH ====================
local trieCache = nil

local function vongLapGiai()
    while _G.AutoSolve do
        local cacO = quetBangChu()
        if hienThiSoO then
            hienThiSoO.Text = "Ô: " .. #cacO .. " | Lưới: ?x?"
        end
        if #cacO < 25 then -- bảng 5x5 cần ít nhất 25 ô
            if trangThai then trangThai.Text = "Đang chờ bảng 5x5 (" .. #cacO .. " ô)..." end
            wait(1)
            continue -- Lua không hỗ trợ continue, dùng goto hoặc vòng lặp
        end

        local luoi, nutGrid, soHang, soCot = xayDungLuoi(cacO)
        if not luoi or soHang < 2 or soCot < 2 then
            if trangThai then trangThai.Text = "Lưới không hợp lệ" end
            wait(1)
            goto tiepTuc
        end
        if hienThiSoO then
            hienThiSoO.Text = "Ô: " .. #cacO .. " | Lưới " .. soHang .. "x" .. soCot
        end

        -- Hash bảng hiện tại để phát hiện thay đổi
        local hash = ""
        for i = 1, soHang do
            for j = 1, soCot do
                hash = hash .. (luoi[i][j] or "?")
            end
        end

        if not trieCache then
            if trangThai then trangThai.Text = "Đang tải từ điển..." end
            local tuDien = taiTuDien()
            trieCache = xayDungTrie(tuDien)
        end

        if trangThai then trangThai.Text = "Đang tìm từ..." end
        local cacTu = timTatCaTu(luoi, soHang, soCot, trieCache)
        if trangThai then trangThai.Text = "Tìm thấy " .. #cacTu .. " từ, đang gửi..." end

        for _, duLieu in ipairs(cacTu) do
            if not _G.AutoSolve then break end
            guiTu(nutGrid, duLieu.duongDi)
        end

        -- Chờ bảng mới
        if trangThai then trangThai.Text = "Chờ bảng mới..." end
        while _G.AutoSolve do
            wait(1)
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
        wait(0.1)
    end
    if trangThai then trangThai.Text = "Đã dừng" end
    if nutChinh then
        nutChinh.Text = "Tự động giải: TẮT"
        nutChinh.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end

-- ==================== KHỞI TẠO ====================
taoGiaoDien()
if nutChinh then
    nutChinh.MouseButton1Click:Connect(function()
        _G.AutoSolve = not _G.AutoSolve
        if _G.AutoSolve then
            nutChinh.Text = "Tự động giải: BẬT"
            nutChinh.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            if trangThai then trangThai.Text = "Bắt đầu..." end
            spawn(vongLapGiai) -- Dùng spawn thay cho task.spawn
        else
            nutChinh.Text = "Tự động giải: TẮT"
            nutChinh.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            if trangThai then trangThai.Text = "Sẵn sàng" end
        end
    end)
    log("Giao diện đã sẵn sàng, bấm nút để bắt đầu.")
else
    log("Không tạo được giao diện. Chạy nền với _G.AutoSolve = true")
    _G.AutoSolve = true
    spawn(vongLapGiai)
end