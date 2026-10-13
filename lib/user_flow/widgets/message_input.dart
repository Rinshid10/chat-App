import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/utils/responsive.dart';

/// Pill-shaped message bar: a round "+" button, the text field, an attach
/// button and a round accent send button that dims while empty.
class MessageInput extends StatefulWidget {
  final Message? replyingToMessage;
  final VoidCallback? onCancelReply;

  const MessageInput({super.key, this.replyingToMessage, this.onCancelReply});

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
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: colorScheme.outline),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _RoundButton(
                    icon: Icons.add_rounded,
                    background: colorScheme.surfaceContainerHighest,
                    foreground: colorScheme.onSurface,
                    onTap: () {},
                    tooltip: 'More',
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
                    child: ScaleTransition(
                      scale: _sendBtnAnim,
                      child: _RoundButton(
                        icon: Icons.send_rounded,
                        background: colorScheme.primary,
                        foreground: colorScheme.onPrimary,
                        onTap: _sendMessage,
                        tooltip: 'Send',
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

  Widget _buildReplyStrip(ColorScheme colorScheme) {
    final reply = widget.replyingToMessage!;
    final accent = getAvatarColor(reply.username);

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final String tooltip;

  const _RoundButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 22, color: foreground),
          ),
        ),
      ),
    );
  }
}
