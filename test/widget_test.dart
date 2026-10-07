import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_ai_playground/main.dart';

void main() {
  testWidgets('Home screen shows AI Chat Agent and settings',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('AI Chat Agent'), findsOneWidget);
    expect(find.text('Temp: 1.0'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Config'), findsOneWidget);
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('Precise (0.2)'), findsOneWidget);
    expect(find.text('System prompt'), findsOneWidget);
  });
}
