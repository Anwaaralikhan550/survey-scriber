// Published survey tree on the phone: every way it can go wrong ends with the
// built-in tree, and a good one leaves the surveyor's work alone.
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:survey_scriber/core/database/app_database.dart' hide Survey;
import 'package:survey_scriber/core/network/api_client.dart';
import 'package:survey_scriber/core/survey_tree/tree_sync.dart';
import 'package:survey_scriber/features/property_inspection/data/inspection_repository.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/domain/section_visibility.dart';
import 'package:survey_scriber/features/property_valuation/data/valuation_repository.dart';

class _Api extends Mock implements ApiClient {}

class _MemoryStore implements TreeStore {
  final files = <String, String>{};
  bool failing = false;

  @override
  Future<String?> read(String name) async {
    if (failing) throw const FileSystemException('disk');
    return files[name];
  }

  @override
  Future<void> write(String name, String content) async {
    if (failing) throw const FileSystemException('disk');
    files[name] = content;
  }

  @override
  Future<void> delete(String name) async => files.remove(name);
}

const _type = 'inspection_v2';
const _bundled = InspectionRepository.bundledVersion;

Map<String, dynamic> _assetJson() => jsonDecode(
      File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
    ) as Map<String, dynamic>;

Map<String, dynamic> _published({int base = _bundled}) =>
    {..._assetJson(), 'baseBundledVersion': base};

Response<Map<String, dynamic>> _reply(Map<String, dynamic> data) => Response(
      data: data,
      requestOptions: RequestOptions(path: 'config/v2-tree/$_type'),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Api api;
  late _MemoryStore store;
  late TreeSync sync;

  void serverAnswers(Map<String, dynamic> data) {
    when(() => api.get<Map<String, dynamic>>(
          'config/v2-tree/$_type',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => _reply(data));
  }

  setUp(() {
    api = _Api();
    store = _MemoryStore();
    sync = TreeSync(apiClient: api, store: store);
  });

  group('receiving a tree', () {
    test('a good tree is kept and used', () async {
      serverAnswers({'version': 2, 'checksum': 'abc', 'tree': _published()});
      expect(await sync.refresh(_type, _bundled), isTrue);
      final tree = await sync.readUsable(_type, _bundled);
      expect(tree, isNotNull);
      expect(tree!.sections.length, _assetJson()['sections'].length);
    });

    test('next time it says what it has, and an unchanged answer changes nothing', () async {
      serverAnswers({'version': 2, 'checksum': 'abc', 'tree': _published()});
      await sync.refresh(_type, _bundled);
      serverAnswers({'version': 2, 'checksum': 'abc', 'unchanged': true});
      expect(await sync.refresh(_type, _bundled), isFalse);
      verify(() => api.get<Map<String, dynamic>>(
            'config/v2-tree/$_type',
            queryParameters: {'known': 'abc'},
          )).called(1);
      expect(await sync.readUsable(_type, _bundled), isNotNull);
    });

    test('offline changes nothing and does not throw', () async {
      serverAnswers({'version': 2, 'checksum': 'abc', 'tree': _published()});
      await sync.refresh(_type, _bundled);
      when(() => api.get<Map<String, dynamic>>(
            'config/v2-tree/$_type',
            queryParameters: any(named: 'queryParameters'),
          )).thenThrow(Exception('offline'));
      expect(await sync.refresh(_type, _bundled), isFalse);
      expect(await sync.readUsable(_type, _bundled), isNotNull);
    });

    test('a server error page is not stored', () async {
      serverAnswers({'message': 'Internal server error'});
      expect(await sync.refresh(_type, _bundled), isFalse);
      expect(await sync.readUsable(_type, _bundled), isNull);
    });

    test('a tree for another app version is not stored', () async {
      serverAnswers({'version': 2, 'checksum': 'abc', 'tree': _published(base: _bundled - 1)});
      expect(await sync.refresh(_type, _bundled), isFalse);
      expect(store.files, isEmpty);
    });

    test('a tree with no marker, like the old mobile publishes, is not stored', () async {
      serverAnswers({'version': 2, 'checksum': 'abc', 'tree': _assetJson()});
      expect(await sync.refresh(_type, _bundled), isFalse);
      expect(store.files, isEmpty);
    });

    test('a broken tree is not stored over a good one', () async {
      serverAnswers({'version': 2, 'checksum': 'abc', 'tree': _published()});
      await sync.refresh(_type, _bundled);
      serverAnswers({
        'version': 3,
        'checksum': 'bad',
        'tree': {'baseBundledVersion': _bundled, 'sections': []},
      });
      expect(await sync.refresh(_type, _bundled), isFalse);
      expect(store.files['tree_$_type.sha'], 'abc');
      expect(await sync.readUsable(_type, _bundled), isNotNull);
    });
  });

  group('reading the copy on the phone', () {
    Future<InspectionTreePayload?> readWith(String raw) async {
      store.files['tree_$_type.json'] = raw;
      return sync.readUsable(_type, _bundled);
    }

    test('nothing stored', () async {
      expect(await sync.readUsable(_type, _bundled), isNull);
    });

    test('bad JSON', () async {
      expect(await readWith('{not json'), isNull);
    });

    test('half a file, as after a crash', () async {
      final raw = jsonEncode(_published());
      expect(await readWith(raw.substring(0, raw.length ~/ 2)), isNull);
    });

    test('the wrong shape', () async {
      expect(await readWith('[1,2,3]'), isNull);
      expect(await readWith('{"baseBundledVersion":$_bundled,"sections":"x"}'), isNull);
    });

    test('no sections', () async {
      expect(await readWith('{"baseBundledVersion":$_bundled,"sections":[]}'), isNull);
    });

    test('no screens anywhere', () async {
      expect(
        await readWith('{"baseBundledVersion":$_bundled,"sections":[{"key":"A","title":"A","nodes":[]}]}'),
        isNull,
      );
    });

    test('an update to the app makes an old publish stop applying', () async {
      store.files['tree_$_type.json'] = jsonEncode(_published());
      expect(await sync.readUsable(_type, _bundled), isNotNull);
      expect(await sync.readUsable(_type, _bundled + 1), isNull);
    });

    test('a disk error', () async {
      store.failing = true;
      expect(await sync.readUsable(_type, _bundled), isNull);
    });
  });

  group('the repository', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    InspectionRepository repo() => InspectionRepository(db, treeSync: sync);

    Map<String, dynamic> withRenamedScreen() {
      final tree = _published();
      final sections = tree['sections'] as List;
      final node = (sections.first['nodes'] as List).first as Map<String, dynamic>;
      node['title'] = 'Renamed From The Admin';
      return tree;
    }

    test('uses the built-in tree when nothing is published', () async {
      final tree = await repo().loadTree();
      expect(tree.sections.length, _assetJson()['sections'].length);
    });

    test('uses the published tree when there is one', () async {
      store.files['tree_$_type.json'] = jsonEncode(withRenamedScreen());
      final tree = await repo().loadTree();
      expect(tree.sections.first.nodes.first.title, 'Renamed From The Admin');
    });

    test('a broken copy falls back to the built-in tree', () async {
      store.files['tree_$_type.json'] = '{oops';
      final tree = await repo().loadTree();
      expect(tree.sections.first.nodes.first.title, isNot('Renamed From The Admin'));
      expect(tree.sections, isNotEmpty);
    });

    test('with no documents folder at all it still works', () async {
      // The sync manager and the tests build it with no TreeSync; path_provider
      // is not there in a test.
      final tree = await InspectionRepository(db).loadTree();
      expect(tree.sections, isNotEmpty);
    });

    test('valuation has its own copy', () async {
      store.files['tree_$_type.json'] = jsonEncode(withRenamedScreen());
      final tree = await ValuationRepository(db, treeSync: sync).loadTree();
      expect(tree.sections.first.nodes.first.title, isNot('Renamed From The Admin'));
    });
  });

  group('a survey in progress when a tree arrives', () {
    late AppDatabase db;
    late InspectionRepository repository;
    const surveyId = 'survey-1';
    late String screenId;
    late String secondScreenId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = InspectionRepository(db, treeSync: sync);
      await db.into(db.surveys).insert(SurveysCompanion.insert(
            id: surveyId,
            title: 'Inspection',
            type: 'inspection',
            status: 'inProgress',
            createdAt: DateTime(2026, 11, 1),
          ));
      await repository.ensureSurveyInitialized(surveyId);
      final screens = (await repository.loadTree())
          .sections
          .expand((s) => s.nodes)
          .where((n) => n.type == InspectionNodeType.screen)
          .toList();
      screenId = screens[0].id;
      secondScreenId = screens[1].id;
      await repository.saveScreenAnswers(surveyId: surveyId, screenId: screenId, answers: {'a': 'Sunny'});
      await repository.setScreenCompleted(surveyId: surveyId, screenId: screenId, isCompleted: true);
      await repository.savePhraseOutput(
        surveyId: surveyId,
        screenId: screenId,
        phraseJson: '["edited"]',
        phraseEditedManually: true,
      );
      await (db.update(db.inspectionV2Screens)
            ..where((t) => t.surveyId.equals(surveyId) & t.screenId.equals(screenId)))
          .write(const InspectionV2ScreensCompanion(userNote: Value('my note')));
    });

    tearDown(() => db.close());

    Future<InspectionV2Screen?> row(String id) => (db.select(db.inspectionV2Screens)
          ..where((t) => t.surveyId.equals(surveyId) & t.screenId.equals(id)))
        .getSingleOrNull();

    Future<void> expectWorkKept() async {
      final r = (await row(screenId))!;
      expect(r.isCompleted, isTrue);
      expect(r.phraseOutput, '["edited"]');
      expect(r.phraseEditedManually, isTrue);
      expect(r.userNote, 'my note');
      final answers = await repository.getScreenAnswersMap(surveyId, screenId);
      expect(answers['a'], 'Sunny');
    }

    Future<void> receive(Map<String, dynamic> tree) async {
      store.files['tree_$_type.json'] = jsonEncode(tree);
      repository.invalidateCache();
      await repository.ensureSurveyInitialized(surveyId);
    }

    test('a screen renamed: work kept, new name shown', () async {
      final tree = _published();
      for (final s in tree['sections'] as List) {
        for (final n in s['nodes'] as List) {
          if (n['id'] == screenId) n['title'] = 'New Name';
        }
      }
      await receive(tree);
      await expectWorkKept();
      expect((await row(screenId))!.title, 'New Name');
    });

    test('a screen added: work kept, new one empty', () async {
      final tree = _published();
      final first = (tree['sections'] as List).first;
      (first['nodes'] as List).add({
        'id': 'brand_new',
        'title': 'Brand New',
        'type': 'screen',
        'parentId': null,
        'order': 999,
        'fields': <dynamic>[],
      });
      await receive(tree);
      await expectWorkKept();
      expect((await row('brand_new'))!.isCompleted, isFalse);
    });

    test('a screen removed: other work kept, its answers still safe', () async {
      await repository.saveScreenAnswers(surveyId: surveyId, screenId: secondScreenId, answers: {'b': 'Kept'});
      final tree = _published();
      for (final s in tree['sections'] as List) {
        (s['nodes'] as List).removeWhere((n) => n['id'] == secondScreenId);
      }
      await receive(tree);
      await expectWorkKept();
      expect(await row(secondScreenId), isNull);
      final stored = await repository.getScreenAnswersMap(surveyId, secondScreenId);
      expect(stored['b'], 'Kept');
    });

    test('and back to the built-in tree after a rollback: work still kept', () async {
      final tree = _published();
      (tree['sections'] as List).first['title'] = 'Changed';
      await receive(tree);
      store.files.remove('tree_$_type.json');
      repository.invalidateCache();
      await repository.ensureSurveyInitialized(surveyId);
      await expectWorkKept();
    });
  });

  test('the guard checks see the same tree through a published copy', () async {
    // The tree guard tests read the asset. A published copy of it must parse to
    // the very same screens, fields and options, so they hold for it too.
    final fromAsset = InspectionTreePayload.fromJson(jsonEncode(_assetJson()));
    final viaPublish = TreeSync.parseUsable(jsonEncode(_published()), _bundled)!;
    expect(viaPublish.toJsonString(), fromAsset.toJsonString());
    expect(visibleSectionNodes, isNotNull);
  });
}
