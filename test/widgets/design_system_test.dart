import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/widgets/glass_container.dart';
import '../../lib/core/widgets/neon_button.dart';
import '../../lib/core/widgets/pulse_ring.dart';

void main() {
  testWidgets('GlassContainer renders its child and handles taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassContainer(onTap: () => taps++, child: const Text('Glass')),
        ),
      ),
    );
    expect(find.text('Glass'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    await tester.tap(find.text('Glass'));
    expect(taps, 1);
  });

  testWidgets('NeonButton shows a spinner while loading and ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NeonButton(label: 'Go', loading: true, onPressed: () => taps++)),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(NeonButton));
    expect(taps, 0);
  });

  testWidgets('PulseRing and NeonGauge paint without errors', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(children: [PulseRing(color: Colors.cyan), NeonGauge(value: 0.7)]),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 950));
    expect(find.text('70%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
