import 'package:flutter/widgets.dart';

import 'app_settings.dart';
import 'data/repository.dart';

/// Stellt Inhalte und Einstellungen allen Seiten zur Verfügung.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repository,
    required this.settings,
    required super.child,
  });

  final ContentRepository repository;
  final AppSettings settings;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope fehlt');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      old.repository != repository || old.settings != settings;
}
