import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/message.dart';

class FirebaseChatService extends ChangeNotifier {
  final DatabaseReference _messagesRef =
      FirebaseDatabase.instance.ref('messages');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  final List<Message> _messages = [];
  bool _isConnected = false;
  String? _username;

  List<Message> get messages => _messages;
  bool get isConnected => _isConnected;
  String? get username => _username;

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
    _messagesRef.orderByChild('timestamp').onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data['id'] = event.snapshot.key;
        final message = Message.fromJson(data);
        _messages.add(message);
        notifyListeners();
      }
    });
  }

  Future<void> join(String username) async {
    _username = username;
    await _usersRef.child(username).set({
      'online': true,
      'lastSeen': ServerValue.timestamp,
    });

    final systemMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: 'System',
      text: '$username joined the chat',
      timestamp: DateTime.now(),
      isSystem: true,
    );
    await _messagesRef.push().set(systemMessage.toJson());
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isNotEmpty && _username != null) {
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: _username!,
        text: text.trim(),
        timestamp: DateTime.now(),
        isSystem: false,
      );
      await _messagesRef.push().set(message.toJson());
    }
  }

  Future<void> disconnect() async {
    if (_username != null) {
      await _usersRef.child(_username!).update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
    _messages.clear();
    _isConnected = false;
    _username = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
