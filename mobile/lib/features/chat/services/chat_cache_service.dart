import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class ChatCacheService {
  static const String _conversationsBox = 'conversations_cache';
  static const String _messagesBox = 'chat_messages_cache';

  // Conversations Cache
  Future<void> saveConversations(List<Map<String, dynamic>> conversations) async {
    final box = Hive.box(_conversationsBox);
    await box.put('conversations', jsonEncode(conversations));
  }

  List<Map<String, dynamic>>? getConversations() {
    final box = Hive.box(_conversationsBox);
    final data = box.get('conversations');
    if (data == null) return null;
    
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Messages Cache (per conversation)
  Future<void> saveMessages(String conversationId, List<Map<String, dynamic>> messages) async {
    final box = Hive.box(_messagesBox);
    // Store last 50 messages only
    final messagesToCache = messages.length > 50 ? messages.sublist(0, 50) : messages;
    await box.put(conversationId, jsonEncode(messagesToCache));
  }

  List<Map<String, dynamic>>? getMessages(String conversationId) {
    final box = Hive.box(_messagesBox);
    final data = box.get(conversationId);
    if (data == null) return null;
    
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Clear cache
  Future<void> clearConversationsCache() async {
    final box = Hive.box(_conversationsBox);
    await box.clear();
  }

  Future<void> clearMessagesCache(String conversationId) async {
    final box = Hive.box(_messagesBox);
    await box.delete(conversationId);
  }

  Future<void> clearAllCache() async {
    await clearConversationsCache();
    final box = Hive.box(_messagesBox);
    await box.clear();
  }
}
