// The dropdown shows the admin's words and stores the original value.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/presentation/widgets/inspection_fields.dart';

const _field = InspectionFieldDefinition(
  id: 'cond',
  label: 'Condition',
  type: InspectionFieldType.dropdown,
  options: ['Good', 'Fair', 'Poor'],
  optionLabels: {'Good': 'Very good'},
  hiddenOptions: ['Poor'],
);

void main() {
  Future<void> pump(WidgetTester tester, String value, void Function(String) onChanged) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InspectionFieldInput(
          field: _field,
          value: value,
          onChanged: onChanged,
        ),
      ),
    ));
  }

  testWidgets('a saved value shows its new words', (tester) async {
    await pump(tester, 'Good', (_) {});
    expect(find.text('Very good'), findsOneWidget);
    expect(find.text('Good'), findsNothing);
  });

  testWidgets('the list offers the new words and hides the hidden option', (tester) async {
    await pump(tester, '', (_) {});
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.text('Very good'), findsOneWidget);
    expect(find.text('Fair'), findsOneWidget);
    expect(find.text('Poor'), findsNothing);
    expect(find.text('Good'), findsNothing);
  });

  testWidgets('choosing the new words stores the original value', (tester) async {
    String? stored;
    await pump(tester, '', (v) => stored = v);
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Very good'));
    await tester.pumpAndSettle();
    expect(stored, 'Good');
  });

  testWidgets('an old answer on a hidden option still shows', (tester) async {
    await pump(tester, 'Poor', (_) {});
    expect(find.text('Poor'), findsOneWidget);
    await tester.tap(find.byType(InputDecorator));
    await tester.pumpAndSettle();
    expect(find.text('Poor'), findsNWidgets(2));
  });

  testWidgets('an old answer on an option removed from the list still shows', (tester) async {
    await pump(tester, 'Gone', (_) {});
    expect(find.text('Gone'), findsOneWidget);
  });

  test('saving a field keeps its words', () {
    final json = _field.toJson();
    final back = InspectionFieldDefinition.fromJson(json);
    expect(back.optionLabels, {'Good': 'Very good'});
    expect(back.hiddenOptions, ['Poor']);
    expect(back.copyWith(label: 'X').optionLabels, {'Good': 'Very good'});
  });
}
