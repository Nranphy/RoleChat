import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/app_store.dart';
import 'package:rolechat/infrastructure/storage/workspace_storage.dart';
import 'package:rolechat/domain/models/workspace_cleanup.dart';
import '../../fixtures/test_store.dart';

class ControlledStorage extends MemoryWorkspaceStorage {
  bool fail = false;
  Completer<void>? gate;
  @override
  Future<void> write(FileTree value) async {
    if (gate != null) await gate!.future;
    if (fail) throw StateError('test storage failure');
    await super.write(value);
  }
}

void main() {
  late AppStore store;
  late ControlledStorage storage;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'themeMode': 2,
      'seed': 123,
      'unrelated': 'keep',
    });
    storage = ControlledStorage();
    store = createTestStore(
      await SharedPreferences.getInstance(),
      storage: storage,
    );
    store.apis.single.key = 'test-key';
    store.runtimeData.addAll({'view:role:chat': 9, 'background': false});
    await store.saveProfiles();
    await storage.markInitialized();
  });
  tearDown(() => store.dispose());

  test(
    'clearing messages preserves configuration and documents including archived chats',
    () async {
      final identity = store.roles.first.identity;
      final memory = store.roles.first.memory;
      final chatCount = store.conversations.length;
      store.conversations.first.archived = true;
      await store.clearData(WorkspaceCleanup.messages);
      expect(store.conversations.length, chatCount);
      expect(
        store.conversations.every(
          (c) => c.messages.isEmpty && c.nextSequence == 1,
        ),
        isTrue,
      );
      expect(store.roles.first.identity, identity);
      expect(store.roles.first.memory, memory);
      expect(store.schedules, isNotEmpty);
      expect(store.apis.single.key, 'test-key');
      expect(store.runtimeData, {'background': false});
      expect(await storage.isInitialized(), isTrue);
      final restored = AppStore(store.preferences, storage: storage);
      await restored.initialize();
      expect(restored.conversations.every((c) => c.messages.isEmpty), isTrue);
      restored.dispose();
    },
  );
  test(
    'clearing profiles keeps API keys, preferences and marker without reseeding',
    () async {
      await store.clearData(WorkspaceCleanup.profiles);
      expect(store.roles, isEmpty);
      expect(store.conversations, isEmpty);
      expect(store.schedules, isEmpty);
      expect(store.apis.single.key, 'test-key');
      expect(store.preferences.getInt('seed'), 123);
      expect(await storage.isInitialized(), isTrue);
      final restored = AppStore(store.preferences, storage: storage);
      await restored.initialize();
      expect(restored.roles, isEmpty);
      restored.dispose();
    },
  );
  test('clearing marker changes no business file', () async {
    final before = await storage.read();
    await store.clearData(WorkspaceCleanup.initialization);
    expect(await storage.isInitialized(), isFalse);
    expect(await storage.read(), before);
    expect(store.roles.length, 3);
  });
  test(
    'clearing all drains pending writes and removes app preferences and marker',
    () async {
      storage.gate = Completer<void>();
      store.send('排队保存的消息');
      final clearing = store.clearData(WorkspaceCleanup.all);
      expect(store.transferring, isTrue);
      expect(await store.saveProfiles(), isFalse);
      storage.gate!.complete();
      await clearing;
      expect(await storage.read(), isEmpty);
      expect(await storage.isInitialized(), isFalse);
      expect(store.roles, isEmpty);
      expect(store.apis, isEmpty);
      expect(store.preferences.getInt('themeMode'), isNull);
      expect(store.preferences.getInt('seed'), isNull);
      expect(store.preferences.getString('unrelated'), 'keep');
      expect(store.transferring, isFalse);
    },
  );
  test(
    'failed cleanup leaves live data intact and releases the busy state',
    () async {
      final count = store.selected.messages.length;
      storage.fail = true;
      await expectLater(
        store.clearData(WorkspaceCleanup.messages),
        throwsStateError,
      );
      expect(store.selected.messages.length, count);
      expect(store.transferring, isFalse);
      expect(await storage.isInitialized(), isTrue);
    },
  );
}
