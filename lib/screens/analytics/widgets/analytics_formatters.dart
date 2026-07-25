String formatAnalyticsNumber(
  double value,
) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(2);
}

String formatCurrency(
  double value,
) {
  return '₱${value.toStringAsFixed(0)}';
}
