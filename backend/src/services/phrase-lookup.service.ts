/**
 * Phrase Lookup Service
 * Returns hardcoded professional phrases from Excel database
 * instead of generating them with AI
 */
import phraseLibrary from '../../excel-phrase-library.json';

export interface PhraseResult {
  found: boolean;
  phrase?: string;
  fieldKey: string;
  optionValue: string;
}

interface PhraseOption {
  value: string;
  phrase: string;
  phraseLength: number;
}

interface PhraseField {
  excelFieldName: string;
  displayName: string;
  row: number;
  options: Record<string, PhraseOption>;
}

type PhraseLibrary = Record<string, PhraseField>;

export class PhraseLookupService {
  private static readonly library = phraseLibrary as PhraseLibrary;

  /**
   * Get the professional phrase for a field option
   * @param fieldKey - The field key (e.g., 'party_disclosures', 'weather')
   * @param optionValue - The selected option value (e.g., 'None', 'Conflict')
   * @returns The professional phrase or null if not found
   */
  static getPhrase(fieldKey: string, optionValue: string): PhraseResult {
    const normalizedKey = this.normalizeKey(fieldKey);
    const field = this.library[normalizedKey];

    if (!field) {
      return {
        found: false,
        fieldKey: normalizedKey,
        optionValue,
      };
    }

    // Try exact match first
    if (field.options[optionValue]) {
      return {
        found: true,
        phrase: field.options[optionValue].phrase,
        fieldKey: normalizedKey,
        optionValue,
      };
    }

    // Try case-insensitive match
    const normalizedOption = optionValue.toLowerCase();
    for (const [key, value] of Object.entries(field.options)) {
      if (key.toLowerCase() === normalizedOption) {
        return {
          found: true,
          phrase: value.phrase,
          fieldKey: normalizedKey,
          optionValue: key,
        };
      }
    }

    return {
      found: false,
      fieldKey: normalizedKey,
      optionValue,
    };
  }

  /**
   * Get phrases for multiple field values at once
   */
  static getPhrases(fieldValues: Record<string, string>): Record<string, PhraseResult> {
    const results: Record<string, PhraseResult> = {};

    for (const [fieldKey, optionValue] of Object.entries(fieldValues)) {
      results[fieldKey] = this.getPhrase(fieldKey, optionValue);
    }

    return results;
  }

  /**
   * Get all available options for a field
   */
  static getFieldOptions(fieldKey: string): string[] | null {
    const normalizedKey = this.normalizeKey(fieldKey);
    const field = this.library[normalizedKey];

    if (!field) return null;

    return Object.keys(field.options);
  }

  /**
   * Get field metadata
   */
  static getFieldMetadata(fieldKey: string) {
    const normalizedKey = this.normalizeKey(fieldKey);
    const field = this.library[normalizedKey];

    if (!field) return null;

    return {
      fieldKey: normalizedKey,
      displayName: field.displayName,
      excelFieldName: field.excelFieldName,
      excelRow: field.row,
      optionCount: Object.keys(field.options).length,
    };
  }

  /**
   * Check if a field exists in the phrase library
   */
  static hasField(fieldKey: string): boolean {
    const normalizedKey = this.normalizeKey(fieldKey);
    return !!this.library[normalizedKey];
  }

  /**
   * List all available fields
   */
  static listAllFields(): string[] {
    return Object.keys(this.library);
  }

  /**
   * Normalize field key (convert to lowercase, replace spaces with underscores)
   */
  private static normalizeKey(key: string): string {
    return key
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '');
  }
}

// Example usage:
/*
const result = PhraseLookupService.getPhrase('party_disclosures', 'None');
if (result.found) {
  console.log(result.phrase);
  // Output: "I do not know of any conflict of interest issue in this transaction..."
}

// Get multiple phrases
const phrases = PhraseLookupService.getPhrases({
  party_disclosures: 'None',
  weather: 'Now / Before',
  property_type: 'House',
});

// Check available options
const options = PhraseLookupService.getFieldOptions('party_disclosures');
// Output: ['None', 'Conflict']
*/
