import 'package:isdalink/models/fish_product.dart';

class Supplier {
  final String name;
  final String location;
  final String contactNumber;
  final String description;
  final double rating;
  final int reviews;
  final List<FishProduct> products;

  const Supplier({
    required this.name,
    required this.location,
    required this.contactNumber,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.products,
  });
}
