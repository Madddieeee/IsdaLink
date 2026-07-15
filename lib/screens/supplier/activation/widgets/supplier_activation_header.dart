import 'package:flutter/material.dart';

class SupplierActivationHeader
    extends
        StatelessWidget {
  const SupplierActivationHeader({
    super.key,
    required this.enabledUnitCount,
    required this.onBack,
  });

  final int enabledUnitCount;
  final VoidCallback onBack;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        54,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(
              0xFF102C44,
            ),
            Color(
              0xFF146BFF,
            ),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(
            32,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(
                      38,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              const Expanded(
                child: Text(
                  'Become a Supplier',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 18,
          ),
          const Text(
            'Submit a supplier application for admin review before posting stocks, managing products, and viewing supplier tools.',
            style: TextStyle(
              color: Color(
                0xFFDCE9F5,
              ),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Container(
            padding: const EdgeInsets.all(
              15,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(
                34,
              ),
              borderRadius: BorderRadius.circular(
                22,
              ),
              border: Border.all(
                color: Colors.white.withAlpha(
                  34,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Color(
                      0xFF146BFF,
                    ),
                    size: 30,
                  ),
                ),
                const SizedBox(
                  width: 14,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Supplier Application',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        '$enabledUnitCount unit options selected • COD only',
                        style: const TextStyle(
                          color: Color(
                            0xFFDCE9F5,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.pending_actions,
                  color: Color(
                    0xFF38D39F,
                  ),
                  size: 25,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
