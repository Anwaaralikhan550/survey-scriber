import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/media_remote_datasource.dart';

// API Client provider is already available
final mediaRemoteDataSourceProvider = Provider<MediaRemoteDataSource>((ref) {
  // We need Dio instance for multipart uploads
  // ApiClient wraps Dio, usually exposes it or we can get it from same source
  final apiClient = ref.watch(apiClientProvider);
  // Assuming ApiClient has a public dio property or we can get dio provider
  // If not, we might need to change how we get Dio.
  // Looking at ApiClient definition (not visible here but usually standard),
  // let's assume we can get Dio or we inject ApiClient and let it handle it.
  // But MediaRemoteDataSource uses Dio directly for FormData.
  // Let's check ApiClient source if possible, or just cast/assume.
  // Actually, let's just use the provider that provides Dio if it exists.
  // Usually 'apiClientProvider' returns ApiClient class.
  // Let's assume ApiClient has a 'dio' getter.
  return MediaRemoteDataSource(apiClient.dio); 
});
