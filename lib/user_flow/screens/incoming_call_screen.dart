import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:chatapp/services/call_notification_service.dart';
import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/user_flow/screens/call_screen.dart';
import 'package:chatapp/utils/avatar_utils.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerUsername;
  final String callId;
  final String channelName;

  const IncomingCallScreen({
    super.key,
    required this.callerUsername,
    required this.callId,
    required this.channelName,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final avatarColor = getAvatarColor(widget.callerUsername);
    final callNotificationService = context.read<CallNotificationService>();
    final chatService = context.read<FirebaseChatService>();

    Future<void> _acceptCall() async {
      // Request microphone permission
      final status = await Permission.microphone.request();
      
      if (status.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Microphone permission is required for voice calls'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
        return;
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Microphone Permission Required'),
              content: Text('Please enable microphone permission in app settings'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Accept the call notification
      await callNotificationService.acceptCall(
        widget.callId,
        chatService.username ?? '',
      );

      // Navigate to call screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              otherUsername: widget.callerUsername,
              channelName: widget.channelName,
            ),
          ),
        );
      }
    }

    Future<void> _rejectCall() async {
      final chatService = context.read<FirebaseChatService>();
      await callNotificationService.rejectCall(
        widget.callId,
        chatService.username ?? '',
      );
      if (mounted) {
        Navigator.pop(context);
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Status
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Incoming Call',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar with animation
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: avatarColor,
                      boxShadow: [
                        BoxShadow(
                          color: avatarColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.callerUsername[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Caller name
                  Text(
                    widget.callerUsername,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Call status
                  Text(
                    'Incoming voice call...',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.error,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.error.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _rejectCall,
                      icon: Icon(
                        Icons.call_end_rounded,
                        color: colorScheme.onError,
                        size: 32,
                      ),
                    ),
                  ),

                  // Accept button
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _acceptCall,
                      icon: Icon(
                        Icons.call_rounded,
                        color: colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
