import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_input_decoration.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockProductInformationCard extends StatelessWidget {
  const FishStockProductInformationCard({
    super.key,
    required this.productNameController,
    required this.descriptionController,
    required this.categories,
    required this.selectedCategory,
    required this.onPreviewChanged,
    required this.onCategoryChanged,
    this.productNameError,
    this.descriptionError,
  });

  final TextEditingController productNameController;
  final TextEditingController descriptionController;
  final List<String> categories;
  final String selectedCategory;
  final VoidCallback onPreviewChanged;
  final ValueChanged<String> onCategoryChanged;
  final String? productNameError;
  final String? descriptionError;

  @override
  Widget build(BuildContext context) {
    return PostStockSectionCard(
      title: 'Product Information',
      subtitle: 'Add the marketplace details vendors need.',
      icon: Icons.inventory_2_outlined,
      badge: 'STEP 1',
      child: Column(
        children: [
          TextField(
            controller: productNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              LengthLimitingTextInputFormatter(60),
            ],
            onChanged: (_) => onPreviewChanged(),
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            decoration: postStockInputDecoration(
              label: 'Fish product name',
              hintText: 'Example: Tamban',
              icon: Icons.set_meal_outlined,
              errorText: productNameError,
            ),
          ),
          const SizedBox(height: 11),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            isExpanded: true,
            decoration: postStockInputDecoration(
              label: 'Category',
              icon: Icons.category_outlined,
            ),
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF52677A),
            ),
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            items: categories.map(
              (category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ).toList(),
            onChanged: (value) {
              if (value != null) {
                onCategoryChanged(value);
              }
            },
          ),
          const SizedBox(height: 11),
          TextField(
            controller: descriptionController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            minLines: 2,
            maxLines: 3,
            inputFormatters: [
              LengthLimitingTextInputFormatter(240),
            ],
            onChanged: (_) => onPreviewChanged(),
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
            decoration: postStockInputDecoration(
              label: 'Description',
              hintText: 'Freshness, size, or handling details.',
              icon: Icons.description_outlined,
              helperText: 'Use clear details that help vendors decide.',
              errorText: descriptionError,
            ),
          ),
        ],
      ),
    );
  }
}
