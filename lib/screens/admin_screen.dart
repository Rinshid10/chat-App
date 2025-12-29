import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../services/firebase_chat_service.dart';
import 'admin_user_messages_screen.dart';
import 'user_activity_screen.dart';
import 'username_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  int _currentIndex = 0;

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
    
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().loadAllData();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    String username,
    AdminService adminService,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Delete User',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "$username"? This action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFff6b6b)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await adminService.deleteUser(username);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Color(0xFF00ff88),
            ),
          );
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: const Color(0xFFff6b6b),
            ),
          );
        }
        return false;
      }
    }
    return false;
  }

  Widget _buildConversationsTab() {
    return Consumer<AdminService>(
      builder: (context, adminService, _) {
        if (adminService.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF00d9ff),
            ),
          );
        }

        final filteredUsers = adminService.getFilteredUsers();
        if (filteredUsers.isEmpty) {
          return Center(
            child: Text(
              'No users yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          );
        }

        return FadeTransition(
          opacity: _fadeAnim,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final username = filteredUsers[index];
              final isOnline = adminService.userOnlineStatus[username] ?? false;
              final avatarColor = _getAvatarColor(username);
              final userMessages = adminService.getUserMessages(username);

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
                    '${isOnline ? "Online" : "Offline"} • ${userMessages.length} messages',
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
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => AdminUserMessagesScreen(
                          username: username,
                          messages: userMessages,
                        ),
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
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return Consumer<AdminService>(
      builder: (context, adminService, _) {
        if (adminService.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF00d9ff),
            ),
          );
        }

        final filteredUsers = adminService.getFilteredUsers();
        if (filteredUsers.isEmpty) {
          return Center(
            child: Text(
              'No users yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          );
        }

        return FadeTransition(
          opacity: _fadeAnim,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final username = filteredUsers[index];
              final isOnline = adminService.userOnlineStatus[username] ?? false;
              final avatarColor = _getAvatarColor(username);
              final userMessages = adminService.getUserMessages(username);

              return Dismissible(
                key: Key(username),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff6b6b), Color(0xFFff5252)],
                    ),
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
                  return await _showDeleteConfirmation(context, username, adminService);
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
                      '${isOnline ? "Online" : "Offline"} • ${userMessages.length} messages',
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
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => UserActivityScreen(
                            username: username,
                          ),
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
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
              Container(
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
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<AdminService>(
                        builder: (context, adminService, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF00d9ff), Color(0xFF00ff88)],
                              ).createShader(bounds),
                              child: const Text(
                                'Admin Panel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentIndex == 0
                                  ? '${adminService.getFilteredUsers().length} users, ${adminService.allMessages.length} conversations'
                                  : '${adminService.getFilteredUsers().length} users',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Logout button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          final chatService = context.read<FirebaseChatService>();
                          await chatService.logout();
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => const UsernameScreen(),
                                transitionDuration: const Duration(milliseconds: 300),
                                transitionsBuilder: (_, animation, __, child) {
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
              // Content
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildConversationsTab(),
                    _buildUsersTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
            ],
          ),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF00d9ff),
          unselectedItemColor: Colors.white.withOpacity(0.5),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Conversations',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }
}
