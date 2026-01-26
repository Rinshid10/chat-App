import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:chatapp/models/message.dart';
import 'package:chatapp/admin_flow/services/admin_service.dart';
import 'package:chatapp/theme/app_colors.dart';
import 'package:chatapp/utils/avatar_utils.dart';
import 'package:chatapp/widgets/glass_container.dart';

class AdminUserMessagesScreen extends StatefulWidget {
  final String username;
  final List<Message> messages;

  const AdminUserMessagesScreen({
    super.key,
    required this.username,
    required this.messages,
  });

  @override
  State<AdminUserMessagesScreen> createState() => _AdminUserMessagesScreenState();
}

class _AdminUserMessagesScreenState extends State<AdminUserMessagesScreen> {

  Future<void> _deleteMessage(Message message) async {
    final colorScheme = Theme.of(context).colorScheme;
    if (message.conversationId == null) return;

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
                'Delete Message',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this message? This action cannot be undone.',
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
        await adminService.deleteMessage(
          message.conversationId!,
          message.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Message deleted successfully'),
              backgroundColor: colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting message: $e'),
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
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 16),
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
                    tag: 'avatar_conv_${widget.username}',
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
                        Text(
                          '${widget.messages.length} messages',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Messages list
            Expanded(
              child: widget.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 56,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.messages.length,
                      itemBuilder: (context, index) {
                        final message = widget.messages[index];
                        final isFromThisUser = message.username == widget.username;
                        final msgAvatarColor =
                            getAvatarColor(message.username);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: isFromThisUser
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isFromThisUser) ...[
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: msgAvatarColor,
                                  child: Text(
                                    message.username[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: GestureDetector(
                                  onLongPress: () => _deleteMessage(message),
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width * 0.7,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFromThisUser
                                          ? colorScheme.sentBubble
                                          : colorScheme.receivedBubble,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(
                                          isFromThisUser ? 18 : 4,
                                        ),
                                        bottomRight: Radius.circular(
                                          isFromThisUser ? 4 : 18,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!isFromThisUser)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              message.username,
                                              style: TextStyle(
                                                color: msgAvatarColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          message.text,
                                          style: TextStyle(
                                            color: isFromThisUser
                                                ? colorScheme.onPrimary
                                                : colorScheme.onSurface,
                                            fontSize: 15,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              DateFormat('HH:mm')
                                                  .format(message.timestamp),
                                              style: TextStyle(
                                                color: isFromThisUser
                                                    ? colorScheme.onPrimary
                                                        .withOpacity(0.7)
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (message.isEdited) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                'edited',
                                                style: TextStyle(
                                                  color: isFromThisUser
                                                      ? colorScheme.onPrimary
                                                          .withOpacity(0.6)
                                                      : colorScheme
                                                          .onSurfaceVariant,
                                                  fontSize: 10,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (isFromThisUser) const SizedBox(width: 8),
                            ],
                          ),
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

