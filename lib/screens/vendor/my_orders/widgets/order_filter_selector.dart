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

  List<String> get primaryFilters => const [
        'All',
        'Active',
        'Completed',
        'Cancelled',
      ];

  List<String> get activeFilters => const [
        'Active',
        'Pending',
        'Accepted',
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

        if (value == 'active') {
          return status == 'pending' || status == 'accepted';
        }

        if (value == 'completed') {
          return status == 'completed' || status == 'delivered';
        }

        if (value == 'cancelled') {
          return status == 'cancelled' ||
              status == 'rejected' ||
              status == 'returned' ||
              status == 'refunded';
        }

        return status == value;
      },
    ).length;
  }

  Color colorFor(
    String filter,
  ) {
    switch (filter.toLowerCase()) {
      case 'active':
        return const Color(0xFF0875D1);
      case 'pending':
        return const Color(0xFFFF7A1A);
      case 'accepted':
        return const Color(0xFF376EF6);
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
      case 'active':
        return Icons.pending_actions_rounded;
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

  Widget filterChip(
    String filter, {
    String? displayLabel,
    bool compact = false,
  }) {
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
          height: compact ? 36 : 40,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? color : const Color(0xFFDDE9F1),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withAlpha(32),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconFor(filter),
                color: selected ? Colors.white : color,
                size: compact ? 13 : 14,
              ),
              const SizedBox(width: 5),
              Text(
                displayLabel ?? filter,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF52677A),
                  fontSize: compact ? 9.4 : 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                constraints: BoxConstraints(
                  minWidth: compact ? 18 : 20,
                  minHeight: compact ? 18 : 20,
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withAlpha(35) : color.withAlpha(17),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : color,
                    fontSize: compact ? 8.5 : 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final activeMode = selectedFilter == 'Active' ||
        selectedFilter == 'Pending' ||
        selectedFilter == 'Accepted';

    return Container(
      color: const Color(0xFFF4F8FB),
      padding: const EdgeInsets.fromLTRB(16, 13, 0, 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16),
              itemCount: primaryFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = primaryFilters[index];
                final selectedPrimary = filter == 'Active'
                    ? activeMode
                    : selectedFilter == filter;

                if (filter == 'Active' && selectedPrimary && selectedFilter != 'Active') {
                  return _PrimaryActiveProxy(
                    color: colorFor('Active'),
                    count: countFor('Active'),
                    onTap: () => onFilterSelected('Active'),
                  );
                }

                return filterChip(filter);
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 190),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: activeMode
                ? Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: Row(
                      children: [
                        const Text(
                          'ACTIVE STATUS',
                          style: TextStyle(
                            color: Color(0xFF8CA0AE),
                            fontSize: 7.8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              itemCount: activeFilters.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 7),
                              itemBuilder: (context, index) {
                                final filter = activeFilters[index];
                                return filterChip(
                                  filter,
                                  displayLabel: filter == 'Active' ? 'All active' : filter,
                                  compact: true,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActiveProxy extends StatelessWidget {
  const _PrimaryActiveProxy({
    required this.color,
    required this.count,
    required this.onTap,
  });

  final Color color;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(32),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pending_actions_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 5),
              const Text(
                'Active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
