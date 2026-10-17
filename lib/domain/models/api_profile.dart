class ApiProfile {
  ApiProfile({
    required this.id,
    required this.name,
    required this.url,
    this.key = '',
    Map<String, ModelSettings>? models,
  }) : models = models ?? {};
  final String id;
  String name, url, key;
  Map<String, ModelSettings> models;
  ModelSettings settings(String model) =>
      models[model] ?? (throw StateError('模型尚未在 API 配置中设置：$model'));
}

class ModelSettings {
  ModelSettings({
    this.contextTokens = 32768,
    this.historyHigh = 20000,
    this.historyTarget = 12000,
    this.maxOutput = 2048,
    this.concurrency = 2,
    this.timeoutSeconds = 60,
    this.protocol = 'chat',
  });
  int contextTokens,
      historyHigh,
      historyTarget,
      maxOutput,
      concurrency,
      timeoutSeconds;
  String protocol;
  Map<String, dynamic> toJson() => {
    'contextTokens': contextTokens,
    'historyHigh': historyHigh,
    'historyTarget': historyTarget,
    'maxOutput': maxOutput,
    'concurrency': concurrency,
    'timeoutSeconds': timeoutSeconds,
    'protocol': protocol,
  };
  factory ModelSettings.fromJson(Map<String, dynamic> j) => ModelSettings(
    contextTokens: j['contextTokens'] as int,
    historyHigh: j['historyHigh'] as int,
    historyTarget: j['historyTarget'] as int,
    maxOutput: j['maxOutput'] as int,
    concurrency: j['concurrency'] as int,
    timeoutSeconds: j['timeoutSeconds'] as int,
    protocol: j['protocol'] as String,
  );
  void validate() {
    if (contextTokens < 1024 ||
        maxOutput < 1 ||
        historyTarget < 0 ||
        historyTarget >= historyHigh ||
        historyHigh + maxOutput >= contextTokens ||
        concurrency < 1 ||
        concurrency > 32 ||
        timeoutSeconds < 1 ||
        timeoutSeconds > 600 ||
        !['chat', 'responses'].contains(protocol)) {
      throw const FormatException('模型预算、并发或超时无效');
    }
  }
}
