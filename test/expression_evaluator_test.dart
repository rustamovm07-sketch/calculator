import 'package:adenalin_calculator/features/calculator/logic/expression_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final evaluator = ExpressionEvaluator();

  test('honors operator precedence and parentheses', () {
    expect(evaluator.evaluate('2+3×4').value, 14);
    expect(evaluator.evaluate('(2+3)×4').value, 20);
    expect(evaluator.evaluate('-(2+3)').value, -5);
  });

  test('supports decimals, locale commas, and postfix percentages', () {
    expect(evaluator.evaluate('1,5+2.25').value, 3.75);
    expect(evaluator.evaluate('250×10%').value, 25);
    expect(evaluator.evaluate('200+10%').value, 220);
    expect(evaluator.evaluate('200−10%').value, 180);
    expect(evaluator.evaluate('5%').value, .05);
    expect(evaluator.evaluate('1e20+2').value, 1e20 + 2);
  });

  test('reports repeated equals operator and right operand', () {
    final outcome = evaluator.evaluate('8÷2');
    expect(outcome.value, 4);
    expect(outcome.repeatedOperator, '/');
    expect(outcome.repeatedOperand, 2);

    final percent = evaluator.evaluate('200+10%');
    expect(percent.repeatedOperand, 20);
  });

  test('formats finite numbers without insignificant decimal zeroes', () {
    expect(evaluator.format(12.5, precision: 4), '12.5');
    expect(evaluator.format(-0.0), '0');
  });

  test('rejects division by zero, malformed expressions and non-finite results',
      () {
    for (final expression in [
      '4÷0',
      '1+',
      '(1+2',
      '1..2',
      '2**3',
      '1/0',
      '1e309',
      '1e20+1e308*1e308',
    ]) {
      expect(
        () => evaluator.evaluate(expression),
        throwsFormatException,
        reason: expression,
      );
    }
  });
}
