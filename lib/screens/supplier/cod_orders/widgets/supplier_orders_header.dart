import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierOrdersHeader extends StatelessWidget {
  const SupplierOrdersHeader({
    super.key,
    required this.documents,
    required this.onBack,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>>
      documents;
  final VoidCallback onBack;

  int countStatus(
    String target,
  ) {
    return documents.where(
      (
        document,
      ) {
        final status = OrderHelpers.getStringValue(
          document.data(),
          'orderStatus',
          'Pending',
        ).toLowerCase();

        if (target == 'delivered') {
          return status == 'delivered' ||
              status == 'completed';
        }

        return status == target;
      },
    ).length;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final pendingCount = countStatus('pending');
    final acceptedCount = countStatus('accepted');
    final deliveredCount = countStatus('delivered');

    return SliverAppBar(
      pinned: true,
      expandedHeight: 248,
      toolbarHeight: 62,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color(0xFF075FAE),
      foregroundColor: Colors.white,
      leadingWidth: 58,
      leading: Padding(
        padding: const EdgeInsets.only(
          left: 14,
          top: 8,
          bottom: 8,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(99),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(32),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(27),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ),
      ),
      titleSpacing: 8,
      title: const Text(
        'Incoming COD Orders',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.5,
          letterSpacing: -0.15,
          fontWeight: FontWeight.w900,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF063B66),
                Color(0xFF075FAE),
                Color(0xFF146BFF),
              ],
              stops: [
                0.0,
                0.55,
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -58,
                right: -52,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(9),
                    border: Border.all(
                      color: Colors.white.withAlpha(18),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 65,
                right: 24,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(18),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.paddingOf(context).top + 75,
                  18,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(26),
                            borderRadius:
                                BorderRadius.circular(99),
                            border: Border.all(
                              color: Colors.white.withAlpha(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'COD ORDER QUEUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.4,
                                  letterSpacing: 0.65,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${documents.length} total',
                          style: const TextStyle(
                            color: Color(0xFFDDEFFF),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Review vendor requests, confirm fulfillment, and record payment upon delivery.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFDDEFFF),
                        fontSize: 10.7,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _HeaderMetric(
                          icon: Icons.schedule_rounded,
                          value: '$pendingCount',
                          label: 'Pending',
                        ),
                        const SizedBox(width: 9),
                        _HeaderMetric(
                          icon:
                              Icons.inventory_2_outlined,
                          value: '$acceptedCount',
                          label: 'Accepted',
                        ),
                        const SizedBox(width: 9),
                        _HeaderMetric(
                          icon:
                              Icons.local_shipping_outlined,
                          value: '$deliveredCount',
                          label: 'Delivered',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 60,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withAlpha(32),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 17,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFDCEFFA),
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
