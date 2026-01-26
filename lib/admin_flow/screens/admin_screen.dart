import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/admin_flow/services/admin_service.dart';
import 'package:chatapp/admin_flow/screens/admin_user_messages_screen.dart';
import 'package:chatapp/admin_flow/screens/user_activity_screen.dart';
import 'package:chatapp/services/auth_service.dart';
import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/utils/page_transitions.dart';
import 'package:chatapp/widgets/glass_container.dart';
import 'package:chatapp/user_flow/screens/auth_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _staggerController;
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().loadAllData();
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    _searchController.dispose();
    super.dispose();
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

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    String username,
    AdminService adminService,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
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
              Text('Delete User',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete \"$username\"? This action cannot be undone.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
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

    if (confirm == true) {
      try {
        await adminService.deleteUser(username);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('User deleted successfully'),
              backgroundColor: colorScheme.primary,
            ),
          );
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
        return false;
      }
    }
    return false;
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final adminService = context.watch<AdminService>();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: adminService.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        adminService.setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.5),
                ),
              ),
            ),
            onChanged: (value) {
              adminService.setSearchQuery(value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: Text(adminService.showOnlineOnly ? 'Online Only' : 'All Users'),
                  selected: adminService.showOnlineOnly,
                  onSelected: (selected) {
                    adminService.setShowOnlineOnly(selected);
                  },
                  avatar: Icon(
                    adminService.showOnlineOnly
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PopupMenuButton<String>(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sort: ${adminService.sortBy}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onSelected: (value) {
                    adminService.setSortBy(value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'name',
                      child: Text('Sort by Name'),
                    ),
                    const PopupMenuItem(
                      value: 'activity',
                      child: Text('Sort by Activity'),
                    ),
                    const PopupMenuItem(
                      value: 'messages',
                      child: Text('Sort by Messages'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<AdminService>(
      builder: (context, adminService, _) {
        if (adminService.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        final stats = adminService.getOverallStatistics();

        return RefreshIndicator(
          onRefresh: () async {
            await adminService.loadAllData();
          },
          color: colorScheme.primary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.people_rounded,
                      title: 'Total Users',
                      value: '${stats['totalUsers']}',
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.chat_bubble_rounded,
                      title: 'Total Messages',
                      value: '${stats['totalMessages']}',
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.online_prediction_rounded,
                      title: 'Online Users',
                      value: '${stats['onlineUsers']}',
                      color: colorScheme.onlineGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context: context,
                      icon: Icons.forum_rounded,
                      title: 'Conversations',
                      value: '${stats['totalConversations']}',
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Top Users Section
              Text('Top Active Users', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              if ((stats['topUsers'] as List).isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No user activity yet',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...((stats['topUsers'] as List).asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['username'] as String,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${user['messageCount']} messages',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                })),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<AdminService>(
      builder: (context, adminService, _) {
        if (adminService.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        final filteredUsers = adminService.getFilteredUsers();
        if (filteredUsers.isEmpty) {
          return Center(
            child: Text(
              'No users yet',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await adminService.loadAllData();
                },
                color: colorScheme.primary,
                child: AnimatedBuilder(
                  animation: _staggerController,
                  builder: (context, _) {
                    final staggerAnims =
                        _buildStaggerAnimations(filteredUsers.length);
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final username = filteredUsers[index];
                        final isOnline =
                            adminService.userOnlineStatus[username] ?? false;
                        final avatarColor = getAvatarColor(username);
                        final userMessages =
                            adminService.getUserMessages(username);

                        final animValue = index < staggerAnims.length
                            ? staggerAnims[index].value
                            : 1.0;

                        return Opacity(
                          opacity: animValue,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - animValue)),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      colorScheme.outline.withOpacity(0.5),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                leading: Hero(
                                  tag: 'avatar_conv_$username',
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: avatarColor,
                                        child: Text(
                                          username[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
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
                                              color: colorScheme.onlineGreen,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: colorScheme.surface,
                                                width: 2.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                title:
                                    Text(username, style: textTheme.titleMedium),
                                subtitle: Text(
                                  '${isOnline ? "Online" : "Offline"} • ${userMessages.length} messages',
                                  style: TextStyle(
                                    color: isOnline
                                        ? colorScheme.onlineGreen
                                        : colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    SharedAxisPageRoute(
                                      page: AdminUserMessagesScreen(
                                        username: username,
                                        messages: userMessages,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUsersTab() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<AdminService>(
      builder: (context, adminService, _) {
        if (adminService.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        final filteredUsers = adminService.getFilteredUsers();
        if (filteredUsers.isEmpty) {
          return Center(
            child: Text(
              'No users yet',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await adminService.loadAllData();
                },
                color: colorScheme.primary,
                child: AnimatedBuilder(
                  animation: _staggerController,
                  builder: (context, _) {
                    final staggerAnims =
                        _buildStaggerAnimations(filteredUsers.length);
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final username = filteredUsers[index];
                        final isOnline =
                            adminService.userOnlineStatus[username] ?? false;
                        final avatarColor = getAvatarColor(username);
                        final userMessages =
                            adminService.getUserMessages(username);

                        final animValue = index < staggerAnims.length
                            ? staggerAnims[index].value
                            : 1.0;

                        return Opacity(
                          opacity: animValue,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - animValue)),
                            child: Dismissible(
                              key: Key(username),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: Icon(
                                  Icons.delete_rounded,
                                  color: colorScheme.onPrimary,
                                  size: 28,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await _showDeleteConfirmation(
                                  context,
                                  username,
                                  adminService,
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        colorScheme.outline.withOpacity(0.5),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  leading: Hero(
                                    tag: 'avatar_user_$username',
                                    child: Stack(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: avatarColor,
                                          child: Text(
                                            username[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
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
                                                color: colorScheme.onlineGreen,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: colorScheme.surface,
                                                  width: 2.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  title:
                                      Text(username, style: textTheme.titleMedium),
                                  subtitle: Text(
                                    '${isOnline ? "Online" : "Offline"} • ${userMessages.length} messages',
                                    style: TextStyle(
                                      color: isOnline
                                          ? colorScheme.onlineGreen
                                          : colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      SharedAxisPageRoute(
                                        page: UserActivityScreen(
                                          username: username,
                                        ),
                                      ),
                                    );
                                  },
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
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: colorScheme.onPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Consumer<AdminService>(
                        builder: (context, adminService, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin Panel',
                                style: textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text(
                              _currentIndex == 0
                                  ? '${adminService.getFilteredUsers().length} users, ${adminService.allMessages.length} conversations'
                                  : '${adminService.getFilteredUsers().length} users',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final chatService =
                            context.read<FirebaseChatService>();
                        final authService =
                            context.read<AuthService>();
                        await chatService.logout();
                        await authService.signOut();
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            FadeScalePageRoute(
                              page: const AuthScreen(),
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.logout_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildConversationsTab(),
                  _buildUsersTab(),
                  _buildStatisticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GlassContainer(
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurfaceVariant,
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
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Statistics',
            ),
          ],
        ),
      ),
    );
  }
}

