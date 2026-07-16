import 'package:flutter/material.dart';

class AdminEmptyCard
    extends
        StatelessWidget {
  const AdminEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(
              0xFF146BFF,
            ),
            size: 42,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminLoadingBody
    extends
        StatelessWidget {
  const AdminLoadingBody({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Scaffold(
      backgroundColor: Color(
        0xFFF4F8FB,
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class AdminErrorBody
    extends
        StatelessWidget {
  const AdminErrorBody({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(
            22,
          ),
          padding: const EdgeInsets.all(
            18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ),
          ),
          child: Text(
            'Unable to load admin dashboard: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFFD32F2F,
              ),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
