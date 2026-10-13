import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/home/widgets/home_notification_button.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onLogout,
    required this.onSearchTap,
    this.onProfileTap,
    this.onNotificationsTap,
    this.userId = '',
    this.onSuppliersTap,
    this.onFishStocksTap,
    this.onActiveOrdersTap,
  });

  final VoidCallback onLogout;
  final VoidCallback onSearchTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final String userId;
  final VoidCallback? onSuppliersTap;
  final VoidCallback? onFishStocksTap;
  final VoidCallback? onActiveOrdersTap;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final coverHeight = topPadding + 178;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF06355F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: SizedBox(
        height: coverHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/isdalink_main_header.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, _, _) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF06355F), Color(0xFF0875D1)],
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x5C001E38), Color(0xC900294A)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, topPadding + 10, 18, 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBrandRow(
                    onProfileTap: onProfileTap,
                    onNotificationsTap: onNotificationsTap,
                    userId: userId,
                  ),
                  const Spacer(),
                  const Text(
                    'FRESH FROM CARAGA',
                    style: TextStyle(
                      color: Color(0xFFD7EEFA),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const _HeaderMessageText(),
                  const SizedBox(height: 5),
                  const Text(
                    'Discover local suppliers and today\'s catch.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFFF1FAFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

class _TopBrandRow extends StatelessWidget {
  const _TopBrandRow({
    required this.onProfileTap,
    required this.onNotificationsTap,
    required this.userId,
  });

  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Image.asset(
            'assets/images/isdalink_logo.png',
            width: 112,
            height: 38,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => const Text(
              'IsdaLink',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          HomeNotificationButton(
            userId: userId,
            onTap: onNotificationsTap ?? () {},
            compact: true,
            roundedSquare: true,
          ),
          const SizedBox(width: 8),
          _HeaderActionButton(
            tooltip: 'My profile',
            icon: Icons.person_rounded,
            onTap: onProfileTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderMessageText extends StatelessWidget {
  const _HeaderMessageText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Your local fish market',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white,
        fontSize: 27,
        height: 1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.35,
        shadows: [
          Shadow(
            color: Color(0x6600182B),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withAlpha(242),
        borderRadius: BorderRadius.circular(13),
        elevation: 0.5,
        shadowColor: const Color(0x16001D33),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: const Color(0xFF0B3658), size: 20),
          ),
        ),
      ),
    );
  }
}

class HomeHeaderSearch extends StatelessWidget {
  const HomeHeaderSearch({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width <= 400;
    final searchHeight = compact ? 47.0 : 50.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF9CD6EA), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22004B73),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: double.infinity,
            height: searchHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 15 : 17),
              child: Row(
                children: [
                  Container(
                    width: compact ? 31 : 33,
                    height: compact ? 31 : 33,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE4F5FC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: const Color(0xFF007EAF),
                      size: compact ? 19 : 20,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Text(
                      'Search fish, suppliers, or locations',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF506A7D),
                        fontSize: compact ? 10.9 : 11.7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF1598C4),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
