import 'dart:convert';

/// Data model for inspection reference stored in valuation survey
/// Stored in SurveyAnswer with fieldKey: 'inspection_reference'
class InspectionReferenceData {
  const InspectionReferenceData({
    required this.inspectionId,
    this.surveyNumber,
    this.address,
    required this.linkedAt,
    this.source = 'selected',
  }); // 'selected' or 'auto'

  factory InspectionReferenceData.fromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return InspectionReferenceData(
        inspectionId: json['inspectionId'] as String? ?? '',
        surveyNumber: json['surveyNumber'] as String?,
        address: json['address'] as String?,
        linkedAt: json['linkedAt'] != null
            ? DateTime.parse(json['linkedAt'] as String)
            : DateTime.now(),
        source: json['source'] as String? ?? 'selected',
      );
    } catch (_) {
      return InspectionReferenceData(
        inspectionId: '',
        linkedAt: DateTime.now(),
      );
    }
  }

  final String inspectionId;
  final String? surveyNumber;
  final String? address;
  final DateTime linkedAt;
  final String source;

  String toJson() => jsonEncode({
        'inspectionId': inspectionId,
        'surveyNumber': surveyNumber,
        'address': address,
        'linkedAt': linkedAt.toIso8601String(),
        'source': source,
      });

  bool get isValid => inspectionId.isNotEmpty;

  InspectionReferenceData copyWith({
    String? inspectionId,
    String? surveyNumber,
    String? address,
    DateTime? linkedAt,
    String? source,
  }) =>
      InspectionReferenceData(
        inspectionId: inspectionId ?? this.inspectionId,
        surveyNumber: surveyNumber ?? this.surveyNumber,
        address: address ?? this.address,
        linkedAt: linkedAt ?? this.linkedAt,
        source: source ?? this.source,
      );
}

/// Data model for manual property summary entry
/// Stored in SurveyAnswer with fieldKey: 'manual_property_summary'
class ManualPropertySummaryData {
  const ManualPropertySummaryData({
    this.address,
    this.propertyType,
    this.tenure,
    this.bedrooms,
    this.bathrooms,
    this.floorAreaSqm,
    this.yearBuilt,
    this.condition,
    this.keyDefects,
    this.risk,
    this.notes,
    this.updatedAt,
  });

  factory ManualPropertySummaryData.fromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ManualPropertySummaryData(
        address: json['address'] as String?,
        propertyType: json['propertyType'] as String?,
        tenure: json['tenure'] as String?,
        bedrooms: json['bedrooms'] as int?,
        bathrooms: json['bathrooms'] as int?,
        floorAreaSqm: (json['floorAreaSqm'] as num?)?.toDouble(),
        yearBuilt: json['yearBuilt'] as int?,
        condition: json['condition'] as String?,
        keyDefects: json['defects'] as String? ?? json['keyDefects'] as String?,
        risk: json['risk'] as String?,
        notes: json['notes'] as String?,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );
    } catch (_) {
      return const ManualPropertySummaryData();
    }
  }

  final String? address;
  final String? propertyType;
  final String? tenure;
  final int? bedrooms;
  final int? bathrooms;
  final double? floorAreaSqm;
  final int? yearBuilt;
  final String? condition; // Good, Fair, Poor, Unknown
  final String? keyDefects;
  final String? risk; // Low, Medium, High, Unknown
  final String? notes;
  final DateTime? updatedAt;

  static const List<String> propertyTypeOptions = [
    'Detached House',
    'Semi-Detached House',
    'Terraced House',
    'End of Terrace',
    'Flat/Apartment',
    'Maisonette',
    'Bungalow',
    'Cottage',
    'Other',
  ];

  static const List<String> tenureOptions = [
    'Freehold',
    'Leasehold',
    'Share of Freehold',
    'Commonhold',
    'Unknown',
  ];

  static const List<String> conditionOptions = [
    'Excellent',
    'Good',
    'Fair',
    'Poor',
    'Very Poor',
    'Unknown',
  ];

  static const List<String> riskOptions = [
    'Low',
    'Medium',
    'High',
    'Unknown',
  ];

  String toJson() => jsonEncode({
        'address': address,
        'propertyType': propertyType,
        'tenure': tenure,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'floorAreaSqm': floorAreaSqm,
        'yearBuilt': yearBuilt,
        'condition': condition,
        'defects': keyDefects,
        'risk': risk,
        'notes': notes,
        'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
      });

  bool get isEmpty =>
      address == null &&
      propertyType == null &&
      bedrooms == null &&
      floorAreaSqm == null &&
      condition == null;

  bool get isNotEmpty => !isEmpty;

  /// Convert to property details map for display
  Map<String, String> toPropertyDetailsMap() {
    final details = <String, String>{};
    if (address != null && address!.isNotEmpty) {
      details['Address'] = address!;
    }
    if (propertyType != null && propertyType!.isNotEmpty) {
      details['Property Type'] = propertyType!;
    }
    if (tenure != null && tenure!.isNotEmpty) {
      details['Tenure'] = tenure!;
    }
    if (bedrooms != null) {
      details['Bedrooms'] = bedrooms.toString();
    }
    if (bathrooms != null) {
      details['Bathrooms'] = bathrooms.toString();
    }
    if (floorAreaSqm != null) {
      details['Floor Area'] = '${floorAreaSqm!.toStringAsFixed(0)} sqm';
    }
    if (yearBuilt != null) {
      details['Year Built'] = yearBuilt.toString();
    }
    return details;
  }

  /// Convert to condition summary map for display
  Map<String, String> toConditionSummaryMap() {
    final summary = <String, String>{};
    if (condition != null && condition!.isNotEmpty) {
      summary['Overall'] = condition!;
    }
    if (risk != null && risk!.isNotEmpty) {
      summary['Risk Level'] = risk!;
    }
    return summary;
  }

  ManualPropertySummaryData copyWith({
    String? address,
    String? propertyType,
    String? tenure,
    int? bedrooms,
    int? bathrooms,
    double? floorAreaSqm,
    int? yearBuilt,
    String? condition,
    String? keyDefects,
    String? risk,
    String? notes,
    DateTime? updatedAt,
  }) =>
      ManualPropertySummaryData(
        address: address ?? this.address,
        propertyType: propertyType ?? this.propertyType,
        tenure: tenure ?? this.tenure,
        bedrooms: bedrooms ?? this.bedrooms,
        bathrooms: bathrooms ?? this.bathrooms,
        floorAreaSqm: floorAreaSqm ?? this.floorAreaSqm,
        yearBuilt: yearBuilt ?? this.yearBuilt,
        condition: condition ?? this.condition,
        keyDefects: keyDefects ?? this.keyDefects,
        risk: risk ?? this.risk,
        notes: notes ?? this.notes,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// Combined state for property summary section
enum PropertySummaryMode {
  none, // No data yet - show prompt
  linkedInspection, // Using linked inspection data
  manualEntry, // Using manual entry data
}
