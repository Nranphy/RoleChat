enum AgentState { paused, activated, processing }

enum ActivationReason { periodic, activityChanged }

class ActivationRequest {
  const ActivationRequest({
    required this.agentId,
    required this.targetId,
    required this.dueAt,
    required this.reason,
  });
  final String agentId, targetId;
  final DateTime dueAt;
  final ActivationReason reason;
}

/// The caller translates application data into these scheduler-only facts.
class ActivationTarget {
  const ActivationTarget({
    required this.id,
    required this.latestSequence,
    this.unreadCount = 0,
    this.mentioned = false,
    this.automaticTailSequences = const [],
  });
  final String id;
  final int latestSequence, unreadCount;
  final bool mentioned;
  final List<int> automaticTailSequences;
}

class ActivationSnapshot {
  const ActivationSnapshot({
    required this.agentId,
    required this.label,
    required this.activityKey,
    required this.activityLabel,
    required this.probability,
    required this.minimumInterval,
    required this.maximumInterval,
    required this.targets,
  });
  final String agentId, label, activityKey, activityLabel;
  final double probability;
  final Duration minimumInterval, maximumInterval;
  final List<ActivationTarget> targets;
}
