import '../../domain/entities/survey.dart';

abstract class SurveyRepository {
  Future<List<Survey>> getAllSurveys();
  Future<List<Survey>> getRecentSurveys({int limit = 5});
  Future<List<Survey>> getSurveysByStatus(SurveyStatus status);
  Future<List<Survey>> getInProgressSurveys();
  Future<List<Survey>> getCompletedSurveys();
  Future<Survey?> getSurveyById(String id);
  Future<int> getTotalSurveyCount();
  Future<int> getInProgressCount();
  Future<int> getCompletedCount();
}

class MockSurveyRepository implements SurveyRepository {
  final List<Survey> _mockSurveys = [
    Survey(
      id: '1',
      title: 'Riverside Property Inspection',
      type: SurveyType.inspection,
      status: SurveyStatus.inProgress,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      address: '123 Riverside Drive, Lagos',
      clientName: 'Adebayo & Sons Ltd',
      progress: 0.65,
      photoCount: 12,
      noteCount: 5,
    ),
    Survey(
      id: '2',
      title: 'Commercial Building Assessment',
      type: SurveyType.inspection,
      status: SurveyStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      completedAt: DateTime.now().subtract(const Duration(hours: 4)),
      address: '45 Victoria Island, Lagos',
      clientName: 'Sterling Properties',
      progress: 1,
      photoCount: 28,
      noteCount: 12,
    ),
    Survey(
      id: '3',
      title: 'Vehicle Fleet Valuation',
      type: SurveyType.other,
      status: SurveyStatus.inProgress,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      clientName: 'Dangote Transport',
      progress: 0.40,
      photoCount: 8,
      noteCount: 3,
    ),
    Survey(
      id: '4',
      title: 'Industrial Equipment Survey',
      type: SurveyType.other,
      status: SurveyStatus.pendingReview,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
      address: 'Apapa Industrial Zone',
      clientName: 'Zenith Manufacturing',
      progress: 1,
      photoCount: 45,
      noteCount: 18,
    ),
    Survey(
      id: '5',
      title: 'Residential Apartment Block',
      type: SurveyType.inspection,
      status: SurveyStatus.draft,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      address: '78 Lekki Phase 1',
      clientName: 'Oceanic Realty',
    ),
    Survey(
      id: '6',
      title: 'Mining Equipment Assessment',
      type: SurveyType.other,
      status: SurveyStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      completedAt: DateTime.now().subtract(const Duration(days: 3)),
      clientName: 'BUA Mining Corp',
      progress: 1,
      photoCount: 32,
      noteCount: 14,
    ),
    Survey(
      id: '7',
      title: 'Luxury Villa Inspection',
      type: SurveyType.inspection,
      status: SurveyStatus.inProgress,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      address: 'Banana Island, Ikoyi',
      clientName: 'Premium Estates',
      progress: 0.25,
      photoCount: 6,
      noteCount: 2,
    ),
    Survey(
      id: '8',
      title: 'Warehouse Facility Review',
      type: SurveyType.inspection,
      status: SurveyStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      completedAt: DateTime.now().subtract(const Duration(days: 5)),
      address: 'Ikeja Industrial Estate',
      clientName: 'GTBank PLC',
      progress: 1,
      photoCount: 20,
      noteCount: 8,
    ),
  ];

  @override
  Future<List<Survey>> getAllSurveys() async {
    await _simulateDelay();
    return List.from(_mockSurveys);
  }

  @override
  Future<List<Survey>> getRecentSurveys({int limit = 5}) async {
    await _simulateDelay();
    final sorted = List<Survey>.from(_mockSurveys)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<Survey>> getSurveysByStatus(SurveyStatus status) async {
    await _simulateDelay();
    return _mockSurveys.where((s) => s.status == status).toList();
  }

  @override
  Future<List<Survey>> getInProgressSurveys() async {
    await _simulateDelay();
    return _mockSurveys
        .where((s) =>
            s.status == SurveyStatus.inProgress ||
            s.status == SurveyStatus.draft,)
        .toList();
  }

  @override
  Future<List<Survey>> getCompletedSurveys() async {
    await _simulateDelay();
    return _mockSurveys
        .where((s) =>
            s.status == SurveyStatus.completed ||
            s.status == SurveyStatus.pendingReview ||
            s.status == SurveyStatus.approved,)
        .toList();
  }

  @override
  Future<Survey?> getSurveyById(String id) async {
    await _simulateDelay();
    try {
      return _mockSurveys.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> getTotalSurveyCount() async {
    await _simulateDelay();
    return _mockSurveys.length;
  }

  @override
  Future<int> getInProgressCount() async {
    await _simulateDelay();
    return _mockSurveys
        .where((s) =>
            s.status == SurveyStatus.inProgress ||
            s.status == SurveyStatus.draft,)
        .length;
  }

  @override
  Future<int> getCompletedCount() async {
    await _simulateDelay();
    return _mockSurveys
        .where((s) =>
            s.status == SurveyStatus.completed ||
            s.status == SurveyStatus.pendingReview ||
            s.status == SurveyStatus.approved,)
        .length;
  }

  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
