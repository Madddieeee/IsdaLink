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

  String get stepLabel {
    if (submitted) {
      return 'Pending Review';
    }

    return 'Step ${currentStep + 1} of $totalSteps';
  }

  String get reviewValue {
    return submitted ? 'Pending review' : 'Admin review';
  }

  String get unitsValue {
    if (enabledUnitCount == 1) {
      return '1 selected';
    }

    return '$enabledUnitCount selected';
  }

  Widget backButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBack,
        customBorder: const CircleBorder(),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withAlpha(28),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget stepBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withAlpha(30),
        ),
      ),
      child: Text(
        stepLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget summaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 17,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFBFE8FA),
              fontSize: 7.1,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryDivider() {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      color: Colors.white.withAlpha(28),
    );
  }

  Widget headerCopy(double visibility) {
    return IgnorePointer(
      ignoring: visibility < 0.1,
      child: Opacity(
        opacity: visibility,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SUPPLIER ACTIVATION',
              style: TextStyle(
                color: Color(0xFFBFE8FA),
                fontSize: 8.4,
                letterSpacing: 0.95,
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
                color: Color(0xFFDDEFFA),
                fontSize: 10.6,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget summaryCard(double visibility) {
    return IgnorePointer(
      ignoring: visibility < 0.1,
      child: Opacity(
        opacity: visibility,
        child: Container(
          width: double.infinity,
          height: 64,
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(27),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withAlpha(31),
            ),
          ),
          child: Row(
            children: [
              summaryItem(
                icon: Icons.verified_user_outlined,
                label: 'REVIEW',
                value: reviewValue,
              ),
              summaryDivider(),
              summaryItem(
                icon: Icons.scale_outlined,
                label: 'SELLING UNITS',
                value: unitsValue,
              ),
              summaryDivider(),
              summaryItem(
                icon: Icons.payments_outlined,
                label: 'PAYMENT',
                value: 'COD only',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 244,
      toolbarHeight: 62,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color(0xFF075FAE),
      foregroundColor: Colors.white,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(
          left: 14,
          top: 8,
          bottom: 8,
        ),
        child: backButton(),
      ),
      titleSpacing: 6,
      title: const Text(
        'Supplier Onboarding',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: 19.4,
          letterSpacing: -0.15,
          fontWeight: FontWeight.w900,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(
            right: 15,
          ),
          child: Center(
            child: stepBadge(),
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final collapsedHeight = topPadding + 62;
          final expandedHeight = topPadding + 244;
          final range = expandedHeight - collapsedHeight;

          final expansion = range <= 0
              ? 0.0
              : ((constraints.maxHeight - collapsedHeight) / range)
                  .clamp(0.0, 1.0)
                  .toDouble();

          final copyVisibility =
              ((expansion - 0.52) / 0.30).clamp(0.0, 1.0).toDouble();

          final summaryVisibility =
              ((expansion - 0.72) / 0.20).clamp(0.0, 1.0).toDouble();

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(29),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF063B66),
                    Color(0xFF075FAE),
                    Color(0xFF146BFF),
                  ],
                  stops: [
                    0.0,
                    0.55,
                    1.0,
                  ],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SupplierHeaderPainter(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    top: topPadding + 76,
                    child: headerCopy(copyVisibility),
                  ),
                  if (expansion > 0.68)
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: summaryCard(summaryVisibility),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(29),
        ),
      ),
    );
  }
}

class _SupplierHeaderPainter extends CustomPainter {
  const _SupplierHeaderPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final fillPaint = Paint()
      ..color = Colors.white.withAlpha(10);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = Colors.white.withAlpha(20);

    canvas.drawCircle(
      Offset(
        size.width * 0.89,
        size.height * 0.12,
      ),
      size.width * 0.25,
      fillPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.85,
        size.height * 0.27,
      ),
      size.width * 0.18,
      borderPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.74,
        size.height * 0.47,
      ),
      size.width * 0.1,
      borderPaint,
    );

    final accentPaint = Paint()
      ..color = Colors.white.withAlpha(8);

    final accentPath = Path()
      ..moveTo(
        size.width * 0.58,
        size.height,
      )
      ..lineTo(
        size.width,
        size.height * 0.50,
      )
      ..lineTo(
        size.width,
        size.height,
      )
      ..close();

    canvas.drawPath(
      accentPath,
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _SupplierHeaderPainter oldDelegate,
  ) {
    return false;
  }
}
