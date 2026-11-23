String clock(int seconds) {
  final s = seconds.clamp(0, 999999);
  return '${s >= 3600 ? '${s ~/ 3600}:' : ''}${(s ~/ 60 % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

String stopwatchText(int ms) =>
    '${ms ~/ 60000}:${(ms ~/ 1000 % 60).toString().padLeft(2, '0')},${ms % 1000 ~/ 100}';
String durationLabel(int s) => s < 60
    ? '$s giây'
    : s % 60 == 0
    ? '${s ~/ 60} phút'
    : '${s ~/ 60} phút ${s % 60} giây';
String dateLabel(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
