import '../data/leitner.dart';
import '../l10n/app_localizations.dart';

/// „22 Karten · 2 sicher · 3 gelernt · 4 im Lernen · 13 neu“.
String statsLine(AppLocalizations t, SetStats s) => [
  t.cardCount(s.total),
  if (s.secure > 0) '${s.secure} ${t.statSecure}',
  '${s.learned} ${t.statLearned}',
  '${s.learning} ${t.statLearning}',
  '${s.fresh} ${t.statNew}',
].join(' · ');
