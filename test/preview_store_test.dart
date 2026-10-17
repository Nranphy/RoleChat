import 'fixtures/test_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'stores own independent samples and rapidly generated IDs remain unique',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final first = createTestStore(preferences);
      final second = createTestStore(preferences);
      first.roles.first.name = 'changed';
      expect(second.roles.first.name, '林间');
      final ids = List.generate(5000, (_) => first.newId());
      expect(ids.toSet().length, ids.length);
      first.dispose();
      second.dispose();
    },
  );
  test(
    'role deletion removes orphan schedules and stored invalid theme falls back safely',
    () async {
      SharedPreferences.setMockInitialValues({'themeMode': 99});
      final preferences = await SharedPreferences.getInstance();
      final store = createTestStore(preferences);
      expect(store.mode, ThemeMode.system);
      store.deleteRole(
        '11111111-1111-4111-8111-111111111111',
        keepHistory: true,
      );
      expect(
        store.schedules.where(
          (s) => s.roleId == '11111111-1111-4111-8111-111111111111',
        ),
        isEmpty,
      );
      expect(await store.saveProfiles(), isTrue);
      final restored = createTestStore(preferences, storage: store.storage);
      await restored.initialize();
      expect(
        restored.roles.where(
          (r) => r.id == '11111111-1111-4111-8111-111111111111',
        ),
        isEmpty,
      );
      expect(
        restored.schedules.where(
          (s) => s.roleId == '11111111-1111-4111-8111-111111111111',
        ),
        isEmpty,
      );
      store.dispose();
      restored.dispose();
    },
  );
}
