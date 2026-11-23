# Phân tích nguồn và quyết định port

Đã đọc index.html, toàn bộ app.css/app.js, fonts.css, lich.txt; kiểm tra cả 24 khung JPEG, dau.jpg và 9 screenshot 1080×2400. Hai bộ am-thanh có cùng nội dung (kiểm chứng SHA-256 trong quá trình triển khai).

## Nguồn và giới hạn
HTML chỉ là shell. app.js dựng 9 trạng thái giao diện và gọi window.App sang Java để lấy cài đặt, thống kê, chạy dịch vụ, lưu dữ liệu. Ban đầu không có source Java trong workspace. Sau đó phát hiện ứng dụng gốc `com.nguyenlong.xikebacau` 1.0.0 đã cài trên máy ảo Pixel_8a_API_33; đã đọc APK của chính ứng dụng bằng jadx để đối chiếu các lớp CaiDat, KeHoach, NhipTho, Chay, Tron, Du, Ngay, HuyHieu và ThongKe. SHA-256 APK: `9694a869d6e6205c5e7fafa00d4e416f98dd9ac567b78dede1c0d0e8b538f4b2`. Không sửa dữ liệu hoặc cài đặt app gốc. Máy ảo QA riêng được tạo cho Flutter.

Java xác nhận chu kỳ thở lặp ba bản, fade âm thanh, công thức timeline, các nấc slider và smoothstep `t*t*(3-2*t)`. Flutter dùng đúng danh sách NIN [15,30,45,60,75,90,105,120,135,150,165,180,210,240,270,300,360,420,480,540,600] và GIU [5,10,15,20,25,30,35,40,45,50,60]. Java cho phép lưu buổi dở; bản Flutter theo yêu cầu chỉ đưa buổi hoàn thành vào lịch sử và thống kê. Java mặc định giữ 15s, screenshot cấu hình đã lưu 40s: bản Flutter dùng 40s để khớp trạng thái mẫu.

Thời lượng âm thanh lấy từ lịch gốc, không ước đoán 40×3,26 là toàn bộ pha thở.

Source mới có bưu thiếp mở đầu không xuất hiện ở ảnh 1; để khớp ảnh, trang chính mở tại menu, bưu thiếp và nguyên văn câu dẫn được giữ ở phần Giới thiệu mở từ footer. Source fallback giữ 15 giây trong khi screenshot và yêu cầu dùng 40 giây: mặc định Flutter là 40 giây. Các ảnh cài đặt chụp mức nín 4 phút, ảnh buổi tập/trang chủ là 90 giây: đây là hai trạng thái cài đặt, không hardcode 4 phút làm mặc định.

## Thiết kế
Màu CSS: nền #FBF3E4, giấy #FFF9EE, mực #3B2A20, chữ phụ #8A7262, viền #CDB58D, san hô #E07A5F, bạc hà #7FB7A4, xanh ngọc #3F8C86, vàng nhạt #F6E2B0. Lora 400–700 cho heading, Be Vietnam Pro 400/500/600/700 cho nội dung. Font WOFF2 tách unicode được chuyển và ghép thành TTF offline bằng fontTools, giữ giấy phép OFL. Card viền đứt 2px, radius 18px, padding 14×16; nội dung max-width 640px. Khung buổi tập aspect 4:5, crop dọc 60%, cao tối đa 58vh. Animation trộn 24 khung theo độ đầy phổi.

## Âm thanh
Metadata lich.txt xác nhận s16le mono 22050 Hz. giong có 5.305.947 mẫu; nhac 3.693.375 mẫu. Lịch gồm câu có độ dài ms và sự kiện dat(offset ms, sample start, sample count). Hệ số giọng 0.819746, nhạc 0.170038. Nhạc lặp, fade-in 44.100 mẫu, fade-out 132.300 mẫu. Trộn theo clamp(round((voice*gv + music*gm)*32767)), PCM /32768.

Dựng WAV lossless theo cấu hình trong isolate, ghi từng block để tránh giữ toàn buổi trong RAM. Các đoạn giọng đặt đúng sample floor(ms*441/20). Chuẩn bị 19.470ms; thở 135.500/135.550/135.500ms, từ hiệp 4 lặp mẫu thở theo chu kỳ 3 (đã xác nhận KeHoach.tepTho); chuyển hiệp theo tha-ra-2…10; kết thúc 31.870ms. Nín chèn nin-cuoi-30 khi >=45s hoặc nin-cuoi-10 khi >=20s, kết thúc đúng cuối pha; các câu giữa chỉ chèn khi đủ chỗ và cách câu cuối 1s. Giữ chèn hit-vao nếu đủ chỗ và giu-cuoi khi >=8s; khoảng đệm 2.205 mẫu. Không TTS.

Player âm thanh là nguồn vị trí của engine; timer chỉ yêu cầu vẽ lại. AudioService foreground mediaPlayback, media notification, wake lock và audio focus/interruption qua audio_session. Pause giữ nguyên vị trí WAV. Dấu buổi đang chạy được lưu trước play; sau process death đánh dấu gián đoạn và không tự ghi hoàn thành. Activity bị huỷ trong khi foreground service còn sống vẫn dùng chung engine. Không tự resume buổi từ process cũ.

## Mapping
| Nguồn | Flutter/GetX |
|---|---|
| MAN.chinh, .muc, .nut-lon | HomeView/HomeController, PrimaryActionCard, menu dùng SVG gốc |
| MAN.buoi, canvas khung, window.App.buoi | BreathingView/BreathingController, BreathingEngine, TrainingAudioHandler |
| lịch cau/dat, PCM | AudioManifest, SessionTimeline, AudioRenderer |
| MAN.xong/chitiet/ds | SessionDetailView, SessionsView, SessionRepository |
| MAN.ninvui + SVG đồng hồ | BreathHoldController + Stopwatch monotonic + StopwatchPainter |
| MAN.caidat | SettingsController, SettingsRepository, SettingSliderCard |
| MAN.thongke | StatisticsController/Repository, TrainingCalendar, AchievementBadge |
| MAN.nhatky, chiaSe | LoggingService, DeviceInfo, Share sheet |
| window.App persistence | shared_preferences, model JSON, ghi ngay khi thay đổi |

## Thư viện
Get: DI/state/navigation; shared_preferences: lưu cục bộ; just_audio: WAV playback; audio_service: foreground service/media controls; audio_session: focus/interruption; path_provider: cache; flutter_svg: icon SVG gốc; share_plus: share sheet; device_info_plus/package_info_plus: thông tin thật; permission_handler: kiểm tra/xin quyền thông báo Android. Không WebView/backend.

Lịch âm thanh cộng dồn số mẫu từng đoạn như Tron.lap; phần lẻ dưới một mẫu được xử lý ở từng đoạn, không cộng ms rồi đổi một lần. WAV dùng số mẫu thực cho độ dài RIFF. Font TTF giữ cả GSUB/GPOS sau khi ghép subset, gồm kerning và positioning.
