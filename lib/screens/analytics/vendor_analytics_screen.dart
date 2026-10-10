import 'package:flutter/material.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';

/// Vendor-facing analytics entry point.
///
/// Vendor-specific presentation and permissions are selected here, while the
/// shared forecasting engine remains in [AnalyticsScreen]. This keeps the
/// calculations consistent with supplier analytics without mixing navigation
/// code for the two roles.
class VendorAnalyticsScreen extends StatelessWidget {
  const VendorAnalyticsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AnalyticsScreen(mode: AnalyticsMode.vendor, onBack: onBack);
  }
}
