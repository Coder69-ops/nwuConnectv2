
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/ban_screen.dart';
import '../../features/home/home_screen.dart'; // Using as Profile for now
import '../../features/onboarding/waiting_screen.dart';
import '../../features/social/screens/feed_screen.dart';
import '../../features/social/screens/create_post_screen.dart';
import '../../features/connect/screens/connect_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/notification/screens/notification_screen.dart';
import '../../features/chat/providers/chat_provider.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/verification_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../widgets/scaffold_with_navbar.dart';
import '../widgets/splash_screen.dart';

import '../../features/profile/providers/profile_provider.dart';
import '../../features/profile/screens/profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: _RouterRefreshStream(ref),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/ban',
        builder: (context, state) => const BanScreen(),
      ),
      GoRoute(
        path: '/waiting',
        builder: (context, state) => const WaitingScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/chat/details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ChatScreen(
            conversationId: extra['conversationId'],
            targetUser: extra['targetUser'],
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/connect',
                builder: (context, state) => const ConnectScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  final userId = state.uri.queryParameters['userId'];
                  return ProfileScreen(userId: userId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isAuthLoading = authState.isLoading;
      final isUserLoading = userAsync.isLoading;
      final location = state.matchedLocation;

      // 1. Wait for Auth & User Data
      if (isAuthLoading || isUserLoading) {
        return location == '/' ? null : '/';
      }

      final isAuthenticated = authState.value != null;
      final user = userAsync.value;
      
      final isLoginRoute = location == '/login';

      // 2. Unauthenticated -> Login
      if (!isAuthenticated) {
        return isLoginRoute ? null : '/login';
      }

      // 3. Authenticated but User fetch failed (Network error or new user not in DB sync yet)
      // For now, if user is null but auth is true, it might mean creating user in progress?
      // Default to Login or error screen. Let's send to Login for safety.
      // 3. Authenticated but User fetch failed (Race condition or Sync lag)
      if (user == null) {
         // Send to waiting screen which is safe.
         // Ideally, WaitingScreen should have a "Retry" button.
         return '/waiting';
      }

      // 4. THE GATE LOGIC
      
      // 4.1 BANNED - Block everything
      if (user.status == 'banned') {
        return location == '/ban' ? null : '/ban';
      }

      // 4.2 ONBOARDING - Must be done first (so we have Name, Dept, etc.)
      // This applies to both Pending and Approved users.
      if (!user.onboardingCompleted) {
        return location == '/onboarding' ? null : '/onboarding';
      }

      // 4.3 PENDING - Verification Queue
      if (user.status == 'pending') {
         final verification = user.verification;
         final submitted = verification['submitted'] == true;
         
         if (submitted) {
           return location == '/waiting' ? null : '/waiting';
         } else {
           return location == '/verification' ? null : '/verification';
         }
      }

      // 4.4 APPROVED - The Happy Path
      if (user.status == 'approved' || user.status == 'admin') {
         // Welcome Screen (First time only)
         if (!user.welcomeSeen) {
           return location == '/welcome' ? null : '/welcome';
         }
         
         // Accessing Gate/Post-Auth Pages
         final isGatePage = ['/', '/login', '/waiting', '/verification', '/ban', '/onboarding', '/welcome'].contains(location);
         if (isGatePage) {
           return '/feed';
         }
      }

      return null;
    },
  );
});

class _RouterRefreshStream extends ChangeNotifier {
  _RouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}
