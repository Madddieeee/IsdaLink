import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/stock_helpers.dart';

class SupplierStockCard
    extends
        StatelessWidget {
  const SupplierStockCard({
    super.key,
    required this.document,
    required this.onEdit,
  });

  final QueryDocumentSnapshot<
    Map<
      String,
      dynamic
    >
  >
  document;
  final VoidCallback onEdit;

  @override
  Widget build(
    BuildContext context,
  ) {
    final data = document.data();

    final productName = OrderHelpers.getStringValue(
      data,
      'productName',
      'Fish Product',
    );

    final emoji = OrderHelpers.getStringValue(
      data,
      'emoji',
      '🐟',
    );

    final price = OrderHelpers.getDoubleValue(
      data,
      'price',
    );

    final priceUnit = OrderHelpers.getStringValue(
      data,
      'priceUnit',
      'per kilo',
    );

    final quantity = OrderHelpers.getDoubleValue(
      data,
      'quantity',
    );

    final quantityUnit = OrderHelpers.getStringValue(
      data,
      'quantityUnit',
      'kilo',
    );

    final lowStockLevel = OrderHelpers.getDoubleValue(
      data,
      'lowStockLevel',
    );

    final status = OrderHelpers.getStringValue(
      data,
      'status',
      'available',
    );

    final stockColor = StockHelpers.getStockColor(
      quantity: quantity,
      lowStockLevel: lowStockLevel,
      status: status,
    );

    final stockStatus = StockHelpers.getStockStatus(
      quantity: quantity,
      lowStockLevel: lowStockLevel,
      status: status,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0F000000,
            ),
            blurRadius: 12,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(
                0xFFEAF7FB,
              ),
              borderRadius: BorderRadius.circular(
                17,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(
                  fontSize: 28,
                ),
              ),
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
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '₱${price.toStringAsFixed(0)} $priceUnit',
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: stockColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Text(
                        '$stockStatus • ${quantity.toStringAsFixed(0)} $quantityUnit',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: stockColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFEAF7FB,
                ),
                borderRadius: BorderRadius.circular(
                  13,
                ),
              ),
              child: const Icon(
                Icons.edit,
                color: Color(
                  0xFF146BFF,
                ),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
