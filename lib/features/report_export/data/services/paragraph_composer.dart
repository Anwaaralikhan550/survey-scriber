/// Master-template-driven paragraph composition.
///
/// The approved phrase database's 79 master templates encode the report's
/// paragraph grammar: sub-phrase codes that are space-joined belong to the
/// same paragraph, while `<br /><br />` marks a paragraph break. Example
/// (`{E_CONSERVATORY_PORCHES}`):
///
///     {PORCH_LOCATION_CONSTRUCTION} {PORCH_SAFETY_GLASS_RATING}
///     <br /><br />
///     {PORCH_ROOF} {PORCH_DOORS} {PORCH_WINDOWS} {PORCH_FLOOR} ...
///
/// The phrase engine emits one string per sub-phrase, so without this
/// composer the renderer prints one sentence per paragraph — the exact
/// defect reported by the client for the Construction and Porch sections.
///
/// [ParagraphComposer] reverses that: it identifies which approved sub-phrase
/// each emitted string came from (placeholder-tolerant template matching) and
/// re-joins adjacent phrases that the master template places in the same
/// paragraph group.
library;

class ParagraphComposer {
  ParagraphComposer(Map<String, String> phraseTexts) {
    _build(phraseTexts);
  }

  /// Matchers ordered by literal length (most specific first).
  final List<_SubPhraseMatcher> _matchers = <_SubPhraseMatcher>[];

  /// `master::subCode` -> paragraph-group ordinal within that master.
  final Map<String, int> _groupOf = <String, int>{};

  static final RegExp _masterCodePattern = RegExp(r'\{[A-Z0-9_]+\}');
  static final RegExp _brSplit =
      RegExp(r'(?:\\r\\n|<br\s*/?>|\r|\n)+', caseSensitive: false);
  static final RegExp _placeholder = RegExp(r'\{[a-z0-9_]+\}');

  /// Lines that must never be merged into a narrative paragraph.
  static final RegExp _standalonePattern = RegExp(
    r'^(\[\[SUBHEADING\]\]|condition rating is:|notes?:|\*\*)',
    caseSensitive: false,
  );

  void _build(Map<String, String> phraseTexts) {
    // 1. Paragraph groups from master templates.
    phraseTexts.forEach((key, template) {
      if (key.contains('::')) return;
      var group = 0;
      for (final segment in template.split(_brSplit)) {
        final codes = _masterCodePattern.allMatches(segment).toList();
        if (codes.isEmpty) continue;
        for (final code in codes) {
          _groupOf['$key::${segment.substring(code.start, code.end)}'] = group;
        }
        group++;
      }
    });

    // 2. Sub-phrase matchers.
    var insertionOrder = 0;
    phraseTexts.forEach((key, template) {
      final sep = key.indexOf('::');
      if (sep < 0) return;
      final master = key.substring(0, sep);
      final subCode = key.substring(sep + 2);
      final groupKey = '$master::$subCode';
      final group = _groupOf[groupKey];
      if (group == null) return; // sub-code not referenced by its master

      for (final segment in template.split(_brSplit)) {
        final regex = _templateToRegex(segment);
        if (regex == null) continue;
        _matchers.add(_SubPhraseMatcher(
          master: master,
          group: group,
          literalLength: _literalLength(segment),
          regex: regex,
          insertionOrder: insertionOrder++,
        ));
      }
    });

    // `List.sort` is not guaranteed stable, so two sub-phrases with
    // byte-identical literal text (e.g. two different masters that both
    // happen to read "The floors are covered in {X}.") could silently swap
    // which one wins a match whenever an UNRELATED matcher is added
    // elsewhere in the bank, shifting the tie-break outcome. Break ties on
    // insertion order so a match is deterministic and stable release over
    // release regardless of what else changes in the bank.
    _matchers.sort((a, b) {
      final byLength = b.literalLength.compareTo(a.literalLength);
      if (byLength != 0) return byLength;
      return a.insertionOrder.compareTo(b.insertionOrder);
    });
  }

  static String _normalize(String text) {
    var t = text
        .replaceAll(r'\r\n', ' ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(' ', ' ')
        .replaceAll(RegExp(r'\buPVC\b'), 'PVC');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.toLowerCase();
  }

  static int _literalLength(String template) =>
      _normalize(template).replaceAll(_placeholder, '').trim().length;

  /// Placeholder-tolerant matcher. Returns null when the template carries too
  /// little literal text to discriminate (would match arbitrary sentences).
  static RegExp? _templateToRegex(String template) {
    final normalized = _normalize(template);
    final literal = normalized.replaceAll(_placeholder, ' ').trim();
    final words =
        literal.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (literal.length < 12 || words < 3) return null;

    // Placeholders may resolve to empty (optional slots), so each becomes
    // (.*?) with elastic surrounding whitespace.
    final parts = normalized.split(_placeholder);
    final buffer = StringBuffer(r'^\s*');
    for (var i = 0; i < parts.length; i++) {
      buffer.write(RegExp.escape(parts[i].trim()));
      if (i < parts.length - 1) buffer.write(r'\s*(.*?)\s*');
    }
    buffer.write(r'\s*$');
    return RegExp(buffer.toString());
  }

  _SubPhraseMatcher? _resolve(String phrase) {
    final normalized = _normalize(phrase);
    if (normalized.isEmpty) return null;
    for (final matcher in _matchers) {
      if (matcher.regex.hasMatch(normalized)) return matcher;
    }
    return null;
  }

  /// Re-joins adjacent phrases that the approved master templates place in
  /// the same paragraph group. Unrecognised phrases, subheadings, condition
  /// ratings and notes always stand alone.
  List<String> compose(List<String> phrases) {
    if (phrases.length < 2) return phrases;

    final result = <String>[];
    String? currentKey;
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isNotEmpty) {
        result.add(buffer.toString());
        buffer.clear();
      }
      currentKey = null;
    }

    for (final phrase in phrases) {
      final trimmed = phrase.trim();
      if (trimmed.isEmpty) continue;

      if (_standalonePattern.hasMatch(trimmed)) {
        flush();
        result.add(trimmed);
        continue;
      }

      final matcher = _resolve(trimmed);
      final key =
          matcher == null ? null : '${matcher.master}#${matcher.group}';

      if (key != null && key == currentKey) {
        buffer
          ..write(' ')
          ..write(trimmed);
        continue;
      }

      flush();
      if (key == null) {
        result.add(trimmed);
      } else {
        currentKey = key;
        buffer.write(trimmed);
      }
    }
    flush();
    return result;
  }
}

class _SubPhraseMatcher {
  const _SubPhraseMatcher({
    required this.master,
    required this.group,
    required this.literalLength,
    required this.regex,
    required this.insertionOrder,
  });

  final String master;
  final int group;
  final int literalLength;
  final RegExp regex;
  final int insertionOrder;
}
