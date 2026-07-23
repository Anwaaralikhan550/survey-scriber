class ReportNarrativePolicy {
  const ReportNarrativePolicy._();

  static const int executiveSummaryMaxWords = 180;

  static String conciseExecutiveSummary(
    String summary, {
    int maxWords = executiveSummaryMaxWords,
  }) {
    final paragraphs = summary
        .split(RegExp(r'\n\s*\n'))
        .map((paragraph) => paragraph.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .take(3)
        .toList(growable: false);
    final normalized = paragraphs.join('\n\n');
    final words = normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.length <= maxWords) return normalized;

    final clipped = words.take(maxWords).join(' ');
    final sentenceEnd = <int>[
      clipped.lastIndexOf('.'),
      clipped.lastIndexOf('!'),
      clipped.lastIndexOf('?'),
    ].reduce((a, b) => a > b ? a : b);
    if (sentenceEnd >= (clipped.length * 0.6).floor()) {
      return clipped.substring(0, sentenceEnd + 1).trim();
    }
    return '${clipped.trimRight()}...';
  }
}
