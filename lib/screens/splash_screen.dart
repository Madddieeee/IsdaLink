import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef StartupInitializer = Future<void> Function();
typedef StartupDestinationBuilder = Widget Function(BuildContext context);
typedef StartupDestinationCallback = Future<void> Function();

class StartupSplash extends StatefulWidget {
  const StartupSplash({
    required this.initialize,
    required this.destinationBuilder,
    this.onDestinationShown,
    super.key,
  });

  final StartupInitializer initialize;
  final StartupDestinationBuilder destinationBuilder;
  final StartupDestinationCallback? onDestinationShown;

  @override
  State<StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<StartupSplash>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _handoffController;

  bool _destinationMounted = false;
  bool _handoffComplete = false;
  bool _destinationCallbackScheduled = false;
  bool _starting = false;
  String? _startupError;

  @override
  void initState() {
    super.initState();

    // The native Android launch and Flutter share the same fish mark. Flutter
    // holds that mark just long enough for the combined fish-only moment to
    // feel close to 1.5 seconds on a normal cold start, then gives the wordmark,
    // wave, and tagline more room to breathe without making startup feel long.
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Premium handoff: after the launcher finishes, the Login page rises
    // clearly from the bottom and eases into its final position. A little over
    // one second keeps the motion visible and polished without feeling slow.
    _handoffController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1180),
    );

    // Wait until Flutter has a visible first frame so the branded motion never
    // runs behind Android's native launch screen on a cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_start());
    });
  }

  Future<void> _start() async {
    if (!mounted || _starting) {
      return;
    }

    _starting = true;

    if (_startupError != null) {
      setState(() {
        _startupError = null;
      });
    }

    try {
      final initialization = widget.initialize();

      // The splash pieces are the only images allowed to gate the branded
      // animation. The Login header is warmed in parallel but is intentionally
      // not part of the critical wait, so a large header decode cannot stretch
      // the launcher beyond its intended short sequence.
      final splashWarmup = Future.wait<void>([
        precacheImage(
          const AssetImage('assets/images/isdalink_logo_body.png'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/isdalink_logo_wave.png'),
          context,
        ),
      ]);

      unawaited(
        precacheImage(
          const AssetImage('assets/images/isdalink_logo.png'),
          context,
        ),
      );
      unawaited(
        precacheImage(
          const AssetImage('assets/images/isdalink_main_header.png'),
          context,
        ),
      );

      // Preserve continuity with Android's native fish mark. The first portion
      // of the Flutter timeline remains fish-only, so no extra artificial wait
      // is needed here and the animation starts as soon as the frame is ready.
      await Future<void>.delayed(const Duration(milliseconds: 8));

      if (!mounted) {
        return;
      }

      final introAnimation = _introController.forward(from: 0);

      // If Firebase is slower than the brand animation, the completed logo
      // stays on-screen until initialization is ready instead of disappearing.
      await Future.wait([
        initialization,
        splashWarmup,
        introAnimation,
      ]);

      // Let the completed lockup register briefly before the page handoff.
      await Future<void>.delayed(const Duration(milliseconds: 180));

      if (!mounted) {
        return;
      }

      // Build the destination off-screen first so it is fully laid out and its
      // header image is ready before it starts sliding into view.
      setState(() {
        _destinationMounted = true;
      });

      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 18));

      if (!mounted) {
        return;
      }

      await _handoffController.forward(from: 0);

      if (!mounted) {
        return;
      }

      setState(() {
        _handoffComplete = true;
      });

      _scheduleDestinationCallback();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _startupError = error.toString();
        _destinationMounted = false;
        _handoffComplete = false;
      });

      _handoffController.reset();
    } finally {
      _starting = false;
    }
  }

  void _scheduleDestinationCallback() {
    if (_destinationCallbackScheduled || widget.onDestinationShown == null) {
      return;
    }

    _destinationCallbackScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(widget.onDestinationShown!());
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _handoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_handoffComplete) {
      return widget.destinationBuilder(context);
    }

    return AnimatedBuilder(
      animation: _handoffController,
      builder: (context, _) {
        final raw = _handoffController.value;
        // Long, soft deceleration: the page moves quickly enough at the
        // beginning to feel responsive, then gently settles at the top.
        final pageSlide = const Cubic(0.16, 0.82, 0.18, 1.00).transform(raw);
        final splashExit = const Cubic(0.32, 0.00, 0.18, 1.00).transform(raw);
        final size = MediaQuery.sizeOf(context);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Keep the completed splash underneath during the handoff. It
            // moves only a little upward and fades as Login visibly rises from
            // below, so the transition reads as one continuous premium motion.
            IgnorePointer(
              ignoring: _destinationMounted,
              child: Opacity(
                opacity: (1 - (0.82 * splashExit)).clamp(0.0, 1.0).toDouble(),
                child: Transform.translate(
                  offset: Offset(0, -38 * splashExit),
                  child: Transform.scale(
                    scale: 1 - (0.010 * splashExit),
                    child: _buildSplash(),
                  ),
                ),
              ),
            ),
            if (_destinationMounted)
              Opacity(
                opacity: (0.20 + (0.80 * pageSlide)).clamp(0.0, 1.0).toDouble(),
                child: Transform.translate(
                  offset: Offset(0, size.height * 0.18 * (1 - pageSlide)),
                  child: widget.destinationBuilder(context),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSplash() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFE9F7FB),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFD8F0F7),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFE9F7FB),
        body: AnimatedBuilder(
          animation: _introController,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _IceMarineBackground(progress: _introController.value),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _startupError == null
                          ? _SplashBrand(introController: _introController)
                          : _StartupErrorCard(onRetry: _start),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IceMarineBackground extends StatelessWidget {
  const _IceMarineBackground({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final gradientIn = Curves.easeOutCubic.transform(
      (progress / 0.16).clamp(0.0, 1.0).toDouble(),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFE9F7FB)),
        Opacity(
          opacity: gradientIn,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF3FBFD),
                  Color(0xFFE5F6FA),
                  Color(0xFFD8F0F7),
                ],
                stops: [0.0, 0.52, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashBrand extends StatelessWidget {
  const _SplashBrand({required this.introController});

  final AnimationController introController;

  static const double _logoWidth = 380;
  static const double _logoAspect = 2048 / 682;

  // Exact boundaries from the official IsdaLink PNG. The opening frame shows
  // only the fish, then the real wordmark and underline are revealed from the
  // same artwork so there is no font recreation or alignment jump.
  static const double _fishOnlyClip = 0.386;
  static const double _initialFishShift = 78;
  static const double _waveStart = 746 / 2048;
  static const double _waveEnd = 1666 / 2048;

  double _segment(double progress, double start, double end) {
    if (progress <= start) {
      return 0;
    }
    if (progress >= end) {
      return 1;
    }
    return (progress - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: introController,
      builder: (context, _) {
        final progress = introController.value;

        // Keep the fish alone at the beginning. On a cold launch, Android's
        // native fish plus this first ~0.8 s of Flutter gives roughly the
        // requested 1.5 s fish-only opening without wasting the rest of the
        // launcher. The remaining beats overlap so they feel smooth and premium.
        final fishSettle = Curves.easeOutCubic.transform(
          _segment(progress, 0.00, 0.12),
        );
        final fishTravel = Curves.easeInOutCubic.transform(
          _segment(progress, 0.26, 0.49),
        );
        final wordReveal = Curves.easeInOutCubic.transform(
          _segment(progress, 0.30, 0.68),
        );
        final waveReveal = Curves.easeInOutCubic.transform(
          _segment(progress, 0.57, 0.78),
        );
        final taglineIn = Curves.easeOutCubic.transform(
          _segment(progress, 0.70, 0.89),
        );
        final finalSettle = Curves.easeOutCubic.transform(
          _segment(progress, 0.82, 1.00),
        );

        final bodyRevealWidth =
            _fishOnlyClip + ((1 - _fishOnlyClip) * wordReveal);
        final horizontalShift = _initialFishShift * (1 - fishTravel);

        // Keep motion subtle. The fish should feel like it is finding its place,
        // not shrinking dramatically before the rest of the logo arrives.
        final settleScale = 0.988 + (0.012 * fishSettle);
        final finalScale = 1.006 - (0.006 * finalSettle);
        final combinedScale = settleScale * finalScale;
        final logoHeight = _logoWidth / _logoAspect;

        return Transform.translate(
          offset: Offset(0, -4 - (2 * finalSettle)),
          child: SizedBox(
            width: 410,
            height: 224,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 38,
                  left: 15,
                  right: 15,
                  height: logoHeight,
                  child: Transform.translate(
                    offset: Offset(horizontalShift, 0),
                    child: Transform.scale(
                      scale: combinedScale,
                      child: SizedBox(
                        width: _logoWidth,
                        height: logoHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRect(
                              clipper: _FractionalWidthClipper(
                                bodyRevealWidth,
                              ),
                              child: Image.asset(
                                'assets/images/isdalink_logo_body.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                gaplessPlayback: true,
                              ),
                            ),
                            ClipRect(
                              clipper: _RangeRevealClipper(
                                startFraction: _waveStart,
                                endFraction: _waveStart +
                                    ((_waveEnd - _waveStart) * waveReveal),
                              ),
                              child: Image.asset(
                                'assets/images/isdalink_logo_wave.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                gaplessPlayback: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 30,
                  child: Opacity(
                    opacity: taglineIn,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - taglineIn)),
                      child: const Text(
                        'FRESH CATCH, DIRECT SOURCE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF164E6C),
                          fontSize: 11.6,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.85,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FractionalWidthClipper extends CustomClipper<Rect> {
  const _FractionalWidthClipper(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) {
    final width = size.width * fraction.clamp(0.0, 1.0).toDouble();
    return Rect.fromLTWH(0, 0, width, size.height);
  }

  @override
  bool shouldReclip(covariant _FractionalWidthClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}

class _RangeRevealClipper extends CustomClipper<Rect> {
  const _RangeRevealClipper({
    required this.startFraction,
    required this.endFraction,
  });

  final double startFraction;
  final double endFraction;

  @override
  Rect getClip(Size size) {
    final start = size.width * startFraction.clamp(0.0, 1.0).toDouble();
    final end = size.width * endFraction.clamp(0.0, 1.0).toDouble();
    return Rect.fromLTRB(start, 0, end, size.height);
  }

  @override
  bool shouldReclip(covariant _RangeRevealClipper oldClipper) {
    return oldClipper.startFraction != startFraction ||
        oldClipper.endFraction != endFraction;
  }
}

class _StartupErrorCard extends StatelessWidget {
  const _StartupErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD3E6EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16062C43),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 38,
            color: Color(0xFF0875D1),
          ),
          const SizedBox(height: 14),
          const Text(
            'Unable to start IsdaLink',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF06283C),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Check your connection, then try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF69818E),
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF0875D1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
