import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/map/vendor_delivery_map_card.dart';

class CheckoutCard extends StatelessWidget {
  const CheckoutCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 13),
    this.padding = const EdgeInsets.all(15),
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE0EBF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E00152A),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CheckoutSectionTitle extends StatelessWidget {
  const CheckoutSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    this.leading,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: leading == null
              ? Icon(
                  icon,
                  color: const Color(0xFF0875D1),
                  size: 18,
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: leading,
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class BuyerDetailsCard extends StatelessWidget {
  const BuyerDetailsCard({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.isLoading,
    required this.errorMessage,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.province,
    required this.locality,
    required this.displayAddress,
    required this.hasDetailedAddress,
    required this.isEditing,
    required this.isSaving,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
    required this.onChooseDeliveryPin,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final bool isLoading;
  final String errorMessage;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String province;
  final String locality;
  final String displayAddress;
  final bool hasDetailedAddress;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onChooseDeliveryPin;

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: const TextStyle(
        color: Color(0xFF7B8FA3),
        fontSize: 10.3,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8FD),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF0875D1),
          size: 17,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE0EBF2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF12A9D1),
          width: 1.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Delivery Information',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isEditing)
                TextButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Color(0xFF0875D1),
                ),
              ),
            )
          else ...[
            if (isEditing) ...[
              TextField(
                controller: nameController,
                enabled: !isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: fieldDecoration(
                  label: 'Recipient name',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: phoneController,
                enabled: !isSaving,
                keyboardType: TextInputType.phone,
                decoration: fieldDecoration(
                  label: 'Contact number',
                  icon: Icons.phone_outlined,
                ),
              ),
              const SizedBox(height: 9),
              TextField(
                controller: addressController,
                enabled: !isSaving,
                keyboardType: TextInputType.streetAddress,
                textCapitalization: TextCapitalization.words,
                minLines: 1,
                maxLines: 3,
                decoration: fieldDecoration(
                  label: 'Detailed delivery address *',
                  icon: Icons.home_work_outlined,
                  hintText: 'Block, street, barangay, house, or landmark',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 43,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                          size: 17,
                        ),
                  label: Text(
                    isSaving ? 'Saving...' : 'Save Delivery Information',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0875D1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF8CA5BA),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF0875D1),
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: nameController.text.trim(),
                                      style: const TextStyle(
                                        color: Color(0xFF102C44),
                                        fontSize: 13.2,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    TextSpan(
                                      text: phoneController.text.trim().isEmpty
                                          ? ''
                                          : '  ${phoneController.text.trim()}',
                                      style: const TextStyle(
                                        color: Color(0xFF7B8FA3),
                                        fontSize: 11.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                hasDetailedAddress
                                    ? displayAddress
                                    : 'Add a barangay, street, block, house, or landmark before placing an order.',
                                style: TextStyle(
                                  color: hasDetailedAddress
                                      ? const Color(0xFF52677A)
                                      : const Color(0xFFC46A00),
                                  fontSize: 11.2,
                                  height: 1.42,
                                  fontWeight: hasDetailedAddress
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF9AAEBD),
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasDetailedAddress) ...[
                const SizedBox(height: 12),
                VendorDeliveryMapCard(
                  latitude: deliveryLatitude,
                  longitude: deliveryLongitude,
                  province: province,
                  locality: locality,
                  onTap: onChooseDeliveryPin,
                ),
              ],
            ],
            if (errorMessage.trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E8),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFFFFE0B8),
                  ),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Color(0xFFB26400),
                    fontSize: 9.8,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class ProductOrderCard extends StatelessWidget {
  const ProductOrderCard({
    super.key,
    required this.supplier,
    required this.supplierImageUrl,
    required this.product,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onEnterQuantity,
  });

  final Supplier supplier;
  final String supplierImageUrl;
  final FishProduct product;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onEnterQuantity;

  bool get hasProductImage {
    final imageUrl = product.imageUrl.trim();
    return imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');
  }

  bool get hasSupplierImage {
    final imageUrl = supplierImageUrl.trim();
    return imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');
  }

  Widget supplierImage() {
    if (!hasSupplierImage) {
      return const Icon(
        Icons.storefront_outlined,
        color: Color(0xFF0875D1),
        size: 18,
      );
    }

    return Image.network(
      supplierImageUrl,
      width: 34,
      height: 34,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(
        Icons.storefront_outlined,
        color: Color(0xFF0875D1),
        size: 18,
      ),
    );
  }

  bool get canDecrease => quantity > 1;
  bool get canIncrease => quantity < product.availableQuantity;

  String formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String get cleanPriceUnit {
    final value = product.priceUnit.trim();
    if (value.isEmpty) {
      return product.quantityUnit;
    }
    if (value.toLowerCase().startsWith('per ')) {
      return value.substring(4);
    }
    return value;
  }

  Widget productImage() {
    if (hasProductImage) {
      return Image.network(
        product.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => productEmoji(),
      );
    }
    return productEmoji();
  }

  Widget productEmoji() {
    return Container(
      color: const Color(0xFFEAF7FB),
      alignment: Alignment.center,
      child: Text(
        product.emoji.trim().isEmpty ? '🐟' : product.emoji,
        style: const TextStyle(fontSize: 36),
      ),
    );
  }

  Widget quantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return Material(
      color: enabled
          ? const Color(0xFFE8F8FD)
          : const Color(0xFFF0F3F5),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFCBEAF5)
                  : const Color(0xFFE2E7EA),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? const Color(0xFF0875D1)
                : const Color(0xFFA6B2BC),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckoutSectionTitle(
            icon: Icons.storefront_outlined,
            title: supplier.name,
            leading: supplierImage(),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8FD),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'Order item',
                style: TextStyle(
                  color: Color(0xFF0875D1),
                  fontSize: 8.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE0EBF2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: productImage(),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '₱${formatNumber(product.price)} / $cleanPriceUnit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0875D1),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF19A66A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${formatNumber(product.availableQuantity)} '
                            '${product.quantityUnit} available',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF62798B),
                              fontSize: 9.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 9, 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FAFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE0EBF2),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 11.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Choose the amount to reserve.',
                        style: TextStyle(
                          color: Color(0xFF7B8FA3),
                          fontSize: 8.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                quantityButton(
                  icon: Icons.remove_rounded,
                  onTap: onDecrease,
                  enabled: canDecrease,
                ),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onEnterQuantity,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 78,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFDCE8EF),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              '$quantity ${product.quantityUnit}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 11.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF0875D1),
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                quantityButton(
                  icon: Icons.add_rounded,
                  onTap: onIncrease,
                  enabled: canIncrease,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentDetailsCard extends StatelessWidget {
  const PaymentDetailsCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.totalAmount,
  });

  final FishProduct product;
  final int quantity;
  final double totalAmount;

  String formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String get cleanPriceUnit {
    final value = product.priceUnit.trim();
    if (value.isEmpty) {
      return product.quantityUnit;
    }
    if (value.toLowerCase().startsWith('per ')) {
      return value.substring(4);
    }
    return value;
  }

  Widget summaryRow({
    required String label,
    required String value,
    bool strong = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong
                    ? const Color(0xFF102C44)
                    : const Color(0xFF62798B),
                fontSize: strong ? 12 : 10.5,
                fontWeight: strong
                    ? FontWeight.w900
                    : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: strong
                  ? const Color(0xFF0875D1)
                  : const Color(0xFF102C44),
              fontSize: strong ? 16 : 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CheckoutSectionTitle(
            icon: Icons.receipt_long_outlined,
            title: 'Payment Summary',
          ),
          const SizedBox(height: 10),
          summaryRow(
            label: 'Unit price',
            value: '₱${formatNumber(product.price)} / $cleanPriceUnit',
          ),
          summaryRow(
            label: 'Quantity',
            value: '$quantity ${product.quantityUnit}',
          ),
          summaryRow(
            label: 'Merchandise subtotal',
            value: '₱${formatNumber(totalAmount)}',
          ),
          summaryRow(
            label: 'Payment method',
            value: 'Cash on Delivery',
          ),
          const Divider(
            height: 22,
            color: Color(0xFFE0EBF2),
          ),
          summaryRow(
            label: 'Total payment',
            value: '₱${formatNumber(totalAmount)}',
            strong: true,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8FD),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFD8ECF6),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF0875D1),
                  size: 18,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash on Delivery',
                        style: TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 10.7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Pay the supplier when the order is received. '
                        'Stock is reserved after order placement.',
                        style: TextStyle(
                          color: Color(0xFF62798B),
                          fontSize: 9.3,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
