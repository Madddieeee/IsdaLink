import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/my_orders_screen.dart';
import 'package:isdalink/screens/vendor/place_order/widgets/place_order_cards.dart';
import 'package:isdalink/screens/vendor/place_order/widgets/place_order_header.dart';
import 'package:isdalink/services/place_order_service.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({
    super.key,
    required this.supplier,
    required this.product,
    this.stockId = '',
    this.supplierId = '',
  });

  final Supplier supplier;
  final FishProduct product;
  final String stockId;
  final String supplierId;

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final PlaceOrderService orderService = const PlaceOrderService();
  final TextEditingController buyerNameController = TextEditingController();
  final TextEditingController buyerPhoneController = TextEditingController();
  final TextEditingController buyerAddressController = TextEditingController();

  int quantity = 1;
  bool isSubmitting = false;
  bool isLoadingBuyer = true;
  String buyerLoadError = '';

  double get totalAmount => widget.product.price * quantity;

  @override
  void initState() {
    super.initState();
    loadBuyerDetails();
  }

  @override
  void dispose() {
    buyerNameController.dispose();
    buyerPhoneController.dispose();
    buyerAddressController.dispose();
    super.dispose();
  }

  String firstNonEmpty(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  Future<void> loadBuyerDetails() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        isLoadingBuyer = false;
        buyerLoadError = 'Please log in again to load your buyer details.';
      });
      return;
    }

    try {
      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDocument.data() ?? <String, dynamic>{};

      buyerNameController.text = firstNonEmpty(
        userData,
        const ['name', 'fullName', 'displayName'],
        fallback: user.displayName ?? user.email ?? 'Vendor',
      );

      buyerPhoneController.text = firstNonEmpty(
        userData,
        const ['phone', 'contactNumber', 'mobileNumber'],
      );

      buyerAddressController.text = firstNonEmpty(
        userData,
        const [
          'deliveryAddress',
          'address',
          'location',
          'region',
        ],
        fallback: 'Caraga Region',
      );

      if (!mounted) return;
      setState(() {
        isLoadingBuyer = false;
        buyerLoadError = '';
      });
    } catch (error) {
      buyerNameController.text =
          user.displayName ?? user.email ?? 'Vendor';
      buyerAddressController.text = 'Caraga Region';

      if (!mounted) return;
      setState(() {
        isLoadingBuyer = false;
        buyerLoadError =
            'Some profile details could not be loaded. You can enter them below.';
      });
    }
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  void increaseQuantity() {
    if (quantity < widget.product.availableQuantity) {
      setState(() {
        quantity++;
      });
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
      ),
    );
  }

  bool validateBuyerDetails() {
    if (buyerNameController.text.trim().isEmpty) {
      showMessage('Please enter the buyer name.', isError: true);
      return false;
    }

    if (buyerPhoneController.text.trim().isEmpty) {
      showMessage('Please enter the buyer contact number.', isError: true);
      return false;
    }

    if (buyerAddressController.text.trim().isEmpty) {
      showMessage('Please enter the delivery address.', isError: true);
      return false;
    }

    return true;
  }

  Future<void> confirmOrder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Please log in first before placing an order.',
        isError: true,
      );
      return;
    }

    if (!validateBuyerDetails()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isSubmitting = true;
    });

    try {
      await orderService.createCodOrder(
        user: user,
        supplier: widget.supplier,
        product: widget.product,
        quantity: quantity,
        stockId: widget.stockId,
        supplierId: widget.supplierId,
        buyerName: buyerNameController.text.trim(),
        buyerPhone: buyerPhoneController.text.trim(),
        buyerAddress: buyerAddressController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      showOrderPlacedDialog();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      showMessage(
        'Failed to place order: $error',
        isError: true,
      );
    }
  }

  Future<void> showOrderPlacedDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E2EA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 22),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 620),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2E7D32),
                          Color(0xFF38D39F),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x3038D39F),
                          blurRadius: 18,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 43,
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'Order Placed Successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.product.name} was sent to ${widget.supplier.name} for confirmation.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE1EEF6)),
                  ),
                  child: Column(
                    children: [
                      OrderPlacedRow(
                        label: 'Product',
                        value: widget.product.name,
                      ),
                      OrderPlacedRow(
                        label: 'Quantity',
                        value: '$quantity ${widget.product.quantityUnit}',
                      ),
                      const OrderPlacedRow(
                        label: 'Payment',
                        value: 'Cash on Delivery',
                      ),
                      const Divider(height: 20),
                      OrderPlacedRow(
                        label: 'Total',
                        value: '₱${totalAmount.toStringAsFixed(0)}',
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFF087AC0),
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Track supplier updates in My Orders.',
                        style: TextStyle(
                          color: Color(0xFF52677A),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);

                          Future<void>.delayed(
                            const Duration(milliseconds: 260),
                            () {
                              if (mounted && Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF146BFF),
                          side: const BorderSide(color: Color(0xFF146BFF)),
                          minimumSize: const Size.fromHeight(51),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Continue Shopping',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);

                          Future<void>.delayed(
                            const Duration(milliseconds: 260),
                            () {
                              if (!mounted) return;

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MyOrdersScreen(),
                                ),
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF146BFF),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          minimumSize: const Size.fromHeight(51),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'View My Orders',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget checkoutBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF146BFF),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 166,
              height: 52,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF146BFF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF8CA5BA),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          const PlaceOrderHeader(),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                BuyerDetailsCard(
                  nameController: buyerNameController,
                  phoneController: buyerPhoneController,
                  addressController: buyerAddressController,
                  isLoading: isLoadingBuyer,
                  errorMessage: buyerLoadError,
                ),
                ProductOrderCard(
                  supplier: widget.supplier,
                  product: widget.product,
                  quantity: quantity,
                  onDecrease: decreaseQuantity,
                  onIncrease: increaseQuantity,
                ),
                PaymentDetailsCard(
                  product: widget.product,
                  quantity: quantity,
                  totalAmount: totalAmount,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: checkoutBottomBar(),
    );
  }
}

class OrderPlacedRow extends StatelessWidget {
  const OrderPlacedRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF102C44),
              fontSize: bold ? 16 : 12,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
