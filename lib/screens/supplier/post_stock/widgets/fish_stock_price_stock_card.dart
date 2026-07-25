import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_product_information_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockPriceStockCard extends StatelessWidget {
  const FishStockPriceStockCard({
    super.key,
    required this.priceController,
    required this.quantityController,
    required this.lowStockController,
    required this.units,
    required this.selectedUnit,
    required this.onPreviewChanged,
    required this.onUnitChanged,
  });

  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController lowStockController;
  final List<String> units;
  final String selectedUnit;
  final VoidCallback onPreviewChanged;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return PostStockSectionCard(
      title: 'Price and Stock',
      subtitle: 'Set price, unit, quantity, and low stock alert level.',
      icon: Icons.inventory,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: CompactInputField(
                  controller: priceController,
                  hintText: 'Price',
                  icon: Icons.sell,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onPreviewChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: CompactUnitDropdown(
                  value: selectedUnit,
                  items: units,
                  onChanged: onUnitChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CompactInputField(
            controller: quantityController,
            hintText: 'Available quantity',
            icon: Icons.inventory_2,
            keyboardType: TextInputType.number,
            onChanged: (_) => onPreviewChanged(),
          ),
          const SizedBox(height: 10),
          CompactInputField(
            controller: lowStockController,
            hintText: 'Low stock alert level',
            icon: Icons.warning_amber_rounded,
            keyboardType: TextInputType.number,
            onChanged: (_) => onPreviewChanged(),
          ),
        ],
      ),
    );
  }
}

class CompactUnitDropdown extends StatelessWidget {
  const CompactUnitDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Unit',
        labelStyle: const TextStyle(
          color: Color(0xFF7B8FA3),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        prefixIcon: const Icon(
          Icons.scale,
          color: Color(0xFF146BFF),
          size: 18,
        ),
        filled: true,
        fillColor: const Color(0xFFF1F6FA),
        contentPadding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 34,
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
        size: 20,
      ),
      style: const TextStyle(
        color: Color(0xFF102C44),
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
      ),
      selectedItemBuilder: (context) {
        return items.map(
          (item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'per $item',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ).toList();
      },
      items: items.map(
        (item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              'per $item',
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
    );
  }
}
