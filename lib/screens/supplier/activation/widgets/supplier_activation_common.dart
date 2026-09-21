import 'package:flutter/material.dart';

class SupplierActivationProgressCard extends StatelessWidget {
  const SupplierActivationProgressCard({
    super.key,
    required this.currentStep,
    required this.stepTitles,
    required this.onStepTap,
  });

  final int currentStep;
  final List<String> stepTitles;
  final ValueChanged<int> onStepTap;

  static const _blue = Color(0xFF146BFF);
  static const _navy = Color(0xFF102C44);

  @override
  Widget build(BuildContext context) {
    const icons = <IconData>[
      Icons.person_outline_rounded,
      Icons.storefront_outlined,
      Icons.verified_user_outlined,
      Icons.fact_check_outlined,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D00152A),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Application Progress',
            style: TextStyle(
              color: _navy,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(stepTitles.length * 2 - 1, (slot) {
              if (slot.isOdd) {
                final stepIndex = slot ~/ 2;
                final completed = stepIndex < currentStep;
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(top: 17),
                    decoration: BoxDecoration(
                      color: completed ? _blue : const Color(0xFFDCE7EF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              }

              final index = slot ~/ 2;
              final active = index == currentStep;
              final done = index < currentStep;
              final enabled = index <= currentStep;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? () => onStepTap(index) : null,
                child: SizedBox(
                  width: 58,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: done || active
                              ? _blue
                              : const Color(0xFFEAF0F5),
                          shape: BoxShape.circle,
                          boxShadow: active
                              ? const [
                                  BoxShadow(
                                    color: Color(0x30146BFF),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : active
                              ? Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                )
                              : Icon(
                                  icons[index],
                                  color: const Color(0xFF9AADBC),
                                  size: 17,
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stepTitles[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: done || active
                              ? _blue
                              : const Color(0xFF8CA0B3),
                          fontSize: 8.6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class SupplierStepStatusCard extends StatelessWidget {
  const SupplierStepStatusCard({
    super.key,
    required this.complete,
    required this.missingItems,
  });

  final bool complete;
  final List<String> missingItems;

  @override
  Widget build(BuildContext context) {
    if (complete) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8ED),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFFFD4A3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB86112),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete required details',
                  style: TextStyle(
                    color: Color(0xFF9B510F),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  missingItems.isEmpty
                      ? 'Check the information above before continuing.'
                      : 'Still needed: ${missingItems.join(', ')}.',
                  style: const TextStyle(
                    color: Color(0xFF65717D),
                    fontSize: 9.7,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class SupplierActivationIntroCard extends StatelessWidget {
  const SupplierActivationIntroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFE),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFDCEBF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF087FCB), size: 19),
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
                    fontSize: 11.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF657C8E),
                    fontSize: 9.8,
                    height: 1.34,
                    fontWeight: FontWeight.w600,
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

class SupplierActivationSectionCard extends StatelessWidget {
  const SupplierActivationSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE1EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B00152A),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FB),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF087FCB), size: 20),
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
                        fontSize: 13.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 9.7,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }
}

class SupplierSelectionField extends StatelessWidget {
  const SupplierSelectionField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.onClear,
    this.helperText,
  });

  final String label;
  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final selected = value?.trim().isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(9, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF8EDBC2)
                      : const Color(0xFFE2EBF1),
                  width: selected ? 1.2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7FB),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: const Color(0xFF087FCB), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF718598),
                            fontSize: 9.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selected ? (value ?? placeholder) : placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF102C44)
                                : const Color(0xFF94A5B4),
                            fontSize: 11.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected && onClear != null)
                    IconButton(
                      tooltip: 'Clear $label',
                      onPressed: onClear,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF8BA0B1),
                        size: 18,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF52677A),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              helperText!,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 9.4,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class SupplierSelectionSheet extends StatefulWidget {
  const SupplierSelectionSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedValue,
  });

  final String title;
  final String subtitle;
  final List<String> items;
  final String? selectedValue;

  @override
  State<SupplierSelectionSheet> createState() => _SupplierSelectionSheetState();
}

class _SupplierSelectionSheetState extends State<SupplierSelectionSheet> {
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final items = normalized.isEmpty
        ? widget.items
        : widget.items
              .where((item) => item.toLowerCase().contains(normalized))
              .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(29)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFBED0DC),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF7B8FA3),
                          fontSize: 9.8,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          if (widget.items.length > 8)
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 0, 17, 11),
              child: TextField(
                controller: searchController,
                autofocus: true,
                onChanged: (value) => setState(() => query = value),
                decoration: InputDecoration(
                  hintText: 'Search locality',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF087FCB),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE1EBF2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF087FCB),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          Divider(height: 1, color: Colors.black.withAlpha(16)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = item == widget.selectedValue;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, item),
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFEAF8FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF73C9F3)
                              : const Color(0xFFE4ECF2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF087FCB)
                                  : const Color(0xFFEAF7FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF087FCB),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                color: Color(0xFF102C44),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF1DBB8A),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
