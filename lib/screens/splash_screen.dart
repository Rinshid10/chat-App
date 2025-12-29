import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/firebase_chat_service.dart';
import 'username_screen.dart';
import 'user_list_screen.dart';
import 'admin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for the first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('username');
      
      debugPrint(' login status. Saved username: $savedUsername');
      
      if (savedUsername != null && savedUsername.isNotEmpty) {
        // Check if admin forced logout
        try {
          final usersRef = FirebaseDatabase.instance.ref('users').child(savedUsername);
          final userSnapshot = await usersRef.get();
          
          if (userSnapshot.exists) {
            final userData = userSnapshot.value as Map<dynamic, dynamic>?;
            final forceLogout = userData?['forceLogout'] == true;
            
            if (forceLogout) {
              debugPrint('Admin forced logout detected. Clearing saved username.');
              // Clear saved username to force re-login
              await prefs.remove('username');
              
              // Clear the forceLogout flag (optional, or keep it until user logs in again)
              // await usersRef.update({'forceLogout': false});
              
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const UsernameScreen(),
                    transitionDuration: const Duration(milliseconds: 300),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              }
              return;
            }
          }
        } catch (e) {
          debugPrint('Error checking force logout: $e');
          // Continue with normal login if check fails
        }
        
        debugPrint('Auto-logging in as: $savedUsername');
        try {
          // User is logged in, restore session
          final chatService = context.read<FirebaseChatService>();
          await chatService.join(savedUsername);
          
          if (mounted) {
            // Check if admin user
            if (savedUsername.toLowerCase() == 'adminrinshid') {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const AdminScreen(),
                  transitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const UserListScreen(),
                  transitionDuration: const Duration(milliseconds: 300),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            }
          }
        } catch (e, stackTrace) {
          debugPrint('Error joining Firebase: $e');
          debugPrint('Stack trace: $stackTrace');
          // If Firebase join fails, still go to login to let user retry
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const UsernameScreen(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          }
        }
      } else {
        // No saved username, go to login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const UsernameScreen(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error checking login status: $e');
      debugPrint('Stack trace: $stackTrace');
      // On error, go to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const UsernameScreen(),
            transitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00d9ff), Color(0xFF00ff88)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00d9ff).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF00d9ff), Color(0xFF00ff88)],
                ).createShader(bounds),
                child: const Text(
                  'ChatFlow',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

