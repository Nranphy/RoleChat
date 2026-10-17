import 'dart:convert';
import 'package:rolechat/application/agents/ports/agent_workspace.dart';
import 'package:rolechat/application/agents/tools/agent_documents.dart';
import 'package:rolechat/domain/models/models.dart';

import 'package:rolechat/domain/services/conversation_messages.dart';

class AgentToolExecutor {
  AgentToolExecutor(this.store, this.role, this.chat);
  final AgentWorkspace store;
  final RoleProfile role;
  final Conversation chat;

  bool canRead(Conversation c) =>
      !role.archived && !c.archived && c.members.contains(role.id);
  Object execute(
    String name,
    Map<String, dynamic> args,
    bool Function() current,
  ) {
    if (!current() || !canRead(chat)) throw StateError('上下文或会话权限已变化');
    switch (name) {
      case 'finish':
        return {'finished': true};
      case 'send_message':
        final text = (args['text'] as String).trim();
        if (text.isEmpty || text.length > 8000) {
          throw const FormatException('消息内容为空或过长');
        }
        final now = DateTime.now();
        final message = ConversationMessages.append(
          chat,
          id: store.newId(),
          sender: role,
          text: text,
          now: now,
          roles: store.activeRoles,
        );
        store.changed();
        return {'sent': true, 'message_id': message.id};
      case 'search_history':
        final target = store.conversations
            .where((c) => c.id == args['conversation_id'])
            .firstOrNull;
        if (target == null || !canRead(target)) throw StateError('无法访问此会话');
        final query = (args['query'] as String).toLowerCase();
        return target.messages.reversed
            .where((m) => m.text.toLowerCase().contains(query))
            .take(50)
            .map(
              (m) => {
                'id': m.id,
                'sender': m.senderName ?? m.roleId ?? '你',
                'text': m.text,
                'time': m.createdAt.toUtc().toIso8601String(),
              },
            )
            .toList();
      case 'search_memory':
        final query = (args['query'] as String).toLowerCase();
        return const LineSplitter()
            .convert(role.memory)
            .where((s) => s.toLowerCase().contains(query))
            .take(50)
            .toList();
      case 'read_document':
        return AgentDocuments(store, role).read(args['name'] as String);
      case 'update_document':
        return AgentDocuments(store, role).update(
          args['name'] as String,
          args['content'] as String,
          args['expected_hash'] as String,
        );
      default:
        throw const FormatException('未知工具');
    }
  }
}
