import 'package:flutter_test/flutter_test.dart';
import 'package:isdalink/main.dart';

void
main() {
  testWidgets(
    'IsdaLink app starts',
    (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const IsdaLinkApp(),
      );
      await tester.pump();
    },
  );
}
