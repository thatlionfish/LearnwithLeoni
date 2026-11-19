/// Gemeinsame Themen-Bibliothek unter `web/data/themen/<id>/thema.json`.
///
/// Ein Thema (z. B. „Gesundheit“) wird einmal geschrieben und von mehreren
/// Schülern genutzt. Übersetzungen stehen für jede Hilfesprache im selben
/// Feld, z. B. `"translation": {"en": "doctor", "ja": "医者"}`; Audio-Pfade
/// sind relativ zum Themenordner (`audio/tts/…`).
library;

/// Felder mit einer Übersetzung je Hilfesprache.
const translatedKeys = {
  'translation',
  'exampleTranslation',
  'titleTranslation',
  'situationTranslation',
  'questionTranslation',
  'modelTranslation',
};

/// Felder mit einem Audio-Pfad.
const audioKeys = {'audio', 'exampleAudio', 'gapAudio', 'hintAudio'};

/// Sprachen, in die jedes Thema übersetzt ist (ein Test prüft das).
const libraryLanguages = ['en', 'ja'];

/// Ordner eines Themas, relativ zu `data/`.
String themeDir(String id) => 'themen/$id';

/// Ein Thema für einen Schüler: Übersetzungen in [language] (sonst Englisch)
/// und – mit [audioPrefix] – Audio-Pfade relativ zu `data/`.
Map<String, dynamic> localizeTheme(
  Map<String, dynamic> json,
  String language, {
  String? audioPrefix,
}) => _walk(json, language, audioPrefix) as Map<String, dynamic>;

/// Die Übersetzung in [language], sonst Englisch, sonst die erste.
String? pickLanguage(Map<dynamic, dynamic> byLanguage, String language) =>
    (byLanguage[language] ??
            byLanguage['en'] ??
            (byLanguage.isEmpty ? null : byLanguage.values.first))
        as String?;

Object? _walk(Object? value, String language, String? audioPrefix) {
  if (value is List) {
    return [for (final v in value) _walk(v, language, audioPrefix)];
  }
  if (value is Map<String, dynamic>) {
    return <String, dynamic>{
      for (final MapEntry(:key, value: v) in value.entries)
        key: switch (v) {
          final Map<dynamic, dynamic> m when translatedKeys.contains(key) =>
            pickLanguage(m, language),
          final String path
              when audioPrefix != null && audioKeys.contains(key) =>
            '$audioPrefix/$path',
          _ => _walk(v, language, audioPrefix),
        },
    };
  }
  return value;
}
