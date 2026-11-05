import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../app_settings.dart';
import '../l10n/app_localizations.dart';
import '../ui/theme.dart';

/// Sprachnamen in der jeweiligen Sprache selbst.
const Map<String, String> nativeLanguageNames = {
  'de': 'Deutsch',
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'it': 'Italiano',
  'ja': '日本語',
  'pt': 'Português',
};

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      final t = AppLocalizations.of(context);
      final settings = AppScope.of(context).settings;
      final current = Localizations.localeOf(context).languageCode;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.settings, style: serif(24)),
              const SizedBox(height: 16),
              Text(t.language, style: Theme.of(context).textTheme.titleMedium),
              RadioGroup<String>(
                groupValue: current,
                onChanged: (code) {
                  if (code != null) settings.choose(Locale(code));
                  Navigator.of(context).pop();
                },
                child: Column(
                  children: [
                    for (final l in AppSettings.supported)
                      RadioListTile<String>(
                        value: l.languageCode,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          nativeLanguageNames[l.languageCode] ?? l.languageCode,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline),
                title: Text(t.privacy),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/datenschutz');
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
