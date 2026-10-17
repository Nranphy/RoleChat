import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../app/preview_store.dart';
import '../models/preview_models.dart';
import 'agent_gateway.dart';
import 'agent_tools.dart';
import 'context_builder.dart';
import 'schedule_policy.dart';
import 'browser_environment.dart';

enum AgentState { paused, activated, processing }

class _RoleClock {
  DateTime nextCheck = DateTime.fromMillisecondsSinceEpoch(0);
  String? activity;
  final pending = <String, DateTime>{};
  final baselines = <String, int>{};
  bool running = false;
  bool processing = false;
  String? activeChat;
}

/// Owns timers and per-role serialization independently of the widget lifecycle.
class AgentRuntime {
  AgentRuntime(this.store, {AgentGateway? gateway, Random? random})
    : gateway = gateway ?? SdkAgentGateway(),
      random = random ?? Random();
  final PreviewStore store;
  final AgentGateway gateway;
  final Random random;
  final _roles = <String, _RoleClock>{};
  final _requests = <String, int>{};
  Timer? _timer;
  bool _closed = false;
  int? _epoch;
  AgentState state(String id) {
    final clock = _roles[id];
    return clock?.processing == true
        ? AgentState.processing
        : clock?.running == true || clock?.pending.isNotEmpty == true
        ? AgentState.activated
        : AgentState.paused;
  }

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => tick(DateTime.now()),
    );
    tick(DateTime.now());
  }

  void dispose() {
    _closed = true;
    _timer?.cancel();
  }

  List<Conversation> _chats(RoleProfile role) =>
      store.activeChats.where((c) => c.members.contains(role.id)).toList();
  bool _valid(RoleProfile role, Conversation chat, int epoch) =>
      !_closed &&
      !store.transferring &&
      store.dataEpoch == epoch &&
      store.roles.contains(role) &&
      !role.archived &&
      store.conversations.contains(chat) &&
      !chat.archived &&
      chat.members.contains(role.id);

  void tick(DateTime now) {
    if (_closed ||
        store.transferring ||
        (browserHidden() && store.runtimeData['background'] == false)) {
      return;
    }
    if (_epoch != store.dataEpoch) {
      _epoch = store.dataEpoch;
      for (final clock in _roles.values) {
        clock.pending.clear();
        clock.baselines.clear();
        clock.activity = null;
        clock.nextCheck = DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    for (final role in store.activeRoles) {
      final api = store.apis.where((a) => a.id == role.apiId).firstOrNull;
      if (api == null || api.key.trim().isEmpty || role.model.trim().isEmpty) {
        continue;
      }
      final settings = api.settings(role.model);
      if (settings.toolsUnsupported) continue;
      final clock = _roles.putIfAbsent(role.id, _RoleClock.new);
      final activity = SchedulePolicy.match(role, store.schedules, now);
      final transition =
          clock.activity != null && clock.activity != activity.key;
      clock.activity = activity.key;
      if (activity.probability == 0) clock.pending.clear();
      if (transition) {
        for (final chat in _chats(role)) {
          clock.baselines[chat.id] = chat.nextSequence - 1;
          if (activity.probability > 0) {
            clock.pending.putIfAbsent(
              chat.id,
              () => now.add(
                SchedulePolicy.transitionDelay(activity.probability, random),
              ),
            );
          }
        }
      }
      if (!now.isBefore(clock.nextCheck)) {
        clock.nextCheck = now.add(
          Duration(
            milliseconds:
                (role.checkMin * 1000 +
                        random.nextDouble() *
                            (role.checkMax - role.checkMin) *
                            1000)
                    .round(),
          ),
        );
        if (activity.probability > 0) {
          for (final chat in _chats(role)) {
            if (clock.activeChat == chat.id) continue;
            final cursor =
                (store.runtimeData['view:${role.id}:${chat.id}'] as int?) ?? 0;
            final unread = chat.messages.where(
              (m) => m.sequence > cursor && m.roleId != role.id,
            );
            final baseline = clock.baselines[chat.id] ?? 0;
            var count = 0;
            for (final m in chat.messages.reversed) {
              if (m.sequence <= baseline || m.isUser) break;
              count++;
            }
            final p = SchedulePolicy.probability(
              activity.probability,
              count,
              unread.any((m) => m.mentions.contains(role.id)),
            );
            if (random.nextDouble() < p) {
              clock.pending.putIfAbsent(
                chat.id,
                () => now.add(Duration(milliseconds: random.nextInt(5001))),
              );
            }
          }
        }
      }
      if (clock.running) continue;
      final due =
          clock.pending.entries.where((e) => !now.isBefore(e.value)).toList()
            ..sort((a, b) => a.value.compareTo(b.value));
      if (due.isEmpty) continue;
      final id = due.first.key;
      clock.pending.remove(id);
      final chat = _chats(role).where((c) => c.id == id).firstOrNull;
      if (chat == null) continue;
      clock.running = true;
      clock.activeChat = chat.id;
      unawaited(
        _run(role, chat, api, settings).whenComplete(() {
          clock.running = false;
          clock.processing = false;
          clock.activeChat = null;
        }),
      );
    }
  }

  String _generation(Conversation chat, RoleProfile role) => jsonEncode([
    for (final m in chat.messages)
      if (m.roleId != role.id) [m.id, m.text],
  ]);

  Future<void> _run(
    RoleProfile role,
    Conversation chat,
    ApiProfile api,
    ModelSettings settings,
  ) async {
    final epoch = store.dataEpoch;
    final limiter = '${api.id}:${role.model}';
    var acquired = false;
    try {
      while ((_requests[limiter] ?? 0) >= settings.concurrency) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!_valid(role, chat, epoch)) return;
        if (SchedulePolicy.match(
              role,
              store.schedules,
              DateTime.now(),
            ).probability ==
            0) {
          return;
        }
      }
      if (!_valid(role, chat, epoch) ||
          SchedulePolicy.match(
                role,
                store.schedules,
                DateTime.now(),
              ).probability ==
              0) {
        return;
      }
      _requests[limiter] = (_requests[limiter] ?? 0) + 1;
      acquired = true;
      _roles[role.id]?.processing = true;
      while (_valid(role, chat, epoch)) {
        final generation = _generation(chat, role);
        bool current() =>
            _valid(role, chat, epoch) && generation == _generation(chat, role);
        store.runtimeData['view:${role.id}:${chat.id}'] = chat.nextSequence - 1;
        final messages = ContextBuilder().build(
          store,
          role,
          chat,
          api,
          settings,
          SchedulePolicy.match(role, store.schedules, DateTime.now()),
          agentTools,
          DateTime.now(),
        );
        await store.saveProfiles();
        final executor = AgentToolExecutor(store, role, chat);
        var restart = false;
        for (var round = 0; round < role.maxToolRounds; round++) {
          if (!current()) {
            restart = true;
            break;
          }
          if (estimateTokens(messages) +
                  estimateTokens(agentTools) +
                  settings.maxOutput >
              settings.contextTokens) {
            throw StateError('本轮工具过程超出上下文预算');
          }
          late final ModelTurn turn;
          try {
            turn = await gateway.complete(
              api,
              role.model,
              settings,
              messages,
              agentTools,
            );
          } catch (_) {
            if (!current()) {
              restart = true;
              break;
            }
            rethrow;
          }
          if (!current()) {
            restart = true;
            break;
          }
          if (turn.calls.isEmpty) {
            settings.toolsUnsupported = true;
            store.changed();
            throw const FormatException('模型未返回原生工具调用，请确认模型支持工具调用');
          }
          messages.addAll(turn.continuation);
          var finished = false;
          for (final call in turn.calls) {
            if (!current()) {
              restart = true;
              break;
            }
            Object result;
            try {
              result = executor.execute(call.name, call.arguments, current);
              if (call.name == 'finish') finished = true;
            } catch (e) {
              result = {'error': '$e'};
            }
            messages.add(
              settings.protocol == 'responses'
                  ? {
                      'type': 'function_call_output',
                      'call_id': call.id,
                      'output': jsonEncode(result),
                    }
                  : {
                      'role': 'tool',
                      'tool_call_id': call.id,
                      'content': jsonEncode(result),
                    },
            );
          }
          if (restart) break;
          if (finished) return;
          if (round == role.maxToolRounds - 1) throw StateError('达到工具循环最大轮数');
        }
        if (!restart) return;
      }
    } catch (e) {
      if (_valid(role, chat, epoch)) {
        store.runtimeError = '${role.name}试图发消息但失败了：$e';
        store.refresh();
      }
    } finally {
      if (acquired) _requests[limiter] = (_requests[limiter] ?? 1) - 1;
    }
  }
}
