/// Redacts personally identifiable information (PII) from text before
/// sending to the AI backend.
///
/// The backend proxies requests to Gemini — while the backend itself is
/// trusted, minimising PII in AI prompts follows data minimisation
/// principles and reduces exposure surface.
///
/// Redaction is reversible: the [RedactionResult] contains a mapping
/// that allows re-inserting original values into AI responses.
class PiiRedactor {

  /// Patterns that match common PII in survey data.
  /// Order matters — more specific patterns first.
  static final _emailPattern = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );

  static final _ukPhonePattern = RegExp(
    r'\b(?:(?:\+44|0)\s?(?:\d[\s-]?){9,10}\d)\b',
  );

  static final _ukPostcodePattern = RegExp(
    r'\b[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}\b',
    caseSensitive: false,
  );

  /// Redact a single string value.
  ///
  /// Returns the redacted string and a reverse mapping.
  RedactionResult redactText(String text) {
    final mapping = <String, String>{};
    var redacted = text;
    var counter = 0;

    // Redact emails
    redacted = redacted.replaceAllMapped(_emailPattern, (match) {
      final token = '[EMAIL_${counter++}]';
      mapping[token] = match.group(0)!;
      return token;
    });

    // Redact UK phone numbers
    redacted = redacted.replaceAllMapped(_ukPhonePattern, (match) {
      final token = '[PHONE_${counter++}]';
      mapping[token] = match.group(0)!;
      return token;
    });

    // Redact UK postcodes
    redacted = redacted.replaceAllMapped(_ukPostcodePattern, (match) {
      final token = '[POSTCODE_${counter++}]';
      mapping[token] = match.group(0)!;
      return token;
    });

    return RedactionResult(redacted: redacted, mapping: mapping);
  }

  /// Redact PII from a property address.
  ///
  /// For addresses we replace the entire string rather than
  /// pattern-matching, since any part of an address is PII.
  RedactionResult redactAddress(String address) {
    if (address.isEmpty) return RedactionResult(redacted: address, mapping: {});

    const token = '[PROPERTY_ADDRESS]';
    return RedactionResult(
      redacted: token,
      mapping: {token: address},
    );
  }

  /// Redact PII from a person's name.
  RedactionResult redactName(String name) {
    if (name.isEmpty) return RedactionResult(redacted: name, mapping: {});

    const token = '[CLIENT_NAME]';
    return RedactionResult(
      redacted: token,
      mapping: {token: name},
    );
  }

  /// Redact PII from a map of field answers.
  ///
  /// Returns the redacted map and a combined reverse mapping.
  MapRedactionResult redactAnswerMap(Map<String, String> answers) {
    final mapping = <String, String>{};
    final redacted = <String, String>{};

    for (final entry in answers.entries) {
      final result = redactText(entry.value);
      redacted[entry.key] = result.redacted;
      mapping.addAll(result.mapping);
    }

    return MapRedactionResult(redacted: redacted, mapping: mapping);
  }

  /// Restore redacted tokens in an AI response text using the reverse mapping.
  String unredact(String text, Map<String, String> mapping) {
    var restored = text;
    for (final entry in mapping.entries) {
      restored = restored.replaceAll(entry.key, entry.value);
    }
    return restored;
  }
}

/// Result of redacting a single text value.
class RedactionResult {
  const RedactionResult({
    required this.redacted,
    required this.mapping,
  });

  /// The redacted text with PII replaced by tokens.
  final String redacted;

  /// Reverse mapping: token → original value.
  final Map<String, String> mapping;
}

/// Result of redacting a map of field answers.
class MapRedactionResult {
  const MapRedactionResult({
    required this.redacted,
    required this.mapping,
  });

  /// The redacted answer map.
  final Map<String, String> redacted;

  /// Combined reverse mapping for all redacted values.
  final Map<String, String> mapping;
}
