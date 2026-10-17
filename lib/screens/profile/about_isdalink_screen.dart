import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutIsdaLinkScreen extends StatelessWidget {
  const AboutIsdaLinkScreen({super.key});

  static const Color ink = Color(0xFF102C44);
  static const Color muted = Color(0xFF6F8495);
  static const Color blue = Color(0xFF087AC0);
  static const Color surface = Color(0xFFF7FAFC);

  Widget header(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return SizedBox(
      height: topPadding + 176,
      child: Stack(
        children: [
          Positioned.fill(
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
                        colors: [Color(0xFF075489), Color(0xFF079AC7)],
                      ),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x52001E38), Color(0xCE002B4E)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, topPadding + 8, 18, 38),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withAlpha(28),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withAlpha(52),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Image.asset(
                      'assets/images/isdalink_logo.png',
                      width: 92,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text(
                        'IsdaLink',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'OUR PROJECT',
                  style: TextStyle(
                    color: Color(0xFFD7EEFA),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.7,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'About IsdaLink',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.55,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Connecting fish vendors and suppliers across Caraga.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFE2F4FA),
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: blue, size: 21),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget feature(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Icon(icon, color: blue, size: 19),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10.5,
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

  Widget developer({
    required String name,
    required String initials,
    String? photoAsset,
  }) {
    final initialsLabel = Text(
      initials,
      style: const TextStyle(
        color: blue,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6FC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCBEAF6), width: 2),
            ),
            child: photoAsset == null
                ? initialsLabel
                : ClipOval(
                    child: Image.asset(
                      photoAsset,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) =>
                          Center(child: initialsLabel),
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Developer and Researcher',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10.5,
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: surface,
        body: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: header(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: Image.asset(
                      'assets/images/isdalink_logo.png',
                      width: 132,
                      height: 58,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Design and Development of a Mobile-Based Fish Supply '
                    'Management System with Sales Analytics for '
                    'Vendor–Supplier Coordination in the Caraga Region',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  sectionTitle('Why we built IsdaLink', Icons.lightbulb_outline),
                  const SizedBox(height: 9),
                  const Text(
                    'IsdaLink began with a challenge faced by the family of '
                    'one of its developers, Ibhan Gardiola Calubag. Their '
                    'fish store had difficulties contacting and finding '
                    'other fish suppliers.\n\n'
                    'We built IsdaLink to help not only their family, but '
                    'also other fish vendors and suppliers across the Caraga '
                    'Region. By bringing supplier discovery, stock '
                    'information, and sales-based guidance together, the '
                    'system aims to make coordination and restocking '
                    'decisions easier.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11.5,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Divider(color: Color(0xFFDCE8EF), height: 1),
                  const SizedBox(height: 20),
                  sectionTitle('What IsdaLink provides', Icons.hub_outlined),
                  const SizedBox(height: 5),
                  feature(
                    Icons.storefront_outlined,
                    'Vendor–supplier coordination',
                    'Discover approved suppliers and view available fish stocks.',
                  ),
                  feature(
                    Icons.inventory_2_outlined,
                    'Fish inventory and order management',
                    'Manage fish listings, monitor stock, and track orders.',
                  ),
                  feature(
                    Icons.insights_outlined,
                    'Sales analytics and restocking guidance',
                    'View weekly and monthly trends, forecasts, and restocking suggestions.',
                  ),
                  const SizedBox(height: 13),
                  const Divider(color: Color(0xFFDCE8EF), height: 1),
                  const SizedBox(height: 20),
                  sectionTitle('Developed by', Icons.groups_2_outlined),
                  const SizedBox(height: 5),
                  developer(name: 'Jon Carlo S. Albarida', initials: 'JA'),
                  const Divider(
                    color: Color(0xFFE4EDF2),
                    height: 1,
                    indent: 67,
                  ),
                  developer(
                    name: 'Ibhan Gardiola Calubag',
                    initials: 'IC',
                    photoAsset: 'assets/images/ibhan_gardiola_calubag_avatar.jpg',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Created for fish vendors and suppliers in the Caraga Region.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 10.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
