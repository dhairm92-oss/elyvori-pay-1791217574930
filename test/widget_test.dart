import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/core/theme/app_colors.dart';

void main() {
  testWidgets('the palette renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ColoredBox(color: AppColors.obsidian)));
    expect(
      find.byWidgetPredicate((w) => w is ColoredBox && w.color == AppColors.obsidian),
      findsOneWidget,
    );
  });
}
