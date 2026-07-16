import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/manage_products/widgets/manage_product_card.dart';
import 'package:isdalink/screens/supplier/manage_products/widgets/manage_product_dialogs.dart';
import 'package:isdalink/screens/supplier/manage_products/widgets/manage_products_header.dart';
import 'package:isdalink/screens/supplier/manage_products/widgets/manage_products_status_cards.dart';
import 'package:isdalink/services/supplier_product_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierManageProductsScreen
    extends
        StatelessWidget {
  const SupplierManageProductsScreen({
    super.key,
  });

  User? get currentUser => FirebaseAuth.instance.currentUser;

  SupplierProductService get productService => const SupplierProductService();

  void showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor: isError
            ? const Color(
                0xFFD32F2F,
              )
            : const Color(
                0xFF2E7D32,
              ),
      ),
    );
  }

  Future<
    void
  >
  editProduct({
    required BuildContext context,
    required QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  }) async {
    final input = await ManageProductDialogs.showEditDialog(
      context: context,
      document: document,
    );

    if (!context.mounted) {
      return;
    }

    if (input ==
        null) {
      return;
    }

    try {
      await productService.updateProduct(
        documentId: document.id,
        input: input,
      );

      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Product updated successfully.',
      );
    } catch (
      error
    ) {
      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Failed to update product: $error',
        isError: true,
      );
    }
  }

  Future<
    void
  >
  toggleAvailability({
    required BuildContext context,
    required String documentId,
    required String currentStatus,
  }) async {
    final newStatus =
        currentStatus.toLowerCase() ==
            'unavailable'
        ? 'available'
        : 'unavailable';

    try {
      await productService.toggleAvailability(
        documentId: documentId,
        currentStatus: currentStatus,
      );

      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Product marked as $newStatus.',
      );
    } catch (
      error
    ) {
      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Failed to update availability: $error',
        isError: true,
      );
    }
  }

  Future<
    void
  >
  confirmDelete({
    required BuildContext context,
    required String documentId,
    required String productName,
  }) async {
    final shouldDelete = await ManageProductDialogs.showDeleteDialog(
      context: context,
      productName: productName,
    );

    if (!context.mounted) {
      return;
    }

    if (!shouldDelete) {
      return;
    }

    try {
      await productService.deleteProduct(
        documentId,
      );

      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Product deleted from Firebase.',
        isError: true,
      );
    } catch (
      error
    ) {
      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Failed to delete product: $error',
        isError: true,
      );
    }
  }

  Widget bodyContent({
    required BuildContext context,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  }) {
    final stats = productService.calculateStats(
      documents,
    );

    return Column(
      children: [
        ManageProductsHeader(
          stats: stats,
          onBack: () => Navigator.pop(
            context,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              20,
            ),
            children: [
              const Text(
                'Your Firebase Product Records',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                'These records belong only to the logged-in supplier account.',
                style: TextStyle(
                  color: Color(
                    0xFF7B8FA3,
                  ),
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              if (documents.isEmpty)
                const ManageProductsEmptyCard()
              else
                ...documents.map(
                  (
                    document,
                  ) {
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
                    );

                    return ManageProductCard(
                      document: document,
                      onEdit: () => editProduct(
                        context: context,
                        document: document,
                      ),
                      onToggleAvailability: () => toggleAvailability(
                        context: context,
                        documentId: document.id,
                        currentStatus: status,
                      ),
                      onDelete: () => confirmDelete(
                        context: context,
                        documentId: document.id,
                        productName: productName,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget loadingBody(
    BuildContext context,
  ) {
    return Column(
      children: [
        ManageProductsHeader(
          stats: const SupplierProductStats(
            totalProducts: 0,
            lowStockCount: 0,
            unavailableCount: 0,
          ),
          onBack: () => Navigator.pop(
            context,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              20,
            ),
            children: const [
              Text(
                'Your Firebase Product Records',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                height: 18,
              ),
              ManageProductsLoadingCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget errorBody(
    BuildContext context,
    Object error,
  ) {
    return Column(
      children: [
        ManageProductsHeader(
          stats: const SupplierProductStats(
            totalProducts: 0,
            lowStockCount: 0,
            unavailableCount: 0,
          ),
          onBack: () => Navigator.pop(
            context,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              20,
            ),
            children: [
              const Text(
                'Your Firebase Product Records',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              ManageProductsErrorCard(
                error: error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget notLoggedInBody() {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(
            22,
          ),
          padding: const EdgeInsets.all(
            18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ),
          ),
          child: const Text(
            'Please log in first to manage supplier products.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(
                0xFFD32F2F,
              ),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user = currentUser;

    if (user ==
        null) {
      return notLoggedInBody();
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body:
          StreamBuilder<
            QuerySnapshot<
              Map<
                String,
                dynamic
              >
            >
          >(
            stream: productService.fishStocksStream(
              user.uid,
            ),
            builder:
                (
                  context,
                  snapshot,
                ) {
                  if (snapshot.hasError) {
                    return errorBody(
                      context,
                      snapshot.error!,
                    );
                  }

                  if (!snapshot.hasData) {
                    return loadingBody(
                      context,
                    );
                  }

                  final documents = productService.sortStocks(
                    snapshot.data!.docs,
                  );

                  return bodyContent(
                    context: context,
                    documents: documents,
                  );
                },
          ),
    );
  }
}
