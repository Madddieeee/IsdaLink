import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/utils/app_error_message.dart';
import 'package:isdalink/utils/order_helpers.dart';

enum TopFishHistoryPeriod {
  thisMonth,
  threeMonths,
  allTime,
}

class TopSellingFishStrip extends StatefulWidget {
  const TopSellingFishStrip({
    super.key,
    required this.onProductTap,
  });

  final void Function(
    Supplier supplier,
    FishProduct product,
    String stockId,
    String supplierId,
  ) onProductTap;

  @override
  State<TopSellingFishStrip> createState() => _TopSellingFishStripState();
}

class _TopSellingFishStripState extends State<TopSellingFishStrip> {
  HomeStockService get stockService => const HomeStockService();

  bool isCompletedOrder(
    Map<String, dynamic> data,
  ) {
    final status = OrderHelpers.getStringValue(
      data,
      'orderStatus',
      'Pending',
    ).toLowerCase();

    return status == 'delivered' || status == 'completed';
  }

  String normalizedUnit(
    String rawUnit,
  ) {
    final value = rawUnit
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    if (value == 'kg' ||
        value == 'kilo' ||
        value == 'kilos' ||
        value == 'kilogram' ||
        value == 'kilograms') {
      return 'kilogram';
    }

    if (value == 'tabs') {
      return 'tab';
    }

    if (value == 'ice box' ||
        value == 'ice boxes' ||
        value == 'iceboxes') {
      return 'icebox';
    }

    return value.isEmpty ? 'kilogram' : value;
  }

  DateTime? orderDate(
    Map<String, dynamic> data,
  ) {
    const keys = <String>[
      'transactionDate',
      'orderDate',
      'createdAt',
      'completedAt',
      'deliveredAt',
      'updatedAt',
    ];

    for (final key in keys) {
      final value = data[key];

      if (value is Timestamp) {
        return value.toDate().toLocal();
      }

      if (value is DateTime) {
        return value.toLocal();
      }

      if (value is String) {
        final parsed = DateTime.tryParse(value);

        if (parsed != null) {
          return parsed.toLocal();
        }
      }
    }

    return null;
  }

  DateTime monthStart(
    DateTime date,
  ) {
    return DateTime(date.year, date.month);
  }

  DateTime nextMonthStart(
    DateTime date,
  ) {
    return DateTime(date.year, date.month + 1);
  }

  List<TopSellingFish> buildTopSellingFish(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents, {
    DateTime? startInclusive,
    DateTime? endExclusive,
  }) {
    final fishMap = <String, TopSellingFish>{};

    for (final document in documents) {
      final data = document.data();

      if (!isCompletedOrder(data)) {
        continue;
      }

      if (startInclusive != null || endExclusive != null) {
        final date = orderDate(data);

        if (date == null) {
          continue;
        }

        if (startInclusive != null && date.isBefore(startInclusive)) {
          continue;
        }

        if (endExclusive != null && !date.isBefore(endExclusive)) {
          continue;
        }
      }

      final rawProductName = OrderHelpers.getStringValue(
        data,
        'productName',
        'Fish Product',
      );

      if (FishNameHelper.isTestLike(rawProductName)) {
        continue;
      }

      final fishName = FishNameHelper.canonicalDisplayName(rawProductName);
      final quantityUnit = normalizedUnit(
        OrderHelpers.getStringValue(
          data,
          'quantityUnit',
          'kilogram',
        ),
      );
      final fishKey =
          '${FishNameHelper.canonicalKey(rawProductName)}|$quantityUnit';

      final emoji = OrderHelpers.getStringValue(
        data,
        'productEmoji',
        OrderHelpers.getStringValue(
          data,
          'emoji',
          FishNameHelper.defaultEmoji(fishName),
        ),
      );

      final storedFulfilledQuantity = OrderHelpers.getDoubleValue(
        data,
        'fulfilledQuantity',
      );
      final quantity = storedFulfilledQuantity > 0
          ? storedFulfilledQuantity
          : OrderHelpers.getDoubleValue(
              data,
              'quantity',
            );

      final fulfilledTotalAmount = OrderHelpers.getDoubleValue(
        data,
        'fulfilledTotalAmount',
      );
      final revenue = fulfilledTotalAmount > 0
          ? fulfilledTotalAmount
          : OrderHelpers.getDoubleValue(
              data,
              'totalAmount',
            );

      final currentFish = fishMap[fishKey];

      fishMap[fishKey] = TopSellingFish(
        name: fishName,
        emoji: currentFish?.emoji ?? emoji,
        quantityUnit: quantityUnit,
        quantity: (currentFish?.quantity ?? 0.0) + quantity,
        revenue: (currentFish?.revenue ?? 0.0) + revenue,
        orderCount: (currentFish?.orderCount ?? 0) + 1,
      );
    }

    final fishList = fishMap.values.toList()
      ..sort((a, b) {
        final quantityCompare = b.quantity.compareTo(a.quantity);

        if (quantityCompare != 0) {
          return quantityCompare;
        }

        final orderCompare = b.orderCount.compareTo(a.orderCount);

        if (orderCompare != 0) {
          return orderCompare;
        }

        return a.name.compareTo(b.name);
      });

    return fishList;
  }

  List<TopFishMonthHistory> buildPreviousThreeMonths(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    DateTime now,
  ) {
    return List<TopFishMonthHistory>.generate(3, (index) {
      final start = DateTime(now.year, now.month - (index + 1));
      final end = nextMonthStart(start);

      return TopFishMonthHistory(
        month: start,
        fish: buildTopSellingFish(
          documents,
          startInclusive: start,
          endExclusive: end,
        ),
      );
    });
  }

  void showAvailableFishSheet(
    BuildContext context,
    TopSellingFish fish,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF4FAFF),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9DDEA),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF087AC0),
                            Color(0xFF10B7D4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          fish.emoji,
                          style: const TextStyle(
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available ${fish.name} · ${fish.quantityUnit}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Suppliers currently selling this fish.',
                            style: TextStyle(
                              color: Color(0xFF7B8FA3),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('fishStocks')
                      .snapshots(),
                  builder: (context, stockSnapshot) {
                    if (stockSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            AppErrorMessage.from(
                              stockSnapshot.error!,
                              fallback:
                                  'Unable to load available ${fish.name} right now.',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }

                    if (!stockSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      );
                    }

                    final availableStocks = stockSnapshot.data!.docs.where(
                      (document) {
                        final data = document.data();

                        final productName = OrderHelpers.getStringValue(
                          data,
                          'productName',
                          'Fish Product',
                        );

                        final status = OrderHelpers.getStringValue(
                          data,
                          'status',
                          'available',
                        ).toLowerCase();

                        final quantity = OrderHelpers.getDoubleValue(
                          data,
                          'quantity',
                        );

                        final stockFishKey = FishNameHelper.canonicalKey(
                          productName,
                        );

                        final stockUnit = normalizedUnit(
                          OrderHelpers.getStringValue(
                            data,
                            'quantityUnit',
                            'kilogram',
                          ),
                        );

                        return stockFishKey ==
                                FishNameHelper.canonicalKey(fish.name) &&
                            stockUnit == fish.quantityUnit &&
                            (status == 'available' || status == 'active') &&
                            quantity > 0;
                      },
                    ).toList();

                    if (availableStocks.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Text(
                            'No available ${fish.name} stocks are posted right now.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF7B8FA3),
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                      itemCount: availableStocks.length,
                      itemBuilder: (context, index) {
                        final document = availableStocks[index];
                        final data = document.data();

                        final product = stockService.fishProductFromFirestore(
                          data,
                        );

                        final supplier = stockService.supplierForStock(
                          data,
                        );

                        final supplierId = OrderHelpers.getStringValue(
                          data,
                          'supplierId',
                          '',
                        );

                        if (supplier == null) {
                          return const SizedBox.shrink();
                        }

                        return AvailableFishMarketTile(
                          product: product,
                          supplier: supplier,
                          onTap: () {
                            Navigator.pop(sheetContext);

                            widget.onProductTap(
                              supplier,
                              product,
                              document.id,
                              supplierId,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void showAllFishSheet(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final now = DateTime.now();
    final currentStart = monthStart(now);
    final currentEnd = nextMonthStart(currentStart);
    final currentFish = buildTopSellingFish(
      documents,
      startInclusive: currentStart,
      endExclusive: currentEnd,
    );
    final previousMonths = buildPreviousThreeMonths(documents, now);
    final allTimeFish = buildTopSellingFish(documents);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FishPurchaseHistorySheet(
          currentMonth: currentStart,
          currentFish: currentFish,
          previousMonths: previousMonths,
          allTimeFish: allTimeFish,
          onFishTap: (fish) {
            Navigator.pop(sheetContext);
            showAvailableFishSheet(context, fish);
          },
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null || userId.isEmpty) {
      return const TopSellingStateLine(
        text: 'Your purchase insight will appear after completed orders.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Order documents contain private vendor contact and delivery data.
      // Read only the signed-in vendor's orders instead of the whole
      // marketplace order collection.
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const TopSellingStateLine(
            text: 'Unable to load your purchase insight right now.',
            isError: true,
          );
        }

        if (!snapshot.hasData) {
          return const TopSellingLoadingLine();
        }

        final documents = snapshot.data!.docs;
        final now = DateTime.now();
        final currentStart = monthStart(now);
        final currentEnd = nextMonthStart(currentStart);
        final currentFish = buildTopSellingFish(
          documents,
          startInclusive: currentStart,
          endExclusive: currentEnd,
        );
        final allTimeFish = buildTopSellingFish(documents);
        final topFish = currentFish.isEmpty ? null : currentFish.first;

        if (allTimeFish.isEmpty) {
          return const TopSellingStateLine(
            text: 'Your purchase insight will appear after completed orders.',
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showAllFishSheet(context, documents),
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                height: 60,
                decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD6EAF3)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10002842),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE7F8FD),
                            Color(0xFFDDF3FA),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: const Color(0xFFCFEAF4),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        topFish?.emoji ?? '🐟',
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Top Fish',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF12354C),
                              fontSize: 10.9,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            topFish == null
                                ? 'No completed orders this month'
                                : '#1 ${topFish.name} · this month',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: topFish == null
                                  ? const Color(0xFF849CAA)
                                  : const Color(0xFF3F6F8C),
                              fontSize: 8.2,
                              height: 1,
                              fontWeight: topFish == null
                                  ? FontWeight.w700
                                  : FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FD),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: const Color(0xFFDCEFF7),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            color: Color(0xFF0877C9),
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'History',
                            style: TextStyle(
                              color: Color(0xFF0877C9),
                              fontSize: 8.8,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FishPurchaseHistorySheet extends StatefulWidget {
  const FishPurchaseHistorySheet({
    super.key,
    required this.currentMonth,
    required this.currentFish,
    required this.previousMonths,
    required this.allTimeFish,
    required this.onFishTap,
  });

  final DateTime currentMonth;
  final List<TopSellingFish> currentFish;
  final List<TopFishMonthHistory> previousMonths;
  final List<TopSellingFish> allTimeFish;
  final ValueChanged<TopSellingFish> onFishTap;

  @override
  State<FishPurchaseHistorySheet> createState() =>
      _FishPurchaseHistorySheetState();
}

class _FishPurchaseHistorySheetState extends State<FishPurchaseHistorySheet> {
  TopFishHistoryPeriod selectedPeriod = TopFishHistoryPeriod.thisMonth;

  static const monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String monthLabel(DateTime month) {
    return '${monthNames[month.month - 1]} ${month.year}';
  }

  Widget periodButton({
    required TopFishHistoryPeriod period,
    required String label,
  }) {
    final selected = selectedPeriod == period;

    return Expanded(
      child: Material(
        color: selected ? const Color(0xFF087AC0) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            if (selectedPeriod != period) {
              setState(() => selectedPeriod = period);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 38,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF6E8798),
                  fontSize: 10.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8FD),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xFF87AFC4),
              size: 23,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget rankingList(List<TopSellingFish> fish) {
    if (fish.isEmpty) {
      return emptyState('No completed fish purchases were recorded for this period.');
    }

    return Column(
      children: [
        for (var index = 0; index < fish.length; index++)
          TopSellingFishListTile(
            rank: index + 1,
            fish: fish[index],
            onTap: () => widget.onFishTap(fish[index]),
          ),
      ],
    );
  }

  Widget thisMonthView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: [
        _FishHistoryPeriodHeader(
          title: monthLabel(widget.currentMonth),
          subtitle: 'Completed orders placed during the current calendar month.',
        ),
        const SizedBox(height: 10),
        rankingList(widget.currentFish),
      ],
    );
  }

  Widget threeMonthsView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: [
        const _FishHistoryPeriodHeader(
          title: 'Previous 3 Months',
          subtitle:
              'Three complete calendar months before the current month. Each month is ranked separately.',
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < widget.previousMonths.length; index++) ...[
          _FishMonthSection(
            title: monthLabel(widget.previousMonths[index].month),
            fish: widget.previousMonths[index].fish,
            onFishTap: widget.onFishTap,
          ),
          if (index != widget.previousMonths.length - 1)
            const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget allTimeView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      children: [
        const _FishHistoryPeriodHeader(
          title: 'All-Time Purchase Ranking',
          subtitle: 'All of your completed fish purchases recorded in IsdaLink.',
        ),
        const SizedBox(height: 10),
        rankingList(widget.allTimeFish),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.84;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Color(0xFFF4FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC8DCE8),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF087AC0),
                          Color(0xFF10B7D4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fish Purchase History',
                          style: TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Completed orders only · tap a fish to find it in the market.',
                          style: TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 10.7,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF6E8798),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1F6),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    periodButton(
                      period: TopFishHistoryPeriod.thisMonth,
                      label: 'This Month',
                    ),
                    periodButton(
                      period: TopFishHistoryPeriod.threeMonths,
                      label: '3 Months',
                    ),
                    periodButton(
                      period: TopFishHistoryPeriod.allTime,
                      label: 'All Time',
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: switch (selectedPeriod) {
                  TopFishHistoryPeriod.thisMonth => KeyedSubtree(
                      key: const ValueKey('this-month'),
                      child: thisMonthView(),
                    ),
                  TopFishHistoryPeriod.threeMonths => KeyedSubtree(
                      key: const ValueKey('three-months'),
                      child: threeMonthsView(),
                    ),
                  TopFishHistoryPeriod.allTime => KeyedSubtree(
                      key: const ValueKey('all-time'),
                      child: allTimeView(),
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FishHistoryPeriodHeader extends StatelessWidget {
  const _FishHistoryPeriodHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD5ECF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF087AC0),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF17384E),
                    fontSize: 12.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7790A1),
                    fontSize: 9.5,
                    height: 1.28,
                    fontWeight: FontWeight.w600,
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

class _FishMonthSection extends StatelessWidget {
  const _FishMonthSection({
    required this.title,
    required this.fish,
    required this.onFishTap,
  });

  final String title;
  final List<TopSellingFish> fish;
  final ValueChanged<TopSellingFish> onFishTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFDCEBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B002842),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 9),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Color(0xFF087AC0),
                  size: 14,
                ),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF17384E),
                    fontSize: 12.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (fish.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 2, 2, 14),
              child: Text(
                'No completed fish purchases for this month.',
                style: TextStyle(
                  color: Color(0xFF8AA0AF),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            for (var index = 0; index < fish.length; index++)
              TopSellingFishListTile(
                rank: index + 1,
                fish: fish[index],
                onTap: () => onFishTap(fish[index]),
                compact: true,
              ),
        ],
      ),
    );
  }
}

class TopSellingFishMarqueeLine extends StatefulWidget {
  const TopSellingFishMarqueeLine({
    super.key,
    required this.fishList,
    required this.onFishTap,
  });

  final List<TopSellingFish> fishList;
  final void Function(TopSellingFish fish) onFishTap;

  @override
  State<TopSellingFishMarqueeLine> createState() =>
      _TopSellingFishMarqueeLineState();
}

class _TopSellingFishMarqueeLineState extends State<TopSellingFishMarqueeLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void didUpdateWidget(
    TopSellingFishMarqueeLine oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.fishList.length != widget.fishList.length) {
      controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String marqueeText() {
    return widget.fishList.asMap().entries.map(
      (entry) {
        final rank = entry.key + 1;
        final fish = entry.value;
        return '#$rank ${fish.emoji} ${fish.name}';
      },
    ).join('   •   ');
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final displayText = marqueeText();

    return GestureDetector(
      onTap: () {
        if (widget.fishList.isNotEmpty) {
          widget.onFishTap(
            widget.fishList.first,
          );
        }
      },
      child: SizedBox(
        height: 18,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final width = MediaQuery.of(context).size.width;
              final offset = width - (controller.value * width * 2);

              return Transform.translate(
                offset: Offset(
                  offset,
                  0,
                ),
                child: child,
              );
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$displayText   •   $displayText',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopSellingFishListTile extends StatelessWidget {
  const TopSellingFishListTile({
    super.key,
    required this.rank,
    required this.fish,
    required this.onTap,
    this.compact = false,
  });

  final int rank;
  final TopSellingFish fish;
  final VoidCallback onTap;
  final bool compact;

  String formatNumber(
    double value,
  ) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: compact ? 9 : 10),
        padding: EdgeInsets.all(compact ? 10 : 13),
        decoration: BoxDecoration(
          color: compact ? const Color(0xFFF7FBFD) : Colors.white,
          borderRadius: BorderRadius.circular(compact ? 15 : 19),
          border: compact
              ? Border.all(color: const Color(0xFFE0EEF4))
              : null,
          boxShadow: compact
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 30 : 34,
              height: compact ? 30 : 34,
              decoration: BoxDecoration(
                color: const Color(0xFF087AC0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Text(
              fish.emoji,
              style: TextStyle(
                fontSize: compact ? 21 : 25,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fish.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF102C44),
                      fontSize: compact ? 12.4 : 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${formatNumber(fish.quantity)} ${fish.quantityUnit} bought • ${fish.orderCount} completed orders',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF7B8FA3),
                      fontSize: compact ? 9.8 : 10.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9AADBC),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class AvailableFishMarketTile extends StatelessWidget {
  const AvailableFishMarketTile({
    super.key,
    required this.product,
    required this.supplier,
    required this.onTap,
  });

  final FishProduct product;
  final Supplier supplier;
  final VoidCallback onTap;

  String formatNumber(
    double value,
  ) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F9FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  product.emoji,
                  style: const TextStyle(
                    fontSize: 27,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    supplier.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF087AC0),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    supplier.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF087AC0),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatNumber(product.availableQuantity)} ${product.quantityUnit}',
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TopSellingLoadingLine extends StatelessWidget {
  const TopSellingLoadingLine({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD8EAF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10002842),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class TopSellingStateLine extends StatelessWidget {
  const TopSellingStateLine({
    super.key,
    required this.text,
    this.isError = false,
  });

  final String text;
  final bool isError;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD8EAF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10002842),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.local_fire_department,
            color: isError ? const Color(0xFFD32F2F) : const Color(0xFFFF7A1A),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopFishMonthHistory {
  const TopFishMonthHistory({
    required this.month,
    required this.fish,
  });

  final DateTime month;
  final List<TopSellingFish> fish;
}

class TopSellingFish {
  const TopSellingFish({
    required this.name,
    required this.emoji,
    required this.quantityUnit,
    required this.quantity,
    required this.revenue,
    required this.orderCount,
  });

  final String name;
  final String emoji;
  final String quantityUnit;
  final double quantity;
  final double revenue;
  final int orderCount;
}

class FishNameHelper {
  const FishNameHelper();

  static bool isTestLike(
    String rawName,
  ) {
    final value = rawName.trim().toLowerCase();

    return value == 'test' ||
        value == 'testing' ||
        value == 'asdw' ||
        value == 'asdf' ||
        value == 'sample';
  }

  static String canonicalDisplayName(
    String rawName,
  ) {
    final cleaned = cleanedDisplayText(rawName);
    final lowerName = cleaned.toLowerCase();

    final aliases = <String, String>{
      'bangus': 'Bangus',
      'milkfish': 'Bangus',
      'tilapia': 'Tilapia',
      'torta': 'Torta',
      'isda': 'Isda',
      'goldfish': 'Goldfish',
      'galunggong': 'Galunggong',
      'round scad': 'Galunggong',
      'tulingan': 'Tulingan',
      'tamban': 'Tamban',
      'tuna': 'Tuna',
      'salmon': 'Salmon',
      'shark': 'Shark',
      'lapu lapu': 'Lapu-Lapu',
      'lapu-lapu': 'Lapu-Lapu',
      'maya maya': 'Maya-Maya',
      'maya-maya': 'Maya-Maya',
      'pusit': 'Squid',
      'squid': 'Squid',
      'hipon': 'Shrimp',
      'shrimp': 'Shrimp',
      'crab': 'Crab',
      'alimasag': 'Crab',
      'alimango': 'Crab',
    };

    for (final entry in aliases.entries) {
      if (lowerName == entry.key || lowerName.contains(entry.key)) {
        return entry.value;
      }
    }

    return titleCase(cleaned);
  }

  static String canonicalKey(
    String rawName,
  ) {
    return canonicalDisplayName(rawName)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static String cleanedDisplayText(
    String rawName,
  ) {
    var value = rawName.trim();

    if (value.isEmpty) {
      return 'Fish Product';
    }

    value = value.replaceAll('_', ' ');
    value = value.replaceAll('-', ' ');
    value = value.replaceAll(RegExp(r'(?<=[a-z])(?=[A-Z])'), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();

    value = value.split(RegExp(r'\s+[@|/]\s+')).first.trim();
    value = value.split(RegExp(r'\s+\bin\b\s+', caseSensitive: false)).first.trim();
    value = value.split(RegExp(r'\s+\bfrom\b\s+', caseSensitive: false)).first.trim();

    if (value.isEmpty) {
      return 'Fish Product';
    }

    return value;
  }

  static String titleCase(
    String text,
  ) {
    return text
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map(
          (word) {
            final lowerWord = word.toLowerCase();

            if (lowerWord.length == 1) {
              return lowerWord.toUpperCase();
            }

            return '${lowerWord[0].toUpperCase()}${lowerWord.substring(1)}';
          },
        )
        .join(' ');
  }

  static String defaultEmoji(
    String fishName,
  ) {
    final lowerName = fishName.toLowerCase();

    if (lowerName.contains('shrimp') || lowerName.contains('hipon')) {
      return '🦐';
    }

    if (lowerName.contains('squid') || lowerName.contains('pusit')) {
      return '🦑';
    }

    if (lowerName.contains('crab') ||
        lowerName.contains('alimasag') ||
        lowerName.contains('alimango')) {
      return '🦀';
    }

    if (lowerName.contains('shark')) {
      return '🦈';
    }

    return '🐟';
  }
}
