import 'dart:convert';
import 'agent_workspace.dart';
import '../data/schedule_codec.dart';
import '../models/preview_models.dart';
import 'context_builder.dart';
import '../services/conversation_messages.dart';

Map<String, dynamic> _tool(
  String name,
  String description,
  Map<String, dynamic> properties,
  List<String> required,
) => {
  'type': 'function',
  'function': {
    'name': name,
    'description': description,
    'parameters': {
      'type': 'object',
      'properties': properties,
      'required': required,
      'additionalProperties': false,
    },
  },
};
const _string = {'type': 'string'};
final agentTools = <Map<String, dynamic>>[
  _tool(
    'send_message',
    '向当前会话发送一条自然的纯文本消息，可以分条发送。发送成功的内容已对外可见。',
    {'text': _string},
    ['text'],
  ),
  _tool(
    'search_history',
    '在当前有权限参与的会话中关键词搜索；空关键词读取最近消息。',
    {'conversation_id': _string, 'query': _string},
    ['conversation_id', 'query'],
  ),
  _tool('search_memory', '关键词检索自己的记忆。', {'query': _string}, ['query']),
  _tool(
    'read_document',
    '读取自己的soul.md、memory.md或schedule.json及当前哈希。',
    {'name': _string},
    ['name'],
  ),
  _tool(
    'update_document',
    '按读取时的哈希更新自己的灵魂、记忆或结构化行程。行程正文为JSON数组，规则格式与读取结果一致。',
    {'name': _string, 'content': _string, 'expected_hash': _string},
    ['name', 'content', 'expected_hash'],
  ),
  _tool('finish', '结束本轮处理，允许不发言。', {}, []),
];

class AgentToolExecutor {
  AgentToolExecutor(this.store, this.role, this.chat);
  final AgentWorkspace store;
  final RoleProfile role;
  final Conversation chat;

  bool canRead(Conversation c) =>
      !role.archived && !c.archived && c.members.contains(role.id);
  String document(String name) => switch (name) {
    'soul.md' => role.soul,
    'memory.md' => role.memory,
    'schedule.json' => jsonEncode(
      store.schedules
          .where((s) => s.roleId == role.id)
          .map(ScheduleCodec.encode)
          .toList(),
    ),
    _ => throw const FormatException('不允许访问此文档'),
  };

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
        final text = document(args['name'] as String);
        return {'content': text, 'hash': contentHash(text)};
      case 'update_document':
        final file = args['name'] as String;
        final text = args['content'] as String;
        if (text.length > 200000) throw const FormatException('文档过长');
        final old = document(file);
        if (contentHash(old) != args['expected_hash']) {
          throw StateError('内容已变化，请重新读取后更新');
        }
        if (file == 'soul.md') {
          if (role.lockSoul) throw StateError('灵魂已被用户锁定');
          role.soul = text;
        } else if (file == 'memory.md') {
          if (role.lockMemory) throw StateError('记忆已被用户锁定');
          role.memory = text;
        } else {
          final rows = jsonDecode(text) as List;
          final rules = rows
              .map(
                (r) => ScheduleCodec.decode(
                  Map<String, dynamic>.from(r as Map),
                  role.id,
                ),
              )
              .toList();
          if (rules.map((s) => s.id).toSet().length != rules.length) {
            throw const FormatException('规则ID重复');
          }
          for (final id in role.lockedSchedules) {
            final previous = store.schedules
                .where((s) => s.roleId == role.id && s.id == id)
                .firstOrNull;
            final next = rules.where((s) => s.id == id).firstOrNull;
            if (previous != null &&
                (next == null ||
                    jsonEncode(ScheduleCodec.encode(previous)) !=
                        jsonEncode(ScheduleCodec.encode(next)))) {
              throw StateError('行程规则已被用户锁定');
            }
          }
          store.schedules.removeWhere((s) => s.roleId == role.id);
          store.schedules.addAll(rules);
        }
        store.changed();
        return {'updated': true, 'hash': contentHash(document(file))};
      default:
        throw const FormatException('未知工具');
    }
  }
}
