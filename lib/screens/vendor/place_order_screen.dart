import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/map/caraga_location_picker_screen.dart';
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
  final ScrollController checkoutScrollController = ScrollController();

  int quantity = 1;
  bool isSubmitting = false;
  bool isLoadingBuyer = true;
  bool isEditingBuyer = false;
  bool isSavingBuyer = false;
  String buyerLoadError = '';
  String buyerProvince = '';
  String buyerLocality = '';
  double? deliveryLatitude;
  double? deliveryLongitude;
  String savedBuyerName = '';
  String savedBuyerPhone = '';
  String savedBuyerAddress = '';
  String supplierStoreImageUrl = '';

  double get totalAmount => widget.product.price * quantity;
  bool get hasDetailedDeliveryAddress =>
      !isGeneralLocationOnly(buyerAddressController.text);
  bool get hasSavedDeliveryPin =>
      deliveryLatitude != null && deliveryLongitude != null;

  String normalizeAddress(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  bool isGeneralLocationOnly(String address) {
    final normalizedAddress = normalizeAddress(address);

    if (normalizedAddress.isEmpty) {
      return true;
    }

    final province = buyerProvince.trim();
    final locality = buyerLocality.trim();
    final generalLocations = <String>{
      'Caraga Region',
      province,
      locality,
      if (locality.isNotEmpty && province.isNotEmpty)
        '$locality, $province',
      if (locality.isNotEmpty && province.isNotEmpty)
        '$locality, $province, Caraga Region',
    };

    return generalLocations
        .where((value) => value.trim().isNotEmpty)
        .map(normalizeAddress)
        .contains(normalizedAddress);
  }

  String get fullDeliveryAddress {
    final detailedAddress = buyerAddressController.text.trim();
    final addressParts = <String>[];

    if (detailedAddress.isNotEmpty) {
      addressParts.add(detailedAddress);
    }

    final normalizedDetails = normalizeAddress(detailedAddress);
    final locality = buyerLocality.trim();
    final province = buyerProvince.trim();

    if (locality.isNotEmpty &&
        !normalizedDetails.contains(normalizeAddress(locality))) {
      addressParts.add(locality);
    }

    if (province.isNotEmpty &&
        !normalizedDetails.contains(normalizeAddress(province))) {
      addressParts.add(province);
    }

    if (!normalizedDetails.contains(normalizeAddress('Caraga Region'))) {
      addressParts.add('Caraga Region');
    }

    return addressParts.join(', ');
  }

  @override
  void initState() {
    super.initState();
    supplierStoreImageUrl = widget.supplier.profileImageUrl.trim();
    loadBuyerDetails();
    loadSupplierStoreImage();
  }

  @override
  void dispose() {
    buyerNameController.dispose();
    buyerPhoneController.dispose();
    buyerAddressController.dispose();
    checkoutScrollController.dispose();
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

  double? coordinateValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> loadSupplierStoreImage() async {
    final supplierId = widget.supplierId.trim();

    if (supplierId.isEmpty) {
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('supplierProfiles')
          .doc(supplierId)
          .get();
      final data = snapshot.data() ?? <String, dynamic>{};
      var imageUrl = firstNonEmpty(
        data,
        const [
          'storePhotoUrl',
          'profileImageUrl',
          'businessPhotoUrl',
          'photoUrl',
          'imageUrl',
        ],
        fallback: supplierStoreImageUrl,
      );

      if (imageUrl.isEmpty) {
        final application = data['supplierApplication'];

        if (application is Map) {
          imageUrl = firstNonEmpty(
            Map<String, dynamic>.from(application),
            const [
              'storePhotoUrl',
              'profileImageUrl',
              'businessPhotoUrl',
              'photoUrl',
              'imageUrl',
            ],
          );
        }
      }

      if (!mounted || imageUrl.isEmpty) {
        return;
      }

      setState(() {
        supplierStoreImageUrl = imageUrl;
      });
    } catch (_) {
      // Keep the image already carried by the selected supplier card.
    }
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

      buyerProvince = firstNonEmpty(
        userData,
        const ['province'],
      );

      buyerLocality = firstNonEmpty(
        userData,
        const [
          'cityMunicipality',
          'city',
          'municipality',
          'locality',
        ],
      );

      final storedDeliveryAddress = firstNonEmpty(
        userData,
        const ['deliveryAddress'],
      );
      buyerAddressController.text =
          isGeneralLocationOnly(storedDeliveryAddress)
              ? ''
              : storedDeliveryAddress;

      deliveryLatitude = coordinateValue(
        userData['deliveryLatitude'],
      );
      deliveryLongitude = coordinateValue(
        userData['deliveryLongitude'],
      );

      savedBuyerName = buyerNameController.text.trim();
      savedBuyerPhone = buyerPhoneController.text.trim();
      savedBuyerAddress = buyerAddressController.text.trim();

      if (!mounted) return;
      setState(() {
        isLoadingBuyer = false;
        isEditingBuyer = false;
        buyerLoadError = '';
      });
    } catch (error) {
      buyerNameController.text =
          user.displayName ?? user.email ?? 'Vendor';
      buyerAddressController.clear();
      savedBuyerName = buyerNameController.text.trim();
      savedBuyerPhone = buyerPhoneController.text.trim();
      savedBuyerAddress = buyerAddressController.text.trim();

      if (!mounted) return;
      setState(() {
        isLoadingBuyer = false;
        isEditingBuyer = false;
        buyerLoadError =
            'Some profile details could not be loaded. You can enter them below.';
      });
    }
  }

  void beginEditingBuyerDetails() {
    if (isLoadingBuyer || isSavingBuyer) {
      return;
    }

    setState(() {
      isEditingBuyer = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !checkoutScrollController.hasClients) {
        return;
      }

      checkoutScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void cancelEditingBuyerDetails() {
    if (isSavingBuyer) {
      return;
    }

    buyerNameController.text = savedBuyerName;
    buyerPhoneController.text = savedBuyerPhone;
    buyerAddressController.text = savedBuyerAddress;

    setState(() {
      isEditingBuyer = false;
      buyerLoadError = '';
    });
  }

  Future<bool> saveVendorDeliveryDetails({
    bool closeEditor = true,
    bool showFeedback = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || isSavingBuyer) {
      return false;
    }

    final name = buyerNameController.text.trim();
    final phone = buyerPhoneController.text.trim();
    final address = buyerAddressController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      showMessage(
        'Complete your delivery name and phone number.',
        isError: true,
      );
      return false;
    }

    if (isGeneralLocationOnly(address)) {
      showMessage(
        'Enter a detailed delivery address such as your barangay, street, block, house, or landmark.',
        isError: true,
      );
      return false;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isSavingBuyer = true;
    });

    try {
      final updates = <String, dynamic>{
        'name': name,
        'phone': phone,
        'deliveryAddress': address,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (deliveryLatitude != null && deliveryLongitude != null) {
        updates.addAll({
          'deliveryLatitude': deliveryLatitude,
          'deliveryLongitude': deliveryLongitude,
          'deliveryReferenceType': 'map_pin',
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
            updates,
            SetOptions(merge: true),
          );

      if (!mounted) {
        return false;
      }

      setState(() {
        savedBuyerName = name;
        savedBuyerPhone = phone;
        savedBuyerAddress = address;
        buyerLoadError = '';
        isEditingBuyer = closeEditor ? false : isEditingBuyer;
      });

      if (showFeedback) {
        showMessage('Delivery information updated.');
      }

      return true;
    } catch (_) {
      showMessage(
        'Unable to update your delivery information.',
        isError: true,
      );
      return false;
    } finally {
      if (mounted) {
        setState(() {
          isSavingBuyer = false;
        });
      }
    }
  }

  Future<void> chooseDeliveryReferencePin() async {
    if (isSavingBuyer || isSubmitting) {
      return;
    }

    final address = buyerAddressController.text.trim();

    if (isGeneralLocationOnly(address)) {
      showMessage(
        'Enter your barangay, street, block, house, or landmark before setting the map location.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final result =
        await Navigator.of(context)
            .push<CaragaLocationResult>(
      MaterialPageRoute(
        builder: (_) =>
            CaragaLocationPickerScreen(
          title: 'Delivery Location',
          subtitle: fullDeliveryAddress,
          province:
              buyerProvince.trim().isEmpty
                  ? null
                  : buyerProvince,
          locality:
              buyerLocality.trim().isEmpty
                  ? null
                  : buyerLocality,
          initialLatitude: deliveryLatitude,
          initialLongitude: deliveryLongitude,
          instructionText:
              'Tap the map at the COD delivery reference point. '
              'This pin is only a location reference and does not calculate routes.',
          markerTitle:
              'COD delivery reference point',
          confirmButtonLabel:
              'Confirm Delivery Location',
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      deliveryLatitude = result.latitude;
      deliveryLongitude = result.longitude;
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(
              {
                'deliveryLatitude': result.latitude,
                'deliveryLongitude': result.longitude,
                'deliveryReferenceType': 'map_pin',
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
      } catch (_) {
        if (!mounted) {
          return;
        }

        showMessage(
          'The pin is selected for this order but could not be saved to your account.',
          isError: true,
        );
        return;
      }
    }

    showMessage(
      'Delivery location saved for future orders.',
    );
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

  Future<void> enterSpecificQuantity() async {
    final maximumQuantity = widget.product.availableQuantity.floor();
    var draftQuantity = quantity.toString();

    final enteredValue = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        void closeDialog([String? value]) {
          FocusScope.of(dialogContext).unfocus();
          Navigator.of(dialogContext).pop(value);
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Enter Quantity',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter a whole-number amount from 1 to $maximumQuantity '
                '${widget.product.quantityUnit}.',
                style: const TextStyle(
                  color: Color(0xFF62798B),
                  fontSize: 11.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: draftQuantity,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  draftQuantity = value;
                },
                onFieldSubmitted: (value) {
                  closeDialog(value);
                },
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: widget.product.quantityUnit,
                  prefixIcon: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF0875D1),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5FAFD),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFF0875D1),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                closeDialog();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                closeDialog(draftQuantity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0875D1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || enteredValue == null) {
      return;
    }

    final enteredQuantity = int.tryParse(enteredValue.trim());

    if (enteredQuantity == null || enteredQuantity < 1) {
      showMessage(
        'Enter a quantity of at least 1.',
        isError: true,
      );
      return;
    }

    if (enteredQuantity > maximumQuantity) {
      showMessage(
        'Only $maximumQuantity ${widget.product.quantityUnit} are available.',
        isError: true,
      );
      return;
    }

    setState(() {
      quantity = enteredQuantity;
    });
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

    if (isGeneralLocationOnly(buyerAddressController.text)) {
      showMessage(
        'Enter a detailed delivery address such as your barangay, street, block, house, or landmark.',
        isError: true,
      );
      return false;
    }

    if (deliveryLatitude == null ||
        deliveryLongitude == null) {
      showMessage(
        'Set your delivery location on the map.',
        isError: true,
      );
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
                      const _ConfirmationRow(
                        label: 'Delivery Pin',
                        value: 'Selected',
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

    final profileSaved = await saveVendorDeliveryDetails(
      closeEditor: true,
      showFeedback: false,
    );

    if (!mounted || !profileSaved) {
      return;
    }

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
        buyerAddress: fullDeliveryAddress,
        deliveryLatitude: deliveryLatitude!,
        deliveryLongitude: deliveryLongitude!,
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

  Future<void> handleCheckoutAction() async {
    if (isEditingBuyer) {
      await saveVendorDeliveryDetails();
      return;
    }

    if (!hasDetailedDeliveryAddress) {
      beginEditingBuyerDetails();
      showMessage(
        'Add and save your detailed delivery address before placing the order.',
        isError: true,
      );
      return;
    }

    if (!hasSavedDeliveryPin) {
      await chooseDeliveryReferencePin();
      return;
    }

    await confirmOrder();
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
    final actionLabel = isEditingBuyer
        ? 'Save Delivery Details'
        : !hasDetailedDeliveryAddress
            ? 'Add Delivery Address'
            : !hasSavedDeliveryPin
                ? 'Set Delivery Pin'
                : 'Place Order';
    final actionIcon = isEditingBuyer
        ? Icons.save_outlined
        : !hasDetailedDeliveryAddress
            ? Icons.add_location_alt_outlined
            : !hasSavedDeliveryPin
                ? Icons.location_on_outlined
                : Icons.arrow_forward_rounded;

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
                onPressed: isSubmitting || isLoadingBuyer || isSavingBuyer
                    ? null
                    : handleCheckoutAction,
                icon: isSubmitting
                    ? const SizedBox.shrink()
                    : Icon(
                        actionIcon,
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
                    : Text(
                        actionLabel,
                        style: const TextStyle(
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
              controller: checkoutScrollController,
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
                  deliveryLatitude: deliveryLatitude,
                  deliveryLongitude: deliveryLongitude,
                  province: buyerProvince,
                  locality: buyerLocality,
                  displayAddress: fullDeliveryAddress,
                  hasDetailedAddress: hasDetailedDeliveryAddress,
                  isEditing: isEditingBuyer,
                  isSaving: isSavingBuyer,
                  onEdit: beginEditingBuyerDetails,
                  onCancel: cancelEditingBuyerDetails,
                  onSave: () {
                    saveVendorDeliveryDetails();
                  },
                  onChooseDeliveryPin:
                      chooseDeliveryReferencePin,
                ),
                ProductOrderCard(
                  supplier: widget.supplier,
                  supplierImageUrl: supplierStoreImageUrl,
                  product: widget.product,
                  quantity: quantity,
                  onDecrease: decreaseQuantity,
                  onIncrease: increaseQuantity,
                  onEnterQuantity: enterSpecificQuantity,
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
