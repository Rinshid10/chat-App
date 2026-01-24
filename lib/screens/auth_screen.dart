import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firebase_chat_service.dart';
import 'splash_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  String? _errorText;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<bool> _isUsernameTaken(String username) async {
    final ref = FirebaseDatabase.instance.ref('users').child(username);
    final snapshot = await ref.get();
    return snapshot.exists;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    final authService = context.read<AuthService>();

    try {
      if (_isLoginMode) {
        await authService.signIn(email: email, password: password);
      } else {
        // Ensure username uniqueness
        final taken = await _isUsernameTaken(username);
        if (taken) {
          setState(() {
            _errorText = 'Username already taken. Please choose another.';
            _isLoading = false;
          });
          return;
        }

        await authService.signUp(
          email: email,
          password: password,
          username: username,
        );
      }

      // After successful auth, let SplashScreen handle join + routing
      if (!mounted) return;

      // Clear any cached username in chat service; it will be re-joined in Splash
      final chatService = context.read<FirebaseChatService>();
      await chatService.disconnect();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SplashScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      setState(() {
        _errorText = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (_isLoginMode) {
      return null;
    }
    if (value == null || value.trim().isEmpty) {
      return 'Please choose a username';
    }
    if (value.contains(' ')) {
      return 'Username cannot contain spaces';
    }
    return null;
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 90,
                      height: 90,
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
                        Icons.lock_open_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00d9ff), Color(0xFF00ff88)],
                      ).createShader(bounds),
                      child: Text(
                        _isLoginMode ? 'Welcome Back' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoginMode
                          ? 'Login to continue chatting'
                          : 'Sign up to start using ChatFlow',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(18),
                              ),
                              validator: _validateEmail,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(18),
                              ),
                              validator: _validatePassword,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Username (sign up only)
                          if (!_isLoginMode)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Username (chat name)',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(18),
                                ),
                                validator: _validateUsername,
                              ),
                            ),
                          if (!_isLoginMode) const SizedBox(height: 16),

                          if (_errorText != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _errorText!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          const SizedBox(height: 8),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00d9ff),
                                    Color(0xFF00ff88),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00d9ff)
                                        .withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _isLoginMode ? 'Login' : 'Sign Up',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            _isLoginMode
                                                ? Icons.login_rounded
                                                : Icons.person_add_alt_rounded,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Toggle
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                                _errorText = null;
                              });
                            },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _isLoginMode
                                  ? "Don't have an account? "
                                  : 'Already have an account? ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const TextSpan(
                              text: 'Switch',
                              style: TextStyle(
                                color: Color(0xFF00d9ff),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

