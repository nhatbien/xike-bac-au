# PROMPT: REBUILD ỨNG DỤNG XÌ KE BẮC ÂU BẰNG FLUTTER + GETX

## 1. Vai trò và mục tiêu

Bạn là Senior Flutter Engineer, chuyên tái tạo ứng dụng Android từ ảnh chụp màn hình với độ chính xác pixel-perfect.

Tôi cung cấp bộ ảnh chụp màn hình của một ứng dụng có tên **Xì ke Bắc Âu**, một ứng dụng hướng dẫn tập thở theo phương pháp Wim Hof.

Nhiệm vụ của bạn:

1. Phân tích toàn bộ ảnh tham chiếu.
2. Xây dựng ứng dụng bằng **Flutter**, sử dụng **GetX làm giải pháp chủ đạo**.
3. Tái tạo giao diện sát ảnh gốc nhất có thể: màu sắc, font chữ, khoảng cách, kích thước, bố cục, bo góc, đường viền, đổ bóng, icon và animation.
4. Triển khai đầy đủ chức năng thực tế của ứng dụng.
5. Cho phép điều hướng và tương tác giữa tất cả màn hình.
6. Lưu trữ dữ liệu cục bộ để không mất lịch sử, cài đặt và thành tích khi khởi động lại ứng dụng.
7. Đảm bảo ứng dụng hoạt động tốt trên Android.

**Đây không phải nhiệm vụ thiết kế lại UI. Không tự ý sáng tạo giao diện khác ảnh gốc.**

## 2. Công nghệ bắt buộc

- Flutter, sử dụng phiên bản stable tương thích với môi trường dự án.
- Dart với null safety.
- GetX để quản lý state, dependency injection và navigation.
- GetStorage hoặc cơ chế local persistence phù hợp để lưu dữ liệu.
- Không sử dụng Provider, Riverpod hoặc Bloc.
- Ưu tiên Flutter widgets native.
- CustomPainter cho các thành phần đồ họa đặc biệt như đồng hồ bấm giờ.
- Không cần backend, Firebase hoặc tài khoản đăng nhập.
- Có thể sử dụng thư viện bổ sung khi thực sự cần thiết, nhưng phải giải thích lý do.

Nếu đã có source code, hãy kiểm tra cấu trúc trước khi chỉnh sửa. Không tự ý xóa những phần không liên quan.

## 3. Quy tắc tái tạo UI

### 3.1. Ảnh tham chiếu là nguồn chuẩn

Phân tích từng ảnh để xác định:

- Kích thước và tỷ lệ màn hình.
- Safe area, status bar và navigation bar.
- Khoảng cách giữa các thành phần.
- Padding, margin, spacing.
- Màu nền và gradient nếu có.
- Màu viền và kiểu viền.
- Border radius.
- Font family, font size, font weight, line height.
- Vị trí và kích thước icon.
- Chiều cao từng card và button.
- Alignment của tiêu đề, nội dung và hành động.
- Shadow và độ trong suốt.
- Trạng thái được chọn, không được chọn và vô hiệu hóa.

Không được thay thế tùy tiện:

- Đường viền nét đứt bằng viền liền.
- Font serif bằng font sans-serif.
- Icon riêng bằng icon Material không tương đồng.
- Màu pastel bằng màu Material mặc định.
- Bố cục tùy chỉnh bằng giao diện Material mặc định.

### 3.2. Design system

Xây dựng hệ thống style dùng chung.

Màu chủ đạo dựa trên ảnh:

- Background: kem rất nhạt.
- Primary text: nâu đậm.
- Secondary text: nâu xám.
- Primary action: cam san hô.
- Border: vàng be.
- Selected state: cam san hô.
- Accent teal: xanh ngọc trầm.
- Card background: trắng kem.
- Warning/highlight: vàng pastel.

**Không coi các mô tả màu trên là mã màu cuối cùng.** Phải lấy mẫu trực tiếp từ ảnh để xác định mã HEX gần nhất.

Typography:

- Tiêu đề lớn dùng font serif đậm.
- Tiêu đề card dùng font serif.
- Nội dung, button, label và mô tả dùng font sans-serif.
- Giữ nguyên toàn bộ nội dung tiếng Việt và dấu câu.
- Chọn font hỗ trợ đầy đủ dấu tiếng Việt, có hình dáng gần ảnh nhất.

Tạo các thành phần tái sử dụng:

- AppBackground
- AppHeader
- DashedBorderCard
- PrimaryActionCard
- RoundedOutlineButton
- AppSectionTitle
- SettingSliderCard
- BreathingProgressBar
- AchievementBadge
- TrainingCalendar
- EmptyStateCard

Cấu hình màu sắc, typography, kích thước và spacing phải tập trung trong một design system.

## 4. Danh sách màn hình cần triển khai

### SCREEN 1: Trang chủ

Tiêu đề:

**Xì ke bắc âu**

Phụ đề:

"thở cùng ông Wim · rảnh tay từ đầu tới cuối"

Thành phần:

**A. Thông báo trạng thái**

Card xanh pastel, viền nét đứt xanh ngọc.

Khi chưa có buổi tập:

"Chưa có buổi nào. Buổi đầu tiên chỉ mất chừng mười lăm phút."

Có icon bông tuyết ở bên trái.

Khi đã có dữ liệu, thay đổi nội dung phù hợp với thành tích và lịch tập.

**B. Nút bắt đầu thở**

Card lớn màu cam san hô.

- Icon gió.
- Tiêu đề: "Bắt đầu thở".
- Phụ đề động theo cài đặt.

Ví dụ:

"3 hiệp · nín 01:30 · giữ 40 giây · khoảng 14 phút"

Nhấn để bắt đầu buổi tập.

**C. Danh sách chức năng**

Tạo đúng thứ tự:

1. Nín thở vui
2. Cài đặt
3. Thống kê
4. Các buổi đã tập
5. Nhật ký

Mỗi card:

- Nền kem.
- Viền nét đứt vàng be.
- Icon nằm trong vòng tròn pastel.
- Tiêu đề serif đậm.
- Mô tả nhỏ hơn.
- Chevron bên phải.
- Toàn bộ card có thể nhấn.

**D. Footer**

Câu trích dẫn:

"Lúc muốn bỏ cuộc, thở thêm một nhịp nữa rồi hẵng tính."

Hiển thị tên ứng dụng, phiên bản và chú thích về phương pháp Wim Hof.

### SCREEN 2: Buổi tập thở

Đây là màn hình quan trọng nhất.

Bố cục:

**A. Background**

Hình ảnh một người ngồi thiền trước khung cảnh băng tuyết.

Ảnh phải phủ đúng khu vực như screenshot, dùng BoxFit.cover và căn chỉnh crop phù hợp.

Nếu chưa có đúng asset gốc, không được tự chọn ảnh khác rồi tuyên bố khớp hoàn toàn.

**B. Header overlay**

Hai nhãn dạng capsule:

Bên trái:

"Hiệp 1 / 3"

Bên phải:

"Chuẩn bị · 18:21"

Hai nhãn có nền trắng kem, viền vàng be.

**C. Bảng hướng dẫn phía dưới**

Card lớn có:

- Nền kem.
- Border nét đứt.
- Góc bo lớn.
- Tiêu đề lớn ở giữa.

Ví dụ:

"Ngồi thoải mái"

Mô tả:

"thả lỏng vai · 3 hiệp · nín 01:30 · giữ 40 giây"

Hai thanh tiến độ:

1. Tiến độ giai đoạn hiện tại.
2. Tiến độ toàn bộ buổi tập.

Hiển thị:

- Phần trăm hoàn thành.
- Thời gian còn lại.

Hai nút:

- Tạm dừng
- Dừng

Bên dưới có thông báo:

"Phím âm lượng bên hông máy: to / nhỏ tiếng · tắt màn hình vẫn thở tiếp"

**D. State machine của buổi thở**

Xây dựng luồng hoạt động:

PREPARING
→ GUIDED_BREATHING
→ EXHALE_AND_HOLD
→ RECOVERY_HOLD
→ NEXT_ROUND
→ COMPLETED

PAUSED và STOPPED là các trạng thái điều khiển riêng.

Chi tiết:

**PREPARING**

- Hướng dẫn tư thế ngồi.
- Hiển thị "Ngồi thoải mái".
- Đếm thời gian chuẩn bị nếu cần theo luồng tham chiếu.

**GUIDED_BREATHING**

- Hướng dẫn 40 nhịp thở sâu.
- Một nhịp dài khoảng 3,26 giây.
- Pha hít khoảng 1,7 giây.
- Pha thở ra khoảng 1,56 giây.
- Hiển thị nội dung tương ứng từng pha.
- Animation và tiến độ đồng bộ với nhịp thở.
- Hỗ trợ hướng dẫn bằng âm thanh.

**EXHALE_AND_HOLD**

- Hướng dẫn thở ra hết rồi nín.
- Đếm thời gian nín theo cấu hình.
- Hiển thị thời gian còn lại.

**RECOVERY_HOLD**

- Hướng dẫn hít sâu rồi giữ.
- Đếm ngược theo thời gian phục hồi được cấu hình.

**NEXT_ROUND**

- Tăng số hiệp.
- Tự động bắt đầu hiệp kế tiếp.
- Không yêu cầu người dùng thao tác.

**COMPLETED**

- Hiển thị trạng thái hoàn thành.
- Lưu kết quả buổi tập.
- Cập nhật thống kê, streak và huy hiệu.
- Cho phép quay về trang chủ.

**PAUSED**

- Dừng chính xác các bộ đếm.
- Tạm dừng âm thanh.
- Không mất tiến độ hiện tại.
- Tiếp tục chính xác từ thời điểm bị tạm dừng.

**STOPPED**

- Dừng buổi tập.
- Không ghi thành buổi hoàn thành.
- Ghi nhật ký sự kiện nếu cần.

**E. Thời gian chạy**

Không dựa vào việc tăng biến đếm mỗi giây bằng Timer.periodic như nguồn thời gian duy nhất.

Sử dụng thời gian thực tế, timestamp và elapsed duration để hạn chế sai lệch khi ứng dụng chạy nền.

Âm thanh và quá trình thở phải được xử lý nhất quán theo vòng đời ứng dụng.

Nếu cần tiếp tục phát âm thanh khi tắt màn hình Android, triển khai đúng Android audio foreground service, media notification và lifecycle.

Không được mặc định rằng Flutter Timer vẫn hoạt động chính xác khi Android đưa ứng dụng vào background.

### SCREEN 3: Nín thở vui

Màn hình đồng hồ bấm giờ.

**A. Header**

- Back button.
- Tiêu đề "Nín thở vui".

**B. Đồng hồ tròn**

Dựng bằng CustomPainter hoặc phương pháp tương đương để đạt giao diện gần như screenshot.

Bao gồm:

- Vòng ngoài nét đứt.
- Vòng tròn trong.
- Vạch chia thời gian.
- Vạch lớn tại các mốc.
- Các số 0, 15, 30, 45.
- Kim màu cam.
- Tâm kim tròn.
- Đồng hồ số nằm giữa.

Định dạng hiển thị:

`0:00,0`

Độ chính xác hiển thị 0,1 giây.

**C. Tương tác**

Trạng thái ban đầu:

"Hít thở vài hơi, thở ra hết, rồi chạm để bắt đầu nín"

Phụ đề:

"chạm vào mặt đồng hồ"

Khi chạm:

- Bắt đầu stopwatch.
- Kim đồng hồ chuyển động.
- Số thời gian cập nhật liên tục.
- Hiển thị hướng dẫn chạm để kết thúc.

Khi chạm lần nữa:

- Dừng stopwatch.
- Lưu một lần thử.
- Cập nhật kỷ lục nếu vượt thành tích cũ.

Không tự động dừng ở 60 giây. Đồng hồ phải tiếp tục hoạt động khi vượt một vòng.

**D. Thống kê bên dưới**

Card hiển thị:

- Kỷ lục cá nhân.
- Số lần thử hôm nay.
- Trung bình 7 ngày.
- Danh sách lần thử gần đây.

Dữ liệu lưu cục bộ, không mất khi mở lại app.

### SCREEN 4: Cài đặt buổi thở

Header:

"Cài đặt buổi thở"

**A. Số hiệp**

Các button từ 1 đến 10.

Bố cục grid 5 cột, 2 hàng.

Trạng thái được chọn:

- Background cam.
- Text trắng.
- Border cam đậm.

Trạng thái chưa chọn:

- Nền kem.
- Viền vàng be.
- Chữ nâu.

Mặc định: 3 hiệp.

**B. Nín thở mỗi hiệp**

Card riêng chứa:

- Tiêu đề.
- Giá trị lớn ở giữa.
- Slider màu pastel.
- Nhãn tối thiểu: 15 giây.
- Nhãn tối đa: 10 phút.
- Mô tả "thở ra hết rồi nín".

Cho phép chọn thời gian từ 15 đến 600 giây.

Giá trị cần hiển thị theo phút/giây phù hợp.

**C. Hít vào giữ (phục hồi)**

Card riêng chứa:

- Tiêu đề.
- Thời gian được chọn.
- Slider.
- Giá trị tối thiểu: 5 giây.
- Giá trị tối đa: 60 giây.
- Mô tả "hít đầy rồi giữ".

**D. Summary card**

Màu vàng pastel nổi bật.

Ví dụ:

"3 hiệp · nín 04:00 · giữ 40 giây"

"Một buổi dài khoảng 21 phút, nín tổng 12 phút."

Tự động tính toán khi thay đổi bất kỳ cấu hình nào.

Cần phân biệt:

- Thời gian nín tổng cộng.
- Thời gian giữ phục hồi.
- Thời gian thở dẫn.
- Thời gian chuẩn bị.
- Thời gian toàn buổi.

Không hardcode các con số 14 hoặc 21 phút.

**E. Hướng dẫn**

Card mô tả đầy đủ chuỗi:

Thở 40 nhịp sâu
→ Thở ra hết
→ Nín
→ Hít đầy và giữ
→ Thả ra
→ Hiệp mới

Hiển thị lưu ý an toàn như trong screenshot.

Lưu cài đặt ngay khi thay đổi, đồng bộ với trang chủ và buổi tập tiếp theo.

### SCREEN 5: Thống kê

Header:

"Thống kê"

**A. Bộ lọc thời gian**

- Hôm nay
- Tuần này
- Tháng này
- Năm này

Dạng segmented/pill control có thể cuộn ngang nếu cần.

Trạng thái được chọn:

Nền nâu đậm, chữ trắng kem.

**B. Điều hướng thời gian**

Ba nút:

- Trước
- Nay
- Sau

Cho phép di chuyển giữa các khoảng thời gian.

Không cho phép điều hướng sang tương lai vượt thời điểm hiện tại.

**C. Danh sách buổi tập**

Hiển thị các buổi thuộc khoảng thời gian đang chọn.

Nếu không có dữ liệu:

"Không có buổi nào trong khoảng này."

**D. Thành tích tổng**

Hiển thị:

- Kỷ lục nín thở trong buổi tập.
- Chuỗi ngày hiện tại.
- Chuỗi ngày dài nhất.

**E. Lịch tập**

Hiển thị lịch tháng với:

- Header ngày trong tuần.
- Grid 7 cột.
- Ngày hiện tại có viền xanh ngọc.
- Ngày có buổi tập được đánh dấu bằng sticker/màu.
- Ngày không tập sử dụng nền kem.

Tính toán đúng:

- Thứ bắt đầu là thứ Hai.
- Số ngày trong tháng.
- Năm nhuận.
- Ngày đầu tháng.
- Ngày hiện tại.

**F. Huy hiệu**

Các huy hiệu:

1. Buổi đầu tiên.
2. Nín 01:00.
3. Chuỗi 3 ngày.
4. 1 giờ tập.
5. 50 hiệp.

Mỗi huy hiệu có:

- Icon ngôi sao.
- Tên.
- Tiến độ.
- Trạng thái đạt/chưa đạt.
- Màu sắc tương ứng.

Tự động cập nhật huy hiệu khi dữ liệu tập luyện thay đổi.

### SCREEN 6: Các buổi đã tập

Tái sử dụng ngôn ngữ thiết kế của ứng dụng.

Hiển thị danh sách các buổi đã hoàn thành:

- Ngày giờ.
- Tổng thời gian.
- Số hiệp.
- Thời gian nín.
- Thời gian giữ phục hồi.
- Trạng thái hoàn thành.

Cho phép nhấn vào một buổi để xem chi tiết.

Sắp xếp mới nhất trước.

Khi chưa có dữ liệu, hiển thị trạng thái rỗng phù hợp.

Không tự tạo dữ liệu giả dưới dạng lịch sử thật.

### SCREEN 7: Nhật ký

Header:

"Nhật ký"

Mô tả:

"Có lỗi thì chụp màn này hoặc bấm “Gửi nhật ký” rồi gửi lại."

**A. Khối thông tin kỹ thuật**

Hiển thị thông tin thiết bị và ứng dụng:

- Tên và phiên bản app.
- Phiên bản Android.
- API level.
- Thông tin thiết bị.
- Trạng thái âm thanh.
- Số câu hướng dẫn.
- Số nhịp mỗi hiệp.
- Trạng thái preload.
- Số buổi tập đã ghi.
- Số lần thử nín thở.
- Cài đặt hiện tại.
- Trạng thái quyền thông báo.
- Trạng thái buổi đang chạy.
- Dung lượng bộ nhớ app.

**B. Nhật ký sự kiện**

Ghi nhận các sự kiện:

- Mở app.
- Thay đổi cài đặt.
- Bắt đầu buổi thở.
- Nạp âm thanh.
- Tạm dừng.
- Tiếp tục.
- Dừng buổi.
- Hoàn thành buổi.
- Bắt đầu/kết thúc nín thở vui.
- Lỗi runtime nếu có.

Mỗi sự kiện có timestamp.

Giới hạn số lượng log lưu trữ để tránh tăng dung lượng vô hạn.

**C. Gửi nhật ký**

Nút "Gửi nhật ký".

Khi nhấn:

- Tạo nội dung log dạng text.
- Bao gồm thông tin phiên bản và thiết bị.
- Mở Android share sheet để người dùng chia sẻ.
- Không tự động gửi dữ liệu ra ngoài.

Không ghi password, token hoặc thông tin nhạy cảm vào log.

## 5. Kiến trúc GetX

Tổ chức dự án theo dạng feature-first.

Cấu trúc gợi ý:

```text
lib/
  main.dart
  app/
    routes/
      app_routes.dart
      app_pages.dart
    bindings/
      initial_binding.dart
    theme/
      app_colors.dart
      app_typography.dart
      app_theme.dart
      app_dimensions.dart
    widgets/
      dashed_border_card.dart
      app_header.dart
      app_button.dart
      training_calendar.dart
      achievement_badge.dart
  core/
    services/
      storage_service.dart
      audio_service.dart
      logging_service.dart
      breathing_engine.dart
    utils/
      date_utils.dart
      time_formatter.dart
      duration_calculator.dart
  features/
    home/
      home_view.dart
      home_controller.dart
      home_binding.dart
    breathing/
      breathing_view.dart
      breathing_controller.dart
      breathing_binding.dart
    breath_hold/
      breath_hold_view.dart
      breath_hold_controller.dart
      breath_hold_binding.dart
      stopwatch_painter.dart
    settings/
      settings_view.dart
      settings_controller.dart
      settings_binding.dart
    statistics/
      statistics_view.dart
      statistics_controller.dart
      statistics_binding.dart
    sessions/
      sessions_view.dart
      sessions_controller.dart
      sessions_binding.dart
    logs/
      logs_view.dart
      logs_controller.dart
      logs_binding.dart
  data/
    models/
      breathing_settings.dart
      breathing_session.dart
      breath_hold_attempt.dart
      achievement.dart
      app_log.dart
    repositories/
      session_repository.dart
      settings_repository.dart
      statistics_repository.dart
assets/
  images/
  audio/
  fonts/
```

### Nguyên tắc kiến trúc

- View chỉ chịu trách nhiệm hiển thị.
- Controller xử lý trạng thái giao diện và tương tác.
- Service xử lý các chức năng dùng chung.
- Repository xử lý dữ liệu.
- Model biểu diễn dữ liệu.
- Dependency injection qua GetX Bindings.
- Sử dụng GetView, GetBuilder hoặc Obx phù hợp từng tình huống.
- Không nhét toàn bộ logic vào main.dart.
- Không đặt state quan trọng của buổi tập trong widget có thể bị dispose khi chuyển trang.
- Không tạo nhiều controller cùng quản lý một buổi thở.
- Dispose tài nguyên, subscription, audio player và timer đúng cách.
- Bảo đảm dữ liệu được cập nhật đồng bộ giữa các màn hình.

## 6. Mô hình dữ liệu

### BreathingSettings

```dart
class BreathingSettings {
  final int rounds;
  final int holdSeconds;
  final int recoverySeconds;
  final int breathsPerRound;
}
```

### BreathingSession

```dart
class BreathingSession {
  final String id;
  final DateTime startedAt;
  final DateTime completedAt;
  final int completedRounds;
  final int totalDurationSeconds;
  final int totalHoldSeconds;
  final int recoverySeconds;
  final bool isCompleted;
}
```

Có thể bổ sung dữ liệu từng hiệp nếu cần.

### BreathHoldAttempt

```dart
class BreathHoldAttempt {
  final String id;
  final DateTime createdAt;
  final int durationMilliseconds;
}
```

### Achievement

Phải đủ thông tin để xác định:

- Loại huy hiệu.
- Điều kiện mở khóa.
- Tiến độ hiện tại.
- Ngày đạt.
- Trạng thái mở khóa.

Không lưu tiến độ huy hiệu thành những giá trị hardcode không liên quan dữ liệu thực.

## 7. Xử lý âm thanh

Ứng dụng có chế độ hướng dẫn thở bằng âm thanh.

Yêu cầu:

- Thiết kế AudioService riêng.
- Có khả năng phát giọng nói hướng dẫn.
- Có khả năng phát âm thanh nhịp thở.
- Hỗ trợ pause/resume/stop.
- Không bị chồng âm.
- Không phát lặp do widget rebuild.
- Đồng bộ với trạng thái breathing engine.
- Preload những tài nguyên cần thiết trước khi phát.
- Xử lý audio focus, interruption và background playback trên Android.

Nếu không có file âm thanh gốc:

1. Kiểm tra các assets đã được cung cấp.
2. Nếu không có, báo rõ.
3. Dùng TTS hoặc tài nguyên thay thế có kiểm soát cho phần chức năng.
4. Không tuyên bố âm thanh giống bản gốc nếu chưa có nguồn chuẩn.

Không giả lập trạng thái audio thành công khi thực tế chưa phát được.

## 8. Xử lý thay đổi và khôi phục trạng thái

Ứng dụng phải hoạt động ổn định khi:

- Người dùng chuyển app sang background.
- Màn hình khóa.
- Người dùng tạm dừng rồi tiếp tục.
- Xoay màn hình nếu được hỗ trợ.
- Android thay đổi vòng đời Activity.
- Người dùng nhấn Back.
- Ứng dụng bị hệ điều hành kết thúc tiến trình.

Phải xác định rõ lúc nào có thể khôi phục một buổi tập và lúc nào buổi tập phải được đánh dấu là gián đoạn.

Không ghi một buổi bị gián đoạn thành hoàn thành.

## 9. Responsive

Ảnh tham chiếu là giao diện Android dạng portrait.

Ưu tiên tái tạo chính xác trên kích thước tham chiếu trước.

Sau đó hỗ trợ các kích thước khác:

- Không overflow.
- Không cắt chữ.
- Không đè nội dung.
- Không bị che bởi navigation bar.
- Không làm thay đổi tỷ lệ các thành phần quan trọng.

Sử dụng LayoutBuilder, MediaQuery và các constraint phù hợp.

Không scale toàn bộ giao diện theo một tỷ lệ cố định khiến text và touch target sai trên những thiết bị khác.

## 10. Kiểm thử

### Unit tests

Kiểm thử:

- Tính thời gian buổi tập.
- Chuyển trạng thái các pha thở.
- Pause/resume.
- Chuyển hiệp.
- Định dạng thời gian.
- Kỷ lục nín thở.
- Tổng thời gian tập.
- Chuỗi ngày liên tiếp.
- Điều kiện huy hiệu.
- Lọc thống kê theo thời gian.

### Widget tests

Kiểm thử:

- Điều hướng các màn hình.
- Thay đổi số hiệp.
- Slider thời gian nín.
- Slider giữ phục hồi.
- Đồng hồ bấm giờ.
- Các trạng thái trống.
- Card và button quan trọng.

### Visual regression

Đây là phần bắt buộc.

Với mỗi ảnh tham chiếu:

1. Render màn hình Flutter tương ứng.
2. Chụp screenshot trên cùng kích thước viewport.
3. So sánh với ảnh gốc.
4. Phân tích chênh lệch.
5. Chỉnh sửa.
6. Lặp lại đến khi đạt mức tương đồng cao nhất có thể.

Các yếu tố ưu tiên:

- Font và hình dáng chữ.
- Bố cục tổng thể.
- Chiều cao card.
- Padding.
- Spacing.
- Màu sắc.
- Border nét đứt.
- Background image.
- Icon.
- Căn chỉnh.

Không chỉ kiểm tra bằng mắt rồi kết luận pixel-perfect.

Có thể dùng image diff, overlay và các chỉ số sai lệch để hỗ trợ đánh giá.

## 11. Quy tắc triển khai

Làm việc theo trình tự:

**Giai đoạn 1: Phân tích**

- Đọc toàn bộ ảnh.
- Xác định các màn hình và trạng thái.
- Lập bảng component.
- Xác định design tokens.
- Xác định assets còn thiếu.

**Giai đoạn 2: Khởi tạo**

- Thiết lập Flutter project.
- Cài GetX và dependency cần thiết.
- Tạo theme.
- Tạo routes, bindings.
- Tạo data models và local storage.

**Giai đoạn 3: UI**

- Dựng trang chủ.
- Dựng màn hình thở.
- Dựng đồng hồ.
- Dựng cài đặt.
- Dựng thống kê.
- Dựng lịch sử.
- Dựng nhật ký.

**Giai đoạn 4: Chức năng**

- Breathing engine.
- Audio.
- Stopwatch.
- Persistence.
- Statistics.
- Achievements.
- Logging.

**Giai đoạn 5: Hoàn thiện**

- Chạy flutter analyze.
- Chạy flutter test.
- Build Android.
- So sánh screenshot.
- Sửa các lỗi và sai lệch.
- Kiểm tra tương tác thực tế.

## 12. Tiêu chí nghiệm thu

Chỉ coi nhiệm vụ hoàn thành khi:

- [ ] Tất cả màn hình được triển khai.
- [ ] UI khớp sát ảnh tham chiếu.
- [ ] GetX là state management chủ đạo.
- [ ] Toàn bộ điều hướng hoạt động.
- [ ] Các card và button có chức năng thật.
- [ ] Stopwatch hoạt động chính xác.
- [ ] Luồng thở hoạt động theo từng pha.
- [ ] Pause/resume không làm sai thời gian.
- [ ] Cài đặt được lưu và áp dụng.
- [ ] Lịch sử buổi tập được lưu.
- [ ] Thống kê sử dụng dữ liệu thật.
- [ ] Huy hiệu tự động mở khóa.
- [ ] Nhật ký ghi nhận sự kiện thật.
- [ ] Audio xử lý đúng vòng đời ứng dụng.
- [ ] Không có overflow.
- [ ] Không có lỗi nghiêm trọng từ flutter analyze.
- [ ] Các bài kiểm thử cốt lõi chạy thành công.
- [ ] Android build thành công.

## 13. Yêu cầu đặc biệt

**KHÔNG ĐƯỢC:**

- Chỉ dựng UI rồi bỏ qua logic.
- Tạo các nút không có hành động.
- Hardcode dữ liệu thống kê để trông giống ảnh.
- Tự ý thay đổi thiết kế.
- Dùng font mặc định khi ảnh sử dụng font khác rõ ràng.
- Bỏ qua các trạng thái empty, loading, completed.
- Dùng một ảnh toàn màn hình thay cho các Flutter widget thật.
- Tuyên bố đã chạy test nếu chưa thực sự chạy.
- Tuyên bố pixel-perfect nếu chưa đối chiếu screenshot.
- Giả định có âm thanh hoặc ảnh gốc khi assets chưa được cung cấp.

**BẮT BUỘC:**

- Ưu tiên độ trung thực của giao diện.
- Giữ nguyên nội dung tiếng Việt.
- Có kiến trúc rõ ràng, dễ bảo trì.
- Có thể thay đổi màu và font tập trung.
- Có thể mở rộng tính năng sau này.
- Không để business logic phụ thuộc trực tiếp widget.
- Báo cáo những chỗ chưa thể tái tạo chính xác do thiếu tài nguyên hoặc thông tin.

## 14. Cách phản hồi khi triển khai

Không chỉ trả về hướng dẫn hoặc pseudocode.

Hãy tạo/chỉnh sửa trực tiếp source code Flutter trong workspace đang làm việc.

Sau khi triển khai, báo cáo:

1. Các màn hình đã hoàn thành.
2. Các chức năng đã hoàn thành.
3. Các thư viện đã sử dụng.
4. Các assets còn thiếu.
5. Kết quả chạy analyze/test/build.
6. Những khác biệt còn tồn tại so với ảnh gốc.

**Nếu gặp điểm không thể xác định từ ảnh, phải hỏi tôi thay vì tự bịa ra hành vi hoặc tuyên bố đã tái tạo chính xác.**

Mục tiêu cuối cùng: một ứng dụng Flutter + GetX chạy được, có giao diện giống ảnh tham chiếu nhất có thể, với logic sử dụng thực tế.