# Chính sách và cảnh báo an toàn

Chủ ứng dụng: **Mai Biên**. Email hỗ trợ: **nhatbien99@gmail.com**.
Ngày cập nhật nội dung: **24/11/2026**.

## Nội dung và cập nhật

Nguồn chung của cả bản native và website: `assets/legal/content.json`.
Ứng dụng đóng gói nội dung này để đọc offline. Cài đặt → Thông tin & hỗ trợ
mở ba trang `/privacy`, `/terms`, `/support` và mục xem lại cảnh báo an toàn.
Các đường dẫn trong app là màn hình native, không cần domain hoặc Internet.

Sau khi sửa nội dung, chạy:

```sh
python3 tools/export_legal_site.py
```

Bản HTML nằm ở `sites/xike-legal/dist/`, gồm `index.html`, `style.css` và
`privacy/index.html`, `terms/index.html`, `support/index.html`. Upload **nội dung
của dist** vào thư mục gốc trên static hosting. Không upload toàn bộ source app.
Dùng HTTPS và bảo đảm ba URL `/privacy/`, `/terms/`, `/support/` mở được không
đăng nhập, không giới hạn khu vực, trước khi nhập vào store console.

Sites đã triển khai công khai tại:
https://xike-bac-au-max.bi-n-mai-nh-4049.chatgpt.site

Chủ ứng dụng đã yêu cầu bật công khai ngày 23/11/2026. Đã kiểm tra cả ba
trang `/privacy/`, `/terms/`, `/support/` trả HTTP 200 và nội dung ứng dụng
khi truy cập không đăng nhập. Có thể dùng các URL này cho store. Các màn
hình trong app vẫn đọc nội dung offline.

## Cảnh báo lần đầu

Lần mở đầu tiên đi tới `/safety`. Người dùng có thể về trang chủ để xem app;
chưa xác nhận thì mở `/breathing` hoặc `/hold` đều chuyển về cảnh báo, trước
khi tạo màn tập hay bắt đầu phát âm thanh. Checkbox chỉ xác nhận đọc cảnh báo,
không phải sự đồng ý gửi dữ liệu hoặc từ bỏ quyền hợp pháp.

Xác nhận được ghi sau khi bấm nút tiếp tục và chờ ghi dữ liệu hoàn tất. Lần mở
sau không yêu cầu xác nhận lại. Khóa lưu: `safetyAcknowledgementVersion`.
Nếu nội dung cảnh báo thay đổi đáng kể và cần xác nhận lại, tăng
`SafetyAcknowledgement.version` trong `lib/features/safety/safety_view.dart`.
Xóa dữ liệu/gỡ app cũng làm mất xác nhận (trừ trường hợp dữ liệu được OS khôi phục).

## Khi gửi store

- Điền App Privacy / Data safety theo bản build cuối và SDK thực tế; tài liệu
  này không tự thay các biểu mẫu trong console.
- Hoàn tất Health apps declaration; thêm tuyên bố không phải thiết bị y tế,
  không chẩn đoán/điều trị/chữa/phòng bệnh và khuyến nghị tư vấn chuyên môn
  vào mô tả store, như nội dung trong Điều khoản/cảnh báo.
- Kiểm tra tên Mai Biên/tên app khớp thông tin chủ thể thể hiện trên store.
- Xác nhận quyền phân phối ảnh, giọng đọc và âm thanh riêng. Điều khoản không
  tạo quyền sử dụng tài nguyên của bên thứ ba.

Nguồn chính sách tham khảo:
- https://developer.apple.com/app-store/review/guidelines/#privacy
- https://support.google.com/googleplay/android-developer/answer/10144311
- https://support.google.com/googleplay/android-developer/answer/16679511

## Xác minh

Chạy `flutter analyze`, `flutter test` và build Android debug. Bài kiểm thử
mới bao gồm chặn hai route tập, bỏ qua cảnh báo, ghi xác nhận, lỗi ghi dữ liệu
và bố cục màn nhỏ. Integration test hiện có đã cập nhật để xác nhận cảnh báo
trên bản cài mới; cần chạy lại trên thiết bị nếu muốn kiểm tra toàn bộ vòng
đời audio với thay đổi này.
