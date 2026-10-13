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

  static const primaryFilters = <String>[
    'All',
    'Active',
    'Completed',
    'Cancelled',
  ];

  String statusOf(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    return OrderHelpers.getStringValue(
      document.data(),
      'orderStatus',
      'Pending',
    ).toLowerCase();
  }

  int countFor(String filter) {
    final value = filter.toLowerCase();

    if (value == 'all') {
      return documents.length;
    }

    return documents.where((document) {
      final status = statusOf(document);

      switch (value) {
        case 'active':
          return status == 'pending' || status == 'accepted';
        case 'completed':
          return status == 'completed' || status == 'delivered';
        case 'cancelled':
          return status == 'cancelled' ||
              status == 'rejected' ||
              status == 'returned' ||
              status == 'refunded';
        default:
          return status == value;
      }
    }).length;
  }

  bool get activeMode {
    final value = selectedFilter.toLowerCase();
    return value == 'active' || value == 'pending' || value == 'accepted';
  }

  bool primarySelected(String filter) {
    if (filter == 'Active') {
      return activeMode;
    }
    return selectedFilter == filter;
  }

  Widget primarySegment(String filter) {
    final selected = primarySelected(filter);
    final count = countFor(filter);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$filter orders, $count',
        child: Material(
          color: selected ? const Color(0xFF0875D1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: () => onFilterSelected(filter),
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          filter,
                          maxLines: 1,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF102C44),
                            fontSize: 10.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withAlpha(35)
                            : const Color(0xFFEAF4FB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF0875D1),
                          fontSize: 8.8,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget activeStatusButton({required String filter, required String label}) {
    final selected = selectedFilter == filter;

    return Expanded(
      child: Material(
        color: selected ? const Color(0xFFE6F3FC) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onFilterSelected(filter),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 34,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF8BC7EE)
                    : const Color(0xFFDDE9F1),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$label  ${countFor(filter)}',
                maxLines: 1,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF076BB6)
                      : const Color(0xFF5F7485),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F8FB),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: const Color(0xFFDCE9F1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D00152A),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                for (var index = 0; index < primaryFilters.length; index++) ...[
                  primarySegment(primaryFilters[index]),
                  if (index < primaryFilters.length - 1)
                    Container(
                      width: 1,
                      height: 31,
                      color: const Color(0xFFE3EDF3),
                    ),
                ],
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: activeMode
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(5, 5, 5, 3),
                      child: Row(
                        children: [
                          activeStatusButton(
                            filter: 'Pending',
                            label: 'Pending',
                          ),
                          const SizedBox(width: 6),
                          activeStatusButton(
                            filter: 'Accepted',
                            label: 'To Receive',
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
