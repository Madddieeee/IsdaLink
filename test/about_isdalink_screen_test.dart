import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account center opens the completed About IsdaLink page', () {
    final accountCenter = File(
      'lib/screens/profile/me_screen.dart',
    ).readAsStringSync();
    final about = File(
      'lib/screens/profile/about_isdalink_screen.dart',
    ).readAsStringSync();

    expect(accountCenter, contains("title: 'About IsdaLink'"));
    expect(accountCenter, contains('const AboutIsdaLinkScreen()'));
    expect(accountCenter, isNot(contains('content will be available here')));

    expect(about, contains('Why we built IsdaLink'));
    expect(about, contains('What IsdaLink provides'));
    expect(about, contains('Jon Carlo S. Albarida'));
    expect(about, contains('Ibhan Gardiola Calubag'));
    expect(about, isNot(contains('Version 1.0.0')));
    expect(
      about,
      contains('Design and Development of a Mobile-Based Fish Supply'),
    );
    expect(about, contains('Their '));
    expect(about, contains('other fish suppliers'));
    expect(about, contains('Fish inventory and order management'));
    expect(about, contains('Sales analytics and restocking guidance'));
    expect(about, isNot(contains('Cash on Delivery ordering')));
    expect(about, contains('ibhan_gardiola_calubag_avatar.jpg'));

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains('assets/images/ibhan_gardiola_calubag_avatar.jpg'),
    );
    expect(
      File('assets/images/ibhan_gardiola_calubag_avatar.jpg').existsSync(),
      isTrue,
    );
  });
}
