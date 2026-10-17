import 'dart:convert';
import '../models/preview_models.dart';
import '../models/workspace_data.dart';
import '../data/schedule_codec.dart';

/// In-memory profile operations; callers own validation UI and persistence.
class ProfileActions {
  ProfileActions(this.data, {required this.newId});
  final WorkspaceData data;
  final String Function() newId;

  void renameRole(String id, String name) {
    final role = data.roles.firstWhere((r) => r.id == id);
    role.name = name;
    for (final chat in data.chats.where(
      (c) => !c.group && c.members.contains(id),
    )) {
      chat.name = name;
    }
  }

  void saveRole(RoleProfile draft, {List<ScheduleEntry>? schedules}) {
    final role = data.roles.where((r) => r.id == draft.id).firstOrNull;
    if (role == null) {
      data.roles.add(draft);
      data.chats.add(
        Conversation(id: newId(), name: draft.name, members: [draft.id]),
      );
    } else {
      role.avatar = draft.avatar;
      role.apiId = draft.apiId;
      role.model = draft.model;
      role.identity = draft.identity;
      role.soul = draft.soul;
      role.memory = draft.memory;
      role.examples = draft.examples;
      role.timezone = draft.timezone;
      role.checkMin = draft.checkMin;
      role.checkMax = draft.checkMax;
      role.maxToolRounds = draft.maxToolRounds;
      role.defaultActivationProbability = draft.defaultActivationProbability;
      role.lockSoul = draft.lockSoul;
      role.lockMemory = draft.lockMemory;
      role.lockedSchedules = draft.lockedSchedules;
      renameRole(role.id, draft.name);
    }
    if (schedules != null) _replaceSchedules(draft.id, schedules);
  }

  void _replaceSchedules(String roleId, List<ScheduleEntry> updated) {
    final previous = {
      for (final s in data.schedules.where((s) => s.roleId == roleId))
        s.id: jsonEncode(ScheduleCodec.encode(s)),
    };
    bool unchanged(ScheduleEntry s) =>
        previous[s.id] == jsonEncode(ScheduleCodec.encode(s));
    data.schedules.removeWhere((s) => s.roleId == roleId);
    data.schedules.addAll([
      ...updated.where(unchanged),
      ...updated.where((s) => !unchanged(s)),
    ]);
  }

  List<RoleProfile> affectedByRemovedModels(
    String? apiId,
    Set<String> models,
    Map<String, String> renamed,
  ) => apiId == null
      ? []
      : data.roles
            .where(
              (r) =>
                  r.apiId == apiId &&
                  r.model.isNotEmpty &&
                  !renamed.containsKey(r.model) &&
                  !models.contains(r.model),
            )
            .toList();

  void saveApi(ApiProfile draft, {Map<String, String> renamed = const {}}) {
    final api = data.apis.where((a) => a.id == draft.id).firstOrNull;
    if (api == null) {
      data.apis.add(draft);
    } else {
      api.name = draft.name;
      api.url = draft.url;
      api.key = draft.key;
      api.models = draft.models;
    }
    for (final role in data.roles.where((r) => r.apiId == draft.id)) {
      role.model =
          renamed[role.model] ??
          (draft.models.containsKey(role.model) ? role.model : '');
    }
  }

  void removeApi(String id) {
    for (final role in data.roles.where((r) => r.apiId == id)) {
      role.apiId = null;
      role.model = '';
    }
    data.apis.removeWhere((a) => a.id == id);
  }

  void saveGroup(Conversation draft) {
    final group = data.chats.where((c) => c.id == draft.id).firstOrNull;
    if (group == null) {
      data.chats.insert(0, draft);
    } else {
      group.name = draft.name;
      group.avatar = draft.avatar;
      group.background = draft.background;
      group.members = draft.members;
    }
  }

  void setRoleArchived(String id, bool archived) {
    data.roles.firstWhere((r) => r.id == id).archived = archived;
    for (final chat in data.chats.where(
      (c) => !c.group && c.members.contains(id),
    )) {
      chat.archived = archived;
    }
  }

  void deleteRole(String id, {required bool keepHistory}) {
    data.roles.removeWhere((r) => r.id == id);
    data.schedules.removeWhere((s) => s.roleId == id);
    data.chats.removeWhere(
      (c) => !c.group && c.members.contains(id) && !keepHistory,
    );
    for (final chat in data.chats) {
      chat.members.remove(id);
    }
  }
}
