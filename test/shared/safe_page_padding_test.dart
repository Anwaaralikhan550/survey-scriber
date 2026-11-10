// Client file (3), 10 Nov 2026: Booking Details' Cancel/Confirm sat under the
// phone's navigation bar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/shared/presentation/widgets/safe_page_padding.dart';

void main() {
  testWidgets('bottom padding adds the navigation bar height', (tester) async {
    late EdgeInsets padding;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 48)),
        child: Builder(builder: (context) {
          padding = safePagePadding(context);
          return const SizedBox();
        }),
      ),
    );
    expect(padding, const EdgeInsets.fromLTRB(16, 16, 16, 64));
  });

  testWidgets('the last button of a long page scrolls clear of the bar', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800), padding: EdgeInsets.only(bottom: 48)),
          child: Scaffold(
            body: Builder(
              builder: (context) => ListView(
                padding: safePagePadding(context),
                children: [
                  const SizedBox(height: 1200),
                  FilledButton(onPressed: () {}, child: const Text('Confirm')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    final bottom = tester.getRect(find.text('Confirm')).bottom;
    expect(bottom, lessThanOrEqualTo(800 - 48));
  });
}
