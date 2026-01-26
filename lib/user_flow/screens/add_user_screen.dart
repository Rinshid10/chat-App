import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/widgets/glass_container.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen>
    with TickerProviderStateMixin {
  List<String> _availableUsers = [];
  List<String> _filteredUsers = [];
  Map<String, bool> _userOnlineStatus = {};
  bool _isLoading = true;
  String _searchQuery = '';
  StreamSubscription? _usersSubscription;
  StreamSubscription? _statusSubscription;
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _staggerController;

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

    _searchController.addListener(_filterUsers);
    _loadAvailableUsers();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = _searchController.text;
      if (query.isEmpty) {
        _filteredUsers = _availableUsers;
      } else {
        _filteredUsers = _availableUsers
            .where((user) => user.toLowerCase().contains(query))
            .toList();
      }
    });
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
          curve: Interval(start.clamp(0.0, 1.0), end, curve: Curves.easeOutCubic),
        ),
      );
    }
    return animations;
  }

  Future<void> _loadAvailableUsers() async {
    final chatService = context.read<FirebaseChatService>();
    final users = await chatService.getAllAvailableUsers();

    setState(() {
      _availableUsers = users;
      _filteredUsers = users;
      _isLoading = false;
    });

    _staggerController.forward();

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

    _usersSubscription = usersRef.onChildAdded.listen((event) async {
      if (mounted) {
        final chatService = context.read<FirebaseChatService>();
        final updatedUsers = await chatService.getAllAvailableUsers();
        setState(() {
          _availableUsers = updatedUsers;
          _filterUsers();
        });
      }
    });
  }

  Future<void> _addContact(String username) async {
    final chatService = context.read<FirebaseChatService>();
    final colorScheme = Theme.of(context).colorScheme;
    try {
      await chatService.addContact(username);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$username added to contacts'),
            backgroundColor: colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding contact: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _statusSubscription?.cancel();
    _searchController.dispose();
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            FadeTransition(
              opacity: _fadeAnim,
              child: GlassContainer(
                padding: const EdgeInsets.fromLTRB(12, 12, 20, 16),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Contacts',
                                  style: textTheme.headlineMedium),
                              const SizedBox(height: 2),
                              Text(
                                '${_availableUsers.length} users available',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search bar
                    TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
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
                  : _availableUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 56,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No users available',
                                style: textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'All users are already in your contacts',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : _filteredUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 56,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No users found',
                                    style:
                                        textTheme.titleLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try a different search term',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            )
                          : AnimatedBuilder(
                              animation: _staggerController,
                              builder: (context, _) {
                                final staggerAnims =
                                    _buildStaggerAnimations(
                                        _filteredUsers.length);
                                return ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  itemCount: _filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final username =
                                        _filteredUsers[index];
                                    final isOnline =
                                        _userOnlineStatus[username] ??
                                            false;
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
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(
                                                  bottom: 8),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    16),
                                            border: Border.all(
                                              color: colorScheme
                                                  .outline
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
                                            leading: Stack(
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
                                            trailing: FilledButton.icon(
                                              onPressed: () =>
                                                  _addContact(
                                                      username),
                                              icon: const Icon(
                                                Icons
                                                    .person_add_rounded,
                                                size: 18,
                                              ),
                                              label: const Text('Add'),
                                              style: FilledButton
                                                  .styleFrom(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                  horizontal: 12,
                                                ),
                                                minimumSize:
                                                    const Size(0, 36),
                                              ),
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
    );
  }
}

