import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/home/widgets/home_section_header.dart';
import 'package:isdalink/screens/home/widgets/home_carousel_physics.dart';
import 'package:isdalink/screens/home/widgets/recent_fish_card.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/services/supplier_browse_service.dart';
import 'package:isdalink/utils/app_error_message.dart';
import 'package:isdalink/utils/order_helpers.dart';

class RecentFishPosts extends StatelessWidget {
  const RecentFishPosts({
    super.key,
    required this.onProductTap,
    required this.onViewAll,
  });

  final void Function(
    Supplier supplier,
    FishProduct product,
    String stockId,
    String supplierId,
  ) onProductTap;
  final VoidCallback onViewAll;

  HomeStockService get stockService => const HomeStockService();

  Widget supplierUnavailableCard(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Supplier information is not available yet.',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: Text(
            'Supplier information is not available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget errorList(
    Object error,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9EAF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFD65A5A),
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              AppErrorMessage.from(
                error,
                fallback: 'Unable to load fresh fish stocks right now.',
              ),
              style: const TextStyle(
                color: Color(0xFF6F8494),
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingGrid() {
    return SizedBox(
      height: 214,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 2,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 190,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCECF3)),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  Widget emptyList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFF146BFF),
            size: 38,
          ),
          SizedBox(height: 10),
          Text(
            'No recent fish posts yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Supplier fish stocks will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget cardForDocument(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> document, {
    bool isWide = false,
    required Map<String, String> supplierImageUrlsById,
  }) {
    final data = document.data();

    final product = stockService.fishProductFromFirestore(data);
    final supplier = stockService.supplierForStock(data);

    final stockSupplierId = OrderHelpers.getStringValue(
      data,
      'supplierId',
      '',
    );

    if (supplier == null) {
      return supplierUnavailableCard(context);
    }

    return RecentFishCard(
      product: product,
      supplierName: supplier.name,
      supplierImageUrl: stockService.supplierImageUrlForStock(
        data,
        supplierImageUrlsById,
      ),
      isWide: isWide,
      badgeLabel: stockService.arrivalBadge(data),
      activityLabel: stockService.activityLabel(data),
      onTap: () => onProductTap(
        supplier,
        product,
        document.id,
        stockSupplierId,
      ),
    );
  }

  Widget exploreAllFishCard({
    required int totalStocks,
  }) {
    return SizedBox(
      width: 134,
      child: Center(
        child: SizedBox(
          height: 158,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF5FBFD),
                      Color(0xFFEAF7FB),
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFCFE7F1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D075C9B),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: const Color(0xFFD3EAF3)),
                        ),
                        child: const Icon(
                          Icons.set_meal_rounded,
                          color: Color(0xFF087AC0),
                          size: 17,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$totalStocks fish stocks',
                        style: const TextStyle(
                          color: Color(0xFF7693A4),
                          fontSize: 8.8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'See all fresh stock',
                        style: TextStyle(
                          color: Color(0xFF123B55),
                          fontSize: 13.5,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Row(
                        children: [
                          Text(
                            'Browse market',
                            style: TextStyle(
                              color: Color(0xFF087AC0),
                              fontSize: 8.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF087AC0),
                            size: 13,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget feedForCutoff(
    BuildContext context,
    DateTime cutoff,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: const SupplierBrowseService().suppliersStream,
      builder: (context, supplierSnapshot) {
        final supplierImageUrlsById = stockService.supplierImageUrlsById(
          supplierSnapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stockService.recentFishPostsStream,
          builder: (context, snapshot) {
            final allDocuments = snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final unseenCount = stockService.unseenArrivalCount(
              allDocuments,
              cutoff,
            );

            Widget body;

            if (snapshot.hasError) {
              body = errorList(snapshot.error!);
            } else if (!snapshot.hasData) {
              body = loadingGrid();
            } else {
              final allAvailableStocks = stockService.availableStocks(
                allDocuments,
              );
              final documents = allAvailableStocks.take(6).toList();

              if (documents.isEmpty) {
                body = emptyList();
              } else {
                final hasMoreStocks = allAvailableStocks.length > documents.length;

                final screenWidth = MediaQuery.sizeOf(context).width;
                final cardWidth =
                    (screenWidth * 0.50).clamp(184.0, 198.0).toDouble();
                final cards = <Widget>[
                  for (final document in documents)
                    SizedBox(
                      width: cardWidth,
                      child: cardForDocument(
                        context,
                        document,
                        isWide: false,
                        supplierImageUrlsById: supplierImageUrlsById,
                      ),
                    ),
                  if (hasMoreStocks)
                    SizedBox(
                      width: 148,
                      child: exploreAllFishCard(
                        totalStocks: allAvailableStocks.length,
                      ),
                    ),
                ];

                body = SizedBox(
                  height: 214,
                  child: _HomeFishSnappingCarousel(
                    itemExtent: cardWidth + 12,
                    children: cards,
                  ),
                );
              }
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: HomeSectionHeader(
                    title: 'Latest Fish Stocks',
                    icon: Icons.set_meal,
                    badgeLabel:
                        unseenCount > 0 ? '$unseenCount updates' : null,
                    actionLabel: 'View all',
                    onViewAll: onViewAll,
                  ),
                ),
                const SizedBox(height: 9),
                body,
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      return feedForCutoff(
        context,
        stockService.feedCutoff(null),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: stockService.vendorFeedStateStream(userId),
      builder: (context, snapshot) {
        final cutoff = stockService.feedCutoff(snapshot.data?.data());
        return feedForCutoff(context, cutoff);
      },
    );
  }
}


class _HomeFishSnappingCarousel extends StatelessWidget {
  const _HomeFishSnappingCarousel({
    required this.children,
    required this.itemExtent,
  });

  final List<Widget> children;
  final double itemExtent;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16, right: 16),
      physics: HomeItemSnapScrollPhysics(
        parent: const BouncingScrollPhysics(),
        itemExtent: itemExtent,
      ),
      itemCount: children.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        return children[index];
      },
    );
  }
}
