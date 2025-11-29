// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tennis_app/main.dart';

void main() {
  testWidgets('Login Screen UI Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that Login Screen elements are present
    expect(find.text('무안 테니스 클럽'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);

    // Verify TextFields are present
    expect(find.byType(TextFormField), findsNWidgets(2)); // Phone and PIN

    // Tap to switch to Register
    await tester.tap(find.text('신규 회원이신가요? 회원가입하기'));
    await tester.pump();

    // Verify Register UI
    expect(find.text('회원가입'), findsOneWidget);
    expect(
      find.byType(TextFormField),
      findsNWidgets(4),
    ); // Name, Birth, Phone, PIN
  });
}
