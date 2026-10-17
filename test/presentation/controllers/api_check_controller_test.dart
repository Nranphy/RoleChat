import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolechat/presentation/controllers/api_check_controller.dart';
import 'package:rolechat/application/apis/ports/api_checker.dart';

void main() {
  test(
    'checks reject duplicates and ignore results for changed inputs',
    () async {
      final controller = ApiCheckController();
      final response = Completer<ModelCheckResult>();
      var calls = 0;
      Future<ModelCheckResult> request() {
        calls++;
        return response.future;
      }

      final pending = controller.run(request);
      await controller.run(request);
      expect(calls, 1);
      expect(controller.running, isTrue);
      controller.invalidate();
      response.complete(const ModelCheckResult(true, 'old'));
      await pending;
      expect(controller.result, isNull);
      expect(controller.running, isFalse);
      await controller.run(() async => const ModelCheckResult(true, 'new'));
      expect(controller.result!.message, 'new');
      controller.dispose();
    },
  );
  test('closing an editor prevents late completion notifications', () async {
    final controller = ApiCheckController();
    final response = Completer<ModelCheckResult>();
    var changes = 0;
    controller.addListener(() => changes++);
    final pending = controller.run(() => response.future);
    expect(changes, 1);
    controller.dispose();
    response.complete(const ModelCheckResult(true, 'late'));
    await pending;
    expect(changes, 1);
  });
  test(
    'unexpected failures release the running state for another attempt',
    () async {
      final controller = ApiCheckController();
      await controller.run(() async => throw StateError('failed'));
      expect(controller.running, isFalse);
      expect(controller.result!.success, isFalse);
      controller.dispose();
    },
  );
}
