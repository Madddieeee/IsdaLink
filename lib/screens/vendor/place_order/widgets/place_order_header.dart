import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';

class PlaceOrderHeader
    extends
        StatelessWidget {
  const PlaceOrderHeader({
    super.key,
    required this.supplier,
    required this.product,
  });

  final Supplier supplier;
  final FishProduct product;

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
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(
                  context,
                ),
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
                  'Place COD Order',
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
            height: 22,
          ),
          Container(
            padding: const EdgeInsets.all(
              16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(
                34,
              ),
              borderRadius: BorderRadius.circular(
                24,
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
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      22,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      product.emoji,
                      style: const TextStyle(
                        fontSize: 38,
                      ),
                    ),
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
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        supplier.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(
                            0xFFDCE9F5,
                          ),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        '₱${product.price.toStringAsFixed(0)} ${product.priceUnit}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
