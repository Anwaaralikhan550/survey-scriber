import { Test, TestingModule } from '@nestjs/testing';
import { EnhancedReportService, EnrichedSectionData } from './enhanced-report.service';
import { ExcelPhraseGeneratorService } from './excel-phrase-generator.service';

describe('EnhancedReportService AST Domain Rules', () => {
  let service: EnhancedReportService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EnhancedReportService,
        {
          provide: ExcelPhraseGeneratorService,
          useValue: {},
        },
      ],
    }).compile();

    service = module.get<EnhancedReportService>(EnhancedReportService);
  });

  const makeEnrichedSection = (overrides: Partial<EnrichedSectionData>): EnrichedSectionData => ({
    sectionId: 'section-1',
    sectionType: 'inspection',
    title: 'Generic Section',
    answers: {},
    narratives: [],
    excelPhraseCount: 0,
    aiNeededCount: 0,
    totalFields: 0,
    ...overrides,
  });

  const countNoRepairSentence = (text: string): number => {
    const matches = text.match(/No repair is currently needed\./gi);
    return matches ? matches.length : 0;
  };

  describe('1) Conditional suppression of "No repair is currently needed"', () => {
    const phraseWithNoRepair =
      'These appear in satisfactory condition. No repair is currently needed. The property should be maintained in the normal way.';

    it('should append sentence only when observed defect require repair = No', () => {
      const section = makeEnrichedSection({
        title: 'E Outside Property',
        answers: {
          observed_defect_require_repair: 'No',
        },
        narratives: [
          {
            fieldKey: 'outside_walls_condition',
            optionValue: 'Satisfactory',
            phrase: phraseWithNoRepair,
            source: 'excel',
          },
        ],
        excelPhraseCount: 1,
        totalFields: 1,
      });

      const { ast } = service.buildReportAstWithExcelPhrases([section]);
      const text = ast.sections[0].dynamicPhrases[0].text;

      expect(text).toContain('No repair is currently needed.');
      expect(countNoRepairSentence(text)).toBe(1);
    });

    it('should suppress sentence when observed defect require repair = Yes', () => {
      const section = makeEnrichedSection({
        title: 'E Outside Property',
        answers: {
          observed_defect_require_repair: 'Yes',
        },
        narratives: [
          {
            fieldKey: 'outside_walls_condition',
            optionValue: 'Satisfactory',
            phrase: phraseWithNoRepair,
            source: 'excel',
          },
        ],
        excelPhraseCount: 1,
        totalFields: 1,
      });

      const { ast } = service.buildReportAstWithExcelPhrases([section]);
      const text = ast.sections[0].dynamicPhrases[0].text;

      expect(text).not.toContain('No repair is currently needed.');
      expect(countNoRepairSentence(text)).toBe(0);
    });
  });

  describe('2) Section E paragraph merging with groupKey', () => {
    it('should merge walls/windows/doors phrases into cohesive blocks per groupKey', () => {
      const section = makeEnrichedSection({
        title: 'E Outside Property',
        sectionType: 'exterior',
        answers: {
          observed_defect_require_repair: 'No',
        },
        narratives: [
          {
            fieldKey: 'main_wall_finish',
            optionValue: 'Brick',
            phrase: 'Walls are of brick construction.',
            source: 'excel',
          },
          {
            fieldKey: 'external_wall_thickness',
            optionValue: '250',
            phrase: 'Wall thickness measured approximately 250 mm.',
            source: 'excel',
          },
          {
            fieldKey: 'front_window_condition',
            optionValue: 'Good',
            phrase: 'Windows appear serviceable.',
            source: 'excel',
          },
          {
            fieldKey: 'rear_window_glazing',
            optionValue: 'Double',
            phrase: 'Windows are predominantly double glazed.',
            source: 'excel',
          },
          {
            fieldKey: 'front_door_condition',
            optionValue: 'Good',
            phrase: 'Doors are secure and weather-tight.',
            source: 'excel',
          },
        ],
        excelPhraseCount: 5,
        totalFields: 5,
      });

      const { ast } = service.buildReportAstWithExcelPhrases([section]);
      const dynamic = ast.sections[0].dynamicPhrases;

      expect(dynamic.length).toBe(3);
      expect(dynamic[0].groupKey).toBe('section-e:walls');
      expect(dynamic[0].text).toContain('Walls are of brick construction.');
      expect(dynamic[0].text).toContain('250 mm.');

      expect(dynamic[1].groupKey).toBe('section-e:windows');
      expect(dynamic[1].text).toContain('Windows appear serviceable.');
      expect(dynamic[1].text).toContain('double glazed');

      expect(dynamic[2].groupKey).toBe('section-e:doors');
      expect(dynamic[2].text).toContain('Doors are secure and weather-tight.');
    });
  });

  describe('3) Section K leasehold auto-injection for Flat properties', () => {
    it('should inject leasehold assumption into K assumptions and Other Considerations when propertyType includes Flat', () => {
      const kSection = makeEnrichedSection({
        sectionId: 'k-1',
        sectionType: 'assumptions',
        title: 'K Additional Assumptions',
      });

      const otherConsiderations = makeEnrichedSection({
        sectionId: 'k-2',
        sectionType: 'notes',
        title: 'Other Considerations',
      });

      const { ast } = service.buildReportAstWithExcelPhrases(
        [kSection, otherConsiderations],
        { propertyType: 'Flat/Apartment' },
      );

      const assumptionText =
        'As the property type is Flat, it is assumed to be leasehold unless confirmed otherwise by legal title documents.';

      const kAst = ast.sections.find((s) => s.sectionId === 'k-1');
      const otherAst = ast.sections.find((s) => s.sectionId === 'k-2');

      expect(kAst).toBeDefined();
      expect(otherAst).toBeDefined();
      expect(kAst!.defaultParagraphs.some((p) => p.text === assumptionText)).toBe(true);
      expect((otherAst!.otherConsiderations ?? []).some((p) => p.text === assumptionText)).toBe(true);
    });
  });

  describe('4) Section F default paragraphs (Inspection Limitations + Moisture)', () => {
    it('should inject both default paragraphs in Section F AST output', () => {
      const sectionF = makeEnrichedSection({
        sectionId: 'f-1',
        sectionType: 'interior',
        title: 'F Inside Property',
        answers: {
          moisture_detected: 'Yes',
        },
        narratives: [
          {
            fieldKey: 'inspection_limitation_access',
            optionValue: 'Restricted',
            phrase: 'Access to parts of the roof void was restricted.',
            source: 'excel',
          },
          {
            fieldKey: 'moisture_reading_internal_wall',
            optionValue: 'Elevated',
            phrase: 'Moisture readings were elevated in isolated areas.',
            source: 'excel',
          },
        ],
        excelPhraseCount: 2,
        totalFields: 2,
      });

      const { ast } = service.buildReportAstWithExcelPhrases([sectionF]);
      const defaults = ast.sections[0].defaultParagraphs.map((p) => p.text);

      expect(defaults).toContain(
        'Inspection limitations apply where access, visibility, or safety constraints prevented a complete assessment of all elements.',
      );
      expect(defaults).toContain(
        'Moisture and dampness observations are based on visible surfaces and meter readings at inspection time only; concealed conditions may still exist.',
      );
    });
  });
});

