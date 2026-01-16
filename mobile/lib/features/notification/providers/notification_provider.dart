import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../models/notification_model.dart';

final notificationsProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<Notification>>>((ref) {
  return NotificationNotifier(ref);
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<Notification>>> {
  final Ref _ref;

  NotificationNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get('/notifications');
      final List<dynamic> data = response.data;
      final notifications = data.map((json) => Notification.fromJson(json)).toList();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put('/notifications/$id/read');
      
      // Optimistic update
      state.whenData((notifications) {
        state = AsyncValue.data(notifications.map((n) {
          if (n.id == id) {
             return Notification(
               id: n.id,
               title: n.title,
               body: n.body,
               data: n.data,
               isRead: true,
               createdAt: n.createdAt,
             );
          }
          return n;
        }).toList());
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put('/notifications/read-all');
       state.whenData((notifications) {
        state = AsyncValue.data(notifications.map((n) {
             return Notification(
               id: n.id,
               title: n.title,
               body: n.body,
               data: n.data,
               isRead: true,
               createdAt: n.createdAt,
             );
        }).toList());
      });
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }
}
