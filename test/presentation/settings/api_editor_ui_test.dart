import '../../fixtures/test_store.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/presentation/features/settings/api_editor.dart';
import 'package:rolechat/infrastructure/ai/model_availability_checker.dart';
import 'package:rolechat/application/apis/ports/api_checker.dart';

class PendingApiChecker extends ModelAvailabilityChecker {
  final pending = <Completer<ModelCheckResult>>[];
  @override
  Future<ModelCheckResult> checkApi({
    required String address,
    required String apiKey,
  }) {
    final request = Completer<ModelCheckResult>();
    pending.add(request);
    return request.future;
  }
}

void main() {
  testWidgets(
    'API dialog ignores stale results and late completion after dismissal',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = createTestStore(await SharedPreferences.getInstance());
      final checker = PendingApiChecker();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const SizedBox())),
      );
      final context = tester.element(find.byType(Scaffold));
      final route = editApi(context, store, checker: checker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('检查接口'));
      await tester.pump();
      expect(find.text('检查中…'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, '接口地址'),
        'https://changed.test/v1',
      );
      checker.pending.last.complete(const ModelCheckResult(true, 'stale'));
      await tester.pump();
      expect(find.text('stale'), findsNothing);
      await tester.tap(find.text('检查接口'));
      await tester.pump();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await route;
      checker.pending.last.complete(const ModelCheckResult(true, 'late'));
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      store.dispose();
    },
  );
}
