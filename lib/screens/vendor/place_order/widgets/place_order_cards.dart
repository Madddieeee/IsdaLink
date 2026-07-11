import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';

class SectionCard
    extends
        StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      const Color(
                        0xFF146BFF,
                      ).withAlpha(
                        24,
                      ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(
                    0xFF146BFF,
                  ),
                  size: 21,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          child,
        ],
      ),
    );
  }
}

class QuantitySelectorCard
    extends
        StatelessWidget {
  const QuantitySelectorCard({
    super.key,
    required this.quantity,
    required this.product,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final FishProduct product;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  bool get canDecrease =>
      quantity >
      1;
  bool get canIncrease =>
      quantity <
      product.availableQuantity;

  Widget quantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled
          ? onTap
          : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(
                  0xFF146BFF,
                )
              : const Color(
                  0xFFE1E9F0,
                ),
          borderRadius: BorderRadius.circular(
            15,
          ),
        ),
        child: Icon(
          icon,
          color: enabled
              ? Colors.white
              : const Color(
                  0xFF7B8FA3,
                ),
          size: 22,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SectionCard(
      title: 'Order Quantity',
      icon: Icons.add_shopping_cart,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              quantityButton(
                icon: Icons.remove,
                onTap: onDecrease,
                enabled: canDecrease,
              ),
              Container(
                width: 120,
                margin: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFEAF7FB,
                  ),
                  borderRadius: BorderRadius.circular(
                    18,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      product.quantityUnit,
                      style: const TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              quantityButton(
                icon: Icons.add,
                onTap: onIncrease,
                enabled: canIncrease,
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            'Available stock: ${product.availableQuantity.toStringAsFixed(0)} ${product.quantityUnit}',
            style: const TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodCard
    extends
        StatelessWidget {
  const PaymentMethodCard({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SectionCard(
      title: 'Payment Method',
      icon: Icons.payments,
      child: Container(
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFFEAF7FB,
          ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color:
                const Color(
                  0xFF146BFF,
                ).withAlpha(
                  50,
                ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF146BFF,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: const Icon(
                Icons.local_shipping,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cash on Delivery',
                    style: TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(
                    height: 3,
                  ),
                  Text(
                    'Pay the supplier when the order is received.',
                    style: TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: Color(
                0xFF2E7D32,
              ),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class OrderSummaryCard
    extends
        StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.supplier,
    required this.product,
    required this.quantity,
    required this.totalAmount,
  });

  final Supplier supplier;
  final FishProduct product;
  final int quantity;
  final double totalAmount;

  Widget detailRow({
    required String label,
    required String value,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(
                  0xFF7B8FA3,
                ),
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(
                  0xFF102C44,
                ),
                fontSize: bold
                    ? 18
                    : 13,
                fontWeight: bold
                    ? FontWeight.w900
                    : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return SectionCard(
      title: 'Order Summary',
      icon: Icons.receipt_long,
      child: Column(
        children: [
          detailRow(
            label: 'Product',
            value: product.name,
          ),
          detailRow(
            label: 'Supplier',
            value: supplier.name,
          ),
          detailRow(
            label: 'Quantity',
            value: '$quantity ${product.quantityUnit}',
          ),
          detailRow(
            label: 'Price',
            value: '₱${product.price.toStringAsFixed(0)} ${product.priceUnit}',
          ),
          detailRow(
            label: 'Payment',
            value: 'COD',
          ),
          const Divider(
            height: 24,
          ),
          detailRow(
            label: 'Total Amount',
            value: '₱${totalAmount.toStringAsFixed(0)}',
            bold: true,
          ),
        ],
      ),
    );
  }
}

class PlaceOrderInfoCard
    extends
        StatelessWidget {
  const PlaceOrderInfoCard({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFEAF7FB,
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color:
              const Color(
                0xFF146BFF,
              ).withAlpha(
                42,
              ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_done,
            color: Color(
              0xFF146BFF,
            ),
            size: 22,
          ),
          SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              'Firebase mode: This COD order will reserve stock immediately. Cancelled orders return the reserved stock.',
              style: TextStyle(
                color: Color(
                  0xFF52677A,
                ),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
