import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registration provides visible and system back navigation', () {
    final source = File(
      'lib/screens/auth/register_screen.dart',
    ).readAsStringSync();

    expect(source, contains("final canGoBack = currentStep > 0;"));
    expect(source, contains("'Back'"));
    expect(source, contains('onPressed: isLoading ? null : previousStep'));
    expect(source, contains('canPop: currentStep == 0 && !isLoading'));
    expect(source, contains('if (!didPop && currentStep > 0)'));
    expect(source, contains('fit: BoxFit.scaleDown'));
    expect(source, contains('mainAxisSize: MainAxisSize.min'));
  });
}
