import 'package:flutter/material.dart';

import 'calculator_engine.dart';
import 'calculator_model.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Калькулятор',
    debugShowCheckedModeBanner: false,
    restorationScopeId: 'calculator',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const CalculatorScreen(),
  );
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with RestorationMixin {
  final model = CalculatorModel();
  final input = TextEditingController();
  final saved = RestorableString('');
  @override
  String get restorationId => 'calculator_screen';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(saved, 'state');
    model.restore(saved.value);
    syncInput();
  }

  void syncInput() {
    if (input.text != model.expression) {
      input.value = TextEditingValue(
        text: model.expression,
        selection: TextSelection.collapsed(offset: model.expression.length),
      );
    }
  }

  void update(VoidCallback action) {
    setState(() {
      action();
      syncInput();
      saved.value = model.serialize();
    });
  }

  void insert(String text) {
    final selection = input.selection;
    final start = selection.isValid ? selection.start : input.text.length;
    final end = selection.isValid ? selection.end : start;
    update(() => model.edit(input.text.replaceRange(start, end, text)));
    input.selection = TextSelection.collapsed(offset: start + text.length);
  }

  void backspace() {
    final selection = input.selection;
    final end = selection.isValid ? selection.end : input.text.length;
    final start = selection.isValid ? selection.start : end;
    if (end == 0 && start == end) return;
    final from = start == end ? start - 1 : start;
    update(() => model.edit(input.text.replaceRange(from, end, '')));
    input.selection = TextSelection.collapsed(offset: from);
  }

  void toggleSign() {
    final caret = input.selection.isValid
        ? input.selection.extentOffset
        : input.text.length;
    // Меняем знак числа под курсором (либо непосредственно перед ним).
    final matches = RegExp(r'(?:\d+(?:[.,]\d*)?|[.,]\d+)(?:[eE][+-]?\d+)?')
        .allMatches(input.text);
    for (final match in matches) {
      if (match.start <= caret &&
          (caret <= match.end ||
              (caret > match.end &&
                  RegExp(r'^[)]+$')
                      .hasMatch(input.text.substring(match.end, caret))))) {
        var previous = match.start - 1;
        while (previous >= 0 && input.text[previous] == ' ') {
          previous--;
        }
        if (previous >= 0 && '-−'.contains(input.text[previous])) {
          var before = previous - 1;
          while (before >= 0 && input.text[before] == ' ') {
            before--;
          }
          if (before < 0 || '(+−-×÷*/'.contains(input.text[before])) {
            update(
              () => model.edit(
                input.text.replaceRange(previous, previous + 1, ''),
              ),
            );
            return;
          }
        }
        // Скобки предотвращают появление неоднозначного бинарного минуса.
        final number = input.text.substring(match.start, match.end);
        update(
          () => model.edit(
            input.text.replaceRange(match.start, match.end, '(-$number)'),
          ),
        );
        return;
      }
    }
    // После закрывающей скобки меняем знак всего выражения.
    if (input.text.trimRight().endsWith(')')) {
      update(() => model.edit('-(${input.text})'));
    } else {
      insert('-');
    }
  }

  @override
  void dispose() {
    input.dispose();
    saved.dispose();
    super.dispose();
  }

  Widget keyButton(String label, VoidCallback action) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        height: 46,
        child: FilledButton.tonal(
          key: ValueKey('button_$label'),
          onPressed: action,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 19)),
        ),
      ),
    ),
  );

  Widget calculator() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: input,
        key: const ValueKey('expression'),
        keyboardType: TextInputType.text,
        maxLines: 2,
        minLines: 1,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(
          labelText: 'Выражение',
          hintText: '(12 + 5) × 3',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => update(() => model.edit(value)),
        onSubmitted: (_) => update(model.calculate),
      ),
      const SizedBox(height: 8),
      Text(
        model.lastResult == null
            ? 'Результат: —'
            : 'Результат: ${formatNumber(model.lastResult!)}',
        key: const ValueKey('result'),
        style: const TextStyle(fontSize: 24),
      ),
      if (model.error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            model.error!,
            key: const ValueKey('error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      Text(
        'Память: ${formatNumber(model.memory)}',
        key: const ValueKey('memory'),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          keyButton('M+', () => update(() => model.changeMemory(1))),
          keyButton('M−', () => update(() => model.changeMemory(-1))),
          keyButton('MR', () => update(model.recallMemory)),
          keyButton(
            'MC',
            () => update(() {
              model.memory = 0;
            }),
          ),
        ],
      ),
      for (final row in [
        ['C', '(', ')', '⌫'],
        ['7', '8', '9', '÷'],
        ['4', '5', '6', '×'],
        ['1', '2', '3', '−'],
        ['±', '0', '.', '+'],
      ])
        Row(
          children: row
              .map(
                (label) => keyButton(label, () {
                  switch (label) {
                    case 'C':
                      update(model.clear);
                    case '⌫':
                      backspace();
                    case '±':
                      toggleSign();
                    default:
                      insert(label);
                  }
                }),
              )
              .toList(),
        ),
      Row(
        children: [
          keyButton('%', () => insert('%')),
          keyButton('=', () => update(model.calculate)),
        ],
      ),
    ],
  );

  Widget history() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'История (${model.history.length}/10)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (model.history.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Здесь появятся вычисления'),
        ),
      for (final entry in model.history)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(entry.expression),
          subtitle: Text('= ${formatNumber(entry.result)}'),
          trailing: const Icon(Icons.north_west, size: 18),
          onTap: () => update(() => model.recallHistory(entry)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Калькулятор')),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 650) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: calculator(),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: history(),
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [calculator(), const SizedBox(height: 20), history()],
            ),
          );
        },
      ),
    ),
  );
}
