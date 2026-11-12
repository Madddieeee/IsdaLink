import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin curved body uses the header transition color', () {
    final source = File(
      'lib/screens/admin/admin_dashboard_screen.dart',
    ).readAsStringSync();

    expect(source, contains('color: const Color(0xFF00294A)'));
    expect(source, isNot(contains('color: const Color(0xFF0A5B84)')));
  });
}
