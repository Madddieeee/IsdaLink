import 'package:flutter/material.dart';

class BrowseSuppliersHeader extends StatelessWidget {
  const BrowseSuppliersHeader({
    super.key,
    required this.approvedCount,
    required this.availableStockCount,
    required this.searchController,
    required this.onSearchChanged,
    required this.onBack,
  });

  final int approvedCount;
  final int availableStockCount;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBack;

  Widget _metric({
    required String value,
    required String label,
    required IconData icon,
    required Color accent,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(24),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withAlpha(28)),
          ),
          child: Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: accent.withAlpha(32),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFD8ECF4),
                        fontSize: 8.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.paddingOf(context).top + 12,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06355F),
            Color(0xFF0875D1),
            Color(0xFF12B6D6),
          ],
          stops: [0.0, 0.58, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -42,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 48,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withAlpha(28),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onBack,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Browse Suppliers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Verified fish suppliers across Caraga',
                          style: TextStyle(
                            color: Color(0xFFD9F0F6),
                            fontSize: 9.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: Colors.white.withAlpha(25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded, color: Color(0xFFE6FAFC), size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Caraga',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0xFFE0EDF4)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18002A47),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF8FC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF087AC0),
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        maxLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                        cursorColor: const Color(0xFF087AC0),
                        cursorHeight: 18,
                        cursorWidth: 1.6,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search supplier, fish, or location',
                          hintStyle: const TextStyle(
                            color: Color(0xFF8296A6),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          suffixIcon: searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    searchController.clear();
                                    onSearchChanged('');
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Color(0xFF7890A1),
                                  ),
                                ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 13.2,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  _metric(
                    value: '$approvedCount',
                    label: 'Suppliers',
                    icon: Icons.storefront_rounded,
                    accent: const Color(0xFFA8F0DC),
                  ),
                  _metric(
                    value: '$availableStockCount',
                    label: 'Fish stocks',
                    icon: Icons.inventory_2_outlined,
                    accent: const Color(0xFFAEEBFF),
                  ),
                  _metric(
                    value: 'COD',
                    label: 'Payment',
                    icon: Icons.payments_outlined,
                    accent: const Color(0xFFFFDEA0),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
