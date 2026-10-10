import 'dart:io';
import '../test/analytics_target_cases.dart';

void main() {
  for (final entry in analyticsTargetCases.entries) {
    entry.value();
    stdout.writeln('PASS: ${entry.key}');
  }
}
