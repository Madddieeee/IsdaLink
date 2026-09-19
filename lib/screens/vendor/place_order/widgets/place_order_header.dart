import 'package:flutter/material.dart';

class PlaceOrderHeader extends StatelessWidget {
  const PlaceOrderHeader({super.key});

  static const String _waveHeaderAsset = 'assets/images/productdetailwave.png';
  static const double _contentHeight = 112;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: _contentHeight + topPadding,
      child: ClipPath(
        clipper: const _CheckoutHeaderClipper(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _waveHeaderAsset,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (context, error, stackTrace) {
                return const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF064779),
                        Color(0xFF087BCB),
                        Color(0xFF20B9D5),
                      ],
                    ),
                  ),
                );
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xB5084779),
                    Color(0x880875C5),
                    Color(0x2200A9D5),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 9, 16, 19),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 12,
                    child: _HeaderBackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const Positioned(
                    left: 62,
                    top: 1,
                    child: Text(
                      'CHECKOUT',
                      style: TextStyle(
                        color: Color(0xFFDDF5FF),
                        fontSize: 9.5,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.35,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 62,
                    right: 0,
                    top: 23,
                    child: Text(
                      'Review Your Order',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21.5,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        shadows: [
                          Shadow(
                            color: Color(0x45001F38),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 62,
                    right: 0,
                    top: 55,
                    child: Text(
                      'Confirm your details before placing the order.',
                      maxLines: 1,
                      style: TextStyle(
                        color: Color(0xFFF0FAFF),
                        fontSize: 10.2,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Color(0x66002545),
                            blurRadius: 5,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.white.withAlpha(42)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 25),
        ),
      ),
    );
  }
}

class _CheckoutHeaderClipper extends CustomClipper<Path> {
  const _CheckoutHeaderClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 12)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height + 5,
        size.width,
        size.height - 9,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
