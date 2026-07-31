import 'package:isdalink/models/fish_product.dart';

class Supplier {
  final String name;
  final String location;
  final String contactNumber;
  final String description;
  final double rating;
  final int reviews;
  final List<FishProduct> products;
  final String profileImageUrl;
  final DateTime? accountCreatedAt;

  const Supplier({
    required this.name,
    required this.location,
    required this.contactNumber,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.products,
    this.profileImageUrl = '',
    this.accountCreatedAt,
  });

  bool get isNewSupplier {
    final createdAt = accountCreatedAt;

    if (createdAt == null) {
      return false;
    }

    final now = DateTime.now().toUtc();
    final created = createdAt.toUtc();

    if (created.isAfter(now)) {
      return false;
    }

    return now.difference(created) < const Duration(days: 7);
  }

  int get newSupplierDaysRemaining {
    final createdAt = accountCreatedAt;

    if (createdAt == null || !isNewSupplier) {
      return 0;
    }

    final expiresAt = createdAt.toUtc().add(
          const Duration(days: 7),
        );
    final remaining = expiresAt.difference(
      DateTime.now().toUtc(),
    );

    final days = (remaining.inMinutes / Duration.minutesPerDay).ceil();

    return days.clamp(1, 7).toInt();
  }
}
