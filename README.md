# Xì ke bắc âu — Flutter + GetX

Ứng dụng Android và iOS native, offline, port từ tài nguyên web/PCM được cung cấp. Không dùng WebView.

App yêu cầu mã mời ở lần mở đầu. Danh sách mã nằm trong `lib/config/invite_codes.dart`, hiện có `max` và `chuotbu`. Mã không phân biệt chữ hoa/thường, bỏ khoảng trắng ở hai đầu; kích hoạt lưu trên thiết bị nên lần sau không cần nhập lại. Xóa dữ liệu app sẽ cần nhập lại. Sửa danh sách phải build và cài bản mới; mã đã lưu chỉ còn hợp lệ nếu vẫn nằm trong danh sách của bản đang chạy. Mã dùng chung, hoạt động offline và không có giới hạn số người dùng hoặc thu hồi từ xa. Bundle ID iOS/applicationId Android: `max.xike.hihi`.

## Chạy

```sh
flutter pub get
flutter run -d <android-device-id>
```

Flutter đã xác minh: 3.47.9 stable, Dart 3.13.7, JDK 21. Android minSdk theo Flutter (24), compile/target SDK theo Flutter (36). `permission_handler` giữ nhánh 12 vì nhánh 13 yêu cầu SDK 37. `pubspec.lock` được giữ để build tái lập.

## Sao lưu và chuyển máy

Vào Cài đặt → Sao lưu & chuyển dữ liệu → Xuất dữ liệu ra file. Chọn Lưu vào Tệp/lưu trên máy hoặc AirDrop để giữ file `xike-backup-<thời gian>.json`. Trên máy mới, nhập mã mời rồi vào cùng mục → Nhập dữ liệu từ file và chọn file đã chuyển. Tính năng không dùng backend hoặc mạng; file cần sẵn trên thiết bị nếu dùng offline.

File gồm cài đặt bài tập, lịch sử buổi thở và các lần nín thở. Không chứa mã mời, xác nhận an toàn, nhật ký kỹ thuật hoặc buổi đang chạy. App kiểm tra định dạng, phiên bản và dữ liệu trước khi hiện xác nhận. Nhập sẽ **thay thế** cài đặt và lịch sử hiện tại; nên xuất dữ liệu hiện tại trước nếu cần giữ. Không cho nhập khi đang tập. Hỗ trợ file tối đa 20 MB, cập nhật màn hình ngay sau khi nhập thành công.

File JSON không mã hóa; hãy chọn nơi lưu và người nhận phù hợp. App không tự gửi file. Việc sửa/gỡ app không xóa những file đã xuất ra ngoài.

## Chạy iOS

```sh
flutter devices
flutter run -d <iphone-simulator-id>
flutter build ios --simulator
flutter build ios --release --no-codesign
open ios/Runner.xcworkspace
```

iOS tối thiểu 15.0. Target `Runner` dùng Swift Package Manager theo Flutter stable hiện tại. Tên app và icon giữ cùng thiết kế Android. `UIBackgroundModes = audio` và AVAudioSession playback qua audio_session hỗ trợ phát nền/Now Playing. Không xin quyền notification trên iOS chỉ để phát audio.

Build `--no-codesign` dùng để xác minh bản release cho CPU iPhone, không phải IPA cài trực tiếp. Để chạy iPhone thật hoặc xuất IPA/TestFlight, chọn Signing Team và provisioning profile phù hợp trong Xcode rồi archive/export. Build Simulator không cần tài khoản Apple Developer.

```sh
flutter drive --keep-app-running --driver=test_driver/ios_integration_test.dart --target=integration_test/app_test.dart -d <iphone-simulator-id>
```

Driver iOS dùng socket loopback cục bộ chỉ trong mã kiểm thử để chuyển qua Settings 5 giây rồi trở về, kiểm tra vị trí âm thanh vẫn tăng. Không có server/socket kiểm thử trong ứng dụng production. Bằng chứng iOS nằm ở `artifacts/ios/`.

## Kiểm tra

```sh
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter drive --keep-app-running --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d <emulator-id>
```

Integration test chạy trên emulator chuyên kiểm thử, cài app và tạo dữ liệu thử trong sandbox của app. Driver khóa màn hình 5 giây để xác minh background playback. Đường dẫn adb trong driver dành cho máy workspace này; thay nếu chạy máy khác. Để chạy lại từ trạng thái rỗng: `adb shell pm clear max.xike.hihi` trên emulator kiểm thử.

Ảnh kiểm thử ở `artifacts/screenshots/`, overlay/diff và số đo ở `artifacts/visual/`. Chạy `python tools/compare_screenshots.py` bằng Python có Pillow sau integration test.

## Kiến trúc

- `lib/app`: theme, native widgets dùng chung, GetX routes và khởi tạo dependency.
- `lib/features`: view/controller theo tính năng.
- `lib/core/services`: lưu trữ, log, parse lịch, dựng WAV trong isolate, bộ máy thở, media handler.
- `lib/data`: model JSON, repositories và thống kê.
- `docs/SOURCE_ANALYSIS.md`: phân tích đầu vào, quyết định port và mapping.
- `docs/VALIDATION.md`: kết quả xác minh và giới hạn.

Cài đặt, buổi hoàn thành, lần nín thở, mã mời và tối đa 300 log lưu bằng shared_preferences (SharedPreferencesWithCache), dữ liệu phức hợp mã hóa thành JSON. Bản này dùng kho dữ liệu mới, không đọc hoặc chuyển dữ liệu từ thư viện lưu trữ cũ. Không có dữ liệu mẫu trong source production. Lịch tập bắt đầu thứ Hai; lọc tuần/tháng/năm theo thời gian địa phương.

Âm thanh PCM gốc được trộn thành WAV mono 22.050 Hz, 16-bit theo `lich.txt`, không nén lại, không TTS. Chỉ giữ một WAV cache. Thời gian chuẩn bị, thở, nín, giữ, chuyển hiệp và thư giãn cuối buổi cùng nằm trên timeline âm thanh. `AudioPlayer.position` điều khiển UI; timer chỉ vẽ. Bộ máy không phụ thuộc widget. Android audio_service foreground service giữ phát khi khóa màn hình; thông báo hỗ trợ tạm dừng/tiếp tục/dừng; audio focus xử lý cuộc gọi và rút tai nghe. Buổi dừng hoặc bị process death không được ghi hoàn thành.

Dữ liệu được ghi trước khi đánh dấu kết quả hoàn thành; marker buổi đang chạy được dọn sau ghi. Nếu process bị kết thúc, lần mở tiếp theo ghi log gián đoạn. Không tự khôi phục buổi cũ hoặc âm thanh khi người dùng chưa chọn.

## Assets và giấy phép

Dùng lại đủ 24 khung ảnh, ảnh bưu thiếp, hai PCM và lịch gốc. TTF được ghép từ các subset WOFF2 bằng `tools/prepare_fonts.py` (fontTools, brotli); giấy phép OFL vẫn nằm trong assets. Tài nguyên source gốc được giữ nguyên. Quyền phân phối ảnh/giọng gốc phụ thuộc tài nguyên người dùng cung cấp.

APK release hiện dùng debug signing từ scaffold, phù hợp cài thử nội bộ. Khi phát hành store cần signing key phát hành của chủ ứng dụng. Các target được triển khai là Android và iOS; thư mục web scaffold không phải nền tảng được hỗ trợ.

## Chính sách và hỗ trợ

Chính sách quyền riêng tư, điều khoản và hỗ trợ đọc offline từ Cài đặt. Lần mở đầu tiên có cảnh báo an toàn; cả hai chế độ tập yêu cầu xác nhận trước khi sử dụng. Nội dung dùng chung tại `assets/legal/content.json`. Xem [hướng dẫn xuất HTML và tự host](docs/LEGAL_RELEASE.md).
