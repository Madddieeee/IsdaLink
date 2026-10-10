import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';

void main() {
  testWidgets('section tabs expose all four sections and report each tap', (
    tester,
  ) async {
    var selected = SupplierAnalyticsTab.summary;
    final taps = <SupplierAnalyticsTab>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Align(
              alignment: Alignment.topCenter,
              child: AnalyticsSectionTabs(
                selectedTab: selected,
                onSelected: (tab) => setState(() {
                  taps.add(tab);
                  selected = tab;
                }),
              ),
            ),
          ),
        ),
      ),
    );
    for (final tab in SupplierAnalyticsTab.values) {
      await tester.tap(find.byKey(ValueKey('analytics_section_${tab.name}')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnalyticsSectionTabs>(find.byType(AnalyticsSectionTabs))
            .selectedTab,
        tab,
      );
    }
    expect(taps, SupplierAnalyticsTab.values);
    expect(tester.takeException(), isNull);
  });

  testWidgets('section tabs fit a narrow screen with enlarged text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 320,
                child: AnalyticsSectionTabs(
                  selectedTab: SupplierAnalyticsTab.accuracy,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (final label in ['Summary', 'Accuracy', 'Guidance', 'Products']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.getSize(find.byType(AnalyticsSectionTabs)).height, 60);
    expect(tester.takeException(), isNull);
  });
}
