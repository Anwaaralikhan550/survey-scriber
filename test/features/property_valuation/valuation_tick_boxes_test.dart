// Client 17 Nov 2026: Valuation uses on-screen tick boxes like Inspection, not pop-up lists.
// Single choice fields show every option as a radio-style tick; keys and stored values are unchanged.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/presentation/widgets/inspection_fields.dart';

const _field = InspectionFieldDefinition(
  id: 'actv_x',
  label: 'Condition',
  type: InspectionFieldType.dropdown,
  options: ['Good', 'Reasonable', 'Poor'],
  optionLabels: {'Good': 'Very good'},
);

/// Keeps the answer like the screen does, so a tap changes what is shown.
class _Host extends StatefulWidget {
  const _Host({super.key, required this.field, this.start = '', this.inline = true, required this.log});
  final InspectionFieldDefinition field;
  final String start;
  final bool inline;
  final List<String> log;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.start;
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InspectionFieldInput(
              field: widget.field,
              value: value,
              inlineChoices: widget.inline,
              onChanged: (v) {
                widget.log.add(v);
                setState(() => value = v);
              },
            ),
          ),
        ),
      );
}

void main() {
  group('A1 one choice at a time, on screen', () {
    testWidgets('every option is visible without opening anything', (tester) async {
      await tester.pumpWidget(_Host(field: _field, log: []));
      expect(find.byType(InputDecorator), findsNothing);
      expect(find.text('Condition'), findsOneWidget);
      expect(find.text('Very good'), findsOneWidget);
      expect(find.text('Reasonable'), findsOneWidget);
      expect(find.text('Poor'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(3));
    });

    testWidgets('tapping stores the original option text, not the admin words', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(_Host(field: _field, log: log));
      await tester.tap(find.text('Very good'));
      await tester.pump();
      expect(log, ['Good']);
    });

    testWidgets('only one tick at a time: choosing another moves the tick', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(_Host(field: _field, log: log));
      await tester.tap(find.text('Reasonable'));
      await tester.pump();
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
      await tester.tap(find.text('Poor'));
      await tester.pump();
      expect(log, ['Reasonable', 'Poor']);
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(2));
    });

    testWidgets('tapping the ticked option again clears the answer', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(_Host(field: _field, start: 'Poor', log: log));
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
      await tester.tap(find.text('Poor'));
      await tester.pump();
      expect(log, ['']);
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsNothing);
    });

    testWidgets('an old answer that is no longer in the list still shows ticked', (tester) async {
      await tester.pumpWidget(_Host(field: _field, start: 'Satisfactory', log: []));
      expect(find.text('Satisfactory'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    });

    testWidgets('Inspection screens are unchanged: they still use the pop-up list', (tester) async {
      await tester.pumpWidget(_Host(field: _field, inline: false, log: []));
      expect(find.byType(InputDecorator), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNothing);
    });
  });

  group('A1 every Valuation dropdown in the real tree', () {
    final tree = jsonDecode(File('assets/property_valuation/valuation_tree.json').readAsStringSync())
        as Map<String, dynamic>;
    final fields = <InspectionFieldDefinition>[
      for (final s in tree['sections'] as List)
        for (final n in (s as Map)['nodes'] as List)
          for (final f in ((n as Map)['fields'] as List? ?? const []))
            if ((f as Map)['type'] == 'dropdown')
              InspectionFieldDefinition.fromJson(f.cast<String, dynamic>()),
    ];

    test('the tree has dropdown fields to convert', () {
      expect(fields.length, greaterThan(40));
      for (final f in fields) {
        expect(f.options, isNotEmpty, reason: f.id);
      }
    });

    testWidgets('each one shows all its options as ticks and ticking stores that option', (tester) async {
      for (final f in fields) {
        final log = <String>[];
        await tester.pumpWidget(_Host(key: ValueKey(f.id), field: f, log: log));
        expect(find.byType(InputDecorator), findsNothing, reason: f.id);
        expect(find.byType(InlineChoiceGroup), findsOneWidget, reason: f.id);
        final options = f.offeredOptions('');
        expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsNWidgets(options.length), reason: f.id);
        for (final o in options) {
          final key = find.byKey(ValueKey('choice:${f.label}:$o'));
          await tester.ensureVisible(key);
          await tester.tap(key);
          await tester.pump();
        }
        expect(log, options, reason: '${f.id}: each tap stores its own option text');
      }
    });
  });
}
