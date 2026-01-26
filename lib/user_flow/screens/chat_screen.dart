import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/services/call_notification_service.dart';
import 'package:chatapp/user_flow/widgets/message_bubble.dart';
import 'package:chatapp/user_flow/widgets/message_input.dart';
import 'package:chatapp/user_flow/screens/call_screen.dart';
import 'package:chatapp/widgets/glass_container.dart';
import 'package:chatapp/widgets/confirmation_sheet.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  final String otherUsername;

  const ChatScreen({super.key, required this.otherUsername});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _headerController;
  late Animation<double> _headerAnim;
  Message? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _headerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = context.read<FirebaseChatService>();
      chatService.loadConversation(widget.otherUsername);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _showCallConfirmation(BuildContext context) async {
    final shouldStartCall = await showConfirmationSheet<bool>(
      context: context,
      title: 'Start Call',
      message: 'Do you want to start an audio call with ${widget.otherUsername}?',
      confirmText: 'Call',
      icon: Icons.call_rounded,
    );

    if (shouldStartCall == true && mounted) {
      await _startCall(context);
    }
  }

  Future<void> _startCall(BuildContext context) async {
    // Request microphone permission
    final status = await Permission.microphone.request();
    
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone permission is required for voice calls'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        final shouldOpenSettings = await showConfirmationSheet<bool>(
          context: context,
          title: 'Microphone Permission Required',
          message: 'Please enable microphone permission in app settings to make voice calls.',
          confirmText: 'Open Settings',
          icon: Icons.mic_off_rounded,
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
      }
      return;
    }

    // Generate unique channel name for this call
    final channelName = 'test_call';
    
    // Send call notification to the other user
    final callNotificationService = context.read<CallNotificationService>();
    final chatService = context.read<FirebaseChatService>();
    
    try {
      await callNotificationService.sendCallInvitation(
        fromUsername: chatService.username ?? '',
        toUsername: widget.otherUsername,
        channelName: channelName,
      );

      // Navigate to call screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              otherUsername: widget.otherUsername,
              channelName: channelName,
            ),
          ),
        );
      }
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

  @override
  void dispose() {
    _scrollController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final avatarColor = getAvatarColor(widget.otherUsername);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Messages area (full screen, padded for header and input)
          Positioned.fill(
            child: Column(
              children: [
                // Space for the glass header
                SizedBox(height: topPadding + 76),
                // Messages
                Expanded(
                  child: Consumer<FirebaseChatService>(
                    builder: (context, service, _) {
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      if (service.messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 56,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style:
                                    textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to say hello!',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          16,
                        ),
                        itemCount: service.messages.length,
                        itemBuilder: (context, index) {
                          final message = service.messages[index];
                          final isMe =
                              message.username == service.username;
                          return MessageBubble(
                            message: message,
                            isMe: isMe,
                            index: index,
                            allMessages: service.messages,
                            onReply: !isMe
                                ? () {
                                    setState(() {
                                      _replyingToMessage = message;
                                    });
                                  }
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
                // Message input (glass applied inside the widget)
                MessageInput(
                  replyingToMessage: _replyingToMessage,
                  onCancelReply: () {
                    setState(() {
                      _replyingToMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
          // Glass Header (positioned on top, blurs messages behind it)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _headerAnim,
              child: GlassContainer(
                padding: EdgeInsets.only(
                  top: topPadding + 12,
                  bottom: 12,
                  left: 12,
                  right: 16,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.otherUsername,
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Consumer<FirebaseChatService>(
                            builder: (context, service, _) => Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: service.isConnected
                                        ? colorScheme.onlineGreen
                                        : colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  service.isConnected
                                      ? 'Online'
                                      : 'Offline',
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                    
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () => _showCallConfirmation(context),
                        icon: Icon(
                          Icons.call_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        tooltip: 'Voice Call',
                      ),
                    ),
                    const SizedBox(width: 8),
                      Hero(
                      tag: 'avatar_${widget.otherUsername}',
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: avatarColor,
                        child: Text(
                          widget.otherUsername[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

