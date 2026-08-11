-- Script tự động giải Word Hunt Battle (Roblox) cho Delta Executor
-- Sửa lỗi: tải từ điển từ JSON, tối ưu tìm từ bằng Trie, thêm giao diện bật/tắt.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TU_DIEN_URL = "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_dictionary.json"
local MAX_DO_DAI_TU = 12 -- Giới hạn độ dài từ để tăng tốc, tránh treo máy
local KHOANG_CACH_O = 100 -- Khoảng cách trung bình giữa các ô (pixel)

-- ==================== GIAO DIỆN ====================
local function taoGiaoDien()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local manHinh = Instance.new("ScreenGui")
    manHinh.Name = "WordHuntSolverUI"
    manHinh.ResetOnSpawn = false
    manHinh.Parent = playerGui

    local khung = Instance.new("Frame")
    khung.Size = UDim2.new(0, 180, 0, 80)
    khung.Position = UDim2.new(0, 10, 0, 10)
    khung.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    khung.BorderSizePixel = 0
    khung.Parent = manHinh

    local nutChinh = Instance.new("TextButton")
    nutChinh.Size = UDim2.new(0, 160, 0, 40)
    nutChinh.Position = UDim2.new(0, 10, 0, 10)
    nutChinh.Text = "Tự động giải: TẮT"
    nutChinh.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    nutChinh.TextColor3 = Color3.new(1, 1, 1)
    nutChinh.Font = Enum.Font.SourceSansBold
    nutChinh.TextSize = 16
    nutChinh.Parent = khung

    local trangThai = Instance.new("TextLabel")
    trangThai.Size = UDim2.new(0, 160, 0, 20)
    trangThai.Position = UDim2.new(0, 10, 0, 55)
    trangThai.Text = "Sẵn sàng"
    trangThai.BackgroundTransparency = 1
    trangThai.TextColor3 = Color3.new(1, 1, 1)
    trangThai.Font = Enum.Font.SourceSans
    trangThai.TextSize = 14
    trangThai.Parent = khung

    return nutChinh, trangThai
end

-- ==================== TỪ ĐIỂN ====================
local function taiTuDien(url)
    local duLieuTho, err = pcall(function()
        return game:HttpGet(url)
    end)
    if not duLieuTho then
        warn("Không tải được từ điển, dùng danh sách dự phòng.")
        return {"hello","world","script","roblox","delta"}
    end
    local json, errJson = pcall(function()
        return HttpService:JSONDecode(duLieuTho)
    end)
    if not json then
        warn("Parse JSON thất bại, dùng danh sách dự phòng.")
        return {"hello","world","script","roblox","delta"}
    end
    local tuDien = {}
    for tu, _ in pairs(json) do
        tu = tostring(tu):lower()
        if #tu >= 2 and #tu <= MAX_DO_DAI_TU then
            tuDien[#tuDien + 1] = tu
        end
    end
    return tuDien
end

-- Cấu trúc Trie để kiểm tra tiền tố và từ hoàn chỉnh nhanh
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

-- ==================== QUÉT BẢNG ====================
local function quetBangChu()
    local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local cacO = {}
    local function duyet(troCon)
        for _, con in ipairs(troCon:GetChildren()) do
            if con:IsA("TextButton") or con:IsA("ImageButton") then
                local kyTu = nil
                if con:IsA("TextButton") then
                    kyTu = con.Text
                elseif con:FindFirstChild("TextLabel") then
                    kyTu = con.TextLabel.Text
                end
                if kyTu and #kyTu == 1 and kyTu:match("%a") then
                    local viTriTuyetDoi = con.AbsolutePosition
                    table.insert(cacO, {
                        nut = con,
                        kyTu = kyTu:lower(),
                        x = viTriTuyetDoi.X,
                        y = viTriTuyetDoi.Y,
                    })
                end
            end
            duyet(con)
        end
    end
    duyet(gui)
    -- Sắp xếp theo tọa độ để xác định lưới
    table.sort(cacO, function(a, b)
        if math.abs(a.y - b.y) < KHOANG_CACH_O / 2 then
            return a.x < b.x
        else
            return a.y < b.y
        end
    end)
    return cacO
end

-- Xây dựng ma trận và ánh xạ chỉ số -> vị trí
local function phanTichLuoi(cacO)
    if #cacO == 0 then return {}, {}, 0, 0 end
    -- Tìm số cột và hàng
    local cacHang = {}
    local hangHienTai = {cacO[1]}
    local yTruoc = cacO[1].y
    for i = 2, #cacO do
        if math.abs(cacO[i].y - yTruoc) < KHOANG_CACH_O / 2 then
            table.insert(hangHienTai, cacO[i])
        else
            table.insert(cacHang, hangHienTai)
            hangHienTai = {cacO[i]}
            yTruoc = cacO[i].y
        end
    end
    table.insert(cacHang, hangHienTai)
    local soHang = #cacHang
    local soCot = #cacHang[1]  -- giả định các hàng đều đủ
    local luoi = {}  -- ma trận kyTu
    local viTriNut = {} -- [i][j] = nut
    for i, hang in ipairs(cacHang) do
        luoi[i] = {}
        viTriNut[i] = {}
        for j, o in ipairs(hang) do
            luoi[i][j] = o.kyTu
            viTriNut[i][j] = o.nut
        end
    end
    return luoi, viTriNut, soHang, soCot
end

-- Tìm tất cả các từ bằng DFS sử dụng Trie
local function timTatCaTu(luoi, soHang, soCot, trie)
    local ketQua = {} -- dùng set để tránh trùng
    local daGheTham = {}
    local buocHienTai = {}
    local huong = {
        {-1,-1}, {-1,0}, {-1,1},
        {0,-1},          {0,1},
        {1,-1},  {1,0},  {1,1}
    }
    local function dfs(i, j, nutTrie, doDai)
        if doDai > MAX_DO_DAI_TU then return end
        local kyTu = luoi[i][j]
        local nutMoi = nutTrie.con[kyTu]
        if not nutMoi then return end
        daGheTham[i][j] = true
        buocHienTai[doDai] = {dong = i, cot = j}
        if nutMoi.ketThuc then
            local tu = ""
            for idx = 1, doDai do
                tu = tu .. luoi[buocHienTai[idx].dong][buocHienTai[idx].cot]
            end
            ketQua[tu] = {tu = tu, duongDi = {table.unpack(buocHienTai, 1, doDai)}}
        end
        for _, dir in ipairs(huong) do
            local ni, nj = i + dir[1], j + dir[2]
            if ni >= 1 and ni <= soHang and nj >= 1 and nj <= soCot and not daGheTham[ni][nj] then
                dfs(ni, nj, nutMoi, doDai + 1)
            end
        end
        daGheTham[i][j] = false
    end
    -- Khởi tạo mảng đã ghé thăm
    for i = 1, soHang do
        daGheTham[i] = {}
    end
    for i = 1, soHang do
        for j = 1, soCot do
            dfs(i, j, trie, 1)
        end
    end
    -- Chuyển kết quả thành danh sách, sắp xếp từ dài nhất
    local dsKetQua = {}
    for _, v in pairs(ketQua) do
        dsKetQua[#dsKetQua + 1] = v
    end
    table.sort(dsKetQua, function(a, b) return #a.tu > #b.tu end)
    return dsKetQua
end

-- Gửi một từ bằng cách nhấn các nút theo đường đi và nút submit
local function guiTu(viTriNut, duongDi)
    for _, buoc in ipairs(duongDi) do
        local nut = viTriNut[buoc.dong][buoc.cot]
        if nut and nut.Visible and nut.Active then
            pcall(function()
                nut:FireClick()
            end)
            -- dự phòng
            local ketNoi = getconnections(nut.MouseButton1Click)
            if ketNoi and #ketNoi > 0 then
                for _, kn in ipairs(ketNoi) do
                    pcall(function() kn:Fire() end)
                end
            end
        end
        task.wait(0.03)
    end
    -- Nhấn nút gửi (tên thường gặp)
    local nutGui = Players.LocalPlayer.PlayerGui:FindFirstChild("Submit", true) or
                   Players.LocalPlayer.PlayerGui:FindFirstChild("SubmitButton", true)
    if nutGui then
        pcall(function() nutGui:FireClick() end)
    end
    task.wait(0.15)
end

-- ==================== CHƯƠNG TRÌNH CHÍNH ====================
local nutChinh, trangThai = taoGiaoDien()
local dangChay = false

local function capNhatNut()
    if dangChay then
        nutChinh.Text = "Tự động giải: BẬT"
        nutChinh.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    else
        nutChinh.Text = "Tự động giải: TẮT"
        nutChinh.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end

nutChinh.MouseButton1Click:Connect(function()
    dangChay = not dangChay
    capNhatNut()
    if dangChay then
        trangThai.Text = "Đang quét bảng..."
        -- Chạy vòng lặp giải
        task.spawn(function()
            while dangChay do
                local cacO = quetBangChu()
                if #cacO == 0 then
                    trangThai.Text = "Không thấy bảng chữ"
                    task.wait(2)
                    continue
                end
                local luoi, viTriNut, soHang, soCot = phanTichLuoi(cacO)
                if soHang == 0 or soCot == 0 then
                    trangThai.Text = "Lỗi phân tích lưới"
                    task.wait(2)
                    continue
                end
                -- Tính mã băm của bảng hiện tại để biết khi nào bảng thay đổi
                local banDau = ""
                for _, o in ipairs(cacO) do banDau = banDau .. o.kyTu end
                -- Tải từ điển và xây Trie (có thể cache để tái sử dụng)
                local tuDien = taiTuDien(TU_DIEN_URL)
                local trie = xayDungTrie(tuDien)
                trangThai.Text = "Đang tìm từ..."
                local cacTu = timTatCaTu(luoi, soHang, soCot, trie)
                trangThai.Text = "Tìm thấy " .. #cacTu .. " từ"
                -- Gửi từng từ
                for _, duLieuTu in ipairs(cacTu) do
                    if not dangChay then break end
                    guiTu(viTriNut, duLieuTu.duongDi)
                end
                -- Chờ bảng thay đổi (reset)
                trangThai.Text = "Chờ bảng mới..."
                while dangChay do
                    task.wait(1)
                    local cacOMoi = quetBangChu()
                    local banMoi = ""
                    for _, o in ipairs(cacOMoi) do banMoi = banMoi .. o.kyTu end
                    if banMoi ~= banDau and #banMoi > 0 then
                        break
                    end
                end
            end
            trangThai.Text = "Đã dừng"
            capNhatNut()
        end)
    else
        trangThai.Text = "Sẵn sàng"
    end
end)