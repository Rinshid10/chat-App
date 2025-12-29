import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_chat_service.dart';
import 'services/admin_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up error handling for release mode
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // In release mode, log to console for debugging
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    }
  };
  
  // Handle platform errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };
  
  // Initialize Firebase with proper error handling
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue even if Firebase initialization fails in some cases
    // The app will handle this gracefully
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FirebaseChatService>(
          create: (_) {
            final chatService = FirebaseChatService();
            chatService.connect();
            return chatService;
          },
        ),
        ChangeNotifierProvider<AdminService>(
          create: (_) => AdminService(),
        ),
      ],
      child: const AppLifecycleWrapper(),
    );
  }
}

class AppLifecycleWrapper extends StatefulWidget {
  const AppLifecycleWrapper({super.key});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final chatService = context.read<FirebaseChatService>();
    
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App went to background or is closing - set user offline
      chatService.setOffline();
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground - set user online if logged in
      chatService.setOnline();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      builder: (context, child) {
        // Add error boundary for release mode
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
