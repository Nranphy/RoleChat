import 'package:rolechat/domain/models/models.dart';

/// Common message construction, sequence allocation and mention extraction.
abstract final class ConversationMessages {
  static ChatMessage append(
    Conversation chat, {
    required String id,
    required String text,
    required DateTime now,
    required List<RoleProfile> roles,
    RoleProfile? sender,
    MessageReference? reply,
  }) {
    final content = text.trim();
    if (content.isEmpty) throw const FormatException('消息内容为空');
    final message = ChatMessage(
      id: id,
      text: content,
      sequence: chat.nextSequence++,
      senderName: sender?.name ?? '你',
      roleId: sender?.id,
      reply: reply,
      createdAt: now,
      time:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      mentions: [
        for (final role in roles)
          if (chat.members.contains(role.id) &&
              content.contains('@${role.name}'))
            role.id,
      ],
    );
    chat.messages.add(message);
    return message;
  }
}
