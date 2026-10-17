import '../../fixtures/test_store.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/infrastructure/storage/workspace_codec.dart';
import 'package:rolechat/infrastructure/transfer/workspace_transfer.dart';

void main() {
  Future<AppStore> create() async {
    SharedPreferences.setMockInitialValues({});
    return createTestStore(await SharedPreferences.getInstance());
  }

  test(
    'files restore API keys, independent documents and JSONL replies',
    () async {
      final store = await create();
      store.apis.first.key = 'secret';
      store.roles.first.memory = '# 日记\n两行\n文字';
      store.roles.first.defaultActivationProbability = 35.5;
      store.send('新消息\n第二行');
      expect(await store.saveProfiles(), isTrue);
      final files = await store.storage.read();
      expect(utf8.decode(files['config.json']!), isNot(contains('secret')));
      expect(utf8.decode(files['auth.json']!), contains('secret'));
      expect(
        utf8.decode(files['agents/${store.roles.first.id}/memory.md']!),
        '# 日记\n两行\n文字',
      );
      final restored = createTestStore(
        store.preferences,
        storage: store.storage,
      );
      await restored.initialize();
      expect(restored.apis.first.key, 'secret');
      expect(restored.roles.first.defaultActivationProbability, 35.5);
      expect(restored.selected.messages.last.text, '新消息\n第二行');
    },
  );
  test(
    'single character ZIP excludes history and keys unless selected',
    () async {
      final store = await create();
      store.roles.first.apiId = store.apis.first.id;
      store.apis.first.key = 'secret';
      final transfer = WorkspaceTransfer();
      final imported = transfer.inspect(
        transfer.export(store.data, roleId: store.roles.first.id),
      );
      expect(imported.roles.length, 1);
      expect(imported.chats, isEmpty);
      expect(imported.apis.single.key, isEmpty);
      expect(imported.roles.single.memory, store.roles.first.memory);
      final full = transfer.inspect(
        transfer.export(store.data, includeKeys: true),
      );
      expect(full.apis.single.key, 'secret');
      expect(
        full.chats.first.messages.length,
        store.conversations.first.messages.length,
      );
    },
  );
  test(
    'keep both remaps relationships while replace removes old directory content',
    () async {
      final store = await create();
      store.roles.first.apiId = store.apis.first.id;
      final transfer = WorkspaceTransfer();
      final incoming = transfer.inspect(
        transfer.export(store.data, includeKeys: true),
      );
      final choices = {
        for (final c in transfer.conflicts(store.data, incoming))
          c.id: ImportChoice.keepBoth,
      };
      final merged = transfer.merge(store.data, incoming, choices);
      expect(merged.roles.length, store.roles.length * 2);
      final imported = merged.roles.lastWhere(
        (r) => r.name == store.roles.first.name,
      );
      expect(imported.id, isNot(store.roles.first.id));
      expect(
        merged.chats.any((c) => !c.group && c.members.contains(imported.id)),
        isTrue,
      );
      final changed = WorkspaceCodec.decode(WorkspaceCodec.encode(store.data));
      changed.roles.first.memory = '';
      final replaced = transfer.merge(store.data, changed, {
        for (final c in transfer.conflicts(store.data, changed))
          c.id: ImportChoice.replace,
      });
      expect(replaced.roles.first.memory, isEmpty);
    },
  );
}
