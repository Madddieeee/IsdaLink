import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class ManageProductCard extends StatelessWidget {
  const ManageProductCard({
    super.key,
    required this.document,
    required this.onEdit,
    required this.onToggleAvailability,
    required this.onDelete,
    this.isBusy = false,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;
  final VoidCallback onDelete;
  final bool isBusy;

  String firstString(
    Map<String, dynamic> data,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  String formatNumber(
    double value,
  ) {
    return value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  bool isHidden(
    Map<String, dynamic> data,
  ) {
    final status = OrderHelpers.getStringValue(
      data,
      'status',
      'available',
    ).toLowerCase();

    return status == 'unavailable' ||
        data['isActive'] == false;
  }

  String stockStatus({
    required Map<String, dynamic> data,
    required double quantity,
    required double lowStockLevel,
  }) {
    if (isHidden(data)) {
      return 'Hidden';
    }

    if (quantity <= 0) {
      return 'Out of Stock';
    }

    if (quantity <= lowStockLevel) {
      return 'Low Stock';
    }

    return 'Available';
  }

  Color statusColor(
    String status,
  ) {
    return switch (status) {
      'Hidden' => const Color(0xFF7B8FA3),
      'Out of Stock' => const Color(0xFFD94A45),
      'Low Stock' => const Color(0xFFFF7A1A),
      _ => const Color(0xFF147D64),
    };
  }

  Widget productImage({
    required String imageUrl,
    required bool hidden,
  }) {
    final placeholder = Container(
      color: const Color(0xFFEAF7FB),
      child: const Icon(
        Icons.add_photo_alternate_outlined,
        color: Color(0xFF7EAAC4),
        size: 32,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isEmpty)
            placeholder
          else
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return placeholder;
              },
            ),
          if (hidden)
            Container(
              color: const Color(0x9900182A),
              alignment: Alignment.center,
              child: const Icon(
                Icons.visibility_off_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
        ],
      ),
    );
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
    final imageUrl = firstString(
      data,
      const [
        'productImageUrl',
        'imageUrl',
      ],
      fallback: '',
    );
    final price = OrderHelpers.getDoubleValue(
      data,
      'price',
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
    final storedPercentage = OrderHelpers.getDoubleValue(
      data,
      'lowStockPercentage',
    );
    final referenceQuantity = OrderHelpers.getDoubleValue(
      data,
      'referenceStockQuantity',
    );

    final lowStockPercentage = storedPercentage > 0
        ? storedPercentage
        : referenceQuantity > 0
            ? lowStockLevel / referenceQuantity * 100
            : 20.0;

    final hidden = isHidden(data);
    final currentStatus = stockStatus(
      data: data,
      quantity: quantity,
      lowStockLevel: lowStockLevel,
    );
    final currentColor = statusColor(currentStatus);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isBusy ? 0.60 : 1,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hidden
                ? const Color(0xFFDDE5EB)
                : const Color(0xFFE1EBF2),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F00152A),
              blurRadius: 17,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: productImage(
                    imageUrl: imageUrl,
                    hidden: hidden,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 15,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: currentColor.withAlpha(18),
                              borderRadius:
                                  BorderRadius.circular(99),
                            ),
                            child: Text(
                              currentStatus,
                              style: TextStyle(
                                color: currentColor,
                                fontSize: 8.3,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7B8FA3),
                          fontSize: 10.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${formatNumber(price)} per $quantityUnit',
                        style: const TextStyle(
                          color: Color(0xFF0875D1),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (imageUrl.isEmpty) ...[
                        const SizedBox(height: 5),
                        const Text(
                          'Photo required on next edit',
                          style: TextStyle(
                            color: Color(0xFFFF7A1A),
                            fontSize: 8.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ProductMetric(
                    icon: Icons.inventory_2_outlined,
                    label: 'AVAILABLE',
                    value:
                        '${formatNumber(quantity)} $quantityUnit',
                    valueColor: currentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProductMetric(
                    icon:
                        Icons.notifications_active_outlined,
                    label: 'ALERT AT',
                    value:
                        '${formatNumber(lowStockLevel)} $quantityUnit',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProductMetric(
                    icon: Icons.percent_rounded,
                    label: 'THRESHOLD',
                    value:
                        '${formatNumber(lowStockPercentage)}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'Edit Product',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF146BFF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFFDCE7EF),
                      minimumSize: const Size.fromHeight(44),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                OutlinedButton.icon(
                  onPressed:
                      isBusy ? null : onToggleAvailability,
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                  ),
                  label: Text(
                    hidden ? 'Show' : 'Hide',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hidden
                        ? const Color(0xFF147D64)
                        : const Color(0xFF52677A),
                    side: BorderSide(
                      color: hidden
                          ? const Color(0xFF80D6BC)
                          : const Color(0xFFB9CBD7),
                    ),
                    minimumSize: const Size(86, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                PopupMenuButton<String>(
                  enabled: !isBusy,
                  tooltip: 'More product actions',
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  onSelected: (
                    value,
                  ) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (
                    context,
                  ) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFD94A45),
                              size: 20,
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Delete Product',
                              style: TextStyle(
                                color: Color(0xFFD94A45),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF52677A),
                  ),
                ),
              ],
            ),
            if (isBusy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(
                minHeight: 3,
                borderRadius: BorderRadius.all(
                  Radius.circular(99),
                ),
                color: Color(0xFF146BFF),
                backgroundColor: Color(0xFFEAF2F7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductMetric extends StatelessWidget {
  const _ProductMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF102C44),
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        7,
        9,
        7,
        9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF146BFF),
            size: 17,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8BA0B1),
              fontSize: 7.2,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: valueColor,
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
