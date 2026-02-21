import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Utility for parsing JSON in isolates to prevent main thread jank.
///
/// Use for large datasets (>50 items or complex nested objects).
/// For small payloads, use regular synchronous parsing.
class JsonIsolate {
  const JsonIsolate._();

  /// Parses a JSON string to a dynamic object in an isolate.
  ///
  /// Use when receiving raw JSON strings from network responses.
  static Future<dynamic> parse(String jsonString) => compute(_parseJson, jsonString);

  /// Parses a list of JSON objects into models using the provided factory.
  ///
  /// Example:
  /// ```dart
  /// final invoices = await JsonIsolate.parseList<InvoiceModel>(
  ///   jsonList,
  ///   InvoiceModel.fromJson,
  /// );
  /// ```
  static Future<List<T>> parseList<T>(
    List<dynamic> jsonList,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    // For small lists, parse synchronously to avoid isolate overhead
    if (jsonList.length < 20) {
      return Future.value(
        jsonList
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    return compute(
      _parseListInIsolate<T>,
      _ParseListParams(jsonList, fromJson),
    );
  }

  /// Encodes an object to JSON string in an isolate.
  ///
  /// Use for large objects that need to be serialized.
  static Future<String> encode(Object? object) => compute(_encodeJson, object);

  /// Encodes a list of models to JSON in an isolate.
  ///
  /// Example:
  /// ```dart
  /// final json = await JsonIsolate.encodeList(
  ///   invoices,
  ///   (invoice) => invoice.toJson(),
  /// );
  /// ```
  static Future<List<Map<String, dynamic>>> encodeList<T>(
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    // For small lists, encode synchronously
    if (items.length < 20) {
      return Future.value(items.map(toJson).toList());
    }

    return compute(
      _encodeListInIsolate<T>,
      _EncodeListParams(items, toJson),
    );
  }
}

// Top-level functions for compute()

dynamic _parseJson(String jsonString) => jsonDecode(jsonString);

String _encodeJson(Object? object) => jsonEncode(object);

List<T> _parseListInIsolate<T>(_ParseListParams<T> params) => params.jsonList
      .map((e) => params.fromJson(e as Map<String, dynamic>))
      .toList();

List<Map<String, dynamic>> _encodeListInIsolate<T>(_EncodeListParams<T> params) => params.items.map(params.toJson).toList();

// Parameter classes for compute() (must be top-level or static)

class _ParseListParams<T> {
  const _ParseListParams(this.jsonList, this.fromJson);

  final List<dynamic> jsonList;
  final T Function(Map<String, dynamic>) fromJson;
}

class _EncodeListParams<T> {
  const _EncodeListParams(this.items, this.toJson);

  final List<T> items;
  final Map<String, dynamic> Function(T) toJson;
}
