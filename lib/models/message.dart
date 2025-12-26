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
    DateTime parsedTime;
    if (json['timestamp'] is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
    } else {
      parsedTime = DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now();
    }

    return Message(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      username: json['username'] ?? 'Anonymous',
      text: json['text'] ?? '',
      timestamp: parsedTime,
      isSystem: json['isSystem'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isSystem': isSystem,
    };
  }
}
