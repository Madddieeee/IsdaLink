import 'package:flutter/material.dart';

class AdminSectionTitle
    extends
        StatelessWidget {
  const AdminSectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                const Color(
                  0xFF146BFF,
                ).withAlpha(
                  24,
                ),
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            color: const Color(
              0xFF146BFF,
            ),
            size: 20,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(
                    0xFF7B8FA3,
                  ),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
