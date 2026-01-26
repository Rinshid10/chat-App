import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:chatapp/admin_flow/services/admin_service.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/widgets/glass_container.dart';
import 'package:chatapp/widgets/confirmation_sheet.dart';

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
  Map<String, dynamic>? _userFirestoreData;
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
    final firestoreData = await adminService.getUserFirestoreData(widget.username);
    setState(() {
      _userStats = stats;
      _userFirestoreData = firestoreData;
      _isLoading = false;
    });
  }

  Future<void> _editUser() async {
    final colorScheme = Theme.of(context).colorScheme;

    final result = await showInputSheet(
      context: context,
      title: 'Edit User',
      initialValue: widget.username,
      hintText: 'Enter new username',
      confirmText: 'Save',
      maxLines: 1,
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

    final confirm = await showConfirmationSheet<bool>(
      context: context,
      title: 'Logout User',
      message: 'Are you sure you want to logout "${widget.username}"?',
      confirmText: 'Logout',
      icon: Icons.logout_rounded,
      isDanger: true,
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

    final confirm = await showConfirmationSheet<bool>(
      context: context,
      title: isBanned ? 'Unban User' : 'Ban User',
      message: isBanned
          ? 'Are you sure you want to unban "${widget.username}"?'
          : 'Are you sure you want to ban "${widget.username}"? They will be logged out immediately.',
      confirmText: isBanned ? 'Unban' : 'Ban',
      icon: isBanned ? Icons.check_circle_outline_rounded : Icons.block_rounded,
      isDanger: !isBanned,
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

    final confirm = await showConfirmationSheet<bool>(
      context: context,
      title: 'Delete User',
      message: 'Are you sure you want to delete "${widget.username}"? This action cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.person_remove_rounded,
      isDanger: true,
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
                              // User Information Section
                              if (_userFirestoreData != null) ...[
                                Text(
                                  'User Information',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  context: context,
                                  icon: Icons.person_rounded,
                                  title: 'Username',
                                  value: _userFirestoreData!['username'] ?? widget.username,
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  context: context,
                                  icon: Icons.email_rounded,
                                  title: 'Email',
                                  value: _userFirestoreData!['email'] ?? 'N/A',
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  context: context,
                                  icon: Icons.lock_rounded,
                                  title: 'Password',
                                  value: _userFirestoreData!['password'] ?? 'N/A',
                                ),
                                const SizedBox(height: 12),
                                _buildInfoCard(
                                  context: context,
                                  icon: Icons.calendar_today_rounded,
                                  title: 'Registration Date',
                                  value: _formatRegistrationDate(_userFirestoreData!),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Statistics Section
                              Text(
                                'Statistics',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
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

  Widget _buildInfoCard({
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
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.onSecondaryContainer,
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
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRegistrationDate(Map<String, dynamic> firestoreData) {
    try {
      // Try to parse createdAtLocal first (ISO 8601 string)
      if (firestoreData['createdAtLocal'] != null) {
        final dateStr = firestoreData['createdAtLocal'] as String;
        if (dateStr.isNotEmpty) {
          final date = DateTime.parse(dateStr);
          return DateFormat('MMM dd, yyyy HH:mm:ss').format(date);
        }
      }
      
      // Fallback to createdAt (Timestamp)
      if (firestoreData['createdAt'] != null) {
        final timestamp = firestoreData['createdAt'];
        DateTime date;
        if (timestamp is Timestamp) {
          date = timestamp.toDate();
        } else if (timestamp is Map) {
          // Firestore Timestamp in Map format
          final seconds = timestamp['_seconds'] as int?;
          if (seconds != null) {
            date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          } else {
            return 'N/A';
          }
        } else {
          return 'N/A';
        }
        return DateFormat('MMM dd, yyyy HH:mm:ss').format(date);
      }
      
      return 'N/A';
    } catch (e) {
      debugPrint('Error formatting registration date: $e');
      return 'N/A';
    }
  }
}

