import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/services/call_notification_service.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/utils/page_transitions.dart';
import 'package:chatapp/widgets/glass_container.dart';
import 'package:chatapp/user_flow/screens/chat_screen.dart';
import 'package:chatapp/user_flow/screens/add_user_screen.dart';
import 'package:chatapp/user_flow/screens/incoming_call_screen.dart';
import 'package:chatapp/user_flow/widgets/app_drawer.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen>
    with TickerProviderStateMixin {
  List<String> _users = [];
  Map<String, bool> _userOnlineStatus = {};
  bool _isLoading = true;
  StreamSubscription? _usersSubscription;
  StreamSubscription? _statusSubscription;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _staggerController;
  late AnimationController _fabFloatController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fabFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _loadUsers();

    // Listen for incoming calls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupCallListener();
    });
  }

  void _setupCallListener() {
    final chatService = context.read<FirebaseChatService>();
    final callNotificationService = context.read<CallNotificationService>();
    
    if (chatService.username != null) {
      callNotificationService.listenForIncomingCalls(chatService.username!);
      
      // Listen for incoming call changes
      callNotificationService.addListener(_handleIncomingCall);
    }
  }

  void _handleIncomingCall() {
    final callNotificationService = context.read<CallNotificationService>();
    
    if (callNotificationService.hasIncomingCall && mounted) {
      // Store values locally to avoid null issues during async operation
      final callId = callNotificationService.currentCallId;
      final callerUsername = callNotificationService.callerUsername;
      final username = context.read<FirebaseChatService>().username ?? '';
      
      if (callId == null || callerUsername == null) {
        return;
      }
      
      // Get call details
      callNotificationService.getCallDetails(callId, username).then((callData) {
        if (callData != null && 
            mounted && 
            callNotificationService.hasIncomingCall) {
          final channelName = callData['channelName'] as String?;
          
          if (channelName != null && channelName.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IncomingCallScreen(
                  callerUsername: callerUsername,
                  callId: callId,
                  channelName: channelName,
                ),
              ),
            );
            // Clear the notification after showing
            callNotificationService.clearIncomingCall();
          }
        }
      });
    }
  }

  List<Animation<double>> _buildStaggerAnimations(int count) {
    final animations = <Animation<double>>[];
    final itemCount = count.clamp(0, 20);
    for (int i = 0; i < itemCount; i++) {
      final start = (i * 50) / 1500;
      final end = (start + 400 / 1500).clamp(0.0, 1.0);
      animations.add(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    }
    return animations;
  }

  Future<void> _loadUsers() async {
    final chatService = context.read<FirebaseChatService>();

    final contacts = await chatService.getContacts();
    final usersWithMessages = await chatService.getUsersWithConversations();

    final allUsers = <String>{};
    allUsers.addAll(contacts);
    allUsers.addAll(usersWithMessages);

    setState(() {
      _users = allUsers.toList();
      _isLoading = false;
    });

    _staggerController.reset();
    _staggerController.forward();

    final chatServiceRef = context.read<FirebaseChatService>();
    if (chatServiceRef.username != null) {
      final contactsRef = FirebaseDatabase.instance
          .ref('users/${chatServiceRef.username}/contacts');
      contactsRef.onValue.listen((event) async {
        if (mounted) {
          await _refreshUsers();
        }
      });
    }

    final conversationsRef =
        FirebaseDatabase.instance.ref('conversations');
    _usersSubscription = conversationsRef.onChildAdded.listen((event) async {
      if (mounted) {
        await _refreshUsers();
      }
    });

    conversationsRef.onChildChanged.listen((event) async {
      if (mounted) {
        await _refreshUsers();
      }
    });

    final usersRef = FirebaseDatabase.instance.ref('users');
    _statusSubscription = usersRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final onlineStatus = <String, bool>{};

        for (var entry in data.entries) {
          final username = entry.key as String;
          final userData = entry.value as Map<dynamic, dynamic>?;
          if (userData != null && userData['online'] == true) {
            onlineStatus[username] = true;
          }
        }

        if (mounted) {
          setState(() {
            _userOnlineStatus = onlineStatus;
          });
        }
      }
    });
  }

  Future<void> _refreshUsers() async {
    final chatService = context.read<FirebaseChatService>();
    final contacts = await chatService.getContacts();
    final usersWithMessages = await chatService.getUsersWithConversations();

    final allUsers = <String>{};
    allUsers.addAll(contacts);
    allUsers.addAll(usersWithMessages);

    if (mounted) {
      setState(() {
        _users = allUsers.toList();
      });
    }
  }

  void _openChat(String otherUsername) {
    final chatService = context.read<FirebaseChatService>();
    chatService.loadConversation(otherUsername);

    Navigator.push(
      context,
      SharedAxisPageRoute(page: ChatScreen(otherUsername: otherUsername)),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String username) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(20),
          blurSigma: 20,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete Conversation?',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Delete all messages with $username?\nThis action cannot be undone.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style:
                          TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final chatService =
                          context.read<FirebaseChatService>();
                      try {
                        await chatService.removeContact(username);
                        await chatService.deleteConversation(username);
                        if (mounted) _loadUsers();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Error removing contact: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Delete',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _usersSubscription?.cancel();
    _statusSubscription?.cancel();
    _fadeController.dispose();
    _staggerController.dispose();
    _fabFloatController.dispose();
    
    // Remove call listener
    try {
      context.read<CallNotificationService>().removeListener(_handleIncomingCall);
    } catch (e) {
      // Ignore if context is not available
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<FirebaseChatService>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Glass Header
            FadeTransition(
              opacity: _fadeAnim,
              child: GlassContainer(
                padding: const EdgeInsets.all(20),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        (chatService.username ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chatService.username ?? 'User',
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: chatService.isConnected
                                      ? colorScheme.onlineGreen
                                      : colorScheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                chatService.isConnected
                                    ? 'Online'
                                    : 'Offline',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                        icon: Icon(
                          Icons.settings_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        tooltip: 'Settings',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Users list
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : _users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_outlined,
                                size: 56,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No contacts yet',
                                style: textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add users',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : AnimatedBuilder(
                          animation: _staggerController,
                          builder: (context, _) {
                            final staggerAnims =
                                _buildStaggerAnimations(_users.length);
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final username = _users[index];
                                final isOnline =
                                    _userOnlineStatus[username] ?? false;
                                final avatarColor =
                                    getAvatarColor(username);

                                final animValue = index <
                                        staggerAnims.length
                                    ? staggerAnims[index].value
                                    : 1.0;

                                return Opacity(
                                  opacity: animValue,
                                  child: Transform.translate(
                                    offset: Offset(
                                        0, 20 * (1 - animValue)),
                                    child: Dismissible(
                                      key: Key(username),
                                      direction:
                                          DismissDirection.endToStart,
                                      background: Container(
                                        margin: const EdgeInsets.only(
                                            bottom: 8),
                                        decoration: BoxDecoration(
                                          color: colorScheme.error,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        alignment:
                                            Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                            right: 20),
                                        child: Icon(
                                          Icons.delete_rounded,
                                          color: colorScheme.onPrimary,
                                          size: 28,
                                        ),
                                      ),
                                      confirmDismiss:
                                          (direction) async {
                                        _showDeleteConfirmation(
                                          context,
                                          username,
                                        );
                                        return false;
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(
                                                bottom: 8),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: colorScheme.outline
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets
                                                  .symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                          leading: Hero(
                                            tag:
                                                'avatar_$username',
                                            child: Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundColor:
                                                      avatarColor,
                                                  child: Text(
                                                    username[0]
                                                        .toUpperCase(),
                                                    style:
                                                        const TextStyle(
                                                      color:
                                                          Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                if (isOnline)
                                                  Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: Container(
                                                      width: 14,
                                                      height: 14,
                                                      decoration:
                                                          BoxDecoration(
                                                        color: colorScheme
                                                            .onlineGreen,
                                                        shape: BoxShape
                                                            .circle,
                                                        border:
                                                            Border.all(
                                                          color: colorScheme
                                                              .surface,
                                                          width: 2.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          title: Text(
                                            username,
                                            style: textTheme
                                                .titleMedium,
                                          ),
                                          subtitle: Text(
                                            isOnline
                                                ? 'Online'
                                                : 'Offline',
                                            style: TextStyle(
                                              color: isOnline
                                                  ? colorScheme
                                                      .onlineGreen
                                                  : colorScheme
                                                      .onSurfaceVariant,
                                              fontSize: 13,
                                            ),
                                          ),
                                          trailing: Icon(
                                            Icons
                                                .chevron_right_rounded,
                                            color: colorScheme
                                                .onSurfaceVariant,
                                            size: 20,
                                          ),
                                          onTap: () =>
                                              _openChat(username),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabFloatController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -3 * _fabFloatController.value),
            child: child,
          );
        },
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              BottomSlidePageRoute(page: const AddUserScreen()),
            ).then((_) {
              _loadUsers();
            });
          },
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

