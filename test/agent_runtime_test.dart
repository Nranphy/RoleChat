import 'fixtures/test_store.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rolechat/app/preview_store.dart';
import 'package:rolechat/models/preview_models.dart';
import 'package:rolechat/runtime/agent_gateway.dart';
import 'package:rolechat/runtime/agent_runtime.dart';
import 'package:rolechat/runtime/agent_tools.dart';
import 'package:rolechat/runtime/agent_documents.dart';
import 'package:rolechat/runtime/schedule_policy.dart';
import 'package:rolechat/runtime/activation_policy.dart';
import 'package:rolechat/models/workspace_cleanup.dart';

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
  final store = createTestStore(await SharedPreferences.getInstance());
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
    'schedule transition does not queue a second run of the currently active chat',
    () async {
      final store = await fixture();
      final role = store.roles.single;
      final gateway = DeferredGateway();
      final runtime = AgentRuntime(
        store,
        gateway: gateway,
        random: ZeroRandom(),
      );
      final now = DateTime.now();
      runtime.tick(now);
      await settle();
      store.schedules.add(
        ScheduleEntry(
          id: store.newId(),
          roleId: role.id,
          activity: '聊天',
          start: '00:00',
          end: '23:59',
          probability: 100,
        ),
      );
      runtime.tick(now.add(const Duration(seconds: 1)));
      gateway.requests.single.complete(
        const ModelTurn([ToolCall('done', 'finish', {})], []),
      );
      await settle();
      runtime.tick(now.add(const Duration(seconds: 2)));
      await settle();
      expect(gateway.requests, hasLength(1));
      runtime.dispose();
      store.dispose();
    },
  );

  test(
    'same tool call is executed once and its full exchange reaches the next model request',
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
      gateway.requests.first.complete(
        const ModelTurn([
          ToolCall('a', 'send_message', {'text': '一起去散步吧'}),
        ], []),
      );
      await settle();
      expect(gateway.requests, hasLength(2));
      gateway.requests.last.complete(
        const ModelTurn([
          ToolCall('a', 'send_message', {'text': '一起去散步吧'}),
          ToolCall('d', 'send_message', {'text': '我在门口等你'}),
          ToolCall('e', 'finish', {}),
        ], []),
      );
      await settle();
      expect(store.selected.messages.map((m) => m.text), ['一起去散步吧', '我在门口等你']);
      expect(gateway.inputs.last, contains('role: assistant'));
      expect(gateway.inputs.last, contains('tool_call_id: a'));
      expect(gateway.inputs.last, contains('"sent":true'));
      runtime.dispose();
      store.dispose();
    },
  );

  test(
    'restart preserves completed assistant-tool exchanges and discards unexecuted stale calls',
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
      gateway.requests.first.complete(
        const ModelTurn([
          ToolCall('a', 'send_message', {'text': '我刚出门'}),
        ], []),
      );
      await settle();
      store.send('记得带伞');
      gateway.requests.last.complete(
        const ModelTurn([
          ToolCall('stale', 'send_message', {'text': '过期内容'}),
        ], []),
      );
      await settle();
      expect(gateway.requests, hasLength(3));
      expect(gateway.inputs.last, contains('tool_call_id: a'));
      expect(gateway.inputs.last, contains('role: assistant'));
      expect(gateway.inputs.last, isNot(contains('过期内容')));
      expect(gateway.inputs.last, contains('我刚出门'));
      gateway.requests.last.complete(
        const ModelTurn([
          ToolCall('new', 'send_message', {'text': '带着呢'}),
          ToolCall('done', 'finish', {}),
        ], []),
      );
      await settle();
      expect(store.selected.messages.map((m) => m.text), [
        '我刚出门',
        '记得带伞',
        '带着呢',
      ]);
      runtime.dispose();
      store.dispose();
    },
  );

  test('independent sends are not blocked by equal message content', () async {
    final store = await fixture();
    final role = store.roles.single;
    final first = AgentToolExecutor(store, role, store.selected);
    final original =
        first.execute('send_message', {'text': '好呀'}, () => true) as Map;
    final second = AgentToolExecutor(store, role, store.selected);
    final duplicate =
        second.execute('send_message', {'text': '好呀'}, () => true) as Map;
    expect(duplicate['message_id'], isNot(original['message_id']));
    expect(store.selected.messages, hasLength(2));
    store.send('明天也可以吗');
    final third = AgentToolExecutor(store, role, store.selected);
    final fresh =
        third.execute('send_message', {'text': '好呀'}, () => true) as Map;
    expect(fresh['sent'], isTrue);
    expect(store.selected.messages, hasLength(4));
    store.dispose();
  });

  test('context refreshes do not reset the handling request budget', () async {
    final store = await fixture();
    store.roles.single.maxToolRounds = 2;
    final gateway = DeferredGateway();
    final runtime = AgentRuntime(store, gateway: gateway, random: ZeroRandom());
    runtime.tick(DateTime.now());
    await settle();
    gateway.requests.first.complete(
      const ModelTurn([
        ToolCall('a', 'send_message', {'text': '出门啦'}),
      ], []),
    );
    await settle();
    store.send('等一下');
    gateway.requests.last.complete(
      const ModelTurn([
        ToolCall('stale', 'send_message', {'text': '过期回复'}),
      ], []),
    );
    await settle();
    expect(gateway.requests, hasLength(2));
    expect(store.runtimeError, contains('达到工具循环最大轮数'));
    expect(store.selected.messages.map((m) => m.text), ['出门啦', '等一下']);
    runtime.dispose();
    store.dispose();
  });

  test('changing model configuration invalidates an in-flight reply', () async {
    final store = await fixture();
    final role = store.roles.single;
    final gateway = DeferredGateway();
    final runtime = AgentRuntime(store, gateway: gateway, random: ZeroRandom());
    runtime.tick(DateTime.now());
    await settle();
    store.apis.single.models.remove(role.model);
    gateway.requests.single.complete(
      const ModelTurn([
        ToolCall('send', 'send_message', {'text': '旧配置消息'}),
        ToolCall('done', 'finish', {}),
      ], []),
    );
    await settle();
    expect(store.conversations.single.messages, isEmpty);
    runtime.dispose();
  });

  test(
    'missing tools cool down temporarily without persisting model disablement',
    () async {
      final store = await fixture();
      final role = store.roles.single;
      role.defaultActivationProbability = 100;
      final gateway = DeferredGateway();
      final runtime = AgentRuntime(
        store,
        gateway: gateway,
        random: ZeroRandom(),
      );
      final now = DateTime.now();
      runtime.tick(now);
      await settle();
      gateway.requests.single.complete(
        const ModelTurn([], [], finishReason: 'length'),
      );
      await settle();
      expect(store.runtimeError, contains('输出 token 上限'));
      expect(
        store.apis.single
            .settings(role.model)
            .toJson()
            .containsKey('toolsUnsupported'),
        isFalse,
      );
      runtime.tick(now.add(const Duration(seconds: 10)));
      await settle();
      expect(gateway.requests, hasLength(1));
      runtime.tick(now.add(const Duration(seconds: 70)));
      await settle();
      expect(gateway.requests, hasLength(2));
      gateway.requests.last.complete(
        const ModelTurn([ToolCall('done', 'finish', {})], []),
      );
      await settle();
      runtime.dispose();
    },
  );

  test(
    'cleanup prevents an in-flight model response from restoring cleared messages',
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
      await store.clearData(WorkspaceCleanup.messages);
      gateway.requests.single.complete(
        const ModelTurn([
          ToolCall('old', 'send_message', {'text': '不应写回的回复'}),
          ToolCall('done', 'finish', {}),
        ], []),
      );
      await settle();
      expect(store.selected.messages, isEmpty);
      expect(store.runtimeError, isNull);
      runtime.dispose();
      store.dispose();
    },
  );
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
      'expected_hash': AgentDocuments.hash(''),
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
    expect(const RoleplayActivationPolicy().probability(0, 100, true), 0);
    expect(
      const RoleplayActivationPolicy().probability(.2, 100, false),
      closeTo(.01, .00001),
    );
    expect(const RoleplayActivationPolicy().probability(1, 10, false), .5);
  });
  test(
    'unmatched schedules use role probability while matched rules take precedence',
    () async {
      final store = await fixture();
      final role = store.roles.single;
      final now = DateTime.utc(2026, 10, 17, 12);
      for (final probability in [0.0, 35.5, 100.0]) {
        role.defaultActivationProbability = probability;
        expect(
          SchedulePolicy.match(role, [], now).probability,
          probability / 100,
        );
      }
      role.defaultActivationProbability = 0;
      final schedule = ScheduleEntry(
        id: store.newId(),
        roleId: role.id,
        activity: '聊天',
        start: '09:00',
        end: '18:00',
        probability: 80,
      );
      expect(SchedulePolicy.match(role, [schedule], now).probability, .8);
      store.dispose();
    },
  );
}
