import 'fixtures/test_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/features/settings/api_editor.dart';
import 'package:rolechat/features/agents/role_editor_dialog.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/anchored_select.dart';

void main() {
  testWidgets(
    'removing a used model asks confirmation and clears only its reference',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = createTestStore(await SharedPreferences.getInstance());
      addTearDown(store.dispose);
      final api = store.apis.first;
      final role = store.roles.first..apiId = api.id;
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      editApi(tester.element(find.byType(Scaffold)), store, profile: api);
      await tester.pumpAndSettle();
      final remove = find.byTooltip('删除模型配置');
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('删除正在使用的模型？'), findsOneWidget);
      expect(api.models, isNotEmpty);
      final buttons = find.descendant(
        of: find.byType(AlertDialog).last,
        matching: find.byType(FilledButton),
      );
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();
      expect(api.models, isEmpty);
      expect(role.apiId, api.id);
      expect(role.model, isEmpty);
      expect(store.roles, contains(role));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'API edits multiple models together and renames role references',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = createTestStore(await SharedPreferences.getInstance());
      addTearDown(store.dispose);
      final api = store.apis.first;
      final role = store.roles.first..apiId = api.id;
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      editApi(tester.element(find.byType(Scaffold)), store, profile: api);
      await tester.pumpAndSettle();
      final first = find.widgetWithText(TextFormField, '模型 ID');
      await tester.ensureVisible(first);
      await tester.enterText(first, 'renamed-model');
      await tester.ensureVisible(find.text('添加模型'));
      await tester.tap(find.text('添加模型'));
      await tester.pumpAndSettle();
      final second = find.widgetWithText(TextFormField, '模型 ID').last;
      await tester.ensureVisible(second);
      await tester.enterText(second, 'renamed-model');
      await tester.tap(find.text('保存'));
      await tester.pump();
      expect(find.text('同一 API 下的模型 ID 不能重复'), findsOneWidget);
      expect(api.models.keys, ['gpt-4o']);
      await tester.ensureVisible(second);
      await tester.enterText(second, 'second-model');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(api.models.keys, ['renamed-model', 'second-model']);
      expect(role.model, 'renamed-model');
      expect(api.models['second-model']!.concurrency, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'role selects only models owned by API and changing API clears model',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = createTestStore(await SharedPreferences.getInstance());
      addTearDown(store.dispose);
      final role = store.roles.first..apiId = store.apis.first.id;
      store.apis.add(
        ApiProfile(
          id: store.newId(),
          name: '第二接口',
          url: 'https://second.test/v1',
          models: {'second-model': ModelSettings()},
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoleEditorDialog(store: store, role: role),
          ),
        ),
      );
      Finder selector(String label) => find.byWidgetPredicate(
        (w) => w is AnchoredSelect<String> && w.label == label,
      );
      await tester.tap(selector('API 配置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('第二接口').last);
      await tester.pumpAndSettle();
      final model = tester.widget<AnchoredSelect<String>>(selector('模型'));
      expect(model.value, '');
      expect(model.options.keys, ['', 'second-model']);
      await tester.tap(selector('模型'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('second-model').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(role.apiId, store.apis.last.id);
      expect(role.model, 'second-model');
      expect(tester.takeException(), isNull);
    },
  );
}
