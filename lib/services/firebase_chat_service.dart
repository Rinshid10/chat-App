import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class FirebaseChatService extends ChangeNotifier {
  final DatabaseReference _conversationsRef =
      FirebaseDatabase.instance.ref('conversations');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  final List<Message> _messages = [];
  bool _isConnected = false;
  String? _username;
  String? _currentConversationId;
  String? _currentOtherUsername;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _messagesChangedSubscription;
  StreamSubscription? _messagesRemovedSubscription;

  List<Message> get messages => _messages;
  bool get isConnected => _isConnected;
  String? get username => _username;
  String? get currentOtherUsername => _currentOtherUsername;

  FirebaseChatService() {
    _initConnectionListener();
  }

  void _initConnectionListener() {
    try {
      FirebaseDatabase.instance
          .ref('.info/connected')
          .onValue
          .listen((event) {
        _isConnected = event.snapshot.value as bool? ?? false;
        notifyListeners();
      }, onError: (error) {
        debugPrint('Connection listener error: $error');
        _isConnected = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing connection listener: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  void connect() {
    // Connection is handled per conversation now
  }

  String _getConversationId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return 'chat_${sorted[0]}_${sorted[1]}';
  }

  Future<List<String>> getUsers() async {
    try {
      final snapshot = await _usersRef.get();
      if (snapshot.exists) {
        final users = <String>[];
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          for (var entry in data.entries) {
            final username = entry.key as String;
            if (username != _username) {
              users.add(username);
            }
          }
        }
        return users;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  Future<List<String>> getContacts() async {
    if (_username == null) return [];
    
    try {
      final contactsRef = _usersRef.child(_username!).child('contacts');
      final snapshot = await contactsRef.get();
      if (snapshot.exists) {
        final contacts = <String>[];
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          for (var entry in data.entries) {
            contacts.add(entry.key as String);
          }
        }
        return contacts;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
      return [];
    }
  }

  Future<List<String>> getUsersWithConversations() async {
    if (_username == null) return [];
    
    try {
      final usersWithMessages = <String>{};
      
      // Get all conversations
      final conversationsSnapshot = await _conversationsRef.get();
      if (conversationsSnapshot.exists) {
        final conversations = conversationsSnapshot.value as Map<dynamic, dynamic>?;
        if (conversations != null) {
          for (var entry in conversations.entries) {
            final conversationId = entry.key as String;
            // Check if this conversation involves the current user
            // Format: chat_user1_user2 (where user1 and user2 are sorted alphabetically)
            if (conversationId.startsWith('chat_')) {
              // Extract usernames from conversation ID
              final withoutPrefix = conversationId.replaceFirst('chat_', '');
              final parts = withoutPrefix.split('_');
              
              // Since usernames are sorted alphabetically, we have two parts
              // One is the current user, the other is the other user
              if (parts.length >= 2) {
                final user1 = parts[0];
                // Join remaining parts in case username has underscore (unlikely but possible)
                final user2 = parts.sublist(1).join('_');
                
                // Add the other user (not the current user and not admin)
                if (user1 == _username && user2 != _username && user2 != 'adminrinshid') {
                  usersWithMessages.add(user2);
                } else if (user2 == _username && user1 != _username && user1 != 'adminrinshid') {
                  usersWithMessages.add(user1);
                }
              }
            }
          }
        }
      }
      
      debugPrint('Users with conversations: ${usersWithMessages.toList()}');
      return usersWithMessages.toList();
    } catch (e) {
      debugPrint('Error fetching users with conversations: $e');
      return [];
    }
  }

  Future<void> addContact(String contactUsername) async {
    if (_username == null || contactUsername == _username) return;
    
    try {
      final contactsRef = _usersRef.child(_username!).child('contacts');
      await contactsRef.child(contactUsername).set({
        'addedAt': ServerValue.timestamp,
      });
      debugPrint('Contact added: $contactUsername');
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding contact: $e');
      rethrow;
    }
  }

  Future<void> removeContact(String contactUsername) async {
    if (_username == null) return;
    
    try {
      final contactsRef = _usersRef.child(_username!).child('contacts');
      await contactsRef.child(contactUsername).remove();
      debugPrint('Contact removed: $contactUsername');
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing contact: $e');
      rethrow;
    }
  }

  Future<List<String>> getAllAvailableUsers() async {
    if (_username == null) return [];
    
    try {
      // Get all users
      final allUsersSnapshot = await _usersRef.get();
      if (!allUsersSnapshot.exists) return [];
      
      // Get current user's contacts
      final contacts = await getContacts();
      final contactsSet = contacts.toSet();
      
      final availableUsers = <String>[];
      final data = allUsersSnapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        for (var entry in data.entries) {
          final username = entry.key as String;
          // Exclude current user, admin user, and already added contacts
          if (username != _username && 
              username != 'adminrinshid' && 
              !contactsSet.contains(username)) {
            availableUsers.add(username);
          }
        }
      }
      return availableUsers;
    } catch (e) {
      debugPrint('Error fetching available users: $e');
      return [];
    }
  }

  Future<void> loadConversation(String otherUsername) async {
    if (_username == null) return;

    // Clear previous messages and unsubscribe
    _messages.clear();
    await _messagesSubscription?.cancel();
    await _messagesChangedSubscription?.cancel();
    await _messagesRemovedSubscription?.cancel();
    _messagesSubscription = null;
    _messagesChangedSubscription = null;
    _messagesRemovedSubscription = null;

    // Generate conversation ID
    _currentConversationId = _getConversationId(_username!, otherUsername);
    _currentOtherUsername = otherUsername;

    // Get conversation reference
    final conversationRef = _conversationsRef.child(_currentConversationId!).child('messages');

    // Load existing messages first
    final existingMessageIds = <String>{};
    try {
      final snapshot = await conversationRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final loadedMessages = <Message>[];
        for (var entry in data.entries) {
          final messageData = Map<String, dynamic>.from(entry.value as Map);
          final messageId = entry.key as String;
          messageData['id'] = messageId;
          messageData['conversationId'] = _currentConversationId;
          final message = Message.fromJson(messageData);
          loadedMessages.add(message);
          existingMessageIds.add(messageId);
        }
        // Sort by timestamp
        loadedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _messages.addAll(loadedMessages);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }

    // Set up listener for new messages (onChildAdded will fire for existing messages too, but we filter them)
    _messagesSubscription = conversationRef.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final messageId = event.snapshot.key;
        // Skip if this is an existing message we already loaded
        if (existingMessageIds.contains(messageId)) {
          debugPrint('Skipping existing message: $messageId');
          return;
        }
        
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data['id'] = messageId;
        data['conversationId'] = _currentConversationId;
        final message = Message.fromJson(data);
        
        debugPrint('New message received: $messageId from ${message.username}');
        
        // Double check for duplicates (safety)
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
          // Keep messages sorted
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          notifyListeners();
        } else {
          debugPrint('Duplicate message detected: $messageId');
        }
      }
    });

    // Listen for message changes (edits)
    _messagesChangedSubscription = conversationRef.onChildChanged.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data['id'] = event.snapshot.key;
        data['conversationId'] = _currentConversationId;
        final updatedMessage = Message.fromJson(data);
        
        final index = _messages.indexWhere((m) => m.id == updatedMessage.id);
        if (index != -1) {
          _messages[index] = updatedMessage;
          notifyListeners();
        }
      }
    });

    // Listen for message deletions
    _messagesRemovedSubscription = conversationRef.onChildRemoved.listen((event) {
      _messages.removeWhere((m) => m.id == event.snapshot.key);
      notifyListeners();
    });
  }

  Future<void> join(String username) async {
    _username = username;
    final userRef = _usersRef.child(username);

    // Get existing user data
    final userSnapshot = await userRef.get();
    Map<dynamic, dynamic> userData = {};

    if (userSnapshot.exists) {
      userData = Map<dynamic, dynamic>.from(userSnapshot.value as Map);
    }

    // Attach authenticated identity if available
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null) {
        userData['uid'] = authUser.uid;
        if (authUser.email != null) {
          userData['email'] = authUser.email;
        }
      }
    } catch (e) {
      debugPrint('Error attaching auth identity to user data: $e');
    }

    // Add login time to history
    final loginTimes = userData['loginTimes'] as Map<dynamic, dynamic>? ?? {};
    final loginTimeKey = DateTime.now().millisecondsSinceEpoch.toString();
    loginTimes[loginTimeKey] = ServerValue.timestamp;

    // Update user data
    userData['online'] = true;
    userData['lastSeen'] = ServerValue.timestamp;
    userData['loginTimes'] = loginTimes;
    userData['forceLogout'] = false; // Clear force logout flag when user logs in

    await userRef.set(userData);

    // Save username to local storage (for convenience only; auth drives sessions)
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString('username', username);
      debugPrint('Username saved: $username, Success: $saved');
    } catch (e) {
      debugPrint('Error saving username: $e');
    }

    notifyListeners();
  }

  Future<void> sendMessage(String text, {String? replyTo}) async {
    if (text.trim().isNotEmpty && 
        _username != null && 
        _currentConversationId != null &&
        _currentOtherUsername != null) {
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: _username!,
        text: text.trim(),
        timestamp: DateTime.now(),
        isSystem: false,
        recipient: _currentOtherUsername,
        conversationId: _currentConversationId,
        replyTo: replyTo,
      );
      
      final conversationRef = _conversationsRef
          .child(_currentConversationId!)
          .child('messages');
      
      try {
        final pushRef = conversationRef.push();
        await pushRef.set(message.toJson());
        debugPrint('Message sent successfully. Conversation: $_currentConversationId, Message ID: ${pushRef.key}');
      } catch (e) {
        debugPrint('Error sending message: $e');
        rethrow;
      }
    } else {
      debugPrint('Cannot send message: username=$_username, conversationId=$_currentConversationId, otherUser=$_currentOtherUsername');
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    if (newText.trim().isNotEmpty && 
        _currentConversationId != null &&
        messageId.isNotEmpty) {
      try {
        final messageRef = _conversationsRef
            .child(_currentConversationId!)
            .child('messages')
            .child(messageId);
        
        // Get current message data
        final snapshot = await messageRef.get();
        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          // Update text and add edited timestamp
          data['text'] = newText.trim();
          data['editedAt'] = DateTime.now().millisecondsSinceEpoch;
          
          await messageRef.update(data);
          
          // Local message will be updated by the onChildChanged listener
        } else {
          debugPrint('Message not found: $messageId');
        }
      } catch (e) {
        debugPrint('Error editing message: $e');
        rethrow;
      }
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (_currentConversationId != null && messageId.isNotEmpty) {
      try {
        final messageRef = _conversationsRef
            .child(_currentConversationId!)
            .child('messages')
            .child(messageId);
        
        await messageRef.remove();
        
        // Remove from local messages
        _messages.removeWhere((m) => m.id == messageId);
        notifyListeners();
      } catch (e) {
        debugPrint('Error deleting message: $e');
        rethrow;
      }
    }
  }

  Future<void> disconnect() async {
    await _messagesSubscription?.cancel();
    await _messagesChangedSubscription?.cancel();
    await _messagesRemovedSubscription?.cancel();
    _messagesSubscription = null;
    _messagesChangedSubscription = null;
    _messagesRemovedSubscription = null;
    
    if (_username != null) {
      await _usersRef.child(_username!).update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
    
    _messages.clear();
    _isConnected = false;
    _username = null;
    _currentConversationId = null;
    _currentOtherUsername = null;
    notifyListeners();
  }

  // Set user offline when app goes to background or closes
  Future<void> setOffline() async {
    if (_username != null) {
      try {
        await _usersRef.child(_username!).update({
          'online': false,
          'lastSeen': ServerValue.timestamp,
        });
        debugPrint('User set to offline: $_username');
      } catch (e) {
        debugPrint('Error setting user offline: $e');
      }
    }
  }

  // Set user online when app comes to foreground (if logged in)
  Future<void> setOnline() async {
    if (_username != null) {
      try {
        await _usersRef.child(_username!).update({
          'online': true,
          'lastSeen': ServerValue.timestamp,
        });
        debugPrint('User set to online: $_username');
      } catch (e) {
        debugPrint('Error setting user online: $e');
      }
    }
  }

  Future<void> deleteConversation(String otherUsername) async {
    if (_username == null) return;
    
    try {
      final conversationId = _getConversationId(_username!, otherUsername);
      final conversationRef = _conversationsRef.child(conversationId);
      
      await conversationRef.remove();
      debugPrint('Conversation deleted: $conversationId');
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    // Set user offline before clearing data
    await setOffline();
    
    // Clear saved username
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    
    // Disconnect from Firebase
    await disconnect();
  }

  @override
  void dispose() {
    // Set user offline before disconnecting
    setOffline();
    disconnect();
    super.dispose();
  }
}
