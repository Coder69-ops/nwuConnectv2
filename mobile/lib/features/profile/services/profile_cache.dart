import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileCacheServiceProvider = Provider((ref) => ProfileCacheService());

class ProfileCacheService {
  final _box = Hive.box('user_profiles');

  Map<String, dynamic>? getProfile(String userId) {
    final data = _box.get(userId);
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveProfile(String userId, Map<String, dynamic> profileData) async {
    await _box.put(userId, profileData);
  }

  Future<void> clearCache() async {
    await _box.clear();
  }
}
