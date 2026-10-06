class CalculationOutcome {
  const CalculationOutcome({
    required this.value,
    this.repeatedOperator,
    this.repeatedOperand,
  });

  final double value;
  final String? repeatedOperator;
  final double? repeatedOperand;
}

class ExpressionEvaluator {
  CalculationOutcome evaluate(String expression) {
    if (expression.trim().isEmpty || expression.length > 256) {
      throw const FormatException('Ifoda bo‘sh yoki juda uzun.');
    }
    final tokens = _tokenize(expression);
    final parser = _Parser(tokens);
    final value = parser.parse();
    if (!value.isFinite) {
      throw const FormatException('Natija son chegarasidan tashqarida.');
    }
    final repeat = _findRepeatOperation(tokens);
    return CalculationOutcome(
      value: value,
      repeatedOperator: repeat?.$1,
      repeatedOperand: repeat?.$2,
    );
  }

  String format(double value, {int precision = 8}) {
    if (!value.isFinite) {
      throw const FormatException('Natijani ko‘rsatib bo‘lmaydi.');
    }
    if (value == 0) return '0';
    final boundedPrecision = precision.clamp(0, 12);
    final abs = value.abs();
    if (abs >= 1e15 || abs < 1e-10) {
      return value.toStringAsPrecision(10);
    }
    final fixed = value.toStringAsFixed(boundedPrecision);
    if (!fixed.contains('.')) return fixed;
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  (String, double)? _findRepeatOperation(List<String> tokens) {
    var depth = 0;
    var bestPrecedence = 99;
    var bestIndex = -1;
    for (var index = 0; index < tokens.length; index++) {
      final token = tokens[index];
      if (token == '(') {
        depth++;
        continue;
      }
      if (token == ')') {
        depth--;
        continue;
      }
      if (depth != 0 || !_isOperator(token)) continue;
      if ((token == '+' || token == '-') &&
          (index == 0 ||
              tokens[index - 1] == '(' ||
              _isOperator(tokens[index - 1]))) {
        continue;
      }
      final precedence = token == '+' || token == '-' ? 1 : 2;
      if (precedence <= bestPrecedence) {
        bestPrecedence = precedence;
        bestIndex = index;
      }
    }
    if (bestIndex < 0) return null;
    final rightTokens = tokens.sublist(bestIndex + 1);
    if (rightTokens.isEmpty) return null;
    final left = _Parser(tokens.sublist(0, bestIndex)).parseDetailed();
    final right = _Parser(rightTokens).parseDetailed();
    final operator = tokens[bestIndex];
    final operand = right.isPercent && (operator == '+' || operator == '-')
        ? left.value * right.value
        : right.value;
    return (operator, operand);
  }

  List<String> _tokenize(String expression) {
    final normalized = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(' ', '');
    final tokens = <String>[];
    var index = 0;
    while (index < normalized.length) {
      final char = normalized[index];
      if (_isDigit(char) || char == '.' || char == ',') {
        final start = index;
        var separatorCount = 0;
        while (index < normalized.length &&
            (_isDigit(normalized[index]) ||
                normalized[index] == '.' ||
                normalized[index] == ',')) {
          if (normalized[index] == '.' || normalized[index] == ',') {
            separatorCount++;
          }
          index++;
        }
        if (separatorCount > 1) {
          throw const FormatException('Son formati noto‘g‘ri.');
        }
        if (index < normalized.length &&
            (normalized[index] == 'e' || normalized[index] == 'E')) {
          index++;
          if (index < normalized.length &&
              (normalized[index] == '+' || normalized[index] == '-')) {
            index++;
          }
          final exponentStart = index;
          while (index < normalized.length && _isDigit(normalized[index])) {
            index++;
          }
          if (index == exponentStart) {
            throw const FormatException('Son darajasi noto‘g‘ri.');
          }
        }
        final number = normalized.substring(start, index).replaceAll(',', '.');
        if (number == '.') {
          throw const FormatException('Son formati noto‘g‘ri.');
        }
        final parsed = double.tryParse(number);
        if (parsed == null || !parsed.isFinite) {
          throw const FormatException('Son formati noto‘g‘ri.');
        }
        tokens.add(number);
        continue;
      }
      if ('+-*/%()'.contains(char)) {
        tokens.add(char);
        index++;
        continue;
      }
      throw const FormatException('Ifodada noma’lum belgi bor.');
    }
    return tokens;
  }

  bool _isDigit(String char) =>
      char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;

  bool _isOperator(String token) => const {'+', '-', '*', '/'}.contains(token);
}

class _Parser {
  _Parser(this.tokens);

  final List<String> tokens;
  var _index = 0;

  double parse() => parseDetailed().value;

  _ParsedValue parseDetailed() {
    if (tokens.isEmpty) {
      throw const FormatException('Hisoblash uchun ifoda yo‘q.');
    }
    final value = _expression(0);
    if (_index != tokens.length) {
      throw const FormatException('Ifoda to‘liq emas yoki noto‘g‘ri yozilgan.');
    }
    return value;
  }

  _ParsedValue _expression(int minimumPrecedence) {
    var left = _prefix();
    while (_index < tokens.length) {
      final operator = tokens[_index];
      if (operator == '%') {
        _index++;
        left = _ParsedValue(left.value / 100, true);
        continue;
      }
      final precedence = _precedence(operator);
      if (precedence < minimumPrecedence) break;
      _index++;
      final right = _expression(precedence + 1);
      final rightValue = right.isPercent && (operator == '+' || operator == '-')
          ? left.value * right.value
          : right.value;
      left = switch (operator) {
        '+' => _ParsedValue(left.value + rightValue, false),
        '-' => _ParsedValue(left.value - rightValue, false),
        '*' => _ParsedValue(left.value * right.value, false),
        '/' => _ParsedValue(_divide(left.value, right.value), false),
        _ => throw const FormatException('Operator noto‘g‘ri.'),
      };
      if (!left.value.isFinite) {
        throw const FormatException('Natija son chegarasidan tashqarida.');
      }
    }
    return left;
  }

  _ParsedValue _prefix() {
    if (_index >= tokens.length) {
      throw const FormatException('Ifoda to‘liq emas.');
    }
    final token = tokens[_index++];
    if (token == '+') return _prefix();
    if (token == '-') {
      final value = _prefix();
      return _ParsedValue(-value.value, value.isPercent);
    }
    if (token == '(') {
      final value = _expression(0);
      if (_index >= tokens.length || tokens[_index] != ')') {
        throw const FormatException('Qavs yopilmagan.');
      }
      _index++;
      return value;
    }
    if (token == ')') {
      throw const FormatException('Qavslar tartibi noto‘g‘ri.');
    }
    if (token == '%') {
      throw const FormatException('Foizdan oldin son kerak.');
    }
    final number = double.tryParse(token);
    if (number == null) throw const FormatException('Son kutilgan edi.');
    return _ParsedValue(number, false);
  }

  int _precedence(String operator) => switch (operator) {
        '+' || '-' => 1,
        '*' || '/' => 2,
        _ => -1,
      };

  double _divide(double left, double right) {
    if (right == 0) throw const FormatException('Nolga bo‘lish mumkin emas.');
    return left / right;
  }
}

class _ParsedValue {
  const _ParsedValue(this.value, this.isPercent);

  final double value;
  final bool isPercent;
}
