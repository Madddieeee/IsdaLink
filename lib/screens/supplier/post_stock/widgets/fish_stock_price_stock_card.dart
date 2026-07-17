import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_input_decoration.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockPriceStockCard
    extends
        StatelessWidget {
  const FishStockPriceStockCard({
    super.key,
    required this.priceController,
    required this.quantityController,
    required this.lowStockController,
    required this.selectedUnit,
    required this.units,
    required this.onUnitChanged,
    required this.onPreviewChanged,
  });

  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController lowStockController;
  final String selectedUnit;
  final List<
    String
  >
  units;
  final ValueChanged<
    String
  >
  onUnitChanged;
  final VoidCallback onPreviewChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return PostStockSectionCard(
      title: 'Price and Stock',
      subtitle: 'Set product price, unit, quantity, and alert level.',
      icon: Icons.inventory_2,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  onChanged:
                      (
                        _,
                      ) => onPreviewChanged(),
                  decoration: postStockInputDecoration(
                    label: 'Price',
                    icon: Icons.sell,
                    suffixText: 'PHP',
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                    DropdownButtonFormField<
                      String
                    >(
                      initialValue: selectedUnit,
                      decoration: postStockInputDecoration(
                        label: 'Unit',
                        icon: Icons.scale,
                      ),
                      items: units.map(
                        (
                          unit,
                        ) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(
                              'per $unit',
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

                            onUnitChanged(
                              value,
                            );
                          },
                    ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: postStockInputDecoration(
              label: 'Available Quantity',
              icon: Icons.inventory,
              suffixText: selectedUnit,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          TextField(
            controller: lowStockController,
            keyboardType: TextInputType.number,
            decoration: postStockInputDecoration(
              label: 'Low Stock Alert Level',
              icon: Icons.warning_amber,
              suffixText: selectedUnit,
            ),
          ),
        ],
      ),
    );
  }
}
