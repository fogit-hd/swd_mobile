String formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

DateTime mondayOfWeek(DateTime date) {
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: date.weekday - DateTime.monday));
}

String weekStartOf(DateTime date) => formatDate(mondayOfWeek(date));

String dayLabel(int dayOfWeek) {
  return switch (dayOfWeek) {
    1 => 'T2',
    2 => 'T3',
    3 => 'T4',
    4 => 'T5',
    5 => 'T6',
    6 => 'T7',
    7 => 'CN',
    _ => 'T$dayOfWeek',
  };
}
