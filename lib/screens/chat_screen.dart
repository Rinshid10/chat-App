import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_chat_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String otherUsername;
  
  const ChatScreen({super.key, required this.otherUsername});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _headerController;
  late Animation<double> _headerAnim;
  Message? _replyingToMessage;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );
    _headerController.forward();
    
    // Load conversation when screen is initialized
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

  @override
  void dispose() {
    _scrollController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
            ],
          ),
        ),
        child: Column(
          children: [
            // Animated Header
            FadeTransition(
              opacity: _headerAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(_headerAnim),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    bottom: 16,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00d9ff).withOpacity(0.2),
                        const Color(0xFF00ff88).withOpacity(0.1),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Back button with animation
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Chat info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF00d9ff), Color(0xFF00ff88)],
                              ).createShader(bounds),
                              child: Text(
                                widget.otherUsername,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Consumer<FirebaseChatService>(
                              builder: (context, socket, _) => Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: socket.isConnected
                                          ? const Color(0xFF00ff88)
                                          : Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: socket.isConnected
                                              ? const Color(0xFF00ff88)
                                              : Colors.red,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    socket.isConnected ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Other user avatar
                      Builder(
                        builder: (context) {
                          final firstLetter = widget.otherUsername[0].toUpperCase();
                          final colors = [
                            const Color(0xFF00d9ff),
                            const Color(0xFF00ff88),
                            const Color(0xFFff6b6b),
                            const Color(0xFFffd93d),
                            const Color(0xFFc56cf0),
                            const Color(0xFFff9f43),
                          ];
                          final avatarColor = colors[widget.otherUsername.hashCode.abs() % colors.length];
                          
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  avatarColor,
                                  avatarColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: avatarColor.withOpacity(0.3),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Text(
                              firstLetter,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Messages area
            Expanded(
              child: Consumer<FirebaseChatService>(
                builder: (context, socket, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  if (socket.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.elasticOut,
                            builder: (_, value, child) => Transform.scale(
                              scale: value,
                              child: child,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF00d9ff).withOpacity(0.2),
                                    const Color(0xFF00ff88).withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 60,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to say hello!',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: socket.messages.length,
                    itemBuilder: (context, index) {
                      final message = socket.messages[index];
                      final isMe = message.username == socket.username;
                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                        index: index,
                        allMessages: socket.messages,
                        onReply: !isMe ? () {
                          setState(() {
                            _replyingToMessage = message;
                          });
                        } : null,
                      );
                    },
                  );
                },
              ),
            ),
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
    );
  }
}
