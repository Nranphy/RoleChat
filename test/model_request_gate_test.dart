import 'package:flutter_test/flutter_test.dart';
import 'package:rolechat/runtime/model_request_gate.dart';

void main() {
  test(
    'capacity is shared only for the same API/model and release is idempotent',
    () async {
      final gate = ModelRequestGate();
      final first = (await gate.acquire('one', 1, () => true))!;
      expect(gate.atCapacity('one', 1), isTrue);
      expect(gate.atCapacity('two', 1), isFalse);
      final other = (await gate.acquire('two', 1, () => true))!;
      first.release();
      first.release();
      expect(gate.atCapacity('one', 1), isFalse);
      other.release();
    },
  );
  test('a waiting invalidated job never acquires a slot', () async {
    final gate = ModelRequestGate();
    final first = (await gate.acquire('model', 1, () => true))!;
    var valid = true;
    final waiting = gate.acquire('model', 1, () => valid);
    valid = false;
    expect(await waiting, isNull);
    expect(gate.atCapacity('model', 1), isTrue);
    first.release();
  });
}
