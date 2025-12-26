import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/message.dart';

class SocketService extends ChangeNotifier {
  late IO.Socket socket;
  final List<Message> _messages = [];
  bool _isConnected = false;
  String? _username;

  List<Message> get messages => _messages;
  bool get isConnected => _isConnected;
  String? get username => _username;

  void connect(String serverUrl) {
    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      _isConnected = true;
      notifyListeners();
      print('Connected to server');
    });

    socket.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
      print('Disconnected from server');
    });

    socket.on('message', (data) {
      final message = Message.fromJson(Map<String, dynamic>.from(data));
      _messages.add(message);
      notifyListeners();
    });

    socket.onError((error) {
      print('Socket error: $error');
    });
  }

  void join(String username) {
    _username = username;
    socket.emit('join', username);
  }

  void sendMessage(String text) {
    if (text.trim().isNotEmpty) {
      socket.emit('message', {'text': text});
    }
  }

  void disconnect() {
    socket.disconnect();
    _messages.clear();
    _isConnected = false;
    _username = null;
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }
}
