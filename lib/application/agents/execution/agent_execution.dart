import 'dart:convert';
import 'package:rolechat/application/agents/ports/agent_gateway.dart';
import 'package:rolechat/application/agents/tools/agent_tools.dart';

/// A handling session survives refreshed history and discarded HTTP responses.
/// Committed tool exchanges remain part of the model conversation.
class AgentExecution {
  final transcript = <Map<String, dynamic>>[];
  final _receipts = <String, (String, Object)>{};
  int requests = 0;

  (Object, bool) execute(
    ToolCall call,
    AgentToolExecutor executor,
    bool Function() current,
  ) {
    if (!current()) throw StateError('上下文已变化');
    final signature = jsonEncode([call.name, call.arguments]);
    final previous = _receipts[call.id];
    if (previous != null) {
      if (previous.$1 != signature) {
        throw const FormatException('模型重复使用工具调用 ID，但参数不同');
      }
      return (previous.$2, true);
    }
    final result = executor.execute(call.name, call.arguments, current);
    _receipts[call.id] = (signature, result);
    return (result, false);
  }

  /// Record only executed calls, keeping assistant/tool pairs well formed even
  /// when a context change interrupts a batch. Discarded calls are never replayed.
  List<Map<String, dynamic>> record(
    ModelTurn turn,
    List<(ToolCall, Object)> results,
    String protocol,
  ) {
    if (results.isEmpty) return [];
    final ids = results.map((r) => r.$1.id).toSet();
    final step = <Map<String, dynamic>>[];
    if (protocol == 'responses') {
      step.addAll(
        turn.continuation.where(
          (m) => m['type'] != 'function_call' || ids.contains(m['call_id']),
        ),
      );
      if (!step.any((m) => m['type'] == 'function_call')) {
        step.addAll(
          results.map(
            (r) => {
              'type': 'function_call',
              'call_id': r.$1.id,
              'name': r.$1.name,
              'arguments': jsonEncode(r.$1.arguments),
            },
          ),
        );
      }
      step.addAll(
        results.map(
          (r) => {
            'type': 'function_call_output',
            'call_id': r.$1.id,
            'output': jsonEncode(r.$2),
          },
        ),
      );
    } else {
      step.add({
        if (turn.continuation.isNotEmpty) ...turn.continuation.last,
        'role': 'assistant',
        'tool_calls': [
          for (final result in results)
            {
              'id': result.$1.id,
              'type': 'function',
              'function': {
                'name': result.$1.name,
                'arguments': jsonEncode(result.$1.arguments),
              },
            },
        ],
      });
      step.addAll(
        results.map(
          (r) => {
            'role': 'tool',
            'tool_call_id': r.$1.id,
            'content': jsonEncode(r.$2),
          },
        ),
      );
    }
    transcript.addAll(step);
    return step;
  }
}
