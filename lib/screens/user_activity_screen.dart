import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';

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

  Future<void> _editUser() async {
    _editController.text = widget.username;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Edit User',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _editController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'New Username',
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00d9ff)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _editController.text.trim()),
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF00d9ff)),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != widget.username) {
      try {
        final adminService = context.read<AdminService>();
        await adminService.editUser(widget.username, result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User updated successfully'),
              backgroundColor: Color(0xFF00ff88),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating user: $e'),
              backgroundColor: const Color(0xFFff6b6b),
            ),
          );
        }
      }
    }
  }

  Future<void> _logoutUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Logout User',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to logout "${widget.username}"?',
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
              'Logout',
              style: TextStyle(color: Color(0xFFff9f43)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final adminService = context.read<AdminService>();
        await adminService.logoutUser(widget.username);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User logged out successfully'),
              backgroundColor: Color(0xFF00ff88),
            ),
          );
          // Reload stats to update online status
          await _loadUserStats();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out user: $e'),
              backgroundColor: const Color(0xFFff6b6b),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Delete User',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.username}"? This action cannot be undone.',
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
        final adminService = context.read<AdminService>();
        await adminService.deleteUser(widget.username);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: Color(0xFF00ff88),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: const Color(0xFFff6b6b),
            ),
          );
        }
      }
    }
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
                    // Back button
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
                    // User avatar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getAvatarColor(widget.username),
                            _getAvatarColor(widget.username).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _getAvatarColor(widget.username).withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.username[0].toUpperCase(),
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
                              widget.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (_userStats != null)
                            Text(
                              _userStats!['isOnline'] == true
                                  ? 'Online'
                                  : 'Offline',
                              style: TextStyle(
                                color: _userStats!['isOnline'] == true
                                    ? const Color(0xFF00ff88)
                                    : Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Logout button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _logoutUser,
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 22,
                        ),
                        tooltip: 'Logout User',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _editUser,
                        icon: Icon(
                          Icons.edit_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 22,
                        ),
                        tooltip: 'Edit User',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _deleteUser,
                        icon: Icon(
                          Icons.delete_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 22,
                        ),
                        tooltip: 'Delete User',
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00d9ff),
                        ),
                      )
                    : _userStats == null
                        ? Center(
                            child: Text(
                              'Failed to load user data',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadUserStats,
                            color: const Color(0xFF00d9ff),
                            child: ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                // Statistics Cards
                                _buildStatCard(
                                  icon: Icons.message_rounded,
                                  title: 'Total Messages',
                                  value: '${_userStats!['totalMessages']}',
                                  color: const Color(0xFF00d9ff),
                                ),
                                const SizedBox(height: 12),
                                _buildStatCard(
                                  icon: Icons.people_rounded,
                                  title: 'People Messaged',
                                  value: '${(_userStats!['peopleMessaged'] as List).length}',
                                  color: const Color(0xFF00ff88),
                                ),
                                const SizedBox(height: 12),
                                if (_userStats!['lastSeen'] != null)
                                  _buildStatCard(
                                    icon: Icons.access_time_rounded,
                                    title: 'Last Seen',
                                    value: DateFormat('MMM dd, yyyy HH:mm').format(
                                      _userStats!['lastSeen'] as DateTime,
                                    ),
                                    color: const Color(0xFFff9f43),
                                  ),
                                const SizedBox(height: 24),
                                
                                // Login Times Section
                                Text(
                                  'Login History',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if ((_userStats!['loginTimes'] as List).isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'No login history available',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...((_userStats!['loginTimes'] as List<DateTime>)
                                      .take(20)
                                      .map((loginTime) => Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.1),
                                                  Colors.white.withOpacity(0.05),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.1),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF00d9ff)
                                                        .withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(
                                                    Icons.login_rounded,
                                                    color: Color(0xFF00d9ff),
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
                                                        DateFormat('MMM dd, yyyy')
                                                            .format(loginTime),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        DateFormat('HH:mm:ss')
                                                            .format(loginTime),
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.6),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))),
                                
                                const SizedBox(height: 24),
                                
                                // People Messaged Section
                                Text(
                                  'People Messaged',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if ((_userStats!['peopleMessaged'] as List).isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'No conversations yet',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...((_userStats!['peopleMessaged'] as List<String>)
                                      .map((person) => Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.1),
                                                  Colors.white.withOpacity(0.05),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.1),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        _getAvatarColor(person),
                                                        _getAvatarColor(person)
                                                            .withOpacity(0.7),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      person[0].toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    person,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
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
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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

