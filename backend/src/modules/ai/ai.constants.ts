/**
 * AI Module Constants
 * Contains configuration, disclaimers, and safety rules
 */

export const AI_DISCLAIMERS = {
  REPORT: `IMPORTANT: This AI-generated narrative is a draft intended to assist the surveyor. All content must be reviewed, verified, and approved by a qualified RICS professional before inclusion in any final report. The AI cannot physically inspect properties and may make errors or omissions based on the data provided.`,

  RECOMMENDATIONS: `These recommendations are AI-generated suggestions based on the information provided. They do not constitute professional advice. A qualified specialist should be consulted for definitive diagnosis and repair specifications. Costs and timelines are indicative only.`,

  PHOTO_TAGS: `AI-suggested tags are assistive only. The AI analyzes visual patterns and cannot determine structural integrity, hidden defects, or safety hazards. Verify all tags before use.`,

  RISK_SUMMARY: `This risk summary is AI-generated based on the survey data provided. It is intended as a guide only and does not replace professional judgment. A qualified surveyor must review and validate all risk assessments.`,

  CONSISTENCY_CHECK: `This consistency check is AI-assisted and may not identify all issues. A qualified surveyor must perform final review and validation of all survey data.`,

  DEFECT_DESCRIPTION: `This description is based on visual analysis only and is not a diagnosis. The AI cannot determine structural integrity, hidden defects, or safety hazards. Professional inspection by a qualified specialist is required for any concerns.`,
};

/**
 * Default AI Models - these are fallbacks if env vars not set.
 *
 * IMPORTANT: Model names must match exactly what Gemini API accepts.
 * Current supported models (as of 2025):
 * - gemini-2.5-pro (best quality, slower)
 * - gemini-2.5-flash (faster, good for quick tasks)
 *
 * Legacy models (may be deprecated):
 * - gemini-1.5-pro, gemini-1.5-flash
 *
 * DO NOT use '-latest' suffix - it's not consistently supported.
 * Configure via GEMINI_PRO_MODEL and GEMINI_FLASH_MODEL env vars.
 */
export const AI_MODELS_DEFAULT = {
  PRO: 'gemini-2.5-pro',
  FLASH: 'gemini-2.5-flash',
};

/**
 * Fallback models if primary models are not available
 */
export const AI_MODELS_FALLBACK = {
  PRO: 'gemini-2.0-flash', // Flash can substitute for Pro if needed
  FLASH: 'gemini-2.0-flash',
};

/**
 * Feature to model mapping - uses the model type, actual model name
 * is resolved at runtime from config
 */
export const AI_FEATURE_MODEL_TYPE = {
  REPORT: 'PRO',
  RECOMMENDATIONS: 'PRO',
  PHOTO_TAGS: 'FLASH',
  RISK_SUMMARY: 'FLASH',
  CONSISTENCY_CHECK: 'FLASH',
} as const;

export const AI_TOKEN_LIMITS = {
  REPORT: { input: 8000, output: 16000 },
  RECOMMENDATIONS: { input: 8000, output: 8000 },
  PHOTO_TAGS: { input: 1000, output: 500 },
  RISK_SUMMARY: { input: 6000, output: 8000 },
  CONSISTENCY_CHECK: { input: 4000, output: 1500 },
};

export const AI_CACHE_TTL = {
  REPORT: 24 * 60 * 60 * 1000, // 24 hours
  RECOMMENDATIONS: 24 * 60 * 60 * 1000,
  PHOTO_TAGS: 7 * 24 * 60 * 60 * 1000, // 7 days (photos don't change)
  RISK_SUMMARY: 24 * 60 * 60 * 1000,
  CONSISTENCY_CHECK: 12 * 60 * 60 * 1000, // 12 hours
};

export const AI_RATE_LIMITS = {
  // Requests per minute per user
  USER_RPM: 10,
  // Daily token quota per organization
  ORG_DAILY_TOKENS: 100000,
  // B3 FIX: Daily token quota per user (prevents single user consuming all org quota)
  USER_DAILY_TOKENS: 25000,
};

export const RETRY_CONFIG = {
  maxRetries: 3,
  baseDelayMs: 1000,
  maxDelayMs: 30000,
  exponentialBase: 2,
  retryableStatusCodes: [429, 500, 502, 503, 504],
};

// Section types that should have narratives generated
export const NARRATIVE_SECTION_TYPES = [
  'aboutProperty',
  'externalCondition',
  'internalCondition',
  'services',
  'grounds',
  'issues',
  'summary',
];

// Photo tag categories (limited set for consistency)
export const PHOTO_TAG_CATEGORIES = [
  // Building elements
  'roof', 'chimney', 'guttering', 'fascia', 'soffit',
  'wall', 'brickwork', 'render', 'cladding', 'pointing',
  'window', 'door', 'frame', 'lintel', 'sill',
  'foundation', 'damp_course', 'airbrick', 'vent',

  // Interior elements
  'ceiling', 'floor', 'staircase', 'bathroom', 'kitchen',
  'fireplace', 'radiator', 'boiler', 'electrical', 'plumbing',

  // Defects
  'crack', 'damp', 'mould', 'rot', 'corrosion', 'damage',
  'staining', 'discoloration', 'movement', 'settlement',

  // General
  'front', 'rear', 'side', 'interior', 'exterior',
  'garden', 'boundary', 'outbuilding', 'garage',
];

// Section suggestions based on tags
export const TAG_TO_SECTION_MAP: Record<string, string> = {
  roof: 'externalCondition',
  chimney: 'externalCondition',
  guttering: 'externalCondition',
  wall: 'externalCondition',
  brickwork: 'externalCondition',
  window: 'externalCondition',
  door: 'externalCondition',
  ceiling: 'internalCondition',
  floor: 'internalCondition',
  staircase: 'internalCondition',
  bathroom: 'internalCondition',
  kitchen: 'internalCondition',
  boiler: 'services',
  electrical: 'services',
  plumbing: 'services',
  garden: 'grounds',
  boundary: 'grounds',
  outbuilding: 'grounds',
  crack: 'issues',
  damp: 'issues',
  mould: 'issues',
  rot: 'issues',
  damage: 'issues',
};
