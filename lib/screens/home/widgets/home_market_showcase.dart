import 'dart:async';

import 'package:flutter/material.dart';

class HomeMarketShowcase extends StatefulWidget {
  const HomeMarketShowcase({
    super.key,
    required this.onBrowseSuppliers,
    required this.onBrowseFishStocks,
  });

  final VoidCallback onBrowseSuppliers;
  final VoidCallback onBrowseFishStocks;

  @override
  State<HomeMarketShowcase> createState() => _HomeMarketShowcaseState();
}

class _HomeMarketShowcaseState extends State<HomeMarketShowcase> {
  static const Duration _rotationInterval = Duration(milliseconds: 4500);
  static const Duration _slideDuration = Duration(milliseconds: 600);

  Timer? _rotationTimer;
  late final PageController _bannerController;
  int _bannerIndex = 0;

  static const _bannerSlides = <_HomeBannerSlide>[
    _HomeBannerSlide(
      title: 'Trusted suppliers\nacross Caraga.',
      subtitle:
          'Find verified fish suppliers\nand explore their available products.',
      buttonLabel: 'Browse suppliers',
      assetIconPath: 'assets/images/Store.png',
    ),
    _HomeBannerSlide(
      title: 'Fresh fish stocks\nready to explore.',
      subtitle: 'See the latest fish posted\nby suppliers across Caraga.',
      buttonLabel: 'Browse fish stocks',
      assetIconPath: 'assets/images/Fish.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController(initialPage: 1000);
    _scheduleNextSlide();
  }

  void _scheduleNextSlide() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer(_rotationInterval, () {
      if (!mounted || !_bannerController.hasClients) {
        return;
      }

      final currentPage = _bannerController.page?.round() ?? 1000;
      _bannerController.animateToPage(
        currentPage + 1,
        duration: _slideDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  bool _handleBannerScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _rotationTimer?.cancel();
    } else if (notification is ScrollEndNotification) {
      _scheduleNextSlide();
    }

    return false;
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _openBannerAction(int index) {
    if (index == 0) {
      widget.onBrowseSuppliers();
      return;
    }

    widget.onBrowseFishStocks();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: SizedBox(
            height: 188,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/home_ocean_banner.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: const [0.0, 0.58, 1.0],
                          colors: [
                            const Color(0xFF003853).withValues(alpha: .90),
                            const Color(0xFF006C8F).withValues(alpha: .56),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(17, 17, 17, 16),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleBannerScroll,
                      child: PageView.builder(
                        controller: _bannerController,
                        physics: const PageScrollPhysics(),
                        onPageChanged: (page) {
                          setState(() {
                            _bannerIndex = page % _bannerSlides.length;
                          });
                          _scheduleNextSlide();
                        },
                        itemBuilder: (context, page) {
                          final index = page % _bannerSlides.length;

                          return _BannerContent(
                            key: ValueKey(page),
                            slide: _bannerSlides[index],
                            onPressed: () => _openBannerAction(index),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 17,
                    bottom: 33,
                    child: IgnorePointer(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _bannerSlides.length,
                          (index) => Container(
                            width: 15,
                            height: 6,
                            margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
                            alignment: Alignment.center,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: index == _bannerIndex ? 15 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: index == _bannerIndex
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: .48),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({
    super.key,
    required this.slide,
    required this.onPressed,
  });

  final _HomeBannerSlide slide;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 41,
          child: FractionallySizedBox(
            alignment: Alignment.topLeft,
            widthFactor: .70,
            child: Text(
              slide.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 48,
          child: FractionallySizedBox(
            alignment: Alignment.topLeft,
            widthFactor: .64,
            child: Text(
              slide.subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFD5F2FA),
                fontSize: 11.6,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 166,
          height: 40,
          child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF08A9D2),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            icon: Image.asset(
              slide.assetIconPath,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(width: 18, height: 18),
            ),
            label: Text(
              slide.buttonLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeBannerSlide {
  const _HomeBannerSlide({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.assetIconPath,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final String assetIconPath;
}

class HomeMarketFooter extends StatelessWidget {
  const HomeMarketFooter({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFDDF3FC),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      children: [
        Icon(Icons.waves, color: Color(0xFF0AB2D3), size: 36),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Fresh connections.\nStronger communities.',
            style: TextStyle(
              color: Color(0xFF123452),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(Icons.handshake_outlined, color: Color(0xFF098FB6)),
      ],
    ),
  );
}
