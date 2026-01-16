import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../models/post_model.dart';
import '../repositories/feed_repository.dart';
import '../../auth/providers/auth_provider.dart';

// Feed Notifier for Stale-While-Revalidate & Optimistic Updates
final feedProvider = AsyncNotifierProvider<FeedNotifier, List<Post>>(() {
  return FeedNotifier();
});

class FeedNotifier extends AsyncNotifier<List<Post>> {
  late FeedRepository _repository;

  @override
  Future<List<Post>> build() async {
    _repository = ref.watch(feedRepositoryProvider);
    return _loadFeed();
  }

  Future<List<Post>> _loadFeed() async {
    // 1. Load Local
    final localData = await _repository.getFeed();
    final localPosts = localData.map((e) {
      if (e is Map) {
         return Post.fromJson(Map<String, dynamic>.from(e));
      }
      return null;
    }).whereType<Post>().toList();
    
    // If we have local data, we can yield it immediately, 
    // but build() expects a return value. 
    // We can just return it, and trigger a sync in the background.
    
    // Trigger background sync (fire and forget or safe await)
    _syncFeed();
    
    return localPosts;
  }

  Future<void> _syncFeed() async {
    try {
      final remoteData = await _repository.syncFeed();
      final remotePosts = remoteData.map((e) => Post.fromJson(e)).toList();
      state = AsyncValue.data(remotePosts);
    } catch (e) {
      // If sync fails, we just keep the local data.
      // Optionally handle error state if local was empty.
      if (state.valueOrNull?.isEmpty ?? true) {
         state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _syncFeed();
  }

  // Debounce map to track timers per postId
  final Map<String, Timer> _likeDebounceTimers = {};

  // Optimistic Like with Debouncing
  Future<void> toggleLike(String postId) async {
    final currentPosts = state.valueOrNull ?? [];
    
    // 1. Get Current User ID
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return; 
    final currentUserId = currentUser.firebaseUid;

    // 2. Find post index
    final postIndex = currentPosts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = currentPosts[postIndex];

    // 3. Optimistic Update Logic (Instant UI)
    final hasLiked = post.likes.contains(currentUserId);
    final updatedLikes = List<String>.from(post.likes);
    
    if (hasLiked) {
      updatedLikes.remove(currentUserId);
    } else {
      updatedLikes.add(currentUserId);
    }

    final updatedPost = post.copyWith(likes: updatedLikes);
    final updatedPosts = List<Post>.from(currentPosts);
    updatedPosts[postIndex] = updatedPost;
    
    state = AsyncValue.data(updatedPosts);

    // 4. Debounced API Call (Prevent flooding on double-tap/spam)
    _likeDebounceTimers[postId]?.cancel();
    _likeDebounceTimers[postId] = Timer(const Duration(milliseconds: 500), () async {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.post('/feed/$postId/like'); 
        _likeDebounceTimers.remove(postId);
      } catch (e) {
        print('Error syncing like for $postId: $e');
        // Revert to server state or previous local state if needed
        // For now, let's just log. A full revert might be jarring if other things changed.
      }
    });
  }

  Future<void> addComment(String postId, String text) async {
    final apiClient = ref.read(apiClientProvider);
    try {
       await apiClient.post('/feed/$postId/comment', data: {'text': text});
       // Ideally refresh the specific post or the whole feed
       // For now, refreshing feed is safest to see new comment count if displayed
       await _loadFeed(); 
    } catch (e) {
      print('Error commenting: $e');
      rethrow;
    }
  }

  Future<void> replyToComment(String postId, String commentId, String text) async {
    final apiClient = ref.read(apiClientProvider);
    try {
       await apiClient.post('/feed/$postId/comment/$commentId/reply', data: {'text': text});
       // Refresh feed to update UI
       await _loadFeed(); 
    } catch (e) {
      print('Error replying: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    final currentPosts = state.valueOrNull ?? [];
    // Optimistic Remove
    state = AsyncValue.data(currentPosts.where((p) => p.id != postId).toList());

    try {
       await _repository.deletePost(postId); 
    } catch (e) {
      print('Error deleting: $e');
      state = AsyncValue.data(currentPosts); // Revert
      rethrow;
    }
  }

  Future<void> archivePost(String postId) async {
    final currentPosts = state.valueOrNull ?? [];
    // Optimistic Remove (since we filter out archived posts in the feed)
    state = AsyncValue.data(currentPosts.where((p) => p.id != postId).toList());

    try {
       await _repository.archivePost(postId); 
    } catch (e) {
      print('Error archiving: $e');
      state = AsyncValue.data(currentPosts); // Revert
      rethrow;
    }
  }

  Future<void> editPost(String postId, String newContent) async {
    final currentPosts = state.valueOrNull ?? [];
    final index = currentPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final oldPost = currentPosts[index];
    // Optimistic Update
    final newPost = oldPost.copyWith(content: newContent);
    // Note: We don't verify edit history optimistically here as we'd need to mock the date etc
    
    final updatedPosts = List<Post>.from(currentPosts);
    updatedPosts[index] = newPost;
    state = AsyncValue.data(updatedPosts);

    try {
       await _repository.editPost(postId, newContent);
       await _loadFeed(); // Reload nicely to get the updated history clean
    } catch (e) {
      print('Error editing: $e');
      state = AsyncValue.data(currentPosts); // Revert
      rethrow;
    }
  }
}

// Create Post Provider
// Using AsyncNotifier which is the modern Riverpod 2.0 way
// Create Post Provider
// Keep alive to prevent disposal during async operations if not watched
final createPostProvider = AsyncNotifierProvider<CreatePostNotifier, void>(CreatePostNotifier.new);

class CreatePostNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is void (null), meaning "idle"
    return null;
  }

  Future<bool> createPost({
    required String content,
    List<String> imageUrls = const [],
    String visibility = 'public',
  }) async {
    // Set loading state
    state = const AsyncValue.loading();
    
    // Perform operation
    // Perform operation
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post('/feed/create', data: {
        'content': content,
        'imageUrls': imageUrls,
        'visibility': visibility,
      });

      // On success
      state = const AsyncValue.data(null);
    } catch (e, st) {
      // On error
      state = AsyncValue.error(e, st);
    }

    if (state.hasError) {
      return false;
    }
    
    // Refresh the feed on success
    ref.refresh(feedProvider);
    return true;
  }
}
