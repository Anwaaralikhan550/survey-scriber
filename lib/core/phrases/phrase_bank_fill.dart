import 'dart:convert';

/// A bank published by an admin replaces the bundled one on every phone. Wording the app
/// added after that publish is only in the bundled bank, so without this it would print
/// nothing (client file 6, 13 Nov 2026: Other Garden and Basement sentences were missing
/// on phones that had the live bank).
///
/// Keys the published bank has are never touched. Keys it lacks come from the bundled one.
Map<String, dynamic> fillMissingPhrases(
  Map<String, dynamic> published,
  Map<String, dynamic> bundled,
) {
  final pubTemplates = published['templates'];
  final bunTemplates = bundled['templates'];
  if (pubTemplates is Map<String, dynamic> && bunTemplates is Map<String, dynamic>) {
    // The valuation bank keeps its sentences under "templates".
    return {
      ...published,
      'templates': {
        for (final e in bunTemplates.entries)
          if (!pubTemplates.containsKey(e.key)) e.key: e.value,
        ...pubTemplates,
      },
    };
  }
  return {
    for (final e in bundled.entries)
      if (!published.containsKey(e.key)) e.key: e.value,
    ...published,
  };
}

/// Same, on the raw JSON text. Anything unreadable returns the published text unchanged.
String fillMissingPhrasesRaw(String publishedRaw, String bundledRaw) {
  try {
    final published = jsonDecode(publishedRaw);
    final bundled = jsonDecode(bundledRaw);
    if (published is! Map<String, dynamic> || bundled is! Map<String, dynamic>) {
      return publishedRaw;
    }
    return jsonEncode(fillMissingPhrases(published, bundled));
  } catch (_) {
    return publishedRaw;
  }
}
