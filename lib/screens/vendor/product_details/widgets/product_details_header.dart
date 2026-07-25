import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/screens/vendor/product_details/widgets/product_stock_badge.dart';

class ProductDetailsHeader extends StatelessWidget {
  const ProductDetailsHeader({
    super.key,
    required this.product,
    required this.onBack,
  });

  final FishProduct product;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102C44), Color(0xFF146BFF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Product Details',
                  style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Container(
              width: 124,
              height: 124,
              color: Colors.white,
              child: product.hasImage
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return ProductEmojiFallback(emoji: product.emoji);
                      },
                    )
                  : ProductEmojiFallback(emoji: product.emoji),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            product.name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            product.category,
            style: const TextStyle(color: Color(0xFFDCE9F5), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ProductStockBadge(product: product),
        ],
      ),
    );
  }
}

class ProductEmojiFallback extends StatelessWidget {
  const ProductEmojiFallback({super.key, required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(emoji, style: const TextStyle(fontSize: 62)),
    );
  }
}
