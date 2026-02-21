import 'auth_tokens_model.dart';
import 'user_model.dart';

class AuthResponseModel {
  const AuthResponseModel({
    required this.user,
    required this.tokens,
  });

  /// Parse auth response from backend
  /// Backend returns flat structure: { user, accessToken, refreshToken, expiresIn }
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Parse expiresIn which can be int or String
    int? parseExpiresIn(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokensModel(
        accessToken: json['accessToken'] as String? ??
            json['access_token'] as String,
        refreshToken: json['refreshToken'] as String? ??
            json['refresh_token'] as String,
        tokenType: json['tokenType'] as String? ??
            json['token_type'] as String? ??
            'Bearer',
        expiresIn: parseExpiresIn(json['expiresIn'] ?? json['expires_in']),
      ),
    );
  }

  final UserModel user;
  final AuthTokensModel tokens;
}
