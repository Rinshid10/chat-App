import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
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
    FirebaseDatabase.instance
        .ref('.info/connected')
        .onValue
        .listen((event) {
      _isConnected = event.snapshot.value as bool? ?? false;
      notifyListeners();
    });
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

    // Load existing messages
    try {
      final snapshot = await conversationRef.orderByChild('timestamp').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final loadedMessages = <Message>[];
        for (var entry in data.entries) {
          final messageData = Map<String, dynamic>.from(entry.value as Map);
          messageData['id'] = entry.key;
          messageData['conversationId'] = _currentConversationId;
          final message = Message.fromJson(messageData);
          loadedMessages.add(message);
        }
        // Sort by timestamp
        loadedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _messages.addAll(loadedMessages);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }

    // Listen for new messages
    _messagesSubscription = conversationRef
        .orderByChild('timestamp')
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data['id'] = event.snapshot.key;
        data['conversationId'] = _currentConversationId;
        final message = Message.fromJson(data);
        
        // Check if message already exists (avoid duplicates)
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
          // Keep messages sorted
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          notifyListeners();
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
    await _usersRef.child(username).set({
      'online': true,
      'lastSeen': ServerValue.timestamp,
    });
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
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
      );
      
      final conversationRef = _conversationsRef
          .child(_currentConversationId!)
          .child('messages');
      
      await conversationRef.push().set(message.toJson());
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

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
