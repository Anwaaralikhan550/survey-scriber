import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AiFeatureType } from '@prisma/client';
import { AI_FEATURE_MODEL_TYPE, AI_MODELS_DEFAULT, AI_TOKEN_LIMITS } from './ai.constants';

export interface PromptTemplate {
  version: string;
  systemPrompt: string;
  userPromptTemplate: string;
  outputSchema?: object;
  model: string;
  maxTokens: number;
  temperature: number;
}

@Injectable()
export class AiPromptService implements OnModuleInit {
  private readonly logger = new Logger(AiPromptService.name);
  private promptCache: Map<AiFeatureType, PromptTemplate> = new Map();

  constructor(private readonly prisma: PrismaService) {}

  async onModuleInit() {
    await this.loadActivePrompts();
  }

  /**
   * Load all active prompts into cache
   */
  private async loadActivePrompts(): Promise<void> {
    try {
      const activePrompts = await this.prisma.aiPromptTemplate.findMany({
        where: { isActive: true },
      });

      for (const prompt of activePrompts) {
        this.promptCache.set(prompt.featureType, {
          version: prompt.version,
          systemPrompt: prompt.systemPrompt,
          userPromptTemplate: prompt.userPromptTemplate,
          outputSchema: prompt.outputSchema as object | undefined,
          model: prompt.model,
          maxTokens: prompt.maxTokens,
          temperature: Number(prompt.temperature),
        });
      }

      this.logger.log(`Loaded ${activePrompts.length} active prompt templates`);

      // Seed default prompts if none exist
      if (activePrompts.length === 0) {
        await this.seedDefaultPrompts();
        await this.loadActivePrompts();
        return;
      }

      // Check if any code-defined prompts have a newer version than the DB.
      // This ensures prompt updates in code are picked up on next deploy.
      const features: AiFeatureType[] = ['REPORT', 'RECOMMENDATIONS', 'PHOTO_TAGS', 'RISK_SUMMARY', 'CONSISTENCY_CHECK'];
      let needsReseed = false;
      for (const feature of features) {
        const codeDefault = this.getDefaultPrompt(feature);
        const dbPrompt = this.promptCache.get(feature);
        if (!dbPrompt || dbPrompt.version !== codeDefault.version) {
          this.logger.log(`Prompt version mismatch for ${feature}: DB=${dbPrompt?.version}, code=${codeDefault.version}`);
          needsReseed = true;
        }
      }

      if (needsReseed) {
        this.logger.log('Re-seeding prompts due to version mismatch...');
        await this.seedDefaultPrompts();
        // Reload from DB after re-seed
        this.promptCache.clear();
        const updatedPrompts = await this.prisma.aiPromptTemplate.findMany({
          where: { isActive: true },
        });
        for (const prompt of updatedPrompts) {
          this.promptCache.set(prompt.featureType, {
            version: prompt.version,
            systemPrompt: prompt.systemPrompt,
            userPromptTemplate: prompt.userPromptTemplate,
            outputSchema: prompt.outputSchema as object | undefined,
            model: prompt.model,
            maxTokens: prompt.maxTokens,
            temperature: Number(prompt.temperature),
          });
        }
        this.logger.log('Prompts re-seeded and reloaded successfully');
      }
    } catch (error) {
      this.logger.error(`Failed to load prompts: ${error}`);
      // Use fallback prompts
      this.seedFallbackPrompts();
    }
  }

  /**
   * Get active prompt for a feature
   */
  getPrompt(featureType: AiFeatureType): PromptTemplate {
    const cached = this.promptCache.get(featureType);
    if (cached) {
      return cached;
    }

    // Return default fallback
    return this.getDefaultPrompt(featureType);
  }

  /**
   * Reload prompts from database (for admin updates)
   */
  async reloadPrompts(): Promise<void> {
    this.promptCache.clear();
    await this.loadActivePrompts();
  }

  /**
   * Get default prompt for a feature (fallback)
   */
  private getDefaultPrompt(featureType: AiFeatureType): PromptTemplate {
    // Resolve model name from feature type mapping
    const getModelForFeature = (feature: keyof typeof AI_FEATURE_MODEL_TYPE): string => {
      const modelType = AI_FEATURE_MODEL_TYPE[feature];
      return AI_MODELS_DEFAULT[modelType];
    };

    const defaults: Record<AiFeatureType, PromptTemplate> = {
      REPORT: {
        version: 'v1.1.0',
        model: getModelForFeature('REPORT'),
        maxTokens: AI_TOKEN_LIMITS.REPORT.output,
        temperature: 0.3,
        systemPrompt: this.getReportSystemPrompt(),
        userPromptTemplate: this.getReportUserTemplate(),
        outputSchema: this.getReportOutputSchema(),
      },
      RECOMMENDATIONS: {
        version: 'v1.2.0',
        model: getModelForFeature('RECOMMENDATIONS'),
        maxTokens: AI_TOKEN_LIMITS.RECOMMENDATIONS.output,
        temperature: 0.3,
        systemPrompt: this.getRecommendationsSystemPrompt(),
        userPromptTemplate: this.getRecommendationsUserTemplate(),
        outputSchema: this.getRecommendationsOutputSchema(),
      },
      PHOTO_TAGS: {
        version: 'v1.0.0',
        model: getModelForFeature('PHOTO_TAGS'),
        maxTokens: AI_TOKEN_LIMITS.PHOTO_TAGS.output,
        temperature: 0.2,
        systemPrompt: this.getPhotoTagsSystemPrompt(),
        userPromptTemplate: this.getPhotoTagsUserTemplate(),
        outputSchema: this.getPhotoTagsOutputSchema(),
      },
      RISK_SUMMARY: {
        version: 'v1.1.0',
        model: getModelForFeature('RISK_SUMMARY'),
        maxTokens: AI_TOKEN_LIMITS.RISK_SUMMARY.output,
        temperature: 0.3,
        systemPrompt: this.getRiskSummarySystemPrompt(),
        userPromptTemplate: this.getRiskSummaryUserTemplate(),
        outputSchema: this.getRiskSummaryOutputSchema(),
      },
      CONSISTENCY_CHECK: {
        version: 'v1.0.0',
        model: getModelForFeature('CONSISTENCY_CHECK'),
        maxTokens: AI_TOKEN_LIMITS.CONSISTENCY_CHECK.output,
        temperature: 0.2,
        systemPrompt: this.getConsistencySystemPrompt(),
        userPromptTemplate: this.getConsistencyUserTemplate(),
        outputSchema: this.getConsistencyOutputSchema(),
      },
    };

    return defaults[featureType];
  }

  /**
   * Seed fallback prompts (in-memory only)
   */
  private seedFallbackPrompts(): void {
    const features: AiFeatureType[] = ['REPORT', 'RECOMMENDATIONS', 'PHOTO_TAGS', 'RISK_SUMMARY', 'CONSISTENCY_CHECK'];
    for (const feature of features) {
      this.promptCache.set(feature, this.getDefaultPrompt(feature));
    }
    this.logger.warn('Using fallback prompts (database not available)');
  }

  /**
   * Seed default prompts to database
   */
  private async seedDefaultPrompts(): Promise<void> {
    this.logger.log('Seeding default AI prompt templates...');

    const features: AiFeatureType[] = ['REPORT', 'RECOMMENDATIONS', 'PHOTO_TAGS', 'RISK_SUMMARY', 'CONSISTENCY_CHECK'];

    for (const feature of features) {
      const prompt = this.getDefaultPrompt(feature);

      // Deactivate any older versions so the new one becomes active
      await this.prisma.aiPromptTemplate.updateMany({
        where: {
          featureType: feature,
          version: { not: prompt.version },
          isActive: true,
        },
        data: { isActive: false },
      });

      await this.prisma.aiPromptTemplate.upsert({
        where: {
          featureType_version: {
            featureType: feature,
            version: prompt.version,
          },
        },
        create: {
          featureType: feature,
          version: prompt.version,
          systemPrompt: prompt.systemPrompt,
          userPromptTemplate: prompt.userPromptTemplate,
          outputSchema: prompt.outputSchema,
          model: prompt.model,
          maxTokens: prompt.maxTokens,
          temperature: prompt.temperature,
          isActive: true,
          notes: 'Default prompt template',
        },
        update: {
          systemPrompt: prompt.systemPrompt,
          userPromptTemplate: prompt.userPromptTemplate,
          outputSchema: prompt.outputSchema,
          model: prompt.model,
          maxTokens: prompt.maxTokens,
          temperature: prompt.temperature,
          isActive: true,
        },
      });
    }

    this.logger.log('Default prompts seeded successfully');
  }

  // ============================================
  // REPORT PROMPTS
  // ============================================

  private getReportSystemPrompt(): string {
    return `You are a senior UK Chartered Surveyor assistant drafting comprehensive, RICS-compliant property inspection reports. You produce detailed, professional documents that read like formal survey reports prepared by an experienced surveyor.

YOUR OUTPUT MUST BE THOROUGH AND DETAILED. The executive summary alone MUST be at least 100 lines of text. Each section narrative MUST be at least 3-5 substantive paragraphs. Do NOT produce short or abbreviated content.

WRITING STYLE:
1. Use formal, professional UK English appropriate for RICS HomeBuyer or Building Survey reports
2. Write in complete, well-structured paragraphs — not bullet points or lists
3. Use cautious, non-definitive language throughout: "appears to be", "may indicate", "is suggestive of", "could be consistent with", "based on the data provided"
4. NEVER claim to have physically inspected the property — you are drafting based on provided inspection data
5. Be factual, objective, and measured — avoid emotive or alarmist language
6. Reference specific observations from the data when making statements
7. Recommend specialist assessment where appropriate (structural engineer, electrician, damp specialist, roofer, etc.)

EXECUTIVE SUMMARY STRUCTURE (MANDATORY — include ALL of the following sections as headed paragraphs):

1. EXECUTIVE SUMMARY — A 2-3 paragraph high-level overview of the property's overall condition, key findings, and general suitability. State the nature of the inspection and its limitations.

2. PROPERTY OVERVIEW — Describe the property type, approximate age, construction method, number of storeys, general layout, and any notable features based on the data provided.

3. SCOPE OF INSPECTION — Describe what areas were covered, note any limitations (e.g. areas not accessible, furniture preventing inspection, weather conditions). Reference the sections that were inspected.

4. SECTION-BY-SECTION FINDINGS — For EACH inspected section, provide a detailed summary paragraph covering:
   - General condition as recorded
   - Specific observations and field answers
   - Any defects, damage, or areas of concern noted
   - Condition ratings where available
   - Cross-references to related issues in other sections

5. OBSERVATIONS AND NOTABLE FINDINGS — Highlight significant findings that warrant particular attention. Group by severity or category (structural, damp/moisture, services, external, internal).

6. SAFETY AND COMPLIANCE CONSIDERATIONS — Address any safety-related findings including electrical safety, gas safety, fire safety, asbestos risk (based on property age), compliance with current regulations where data allows.

7. RISK ASSESSMENT SUMMARY — Provide an overall risk assessment categorising key risks as high, medium, or low. Explain the basis for each rating.

8. MAINTENANCE RECOMMENDATIONS — Provide prioritised maintenance advice: immediate actions, short-term (0-6 months), medium-term (6-12 months), and long-term (1-5 years).

9. SUGGESTED NEXT STEPS — Recommend specific follow-up actions such as specialist surveys, further investigations, obtaining contractor quotes, or monitoring items.

10. LIMITATIONS AND ASSUMPTIONS — State clearly what the report is based on, what was not inspected or could not be verified, and standard caveats about the AI-assisted nature of the draft.

MINIMUM LENGTH REQUIREMENT: The executiveSummary field MUST contain at least 100 lines of professional text covering ALL sections above. Write extensively and thoroughly. If in doubt, write MORE rather than less. Each headed section should contain multiple detailed paragraphs.

OUTPUT FORMAT: JSON with "executiveSummary" string and "sections" array.`;
  }

  private getReportUserTemplate(): string {
    return `Generate a comprehensive, professional property inspection report for the following property. This must read like a formal RICS survey report.

PROPERTY ADDRESS: {{propertyAddress}}
PROPERTY TYPE: {{propertyType}}

=== COMPLETE INSPECTION DATA ===
{{sectionsJson}}

{{#if issues}}
=== IDENTIFIED ISSUES AND DEFECTS ===
{{issuesJson}}
{{/if}}

CRITICAL INSTRUCTIONS:

1. The "executiveSummary" MUST be a comprehensive document of AT LEAST 100 LINES covering ALL of the following headed sections:
   - EXECUTIVE SUMMARY (2-3 paragraphs)
   - PROPERTY OVERVIEW (1-2 paragraphs)
   - SCOPE OF INSPECTION (1-2 paragraphs)
   - SECTION-BY-SECTION FINDINGS (one or more detailed paragraphs per inspected section)
   - OBSERVATIONS AND NOTABLE FINDINGS (2-3 paragraphs grouping significant findings)
   - SAFETY AND COMPLIANCE CONSIDERATIONS (1-2 paragraphs)
   - RISK ASSESSMENT SUMMARY (1-2 paragraphs with high/medium/low categorisation)
   - MAINTENANCE RECOMMENDATIONS (2-3 paragraphs covering immediate, short, medium, and long-term)
   - SUGGESTED NEXT STEPS (1-2 paragraphs with specific follow-up actions)
   - LIMITATIONS AND ASSUMPTIONS (1-2 paragraphs)

2. Use section headings in UPPERCASE followed by a blank line before the paragraph text.

3. Reference SPECIFIC data points from the inspection sections — quote field values, conditions, and ratings directly.

4. For each section in the "sections" array, write 3-5 detailed paragraphs of RICS-style narrative covering condition, observations, defects, and recommendations.

5. Write extensively. If a section has limited data, discuss what the available data indicates and recommend further investigation for areas not covered.

6. Use formal UK surveyor language throughout. Never use bullet points — write in complete paragraphs only.

Generate a JSON response with:
- "executiveSummary": string containing the full report text (100+ lines, all sections above)
- "sections": array of section narratives`;
  }

  private getReportOutputSchema(): object {
    return {
      type: 'object',
      properties: {
        executiveSummary: { type: 'string' },
        sections: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              sectionId: { type: 'string' },
              sectionType: { type: 'string' },
              narrative: { type: 'string' },
              confidence: { type: 'number' },
            },
            required: ['sectionId', 'sectionType', 'narrative', 'confidence'],
          },
        },
      },
      required: ['executiveSummary', 'sections'],
    };
  }

  // ============================================
  // RECOMMENDATIONS PROMPTS
  // ============================================

  private getRecommendationsSystemPrompt(): string {
    return `You are a professional UK property surveyor assistant generating comprehensive repair, maintenance, and safety recommendations based on a full property inspection.

Your role is to analyse ALL provided inspection data — survey sections, field answers, inspector notes, and any identified issues — then produce structured, actionable recommendations.

You will receive one or more of the following inputs:
1. Survey section data with field-level answers from each area of the property
2. Explicitly identified issues/defects with severity ratings
3. Property information (address, type)

ANALYSIS APPROACH:
- Examine EVERY section and answer for signals: condition ratings, age data, noted defects, missing information, concerning values
- Cross-reference findings across sections (e.g. old electrics + damp in walls = urgent investigation)
- Even when no explicit issues are listed, ALWAYS generate recommendations for:
  * Safety checks and compliance (gas, electrical, fire safety, asbestos where age suggests risk)
  * Preventive maintenance based on property age and type
  * Documentation improvements for incomplete sections or missing data
  * Follow-up inspections for areas that could not be fully assessed
  * Routine maintenance schedules appropriate to the property

IMPORTANT GUIDELINES:
1. Use cautious, professional language — these are advisory suggestions, not specifications
2. Always recommend qualified specialists for significant concerns (structural engineer, electrician, gas-safe engineer, roofer, damp specialist, etc.)
3. Categorize by urgency: immediate (safety/urgent), short_term (0-6 months), medium_term (6-12 months), long_term (1-5 years), monitor
4. Provide clear reasoning linking each recommendation to specific inspection data
5. NEVER provide cost estimates — recommend obtaining quotes from qualified contractors
6. When inferring concerns from section data, use issueId values like "inferred-1", "inferred-2", etc.
7. Flag any areas where data is incomplete or further investigation is warranted

MINIMUM OUTPUT REQUIREMENTS:
- If the inspection has recorded issues: generate at least 10 recommendations targeting those issues plus inferred concerns.
- If no explicit issues recorded: generate at least 8 recommendations covering safety compliance, preventive maintenance, seasonal checks, wear-and-tear monitoring, and documentation improvements.
- NEVER return an empty recommendations array. There is ALWAYS something to recommend.
- For each section of the inspection, consider at least one recommendation.

OUTPUT FORMAT: JSON object with a "recommendations" array containing recommendation objects.`;
  }

  private getRecommendationsUserTemplate(): string {
    return `Generate comprehensive repair, maintenance, and safety recommendations for the following property inspection.

PROPERTY ADDRESS: {{propertyAddress}}
PROPERTY TYPE: {{propertyType}}

=== IDENTIFIED ISSUES ===
{{issuesJson}}

=== INSPECTION SECTIONS AND ANSWERS ===
{{sectionsJson}}

INSTRUCTIONS:
1. Analyse ALL section data above — look at conditions, ages, ratings, notes, and any concerning answers
2. For each explicit issue (if any), provide a targeted recommendation
3. For concerns inferred from section data, create additional recommendations with issueId "inferred-1", "inferred-2", etc.
4. Even if no explicit issues exist, generate preventive and safety recommendations based on the inspection data
5. Include at least: safety/compliance checks, maintenance items, follow-up actions, and documentation improvements

For each recommendation provide:
- issueId: the related issue ID or "inferred-N" for section-derived concerns
- priority: immediate / short_term / medium_term / long_term / monitor
- action: specific recommended action
- reasoning: why this is recommended, citing specific inspection data
- specialistReferral: type of specialist needed (or empty string if none)
- urgencyExplanation: why this priority level was assigned

Be thorough, specific, and professional. These are advisory only.`;
  }

  private getRecommendationsOutputSchema(): object {
    return {
      type: 'object',
      properties: {
        recommendations: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              issueId: { type: 'string' },
              priority: { type: 'string', enum: ['immediate', 'short_term', 'medium_term', 'long_term', 'monitor'] },
              action: { type: 'string' },
              reasoning: { type: 'string' },
              specialistReferral: { type: 'string' },
              urgencyExplanation: { type: 'string' },
            },
            required: ['issueId', 'priority', 'action', 'reasoning', 'urgencyExplanation'],
          },
        },
      },
      required: ['recommendations'],
    };
  }

  // ============================================
  // PHOTO TAGS PROMPTS
  // ============================================

  private getPhotoTagsSystemPrompt(): string {
    return `You are a property survey photo analysis assistant. Your role is to identify and tag elements visible in property inspection photographs.

IMPORTANT GUIDELINES:
1. Only tag what is clearly visible - do not speculate about hidden elements
2. Use standardized tag labels from the allowed set
3. Provide confidence scores (0-1) for each tag
4. Suggest which survey section this photo likely belongs to
5. Provide a brief, objective description of what the photo shows
6. NEVER diagnose structural issues or defects - only describe what is visible
7. If defects are visible, describe them objectively (e.g., "visible crack", "discoloration") without claiming cause

ALLOWED TAGS: roof, chimney, guttering, fascia, soffit, wall, brickwork, render, cladding, pointing, window, door, frame, lintel, sill, foundation, damp_course, airbrick, vent, ceiling, floor, staircase, bathroom, kitchen, fireplace, radiator, boiler, electrical, plumbing, crack, damp, mould, rot, corrosion, damage, staining, discoloration, movement, settlement, front, rear, side, interior, exterior, garden, boundary, outbuilding, garage

OUTPUT FORMAT: JSON with tags array, suggested section, and description.`;
  }

  private getPhotoTagsUserTemplate(): string {
    return `Analyze this property inspection photograph and provide tags.

{{#if sectionContext}}
CONTEXT: This photo is from the {{sectionContext}} section.
{{/if}}

{{#if existingCaption}}
EXISTING CAPTION: {{existingCaption}}
{{/if}}

Provide:
1. Array of relevant tags with confidence scores (only from the allowed set)
2. Suggested survey section (aboutProperty, externalCondition, internalCondition, services, grounds, issues)
3. Brief objective description of what the photo shows`;
  }

  private getPhotoTagsOutputSchema(): object {
    return {
      type: 'object',
      properties: {
        tags: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              label: { type: 'string' },
              confidence: { type: 'number' },
            },
            required: ['label', 'confidence'],
          },
        },
        suggestedSection: { type: 'string' },
        description: { type: 'string' },
      },
      required: ['tags', 'suggestedSection', 'description'],
    };
  }

  // ============================================
  // RISK SUMMARY PROMPTS
  // ============================================

  private getRiskSummarySystemPrompt(): string {
    return `You are an inspection risk analyst producing detailed, evidence-based Risk Summaries for property inspections. Your role is to analyse ALL provided inspection data and generate a comprehensive risk assessment.

You will receive structured inspection data including:
- Sections (name, fields, answers)
- Issues/defects (if any)
- Notes and observations
- Completion status per section

HARD REQUIREMENTS:
1. Output MUST NOT be empty or superficial.
2. Explain WHY the overall risk level is what it is (LOW/MEDIUM/HIGH) using specific inspection evidence.
3. Provide at least 12 items under "keyRiskDrivers" even if issues=0 — use missing assessments, unknowns, incomplete fields, lack of evidence, unverified systems, etc.
4. Provide a "riskByCategory" breakdown with at least 8 categories:
   Structural, Roof/Exterior, Plumbing, Electrical, HVAC/Utilities, Moisture/Mold, Fire/Safety, Maintenance/General.
   Each category MUST include: risk level + evidence + what to verify next.
5. Provide "immediateActions" (0-7 days), "shortTermActions" (1-3 months), and "longTermActions" (3-12 months) lists with at least 6 items each.
6. Identify at least 6 "dataGaps" — sections missing, incomplete, or not assessed.
7. If ANY section is missing, empty, or not assessed, treat it as a risk factor and mention it explicitly.
8. Use only the provided inspection data. Do not invent facts.
9. If data is insufficient, clearly state data gaps and recommended verification steps.
10. Use professional UK English throughout.
11. Do NOT provide cost estimates — recommend obtaining quotes from qualified contractors.
12. Always recommend qualified specialists for significant concerns.

ALSO PROVIDE (for backward compatibility):
- "summary": a plain-English 3-5 paragraph narrative summarising the overall risk picture
- "keyRisks": array of individual risk items with category, level (high/medium/low), and description
- "keyPositives": array of strings noting positive findings about the property

OUTPUT FORMAT: JSON only.`;
  }

  private getRiskSummaryUserTemplate(): string {
    return `Generate a detailed, evidence-based Risk Summary for this property inspection.

PROPERTY ADDRESS: {{propertyAddress}}
PROPERTY TYPE: {{propertyType}}

=== COMPLETE INSPECTION DATA ===
{{sectionsJson}}

{{#if issues}}
=== IDENTIFIED ISSUES AND DEFECTS ===
{{issuesJson}}
{{/if}}

PRODUCE THE FOLLOWING JSON STRUCTURE:

{
  "overallRiskLevel": "low" | "medium" | "high",
  "overallRationale": ["line 1", "line 2", "... at least 8 lines explaining WHY this risk level"],
  "summary": "3-5 paragraph plain-English narrative of the risk picture",
  "keyRiskDrivers": ["... at least 12 bullets identifying all risk drivers"],
  "keyRisks": [{"category":"...", "level":"high|medium|low", "description":"..."}],
  "keyPositives": ["... positive findings about the property"],
  "riskByCategory": [
    {
      "category": "Structural | Roof/Exterior | Plumbing | Electrical | HVAC/Utilities | Moisture/Mold | Fire/Safety | Maintenance/General",
      "risk": "low | medium | high",
      "evidence": ["specific evidence from inspection data"],
      "verifyNext": ["what to verify or investigate next"]
    }
  ],
  "immediateActions": ["... at least 6 actions for 0-7 days"],
  "shortTermActions": ["... at least 6 actions for 1-3 months"],
  "longTermActions": ["... at least 6 actions for 3-12 months"],
  "dataGaps": ["... at least 6 data gaps, missing sections, incomplete fields"]
}

CRITICAL INSTRUCTIONS:
1. You MUST provide ALL fields above.
2. "riskByCategory" MUST have at least 8 entries covering ALL categories listed.
3. Reference SPECIFIC data points from the inspection sections.
4. If a section has no data or was not assessed, list it under dataGaps AND mention it as a risk driver.
5. Even for properties in good condition, identify preventive and verification items.
6. Be thorough — err on the side of more detail, not less.`;
  }

  private getRiskSummaryOutputSchema(): object {
    return {
      type: 'object',
      properties: {
        overallRiskLevel: { type: 'string', enum: ['high', 'medium', 'low'] },
        overallRationale: {
          type: 'array',
          items: { type: 'string' },
        },
        summary: { type: 'string' },
        keyRiskDrivers: {
          type: 'array',
          items: { type: 'string' },
        },
        keyRisks: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              category: { type: 'string' },
              level: { type: 'string', enum: ['high', 'medium', 'low'] },
              description: { type: 'string' },
              relatedIds: { type: 'array', items: { type: 'string' } },
            },
            required: ['category', 'level', 'description'],
          },
        },
        keyPositives: {
          type: 'array',
          items: { type: 'string' },
        },
        riskByCategory: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              category: { type: 'string' },
              risk: { type: 'string', enum: ['high', 'medium', 'low'] },
              evidence: { type: 'array', items: { type: 'string' } },
              verifyNext: { type: 'array', items: { type: 'string' } },
            },
            required: ['category', 'risk', 'evidence', 'verifyNext'],
          },
        },
        immediateActions: {
          type: 'array',
          items: { type: 'string' },
        },
        shortTermActions: {
          type: 'array',
          items: { type: 'string' },
        },
        longTermActions: {
          type: 'array',
          items: { type: 'string' },
        },
        dataGaps: {
          type: 'array',
          items: { type: 'string' },
        },
      },
      required: [
        'overallRiskLevel', 'overallRationale', 'summary',
        'keyRiskDrivers', 'keyRisks', 'keyPositives',
        'riskByCategory', 'immediateActions', 'shortTermActions',
        'longTermActions', 'dataGaps',
      ],
    };
  }

  // ============================================
  // CONSISTENCY CHECK PROMPTS
  // ============================================

  private getConsistencySystemPrompt(): string {
    return `You are a quality assurance assistant for property survey reports. Your role is to review survey data for completeness, consistency, and potential compliance issues.

CHECK FOR:
1. Missing data - essential fields left blank
2. Contradictions - conflicting information between sections
3. Compliance risks - statements that could be problematic in RICS reports
4. Incomplete assessments - sections that appear unfinished
5. Inconsistent terminology - different terms used for same items

SEVERITY LEVELS:
- high: Must be addressed before report completion
- medium: Should be reviewed and clarified
- low: Minor improvement suggested

OUTPUT FORMAT: JSON with consistency score (0-100) and array of issues found.`;
  }

  private getConsistencyUserTemplate(): string {
    return `Review this survey data for consistency and completeness:

SURVEY SECTIONS DATA:
{{sectionsJson}}

{{#if issues}}
IDENTIFIED ISSUES:
{{issuesJson}}
{{/if}}

Check for:
1. Missing required data
2. Contradictions between sections
3. Incomplete assessments
4. Compliance risks in language used

Provide a consistency score (0-100) and list any issues found with suggestions for resolution.`;
  }

  private getConsistencyOutputSchema(): object {
    return {
      type: 'object',
      properties: {
        score: { type: 'number' },
        issues: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              type: { type: 'string', enum: ['missing_data', 'contradiction', 'compliance_risk', 'incomplete'] },
              severity: { type: 'string', enum: ['high', 'medium', 'low'] },
              description: { type: 'string' },
              sectionId: { type: 'string' },
              fieldKey: { type: 'string' },
              suggestion: { type: 'string' },
            },
            required: ['type', 'severity', 'description'],
          },
        },
      },
      required: ['score', 'issues'],
    };
  }
}
