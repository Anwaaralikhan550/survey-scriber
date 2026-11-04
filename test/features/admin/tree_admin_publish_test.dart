// Mobile Survey Tree Management and the published tree.
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:survey_scriber/core/network/api_client.dart';
import 'package:survey_scriber/core/survey_tree/tree_sync.dart';
import 'package:survey_scriber/features/admin/data/tree_admin_repository.dart';

class _Api extends Mock implements ApiClient {}

class _Paths extends PathProviderPlatform {
  _Paths(this.docs);
  final String docs;
  @override
  Future<String?> getApplicationDocumentsPath() async => docs;
}

class _Store implements TreeStore {
  final files = <String, String>{};
  @override
  Future<String?> read(String name) async => files[name];
  @override
  Future<void> write(String name, String content) async => files[name] = content;
  @override
  Future<void> delete(String name) async => files.remove(name);
}

Response<Map<String, dynamic>> _reply(String path, Map<String, dynamic> data) =>
    Response(data: data, requestOptions: RequestOptions(path: path));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const type = SurveyTreeType.inspection;
  late _Api api;
  late _Store store;
  late TreeAdminRepository repo;
  late Directory dir;
  Map<String, dynamic>? sent;

  setUpAll(() => registerFallbackValue(Options()));

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tree_admin_');
    PathProviderPlatform.instance = _Paths(dir.path);
    api = _Api();
    store = _Store();
    sent = null;
    repo = TreeAdminRepository(apiClient: api, treeSync: TreeSync(apiClient: api, store: store));
    when(() => api.get<Map<String, dynamic>>('config/v2-tree/${type.key}/version'))
        .thenAnswer((_) async => _reply('v', {'version': 4}));
    when(() => api.post<Map<String, dynamic>>(
          'admin/config/v2-tree/upload',
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((call) async {
      sent = call.namedArguments[#data] as Map<String, dynamic>;
      return _reply('u', {'version': 5, 'checksum': 'new-sum'});
    });
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<String> firstScreenId() async {
    final tree = await repo.loadTree(type);
    return tree.sections.expand((s) => s.nodes).firstWhere((n) => n.fields.isNotEmpty).id;
  }

  test('edits start from what is published, not the old built-in tree', () async {
    final asset = jsonDecode(File(type.assetPath).readAsStringSync()) as Map<String, dynamic>;
    final first = ((asset['sections'] as List).first['nodes'] as List).first as Map<String, dynamic>;
    first['title'] = 'Published Title';
    asset['baseBundledVersion'] = type.bundledVersion;
    store.files['tree_${type.key}.json'] = jsonEncode(asset);

    final tree = await repo.loadTree(type);
    expect(tree.sections.first.nodes.first.title, 'Published Title');
  });

  test('publish says which app and which version the edits came from', () async {
    final id = await firstScreenId();
    await repo.updateScreenTitle(type, id, 'New title');
    await repo.publishTree(type);

    expect(sent!['treeType'], type.key);
    expect(sent!['baseVersion'], 4);
    expect((sent!['tree'] as Map)['baseBundledVersion'], type.bundledVersion);
  });

  test('after publishing this phone uses the server copy and has no draft left', () async {
    final id = await firstScreenId();
    await repo.updateScreenTitle(type, id, 'New title');
    expect(await repo.hasLocalOverride(type), isTrue);
    await repo.publishTree(type);

    expect(await repo.hasLocalOverride(type), isFalse);
    expect(store.files['tree_${type.key}.sha'], 'new-sum');
    final tree = await repo.loadTree(type);
    expect(tree.sections.expand((s) => s.nodes).firstWhere((n) => n.id == id).title, 'New title');
  });

  test('someone else published first: the draft stays and the error comes through', () async {
    when(() => api.post<Map<String, dynamic>>(
          'admin/config/v2-tree/upload',
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(Exception('409 Someone published version 5'));
    final id = await firstScreenId();
    await repo.updateScreenTitle(type, id, 'Mine');
    await expectLater(repo.publishTree(type), throwsException);
    expect(await repo.hasLocalOverride(type), isTrue);
    expect(store.files['tree_${type.key}.json'], isNull);
  });

  test('offline when the draft began: publish still works, with no version to compare', () async {
    when(() => api.get<Map<String, dynamic>>('config/v2-tree/${type.key}/version'))
        .thenThrow(Exception('offline'));
    final id = await firstScreenId();
    await repo.updateScreenTitle(type, id, 'Mine');
    await repo.publishTree(type);
    expect(sent!.containsKey('baseVersion'), isFalse);
  });

  test('reset throws the draft away', () async {
    final id = await firstScreenId();
    await repo.updateScreenTitle(type, id, 'Mine');
    await repo.resetToAsset(type);
    expect(await repo.hasLocalOverride(type), isFalse);
    final tree = await repo.loadTree(type);
    expect(tree.sections.expand((s) => s.nodes).firstWhere((n) => n.id == id).title, isNot('Mine'));
  });
}
