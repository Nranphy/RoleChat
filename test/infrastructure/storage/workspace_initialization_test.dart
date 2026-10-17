import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/infrastructure/storage/workspace_storage.dart';
import 'package:rolechat/infrastructure/presets/preset_workspace.dart';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/domain/models/workspace_cleanup.dart';
import '../../fixtures/test_store.dart';

class ObservedStorage extends MemoryWorkspaceStorage {
  int writes = 0, markers = 0;
  bool fail = false;
  @override
  Future<void> write(FileTree value) async {
    writes++;
    if (fail) throw StateError('test write failure');
    await super.write(value);
  }

  @override
  Future<void> markInitialized() async {
    markers++;
    await super.markInitialized();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  test(
    'first initialization loads adapted presets once and commits a marker',
    () async {
      final storage = ObservedStorage();
      final store = AppStore(preferences, storage: storage);
      expect(store.roles, isEmpty);
      await Future.wait([store.initialize(), store.initialize()]);
      expect(store.roles.map((r) => r.name), ['朝雫', '枫', '凪津', '咲', '若叶']);
      expect(storage.writes, 1);
      expect(storage.markers, 1);
      expect(await storage.isInitialized(), isTrue);
      expect(store.apis, isEmpty);
      expect(store.conversations.length, 6);
      final group = store.conversations.singleWhere((c) => c.group);
      expect(group.id, PresetIds.group);
      expect(group.name, '回春女子校社团');
      expect(group.members, store.roles.map((r) => r.id).toList());
      expect(group.background, contains('朝雫'));
      expect(group.messages, isEmpty);
      for (final role in store.roles) {
        expect(Uuid.isValidUUID(fromString: role.id), isTrue);
        expect(role.id[14], '5');
        expect(store.newId()[14], '4');
        expect(role.avatar, isNotEmpty);
        expect(role.identity, contains(role.name));
        expect(role.soul, isNotEmpty);
        expect(role.memory, isEmpty);
        expect(role.examples.length, 5);
        expect(role.apiId, isNull);
        final chat = store.conversations.singleWhere(
          (c) => !c.group && c.members.contains(role.id),
        );
        expect(chat.group, isFalse);
        expect(chat.messages, isEmpty);
        expect(Uuid.isValidUUID(fromString: chat.id), isTrue);
      }
      final id = store.roles.first.id;
      store.roles.first.identity = '用户修改的人设';
      store.removeRole(store.roles.last.id);
      await store.saveProfiles();
      final restored = AppStore(preferences, storage: storage);
      await restored.initialize();
      expect(restored.role(id).identity, '用户修改的人设');
      expect(restored.activeRoles.length, 4);
      expect(storage.markers, 1);
      restored.roles.clear();
      restored.conversations.clear();
      restored.schedules.clear();
      await restored.saveProfiles();
      final empty = AppStore(preferences, storage: storage);
      await empty.initialize();
      expect(empty.roles, isEmpty);
      expect(empty.conversations, isEmpty);
      expect(storage.markers, 1);
      store.dispose();
      restored.dispose();
      empty.dispose();
    },
  );

  test(
    'an unmarked workspace adds presets without overwriting user data',
    () async {
      final storage = ObservedStorage();
      final original = createTestStore(preferences, storage: storage);
      storage.initialized = false;
      original.roles.first.name = '用户自建角色';
      await original.saveProfiles();
      final writes = storage.writes;
      final restored = AppStore(preferences, storage: storage);
      await restored.initialize();
      expect(restored.roles.first.name, '用户自建角色');
      expect(restored.roles.length, 8);
      expect(restored.apis.single.id, original.apis.single.id);
      expect(storage.writes, writes + 1);
      expect(storage.markers, 1);
      original.dispose();
      restored.dispose();
    },
  );

  test(
    'clearing marker repairs preset IDs and membership without duplicates or overwrites',
    () async {
      final storage = ObservedStorage();
      final store = AppStore(preferences, storage: storage);
      await store.initialize();
      final first = store.role(PresetIds.role('asashizuku'));
      first.name = '用户改名';
      first.identity = '修改后的身份';
      first.memory = '用户保留的记忆';
      final removedId = PresetIds.role('kaede');
      final privateId = PresetIds.privateChat('kaede');
      store.selectedId = privateId;
      store.send('保留的私聊历史');
      final user = RoleProfile(
        id: store.newId(),
        name: '朝雫',
        identity: '用户自建同名角色',
      );
      store.addRole(user);
      final group = store.conversations.singleWhere(
        (c) => c.id == PresetIds.group,
      );
      group.name = '用户改过的群名';
      group.background = '用户改过的背景';
      group.members.add(user.id);
      group.members.remove(first.id);
      store.selectedId = group.id;
      store.send('保留的群聊历史');
      store.removeRole(PresetIds.role('nagitsu'));
      store.deleteRole(removedId, keepHistory: true);
      await store.saveProfiles();
      await store.clearData(WorkspaceCleanup.initialization);
      final restored = AppStore(preferences, storage: storage);
      await restored.initialize();
      expect(restored.roles.length, 6);
      expect(restored.role(user.id).identity, '用户自建同名角色');
      expect(restored.role(first.id).name, '用户改名');
      expect(restored.role(first.id).identity, '修改后的身份');
      expect(restored.role(first.id).memory, '用户保留的记忆');
      expect(restored.role(PresetIds.role('nagitsu')).archived, isTrue);
      expect(restored.role(removedId).name, '枫');
      final private = restored.conversations.singleWhere(
        (c) => c.id == privateId,
      );
      expect(private.members, [removedId]);
      expect(private.messages.single.text, '保留的私聊历史');
      final preserved = restored.conversations.singleWhere(
        (c) => c.id == PresetIds.group,
      );
      expect(preserved.name, '用户改过的群名');
      expect(preserved.background, '用户改过的背景');
      expect(preserved.messages.single.text, '保留的群聊历史');
      expect(
        preserved.members.toSet(),
        restored.roles.map((r) => r.id).toSet(),
      );
      await restored.clearData(WorkspaceCleanup.initialization);
      final repeated = AppStore(preferences, storage: storage);
      await repeated.initialize();
      expect(repeated.roles.length, 6);
      expect(repeated.conversations.length, 7);
      expect(repeated.conversations.map((c) => c.id).toSet().length, 7);
      repeated.conversations.removeWhere((c) => c.id == PresetIds.group);
      await repeated.saveProfiles();
      await repeated.clearData(WorkspaceCleanup.initialization);
      final withGroup = AppStore(preferences, storage: storage);
      await withGroup.initialize();
      expect(withGroup.roles.length, 6);
      final created = withGroup.conversations.singleWhere(
        (c) => c.id == PresetIds.group,
      );
      expect(created.name, '回春女子校社团');
      expect(created.members.length, 5);
      expect(created.messages, isEmpty);
      store.dispose();
      restored.dispose();
      repeated.dispose();
      withGroup.dispose();
    },
  );

  test('missing initialized data is an error and never reseeds', () async {
    final storage = ObservedStorage()..initialized = true;
    final store = AppStore(preferences, storage: storage);
    await expectLater(store.initialize(), throwsStateError);
    expect(store.roles, isEmpty);
    expect(storage.writes, 0);
    expect(storage.markers, 0);
    store.dispose();
  });

  test('failed first write does not create an initialization marker', () async {
    final storage = ObservedStorage()..fail = true;
    final store = AppStore(preferences, storage: storage);
    await expectLater(store.initialize(), throwsStateError);
    expect(await storage.isInitialized(), isFalse);
    expect(store.roles, isEmpty);
    store.dispose();
  });

  test(
    'corrupt data is not replaced by presets regardless of marker',
    () async {
      for (final initialized in [false, true]) {
        final storage = ObservedStorage()..initialized = initialized;
        storage.files['config.json'] = Uint8List.fromList(
          utf8.encode('{broken'),
        );
        final store = AppStore(preferences, storage: storage);
        await expectLater(store.initialize(), throwsFormatException);
        expect(storage.writes, 0);
        expect(storage.markers, 0);
        expect(utf8.decode(storage.files['config.json']!), '{broken');
        store.dispose();
      }
    },
  );
}
