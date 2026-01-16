import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;
import 'dart:async';
import '../../../models/user_model.dart' as model;
import '../../../core/api_client.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Fetch Backend User Details
final currentUserProvider = FutureProvider<model.User?>((ref) async {
  final authState = ref.watch(authStateProvider);
  
  // Only proceed if auth session is ready
  if (authState.isLoading) {
    // Return a never-completing future or wait? 
    // Actually, watching authState will re-run this when it changes.
    // We want the FutureProvider itself to stay in 'loading' state.
    return Completer<model.User?>().future; 
  }

  final firebaseUser = authState.value;
  if (firebaseUser == null) return null;
  
  final apiClient = ref.read(apiClientProvider);
  try {
    final response = await apiClient.get('/user/me');
    return model.User.fromJson(response.data);
  } catch (e) {
    print('Error fetching user from backend: $e');
    // If it's a new user, they might not have a record yet
    return null;
  }
});

// Helper for Completer

class AuthController {
  final FirebaseAuth _auth;
  final ApiClient _apiClient;
  final Ref _ref;

  AuthController(this._auth, this._apiClient, this._ref);

  Future<void> signInWithEmailPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _syncUser(email);
    _ref.invalidate(currentUserProvider);
  }
  
  Future<void> signUpWithEmailPassword(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _syncUser(email);
    _ref.invalidate(currentUserProvider);
  }

  Future<void> _syncUser(String? email) async {
      try {
        await _apiClient.post('/user/sync', data: {'email': email});
      } catch (e) {
        print('Sync failed: $e');
      }
  }

  Future<void> signInWithGoogle() async {
    final google_sign_in.GoogleSignIn googleSignIn = google_sign_in.GoogleSignIn();
    
    // Trigger the authentication flow
    final google_sign_in.GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return; // User canceled

    // Obtain the auth details from the request
    final google_sign_in.GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the generated credential
    await _auth.signInWithCredential(credential);
    await _syncUser(googleUser.email);
    _ref.invalidate(currentUserProvider);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _ref.invalidate(currentUserProvider); // usage for good measure
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    ref.watch(firebaseAuthProvider),
    ref.watch(apiClientProvider),
    ref,
  );
});
