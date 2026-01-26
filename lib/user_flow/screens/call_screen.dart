import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatapp/services/agora_call_service.dart';
import 'package:chatapp/utils/avatar_utils.dart';

class CallScreen extends StatefulWidget {
  final String otherUsername;
  final String channelName;

  const CallScreen({
    super.key,
    required this.otherUsername,
    required this.channelName,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCall();
    });
  }

  Future<void> _startCall() async {
    final callService = context.read<AgoraCallService>();
    try {
      await callService.joinChannel(widget.channelName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting call: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _endCall() async {
    final callService = context.read<AgoraCallService>();
    await callService.disposeEngine();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final avatarColor = getAvatarColor(widget.otherUsername);
    final callService = context.watch<AgoraCallService>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _endCall,
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    callService.isJoined
                        ? (callService.remoteUid != null
                            ? 'Connected'
                            : 'Connecting...')
                        : 'Connecting...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: callService.isJoined && callService.remoteUid != null
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
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
                  // Avatar
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
                        widget.otherUsername[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Username
                  Text(
                    widget.otherUsername,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Call status
                  Text(
                    callService.isJoined
                        ? (callService.remoteUid != null
                            ? 'In call'
                            : 'Waiting for user to join...')
                        : 'Connecting...',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // End call button
            Padding(
              padding: const EdgeInsets.all(32),
              child: Container(
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
                  onPressed: _endCall,
                  icon: Icon(
                    Icons.call_end_rounded,
                    color: colorScheme.onError,
                    size: 32,
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
