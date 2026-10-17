class RoleProfile {
  RoleProfile({
    required this.id,
    required this.name,
    this.avatar,
    this.model = 'gpt-4o',
    this.apiId,
    this.identity = '',
    this.soul = '',
    this.memory = '',
    this.archived = false,
    this.timezone = 'UTC',
    this.checkMin = 5,
    this.checkMax = 30,
    this.maxToolRounds = 8,
    this.defaultActivationProbability = 50,
    this.lockSoul = false,
    this.lockMemory = false,
    List<String>? lockedSchedules,
    List<Map<String, String>>? examples,
  }) : examples = examples ?? [],
       lockedSchedules = lockedSchedules ?? [];
  final String id;
  bool archived, lockSoul, lockMemory;
  String timezone;
  int checkMin, checkMax, maxToolRounds;
  double defaultActivationProbability;
  List<String> lockedSchedules;
  String name, model, identity, soul, memory;
  String? apiId, avatar;
  List<Map<String, String>> examples;
}

class MessageReference {
  const MessageReference({
    required this.messageId,
    required this.text,
    required this.senderName,
    this.roleId,
  });
  final String messageId, text, senderName;
  final String? roleId;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    this.roleId,
    this.time = '16:42',
    this.reply,
    this.sequence = 0,
    this.senderName,
    DateTime? createdAt,
    List<String>? mentions,
  }) : createdAt = createdAt ?? DateTime.now().toUtc(),
       mentions = mentions ?? [];
  final String id;
  final String text;
  final String? roleId;
  final MessageReference? reply;
  final String time;
  int sequence;
  final DateTime createdAt;
  final String? senderName;
  final List<String> mentions;
  bool get isUser => roleId == null;
}

class Conversation {
  Conversation({
    required this.id,
    required this.name,
    this.avatar,
    required this.members,
    this.group = false,
    this.background = '',
    this.archived = false,
    List<ChatMessage>? messages,
    this.nextSequence = 1,
  }) : messages = messages ?? [] {
    for (final m in this.messages) {
      if (m.sequence == 0) m.sequence = nextSequence;
      if (m.sequence >= nextSequence) nextSequence = m.sequence + 1;
    }
  }
  final String id;
  String name, background;
  String? avatar;
  bool group, archived;
  int nextSequence;
  List<String> members;
  List<ChatMessage> messages;
}

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
      models.putIfAbsent(model, ModelSettings.new);
}

enum ScheduleRuleKind { daily, weekly, annual, date, range }

class ScheduleEntry {
  ScheduleEntry({
    required this.id,
    required this.roleId,
    required this.activity,
    required this.start,
    required this.end,
    required this.probability,
    this.weekdays = const [],
    this.ruleKind = ScheduleRuleKind.daily,
    this.dateFrom,
    this.dateUntil,
    this.annualMonth,
    this.annualDay,
  });
  final String id, roleId;
  String activity, start, end;
  double probability;
  List<int> weekdays;
  ScheduleRuleKind ruleKind;
  String? dateFrom, dateUntil;
  int? annualMonth, annualDay;
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
    this.toolsUnsupported = false,
  });
  int contextTokens,
      historyHigh,
      historyTarget,
      maxOutput,
      concurrency,
      timeoutSeconds;
  String protocol;
  bool toolsUnsupported;
  Map<String, dynamic> toJson() => {
    'contextTokens': contextTokens,
    'historyHigh': historyHigh,
    'historyTarget': historyTarget,
    'maxOutput': maxOutput,
    'concurrency': concurrency,
    'timeoutSeconds': timeoutSeconds,
    'protocol': protocol,
    'toolsUnsupported': toolsUnsupported,
  };
  factory ModelSettings.fromJson(Map<String, dynamic> j) => ModelSettings(
    contextTokens: j['contextTokens'] as int,
    historyHigh: j['historyHigh'] as int,
    historyTarget: j['historyTarget'] as int,
    maxOutput: j['maxOutput'] as int,
    concurrency: j['concurrency'] as int,
    timeoutSeconds: j['timeoutSeconds'] as int,
    protocol: j['protocol'] as String,
    toolsUnsupported: j['toolsUnsupported'] as bool,
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
