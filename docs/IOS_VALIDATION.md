# Bổ sung iOS — 23/11/2026

Đã thêm target iOS trong `ios/`. Ứng dụng dùng chung toàn bộ Flutter/GetX, assets, audio PCM và dữ liệu nghiệp vụ với Android. iOS tối thiểu 15.0; đã kiểm tra trên iPhone 17 Pro Simulator, iOS26.3, thiết bị QA riêng `A6DE8661-7AFB-4E8E-9FA9-B6AB8CEE02E9`.

## Cấu hình và thay đổi

- Tên hiển thị tiếng Việt, icon bông tuyết cùng Android, chế độ sáng và portrait, safe area cho Dynamic Island/home indicator.
- `UIBackgroundModes: audio`. AudioSession dùng playback/music; audio_service cung cấp Now Playing và media controls. Không xin quyền notification trên iOS để phát audio.
- Giữ plugin registration và UIScene lifecycle do Flutter3.47 sinh, build bằng Swift Package Manager.
- Nhật ký đọc đúng systemName, systemVersion và hardware model iPhone; không gắn Android API level vào thông tin iOS.
- Bảng chia sẻ nhận rect của nút bấm làm `sharePositionOrigin`, hỗ trợ popover iPad. Không tự gửi dữ liệu.
- Không thêm backend, TTS hoặc thư viện state management khác.

## Đã xác minh

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze` | Không có vấn đề |
| `flutter test` | 16 bài đạt |
| `flutter build ios --simulator` | Đạt |
| `flutter build ios --release --no-codesign` | Đạt, Runner.app cho CPU iPhone ~39,9 MB |
| Flutter integration trên iPhone Simulator | Đạt: tất cả route chính, rounds/slider, stopwatch, empty/history/completed, audio và screenshot |
| Audio khi chuyển app | Đạt: chuyển sang iOS Settings 5 giây, trở lại app, player vẫn phát và vị trí tăng hơn 4 giây |
| Pause/resume iOS | Đạt: position khi pause lệch <100ms; tiếp tục tăng sau resume |
| Dừng/hoàn thành | Đạt: dừng không ghi completed; decoder phát đến cuối tạo đúng một buổi và dọn marker |
| Khởi động lại tiến trình | Đạt: buổi hoàn thành, lần nín thở và cài đặt giữ nguyên khi mở bản main.dart bình thường |
| UI | Đã kiểm tra screenshot tất cả màn, không phát hiện overflow trong integration test |

Integration dùng một kịch bản đầy đủ; framework báo +2 bao gồm teardown. Để kiểm tra hoàn thành nhanh, mã test seek decoder gần cuối WAV rồi chờ phát hết thật; production không có chức năng bỏ qua giai đoạn. Dữ liệu thử chỉ nằm trên Simulator QA.

Bằng chứng: `artifacts/ios/analyze.log`, `tests.log`, `build-simulator.log`, `build-release-unsigned.log`, `integration.log`, `background-check.txt`, `persistence-check.json`, `iphone-home.png`, `screenshots/`. Driver iOS dùng socket loopback trong **mã test** để điều khiển Simulator; không có socket/test server trong production.

## Cài iPhone thật

`build/ios/iphoneos/Runner.app` là build release **chưa ký**, không phải IPA có thể cài trực tiếp. Mở `ios/Runner.xcworkspace`, cấu hình Signing Team/bundle identifier/provisioning profile rồi chạy lên iPhone hoặc archive/export IPA/TestFlight. Không tuyên bố đã phát hành TestFlight/App Store hoặc có IPA đã ký.

Âm thanh nền đã xác minh bằng chuyển ứng dụng trên Simulator. Khóa màn hình, cuộc gọi thật, Bluetooth và chính sách hệ điều hành trên iPhone vật lý chưa được xác minh; chưa có iPhone thật kết nối trong phiên làm việc này. iPad chưa chạy thử riêng, dù rect chia sẻ và bố cục responsive đã được cấu hình.

Tài liệu tham khảo: [audio_service iOS setup](https://pub.dev/packages/audio_service#ios-setup), [Apple UIBackgroundModes](https://developer.apple.com/documentation/BundleResources/Information-Property-List/UIBackgroundModes), [share_plus iPad](https://pub.dev/packages/share_plus#ipad).
