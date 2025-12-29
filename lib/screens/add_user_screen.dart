import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/firebase_chat_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen>
    with SingleTickerProviderStateMixin {
  List<String> _availableUsers = [];
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
    _loadAvailableUsers();
  }

  Future<void> _loadAvailableUsers() async {
    final chatService = context.read<FirebaseChatService>();
    final users = await chatService.getAllAvailableUsers();
    
    setState(() {
      _availableUsers = users;
      _isLoading = false;
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

    // Listen for new users being added
    _usersSubscription = usersRef.onChildAdded.listen((event) async {
      if (mounted) {
        final chatService = context.read<FirebaseChatService>();
        final updatedUsers = await chatService.getAllAvailableUsers();
        setState(() {
          _availableUsers = updatedUsers;
        });
      }
    });
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

  Future<void> _addContact(String username) async {
    final chatService = context.read<FirebaseChatService>();
    try {
      await chatService.addContact(username);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$username added to contacts'),
            backgroundColor: const Color(0xFF00ff88),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding contact: $e'),
            backgroundColor: Colors.red[300],
          ),
        );
      }
    }
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
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF00d9ff), Color(0xFF00ff88)],
                              ).createShader(bounds),
                              child: const Text(
                                'Add Users',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select users to add to your contacts',
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
              ),
              // Users list
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFF00d9ff),
                        ),
                      )
                    : _availableUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No users available',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'All users are already in your contacts',
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
                              itemCount: _availableUsers.length,
                              itemBuilder: (context, index) {
                                final username = _availableUsers[index];
                                final isOnline = _userOnlineStatus[username] ?? false;
                                final avatarColor = _getAvatarColor(username);
                                
                                return Container(
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
                                    trailing: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF00d9ff), Color(0xFF00ff88)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF00d9ff).withOpacity(0.3),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        onPressed: () => _addContact(username),
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        tooltip: 'Add to contacts',
                                      ),
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
    );
  }
}

