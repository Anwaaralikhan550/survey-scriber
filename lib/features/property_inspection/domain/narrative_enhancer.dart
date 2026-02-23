/// Central post-processor that adds professional surveyor context to report
/// phrases without modifying the phrase engine or individual screen logic.
///
/// Three enrichment types:
/// 1. **Section preambles** — professional intro paragraph for each major section
/// 2. **Condition rating context** — interpretive text after condition ratings
/// 3. **Repair urgency suffixes** — additional context for repair-soon/repair-now
class NarrativeEnhancer {
  NarrativeEnhancer._();

  // ═══════════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════

  /// Enhance a list of phrases with professional context.
  ///
  /// [phrases] — raw phrases from the phrase engine + field processor.
  /// [sectionKey] — section key identifying the section (e.g. E/F/G/H for
  ///   inspection, or valuation_details/property_inspection etc. for valuation).
  /// [screenId] — the screen node ID (used for first-screen detection).
  /// [isFirstScreenInSection] — whether this is the first screen/group in its
  ///   section, triggering the section preamble.
  static List<String> enhance(
    List<String> phrases, {
    required String sectionKey,
    required String screenId,
    bool isFirstScreenInSection = false,
  }) {
    if (phrases.isEmpty) return phrases;

    final result = <String>[];

    // 1. Section preamble (only for the first screen in a section)
    if (isFirstScreenInSection) {
      final preamble = _sectionPreambles[sectionKey];
      if (preamble != null) {
        result.add(preamble);
      }
    }

    // 2. Process each phrase for condition rating context and repair suffixes
    for (final phrase in phrases) {
      result.add(phrase);

      // Condition rating context
      final ratingContext = _conditionRatingContext(phrase);
      if (ratingContext != null) {
        result.add(ratingContext);
      }

      // Repair urgency suffix
      final repairSuffix = _repairUrgencySuffix(phrase);
      if (repairSuffix != null) {
        result.add(repairSuffix);
      }
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SECTION PREAMBLES
  // ═══════════════════════════════════════════════════════════════════════

  static const _sectionPreambles = <String, String>{
    'E': 'The following observations relate to the external elements of the '
        'property as inspected from ground level, public thoroughfares, and '
        'all accessible vantage points. Where specific elements could not be '
        'fully inspected due to height, access limitations, or vegetation, '
        'this has been noted accordingly.',
    'F': 'The following observations relate to the internal elements of the '
        'property. The inspection was carried out in a non-invasive manner; '
        'floor coverings were not lifted, furniture was not moved, and fixed '
        'panels or service hatches were not opened unless readily accessible.',
    'G': 'The building services were visually inspected where accessible. No '
        'tests were carried out to the services, and specialist reports should '
        'be obtained from appropriately qualified contractors prior to legal '
        'commitment.',
    'H': 'The grounds, boundaries, and immediate surroundings of the property '
        'were inspected from within the site and from adjacent public areas '
        'where accessible.',
    // ── Valuation section preambles ──
    'valuation_details': 'The following details have been recorded as part of '
        'the valuation inspection and are based upon the information provided '
        'to us, together with our own observations at the time of the inspection.',
    'property_assessment': 'The following assessment of the property has been '
        'prepared based upon our inspection and our knowledge of the local '
        'property market. The accommodation details have been measured and '
        'verified where possible.',
    'property_inspection': 'The following observations relate to the condition '
        'of the property as assessed during our inspection. The inspection was '
        'carried out in a non-invasive manner. Floor coverings were not lifted, '
        'furniture was not moved, and fixed panels or service hatches were not '
        'opened unless readily accessible. No tests were carried out to the '
        'building services.',
    'condition_restrictions': 'The following assessment of the overall condition '
        'of the property takes into account the individual observations set out '
        'in the preceding sections of this report.',
    'valuation_completion': 'The following valuation has been prepared in '
        'accordance with the RICS Valuation — Global Standards and is subject '
        'to the assumptions and conditions set out in this report.',
  };

  // ═══════════════════════════════════════════════════════════════════════
  //  CONDITION RATING CONTEXT
  // ═══════════════════════════════════════════════════════════════════════

  /// Detect "Condition rating is: N" or "Condition Rating: N" patterns and
  /// return an interpretive paragraph, or null if no match.
  ///
  /// Skips enrichment if the phrase already contains professional context
  /// (e.g. from the valuation phrase engine which embeds rating explanations).
  static String? _conditionRatingContext(String phrase) {
    final match = _conditionRatingPattern.firstMatch(phrase);
    if (match == null) return null;

    // Skip if the phrase already contains professional rating context
    final lower = phrase.toLowerCase();
    if (lower.contains('routine maintenance') ||
        lower.contains('budget provision') ||
        lower.contains('urgent attention')) {
      return null;
    }

    final rating = match.group(1)?.trim();
    return _ratingContextMap[rating];
  }

  static final _conditionRatingPattern =
      RegExp(r'[Cc]ondition [Rr]ating\s*(?:is)?:?\s*(\d)', caseSensitive: false);

  static const _ratingContextMap = <String, String>{
    '1': 'This rating reflects that the element is in a satisfactory condition '
        'with no immediate repair requirements identified. Routine maintenance '
        'should continue as normal.',
    '2': 'This rating indicates that defects requiring repair or replacement '
        'have been identified, but these are not considered to be serious or '
        'urgent at the present time. Budget provision should be made for the '
        'recommended works.',
    '3': 'This rating indicates serious defects that require urgent attention '
        'and may pose a risk to the safety or structural integrity of the '
        'property. Immediate further investigation by a suitably qualified '
        'specialist is strongly recommended.',
  };

  // ═══════════════════════════════════════════════════════════════════════
  //  REPAIR URGENCY SUFFIX
  // ═══════════════════════════════════════════════════════════════════════

  /// Detect repair urgency phrases and return a professional suffix, or null.
  ///
  /// Skips enrichment if the phrase already contains professional advice
  /// (e.g. enriched templates that already mention quotations or delay).
  static String? _repairUrgencySuffix(String phrase) {
    final lower = phrase.toLowerCase();

    // Skip if the phrase already contains professional context from enriched
    // templates — avoids double-appending the same advice.
    if (lower.contains('quotations') ||
        lower.contains('delay in undertaking')) {
      return null;
    }

    // "repair now" / "repaired now" / "replacing now" / "replaced now"
    if (_repairNowPattern.hasMatch(lower)) {
      return 'This matter requires urgent attention. Delay in undertaking the '
          'recommended repairs may result in further deterioration, increased '
          'repair costs, and potential consequential damage to adjacent '
          'building elements.';
    }

    // "repair soon" / "repaired soon" — but only if "repair now" isn't also present
    if (_repairSoonPattern.hasMatch(lower) &&
        !_repairNowPattern.hasMatch(lower)) {
      return 'It is recommended that quotations for this work be obtained from '
          'at least two suitably qualified contractors at the earliest '
          'opportunity.';
    }

    return null;
  }

  static final _repairNowPattern =
      RegExp(r'\b(?:repair(?:ed)?|replac(?:e|ed|ing))\b.{0,20}\bnow\b');

  static final _repairSoonPattern =
      RegExp(r'\b(?:repair(?:ed)?|replac(?:e|ed|ing))\b.{0,20}\bsoon\b');
}
