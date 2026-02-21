/**
 * Enhanced Report Service
 * Integrates Excel phrase generation with AI report generation
 * Uses hardcoded professional phrases with template substitution when available, AI as fallback
 */
import { Injectable, Logger } from '@nestjs/common';
import { ExcelPhraseGeneratorService } from './excel-phrase-generator.service';
import { SectionAnswersDto } from '../modules/ai/dto/ai-report.dto';

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

@Injectable()
export class EnhancedReportService {
  private readonly logger = new Logger(EnhancedReportService.name);

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
  buildReportWithExcelPhrases(enrichedSections: EnrichedSectionData[]): {
    sectionsWithPhrases: Array<{
      sectionId: string;
      sectionType: string;
      title: string;
      narrative: string;
      source: 'excel' | 'mixed' | 'ai-needed';
      usedExcelPhrases: number;
      totalPhrases: number;
    }>;
    stats: {
      totalSections: number;
      totalFields: number;
      excelPhraseCount: number;
      aiNeededCount: number;
      coveragePercent: number;
    };
  } {
    const sectionsWithPhrases = [];
    let totalFields = 0;
    let totalExcelPhrases = 0;
    let totalAiNeeded = 0;

    for (const section of enrichedSections) {
      // Combine Excel phrases into a narrative
      const excelNarratives = section.narratives
        .filter(n => n.source === 'excel' && n.phrase)
        .map(n => n.phrase);

      const narrative = excelNarratives.join('\n\n');

      // Determine source
      let source: 'excel' | 'mixed' | 'ai-needed';
      if (section.excelPhraseCount === section.totalFields) {
        source = 'excel'; // All phrases from Excel
      } else if (section.excelPhraseCount > 0) {
        source = 'mixed'; // Some Excel, some need AI
      } else {
        source = 'ai-needed'; // All need AI
      }

      sectionsWithPhrases.push({
        sectionId: section.sectionId,
        sectionType: section.sectionType,
        title: section.title,
        narrative,
        source,
        usedExcelPhrases: section.excelPhraseCount,
        totalPhrases: section.totalFields,
      });

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

    return {
      sectionsWithPhrases,
      stats: {
        totalSections: enrichedSections.length,
        totalFields,
        excelPhraseCount: totalExcelPhrases,
        aiNeededCount: totalAiNeeded,
        coveragePercent,
      },
    };
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
