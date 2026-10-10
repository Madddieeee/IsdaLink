import 'dart:io';
import '../test/analytics_identity_cases.dart';

void main() {
  for (final entry in analyticsIdentityCases.entries) {
    entry.value();
    stdout.writeln('PASS: ${entry.key}');
  }
}
