import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';

class AdminService extends ChangeNotifier {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _conversationsRef = FirebaseDatabase.instance.ref('conversations');

  List<String> _users = [];
  Map<String, List<Message>> _allMessages = {};
  Map<String, bool> _userOnlineStatus = {};
  bool _isLoading = true;
  StreamSubscription? _usersSubscription;
  StreamSubscription? _conversationsSubscription;

  List<String> get users => _users;
  Map<String, List<Message>> get allMessages => _allMessages;
  Map<String, bool> get userOnlineStatus => _userOnlineStatus;
  bool get isLoading => _isLoading;

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    // Load all users
    try {
      final usersSnapshot = await _usersRef.get();
      if (usersSnapshot.exists) {
        final usersData = usersSnapshot.value as Map<dynamic, dynamic>;
        final usersList = <String>[];
        final onlineStatus = <String, bool>{};
        
        for (var entry in usersData.entries) {
          final username = entry.key as String;
          final userData = entry.value as Map<dynamic, dynamic>?;
          usersList.add(username);
          if (userData != null && userData['online'] == true) {
            onlineStatus[username] = true;
          }
        }
        
        _users = usersList;
        _userOnlineStatus = onlineStatus;
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }

    // Load all conversations and messages
    try {
      final conversationsSnapshot = await _conversationsRef.get();
      if (conversationsSnapshot.exists) {
        final conversationsData = conversationsSnapshot.value as Map<dynamic, dynamic>;
        final allMessages = <String, List<Message>>{};
        
        for (var conversationEntry in conversationsData.entries) {
          final conversationId = conversationEntry.key as String;
          final conversationData = conversationEntry.value as Map<dynamic, dynamic>?;
          
          if (conversationData != null && conversationData['messages'] != null) {
            final messagesData = conversationData['messages'] as Map<dynamic, dynamic>;
            final messages = <Message>[];
            
            for (var messageEntry in messagesData.entries) {
              final messageData = Map<String, dynamic>.from(messageEntry.value as Map);
              messageData['id'] = messageEntry.key;
              messageData['conversationId'] = conversationId;
              final message = Message.fromJson(messageData);
              messages.add(message);
            }
            
            // Sort by timestamp
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            allMessages[conversationId] = messages;
          }
        }
        
        _allMessages = allMessages;
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      _isLoading = false;
      notifyListeners();
    }

    // Listen for real-time updates
    _usersSubscription = _usersRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final onlineStatus = <String, bool>{};
        final usersList = <String>[];
        
        for (var entry in data.entries) {
          final username = entry.key as String;
          final userData = entry.value as Map<dynamic, dynamic>?;
          usersList.add(username);
          if (userData != null && userData['online'] == true) {
            onlineStatus[username] = true;
          }
        }
        
        _users = usersList;
        _userOnlineStatus = onlineStatus;
        notifyListeners();
      }
    });

    _conversationsSubscription = _conversationsRef.onChildChanged.listen((event) {
      if (event.snapshot.value != null) {
        final conversationId = event.snapshot.key;
        final conversationData = event.snapshot.value as Map<dynamic, dynamic>?;
        
        if (conversationData != null && conversationData['messages'] != null) {
          final messagesData = conversationData['messages'] as Map<dynamic, dynamic>;
          final messages = <Message>[];
          
          for (var messageEntry in messagesData.entries) {
            final messageData = Map<String, dynamic>.from(messageEntry.value as Map);
            messageData['id'] = messageEntry.key;
            messageData['conversationId'] = conversationId;
            final message = Message.fromJson(messageData);
            messages.add(message);
          }
          
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          _allMessages[conversationId!] = messages;
          notifyListeners();
        }
      }
    });
  }

  List<Message> getUserMessages(String username) {
    // Get all conversations this user is part of
    final userConversations = _allMessages.entries.where((entry) {
      final conversationId = entry.key;
      return conversationId.contains(username);
    }).toList();
    
    // Get all messages from this user's conversations
    final userMessages = <Message>[];
    for (var conversation in userConversations) {
      userMessages.addAll(conversation.value);
    }
    userMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return userMessages;
  }

  List<String> getFilteredUsers() {
    return _users.where((u) => u.toLowerCase() != 'adminrinshid').toList();
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(String username) async {
    try {
      final userRef = _usersRef.child(username);
      final userSnapshot = await userRef.get();
      
      Map<String, dynamic> stats = {
        'totalMessages': 0,
        'peopleMessaged': <String>{},
        'loginTimes': <DateTime>[],
        'lastSeen': null,
        'isOnline': false,
      };

      // Get user data
      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>?;
        if (userData != null) {
          stats['isOnline'] = userData['online'] == true;
          
          // Get lastSeen
          if (userData['lastSeen'] != null) {
            final lastSeenTimestamp = userData['lastSeen'];
            if (lastSeenTimestamp is int) {
              stats['lastSeen'] = DateTime.fromMillisecondsSinceEpoch(lastSeenTimestamp);
            }
          }
          
          // Get login times history
          if (userData['loginTimes'] != null) {
            final loginTimes = userData['loginTimes'] as Map<dynamic, dynamic>?;
            if (loginTimes != null) {
              final loginList = <DateTime>[];
              for (var entry in loginTimes.entries) {
                final timestamp = entry.value;
                if (timestamp is int) {
                  loginList.add(DateTime.fromMillisecondsSinceEpoch(timestamp));
                }
              }
              loginList.sort((a, b) => b.compareTo(a)); // Most recent first
              stats['loginTimes'] = loginList;
            }
          }
        }
      }

      // Count messages and people messaged
      final userMessages = getUserMessages(username);
      stats['totalMessages'] = userMessages.length;
      
      final peopleMessaged = <String>{};
      for (var message in userMessages) {
        if (message.recipient != null && message.recipient != username) {
          peopleMessaged.add(message.recipient!);
        }
        // Also check conversations to find other participants
        if (message.conversationId != null) {
          final conversationId = message.conversationId!;
          if (conversationId.startsWith('chat_')) {
            final withoutPrefix = conversationId.replaceFirst('chat_', '');
            final parts = withoutPrefix.split('_');
            if (parts.length >= 2) {
              final user1 = parts[0];
              final user2 = parts.sublist(1).join('_');
              if (user1 == username && user2 != username) {
                peopleMessaged.add(user2);
              } else if (user2 == username && user1 != username) {
                peopleMessaged.add(user1);
              }
            }
          }
        }
      }
      stats['peopleMessaged'] = peopleMessaged.toList();

      return stats;
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return {
        'totalMessages': 0,
        'peopleMessaged': <String>[],
        'loginTimes': <DateTime>[],
        'lastSeen': null,
        'isOnline': false,
      };
    }
  }

  // Edit user (rename username)
  Future<void> editUser(String oldUsername, String newUsername) async {
    try {
      if (oldUsername == newUsername) return;
      
      // Get old user data
      final oldUserRef = _usersRef.child(oldUsername);
      final oldUserSnapshot = await oldUserRef.get();
      
      if (!oldUserSnapshot.exists) {
        throw Exception('User not found');
      }
      
      final oldUserData = oldUserSnapshot.value as Map<dynamic, dynamic>;
      
      // Create new user with same data
      final newUserRef = _usersRef.child(newUsername);
      await newUserRef.set(oldUserData);
      
      // Update all conversations that reference this user
      final conversationsSnapshot = await _conversationsRef.get();
      if (conversationsSnapshot.exists) {
        final conversations = conversationsSnapshot.value as Map<dynamic, dynamic>;
        for (var entry in conversations.entries) {
          final conversationId = entry.key as String;
          if (conversationId.contains(oldUsername)) {
            // Create new conversation ID
            final withoutPrefix = conversationId.replaceFirst('chat_', '');
            final parts = withoutPrefix.split('_');
            if (parts.length >= 2) {
              final user1 = parts[0] == oldUsername ? newUsername : parts[0];
              final user2 = parts.sublist(1).join('_');
              final updatedUser2 = user2 == oldUsername ? newUsername : user2;
              
              final sorted = [user1, updatedUser2]..sort();
              final newConversationId = 'chat_${sorted[0]}_${sorted[1]}';
              
              // Update messages in conversation
              final conversationData = entry.value as Map<dynamic, dynamic>?;
              if (conversationData != null && conversationData['messages'] != null) {
                final messages = conversationData['messages'] as Map<dynamic, dynamic>;
                final updatedMessages = <String, dynamic>{};
                
                for (var msgEntry in messages.entries) {
                  final msgData = Map<String, dynamic>.from(msgEntry.value as Map);
                  if (msgData['username'] == oldUsername) {
                    msgData['username'] = newUsername;
                  }
                  if (msgData['recipient'] == oldUsername) {
                    msgData['recipient'] = newUsername;
                  }
                  updatedMessages[msgEntry.key] = msgData;
                }
                
                // Create new conversation
                await _conversationsRef.child(newConversationId).set({
                  'messages': updatedMessages,
                });
                
                // Delete old conversation if different ID
                if (conversationId != newConversationId) {
                  await _conversationsRef.child(conversationId).remove();
                }
              }
            }
          }
        }
      }
      
      // Delete old user
      await oldUserRef.remove();
      
      // Reload data
      await loadAllData();
    } catch (e) {
      debugPrint('Error editing user: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String username) async {
    try {
      // Delete user from users
      await _usersRef.child(username).remove();
      
      // Delete all conversations involving this user
      final conversationsSnapshot = await _conversationsRef.get();
      if (conversationsSnapshot.exists) {
        final conversations = conversationsSnapshot.value as Map<dynamic, dynamic>;
        final conversationsToDelete = <String>[];
        
        for (var entry in conversations.entries) {
          final conversationId = entry.key as String;
          if (conversationId.contains(username)) {
            conversationsToDelete.add(conversationId);
          }
        }
        
        for (var conversationId in conversationsToDelete) {
          await _conversationsRef.child(conversationId).remove();
        }
      }
      
      // Reload data
      await loadAllData();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  // Logout user (admin action) - forces logout from device
  Future<void> logoutUser(String username) async {
    try {
      await _usersRef.child(username).update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
        'forceLogout': true, // Flag to force logout from device
      });
      debugPrint('User logged out: $username');
    } catch (e) {
      debugPrint('Error logging out user: $e');
      rethrow;
    }
  }

  String _getConversationId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return 'chat_${sorted[0]}_${sorted[1]}';
  }

  Future<void> sendReply(String username, String text, String? replyToMessageId) async {
    try {
      // Generate conversation ID between admin and the user
      final conversationId = _getConversationId('adminrinshid', username);
      
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: 'adminrinshid',
        text: text.trim(),
        timestamp: DateTime.now(),
        isSystem: false,
        recipient: username,
        conversationId: conversationId,
        replyTo: replyToMessageId,
      );

      final conversationRef = _conversationsRef
          .child(conversationId)
          .child('messages');
      
      final pushRef = conversationRef.push();
      await pushRef.set(message.toJson());
      debugPrint('Reply sent successfully. Conversation: $conversationId, Message ID: ${pushRef.key}');
    } catch (e) {
      debugPrint('Error sending reply: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _conversationsSubscription?.cancel();
    super.dispose();
  }
}

