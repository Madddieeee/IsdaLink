import 'analytics_calendar.dart';

/// Current planning estimates the current open business-calendar period using
/// preceding closed observations. Historical targets require explicit selection.
class AnalyticsForecastTarget {
  const AnalyticsForecastTarget({required this.date, required this.historical});
  final DateTime date;
  final bool historical;
}

AnalyticsForecastTarget analyticsForecastTarget({
  required DateTime now,
  required bool monthly,
  DateTime? historicalPeriod,
}) {
  final current = analyticsPeriodStart(
    analyticsBusinessDate(now),
    monthly: monthly,
  );
  if (historicalPeriod == null) {
    return AnalyticsForecastTarget(date: current, historical: false);
  }
  final selected = analyticsPeriodStart(historicalPeriod, monthly: monthly);
  if (!selected.isBefore(current)) {
    throw ArgumentError('Historical selection must be a closed period.');
  }
  return AnalyticsForecastTarget(
    date: monthly
        ? DateTime.utc(selected.year, selected.month + 1)
        : selected.add(const Duration(days: 7)),
    historical: true,
  );
}
