import 'package:flutter/material.dart';

class ManageProductsEmptyCard extends StatelessWidget {
  const ManageProductsEmptyCard({
    super.key,
    required this.onPostStock,
  });

  final VoidCallback onPostStock;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F00152A),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF7FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF146BFF),
              size: 32,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'No products to manage yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Post your first fish stock to create a marketplace listing and automatic stock alert.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 10.8,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton.icon(
              onPressed: onPostStock,
              icon: const Icon(
                Icons.add_box_outlined,
                size: 19,
              ),
              label: const Text(
                'Post Fish Stock',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF146BFF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ManageProductsFilteredEmptyCard extends StatelessWidget {
  const ManageProductsFilteredEmptyCard({
    super.key,
    required this.onClear,
  });

  final VoidCallback onClear;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Color(0xFF8BA0B1),
            size: 38,
          ),
          const SizedBox(height: 9),
          const Text(
            'No matching products',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try another search or clear the selected stock filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(
              Icons.filter_alt_off_outlined,
              size: 18,
            ),
            label: const Text(
              'Clear Search and Filters',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ManageProductsLoadingCard extends StatelessWidget {
  const ManageProductsLoadingCard({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Color(0xFF146BFF),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading your product listings...',
              style: TextStyle(
                color: Color(0xFF52677A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ManageProductsErrorCard extends StatelessWidget {
  const ManageProductsErrorCard({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFF2C7C5),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFFD94A45),
            size: 39,
          ),
          const SizedBox(height: 9),
          const Text(
            'Unable to load products',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Unable to load the supplier inventory right now. Refresh and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: const Text(
              'Try Again',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
