import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? organization,
  });

  Future<void> forgotPassword({required String email});

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<AuthTokensModel> refreshToken({required String refreshToken});

  Future<UserModel> getCurrentUser();

  /// Logout and revoke the refresh token on the server.
  /// [refreshToken] is optional - if null/empty, only local cleanup happens.
  Future<void> logout({String? refreshToken});

  Future<UserModel> updateProfile({required String fullName});

  Future<UserModel> uploadProfileImage({required File imageFile});

  Future<UserModel> deleteProfileImage();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._apiClient, this._dio);

  final ApiClient _apiClient;
  final Dio _dio;

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'auth/login',
      data: {'email': email, 'password': password},
    );

    return AuthResponseModel.fromJson(response.data!);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? organization,
  }) async {
    // Server returns 201 with empty body on success
    // We don't parse response - if no exception, registration succeeded
    await _apiClient.post<void>(
      'auth/register',
      data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (organization != null) 'organization': organization,
      },
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _apiClient.post<void>(
      'auth/forgot-password',
      data: {'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.post<void>(
      'auth/reset-password',
      data: {
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<AuthTokensModel> refreshToken({required String refreshToken}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      'auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    return AuthTokensModel.fromJson(response.data!);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get<Map<String, dynamic>>('auth/me');
    return UserModel.fromJson(response.data!);
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    // Backend requires refreshToken in body for server-side token revocation.
    // If no token provided, skip API call (local cleanup still happens in repository).
    if (refreshToken == null || refreshToken.isEmpty) {
      return;
    }
    await _apiClient.post<void>(
      'auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  @override
  Future<UserModel> updateProfile({required String fullName}) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      'auth/profile',
      data: {'fullName': fullName},
    );
    return UserModel.fromJson(response.data!);
  }

  @override
  Future<UserModel> uploadProfileImage({required File imageFile}) async {
    final fileName = p.basename(imageFile.path);
    final ext = p.extension(fileName).toLowerCase();
    final mimeType = ext == '.png' ? 'image/png' : 'image/jpeg';

    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });

    final response = await _dio.patch<Map<String, dynamic>>(
      'auth/profile/image',
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    return UserModel.fromJson(response.data!);
  }

  @override
  Future<UserModel> deleteProfileImage() async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      'auth/profile/image',
    );
    return UserModel.fromJson(response.data!);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.patch<Map<String, dynamic>>(
      'auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }
}
