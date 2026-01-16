import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/api_client.dart';
import '../services/chat_cache_service.dart';

// Models
class Conversation {
  final String id;
  final String lastMessage;
  final DateTime lastMessageAt;
  final ChatUser otherUser;

  Conversation({
    required this.id,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.otherUser,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt']) 
          : DateTime.now(),
      otherUser: ChatUser.fromJson(json['otherUser'] ?? {}),
    );
  }
}

class ChatUser {
  final String id;
  final String name;
  final String photo;

  ChatUser({required this.id, required this.name, required this.photo});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      photo: json['photo'] ?? '',
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String content;
  final String type; // text, image
  final String? imageUrl;
  final String status; // sent, delivered, seen
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.type,
    this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'sent',
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']) 
              : DateTime.parse(json['createdAt'])) 
          : DateTime.now(),
    );
  }
}

// Providers
final chatStreamProvider = StreamProvider.family.autoDispose<List<Message>, String>((ref, conversationId) {
  final db = FirebaseDatabase.instance.ref('chats/$conversationId/messages');
  final cacheService = ChatCacheService();
  
  return db.onValue.map((event) {
    if (event.snapshot.value == null) return [];
    
    final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
    final List<Message> messages = [];
    
    data.forEach((key, value) {
      final map = Map<String, dynamic>.from(value as Map);
      messages.add(Message(
        id: key,
        senderId: map['senderId'] ?? '',
        content: map['content'] ?? '',
        type: map['type'] ?? 'text',
        imageUrl: map['imageUrl'],
        status: map['status'] ?? 'sent',
        createdAt: map['createdAt'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
            : DateTime.now(),
      ));
    });
    
    // Sort by creation time
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    // Cache messages in background (fire and forget)
    Future.microtask(() async {
      final messageMaps = messages.map((m) => {
        'id': m.id,
        'senderId': m.senderId,
        'content': m.content,
        'type': m.type,
        'imageUrl': m.imageUrl,
        'status': m.status,
        'createdAt': m.createdAt.toIso8601String(),
      }).toList();
      await cacheService.saveMessages(conversationId, messageMaps);
    });
    
    return messages;
  });
});

// Conversations Provider with Caching
class ConversationsNotifier extends AutoDisposeAsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    // 1. Load from cache immediately
    final cacheService = ChatCacheService();
    final cached = cacheService.getConversations();
    
    if (cached != null && cached.isNotEmpty) {
      state = AsyncValue.data(cached.map((e) => Conversation.fromJson(e)).toList());
    }

    // 2. Fetch fresh data from API
    try {
      final apiClient = ref.watch(apiClientProvider);
      final response = await apiClient.get('/chat/conversations');
      final data = response.data as List;
      final conversations = data.map((e) => Conversation.fromJson(e)).toList();
      
      // 3. Update cache
      await cacheService.saveConversations(data.map((e) => Map<String, dynamic>.from(e)).toList());
      
      return conversations;
    } catch (e) {
      // If fetch fails but we have cache, return cached data
      if (cached != null && cached.isNotEmpty) {
        return cached.map((e) => Conversation.fromJson(e)).toList();
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

final chatConversationsProvider = AsyncNotifierProvider.autoDispose<ConversationsNotifier, List<Conversation>>(() {
  return ConversationsNotifier();
});

final chatMessagesProvider = FutureProvider.family.autoDispose<List<Message>, String>((ref, conversationId) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.get('/chat/messages/$conversationId');
    final data = response.data as List;
    return data.map((e) => Message.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
});

class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ChatNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> sendMessage(String targetId, String content, {String type = 'text', String? imageUrl}) async {
    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post('/chat/send', data: {
        'targetId': targetId,
        'content': content,
        'type': type,
        'imageUrl': imageUrl,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post('/chat/read/$conversationId');
    } catch (e) {
      // Silently fail for read receipts
      print('Failed to mark as read: $e');
    }
  }

  Future<String?> uploadImage(String filePath) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      
      // 1. Get Presigned URL
      final response = await apiClient.post('/upload/presigned-url', data: {
        'mimeType': 'image/jpeg', // Simplified for now
      });
      
      final String uploadUrl = response.data['uploadUrl'];
      final String publicUrl = response.data['publicUrl'];

      // 2. Upload to R2 (Cloudflare) via PUT
      final file = File(filePath);
      await Dio().put(
        uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            'Content-Type': 'image/jpeg',
            'Content-Length': await file.length(),
          },
        ),
      );

      return publicUrl;
    } catch (e) {
      print('Upload failed: $e');
      return null;
    }
  }
}

final chatActionProvider = StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  return ChatNotifier(ref);
});
