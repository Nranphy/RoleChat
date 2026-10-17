import 'dart:convert';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/application/agents/ports/agent_workspace.dart';
import 'package:rolechat/application/agents/execution/agent_binding.dart';
import 'package:rolechat/application/agents/ports/agent_gateway.dart';
import 'package:rolechat/application/agents/tools/agent_tools.dart';
import 'package:rolechat/application/agents/tools/tool_definitions.dart';
import 'package:rolechat/application/agents/execution/agent_execution.dart';
import 'package:rolechat/application/agents/execution/context_builder.dart';
import 'package:rolechat/domain/services/schedule_policy.dart';
import 'package:rolechat/application/agents/execution/model_request_gate.dart';
import 'package:rolechat/core/diagnostics/runtime_events.dart';

class AgentRunner {
  AgentRunner(
    this.store, {
    required this.gateway,
    required this.gate,
    required this.log,
    required this.isClosed,
    required this.clock,
  });
  final AgentWorkspace store;
  final AgentGateway gateway;
  final ModelRequestGate gate;
  final RuntimeLog log;
  final bool Function() isClosed;
  final DateTime Function() clock;
  void _log(String event, Map<String, Object?> details) => log(event, details);
  String _generation(Conversation chat, RoleProfile role) => jsonEncode([
    for (final m in chat.messages)
      if (m.roleId != role.id) [m.id, m.text],
  ]);

  Future<void> run(
    AgentBinding binding,
    Conversation chat, {
    required void Function() onProcessing,
  }) async {
    final role = binding.role;
    final api = binding.api;
    final settings = binding.settings;
    final epoch = store.dataEpoch;
    final model = binding.model;
    final limiter = binding.key;
    bool valid() =>
        !isClosed() &&
        !store.transferring &&
        store.dataEpoch == epoch &&
        store.roles.contains(role) &&
        !role.archived &&
        store.conversations.contains(chat) &&
        !chat.archived &&
        chat.members.contains(role.id) &&
        binding.current(store);
    ModelRequestLease? lease;
    var sentMessages = 0;
    final execution = AgentExecution();
    final runId = store.newId();
    try {
      if (gate.atCapacity(limiter, settings.concurrency)) {
        _log('等待模型并发额度', {
          'role': role.name,
          'concurrency': settings.concurrency,
        });
      }
      lease = await gate.acquire(
        limiter,
        settings.concurrency,
        () =>
            valid() &&
            SchedulePolicy.match(role, store.schedules, clock()).probability >
                0,
      );
      if (lease == null) {
        _log('取消等待', {'role': role.name, 'reason': '会话或角色已失效，或当前行程概率为 0'});
        return;
      }
      onProcessing();
      while (valid()) {
        if (execution.requests >= role.maxToolRounds) {
          throw StateError('达到工具循环最大轮数（包含上下文更新前的请求）');
        }
        final generation = _generation(chat, role);
        bool current() => valid() && generation == _generation(chat, role);
        final viewKey = 'view:${role.id}:${chat.id}';
        final previousViewSequence = (store.runtimeData[viewKey] as int?) ?? 0;
        store.runtimeData[viewKey] = chat.nextSequence - 1;
        final messages = ContextBuilder().build(
          store,
          role,
          chat,
          api,
          settings,
          SchedulePolicy.match(role, store.schedules, clock()),
          agentTools,
          clock(),
          previousViewSequence: previousViewSequence,
        );
        messages.addAll(execution.transcript);
        await store.save();
        _log('上下文就绪', {
          'role': role.name,
          'chatId': chat.id,
          'messageCount': chat.messages.length,
          'estimatedTokens': estimateTokens(messages),
        });
        final executor = AgentToolExecutor(store, role, chat);
        var restart = false;
        while (execution.requests < role.maxToolRounds) {
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
            execution.requests++;
            _log('请求模型', {
              'runId': runId,
              'role': role.name,
              'chatId': chat.id,
              'round': execution.requests,
              'maxRounds': role.maxToolRounds,
              'model': role.model,
              'protocol': settings.protocol,
            });
            turn = await gateway.complete(
              api,
              model,
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
            gate.coolDown(limiter, clock().add(const Duration(seconds: 60)));
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
          _log('模型返回工具', {
            'role': role.name,
            'tools': turn.calls.map((c) => c.name).toList(),
          });
          var finished = false;
          final results = <(ToolCall, Object)>[];
          for (final call in turn.calls) {
            if (!current()) {
              restart = true;
              break;
            }
            Object result;
            try {
              final receipt = execution.execute(call, executor, current);
              result = receipt.$1;
              if (call.name == 'send_message') {
                final message = result as Map;
                if (receipt.$2) {
                  _log('复用工具调用结果', {
                    'runId': runId,
                    'role': role.name,
                    'chatId': chat.id,
                    'toolCallId': call.id,
                    'messageId': message['message_id'],
                  });
                } else {
                  sentMessages++;
                  _log('消息已发送', {
                    'runId': runId,
                    'role': role.name,
                    'chatId': chat.id,
                    'toolCallId': call.id,
                    'messageId': message['message_id'],
                  });
                }
              }
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
            results.add((call, result));
            if (finished) break;
          }
          messages.addAll(execution.record(turn, results, settings.protocol));
          if (restart) break;
          if (finished) {
            _log('模型结束本轮', {
              'role': role.name,
              'chatId': chat.id,
              'sentMessages': sentMessages,
            });
            return;
          }
          if (execution.requests == role.maxToolRounds) {
            throw StateError('达到工具循环最大轮数');
          }
        }
        if (!restart) return;
      }
    } catch (e) {
      _log('处理失败', {
        'role': role.name,
        'chatId': chat.id,
        'error': '$e'.replaceAll(api.key, '[REDACTED]'),
      });
      if (valid()) {
        store.reportError('${role.name}试图发消息但失败了：$e');
      }
    } finally {
      lease?.release();
    }
  }
}
