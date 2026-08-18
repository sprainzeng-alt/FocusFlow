DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool isSameDay(DateTime a, DateTime b) => startOfDay(a) == startOfDay(b);

String formatDeadline(DateTime? deadline) {
  if (deadline == null) {
    return '无截止';
  }
  final today = startOfDay(DateTime.now());
  final day = startOfDay(deadline);
  if (day == today) {
    return '今天截止';
  }
  if (day == today.add(const Duration(days: 1))) {
    return '明天截止';
  }
  if (day.isBefore(today)) {
    return '已逾期';
  }
  return '${deadline.month}/${deadline.day} 截止';
}

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
