import 'package:flutter/material.dart';

class ProductBottomOrderBar
    extends
        StatelessWidget {
  const ProductBottomOrderBar({
    super.key,
    required this.isOutOfStock,
    required this.onPlaceOrder,
  });

  final bool isOutOfStock;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(
              0x14000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              -4,
            ),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isOutOfStock
                ? null
                : onPlaceOrder,
            icon: const Icon(
              Icons.shopping_cart,
            ),
            label: Text(
              isOutOfStock
                  ? 'Out of Stock'
                  : 'Place COD Order',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFF146BFF,
              ),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFFCAD6E0,
              ),
              disabledForegroundColor: const Color(
                0xFF7B8FA3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
