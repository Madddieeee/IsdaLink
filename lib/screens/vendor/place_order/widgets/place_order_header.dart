import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlaceOrderHeader extends StatelessWidget {
  const PlaceOrderHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF06355F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: const _CheckoutWaveAccentPainter(),
              ),
            ),
          ),
          ClipPath(
            clipper: const _CheckoutHeaderClipper(),
            clipBehavior: Clip.hardEdge,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                18,
                topPadding + 9,
                18,
                31,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF06355F),
                    Color(0xFF0875D1),
                    Color(0xFF12B6D6),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _CheckoutHeaderBackdropPainter(),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Material(
                        color: Colors.white.withAlpha(31),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withAlpha(39),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHECKOUT',
                              style: TextStyle(
                                color: Color(0xFFCBF4F7),
                                fontSize: 8.4,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.25,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Review Your Order',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Confirm your details before placing the order.',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFFDDF5F7),
                                fontSize: 10.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.white.withAlpha(40),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.payments_outlined,
                              color: Color(0xFFE9FDFF),
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'COD',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.6,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutHeaderClipper extends CustomClipper<Path> {
  const _CheckoutHeaderClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height - 20)
      ..cubicTo(
        size.width * 0.22,
        size.height - 7,
        size.width * 0.43,
        size.height - 8,
        size.width * 0.59,
        size.height - 12,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height - 17,
        size.width * 0.88,
        size.height - 25,
        size.width + 6,
        size.height - 23,
      )
      ..lineTo(size.width + 6, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _CheckoutWaveAccentPainter extends CustomPainter {
  const _CheckoutWaveAccentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(-6, size.height - 20)
      ..cubicTo(
        size.width * 0.22,
        size.height - 7,
        size.width * 0.43,
        size.height - 8,
        size.width * 0.59,
        size.height - 12,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height - 17,
        size.width * 0.88,
        size.height - 25,
        size.width + 8,
        size.height - 23,
      );

    final glow = Paint()
      ..color = const Color(0xFF42D5E5).withAlpha(82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final foam = Paint()
      ..color = Colors.white.withAlpha(92)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawPath(path, glow)
      ..drawPath(path, foam);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _CheckoutHeaderBackdropPainter extends CustomPainter {
  const _CheckoutHeaderBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;

    fill.color = Colors.white.withAlpha(12);
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.14),
      size.width * 0.19,
      fill,
    );

    fill.color = Colors.white.withAlpha(8);
    canvas.drawCircle(
      Offset(size.width * 0.74, size.height * 0.70),
      size.width * 0.13,
      fill,
    );

    final ring = Paint()
      ..color = Colors.white.withAlpha(14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas
      ..drawCircle(
        Offset(size.width * 0.89, size.height * 0.35),
        size.width * 0.10,
        ring,
      )
      ..drawCircle(
        Offset(size.width * 0.89, size.height * 0.35),
        size.width * 0.17,
        ring,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
