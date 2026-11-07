import '../data/repository.dart';

/// Kumachans vorab aufgenommene Sätze (`data/kuma/index.json`, erzeugt von
/// `tool/tts.dart`): Satz → Aufnahme mit ihrer Kinderstimme.
abstract final class KumaVoice {
  static Map<String, String>? _phrases;
  static Future<void>? _loading;

  /// Einmal laden; danach findet [urlFor] die Aufnahmen sofort.
  static Future<void> preload(ContentRepository repository) =>
      _loading ??= () async {
        try {
          final json = await repository.shared('kuma/index.json');
          final p = json?['phrases'];
          _phrases = {
            if (p is Map)
              for (final e in p.entries)
                if (e.value is String) '${e.key}': e.value as String,
          };
        } catch (_) {
          _phrases = const {};
        }
      }();

  /// Adresse der Aufnahme zu [text], sonst `null` (dann Browser-Stimme).
  static String? urlFor(String text) {
    final file = _phrases?[text.trim()];
    return file == null ? null : 'data/$file';
  }

  /// Nur für Tests.
  static void reset() {
    _phrases = null;
    _loading = null;
  }
}
