import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/home/widgets/recent_fish_card.dart';
import 'package:isdalink/services/home_stock_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class RecentFishPosts
    extends
        StatelessWidget {
  const RecentFishPosts({
    super.key,
    required this.onProductTap,
  });

  final void Function(
    Supplier supplier,
    FishProduct product,
    String stockId,
    String supplierId,
  )
  onProductTap;

  HomeStockService get stockService => const HomeStockService();

  Widget supplierUnavailableCard(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Supplier information is not available yet.',
            ),
          ),
        );
      },
      child: Container(
        width: 158,
        margin: const EdgeInsets.only(
          right: 14,
        ),
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            22,
          ),
        ),
        child: const Center(
          child: Text(
            'Supplier information is not available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
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
    return ListView(
      padding: const EdgeInsets.only(
        left: 20,
      ),
      scrollDirection: Axis.horizontal,
      children: [
        Container(
          width: 250,
          padding: const EdgeInsets.all(
            16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              22,
            ),
          ),
          child: Text(
            'Unable to load recent fish posts: $error',
            style: const TextStyle(
              color: Color(
                0xFFD32F2F,
              ),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget loadingList() {
    return ListView(
      padding: const EdgeInsets.only(
        left: 20,
      ),
      scrollDirection: Axis.horizontal,
      children: List.generate(
        3,
        (
          index,
        ) => Container(
          width: 158,
          margin: const EdgeInsets.only(
            right: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              22,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget emptyList() {
    return ListView(
      padding: const EdgeInsets.only(
        left: 20,
      ),
      scrollDirection: Axis.horizontal,
      children: [
        Container(
          width: 250,
          padding: const EdgeInsets.all(
            18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              22,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x10000000,
                ),
                blurRadius: 14,
                offset: Offset(
                  0,
                  7,
                ),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Color(
                  0xFF146BFF,
                ),
                size: 38,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                'No recent fish posts yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                'Supplier Firebase posts will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(
                    0xFF7B8FA3,
                  ),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget cardForDocument(
    BuildContext context,
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final data = document.data();

    final product = stockService.fishProductFromFirestore(
      data,
    );
    final supplier = stockService.supplierForStock(
      data,
    );

    final stockSupplierId = OrderHelpers.getStringValue(
      data,
      'supplierId',
      '',
    );

    if (supplier ==
        null) {
      return supplierUnavailableCard(
        context,
      );
    }

    return RecentFishCard(
      product: product,
      onTap: () => onProductTap(
        supplier,
        product,
        document.id,
        stockSupplierId,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<
      QuerySnapshot<
        Map<
          String,
          dynamic
        >
      >
    >(
      stream: stockService.recentFishPostsStream,
      builder:
          (
            context,
            snapshot,
          ) {
            if (snapshot.hasError) {
              return errorList(
                snapshot.error!,
              );
            }

            if (!snapshot.hasData) {
              return loadingList();
            }

            final documents = snapshot.data!.docs
                .where(
                  stockService.isAvailableStock,
                )
                .toList();

            if (documents.isEmpty) {
              return emptyList();
            }

            return ListView(
              padding: const EdgeInsets.only(
                left: 20,
              ),
              scrollDirection: Axis.horizontal,
              children: documents
                  .map(
                    (
                      document,
                    ) => cardForDocument(
                      context,
                      document,
                    ),
                  )
                  .toList(),
            );
          },
    );
  }
}
