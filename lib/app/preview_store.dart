import '../data/workspace_remap.dart';
import '../data/preview_data.dart';
import '../data/workspace_storage.dart';
import '../data/workspace_repository.dart';
import '../data/workspace_codec.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/app_theme.dart';
import '../models/preview_models.dart';

class PreviewStore extends ChangeNotifier {
  PreviewStore(this.preferences, {WorkspaceStorage? storage})
    : _persistence = WorkspaceRepository(storage ?? MemoryWorkspaceStorage());
  final SharedPreferences preferences;
  final WorkspaceRepository _persistence;
  WorkspaceStorage get storage => _persistence.storage;
  final runtimeData = <String, dynamic>{};
  bool _disposed = false;
  Future<void> initialize() async {
    final saved = await _persistence.load();
    if (saved != null) {
      applyData(saved);
    } else {
      final mapping = <String, String>{};
      String id(String old) => mapping.putIfAbsent(old, newId);
      final files = WorkspaceCodec.encode(data);
      // Only first-run samples are instantiated, never migrated from old storage.
      final source = WorkspaceCodec.decode(files);
      for (final r in source.roles) {
        id(r.id);
      }
      for (final a in source.apis) {
        id(a.id);
      }
      for (final c in source.chats) {
        id(c.id);
      }
      applyData(remapData(source, mapping));
      if (!await saveProfiles()) throw StateError(persistenceError!);
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

  List<Conversation> get activeChats =>
      conversations.where((c) => !c.archived).toList();
  List<RoleProfile> get activeRoles => roles.where((r) => !r.archived).toList();
  void refresh() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _persistence.close();
    super.dispose();
  }

  int destination = 0;
  String selectedId = '55555555-5555-4555-8555-555555555555';
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
  String newId() => const Uuid().v4();

  void send(String text, {MessageReference? reply}) {
    if (text.trim().isEmpty) return;
    selected.messages.add(
      ChatMessage(
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
    final saved = await _persistence.save(data);
    if (!saved) refresh();
    return saved;
  }

  final apis = PreviewData.apis();
  final roles = PreviewData.roles();
  final conversations = PreviewData.conversations();
  final schedules = PreviewData.schedules();
}

extension on TimeOfDay {
  String get format24 =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
