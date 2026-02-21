import '../../domain/entities/client.dart';
import '../../domain/entities/client_booking.dart';
import '../../domain/entities/client_report.dart';
import '../../domain/repositories/client_portal_repository.dart';
import '../datasources/client_portal_remote_datasource.dart';

/// Implementation of ClientPortalRepository
class ClientPortalRepositoryImpl implements ClientPortalRepository {
  const ClientPortalRepositoryImpl(this._remoteDataSource);

  final ClientPortalRemoteDataSource _remoteDataSource;

  @override
  Future<void> requestMagicLink(String email) => _remoteDataSource.requestMagicLink(email);

  @override
  Future<ClientAuthResult> verifyMagicLink(String token) async {
    final response = await _remoteDataSource.verifyMagicLink(token);
    return ClientAuthResult(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      expiresIn: response.expiresIn,
      client: response.client,
    );
  }

  @override
  Future<ClientAuthResult> refreshToken(String refreshToken) async {
    final response = await _remoteDataSource.refreshToken(refreshToken);
    return ClientAuthResult(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      expiresIn: response.expiresIn,
      client: response.client,
    );
  }

  @override
  Future<void> logout(String refreshToken) => _remoteDataSource.logout(refreshToken);

  @override
  Future<Client> getProfile() => _remoteDataSource.getProfile();

  @override
  Future<ClientBookingsResult> getBookings({
    ClientBookingStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _remoteDataSource.getBookings(
      status: status,
      page: page,
      limit: limit,
    );
    return ClientBookingsResult(
      bookings: response.bookings,
      page: response.page,
      limit: response.limit,
      total: response.total,
      totalPages: response.totalPages,
    );
  }

  @override
  Future<ClientBooking> getBooking(String id) => _remoteDataSource.getBooking(id);

  @override
  Future<ClientReportsResult> getReports({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _remoteDataSource.getReports(
      page: page,
      limit: limit,
    );
    return ClientReportsResult(
      reports: response.reports,
      page: response.page,
      limit: response.limit,
      total: response.total,
      totalPages: response.totalPages,
    );
  }

  @override
  Future<ClientReport> getReport(String id) => _remoteDataSource.getReport(id);

  @override
  Future<List<int>> downloadReportPdf(String id) async {
    final bytes = await _remoteDataSource.downloadReportPdf(id);
    if (bytes == null) {
      throw Exception('PDF not yet available. The surveyor needs to export the report first.');
    }
    return bytes;
  }
}
