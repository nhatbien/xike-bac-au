# Kết quả xác minh — 23/11/2026

## Phạm vi đã triển khai

Flutter native + GetX, không WebView: trang chủ, buổi thở, màn hoàn thành, nín thở vui, cài đặt, thống kê, lịch sử, chi tiết buổi, nhật ký và trang giới thiệu giữ bưu thiếp gốc. Có trạng thái rỗng/loading/lỗi/pause/completed và xác nhận khi dừng/xoá.

- Buổi thở tự chạy đủ pha và hiệp, timeline theo `lich.txt`, pause/resume theo vị trí decoder, hoạt ảnh 24 khung có smoothstep gốc.
- WAV dùng PCM gốc, 22.050 Hz mono 16-bit, sample offsets và nhạc fade/lặp theo lịch; dựng trong isolate, bộ nhớ theo block. Không TTS hoặc nén mất dữ liệu.
- Android foreground mediaPlayback service, media notification, audio focus, interruption và rút tai nghe; quyền thông báo chỉ được yêu cầu khi bắt đầu thở.
- Stopwatch monotonic, hiển thị 0,1 giây, vượt 60 giây, kỷ lục, trung bình 7 ngày, số lần hôm nay và xoá lần gần nhất. Chạm nhầm dưới 1 giây không ghi, như UI gốc.
- shared_preferences lưu cài đặt, buổi hoàn thành, lần nín thở và 300 log gần nhất. StorageService dùng SharedPreferencesWithCache, mã hóa dữ liệu thành JSON và chờ thao tác ghi của nền tảng hoàn tất trước khi xác nhận marker/kết quả. shared_preferences không bảo đảm dữ liệu đã bền vững trên đĩa ngay khi Future hoàn tất.
- Thống kê ngày/tuần/tháng/năm/tất cả, lọc và điều hướng quá khứ, lịch thứ Hai/năm nhuận, chuỗi ngày, kỷ lục và năm loại huy hiệu với ngày đạt suy từ dữ liệu thật.
- Share sheet nhật ký do người dùng chọn; không tự gửi ra ngoài.

## Kiểm tra đã chạy

| Kiểm tra | Kết quả |
|---|---|
| `flutter analyze` | Không có vấn đề |
| `flutter test` | 16 bài đạt: 11 core + 5 widget |
| Android debug build | Đạt |
| Android release build | Đạt, APK universal 73,4 MB; đã cài và mở trên emulator |
| Android integration | Đạt, một kịch bản đầy đủ; framework báo +2 gồm teardown |
| Phát khi khóa màn hình | Đạt: 5 giây khóa, player tiếp tục tăng vị trí; dumpsys xác nhận isForeground=true, media state=3 |
| Pause/resume | Đạt: vị trí không tăng khi pause (sai số kiểm tra <100ms), tiếp tục tăng sau resume |
| Dừng buổi | Đạt: không tạo buổi hoàn thành |
| Hoàn thành và lưu | Đạt: decoder được seek gần cuối bằng mã kiểm thử, phát hết thật, lưu một kết quả; production không cung cấp nút seek |
| Đóng/mở tiến trình | Đạt: một buổi và một lần thử vẫn còn; cấu hình khôi phục đúng |
| Process death giữa buổi | Đạt: active marker được dọn khi mở lại, có log gián đoạn, số buổi không tăng |
| Android share sheet release | Đạt: Gửi nhật ký mở ChooserActivity; không gửi dữ liệu |
| Visual regression | Đã render/chụp và đối chiếu cả 9 ảnh tham chiếu, có overlay/diff và MAE RGB |

Thiết bị kiểm thử: AVD riêng `Xike_QA_API33`, Android 13/API33, arm64, 1080×2400, density 420. Không xoá dữ liệu ứng dụng gốc trên AVD cũ. Source build: Flutter 3.47.9 / Dart 3.13.7, JDK21.

Bằng chứng trong `artifacts/`: analyze.log, tests.log, integration.log, build-debug.log, build-release.log, background-check.txt, process-restart.json, screenshots/, visual/metrics.json, ảnh comparison/overlay/diff. `flutter drive` mặc định gỡ ứng dụng khi xong; dùng `--keep-app-running` để giữ dữ liệu phục vụ bài kiểm tra khởi động lại.

## Cách đánh giá ảnh

Ảnh tham chiếu có 1080×2400 pixel, gồm system bars. Lượt cuối có thêm screenshot native từ chính APK release cho trang chủ, stopwatch, cài đặt, thống kê và nhật ký; chúng đủ 1080×2400. Hai ảnh buổi thở tiếp tục dùng capture từ integration test. PixelCopy của integration test trả surface Flutter 1080×2337, không có thanh navigation 63px và không lấy các icon status bar. Công cụ so sánh cắt phần navigation của ảnh tham chiếu, che status bar và so cùng pixel vật lý; không kéo giãn ảnh Flutter. Lưu cả ảnh cạnh nhau, overlay 50% và diff tăng tương phản.

Đã sửa qua các lượt ảnh: bảo toàn GSUB/GPOS của font ghép, chiều cao tiêu đề, padding viền card, kích thước icon, fit nội dung nút lớn, nấc slider phi tuyến, track gradient/viền/thumb giấy, chiều cao hàng thứ lịch và các nút bộ lọc. MAE chỉ là sai số RGB toàn ảnh, không phải phần trăm “giống” hay chứng nhận pixel-perfect.

## Khác biệt và giới hạn còn lại

- Rasterization font, shader gradient, nét đứt và shadow Flutter khác trình duyệt Android. Không tuyên bố pixel-perfect.
- Ảnh gốc stopwatch có kỷ lục 45,3 giây; ảnh kiểm thử dùng lần nín thực ~1,6 giây hoặc trạng thái rỗng. Không chèn kỷ lục giả vào production. Các nội dung động (giờ, log, số lần thử, dữ liệu thống kê) khác là có chủ đích.
- Bưu thiếp mở đầu của source mới được giữ trong trang Giới thiệu; màn đầu tiên mở thẳng menu theo ảnh 1. Mặc định giữ 40 giây theo ảnh, thay vì 15 giây trong Java nguyên bản.
- Source Java có thể lưu phần buổi dở. Theo yêu cầu rebuild, buổi dừng/gián đoạn không được đưa thành buổi hoàn thành. Không tự khôi phục buổi cũ sau process death.
- Toàn bộ ảnh, audio và font cần thiết đều có. Không cần asset thay thế.
- Đã kiểm tra trên emulator Android13. Cuộc gọi thật, Bluetooth thật, OEM battery policy và các phiên bản Android khác chưa được xác minh bằng thiết bị vật lý. Audio focus/lifecycle tương ứng đã được triển khai, không giả lập trạng thái thành công.
- Báo cáo Android bên trên ghi lại lượt bàn giao đầu tiên. iOS đã được bổ sung ở lượt tiếp theo; xem IOS_VALIDATION.md. Web scaffold không phải nền tảng được hỗ trợ.
- APK release hiện ký bằng debug key của scaffold để cài thử; chưa cấu hình khoá ký phát hành riêng hoặc phát hành lên store.

## Thư viện

Get, shared_preferences, just_audio, audio_service, audio_session, path_provider, share_plus, device_info_plus, package_info_plus, permission_handler, flutter_svg. Phiên bản cụ thể được khoá trong pubspec.lock. Giải thích vai trò và mapping trong SOURCE_ANALYSIS.md.

APK kiểm tra: `build/app/outputs/flutter-apk/app-release.apk`. SHA-256 được ghi ở `artifacts/APK.sha256`. Sau kiểm tra share sheet, app trên máy ảo QA được đưa về trạng thái rỗng/cấu hình mặc định; dữ liệu thử chỉ còn trong bằng chứng kiểm thử.
