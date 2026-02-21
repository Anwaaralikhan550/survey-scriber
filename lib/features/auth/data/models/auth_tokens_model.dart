import '../../domain/entities/auth_tokens.dart';

class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({
    required super.accessToken,
    required super.refreshToken,
    super.tokenType,
    super.expiresIn,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) =>
      AuthTokensModel(
        accessToken: json['accessToken'] as String? ??
            json['access_token'] as String,
        refreshToken: json['refreshToken'] as String? ??
            json['refresh_token'] as String,
        tokenType: json['tokenType'] as String? ??
            json['token_type'] as String? ??
            'Bearer',
        expiresIn: _parseExpiresIn(json['expiresIn'] ?? json['expires_in']),
      );

  /// Parse expiresIn which can be int or String from different backends
  static int? _parseExpiresIn(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': tokenType,
        'expiresIn': expiresIn,
      };
}
