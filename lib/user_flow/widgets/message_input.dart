import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/widgets/glass_container.dart';

class MessageInput extends StatefulWidget {
  final Message? replyingToMessage;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    this.replyingToMessage,
    this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _canSend = false;

  late AnimationController _sendBtnController;
  late Animation<double> _sendBtnAnim;

  @override
  void initState() {
    super.initState();
    _sendBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sendBtnAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _sendBtnController, curve: Curves.easeInOut),
    );
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      _sendBtnController.forward().then((_) {
        _sendBtnController.reverse();
      });

      context.read<FirebaseChatService>().sendMessage(
            _controller.text,
            replyTo: widget.replyingToMessage?.id,
          );
      _controller.clear();
      setState(() => _canSend = false);
      _focusNode.requestFocus();
      widget.onCancelReply?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: Border(
        top: BorderSide(
          color: colorScheme.outline.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingToMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 32,
                      decoration: BoxDecoration(
                        color: getAvatarColor(
                          widget.replyingToMessage!.username,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${widget.replyingToMessage!.username}',
                            style: TextStyle(
                              color: getAvatarColor(
                                widget.replyingToMessage!.username,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.replyingToMessage!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCancelReply,
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.emoji_emotions_outlined,
                            color: colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.replyingToMessage != null
                                  ? 'Reply to ${widget.replyingToMessage!.username}...'
                                  : 'Type a message...',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                            textCapitalization:
                                TextCapitalization.sentences,
                            onChanged: (text) {
                              final canSend = text.trim().isNotEmpty;
                              if (canSend != _canSend) {
                                setState(() => _canSend = canSend);
                              }
                            },
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _canSend ? 0.0 : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _canSend ? 0 : 44,
                            child: _canSend
                                ? null
                                : IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.attach_file_rounded,
                                      color: colorScheme.onSurfaceVariant,
                                      size: 22,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: _canSend ? 1.0 : 0.0,
                  child: ScaleTransition(
                    scale: _sendBtnAnim,
                    child: GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

