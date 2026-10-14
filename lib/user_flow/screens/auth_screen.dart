import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/services/auth_service.dart';
import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/theme/app_theme.dart';
import 'package:chatapp/user_flow/screens/splash_screen.dart';
import 'package:chatapp/utils/responsive.dart';
import 'package:chatapp/widgets/brand_mark.dart';
import 'package:chatapp/widgets/confirmation_sheet.dart';
import 'package:chatapp/widgets/depth.dart';

/// Login / sign-up panel: brand header, labeled fields, gradient call to
/// action and a link to switch modes.
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
  final _confirmController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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

      if (!mounted) return;

      final chatService = context.read<FirebaseChatService>();
      await chatService.disconnect();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SplashScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
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

  Future<void> _forgotPassword() async {
    final email = await showInputSheet(
      context: context,
      title: 'Reset password',
      initialValue: _emailController.text.trim(),
      hintText: 'Your email address',
      confirmText: 'Send link',
      maxLines: 1,
    );
    if (email == null || !mounted) return;

    if (_validateEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    try {
      await context.read<AuthService>().sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send reset link: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _switchMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorText = null;
      _confirmController.clear();
    });
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

  String? _validateConfirm(String? value) {
    if (_isLoginMode) return null;
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value.trim() != _passwordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (_isLoginMode) return null;
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
      body: isDesktopLayout(context)
          ? _buildDesktop(context)
          : _buildMobile(context),
    );
  }

  /// Phone: single scrolling column with the brand header on top.
  Widget _buildMobile(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _AmbientBackground()),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: DepthSurface(
                  level: 2,
                  radius: 20,
                  padding: const EdgeInsets.all(24),
                  child: _buildForm(context, desktop: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Desktop / web: brand panel on the left, larger form on the right.
  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        const Expanded(flex: 5, child: _BrandPanel()),
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              const Positioned.fill(child: _AmbientBackground()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 40,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Theme(
                        // Taller inputs read better at desktop sizes.
                        data: theme.copyWith(
                          inputDecorationTheme: theme.inputDecorationTheme
                              .copyWith(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 17,
                                ),
                              ),
                        ),
                        child: TiltCard(
                          child: DepthSurface(
                            level: 3,
                            radius: 24,
                            padding: const EdgeInsets.all(40),
                            child: _buildForm(context, desktop: true),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, {required bool desktop}) {
    final colorScheme = Theme.of(context).colorScheme;

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            desktop ? _buildDesktopHeading(context) : _buildHeader(context),
            SizedBox(height: desktop ? 28 : 32),
            if (!_isLoginMode) ...[
              _Field(
                label: 'Username',
                child: TextFormField(
                  key: const Key('auth_username'),
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Choose a chat name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: _validateUsername,
                ),
              ),
            ],
            _Field(
              label: 'Email Address',
              child: TextFormField(
                key: const Key('auth_email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: _validateEmail,
              ),
            ),
            _Field(
              label: 'Password',
              child: TextFormField(
                key: const Key('auth_password'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: _isLoginMode
                    ? TextInputAction.done
                    : TextInputAction.next,
                onFieldSubmitted: (_) {
                  if (_isLoginMode && !_isLoading) _submit();
                },
                decoration: InputDecoration(
                  hintText: _isLoginMode
                      ? 'Enter your password'
                      : 'Create a password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: _VisibilityToggle(
                    obscured: _obscurePassword,
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: _validatePassword,
              ),
            ),
            if (!_isLoginMode)
              _Field(
                label: 'Confirm Password',
                child: TextFormField(
                  key: const Key('auth_confirm'),
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_isLoading) _submit();
                  },
                  decoration: InputDecoration(
                    hintText: 'Confirm your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: _VisibilityToggle(
                      obscured: _obscureConfirm,
                      onTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: _validateConfirm,
                ),
              ),
            if (_isLoginMode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _forgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Forgot password?'),
                ),
              ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  _errorText!,
                  style: TextStyle(color: colorScheme.error, fontSize: 13),
                ),
              ),
            const SizedBox(height: 16),
            _GradientButton(
              label: _isLoginMode ? 'Log In' : 'Create Account',
              loading: _isLoading,
              onPressed: _isLoading ? null : _submit,
            ),
            const SizedBox(height: 24),
            _buildSwitchLink(context),
          ],
        ),
      ),
    );
  }

  /// Heading used on the desktop form; the brand itself lives in the
  /// left panel there.
  Widget _buildDesktopHeading(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isLoginMode ? 'Welcome back' : 'Create your account',
          style: textTheme.headlineLarge?.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLoginMode
              ? 'Sign in to pick up where you left off.'
              : 'It only takes a minute to get started.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const BrandMark(size: 56),
        const SizedBox(height: 16),
        Text(
          'ChatFlow',
          style: textTheme.headlineLarge?.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLoginMode
              ? 'Chat with anyone, anywhere.\nSign in to pick up where you left off.'
              : 'Create your account and\nstart chatting in seconds.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchLink(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            _isLoginMode
                ? "Don't have an account? "
                : 'Already have an account? ',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          InkWell(
            onTap: _isLoading ? null : _switchMode,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                _isLoginMode ? 'Sign Up' : 'Log In',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label above a field, like the reference design.
class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Pressed-in well around the field; the field itself stays unfilled.
          DepthSurface(
            inset: true,
            radius: AppTheme.controlRadius,
            color: colorScheme.surfaceContainerHighest,
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: Theme.of(
                  context,
                ).inputDecorationTheme.copyWith(filled: false),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onTap;

  const _VisibilityToggle({required this.obscured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}

/// Full-width gradient call to action with a trailing arrow.
class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DepthButton(
      onPressed: loading ? null : onPressed,
      height: 54,
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: colorScheme.onPrimary,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ],
            ),
    );
  }
}

/// Soft tinted blobs in two corners so the page is not a flat void.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = colorScheme.primary;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -160,
            left: -120,
            child: _Blob(color: tint.withOpacity(0.14), size: 520),
          ),
          Positioned(
            bottom: -200,
            right: -140,
            child: _Blob(color: tint.withOpacity(0.10), size: 600),
          ),
        ],
      ),
    );
  }
}

/// Left half of the desktop login: brand, tagline and feature highlights.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final base = theme.scaffoldBackgroundColor;
    final accent = colorScheme.accentGradient;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(accent.first.withOpacity(0.22), base),
            Color.alphaBlend(accent.last.withOpacity(0.16), base),
          ],
        ),
        border: Border(right: BorderSide(color: colorScheme.outline)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -180,
            right: -160,
            child: _Blob(color: accent.first.withOpacity(0.25), size: 560),
          ),
          Positioned(
            bottom: -220,
            left: -180,
            child: _Blob(color: accent.last.withOpacity(0.22), size: 620),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 48, 56, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrandMark(size: 40),
                    const SizedBox(width: 12),
                    Text(
                      'ChatFlow',
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Chat with anyone, anywhere.',
                  style: textTheme.headlineLarge?.copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Realtime one-to-one messaging with voice calls and a '
                  'PIN lock, on your phone and in the browser.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                const _Feature(
                  icon: Icons.bolt_rounded,
                  title: 'Realtime messages',
                  description: 'Delivered instantly, with replies and edits.',
                ),
                const SizedBox(height: 20),
                const _Feature(
                  icon: Icons.call_rounded,
                  title: 'Voice calls',
                  description: 'One-tap audio calls with your contacts.',
                ),
                const SizedBox(height: 20),
                const _Feature(
                  icon: Icons.lock_rounded,
                  title: 'App lock',
                  description: 'Protect your chats with a 4-digit PIN.',
                ),
                const Spacer(),
                Text(
                  '© ${DateTime.now().year} ChatFlow',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DepthSurface(
          width: 44,
          height: 44,
          level: 2,
          color: Color.alphaBlend(
            colorScheme.primary.withOpacity(0.22),
            colorScheme.surface,
          ),
          rimTint: colorScheme.primary,
          child: Icon(icon, size: 22, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}
