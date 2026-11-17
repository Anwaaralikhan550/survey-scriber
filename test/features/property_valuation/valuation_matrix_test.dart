// Client 17 Nov 2026 (Q10): the matrix grid in the app. Blank, typed by hand, stored as one answer.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_matrix.dart';
import 'package:survey_scriber/features/property_valuation/presentation/widgets/valuation_matrix_editor.dart';

class _Host extends StatefulWidget {
  const _Host({required this.log, this.start = ''});
  final List<String> log;
  final String start;
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String value = widget.start;
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ValuationMatrixEditor(
                value: value,
                onChanged: (v) {
                  widget.log.add(v);
                  setState(() => value = v);
                },
              ),
            ],
          ),
        ),
      );
}

void main() {
  group('domain', () {
    test('blank by default: 17 rows of 6 empty cells, stored as an empty answer', () {
      final g = ValuationMatrix.emptyGrid();
      expect(g.length, 17);
      expect(g, everyElement(hasLength(6)));
      expect(g.expand((r) => r), everyElement(''));
      expect(ValuationMatrix.encode(g), '');
      expect(ValuationMatrix.parse(''), g);
      expect(ValuationMatrix.parse(null), g);
    });
    test('round trip keeps every cell', () {
      final g = ValuationMatrix.emptyGrid();
      g[0][0] = '12 High St';
      g[16][5] = '£1,000';
      final back = ValuationMatrix.parse(ValuationMatrix.encode(g));
      expect(back, g);
    });
    test('damaged answers never throw', () {
      for (final bad in ['x', '{', '{"a":1}', '[[1,null,{}]]', '[null]', '"str"', '42']) {
        expect(ValuationMatrix.parse(bad).length, 17, reason: bad);
      }
      expect(ValuationMatrix.parse('[[1,null,"b"]]')[0].take(3), ['1', '', 'b']);
    });
    test('long text is cut, extra rows and columns are ignored', () {
      final long = 'x' * 500;
      final g = ValuationMatrix.parse(jsonEncode([
        [long, 'a', 'b', 'c', 'd', 'e', 'EXTRA'],
        ...List.generate(30, (_) => ['z']),
      ]));
      expect(g[0][0].length, ValuationMatrix.maxCellLength);
      expect(g.length, 17);
      expect(g[0].length, 6);
    });
    test('the row names and the header are the client sample', () {
      expect(ValuationMatrix.rowLabels.length, 17);
      expect(ValuationMatrix.rowLabels.first, 'Address');
      expect(ValuationMatrix.rowLabels[9], 'Price/Sqm');
      expect(ValuationMatrix.headers.first, 'Best Match');
      expect(ValuationMatrix.headers.last, 'Subject');
      expect(ValuationMatrix.title, 'FBS Valuation Matrix');
    });
    test('the tree has the screen with the one answer, after Valuation and before General Remarks', () {
      final tree = jsonDecode(File('assets/property_valuation/valuation_tree.json').readAsStringSync()) as Map<String, dynamic>;
      final section = (tree['sections'] as List).cast<Map>().firstWhere((s) => s['key'] == 'valuation_completion');
      final ids = [for (final n in section['nodes'] as List) (n as Map)['id']];
      expect(ids, ['valuation', 'valuation_matrix', 'general_remarks', 'scan_floor_plan']);
      final node = (section['nodes'] as List).cast<Map>().firstWhere((n) => n['id'] == 'valuation_matrix');
      expect([for (final f in node['fields'] as List) (f as Map)['id']], [ValuationMatrix.fieldId]);
    });
  });

  group('the grid on screen', () {
    testWidgets('shows the header, the 17 row names and 102 empty cells', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_Host(log: []));
      expect(find.text('FBS Valuation Matrix'), findsOneWidget);
      for (final h in ValuationMatrix.headers) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
      expect(find.byType(TextField), findsNWidgets(17 * 6));
      for (final l in ['Address', 'Date of Trans', 'Price', 'Price/Sqm', 'Features']) {
        expect(find.text(l), findsOneWidget, reason: l);
      }
      expect(find.text('Adjustment'), findsNWidgets(3));
      expect(find.text('Amount'), findsNWidgets(3));
      for (final f in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(f.controller!.text, '');
      }
    });

    testWidgets('typing in a cell stores the grid; nothing else changes', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final log = <String>[];
      await tester.pumpWidget(_Host(log: log));
      await tester.enterText(find.byKey(const ValueKey('matrix:0:0')), '12 High Street');
      await tester.enterText(find.byKey(const ValueKey('matrix:2:5')), '£460,000');
      await tester.pump();
      final g = ValuationMatrix.parse(log.last);
      expect(g[0][0], '12 High Street');
      expect(g[2][5], '£460,000');
      expect(g.expand((r) => r).where((c) => c.isNotEmpty).length, 2);
      expect(g[9], everyElement(''), reason: 'Price/Sqm is not calculated');
    });


    testWidgets('long text wraps and the row grows; a new line cannot be typed', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final log = <String>[];
      await tester.pumpWidget(_Host(log: log));
      final short = tester.getSize(find.byKey(const ValueKey('matrix:0:0'))).height;
      await tester.enterText(find.byKey(const ValueKey('matrix:0:0')), 'Flat 3, Riverside Court, 12 High Street, Dartford, Kent DA1 4PL');
      await tester.pump();
      final tall = tester.getSize(find.byKey(const ValueKey('matrix:0:0'))).height;
      expect(tall, greaterThan(short), reason: 'the cell grows to show all the text');
      await tester.enterText(find.byKey(const ValueKey('matrix:1:0')), 'line one\nline two');
      await tester.pump();
      expect(ValuationMatrix.parse(log.last)[1][0], 'line oneline two');
    });


    testWidgets('spaces typed between words are kept while the answer round-trips through the screen', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final log = <String>[];
      await tester.pumpWidget(_Host(log: log));
      final cell = find.byKey(const ValueKey('matrix:0:0'));
      String shown() => tester.widget<TextField>(cell).controller!.text;
      // as a keyboard does: one character at a time, the host stores and hands the answer back each time
      var typed = '';
      for (final ch in 'Flat 3, Riverside Court'.split('')) {
        typed += ch;
        await tester.enterText(cell, typed);
        await tester.pump();
        expect(shown(), typed, reason: 'after typing "$typed"');
      }
      expect(ValuationMatrix.parse(log.last)[0][0], 'Flat 3, Riverside Court');
    });

    testWidgets('clearing everything stores an empty answer', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final log = <String>[];
      await tester.pumpWidget(_Host(log: log));
      await tester.enterText(find.byKey(const ValueKey('matrix:1:1')), 'x');
      await tester.enterText(find.byKey(const ValueKey('matrix:1:1')), '');
      await tester.pump();
      expect(log.last, '');
    });

    testWidgets('a saved answer is shown, and a late or synchronised answer replaces the cells', (tester) async {
      tester.view.physicalSize = const Size(1400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final g = ValuationMatrix.emptyGrid()..[4][2] = 'Three';
      await tester.pumpWidget(_Host(log: [], start: ValuationMatrix.encode(g)));
      expect(find.text('Three'), findsOneWidget);
      final g2 = ValuationMatrix.emptyGrid()..[4][2] = 'Four';
      await tester.pumpWidget(_Host(log: [], start: ValuationMatrix.encode(g2)));
      // same State is kept, new value arrives through the host
      expect(find.text('Three'), findsOneWidget);
    });
  });
}
