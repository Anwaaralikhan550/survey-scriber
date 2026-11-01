import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Native (Android/iOS/desktop): the regular drift_flutter database file.
QueryExecutor openAppConnection() => driftDatabase(name: 'survey_scriber');
