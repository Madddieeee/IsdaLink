import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/services/notification_center_service.dart';

class HomeNotificationButton extends StatelessWidget {
  const HomeNotificationButton({
    super.key,
    required this.userId,
    required this.onTap,
    this.compact = false,
    this.pinned = false,
  });

  final String userId;
  final VoidCallback onTap;
  final bool compact;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final size = pinned ? 38.0 : (compact ? 38.0 : 42.0);
    final iconSize = pinned ? 19.0 : (compact ? 19.0 : 21.0);
    const service = NotificationCenterService();

    Widget buildButton(int unreadCount) {
      final label = unreadCount > 9 ? '9+' : '$unreadCount';

      return Tooltip(
        message: unreadCount == 0
            ? 'Notifications'
            : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: pinned
                  ? const Color(0xFFEAF7FB)
                  : Colors.white.withAlpha(242),
              shape: CircleBorder(
                side: pinned
                    ? const BorderSide(color: Color(0xFFCDE7F0))
                    : BorderSide.none,
              ),
              elevation: pinned ? 0 : 0.5,
              shadowColor: const Color(0x16001D33),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: pinned
                        ? const Color(0xFF075C9B)
                        : const Color(0xFF0B3658),
                    size: iconSize,
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: EdgeInsets.symmetric(
                    horizontal: unreadCount > 9 ? 4.5 : 4,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4B4B),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (userId.trim().isEmpty) {
      return buildButton(0);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: service.userStream(userId),
      builder: (context, userSnapshot) {
        final isSupplier = service.hasSupplierAccess(userSnapshot.data?.data());

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.notificationsStream(userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return buildButton(0);
            }

            final visible = service.visibleForAccess(
              snapshot.data!.docs,
              isSupplier: isSupplier,
            );
            final unread = service.unreadCount(visible);

            return buildButton(unread);
          },
        );
      },
    );
  }
}
