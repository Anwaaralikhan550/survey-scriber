/**
 * Enhanced Report Service
 * Integrates Excel phrase generation with AI report generation
 * Uses hardcoded professional phrases with template substitution when available, AI as fallback
 */
import { Injectable, Logger } from '@nestjs/common';
import { ExcelPhraseGeneratorService } from './excel-phrase-generator.service';
import { SectionAnswersDto } from '../modules/ai/dto/ai-report.dto';
import {
  ReportAstMetadata,
  ReportAstParagraph,
  ReportAstPayload,
  ReportSectionAst,
} from '../modules/ai/dto/report-ast.dto';

export interface EnrichedSectionData {
  sectionId: string;
  sectionType: string;
  title: string;
  answers: Record<string, string>;
  // New: Professional phrases from Excel
  narratives: {
    fieldKey: string;
    optionValue: string;
    phrase: string;
    source: 'excel' | 'ai-needed';
  }[];
  // Statistics
  excelPhraseCount: number;
  aiNeededCount: number;
  totalFields: number;
}

export interface LegacySectionWithPhrases {
  sectionId: string;
  sectionType: string;
  title: string;
  narrative: string;
  source: 'excel' | 'mixed' | 'ai-needed';
  usedExcelPhrases: number;
  totalPhrases: number;
}

interface BuildAstMetadataInput {
  surveyId?: string;
  propertyAddress?: string;
  propertyType?: string;
}

interface BuildStats {
  totalSections: number;
  totalFields: number;
  excelPhraseCount: number;
  aiNeededCount: number;
  coveragePercent: number;
}

@Injectable()
export class EnhancedReportService {
  private readonly logger = new Logger(EnhancedReportService.name);
  private static readonly NO_REPAIR_SENTENCE = 'No repair is currently needed.';
  private static readonly LEASEHOLD_ASSUMPTION_TEXT =
    'As the property type is Flat, it is assumed to be leasehold unless confirmed otherwise by legal title documents.';
  private static readonly INSPECTION_LIMITATIONS_DEFAULT_TEXT =
    'Inspection limitations apply where access, visibility, or safety constraints prevented a complete assessment of all elements.';
  private static readonly MOISTURE_DAMPNESS_DEFAULT_TEXT =
    'Moisture and dampness observations are based on visible surfaces and meter readings at inspection time only; concealed conditions may still exist.';

  constructor(
    private readonly phraseGenerator: ExcelPhraseGeneratorService,
  ) {}

  /**
   * Enrich survey sections with Excel phrases (with template substitution)
   * Identifies which fields have professional phrases and which need AI
   */
  enrichSectionsWithPhrases(sections: SectionAnswersDto[]): EnrichedSectionData[] {
    const enrichedSections: EnrichedSectionData[] = [];

    for (const section of sections) {
      const narratives: EnrichedSectionData['narratives'] = [];
      let excelPhraseCount = 0;
      let aiNeededCount = 0;

      // Process each field answer
      for (const [fieldKey, optionValue] of Object.entries(section.answers)) {
        // Skip empty or null values
        if (!optionValue || optionValue.trim() === '') {
          continue;
        }

        // Try to generate Excel phrase with template substitution
        // Pass all section answers as formData for template substitution
        const result = this.phraseGenerator.generatePhrase(
          fieldKey,
          optionValue,
          section.answers, // All form data for template substitution
        );

        if (result.success && result.phrase) {
          // Excel phrase generated successfully!
          narratives.push({
            fieldKey,
            optionValue,
            phrase: result.phrase,
            source: 'excel',
          });
          excelPhraseCount++;

          this.logger.debug(
            `✓ Excel phrase generated: ${fieldKey}=${optionValue} ` +
            `(${result.substitutions.length} substitutions, ` +
            `confidence: ${(result.confidence * 100).toFixed(0)}%, ` +
            `phrase length: ${result.phrase.length})`,
          );
        } else {
          // No Excel phrase or generation failed, needs AI
          narratives.push({
            fieldKey,
            optionValue,
            phrase: '', // Will be filled by AI
            source: 'ai-needed',
          });
          aiNeededCount++;

          this.logger.debug(
            `⚠ No Excel phrase: ${fieldKey}=${optionValue} ` +
            `(${result.error || 'field not found'}) - will use AI`,
          );
        }
      }

      enrichedSections.push({
        sectionId: section.sectionId,
        sectionType: section.sectionType,
        title: section.title,
        answers: section.answers,
        narratives,
        excelPhraseCount,
        aiNeededCount,
        totalFields: narratives.length,
      });

      this.logger.log(
        `Section "${section.title}": ${excelPhraseCount} Excel phrases, ` +
        `${aiNeededCount} need AI, ${narratives.length} total fields`,
      );
    }

    return enrichedSections;
  }

  /**
   * Build report sections using Excel phrases + AI
   * Returns sections with narratives from Excel where available
   */
  buildReportWithExcelPhrases(
    enrichedSections: EnrichedSectionData[],
    metadata?: BuildAstMetadataInput,
  ): {
    ast: ReportAstPayload;
    sectionsWithPhrases: LegacySectionWithPhrases[];
    stats: BuildStats;
  } {
    const { ast, stats } = this.buildReportAstWithExcelPhrases(
      enrichedSections,
      metadata,
    );
    const sectionsWithPhrases = this.adaptAstToLegacySections(
      ast.sections,
      enrichedSections,
    );

    return {
      ast,
      sectionsWithPhrases,
      stats,
    };
  }

  /**
   * Build report AST payload from enriched sections.
   * This preserves the phrase-generation engine while upgrading assembly
   * to structured data for downstream renderers.
   */
  buildReportAstWithExcelPhrases(
    enrichedSections: EnrichedSectionData[],
    metadata?: BuildAstMetadataInput,
  ): {
    ast: ReportAstPayload;
    stats: BuildStats;
  } {
    const sections: ReportSectionAst[] = [];
    let totalFields = 0;
    let totalExcelPhrases = 0;
    let totalAiNeeded = 0;

    for (const section of enrichedSections) {
      const sectionAst = this.compileSectionAst(section);
      this.applySectionFDefaults(sectionAst, section.answers);
      sections.push(sectionAst);

      totalFields += section.totalFields;
      totalExcelPhrases += section.excelPhraseCount;
      totalAiNeeded += section.aiNeededCount;
    }

    const coveragePercent = totalFields > 0
      ? Math.round((totalExcelPhrases / totalFields) * 100)
      : 0;

    this.logger.log(
      `Report built: ${totalExcelPhrases}/${totalFields} fields (${coveragePercent}%) ` +
      `using Excel phrases, ${totalAiNeeded} need AI`,
    );

    const astMetadata: ReportAstMetadata = {
      reportTitle: 'Home Survey Inspection Report',
      surveyId: metadata?.surveyId,
      propertyAddress: metadata?.propertyAddress,
      propertyType: metadata?.propertyType,
      generatedAtIso: new Date().toISOString(),
    };

    this.injectFlatLeaseholdAssumptionIfNeeded(sections, astMetadata.propertyType);

    return {
      ast: {
        schemaVersion: '2.0',
        metadata: astMetadata,
        sectionOrder: sections.map((s) => s.sectionId),
        sections,
      },
      stats: {
        totalSections: enrichedSections.length,
        totalFields,
        excelPhraseCount: totalExcelPhrases,
        aiNeededCount: totalAiNeeded,
        coveragePercent,
      },
    };
  }

  private compileSectionAst(section: EnrichedSectionData): ReportSectionAst {
    const limitations: ReportAstParagraph[] = [];
    const defaultParagraphs: ReportAstParagraph[] = [];
    const dynamicPhrases: ReportAstParagraph[] = [];
    const remarks: ReportAstParagraph[] = [];
    let conditionRating: ReportSectionAst['conditionRating'];
    const repairDecision = this.resolveObservedDefectRepairDecision(section.answers);
    const isSectionE = this.isSectionE(section);

    for (const narrative of section.narratives) {
      if (narrative.source !== 'excel' || !narrative.phrase) {
        continue;
      }

      const fieldKeyLower = narrative.fieldKey.toLowerCase();
      const paragraph: ReportAstParagraph = {
        id: `${section.sectionId}:${narrative.fieldKey}`,
        text: this.applyNoRepairSentencePolicy(narrative.phrase, repairDecision),
        source: 'excel',
      };

      if (isSectionE) {
        paragraph.groupKey = this.resolveSectionEGroupKey(fieldKeyLower);
      }

      if (!conditionRating && this.isConditionRatingField(narrative.fieldKey)) {
        conditionRating = {
          label: 'Condition Rating',
          value: narrative.optionValue,
          sourceFieldKey: narrative.fieldKey,
        };
      }

      if (this.isLimitationField(fieldKeyLower)) {
        limitations.push(paragraph);
        continue;
      }

      if (this.isRemarkField(fieldKeyLower)) {
        remarks.push(paragraph);
        continue;
      }

      if (this.shouldMergeWithOpenGroup(paragraph, dynamicPhrases)) {
        const last = dynamicPhrases[dynamicPhrases.length - 1];
        last.text = `${last.text} ${paragraph.text}`.trim();
        continue;
      }

      dynamicPhrases.push(paragraph);
    }

    return {
      sectionId: section.sectionId,
      sectionType: section.sectionType,
      title: section.title,
      conditionRating,
      limitations,
      defaultParagraphs,
      dynamicPhrases,
      remarks,
    };
  }

  private adaptAstToLegacySections(
    astSections: ReportSectionAst[],
    enrichedSections: EnrichedSectionData[],
  ): LegacySectionWithPhrases[] {
    return astSections.map((section) => {
      const enriched = enrichedSections.find((s) => s.sectionId === section.sectionId);
      const narrative = this.renderLegacyNarrativeFromAst(section);
      const totalPhrases = enriched?.totalFields ?? 0;
      const usedExcelPhrases = enriched?.excelPhraseCount ?? 0;

      let source: 'excel' | 'mixed' | 'ai-needed';
      if (totalPhrases > 0 && usedExcelPhrases === totalPhrases) {
        source = 'excel';
      } else if (usedExcelPhrases > 0) {
        source = 'mixed';
      } else {
        source = 'ai-needed';
      }

      return {
        sectionId: section.sectionId,
        sectionType: section.sectionType,
        title: section.title,
        narrative,
        source,
        usedExcelPhrases,
        totalPhrases,
      };
    });
  }

  private renderLegacyNarrativeFromAst(section: ReportSectionAst): string {
    const paragraphs: string[] = [];

    if (section.conditionRating?.value) {
      paragraphs.push(`Condition Rating: ${section.conditionRating.value}`);
    }

    const addParagraphs = (items: ReportAstParagraph[]) => {
      for (const item of items) {
        if (item.text && item.text.trim()) {
          paragraphs.push(item.text.trim());
        }
      }
    };

    addParagraphs(section.limitations);
    addParagraphs(section.defaultParagraphs);
    addParagraphs(section.dynamicPhrases);
    addParagraphs(section.remarks);
    addParagraphs(section.otherConsiderations ?? []);

    return paragraphs.join('\n\n');
  }

  private isConditionRatingField(fieldKey: string): boolean {
    const key = fieldKey.toLowerCase();
    return key.includes('condition') && key.includes('rating');
  }

  private isLimitationField(fieldKeyLower: string): boolean {
    return fieldKeyLower.includes('limitation');
  }

  private isRemarkField(fieldKeyLower: string): boolean {
    return (
      fieldKeyLower.includes('remark') ||
      fieldKeyLower.includes('note') ||
      fieldKeyLower.includes('comment')
    );
  }

  private shouldMergeWithOpenGroup(
    paragraph: ReportAstParagraph,
    dynamicPhrases: ReportAstParagraph[],
  ): boolean {
    if (dynamicPhrases.length === 0) return false;
    const last = dynamicPhrases[dynamicPhrases.length - 1];
    return !!paragraph.groupKey && paragraph.groupKey === last.groupKey;
  }

  private resolveSectionEGroupKey(fieldKeyLower: string): string | undefined {
    if (fieldKeyLower.includes('wall')) return 'section-e:walls';
    if (fieldKeyLower.includes('window')) return 'section-e:windows';
    if (fieldKeyLower.includes('door')) return 'section-e:doors';
    return undefined;
  }

  private resolveObservedDefectRepairDecision(
    answers: Record<string, string>,
  ): boolean | undefined {
    for (const [key, value] of Object.entries(answers)) {
      const normalizedKey = key.toLowerCase().replace(/[^a-z0-9]/g, '');
      const normalizedValue = (value ?? '').toLowerCase().trim();

      const looksLikeRepairFlag =
        (normalizedKey.includes('observed') &&
          normalizedKey.includes('defect') &&
          normalizedKey.includes('repair')) ||
        normalizedKey.includes('requirerepair') ||
        normalizedKey.includes('defectrepair');

      if (!looksLikeRepairFlag) continue;

      if (normalizedValue === 'no' || normalizedValue === 'false') return false;
      if (normalizedValue === 'yes' || normalizedValue === 'true') return true;
    }

    return undefined;
  }

  private applyNoRepairSentencePolicy(
    phrase: string,
    repairDecision: boolean | undefined,
  ): string {
    const token = EnhancedReportService.NO_REPAIR_SENTENCE;
    const hadToken = phrase.toLowerCase().includes(token.toLowerCase());
    const stripped = phrase
      .replace(/No repair is currently needed\.?/gi, '')
      .replace(/\s{2,}/g, ' ')
      .replace(/\s+\./g, '.')
      .trim();

    if (hadToken && repairDecision === false) {
      return `${stripped} ${token}`.trim();
    }

    return stripped;
  }

  private isSectionE(section: EnrichedSectionData): boolean {
    const title = section.title.toLowerCase();
    const type = section.sectionType.toLowerCase();
    return title.startsWith('e ') || title.includes('outside property') || type.includes('exterior');
  }

  private isSectionF(section: ReportSectionAst): boolean {
    const title = section.title.toLowerCase();
    const type = section.sectionType.toLowerCase();
    return title.startsWith('f ') || title.includes('inside property') || type.includes('interior');
  }

  private applySectionFDefaults(
    section: ReportSectionAst,
    answers: Record<string, string>,
  ): void {
    if (!this.isSectionF(section)) return;

    if (section.limitations.length > 0) {
      section.defaultParagraphs.push({
        id: `${section.sectionId}:default:inspection-limitations`,
        text: EnhancedReportService.INSPECTION_LIMITATIONS_DEFAULT_TEXT,
        source: 'rule',
        tags: ['inspection-limitations'],
      });
    }

    const hasMoistureSignal =
      Object.keys(answers).some((k) => {
        const key = k.toLowerCase();
        return key.includes('moisture') || key.includes('damp');
      }) ||
      section.dynamicPhrases.some((p) => {
        const text = p.text.toLowerCase();
        return text.includes('moisture') || text.includes('damp');
      });

    if (hasMoistureSignal) {
      section.defaultParagraphs.push({
        id: `${section.sectionId}:default:moisture-dampness`,
        text: EnhancedReportService.MOISTURE_DAMPNESS_DEFAULT_TEXT,
        source: 'rule',
        tags: ['moisture-dampness'],
      });
    }
  }

  private injectFlatLeaseholdAssumptionIfNeeded(
    sections: ReportSectionAst[],
    propertyType?: string,
  ): void {
    if (!propertyType || !propertyType.toLowerCase().includes('flat')) {
      return;
    }

    const assumptionText = EnhancedReportService.LEASEHOLD_ASSUMPTION_TEXT;
    const targetSection = sections.find((s) => {
      const t = s.title.toLowerCase();
      const st = s.sectionType.toLowerCase();
      return t.includes('assumption') || st.includes('assumption') || t.startsWith('k ');
    });

    if (targetSection) {
      const alreadyPresent = targetSection.defaultParagraphs.some(
        (p) => p.text.toLowerCase() === assumptionText.toLowerCase(),
      );
      if (!alreadyPresent) {
        targetSection.defaultParagraphs.push({
          id: `${targetSection.sectionId}:default:leasehold-assumption`,
          text: assumptionText,
          source: 'rule',
          tags: ['leasehold', 'flat'],
        });
      }
    }

    const otherConsiderationsSection = sections.find((s) =>
      s.title.toLowerCase().includes('other considerations'),
    );
    if (otherConsiderationsSection) {
      const existing = otherConsiderationsSection.otherConsiderations ?? [];
      const alreadyPresent = existing.some(
        (p) => p.text.toLowerCase() === assumptionText.toLowerCase(),
      );
      if (!alreadyPresent) {
        otherConsiderationsSection.otherConsiderations = [
          ...existing,
          {
            id: `${otherConsiderationsSection.sectionId}:default:leasehold-assumption`,
            text: assumptionText,
            source: 'rule',
            tags: ['leasehold', 'flat'],
          },
        ];
      }
    }
  }

  /**
   * Get fields that still need AI generation
   * Returns sections filtered to only include fields without Excel phrases
   */
  getSectionsNeedingAI(enrichedSections: EnrichedSectionData[]): SectionAnswersDto[] {
    const sectionsForAI: SectionAnswersDto[] = [];

    for (const section of enrichedSections) {
      // Get only answers that don't have Excel phrases
      const answersNeedingAI: Record<string, string> = {};

      for (const narrative of section.narratives) {
        if (narrative.source === 'ai-needed') {
          answersNeedingAI[narrative.fieldKey] = narrative.optionValue;
        }
      }

      // Only include section if it has fields needing AI
      if (Object.keys(answersNeedingAI).length > 0) {
        sectionsForAI.push({
          sectionId: section.sectionId,
          sectionType: section.sectionType,
          title: section.title,
          answers: answersNeedingAI,
        });
      }
    }

    return sectionsForAI;
  }

  /**
   * Merge Excel phrases with AI-generated narratives
   */
  mergeExcelAndAiNarratives(
    enrichedSections: EnrichedSectionData[],
    aiNarratives: Array<{ sectionId: string; narrative: string }>,
  ): string {
    const mergedSections: string[] = [];

    for (const section of enrichedSections) {
      const sectionParts: string[] = [];

      // Add Excel phrases
      const excelPhrases = section.narratives
        .filter(n => n.source === 'excel' && n.phrase)
        .map(n => n.phrase);

      if (excelPhrases.length > 0) {
        sectionParts.push(excelPhrases.join('\n\n'));
      }

      // Add AI narrative for this section (if any)
      const aiNarrative = aiNarratives.find(n => n.sectionId === section.sectionId);
      if (aiNarrative && aiNarrative.narrative) {
        sectionParts.push(aiNarrative.narrative);
      }

      if (sectionParts.length > 0) {
        mergedSections.push(
          `## ${section.title}\n\n${sectionParts.join('\n\n')}`,
        );
      }
    }

    return mergedSections.join('\n\n---\n\n');
  }
}
