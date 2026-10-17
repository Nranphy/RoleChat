import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/preview_models.dart';
import 'workspace_codec.dart';

/// Presets occupy UUIDv5 identities; user-created entities use UUIDv4.
abstract final class PresetIds {
  static const namespace = 'a25a1ee4-0a9b-4b41-a95c-fcaa53725cf2';
  static String role(String directory) =>
      const Uuid().v5(namespace, 'role:$directory');
  static String privateChat(String directory) =>
      const Uuid().v5(namespace, 'private-chat:$directory');
  static final group = const Uuid().v5(namespace, 'group:school-club');
}

/// Called only without the initialization marker. Existing documents stay intact.
Future<WorkspaceData> loadPresetWorkspace({
  required String timezone,
  AssetBundle? bundle,
  WorkspaceData? existing,
}) async {
  final assets = bundle ?? rootBundle;
  final catalog =
      jsonDecode(await assets.loadString('assets/presets/catalog.json'))
          as List;
  final roles = [...?existing?.roles];
  final chats = [...?existing?.chats];
  final missing = catalog.where(
    (entry) =>
        !roles.any((r) => r.id == PresetIds.role(entry['directory'] as String)),
  );
  roles.addAll(
    await Future.wait(
      missing.map((entry) async {
        final path = 'assets/presets/${entry['directory']}';
        final documents = await Future.wait([
          assets.loadString('$path/identity.md'),
          assets.loadString('$path/soul.md'),
          assets.loadString('$path/examples.json'),
        ]);
        final avatar = await assets.load('$path/avatar.png');
        return RoleProfile(
          id: PresetIds.role(entry['directory'] as String),
          name: entry['name'] as String,
          timezone: timezone,
          model: '',
          avatar: base64Encode(
            avatar.buffer.asUint8List(
              avatar.offsetInBytes,
              avatar.lengthInBytes,
            ),
          ),
          identity: documents[0],
          soul: documents[1],
          examples: (jsonDecode(documents[2]) as List)
              .map(
                (e) => {
                  'question': e['question'] as String,
                  'answer': e['answer'] as String,
                },
              )
              .toList(),
        );
      }),
    ),
  );
  for (final entry in catalog) {
    final directory = entry['directory'] as String;
    final role = roles.singleWhere((r) => r.id == PresetIds.role(directory));
    final chatId = PresetIds.privateChat(directory);
    final chat = chats.where((c) => c.id == chatId).firstOrNull;
    if (chat == null) {
      chats.add(
        Conversation(
          id: chatId,
          name: role.name,
          members: [role.id],
          archived: role.archived,
        ),
      );
    } else {
      if (chat.group) throw const FormatException('预设私聊 UUID 被其他会话类型占用');
      if (!chat.members.contains(role.id)) chat.members = [role.id];
    }
  }
  final memberIds = [
    for (final entry in catalog) PresetIds.role(entry['directory'] as String),
  ];
  final group = chats.where((c) => c.id == PresetIds.group).firstOrNull;
  if (group == null) {
    chats.insert(
      0,
      Conversation(
        id: PresetIds.group,
        name: '回春女子校社团',
        group: true,
        members: memberIds,
        background: await assets.loadString(
          'assets/presets/group-background.md',
        ),
      ),
    );
  } else {
    if (!group.group) throw const FormatException('预设群聊 UUID 被其他会话类型占用');
    for (final id in memberIds) {
      if (!group.members.contains(id)) group.members.add(id);
    }
  }
  return WorkspaceData(
    apis: existing?.apis ?? [],
    roles: roles,
    chats: chats,
    schedules: existing?.schedules ?? [],
    runtime: existing?.runtime,
  );
}
