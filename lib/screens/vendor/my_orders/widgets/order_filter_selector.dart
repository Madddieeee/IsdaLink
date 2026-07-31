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

  List<String> get filters => const [
        'All',
        'Pending',
        'Accepted',
        'Completed',
        'Cancelled',
      ];

  String statusOf(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return OrderHelpers.getStringValue(
      document.data(),
      'orderStatus',
      'Pending',
    ).toLowerCase();
  }

  int countFor(
    String filter,
  ) {
    final value = filter.toLowerCase();

    if (value == 'all') {
      return documents.length;
    }

    return documents.where(
      (document) {
        final status = statusOf(document);

        if (value == 'completed') {
          return status == 'completed' || status == 'delivered';
        }

        if (value == 'cancelled') {
          return status == 'cancelled' || status == 'rejected';
        }

        return status == value;
      },
    ).length;
  }

  Color colorFor(
    String filter,
  ) {
    switch (filter.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFF7A1A);
      case 'accepted':
        return const Color(0xFF0A73D8);
      case 'completed':
        return const Color(0xFF2E7D32);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      case 'all':
      default:
        return const Color(0xFF102C44);
    }
  }

  IconData iconFor(
    String filter,
  ) {
    switch (filter.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'all':
      default:
        return Icons.grid_view_rounded;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color: const Color(0xFFF4F8FB),
      padding: const EdgeInsets.fromLTRB(
        16,
        13,
        0,
        2,
      ),
      child: SizedBox(
        height: 45,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: 16),
          itemCount: filters.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final selected = selectedFilter == filter;
            final color = colorFor(filter);
            final count = countFor(filter);

            return Material(
              color: selected ? color : Colors.white,
              borderRadius: BorderRadius.circular(99),
              child: InkWell(
                onTap: () => onFilterSelected(filter),
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: selected
                          ? color
                          : const Color(0xFFDDE9F1),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: color.withAlpha(38),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        iconFor(filter),
                        color: selected
                            ? Colors.white
                            : color,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filter,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF52677A),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 21,
                          minHeight: 21,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withAlpha(34)
                              : color.withAlpha(18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : color,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
