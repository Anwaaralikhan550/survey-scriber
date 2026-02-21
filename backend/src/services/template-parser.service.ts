/**
 * Template Parser Service
 * Parses Excel phrase templates and extracts placeholders
 * Example: "The property is a (detached/semi-detached/other) house"
 * Extracts: [(detached, semi-detached, other)]
 */

export interface Placeholder {
  fullMatch: string;           // "(detached/semi-detached/other)"
  options: string[];           // ["detached", "semi-detached", "other"]
  startIndex: number;          // Position in template
  endIndex: number;            // End position
}

export interface ParsedTemplate {
  originalTemplate: string;
  placeholders: Placeholder[];
  hasPlaceholders: boolean;
}

export class TemplateParserService {
  /**
   * Parse template and extract all placeholders
   */
  static parseTemplate(template: string): ParsedTemplate {
    const placeholders: Placeholder[] = [];

    // Regex to match (option1/option2/option3) patterns
    const placeholderRegex = /\(([^)]+)\)/g;
    let match;

    while ((match = placeholderRegex.exec(template)) !== null) {
      const fullMatch = match[0]; // "(detached/semi-detached/other)"
      const optionsString = match[1]; // "detached/semi-detached/other"

      // Split by / to get individual options
      const options = optionsString
        .split('/')
        .map(opt => opt.trim())
        .filter(opt => opt.length > 0);

      // Only consider it a placeholder if it has multiple options or looks like a choice
      if (options.length > 1 || this.looksLikeChoice(optionsString)) {
        placeholders.push({
          fullMatch,
          options,
          startIndex: match.index,
          endIndex: match.index + fullMatch.length,
        });
      }
    }

    return {
      originalTemplate: template,
      placeholders,
      hasPlaceholders: placeholders.length > 0,
    };
  }

  /**
   * Check if a string looks like a choice placeholder
   */
  private static looksLikeChoice(str: string): boolean {
    // Contains slash = likely a choice
    if (str.includes('/')) return true;

    // Common choice patterns
    const choicePatterns = [
      /one|two|three|four|five/i,
      /yes|no/i,
      /good|fair|poor/i,
      /low|medium|high/i,
      /front|side|rear|back/i,
    ];

    return choicePatterns.some(pattern => pattern.test(str));
  }

  /**
   * Extract all unique placeholder options from a template
   */
  static extractAllOptions(template: string): string[] {
    const parsed = this.parseTemplate(template);
    const allOptions = new Set<string>();

    for (const placeholder of parsed.placeholders) {
      placeholder.options.forEach(opt => allOptions.add(opt));
    }

    return Array.from(allOptions);
  }

  /**
   * Check if template has specific placeholder
   */
  static hasPlaceholder(template: string, searchTerm: string): boolean {
    const parsed = this.parseTemplate(template);

    return parsed.placeholders.some(ph =>
      ph.options.some(opt =>
        opt.toLowerCase().includes(searchTerm.toLowerCase())
      )
    );
  }
}
