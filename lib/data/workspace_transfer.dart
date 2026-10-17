import '../models/preview_models.dart';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:uuid/uuid.dart';
import 'workspace_codec.dart';
import '../models/workspace_data.dart';
import 'workspace_remap.dart';
import 'workspace_storage.dart';

enum ImportChoice { keepBoth, replace }

class ImportConflict {
  const ImportConflict(this.id, this.name, this.type);
  final String id, name, type;
}

class WorkspaceTransfer {
  static const maxBytes = 100 * 1024 * 1024;
  Uint8List export(
    WorkspaceData source, {
    bool includeKeys = false,
    String? roleId,
  }) {
    var data = source;
    if (roleId != null) {
      final role = source.roles.singleWhere((r) => r.id == roleId);
      data = WorkspaceData(
        apis: source.apis.where((a) => a.id == role.apiId).toList(),
        roles: [role],
        chats: [],
        schedules: source.schedules.where((s) => s.roleId == roleId).toList(),
      );
    }
    final files = WorkspaceCodec.encode(data, includeKeys: includeKeys)
      ..remove('runtime.json');
    final archive = Archive();
    for (final e in files.entries) {
      archive.addFile(ArchiveFile(e.key, e.value.length, e.value));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  WorkspaceData inspect(Uint8List bytes) {
    if (bytes.length > maxBytes) throw const FormatException('导入包不能超过100MB');
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    if (archive.length > 10000) throw const FormatException('导入文件过多');
    final files = <String, Uint8List>{};
    var total = 0;
    for (final entry in archive) {
      if (entry.isSymbolicLink) throw const FormatException('不支持符号链接');
      if (!entry.isFile) {
        validateFilePath(entry.name.replaceFirst(RegExp(r'/$'), ''));
        continue;
      }
      validateFilePath(entry.name);
      if (files.containsKey(entry.name)) {
        throw const FormatException('导入包含重复文件');
      }
      total += entry.size;
      if (entry.size < 0 || total > maxBytes) {
        throw const FormatException('解包内容超过100MB');
      }
      final content = entry.content;
      if (content.length != entry.size) throw const FormatException('文件长度错误');
      files[entry.name] = Uint8List.fromList(content);
    }
    return WorkspaceCodec.decode(files);
  }

  List<ImportConflict> conflicts(WorkspaceData local, WorkspaceData incoming) =>
      [
        for (final r in incoming.roles)
          if (local.roles.any((x) => x.id == r.id))
            ImportConflict(r.id, r.name, '角色'),
        for (final c in incoming.chats)
          if (local.chats.any((x) => x.id == c.id))
            ImportConflict(c.id, c.name, c.group ? '群聊' : '私聊'),
        for (final a in incoming.apis)
          if (local.apis.any((x) => x.id == a.id))
            ImportConflict(a.id, a.name, 'API配置'),
      ];
  WorkspaceData merge(
    WorkspaceData local,
    WorkspaceData incoming,
    Map<String, ImportChoice> choices,
  ) {
    final collisions = conflicts(local, incoming);
    if (collisions.any((c) => !choices.containsKey(c.id))) {
      throw const FormatException('需要选择冲突处理方式');
    }
    final ids = <String, String>{};
    for (final c in collisions.where(
      (c) => choices[c.id] == ImportChoice.keepBoth,
    )) {
      ids[c.id] = const Uuid().v4();
    }
    for (final chat in incoming.chats.where((c) => ids.containsKey(c.id))) {
      for (final m in chat.messages) {
        ids[m.id] = const Uuid().v4();
      }
    }
    for (final s in incoming.schedules.where(
      (s) => ids.containsKey(s.roleId),
    )) {
      ids[s.id] = const Uuid().v4();
    }
    final imported = remapData(incoming, ids);
    final roleIds = imported.roles.map((r) => r.id).toSet();
    final chatIds = imported.chats.map((c) => c.id).toSet();
    final apiIds = imported.apis.map((a) => a.id).toSet();
    final result = WorkspaceData(
      apis: [
        ...local.apis.where((a) => !apiIds.contains(a.id)),
        ...imported.apis,
      ],
      roles: [
        ...local.roles.where((r) => !roleIds.contains(r.id)),
        ...imported.roles,
      ],
      chats: [
        ...local.chats.where((c) => !chatIds.contains(c.id)),
        ...imported.chats,
      ],
      schedules: [
        ...local.schedules.where((s) => !roleIds.contains(s.roleId)),
        ...imported.schedules,
      ],
      runtime: {},
    );
    for (final r in imported.roles) {
      if (!result.chats.any((c) => !c.group && c.members.contains(r.id))) {
        result.chats.add(
          Conversation(
            id: const Uuid().v4(),
            name: r.name,
            members: [r.id],
            archived: r.archived,
          ),
        );
      }
    }
    return WorkspaceCodec.decode(WorkspaceCodec.encode(result));
  }
}
