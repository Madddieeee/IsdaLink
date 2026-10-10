/// Presentation only. Never use this text as a model or evaluation input.
String formatForecastEstimate(double value) {
  if (!value.isFinite || value < 0) {
    return 'Unavailable';
  }
  if (value == 0) {
    return '0';
  }
  if (value < 0.01) {
    return '<0.01';
  }
  final text = value.toStringAsFixed(2);
  if (!text.contains('.') || text.contains('e')) {
    return text;
  }
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}
