import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/data/workspace_storage.dart';
import 'fixtures/test_store.dart';

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
      final store = PreviewStore(preferences, storage: storage);
      expect(store.roles, isEmpty);
      await Future.wait([store.initialize(), store.initialize()]);
      expect(store.roles.map((r) => r.name), ['朝雫', '枫', '凪津', '咲', '若叶']);
      expect(storage.writes, 1);
      expect(storage.markers, 1);
      expect(await storage.isInitialized(), isTrue);
      expect(store.apis, isEmpty);
      expect(store.conversations.length, 5);
      for (final role in store.roles) {
        expect(Uuid.isValidUUID(fromString: role.id), isTrue);
        expect(role.avatar, isNotEmpty);
        expect(role.identity, contains(role.name));
        expect(role.soul, isNotEmpty);
        expect(role.memory, isEmpty);
        expect(role.examples.length, 5);
        expect(role.apiId, isNull);
        final chat = store.conversations.singleWhere(
          (c) => c.members.contains(role.id),
        );
        expect(chat.group, isFalse);
        expect(chat.messages, isEmpty);
        expect(Uuid.isValidUUID(fromString: chat.id), isTrue);
      }
      final id = store.roles.first.id;
      store.roles.first.identity = '用户修改的人设';
      store.removeRole(store.roles.last.id);
      await store.saveProfiles();
      final restored = PreviewStore(preferences, storage: storage);
      await restored.initialize();
      expect(restored.role(id).identity, '用户修改的人设');
      expect(restored.activeRoles.length, 4);
      expect(storage.markers, 1);
      restored.roles.clear();
      restored.conversations.clear();
      restored.schedules.clear();
      await restored.saveProfiles();
      final empty = PreviewStore(preferences, storage: storage);
      await empty.initialize();
      expect(empty.roles, isEmpty);
      expect(empty.conversations, isEmpty);
      expect(storage.markers, 1);
      store.dispose();
      restored.dispose();
      empty.dispose();
    },
  );

  test('an existing unmarked workspace only receives its marker', () async {
    final storage = ObservedStorage();
    final original = createTestStore(preferences, storage: storage);
    original.roles.first.name = '用户自建角色';
    await original.saveProfiles();
    final writes = storage.writes;
    final restored = PreviewStore(preferences, storage: storage);
    await restored.initialize();
    expect(restored.roles.first.name, '用户自建角色');
    expect(storage.writes, writes);
    expect(storage.markers, 1);
    original.dispose();
    restored.dispose();
  });

  test('missing initialized data is an error and never reseeds', () async {
    final storage = ObservedStorage()..initialized = true;
    final store = PreviewStore(preferences, storage: storage);
    await expectLater(store.initialize(), throwsStateError);
    expect(store.roles, isEmpty);
    expect(storage.writes, 0);
    expect(storage.markers, 0);
    store.dispose();
  });

  test('failed first write does not create an initialization marker', () async {
    final storage = ObservedStorage()..fail = true;
    final store = PreviewStore(preferences, storage: storage);
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
        final store = PreviewStore(preferences, storage: storage);
        await expectLater(store.initialize(), throwsFormatException);
        expect(storage.writes, 0);
        expect(storage.markers, 0);
        expect(utf8.decode(storage.files['config.json']!), '{broken');
        store.dispose();
      }
    },
  );
}
