import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/services/pin_service.dart';
import 'package:chatapp/services/auth_service.dart';
import 'package:chatapp/widgets/confirmation_sheet.dart';

/// PIN Lock screen shown when app launches and PIN is enabled.
/// User must enter correct 4-digit PIN to access the app.
class PinLockScreen extends StatefulWidget {
  final VoidCallback? onSuccess;

  const PinLockScreen({
    super.key,
    this.onSuccess,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _isVerifying = false;
  bool _hasError = false;
  int _attempts = 0;
  static const int _maxAttempts = 3;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4 || _isVerifying) return;

    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin += digit;
      _hasError = false;
    });

    // Auto-submit when 4 digits entered
    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty || _isVerifying) return;

    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);

    final pinService = context.read<PinService>();
    final isValid = await pinService.verifyPin(_enteredPin);

    if (isValid) {
      HapticFeedback.heavyImpact();
      widget.onSuccess?.call();
    } else {
      HapticFeedback.vibrate();
      _shakeController.forward().then((_) => _shakeController.reset());

      setState(() {
        _hasError = true;
        _attempts++;
        _enteredPin = '';
        _isVerifying = false;
      });
    }
  }

  Future<void> _forgotPin() async {
    final confirm = await showConfirmationSheet<bool>(
      context: context,
      title: 'Forgot PIN?',
      message: 'You will be logged out. After signing in again, you can set a new PIN.',
      confirmText: 'Logout',
      icon: Icons.lock_reset_rounded,
      isDanger: true,
    );

    if (confirm == true && mounted) {
      // Disable PIN and logout
      final pinService = context.read<PinService>();
      final authService = context.read<AuthService>();

      await pinService.disablePin();
      await authService.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // App Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Enter your PIN',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Error message
            AnimatedOpacity(
              opacity: _hasError ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Wrong PIN. ${_maxAttempts - _attempts} attempts remaining.',
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // PIN dots with shake animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final shake = _shakeAnimation.value * 10;
                return Transform.translate(
                  offset: Offset(
                    shake * ((_shakeAnimation.value * 10).toInt() % 2 == 0 ? 1 : -1),
                    0,
                  ),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? (_hasError ? colorScheme.error : colorScheme.primary)
                          : Colors.transparent,
                      border: Border.all(
                        color: _hasError
                            ? colorScheme.error
                            : colorScheme.outline,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const Spacer(flex: 1),

            // Forgot PIN button (after max attempts)
            if (_attempts >= _maxAttempts)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(
                  onPressed: _forgotPin,
                  child: Text(
                    'Forgot PIN?',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Number pad
            _buildNumberPad(colorScheme),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Row 1: 1 2 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigitButton('1', colorScheme),
              _buildDigitButton('2', colorScheme),
              _buildDigitButton('3', colorScheme),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: 4 5 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigitButton('4', colorScheme),
              _buildDigitButton('5', colorScheme),
              _buildDigitButton('6', colorScheme),
            ],
          ),
          const SizedBox(height: 16),

          // Row 3: 7 8 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDigitButton('7', colorScheme),
              _buildDigitButton('8', colorScheme),
              _buildDigitButton('9', colorScheme),
            ],
          ),
          const SizedBox(height: 16),

          // Row 4: empty 0 backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72, height: 72),
              _buildDigitButton('0', colorScheme),
              _buildBackspaceButton(colorScheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitButton(String digit, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isVerifying ? null : () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isVerifying ? null : _onBackspacePressed,
        borderRadius: BorderRadius.circular(36),
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 28,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
