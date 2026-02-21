import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure({this.message, this.code});

  final String? message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

final class ServerFailure extends Failure {
  const ServerFailure({super.message, super.code, this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

final class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

final class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error'});
}

final class ValidationFailure extends Failure {
  const ValidationFailure({super.message, this.fieldErrors});

  final Map<String, String>? fieldErrors;

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}

final class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication failed', super.code});
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Unauthorized access'});
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Resource not found'});
}

final class ConflictFailure extends Failure {
  const ConflictFailure({super.message = 'Resource conflict'});
}

final class UnknownFailure extends Failure {
  const UnknownFailure({super.message = 'An unknown error occurred'});
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'Request timed out'});
}

final class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'Permission denied'});
}
