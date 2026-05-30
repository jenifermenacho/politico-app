// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:politico_app/main.dart';

void main() {
  testWidgets('TelaPrincipal smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: TelaPrincipal(),
    ));

    // Verify that our app bar title is present.
    expect(find.text('Ranking Parlamentar'), findsOneWidget);
  });
}
