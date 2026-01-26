import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/services/pin_service.dart';

/// Screen for setting up or changing the 4-digit PIN.
/// Has two steps: Enter PIN, then Confirm PIN.
class PinSetupScreen extends StatefulWidget {
  /// If true, user must enter current PIN first before setting new one
  final bool isChangingPin;

  const PinSetupScreen({
    super.key,
    this.isChangingPin = false,
  });

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String _firstPin = '';
  bool _isConfirmStep = false;
  bool _isVerifyingOld = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSaving = false;

  // For change PIN flow
  bool _needsOldPinVerification = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _needsOldPinVerification = widget.isChangingPin;

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

  String get _title {
    if (_needsOldPinVerification && _isVerifyingOld) {
      return 'Enter current PIN';
    }
    if (_isConfirmStep) {
      return 'Confirm your PIN';
    }
    return 'Create a PIN';
  }

  String get _subtitle {
    if (_needsOldPinVerification && _isVerifyingOld) {
      return 'Enter your current 4-digit PIN';
    }
    if (_isConfirmStep) {
      return 'Re-enter your 4-digit PIN';
    }
    return 'Choose a 4-digit PIN to lock your app';
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4 || _isSaving) return;

    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin += digit;
      _hasError = false;
      _errorMessage = '';
    });

    // Auto-submit when 4 digits entered
    if (_enteredPin.length == 4) {
      _handlePinComplete();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty || _isSaving) return;

    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
      _errorMessage = '';
    });
  }

  Future<void> _handlePinComplete() async {
    // Step 1: Verify old PIN (if changing)
    if (_needsOldPinVerification && _isVerifyingOld) {
      final pinService = context.read<PinService>();
      final isValid = await pinService.verifyPin(_enteredPin);

      if (isValid) {
        setState(() {
          _isVerifyingOld = false;
          _enteredPin = '';
        });
      } else {
        _showError('Wrong PIN. Try again.');
      }
      return;
    }

    // Step 2: First PIN entry
    if (!_isConfirmStep) {
      setState(() {
        _firstPin = _enteredPin;
        _enteredPin = '';
        _isConfirmStep = true;
      });
      return;
    }

    // Step 3: Confirm PIN
    if (_enteredPin == _firstPin) {
      await _savePin();
    } else {
      _showError('PINs do not match. Try again.');
      setState(() {
        _isConfirmStep = false;
        _firstPin = '';
        _enteredPin = '';
      });
    }
  }

  void _showError(String message) {
    HapticFeedback.vibrate();
    _shakeController.forward().then((_) => _shakeController.reset());

    setState(() {
      _hasError = true;
      _errorMessage = message;
      _enteredPin = '';
    });
  }

  Future<void> _savePin() async {
    setState(() => _isSaving = true);

    try {
      final pinService = context.read<PinService>();
      await pinService.setPin(_firstPin);

      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isChangingPin ? 'PIN changed successfully' : 'PIN set successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving PIN: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showError('Error: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Initialize verification state
    if (_needsOldPinVerification && !_isVerifyingOld && _firstPin.isEmpty) {
      _isVerifyingOld = true;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
          ),
        ),
        title: Text(
          widget.isChangingPin ? 'Change PIN' : 'Set PIN',
          style: textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Step indicator
            if (!_needsOldPinVerification || !_isVerifyingOld)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(1, !_isConfirmStep, colorScheme),
                  Container(
                    width: 40,
                    height: 2,
                    color: _isConfirmStep
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.3),
                  ),
                  _buildStepIndicator(2, _isConfirmStep, colorScheme),
                ],
              ),

            const SizedBox(height: 32),

            // Title
            Text(
              _title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              _subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Error message
            AnimatedOpacity(
              opacity: _hasError ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _errorMessage,
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

            // Number pad
            _buildNumberPad(colorScheme),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, ColorScheme colorScheme) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: isActive ? colorScheme.primary : colorScheme.outline,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
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
        onTap: _isSaving ? null : () => _onDigitPressed(digit),
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
        onTap: _isSaving ? null : _onBackspacePressed,
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
