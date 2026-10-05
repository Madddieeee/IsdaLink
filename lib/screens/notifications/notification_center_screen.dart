import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/services/notification_center_service.dart';
import 'package:isdalink/services/notification_navigation_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationCenterService service = const NotificationCenterService();
  bool unreadOnly = false;
  bool markingAllRead = false;
  String? selectedCategory;

  Future<void> markAllRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    if (markingAllRead || service.unreadCount(documents) == 0) {
      return;
    }

    setState(() {
      markingAllRead = true;
    });

    try {
      await service.markAllRead(documents);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications could not be updated. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          markingAllRead = false;
        });
      }
    }
  }

  Future<void> openNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = Map<String, dynamic>.from(document.data());
    data['notificationId'] = document.id;

    try {
      await service.markRead(document);
    } catch (_) {
      // The destination is still useful even if the read marker cannot update.
    }

    if (!mounted) {
      return;
    }

    final opened = NotificationNavigationService.openFromContext(
      context: context,
      data: data,
    );

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marked as read.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF06355F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFFF4F8FB),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        body: user == null
            ? _signedOutState(context)
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: service.userStream(user.uid),
                builder: (context, userSnapshot) {
                  final isSupplier = service.hasSupplierAccess(
                    userSnapshot.data?.data(),
                  );

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: service.notificationsStream(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _pageShell(
                          context,
                          children: const [
                            _MessageState(
                              icon: Icons.cloud_off_rounded,
                              title: 'Unable to load notifications',
                              message: 'Check your connection and try again.',
                            ),
                          ],
                        );
                      }

                      if (!snapshot.hasData) {
                        return _pageShell(
                          context,
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 90),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2.4),
                              ),
                            ),
                          ],
                        );
                      }

                      final sorted = service.sortedNotifications(
                        snapshot.data!.docs,
                      );
                      final all = service.visibleForAccess(
                        sorted,
                        isSupplier: isSupplier,
                      );
                      final effectiveCategory =
                          !isSupplier && selectedCategory == 'stock'
                              ? null
                              : selectedCategory;
                      final unreadCount = service.unreadCount(all);
                      final orderCount = all
                          .where(
                            (document) =>
                                service.categoryOf(document.data()) == 'orders',
                          )
                          .length;
                      final stockCount = all
                          .where(
                            (document) =>
                                service.categoryOf(document.data()) == 'stock',
                          )
                          .length;
                      final accountCount = all
                          .where(
                            (document) =>
                                service.categoryOf(document.data()) == 'account',
                          )
                          .length;

                      var visible = unreadOnly
                          ? all
                              .where(
                                (document) => document.data()['isRead'] != true,
                              )
                              .toList()
                          : List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                              all,
                            );

                      if (effectiveCategory != null) {
                        visible = visible
                            .where(
                              (document) =>
                                  service.categoryOf(document.data()) ==
                                  effectiveCategory,
                            )
                            .toList();
                      }

                      return _pageShell(
                        context,
                        controls: _NotificationControls(
                          unreadOnly: unreadOnly,
                          totalCount: all.length,
                          unreadCount: unreadCount,
                          markingAllRead: markingAllRead,
                          isSupplier: isSupplier,
                          selectedCategory: effectiveCategory,
                          orderCount: orderCount,
                          stockCount: stockCount,
                          accountCount: accountCount,
                          onAll: () => setState(() => unreadOnly = false),
                          onUnread: () => setState(() => unreadOnly = true),
                          onCategory: (category) {
                            setState(() {
                              selectedCategory = selectedCategory == category
                                  ? null
                                  : category;
                            });
                          },
                          onMarkAllRead: unreadCount == 0
                              ? null
                              : () => markAllRead(all),
                        ),
                        children: visible.isEmpty
                            ? [
                                _MessageState(
                                  icon: unreadOnly
                                      ? Icons.done_all_rounded
                                      : Icons.notifications_none_rounded,
                                  title: unreadOnly
                                      ? 'No matching unread updates'
                                      : 'No updates in this category',
                                  message: effectiveCategory == null
                                      ? 'New order and account updates will appear here.'
                                      : 'Choose another filter to see more updates.',
                                ),
                              ]
                            : _notificationGroups(visible),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _signedOutState(BuildContext context) {
    return _pageShell(
      context,
      children: const [
        _MessageState(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in to view notifications',
          message: 'Your IsdaLink updates are available after you sign in.',
        ),
      ],
    );
  }

  Widget _pageShell(
    BuildContext context, {
    Widget? controls,
    required List<Widget> children,
  }) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final headerHeight = topPadding + 178;
    final minimumSheetHeight =
        MediaQuery.sizeOf(context).height - headerHeight + 26;

    return ListView(
      padding: EdgeInsets.zero,
      physics: const ClampingScrollPhysics(),
      children: [
        Stack(
          children: [
            _header(context, topPadding),
            Padding(
              padding: EdgeInsets.only(top: headerHeight - 26),
              child: Container(
                clipBehavior: Clip.antiAlias,
                constraints: BoxConstraints(minHeight: minimumSheetHeight),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F8FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1900213D),
                      blurRadius: 20,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (controls != null) ...[
                      controls,
                      const SizedBox(height: 20),
                    ],
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _header(BuildContext context, double topPadding) {
    return SizedBox(
      height: topPadding + 178,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/order_center_caraga_header.png',
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
                Row(
                  children: [
                    _HeaderActionButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/images/isdalink_logo.png',
                            width: 92,
                            height: 31,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'NOTIFICATIONS',
                  style: TextStyle(
                    color: Color(0xFFD7EEFA),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Your Updates',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    shadows: [
                      Shadow(
                        color: Color(0x6600182B),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Orders and account updates in one place.',
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
    );
  }

  List<Widget> _notificationGroups(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final now = DateTime.now();
    final today = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final thisWeek = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final older = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final document in documents) {
      final date = _dateOf(document.data());

      if (date != null && _sameDay(date, now)) {
        today.add(document);
      } else if (date != null && now.difference(date).inDays < 7) {
        thisWeek.add(document);
      } else {
        older.add(document);
      }
    }

    final widgets = <Widget>[];
    void addGroup(
      String label,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
    ) {
      if (items.isEmpty) {
        return;
      }

      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 18));
      }

      widgets.add(_GroupLabel(label: label, count: items.length));
      widgets.add(const SizedBox(height: 8));

      for (var index = 0; index < items.length; index++) {
        widgets.add(
          _NotificationCard(
            document: items[index],
            onTap: () => openNotification(items[index]),
          ),
        );

        if (index != items.length - 1) {
          widgets.add(const SizedBox(height: 9));
        }
      }
    }

    addGroup('Today', today);
    addGroup('Earlier this week', thisWeek);
    addGroup('Older', older);

    return widgets;
  }

  DateTime? _dateOf(Map<String, dynamic> data) {
    final value = data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _NotificationControls extends StatelessWidget {
  const _NotificationControls({
    required this.unreadOnly,
    required this.totalCount,
    required this.unreadCount,
    required this.markingAllRead,
    required this.isSupplier,
    required this.selectedCategory,
    required this.orderCount,
    required this.stockCount,
    required this.accountCount,
    required this.onAll,
    required this.onUnread,
    required this.onCategory,
    required this.onMarkAllRead,
  });

  final bool unreadOnly;
  final int totalCount;
  final int unreadCount;
  final bool markingAllRead;
  final bool isSupplier;
  final String? selectedCategory;
  final int orderCount;
  final int stockCount;
  final int accountCount;
  final VoidCallback onAll;
  final VoidCallback onUnread;
  final ValueChanged<String> onCategory;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE9F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D00304D),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterButton(
                  label: 'All',
                  count: totalCount,
                  selected: !unreadOnly,
                  onTap: onAll,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterButton(
                  label: 'Unread',
                  count: unreadCount,
                  selected: unreadOnly,
                  onTap: onUnread,
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Mark all as read',
                child: Material(
                  color: const Color(0xFFEAF7FB),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onMarkAllRead,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: markingAllRead
                          ? const Padding(
                              padding: EdgeInsets.all(13),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.done_all_rounded,
                              color: onMarkAllRead == null
                                  ? const Color(0xFFAFC1CC)
                                  : const Color(0xFF0875D1),
                              size: 21,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Text(
            'Filter by type',
            style: TextStyle(
              color: Color(0xFF7890A1),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _CategoryFilterChip(
                label: 'Orders',
                count: orderCount,
                icon: Icons.receipt_long_rounded,
                selected: selectedCategory == 'orders',
                onTap: () => onCategory('orders'),
              ),
              if (isSupplier)
                _CategoryFilterChip(
                  label: 'Stock',
                  count: stockCount,
                  icon: Icons.inventory_2_outlined,
                  selected: selectedCategory == 'stock',
                  onTap: () => onCategory('stock'),
                ),
              _CategoryFilterChip(
                label: 'Account',
                count: accountCount,
                icon: Icons.person_outline_rounded,
                selected: selectedCategory == 'account',
                onTap: () => onCategory('account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE5F4FD) : Colors.white,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? const Color(0xFF67B9E8)
                  : const Color(0xFFD5E3EB),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? const Color(0xFF0875D1)
                    : const Color(0xFF5E7585),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF0875D1)
                      : const Color(0xFF40596A),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF0875D1)
                        : const Color(0xFF8296A4),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF0875D1) : const Color(0xFFF4F8FB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF3F586A),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withAlpha(36)
                      : const Color(0xFFE3EDF3),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF587080),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF102C44),
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(
            color: Color(0xFF7B8FA0),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.document, required this.onTap});

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final title = _value(data, 'title', 'IsdaLink update');
    final message = _value(data, 'message', 'You have a new update.');
    final type = _value(data, 'type', '').toLowerCase();
    final status = _value(data, 'status', '').toLowerCase();
    final unread = data['isRead'] != true;
    final appearance = _appearance(type: type, status: status, data: data);

    return Material(
      color: unread ? const Color(0xFFF2FAFF) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread
                  ? const Color(0xFFCBE9F7)
                  : const Color(0xFFDDE8EF),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    appearance.icon,
                    color: appearance.foreground,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (unread) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0875D1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _relativeTime(data['createdAt']),
                          style: const TextStyle(
                            color: Color(0xFF8A9BA9),
                            fontSize: 8.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF60778A),
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Text(
                          _actionLabel(type),
                          style: TextStyle(
                            color: appearance.foreground,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: appearance.foreground,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _NotificationAppearance _appearance({
    required String type,
    required String status,
    required Map<String, dynamic> data,
  }) {
    if (type == 'stock_alert') {
      final stockStatus = _value(data, 'stockStatus', '').toLowerCase();
      if (stockStatus == 'outofstock' || stockStatus == 'out_of_stock') {
        return const _NotificationAppearance(
          icon: Icons.inventory_2_outlined,
          foreground: Color(0xFFD94A3A),
        );
      }
      return const _NotificationAppearance(
        icon: Icons.warning_amber_rounded,
        foreground: Color(0xFFE48A00),
      );
    }

    if (status == 'approved' ||
        status == 'accepted' ||
        status == 'delivered' ||
        status == 'completed') {
      return const _NotificationAppearance(
        icon: Icons.check_circle_outline_rounded,
        foreground: Color(0xFF159A6F),
      );
    }

    if (status == 'rejected' ||
        status == 'declined' ||
        status == 'cancelled') {
      return const _NotificationAppearance(
        icon: Icons.error_outline_rounded,
        foreground: Color(0xFFD94A3A),
      );
    }

    if (type == 'new_order') {
      return const _NotificationAppearance(
        icon: Icons.receipt_long_rounded,
        foreground: Color(0xFF0875D1),
      );
    }

    if (type == 'supplier_application_status' ||
        type == 'supplier_profile_change') {
      return const _NotificationAppearance(
        icon: Icons.storefront_outlined,
        foreground: Color(0xFF0875D1),
      );
    }

    return const _NotificationAppearance(
      icon: Icons.notifications_none_rounded,
      foreground: Color(0xFF0875D1),
    );
  }

  static String _actionLabel(String type) {
    switch (type) {
      case 'new_order':
        return 'View order';
      case 'order_status':
        return 'View order';
      case 'stock_alert':
        return 'Manage stock';
      case 'supplier_application_status':
        return 'View update';
      case 'supplier_profile_change':
        return 'View profile';
      default:
        return 'View update';
    }
  }

  static String _value(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  static String _relativeTime(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    }

    if (date == null) {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }
}

class _NotificationAppearance {
  const _NotificationAppearance({
    required this.icon,
    required this.foreground,
  });

  final IconData icon;
  final Color foreground;
}

class _MessageState extends StatelessWidget {
  const _MessageState({
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
      margin: const EdgeInsets.only(top: 36),
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE8EF)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF0875D1), size: 34),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF718696),
              fontSize: 10.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withAlpha(38),
        shape: CircleBorder(
          side: BorderSide(color: Colors.white.withAlpha(76)),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: Colors.white, size: 25),
          ),
        ),
      ),
    );
  }
}
