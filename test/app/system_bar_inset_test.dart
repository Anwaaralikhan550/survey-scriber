// Client file (4), 10 Nov 2026: Create Booking's bottom button sat under the phone's navigation bar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/app/system_bar_inset.dart';
import 'package:survey_scriber/shared/presentation/widgets/safe_page_padding.dart';

void main() {
  Future<void> phone(WidgetTester tester, Widget home, {required double bar}) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(bottom: bar);
    tester.view.viewPadding = FakeViewPadding(bottom: bar);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(builder: keepAboveNavigationBar, home: home));
  }

  testWidgets('with a navigation bar, a bottom button ends above it', (tester) async {
    await phone(
      tester,
      Scaffold(
        body: Column(children: [
          const Spacer(),
          ElevatedButton(key: const Key('create'), onPressed: () {}, child: const Text('Create Booking')),
        ]),
      ),
      bar: 48,
    );
    expect(tester.getBottomLeft(find.byKey(const Key('create'))).dy, 800 - 48);
  });

  testWidgets('with no navigation bar, the page uses the whole screen', (tester) async {
    await phone(tester, const Scaffold(body: SizedBox.expand(key: Key('body'))), bar: 0);
    expect(tester.getSize(find.byKey(const Key('body'))).height, 800);
  });

  testWidgets('a page that already handles the bar is not padded twice', (tester) async {
    late EdgeInsets padding;
    await phone(
      tester,
      Builder(builder: (context) {
        padding = safePagePadding(context, 16);
        return const Scaffold(body: SizedBox());
      }),
      bar: 48,
    );
    expect(padding.bottom, 16);
  });
}
