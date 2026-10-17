import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/preview_models.dart';
import 'workspace_codec.dart';

/// Called only for an unmarked, empty workspace. Resources never merge on load.
Future<WorkspaceData> loadPresetWorkspace({
  required String timezone,
  AssetBundle? bundle,
}) async {
  final assets = bundle ?? rootBundle;
  final catalog =
      jsonDecode(await assets.loadString('assets/presets/catalog.json'))
          as List;
  final roles = await Future.wait(
    catalog.map((entry) async {
      final path = 'assets/presets/${entry['directory']}';
      final documents = await Future.wait([
        assets.loadString('$path/identity.md'),
        assets.loadString('$path/soul.md'),
        assets.loadString('$path/examples.json'),
      ]);
      final avatar = await assets.load('$path/avatar.png');
      return RoleProfile(
        id: const Uuid().v4(),
        name: entry['name'] as String,
        timezone: timezone,
        model: '',
        avatar: base64Encode(
          avatar.buffer.asUint8List(avatar.offsetInBytes, avatar.lengthInBytes),
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
  );
  return WorkspaceData(
    apis: [],
    roles: roles,
    chats: [
      for (final role in roles)
        Conversation(
          id: const Uuid().v4(),
          name: role.name,
          members: [role.id],
        ),
    ],
    schedules: [],
  );
}
