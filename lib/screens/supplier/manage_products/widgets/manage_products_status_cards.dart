import 'package:flutter/material.dart';

class ManageProductsEmptyCard
    extends
        StatelessWidget {
  const ManageProductsEmptyCard({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Color(
              0xFF146BFF,
            ),
            size: 44,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'No products to manage yet',
            style: TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'Only fish stocks posted by this supplier account will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class ManageProductsLoadingCard
    extends
        StatelessWidget {
  const ManageProductsLoadingCard({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              'Loading your products from Firebase...',
              style: TextStyle(
                color: Color(
                  0xFF7B8FA3,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ManageProductsErrorCard
    extends
        StatelessWidget {
  const ManageProductsErrorCard({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
      ),
      child: Text(
        'Unable to load your Firebase products: $error',
        style: const TextStyle(
          color: Color(
            0xFFD32F2F,
          ),
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
