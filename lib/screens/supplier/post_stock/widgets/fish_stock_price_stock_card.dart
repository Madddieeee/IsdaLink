import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    required this.isCustomPercentage,
    required this.onUnitChanged,
    required this.onPreviewChanged,
    required this.onPercentageChanged,
    required this.onCustomPercentageChanged,
    this.priceError,
    this.quantityError,
    this.percentageError,
  });

  final TextEditingController priceController;
  final TextEditingController quantityController;
  final TextEditingController lowStockController;
  final TextEditingController percentageController;
  final String selectedUnit;
  final List<String> units;
  final bool isCustomPercentage;
  final ValueChanged<String> onUnitChanged;
  final VoidCallback onPreviewChanged;
  final VoidCallback onPercentageChanged;
  final ValueChanged<bool> onCustomPercentageChanged;
  final String? priceError;
  final String? quantityError;
  final String? percentageError;

  String formatNumber(double value) {
    return value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  void applyPreset(
    String value,
  ) {
    percentageController.text = value;
    percentageController.selection = TextSelection.collapsed(
      offset: percentageController.text.length,
    );
    onCustomPercentageChanged(false);
    onPercentageChanged();
  }

  void openCustomPercentage() {
    if (!isCustomPercentage) {
      percentageController.clear();
      onCustomPercentageChanged(true);
      onPercentageChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantity =
        double.tryParse(quantityController.text.trim()) ?? 0;
    final percentage =
        double.tryParse(percentageController.text.trim()) ?? 0;
    final validPercentage =
        percentage >= 1 && percentage <= 100;
    final double suggested = validPercentage
        ? quantity * percentage / 100
        : 0.0;
    final currentPercentage =
        percentageController.text.trim();

    return PostStockSectionCard(
      title: 'Price, Unit, and Stock',
      subtitle: 'Set availability and the automatic alert threshold.',
      icon: Icons.inventory_2_outlined,
      badge: 'STEP 3',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (_) => onPreviewChanged(),
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: postStockInputDecoration(
                    label: 'Selling price',
                    icon: Icons.sell_outlined,
                    prefixText: '₱ ',
                    errorText: priceError,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedUnit,
                  isExpanded: true,
                  decoration: postStockInputDecoration(
                    label: 'Selling unit',
                    icon: Icons.scale_outlined,
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  items: units.map(
                    (unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(
                          'per $unit',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onUnitChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          TextField(
            controller: quantityController,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*\.?\d{0,2}'),
              ),
            ],
            onChanged: (_) => onPercentageChanged(),
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontWeight: FontWeight.w800,
            ),
            decoration: postStockInputDecoration(
              label: 'Available stock',
              icon: Icons.inventory_outlined,
              suffixText: selectedUnit,
              helperText:
                  'Quantity currently available for vendor orders.',
              errorText: quantityError,
            ),
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEAF8FF),
                  Color(0xFFEAFBF5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF75CFEA).withAlpha(88),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    _AlertIcon(),
                    SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Automatic Low-Stock Alert',
                            style: TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 12.3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Choose when the supplier stock alert should appear.',
                            style: TextStyle(
                              color: Color(0xFF657C8E),
                              fontSize: 9.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final value in const [
                      '10',
                      '20',
                      '25',
                      '30',
                    ])
                      _PercentageChoice(
                        label: value == '20'
                            ? '20% Recommended'
                            : '$value%',
                        selected:
                            !isCustomPercentage &&
                            currentPercentage == value,
                        onTap: () {
                          applyPreset(value);
                        },
                      ),
                    _PercentageChoice(
                      label: 'Custom',
                      selected: isCustomPercentage,
                      onTap: openCustomPercentage,
                    ),
                  ],
                ),
                if (isCustomPercentage) ...[
                  const SizedBox(height: 11),
                  TextField(
                    controller: percentageController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,1}'),
                      ),
                    ],
                    onChanged: (_) => onPercentageChanged(),
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: postStockInputDecoration(
                      label: 'Custom alert percentage',
                      icon: Icons.percent_rounded,
                      suffixText: '%',
                      helperText: 'Enter a value from 1% to 100%.',
                      errorText: percentageError,
                    ),
                  ),
                ] else if (percentageError != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    percentageError!,
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 11),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    11,
                    12,
                    11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(210),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFDDEAF1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 39,
                        height: 39,
                        decoration: BoxDecoration(
                          color: quantity > 0 &&
                                  validPercentage
                              ? const Color(0xFFE7F8F1)
                              : const Color(0xFFFFF2E8),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: Icon(
                          quantity > 0 && validPercentage
                              ? Icons
                                  .notifications_active_rounded
                              : Icons.calculate_outlined,
                          color: quantity > 0 &&
                                  validPercentage
                              ? const Color(0xFF147D64)
                              : const Color(0xFFFF7A1A),
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              quantity > 0 && validPercentage
                                  ? 'CALCULATED ALERT LEVEL'
                                  : 'ALERT LEVEL',
                              style: const TextStyle(
                                color: Color(0xFF7B8FA3),
                                fontSize: 8.4,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              quantity > 0 && validPercentage
                                  ? '${formatNumber(suggested)} $selectedUnit'
                                  : 'Enter available stock',
                              style: TextStyle(
                                color: quantity > 0 &&
                                        validPercentage
                                    ? const Color(0xFF102C44)
                                    : const Color(0xFF8BA0B1),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              quantity > 0 && validPercentage
                                  ? 'You will receive an alert when remaining stock reaches this quantity.'
                                  : 'The threshold will be calculated automatically.',
                              style: const TextStyle(
                                color: Color(0xFF657C8E),
                                fontSize: 9.3,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _AlertIcon extends StatelessWidget {
  const _AlertIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 37,
      height: 37,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF2E8),
        borderRadius: BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      child: const Icon(
        Icons.notifications_active_outlined,
        color: Color(0xFFFF7A1A),
        size: 20,
      ),
    );
  }
}

class _PercentageChoice extends StatelessWidget {
  const _PercentageChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF146BFF)
                : Colors.white.withAlpha(200),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? const Color(0xFF146BFF)
                  : const Color(0xFFD8E7EF),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : const Color(0xFF52677A),
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
