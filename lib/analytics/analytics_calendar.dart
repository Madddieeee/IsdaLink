/// Analytics uses the Caraga business calendar (Philippines, UTC+08:00).
/// Calendar dates use UTC-tagged fields to avoid the host/device timezone
/// changing their day or duration arithmetic. They are calendar labels, not
/// timestamps to convert back to local time.
DateTime analyticsBusinessDate(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 8));

DateTime analyticsPeriodStart(DateTime calendarDate, {required bool monthly}) {
  if (monthly) return DateTime.utc(calendarDate.year, calendarDate.month);
  final day = DateTime.utc(
    calendarDate.year,
    calendarDate.month,
    calendarDate.day,
  );
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

bool isClosedAnalyticsPeriod(
  DateTime calendarDate, {
  required DateTime now,
  required bool monthly,
}) => analyticsPeriodStart(
  calendarDate,
  monthly: monthly,
).isBefore(analyticsPeriodStart(analyticsBusinessDate(now), monthly: monthly));
