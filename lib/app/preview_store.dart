import 'package:timezone/data/latest.dart' as tzdata;
import '../models/workspace_data.dart';
import '../data/workspace_lifecycle.dart';
import '../data/workspace_storage.dart';
import '../data/workspace_repository.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../runtime/agent_runtime.dart';
import '../runtime/agent_workspace.dart';
import '../runtime/browser_environment.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/app_theme.dart';
import '../models/preview_models.dart';
import '../models/workspace_cleanup.dart';
import '../services/conversation_messages.dart';
import '../services/profile_actions.dart';

class PreviewStore extends ChangeNotifier implements AgentWorkspace {
  PreviewStore(this.preferences, {WorkspaceStorage? storage})
    : _persistence = WorkspaceRepository(storage ?? MemoryWorkspaceStorage()) {
    tzdata.initializeTimeZones();
  }
  final SharedPreferences preferences;
  final WorkspaceRepository _persistence;
  late final _lifecycle = WorkspaceLifecycle(_persistence);
  AgentRuntime? runtime;
  String? runtimeError;
  @override
  Future<bool> save() => saveProfiles();
  @override
  void reportError(String message) {
    runtimeError = message;
    refresh();
  }

  void startRuntime() {
    runtime ??= AgentRuntime(this);
    runtime!.start();
  }

  WorkspaceStorage get storage => _persistence.storage;
  ProfileActions get profileActions => ProfileActions(data, newId: newId);
  Future<bool> saveRole(RoleProfile role, {List<ScheduleEntry>? schedules}) {
    profileActions.saveRole(role, schedules: schedules);
    refresh();
    return saveProfiles();
  }

  Future<bool> saveApi(
    ApiProfile api, {
    Map<String, String> renamed = const {},
  }) {
    profileActions.saveApi(api, renamed: renamed);
    refresh();
    return saveProfiles();
  }

  void renameRole(String id, String name) {
    profileActions.renameRole(id, name);
    changed();
  }

  Future<bool> saveGroup(Conversation group) {
    final isNew = !conversations.any((c) => c.id == group.id);
    profileActions.saveGroup(group);
    if (isNew) {
      select(group.id);
    } else {
      refresh();
    }
    return saveProfiles();
  }

  void restoreRole(String id) {
    profileActions.setRoleArchived(id, false);
    ensureSelection();
    changed();
  }

  void restoreChat(Conversation chat) {
    chat.archived = false;
    ensureSelection();
    changed();
  }

  void deleteChat(Conversation chat) {
    conversations.remove(chat);
    ensureSelection();
    changed();
  }

  void clearMessages(Conversation chat) {
    chat.messages.clear();
    changed();
  }

  void deleteMessage(Conversation chat, ChatMessage message) {
    chat.messages.remove(message);
    changed();
  }

  void removeApi(String id) {
    profileActions.removeApi(id);
    changed();
  }

  @override
  final runtimeData = <String, dynamic>{};
  bool _disposed = false;
  @override
  bool transferring = false;
  @override
  int dataEpoch = 0;
  String localTimezone = 'UTC';
  Future<void> importData(WorkspaceData merged) async {
    if (transferring) throw StateError('本地数据操作正在进行');
    transferring = true;
    dataEpoch++;
    refresh();
    try {
      await _persistence.saveOrThrow(merged);
      applyData(merged);
    } finally {
      transferring = false;
      refresh();
    }
  }

  Future<void> clearData(WorkspaceCleanup scope) async {
    if (transferring) throw StateError('本地数据操作正在进行');
    transferring = true;
    dataEpoch++;
    refresh();
    try {
      final next = await _lifecycle.clear(scope, data);
      if (next == null) return;
      if (scope == WorkspaceCleanup.all) {
        runtime?.dispose();
        runtime = null;
        await preferences.remove('themeMode');
        await preferences.remove('seed');
      }
      applyData(next);
      runtimeError = null;
      showChatOnMobile = false;
    } finally {
      transferring = false;
      refresh();
    }
  }

  Future<void>? _initialization;
  Future<void> initialize() => _initialization ??= _initializeWorkspace();

  Future<void> _initializeWorkspace() async {
    localTimezone = browserTimezone();
    applyData(await _lifecycle.initialize(localTimezone));
  }

  WorkspaceData get data => WorkspaceData(
    apis: apis,
    roles: roles,
    chats: conversations,
    schedules: schedules,
    runtime: runtimeData,
  );
  void applyData(WorkspaceData data) {
    dataEpoch++;
    apis
      ..clear()
      ..addAll(data.apis);
    roles
      ..clear()
      ..addAll(data.roles);
    conversations
      ..clear()
      ..addAll(data.chats);
    schedules
      ..clear()
      ..addAll(data.schedules);
    runtimeData
      ..clear()
      ..addAll(data.runtime);
    if (!activeChats.any((c) => c.id == selectedId)) {
      selectedId = activeChats.firstOrNull?.id ?? '';
    }
    refresh();
  }

  @override
  List<Conversation> get activeChats =>
      conversations.where((c) => !c.archived).toList();
  @override
  List<RoleProfile> get activeRoles => roles.where((r) => !r.archived).toList();
  void refresh() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    runtime?.dispose();
    _persistence.close();
    super.dispose();
  }

  int destination = 0;
  String selectedId = '';
  bool showChatOnMobile = false;
  ThemeMode get mode {
    final index = preferences.getInt('themeMode');
    return index != null && index >= 0 && index < ThemeMode.values.length
        ? ThemeMode.values[index]
        : ThemeMode.system;
  }

  Color get seed =>
      Color(preferences.getInt('seed') ?? AppTheme.seeds.first.toARGB32());
  Future<void> setMode(ThemeMode value) async {
    await preferences.setInt('themeMode', value.index);
    refresh();
  }

  Future<void> setSeed(Color value) async {
    await preferences.setInt('seed', value.toARGB32());
    notifyListeners();
  }

  @override
  void changed() {
    refresh();
    unawaited(saveProfiles());
  }

  void navigate(int value) {
    destination = value;
    showChatOnMobile = false;
    notifyListeners();
  }

  void select(String id) {
    selectedId = id;
    destination = 0;
    showChatOnMobile = true;
    notifyListeners();
  }

  Conversation get selected => conversations.firstWhere(
    (c) => c.id == selectedId,
    orElse: () => conversations.first,
  );
  RoleProfile role(String id) => roles.firstWhere((r) => r.id == id);
  @override
  String newId() => const Uuid().v4();

  void send(String text, {MessageReference? reply}) {
    if (text.trim().isEmpty) return;
    ConversationMessages.append(
      selected,
      id: newId(),
      text: text,
      now: DateTime.now(),
      roles: activeRoles,
      reply: reply,
    );
    changed();
  }

  void addRole(RoleProfile profile) {
    profileActions.saveRole(profile);
    changed();
  }

  void removeRole(String id) {
    profileActions.setRoleArchived(id, true);
    ensureSelection();
    changed();
  }

  void deleteRole(String id, {required bool keepHistory}) {
    profileActions.deleteRole(id, keepHistory: keepHistory);
    changed();
  }

  void archiveChat(Conversation chat) {
    chat.archived = true;
    ensureSelection();
    changed();
  }

  void ensureSelection() {
    if (!activeChats.any((c) => c.id == selectedId)) {
      selectedId = activeChats.firstOrNull?.id ?? '';
    }
  }

  void addGroup(
    String name,
    List<String> members, {
    String? avatar,
    String background = '',
  }) {
    final id = newId();
    profileActions.saveGroup(
      Conversation(
        id: id,
        name: name,
        avatar: avatar,
        background: background,
        members: members,
        group: true,
      ),
    );
    select(id);
    changed();
  }

  String? get persistenceError => _persistence.error;
  String? avatarFor(Conversation c) => c.group
      ? c.avatar
      : roles.where((r) => c.members.contains(r.id)).firstOrNull?.avatar;
  Future<bool> saveProfiles() async {
    if (transferring) return false;
    final saved = await _persistence.save(data);
    if (!saved) refresh();
    return saved;
  }

  @override
  final apis = <ApiProfile>[];
  @override
  final roles = <RoleProfile>[];
  @override
  final conversations = <Conversation>[];
  @override
  final schedules = <ScheduleEntry>[];
}
