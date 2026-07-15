import 'package:flutter/material.dart';

class MeHeader
    extends
        StatelessWidget {
  const MeHeader({
    super.key,
    required this.name,
    required this.supplierStatus,
    required this.onBack,
  });

  final String name;
  final String supplierStatus;
  final VoidCallback onBack;

  @override
  Widget build(
    BuildContext context,
  ) {
    final isSupplierApproved =
        supplierStatus ==
        'approved';
    final isPending =
        supplierStatus ==
        'pending';

    final accountLabel = isSupplierApproved
        ? 'Supplier Account • Caraga Region'
        : isPending
        ? 'Vendor Account • Supplier Application Pending'
        : 'Vendor Account • Caraga Region';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        54,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(
              0xFF102C44,
            ),
            Color(
              0xFF146BFF,
            ),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(
            32,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(
                      38,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              const Expanded(
                child: Text(
                  'Me',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 26,
          ),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                28,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(
                    0x22000000,
                  ),
                  blurRadius: 16,
                  offset: Offset(
                    0,
                    8,
                  ),
                ),
              ],
            ),
            child: Icon(
              isSupplierApproved
                  ? Icons.storefront
                  : Icons.person,
              color: const Color(
                0xFF146BFF,
              ),
              size: 46,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            accountLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFFDCE9F5,
              ),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
