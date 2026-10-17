import 'dart:math';
import 'activation_policy.dart';

/// Existing roleplay rules are one replaceable activation strategy.
class RoleplayActivationPolicy implements ActivationPolicy {
  const RoleplayActivationPolicy();
  @override
  double probability(double base, int automaticCount, bool mentioned) =>
      min(1.0, base * (mentioned ? 2 : 1)) *
      max(.05, pow(2, -max(0, automaticCount - 6) / 4).toDouble());

  @override
  Duration checkInterval(Duration minimum, Duration maximum, Random random) =>
      Duration(
        milliseconds:
            (minimum.inMilliseconds +
                    random.nextDouble() *
                        (maximum.inMilliseconds - minimum.inMilliseconds))
                .round(),
      );

  @override
  Duration activationDelay(Random random) =>
      Duration(milliseconds: random.nextInt(5001));

  @override
  Duration transitionDelay(double p, Random random) => Duration(
    milliseconds:
        ((5 * (1 - p) + random.nextDouble() * (5 + 50 * (1 - p))) * 1000)
            .round(),
  );
}
