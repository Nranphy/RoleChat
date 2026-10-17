import 'package:timezone/data/latest.dart' as tzdata;
import '../data/preset_workspace.dart';
import '../data/workspace_storage.dart';
import '../data/workspace_repository.dart';
import '../data/workspace_codec.dart';
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

class PreviewStore extends ChangeNotifier implements AgentWorkspace {
  PreviewStore(this.preferences, {WorkspaceStorage? storage})
    : _persistence = WorkspaceRepository(storage ?? MemoryWorkspaceStorage()) {
    tzdata.initializeTimeZones();
  }
  final SharedPreferences preferences;
  final WorkspaceRepository _persistence;
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
      if (!await _persistence.save(merged)) {
        throw StateError(_persistence.error!);
      }
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
      await _persistence.flush();
      if (scope == WorkspaceCleanup.initialization) {
        await storage.removeInitializationMarker();
        return;
      }
      if (scope == WorkspaceCleanup.all) {
        await storage.clearAll();
        runtime?.dispose();
        runtime = null;
        applyData(WorkspaceData(apis: [], roles: [], chats: [], schedules: []));
        await preferences.remove('themeMode');
        await preferences.remove('seed');
      } else {
        final next = scope == WorkspaceCleanup.profiles
            ? WorkspaceData(
                apis: apis.toList(),
                roles: [],
                chats: [],
                schedules: [],
                runtime: {
                  if (runtimeData.containsKey('background'))
                    'background': runtimeData['background'],
                },
              )
            : WorkspaceCodec.decode(WorkspaceCodec.encode(data));
        if (scope == WorkspaceCleanup.messages) {
          for (final chat in next.chats) {
            chat.messages.clear();
            chat.nextSequence = 1;
          }
          next.runtime.removeWhere((key, _) => key != 'background');
        }
        if (!await _persistence.save(next)) throw StateError(persistenceError!);
        applyData(next);
      }
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
    final initialized = await storage.isInitialized();
    final saved = await _persistence.load();
    if (initialized) {
      if (saved == null) throw StateError('初始化标记存在，但数据文件缺失；不会重新注入预设');
      applyData(saved);
    } else {
      final initial = await loadPresetWorkspace(
        timezone: localTimezone,
        existing: saved,
      );
      if (!await _persistence.save(initial)) {
        throw StateError(persistenceError!);
      }
      await storage.markInitialized();
      applyData(initial);
    }
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
    selected.messages.add(
      ChatMessage(
        sequence: selected.nextSequence++,
        senderName: '你',
        mentions: [
          for (final r in activeRoles)
            if (selected.members.contains(r.id) && text.contains('@${r.name}'))
              r.id,
        ],
        id: newId(),
        text: text.trim(),
        time: TimeOfDay.now().format24,
        reply: reply,
      ),
    );
    changed();
  }

  void addRole(RoleProfile profile) {
    roles.add(profile);
    conversations.add(
      Conversation(id: newId(), name: profile.name, members: [profile.id]),
    );
    changed();
  }

  void removeRole(String id) {
    role(id).archived = true;
    for (final c in conversations.where(
      (c) => !c.group && c.members.contains(id),
    )) {
      c.archived = true;
    }
    ensureSelection();
    changed();
  }

  void deleteRole(String id, {required bool keepHistory}) {
    roles.removeWhere((r) => r.id == id);
    schedules.removeWhere((s) => s.roleId == id);
    conversations.removeWhere(
      (c) => !c.group && c.members.contains(id) && !keepHistory,
    );
    for (final c in conversations) {
      c.members.remove(id);
    }
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
    conversations.insert(
      0,
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

extension on TimeOfDay {
  String get format24 =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
