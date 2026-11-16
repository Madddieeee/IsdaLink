import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account center location uses the available profile width', () {
    final source = File(
      'lib/screens/profile/me_screen.dart',
    ).readAsStringSync();

    final headerStart = source.indexOf('class _AccountCenterHeader');
    final headerEnd = source.indexOf('class _VendorToolsCard');
    final headerSource = source.substring(headerStart, headerEnd);

    expect(
      headerSource,
      contains(
        'Expanded(\n'
        '                                    child: Text(\n'
        '                                      location,',
      ),
    );
    expect(headerSource, contains('overflow: TextOverflow.ellipsis'));
    expect(headerSource, isNot(contains('maxWidth: 220')));
    expect(headerSource, contains('const panelHeight = 132.0'));
  });
}
