import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/property_inspection/domain/inspection_phrase_engine.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking_status.dart';

/// Generates human-readable sample output straight from the production engine
/// and entities, and writes it to sample_output.md for client review.
/// This is a generator, not an assertion suite.
void main() {
  test('generate sample bookings + report', () {
    final buf = StringBuffer();
    void h(String s) => buf.writeln('\n## $s\n');

    // ---- Engine (reads the current, verbatim-aligned phrase bank) ----
    final phraseTexts = (jsonDecode(
      File('assets/property_inspection/phrase_texts.json').readAsStringSync(),
    ) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
    final engine = InspectionPhraseEngine(phraseTexts);

    buf.writeln('# SurveyScriber — Sample Output (real engine + entities)');
    buf.writeln('\nGenerated from the merged `main` phrase bank and booking '
        'entities. Report text below is produced by the live phrase engine — '
        'it is exactly what a generated report contains.');

    // =====================================================================
    // PART 1 — Sample Bookings (App-Edit "Booking Appointment View")
    // =====================================================================
    buf.writeln('\n---\n# Part 1 — Sample Bookings (Booking Appointment View)');

    String addr(Booking b) => [
          b.addressLine,
          b.city,
          b.town,
          b.county,
          b.postcode,
        ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');

    void printBooking(String title, Booking b) {
      h(title);
      buf.writeln('- **Survey Type:** ${b.surveyType.label}');
      if (b.jobRef != null) buf.writeln('- **Job Ref No.:** ${b.jobRef}');
      buf.writeln('- **Date:** ${b.date.day}/${b.date.month}/${b.date.year}');
      buf.writeln('- **Time:** ${b.timeRange}');
      if (b.clientName != null) buf.writeln('- **Client Name:** ${b.clientName}');
      if (b.clientPhone != null) buf.writeln('- **Phone Number:** ${b.clientPhone}');
      if (b.propertyType != null) buf.writeln('- **Property type:** ${b.propertyType}');
      if (b.yearBuilt != null) buf.writeln('- **Year Built:** ${b.yearBuilt}');
      final a = addr(b);
      if (a.isNotEmpty) buf.writeln('- **Property Address:** $a');
      if (b.notes != null) buf.writeln("- **Client's Notes:** ${b.notes}");
      buf.writeln('- **Access:** ${b.accessType?.label ?? '—'}');
      if (b.accessType == BookingAccessType.collectKeys) {
        if (b.estateAgentName != null) buf.writeln('  - **Estate Agent:** ${b.estateAgentName}');
        if (b.estateAgentPhone != null) buf.writeln('  - **Agent Phone:** ${b.estateAgentPhone}');
        if (b.estateAgentAddress != null) buf.writeln('  - **Agent Address:** ${b.estateAgentAddress}');
        if (b.estateAgentNotes != null) buf.writeln("  - **Agent's Notes:** ${b.estateAgentNotes}");
      }
    }

    // Booking A — the exact example from the App-Edit PDF (George Adam).
    printBooking('Booking A — Home Survey, Direct Access (App-Edit PDF example)',
        Booking(
          id: 'A',
          surveyorId: 's1',
          date: DateTime(2026, 7, 25),
          startTime: '09:00',
          endTime: '10:00',
          status: BookingStatus.pending,
          surveyType: BookingSurveyType.homeSurvey,
          jobRef: 'FDF2223354',
          clientName: 'George Adam',
          clientPhone: '02458754210',
          propertyType: 'House',
          yearBuilt: '1950',
          addressLine: '29 Taylor Drive',
          city: 'Chelmsford',
          county: 'Essex',
          postcode: 'IG4 5DD',
          notes: 'Pet let in the house',
          accessType: BookingAccessType.directAccess,
          createdById: 'u1',
          createdAt: DateTime(2026, 7, 1),
          updatedAt: DateTime(2026, 7, 1),
        ));

    // Booking B — Collect Keys shows the estate-agent block.
    printBooking('Booking B — Home Survey, Collect Keys (estate-agent block)',
        Booking(
          id: 'B',
          surveyorId: 's1',
          date: DateTime(2026, 8, 3),
          startTime: '11:00',
          endTime: '12:30',
          status: BookingStatus.confirmed,
          surveyType: BookingSurveyType.homeSurvey,
          jobRef: 'JOB-1187',
          clientName: 'Priya Shah',
          clientPhone: '07700900123',
          propertyType: 'Flat',
          yearBuilt: '1998',
          addressLine: '4 Mill Court',
          city: 'Bristol',
          postcode: 'BS1 4ST',
          county: 'Avon',
          notes: 'Access from rear only',
          accessType: BookingAccessType.collectKeys,
          estateAgentName: 'Bravo Agent',
          estateAgentPhone: '1254875928',
          estateAgentAddress: '29 Taylor Drive, Chelmsford, IG4 5DD',
          estateAgentNotes: 'Key safe to the back',
          createdById: 'u1',
          createdAt: DateTime(2026, 7, 20),
          updatedAt: DateTime(2026, 7, 20),
        ));

    // Booking C — Valuation (the separate home-screen segment).
    printBooking('Booking C — Valuation, Direct Access',
        Booking(
          id: 'C',
          surveyorId: 's1',
          date: DateTime(2026, 8, 10),
          startTime: '14:00',
          endTime: '14:45',
          status: BookingStatus.pending,
          surveyType: BookingSurveyType.valuation,
          jobRef: 'VAL-556',
          clientName: 'Tom Reeves',
          clientPhone: '07811223344',
          propertyType: 'Bungalow',
          yearBuilt: '1972',
          addressLine: '7 Oakfield Road',
          city: 'Cardiff',
          postcode: 'CF14 3AB',
          accessType: BookingAccessType.directAccess,
          createdById: 'u1',
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 1),
        ));

    // =====================================================================
    // PART 2 — Sample generated report sections (live phrase engine)
    // =====================================================================
    buf.writeln('\n---\n# Part 2 — Sample Report Sections (live phrase engine)');
    buf.writeln('\nEach block is the verbatim engine output for realistic '
        'answers. Note the revised-PDF wording in bold-worthy places '
        '(e.g. "Modern Building Design", "No defects noted:", '
        '"economical to rebuild the whole stack", per-element maintenance).');

    void section(String title, String screenId, Map<String, String> answers) {
      final out = engine.buildPhrases(screenId, answers);
      h(title);
      if (out.isEmpty) {
        buf.writeln('_(no output for these answers)_');
      } else {
        for (final s in out) {
          buf.writeln('- $s');
        }
      }
    }

    section('D — Construction (cavity + timber frame)',
        'activity_property_construction', {'ch3': 'true', 'ch4': 'true'});

    section('E — Roof covering', 'activity_property_roof', {
      'ch1': 'true',
      'ch8': 'true',
      'ch_plastic': 'true',
      'ch16': 'true',
      'etCoveredWithOther': 'zinc',
    });

    section('E — External walls (rendered)', 'activity_extended_wall', {
      'ch1': 'true',
      'android_material_design_spinner': 'Fully',
      'android_material_design_spinner2': 'Smooth',
      'ch7': 'true',
      'android_material_design_spinner4': 'Partially',
    });

    section('E — Chimney in disrepair (repair soon, front stack)',
        'activity_outside_property_repair_chimney_disrepair',
        {'cb_repair_soon_70': 'true', 'cb_front_101': 'true'});

    section('F — Floors', 'activity_construction_floor', {
      'android_material_design_spinner': 'Of a mixture of',
      'ch1': 'true',
      'ch5': 'true',
      'etCoveredWithOther': 'resin',
    });

    section('F — Ceilings (reasonable condition — "No defects noted:")',
        'inside_property_ceilings_about_ceilings', {
      'actv_made_up': 'Mainly of',
      'cb_plasterboard': 'true',
      'cb_painted': 'true',
      'actv_condition': 'Reasonable',
    });

    section('F — Windows', 'activity_construction_window', {
      'android_material_design_spinner': 'A mixture of',
      'ch2': 'true',
      'ch4': 'true',
      'etCoveredWithOther': 'triple',
      'ch5': 'true',
    });

    section('G — Heating (air source heat pump)',
        'activity_services_heating_about_heating',
        {'cb_air_source_heat_pump': 'true'});

    final f = File('sample_output.md');
    f.writeAsStringSync(buf.toString());
    // Echo to stdout too.
    // ignore: avoid_print
    print(buf.toString());
    expect(f.existsSync(), isTrue);
  });
}
