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
    List<Map<String, String>>? examples,
  }) : examples = examples ?? [];
  final String id;
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
  });
  final String id;
  final String text;
  final String? roleId;
  final MessageReference? reply;
  final String time;
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
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];
  final String id;
  String name, background;
  String? avatar;
  bool group;
  List<String> members;
  List<ChatMessage> messages;
}

class ApiProfile {
  ApiProfile({
    required this.id,
    required this.name,
    required this.url,
    this.key = '',
  });
  final String id;
  String name, url, key;
}

enum ScheduleRuleKind { daily, weekly, annual, date, range }

class ScheduleEntry {
  ScheduleEntry({
    required this.id,
    required this.roleId,
    required this.activity,
    required this.condition,
    required this.start,
    required this.end,
    required this.probability,
    this.dateDetail = '',
    this.weekdays = const [],
    this.ruleKind,
    this.dateFrom,
    this.dateUntil,
    this.annualMonth,
    this.annualDay,
  });
  final String id, roleId;
  String activity, condition, start, end, dateDetail;
  double probability;
  List<int> weekdays;
  ScheduleRuleKind? ruleKind;
  String? dateFrom, dateUntil;
  int? annualMonth, annualDay;
}
