import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';

/// Phrase banks that admins can edit and publish to every phone.
enum PhraseBank {
  inspection('inspection_phrases'),
  valuation('valuation_phrases');

  const PhraseBank(this.apiType);

  /// Name used by the backend (`config/phrase-bank/:bankType`).
  final String apiType;
}

/// Result of publishing a bank to the server.
class PhrasePublishResult {
  const PhrasePublishResult({
    required this.version,
    required this.checksum,
    required this.unchanged,
  });

  final int version;
  final String checksum;

  /// true when the server already had identical content (no new version).
  final bool unchanged;
}

/// Live phrase updates: the server holds the latest published bank; phones
/// cache it for offline use and re-check on start/resume.
///
/// Load priority used by the providers:
///   1. unpublished local admin edit (publish still pending / offline)
///   2. [readCached] - last bank received from the server
///   3. bundled asset (factory default)
class PhraseBankSync {
  PhraseBankSync({ApiClient? apiClient, Future<Directory> Function()? docsDir})
      : _api = apiClient,
        _docsDir = docsDir ?? getApplicationDocumentsDirectory;

  final ApiClient? _api;
  final Future<Directory> Function() _docsDir;

  Future<File> _bankFile(PhraseBank b) async {
    final dir = await _docsDir();
    return File('${dir.path}/cache/phrase_bank_${b.apiType}.json');
  }

  Future<File> _checksumFile(PhraseBank b) async {
    final dir = await _docsDir();
    return File('${dir.path}/cache/phrase_bank_${b.apiType}.sha');
  }

  /// Raw JSON of the last bank received from the server, or null.
  Future<String?> readCached(PhraseBank b) async {
    try {
      final f = await _bankFile(b);
      if (await f.exists()) return await f.readAsString();
    } catch (e) {
      debugPrint('[PhraseBankSync] cache read failed: $e');
    }
    return null;
  }

  Future<String?> _cachedChecksum(PhraseBank b) async {
    try {
      final f = await _checksumFile(b);
      // The checksum only counts if the bank body it belongs to still exists.
      if (await f.exists() && await (await _bankFile(b)).exists()) {
        return (await f.readAsString()).trim();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _writeCache(PhraseBank b, String rawBank, String checksum) async {
    final bank = await _bankFile(b);
    await bank.parent.create(recursive: true);
    // Body first, checksum last: a crash in between just causes one re-download.
    await bank.writeAsString(rawBank, flush: true);
    await (await _checksumFile(b)).writeAsString(checksum, flush: true);
  }

  /// Asks the server for a newer bank. Returns true when the cached copy
  /// changed (callers then reload their phrase provider). Never throws:
  /// offline / server problems just keep the current phrases.
  Future<bool> refresh(PhraseBank b) async {
    final api = _api;
    if (api == null) return false;
    try {
      final known = await _cachedChecksum(b);
      final response = await api.get<Map<String, dynamic>>(
        'config/phrase-bank/${b.apiType}',
        queryParameters: {if (known != null) 'known': known},
      );
      final data = response.data;
      if (data == null || data['unchanged'] == true) return false;
      final bank = data['bank'];
      final checksum = data['checksum'];
      if (bank is! Map || checksum is! String) return false;
      await _writeCache(b, jsonEncode(bank), checksum);
      debugPrint('[PhraseBankSync] ${b.apiType} updated to v${data['version']}');
      return true;
    } catch (e) {
      // 404 = nothing published yet; anything else = offline. Both are fine.
      debugPrint('[PhraseBankSync] refresh ${b.apiType} skipped: $e');
      return false;
    }
  }

  /// Publishes [bank] (admin only). On success the server copy is also stored
  /// as this phone's cache so the editing admin sees it immediately.
  /// Throws on failure so the caller can keep the edit pending.
  Future<PhrasePublishResult> publish(
    PhraseBank b,
    Map<String, dynamic> bank,
  ) async {
    final api = _api;
    if (api == null) throw StateError('No API client - cannot publish');
    final response = await api.post<Map<String, dynamic>>(
      'admin/config/phrase-bank/upload',
      data: {'bankType': b.apiType, 'bank': bank},
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    final data = response.data ?? const <String, dynamic>{};
    final checksum = data['checksum'] as String? ?? '';
    await _writeCache(b, jsonEncode(bank), checksum);
    return PhrasePublishResult(
      version: (data['version'] as num?)?.toInt() ?? 0,
      checksum: checksum,
      unchanged: data['unchanged'] == true,
    );
  }
}

final phraseBankSyncProvider = Provider<PhraseBankSync>(
  (ref) => PhraseBankSync(apiClient: ref.watch(apiClientProvider)),
);
