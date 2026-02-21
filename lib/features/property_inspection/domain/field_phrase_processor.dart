import 'models/inspection_models.dart';

/// Processes field-level phrase templates by substituting {fieldId}
/// placeholders with answer values.
///
/// This extends the existing phrase pipeline without modifying the
/// 11K-line InspectionPhraseEngine. Fields with a [phraseTemplate]
/// property get their templates processed here, and the results are
/// appended to the engine's output at the integration points (live
/// preview and report export).
class FieldPhraseProcessor {
  const FieldPhraseProcessor._();

  /// Process all field-level phrase templates for a screen's fields.
  ///
  /// Returns a list of resolved phrase strings (empty placeholders removed,
  /// templates with no resolved content excluded).
  static List<String> buildFieldPhrases(
    List<InspectionFieldDefinition> fields,
    Map<String, String> answers,
  ) {
    final result = <String>[];
    // Build a type lookup so _resolveTemplate can handle checkboxes
    final fieldTypes = <String, InspectionFieldType>{
      for (final f in fields) f.id: f.type,
    };

    for (final field in fields) {
      final template = field.phraseTemplate;
      if (template == null || template.trim().isEmpty) continue;

      // Check if this field is visible (skip hidden conditional fields)
      if (!_isFieldActive(field, answers)) continue;

      // For checkbox-owned templates with no placeholder, the checkbox acts
      // as a gate: checked → emit the static text, unchecked → skip.
      if (field.type == InspectionFieldType.checkbox) {
        final val = (answers[field.id] ?? '').trim().toLowerCase();
        if (val != 'true') continue; // unchecked — skip entirely
      }

      final resolved = _resolveTemplate(template, answers, fieldTypes);
      if (resolved.isNotEmpty) {
        result.add(resolved);
      }
    }

    return result;
  }

  /// Substitute {fieldId} placeholders in the template with answer values.
  ///
  /// Follows the existing phrase_texts.json convention where placeholders
  /// are wrapped in braces: {some_field_id}.
  ///
  /// **Checkbox handling:** When a placeholder references a checkbox field,
  /// the literal "true"/"false" is never injected. Instead:
  ///  - checked (true)  → placeholder is replaced with empty string
  ///  - unchecked/empty → placeholder is replaced with empty string
  /// This allows checkbox-gated templates like:
  ///   phraseTemplate = "Damp-proofing was noted as defective."
  /// where the checkbox just gates whether the sentence appears, without
  /// injecting "true" into the prose.
  static String _resolveTemplate(
    String template,
    Map<String, String> answers,
    Map<String, InspectionFieldType> fieldTypes,
  ) {
    var result = template;

    // Replace all {fieldId} placeholders with their answer values
    result = result.replaceAllMapped(
      RegExp(r'\{([^}]+)\}'),
      (match) {
        final fieldId = match.group(1)!;
        final raw = (answers[fieldId] ?? '').trim();

        // Never inject boolean literals into prose
        if (fieldTypes[fieldId] == InspectionFieldType.checkbox) {
          return '';
        }

        return raw;
      },
    );

    // Clean up: collapse multiple spaces, trim
    result = result.replaceAll(RegExp(r' {2,}'), ' ').trim();

    // If all placeholders resolved to empty, skip this phrase
    if (result.isEmpty || result == template.replaceAll(RegExp(r'\{[^}]+\}'), '').trim()) {
      // Check if the template only had placeholders and they're all empty
      final nonPlaceholderText = template.replaceAll(RegExp(r'\{[^}]+\}'), '').trim();
      if (result == nonPlaceholderText && nonPlaceholderText.isEmpty) {
        return '';
      }
      // If there's static text but no placeholder was resolved, still skip.
      // Exception: checkbox fields already passed the gate above, so their
      // templates (which may have no other placeholders) should still emit.
      final anyResolved = answers.entries.any((e) =>
          template.contains('{${e.key}}') && e.value.trim().isNotEmpty &&
          fieldTypes[e.key] != InspectionFieldType.checkbox);
      final hasCheckboxPlaceholder = answers.entries.any((e) =>
          template.contains('{${e.key}}') &&
          fieldTypes[e.key] == InspectionFieldType.checkbox);
      if (!anyResolved && !hasCheckboxPlaceholder) return '';
    }

    return result;
  }

  /// Check if a field is visible given current answers (simplified conditional check).
  static bool _isFieldActive(
    InspectionFieldDefinition field,
    Map<String, String> answers,
  ) {
    final condOn = field.conditionalOn;
    if (condOn == null || condOn.isEmpty) return true;

    // Simple single-field conditional check (covers most cases)
    if (!condOn.contains('&') &&
        !condOn.contains('|') &&
        !condOn.contains('=') &&
        !condOn.startsWith('!')) {
      final val = (answers[condOn] ?? '').trim();
      final expected = (field.conditionalValue ?? '').trim().toLowerCase();
      final actual = val.toLowerCase();
      final matches = expected.isEmpty ? val.isNotEmpty : actual == expected;
      return field.conditionalMode == 'hide' ? !matches : matches;
    }

    // For complex expressions, assume visible (the full check happens in the UI)
    return true;
  }
}
