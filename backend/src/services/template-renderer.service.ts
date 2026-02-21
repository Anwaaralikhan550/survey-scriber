/**
 * Template Renderer Service
 * Fills in Excel phrase templates with form values
 * Example: "The property is a (detached/semi-detached) house" + formData
 *       → "The property is a detached house"
 */

import { TemplateParserService, ParsedTemplate } from './template-parser.service';
import { TemplateMatcherService, MatchResult } from './template-matcher.service';

export interface RenderResult {
  success: boolean;
  renderedText: string;
  originalTemplate: string;
  substitutions: {
    placeholder: string;
    replacedWith: string;
    confidence: number;
  }[];
  unmatchedPlaceholders: string[];
}

export class TemplateRendererService {
  /**
   * Render template with form data
   * @param template - Excel phrase template
   * @param formData - Object with field key → value
   */
  static render(
    template: string,
    formData: Record<string, any>,
  ): RenderResult {
    const parsed = TemplateParserService.parseTemplate(template);

    if (!parsed.hasPlaceholders) {
      // No placeholders, return as-is
      return {
        success: true,
        renderedText: template,
        originalTemplate: template,
        substitutions: [],
        unmatchedPlaceholders: [],
      };
    }

    return this.renderWithPlaceholders(parsed, formData);
  }

  /**
   * Render template with placeholders
   */
  private static renderWithPlaceholders(
    parsed: ParsedTemplate,
    formData: Record<string, any>,
  ): RenderResult {
    let renderedText = parsed.originalTemplate;
    const substitutions: RenderResult['substitutions'] = [];
    const unmatchedPlaceholders: string[] = [];

    // Get all form values as array
    const formValues = Object.values(formData)
      .filter(v => v !== null && v !== undefined)
      .map(v => String(v));

    // Process placeholders in reverse order (to maintain string indices)
    const placeholdersReverse = [...parsed.placeholders].reverse();

    for (const placeholder of placeholdersReverse) {
      // Try to match placeholder with form values
      const matchResult = TemplateMatcherService.matchMultipleValues(
        formValues,
        placeholder.options,
      );

      if (matchResult.matched && matchResult.matchedOption) {
        // Replace placeholder with matched value
        renderedText =
          renderedText.substring(0, placeholder.startIndex) +
          matchResult.matchedOption +
          renderedText.substring(placeholder.endIndex);

        substitutions.push({
          placeholder: placeholder.fullMatch,
          replacedWith: matchResult.matchedOption,
          confidence: matchResult.confidence,
        });
      } else {
        // Could not match - keep first option as default
        const defaultOption = placeholder.options[0] || '';

        renderedText =
          renderedText.substring(0, placeholder.startIndex) +
          defaultOption +
          renderedText.substring(placeholder.endIndex);

        unmatchedPlaceholders.push(placeholder.fullMatch);

        substitutions.push({
          placeholder: placeholder.fullMatch,
          replacedWith: defaultOption,
          confidence: 0,
        });
      }
    }

    return {
      success: unmatchedPlaceholders.length === 0,
      renderedText,
      originalTemplate: parsed.originalTemplate,
      substitutions,
      unmatchedPlaceholders,
    };
  }

  /**
   * Render template with explicit placeholder values
   * @param template - Template string
   * @param placeholderValues - Map of placeholder → value
   */
  static renderWithMapping(
    template: string,
    placeholderValues: Record<string, string>,
  ): RenderResult {
    const parsed = TemplateParserService.parseTemplate(template);

    if (!parsed.hasPlaceholders) {
      return {
        success: true,
        renderedText: template,
        originalTemplate: template,
        substitutions: [],
        unmatchedPlaceholders: [],
      };
    }

    let renderedText = parsed.originalTemplate;
    const substitutions: RenderResult['substitutions'] = [];
    const unmatchedPlaceholders: string[] = [];

    // Process in reverse to maintain indices
    const placeholdersReverse = [...parsed.placeholders].reverse();

    for (const placeholder of placeholdersReverse) {
      const replacement = placeholderValues[placeholder.fullMatch];

      if (replacement) {
        renderedText =
          renderedText.substring(0, placeholder.startIndex) +
          replacement +
          renderedText.substring(placeholder.endIndex);

        substitutions.push({
          placeholder: placeholder.fullMatch,
          replacedWith: replacement,
          confidence: 1.0,
        });
      } else {
        // Use first option as default
        const defaultOption = placeholder.options[0] || '';

        renderedText =
          renderedText.substring(0, placeholder.startIndex) +
          defaultOption +
          renderedText.substring(placeholder.endIndex);

        unmatchedPlaceholders.push(placeholder.fullMatch);

        substitutions.push({
          placeholder: placeholder.fullMatch,
          replacedWith: defaultOption,
          confidence: 0,
        });
      }
    }

    return {
      success: unmatchedPlaceholders.length === 0,
      renderedText,
      originalTemplate: parsed.originalTemplate,
      substitutions,
      unmatchedPlaceholders,
    };
  }

  /**
   * Clean up rendered text (remove double spaces, etc.)
   */
  static cleanText(text: string): string {
    return text
      .replace(/\s+/g, ' ') // Multiple spaces → single space
      .replace(/\s+\./g, '.') // Space before period
      .replace(/\s+,/g, ',') // Space before comma
      .trim();
  }
}
