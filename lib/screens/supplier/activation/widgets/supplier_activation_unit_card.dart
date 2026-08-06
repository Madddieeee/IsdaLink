import 'package:flutter/material.dart';

class SupplierActivationUnitCard extends StatelessWidget {
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
  final ValueChanged<bool> onKiloChanged;
  final ValueChanged<bool> onTabChanged;
  final ValueChanged<bool> onIceboxChanged;

  @override
  Widget build(BuildContext context) {
    final selectedCount = [
      kiloUnit,
      tabUnit,
      iceboxUnit,
    ].where((value) => value).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E00152A),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 41,
                height: 41,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.scale_outlined,
                  color: Color(0xFF146BFF),
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supported Selling Units',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Choose every unit this store can fulfill.',
                      style: TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: selectedCount > 0
                      ? const Color(0xFFE7F8F1)
                      : const Color(0xFFF2F7FB),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$selectedCount selected',
                  style: TextStyle(
                    color: selectedCount > 0
                        ? const Color(0xFF147D64)
                        : const Color(0xFF7B8FA3),
                    fontSize: 8.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _UnitOption(
            title: 'Kilogram',
            subtitle: 'For fish sold by weight.',
            selected: kiloUnit,
            onChanged: onKiloChanged,
          ),
          const SizedBox(height: 9),
          _UnitOption(
            title: 'Tab',
            subtitle: 'For bulk fish container orders.',
            selected: tabUnit,
            onChanged: onTabChanged,
          ),
          const SizedBox(height: 9),
          _UnitOption(
            title: 'Icebox',
            subtitle: 'For larger fish supply orders.',
            selected: iceboxUnit,
            onChanged: onIceboxChanged,
          ),
          if (selectedCount == 0) ...[
            const SizedBox(height: 11),
            const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFFF7A1A),
                  size: 17,
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Select at least one selling unit to continue.',
                    style: TextStyle(
                      color: Color(0xFF7A5328),
                      fontSize: 9.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UnitOption extends StatelessWidget {
  const _UnitOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          padding: const EdgeInsets.fromLTRB(12, 11, 11, 11),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEAF8FF)
                : const Color(0xFFF4F8FB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF73C9F3)
                  : const Color(0xFFE3EBF1),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF146BFF) : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.scale_outlined,
                  color: selected ? Colors.white : const Color(0xFF146BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 9.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF1DBB8A)
                      : const Color(0xFFE5EDF2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.add_rounded,
                  color: selected ? Colors.white : const Color(0xFF7B8FA3),
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
