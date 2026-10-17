import 'dart:convert';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/preview_models.dart';
import 'workspace_storage.dart';

class WorkspaceData {
  WorkspaceData({
    required this.apis,
    required this.roles,
    required this.chats,
    required this.schedules,
    Map<String, dynamic>? runtime,
  }) : runtime = runtime ?? {};
  final List<ApiProfile> apis;
  final List<RoleProfile> roles;
  final List<Conversation> chats;
  final List<ScheduleEntry> schedules;
  final Map<String, dynamic> runtime;
}

abstract final class WorkspaceCodec {
  static Uint8List text(String value) => Uint8List.fromList(utf8.encode(value));
  static Uint8List json(Object value) =>
      text('${const JsonEncoder.withIndent('  ').convert(value)}\n');
  static String rolePath(String id) => 'agents/$id';
  static String chatPath(Conversation chat) =>
      '${chat.group ? 'groups' : 'chats'}/${chat.id}';
  static FileTree encode(WorkspaceData data, {bool includeKeys = true}) {
    final files = <String, Uint8List>{
      'config.json': json({
        'apis': data.apis
            .map(
              (a) => {
                'id': a.id,
                'name': a.name,
                'url': a.url,
                'models': a.models.map((k, v) => MapEntry(k, v.toJson())),
              },
            )
            .toList(),
      }),
      'runtime.json': json(data.runtime),
    };
    if (includeKeys) {
      files['auth.json'] = json({for (final a in data.apis) a.id: a.key});
    }
    for (final r in data.roles) {
      final path = rolePath(r.id);
      files['$path/profile.json'] = json({
        'id': r.id,
        'name': r.name,
        'apiId': r.apiId,
        'model': r.model,
        'examples': r.examples,
        'archived': r.archived,
        'timezone': r.timezone,
        'checkMin': r.checkMin,
        'checkMax': r.checkMax,
        'maxToolRounds': r.maxToolRounds,
        'defaultActivationProbability': r.defaultActivationProbability,
        'lockSoul': r.lockSoul,
        'lockMemory': r.lockMemory,
        'lockedSchedules': r.lockedSchedules,
      });
      files['$path/identity.md'] = text(r.identity);
      files['$path/soul.md'] = text(r.soul);
      files['$path/memory.md'] = text(r.memory);
      files['$path/schedule.json'] = json(
        data.schedules
            .where((s) => s.roleId == r.id)
            .map(scheduleJson)
            .toList(),
      );
      if (r.avatar != null) files['$path/avatar.png'] = base64Decode(r.avatar!);
    }
    for (final c in data.chats) {
      final path = chatPath(c);
      files['$path/profile.json'] = json({
        'id': c.id,
        'name': c.name,
        'group': c.group,
        'nextSequence': c.nextSequence,
        'members': c.members,
        'archived': c.archived,
      });
      if (c.group) files['$path/background.md'] = text(c.background);
      if (c.avatar != null && c.group) {
        files['$path/avatar.png'] = base64Decode(c.avatar!);
      }
      files['$path/messages.jsonl'] = text(
        c.messages
            .map(
              (m) => jsonEncode({
                'id': m.id,
                'sequence': m.sequence,
                'roleId': m.roleId,
                'senderName': m.senderName,
                'createdAt': m.createdAt.toUtc().toIso8601String(),
                'text': m.text,
                'mentions': m.mentions,
                'reply': m.reply == null
                    ? null
                    : {
                        'messageId': m.reply!.messageId,
                        'roleId': m.reply!.roleId,
                        'senderName': m.reply!.senderName,
                        'text': m.reply!.text,
                      },
              }),
            )
            .map((line) => '$line\n')
            .join(),
      );
    }
    return files;
  }

  static Map<String, dynamic> scheduleJson(ScheduleEntry s) => {
    'id': s.id,
    'activity': s.activity,
    'start': s.start,
    'end': s.end,
    'probability': s.probability,
    'weekdays': s.weekdays,
    'ruleKind': s.ruleKind.name,
    'dateFrom': s.dateFrom,
    'dateUntil': s.dateUntil,
    'annualMonth': s.annualMonth,
    'annualDay': s.annualDay,
  };
  static ScheduleEntry scheduleFrom(Map<String, dynamic> j, String roleId) {
    final s = ScheduleEntry(
      id: j['id'] as String,
      roleId: roleId,
      activity: j['activity'] as String,
      start: j['start'] as String,
      end: j['end'] as String,
      probability: (j['probability'] as num).toDouble(),
      weekdays: List<int>.from(j['weekdays'] as List),
      ruleKind: ScheduleRuleKind.values.byName(j['ruleKind'] as String),
      dateFrom: j['dateFrom'] as String?,
      dateUntil: j['dateUntil'] as String?,
      annualMonth: j['annualMonth'] as int?,
      annualDay: j['annualDay'] as int?,
    );
    final time = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$');
    if (!time.hasMatch(s.start) ||
        !time.hasMatch(s.end) ||
        s.activity.trim().isEmpty ||
        !s.probability.isFinite ||
        s.probability < 0 ||
        s.probability > 100 ||
        s.weekdays.any((v) => v < 1 || v > 7) ||
        (s.ruleKind == ScheduleRuleKind.weekly && s.weekdays.isEmpty)) {
      throw const FormatException('行程规则无效');
    }
    if (s.ruleKind == ScheduleRuleKind.annual) {
      final date = DateTime(2024, s.annualMonth!, s.annualDay!);
      if (date.month != s.annualMonth || date.day != s.annualDay) {
        throw const FormatException('年度日期无效');
      }
    }
    if ([ScheduleRuleKind.date, ScheduleRuleKind.range].contains(s.ruleKind)) {
      final from = DateTime.parse(s.dateFrom!);
      if (s.ruleKind == ScheduleRuleKind.range &&
          DateTime.parse(s.dateUntil!).isBefore(from)) {
        throw const FormatException('行程日期范围无效');
      }
    }
    return s;
  }

  static WorkspaceData decode(FileTree files) {
    tzdata.initializeTimeZones();
    for (final path in files.keys) {
      validateFilePath(path);
    }
    String read(String path) {
      final bytes = files[path];
      if (bytes == null) throw FormatException('缺少文件：$path');
      return utf8.decode(bytes);
    }

    Map<String, dynamic> object(String path) =>
        jsonDecode(read(path)) as Map<String, dynamic>;
    final config = object('config.json');
    final auth = files.containsKey('auth.json')
        ? object('auth.json')
        : <String, dynamic>{};
    final apis = (config['apis'] as List)
        .map(
          (j) => ApiProfile(
            id: j['id'] as String,
            name: j['name'] as String,
            url: j['url'] as String,
            key: auth.containsKey(j['id']) ? auth[j['id']] as String : '',
            models: (j['models'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(
                k,
                ModelSettings.fromJson(v as Map<String, dynamic>),
              ),
            ),
          ),
        )
        .toList();
    final roles = <RoleProfile>[];
    final chats = <Conversation>[];
    final schedules = <ScheduleEntry>[];
    final allowed = <String>{'config.json', 'auth.json', 'runtime.json'};
    for (final path in files.keys.where((p) => p.endsWith('/profile.json'))) {
      final parts = path.split('/');
      if (parts.length != 3 || !Uuid.isValidUUID(fromString: parts[1])) {
        throw const FormatException('资料目录需要UUID');
      }
      final j = object(path);
      final base = '${parts[0]}/${parts[1]}';
      if (j['id'] != parts[1]) throw const FormatException('资料ID与目录不一致');
      allowed.add(path);
      if (parts[0] == 'agents') {
        for (final name in [
          'identity.md',
          'soul.md',
          'memory.md',
          'schedule.json',
          'avatar.png',
        ]) {
          allowed.add('$base/$name');
        }
        final role = RoleProfile(
          id: j['id'] as String,
          name: j['name'] as String,
          apiId: j['apiId'] as String?,
          model: j['model'] as String,
          archived: j['archived'] as bool,
          timezone: j['timezone'] as String,
          checkMin: j['checkMin'] as int,
          checkMax: j['checkMax'] as int,
          maxToolRounds: j['maxToolRounds'] as int,
          defaultActivationProbability:
              (j['defaultActivationProbability'] as num?)?.toDouble() ?? 50,
          lockSoul: j['lockSoul'] as bool,
          lockMemory: j['lockMemory'] as bool,
          lockedSchedules: List<String>.from(j['lockedSchedules'] as List),
          avatar: files['$base/avatar.png'] == null
              ? null
              : base64Encode(files['$base/avatar.png']!),
          identity: read('$base/identity.md'),
          soul: read('$base/soul.md'),
          memory: read('$base/memory.md'),
          examples: (j['examples'] as List)
              .map(
                (e) => {
                  'question': e['question'] as String,
                  'answer': e['answer'] as String,
                },
              )
              .toList(),
        );
        if (role.checkMin < 1 ||
            role.checkMax < role.checkMin ||
            role.maxToolRounds < 1 ||
            role.maxToolRounds > 100 ||
            !role.defaultActivationProbability.isFinite ||
            role.defaultActivationProbability < 0 ||
            role.defaultActivationProbability > 100) {
          throw const FormatException('角色运行参数无效');
        }
        roles.add(role);
        schedules.addAll(
          (jsonDecode(read('$base/schedule.json')) as List).map(
            (s) => scheduleFrom(s as Map<String, dynamic>, role.id),
          ),
        );
      } else if (['chats', 'groups'].contains(parts[0])) {
        final group = parts[0] == 'groups';
        if (j['group'] != group) throw const FormatException('会话类型错误');
        allowed.addAll([
          '$base/messages.jsonl',
          if (group) '$base/background.md',
          if (group) '$base/avatar.png',
        ]);
        final ids = <String>{};
        var lastSequence = 0;
        final messages = const LineSplitter()
            .convert(read('$base/messages.jsonl'))
            .where((l) => l.isNotEmpty)
            .map((line) {
              final m = jsonDecode(line) as Map<String, dynamic>;
              final sequence = m['sequence'] as int;
              if (sequence <= lastSequence) {
                throw const FormatException('消息序号必须递增且大于零');
              }
              lastSequence = sequence;
              if (!ids.add(m['id'] as String)) {
                throw const FormatException('重复消息ID');
              }
              final time = DateTime.parse(m['createdAt'] as String).toLocal();
              final reply = m['reply'] as Map<String, dynamic>?;
              return ChatMessage(
                id: m['id'] as String,
                sequence: m['sequence'] as int,
                text: m['text'] as String,
                roleId: m['roleId'] as String?,
                senderName: m['senderName'] as String?,
                createdAt: time.toUtc(),
                time:
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                mentions: List<String>.from(m['mentions'] as List),
                reply: reply == null
                    ? null
                    : MessageReference(
                        messageId: reply['messageId'] as String,
                        text: reply['text'] as String,
                        senderName: reply['senderName'] as String,
                        roleId: reply['roleId'] as String?,
                      ),
              );
            })
            .toList();
        if ((j['nextSequence'] as int) <= lastSequence) {
          throw const FormatException('会话下一消息序号无效');
        }
        chats.add(
          Conversation(
            id: j['id'] as String,
            name: j['name'] as String,
            group: group,
            nextSequence: j['nextSequence'] as int,
            archived: j['archived'] as bool,
            members: List<String>.from(j['members'] as List),
            messages: messages,
            background: group ? read('$base/background.md') : '',
            avatar: files['$base/avatar.png'] == null
                ? null
                : base64Encode(files['$base/avatar.png']!),
          ),
        );
      } else {
        throw const FormatException('未知资料目录');
      }
    }
    if (files.keys.any((p) => !allowed.contains(p))) {
      throw const FormatException('数据包包含未知文件');
    }
    final roleIds = roles.map((r) => r.id).toSet();
    final apiIds = apis.map((a) => a.id).toSet();
    if (roleIds.length != roles.length ||
        apiIds.length != apis.length ||
        chats.map((c) => c.id).toSet().length != chats.length) {
      throw const FormatException('重复实体ID');
    }
    for (final api in apis) {
      if (!Uuid.isValidUUID(fromString: api.id)) {
        throw const FormatException('API配置ID无效');
      }
      final uri = Uri.tryParse(api.url);
      if (uri == null ||
          !uri.hasAuthority ||
          !['http', 'https'].contains(uri.scheme)) {
        throw const FormatException('API地址无效');
      }
      for (final model in api.models.values) {
        model.validate();
      }
    }
    for (final r in roles) {
      if (r.timezone != 'UTC' &&
          !tz.timeZoneDatabase.locations.containsKey(r.timezone)) {
        throw const FormatException('角色时区无效');
      }
      if (r.apiId != null && !apiIds.contains(r.apiId)) {
        throw const FormatException('角色引用不存在的API配置');
      }
    }
    for (final c in chats) {
      if (c.members.any((id) => !roleIds.contains(id))) {
        throw const FormatException('会话引用不存在的角色');
      }
      if (!c.group && c.members.length > 1) {
        throw const FormatException('私聊成员无效');
      }
    }
    return WorkspaceData(
      apis: apis,
      roles: roles,
      chats: chats,
      schedules: schedules,
      runtime: files.containsKey('runtime.json') ? object('runtime.json') : {},
    );
  }
}
