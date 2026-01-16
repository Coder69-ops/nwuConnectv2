import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../models/candidate_model.dart';
import '../../auth/providers/auth_provider.dart';

// Fetch Candidates
final candidatesProvider = FutureProvider.autoDispose<List<Candidate>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/connect/candidates');
  final List<dynamic> data = response.data;
  return data.map((json) => Candidate.fromJson(json)).toList();
});

// Swipe Action Provider
final swipeActionProvider = StateNotifierProvider<SwipeActionNotifier, AsyncValue<void>>((ref) {
  return SwipeActionNotifier(ref);
});

class SwipeActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SwipeActionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<Map<String, dynamic>?> swipe({required String targetId, required String action}) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post('/connect/swipe', data: {
        'targetId': targetId,
        'action': action, // 'like' or 'pass'
      });
      
      if (response.data != null && response.data['match'] == true) {
        return Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // Rethrow to let the UI handle the error dialog
    }
  }
}
