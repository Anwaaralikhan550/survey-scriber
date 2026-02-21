import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/logger.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_auth_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    checkAuthUseCase: ref.watch(checkAuthUseCaseProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    authRepository: ref.watch(authRepositoryProvider),
  ),);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required CheckAuthUseCase checkAuthUseCase,
    required AuthLocalDataSource localDataSource,
    required AuthRepository authRepository,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _checkAuthUseCase = checkAuthUseCase,
        _localDataSource = localDataSource,
        _authRepository = authRepository,
        super(const AuthState()) {
    // Eagerly check auth status on creation so the router can resolve
    // initial → authenticated/unauthenticated before first frame.
    checkAuthStatus();
  }

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final CheckAuthUseCase _checkAuthUseCase;
  final AuthLocalDataSource _localDataSource;
  final AuthRepository _authRepository;

  /// Check authentication status.
  /// CRITICAL: Network errors do NOT invalidate existing auth.
  /// CRITICAL: Proactively refresh tokens if accessToken is missing but refreshToken exists.
  Future<void> checkAuthStatus() async {
    AppLogger.d('AuthNotifier', 'checkAuthStatus: Starting auth check');

    // Verify storage is initialized
    if (!StorageService.isInitialized) {
      AppLogger.e('AuthNotifier', 'checkAuthStatus: StorageService not initialized! Waiting...');
      // This should not happen as init() is awaited in main(), but defensive check
      await StorageService.init();
    }

    // Check tokens
    final hasAccessToken = _localDataSource.isAuthenticated();
    final refreshToken = _localDataSource.getRefreshToken();
    final hasRefreshToken = refreshToken != null && refreshToken.isNotEmpty;
    final cachedUser = _localDataSource.getUser();

    AppLogger.d('AuthNotifier', 'checkAuthStatus: hasAccessToken=$hasAccessToken, hasRefreshToken=$hasRefreshToken, hasCachedUser=${cachedUser != null}');

    state = state.copyWith(
      status: AuthStatus.loading,
      hasValidToken: hasAccessToken,
    );

    // CASE 1: No tokens at all - definitely unauthenticated
    if (!hasAccessToken && !hasRefreshToken) {
      AppLogger.d('AuthNotifier', 'checkAuthStatus: No tokens found, setting unauthenticated');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        hasValidToken: false,
        failureType: AuthFailureType.none,
      );
      return;
    }

    // CASE 2: No accessToken but refreshToken exists - PROACTIVELY REFRESH FIRST
    if (!hasAccessToken && hasRefreshToken) {
      AppLogger.d('AuthNotifier', 'checkAuthStatus: No accessToken but refreshToken exists, attempting proactive refresh');
      final refreshResult = await _authRepository.refreshToken(refreshToken: refreshToken);

      final refreshSuccess = refreshResult.fold(
        (failure) {
          AppLogger.e('AuthNotifier', 'checkAuthStatus: Proactive refresh failed: ${failure.message}');
          return false;
        },
        (tokens) {
          AppLogger.d('AuthNotifier', 'checkAuthStatus: Proactive refresh successful');
          return true;
        },
      );

      if (!refreshSuccess) {
        // Refresh failed - user must re-login
        AppLogger.d('AuthNotifier', 'checkAuthStatus: Refresh failed, setting unauthenticated');
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          hasValidToken: false,
          failureType: AuthFailureType.sessionExpired,
        );
        return;
      }
      // Refresh succeeded - continue to fetch user profile
    }

    // CASE 3: AccessToken exists (or was just refreshed) - verify with /auth/me
    AppLogger.d('AuthNotifier', 'checkAuthStatus: Calling /auth/me to verify session');
    final result = await _checkAuthUseCase();

    result.fold(
      (failure) {
        // Classify the failure type
        final failureType = _mapFailureToType(failure);
        AppLogger.d('AuthNotifier', 'checkAuthStatus: /auth/me failed with $failureType: ${failure.message}');

        // CRITICAL: Network/server errors do NOT invalidate auth if token exists
        if (failureType == AuthFailureType.networkError ||
            failureType == AuthFailureType.serverError) {
          AppLogger.d('AuthNotifier', 'checkAuthStatus: Network/server error, keeping authenticated with cached user');
          // Keep user authenticated with cached user data
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: cachedUser,
            hasValidToken: true,
            failureType: failureType,
            errorMessage: failure.message,
          );
        } else if (failureType == AuthFailureType.sessionExpired ||
            failureType == AuthFailureType.invalidCredentials) {
          AppLogger.d('AuthNotifier', 'checkAuthStatus: Session expired/invalid, setting unauthenticated');
          // Session expired OR invalid credentials (401) - require re-login
          // CRITICAL: 401 during auth check means token is invalid/expired
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            hasValidToken: false,
            failureType: AuthFailureType.sessionExpired,
            errorMessage: failure.message,
          );
        } else {
          AppLogger.d('AuthNotifier', 'checkAuthStatus: Unknown error, keeping authenticated with cached user');
          // Other errors (unknown) - still keep auth if token exists
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: cachedUser,
            hasValidToken: true,
            failureType: failureType,
            errorMessage: failure.message,
          );
        }
      },
      (user) {
        if (user != null) {
          AppLogger.d('AuthNotifier', 'checkAuthStatus: /auth/me success, user authenticated');
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            hasValidToken: true,
            failureType: AuthFailureType.none,
          );
        } else if (hasAccessToken || hasRefreshToken) {
          AppLogger.d('AuthNotifier', 'checkAuthStatus: No user returned but token exists, using cached user');
          // No user returned but token exists - use cached user
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: cachedUser,
            hasValidToken: true,
            failureType: AuthFailureType.none,
          );
        } else {
          AppLogger.d('AuthNotifier', 'checkAuthStatus: No user and no token, unauthenticated');
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            hasValidToken: false,
            failureType: AuthFailureType.none,
          );
        }
      },
    );
  }

  /// Login with email and password.
  /// Returns (success, failureType) tuple for proper UX handling.
  Future<(bool, AuthFailureType)> login({
    required String email,
    required String password,
  }) async {
    AppLogger.d('AuthNotifier', 'login: Attempting login for $email');
    // CRITICAL: Reset hasValidToken to prevent stale state from previous sessions
    // This ensures the router doesn't think we're authenticated during login attempt
    state = state.copyWith(
      status: AuthStatus.loading,
      failureType: AuthFailureType.none,
      hasValidToken: false,
    );

    final result = await _loginUseCase(email: email, password: password);

    return result.fold(
      (failure) {
        final failureType = _mapFailureToType(failure);
        AppLogger.e('AuthNotifier', 'login: Failed with $failureType: ${failure.message}');

        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          failureType: failureType,
          hasValidToken: false,
        );
        return (false, failureType);
      },
      (data) {
        AppLogger.d('AuthNotifier', 'login: Success, user=${data.user.email}');
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: data.user,
          hasValidToken: true,
          failureType: AuthFailureType.none,
        );
        return (true, AuthFailureType.none);
      },
    );
  }

  /// Register a new user account.
  /// Returns (success, failureType) tuple for proper UX handling.
  /// NOTE: Server returns 201 with no body - user must login after registration.
  Future<(bool, AuthFailureType)> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    String? organization,
  }) async {
    // CRITICAL: Reset hasValidToken to prevent stale state from interfering
    state = state.copyWith(
      status: AuthStatus.loading,
      failureType: AuthFailureType.none,
      hasValidToken: false,
    );

    final result = await _registerUseCase(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      organization: organization,
    );

    return result.fold(
      (failure) {
        final failureType = _mapFailureToType(failure);

        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: failure.message,
          failureType: failureType,
          hasValidToken: false,
        );
        return (false, failureType);
      },
      (_) {
        // Registration successful - user must now login
        // Stay unauthenticated so UI can navigate to login page
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          hasValidToken: false,
          failureType: AuthFailureType.none,
        );
        return (true, AuthFailureType.none);
      },
    );
  }

  /// Logout - explicitly clear auth state
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    await _logoutUseCase();

    state = const AuthState(
      status: AuthStatus.unauthenticated,
    );
  }

  void clearError() {
    state = state.copyWith(
      failureType: AuthFailureType.none,
    );
  }

  /// Explicitly set unauthenticated (e.g., token refresh failed)
  void setUnauthenticated() {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      failureType: AuthFailureType.sessionExpired,
    );
  }

  /// Update user profile (fullName only)
  /// Returns (success, errorMessage) tuple
  Future<(bool, String?)> updateProfile({required String fullName}) async {
    final result = await _authRepository.updateProfile(fullName: fullName);

    return result.fold(
      (failure) {
        AppLogger.e('AuthNotifier', 'updateProfile: Failed: ${failure.message}');
        return (false, failure.message);
      },
      (user) {
        AppLogger.d('AuthNotifier', 'updateProfile: Success, user=${user.email}');
        state = state.copyWith(user: user);
        return (true, null);
      },
    );
  }

  /// Upload profile image
  /// Returns (success, errorMessage) tuple
  Future<(bool, String?)> uploadProfileImage({required File imageFile}) async {
    AppLogger.d('AuthNotifier', 'uploadProfileImage: Uploading image');
    final result = await _authRepository.uploadProfileImage(imageFile: imageFile);

    return result.fold(
      (failure) {
        AppLogger.e('AuthNotifier', 'uploadProfileImage: Failed: ${failure.message}');
        return (false, failure.message);
      },
      (user) {
        AppLogger.d('AuthNotifier', 'uploadProfileImage: Success, avatarUrl=${user.avatarUrl}');
        state = state.copyWith(user: user);
        return (true, null);
      },
    );
  }

  /// Delete profile image
  /// Returns (success, errorMessage) tuple
  Future<(bool, String?)> deleteProfileImage() async {
    AppLogger.d('AuthNotifier', 'deleteProfileImage: Deleting image');
    final result = await _authRepository.deleteProfileImage();

    return result.fold(
      (failure) {
        AppLogger.e('AuthNotifier', 'deleteProfileImage: Failed: ${failure.message}');
        return (false, failure.message);
      },
      (user) {
        AppLogger.d('AuthNotifier', 'deleteProfileImage: Success');
        state = state.copyWith(user: user);
        return (true, null);
      },
    );
  }

  /// Change user password
  /// Returns (success, errorMessage) tuple
  Future<(bool, String?)> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    AppLogger.d('AuthNotifier', 'changePassword: Changing password');
    final result = await _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    return result.fold(
      (failure) {
        AppLogger.e('AuthNotifier', 'changePassword: Failed: ${failure.message}');
        return (false, failure.message);
      },
      (_) {
        AppLogger.d('AuthNotifier', 'changePassword: Success');
        return (true, null);
      },
    );
  }

  /// Map Failure types to AuthFailureType for UX handling
  AuthFailureType _mapFailureToType(Failure failure) {
    if (failure is NetworkFailure) {
      return AuthFailureType.networkError;
    } else if (failure is TimeoutFailure) {
      return AuthFailureType.networkError;
    } else if (failure is ServerFailure) {
      return AuthFailureType.serverError;
    } else if (failure is ValidationFailure) {
      return AuthFailureType.validationError;
    } else if (failure is AuthFailure) {
      return AuthFailureType.invalidCredentials;
    } else if (failure is UnauthorizedFailure) {
      return AuthFailureType.sessionExpired;
    } else {
      return AuthFailureType.unknown;
    }
  }
}
