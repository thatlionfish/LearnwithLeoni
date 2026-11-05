import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

/// Geräteweite Einstellungen: Sprache der Oberfläche.
///
/// Ohne eigene Wahl gilt die Erklärsprache des Schülers, sonst Englisch.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._chosen);

  static const _localeKey = 'settings/locale';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    return AppSettings._(prefs, code == null ? null : Locale(code));
  }

  final SharedPreferences _prefs;
  Locale? _chosen;
  Locale? _studentDefault;

  static List<Locale> get supported => AppLocalizations.supportedLocales;

  static bool isSupported(String code) =>
      supported.any((l) => l.languageCode == code);

  /// `null` = Systemsprache (nur auf der Startseite ohne Schüler-Link).
  Locale? get locale => _chosen ?? _studentDefault;

  Locale? get chosen => _chosen;

  void setStudentDefault(String languageCode) {
    final next = isSupported(languageCode)
        ? Locale(languageCode)
        : const Locale('en');
    if (next == _studentDefault) return;
    _studentDefault = next;
    if (_chosen == null) {
      // Während des Bauens der Seite aufgerufen: erst danach benachrichtigen.
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  Future<void> choose(Locale locale) async {
    _chosen = locale;
    notifyListeners();
    await _prefs.setString(_localeKey, locale.languageCode);
  }
}
