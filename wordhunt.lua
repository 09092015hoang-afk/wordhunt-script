-- Script tự động nối từ cho Word Hunt Battle (Roblox) dành cho Delta Executor
-- Chức năng: Quét bảng chữ, tìm tất cả từ hợp lệ từ từ điển, tự động nhấn nối từ để ghi điểm.

-- Cấu hình
local TU_DIEN_URL = "https://pastebin.com/raw/abc123" -- Thay bằng URL chứa danh sách từ (mỗi từ 1 dòng)
local KICH_THUOC_O = 80 -- Khoảng cách trung bình giữa các ô (để xác định hàng xóm)
local THOI_GIAN_CHO = 0.05 -- Độ trễ giữa các lần nhấn ô (giây)

-- Hàm tải từ điển
local function taiTuDien(url)
    local thanhCong, duLieu = pcall(function()
        return game:HttpGet(url)
    end)
    if not thanhCong or not duLieu then
        -- Nếu không tải được, dùng danh sách dự phòng cơ bản
        return {"hello", "world", "lua", "script", "roblox", "delta", "word", "hunt", "battle"}
    end
    local tuDien = {}
    for tu in duLieu:gmatch("[^\r\n]+") do
        tu = tu:lower():gsub("%s+", "")
        if #tu >= 2 then
            tuDien[#tuDien + 1] = tu
        end
    end
    return tuDien
end

-- Lớp đại diện cho một ô chữ
local OChu = {}
OChu.__index = OChu
function OChu.moi(nut, kyTu, viTri)
    return setmetatable({
        nut = nut,           -- Đối tượng GuiButton gốc
        kyTu = kyTu:lower(), -- Ký tự trên ô
        x = viTri.X,         -- Tọa độ trên màn hình
        y = viTri.Y
    }, OChu)
end

-- Quét tất cả các ô chữ trong giao diện
local function quetBangChu()
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local cacO = {}
    local function timTrong(troCon)
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
                    local viTri = Vector2.new(viTriTuyetDoi.X, viTriTuyetDoi.Y)
                    table.insert(cacO, OChu.moi(con, kyTu, viTri))
                end
            end
            timTrong(con)
        end
    end
    timTrong(playerGui)
    -- Sắp xếp các ô theo toạ độ để xác định hàng xóm
    table.sort(cacO, function(a, b)
        if math.abs(a.y - b.y) < KICH_THUOC_O / 2 then
            return a.x < b.x
        else
            return a.y < b.y
        end
    end)
    return cacO
end

-- Xây dựng đồ thị các ô lân cận (8 hướng)
local function xayDungDoThi(cacO)
    local doThi = {}
    for i, o in ipairs(cacO) do
        doThi[i] = {}
        for j, oKhac in ipairs(cacO) do
            if i ~= j then
                local deltaX = math.abs(o.x - oKhac.x)
                local deltaY = math.abs(o.y - oKhac.y)
                if deltaX <= KICH_THUOC_O * 1.2 and deltaY <= KICH_THUOC_O * 1.2 then
                    table.insert(doThi[i], j)
                end
            end
        end
    end
    return doThi
end

-- Tạo bảng tiền tố để tăng tốc tìm từ
local function taoBangTienTo(tuDien)
    local tienTo = {}
    for _, tu in ipairs(tuDien) do
        for i = 1, #tu do
            local tien = tu:sub(1, i)
            tienTo[tien] = true
        end
    end
    return tienTo
end

-- Duyệt DFS tìm tất cả đường đi cho từ điển
local function timTatCaCacTu(cacO, doThi, tuDien)
    local bangTienTo = taoBangTienTo(tuDien)
    local cacDuongDi = {}
    local daTham = {}
    local function dfs(chiSo, hienTai, duongDi)
        -- Nếu từ hiện tại có trong từ điển, lưu đường đi
        local tuHienTai = table.concat(hienTai)
        for _, tu in ipairs(tuDien) do
            if tu == tuHienTai then
                table.insert(cacDuongDi, {tu = tu, cacOBuoc = {table.unpack(duongDi)}})
                break
            end
        end
        -- Thử thêm ký tự mới nếu tiền tố hợp lệ
        for _, ke in ipairs(doThi[chiSo]) do
            if not daTham[ke] then
                local kyTuMoi = cacO[ke].kyTu
                local tienToMoi = tuHienTai .. kyTuMoi
                if bangTienTo[tienToMoi] then
                    daTham[ke] = true
                    table.insert(hienTai, kyTuMoi)
                    table.insert(duongDi, ke)
                    dfs(ke, hienTai, duongDi)
                    table.remove(duongDi)
                    table.remove(hienTai)
                    daTham[ke] = false
                end
            end
        end
    end
    for i = 1, #cacO do
        daTham = {}
        daTham[i] = true
        dfs(i, {cacO[i].kyTu}, {i})
    end
    -- Loại bỏ trùng lặp, giữ từ dài nhất (để tối đa điểm)
    local duyNhat = {}
    for _, duongDi in ipairs(cacDuongDi) do
        local tu = duongDi.tu
        if not duyNhat[tu] or #duongDi.cacOBuoc > #duyNhat[tu].cacOBuoc then
            duyNhat[tu] = duongDi
        end
    end
    local ketQua = {}
    for _, duongDi in pairs(duyNhat) do
        table.insert(ketQua, duongDi)
    end
    -- Sắp xếp theo độ dài từ giảm dần (từ dài cho điểm cao)
    table.sort(ketQua, function(a, b) return #a.tu > #b.tu end)
    return ketQua
end

-- Mô phỏng nhấn một ô (kích hoạt sự kiện click)
local function nhapO(o)
    local nut = o.nut
    if nut.Visible and nut.Active then
        -- Thử fireclick trước (hỗ trợ hầu hết executor)
        pcall(function()
            nut:FireClick()
        end)
        -- Dự phòng bằng cách kích hoạt MouseButton1Click
        local ketNoi = getconnections(nut.MouseButton1Click)
        if ketNoi and #ketNoi > 0 then
            for _, kn in ipairs(ketNoi) do
                pcall(function()
                    kn:Fire()
                end)
            end
        end
        -- Di chuyển chuột đến vị trí và click (cho executor thiếu FireClick)
        pcall(function()
            local viTri = nut.AbsolutePosition + nut.AbsoluteSize / 2
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(viTri.X, viTri.Y, 0, true, game, 0)
            wait(0.02)
            vim:SendMouseButtonEvent(viTri.X, viTri.Y, 0, false, game, 0)
        end)
    end
end

-- Gửi một từ bằng cách nhấn theo đường đi
local function guiTu(cacO, duongDi)
    local cacChiSo = duongDi.cacOBuoc
    for _, idx in ipairs(cacChiSo) do
        nhapO(cacO[idx])
        wait(THOI_GIAN_CHO)
    end
    -- Nhấn nút gửi (giả định tên "SubmitButton", "Submit",... có thể cần chỉnh)
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local nutGui = playerGui:FindFirstChild("SubmitButton", true) or
                   playerGui:FindFirstChild("Submit", true)
    if nutGui and nutGui:IsA("TextButton") then
        pcall(function() nutGui:FireClick() end)
        wait(0.1)
    end
end

-- Chương trình chính
local function chayChuongTrinh()
    print("Đang quét bảng chữ...")
    local cacO = quetBangChu()
    if #cacO == 0 then
        warn("Không tìm thấy ô chữ nào. Hãy đảm bảo bảng đã hiện.")
        return
    end
    print("Đã tìm thấy " .. #cacO .. " ô chữ.")
    local doThi = xayDungDoThi(cacO)
    local tuDien = taiTuDien(TU_DIEN_URL)
    print("Từ điển đã tải " .. #tuDien .. " từ.")
    local cacDuongDi = timTatCaCacTu(cacO, doThi, tuDien)
    print("Tìm thấy " .. #cacDuongDi .. " từ khả dụng.")
    for i, duongDi in ipairs(cacDuongDi) do
        print("Gửi từ: " .. duongDi.tu)
        guiTu(cacO, duongDi)
        wait(0.2) -- Đợi game xử lý từ
    end
    print("Hoàn thành. Tải lại bảng mới (reset) nếu có.")
end

-- Thực thi
chayChuongTrinh()