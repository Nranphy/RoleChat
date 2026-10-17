import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolechat/core/activation/activation_models.dart';
import 'package:rolechat/core/activation/activation_scheduler.dart';
import 'package:rolechat/application/agents/activation/roleplay_activation_policy.dart';

class ImmediatePolicy extends RoleplayActivationPolicy {
  @override
  double probability(double base, int automaticCount, bool mentioned) => 1;
  @override
  Duration activationDelay(Random random) => Duration.zero;
}

class FixedRandom implements Random {
  FixedRandom([this.value = 0]);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => (value * max).floor();
  @override
  bool nextBool() => value >= .5;
}

ActivationSnapshot input({
  String agent = 'a',
  String activity = 'free',
  double p = 1,
  List<ActivationTarget>? targets,
}) => ActivationSnapshot(
  agentId: agent,
  label: agent,
  activityKey: activity,
  activityLabel: activity,
  probability: p,
  minimumInterval: const Duration(seconds: 5),
  maximumInterval: const Duration(seconds: 30),
  targets: targets ?? [const ActivationTarget(id: 'chat', latestSequence: 0)],
);

void main() {
  final now = DateTime.utc(2026, 10, 17, 12);
  test('activation strategy is replaceable without changing execution', () {
    final scheduler = ActivationScheduler(
      random: FixedRandom(.9),
      policy: ImmediatePolicy(),
    );
    expect(scheduler.evaluate(input(p: .1), now), isNotNull);
  });
  test('completing one job dispatches the next target serially', () {
    final scheduler = ActivationScheduler(
      policy: const RoleplayActivationPolicy(),
      random: FixedRandom(),
    );
    final snapshot = input(
      targets: [
        const ActivationTarget(id: 'one', latestSequence: 0),
        const ActivationTarget(id: 'two', latestSequence: 0),
      ],
    );
    expect(scheduler.evaluate(snapshot, now)!.targetId, 'one');
    expect(scheduler.evaluate(snapshot, now), isNull);
    scheduler.complete('a');
    expect(scheduler.evaluate(snapshot, now)!.targetId, 'two');
  });
  test('one active target per agent, independent agents can run together', () {
    final scheduler = ActivationScheduler(
      policy: const RoleplayActivationPolicy(),
      random: FixedRandom(),
    );
    final first = scheduler.evaluate(
      input(
        targets: [
          const ActivationTarget(id: 'one', latestSequence: 0),
          const ActivationTarget(id: 'two', latestSequence: 0),
        ],
      ),
      now,
    );
    expect(first!.targetId, 'one');
    expect(scheduler.state('a'), AgentState.activated);
    scheduler.markProcessing('a');
    expect(scheduler.state('a'), AgentState.processing);
    expect(scheduler.evaluate(input(), now), isNull);
    expect(scheduler.evaluate(input(agent: 'b'), now), isNotNull);
    scheduler.complete('a');
    expect(scheduler.state('a'), AgentState.paused);
  });
  test('pending requests merge and retain their first deadline', () {
    final scheduler = ActivationScheduler(
      policy: const RoleplayActivationPolicy(),
      random: FixedRandom(),
    );
    scheduler.activate(
      ActivationRequest(
        agentId: 'a',
        targetId: 'chat',
        dueAt: now.add(const Duration(seconds: 3)),
        reason: ActivationReason.periodic,
      ),
    );
    scheduler.activate(
      ActivationRequest(
        agentId: 'a',
        targetId: 'chat',
        dueAt: now.add(const Duration(seconds: 8)),
        reason: ActivationReason.activityChanged,
      ),
    );
    expect(scheduler.evaluate(input(), now), isNull);
    expect(
      scheduler.evaluate(input(), now.add(const Duration(seconds: 3)))!.dueAt,
      now.add(const Duration(seconds: 3)),
    );
  });
  test('zero probability cancels waiting jobs without stopping processing', () {
    final scheduler = ActivationScheduler(
      policy: const RoleplayActivationPolicy(),
      random: FixedRandom(.5),
    );
    expect(scheduler.evaluate(input(), now), isNull);
    expect(scheduler.state('a'), AgentState.activated);
    expect(
      scheduler.evaluate(input(p: 0), now.add(const Duration(seconds: 1))),
      isNull,
    );
    expect(scheduler.state('a'), AgentState.paused);
    final instant = ActivationScheduler(
      policy: const RoleplayActivationPolicy(),
      random: FixedRandom(),
    );
    instant.evaluate(input(), now);
    instant.markProcessing('a');
    instant.evaluate(input(p: 0), now.add(const Duration(seconds: 1)));
    expect(instant.state('a'), AgentState.processing);
  });
  test('activity changes never queue the currently running target again', () {
    final scheduler = ActivationScheduler(
      policy: const RoleplayActivationPolicy(),
      random: FixedRandom(),
    );
    scheduler.evaluate(input(), now);
    scheduler.markProcessing('a');
    scheduler.evaluate(
      input(activity: 'new'),
      now.add(const Duration(seconds: 1)),
    );
    scheduler.complete('a');
    expect(
      scheduler.evaluate(
        input(activity: 'new'),
        now.add(const Duration(seconds: 2)),
      ),
      isNull,
    );
  });
  test('deleted targets are pruned from pending work', () {
    final scheduler = ActivationScheduler(
      policy: const RoleplayActivationPolicy(),
      random: FixedRandom(.5),
    );
    scheduler.evaluate(input(), now);
    expect(scheduler.state('a'), AgentState.activated);
    scheduler.evaluate(input(targets: []), now.add(const Duration(seconds: 1)));
    expect(scheduler.state('a'), AgentState.paused);
  });
  test('activity changes reset automatic-message decay baseline', () {
    final scheduler = ActivationScheduler(
      policy: const RoleplayActivationPolicy(),
      random: FixedRandom(.9),
    );
    final target = ActivationTarget(
      id: 'chat',
      latestSequence: 30,
      automaticTailSequences: List.generate(30, (i) => i + 1),
    );
    expect(scheduler.evaluate(input(targets: [target]), now), isNull);
    expect(scheduler.state('a'), AgentState.paused);
    scheduler.evaluate(
      input(activity: 'next', targets: [target]),
      now.add(const Duration(seconds: 1)),
    );
    expect(scheduler.state('a'), AgentState.activated);
  });
  test(
    'intervals come from the supplied range and do not depend on messages',
    () {
      final events = <Map<String, Object?>>[];
      final scheduler = ActivationScheduler(
        policy: const RoleplayActivationPolicy(),
        random: FixedRandom(.5),
        log: (event, values) {
          if (event == '定期检查') events.add(values);
        },
      );
      scheduler.evaluate(input(p: 0), now);
      expect(
        events.single['nextCheck'],
        now.add(const Duration(milliseconds: 17500)).toIso8601String(),
      );
      scheduler.evaluate(input(p: 0), now.add(const Duration(seconds: 10)));
      expect(events, hasLength(1));
    },
  );
}
