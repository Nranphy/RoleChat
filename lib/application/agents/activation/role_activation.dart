import 'package:rolechat/domain/models/models.dart';
import 'package:rolechat/application/agents/ports/agent_workspace.dart';
import 'package:rolechat/core/activation/activation_models.dart';
import 'package:rolechat/domain/services/schedule_policy.dart';

/// Translates chat-specific facts into independent activation inputs.
abstract final class RoleActivation {
  static ActivationSnapshot snapshot(
    AgentWorkspace workspace,
    RoleProfile role,
    DateTime now,
  ) {
    final activity = SchedulePolicy.match(role, workspace.schedules, now);
    return ActivationSnapshot(
      agentId: role.id,
      label: role.name,
      activityKey: activity.key,
      activityLabel: activity.name,
      probability: activity.probability,
      minimumInterval: Duration(seconds: role.checkMin),
      maximumInterval: Duration(seconds: role.checkMax),
      targets: [
        for (final chat in workspace.activeChats.where(
          (c) => c.members.contains(role.id),
        ))
          _target(workspace, role, chat),
      ],
    );
  }

  static ActivationTarget _target(
    AgentWorkspace workspace,
    RoleProfile role,
    Conversation chat,
  ) {
    final cursor =
        (workspace.runtimeData['view:${role.id}:${chat.id}'] as int?) ?? 0;
    final unread = chat.messages.where(
      (m) => m.sequence > cursor && m.roleId != role.id,
    );
    return ActivationTarget(
      id: chat.id,
      latestSequence: chat.nextSequence - 1,
      unreadCount: unread.length,
      mentioned: unread.any((m) => m.mentions.contains(role.id)),
      automaticTailSequences: chat.messages.reversed
          .takeWhile((m) => !m.isUser)
          .map((m) => m.sequence)
          .toList(),
    );
  }
}
