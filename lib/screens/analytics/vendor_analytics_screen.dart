import 'package:flutter/material.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';

/// Vendor-facing analytics entry point.
///
/// Vendor-specific presentation and permissions are selected here, while the
/// shared forecasting engine remains in [AnalyticsScreen]. This keeps the
/// calculations consistent with supplier analytics without mixing navigation
/// code for the two roles.
class VendorAnalyticsScreen extends StatelessWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnalyticsScreen(mode: AnalyticsMode.vendor);
  }
}
