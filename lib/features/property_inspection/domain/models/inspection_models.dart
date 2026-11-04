import 'dart:convert';

enum InspectionFieldType {
  text,
  number,
  checkbox,
  dropdown,
  label,
}

enum InspectionNodeType {
  group,
  screen,
}

class InspectionFieldDefinition {
  const InspectionFieldDefinition({
    required this.id,
    required this.label,
    required this.type,
    this.options,
    this.conditionalOn,
    this.conditionalValue,
    this.conditionalMode,
    this.phraseTemplate,
    this.optionLabels,
    this.hiddenOptions,
  });

  factory InspectionFieldDefinition.fromJson(Map<String, dynamic> json) {
    final type = switch (json['type'] as String? ?? 'text') {
      'number' => InspectionFieldType.number,
      'checkbox' => InspectionFieldType.checkbox,
      'dropdown' => InspectionFieldType.dropdown,
      'label' => InspectionFieldType.label,
      _ => InspectionFieldType.text,
    };

    return InspectionFieldDefinition(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: type,
      options: (json['options'] as List<dynamic>?)?.whereType<String>().toList(),
      conditionalOn: json['conditionalOn'] as String?,
      conditionalValue: json['conditionalValue'] as String?,
      conditionalMode: json['conditionalMode'] as String?,
      phraseTemplate: json['phraseTemplate'] as String?,
      optionLabels: (json['optionLabels'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      hiddenOptions: (json['hiddenOptions'] as List<dynamic>?)?.whereType<String>().toList(),
    );
  }

  final String id;
  final String label;
  final InspectionFieldType type;
  final List<String>? options;
  final String? conditionalOn;
  final String? conditionalValue;
  /// 'show' (default) means show only when value matches.
  /// 'hide' means hide when value matches.
  final String? conditionalMode;

  /// Optional phrase template with {fieldId} placeholders for answer substitution.
  /// Used by the admin panel to attach narrative phrases to fields.
  final String? phraseTemplate;

  /// Option value -> the words people read. The stored answer stays the value,
  /// so saved surveys, report rules and conditions keep working.
  final Map<String, String>? optionLabels;

  /// Options no longer offered. A survey that already chose one still shows and
  /// prints it.
  final List<String>? hiddenOptions;

  /// The words for an option.
  String optionText(String value) => optionLabels?[value] ?? value;

  /// The options to offer, plus [current] when a saved answer needs it.
  List<String> offeredOptions(String current) {
    final all = options ?? const <String>[];
    final hidden = hiddenOptions ?? const <String>[];
    return [
      for (final option in all)
        if (!hidden.contains(option) || option == current) option,
      if (current.isNotEmpty && !all.contains(current)) current,
    ];
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'label': label,
      'type': type.name,
    };
    if (options != null && options!.isNotEmpty) m['options'] = options;
    if (conditionalOn != null) m['conditionalOn'] = conditionalOn;
    if (conditionalValue != null) m['conditionalValue'] = conditionalValue;
    if (conditionalMode != null) m['conditionalMode'] = conditionalMode;
    if (phraseTemplate != null) m['phraseTemplate'] = phraseTemplate;
    if (optionLabels != null && optionLabels!.isNotEmpty) m['optionLabels'] = optionLabels;
    if (hiddenOptions != null && hiddenOptions!.isNotEmpty) m['hiddenOptions'] = hiddenOptions;
    return m;
  }

  InspectionFieldDefinition copyWith({
    String? id,
    String? label,
    InspectionFieldType? type,
    List<String>? options,
    String? conditionalOn,
    String? conditionalValue,
    String? conditionalMode,
    String? phraseTemplate,
    Map<String, String>? optionLabels,
    List<String>? hiddenOptions,
  }) =>
      InspectionFieldDefinition(
        id: id ?? this.id,
        label: label ?? this.label,
        type: type ?? this.type,
        options: options ?? this.options,
        conditionalOn: conditionalOn ?? this.conditionalOn,
        conditionalValue: conditionalValue ?? this.conditionalValue,
        conditionalMode: conditionalMode ?? this.conditionalMode,
        phraseTemplate: phraseTemplate ?? this.phraseTemplate,
        optionLabels: optionLabels ?? this.optionLabels,
        hiddenOptions: hiddenOptions ?? this.hiddenOptions,
      );
}

class InspectionNodeDefinition {
  const InspectionNodeDefinition({
    required this.id,
    required this.title,
    required this.fields,
    required this.type,
    this.parentId,
    this.inlinePosition,
    this.reportDefaults,
    this.order,
  });

  factory InspectionNodeDefinition.fromJson(Map<String, dynamic> json) {
    final rawFields = (json['fields'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(InspectionFieldDefinition.fromJson)
        .where((f) => f.id.isNotEmpty && f.label.isNotEmpty)
        .toList();

    final id = json['id'] as String? ?? json['screen_id'] as String? ?? '';
    final type = switch (json['type'] as String? ?? 'screen') {
      'group' => InspectionNodeType.group,
      _ => InspectionNodeType.screen,
    };
    return InspectionNodeDefinition(
      id: id,
      title: json['title'] as String? ?? _humanizeId(id),
      fields: rawFields,
      type: type,
      parentId: json['parentId'] as String?,
      inlinePosition: json['inlinePosition'] as String?,
      reportDefaults: json['reportDefaults'] as List<dynamic>?,
      order: (json['order'] as num?)?.toInt(),
    );
  }

  final String id;
  final String title;
  final List<InspectionFieldDefinition> fields;
  final InspectionNodeType type;
  final String? parentId;
  final String? inlinePosition;

  /// Not used by the app; kept so that saving a tree does not lose it.
  final List<dynamic>? reportDefaults;
  final int? order;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'id': id,
      'title': title,
      'type': type.name,
    };
    if (parentId != null) m['parentId'] = parentId;
    if (inlinePosition != null) m['inlinePosition'] = inlinePosition;
    if (order != null) m['order'] = order;
    if (fields.isNotEmpty) m['fields'] = fields.map((f) => f.toJson()).toList();
    if (reportDefaults != null) m['reportDefaults'] = reportDefaults;
    return m;
  }

  InspectionNodeDefinition copyWith({
    String? id,
    String? title,
    List<InspectionFieldDefinition>? fields,
    InspectionNodeType? type,
    String? parentId,
    String? inlinePosition,
    int? order,
  }) =>
      InspectionNodeDefinition(
        id: id ?? this.id,
        title: title ?? this.title,
        fields: fields ?? this.fields,
        type: type ?? this.type,
        parentId: parentId ?? this.parentId,
        inlinePosition: inlinePosition ?? this.inlinePosition,
        order: order ?? this.order,
        reportDefaults: reportDefaults,
      );

  static String _humanizeId(String value) {
    if (value.isEmpty) return value;
    final cleaned = value.replaceAll(RegExp(r'^activity_'), '').replaceAll('_', ' ');
    return cleaned
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class InspectionSectionDefinition {
  const InspectionSectionDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.nodes,
  });

  final String key;
  final String title;
  final String description;
  final List<InspectionNodeDefinition> nodes;

  Map<String, dynamic> toJson() => {
        'key': key,
        'title': title,
        'description': description,
        'nodes': nodes.map((n) => n.toJson()).toList(),
      };
}

class InspectionTreePayload {
  const InspectionTreePayload({
    required this.sections,
  });

  factory InspectionTreePayload.fromJson(String rawJson) {
    final decoded = json.decode(rawJson) as Map<String, dynamic>;
    final sections = (decoded['sections'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((sectionJson) {
      final key = sectionJson['key'] as String? ?? '';
      final title = sectionJson['title'] as String? ?? key;
      final description = sectionJson['description'] as String? ?? '';
      final nodes = (sectionJson['nodes'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(InspectionNodeDefinition.fromJson)
          .toList();
      return InspectionSectionDefinition(
        key: key,
        title: title,
        description: description,
        nodes: nodes,
      );
    }).toList();
    return InspectionTreePayload(sections: sections);
  }

  final List<InspectionSectionDefinition> sections;

  String toJsonString() {
    final data = {
      'sections': sections.map((s) => s.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
