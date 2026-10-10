import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/preview_models.dart';

/// Keeps the existing profiles.v1 format and serializes local writes.
class ProfilePersistence {
  ProfilePersistence(this.preferences);
  final SharedPreferences preferences;
  String? persistenceError;
  Future<void> _saveQueue = Future.value();
  Future<bool> save({
    required List<RoleProfile> roles,
    required List<ScheduleEntry> schedules,
    required List<Conversation> conversations,
  }) async {
    final snapshot = jsonEncode({
      'version': 1,
      'roles': roles
          .map(
            (r) => {
              'id': r.id,
              'name': r.name,
              'avatar': r.avatar,
              'model': r.model,
              'apiId': r.apiId,
              'identity': r.identity,
              'soul': r.soul,
              'memory': r.memory,
              'examples': r.examples,
            },
          )
          .toList(),
      'schedules': schedules
          .map(
            (s) => {
              'id': s.id,
              'roleId': s.roleId,
              'activity': s.activity,
              'condition': s.condition,
              'weekdays': s.weekdays,
              'ruleKind': s.ruleKind?.name,
              'dateFrom': s.dateFrom,
              'dateUntil': s.dateUntil,
              'annualMonth': s.annualMonth,
              'annualDay': s.annualDay,
              'start': s.start,
              'end': s.end,
              'probability': s.probability,
              'dateDetail': s.dateDetail,
            },
          )
          .toList(),
      'conversations': conversations
          .map(
            (c) => {
              'id': c.id,
              'name': c.name,
              'avatar': c.group ? c.avatar : null,
              'members': c.members,
              'group': c.group,
              'background': c.background,
            },
          )
          .toList(),
    });
    final operation = _saveQueue.then((_) async {
      if (!await preferences.setString('profiles.v1', snapshot)) {
        throw StateError('Storage unavailable');
      }
    });
    _saveQueue = operation.catchError((Object _) {});
    try {
      await operation;
      persistenceError = null;
      return true;
    } catch (_) {
      persistenceError = '本地保存失败，请检查浏览器存储空间';
      return false;
    }
  }

  void restore({
    required List<ApiProfile> apis,
    required List<RoleProfile> roles,
    required List<ScheduleEntry> schedules,
    required List<Conversation> conversations,
  }) {
    final raw = preferences.getString('profiles.v1');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['version'] != 1) {
        throw const FormatException('Unsupported data version');
      }
      final restoredRoles = (data['roles'] as List).map((item) {
        final r = item as Map<String, dynamic>;
        return RoleProfile(
          id: r['id'] as String,
          name: r['name'] as String,
          avatar: r['avatar'] as String?,
          model: r['model'] as String,
          apiId: apis.any((a) => a.id == r['apiId'])
              ? r['apiId'] as String?
              : null,
          identity: r['identity'] as String,
          soul: r['soul'] as String,
          memory:
              r['memory'] as String? ??
              roles.where((old) => old.id == r['id']).firstOrNull?.memory ??
              '',
          examples: (r['examples'] as List)
              .map((e) => Map<String, String>.from(e as Map))
              .toList(),
        );
      }).toList();
      final restoredSchedules = (data['schedules'] as List?)?.map((item) {
        final s = item as Map<String, dynamic>;
        return ScheduleEntry(
          id: s['id'] as String,
          roleId: s['roleId'] as String,
          activity: s['activity'] as String,
          condition: s['condition'] as String,
          ruleKind: ScheduleRuleKind.values
              .where((k) => k.name == s['ruleKind'])
              .firstOrNull,
          dateFrom: s['dateFrom'] as String?,
          dateUntil: s['dateUntil'] as String?,
          annualMonth: s['annualMonth'] as int?,
          annualDay: s['annualDay'] as int?,
          weekdays: List<int>.from(s['weekdays'] as List? ?? []),
          start: s['start'] as String,
          end: s['end'] as String,
          probability: (s['probability'] as num).toDouble(),
          dateDetail: s['dateDetail'] as String? ?? '',
        );
      }).toList();
      final restoredChats = (data['conversations'] as List).map((item) {
        final c = item as Map<String, dynamic>;
        return Conversation(
          id: c['id'] as String,
          name: c['name'] as String,
          avatar: c['avatar'] as String?,
          members: List<String>.from(c['members'] as List),
          group: c['group'] as bool,
          background: c['background'] as String? ?? '',
          messages: conversations
              .where((old) => old.id == c['id'])
              .firstOrNull
              ?.messages,
        );
      }).toList();
      if (restoredChats.isEmpty) {
        throw const FormatException('Missing conversations');
      }
      if (restoredSchedules != null) {
        schedules
          ..clear()
          ..addAll(restoredSchedules);
      }
      roles
        ..clear()
        ..addAll(restoredRoles);
      conversations
        ..clear()
        ..addAll(restoredChats);
    } catch (_) {
      persistenceError = '无法读取已保存资料，当前显示示例数据';
    }
  }
}
