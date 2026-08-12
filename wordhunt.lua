--[=[
  HƯỚNG DẪN:
  Sau khi chạy script, chờ 30-45 giây cho đến khi thông báo
  "Danh sách từ đã tải xong!" xuất hiện.
  CHỈ KHI ĐÓ mới bật tính năng tự động giải.
  KHÔNG bật trước khi danh sách từ tải xong!
]=]

-- Tải script chính từ nguồn đã biết hoạt động trên bản cập nhật mới nhất [citation:4]
local scriptUrl = "https://raw.githubusercontent.com/LunarielLovely/Scripts/refs/heads/main/WordSearch"
local success, result = pcall(function()
    return game:HttpGet(scriptUrl)
end)

if success then
    loadstring(result)()
else
    warn("Không thể tải script chính. Kiểm tra kết nối hoặc URL.")
end