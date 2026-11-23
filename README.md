# Xì ke bắc âu — Flutter + GetX

Ứng dụng Android và iOS native, offline, port từ tài nguyên web/PCM được cung cấp. Không dùng WebView.

## Chạy

```sh
flutter pub get
flutter run -d <android-device-id>
```

Flutter đã xác minh: 3.47.9 stable, Dart 3.13.7, JDK 21. Android minSdk theo Flutter (24), compile/target SDK theo Flutter (36). `permission_handler` giữ nhánh 12 vì nhánh 13 yêu cầu SDK 37. `pubspec.lock` được giữ để build tái lập.

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

Integration test chạy trên emulator chuyên kiểm thử, cài app và tạo dữ liệu thử trong sandbox của app. Driver khóa màn hình 5 giây để xác minh background playback. Đường dẫn adb trong driver dành cho máy workspace này; thay nếu chạy máy khác. Để chạy lại từ trạng thái rỗng: `adb shell pm clear vn.xike.xike_bac_au` trên emulator kiểm thử.

Ảnh kiểm thử ở `artifacts/screenshots/`, overlay/diff và số đo ở `artifacts/visual/`. Chạy `python tools/compare_screenshots.py` bằng Python có Pillow sau integration test.

## Kiến trúc

- `lib/app`: theme, native widgets dùng chung, GetX routes và khởi tạo dependency.
- `lib/features`: view/controller theo tính năng.
- `lib/core/services`: lưu trữ, log, parse lịch, dựng WAV trong isolate, bộ máy thở, media handler.
- `lib/data`: model JSON, repositories và thống kê.
- `docs/SOURCE_ANALYSIS.md`: phân tích đầu vào, quyết định port và mapping.
- `docs/VALIDATION.md`: kết quả xác minh và giới hạn.

Cài đặt, buổi hoàn thành, lần nín thở và tối đa 300 log lưu bằng GetStorage. Không có dữ liệu mẫu trong source production. Lịch tập bắt đầu thứ Hai; lọc tuần/tháng/năm theo thời gian địa phương.

Âm thanh PCM gốc được trộn thành WAV mono 22.050 Hz, 16-bit theo `lich.txt`, không nén lại, không TTS. Chỉ giữ một WAV cache. Thời gian chuẩn bị, thở, nín, giữ, chuyển hiệp và thư giãn cuối buổi cùng nằm trên timeline âm thanh. `AudioPlayer.position` điều khiển UI; timer chỉ vẽ. Bộ máy không phụ thuộc widget. Android audio_service foreground service giữ phát khi khóa màn hình; thông báo hỗ trợ tạm dừng/tiếp tục/dừng; audio focus xử lý cuộc gọi và rút tai nghe. Buổi dừng hoặc bị process death không được ghi hoàn thành.

Dữ liệu được ghi trước khi đánh dấu kết quả hoàn thành; marker buổi đang chạy được dọn sau ghi. Nếu process bị kết thúc, lần mở tiếp theo ghi log gián đoạn. Không tự khôi phục buổi cũ hoặc âm thanh khi người dùng chưa chọn.

## Assets và giấy phép

Dùng lại đủ 24 khung ảnh, ảnh bưu thiếp, hai PCM và lịch gốc. TTF được ghép từ các subset WOFF2 bằng `tools/prepare_fonts.py` (fontTools, brotli); giấy phép OFL vẫn nằm trong assets. Tài nguyên source gốc được giữ nguyên. Quyền phân phối ảnh/giọng gốc phụ thuộc tài nguyên người dùng cung cấp.

APK release hiện dùng debug signing từ scaffold, phù hợp cài thử nội bộ. Khi phát hành store cần signing key phát hành của chủ ứng dụng. Các target được triển khai là Android và iOS; thư mục web scaffold không phải nền tảng được hỗ trợ.
