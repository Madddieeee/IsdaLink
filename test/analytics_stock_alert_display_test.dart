import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';

void main() {
  for (final period in AnalyticsPeriod.values) {
    testWidgets('$period inventory alerts render without any sales history', (
      tester,
    ) async {
      final dynamic screen = const AnalyticsScreen().createState();
      screen.selectedPeriod = period;
      const alerts = [
        StockAlert(
          productName: 'Test low stock',
          emoji: '',
          quantity: 2,
          quantityUnit: 'kilo',
          lowStockLevel: 5,
        ),
        StockAlert(
          productName: 'Test out of stock',
          emoji: '',
          quantity: 0,
          quantityUnit: 'icebox',
          lowStockLevel: 1,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: screen.stockAlerts(alerts) as Widget)),
      );
      expect(find.text('Test low stock'), findsOneWidget);
      expect(find.text('Test out of stock'), findsOneWidget);
      expect(find.text('LOW'), findsOneWidget);
      expect(find.text('OUT'), findsOneWidget);
      expect(find.textContaining('2 kilo remaining'), findsOneWidget);
      expect(find.textContaining('0 icebox remaining'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('$period empty inventory does not invent alerts', (
      tester,
    ) async {
      final dynamic screen = const AnalyticsScreen().createState();
      screen.selectedPeriod = period;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: screen.stockAlerts(<StockAlert>[]) as Widget),
        ),
      );
      expect(find.text('No stock alerts'), findsOneWidget);
      expect(find.text('LOW'), findsNothing);
      expect(find.text('OUT'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
