/**
 * Excel Phrase Generator Service
 * Main service that generates final phrases from Excel templates + form data
 * This is what the report generation will use!
 */

import { Injectable, Logger } from '@nestjs/common';
import phraseLibrary from '../../excel-phrase-library.json';
import { TemplateRendererService, RenderResult } from './template-renderer.service';

interface PhraseField {
  excelFieldName: string;
  displayName: string;
  row: number;
  options: Record<string, { value: string; phrase: string; phraseLength: number }>;
}

type PhraseLibrary = Record<string, PhraseField>;

export interface GeneratedPhrase {
  success: boolean;
  phrase: string;
  excelField: string;
  excelOption: string;
  templateUsed: string;
  substitutions: RenderResult['substitutions'];
  confidence: number;
  error?: string;
}

@Injectable()
export class ExcelPhraseGeneratorService {
  private readonly logger = new Logger(ExcelPhraseGeneratorService.name);
  private readonly library = phraseLibrary as PhraseLibrary;

  /**
   * Generate phrase from Excel template
   * @param excelFieldKey - Excel field key (e.g., 'property_type')
   * @param excelOptionValue - Excel option value (e.g., 'House')
   * @param formData - All form data for template substitution
   */
  generatePhrase(
    excelFieldKey: string,
    excelOptionValue: string,
    formData: Record<string, any>,
  ): GeneratedPhrase {
    // Get Excel field
    const excelField = this.library[excelFieldKey];

    if (!excelField) {
      return {
        success: false,
        phrase: '',
        excelField: excelFieldKey,
        excelOption: excelOptionValue,
        templateUsed: '',
        substitutions: [],
        confidence: 0,
        error: `Excel field "${excelFieldKey}" not found`,
      };
    }

    // Get Excel option
    const excelPhraseData = excelField.options[excelOptionValue];

    if (!excelPhraseData) {
      return {
        success: false,
        phrase: '',
        excelField: excelFieldKey,
        excelOption: excelOptionValue,
        templateUsed: '',
        substitutions: [],
        confidence: 0,
        error: `Excel option "${excelOptionValue}" not found in field "${excelFieldKey}"`,
      };
    }

    // Get template
    const template = excelPhraseData.phrase;

    // Render template with form data
    const renderResult = TemplateRendererService.render(template, formData);

    // Clean up text
    const finalPhrase = TemplateRendererService.cleanText(renderResult.renderedText);

    // Calculate average confidence
    const avgConfidence = renderResult.substitutions.length > 0
      ? renderResult.substitutions.reduce((sum, s) => sum + s.confidence, 0) /
        renderResult.substitutions.length
      : 1.0;

    this.logger.debug(
      `Generated phrase for ${excelFieldKey}.${excelOptionValue}: ` +
      `${renderResult.substitutions.length} substitutions, ` +
      `confidence: ${(avgConfidence * 100).toFixed(0)}%`,
    );

    return {
      success: renderResult.success,
      phrase: finalPhrase,
      excelField: excelFieldKey,
      excelOption: excelOptionValue,
      templateUsed: template,
      substitutions: renderResult.substitutions,
      confidence: avgConfidence,
    };
  }

  /**
   * Generate phrases for multiple fields
   */
  generatePhrases(
    fieldMappings: Array<{ excelField: string; excelOption: string }>,
    formData: Record<string, any>,
  ): GeneratedPhrase[] {
    return fieldMappings.map(mapping =>
      this.generatePhrase(mapping.excelField, mapping.excelOption, formData)
    );
  }

  /**
   * Generate phrase for a section (combines multiple field phrases)
   */
  generateSectionNarrative(
    sectionFieldMappings: Array<{ excelField: string; excelOption: string }>,
    formData: Record<string, any>,
  ): {
    narrative: string;
    phrases: GeneratedPhrase[];
    successRate: number;
  } {
    const phrases = this.generatePhrases(sectionFieldMappings, formData);

    // Combine successful phrases
    const successfulPhrases = phrases
      .filter(p => p.success)
      .map(p => p.phrase);

    const narrative = successfulPhrases.join('\n\n');
    const successRate = phrases.length > 0
      ? phrases.filter(p => p.success).length / phrases.length
      : 0;

    return {
      narrative,
      phrases,
      successRate,
    };
  }

  /**
   * Get all available Excel fields
   */
  getAvailableFields(): string[] {
    return Object.keys(this.library);
  }

  /**
   * Get field options
   */
  getFieldOptions(excelFieldKey: string): string[] | null {
    const field = this.library[excelFieldKey];
    return field ? Object.keys(field.options) : null;
  }

  /**
   * Preview template without rendering
   */
  previewTemplate(excelFieldKey: string, excelOptionValue: string): string | null {
    const field = this.library[excelFieldKey];
    if (!field) return null;

    const option = field.options[excelOptionValue];
    return option ? option.phrase : null;
  }
}
