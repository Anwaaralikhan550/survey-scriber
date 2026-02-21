import '../../domain/entities/ai_response.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/ai_remote_datasource.dart';

/// Implementation of AI repository
class AiRepositoryImpl implements AiRepository {
  const AiRepositoryImpl(this._remoteDataSource);

  final AiRemoteDataSource _remoteDataSource;

  @override
  Future<AiStatus> getStatus() => _remoteDataSource.getStatus();

  @override
  Future<AiReportResponse> generateReport(GenerateReportRequest request) =>
      _remoteDataSource.generateReport(request);

  @override
  Future<AiRecommendationsResponse> generateRecommendations(
    GenerateRecommendationsRequest request,
  ) =>
      _remoteDataSource.generateRecommendations(request);

  @override
  Future<AiRiskSummaryResponse> generateRiskSummary(
    GenerateRiskSummaryRequest request,
  ) =>
      _remoteDataSource.generateRiskSummary(request);

  @override
  Future<AiConsistencyResponse> checkConsistency(
    ConsistencyCheckRequest request,
  ) =>
      _remoteDataSource.checkConsistency(request);

  @override
  Future<AiPhotoTagsResponse> generatePhotoTags(PhotoTagsRequest request) =>
      _remoteDataSource.generatePhotoTags(request);

  @override
  Future<AiProfessionalAnalysisResponse> analyzeProfessionally(
    ProfessionalAnalysisRequest request,
  ) =>
      _remoteDataSource.analyzeProfessionally(request);
}
