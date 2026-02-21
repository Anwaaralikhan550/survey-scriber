import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_tokens.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, ({User user, AuthTokens tokens})>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? organization,
  });

  Future<Either<Failure, void>> forgotPassword({
    required String email,
  });

  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<Either<Failure, AuthTokens>> refreshToken({
    required String refreshToken,
  });

  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, void>> logout();

  Future<bool> isAuthenticated();

  Future<String?> getStoredToken();

  Future<void> clearAuthData();

  Future<Either<Failure, User>> updateProfile({required String fullName});

  Future<Either<Failure, User>> uploadProfileImage({required File imageFile});

  Future<Either<Failure, User>> deleteProfileImage();

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
