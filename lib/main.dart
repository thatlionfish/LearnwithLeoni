import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'app_scope.dart';
import 'app_settings.dart';
import 'data/repository.dart';
import 'l10n/app_localizations.dart';
import 'l10n/gloss.dart';
import 'games/abc/abc_screen.dart';
import 'games/hangman/hangman_screen.dart';
import 'screens/exercise_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/message_screen.dart';
import 'screens/set_screen.dart';
import 'ui/proportional_scale.dart';
import 'ui/theme.dart';
import 'widgets/leoni.dart';
import 'widgets/student_loader.dart';
import 'audio/speaker.dart';
import 'werkstatt/werkstatt_screens.dart';
import 'werkstatt/werkstatt_store.dart';

/// Werkstatt-Modus: nur lokal mit `--dart-define=WERKSTATT=true`.
const bool werkstatt = bool.fromEnvironment('WERKSTATT');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  // Werkstatt unter Windows: Inhalte direkt aus dem Projektordner.
  final store = werkstatt ? WerkstattStore.create() : null;
  if (store != null) {
    werkstattStore = store;
    Speaker.localRoot = store.projectRoot;
  }
  final repository = ContentRepository(
    store ?? HttpContentSource(),
    includeDrafts: werkstatt,
  );
  runApp(
    LearnWithLeoniApp(
      settings: settings,
      repository: repository,
      router: buildRouter(initialLocation: store != null ? '/werkstatt' : '/'),
    ),
  );
}

GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/werkstatt',
      redirect: (_, _) => werkstattStore == null ? '/' : null,
      builder: (_, _) => const WerkstattHome(),
      routes: [
        GoRoute(
          path: ':code/:setId',
          builder: (_, state) => WerkstattSetScreen(
            code: state.pathParameters['code']!,
            setId: state.pathParameters['setId']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/',
      builder: (context, _) {
        final t = AppLocalizations.of(context);
        // Ohne Schüler-Link: Englisch als Hilfe, ausser auf diesem Gerät
        // wurde etwas anderes gewählt.
        final g =
            glossOf(context) ??
            (AppScope.of(context).settings.chosen == null
                ? lookupAppLocalizations(const Locale('en'))
                : null);
        return MessageScreen(
          title: t.landingTitle,
          body: t.landingBody,
          titleGloss: g?.landingTitle,
          bodyGloss: g?.landingBody,
        );
      },
    ),
    GoRoute(
      path: '/datenschutz',
      builder: (context, _) {
        final t = AppLocalizations.of(context);
        return MessageScreen(
          title: t.privacy,
          body: t.privacyBody,
          showBack: true,
        );
      },
    ),
    GoRoute(
      path: '/s/:code',
      builder: (_, state) => HomeScreen(code: state.pathParameters['code']!),
      routes: [
        GoRoute(
          path: 'set/:setId',
          builder: (_, state) => SetScreen(
            code: state.pathParameters['code']!,
            setId: state.pathParameters['setId']!,
          ),
        ),
        GoRoute(
          path: 'ueben/:type',
          builder: (_, state) => ExerciseScreen(
            code: state.pathParameters['code']!,
            typeSlug: state.pathParameters['type']!,
            setId: state.uri.queryParameters['set'],
            textId: state.uri.queryParameters['text'],
          ),
        ),
        GoRoute(
          path: 'spiel/hangman',
          builder: (_, state) {
            final code = state.pathParameters['code']!;
            return StudentLoader(
              code: code,
              builder: (_, data) =>
                  HangmanScreen(code: code, sets: data.content.sets),
            );
          },
        ),
        GoRoute(
          path: 'spiel/abc-radio',
          builder: (_, state) {
            final code = state.pathParameters['code']!;
            return StudentLoader(
              code: code,
              builder: (_, data) => AbcRadioScreen(
                code: code,
                student: data.content.student,
                sets: data.content.sets,
              ),
            );
          },
        ),
        GoRoute(
          path: 'lernen',
          builder: (_, state) => LearnScreen(
            code: state.pathParameters['code']!,
            setId: state.uri.queryParameters['set'],
          ),
        ),
        // Platzhalter für Übungen und Spiele, die in den nächsten Etappen kommen.
        GoRoute(
          path: 'bald/:what',
          builder: (context, _) {
            final t = AppLocalizations.of(context);
            return MessageScreen(
              title: t.comingSoon,
              body: t.comingSoonBody,
              showBack: true,
              pose: LeoniPose.read,
            );
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, _) {
    final t = AppLocalizations.of(context);
    final g = glossOf(context);
    return MessageScreen(
      title: t.notFoundTitle,
      body: t.notFoundBody,
      titleGloss: g?.notFoundTitle,
      bodyGloss: g?.notFoundBody,
      pose: LeoniPose.shrug,
    );
  },
);

class LearnWithLeoniApp extends StatefulWidget {
  const LearnWithLeoniApp({
    super.key,
    required this.settings,
    required this.repository,
    this.router,
  });

  final AppSettings settings;
  final ContentRepository repository;
  final GoRouter? router;

  @override
  State<LearnWithLeoniApp> createState() => _LearnWithLeoniAppState();
}

class _LearnWithLeoniAppState extends State<LearnWithLeoniApp> {
  late final GoRouter _router = widget.router ?? buildRouter();
  final ThemeData _theme = buildLeoTheme();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      repository: widget.repository,
      settings: widget.settings,
      child: HelpScope(
        settings: widget.settings,
        child: MaterialApp.router(
          title: 'LearnwithLeoni',
          debugShowCheckedModeBanner: false,
          theme: _theme,
          themeMode: ThemeMode.light,
          // Immer Deutsch – die Hilfesprache steht nur klein daneben.
          locale: AppSettings.uiLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
          // Auf grossen Bildschirmen alles gleichmässig grösser zeichnen,
          // damit die App nicht als kleine Spalte in viel Leere steht.
          builder: (context, child) => ProportionalScale(child: child!),
        ),
      ),
    );
  }
}
