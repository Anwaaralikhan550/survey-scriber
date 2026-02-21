/// AI feature module for Gemini-powered survey assistance
///
/// This module provides:
/// - AI narrative report generation (RICS-style)
/// - AI photo auto-tagging with section association
/// - AI repair recommendations
/// - AI risk summary generation
/// - AI consistency checking
///
/// All AI calls are proxied through the backend AI Gateway.
/// API keys are never exposed to the client.
library ai;

// Data
export 'data/datasources/ai_remote_datasource.dart';
export 'data/repositories/ai_repository_impl.dart';
// Domain
export 'domain/entities/ai_response.dart';
export 'domain/repositories/ai_repository.dart';
// Presentation - Providers
export 'presentation/providers/ai_providers.dart';
// Presentation - Widgets
export 'presentation/widgets/ai_action_button.dart';
export 'presentation/widgets/ai_photo_tagger.dart';
export 'presentation/widgets/ai_result_sheet.dart';
export 'presentation/widgets/ai_risk_summary_button.dart';
export 'presentation/widgets/ai_summary_section.dart'
    hide IssueInput, SectionAnswersInput;
