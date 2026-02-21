/**
 * Template Matcher Service
 * Matches form values to template placeholder options
 * Example: "Detached House" matches "(detached/semi-detached)" → "detached"
 */

export interface MatchResult {
  matched: boolean;
  matchedOption: string | null;
  confidence: number; // 0-1
  formValue: string;
}

export class TemplateMatcherService {
  /**
   * Match a form value to one of the placeholder options
   */
  static matchValue(
    formValue: string,
    placeholderOptions: string[],
  ): MatchResult {
    if (!formValue || placeholderOptions.length === 0) {
      return {
        matched: false,
        matchedOption: null,
        confidence: 0,
        formValue,
      };
    }

    const normalized = this.normalize(formValue);

    // Try exact match first
    for (const option of placeholderOptions) {
      if (this.normalize(option) === normalized) {
        return {
          matched: true,
          matchedOption: option,
          confidence: 1.0,
          formValue,
        };
      }
    }

    // Try partial match
    for (const option of placeholderOptions) {
      const normalizedOption = this.normalize(option);

      // Check if form value contains option
      if (normalized.includes(normalizedOption)) {
        return {
          matched: true,
          matchedOption: option,
          confidence: 0.8,
          formValue,
        };
      }

      // Check if option contains form value
      if (normalizedOption.includes(normalized)) {
        return {
          matched: true,
          matchedOption: option,
          confidence: 0.7,
          formValue,
        };
      }
    }

    // Try fuzzy match (edit distance)
    let bestMatch: string | null = null;
    let bestScore = 0;

    for (const option of placeholderOptions) {
      const score = this.fuzzyMatch(normalized, this.normalize(option));
      if (score > bestScore && score > 0.5) {
        bestScore = score;
        bestMatch = option;
      }
    }

    if (bestMatch) {
      return {
        matched: true,
        matchedOption: bestMatch,
        confidence: bestScore,
        formValue,
      };
    }

    // No match found
    return {
      matched: false,
      matchedOption: null,
      confidence: 0,
      formValue,
    };
  }

  /**
   * Match multiple form values to placeholders
   * Returns the best match from all values
   */
  static matchMultipleValues(
    formValues: string[],
    placeholderOptions: string[],
  ): MatchResult {
    let bestResult: MatchResult = {
      matched: false,
      matchedOption: null,
      confidence: 0,
      formValue: '',
    };

    for (const value of formValues) {
      const result = this.matchValue(value, placeholderOptions);
      if (result.confidence > bestResult.confidence) {
        bestResult = result;
      }
    }

    return bestResult;
  }

  /**
   * Normalize string for matching
   */
  private static normalize(str: string): string {
    return str
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '')
      .trim();
  }

  /**
   * Fuzzy match using similarity score
   */
  private static fuzzyMatch(str1: string, str2: string): number {
    if (str1 === str2) return 1.0;

    const longer = str1.length > str2.length ? str1 : str2;
    const shorter = str1.length > str2.length ? str2 : str1;

    if (longer.length === 0) return 1.0;

    // Count matching characters
    let matches = 0;
    for (const char of shorter) {
      if (longer.includes(char)) matches++;
    }

    return matches / longer.length;
  }

  /**
   * Extract relevant keywords from form value
   * Example: "Detached House" → ["detached", "house"]
   */
  static extractKeywords(formValue: string): string[] {
    return formValue
      .toLowerCase()
      .split(/[\s/-]+/)
      .filter(word => word.length > 2) // Skip short words
      .filter(word => !this.isCommonWord(word));
  }

  /**
   * Check if word is too common to be useful
   */
  private static isCommonWord(word: string): boolean {
    const commonWords = [
      'the', 'and', 'or', 'with', 'for', 'in', 'on', 'at',
      'type', 'level', 'number', 'status',
    ];
    return commonWords.includes(word.toLowerCase());
  }
}
