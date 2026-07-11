import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class OrderFilterSelector
    extends
        StatelessWidget {
  const OrderFilterSelector({
    super.key,
    required this.documents,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  documents;
  final String selectedFilter;
  final ValueChanged<
    String
  >
  onFilterSelected;

  List<
    String
  >
  get orderFilters => const [
    'All',
    'Pending',
    'Accepted',
    'Delivered',
    'Cancelled',
  ];

  void showFilterOptions(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            28,
          ),
        ),
      ),
      builder:
          (
            sheetContext,
          ) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFD5E0EA,
                        ),
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color:
                                const Color(
                                  0xFF146BFF,
                                ).withAlpha(
                                  22,
                                ),
                            borderRadius: BorderRadius.circular(
                              14,
                            ),
                          ),
                          child: const Icon(
                            Icons.filter_list,
                            color: Color(
                              0xFF146BFF,
                            ),
                            size: 21,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Expanded(
                          child: Text(
                            'Filter Orders',
                            style: TextStyle(
                              color: Color(
                                0xFF102C44,
                              ),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    ...orderFilters.map(
                      (
                        filter,
                      ) => filterOptionTile(
                        sheetContext: sheetContext,
                        filter: filter,
                        count: OrderHelpers.countByStatus(
                          documents,
                          filter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  Widget filterOptionTile({
    required BuildContext sheetContext,
    required String filter,
    required int count,
  }) {
    final bool isSelected =
        selectedFilter ==
        filter;
    final color = OrderHelpers.statusColor(
      filter,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(
        18,
      ),
      onTap: () {
        onFilterSelected(
          filter,
        );
        Navigator.pop(
          sheetContext,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(
                  22,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: isSelected
                ? color.withAlpha(
                    70,
                  )
                : const Color(
                    0xFFE1E9F0,
                  ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: color,
              size: 20,
            ),
            const SizedBox(
              width: 10,
            ),
            Icon(
              OrderHelpers.statusIcon(
                filter,
              ),
              color: color,
              size: 20,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                filter ==
                        'All'
                    ? 'All Orders'
                    : filter,
                style: TextStyle(
                  color: isSelected
                      ? color
                      : const Color(
                          0xFF102C44,
                        ),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: color.withAlpha(
                  22,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final count = OrderHelpers.countByStatus(
      documents,
      selectedFilter,
    );

    final color = OrderHelpers.statusColor(
      selectedFilter,
    );

    return GestureDetector(
      onTap: () => showFilterOptions(
        context,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          18,
          16,
          18,
          0,
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
                0x0E000000,
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(
                  24,
                ),
                borderRadius: BorderRadius.circular(
                  15,
                ),
              ),
              child: Icon(
                OrderHelpers.statusIcon(
                  selectedFilter,
                ),
                color: color,
                size: 22,
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
                    selectedFilter ==
                            'All'
                        ? 'Showing: All Orders'
                        : 'Showing: $selectedFilter Orders',
                    style: const TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    '$count result${count == 1 ? '' : 's'} • Tap to change filter',
                    style: const TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(
                0xFF7B8FA3,
              ),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
