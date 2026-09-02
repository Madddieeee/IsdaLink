import 'package:flutter/material.dart';
import 'package:isdalink/utils/app_error_message.dart';

class BrowseSuppliersLoadingBody extends StatelessWidget {
  const BrowseSuppliersLoadingBody({super.key});

  Widget _line({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1F5),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      children: List.generate(
        5,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1EBF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0F4),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(width: 130, height: 12),
                    const SizedBox(height: 9),
                    _line(width: 175, height: 8),
                    const SizedBox(height: 11),
                    _line(width: 145, height: 8),
                    const SizedBox(height: 11),
                    _line(width: 90, height: 9),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrowseSuppliersEmptyBody extends StatelessWidget {
  const BrowseSuppliersEmptyBody({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2ECF2)),
          ),
          child: Column(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF8FC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Color(0xFF087AC0),
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF748A9B),
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BrowseSuppliersErrorBody extends StatelessWidget {
  const BrowseSuppliersErrorBody({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE4EBF0)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFF8198A9),
                size: 34,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load suppliers',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppErrorMessage.from(
                  error,
                  fallback: 'The supplier marketplace could not be loaded right now. Please try again.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF748A9B),
                  fontSize: 10.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
