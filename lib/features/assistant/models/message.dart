enum MessageType { user, assistant }

class Message {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
  });

  bool get isUser => type == MessageType.user;
}