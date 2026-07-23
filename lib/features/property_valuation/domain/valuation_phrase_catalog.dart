import 'dart:convert';

/// Versioned, reviewable phrase-bank metadata for valuation narratives.
///
/// A catalog is deliberately separate from the inspection phrase bank: this
/// wording is a professional draft until a qualified reviewer approves it.
class ValuationPhraseCatalog {
  const ValuationPhraseCatalog({
    required this.schemaVersion,
    required this.bankVersion,
    required this.reviewStatus,
    required this.templates,
  });

  final int schemaVersion;
  final String bankVersion;
  final String reviewStatus;
  final Map<String, ValuationPhraseTemplate> templates;

  bool get isApproved => reviewStatus.toLowerCase() == 'approved';

  /// Kept for the existing engine API and compatibility with older callers.
  Map<String, String> get texts => Map.unmodifiable({
        for (final entry in templates.entries) entry.key: entry.value.text,
      });

  factory ValuationPhraseCatalog.fromJson(Map<String, dynamic> json) {
    final rawTemplates = json['templates'];
    if (rawTemplates is! Map<String, dynamic>) {
      return ValuationPhraseCatalog.fromLegacyMap(
        json.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      );
    }

    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final templates = <String, ValuationPhraseTemplate>{};
    for (final entry in rawTemplates.entries) {
      final value = entry.value;
      if (value is String) {
        templates[entry.key] = ValuationPhraseTemplate(
          id: entry.key,
          text: value,
        );
      } else if (value is Map<String, dynamic>) {
        templates[entry.key] = ValuationPhraseTemplate.fromJson(
          entry.key,
          value,
        );
      }
    }
    return ValuationPhraseCatalog(
      schemaVersion: (meta['schemaVersion'] as num?)?.toInt() ?? 1,
      bankVersion: meta['bankVersion']?.toString() ?? 'legacy-draft',
      reviewStatus: meta['reviewStatus']?.toString() ?? 'draft',
      templates: Map.unmodifiable(templates),
    );
  }

  factory ValuationPhraseCatalog.fromLegacyMap(Map<String, String> values) {
    final templates = <String, ValuationPhraseTemplate>{};
    for (final entry in values.entries) {
      if (entry.key == '_meta' || entry.value.trim().isEmpty) continue;
      templates[entry.key] = ValuationPhraseTemplate(
        id: entry.key,
        text: entry.value,
      );
    }
    return ValuationPhraseCatalog(
      schemaVersion: 0,
      bankVersion: 'legacy-draft',
      reviewStatus: 'draft',
      templates: Map.unmodifiable(templates),
    );
  }

  factory ValuationPhraseCatalog.fromRawJson(String raw) =>
      ValuationPhraseCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  String? matchTemplateId(String text) {
    final normalized = _normalise(text);
    for (final template in templates.values) {
      if (template.matches(normalized)) return template.id;
    }
    return null;
  }

  static String _normalise(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}

class ValuationPhraseTemplate {
  const ValuationPhraseTemplate({
    required this.id,
    required this.text,
    this.screenId,
    this.allowedTokens = const <String>[],
  });

  final String id;
  final String text;
  final String? screenId;
  final List<String> allowedTokens;

  factory ValuationPhraseTemplate.fromJson(
    String id,
    Map<String, dynamic> json,
  ) =>
      ValuationPhraseTemplate(
        id: id,
        text: json['text']?.toString() ?? '',
        screenId: json['screenId']?.toString(),
        allowedTokens: (json['allowedTokens'] as List<dynamic>? ?? const [])
            .map((token) => token.toString())
            .toList(growable: false),
      );

  bool matches(String normalizedText) {
    final normalizedTemplate = text
        .replaceAll('[free text]', '{FREE_TEXT}')
        .replaceAll('[number]', '{NUMBER}')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    if (!normalizedTemplate.contains('{')) {
      return normalizedTemplate == normalizedText;
    }

    // A bare free-text record is a surveyor note, not a reusable narrative
    // template. Requiring meaningful literal wording prevents a permissive
    // catalog entry from approving arbitrary invented sentences.
    final literal =
        normalizedTemplate.replaceAll(RegExp(r'\{[a-z0-9_]+\}'), ' ').trim();
    if (literal.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length <
        3) {
      return false;
    }

    final pieces = normalizedTemplate.split(RegExp(r'\{[a-z0-9_]+\}'));
    final pattern = StringBuffer(r'^\s*');
    for (var index = 0; index < pieces.length; index++) {
      final literal = pieces[index].trim();
      if (literal.isNotEmpty) pattern.write(RegExp.escape(literal));
      if (index < pieces.length - 1) pattern.write(r'\s*(.+?)\s*');
    }
    pattern.write(r'\s*$');
    return RegExp(pattern.toString()).hasMatch(normalizedText);
  }
}

/// A rendered paragraph paired with the approved template that produced it.
class ValuationPhraseEmission {
  const ValuationPhraseEmission({
    required this.templateId,
    required this.text,
  });

  final String templateId;
  final String text;

  bool get isRegistered => templateId != 'UNREGISTERED';
}
