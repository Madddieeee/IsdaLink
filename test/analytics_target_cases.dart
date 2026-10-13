import 'package:isdalink/analytics/forecast_target.dart';

void check(bool condition) {
  if (!condition) throw StateError('Forecast target mismatch');
}

final analyticsTargetCases = <String, void Function()>{
  'Weekly default targets current open week, regardless of stale data': () {
    final target = analyticsForecastTarget(
      now: DateTime.utc(2026, 10, 9),
      monthly: false,
    );
    check(!target.historical && target.date == DateTime.utc(2026, 10, 5));
  },
  'Monthly default targets current open calendar month': () {
    final target = analyticsForecastTarget(
      now: DateTime.utc(2026, 10, 9),
      monthly: true,
    );
    check(!target.historical && target.date == DateTime.utc(2026, 10));
  },
  'Explicit weekly history targets the following historical week': () {
    final target = analyticsForecastTarget(
      now: DateTime.utc(2026, 10, 9),
      monthly: false,
      historicalPeriod: DateTime.utc(2026, 8, 17),
    );
    check(target.historical && target.date == DateTime.utc(2026, 8, 24));
  },
  'Explicit monthly history targets the following historical month': () {
    final target = analyticsForecastTarget(
      now: DateTime.utc(2026, 10, 9),
      monthly: true,
      historicalPeriod: DateTime.utc(2026, 8),
    );
    check(target.historical && target.date == DateTime.utc(2026, 9));
  },
  'Latest closed week still targets current planning week': () {
    final target = analyticsForecastTarget(
      now: DateTime.utc(2026, 10, 9),
      monthly: false,
      historicalPeriod: DateTime.utc(2026, 9, 28),
    );
    check(!target.historical && target.date == DateTime.utc(2026, 10, 5));
  },
  'Latest closed month still targets current planning month': () {
    final target = analyticsForecastTarget(
      now: DateTime.utc(2026, 10, 9),
      monthly: true,
      historicalPeriod: DateTime.utc(2026, 9),
    );
    check(!target.historical && target.date == DateTime.utc(2026, 10));
  },
  'Weekly business boundary uses UTC+08': () {
    final target = analyticsForecastTarget(
      now: DateTime.utc(2026, 10, 4, 16),
      monthly: false,
    );
    check(target.date == DateTime.utc(2026, 10, 5));
  },
  'Monthly business boundary uses UTC+08': () {
    final target = analyticsForecastTarget(
      now: DateTime.utc(2026, 9, 30, 16),
      monthly: true,
    );
    check(target.date == DateTime.utc(2026, 10));
  },
  'Historical month rolls across year boundary': () {
    final target = analyticsForecastTarget(
      now: DateTime.utc(2027, 2),
      monthly: true,
      historicalPeriod: DateTime.utc(2026, 12),
    );
    check(target.historical && target.date == DateTime.utc(2027, 1));
  },
  'An open period cannot be selected as closed history': () {
    var rejected = false;
    try {
      analyticsForecastTarget(
        now: DateTime.utc(2026, 10, 9),
        monthly: false,
        historicalPeriod: DateTime.utc(2026, 10, 5),
      );
    } on ArgumentError {
      rejected = true;
    }
    check(rejected);
  },
};
