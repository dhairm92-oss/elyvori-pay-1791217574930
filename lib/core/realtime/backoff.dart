import 'dart:math';

/// Exponential backoff with jitter: 1s, 2s, 4s ... capped at [max].
class Backoff {
  Backoff({
    this.initial = const Duration(seconds: 1),
    this.max = const Duration(seconds: 30),
    Random? random,
  }) : _random = random ?? Random();

  final Duration initial;
  final Duration max;
  final Random _random;
  int _attempt = 0;

  int get attempt => _attempt;

  Duration next() {
    final base = initial.inMilliseconds * pow(2, _attempt).toInt();
    _attempt = min(_attempt + 1, 16);
    final capped = min(base, max.inMilliseconds);
    final jitter = (capped * 0.2 * _random.nextDouble()).round();
    return Duration(milliseconds: min(capped + jitter, max.inMilliseconds));
  }

  void reset() => _attempt = 0;
}
