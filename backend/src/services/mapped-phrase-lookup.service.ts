/**
 * Mapped Phrase Lookup Service
 * Uses manual field mapping to get Excel phrases
 * 100% Excel phrases - NO AI FALLBACK
 */
import phraseLibrary from '../../excel-phrase-library.json';
import fieldMapping from '../../field-mapping-config.json';

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

interface FieldMapping {
  excelField: string | null;
  options: Record<string, string | null>;
  notes?: string;
}

export interface MappedPhraseResult {
  found: boolean;
  phrase?: string;
  appFieldKey: string;
  appOptionValue: string;
  excelFieldKey?: string;
  excelOptionValue?: string;
  error?: string;
}

export class MappedPhraseLookupService {
  private static readonly library = phraseLibrary as PhraseLibrary;
  private static readonly mappings = fieldMapping as any as Record<string, FieldMapping>;

  /**
   * Get phrase using manual field mapping
   * Returns ONLY Excel phrases - no AI fallback!
   */
  static getPhrase(appFieldKey: string, appOptionValue: string): MappedPhraseResult {
    // Check if field has a mapping
    const mapping = this.mappings[appFieldKey];

    if (!mapping) {
      return {
        found: false,
        appFieldKey,
        appOptionValue,
        error: `No mapping configured for field: ${appFieldKey}`,
      };
    }

    // Check if mapping specifies null (field not supported)
    if (!mapping.excelField) {
      return {
        found: false,
        appFieldKey,
        appOptionValue,
        error: `Field ${appFieldKey} is not mapped to any Excel field`,
      };
    }

    // Get Excel field
    const excelField = this.library[mapping.excelField];
    if (!excelField) {
      return {
        found: false,
        appFieldKey,
        appOptionValue,
        excelFieldKey: mapping.excelField,
        error: `Excel field "${mapping.excelField}" not found in library`,
      };
    }

    // Map app option to Excel option
    const excelOptionValue = mapping.options[appOptionValue];

    if (!excelOptionValue) {
      return {
        found: false,
        appFieldKey,
        appOptionValue,
        excelFieldKey: mapping.excelField,
        error: `Option "${appOptionValue}" is not mapped to any Excel option`,
      };
    }

    // Get Excel phrase
    const excelOption = excelField.options[excelOptionValue];

    if (!excelOption) {
      return {
        found: false,
        appFieldKey,
        appOptionValue,
        excelFieldKey: mapping.excelField,
        excelOptionValue,
        error: `Excel option "${excelOptionValue}" not found in field "${mapping.excelField}"`,
      };
    }

    // Success!
    return {
      found: true,
      phrase: excelOption.phrase,
      appFieldKey,
      appOptionValue,
      excelFieldKey: mapping.excelField,
      excelOptionValue,
    };
  }

  /**
   * Get phrases for multiple fields
   */
  static getPhrases(fieldValues: Record<string, string>): Record<string, MappedPhraseResult> {
    const results: Record<string, MappedPhraseResult> = {};

    for (const [fieldKey, optionValue] of Object.entries(fieldValues)) {
      results[fieldKey] = this.getPhrase(fieldKey, optionValue);
    }

    return results;
  }

  /**
   * Validate that ALL required fields have mappings
   */
  static validateMappings(requiredFields: string[]): {
    valid: boolean;
    errors: string[];
    coverage: number;
  } {
    const errors: string[] = [];
    let mappedCount = 0;

    for (const fieldKey of requiredFields) {
      const mapping = this.mappings[fieldKey];

      if (!mapping) {
        errors.push(`Missing mapping for field: ${fieldKey}`);
      } else if (!mapping.excelField) {
        errors.push(`Field ${fieldKey} is mapped to null (not supported)`);
      } else {
        mappedCount++;
      }
    }

    return {
      valid: errors.length === 0,
      errors,
      coverage: requiredFields.length > 0
        ? Math.round((mappedCount / requiredFields.length) * 100)
        : 0,
    };
  }

  /**
   * List all app fields that have mappings
   */
  static getMappedFields(): string[] {
    return Object.keys(this.mappings).filter(
      key => !key.startsWith('_') && this.mappings[key].excelField !== null
    );
  }

  /**
   * Get mapping info for a field
   */
  static getMappingInfo(appFieldKey: string): FieldMapping | null {
    return this.mappings[appFieldKey] || null;
  }
}
