import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// Safe parsing utilities for defensive data handling.
///
/// These utilities prevent crashes from malformed API responses or
/// invalid data formats by providing safe fallbacks and clear errors.

// ===========================
// RESPONSE DATA PARSING
// ===========================

/// Extension on Dio Response for safe data extraction.
extension SafeResponseExtension<T> on Response<T> {
  /// Safely extracts response data with a descriptive error on null.
  ///
  /// Use this instead of `response.data!` to get clear error messages
  /// rather than null pointer exceptions.
  ///
  /// Example:
  /// ```dart
  /// final response = await _apiClient.get<Map<String, dynamic>>('/users');
  /// return UserModel.fromJson(response.requireData());
  /// ```
  T requireData([String? context]) {
    final data = this.data;
    if (data == null) {
      throw ServerException(
        message: context != null
            ? 'Empty response from server: $context'
            : 'Empty response from server',
      );
    }
    return data;
  }
}

// ===========================
// DATETIME PARSING
// ===========================

/// Safely parses a DateTime string, returning null on failure.
///
/// Use this for optional date fields that may be malformed.
DateTime? tryParseDateTime(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// Safely parses a DateTime string with a required fallback.
///
/// Use this for required date fields where you need a default on failure.
DateTime parseDateTimeOrDefault(String? value, {DateTime? defaultValue}) {
  if (value == null || value.isEmpty) {
    return defaultValue ?? DateTime.now();
  }
  return DateTime.tryParse(value) ?? defaultValue ?? DateTime.now();
}

/// Parses a DateTime string, throwing a clear error on failure.
///
/// Use this when the date is required and you want a descriptive error.
DateTime requireDateTime(String? value, {String? fieldName}) {
  if (value == null || value.isEmpty) {
    throw FormatException(
      fieldName != null
          ? 'Missing required date field: $fieldName'
          : 'Missing required date field',
    );
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException(
      fieldName != null
          ? 'Invalid date format for $fieldName: $value'
          : 'Invalid date format: $value',
    );
  }
  return parsed;
}

// ===========================
// JSON CASTING
// ===========================

/// Safely casts a dynamic value to a Map, returning null on failure.
Map<String, dynamic>? asMapOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

/// Safely casts a dynamic value to a List, returning empty on failure.
List<dynamic> asListOrEmpty(dynamic value) {
  if (value == null) return [];
  if (value is List) return value;
  return [];
}

/// Safely casts a dynamic value to a List of Maps.
List<Map<String, dynamic>> asMapListOrEmpty(dynamic value) {
  if (value == null) return [];
  if (value is! List) return [];
  return value
      .map(asMapOrNull)
      .whereType<Map<String, dynamic>>()
      .toList();
}

/// Safely extracts an int from dynamic, handling string numbers.
int? asIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Safely extracts a double from dynamic, handling string numbers.
double? asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Safely extracts a bool from dynamic, handling string booleans.
bool? asBoolOrNull(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  if (value is int) return value != 0;
  return null;
}

/// Safely extracts a String from dynamic.
String? asStringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}
