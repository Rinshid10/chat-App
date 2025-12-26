import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_chat_service.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({super.key});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _canSend = false;
  bool _isFocused = false;

  late AnimationController _sendBtnController;
  late Animation<double> _sendBtnAnim;

  @override
  void initState() {
    super.initState();
    _sendBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sendBtnAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendBtnController, curve: Curves.easeOut),
    );

    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      // Animate send button
      _sendBtnController.forward().then((_) {
        _sendBtnController.reverse();
      });

      context.read<FirebaseChatService>().sendMessage(_controller.text);
      _controller.clear();
      setState(() => _canSend = false);
      _focusNode.requestFocus();
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF16213e).withOpacity(0.95),
            const Color(0xFF1a1a2e),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(_isFocused ? 0.15 : 0.08),
                Colors.white.withOpacity(_isFocused ? 0.1 : 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _isFocused
                  ? const Color(0xFF00d9ff).withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
              width: _isFocused ? 2 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF00d9ff).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Emoji button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: _isFocused
                        ? const Color(0xFF00d9ff)
                        : Colors.white.withOpacity(0.5),
                    size: 24,
                  ),
                ),
              ),
              // Text field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (text) {
                    final canSend = text.trim().isNotEmpty;
                    if (canSend != _canSend) {
                      setState(() => _canSend = canSend);
                    }
                  },
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              // Attach button
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _canSend ? 0.0 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _canSend ? 0 : 48,
                  child: _canSend
                      ? null
                      : IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.attach_file_rounded,
                            color: Colors.white.withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                ),
              ),
              // Send button
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 4),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: _canSend ? 1.0 : 0.0,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.0, end: 0.9).animate(
                      CurvedAnimation(
                        parent: _sendBtnController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00d9ff), Color(0xFF00ff88)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00d9ff).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
