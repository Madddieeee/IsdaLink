import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_section_card.dart';

class SupplierActivationUnitCard
    extends
        StatelessWidget {
  const SupplierActivationUnitCard({
    super.key,
    required this.kiloUnit,
    required this.tabUnit,
    required this.iceboxUnit,
    required this.onKiloChanged,
    required this.onTabChanged,
    required this.onIceboxChanged,
  });

  final bool kiloUnit;
  final bool tabUnit;
  final bool iceboxUnit;
  final ValueChanged<
    bool
  >
  onKiloChanged;
  final ValueChanged<
    bool
  >
  onTabChanged;
  final ValueChanged<
    bool
  >
  onIceboxChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SupplierActivationSectionCard(
      title: 'Bulk Unit Options',
      subtitle: 'Choose the selling units supported by the supplier.',
      icon: Icons.scale,
      child: Column(
        children: [
          SupplierActivationUnitSwitch(
            title: 'Per Kilo',
            subtitle: 'For regular fish purchases by kilogram.',
            value: kiloUnit,
            onChanged: onKiloChanged,
          ),
          SupplierActivationUnitSwitch(
            title: 'Per Tab',
            subtitle: 'For bulk fish container orders.',
            value: tabUnit,
            onChanged: onTabChanged,
          ),
          SupplierActivationUnitSwitch(
            title: 'Per Icebox',
            subtitle: 'For larger fish supply orders.',
            value: iceboxUnit,
            onChanged: onIceboxChanged,
          ),
        ],
      ),
    );
  }
}

class SupplierActivationUnitSwitch
    extends
        StatelessWidget {
  const SupplierActivationUnitSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<
    bool
  >
  onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF4F8FB,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.scale,
            color: Color(
              0xFF146BFF,
            ),
            size: 21,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(
              0xFF146BFF,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
