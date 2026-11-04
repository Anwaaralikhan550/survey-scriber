import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import 'preferences_provider.dart';

/// The surveyor's own company, printed on their reports.
class CompanyBranding extends Equatable {
  const CompanyBranding({this.name = '', this.logo});

  final String name;
  final Uint8List? logo;

  @override
  List<Object?> get props => [name, logo];
}

/// Reports are made offline, so the phone keeps its own copy. The server copy
/// brings the company back on a new phone.
class CompanyBrandingNotifier extends StateNotifier<CompanyBranding> {
  CompanyBrandingNotifier(this._prefs, this._api, this._userId)
      : super(_read(_prefs, _userId)) {
    sync();
  }

  final SharedPreferences _prefs;
  final ApiClient _api;
  final String? _userId;

  static const _path = 'auth/branding';

  static String _nameKey(String? id) => 'company_name_$id';
  static String _logoKey(String? id) => 'company_logo_$id';
  static String _unsentKey(String? id) => 'company_unsent_$id';

  static CompanyBranding _read(SharedPreferences prefs, String? userId) {
    if (userId == null) return const CompanyBranding();
    final logo = prefs.getString(_logoKey(userId));
    return CompanyBranding(
      name: prefs.getString(_nameKey(userId)) ?? '',
      logo: logo == null ? null : base64Decode(logo),
    );
  }

  Future<void> _writeLocal(CompanyBranding branding) async {
    state = branding;
    await _prefs.setString(_nameKey(_userId), branding.name);
    final logo = branding.logo;
    if (logo == null) {
      await _prefs.remove(_logoKey(_userId));
    } else {
      await _prefs.setString(_logoKey(_userId), base64Encode(logo));
    }
  }

  /// Saves on the phone at once. Returns false when the server could not be
  /// reached; the next [sync] sends it.
  Future<bool> save({required String name, Uint8List? logo}) async {
    await _writeLocal(CompanyBranding(name: name.trim(), logo: logo));
    await _prefs.setBool(_unsentKey(_userId), true);
    return sync();
  }

  /// Sends a pending save, otherwise takes the server's copy. Returns false when
  /// the server could not be reached.
  Future<bool> sync() async {
    if (_userId == null) return true;
    try {
      if (_prefs.getBool(_unsentKey(_userId)) ?? false) {
        await _api.put<Map<String, dynamic>>(
          _path,
          data: {
            'companyName': state.name,
            'companyLogo': state.logo == null ? null : base64Encode(state.logo!),
          },
        );
        await _prefs.remove(_unsentKey(_userId));
        return true;
      }
      final response = await _api.get<Map<String, dynamic>>(_path);
      final data = response.data ?? const <String, dynamic>{};
      final logo = data['companyLogo'] as String?;
      // A save made while this was on its way wins.
      if (!mounted || (_prefs.getBool(_unsentKey(_userId)) ?? false)) return true;
      await _writeLocal(CompanyBranding(
        name: data['companyName'] as String? ?? '',
        logo: logo == null ? null : base64Decode(logo),
      ));
      return true;
    } catch (e) {
      AppLogger.w('CompanyBranding', 'Sync failed: $e');
      return false;
    }
  }
}

final companyBrandingProvider =
    StateNotifierProvider<CompanyBrandingNotifier, CompanyBranding>((ref) {
  final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
  return CompanyBrandingNotifier(
    ref.watch(sharedPreferencesProvider),
    ref.watch(apiClientProvider),
    userId,
  );
});
