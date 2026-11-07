import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

/// Geräteweite Einstellungen.
///
/// Die Oberfläche ist immer deutsch – der Fokus liegt auf der Zielsprache.
/// Die **Hilfesprache** (Erklärsprache) erscheint nur klein daneben. Ohne
/// eigene Wahl gilt die Erklärsprache des Schülers.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._chosen);

  static const _helpKey = 'settings/help';
  static const _directionKey = 'settings/germanFront';

  /// Oberflächensprache.
  static const Locale uiLocale = Locale('de');

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(prefs, prefs.getString(_helpKey));
  }

  final SharedPreferences _prefs;
  String? _chosen;
  String? _studentDefault;

  /// Sprachen, in denen es Hilfetexte gibt (`de` = keine Hilfe).
  static List<String> get helpLanguages => [
    for (final l in AppLocalizations.supportedLocales) l.languageCode,
  ];

  static bool isSupported(String code) => helpLanguages.contains(code);

  /// `null` = keine Hilfesprache, nur Deutsch.
  String? get helpLanguage {
    final code = _chosen ?? _studentDefault;
    return code == null || code == 'de' || !isSupported(code) ? null : code;
  }

  /// Eigene Wahl auf diesem Gerät (`de` = nur Deutsch), sonst `null`.
  String? get chosen => _chosen;

  void setStudentDefault(String languageCode) {
    if (languageCode == _studentDefault) return;
    _studentDefault = languageCode;
    if (_chosen == null) {
      // Während des Bauens der Seite aufgerufen: erst danach benachrichtigen.
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  Future<void> choose(String languageCode) async {
    _chosen = languageCode;
    notifyListeners();
    await _prefs.setString(_helpKey, languageCode);
  }

  /// Lernkarten: Deutsch vorne (Standard) oder hinten.
  bool get germanFront => _prefs.getBool(_directionKey) ?? true;

  Future<void> setGermanFront(bool value) async {
    await _prefs.setBool(_directionKey, value);
    notifyListeners();
  }
}

/// Macht Änderungen der Hilfesprache für alle Seiten sichtbar.
class HelpScope extends InheritedNotifier<AppSettings> {
  const HelpScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static String? languageOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<HelpScope>()
      ?.notifier
      ?.helpLanguage;
}
