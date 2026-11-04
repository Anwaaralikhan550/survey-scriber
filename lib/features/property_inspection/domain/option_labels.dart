import 'models/inspection_models.dart';

/// The words an admin chose for dropdown options, without touching what is stored.
///
/// A survey keeps the option's original value, so saved answers, report rules and
/// conditions carry on working. Only what people read changes: the dropdown and
/// the sentence in the report.
class OptionLabels {
  const OptionLabels(this._byScreen);

  /// screen id -> field id -> stored value -> words to show
  final Map<String, Map<String, Map<String, String>>> _byScreen;

  static const empty = OptionLabels({});

  factory OptionLabels.fromSections(Iterable<InspectionSectionDefinition> sections) {
    final byScreen = <String, Map<String, Map<String, String>>>{};
    for (final section in sections) {
      for (final node in section.nodes) {
        for (final field in node.fields) {
          final labels = field.optionLabels;
          if (labels == null || labels.isEmpty) continue;
          (byScreen[node.id] ??= {})[field.id] = labels;
        }
      }
    }
    return byScreen.isEmpty ? empty : OptionLabels(byScreen);
  }

  bool get isEmpty => _byScreen.isEmpty;

  /// The words for [value], or [value] itself when it was not renamed.
  String show(String screenId, String fieldId, String value) =>
      _byScreen[screenId]?[fieldId]?[value] ?? value;

  static const _sayPrefix = '\u0000say:';

  /// [answers] plus the words to print for this screen's renamed options. The
  /// stored values stay as they are, because rules compare against them.
  Map<String, String> withWords(String screenId, Map<String, String> answers) {
    final fields = _byScreen[screenId];
    if (fields == null) return answers;
    final out = {...answers};
    fields.forEach((fieldId, labels) {
      final word = labels[(answers[fieldId] ?? '').trim()];
      if (word != null) out['$_sayPrefix$fieldId'] = word;
    });
    return out;
  }

  /// What to print for [fieldId]: the renamed words, otherwise the stored value.
  static String say(Map<String, String> answers, String fieldId) =>
      (answers['$_sayPrefix$fieldId'] ?? answers[fieldId] ?? '').trim();
}
