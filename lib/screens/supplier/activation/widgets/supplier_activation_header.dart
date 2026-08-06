import 'package:flutter/material.dart';

class SupplierActivationHeader extends StatelessWidget {
  const SupplierActivationHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.enabledUnitCount,
    required this.submitted,
    required this.onBack,
  });

  final int currentStep;
  final int totalSteps;
  final int enabledUnitCount;
  final bool submitted;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 232,
      toolbarHeight: 62,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFF075FAE),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leadingWidth: 58,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(99),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(32),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(28)),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 21),
            ),
          ),
        ),
      ),
      titleSpacing: 8,
      title: const Text(
        'Supplier Onboarding',
        style: TextStyle(
          fontSize: 20.2,
          letterSpacing: -0.15,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(28),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withAlpha(28)),
              ),
              child: Text(
                submitted
                    ? 'Pending Review'
                    : 'Step ${currentStep + 1} of $totalSteps',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF063B66),
                Color(0xFF075FAE),
                Color(0xFF146BFF),
              ],
              stops: [0, 0.55, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -58,
                right: -52,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(9),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                ),
              ),
              Positioned(
                top: 68,
                right: 24,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.paddingOf(context).top + 75,
                  18,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUPPLIER ACTIVATION',
                      style: TextStyle(
                        color: Color(0xFFBCE8FF),
                        fontSize: 8.6,
                        letterSpacing: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      submitted
                          ? 'Your supplier application is awaiting admin review.'
                          : 'Create a trusted supplier profile with verified owner, store, unit, and business details.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFDDEFFF),
                        fontSize: 10.7,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(29),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(color: Colors.white.withAlpha(31)),
                      ),
                      child: Row(
                        children: [
                          const _HeaderFeature(
                            icon: Icons.verified_user_outlined,
                            label: 'REVIEW',
                            value: 'Admin verified',
                          ),
                          const _HeaderDivider(),
                          _HeaderFeature(
                            icon: Icons.scale_outlined,
                            label: 'SELLING UNITS',
                            value: '$enabledUnitCount selected',
                          ),
                          const _HeaderDivider(),
                          const _HeaderFeature(
                            icon: Icons.payments_outlined,
                            label: 'PAYMENT',
                            value: 'COD only',
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
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
    );
  }
}

class _HeaderFeature extends StatelessWidget {
  const _HeaderFeature({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFBCE8FF),
              fontSize: 7.1,
              letterSpacing: 0.35,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDivider extends StatelessWidget {
  const _HeaderDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withAlpha(28),
    );
  }
}
