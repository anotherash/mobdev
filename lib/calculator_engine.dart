/// Независимый от Flutter вычислитель с рекурсивным спуском.
/// expression → term ((+ | -) term)*
/// term → unary ((* | /) unary)*; unary → [-] primary [%]
class CalculationException implements Exception {
  final String message;
  const CalculationException(this.message);
  @override
  String toString() => message;
}

String formatNumber(double value) {
  if (value == 0) return '0';
  final parts = value.toStringAsPrecision(12).split('e');
  if (parts[0].contains('.')) {
    parts[0] = parts[0]
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return parts.join('e');
}

class CalculatorEngine {
  double evaluate(String expression) => _Parser(expression).parse();
}

class _Parser {
  final String source;
  int position = 0;
  int depth = 0;
  _Parser(String input)
    : source = input
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-')
          .replaceAll(',', '.');

  Never fail(String message) => throw CalculationException(message);
  void skipSpaces() {
    while (position < source.length && source[position].trim().isEmpty) {
      position++;
    }
  }

  bool take(String character) {
    skipSpaces();
    if (position < source.length && source[position] == character) {
      position++;
      return true;
    }
    return false;
  }

  bool takeOperator(String character) {
    if (!take(character)) return false;
    skipSpaces();
    if (position < source.length && '+-*/'.contains(source[position])) {
      fail('Два арифметических оператора подряд');
    }
    return true;
  }

  double checked(double value) {
    if (!value.isFinite) fail('Результат слишком большой');
    return value;
  }

  double parse() {
    if (source.trim().isEmpty) fail('Введите выражение');
    if (source.length > 1000) fail('Выражение слишком длинное');
    final result = expression();
    skipSpaces();
    if (position != source.length) {
      if (source[position] == '(' || source[position] == ')') {
        fail('Проверьте скобки и знаки между ними');
      }
      fail('Недопустимый символ или пропущен оператор');
    }
    return checked(result);
  }

  double expression() {
    var value = term();
    while (true) {
      if (takeOperator('+')) {
        value = checked(value + term());
      } else if (takeOperator('-')) {
        value = checked(value - term());
      } else {
        return value;
      }
    }
  }

  double term() {
    var value = unary();
    while (true) {
      if (takeOperator('*')) {
        value = checked(value * unary());
      } else if (takeOperator('/')) {
        final divisor = unary();
        if (divisor == 0) fail('Деление на ноль');
        value = checked(value / divisor);
      } else {
        return value;
      }
    }
  }

  double unary() {
    final negative = take('-');
    var value = primary();
    if (take('%')) value /= 100;
    return negative ? -value : value;
  }

  double primary() {
    skipSpaces();
    if (position == source.length) {
      fail('Выражение не завершено: ожидается число');
    }
    if (take('(')) {
      if (++depth > 64) fail('Слишком много вложенных скобок');
      final value = expression();
      if (!take(')')) fail('Не хватает закрывающей скобки');
      depth--;
      return value;
    }
    final c = source[position];
    if (c == ')') fail('Лишняя скобка или пустые скобки');
    if ('+-*/'.contains(c)) fail('Два оператора подряд или отсутствует число');
    final start = position;
    int dots = 0;
    int digits = 0;
    while (position < source.length) {
      final c = source[position];
      if (c == '.') {
        dots++;
      } else if (RegExp(r'[0-9]').hasMatch(c)) {
        digits++;
      } else {
        break;
      }
      position++;
    }
    if (dots > 1) fail('В числе несколько десятичных точек');
    if (digits == 0) fail('Ожидается число');
    // Научная запись нужна для повторного ввода больших/малых результатов.
    if (position < source.length && source[position].toLowerCase() == 'e') {
      position++;
      if (position < source.length && '+-'.contains(source[position])) {
        position++;
      }
      final exponentStart = position;
      while (position < source.length &&
          RegExp(r'[0-9]').hasMatch(source[position])) {
        position++;
      }
      if (position == exponentStart) fail('Некорректная степень числа');
    }
    final value = double.tryParse(source.substring(start, position));
    if (value == null) fail('Некорректное число');
    return checked(value);
  }
}
