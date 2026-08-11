-- Script tự động giải Word Hunt Battle (Roblox) cho Delta Executor - Khắc phục UI không tạo & quét bảng tối ưu
-- Tác giả: palofsc
-- Mục tiêu: quét mọi bảng chữ (5x5, 6x6, ...) và tự động nối từ, kể cả khi Executor giới hạn API.

local TIENTO = "[WordHuntSolver] "
local function log(...) print(TIENTO .. table.concat({...}, " ")) end

-- ==================== THƯ VIỆN TÙY CHỈNH ====================
local HttpService, Players, RunService, CoreGui
local function khoiTaoDichVu()
    HttpService = game:GetService("HttpService")
    Players = game:GetService("Players")
    RunService = game:GetService("RunService")
    CoreGui = game:GetService("CoreGui")
end
khoiTaoDichVu()

-- URL từ điển (có thể đổi)
local TU_DIEN_URL = "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_dictionary.json"
local MAX_DO_DAI_TU = 10  -- giới hạn để tăng tốc, tránh lag

-- ==================== GIAO DIỆN ====================
-- Thử nhiều cách tạo UI để đảm bảo hiển thị trên Delta Executor
local nutChinh, trangThai, hienThiSoO
local function taoGiaoDien()
    local manHinh = Instance.new("ScreenGui")
    manHinh.Name = "WordHuntSolverUI"
    manHinh.ResetOnSpawn = false
    -- Thử gắn vào CoreGui trước (an toàn hơn)
    pcall(function() manHinh.Parent = CoreGui end)
    if not manHinh.Parent then
        -- Nếu CoreGui bị chặn, thử PlayerGui
        pcall(function() manHinh.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end)
    end
    if not manHinh.Parent then
        warn(TIENTO .. "Không thể gắn UI vào CoreGui hay PlayerGui, dùng cảnh báo text ở góc màn hình.")
        -- Fallback: tạo một TextLabel trực tiếp trên màn hình workspace (không khuyến khích nhưng có thể)
    end

    local khung = Instance.new("Frame")
    khung.Size = UDim2.new(0, 200, 0, 110)
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
    hienThiSoO.Position = UDim2.new(0, 10, 0, 80)
    hienThiSoO.Text = "Ô: 0 | Lưới: ?x?"
    hienThiSoO.BackgroundTransparency = 1
    hienThiSoO.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    hienThiSoO.Font = Enum.Font.SourceSans
    hienThiSoO.TextSize = 12
    hienThiSoO.Parent = khung

    return manHinh
end

-- ==================== TỪ ĐIỂN & TRIE ====================
local function taiTuDien(url)
    local thanhCong, duLieu = pcall(function()
        return game:HttpGet(url)
    end)
    if not thanhCong then
        log("Không thể tải từ điển từ mạng, dùng danh sách dự phòng.")
        -- Danh sách 2500 từ thông dụng (rút gọn)
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
            tuDien[#tuDien + 1] = tu
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

-- ==================== QUÉT BẢNG CHỮ ====================
-- Hàm quét tất cả các đối tượng có ký tự đơn
local function quetBangChu()
    local cacO = {}
    local cacGui = {}
    -- Gom tất cả ScreenGui trong game (bao gồm CoreGui, PlayerGui, StarterGui)
    local function timScreenGui(cha)
        for _, con in ipairs(cha:GetChildren()) do
            if con:IsA("ScreenGui") then
                table.insert(cacGui, con)
            end
            timScreenGui(con)
        end
    end
    -- Bắt đầu từ game (để tìm cả CoreGui, v.v.)
    timScreenGui(game)
    -- Thêm PlayerGui và CoreGui trực tiếp (phòng trường hợp không nằm trong game.Children)
    if Players.LocalPlayer then
        pcall(function() table.insert(cacGui, Players.LocalPlayer:WaitForChild("PlayerGui")) end)
    end
    pcall(function() table.insert(cacGui, CoreGui) end)

    for _, gui in ipairs(cacGui) do
        for _, con in ipairs(gui:GetDescendants()) do
            if con:IsA("TextLabel") or con:IsA("TextButton") or con:IsA("ImageButton") then
                local kyTu = nil
                if con:IsA("TextLabel") or con:IsA("TextButton") then
                    kyTu = con.Text
                end
                -- Nếu không có text trực tiếp, thử tìm TextLabel con
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

    -- Loại bỏ trùng lặp (cùng vị trí)
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

-- Phân cụm thành lưới (ma trận)
local function xayDungLuoi(cacO)
    if #cacO == 0 then return nil, nil, 0, 0 end
    -- Sắp xếp theo y
    table.sort(cacO, function(a, b) return a.y < b.y end)
    local hang = {}
    local hienTai = {cacO[1]}
    local yCuoi = cacO[1].y
    for i = 2, #cacO do
        if math.abs(cacO[i].y - yCuoi) < (cacO[i].h/2 + 5) then
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
    -- Nếu các hàng có số cột không đều, lấy số cột tối đa
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

-- ==================== TÌM KIẾM TỪ ====================
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

    -- Chuyển thành mảng, sắp xếp giảm dần theo độ dài
    local ds = {}
    for _, v in pairs(ketQua) do table.insert(ds, v) end
    table.sort(ds, function(a, b) return #a.tu > #b.tu end)
    return ds
end

-- ==================== GỬI TỪ ====================
local function timNutGui()
    -- Tìm nút có văn bản "Submit", "Enter", "Send", "Done"
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
            -- fallback
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

-- ==================== CHƯƠNG TRÌNH CHÍNH ====================
local trieCache = nil
local dangChay = false

local function vongLapGiai()
    while dangChay do
        local cacO = quetBangChu()
        hienThiSoO.Text = "Ô: " .. #cacO
        if #cacO < 4 then
            trangThai.Text = "Chưa thấy bảng (cần ít nhất 4 ô)"
            task.wait(2)
            goto tiepTuc
        end

        local luoi, nutGrid, soHang, soCot = xayDungLuoi(cacO)
        if soHang < 2 or soCot < 2 then
            trangThai.Text = "Lưới không chuẩn " .. soHang .. "x" .. soCot
            hienThiSoO.Text = "Ô: " .. #cacO .. " | Lưới " .. soHang .. "x" .. soCot
            task.wait(2)
            goto tiepTuc
        end
        hienThiSoO.Text = "Ô: " .. #cacO .. " | Lưới " .. soHang .. "x" .. soCot

        -- Hash bảng hiện tại để phát hiện thay đổi
        local hash = ""
        for i = 1, soHang do
            for j = 1, soCot do
                hash = hash .. (luoi[i][j] or "?")
            end
        end

        if not trieCache then
            trangThai.Text = "Đang tải từ điển..."
            local tuDien = taiTuDien(TU_DIEN_URL)
            trieCache = xayDungTrie(tuDien)
        end
        trangThai.Text = "Đang tìm từ..."
        local cacTu = timTatCaTu(luoi, soHang, soCot, trieCache)
        trangThai.Text = "Tìm thấy " .. #cacTu .. " từ, đang gửi..."
        for _, duLieu in ipairs(cacTu) do
            if not dangChay then break end
            guiTu(nutGrid, duLieu.duongDi)
        end

        -- Chờ bảng mới
        trangThai.Text = "Chờ bảng mới..."
        while dangChay do
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
    trangThai.Text = "Đã dừng"
    if nutChinh then
        nutChinh.Text = "Tự động giải: TẮT"
        nutChinh.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end

-- Gán sự kiện nút
local function ganSuKien()
    if not nutChinh then return end
    nutChinh.MouseButton1Click:Connect(function()
        dangChay = not dangChay
        if dangChay then
            nutChinh.Text = "Tự động giải: BẬT"
            nutChinh.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            trangThai.Text = "Bắt đầu..."
            task.spawn(vongLapGiai)
        else
            nutChinh.Text = "Tự động giải: TẮT"
            nutChinh.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            trangThai.Text = "Sẵn sàng"
        end
    end)
end

-- Khởi tạo
local manHinh = taoGiaoDien()
if nutChinh then
    ganSuKien()
else
    warn(TIENTO .. "UI không khởi tạo được, script vẫn chạy nền nhưng không có nút điều khiển.")
    -- Chạy mặc định (có thể điều khiển bằng console)
    dangChay = true
    task.spawn(vongLapGiai)
end