import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_calculator/main.dart';

void main() {
  testWidgets('Buttons, history, memory, errors, rotation and restoration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CalculatorApp());
    Future<void> tap(String label) async {
      final finder = find.byKey(ValueKey('button_$label'));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> enter(String text) async {
      await tester.enterText(find.byKey(const ValueKey('expression')), text);
      await tester.pump();
    }

    await enter('(12 + 5) × 3');
    await tap('=');
    expect(find.text('Результат: 51'), findsOneWidget);
    await tap('M+');
    expect(find.text('Память: 51'), findsOneWidget);
    await tap('C');
    final entry = find.widgetWithText(ListTile, '(12 + 5) × 3');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '(12 + 5) × 3',
    );
    await tap('=');
    await enter('1÷0');
    await tap('=');
    expect(find.text('Деление на ноль'), findsOneWidget);
    tester.view.physicalSize = const Size(1920, 1080);
    await tester.pumpAndSettle();
    expect(find.text('Деление на ноль'), findsOneWidget);
    expect(find.text('Результат: 51'), findsOneWidget);
    expect(find.text('Память: 51'), findsOneWidget);
    expect(find.text('История (2/10)'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '1÷0',
    );
    await tester.restartAndRestore();
    expect(find.text('Деление на ноль'), findsOneWidget);
    expect(find.text('Результат: 51'), findsOneWidget);
    expect(find.text('Память: 51'), findsOneWidget);
    expect(find.text('История (2/10)'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '1÷0',
    );
    expect(tester.takeException(), isNull);
    await tap('MR');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '51',
    );
    await tap('M−');
    expect(find.text('Память: 0'), findsOneWidget);
    await enter('12+5');
    await tap('±');
    await tap('=');
    expect(find.text('Результат: 7'), findsOneWidget);
    await tap('±');
    await tap('=');
    expect(find.text('Результат: 17'), findsOneWidget);
    await tap('⌫');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '12+(5',
    );
    await tap('MC');
    await tap('C');
    await tap('=');
    expect(find.text('Введите выражение'), findsOneWidget);
  });
}
