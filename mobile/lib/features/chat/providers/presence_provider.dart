import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/api_client.dart';

class UserPresence {
  final bool isOnline;
  final DateTime lastSeen;

  UserPresence({required this.isOnline, required this.lastSeen});

  factory UserPresence.fromMap(Map<dynamic, dynamic> map) {
    return UserPresence(
      isOnline: map['online'] ?? false,
      lastSeen: map['lastSeen'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen']) 
          : DateTime.now(),
    );
  }
}

final presenceServiceProvider = Provider<PresenceService>((ref) {
  return PresenceService(ref);
});

class PresenceService {
  final Ref _ref;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _connectionSubscription;

  PresenceService(this._ref);

  void initialize() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final presenceRef = _db.ref('presence/$uid');
    
    _connectionSubscription = _db.ref('.info/connected').onValue.listen((event) async {
      final connected = event.snapshot.value as bool? ?? false;
      
      if (connected) {
        // Set online status in RTDB
        await presenceRef.set({
          'online': true,
          'lastSeen': ServerValue.timestamp,
        });

        // Ensure offline status on disconnect
        await presenceRef.onDisconnect().set({
          'online': false,
          'lastSeen': ServerValue.timestamp,
        });

        // Update Backend
        _updateBackendPresence(true);
      } else {
         _updateBackendPresence(false);
      }
    });
  }

  void _updateBackendPresence(bool isOnline) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.post('/user/presence', data: {'isOnline': isOnline});
    } catch (e) {
      print('Failed to update backend presence: $e');
    }
  }

  void dispose() {
    _connectionSubscription?.cancel();
  }
}

final userPresenceProvider = StreamProvider.family<UserPresence, String>((ref, userId) {
  final db = FirebaseDatabase.instance;
  return db.ref('presence/$userId').onValue.map((event) {
    if (event.snapshot.value == null) {
      return UserPresence(isOnline: false, lastSeen: DateTime.now());
    }
    return UserPresence.fromMap(event.snapshot.value as Map);
  });
});
