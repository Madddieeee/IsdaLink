import 'package:flutter/material.dart';

class MeMenuTile
    extends
        StatelessWidget {
  const MeMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = const Color(
      0xFF146BFF,
    ),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding: const EdgeInsets.all(
          16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            22,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x12000000,
              ),
              blurRadius: 14,
              offset: Offset(
                0,
                7,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(
                  25,
                ),
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(
              width: 14,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(
                0xFF9AAABD,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
