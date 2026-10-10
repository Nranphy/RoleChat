import '../data/preview_data.dart';
import '../data/profile_persistence.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/app_theme.dart';
import '../models/preview_models.dart';

class PreviewStore extends ChangeNotifier {
  PreviewStore(this.preferences)
    : _persistence = ProfilePersistence(preferences) {
    restoreProfiles();
  }
  final SharedPreferences preferences;
  final ProfilePersistence _persistence;
  int destination = 0;
  String selectedId = 'garden';
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
    notifyListeners();
  }

  Future<void> setSeed(Color value) async {
    await preferences.setInt('seed', value.toARGB32());
    notifyListeners();
  }

  void changed() {
    notifyListeners();
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
  int _lastId = 0;
  String newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastId = now > _lastId ? now : _lastId + 1;
    return _lastId.toString();
  }

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
    notifyListeners();
  }

  void addRole(RoleProfile profile) {
    roles.add(profile);
    conversations.add(
      Conversation(
        id: 'private-${profile.id}',
        name: profile.name,

        members: [profile.id],
      ),
    );
    changed();
  }

  void removeRole(String id) {
    roles.removeWhere((r) => r.id == id);
    schedules.removeWhere((s) => s.roleId == id);
    for (final c in conversations) {
      c.members.remove(id);
    }
    changed();
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

  String? get persistenceError => _persistence.persistenceError;
  String? avatarFor(Conversation c) => c.group
      ? c.avatar
      : roles.where((r) => c.members.contains(r.id)).firstOrNull?.avatar;
  Future<bool> saveProfiles() async {
    final saved = await _persistence.save(
      roles: roles,
      schedules: schedules,
      conversations: conversations,
    );
    if (!saved) notifyListeners();
    return saved;
  }

  void restoreProfiles() {
    _persistence.restore(
      apis: apis,
      roles: roles,
      schedules: schedules,
      conversations: conversations,
    );
    if (!conversations.any((c) => c.id == selectedId)) {
      selectedId = conversations.first.id;
    }
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
