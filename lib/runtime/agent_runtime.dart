import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
  final _retryAfter = <String, DateTime>{};
  Timer? _timer;
  bool _closed = false;
  int? _epoch;
  String? _pauseReason;
  final _skipReasons = <String, String>{};

  void _log(String event, [Map<String, Object?> details = const {}]) {
    debugPrint(
      '[RoleChat runtime] ${jsonEncode({'time': DateTime.now().toIso8601String(), 'event': event, ...details})}',
    );
  }

  void _skip(RoleProfile role, String reason) {
    if (_skipReasons[role.id] == reason) return;
    _skipReasons[role.id] = reason;
    _log('跳过角色', {'role': role.name, 'roleId': role.id, 'reason': reason});
  }

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
    _log('调度启动', {'tickSeconds': 1});
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => tick(DateTime.now()),
    );
    tick(DateTime.now());
  }

  void dispose() {
    _closed = true;
    _timer?.cancel();
    _log('调度停止');
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
    final pauseReason = _closed
        ? '运行时已关闭'
        : store.transferring
        ? '正在导入或清理数据'
        : browserHidden() && store.runtimeData['background'] == false
        ? '页面在后台且未允许后台运行'
        : null;
    if (pauseReason != null) {
      if (_pauseReason != pauseReason) _log('调度暂停', {'reason': pauseReason});
      _pauseReason = pauseReason;
      return;
    }
    if (_pauseReason != null) _log('调度恢复');
    _pauseReason = null;
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
        _skip(
          role,
          api == null
              ? '未关联 API 配置'
              : api.key.trim().isEmpty
              ? 'API Key 为空'
              : '模型名称为空',
        );
        continue;
      }
      final settings = api.settings(role.model);
      final retryAfter = _retryAfter['${api.id}:${role.model}'];
      if (retryAfter != null && now.isBefore(retryAfter)) {
        _skip(role, '模型未返回工具调用，暂缓重试至 ${retryAfter.toIso8601String()}');
        continue;
      }
      if (_skipReasons.remove(role.id) != null) {
        _log('角色恢复调度', {'role': role.name});
      }
      final clock = _roles.putIfAbsent(role.id, _RoleClock.new);
      final activity = SchedulePolicy.match(role, store.schedules, now);
      final transition =
          clock.activity != null && clock.activity != activity.key;
      clock.activity = activity.key;
      if (activity.probability == 0) clock.pending.clear();
      if (transition) {
        _log('行程切换', {
          'role': role.name,
          'activity': activity.name,
          'baseProbability': activity.probability,
        });
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
        _log('定期检查', {
          'role': role.name,
          'roleId': role.id,
          'activity': activity.name,
          'baseProbability': activity.probability,
          'nextCheck': clock.nextCheck.toIso8601String(),
          'state': state(role.id).name,
          'chatCount': _chats(role).length,
        });
        if (activity.probability > 0) {
          for (final chat in _chats(role)) {
            if (clock.activeChat == chat.id) {
              _log('跳过当前会话', {
                'role': role.name,
                'chatId': chat.id,
                'reason': '已在等待额度或处理中',
              });
              continue;
            }
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
            final roll = random.nextDouble();
            _log('概率判定', {
              'role': role.name,
              'chatId': chat.id,
              'unreadCount': unread.length,
              'mentioned': unread.any((m) => m.mentions.contains(role.id)),
              'consecutiveAiMessages': count,
              'effectiveProbability': p,
              'random': roll,
              'passed': roll < p,
            });
            if (roll < p) {
              clock.pending.putIfAbsent(
                chat.id,
                () => now.add(Duration(milliseconds: random.nextInt(5001))),
              );
              _log('激活等待', {
                'role': role.name,
                'chatId': chat.id,
                'due': clock.pending[chat.id]!.toIso8601String(),
              });
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
      _log('开始处理会话', {
        'role': role.name,
        'chatId': chat.id,
        'model': role.model,
      });
      unawaited(
        _run(role, chat, api, settings).whenComplete(() {
          clock.running = false;
          clock.processing = false;
          clock.activeChat = null;
          _log('处理结束', {'role': role.name, 'chatId': chat.id});
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
    var sentMessages = 0;
    try {
      if ((_requests[limiter] ?? 0) >= settings.concurrency) {
        _log('等待模型并发额度', {
          'role': role.name,
          'concurrency': settings.concurrency,
        });
      }
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
        _log('取消等待', {'role': role.name, 'reason': '会话或角色已失效，或当前行程概率为 0'});
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
        _log('上下文就绪', {
          'role': role.name,
          'chatId': chat.id,
          'messageCount': chat.messages.length,
          'estimatedTokens': estimateTokens(messages),
        });
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
            _log('请求模型', {
              'role': role.name,
              'chatId': chat.id,
              'round': round + 1,
              'maxRounds': role.maxToolRounds,
              'model': role.model,
              'protocol': settings.protocol,
            });
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
            _log('上下文已变化，重新处理', {'role': role.name, 'chatId': chat.id});
            restart = true;
            break;
          }
          if (turn.calls.isEmpty) {
            _retryAfter[limiter] = DateTime.now().add(
              const Duration(seconds: 60),
            );
            _log('未返回工具调用', {
              'role': role.name,
              'model': role.model,
              'finishReason': turn.finishReason,
              'maxOutputTokens': settings.maxOutput,
              'retrySeconds': 60,
            });
            throw FormatException(
              turn.finishReason == 'length' ||
                      turn.finishReason == 'max_output_tokens'
                  ? '模型达到输出 token 上限，尚未产生工具调用。请提高模型配置的最大输出 tokens（推理模型的思考也可能占用此额度）。60 秒后允许重试。'
                  : '模型本轮未返回原生工具调用（结束原因：${turn.finishReason ?? "未知"}），不能据此认定模型不支持工具。请检查接口和模型的工具支持；60 秒后允许重试。',
            );
          }
          messages.addAll(turn.continuation);
          _log('模型返回工具', {
            'role': role.name,
            'tools': turn.calls.map((c) => c.name).toList(),
          });
          var finished = false;
          for (final call in turn.calls) {
            if (!current()) {
              restart = true;
              break;
            }
            Object result;
            try {
              result = executor.execute(call.name, call.arguments, current);
              if (call.name == 'send_message') sentMessages++;
              _log('工具执行成功', {
                'role': role.name,
                'chatId': chat.id,
                'tool': call.name,
              });
              if (call.name == 'finish') finished = true;
            } catch (e) {
              _log('工具执行失败', {
                'role': role.name,
                'tool': call.name,
                'errorType': e.runtimeType.toString(),
              });
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
          if (finished) {
            _log('模型结束本轮', {
              'role': role.name,
              'chatId': chat.id,
              'sentMessages': sentMessages,
            });
            return;
          }
          if (round == role.maxToolRounds - 1) throw StateError('达到工具循环最大轮数');
        }
        if (!restart) return;
      }
    } catch (e) {
      _log('处理失败', {
        'role': role.name,
        'chatId': chat.id,
        'error': '$e'.replaceAll(api.key, '[REDACTED]'),
      });
      if (_valid(role, chat, epoch)) {
        store.runtimeError = '${role.name}试图发消息但失败了：$e';
        store.refresh();
      }
    } finally {
      if (acquired) _requests[limiter] = (_requests[limiter] ?? 1) - 1;
    }
  }
}
