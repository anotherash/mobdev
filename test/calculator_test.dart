import 'package:flutter_test/flutter_test.dart';
import 'package:advanced_calculator/calculator_engine.dart';
import 'package:advanced_calculator/calculator_model.dart';

void main() {
  final engine = CalculatorEngine();
  final examples = <String, double>{
    '12 + 5 × 3': 27,
    '(12 + 5) × 3': 51,
    '20 ÷ 4 + 7': 12,
    '15.5 × 2': 31,
    '10-3-2': 5,
    '24/4/2': 3,
    '-2*3': -6,
    '2*(-3)': -6,
    '.5 + 0,25': .75,
    '50%': .5,
    '200×10%': 20,
    '200+10%': 200.1,
    '(10+10)%': .2,
    '((1+2)*4)/2': 6,
    '1e-5 * 100000': 1,
  };
  for (final entry in examples.entries) {
    test(
      entry.key,
      () => expect(engine.evaluate(entry.key), closeTo(entry.value, 1e-10)),
    );
  }
  for (final expression in [
    '',
    ' ',
    '1/0',
    '1/(2-2)',
    '(1+2',
    '1+2)',
    '()',
    '2++3',
    '2×-3',
    '2--3',
    '2+-3',
    '2×÷3',
    '2**3',
    '--3',
    '1.2.3',
    '1+',
    '1-',
    '.',
    'abc',
    '2(3)',
    '1 2',
    '5%%',
    '1e',
    '1e999',
    '9' * 1001,
    '${'(' * 65}1${')' * 65}',
  ]) {
    test(
      'Reject $expression',
      () => expect(
        () => engine.evaluate(expression),
        throwsA(isA<CalculationException>()),
      ),
    );
  }
  test('Formatting and reusing results', () {
    for (final value in [0.0, 10.0, 100.0, 1e20, 1e-20, -1e20, 15.5]) {
      expect(engine.evaluate(formatNumber(value)), value);
    }
    expect(formatNumber(.1 + .2), '0.3');
    expect(formatNumber(1.23456789123e100), '1.23456789123e+100');
  });
  test('History limit, memory and full state round trip', () {
    final model = CalculatorModel();
    for (var i = 0; i < 12; i++) {
      model.edit('$i+1');
      model.calculate();
    }
    expect(model.history.length, 10);
    expect(model.history.first.result, 12);
    expect(model.history.last.result, 3);
    model.changeMemory(1);
    expect(model.memory, 12);
    model.edit('2');
    model.changeMemory(-1);
    expect(model.memory, 10);
    model.edit('1/0');
    model.calculate();
    final restored = CalculatorModel()..restore(model.serialize());
    expect(restored.serialize(), model.serialize());
    expect(restored.lastResult, 12);
    expect(restored.error, 'Деление на ноль');
    restored.recallMemory();
    expect(restored.expression, '10');
    restored.recallHistory(restored.history.first);
    expect(restored.expression, '11+1');
    restored.clear();
    expect(restored.history.length, 10);
    expect(restored.memory, 10);
  });
}
