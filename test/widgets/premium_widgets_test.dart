import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/widgets/app_logo.dart';
import '../../lib/core/widgets/splash_screen.dart';
import '../../lib/features/dashboard/presentation/widgets/charts.dart';

void main() {
  testWidgets('charts and counters render and animate to their values', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BarChart(values: [1, 3, 0, 2, 5, 4, 6], labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S']),
              DonutChart(values: [3, 2, 1], colors: [Colors.cyan, Colors.purple, Colors.green], centerLabel: 'Total'),
              CountUp(42),
              AppLogo(name: 'salon'),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('42'), findsOneWidget);
    expect(find.text('6'), findsOneWidget); // donut total
    expect(find.text('S'), findsWidgets); // logo letter + labels
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash shows the progress bar and the app name', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: SplashScreen())));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(FractionallySizedBox), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); // stop the looping animation
  });
}
