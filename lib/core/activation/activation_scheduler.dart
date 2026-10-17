import 'dart:math';
import 'package:rolechat/core/activation/activation_models.dart';
import 'package:rolechat/core/activation/activation_policy.dart';
import 'package:rolechat/core/diagnostics/runtime_events.dart';

class _AgentClock {
  DateTime nextCheck = DateTime.fromMillisecondsSinceEpoch(0);
  String? activity;
  final pending = <String, ActivationRequest>{};
  final baselines = <String, int>{};
  String? activeTarget;
  bool processing = false;
}

/// A pure scheduler: no widgets, API clients, file access or chat models.
/// One active job per agent; independent agents can be dispatched concurrently.
class ActivationScheduler {
  ActivationScheduler({
    Random? random,
    this.log = silentRuntimeLog,
    required this.policy,
  }) : random = random ?? Random();
  final Random random;
  final RuntimeLog log;
  final ActivationPolicy policy;
  final _clocks = <String, _AgentClock>{};

  AgentState state(String id) {
    final clock = _clocks[id];
    return clock?.processing == true
        ? AgentState.processing
        : clock?.activeTarget != null || clock?.pending.isNotEmpty == true
        ? AgentState.activated
        : AgentState.paused;
  }

  /// Explicit requests share the same queue regardless of activation source.
  void activate(ActivationRequest request) {
    final clock = _clocks.putIfAbsent(request.agentId, _AgentClock.new);
    if (clock.activeTarget == request.targetId) return;
    clock.pending.putIfAbsent(request.targetId, () => request);
  }

  void markProcessing(String id) {
    final clock = _clocks[id];
    if (clock?.activeTarget != null) clock!.processing = true;
  }

  void complete(String id) {
    final clock = _clocks[id];
    if (clock == null) return;
    clock.activeTarget = null;
    clock.processing = false;
  }

  void reset() {
    for (final clock in _clocks.values) {
      clock.pending.clear();
      clock.baselines.clear();
      clock.activity = null;
      clock.nextCheck = DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  void retainAgents(Set<String> ids) => _clocks.removeWhere(
    (id, c) => !ids.contains(id) && c.activeTarget == null,
  );

  ActivationRequest? evaluate(ActivationSnapshot snapshot, DateTime now) {
    final clock = _clocks.putIfAbsent(snapshot.agentId, _AgentClock.new);
    final targetIds = snapshot.targets.map((t) => t.id).toSet();
    clock.pending.removeWhere((id, _) => !targetIds.contains(id));
    clock.baselines.removeWhere((id, _) => !targetIds.contains(id));
    final transition =
        clock.activity != null && clock.activity != snapshot.activityKey;
    clock.activity = snapshot.activityKey;
    if (snapshot.probability == 0) clock.pending.clear();
    if (transition) {
      log('行程切换', {
        'role': snapshot.label,
        'activity': snapshot.activityLabel,
        'baseProbability': snapshot.probability,
      });
      for (final target in snapshot.targets) {
        clock.baselines[target.id] = target.latestSequence;
        if (snapshot.probability > 0) {
          activate(
            ActivationRequest(
              agentId: snapshot.agentId,
              targetId: target.id,
              dueAt: now.add(
                policy.transitionDelay(snapshot.probability, random),
              ),
              reason: ActivationReason.activityChanged,
            ),
          );
        }
      }
    }
    if (!now.isBefore(clock.nextCheck)) {
      clock.nextCheck = now.add(
        policy.checkInterval(
          snapshot.minimumInterval,
          snapshot.maximumInterval,
          random,
        ),
      );
      log('定期检查', {
        'role': snapshot.label,
        'roleId': snapshot.agentId,
        'activity': snapshot.activityLabel,
        'baseProbability': snapshot.probability,
        'nextCheck': clock.nextCheck.toIso8601String(),
        'state': state(snapshot.agentId).name,
        'chatCount': snapshot.targets.length,
      });
      if (snapshot.probability > 0) {
        for (final target in snapshot.targets) {
          if (clock.activeTarget == target.id) continue;
          final count = target.automaticTailSequences
              .where((s) => s > (clock.baselines[target.id] ?? 0))
              .length;
          final p = policy.probability(
            snapshot.probability,
            count,
            target.mentioned,
          );
          final roll = random.nextDouble();
          log('概率判定', {
            'role': snapshot.label,
            'chatId': target.id,
            'unreadCount': target.unreadCount,
            'mentioned': target.mentioned,
            'consecutiveAiMessages': count,
            'effectiveProbability': p,
            'random': roll,
            'passed': roll < p,
          });
          if (roll < p) {
            activate(
              ActivationRequest(
                agentId: snapshot.agentId,
                targetId: target.id,
                dueAt: now.add(policy.activationDelay(random)),
                reason: ActivationReason.periodic,
              ),
            );
            log('激活等待', {
              'role': snapshot.label,
              'chatId': target.id,
              'due': clock.pending[target.id]?.dueAt.toIso8601String(),
            });
          }
        }
      }
    }
    if (clock.activeTarget != null) return null;
    final due =
        clock.pending.values.where((r) => !now.isBefore(r.dueAt)).toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    if (due.isEmpty) return null;
    final request = due.first;
    clock.pending.remove(request.targetId);
    clock.activeTarget = request.targetId;
    return request;
  }
}
