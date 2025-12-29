class Message {
  final String id;
  final String username;
  final String text;
  final DateTime timestamp;
  final bool isSystem;
  final String? recipient;
  final String? conversationId;
  final bool isEdited;
  final String? replyTo;

  Message({
    required this.id,
    required this.username,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
    this.recipient,
    this.conversationId,
    this.isEdited = false,
    this.replyTo,
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
      recipient: json['recipient'],
      conversationId: json['conversationId'],
      isEdited: json['editedAt'] != null || json['isEdited'] == true,
      replyTo: json['replyTo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isSystem': isSystem,
      if (recipient != null) 'recipient': recipient,
      if (conversationId != null) 'conversationId': conversationId,
      if (isEdited) 'isEdited': true,
      if (replyTo != null) 'replyTo': replyTo,
    };
  }
}
