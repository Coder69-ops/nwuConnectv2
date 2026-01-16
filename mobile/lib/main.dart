import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'features/chat/providers/presence_provider.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Hive.initFlutter();
    await Hive.openBox('feed_cache');
    await Hive.openBox('user_profiles');
    await Hive.openBox('conversations_cache');
    await Hive.openBox('chat_messages_cache');
  } catch (e) {
    debugPrint("Initialization failed: $e");
    // Fallback or handle error
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialize Presence Service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(presenceServiceProvider).initialize();
      ref.read(notificationServiceProvider).initialize();
    });

    return MaterialApp.router(
      title: 'NWUConnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}


