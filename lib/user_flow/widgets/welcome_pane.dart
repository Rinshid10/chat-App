import 'package:flutter/material.dart';

import 'package:chatapp/widgets/brand_mark.dart';

/// Desktop landing pane shown in the chat area while no conversation is
/// selected: logo, greeting and a row of quick actions.
class WelcomePane extends StatelessWidget {
  final String username;
  final VoidCallback onAddContact;
  final VoidCallback onAppLock;
  final VoidCallback onToggleTheme;

  const WelcomePane({
    super.key,
    required this.username,
    required this.onAddContact,
    required this.onAppLock,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 64),
            const SizedBox(height: 28),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Welcome Back, '),
                  TextSpan(
                    text: username,
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ],
              ),
              style: textTheme.headlineLarge?.copyWith(
                fontSize: 34,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Pick a contact from the list to start a conversation,\n'
              'or use one of the shortcuts below.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: [
                _QuickAction(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Add a contact',
                  subtitle: 'Find someone new',
                  onTap: onAddContact,
                ),
                _QuickAction(
                  icon: Icons.lock_outline_rounded,
                  title: 'App lock',
                  subtitle: 'Secure with a PIN',
                  onTap: onAppLock,
                ),
                _QuickAction(
                  icon: Icons.brightness_6_outlined,
                  title: 'Switch theme',
                  subtitle: 'Light or dark',
                  onTap: onToggleTheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      shape: StadiumBorder(side: BorderSide(color: colorScheme.outline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 26, 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: colorScheme.onSurface),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
