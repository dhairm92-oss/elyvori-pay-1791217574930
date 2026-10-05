import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/realtime/backoff.dart';

void main() {
  test('backoff grows exponentially, is capped, and resets', () {
    final backoff = Backoff(
      initial: const Duration(seconds: 1),
      max: const Duration(seconds: 10),
      random: Random(1),
    );
    final first = backoff.next();
    final second = backoff.next();
    final third = backoff.next();
    expect(first.inMilliseconds, inInclusiveRange(1000, 1200));
    expect(second.inMilliseconds, inInclusiveRange(2000, 2400));
    expect(third.inMilliseconds, inInclusiveRange(4000, 4800));
    for (var i = 0; i < 10; i++) {
      expect(backoff.next().inMilliseconds, lessThanOrEqualTo(10000));
    }
    backoff.reset();
    expect(backoff.attempt, 0);
    expect(backoff.next().inMilliseconds, inInclusiveRange(1000, 1200));
  });
}
