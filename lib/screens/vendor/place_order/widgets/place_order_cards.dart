import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';

class CheckoutCard extends StatelessWidget {
  const CheckoutCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EDF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
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
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final bool isLoading;
  final String errorMessage;

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF7B8FA3),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF146BFF),
        size: 20,
      ),
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE1EAF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF146BFF),
          width: 1.4,
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
          const Row(
            children: [
              Icon(
                Icons.location_on,
                color: Color(0xFF146BFF),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Buyer Details',
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            )
          else ...[
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration(
                label: 'Buyer name',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: fieldDecoration(
                label: 'Contact number',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              minLines: 2,
              maxLines: 3,
              decoration: fieldDecoration(
                label: 'Delivery address',
                icon: Icons.home_outlined,
              ),
            ),
            if (errorMessage.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: const TextStyle(
                  color: Color(0xFFD97706),
                  fontSize: 10.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
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
    required this.product,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final Supplier supplier;
  final FishProduct product;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  bool get hasProductImage {
    final imageUrl = product.imageUrl.trim();
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  bool get canDecrease => quantity > 1;
  bool get canIncrease => quantity < product.availableQuantity;

  String formatNumber(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
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
    return Center(
      child: Text(
        product.emoji.trim().isEmpty ? '🐟' : product.emoji,
        style: const TextStyle(fontSize: 38),
      ),
    );
  }

  Widget quantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFEAF2FF)
              : const Color(0xFFF0F3F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? const Color(0xFFBFD3F8)
                : const Color(0xFFE2E7EA),
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? const Color(0xFF146BFF)
              : const Color(0xFFA6B2BC),
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
              const Icon(
                Icons.storefront_outlined,
                color: Color(0xFF146BFF),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  supplier.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1EAF0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: productImage(),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '₱${product.price.toStringAsFixed(0)} ${product.priceUnit}',
                      style: const TextStyle(
                        color: Color(0xFF146BFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Available: ${formatNumber(product.availableQuantity)} ${product.quantityUnit}',
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 26),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quantity',
                  style: TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              quantityButton(
                icon: Icons.remove,
                onTap: onDecrease,
                enabled: canDecrease,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 68),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '$quantity ${product.quantityUnit}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              quantityButton(
                icon: Icons.add,
                onTap: onIncrease,
                enabled: canIncrease,
              ),
            ],
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

  Widget detailRow({
    required String label,
    required String value,
    bool total = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: total
                    ? const Color(0xFF102C44)
                    : const Color(0xFF52677A),
                fontSize: total ? 14 : 12.5,
                fontWeight: total ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              color: total
                  ? const Color(0xFF146BFF)
                  : const Color(0xFF102C44),
              fontSize: total ? 18 : 12.5,
              fontWeight: total ? FontWeight.w900 : FontWeight.w800,
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
          const Text(
            'Payment Details',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          detailRow(
            label: 'Unit price',
            value: '₱${product.price.toStringAsFixed(0)} ${product.priceUnit}',
          ),
          detailRow(
            label: 'Quantity',
            value: '$quantity ${product.quantityUnit}',
          ),
          detailRow(
            label: 'Merchandise subtotal',
            value: '₱${totalAmount.toStringAsFixed(0)}',
          ),
          detailRow(
            label: 'Payment method',
            value: 'Cash on Delivery',
          ),
          const Divider(height: 22),
          detailRow(
            label: 'Total Payment',
            value: '₱${totalAmount.toStringAsFixed(0)}',
            total: true,
          ),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF146BFF),
                  size: 19,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pay the supplier upon delivery. The selected quantity is reserved after placing the order.',
                    style: TextStyle(
                      color: Color(0xFF52677A),
                      fontSize: 10.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
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
