import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

// Model would ideally be imported here. 
// For now, using dynamic/Map or assuming a Post model exists.
// Adjust import based on actual Post model location.

class FeedRepository {
  final Dio _dio;
  final Box _box;

  FeedRepository(this._dio, this._box);

  // Get feed from local cache first, then sync
  Future<List<dynamic>> getFeed() async {
    // 1. Return Local Data
    final localData = _box.get('feed', defaultValue: []);
    // Note: If localData is not in the desired List<Post> format, 
    // mapping would happen here. Returning as is for now.
    return localData is List ? localData : [];
  }

  // Sync with server
  Future<List<dynamic>> syncFeed() async {
    try {
      // Replace with your actual endpoint
      final response = await _dio.get('/feed'); 
      
      final data = response.data;
      if (data is List) {
        // Save to Hive
        await _box.put('feed', data);
        return data;
      }
      return [];
    } catch (e) {
      // On error, we rely on what we have or rethrow if critical
      rethrow;
    }
  }
  // Get user specific posts
  Future<List<dynamic>> getUserFeed(String userId) async {
    try {
      final response = await _dio.get('/feed/user/$userId');
      final data = response.data;
      if (data is List) {
        return data; 
      }
      return [];
    } catch (e) {
      // Return empty list on error for now
      return [];
    }
  }

  Future<void> deletePost(String postId) async {
    await _dio.post('/feed/$postId/delete');
  }

  Future<void> archivePost(String postId) async {
    await _dio.post('/feed/$postId/archive');
  }

  Future<void> editPost(String postId, String content) async {
    await _dio.post('/feed/$postId/edit', data: {'content': content});
  }

  Future<List<dynamic>> getPostHistory(String postId) async {
    try {
      final response = await _dio.get('/feed/$postId/history');
      final data = response.data;
      if (data is List) return data;
      return [];
    } catch (e) {
      return [];
    }
  }
}

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final box = Hive.box('feed_cache');
  return FeedRepository(apiClient.dio, box);
});
