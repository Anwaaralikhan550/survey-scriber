import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_catalog.dart';
import 'package:survey_scriber/features/property_valuation/domain/valuation_phrase_engine.dart';
import 'package:survey_scriber/features/report_export/data/services/docx_generator_service.dart';
import 'package:survey_scriber/features/report_export/data/services/pdf_generator_service.dart';
import 'package:survey_scriber/features/report_export/data/services/report_builder.dart';
import 'package:survey_scriber/features/report_export/data/services/report_data_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _ScratchPathProvider();

  test(
      'generates a realistic valuation PDF and DOCX through production renderers',
      () async {
    final output = Directory(
      'generated_reports/valuation_phrase_engine_validation',
    )..createSync(recursive: true);
    final tree = InspectionTreePayload.fromJson(
      File('assets/property_valuation/valuation_tree.json').readAsStringSync(),
    );
    final catalog = ValuationPhraseCatalog.fromRawJson(
      File('assets/property_valuation/phrase_texts.json').readAsStringSync(),
    );
    final survey = Survey(
      id: 'valuation-phrase-engine-validation',
      title: '18 Oakfield Road, Harrogate, HG1 4AB',
      type: SurveyType.valuation,
      status: SurveyStatus.completed,
      createdAt: DateTime(2026, 7, 12),
      address: '18 Oakfield Road, Harrogate, HG1 4AB',
      clientName: 'Example Client',
      jobRef: 'VAL-2026-0712',
    );
    final raw = V2RawReportData(
      survey: survey,
      tree: tree,
      allAnswers: const {
        'general_details': {
          'actv_status': 'Occupied',
          'actv_finishes': 'Partially furnished',
          'actv_carpeted': 'Partially',
          'actv_vl_reason': 'Market Value',
          'actv_weather': 'Dry',
          'actv_tenure': 'Freehold',
          'actv_type': 'House',
          'actv_sub_type': 'Semi',
          'et_age': '1988',
        },
        'no_of_rooms': {
          'et_liv': '2',
          'et_kit': '1',
          'et_bed': '3',
          'et_bath': '1',
          'et_wc': '1',
          'et_ut': '1',
          'et_other': '1',
          'et_other_name': 'Study',
        },
        'accommodation_summary': {
          'cb_single': 'true',
          'actv_parking_location': 'Onsite',
          'cb_external_garden': 'true',
        },
        'location_amenities': {
          'actv_location': 'Town',
          'cb_local_amenities': 'true',
        },
        'val_pitched_roof': {
          'cb_tile': 'true',
          'actv_condition_pitched_roof': 'Satisfactory',
        },
        'val_walls_type': {
          'cb_cavity_wt': 'true',
          'cb_brick_wt': 'true',
          'actv_condition_walls': 'Satisfactory',
        },
        'val_external_joinery': {
          'cb_upvc_ej': 'true',
          'cb_double_glazed': 'true',
          'actv_condition_ext_joinery': 'Satisfactory',
        },
        'val_gas': {
          'actv_gas_supply': 'Mains',
          'actv_condition_gas': 'Satisfactory',
        },
        'val_water': {
          'actv_water_supply': 'Mains',
          'actv_condition_water': 'Satisfactory',
        },
        'val_hot_water_central_heating': {
          'cb_gas_hw': 'true',
          'cb_radiators': 'true',
          'cb_full': 'true',
          'actv_condition_hw_ch': 'Satisfactory',
        },
        'overall_condition': {
          'actv_overall_condition': 'Good',
        },
        'energy_performance': {
          'actv_epc_current_rating': 'C',
          'et_epc_current_score': '72',
          'actv_epc_potential_rating': 'B',
          'et_epc_potential_score': '84',
          'et_epc_reference': '1234-5678-9012-3456-7890',
        },
        'valuation': {
          'et_purchase_price': '325000',
          'et_estimated_value': '320000',
          'cb_open_market_value': 'true',
          'et_value_of_share': '325000',
          'et_share': '100',
          'cb_suitable_security': 'true',
        },
      },
      screenStates: const {},
      photoFilePaths: const [],
      signatureRows: const [],
    );
    const config = ExportConfig(
      includePhotos: false,
      includeSignatures: false,
      includeRecommendations: false,
    );
    final document = ReportBuilder(
      valuationPhraseEngine: ValuationPhraseEngine.catalog(catalog),
    ).build(raw, config);

    final pdf = await PdfGeneratorService(config).generatePdf(document);
    final docx = await DocxGeneratorService(config).generateDocx(document);
    File('${output.path}/valuation_phrase_engine_validation.pdf')
        .writeAsBytesSync(pdf.bytes);
    File('${output.path}/valuation_phrase_engine_validation.docx')
        .writeAsBytesSync(docx.bytes);
    File('${output.path}/report_summary.txt').writeAsStringSync(
      'sections=${document.sections.length}\n'
      'screens=${document.totalScreens}\n'
      'accommodationRows=${document.accommodationSchedule.length}\n'
      'pdfBytes=${pdf.bytes.length}\n'
      'docxBytes=${docx.bytes.length}\n',
    );

    expect(document.accommodationSchedule.single.otherRooms, '1 Study');
    expect(pdf.bytes, isNotEmpty);
    expect(docx.bytes, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

class _ScratchPathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      'E:/survey-scriber/tmp/valuation_export_app_documents';
}
