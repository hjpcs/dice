// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dice/main.dart';

void main() {
  testWidgets('Dice app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DiceApp());

    // Verify that we start with '准备好投掷了吗？'.
    expect(find.text('准备好投掷了吗？'), findsOneWidget);
    
    // Tap the '开始投掷' button.
    await tester.tap(find.text('开始投掷'));
    
    // We need to pump frames to let the animation start
    await tester.pump();

    // Verify that rolling text appears
    expect(find.text('投掷中...'), findsOneWidget);
    
    // Wait for animations to complete to avoid "A Timer is still pending" error
    // The animation duration is 2 seconds, plus 300ms stagger
    await tester.pump(const Duration(seconds: 3));
    
    // After animation, button should say '开始投掷' again
    expect(find.text('开始投掷'), findsOneWidget);
  });
}
