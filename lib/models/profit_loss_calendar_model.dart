class ProfitLossCalendarModel {
  final Map<DateTime, double> dailyNet;

  const ProfitLossCalendarModel({required this.dailyNet});

  double valueFor(DateTime date) {
    return dailyNet[DateTime(date.year, date.month, date.day)] ?? 0;
  }

  double totalForMonth(DateTime month) {
    return dailyNet.entries
        .where(
          (entry) =>
              entry.key.year == month.year && entry.key.month == month.month,
        )
        .fold(0, (total, entry) => total + entry.value);
  }

  int profitableDaysForMonth(DateTime month) {
    return dailyNet.entries
        .where(
          (entry) =>
              entry.key.year == month.year &&
              entry.key.month == month.month &&
              entry.value > 0,
        )
        .length;
  }

  int losingDaysForMonth(DateTime month) {
    return dailyNet.entries
        .where(
          (entry) =>
              entry.key.year == month.year &&
              entry.key.month == month.month &&
              entry.value < 0,
        )
        .length;
  }
}
