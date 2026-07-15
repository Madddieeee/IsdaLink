import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/stock_helpers.dart';

class ManageProductCard
    extends
        StatelessWidget {
  const ManageProductCard({
    super.key,
    required this.document,
    required this.onEdit,
    required this.onToggleAvailability,
    required this.onDelete,
  });

  final QueryDocumentSnapshot<
    Map<
      String,
      dynamic
    >
  >
  document;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;
  final VoidCallback onDelete;

  String stockStatus({
    required double quantity,
    required double lowStockLevel,
    required String status,
  }) {
    if (status.toLowerCase() ==
        'unavailable') {
      return 'Unavailable';
    }

    if (quantity <=
        0) {
      return 'Out of Stock';
    }

    if (quantity <=
        lowStockLevel) {
      return 'Low Stock';
    }

    return 'Available';
  }

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

    final category = OrderHelpers.getStringValue(
      data,
      'category',
      'Fresh Fish',
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

    final currentStockStatus = stockStatus(
      quantity: quantity,
      lowStockLevel: lowStockLevel,
      status: status,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFEAF7FB,
                  ),
                  borderRadius: BorderRadius.circular(
                    18,
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 13,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '$category • ₱${price.toStringAsFixed(0)} $priceUnit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 12,
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
                            '$currentStockStatus • ${OrderHelpers.formatNumber(quantity)} $quantityUnit',
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
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                  ),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleAvailability,
                  icon: Icon(
                    status.toLowerCase() ==
                            'unavailable'
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 16,
                  ),
                  label: Text(
                    status.toLowerCase() ==
                            'unavailable'
                        ? 'Available'
                        : 'Hide',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete,
                    size: 16,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(
                      0xFFD32F2F,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
