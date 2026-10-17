import 'package:flutter_test/flutter_test.dart';
import 'package:rolechat/runtime/agent_execution.dart';
import 'package:rolechat/runtime/agent_gateway.dart';

void main() {
  const sent = ToolCall('sent', 'send_message', {'text': '出门啦'});
  const stale = ToolCall('stale', 'send_message', {'text': '没执行的内容'});
  test('chat journal keeps only executed calls and matching tool results', () {
    final execution = AgentExecution();
    final step = execution.record(
      const ModelTurn(
        [sent, stale],
        [
          {'role': 'assistant', 'content': null},
        ],
      ),
      [
        (sent, {'sent': true, 'message_id': 'message'}),
      ],
      'chat',
    );
    expect(step, hasLength(2));
    expect(step.first['role'], 'assistant');
    expect((step.first['tool_calls'] as List).single['id'], 'sent');
    expect(step.last['tool_call_id'], 'sent');
    expect(execution.transcript.toString(), isNot(contains('stale')));
  });
  test(
    'responses journal retains reasoning and pairs only executed function calls',
    () {
      final execution = AgentExecution();
      final step = execution.record(
        const ModelTurn(
          [sent, stale],
          [
            {'type': 'reasoning', 'id': 'reasoning', 'summary': []},
            {
              'type': 'function_call',
              'call_id': 'sent',
              'name': 'send_message',
              'arguments': '{"text":"出门啦"}',
            },
            {
              'type': 'function_call',
              'call_id': 'stale',
              'name': 'send_message',
              'arguments': '{"text":"没执行的内容"}',
            },
          ],
        ),
        [
          (sent, {'sent': true}),
        ],
        'responses',
      );
      expect(step.map((m) => m['type']), [
        'reasoning',
        'function_call',
        'function_call_output',
      ]);
      expect(step.last['call_id'], 'sent');
      expect(execution.transcript.toString(), isNot(contains('stale')));
    },
  );
  test('discarded response leaves no transcript to replay', () {
    final execution = AgentExecution();
    expect(execution.record(const ModelTurn([stale], []), [], 'chat'), isEmpty);
    expect(execution.transcript, isEmpty);
  });
}
