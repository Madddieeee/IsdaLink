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

  @override
  Widget build(BuildContext context) {
    const icons = <IconData>[
      Icons.person_outline_rounded,
      Icons.storefront_outlined,
      Icons.scale_outlined,
      Icons.verified_user_outlined,
      Icons.fact_check_outlined,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EDF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF146BFF), Color(0xFF10B7D4)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification Progress',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Step ${currentStep + 1} of ${stepTitles.length} · ${stepTitles[currentStep]} details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 10.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / stepTitles.length,
              minHeight: 6,
              backgroundColor: const Color(0xFFEAF0F5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF146BFF),
              ),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: List.generate(stepTitles.length, (index) {
              final active = index == currentStep;
              final done = index < currentStep;

              return Expanded(
                child: GestureDetector(
                  onTap: index <= currentStep ? () => onStepTap(index) : null,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 170),
                        width: active ? 36 : 32,
                        height: active ? 36 : 32,
                        decoration: BoxDecoration(
                          color: done || active
                              ? const Color(0xFF146BFF)
                              : const Color(0xFFEAF0F5),
                          shape: BoxShape.circle,
                          boxShadow: active
                              ? const [
                                  BoxShadow(
                                    color: Color(0x35146BFF),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          done ? Icons.check_rounded : icons[index],
                          color: done || active
                              ? Colors.white
                              : const Color(0xFF9AADBC),
                          size: active ? 18 : 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stepTitles[index],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: done || active
                              ? const Color(0xFF146BFF)
                              : const Color(0xFF8CA0B3),
                          fontSize: 8.8,
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
        color: const Color(0xFFF8FCFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8ECF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFF146BFF), size: 20),
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
                    fontSize: 12.5,
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
                child: Icon(icon, color: const Color(0xFF146BFF), size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
            borderRadius: BorderRadius.circular(19),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(10, 8, 9, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAFD),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF77D7B7)
                      : const Color(0xFFE5EEF6),
                  width: selected ? 1.25 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F9FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFF146BFF), size: 19),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF6B7F93),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selected ? (value ?? placeholder) : placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF102C44)
                                : const Color(0xFF8BA0B1),
                            fontSize: 11.8,
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
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF8BA0B1),
                        size: 18,
                      ),
                    )
                  else
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF52677A),
                      size: 21,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
  State<SupplierSelectionSheet> createState() =>
      _SupplierSelectionSheetState();
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
                    color: Color(0xFF146BFF),
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
                      color: Color(0xFF146BFF),
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
                                  ? const Color(0xFF146BFF)
                                  : const Color(0xFFEAF7FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF146BFF),
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
