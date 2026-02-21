/**
 * Phrase Lookup API Routes
 * Provides endpoints to get hardcoded Excel phrases for report generation
 */
import { Router, Request, Response } from 'express';
import { PhraseLookupService } from '../services/phrase-lookup.service';

const router = Router();

/**
 * GET /api/phrases/fields
 * List all available fields with phrase mappings
 */
router.get('/fields', (req: Request, res: Response) => {
  try {
    const fields = PhraseLookupService.listAllFields();

    const fieldsWithMetadata = fields.map(fieldKey => {
      const metadata = PhraseLookupService.getFieldMetadata(fieldKey);
      return {
        fieldKey,
        ...metadata,
      };
    });

    res.json({
      success: true,
      totalFields: fieldsWithMetadata.length,
      fields: fieldsWithMetadata,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to list fields',
      message: error.message,
    });
  }
});

/**
 * GET /api/phrases/field/:fieldKey
 * Get all options and phrases for a specific field
 */
router.get('/field/:fieldKey', (req: Request, res: Response) => {
  try {
    const { fieldKey } = req.params;

    const metadata = PhraseLookupService.getFieldMetadata(fieldKey);
    if (!metadata) {
      return res.status(404).json({
        success: false,
        error: 'Field not found',
        fieldKey,
      });
    }

    const options = PhraseLookupService.getFieldOptions(fieldKey);

    // Get phrases for each option
    const phrasesMap: Record<string, string> = {};
    options?.forEach(option => {
      const result = PhraseLookupService.getPhrase(fieldKey, option);
      if (result.found && result.phrase) {
        phrasesMap[option] = result.phrase;
      }
    });

    res.json({
      success: true,
      ...metadata,
      options: options || [],
      phrases: phrasesMap,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to get field options',
      message: error.message,
    });
  }
});

/**
 * GET /api/phrases/:fieldKey/:optionValue
 * Get specific phrase for a field option
 */
router.get('/:fieldKey/:optionValue', (req: Request, res: Response) => {
  try {
    const { fieldKey, optionValue } = req.params;

    const result = PhraseLookupService.getPhrase(fieldKey, optionValue);

    if (!result.found) {
      return res.status(404).json({
        success: false,
        error: 'Phrase not found',
        fieldKey: result.fieldKey,
        optionValue: result.optionValue,
        suggestion: 'Check available options with GET /api/phrases/field/:fieldKey',
      });
    }

    res.json({
      success: true,
      ...result,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to get phrase',
      message: error.message,
    });
  }
});

/**
 * POST /api/phrases/batch
 * Get phrases for multiple field values at once
 * Body: { "party_disclosures": "None", "weather": "Now / Before", ... }
 */
router.post('/batch', (req: Request, res: Response) => {
  try {
    const fieldValues = req.body;

    if (!fieldValues || typeof fieldValues !== 'object') {
      return res.status(400).json({
        success: false,
        error: 'Invalid request body',
        expected: 'Object with field keys and option values',
      });
    }

    const results = PhraseLookupService.getPhrases(fieldValues);

    // Separate found and not found
    const found: Record<string, string> = {};
    const notFound: Record<string, { fieldKey: string; optionValue: string }> = {};

    for (const [key, result] of Object.entries(results)) {
      if (result.found && result.phrase) {
        found[key] = result.phrase;
      } else {
        notFound[key] = {
          fieldKey: result.fieldKey,
          optionValue: result.optionValue,
        };
      }
    }

    res.json({
      success: true,
      totalRequested: Object.keys(fieldValues).length,
      foundCount: Object.keys(found).length,
      notFoundCount: Object.keys(notFound).length,
      phrases: found,
      notFound: Object.keys(notFound).length > 0 ? notFound : undefined,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to get phrases',
      message: error.message,
    });
  }
});

export default router;
