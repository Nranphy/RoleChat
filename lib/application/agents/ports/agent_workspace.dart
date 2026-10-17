import 'package:rolechat/domain/models/models.dart';

/// Runtime-facing data and operations. Implementations own persistence and UI
/// notifications; scheduling and tools never depend on a particular app store.
abstract interface class AgentWorkspace {
  List<RoleProfile> get roles;
  List<RoleProfile> get activeRoles;
  List<ApiProfile> get apis;
  List<Conversation> get conversations;
  List<Conversation> get activeChats;
  List<ScheduleEntry> get schedules;
  Map<String, dynamic> get runtimeData;
  int get dataEpoch;
  bool get transferring;
  String newId();
  void changed();
  Future<bool> save();
  void reportError(String message);
}
