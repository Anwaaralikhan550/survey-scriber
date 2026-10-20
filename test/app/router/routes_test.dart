import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/app/router/routes.dart';

void main() {
  test('big plus opens Create Booking for the selected Home segment', () {
    expect(Routes.schedulingBookPath(valuation: false), '/scheduling/book');
    expect(Routes.schedulingBookPath(valuation: true), '/scheduling/book?type=valuation');
  });
}
