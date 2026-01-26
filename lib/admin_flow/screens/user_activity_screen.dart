import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:chatapp/admin_flow/services/admin_service.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/widgets/glass_container.dart';

class UserActivityScreen extends StatefulWidget {
  final String username;

  const UserActivityScreen({
    super.key,
    required this.username,
  });

  @override
  State<UserActivityScreen> createState() => _UserActivityScreenState();
}

class _UserActivityScreenState extends State<UserActivityScreen> {
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    setState(() => _isLoading = true);
    final adminService = context.read<AdminService>();
    final stats = await adminService.getUserStatistics(widget.username);
    setState(() {
      _userStats = stats;
      _isLoading = false;
    });
  }

  Future<void> _editUser() async {
    final colorScheme = Theme.of(context).colorScheme;
    _editController.text = widget.username;

    final result = await showDialog<String>(
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
              Text('Edit User',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _editController,
                decoration: const InputDecoration(
                  labelText: 'New Username',
                ),
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
                    onPressed: () => Navigator.pop(
                      context,
                      _editController.text.trim(),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty && result != widget.username) {
      try {
        final adminService = context.read<AdminService>();
        await adminService.editUser(widget.username, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('User updated successfully'),
              backgroundColor: colorScheme.primary,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating user: $e'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _logoutUser() async {
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
              Text('Logout User',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to logout "${widget.username}"?',
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
                      style:
                          TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'Logout',
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
        final adminService = context.read<AdminService>();
        await adminService.logoutUser(widget.username);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('User logged out successfully'),
              backgroundColor: colorScheme.primary,
            ),
          );
          await _loadUserStats();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out user: $e'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _banUser() async {
    final colorScheme = Theme.of(context).colorScheme;
    final adminService = context.read<AdminService>();
    final isBanned = await adminService.isUserBanned(widget.username);

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
              Text(
                isBanned ? 'Unban User' : 'Ban User',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                isBanned
                    ? 'Are you sure you want to unban "${widget.username}"?'
                    : 'Are you sure you want to ban "${widget.username}"? They will be logged out immediately.',
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
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      isBanned ? 'Unban' : 'Ban',
                      style: TextStyle(
                        color: isBanned
                            ? colorScheme.primary
                            : colorScheme.error,
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

    if (confirm == true) {
      try {
        await adminService.banUser(widget.username, banned: !isBanned);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBanned
                    ? 'User unbanned successfully'
                    : 'User banned successfully',
              ),
              backgroundColor: colorScheme.primary,
            ),
          );
          await _loadUserStats();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error ${isBanned ? "unbanning" : "banning"} user: $e'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteUser() async {
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
                'Are you sure you want to delete "${widget.username}"? This action cannot be undone.',
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
                      style:
                          TextStyle(color: colorScheme.onSurfaceVariant),
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
        final adminService = context.read<AdminService>();
        await adminService.deleteUser(widget.username);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('User deleted successfully'),
              backgroundColor: colorScheme.primary,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final avatarColor = getAvatarColor(widget.username);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            GlassContainer(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Hero(
                    tag: 'avatar_user_${widget.username}',
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: avatarColor,
                      child: Text(
                        widget.username[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.username, style: textTheme.titleLarge),
                        const SizedBox(height: 2),
                        if (_userStats != null)
                          Text(
                            _userStats!['isOnline'] == true
                                ? 'Online'
                                : 'Offline',
                            style: TextStyle(
                              color: _userStats!['isOnline'] == true
                                  ? colorScheme.onlineGreen
                                  : colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _logoutUser,
                    icon: Icon(
                      Icons.logout_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    tooltip: 'Logout User',
                  ),
                  IconButton(
                    onPressed: _banUser,
                    icon: Icon(
                      Icons.block_rounded,
                      color: colorScheme.error,
                      size: 22,
                    ),
                    tooltip: 'Ban/Unban User',
                  ),
                  IconButton(
                    onPressed: _editUser,
                    icon: Icon(
                      Icons.edit_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    tooltip: 'Edit User',
                  ),
                  IconButton(
                    onPressed: _deleteUser,
                    icon: Icon(
                      Icons.delete_rounded,
                      color: colorScheme.error,
                      size: 22,
                    ),
                    tooltip: 'Delete User',
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : _userStats == null
                      ? Center(
                          child: Text(
                            'Failed to load user data',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadUserStats,
                          color: colorScheme.primary,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Statistics Cards
                              _buildStatCard(
                                context: context,
                                icon: Icons.message_rounded,
                                title: 'Total Messages',
                                value: '${_userStats!['totalMessages']}',
                              ),
                              const SizedBox(height: 12),
                              _buildStatCard(
                                context: context,
                                icon: Icons.people_rounded,
                                title: 'People Messaged',
                                value:
                                    '${(_userStats!['peopleMessaged'] as List).length}',
                              ),
                              const SizedBox(height: 12),
                              if (_userStats!['lastSeen'] != null)
                                _buildStatCard(
                                  context: context,
                                  icon: Icons.access_time_rounded,
                                  title: 'Last Seen',
                                  value: DateFormat('MMM dd, yyyy HH:mm')
                                      .format(
                                    _userStats!['lastSeen'] as DateTime,
                                  ),
                                ),
                              const SizedBox(height: 24),

                              // Login Times Section
                              Text('Login History',
                                  style: textTheme.titleMedium),
                              const SizedBox(height: 12),
                              if ((_userStats!['loginTimes'] as List).isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color:
                                        colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No login history available',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...((_userStats!['loginTimes']
                                        as List<DateTime>)
                                    .take(20)
                                    .map(
                                      (loginTime) => Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: colorScheme.outline
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.login_rounded,
                                                color: colorScheme
                                                    .onPrimaryContainer,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    DateFormat(
                                                            'MMM dd, yyyy')
                                                        .format(loginTime),
                                                    style: textTheme.bodyLarge
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    DateFormat('HH:mm:ss')
                                                        .format(loginTime),
                                                    style:
                                                        textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),

                              const SizedBox(height: 24),

                              // People Messaged Section
                              Text('People Messaged',
                                  style: textTheme.titleMedium),
                              const SizedBox(height: 12),
                              if ((_userStats!['peopleMessaged'] as List)
                                  .isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No conversations yet',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...((_userStats!['peopleMessaged']
                                        as List<String>)
                                    .map(
                                      (person) => Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: colorScheme.outline
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor:
                                                  getAvatarColor(person),
                                              child: Text(
                                                person[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                person,
                                                style: textTheme.bodyLarge
                                                    ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

