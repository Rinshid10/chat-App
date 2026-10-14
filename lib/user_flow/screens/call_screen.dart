import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatapp/services/agora_call_service.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/widgets/depth.dart';

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
                  DepthSurface(
                    shape: BoxShape.circle,
                    width: 150,
                    height: 150,
                    level: 3,
                    color: avatarColor,
                    shadowTint: avatarColor,
                    rimTint: avatarColor,
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
              child: DepthButton(
                shape: BoxShape.circle,
                width: 72,
                height: 72,
                padding: EdgeInsets.zero,
                colors: [colorScheme.error, AppDepth.darken(colorScheme.error, 0.25)],
                onPressed: _endCall,
                child: Icon(
                  Icons.call_end_rounded,
                  color: colorScheme.onError,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
