import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/services/supplier_product_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class ManageProductDialogs {
  const ManageProductDialogs._();

  static Future<
    SupplierProductUpdateInput?
  >
  showEditDialog({
    required BuildContext context,
    required QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  }) async {
    final data = document.data();

    final productNameController = TextEditingController(
      text: OrderHelpers.getStringValue(
        data,
        'productName',
        '',
      ),
    );

    final priceController = TextEditingController(
      text:
          OrderHelpers.getDoubleValue(
            data,
            'price',
          ).toStringAsFixed(
            0,
          ),
    );

    final quantityController = TextEditingController(
      text:
          OrderHelpers.getDoubleValue(
            data,
            'quantity',
          ).toStringAsFixed(
            0,
          ),
    );

    final lowStockController = TextEditingController(
      text:
          OrderHelpers.getDoubleValue(
            data,
            'lowStockLevel',
          ).toStringAsFixed(
            0,
          ),
    );

    final result =
        await showDialog<
          SupplierProductUpdateInput
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      24,
                    ),
                  ),
                  title: const Text(
                    'Edit Product',
                    style: TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: productNameController,
                          decoration: const InputDecoration(
                            labelText: 'Product Name',
                            prefixIcon: Icon(
                              Icons.set_meal,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            prefixIcon: Icon(
                              Icons.sell,
                            ),
                            suffixText: 'PHP',
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            prefixIcon: Icon(
                              Icons.inventory,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: lowStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Low Stock Alert Level',
                            prefixIcon: Icon(
                              Icons.warning_amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                      ),
                      child: const Text(
                        'Cancel',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final productName = productNameController.text.trim();

                        final price = double.tryParse(
                          priceController.text.trim(),
                        );

                        final quantity = double.tryParse(
                          quantityController.text.trim(),
                        );

                        final lowStockLevel = double.tryParse(
                          lowStockController.text.trim(),
                        );

                        if (productName.isEmpty ||
                            price ==
                                null ||
                            quantity ==
                                null ||
                            lowStockLevel ==
                                null ||
                            price <=
                                0 ||
                            quantity <
                                0 ||
                            lowStockLevel <
                                0) {
                          ScaffoldMessenger.of(
                            dialogContext,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter valid product values.',
                              ),
                              backgroundColor: Color(
                                0xFFD32F2F,
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(
                          dialogContext,
                          SupplierProductUpdateInput(
                            productName: productName,
                            price: price,
                            quantity: quantity,
                            lowStockLevel: lowStockLevel,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF146BFF,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Save',
                      ),
                    ),
                  ],
                );
              },
        );

    productNameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    lowStockController.dispose();

    return result;
  }

  static Future<
    bool
  >
  showDeleteDialog({
    required BuildContext context,
    required String productName,
  }) async {
    final shouldDelete =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      24,
                    ),
                  ),
                  title: const Text(
                    'Delete Product?',
                    style: TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to delete $productName from this supplier account?',
                    style: const TextStyle(
                      color: Color(
                        0xFF52677A,
                      ),
                      height: 1.4,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        false,
                      ),
                      child: const Text(
                        'Cancel',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        true,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFD32F2F,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Delete',
                      ),
                    ),
                  ],
                );
              },
        );

    return shouldDelete ??
        false;
  }
}
