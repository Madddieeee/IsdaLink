import 'dart:io';
import '../test/analytics_parameter_cases.dart';

void main() {
  for (final entry in analyticsParameterCases.entries) {
    entry.value();
    stdout.writeln('PASS: ${entry.key}');
  }
}
