import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:chatapp/services/firebase_chat_service.dart';
import 'package:chatapp/services/call_notification_service.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/theme/theme_provider.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/utils/page_transitions.dart';
import 'package:chatapp/utils/responsive.dart';
import 'package:chatapp/widgets/brand_mark.dart';
import 'package:chatapp/widgets/glass_container.dart';
import 'package:chatapp/widgets/confirmation_sheet.dart';
import 'package:chatapp/user_flow/screens/chat_screen.dart';
import 'package:chatapp/user_flow/screens/add_user_screen.dart';
import 'package:chatapp/user_flow/screens/incoming_call_screen.dart';
import 'package:chatapp/user_flow/widgets/app_drawer.dart';
import 'package:chatapp/user_flow/widgets/voice_call_launcher.dart';
import 'package:chatapp/user_flow/widgets/welcome_pane.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen>
    with TickerProviderStateMixin {
  List<String> _users = [];
  Map<String, bool> _userOnlineStatus = {};

  /// Contact whose chat is shown in the right pane of the desktop layout.
  String? _selectedUser;
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
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
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

    // Filter out admin user
    allUsers.remove('adminrinshid');

    setState(() {
      _users = allUsers.toList();
      _isLoading = false;
    });

    _staggerController.reset();
    _staggerController.forward();

    final chatServiceRef = context.read<FirebaseChatService>();
    if (chatServiceRef.username != null) {
      final contactsRef = FirebaseDatabase.instance.ref(
        'users/${chatServiceRef.username}/contacts',
      );
      contactsRef.onValue.listen((event) async {
        if (mounted) {
          await _refreshUsers();
        }
      });
    }

    final conversationsRef = FirebaseDatabase.instance.ref('conversations');
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

    // Filter out admin user
    allUsers.remove('adminrinshid');

    if (mounted) {
      setState(() {
        _users = allUsers.toList();
      });
    }
  }

  void _openChat(String otherUsername) {
    final chatService = context.read<FirebaseChatService>();
    chatService.loadConversation(otherUsername);

    if (isDesktopLayout(context)) {
      setState(() => _selectedUser = otherUsername);
      return;
    }

    Navigator.push(
      context,
      SharedAxisPageRoute(page: ChatScreen(otherUsername: otherUsername)),
    );
  }

  void _openAddUser() {
    final Future<dynamic> closed;
    if (isDesktopLayout(context)) {
      final maxHeight = MediaQuery.sizeOf(context).height - 48;
      closed = showDialog<void>(
        context: context,
        barrierColor: Colors.black38,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SizedBox(
            width: 520,
            height: maxHeight < 680 ? maxHeight : 680,
            child: const AddUserScreen(),
          ),
        ),
      );
    } else {
      closed = Navigator.push(
        context,
        BottomSlidePageRoute(page: const AddUserScreen()),
      );
    }
    closed.then((_) {
      if (mounted) _loadUsers();
    });
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String username,
  ) async {
    final confirmed = await showConfirmationSheet<bool>(
      context: context,
      title: 'Delete Conversation?',
      message:
          'Delete all messages with $username?\nThis action cannot be undone.',
      confirmText: 'Delete',
      icon: Icons.delete_outline_rounded,
      isDanger: true,
    );

    if (confirmed == true && mounted) {
      final chatService = context.read<FirebaseChatService>();
      try {
        await chatService.removeContact(username);
        await chatService.deleteConversation(username);
        if (mounted) {
          if (_selectedUser == username) {
            setState(() => _selectedUser = null);
          }
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error removing contact: $e')));
        }
      }
    }
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
      context.read<CallNotificationService>().removeListener(
        _handleIncomingCall,
      );
    } catch (e) {
      // Ignore if context is not available
    }

    super.dispose();
  }

  final GlobalKey<ScaffoldState> _shellKey = GlobalKey<ScaffoldState>();

  /// Settings live in the drawer: left-hand on phones, right-hand (under the
  /// avatar menu) on desktop.
  void _openSettings() {
    final shell = _shellKey.currentState;
    if (shell == null) return;
    if (isDesktopLayout(context)) {
      shell.openEndDrawer();
    } else {
      shell.openDrawer();
    }
  }

  void _toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.read<ThemeProvider>().setThemeMode(
      isDark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return isDesktopLayout(context)
        ? _buildDesktop(context)
        : _buildMobile(context);
  }

  // ---------------------------------------------------------------------------
  // Phone layout
  // ---------------------------------------------------------------------------

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      key: _shellKey,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildMobileHeader(context),
            Expanded(child: _buildContactList(context, desktop: false)),
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
          onPressed: _openAddUser,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    final chatService = context.watch<FirebaseChatService>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final me = chatService.username ?? 'User';

    return FadeTransition(
      opacity: _fadeAnim,
      child: GlassContainer(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
        child: Row(
          children: [
            const BrandMark(size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    me,
                    style: textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  _StatusLabel(online: chatService.isConnected),
                ],
              ),
            ),
            IconButton(
              onPressed: _toggleTheme,
              tooltip: 'Switch theme',
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
            IconButton(
              onPressed: _openSettings,
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Desktop / web layout: sidebar + top bar + content
  // ---------------------------------------------------------------------------

  Widget _buildDesktop(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatService = context.watch<FirebaseChatService>();
    final sidebarWidth = (MediaQuery.sizeOf(context).width * 0.24).clamp(
      280.0,
      330.0,
    );
    final selected = _selectedUser;

    return Scaffold(
      key: _shellKey,
      endDrawer: const AppDrawer(),
      body: Row(
        children: [
          SizedBox(width: sidebarWidth, child: _buildSidebar(context)),
          VerticalDivider(width: 1, thickness: 1, color: colorScheme.outline),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Divider(height: 1, thickness: 1, color: colorScheme.outline),
                Expanded(
                  child: selected == null
                      ? WelcomePane(
                          username: chatService.username ?? 'there',
                          onAddContact: _openAddUser,
                          onAppLock: _openSettings,
                          onToggleTheme: _toggleTheme,
                        )
                      : ChatScreen(
                          key: ValueKey('chat_$selected'),
                          otherUsername: selected,
                          embedded: true,
                          showHeader: false,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: Row(
            children: [
              const BrandMark(size: 40),
              const SizedBox(width: 14),
              Text(
                'ChatFlow',
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _buildNavItem(
          icon: Icons.home_rounded,
          label: 'Home',
          selected: _selectedUser == null,
          onTap: () => setState(() => _selectedUser = null),
        ),
        _buildNavItem(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Add contact',
          selected: false,
          onTap: _openAddUser,
        ),
        _buildNavItem(
          icon: Icons.settings_rounded,
          label: 'Settings',
          selected: false,
          onTap: _openSettings,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Divider(height: 1, color: colorScheme.outline),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 10, 16, 6),
          child: Text(
            'Recent Chats',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: _buildContactList(context, desktop: true)),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: selected
            ? colorScheme.primary.withOpacity(0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 20),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final chatService = context.watch<FirebaseChatService>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = _selectedUser;
    final me = chatService.username ?? 'U';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            if (selected != null) ...[
              CircleAvatar(
                radius: 20,
                backgroundColor: getAvatarColor(selected),
                child: Text(
                  selected[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selected, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  _StatusLabel(online: _userOnlineStatus[selected] ?? false),
                ],
              ),
            ],
            const Spacer(),
            if (selected != null)
              IconButton(
                onPressed: () => confirmAndStartCall(context, selected),
                tooltip: 'Voice call',
                icon: const Icon(Icons.call_rounded),
              ),
            IconButton(
              onPressed: _toggleTheme,
              tooltip: 'Switch theme',
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openSettings,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: getAvatarColor(me),
                        child: Text(
                          me[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Contact list (shared by both layouts)
  // ---------------------------------------------------------------------------

  Widget _buildContactList(BuildContext context, {required bool desktop}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 14),
              Text(
                'No contacts yet',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desktop
                    ? 'Use "Add contact" to find people'
                    : 'Tap the + button to add users',
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final staggerAnims = _buildStaggerAnimations(_users.length);
        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 12 : 8,
            vertical: 4,
          ),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final username = _users[index];
            final animValue = index < staggerAnims.length
                ? staggerAnims[index].value
                : 1.0;

            final tile = _buildContactTile(
              context,
              username: username,
              desktop: desktop,
            );

            return Opacity(
              opacity: animValue,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - animValue)),
                child: desktop
                    ? tile
                    : Dismissible(
                        key: Key(username),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(
                            Icons.delete_rounded,
                            color: colorScheme.onPrimary,
                            size: 26,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          _showDeleteConfirmation(context, username);
                          return false;
                        },
                        child: tile,
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required String username,
    required bool desktop,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOnline = _userOnlineStatus[username] ?? false;
    final avatarColor = getAvatarColor(username);
    final isSelected = desktop && _selectedUser == username;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: Hero(
            tag: 'avatar_$username',
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: avatarColor,
                  child: Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: colorScheme.onlineGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
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
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _StatusLabel(online: isOnline),
          ),
          trailing: desktop
              ? IconButton(
                  onPressed: () => _showDeleteConfirmation(context, username),
                  tooltip: 'Delete conversation',
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
          onTap: () => _openChat(username),
        ),
      ),
    );
  }
}

/// Small "• Online / Offline" label with a colored dot.
class _StatusLabel extends StatelessWidget {
  final bool online;

  const _StatusLabel({required this.online});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = online
        ? colorScheme.onlineGreen
        : colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          online ? 'Online' : 'Offline',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
