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

  String formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool validateBuyerDetails() {
    if (buyerNameController.text.trim().isEmpty) {
      showMessage('Please enter the buyer name.', isError: true);
      return false;
    }

    if (buyerPhoneController.text.trim().isEmpty) {
      showMessage(
        'Please enter the buyer contact number.',
        isError: true,
      );
      return false;
    }

    if (buyerAddressController.text.trim().isEmpty) {
      showMessage('Please enter the delivery address.', isError: true);
      return false;
    }

    return true;
  }

  Future<bool> showOrderConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(19, 19, 19, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(27),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0875D1),
                        Color(0xFF12B6D6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Place this COD order?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review the order before confirming.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F9FC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE0EBF2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _ConfirmationRow(
                        label: 'Product',
                        value: widget.product.name,
                      ),
                      _ConfirmationRow(
                        label: 'Quantity',
                        value: '$quantity ${widget.product.quantityUnit}',
                      ),
                      const _ConfirmationRow(
                        label: 'Payment',
                        value: 'Cash on Delivery',
                      ),
                      const Divider(
                        height: 20,
                        color: Color(0xFFDDE8EF),
                      ),
                      _ConfirmationRow(
                        label: 'Total',
                        value: '₱${formatNumber(totalAmount)}',
                        strong: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8FD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF0875D1),
                        size: 17,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The selected quantity will be deducted from '
                          'available stock after the order is placed.',
                          style: TextStyle(
                            color: Color(0xFF52677A),
                            fontSize: 9.6,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 15,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF52677A),
                          side: const BorderSide(
                            color: Color(0xFFD6E2EA),
                          ),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        label: const Text(
                          'Edit Order',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0875D1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 11,
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
        );
      },
    );

    return result == true;
  }

  String readableOrderError(
    Object error,
  ) {
    final text = error.toString().trim();

    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }

    return text;
  }

  Future<void> confirmOrder() async {
    if (isSubmitting || isLoadingBuyer) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Please log in first before placing an order.',
        isError: true,
      );
      return;
    }

    final ownerUid = widget.supplierId.trim();

    if (ownerUid.isNotEmpty && ownerUid == user.uid) {
      showMessage(
        'You cannot place an order from your own supplier store.',
        isError: true,
      );
      return;
    }

    if (!validateBuyerDetails()) return;

    FocusScope.of(context).unfocus();

    final confirmed = await showOrderConfirmationDialog();
    if (!mounted || !confirmed) return;

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

      final message = readableOrderError(error);

      showMessage(
        message,
        isError: true,
      );
    }
  }

  void showOrderPlacedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 23),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 22,
                  offset: Offset(0, 11),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E9A62),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 37,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Order Placed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${widget.product.name} was sent to '
                  '${widget.supplier.name} for confirmation.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 11.7,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F9FC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE0EBF2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _ConfirmationRow(
                        label: 'Quantity',
                        value: '$quantity ${widget.product.quantityUnit}',
                      ),
                      const _ConfirmationRow(
                        label: 'Payment',
                        value: 'Cash on Delivery',
                      ),
                      const Divider(
                        height: 20,
                        color: Color(0xFFDDE8EF),
                      ),
                      _ConfirmationRow(
                        label: 'Total',
                        value: '₱${formatNumber(totalAmount)}',
                        strong: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0875D1),
                          side: const BorderSide(
                            color: Color(0xFF0875D1),
                          ),
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyOrdersScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0875D1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'My Orders',
                          style: TextStyle(
                            fontSize: 11,
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
        );
      },
    );
  }

  Widget checkoutBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 11, 18, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1C00152A),
            blurRadius: 18,
            offset: Offset(0, -6),
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
                      fontSize: 9.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${formatNumber(totalAmount)}',
                    style: const TextStyle(
                      color: Color(0xFF0875D1),
                      fontSize: 21,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Cash on Delivery',
                    style: TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 8.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 190,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isSubmitting || isLoadingBuyer
                    ? null
                    : confirmOrder,
                icon: isSubmitting
                    ? const SizedBox.shrink()
                    : const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                label: isSubmitting
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
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0875D1),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF8CA5BA),
                  elevation: 2,
                  shadowColor: const Color(0x550875D1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
      backgroundColor: const Color(0xFFF4F8FB),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          const PlaceOrderHeader(),
          Expanded(
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
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

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong
                    ? const Color(0xFF102C44)
                    : const Color(0xFF52677A),
                fontSize: strong ? 11.7 : 10.7,
                fontWeight: strong
                    ? FontWeight.w900
                    : FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: strong
                    ? const Color(0xFF0875D1)
                    : const Color(0xFF102C44),
                fontSize: strong ? 15.5 : 10.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
