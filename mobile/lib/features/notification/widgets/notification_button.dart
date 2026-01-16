import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';

class NotificationButton extends ConsumerWidget {
  final Color? color;

  const NotificationButton({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: color ?? Colors.black87),
          onPressed: () => context.push('/notifications'),
        ),
        // Unread Badge
        Consumer(
          builder: (context, ref, child) {
            final notifications = ref.watch(notificationsProvider).valueOrNull ?? [];
            final unreadCount = notifications.where((n) => !n.isRead).length;
            if (unreadCount == 0) return const SizedBox.shrink();
            
            return Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 8,
                  minHeight: 8,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
