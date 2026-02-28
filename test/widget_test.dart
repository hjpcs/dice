// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dice/main.dart';
import 'package:dice/reward_dialog.dart';

void main() {
  testWidgets('Dice app step-by-step rolling test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DiceApp());

    // Verify that we start with '准备好投掷了吗？'.
    expect(find.text('准备好投掷了吗？'), findsOneWidget);
    
    // --- Step 1: Roll 1st Die ---
    // Tap the '开始投掷' button.
    // There might be multiple '开始投掷' texts (e.g. in BottomNavigationBar).
    // We should tap the ElevatedButton.
    await tester.tap(find.widgetWithText(ElevatedButton, '开始投掷'));
    
    // We need to pump frames to let the animation start
    await tester.pump();

    // Verify that rolling text appears
    // Note: If animation finishes too quickly or not detected, this might fail.
    // But button text changes immediately to "投掷中..." in _handleRoll.
    // Wait, _handleRoll sets _isRolling = true, which changes button text.
    expect(find.text('投掷中...'), findsOneWidget);
    
    // Wait for animation of 1st die to complete (2 seconds)
    // We need to advance time.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(); // Update UI after animation

    // Verify button text changes to '投掷第 2 个'
    // Sometimes animation might need more time or button is rebuilt.
    // Try finding by text directly if widgetWithText fails due to tree structure
    await tester.pump(const Duration(seconds: 1)); // Extra pump to ensure text update
    expect(find.text('投掷第 2 个'), findsOneWidget);

    // --- Step 2: Roll 2nd Die ---
    // Tap the '投掷第 2 个' button.
    await tester.tap(find.text('投掷第 2 个'));
    await tester.pump();
    
    expect(find.text('投掷中...'), findsOneWidget);
    
    // Wait for animation of 2nd die to complete
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // Verify button text changes to '投掷第 3 个'
    await tester.pump(const Duration(seconds: 1)); // Extra pump to ensure text update
    expect(find.text('投掷第 3 个'), findsOneWidget);

    // --- Step 3: Roll 3rd Die ---
    // Tap the '投掷第 3 个' button.
    await tester.tap(find.text('投掷第 3 个'));
    await tester.pump();
    
    expect(find.text('投掷中...'), findsOneWidget);
    
    // Wait for animation of 3rd die to complete
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    
    // The dialog appears after 500ms delay.
    // We pump for that duration.
    await tester.pump(const Duration(milliseconds: 600));
    // Since dialog uses addPostFrameCallback and ensureVisualUpdate, we need to pump again.
    await tester.pump(); 
    // And pump a few more times to ensure it's fully built without settling forever
    await tester.pump();
    await tester.pump();

    // Verify that a Dialog is shown (RewardDialog)
    // The dialog might be using a specific widget type or key.
    // Let's try to find by type `RewardDialog`
    // Since dialog might be rendered differently in test environment, let's try finding the content of dialog
    // "确定" is the button text in dialog
    // Let's pump more to be sure
    await tester.pump(const Duration(seconds: 3)); // Increased wait time
    await tester.pump();
    
    // Check if dialog exists by looking for text "中奖" (part of "中奖规则" or reward text)
    // Or just check if RewardDialog type is present
    expect(find.byType(RewardDialog), findsOneWidget);
    
    // Find the close button. It's an ElevatedButton in the dialog.
    // Try tapping by type if text is elusive
    await tester.tap(find.descendant(of: find.byType(RewardDialog), matching: find.byType(ElevatedButton)));
    
    // Instead of pumpAndSettle which might time out if there are infinite animations (like loop)
    // We pump for a specific duration enough for dialog to close
    await tester.pump(const Duration(seconds: 1)); 
    
    // After closing dialog, game resets to initial state
    expect(find.widgetWithText(ElevatedButton, '开始投掷'), findsOneWidget);
  });
}
