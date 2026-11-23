
# BỔ SUNG: PHÂN TÍCH SOURCE VÀ ASSETS GỐC TRƯỚC KHI REBUILD

Ngoài ảnh screenshot, tôi đã cung cấp thư mục `assets/` và `am-thanh/` chứa tài nguyên của ứng dụng gốc.

**BẮT BUỘC: Đọc và phân tích toàn bộ tài nguyên liên quan trước khi viết code Flutter.**

## 1. Phân tích source gốc

Kiểm tra những file sau:

- `assets/web/index.html`: Cấu trúc UI, component, nội dung và thứ tự hiển thị.
- `assets/web/app.css`: Màu sắc, typography, padding, margin, border, gradient, animation và responsive.
- `assets/web/app.js`: Business logic, timer, flow thở, thống kê, lưu trữ dữ liệu và xử lý sự kiện.
- `assets/web/fonts/`: Xác định font family, weight và mapping để sử dụng lại trong Flutter.
- `assets/web/khung/`: Kiểm tra tất cả hình ảnh, icon và tài nguyên giao diện.
- `assets/web/dau.jpg`: Xác định vai trò và vị trí sử dụng trong giao diện.

## 2. Phân tích âm thanh

Kiểm tra:

- `assets/am-thanh/giong.pcm`
- `assets/am-thanh/nhac.pcm`
- `assets/am-thanh/lich.txt`
- Thư mục `am-thanh/` nếu chứa thêm dữ liệu.

Yêu cầu:

1. Xác định định dạng PCM thực tế: sample rate, bit depth, số kênh.
2. Đọc `lich.txt` để tìm cấu trúc lịch phát, timestamp và thứ tự âm thanh.
3. Đối chiếu cách xử lý âm thanh trong `app.js`.
4. Xác định cách đồng bộ giọng nói, nhạc nền và nhịp thở.
5. Tái sử dụng tài nguyên âm thanh gốc trong Flutter.
6. Nếu cần chuyển PCM sang WAV hoặc định dạng khác, phải giữ nguyên chất lượng và thời gian phát.
7. Không tự giả định định dạng PCM khi chưa xác minh metadata hoặc cách file được sử dụng.

## 3. Ưu tiên nguồn dữ liệu

Khi xây dựng lại Flutter:

- **Source gốc:** dùng để xác định logic, giá trị, công thức, nội dung, animation và hành vi thực tế.
- **CSS và font gốc:** dùng để xác định design tokens và typography.
- **Assets gốc:** ưu tiên sử dụng lại hình ảnh, âm thanh và font.
- **Screenshot:** dùng làm chuẩn xác minh giao diện cuối cùng.

Nếu source và screenshot khác nhau, xác định nguyên nhân (responsive, trạng thái ứng dụng, phiên bản hoặc cấu hình). Không tự ý bỏ qua sự khác biệt.

## 4. Port sang Flutter

Không sử dụng WebView để chạy lại HTML/CSS/JS.

Hãy chuyển thành Flutter native widgets, GetX controllers, services và repositories.

Đảm bảo:

- Giữ logic gốc tối đa.
- Giữ đúng nội dung tiếng Việt.
- Dùng lại font và tài nguyên hợp lệ.
- Giữ đúng công thức thời gian.
- Giữ đúng cách phát âm thanh.
- Tái tạo animation.
- Đồng bộ dữ liệu giữa các màn hình.
- Giữ giao diện sát screenshot.

## 5. Quy trình thực hiện

**Bước 1:** Đọc source và tài nguyên gốc.

**Bước 2:** Viết báo cáo ngắn về kiến trúc, logic, assets, fonts và các tính năng tìm thấy.

**Bước 3:** Lập bảng mapping giữa HTML/CSS/JS gốc và Flutter/GetX.

**Bước 4:** Triển khai Flutter trực tiếp trong workspace.

**Bước 5:** Cấu hình toàn bộ assets trong `pubspec.yaml`.

**Bước 6:** Chạy ứng dụng và so sánh screenshot.

**Bước 7:** Sửa các sai lệch đến khi giao diện đạt mức tương đồng cao nhất.

Không dừng lại ở việc phân tích. Phải tiếp tục triển khai, kiểm thử và báo cáo kết quả.

**QUAN TRỌNG:** Không được bỏ qua `app.js` để tự viết lại logic theo suy đoán. Không được bỏ qua `app.css` để tự chọn màu, kích thước hay font theo cảm tính. Không được bỏ qua âm thanh gốc để thay bằng TTS nếu tài nguyên gốc có thể sử dụng được.