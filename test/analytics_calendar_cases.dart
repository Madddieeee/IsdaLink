import 'package:isdalink/analytics/analytics_calendar.dart';
import 'analytics_common_target_cases.dart' show require;

final analyticsCalendarCases = <String, void Function()>{
  'Monday-Sunday week starts at Monday': () {
    for (var day = 5; day <= 11; day++) {
      require(
        analyticsPeriodStart(DateTime.utc(2026, 10, day), monthly: false) ==
            DateTime.utc(2026, 10, 5),
        'Weekly grouping',
      );
    }
  },
  'calendar month groups to first day': () {
    require(
      analyticsPeriodStart(DateTime.utc(2026, 9, 30), monthly: true) ==
          DateTime.utc(2026, 9),
      'Monthly grouping',
    );
  },
  'both roles and period types exclude open and future periods': () {
    final now = DateTime.utc(2026, 10, 9, 1);
    for (final role in ['vendor', 'supplier']) {
      for (final monthly in [false, true]) {
        require(
          isClosedAnalyticsPeriod(
            DateTime.utc(2026, 9, 28),
            now: now,
            monthly: monthly,
          ),
          '$role prior period closed',
        );
        require(
          !isClosedAnalyticsPeriod(
            DateTime.utc(2026, 10, 9),
            now: now,
            monthly: monthly,
          ),
          '$role current excluded',
        );
        require(
          !isClosedAnalyticsPeriod(
            DateTime.utc(2026, 11, 2),
            now: now,
            monthly: monthly,
          ),
          '$role future excluded',
        );
      }
    }
  },
  'week closes at Philippine Monday midnight, not device midnight': () {
    final sunday = DateTime.utc(2026, 10, 4);
    require(
      !isClosedAnalyticsPeriod(
        sunday,
        now: DateTime.utc(2026, 10, 4, 15, 59, 59),
        monthly: false,
      ),
      'Still Sunday 23:59:59 Philippine time',
    );
    require(
      isClosedAnalyticsPeriod(
        sunday,
        now: DateTime.utc(2026, 10, 4, 16),
        monthly: false,
      ),
      'Monday 00:00 Philippine time closes previous week',
    );
  },
  'month closes at Philippine first-day midnight': () {
    final september = DateTime.utc(2026, 9, 30);
    require(
      !isClosedAnalyticsPeriod(
        september,
        now: DateTime.utc(2026, 9, 30, 15, 59, 59),
        monthly: true,
      ),
      'September open',
    );
    require(
      isClosedAnalyticsPeriod(
        september,
        now: DateTime.utc(2026, 9, 30, 16),
        monthly: true,
      ),
      'September closed',
    );
  },
  'instant conversion crosses year boundary correctly': () {
    require(
      analyticsBusinessDate(DateTime.utc(2026, 12, 31, 20)) ==
          DateTime.utc(2027, 1, 1, 4),
      'Business year boundary',
    );
  },
};
