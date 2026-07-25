import 'package:flutter/material.dart';

class AnalyticsLoadingBody extends StatelessWidget {
  const AnalyticsLoadingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class AnalyticsErrorBody extends StatelessWidget {
  const AnalyticsErrorBody({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Text(
          'Unable to load analytics data: $error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13, height: 1.4, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class AnalyticsLoggedOutBody extends StatelessWidget {
  const AnalyticsLoggedOutBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F8FB),
      body: Center(
        child: Text(
          'Please log in first to view analytics.',
          style: TextStyle(color: Color(0xFFD32F2F), fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
