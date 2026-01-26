import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/services/auth_service.dart';
import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/services/pin_service.dart';
import 'package:chatapp/theme/theme_provider.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/utils/page_transitions.dart';
import 'package:chatapp/user_flow/screens/auth_screen.dart';
import 'package:chatapp/user_flow/screens/pin_setup_screen.dart';
import 'package:chatapp/widgets/glass_container.dart';
import 'package:chatapp/widgets/confirmation_sheet.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isPinEnabled = false;
  bool _isLoadingPin = true;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    final pinService = context.read<PinService>();
    final isEnabled = await pinService.checkPinEnabled();
    if (mounted) {
      setState(() {
        _isPinEnabled = isEnabled;
        _isLoadingPin = false;
      });
    }
  }

  Future<void> _handlePinToggle(bool value) async {
    final pinService = context.read<PinService>();
    final colorScheme = Theme.of(context).colorScheme;

    if (value) {
      // Get navigator reference before closing drawer
      final navigator = Navigator.of(context, rootNavigator: true);

      // Close the drawer first
      Navigator.pop(context);

      // Enable PIN - navigate to setup screen
      final result = await navigator.push<bool>(
        FadeScalePageRoute(page: const PinSetupScreen()),
      );

      if (result == true && mounted) {
        setState(() => _isPinEnabled = true);
      }
    } else {
      // Disable PIN - show confirmation with current PIN verification
      final confirmed = await _showDisablePinDialog(colorScheme);
      if (confirmed == true) {
        await pinService.disablePin();
        if (mounted) {
          setState(() => _isPinEnabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('App Lock disabled'),
              backgroundColor: colorScheme.primary,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showDisablePinDialog(ColorScheme colorScheme) async {
    String enteredPin = '';

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: GlassContainer(
              borderRadius: BorderRadius.circular(20),
              blurSigma: 20,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disable App Lock',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your current PIN to disable App Lock',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),

                  // PIN input field
                  TextField(
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: 'Current PIN',
                      counterText: '',
                    ),
                    onChanged: (value) {
                      enteredPin = value;
                    },
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () async {
                          if (enteredPin.length != 4) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PIN must be 4 digits')),
                            );
                            return;
                          }

                          final pinService = context.read<PinService>();
                          final isValid = await pinService.verifyPin(enteredPin);

                          if (isValid) {
                            Navigator.pop(context, true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Wrong PIN'),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Disable',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleChangePinTap() async {
    final result = await Navigator.push<bool>(
      context,
      FadeScalePageRoute(page: const PinSetupScreen(isChangingPin: true)),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN changed successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authService = context.watch<AuthService>();
    final chatService = context.watch<FirebaseChatService>();
    final themeProvider = context.watch<ThemeProvider>();

    final user = authService.currentUser;
    final username = chatService.username ??
        user?.displayName ??
        user?.email?.split('@').first ??
        'User';
    final email = user?.email ?? '';
    final avatarColor = getAvatarColor(username);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: avatarColor,
                    child: Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Theme Toggle Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    'Theme',
                    style: textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    isDarkMode ? 'Dark Mode' : 'Light Mode',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      themeProvider.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                    activeTrackColor: colorScheme.primary,
                    activeThumbColor: colorScheme.onPrimary,
                    inactiveTrackColor: colorScheme.surfaceContainerHighest,
                    inactiveThumbColor: colorScheme.outline,
                  ),
                ),
              ),
            ),

            // App Lock (PIN) Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.lock_rounded,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        'App Lock',
                        style: textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        _isLoadingPin
                            ? 'Loading...'
                            : (_isPinEnabled ? 'Enabled' : 'Disabled'),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: _isLoadingPin
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Switch(
                              value: _isPinEnabled,
                              onChanged: _handlePinToggle,
                              activeTrackColor: colorScheme.primary,
                              activeThumbColor: colorScheme.onPrimary,
                              inactiveTrackColor: colorScheme.surfaceContainerHighest,
                              inactiveThumbColor: colorScheme.outline,
                            ),
                    ),

                    // Change PIN option (only visible when PIN is enabled)
                    if (_isPinEnabled && !_isLoadingPin) ...[
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                      ListTile(
                        leading: const SizedBox(width: 24),
                        title: Text(
                          'Change PIN',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: _handleChangePinTap,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Show confirmation bottom sheet
                    final shouldLogout = await showConfirmationSheet<bool>(
                      context: context,
                      title: 'Logout',
                      message: 'Are you sure you want to logout from your account?',
                      confirmText: 'Logout',
                      icon: Icons.logout_rounded,
                      isDanger: true,
                    );

                    if (shouldLogout == true && context.mounted) {
                      await chatService.logout();
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          FadeScalePageRoute(page: const AuthScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
