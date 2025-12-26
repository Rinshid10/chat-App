class Message {
  final String id;
  final String username;
  final String text;
  final DateTime timestamp;
  final bool isSystem;

  Message({
    required this.id,
    required this.username,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      username: json['username'] ?? 'Anonymous',
      text: json['text'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isSystem: json['isSystem'] ?? false,
    );
  }
}
