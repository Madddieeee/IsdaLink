import 'package:flutter/material.dart';

class SupplierActivationSectionCard
    extends
        StatelessWidget {
  const SupplierActivationSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(
                        0xFF146BFF,
                      ).withAlpha(
                        24,
                      ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(
                    0xFF146BFF,
                  ),
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 12,
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
                        fontSize: 16,
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
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          child,
        ],
      ),
    );
  }
}

class SupplierActivationInputDecorations {
  const SupplierActivationInputDecorations._();

  static InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(
          0xFF7B8FA3,
        ),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(
          0xFF146BFF,
        ),
      ),
      filled: true,
      fillColor: const Color(
        0xFFF4F8FB,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          18,
        ),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          18,
        ),
        borderSide: const BorderSide(
          color: Color(
            0xFF146BFF,
          ),
          width: 1.4,
        ),
      ),
    );
  }
}
