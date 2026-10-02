import 'dart:convert';

import 'calculator_engine.dart';

class HistoryEntry {
  final String expression;
  final double result;
  const HistoryEntry(this.expression, this.result);
  Map<String, dynamic> toJson() => {'expression': expression, 'result': result};
}

/// Всё пользовательское состояние хранится отдельно от виджетов.
class CalculatorModel {
  final engine = CalculatorEngine();
  String expression = '';
  double memory = 0;
  double? lastResult;
  String? error;
  List<HistoryEntry> history = [];

  void edit(String value) {
    expression = value;
    error = null;
  }

  void clear() {
    expression = '';
    lastResult = null;
    error = null;
  }

  void calculate() {
    try {
      final result = engine.evaluate(expression);
      lastResult = result;
      error = null;
      history.insert(0, HistoryEntry(expression, result));
      if (history.length > 10) history.removeLast();
    } on CalculationException catch (e) {
      error = e.message;
    }
  }

  void changeMemory(int sign) {
    try {
      final value = engine.evaluate(expression);
      final updated = memory + sign * value;
      if (!updated.isFinite) {
        throw const CalculationException('Значение памяти слишком большое');
      }
      memory = updated;
      error = null;
    } on CalculationException catch (e) {
      error = e.message;
    }
  }

  void recallMemory() => edit(formatNumber(memory));
  void recallHistory(HistoryEntry entry) => edit(entry.expression);

  String serialize() => jsonEncode({
    'expression': expression,
    'memory': memory,
    'lastResult': lastResult,
    'error': error,
    'history': history.map((e) => e.toJson()).toList(),
  });
  void restore(String data) {
    if (data.isEmpty) return;
    final map = jsonDecode(data) as Map<String, dynamic>;
    expression = map['expression'] as String;
    memory = (map['memory'] as num).toDouble();
    lastResult = (map['lastResult'] as num?)?.toDouble();
    error = map['error'] as String?;
    history = (map['history'] as List)
        .map(
          (e) => HistoryEntry(
            e['expression'] as String,
            (e['result'] as num).toDouble(),
          ),
        )
        .take(10)
        .toList();
  }
}
