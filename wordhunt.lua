-- Script tự động giải Word Hunt Battle (Roblox) cho Delta Executor - Phiên bản sửa lỗi quét bảng 5x5
-- Tác giả: palofsc
-- Yêu cầu: Delta Executor (hỗ trợ FireClick, getconnections, HttpGet)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local TU_DIEN_URL = "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_dictionary.json"
local MAX_DO_DAI_TU = 12
local KHOANG_CACH_TOI_THIEU = 30   -- Bỏ qua các ô quá gần nhau (trùng)
local SAI_SO_VI_TRI = 10            -- Sai số khi so sánh cùng hàng/cột

-- ==================== GIAO DIỆN ====================
local nutChinh, trangThai, hienThiSoO

local function taoGiaoDien()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local manHinh = Instance.new("ScreenGui")
    manHinh.Name = "WordHuntSolverUI"
    manHinh.ResetOnSpawn = false
    manHinh.Parent = playerGui

    local khung = Instance.new("Frame")
    khung.Size = UDim2.new(0, 200, 0, 120)
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
    hienThiSoO.Text = "Ô: 0 | Hàng: 0 Cột: 0"
    hienThiSoO.BackgroundTransparency = 1
    hienThiSoO.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    hienThiSoO.Font = Enum.Font.SourceSans
    hienThiSoO.TextSize = 12
    hienThiSoO.Parent = khung
end

-- ==================== TỪ ĐIỂN & TRIE ====================
local trieCache = nil
local function taiTuDien(url)
    local thanhCong, duLieu = pcall(function()
        return game:HttpGet(url)
    end)
    if not thanhCong or not duLieu then
        warn("Không tải được từ điển, dùng danh sách dự phòng.")
        return {"hello","world","script","roblox","delta","word","hunt","battle"}
    end
    local ok, json = pcall(function()
        return HttpService:JSONDecode(duLieu)
    end)
    if not ok then
        warn("Parse JSON thất bại.")
        return {"hello","world","script","roblox","delta","word","hunt","battle"}
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

-- ==================== QUÉT VÀ PHÂN TÍCH LƯỚI ====================
local function quetTatCaOChu()
    local cacO = {}
    -- Duyệt tất cả descendants trong game (bao gồm CoreGui và PlayerGui)
    local tatCaCon = {}
    for _, cha in ipairs({CoreGui, Players.LocalPlayer:WaitForChild("PlayerGui")}) do
        if cha then
            for _, con in ipairs(cha:GetDescendants()) do
                table.insert(tatCaCon, con)
            end
        end
    end

    for _, doiTuong in ipairs(tatCaCon) do
        if doiTuong:IsA("TextLabel") or doiTuong:IsA("TextButton") or doiTuong:IsA("ImageButton") then
            local kyTu = nil
            if doiTuong:IsA("TextLabel") or doiTuong:IsA("TextButton") then
                kyTu = doiTuong.Text
            elseif doiTuong:FindFirstChild("TextLabel") then
                kyTu = doiTuong.TextLabel.Text
            end
            if kyTu and #kyTu == 1 and kyTu:match("%a") then
                local viTri = doiTuong.AbsolutePosition
                local kichThuoc = doiTuong.AbsoluteSize
                table.insert(cacO, {
                    nut = doiTuong,
                    kyTu = kyTu:lower(),
                    x = viTri.X + kichThuoc.X / 2,  -- dùng tâm để phân cụm chính xác hơn
                    y = viTri.Y + kichThuoc.Y / 2,
                    kichThuocX = kichThuoc.X,
                    kichThuocY = kichThuoc.Y
                })
            end
        end
    end
    -- Loại bỏ trùng lặp (nếu cùng vị trí)
    local mangLoc = {}
    for _, o in ipairs(cacO) do
        local trung = false
        for _, o2 in ipairs(mangLoc) do
            if math.abs(o.x - o2.x) < KHOANG_CACH_TOI_THIEU and math.abs(o.y - o2.y) < KHOANG_CACH_TOI_THIEU then
                trung = true
                break
            end
        end
        if not trung then
            table.insert(mangLoc, o)
        end
    end
    return mangLoc
end

local function phanCumThanhLuoi(cacO)
    if #cacO == 0 then return {}, {}, 0, 0 end
    -- Phân nhóm theo tọa độ y (hàng)
    table.sort(cacO, function(a, b) return a.y < b.y end)
    local cacHang = {}
    local hangHienTai = {cacO[1]}
    local yCuoi = cacO[1].y
    for i = 2, #cacO do
        if math.abs(cacO[i].y - yCuoi) < (cacO[i].kichThuocY / 2 + SAI_SO_VI_TRI) then
            table.insert(hangHienTai, cacO[i])
        else
            table.insert(cacHang, hangHienTai)
            hangHienTai = {cacO[i]}
            yCuoi = cacO[i].y
        end
    end
    table.insert(cacHang, hangHienTai)

    -- Trong mỗi hàng, sắp xếp theo x
    for _, hang in ipairs(cacHang) do
        table.sort(hang, function(a, b) return a.x < b.x end)
    end

    local soHang = #cacHang
    if soHang == 0 then return {}, {}, 0, 0 end
    local soCot = #cacHang[1]  -- giả định tất cả hàng có cùng số cột
    -- Kiểm tra nếu hàng nào khác số cột, lấy số cột tối đa
    for _, hang in ipairs(cacHang) do
        if #hang > soCot then soCot = #hang end
    end

    local luoi = {}   -- ma trận [dong][cot] = kyTu
    local viTriNut = {}  -- ma trận nút
    for dong = 1, soHang do
        luoi[dong] = {}
        viTriNut[dong] = {}
        for cot = 1, soCot do
            if cacHang[dong][cot] then
                luoi[dong][cot] = cacHang[dong][cot].kyTu
                viTriNut[dong][cot] = cacHang[dong][cot].nut
            else
                -- Trường hợp ô bị thiếu trong hàng (có thể do lỗi)
                luoi[dong][cot] = ""
                viTriNut[dong][cot] = nil
            end
        end
    end
    return luoi, viTriNut, soHang, soCot
end

-- ==================== TÌM TỪ ====================
local function timTatCaTu(luoi, soHang, soCot, trie)
    local ketQua = {}
    local daGheTham = {}
    local buocHienTai = {}
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
        daGheTham[dong][cot] = true
        buocHienTai[doDai] = {dong = dong, cot = cot}
        if nutMoi.ketThuc then
            local tu = ""
            for idx = 1, doDai do
                tu = tu .. luoi[buocHienTai[idx].dong][buocHienTai[idx].cot]
            end
            -- Chỉ lưu nếu chưa có hoặc đường đi dài hơn
            if not ketQua[tu] or #buocHienTai > #ketQua[tu].duongDi then
                ketQua[tu] = {tu = tu, duongDi = {table.unpack(buocHienTai, 1, doDai)}}
            end
        end
        for _, dir in ipairs(huong) do
            local ni, nj = dong + dir[1], cot + dir[2]
            if ni >= 1 and ni <= soHang and nj >= 1 and nj <= soCot and not daGheTham[ni][nj] and luoi[ni][nj] ~= "" then
                dfs(ni, nj, nutMoi, doDai + 1)
            end
        end
        daGheTham[dong][cot] = false
    end
    -- Khởi tạo ma trận đã ghé thăm
    for i = 1, soHang do
        daGheTham[i] = {}
    end
    for i = 1, soHang do
        for j = 1, soCot do
            if luoi[i][j] ~= "" then
                dfs(i, j, trie, 1)
            end
        end
    end
    -- Chuyển sang danh sách, sắp xếp độ dài giảm dần
    local dsKetQua = {}
    for _, v in pairs(ketQua) do
        dsKetQua[#dsKetQua + 1] = v
    end
    table.sort(dsKetQua, function(a, b) return #a.tu > #b.tu end)
    return dsKetQua
end

-- ==================== GỬI TỪ ====================
local function timNutGui()
    -- Tìm nút submit qua tên thông dụng hoặc văn bản
    local cacNut = {}
    for _, cha in ipairs({CoreGui, Players.LocalPlayer:WaitForChild("PlayerGui")}) do
        if cha then
            for _, con in ipairs(cha:GetDescendants()) do
                if con:IsA("TextButton") or con:IsA("ImageButton") then
                    local ten = con.Name:lower()
                    local vanBan = ""
                    if con:IsA("TextButton") then vanBan = con.Text:lower() end
                    if ten:find("submit") or ten:find("enter") or ten:find("send") or ten:find("done") or
                       vanBan:find("submit") or vanBan:find("enter") or vanBan:find("send") then
                        table.insert(cacNut, con)
                    end
                end
            end
        end
    end
    if #cacNut > 0 then
        return cacNut[1]  -- lấy nút đầu tiên khả dụng
    end
    return nil
end

local function guiTu(viTriNut, duongDi)
    for _, buoc in ipairs(duongDi) do
        local nut = viTriNut[buoc.dong][buoc.cot]
        if nut and nut.Visible and nut.Active then
            pcall(function()
                nut:FireClick()
            end)
            local ketNoi = getconnections(nut.MouseButton1Click)
            if ketNoi and #ketNoi > 0 then
                for _, kn in ipairs(ketNoi) do
                    pcall(function() kn:Fire() end)
                end
            end
        end
        task.wait(0.03)
    end
    local nutGui = timNutGui()
    if nutGui then
        pcall(function() nutGui:FireClick() end)
    end
    task.wait(0.15)
end

-- ==================== CHƯƠNG TRÌNH CHÍNH ====================
local dangChay = false
local trieHienTai = nil

local function capNhatNut()
    if dangChay then
        nutChinh.Text = "Tự động giải: BẬT"
        nutChinh.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        nutChinh.Text = "Tự động giải: TẮT"
        nutChinh.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end

local function vongLapGiai()
    while dangChay do
        -- Quét ô
        local cacO = quetTatCaOChu()
        hienThiSoO.Text = "Ô: " .. #cacO .. " | Đang phân tích..."
        if #cacO == 0 then
            trangThai.Text = "Không tìm thấy ô chữ"
            task.wait(2)
            -- Tiếp tục vòng lặp, dùng goto continue (Lua không có continue, dùng ::continue::)
            goto tiepTuc
        end
        local luoi, viTriNut, soHang, soCot = phanCumThanhLuoi(cacO)
        hienThiSoO.Text = "Ô: " .. #cacO .. " | Lưới " .. soHang .. "x" .. soCot
        if soHang < 2 or soCot < 2 then
            trangThai.Text = "Không phải lưới hợp lệ"
            task.wait(2)
            goto tiepTuc
        end
        -- Hash bảng hiện tại
        local banHash = ""
        for i = 1, soHang do
            for j = 1, soCot do
                banHash = banHash .. (luoi[i][j] or "?")
            end
        end
        -- Tải từ điển và xây Trie nếu chưa có
        if not trieHienTai then
            trangThai.Text = "Đang tải từ điển..."
            local tuDien = taiTuDien(TU_DIEN_URL)
            trieHienTai = xayDungTrie(tuDien)
        end
        trangThai.Text = "Đang tìm từ..."
        local cacTu = timTatCaTu(luoi, soHang, soCot, trieHienTai)
        trangThai.Text = "Tìm thấy " .. #cacTu .. " từ"
        -- Gửi từng từ
        for _, duLieuTu in ipairs(cacTu) do
            if not dangChay then break end
            guiTu(viTriNut, duLieuTu.duongDi)
        end
        -- Chờ bảng mới
        trangThai.Text = "Chờ bảng mới..."
        while dangChay do
            task.wait(1)
            local cacOMoi = quetTatCaOChu()
            local luoiMoi, _, hMoi, cMoi = phanCumThanhLuoi(cacOMoi)
            local hashMoi = ""
            for i = 1, hMoi do
                for j = 1, cMoi do
                    hashMoi = hashMoi .. (luoiMoi[i][j] or "?")
                end
            end
            if hashMoi ~= banHash and #hashMoi > 0 then
                break
            end
        end
        ::tiepTuc::
    end
    trangThai.Text = "Đã dừng"
    capNhatNut()
end

nutChinh.MouseButton1Click:Connect(function()
    dangChay = not dangChay
    capNhatNut()
    if dangChay then
        trangThai.Text = "Bắt đầu..."
        task.spawn(vongLapGiai)
    else
        trangThai.Text = "Sẵn sàng"
    end
end)

-- Khởi tạo giao diện
taoGiaoDien()