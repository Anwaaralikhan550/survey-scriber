import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  @override
  Future<Either<Failure, ({User user, AuthTokens tokens})>> login({
    required String email,
    required String password,
  }) async {
    // SECURITY: All login requests MUST go through the real API.
    // Mock login has been removed to prevent fake authentication.
    try {
      final response = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save tokens and user to local storage ONLY on successful API response
      await localDataSource.saveTokens(response.tokens);
      await localDataSource.saveUser(response.user);

      return Right((user: response.user, tokens: response.tokens));
    } on AuthException catch (e) {
      // Invalid credentials - DO NOT save any data
      return Left(AuthFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ),);
    } on NetworkException catch (e) {
      // Network error - DO NOT fake login, show error to user
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? organization,
  }) async {
    try {
      // Server returns 201 with no body on success
      // User must login separately after registration
      await remoteDataSource.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        organization: organization,
      );

      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        fieldErrors: e.fieldErrors,
      ),);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    try {
      await remoteDataSource.forgotPassword(email: email);
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final tokens = await remoteDataSource.refreshToken(
        refreshToken: refreshToken,
      );
      await localDataSource.saveTokens(tokens);
      return Right(tokens);
    } on AuthException catch (e) {
      await localDataSource.clearAuthData();
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      await localDataSource.saveUser(user);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on UnauthorizedException {
      await localDataSource.clearAuthData();
      return const Left(UnauthorizedFailure());
    } on NetworkException catch (e) {
      // On network error, try to return cached user if available
      final cachedUser = localDataSource.getUser();
      if (cachedUser != null) {
        return Right(cachedUser);
      }
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    // Get refresh token BEFORE clearing local data (we need it for server revocation)
    final refreshToken = localDataSource.getRefreshToken();

    try {
      // Attempt server-side token revocation (best effort)
      await remoteDataSource.logout(refreshToken: refreshToken);
    } on Exception {
      // Ignore logout API errors - clear local data anyway.
      // This ensures logout is idempotent and never blocks the user.
    } finally {
      // CRITICAL: Always clear local auth data regardless of API result.
      // This guarantees the user is logged out locally even if:
      // - Network is unavailable
      // - Token is already revoked/invalid
      // - Server returns an error
      await localDataSource.clearAuthData();
    }
    return const Right(null);
  }

  @override
  Future<bool> isAuthenticated() async =>
      localDataSource.isAuthenticated();

  @override
  Future<String?> getStoredToken() async =>
      localDataSource.getAccessToken();

  @override
  Future<void> clearAuthData() async =>
      localDataSource.clearAuthData();

  @override
  Future<Either<Failure, User>> updateProfile({required String fullName}) async {
    try {
      final user = await remoteDataSource.updateProfile(fullName: fullName);
      await localDataSource.saveUser(user);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          message: e.message,
          fieldErrors: e.fieldErrors,
        ),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> uploadProfileImage({required File imageFile}) async {
    try {
      final user = await remoteDataSource.uploadProfileImage(imageFile: imageFile);
      await localDataSource.saveUser(user);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          message: e.message,
          fieldErrors: e.fieldErrors,
        ),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> deleteProfileImage() async {
    try {
      final user = await remoteDataSource.deleteProfileImage();
      await localDataSource.saveUser(user);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message, fieldErrors: e.fieldErrors));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
