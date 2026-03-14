class LegacyMainWallsDecodedAnswer {
  const LegacyMainWallsDecodedAnswer({
    required this.screenId,
    required this.localAnswers,
  });

  final String screenId;
  final Map<String, String> localAnswers;
}

class LegacyMainWallsSyncMapping {
  LegacyMainWallsSyncMapping._();

  static const String solidBrickScreenId =
      'activity_outside_property_main_walls_about_wall';
  static const String cavityBrickScreenId =
      'activity_outside_property_main_walls_about_wall__cavity_brick_wall';
  static const String cavityBlockScreenId =
      'activity_outside_property_main_walls_about_wall__cavity_block_wall';
  static const String cavityStudScreenId =
      'activity_outside_property_main_walls_about_wall__cavity_stud_wall';
  static const String otherScreenId =
      'activity_outside_property_main_walls_about_wall__other';

  static const Set<String> screenIds = <String>{
    solidBrickScreenId,
    cavityBrickScreenId,
    cavityBlockScreenId,
    cavityStudScreenId,
    otherScreenId,
  };

  static const Map<String, String> _screenPrefixes = <String, String>{
    solidBrickScreenId: 'mw_sbbw',
    cavityBrickScreenId: 'mw_cbrw',
    cavityBlockScreenId: 'mw_cblw',
    cavityStudScreenId: 'mw_csw',
    otherScreenId: 'mw_othw',
  };

  static bool handlesScreen(String screenId) => screenIds.contains(screenId);

  static Map<String, String>? buildRemoteAnswers(
    String screenId,
    Map<String, String> localAnswers,
  ) {
    final prefix = _screenPrefixes[screenId];
    if (prefix == null) return null;

    final remote = <String, String>{};

    if (screenId == otherScreenId) {
      final wallName = (localAnswers['other'] ?? '').trim();
      if (wallName.isNotEmpty) {
        remote['${prefix}_wall_name'] = wallName;
      }
    }

    final locations = <String>[];
    if (_isChecked(localAnswers['cb_main_building'])) {
      locations.add('Main building');
    }
    if (_isChecked(localAnswers['cb_back_addition'])) {
      locations.add('Back addition');
    }
    if (_isChecked(localAnswers['cb_extension'])) {
      locations.add('Extension');
    }
    if (_isChecked(localAnswers['cb_other_832'])) {
      final other = (localAnswers['et_other_133'] ?? '').trim();
      if (other.isNotEmpty) {
        locations.add(other);
      }
    }
    if (locations.isNotEmpty) {
      remote['${prefix}_wall'] = locations.join(', ');
    }

    final thickness = (localAnswers['et_thickness'] ?? '').trim();
    if (thickness.isNotEmpty) {
      remote['${prefix}_thickness'] = thickness;
    }

    final finishes = (localAnswers['actv_finishes'] ?? '').trim();
    if (finishes.isNotEmpty) {
      remote['${prefix}_finishes'] = finishes;
    }

    final rendered = (localAnswers['actv_rendered'] ?? '').trim();
    if (rendered.isNotEmpty) {
      remote['${prefix}_rendered'] = rendered;
    }

    final finishesTypes = <String>[];
    if (_isChecked(localAnswers['cb_painted'])) {
      finishesTypes.add('Painted');
    }
    if (_isChecked(localAnswers['cb_pebble_dash'])) {
      finishesTypes.add('Pebble dash');
    }
    if (_isChecked(localAnswers['cb_mock_tudor'])) {
      finishesTypes.add('Mock Tudor Wall');
    }
    if (_isChecked(localAnswers['cb_other_327'])) {
      final other = (localAnswers['et_other_444'] ?? '').trim();
      if (other.isNotEmpty) {
        finishesTypes.add(other);
      }
    }
    if (finishesTypes.isNotEmpty) {
      remote['${prefix}_finishes_type'] = finishesTypes.join(', ');
    }

    if (_isChecked(localAnswers['cb_is_weathered'])) {
      remote['${prefix}_wathered_wall'] = 'true';
    }

    final condition = (localAnswers['actv_condition'] ?? '').trim();
    if (condition.isNotEmpty) {
      remote['${prefix}_condition'] = condition;
    }

    return remote;
  }

  static LegacyMainWallsDecodedAnswer? decodeRemoteAnswer(
    String questionKey,
    String value,
  ) {
    final match = RegExp(r'^(mw_(?:sbbw|cbrw|cblw|csw|othw))_(.+)$')
        .firstMatch(questionKey);
    if (match == null) return null;

    final prefix = match.group(1)!;
    final suffix = match.group(2)!;
    final screenId = _screenForPrefix(prefix);
    if (screenId == null) return null;

    final trimmedValue = value.trim();
    final localAnswers = <String, String>{};

    switch (suffix) {
      case 'wall_name':
        if (screenId == otherScreenId) {
          localAnswers['other'] = trimmedValue;
        }
        break;
      case 'wall':
        localAnswers.addAll(_decodeLocations(trimmedValue));
        break;
      case 'thickness':
        localAnswers['et_thickness'] = trimmedValue;
        break;
      case 'finishes':
        localAnswers['actv_finishes'] = trimmedValue;
        break;
      case 'rendered':
        localAnswers['actv_rendered'] = trimmedValue;
        break;
      case 'finishes_type':
        localAnswers.addAll(_decodeFinishesTypes(trimmedValue));
        break;
      case 'wathered_wall':
        localAnswers['cb_is_weathered'] =
            trimmedValue.isNotEmpty ? 'true' : 'false';
        break;
      case 'condition':
        localAnswers['actv_condition'] = trimmedValue;
        break;
      default:
        return null;
    }

    if (localAnswers.isEmpty) return null;
    return LegacyMainWallsDecodedAnswer(
      screenId: screenId,
      localAnswers: localAnswers,
    );
  }

  static String? _screenForPrefix(String prefix) {
    for (final entry in _screenPrefixes.entries) {
      if (entry.value == prefix) return entry.key;
    }
    return null;
  }

  static Map<String, String> _decodeLocations(String raw) {
    final decoded = <String, String>{
      'cb_main_building': 'false',
      'cb_back_addition': 'false',
      'cb_extension': 'false',
      'cb_other_832': 'false',
      'et_other_133': '',
    };

    final other = <String>[];
    for (final token in _splitCsv(raw)) {
      final normalized = token.toLowerCase();
      if (normalized == 'main building') {
        decoded['cb_main_building'] = 'true';
      } else if (normalized == 'back addition') {
        decoded['cb_back_addition'] = 'true';
      } else if (normalized == 'extension') {
        decoded['cb_extension'] = 'true';
      } else {
        other.add(token);
      }
    }

    if (other.isNotEmpty) {
      decoded['cb_other_832'] = 'true';
      decoded['et_other_133'] = other.join(', ');
    }

    return decoded;
  }

  static Map<String, String> _decodeFinishesTypes(String raw) {
    final decoded = <String, String>{
      'cb_painted': 'false',
      'cb_pebble_dash': 'false',
      'cb_mock_tudor': 'false',
      'cb_other_327': 'false',
      'et_other_444': '',
    };

    final other = <String>[];
    for (final token in _splitCsv(raw)) {
      final normalized = token.toLowerCase();
      if (normalized == 'painted') {
        decoded['cb_painted'] = 'true';
      } else if (normalized == 'pebble dash') {
        decoded['cb_pebble_dash'] = 'true';
      } else if (normalized == 'mock tudor wall') {
        decoded['cb_mock_tudor'] = 'true';
      } else {
        other.add(token);
      }
    }

    if (other.isNotEmpty) {
      decoded['cb_other_327'] = 'true';
      decoded['et_other_444'] = other.join(', ');
    }

    return decoded;
  }

  static List<String> _splitCsv(String raw) => raw
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  static bool _isChecked(String? value) =>
      (value ?? '').trim().toLowerCase() == 'true';
}
