import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../widgets/app_components.dart';
import '../logic/expression_evaluator.dart';

class EverydayCalculatorPage extends StatefulWidget {
  const EverydayCalculatorPage({super.key});

  @override
  State<EverydayCalculatorPage> createState() => _EverydayCalculatorPageState();
}

class _EverydayCalculatorPageState extends State<EverydayCalculatorPage> {
  final _engine = ExpressionEvaluator();
  String _expression = '';
  double? _answer;
  String? _error;
  String? _repeatOperator;
  double? _repeatOperand;
  bool _justEvaluated = false;

  static const _keys = <String>[
    'AC',
    '()',
    '%',
    '÷',
    '7',
    '8',
    '9',
    '×',
    '4',
    '5',
    '6',
    '−',
    '1',
    '2',
    '3',
    '+',
    '±',
    '0',
    '.',
    '⌫',
  ];

  String get _formattedAnswer {
    final answer = _answer;
    if (answer == null) return '';
    return _engine.format(
      answer,
      precision: AppScope.of(context).calculatorPrecision,
    );
  }

  double? _preview() {
    if (_expression.isEmpty) return null;
    try {
      return _engine.evaluate(_expression).value;
    } on FormatException {
      return null;
    }
  }

  Future<void> _tap(String key) async {
    final state = AppScope.of(context);
    if (state.hapticFeedback) await HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() {
      _error = null;
      if (key == 'AC') {
        _clear();
      } else if (key == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
        _resetResult();
      } else if (key == '=') {
        _equals();
      } else if (key == '()') {
        _insertParenthesis();
      } else if (key == '±') {
        _toggleSign();
      } else if (key == '%') {
        if (_endsWithValue(_expression)) {
          _expression += '%';
          _resetResult();
        }
      } else if (_isOperator(key)) {
        _insertOperator(key);
      } else {
        _insertDigit(key);
      }
    });
    if (key == '=' && _error == null && _answer != null) {
      await state.addCalculatorHistory(_expression, _formattedAnswer);
    }
  }

  void _clear() {
    _expression = '';
    _answer = null;
    _error = null;
    _repeatOperator = null;
    _repeatOperand = null;
    _justEvaluated = false;
  }

  void _resetResult() {
    _answer = null;
    _repeatOperator = null;
    _repeatOperand = null;
    _justEvaluated = false;
  }

  void _insertDigit(String value) {
    if (_justEvaluated) _expression = '';
    _justEvaluated = false;
    if (_expression.endsWith(')') || _expression.endsWith('%')) {
      _expression += '×';
    }
    if (value == '.') {
      final lastNumber = RegExp(r'[\d.,]+$').firstMatch(_expression)?.group(0);
      if (lastNumber?.contains('.') == true ||
          lastNumber?.contains(',') == true) {
        return;
      }
      if (lastNumber == null) _expression += '0';
    }
    if (_expression.length < 256) _expression += value;
  }

  void _insertOperator(String value) {
    if (_justEvaluated && _answer != null) {
      _expression = _formattedAnswer;
      _justEvaluated = false;
      _repeatOperator = null;
      _repeatOperand = null;
    }
    if (_expression.isEmpty) {
      if (value == '−') _expression = '−';
      return;
    }
    if (_expression.endsWith('(')) {
      if (value == '−') _expression += value;
      return;
    }
    if (_isOperator(_expression.substring(_expression.length - 1))) {
      _expression = _expression.substring(0, _expression.length - 1) + value;
    } else if (_endsWithValue(_expression)) {
      _expression += value;
    }
    _resetResult();
  }

  void _insertParenthesis() {
    if (_justEvaluated) _expression = '';
    final opens = '('.allMatches(_expression).length;
    final closes = ')'.allMatches(_expression).length;
    final canClose = opens > closes && _endsWithValue(_expression);
    if (canClose) {
      _expression += ')';
    } else {
      if (_endsWithValue(_expression)) _expression += '×';
      _expression += '(';
    }
    _resetResult();
  }

  void _toggleSign() {
    if (_expression.isEmpty) {
      _expression = '−';
    } else if (_justEvaluated && _answer != null) {
      _answer = -_answer!;
    } else {
      _expression = _expression.startsWith('−(') && _expression.endsWith(')')
          ? _expression.substring(2, _expression.length - 1)
          : '−($_expression)';
    }
    _repeatOperator = null;
    _repeatOperand = null;
    _justEvaluated = _answer != null;
  }

  void _equals() {
    if (_justEvaluated && _answer != null) {
      final operator = _repeatOperator;
      final operand = _repeatOperand;
      if (operator == null || operand == null) return;
      final expression = '${_engine.format(_answer!)}$operator'
          '${_engine.format(operand)}';
      try {
        _answer = _engine.evaluate(expression).value;
        _expression = expression;
      } on FormatException catch (error) {
        _error = error.message;
        return;
      }
      return;
    }
    try {
      final outcome = _engine.evaluate(_expression);
      _answer = outcome.value;
      _repeatOperator = outcome.repeatedOperator;
      _repeatOperand = outcome.repeatedOperand;
      _justEvaluated = true;
    } on FormatException catch (error) {
      _error = error.message;
      _answer = null;
    }
  }

  bool _endsWithValue(String expression) =>
      expression.isNotEmpty &&
      (RegExp(r'[\d.,]$').hasMatch(expression) ||
          expression.endsWith(')') ||
          expression.endsWith('%'));

  bool _isOperator(String value) =>
      const {'+', '−', '-', '×', '*', '÷', '/'}.contains(value);

  Future<void> _showHistory() async {
    final state = AppScope.of(context);
    final history = List<Map<String, Object?>>.of(state.calculatorHistory);
    if (history.isEmpty) {
      showMessage(context, 'Hisoblar tarixi hozircha bo‘sh.');
      return;
    }
    final selected = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hisoblar tarixi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Yopish'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return ListTile(
                      title: Text('${entry['result'] ?? ''}'),
                      subtitle: Text('${entry['expression'] ?? ''}'),
                      trailing: const Icon(Icons.north_west),
                      onTap: () => Navigator.pop(context, entry),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _expression = '${selected['result'] ?? ''}';
      _answer = double.tryParse(_expression);
      _error = null;
      _repeatOperator = null;
      _repeatOperand = null;
      _justEvaluated = _answer != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final preview = _preview();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oddiy kalkulyator'),
        actions: [
          IconButton(
            tooltip: 'Hisoblar tarixi',
            onPressed: _showHistory,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            final landscape = wide && constraints.maxHeight < 440;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: landscape ? 900 : 560),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 24 : 16,
                    vertical: landscape ? 8 : 12,
                  ),
                  child: landscape
                      ? Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: _display(
                                preview,
                                state.calculatorPrecision,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _keypad(landscape: true),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: _equalsButton(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: (constraints.maxHeight * .32)
                                    .clamp(180, 240)
                                    .toDouble(),
                                child: _display(
                                  preview,
                                  state.calculatorPrecision,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _keypad(landscape: false, shrinkWrap: true),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: _equalsButton(),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _keypad({
    required bool landscape,
    bool shrinkWrap = false,
  }) =>
      GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        itemCount: _keys.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: landscape ? 5 : 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          mainAxisExtent: landscape ? 48 : 52,
        ),
        itemBuilder: (context, index) => _keyButton(_keys[index]),
      );

  Widget _equalsButton() => FilledButton(
        onPressed: () => _tap('='),
        child: const Text(
          '=',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
      );

  Widget _display(double? preview, int precision) {
    final scheme = Theme.of(context).colorScheme;
    final displayed = _justEvaluated && _answer != null
        ? _engine.format(_answer!, precision: precision)
        : preview == null
            ? ''
            : _engine.format(preview, precision: precision);
    return GlassSurface(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ifoda',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tozalash',
                    onPressed: () => _tap('AC'),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const Spacer(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Semantics(
                  label: 'Kiritilgan ifoda $_expression',
                  child: Text(
                    _expression.isEmpty ? '0' : _expression,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _error ?? displayed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _error == null ? scheme.primary : scheme.error,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _keyButton(String key) {
    final scheme = Theme.of(context).colorScheme;
    final operator = _isOperator(key) || key == '%' || key == '()';
    final destructive = key == 'AC' || key == '⌫';
    return Semantics(
      button: true,
      label: switch (key) {
        'AC' => 'Hammasini tozalash',
        '⌫' => 'Oxirgi belgini o‘chirish',
        '()' => 'Qavs',
        '±' => 'Ishorani almashtirish',
        '×' => 'Ko‘paytirish',
        '÷' => 'Bo‘lish',
        '−' => 'Ayirish',
        '%' => 'Foiz',
        _ => key,
      },
      child: Material(
        color: destructive
            ? scheme.errorContainer
            : operator
                ? scheme.secondaryContainer
                : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _tap(key),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: destructive
                    ? scheme.onErrorContainer
                    : operator
                        ? scheme.onSecondaryContainer
                        : scheme.onSurface,
              ),
              child: key == '⌫'
                  ? const Icon(Icons.backspace_outlined)
                  : Text(
                      key,
                      style: TextStyle(
                        color: destructive
                            ? scheme.onErrorContainer
                            : operator
                                ? scheme.onSecondaryContainer
                                : scheme.onSurface,
                        fontSize: key.length > 2 ? 16 : 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
