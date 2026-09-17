import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/services/favorite_supplier_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

class RecommendedSupplierCard extends StatefulWidget {
  const RecommendedSupplierCard({
    super.key,
    required this.supplier,
    required this.supplierId,
    required this.onTap,
    this.availableListingCount,
  });

  final Supplier supplier;
  final String supplierId;
  final VoidCallback onTap;
  final int? availableListingCount;

  @override
  State<RecommendedSupplierCard> createState() =>
      _RecommendedSupplierCardState();
}

class _RecommendedSupplierCardState extends State<RecommendedSupplierCard> {
  final FavoriteSupplierService favoriteService = FavoriteSupplierService();

  bool favoriteBusy = false;

  Supplier get supplier => widget.supplier;

  bool get hasNetworkImage {
    final imageUrl = supplier.profileImageUrl.trim();
    return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
  }

  bool get canFavorite {
    final currentUserId = favoriteService.currentUserId;
    final supplierId = widget.supplierId.trim();

    return currentUserId != null &&
        supplierId.isNotEmpty &&
        supplierId != currentUserId;
  }

  String get storeInitial {
    final name = supplier.name.trim();
    return name.isEmpty ? 'S' : name.substring(0, 1).toUpperCase();
  }

  String get reviewLabel {
    if (supplier.reviews <= 0 || supplier.rating <= 0) {
      return 'No reviews yet';
    }

    return '${supplier.rating.toStringAsFixed(1)} (${supplier.reviews})';
  }

  String get compactLocation {
    final rawLocation = supplier.location.trim();

    if (rawLocation.isEmpty) {
      return 'Caraga Region';
    }

    final parts = rawLocation
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => part.toLowerCase() != 'caraga region')
        .toList();

    if (parts.isEmpty) {
      return 'Caraga Region';
    }

    if (parts.length == 1) {
      return parts.first;
    }

    return '${parts[parts.length - 2]}, ${parts.last}';
  }

  Future<void> toggleFavorite(bool currentlyFavorite) async {
    if (favoriteBusy || !canFavorite) {
      return;
    }

    setState(() {
      favoriteBusy = true;
    });

    try {
      await favoriteService.toggleFavorite(
        supplierId: widget.supplierId,
        currentlyFavorite: currentlyFavorite,
      );

      if (!mounted) {
        return;
      }

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
      if (!mounted) {
        return;
      }

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
      if (mounted) {
        setState(() {
          favoriteBusy = false;
        });
      }
    }
  }

  Widget favoriteButton() {
    if (!canFavorite) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<bool>(
      stream: favoriteService.isFavoriteStream(widget.supplierId),
      initialData: false,
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return Material(
          color: const Color(0xFFF7FCFF),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: favoriteBusy ? null : () => toggleFavorite(isFavorite),
            customBorder: const CircleBorder(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD7EBF4)),
              ),
              child: favoriteBusy
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF0A73D8),
                      ),
                    )
                  : Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFE94D67)
                          : const Color(0xFF0A73D8),
                      size: 17,
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 8.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * .53)
        .clamp(196.0, 214.0)
        .toDouble();
    final listingCount = widget.availableListingCount ?? 0;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCECF3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F002E48),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: hasNetworkImage
                              ? Image.network(
                                  supplier.profileImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stack) => _placeholder(),
                                )
                              : _placeholder(),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supplier.name.trim().isEmpty
                                  ? 'Supplier'
                                  : supplier.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.4,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF102D48),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 3,
                              children: [
                                _statusPill(
                                  icon: Icons.verified_rounded,
                                  label: 'Verified',
                                  foreground: const Color(0xFF16835F),
                                  background: const Color(0xFFE7F8F1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      favoriteButton(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB02E),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reviewLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.6,
                            color: Color(0xFF566D7E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (listingCount > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '$listingCount stock${listingCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 9.2,
                            color: Color(0xFF087AC0),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Color(0xFF067DA7),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          compactLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.2,
                            color: Color(0xFF617789),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: FilledButton(
                      onPressed: widget.onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE2F5FD),
                        foregroundColor: const Color(0xFF007FB5),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Store',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFDDF2FE),
        alignment: Alignment.center,
        child: Text(
          storeInitial,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF007FB5),
          ),
        ),
      );
}
