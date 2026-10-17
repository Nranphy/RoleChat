import 'dart:math';

abstract interface class ActivationPolicy {
  double probability(double base, int automaticCount, bool mentioned);
  Duration checkInterval(Duration minimum, Duration maximum, Random random);
  Duration activationDelay(Random random);
  Duration transitionDelay(double probability, Random random);
}
