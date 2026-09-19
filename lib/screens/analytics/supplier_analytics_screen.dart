import 'package:flutter/material.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';

/// Supplier-facing analytics entry point.
///
/// Supplier-only capabilities, including sales terminology and inventory
/// alerts, are enabled here. Forecast calculations remain in the shared
/// [AnalyticsScreen] so both roles always use the same validated formulas.
class SupplierAnalyticsScreen extends StatelessWidget {
  const SupplierAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnalyticsScreen(mode: AnalyticsMode.supplier);
  }
}
