import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:rolechat/domain/serialization/schedule_codec.dart';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/application/agents/ports/agent_workspace.dart';

/// Document permissions, optimistic conflicts and locks are independent of
/// context construction and the tool protocol.
class AgentDocuments {
  AgentDocuments(this.store, this.role);
  final AgentWorkspace store;
  final RoleProfile role;
  static String hash(String text) =>
      sha256.convert(utf8.encode(text)).toString();
  String content(String name) => switch (name) {
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

  Map<String, Object> read(String name) {
    final text = content(name);
    return {'content': text, 'hash': hash(text)};
  }

  Object update(String file, String text, String expectedHash) {
    if (text.length > 200000) throw const FormatException('文档过长');
    final old = content(file);
    if (hash(old) != expectedHash) {
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
    return {'updated': true, 'hash': hash(content(file))};
  }
}
