import 'package:flutter_test/flutter_test.dart';
import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/domain/models/workspace_data.dart';
import 'package:rolechat/domain/services/profile_actions.dart';
import 'package:rolechat/domain/services/conversation_messages.dart';

void main() {
  test(
    'editing a role keeps identity and private history while updating name and schedule order',
    () {
      final role = RoleProfile(id: 'role', name: '旧名字');
      final chat = Conversation(
        id: 'chat',
        name: role.name,
        members: [role.id],
        messages: [ChatMessage(id: 'm', text: '历史')],
      );
      final unchanged = ScheduleEntry(
        id: 'unchanged',
        roleId: role.id,
        activity: '上课',
        start: '09:00',
        end: '12:00',
        probability: 20,
      );
      final changed = ScheduleEntry(
        id: 'changed',
        roleId: role.id,
        activity: '逛街',
        start: '09:00',
        end: '12:00',
        probability: 80,
      );
      final data = WorkspaceData(
        apis: [],
        roles: [role],
        chats: [chat],
        schedules: [changed, unchanged],
      );
      final service = ProfileActions(data, newId: () => 'new');
      service.saveRole(
        RoleProfile(
          id: role.id,
          name: '新名字',
          memory: '新的记忆',
          defaultActivationProbability: 35,
        ),
        schedules: [
          ScheduleEntry(
            id: changed.id,
            roleId: role.id,
            activity: '聊天',
            start: '09:00',
            end: '12:00',
            probability: 100,
          ),
          unchanged,
        ],
      );
      expect(identical(data.roles.single, role), isTrue);
      expect(chat.name, '新名字');
      expect(chat.messages.single.text, '历史');
      expect(role.memory, '新的记忆');
      expect(role.defaultActivationProbability, 35);
      expect(data.schedules.map((s) => s.id), ['unchanged', 'changed']);
    },
  );
  test('API model changes update only roles using that API', () {
    final api = ApiProfile(
      id: 'api',
      name: '接口',
      url: 'https://test/v1',
      models: {'old': ModelSettings()},
    );
    final first = RoleProfile(id: 'a', name: '甲', apiId: api.id, model: 'old');
    final other = RoleProfile(id: 'b', name: '乙', apiId: 'other', model: 'old');
    final data = WorkspaceData(
      apis: [api],
      roles: [first, other],
      chats: [],
      schedules: [],
    );
    final service = ProfileActions(data, newId: () => 'new');
    service.saveApi(
      ApiProfile(
        id: api.id,
        name: '改名',
        url: api.url,
        models: {'new': ModelSettings()},
      ),
      renamed: {'old': 'new'},
    );
    expect(identical(data.apis.single, api), isTrue);
    expect(first.model, 'new');
    expect(other.model, 'old');
    service.removeApi(api.id);
    expect(first.apiId, isNull);
    expect(first.model, isEmpty);
    expect(other.apiId, 'other');
  });
  test('group edits preserve its message history and identity', () {
    final group = Conversation(
      id: 'g',
      name: '群',
      members: ['a'],
      group: true,
      messages: [ChatMessage(id: 'm', text: '历史')],
    );
    final data = WorkspaceData(
      apis: [],
      roles: [],
      chats: [group],
      schedules: [],
    );
    ProfileActions(data, newId: () => 'new').saveGroup(
      Conversation(
        id: 'g',
        name: '新群名',
        members: ['a', 'b'],
        group: true,
        background: '背景',
      ),
    );
    expect(identical(data.chats.single, group), isTrue);
    expect(group.messages.single.text, '历史');
    expect(group.members, ['a', 'b']);
    expect(group.background, '背景');
  });
  test('user and agent messages share sequence and mention rules', () {
    final role = RoleProfile(id: 'a', name: '朝雫');
    final chat = Conversation(id: 'c', name: '群', members: [role.id]);
    final now = DateTime(2026, 10, 17, 9, 5);
    final user = ConversationMessages.append(
      chat,
      id: 'u',
      text: ' @朝雫 早 ',
      now: now,
      roles: [role],
    );
    final reply = ConversationMessages.append(
      chat,
      id: 'r',
      text: '早上好',
      now: now,
      roles: [role],
      sender: role,
    );
    expect(user.sequence, 1);
    expect(reply.sequence, 2);
    expect(chat.nextSequence, 3);
    expect(user.mentions, [role.id]);
    expect(user.isUser, isTrue);
    expect(reply.roleId, role.id);
    expect(reply.time, '09:05');
  });
}
