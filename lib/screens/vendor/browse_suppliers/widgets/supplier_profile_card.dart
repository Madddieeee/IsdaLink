import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/services/favorite_supplier_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

class SupplierProfileCard extends StatefulWidget {
  const SupplierProfileCard({
    super.key,
    required this.supplier,
    required this.supplierId,
    required this.imageUrl,
    required this.availableListingCount,
    required this.productNames,
    required this.onTap,
  });

  final Supplier supplier;
  final String supplierId;
  final String imageUrl;
  final int availableListingCount;
  final List<String> productNames;
  final VoidCallback onTap;

  @override
  State<SupplierProfileCard> createState() => _SupplierProfileCardState();
}

class _SupplierProfileCardState extends State<SupplierProfileCard> {
  final FavoriteSupplierService favoriteService = FavoriteSupplierService();
  bool favoriteBusy = false;

  bool get hasNetworkImage {
    final value = widget.imageUrl.trim();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  bool get canFavorite {
    final currentUserId = favoriteService.currentUserId;
    final supplierId = widget.supplierId.trim();
    return currentUserId != null &&
        supplierId.isNotEmpty &&
        supplierId != currentUserId;
  }

  String get compactLocation {
    final raw = widget.supplier.location.trim();
    if (raw.isEmpty) return 'Caraga Region';

    final parts = raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .where((item) => item.toLowerCase() != 'caraga region')
        .toList();

    if (parts.isEmpty) return 'Caraga Region';
    if (parts.length == 1) return parts.first;
    return '${parts[parts.length - 2]}, ${parts.last}';
  }

  String get reviewText {
    if (widget.supplier.reviews <= 0 || widget.supplier.rating <= 0) {
      return 'No reviews yet';
    }
    return '${widget.supplier.rating.toStringAsFixed(1)} (${widget.supplier.reviews})';
  }

  Future<void> toggleFavorite(bool currentlyFavorite) async {
    if (favoriteBusy || !canFavorite) return;

    setState(() => favoriteBusy = true);
    try {
      await favoriteService.toggleFavorite(
        supplierId: widget.supplierId,
        currentlyFavorite: currentlyFavorite,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              currentlyFavorite
                  ? 'Supplier removed from Favorites.'
                  : 'Supplier added to Favorites.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessage.from(
                error,
                fallback: 'Unable to update Favorites right now.',
                allowBusinessMessage: true,
              ),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => favoriteBusy = false);
    }
  }

  Widget favoriteButton() {
    if (!canFavorite) return const SizedBox(width: 40, height: 40);

    return StreamBuilder<bool>(
      stream: favoriteService.isFavoriteStream(widget.supplierId),
      initialData: false,
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        return Material(
          color: const Color(0xFFF3F9FD),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: favoriteBusy ? null : () => toggleFavorite(isFavorite),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: favoriteBusy
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0875D1),
                      ),
                    )
                  : Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFE94D67)
                          : const Color(0xFF68869C),
                      size: 22,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget supplierImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 104,
        height: 104,
        color: const Color(0xFFEAF7FB),
        child: hasNetworkImage
            ? Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imageFallback(),
              )
            : _imageFallback(),
      ),
    );
  }

  Widget _imageFallback() {
    return const Center(
      child: Icon(
        Icons.storefront_rounded,
        color: Color(0xFF0875D1),
        size: 38,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleProducts = widget.productNames.take(3).toList();
    final remainingProducts = widget.productNames.length - visibleProducts.length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDCEAF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F063A5A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              supplierImage(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.supplier.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF082E50),
                                    fontSize: 14.2,
                                    height: 1.12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Tooltip(
                                  message: 'Verified supplier',
                                  child: Icon(
                                    Icons.verified_rounded,
                                    color: Color(0xFF18A56D),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        favoriteButton(),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF7D99AC),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            compactLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF607D92),
                              fontSize: 10.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.supplier.reviews > 0
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: widget.supplier.reviews > 0
                                  ? const Color(0xFFF4A300)
                                  : const Color(0xFF8FA7B7),
                              size: 16,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              reviewText,
                              style: const TextStyle(
                                color: Color(0xFF547186),
                                fontSize: 10.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 1,
                          height: 14,
                          color: const Color(0xFFD9E6ED),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF0875D1),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.availableListingCount} listings',
                              style: const TextStyle(
                                color: Color(0xFF0875D1),
                                fontSize: 10.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (visibleProducts.isNotEmpty)
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          ...visibleProducts.map(
                            (name) => _ProductChip(label: name),
                          ),
                          if (remainingProducts > 0)
                            _ProductChip(label: '+$remainingProducts'),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: widget.onTap,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF0875D1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Store',
                                style: TextStyle(
                                  fontSize: 10.8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
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
}

class _ProductChip extends StatelessWidget {
  const _ProductChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF0875D1),
          fontSize: 9.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
