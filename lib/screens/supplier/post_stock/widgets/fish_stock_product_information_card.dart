import 'package:flutter/material.dart';
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
  });

  final TextEditingController productNameController;
  final TextEditingController descriptionController;
  final List<String> categories;
  final String selectedCategory;
  final VoidCallback onPreviewChanged;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return PostStockSectionCard(
      title: 'Product Information',
      subtitle: 'Enter the fish product details shown to vendors.',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          CompactInputField(
            controller: productNameController,
            hintText: 'Fish product name',
            icon: Icons.edit,
            onChanged: (_) => onPreviewChanged(),
          ),
          const SizedBox(height: 10),
          CompactDropdownField(
            label: 'Category',
            value: selectedCategory,
            items: categories,
            icon: Icons.category,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 10),
          CompactInputField(
            controller: descriptionController,
            hintText: 'Description',
            icon: Icons.description,
            maxLines: 3,
            onChanged: (_) => onPreviewChanged(),
          ),
        ],
      ),
    );
  }
}

class CompactInputField extends StatelessWidget {
  const CompactInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(
        color: Color(0xFF102C44),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9AADBC),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF146BFF),
          size: 19,
        ),
        filled: true,
        fillColor: const Color(0xFFF1F6FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFF146BFF),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class CompactDropdownField extends StatelessWidget {
  const CompactDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF7B8FA3),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF146BFF),
          size: 19,
        ),
        filled: true,
        fillColor: const Color(0xFFF1F6FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: Color(0xFF146BFF),
            width: 1.4,
          ),
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Color(0xFF52677A),
      ),
      style: const TextStyle(
        color: Color(0xFF102C44),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
      items: items.map(
        (item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}
