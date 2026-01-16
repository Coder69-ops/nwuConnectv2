
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/profile_cache.dart';

// Simple model for Profile status check
class ProfileStatus {
  final bool hasProfile;
  final String? status; // pending, approved

  ProfileStatus({required this.hasProfile, this.status});
}

final profileStatusProvider = FutureProvider<ProfileStatus>((ref) async {
  return ProfileStatus(hasProfile: true, status: 'approved'); 
});

// Advanced Provider for Public Profile Data with Multi-Layer Caching
final userProfileProvider = AsyncNotifierProvider.family<UserProfileNotifier, Map<String, dynamic>, String>(() {
  return UserProfileNotifier();
});

class UserProfileNotifier extends FamilyAsyncNotifier<Map<String, dynamic>, String> {
  @override
  Future<Map<String, dynamic>> build(String arg) async {
    final cacheService = ref.read(profileCacheServiceProvider);
    
    // 1. Try to load from cache immediately
    final cachedData = cacheService.getProfile(arg);
    
    // 2. Trigger a background refresh
    // We don't await this so the cached data goes to UI immediately
    _fetchFreshData(arg);

    if (cachedData != null) {
      return cachedData;
    }

    // 3. Fallback if no cache: wait for the initial fetch
    return await _fetchFreshData(arg);
  }

  Future<Map<String, dynamic>> _fetchFreshData(String userId) async {
    final apiClient = ref.read(apiClientProvider);
    final cacheService = ref.read(profileCacheServiceProvider);

    try {
      final response = await apiClient.get('/user/$userId');
      final data = response.data as Map<String, dynamic>;
      
      // Update cache
      await cacheService.saveProfile(userId, data);
      
      // Update state
      state = AsyncValue.data(data);
      return data;
    } catch (e, stack) {
      if (state.hasValue) {
        // If we have cached data, we might not want to throw just because refresh failed
        return state.value!;
      }
      rethrow;
    }
  }

  Future<void> updateLocalProfile(Map<String, dynamic> newData) async {
    final cacheService = ref.read(profileCacheServiceProvider);
    await cacheService.saveProfile(arg, newData);
    state = AsyncValue.data(newData);
  }
}
