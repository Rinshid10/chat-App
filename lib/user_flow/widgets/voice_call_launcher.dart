import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/services/call_notification_service.dart';
import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/user_flow/screens/call_screen.dart';
import 'package:chatapp/widgets/confirmation_sheet.dart';

/// Asks for confirmation, checks the microphone permission, notifies the
/// other user and opens the call screen. Shared by the chat header and the
/// desktop top bar so both start calls the same way.
Future<void> confirmAndStartCall(
  BuildContext context,
  String otherUsername,
) async {
  final shouldStartCall = await showConfirmationSheet<bool>(
    context: context,
    title: 'Start Call',
    message: 'Do you want to start an audio call with $otherUsername?',
    confirmText: 'Call',
    icon: Icons.call_rounded,
  );

  if (shouldStartCall != true || !context.mounted) return;
  await _startCall(context, otherUsername);
}

Future<void> _startCall(BuildContext context, String otherUsername) async {
  final status = await Permission.microphone.request();
  if (!context.mounted) return;

  if (status.isDenied) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Microphone permission is required for voice calls',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    return;
  }

  if (status.isPermanentlyDenied) {
    final shouldOpenSettings = await showConfirmationSheet<bool>(
      context: context,
      title: 'Microphone Permission Required',
      message:
          'Please enable microphone permission in app settings to make voice calls.',
      confirmText: 'Open Settings',
      icon: Icons.mic_off_rounded,
    );
    if (shouldOpenSettings == true) {
      await openAppSettings();
    }
    return;
  }

  // Channel name shared by both sides of the call.
  const channelName = 'test_call';

  final callNotificationService = context.read<CallNotificationService>();
  final chatService = context.read<FirebaseChatService>();

  try {
    await callNotificationService.sendCallInvitation(
      fromUsername: chatService.username ?? '',
      toUsername: otherUsername,
      channelName: channelName,
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CallScreen(otherUsername: otherUsername, channelName: channelName),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error starting call: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
