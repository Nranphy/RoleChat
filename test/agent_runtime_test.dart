import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/runtime/agent_gateway.dart';
import 'package:rolechat/runtime/agent_runtime.dart';
import 'package:rolechat/runtime/agent_tools.dart';
import 'package:rolechat/runtime/context_builder.dart';
import 'package:rolechat/runtime/schedule_policy.dart';

class ZeroRandom implements Random {
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

class DeferredGateway implements AgentGateway {
  final requests = <Completer<ModelTurn>>[];
  final inputs = <String>[];
  @override
  Future<ModelTurn> complete(
    ApiProfile api,
    String model,
    ModelSettings settings,
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>> tools,
  ) {
    inputs.add(messages.toString());
    final result = Completer<ModelTurn>();
    requests.add(result);
    return result.future;
  }
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));
Future<PreviewStore> fixture() async {
  SharedPreferences.setMockInitialValues({});
  final store = PreviewStore(await SharedPreferences.getInstance());
  store.roles.removeRange(1, store.roles.length);
  final role = store.roles.single;
  role.identity = role.soul = role.memory = '';
  role.examples.clear();
  role.apiId = store.apis.single.id;
  store.apis.single.key = 'test';
  store.conversations.clear();
  store.addGroup('客厅', [role.id]);
  store.schedules.clear();
  return store;
}

void main() {
  test(
    'new messages invalidate pending effects and restart with latest history',
    () async {
      final store = await fixture();
      final gateway = DeferredGateway();
      final runtime = AgentRuntime(
        store,
        gateway: gateway,
        random: ZeroRandom(),
      );
      runtime.tick(DateTime.now());
      await settle();
      expect(gateway.requests.length, 1);
      expect(runtime.state(store.roles.single.id), AgentState.processing);
      store.send('刚到家的新消息');
      gateway.requests.first.complete(
        const ModelTurn([
          ToolCall('old', 'send_message', {'text': '过期回复'}),
        ], []),
      );
      await settle();
      expect(gateway.requests.length, 2);
      expect(gateway.inputs.last, contains('刚到家的新消息'));
      expect(store.selected.messages.any((m) => m.text == '过期回复'), isFalse);
      gateway.requests.last.complete(
        const ModelTurn([
          ToolCall('new', 'send_message', {'text': '回来啦'}),
          ToolCall('done', 'finish', {}),
        ], []),
      );
      await settle();
      expect(store.selected.messages.last.text, '回来啦');
      expect(runtime.state(store.roles.single.id), AgentState.paused);
      runtime.dispose();
      store.dispose();
    },
  );
  test('document writes enforce lock, hash and current membership', () async {
    final store = await fixture();
    final role = store.roles.single;
    final tools = AgentToolExecutor(store, role, store.selected);
    final args = {
      'name': 'memory.md',
      'content': '喜欢雨天',
      'expected_hash': contentHash(''),
    };
    role.lockMemory = true;
    expect(
      () => tools.execute('update_document', args, () => true),
      throwsStateError,
    );
    role.lockMemory = false;
    tools.execute('update_document', args, () => true);
    expect(role.memory, '喜欢雨天');
    expect(
      () => tools.execute('update_document', args, () => true),
      throwsStateError,
    );
    store.selected.members.clear();
    expect(
      () => tools.execute('search_history', {
        'conversation_id': store.selected.id,
        'query': '',
      }, () => true),
      throwsStateError,
    );
    store.dispose();
  });
  test('zero probability remains zero and decay has a coefficient floor', () {
    expect(SchedulePolicy.probability(0, 100, true), 0);
    expect(SchedulePolicy.probability(.2, 100, false), closeTo(.01, .00001));
    expect(SchedulePolicy.probability(1, 10, false), .5);
  });
}
