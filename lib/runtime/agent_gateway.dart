import 'dart:async';
import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;
import '../models/preview_models.dart';

class ToolCall {
  const ToolCall(this.id, this.name, this.arguments);
  final String id, name;
  final Map<String, dynamic> arguments;
}

class ModelTurn {
  const ModelTurn(this.calls, this.continuation, {this.finishReason});
  final List<ToolCall> calls;
  final List<Map<String, dynamic>> continuation;
  final String? finishReason;
}

abstract interface class AgentGateway {
  Future<ModelTurn> complete(
    ApiProfile api,
    String model,
    ModelSettings settings,
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>> tools,
  );
}

class SdkAgentGateway implements AgentGateway {
  @override
  Future<ModelTurn> complete(
    ApiProfile api,
    String model,
    ModelSettings settings,
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>> tools,
  ) async {
    final root = api.url.trim().replaceFirst(RegExp(r'/+$'), '');
    final versioned = RegExp(r'/v\d+$').hasMatch(Uri.parse(root).path);
    final slash = root.lastIndexOf('/');
    final sdk = OpenAIClient(
      apiKey: api.key,
      baseUrl: versioned ? root.substring(0, slash) : root,
      version: versioned ? root.substring(slash + 1) : 'v1',
      requestsTimeOut: Duration(seconds: settings.timeoutSeconds),
      retryPolicy: const OpenAIRetryPolicy(maxAttempts: 1),
    );
    final timeout = Duration(seconds: settings.timeoutSeconds);
    if (settings.protocol == 'responses') {
      final response = await sdk.responses
          .create(
            model: model,
            input: messages,
            store: false,
            tools: tools
                .map(
                  (t) => {
                    'type': 'function',
                    ...(t['function'] as Map<String, dynamic>),
                  },
                )
                .toList(),
            toolChoice: 'required',
            maxOutputTokens: settings.maxOutput,
          )
          .timeout(timeout);
      final output = (response.output as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return ModelTurn(
        output
            .where((o) => o['type'] == 'function_call')
            .map(
              (o) => ToolCall(
                o['call_id'] as String,
                o['name'] as String,
                _arguments(o['arguments']),
              ),
            )
            .toList(),
        output,
        finishReason:
            response.incompleteDetails?.reason ?? response.status.toString(),
      );
    }
    final client = http.Client();
    try {
      final response = await sdk.chat
          .create(
            model: model,
            messages: [],
            client: client,
            extraParams: {
              'messages': messages,
              'tools': tools,
              'tool_choice': 'required',
              'max_completion_tokens': settings.maxOutput,
            },
          )
          .timeout(timeout);
      if (response.choices.isEmpty) throw const FormatException('模型返回空响应');
      final message = response.choices.first.message.toMap();
      final calls = message['tool_calls'] as List? ?? [];
      return ModelTurn(
        calls
            .map(
              (c) => ToolCall(
                c['id'] as String,
                c['function']['name'] as String,
                _arguments(c['function']['arguments']),
              ),
            )
            .toList(),
        [message],
        finishReason: response.choices.first.finishReason,
      );
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _arguments(dynamic value) {
    if (value is! String || value.length > 65536) {
      throw const FormatException('工具参数过长或格式无效');
    }
    return Map<String, dynamic>.from(jsonDecode(value) as Map);
  }
}
