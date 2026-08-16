DateTime startOfDay(DateTime value) => DateTime(value.year, value.month, value.day);

bool isSameDay(DateTime a, DateTime b) => startOfDay(a) == startOfDay(b);

String formatMinutes(int minutes) {
  if (minutes < 60) {
    return '${minutes}min';
  }
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) {
    return '${hours}h';
  }
  return '${hours}h ${rest}min';
}
