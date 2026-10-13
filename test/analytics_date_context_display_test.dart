import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';

AnalyticsData historyData(DateTime date) {
  final empty = AnalyticsData.empty();
  return AnalyticsData(
    completedOrders: 1,
    liveCompletedOrders: 0,
    historicalTransactions: 1,
    totalAmount: 100,
    products: const [],
    selectedProduct: null,
    selectedPoints: [PeriodPoint(date: date, quantity: 5, amount: 100)],
    rankingBasis: '',
    simpleForecast: empty.simpleForecast,
    seasonalForecast: empty.seasonalForecast,
    simpleEvaluation: empty.simpleEvaluation,
    seasonalEvaluation: empty.seasonalEvaluation,
    selectedMethod: empty.selectedMethod,
    variability: null,
    suggestions: const [],
    stockAlerts: const [],
  );
}

void main() {
  final now = DateTime.utc(2026, 10, 10, 5);
  for (final mode in AnalyticsMode.values) {
    for (final period in AnalyticsPeriod.values) {
      final monthly = period == AnalyticsPeriod.monthly;
      final historyDate = monthly
          ? DateTime.utc(2026, 7, 1)
          : DateTime.utc(2026, 8, 10);
      final historyRange = monthly ? 'Jul 2026' : 'Aug 10–16, 2026';
      final historicalTarget = monthly ? 'Aug 2026' : 'Aug 17–23, 2026';
      final currentTarget = monthly ? 'Oct 2026' : 'Oct 5–11, 2026';

      Future<void> render(
        WidgetTester tester, {
        required bool historical,
        bool guidance = false,
        bool empty = false,
      }) async {
        final dynamic screen = AnalyticsScreen(mode: mode).createState();
        screen.selectedPeriod = period;
        screen.selectedSupplierPeriodStart = historical ? historyDate : null;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280,
                  child: MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(1.5),
                    ),
                    child:
                        screen.supplierDateContext(
                              empty
                                  ? AnalyticsData.empty()
                                  : historyData(historyDate),
                              currentPlanningOnly: guidance,
                              now: now,
                            )
                            as Widget,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      testWidgets('$mode $period historical dates and target stay distinct', (
        tester,
      ) async {
        await render(tester, historical: true);
        expect(find.text('Historical view'), findsOneWidget);
        expect(find.text('Selected history: $historyRange'), findsOneWidget);
        expect(
          find.text('Historical forecast target: $historicalTarget'),
          findsOneWidget,
        );
        expect(find.text('Planning target: $currentTarget'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        '$mode $period current target does not follow stale history',
        (tester) async {
          await render(tester, historical: false);
          expect(find.text('Current planning'), findsOneWidget);
          expect(
            find.text('Latest recorded period: $historyRange'),
            findsOneWidget,
          );
          expect(find.text('Planning target: $currentTarget'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('$mode $period latest history uses current planning label', (
        tester,
      ) async {
        final latestClosed = monthly
            ? DateTime.utc(2026, 9)
            : DateTime.utc(2026, 9, 28);
        final dynamic screen = AnalyticsScreen(mode: mode).createState();
        screen.selectedPeriod = period;
        screen.selectedSupplierPeriodStart = latestClosed;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: screen.supplierDateContext(
                historyData(latestClosed),
                now: now,
              ) as Widget,
            ),
          ),
        );
        expect(find.text('Current planning'), findsOneWidget);
        expect(find.text('Planning target: $currentTarget'), findsOneWidget);
        expect(find.textContaining('Historical forecast target:'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$mode $period guidance ignores historical selection', (
        tester,
      ) async {
        await render(tester, historical: true, guidance: true);
        expect(find.text('Current planning'), findsOneWidget);
        expect(
          find.text('All fish · each quantity unit kept separate'),
          findsOneWidget,
        );
        expect(find.text('Planning target: $currentTarget'), findsOneWidget);
        expect(find.text('Selected history: $historyRange'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$mode $period empty history still shows planning dates', (
        tester,
      ) async {
        await render(tester, historical: true, empty: true);
        expect(
          find.text('No recorded closed period for this fish'),
          findsOneWidget,
        );
        expect(find.text('Planning target: $currentTarget'), findsOneWidget);
        expect(find.text('Historical view'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
