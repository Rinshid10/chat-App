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

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _conversationsSubscription?.cancel();
    super.dispose();
  }
}

