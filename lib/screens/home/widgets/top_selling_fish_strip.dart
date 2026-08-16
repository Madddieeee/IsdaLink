import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

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

  List<TopSellingFish> buildTopSellingFish(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final fishMap = <String, TopSellingFish>{};

    for (final document in documents) {
      final data = document.data();

      if (!isCompletedOrder(data)) {
        continue;
      }

      final rawProductName = OrderHelpers.getStringValue(
        data,
        'productName',
        'Fish Product',
      );

      if (FishNameHelper.isTestLike(rawProductName)) {
        continue;
      }

      final fishName =
          FishNameHelper.canonicalDisplayName(rawProductName);
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

      final storedFulfilledQuantity =
          OrderHelpers.getDoubleValue(
        data,
        'fulfilledQuantity',
      );
      final quantity =
          storedFulfilledQuantity > 0
              ? storedFulfilledQuantity
              : OrderHelpers.getDoubleValue(
                  data,
                  'quantity',
                );

      final fulfilledTotalAmount =
          OrderHelpers.getDoubleValue(
        data,
        'fulfilledTotalAmount',
      );
      final revenue =
          fulfilledTotalAmount > 0
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
      ..sort(
        (a, b) => b.quantity.compareTo(a.quantity),
      );

    return fishList;
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
                            'Unable to load available ${fish.name}: ${stockSnapshot.error}',
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
    List<TopSellingFish> fishList,
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
                            Color(0xFFFFB703),
                            Color(0xFFFF7A1A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
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
                            'Your Top Purchased Fish',
                            style: TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Grouped by fish product and quantity unit from your completed purchases.',
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
                child: fishList.isEmpty
                    ? const Center(
                        child: Text(
                          'You do not have completed purchase records yet.',
                          style: TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                        itemCount: fishList.length,
                        itemBuilder: (context, index) {
                          return TopSellingFishListTile(
                            rank: index + 1,
                            fish: fishList[index],
                            onTap: () {
                              Navigator.pop(sheetContext);

                              showAvailableFishSheet(
                                context,
                                fishList[index],
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null || userId.isEmpty) {
      return const TopSellingStateLine(
        text: 'Your top fish will appear after completed purchases.',
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
          return TopSellingStateLine(
            text: 'Unable to load top-selling fish',
            isError: true,
          );
        }

        if (!snapshot.hasData) {
          return const TopSellingLoadingLine();
        }

        final allFish = buildTopSellingFish(snapshot.data!.docs);
        final topFiveFish = allFish.take(5).toList();

        if (topFiveFish.isEmpty) {
          return const TopSellingStateLine(
            text: 'Your top fish will appear after completed purchases.',
          );
        }

        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 40,
                padding: const EdgeInsets.fromLTRB(
                  8,
                  6,
                  44,
                  6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F9FF),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: const Color(0xFFC9EDF7),
                  ),
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
                    GestureDetector(
                      onTap: () => showAllFishSheet(
                        context,
                        allFish,
                      ),
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF7A1A),
                              Color(0xFFFFB703),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: 13,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Your Top Fish',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TopSellingFishMarqueeLine(
                        fishList: topFiveFish,
                        onFishTap: (
                          fish,
                        ) {
                          showAvailableFishSheet(
                            context,
                            fish,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -1,
                top: -1,
                child: GestureDetector(
                  onTap: () => showAllFishSheet(
                    context,
                    allFish,
                  ),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFDFA8),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18FF7A1A),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.format_list_bulleted,
                      color: Color(0xFFFF7A1A),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        height: 28,
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
                  fontSize: 11.5,
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
  });

  final int rank;
  final TopSellingFish fish;
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
              width: 34,
              height: 34,
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
              style: const TextStyle(
                fontSize: 25,
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
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${formatNumber(fish.quantity)} ${fish.quantityUnit} bought • ${fish.orderCount} completed orders',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 10.8,
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
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
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
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: const Color(0xFFD7EEF6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.local_fire_department,
            color: isError ? const Color(0xFFD32F2F) : const Color(0xFFFF7A1A),
            size: 18,
          ),
          const SizedBox(width: 8),
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
