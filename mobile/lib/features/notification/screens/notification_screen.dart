import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../providers/notification_provider.dart';
import '../../../../core/widgets/cached_avatar.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.blue),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref.read(notificationsProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
               return await ref.refresh(notificationsProvider.notifier).fetchNotifications();
            },
            color: Theme.of(context).primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(context, ref, notification);
              },
            ),
          );
        },
        loading: () => _buildSkeletonLoader(),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, dynamic notification) {
    bool isUnread = !notification.isRead;
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // TODO: Implement delete
      },
      child: GestureDetector(
        onTap: () {
          if (isUnread) {
            ref.read(notificationsProvider.notifier).markAsRead(notification.id);
          }
          // Navigate based on data type if needed
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFFF0F2F5) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            ),
            boxShadow: [
              if (isUnread)
                BoxShadow(
                  color: Colors.blue.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildIcon(notification.title),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeago.format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String title) {
    IconData iconData = Icons.notifications_rounded;
    Color color = Colors.blue;
    
    if (title.contains('Message')) {
      iconData = Icons.chat_bubble_rounded;
      color = Colors.green;
    } else if (title.contains('Match')) {
      iconData = Icons.favorite_rounded;
      color = Colors.pink;
    } else if (title.contains('Request')) {
      iconData = Icons.person_add_rounded;
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }
  
  Widget _buildEmptyState() {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Container(
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: Colors.blue.withOpacity(0.1),
               shape: BoxShape.circle,
             ),
             child: const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.blue),
           ),
           const SizedBox(height: 16),
           const Text(
             'No notifications yet',
             style: TextStyle(
               fontSize: 18, 
               fontWeight: FontWeight.bold,
               color: Colors.black87
             ),
           ),
           const SizedBox(height: 8),
           const Text(
             'We\'ll notify you when something happens!',
             style: TextStyle(color: Colors.black54),
           ),
         ],
       ),
     );
  }

  Widget _buildSkeletonLoader() {
    return Skeletonizer(
      enabled: true,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
             child: Row(
              children: [
                const CircleAvatar(radius: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 10, width: 100, color: Colors.grey),
                      const SizedBox(height: 8),
                      Container(height: 10, width: 200, color: Colors.grey),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
