import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';

class ProductStockBadge
    extends
        StatelessWidget {
  const ProductStockBadge({
    super.key,
    required this.product,
  });

  final FishProduct product;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: product.stockColor.withAlpha(
          26,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: product.stockColor.withAlpha(
            80,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: product.stockColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            product.stockStatus,
            style: TextStyle(
              color: product.stockColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
