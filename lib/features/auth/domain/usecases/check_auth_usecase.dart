import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CheckAuthUseCase {
  const CheckAuthUseCase(this._repository);

  final AuthRepository _repository;

  /// Check current authentication status.
  ///
  /// Returns:
  /// - Right(user) if authenticated and user profile fetched successfully
  /// - Right(null) if no token exists (not authenticated)
  /// - Left(failure) if token exists but failed to fetch user
  ///   (IMPORTANT: Failure type must be preserved for proper handling)
  Future<Either<Failure, User?>> call() async {
    final isAuthenticated = await _repository.isAuthenticated();
    if (!isAuthenticated) {
      return const Right(null);
    }

    // Token exists - try to get user profile
    final result = await _repository.getCurrentUser();
    return result.fold(
      // CRITICAL: Propagate the failure instead of swallowing it
      // This allows AuthNotifier to distinguish network errors from auth errors
      Left.new,
      Right.new,
    );
  }
}
