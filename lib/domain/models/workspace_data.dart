import 'package:rolechat/domain/models/models.dart';

class WorkspaceData {
  WorkspaceData({
    required this.apis,
    required this.roles,
    required this.chats,
    required this.schedules,
    Map<String, dynamic>? runtime,
  }) : runtime = runtime ?? {};
  final List<ApiProfile> apis;
  final List<RoleProfile> roles;
  final List<Conversation> chats;
  final List<ScheduleEntry> schedules;
  final Map<String, dynamic> runtime;
}
