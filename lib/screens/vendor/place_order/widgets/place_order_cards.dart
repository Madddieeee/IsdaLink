import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        border: Border.all(color: const Color(0xFFE0EBF2)),
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
        if (leading == null)
          Icon(icon, color: const Color(0xFF0875D1), size: 21)
        else
          SizedBox(width: 22, height: 22, child: leading),
        const SizedBox(width: 9),
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
    required this.canSave,
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
  final bool canSave;

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
        child: Icon(icon, color: const Color(0xFF0875D1), size: 17),
      ),
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE0EBF2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF12A9D1), width: 1.3),
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
                textInputAction: TextInputAction.next,
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
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  LengthLimitingTextInputFormatter(16),
                ],
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
                  onPressed: isSaving || !canSave ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 17),
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
                    disabledBackgroundColor: const Color(0xFFD7E4EC),
                    disabledForegroundColor: const Color(0xFF8CA1B0),
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
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: Color(0xFF0875D1),
                                  fontSize: 9.6,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF78A9C9),
                                size: 19,
                              ),
                            ],
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
                  height: 124,
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
                  border: Border.all(color: const Color(0xFFFFE0B8)),
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
    this.lockedQuantity = false,
  });

  final bool lockedQuantity;
  final Supplier supplier;
  final String supplierImageUrl;
  final FishProduct product;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onEnterQuantity;

  bool get hasProductImage {
    final imageUrl = product.imageUrl.trim();
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  bool get hasSupplierImage {
    final imageUrl = supplierImageUrl.trim();
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
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

  bool get canDecrease => !lockedQuantity && quantity > 1;
  bool get canIncrease =>
      !lockedQuantity && quantity < product.availableQuantity;

  String formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String formatPrice(double value) {
    final raw = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');
    final parts = raw.split('.');
    final whole = parts.first;
    final grouped = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      if (index > 0 && (whole.length - index) % 3 == 0) {
        grouped.write(',');
      }
      grouped.write(whole[index]);
    }
    return parts.length > 1
        ? '${grouped.toString()}.${parts[1]}'
        : grouped.toString();
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
      color: enabled ? const Color(0xFFE8F8FD) : const Color(0xFFF0F3F5),
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
            color: enabled ? const Color(0xFF0875D1) : const Color(0xFFA6B2BC),
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
          const Text(
            'ORDER FROM',
            style: TextStyle(
              color: Color(0xFF8AA0B0),
              fontSize: 8.2,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8EAF3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: supplierImage(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  supplier.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 14.4,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE0EBF2)),
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
                      '₱${formatPrice(product.price)} / $cleanPriceUnit',
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
              border: Border.all(color: const Color(0xFFE0EBF2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 11.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lockedQuantity
                            ? 'Agreed Tawad quantity.'
                            : quantity >= product.availableQuantity.floor()
                            ? 'Maximum available selected.'
                            : 'Choose the amount to reserve.',
                        style: TextStyle(
                          color: quantity >= product.availableQuantity.floor()
                              ? const Color(0xFF16845E)
                              : const Color(0xFF7B8FA3),
                          fontSize: 8.8,
                          fontWeight:
                              quantity >= product.availableQuantity.floor()
                              ? FontWeight.w800
                              : FontWeight.w600,
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
                    onTap: lockedQuantity ? null : onEnterQuantity,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 78,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDCE8EF)),
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
                          if (!lockedQuantity) ...[
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF0875D1),
                              size: 12,
                            ),
                          ],
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

class SupplierRequestCard extends StatelessWidget {
  const SupplierRequestCard({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CheckoutSectionTitle(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Message to Supplier',
            trailing: _OptionalPill(),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 30),
            child: Text(
              'Add any note or request for the supplier.',
              style: TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 9.4,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 11),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 3,
            maxLength: 180,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Write a message to the supplier...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A7B5),
                fontSize: 10.3,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF4F8FB),
              contentPadding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDCE8EF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFDCE8EF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF0875D1),
                  width: 1.4,
                ),
              ),
            ),
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 10.8,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionalPill extends StatelessWidget {
  const _OptionalPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F9),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'OPTIONAL',
        style: TextStyle(
          color: Color(0xFF73899A),
          fontSize: 7.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class TawadOfferCard extends StatelessWidget {
  const TawadOfferCard({
    super.key,
    required this.controller,
    required this.listedUnitPrice,
    required this.quantity,
    required this.quantityUnit,
  });

  final TextEditingController controller;
  final double listedUnitPrice;
  final int quantity;
  final String quantityUnit;

  String money(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final offer = double.tryParse(controller.text.trim().replaceAll(',', ''));
    final valid = offer != null && offer > 0 && offer < listedUnitPrice;

    return CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CheckoutSectionTitle(
            icon: Icons.handshake_outlined,
            title: 'Tawad Price Offer',
          ),
          const SizedBox(height: 8),
          Text(
            'Listed price: ₱${money(listedUnitPrice)} per $quantityUnit. '
            'Enter the exact unit price you want the supplier to accept.',
            style: const TextStyle(
              color: Color(0xFF62798B),
              fontSize: 9.7,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d{0,8}(\.\d{0,2})?'),
              ),
            ],
            decoration: InputDecoration(
              labelText: 'Your offer per $quantityUnit',
              prefixText: '₱ ',
              hintText: 'Example: 4500',
              filled: true,
              fillColor: const Color(0xFFF4F8FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            valid
                ? 'Proposed total: ₱${money(offer * quantity)}. The supplier must accept this exact price; declining closes the order.'
                : 'The offer must be greater than zero and lower than the listed price.',
            style: TextStyle(
              color: valid ? const Color(0xFF16845E) : const Color(0xFFB86500),
              fontSize: 9.4,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PriceOptionCard extends StatelessWidget {
  const PriceOptionCard({
    super.key,
    required this.requestTawad,
    required this.listedUnitPrice,
    required this.quantityUnit,
    required this.tawadAvailable,
    required this.checkingTawadAccess,
    this.tawadAccessError = '',
    required this.onChanged,
  });

  final bool requestTawad;
  final double listedUnitPrice;
  final String quantityUnit;
  final bool tawadAvailable;
  final bool checkingTawadAccess;
  final String tawadAccessError;
  final ValueChanged<bool> onChanged;

  String money(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  Widget option({
    required bool value,
    required IconData icon,
    required String title,
    required String subtitle,
    bool enabled = true,
  }) {
    final selected = requestTawad == value;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(11, 11, 10, 11),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFE8F6FC)
                  : !enabled
                  ? const Color(0xFFF1F4F6)
                  : const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? const Color(0xFF0875D1)
                    : !enabled
                    ? const Color(0xFFE2E8EC)
                    : const Color(0xFFDDE8EF),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  !enabled && value ? Icons.lock_outline_rounded : icon,
                  color: selected
                      ? const Color(0xFF0875D1)
                      : !enabled
                      ? const Color(0xFF9AABB7)
                      : const Color(0xFF718797),
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF075FAD)
                              : !enabled
                              ? const Color(0xFF718391)
                              : const Color(0xFF102C44),
                          fontSize: 10.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF718797),
                          fontSize: 8.2,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  !enabled && value
                      ? Icons.lock_rounded
                      : selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? const Color(0xFF0875D1)
                      : !enabled
                      ? const Color(0xFF9AABB7)
                      : const Color(0xFFB4C4CF),
                  size: 17,
                ),
              ],
            ),
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
          const CheckoutSectionTitle(
            icon: Icons.price_change_outlined,
            title: 'Price Option',
          ),
          const SizedBox(height: 6),
          const Text(
            'Use the listed price or ask the supplier to accept a lower price.',
            style: TextStyle(
              color: Color(0xFF62798B),
              fontSize: 9.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              option(
                value: false,
                icon: Icons.sell_outlined,
                title: 'Listed Price',
                subtitle: '₱${money(listedUnitPrice)} / $quantityUnit',
              ),
              const SizedBox(width: 8),
              option(
                value: true,
                icon: Icons.handshake_outlined,
                title: 'Request Tawad',
                subtitle: checkingTawadAccess
                    ? 'Checking access...'
                    : tawadAvailable
                    ? 'Offer a lower price'
                    : 'Unlock after first order',
                enabled: tawadAvailable && !checkingTawadAccess,
              ),
            ],
          ),
          if (!tawadAvailable || checkingTawadAccess) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (checkingTawadAccess)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.8),
                    )
                  else
                    Icon(
                      tawadAccessError.isEmpty
                          ? Icons.lock_outline_rounded
                          : Icons.refresh_rounded,
                      color: const Color(0xFF718391),
                      size: 15,
                    ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      checkingTawadAccess
                          ? 'Checking whether Tawad is unlocked...'
                          : tawadAccessError.isNotEmpty
                          ? 'Tap Request Tawad to check again.'
                          : 'Complete one delivered and paid order from this supplier to unlock Tawad.',
                      style: const TextStyle(
                        color: Color(0xFF62798B),
                        fontSize: 8.8,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    this.tawadPending = false,
    this.listedTotalAmount,
  });

  final FishProduct product;
  final int quantity;
  final double totalAmount;
  final bool tawadPending;
  final double? listedTotalAmount;

  String formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String formatPrice(double value) {
    final raw = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');
    final parts = raw.split('.');
    final whole = parts.first;
    final grouped = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      if (index > 0 && (whole.length - index) % 3 == 0) {
        grouped.write(',');
      }
      grouped.write(whole[index]);
    }
    return parts.length > 1
        ? '${grouped.toString()}.${parts[1]}'
        : grouped.toString();
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
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: strong ? const Color(0xFF0875D1) : const Color(0xFF102C44),
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
            label: tawadPending ? 'Proposed Tawad total' : 'Order subtotal',
            value: '₱${formatPrice(totalAmount)}',
          ),
          if (tawadPending && listedTotalAmount != null)
            summaryRow(
              label: 'Original listed total',
              value: '₱${formatPrice(listedTotalAmount!)}',
            ),
          summaryRow(label: 'Payment method', value: 'Cash on Delivery'),
          const Divider(height: 22, color: Color(0xFFE0EBF2)),
          summaryRow(
            label: tawadPending ? 'Total if accepted' : 'Total payment',
            value: '₱${formatPrice(totalAmount)}',
            strong: true,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8FD),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFD8ECF6)),
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
                        'Your selected stock is reserved after placement.',
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
