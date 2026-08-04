import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_input_decoration.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockPriceStockCard extends StatelessWidget {
  const FishStockPriceStockCard({
    super.key,
    required this.priceController,
    required this.quantityController,
    required this.lowStockController,
    required this.percentageController,
    required this.selectedUnit,
    required this.units,
    required this.onUnitChanged,
    required this.onPreviewChanged,
    required this.onPercentageChanged,
  });

  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController lowStockController;
  final TextEditingController percentageController;
  final String selectedUnit;
  final List<String> units;
  final ValueChanged<String> onUnitChanged;
  final VoidCallback onPreviewChanged;
  final VoidCallback onPercentageChanged;

  String formatNumber(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    final percentage = double.tryParse(percentageController.text.trim()) ?? 20;
    final suggested = quantity * percentage.clamp(1, 100) / 100;

    return PostStockSectionCard(
      title: 'Price and Stock',
      subtitle: 'Set the selling unit and automatic low-stock alert.',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => onPreviewChanged(),
                  decoration: postStockInputDecoration(
                    label: 'Price',
                    icon: Icons.sell_outlined,
                    suffixText: 'PHP',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedUnit,
                  decoration: postStockInputDecoration(
                    label: 'Selling unit',
                    icon: Icons.scale_outlined,
                  ),
                  items: units.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text('per $unit'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onUnitChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onPercentageChanged(),
            decoration: postStockInputDecoration(
              label: 'Available stock',
              icon: Icons.inventory_outlined,
              suffixText: selectedUnit,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8FD),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD9EAF4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFFFF7A1A),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Low-Stock Alert',
                        style: TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'A 20% alert is suggested automatically. You may adjust the percentage or final threshold.',
                  style: TextStyle(
                    color: Color(0xFF71889A),
                    fontSize: 9.6,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: percentageController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => onPercentageChanged(),
                        decoration: postStockInputDecoration(
                          label: 'Alert percentage',
                          icon: Icons.percent_rounded,
                          suffixText: '%',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: lowStockController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => onPreviewChanged(),
                        decoration: postStockInputDecoration(
                          label: 'Alert level',
                          icon: Icons.warning_amber_rounded,
                          suffixText: selectedUnit,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    quantity > 0
                        ? 'Suggested threshold: ${formatNumber(suggested)} $selectedUnit'
                        : 'Enter available stock to calculate the alert level.',
                    style: const TextStyle(
                      color: Color(0xFF0875D1),
                      fontSize: 10.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
