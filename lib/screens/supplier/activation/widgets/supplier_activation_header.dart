import 'package:flutter/material.dart';

class SupplierActivationHeader extends StatelessWidget {
  const SupplierActivationHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.submitted,
    required this.onBack,
  });

  final int currentStep;
  final int totalSteps;
  final bool submitted;
  final VoidCallback onBack;

  String get stepLabel =>
      submitted ? 'Pending Review' : 'Step ${currentStep + 1} of $totalSteps';

  String get reviewValue => submitted ? 'Pending review' : 'Admin review';

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBack,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0x42001B31),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(92)),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
      ),
    );
  }

  Widget _stepBadge() {
    return Container(
      constraints: const BoxConstraints(minWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x42001B31),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withAlpha(92)),
      ),
      child: Text(
        stepLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFC5EAF9),
                fontSize: 7.4,
                height: 1,
                letterSpacing: 0.45,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.4,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(width: 1, height: 36, color: Colors.white.withAlpha(48));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final headerHeight = topPadding + 248;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: headerHeight,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Image.asset(
              'assets/images/supplier_application_header_bg.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.12),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x9A032B4C),
                    Color(0xA8063C65),
                    Color(0xCC07527F),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0x76001D35),
                      Colors.transparent,
                      Color(0x36001D35),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 18),
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _backButton(),
                        ),
                        ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.dst,
                          ),
                          child: Image.asset(
                            'assets/images/isdalink_logo.png',
                            width: 126,
                            height: 42,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _stepBadge(),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Supplier Application',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.2,
                      height: 1.05,
                      letterSpacing: -0.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      submitted
                          ? 'Your application is waiting for admin review.'
                          : 'Become a verified supplier and grow your fish business with IsdaLink.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE5F4FA),
                        fontSize: 9.8,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 68,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0x4D002C4A),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: Colors.white.withAlpha(70)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2500162C),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _summaryItem(
                          icon: Icons.verified_user_outlined,
                          label: 'REVIEW',
                          value: reviewValue,
                        ),
                        _summaryDivider(),
                        _summaryItem(
                          icon: Icons.location_on_outlined,
                          label: 'REGION',
                          value: 'Caraga only',
                        ),
                        _summaryDivider(),
                        _summaryItem(
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
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              child: IgnorePointer(
                child: Container(
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F8FB),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
