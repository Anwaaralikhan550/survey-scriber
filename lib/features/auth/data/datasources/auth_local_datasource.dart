import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(AuthTokensModel tokens);
  Future<void> saveUser(UserModel user);
  UserModel? getUser();
  String? getAccessToken();
  String? getRefreshToken();
  String? getUserId();
  Future<void> clearAuthData();
  bool isAuthenticated();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _userDataKey = 'user_data';

  @override
  Future<void> saveTokens(AuthTokensModel tokens) async {
    AppLogger.d('AuthLocalDataSource', 'Saving tokens to secure storage');
    // CRITICAL FIX: Use StorageService.setRefreshToken() to save to secure storage
    // Previously was using SharedPreferences which wasn't loaded on app restart
    await StorageService.setAuthToken(tokens.accessToken);
    await StorageService.setRefreshToken(tokens.refreshToken);
    AppLogger.d('AuthLocalDataSource', 'Tokens saved successfully');
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await StorageService.setUserId(user.id);
    await StorageService.settingsBox.put(_userDataKey, user.toJson());
  }

  @override
  UserModel? getUser() {
    final userData = StorageService.settingsBox.get(_userDataKey);
    if (userData == null) return null;
    try {
      return UserModel.fromJson(Map<String, dynamic>.from(userData as Map));
    } catch (_) {
      return null;
    }
  }

  @override
  String? getAccessToken() => StorageService.authToken;

  @override
  String? getRefreshToken() {
    // CRITICAL FIX: Read from secure storage cache, not SharedPreferences
    final token = StorageService.refreshToken;
    AppLogger.d('AuthLocalDataSource', 'getRefreshToken: ${token != null ? "exists" : "null"}');
    return token;
  }

  @override
  String? getUserId() => StorageService.userId;

  @override
  Future<void> clearAuthData() async {
    AppLogger.d('AuthLocalDataSource', 'Clearing all auth data');
    await StorageService.setAuthToken(null);
    await StorageService.setRefreshToken(null);
    await StorageService.setUserId(null);
    await StorageService.settingsBox.delete(_userDataKey);
    AppLogger.d('AuthLocalDataSource', 'Auth data cleared');
  }

  @override
  bool isAuthenticated() {
    final token = getAccessToken();
    final hasToken = token != null && token.isNotEmpty;
    AppLogger.d('AuthLocalDataSource', 'isAuthenticated: $hasToken');
    return hasToken;
  }
}
