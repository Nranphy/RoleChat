class MessageReference {
  const MessageReference({
    required this.messageId,
    required this.text,
    required this.senderName,
    this.roleId,
  });
  final String messageId, text, senderName;
  final String? roleId;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    this.roleId,
    this.time = '16:42',
    this.reply,
    this.sequence = 0,
    this.senderName,
    DateTime? createdAt,
    List<String>? mentions,
  }) : createdAt = createdAt ?? DateTime.now().toUtc(),
       mentions = mentions ?? [];
  final String id;
  final String text;
  final String? roleId;
  final MessageReference? reply;
  final String time;
  int sequence;
  final DateTime createdAt;
  final String? senderName;
  final List<String> mentions;
  bool get isUser => roleId == null;
}

class Conversation {
  Conversation({
    required this.id,
    required this.name,
    this.avatar,
    required this.members,
    this.group = false,
    this.background = '',
    this.archived = false,
    List<ChatMessage>? messages,
    this.nextSequence = 1,
  }) : messages = messages ?? [] {
    for (final m in this.messages) {
      if (m.sequence == 0) m.sequence = nextSequence;
      if (m.sequence >= nextSequence) nextSequence = m.sequence + 1;
    }
  }
  final String id;
  String name, background;
  String? avatar;
  bool group, archived;
  int nextSequence;
  List<String> members;
  List<ChatMessage> messages;
}
