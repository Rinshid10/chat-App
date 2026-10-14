import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/utils/responsive.dart';
import 'package:chatapp/widgets/depth.dart';

/// Pill-shaped message bar: a raised 3D pill holding a round "+" button,
/// the text field, an attach button and a round accent send button that
/// dims while empty.
class MessageInput extends StatefulWidget {
  final Message? replyingToMessage;
  final VoidCallback? onCancelReply;

  const MessageInput({super.key, this.replyingToMessage, this.onCancelReply});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _canSend = false;

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    context.read<FirebaseChatService>().sendMessage(
      _controller.text,
      replyTo: widget.replyingToMessage?.id,
    );
    _controller.clear();
    setState(() => _canSend = false);
    _focusNode.requestFocus();
    widget.onCancelReply?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final desktop = isDesktopLayout(context);
    final sideInset = desktop ? 24.0 : 12.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(sideInset, 8, sideInset, desktop ? 20 : 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingToMessage != null) _buildReplyStrip(colorScheme),
            DepthSurface(
              level: 2,
              radius: 32,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  DepthSurface(
                    shape: BoxShape.circle,
                    width: 44,
                    height: 44,
                    color: colorScheme.surfaceContainerHighest,
                    onTap: () {},
                    tooltip: 'More',
                    child: Icon(
                      Icons.add_rounded,
                      size: 22,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onChanged: (text) {
                        final canSend = text.trim().isNotEmpty;
                        if (canSend != _canSend) {
                          setState(() => _canSend = canSend);
                        }
                      },
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    tooltip: 'Attach',
                    icon: Icon(
                      Icons.attach_file_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _canSend ? 1.0 : 0.45,
                    child: DepthButton(
                      onPressed: _sendMessage,
                      shape: BoxShape.circle,
                      width: 44,
                      height: 44,
                      padding: EdgeInsets.zero,
                      child: const Icon(Icons.send_rounded, size: 20),
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

  Widget _buildReplyStrip(ColorScheme colorScheme) {
    final reply = widget.replyingToMessage!;
    final accent = getAvatarColor(reply.username);

    return DepthSurface(
      inset: true,
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${reply.username}',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reply.text,
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
    );
  }
}
