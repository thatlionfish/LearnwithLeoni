import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../app_settings.dart';
import '../l10n/app_localizations.dart';
import '../l10n/gloss.dart';
import '../ui/theme.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      final t = AppLocalizations.of(context);
      final g = glossOf(context);
      final settings = AppScope.of(context).settings;
      final current = settings.helpLanguage ?? 'de';
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.settings, style: serif(24)),
              const SizedBox(height: 16),
              Glossed(
                t.helpLanguage,
                gloss: g?.helpLanguage,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Glossed(
                t.helpLanguageInfo,
                gloss: g?.helpLanguageInfo,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              RadioGroup<String>(
                groupValue: current,
                onChanged: (code) {
                  if (code != null) settings.choose(code);
                  Navigator.of(context).pop();
                },
                child: Column(
                  children: [
                    for (final code in AppSettings.helpLanguages)
                      RadioListTile<String>(
                        value: code,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          code == 'de'
                              ? t.helpNone
                              : helpLanguageNames[code] ?? code,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_outline),
                title: Glossed(t.privacy, gloss: g?.privacy),
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
