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
