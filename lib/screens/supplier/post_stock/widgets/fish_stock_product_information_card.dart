import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_input_decoration.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockProductInformationCard
    extends
        StatelessWidget {
  const FishStockProductInformationCard({
    super.key,
    required this.productNameController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.onPreviewChanged,
  });

  final TextEditingController productNameController;
  final TextEditingController descriptionController;
  final String selectedCategory;
  final List<
    String
  >
  categories;
  final ValueChanged<
    String
  >
  onCategoryChanged;
  final VoidCallback onPreviewChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return PostStockSectionCard(
      title: 'Product Information',
      subtitle: 'Enter the fish product details shown to vendors.',
      icon: Icons.set_meal,
      child: Column(
        children: [
          TextField(
            controller: productNameController,
            onChanged:
                (
                  _,
                ) => onPreviewChanged(),
            decoration: postStockInputDecoration(
              label: 'Fish Product Name',
              icon: Icons.edit,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          DropdownButtonFormField<
            String
          >(
            initialValue: selectedCategory,
            decoration: postStockInputDecoration(
              label: 'Category',
              icon: Icons.category,
            ),
            items: categories.map(
              (
                category,
              ) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                  ),
                );
              },
            ).toList(),
            onChanged:
                (
                  value,
                ) {
                  if (value ==
                      null) {
                    return;
                  }

                  onCategoryChanged(
                    value,
                  );
                },
          ),
          const SizedBox(
            height: 12,
          ),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: postStockInputDecoration(
              label: 'Description',
              icon: Icons.description,
            ),
          ),
        ],
      ),
    );
  }
}
