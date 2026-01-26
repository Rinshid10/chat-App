import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:chatapp/services/auth_service.dart';
import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/services/pin_service.dart';
import 'package:chatapp/utils/page_transitions.dart';
import 'package:chatapp/user_flow/screens/auth_screen.dart';
import 'package:chatapp/user_flow/screens/user_list_screen.dart';
import 'package:chatapp/user_flow/screens/pin_lock_screen.dart';
import 'package:chatapp/admin_flow/screens/admin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;

      if (user != null) {
        String username = user.displayName?.trim() ?? '';
        final String email = user.email?.trim() ?? '';

        // If displayName is missing/empty, derive a username from email
        if (username.isEmpty && email.isNotEmpty && email.contains('@')) {
          username = email.split('@').first;
          try {
            await user.updateDisplayName(username);
            debugPrint(
              'displayName was empty in SplashScreen; set to derived username=$username',
            );
          } catch (e) {
            debugPrint('Error setting displayName in SplashScreen: $e');
          }
        }

        debugPrint(
          'FirebaseAuth user detected. uid=${user.uid}, username=$username, email=$email',
        );

        if (username.isEmpty) {
          // Still no valid username; sign out and send back to auth
          await authService.signOut();
          if (mounted) _navigateTo(const AuthScreen());
          return;
        }

        // Check if admin forced logout
        try {
          final usersRef =
              FirebaseDatabase.instance.ref('users').child(username);
          final userSnapshot = await usersRef.get();

          if (userSnapshot.exists) {
            final userData =
                userSnapshot.value as Map<dynamic, dynamic>?;
            final forceLogout = userData?['forceLogout'] == true;

            if (forceLogout) {
              debugPrint(
                'Admin forced logout detected for $username. Signing out.',
              );
              await authService.signOut();
              if (mounted) _navigateTo(const AuthScreen());
              return;
            }
          }
        } catch (e) {
          debugPrint('Error checking force logout: $e');
        }

        // Check if PIN lock is enabled
        final pinService = context.read<PinService>();
        final isPinEnabled = await pinService.checkPinEnabled();

        if (isPinEnabled && mounted) {
          debugPrint('PIN lock is enabled. Showing PIN screen.');

          // Navigate to PIN lock screen and wait for result
          final verified = await Navigator.push<bool>(
            context,
            FadeScalePageRoute(
              page: PinLockScreen(
                onSuccess: () => Navigator.pop(context, true),
              ),
            ),
          );

          if (verified != true) {
            // User failed PIN or cancelled - stay on splash
            debugPrint('PIN verification failed or cancelled.');
            return;
          }

          debugPrint('PIN verified successfully.');
        }

        debugPrint('Auto-logging in as authenticated user: $username');
        try {
          final chatService = context.read<FirebaseChatService>();
          await chatService.join(username);

          if (mounted) {
            final isAdmin =
                email.toLowerCase() == 'adminrinshid@gmail.com';
            if (isAdmin) {
              _navigateTo(const AdminScreen());
            } else {
              _navigateTo(const UserListScreen());
            }
          }
        } catch (e, stackTrace) {
          debugPrint('Error joining Firebase: $e');
          debugPrint('Stack trace: $stackTrace');
          if (mounted) _navigateTo(const AuthScreen());
        }
      } else {
        if (mounted) _navigateTo(const AuthScreen());
      }
    } catch (e, stackTrace) {
      debugPrint('Error checking login status: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) _navigateTo(const AuthScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      FadeScalePageRoute(page: screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                size: 44,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ChatFlow',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

