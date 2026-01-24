import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/auth_service.dart';
import '../services/firebase_chat_service.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';
import 'add_user_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final chatService = context.read<FirebaseChatService>();
    
    // Get both contacts and users with conversations
    final contacts = await chatService.getContacts();
    final usersWithMessages = await chatService.getUsersWithConversations();
    
    // Combine both lists and remove duplicates
    final allUsers = <String>{};
    allUsers.addAll(contacts);
    allUsers.addAll(usersWithMessages);
    
    setState(() {
      _users = allUsers.toList();
      _isLoading = false;
    });

    // Listen for contacts changes
    final chatServiceRef = context.read<FirebaseChatService>();
    if (chatServiceRef.username != null) {
      final contactsRef = FirebaseDatabase.instance.ref('users/${chatServiceRef.username}/contacts');
      contactsRef.onValue.listen((event) async {
        if (mounted) {
          await _refreshUsers();
        }
      });
    }
    
    // Listen for new conversations/messages
    final conversationsRef = FirebaseDatabase.instance.ref('conversations');
    _usersSubscription = conversationsRef.onChildAdded.listen((event) async {
      if (mounted) {
        await _refreshUsers();
      }
    });
    
    // Also listen for conversation changes (new messages)
    conversationsRef.onChildChanged.listen((event) async {
      if (mounted) {
        await _refreshUsers();
      }
    });

    // Listen for user status changes
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

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF00d9ff),
      const Color(0xFF00ff88),
      const Color(0xFFff6b6b),
      const Color(0xFFffd93d),
      const Color(0xFFc56cf0),
      const Color(0xFFff9f43),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  void _openChat(String otherUsername) {
    final chatService = context.read<FirebaseChatService>();
    chatService.loadConversation(otherUsername);
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChatScreen(otherUsername: otherUsername),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1a1a2e),
                const Color(0xFF16213e),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red[300],
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Conversation?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Delete all messages with $username?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red[300]?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red[300]!,
                      ),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final chatService = context.read<FirebaseChatService>();
                        try {
                          await chatService.removeContact(username);
                          await chatService.deleteConversation(username);
                          // Refresh contacts list
                          if (mounted) {
                            _loadUsers();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error removing contact: $e'),
                                backgroundColor: Colors.red[300],
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.red[300],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<FirebaseChatService>();
    
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                      // User avatar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00d9ff), Color(0xFF00ff88)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00d9ff).withOpacity(0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Text(
                          (chatService.username ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF00d9ff), Color(0xFF00ff88)],
                              ).createShader(bounds),
                              child: Text(
                                chatService.username ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: chatService.isConnected
                                        ? const Color(0xFF00ff88)
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: chatService.isConnected
                                            ? const Color(0xFF00ff88)
                                            : Colors.red,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  chatService.isConnected ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Logout icon button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            final authService = context.read<AuthService>();
                            await chatService.logout();
                            await authService.signOut();
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => const AuthScreen(),
                                  transitionDuration:
                                      const Duration(milliseconds: 300),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.logout_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 22,
                          ),
                          tooltip: 'Logout',
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
                          color: const Color(0xFF00d9ff),
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_add_outlined,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No contacts yet',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to add users',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnim,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                final username = _users[index];
                                final isOnline = _userOnlineStatus[username] ?? false;
                                final avatarColor = _getAvatarColor(username);
                                
                                return Dismissible(
                                  key: Key(username),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red[300],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    _showDeleteConfirmation(context, username);
                                    return false; // Don't dismiss automatically, let dialog handle it
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.1),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: Stack(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  avatarColor,
                                                  avatarColor.withOpacity(0.7),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: avatarColor.withOpacity(0.3),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                username[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
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
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF00ff88),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(0xFF1a1a2e),
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF00ff88)
                                                          .withOpacity(0.5),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Text(
                                        username,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        isOnline ? 'Online' : 'Offline',
                                        style: TextStyle(
                                          color: isOnline
                                              ? const Color(0xFF00ff88)
                                              : Colors.white.withOpacity(0.4),
                                          fontSize: 13,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 16,
                                      ),
                                      onTap: () => _openChat(username),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AddUserScreen(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                );
              },
            ),
          ).then((_) {
            // Refresh contacts when returning from AddUserScreen
            _loadUsers();
          });
        },
        backgroundColor: const Color(0xFF00d9ff),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}

