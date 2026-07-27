import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class OrderFilterSelector extends StatelessWidget {
  const OrderFilterSelector({
    super.key,
    required this.documents,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  List<String> get orderFilters => const [
        'All',
        'Pending',
        'Accepted',
        'Delivered',
        'Cancelled',
      ];

  String filterLabel(
    String filter,
  ) {
    switch (filter.toLowerCase()) {
      case 'pending':
        return 'To Pay';
      case 'accepted':
        return 'To Ship';
      case 'delivered':
        return 'To Receive';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'All';
    }
  }

  IconData filterIcon(
    String filter,
  ) {
    switch (filter.toLowerCase()) {
      case 'pending':
        return Icons.payments_outlined;
      case 'accepted':
        return Icons.inventory_2_outlined;
      case 'delivered':
        return Icons.local_shipping_outlined;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        13,
        0,
        13,
      ),
      decoration: const BoxDecoration(
        color: Color(
          0xFFF4FAFF,
        ),
      ),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(
            right: 14,
          ),
          itemCount: orderFilters.length,
          separatorBuilder: (context, index) {
            return const SizedBox(
              width: 8,
            );
          },
          itemBuilder: (context, index) {
            final filter = orderFilters[index];
            final isSelected = selectedFilter == filter;
            final count = OrderHelpers.countByStatus(
              documents,
              filter,
            );
            final color = OrderHelpers.statusColor(
              filter,
            );

            return GestureDetector(
              onTap: () => onFilterSelected(
                filter,
              ),
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(
                    99,
                  ),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : const Color(
                            0xFFE1EEF6,
                          ),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withAlpha(
                              35,
                            ),
                            blurRadius: 10,
                            offset: const Offset(
                              0,
                              5,
                            ),
                          ),
                        ]
                      : const [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filterIcon(
                        filter,
                      ),
                      color: isSelected ? Colors.white : color,
                      size: 16,
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Text(
                      filterLabel(
                        filter,
                      ),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(
                                0xFF102C44,
                              ),
                        fontSize: 11.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Container(
                      constraints: const BoxConstraints(
                        minWidth: 21,
                      ),
                      height: 21,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withAlpha(
                                42,
                              )
                            : color.withAlpha(
                                22,
                              ),
                        borderRadius: BorderRadius.circular(
                          99,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
