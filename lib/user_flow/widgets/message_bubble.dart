import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chatapp/models/message.dart';
import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/widgets/glass_container.dart';
import 'package:chatapp/widgets/confirmation_sheet.dart';
import 'package:chatapp/widgets/depth.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final int index;
  final VoidCallback? onReply;
  final List<Message>? allMessages;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.index,
    this.onReply,
    this.allMessages,
  });

  /// Upper bound for a bubble's width on wide layouts. On phones the bubble
  /// is still limited to 70% of the available width.
  static const double maxBubbleWidth = 560;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: Offset(widget.isMe ? 0.15 : -0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Message? _findRepliedMessage(String? replyToId) {
    if (replyToId == null || widget.allMessages == null) return null;
    try {
      return widget.allMessages!.firstWhere((m) => m.id == replyToId);
    } catch (e) {
      return null;
    }
  }

  void _showEditDeleteMenu(BuildContext context) {
    final chatService = context.read<FirebaseChatService>();
    final colorScheme = Theme.of(context).colorScheme;

    showAdaptiveSheet<void>(
      context: context,
      dialogMaxWidth: 320,
      builder: (context, isDialog) => GlassContainer(
        borderRadius: isDialog
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(20)),
        blurSigma: 20,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDialog) ...[
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
            ],
            ListTile(
              leading: Icon(Icons.edit_rounded, color: colorScheme.primary),
              title: Text(
                'Edit',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, chatService);
              },
            ),
            Divider(color: colorScheme.outline.withOpacity(0.3)),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: colorScheme.error),
              title: Text('Delete', style: TextStyle(color: colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, chatService);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    FirebaseChatService chatService,
  ) async {
    final newText = await showInputSheet(
      context: context,
      title: 'Edit Message',
      initialValue: widget.message.text,
      hintText: 'Type your message...',
      confirmText: 'Save',
    );

    if (newText != null && newText.isNotEmpty) {
      chatService.editMessage(widget.message.id, newText);
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    FirebaseChatService chatService,
  ) async {
    final confirmed = await showConfirmationSheet<bool>(
      context: context,
      title: 'Delete Message?',
      message: 'This action cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.delete_outline_rounded,
      isDanger: true,
    );

    if (confirmed == true) {
      chatService.deleteMessage(widget.message.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.message.isSystem) {
      return FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.message.text.contains('joined')
                        ? Icons.person_add_rounded
                        : Icons.person_remove_rounded,
                    size: 16,
                    color: widget.message.text.contains('joined')
                        ? colorScheme.onlineGreen
                        : colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.message.text, style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final avatarColor = getAvatarColor(widget.message.username);
    // Sent bubbles are filled with the accent, so their text is inverted.
    final textColor = widget.isMe
        ? colorScheme.onSentBubble
        : colorScheme.onSurface;
    final metaColor = widget.isMe
        ? colorScheme.onSentBubble.withOpacity(0.75)
        : colorScheme.onSurfaceVariant;
    final quoteColor = widget.isMe
        ? colorScheme.onSentBubble.withOpacity(0.18)
        : colorScheme.surfaceContainerHighest.withOpacity(0.5);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bubbleMaxWidth = math.min(
                constraints.maxWidth * 0.7,
                MessageBubble.maxBubbleWidth,
              );
              final canOpenMenu = widget.isMe && !widget.message.isSystem;
              final canReply = !widget.isMe && widget.onReply != null;
              return Row(
                mainAxisAlignment: widget.isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!widget.isMe) ...[
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: avatarColor,
                      child: Text(
                        widget.message.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: MouseRegion(
                      cursor: canOpenMenu || canReply
                          ? SystemMouseCursors.click
                          : MouseCursor.defer,
                      child: GestureDetector(
                        onLongPress: canOpenMenu
                            ? () => _showEditDeleteMenu(context)
                            : null,
                        // Right-click on desktop opens the same menu as long-press.
                        onSecondaryTap: canOpenMenu
                            ? () => _showEditDeleteMenu(context)
                            : null,
                        onTap: canReply ? () => widget.onReply!() : null,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppDepth.raisedFill(
                              colorScheme,
                              widget.isMe
                                  ? colorScheme.sentBubble
                                  : colorScheme.receivedBubble,
                            ),
                            boxShadow: AppDepth.shadows(
                              colorScheme,
                              level: 1,
                              tint: widget.isMe ? colorScheme.sentBubble : null,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(widget.isMe ? 16 : 4),
                              bottomRight: Radius.circular(
                                widget.isMe ? 4 : 16,
                              ),
                            ),
                            // Lit top edge.
                            border: Border.all(
                              color: AppDepth.lighten(
                                widget.isMe
                                    ? colorScheme.sentBubble
                                    : colorScheme.receivedBubble,
                                colorScheme.brightness == Brightness.dark
                                    ? 0.14
                                    : 0.0,
                              ).withOpacity(0.9),
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!widget.isMe)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    widget.message.username,
                                    style: TextStyle(
                                      color: avatarColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (widget.message.replyTo != null)
                                Builder(
                                  builder: (context) {
                                    final repliedMessage = _findRepliedMessage(
                                      widget.message.replyTo,
                                    );
                                    if (repliedMessage == null) {
                                      return const SizedBox.shrink();
                                    }
                                    final replyAvatarColor = getAvatarColor(
                                      repliedMessage.username,
                                    );
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: quoteColor,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border(
                                          left: BorderSide(
                                            color: replyAvatarColor,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            repliedMessage.username,
                                            style: TextStyle(
                                              color: replyAvatarColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            repliedMessage.text,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: metaColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              Text(
                                widget.message.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat(
                                      'HH:mm',
                                    ).format(widget.message.timestamp),
                                    style: TextStyle(
                                      color: metaColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (widget.message.isEdited) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      'edited',
                                      style: TextStyle(
                                        color: metaColor,
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isMe) const SizedBox(width: 10),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
