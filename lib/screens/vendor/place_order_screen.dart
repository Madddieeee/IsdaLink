import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/my_orders_screen.dart';
import 'package:isdalink/screens/vendor/place_order/widgets/place_order_cards.dart';
import 'package:isdalink/screens/vendor/place_order/widgets/place_order_header.dart';
import 'package:isdalink/services/place_order_service.dart';

class PlaceOrderScreen
    extends
        StatefulWidget {
  final Supplier supplier;
  final FishProduct product;
  final String stockId;
  final String supplierId;

  const PlaceOrderScreen({
    super.key,
    required this.supplier,
    required this.product,
    this.stockId = '',
    this.supplierId = '',
  });

  @override
  State<
    PlaceOrderScreen
  >
  createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState
    extends
        State<
          PlaceOrderScreen
        > {
  final PlaceOrderService orderService = const PlaceOrderService();

  int quantity = 1;
  bool isSubmitting = false;

  double get totalAmount =>
      widget.product.price *
      quantity;

  void decreaseQuantity() {
    if (quantity >
        1) {
      setState(
        () {
          quantity--;
        },
      );
    }
  }

  void increaseQuantity() {
    if (quantity <
        widget.product.availableQuantity) {
      setState(
        () {
          quantity++;
        },
      );
    } else {
      showMessage(
        'Quantity cannot exceed available stock.',
        isError: true,
      );
    }
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

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
  confirmOrder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user ==
        null) {
      showMessage(
        'Please log in first before placing an order.',
        isError: true,
      );
      return;
    }

    setState(
      () {
        isSubmitting = true;
      },
    );

    try {
      await orderService.createCodOrder(
        user: user,
        supplier: widget.supplier,
        product: widget.product,
        quantity: quantity,
        stockId: widget.stockId,
        supplierId: widget.supplierId,
      );

      if (!mounted) return;

      setState(
        () {
          isSubmitting = false;
        },
      );

      showOrderPlacedDialog();
    } catch (
      error
    ) {
      if (!mounted) return;

      setState(
        () {
          isSubmitting = false;
        },
      );

      showMessage(
        'Failed to place order: $error',
        isError: true,
      );
    }
  }

  void showOrderPlacedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                'Order Placed',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Text(
                'Your COD order for ${widget.product.name} has been saved.\n\n'
                'The ordered quantity has been reserved and deducted from the supplier stock. '
                'If the supplier cancels the order, the quantity will be returned to the available stock.',
                style: const TextStyle(
                  color: Color(
                    0xFF52677A,
                  ),
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                    Navigator.pop(
                      context,
                    );
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    'Back to Products',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (
                              _,
                            ) => const MyOrdersScreen(),
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
                    'View Orders',
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget confirmButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(
              0x14000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              -4,
            ),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isSubmitting
                ? null
                : confirmOrder,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.check_circle,
                  ),
            label: Text(
              isSubmitting
                  ? 'Saving Order...'
                  : 'Confirm COD Order',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(
                0xFF146BFF,
              ),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFF7B8FA3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
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
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Column(
        children: [
          PlaceOrderHeader(
            supplier: widget.supplier,
            product: widget.product,
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
                QuantitySelectorCard(
                  quantity: quantity,
                  product: widget.product,
                  onDecrease: decreaseQuantity,
                  onIncrease: increaseQuantity,
                ),
                const PaymentMethodCard(),
                OrderSummaryCard(
                  supplier: widget.supplier,
                  product: widget.product,
                  quantity: quantity,
                  totalAmount: totalAmount,
                ),
                const PlaceOrderInfoCard(),
              ],
            ),
          ),
          confirmButton(),
        ],
      ),
    );
  }
}
