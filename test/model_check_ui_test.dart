import 'fixtures/test_store.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/features/agents/role_editor_dialog.dart';
import 'package:rolechat/services/model_availability_checker.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/shared/widgets/anchored_select.dart';

class ControlledChecker extends ModelAvailabilityChecker {
  final pending = <Completer<ModelCheckResult>>[];
  @override
  Future<ModelCheckResult> check({
    required String address,
    required String apiKey,
    required String model,
  }) {
    final result = Completer<ModelCheckResult>();
    pending.add(result);
    return result.future;
  }
}

void main() {
  testWidgets(
    'model detection disables duplicates, clears stale results and displays success or failure',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = createTestStore(await SharedPreferences.getInstance());
      final checker = ControlledChecker();
      final role = store.roles.first;
      role.apiId = store.apis.first.id;
      store.apis.first.models['changed-model'] = ModelSettings();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoleEditorDialog(
              store: store,
              role: role,
              modelChecker: checker,
            ),
          ),
        ),
      );
      final button = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == '检测模型',
      );
      await tester.tap(button);
      await tester.pump();
      expect(tester.widget<IconButton>(button).onPressed, isNull);
      final field = find.byWidgetPredicate(
        (w) => w is AnchoredSelect<String> && w.label == '模型',
      );
      await tester.tap(field);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('changed-model').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(
        tester.widget<AnchoredSelect<String>>(field).value,
        'changed-model',
      );
      checker.pending.last.complete(const ModelCheckResult(true, '旧结果'));
      await tester.pump();
      expect(find.text('旧结果'), findsNothing);
      await tester.tap(button);
      await tester.pump();
      checker.pending.last.complete(
        const ModelCheckResult(true, '检测成功：模型可调用。'),
      );
      await tester.pump();
      final success = tester.widget<Text>(find.text('检测成功：模型可调用。'));
      expect(success.style!.color, Colors.green.shade700);
      await tester.tap(button);
      await tester.pump();
      checker.pending.last.complete(
        const ModelCheckResult(false, '检测失败（HTTP 404）：model not found'),
      );
      await tester.pump();
      final failure = find.text('检测失败（HTTP 404）：model not found');
      expect(
        tester.widget<Text>(failure).style!.color,
        Theme.of(tester.element(failure)).colorScheme.error,
      );
      expect(find.text('检测成功：模型可调用。'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
