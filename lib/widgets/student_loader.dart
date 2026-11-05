import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/leitner.dart';
import '../data/repository.dart';
import '../l10n/app_localizations.dart';
import '../screens/message_screen.dart';
import '../ui/colors.dart';
import 'leoni.dart';

/// Alles, was eine Schüler-Seite braucht.
class StudentData {
  const StudentData(this.content, this.progress, this.days);
  final StudentContent content;
  final ProgressStore progress;
  final PracticeDays days;
}

/// Lädt Inhalte und Lernstand eines Schülers und zeigt Ladezustand bzw. Fehler.
class StudentLoader extends StatefulWidget {
  const StudentLoader({super.key, required this.code, required this.builder});

  final String code;
  final Widget Function(BuildContext context, StudentData data) builder;

  @override
  State<StudentLoader> createState() => _StudentLoaderState();
}

class _StudentLoaderState extends State<StudentLoader> {
  Future<StudentData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<StudentData> _load() async {
    final scope = AppScope.of(context);
    final results = await Future.wait([
      scope.repository.student(widget.code),
      ProgressStore.open(widget.code),
      PracticeDays.open(widget.code),
    ]);
    final content = results[0] as StudentContent;
    scope.settings.setStudentDefault(content.student.explainLanguage);
    return StudentData(
      content,
      results[1] as ProgressStore,
      results[2] as PracticeDays,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<StudentData>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return snap.error is StudentNotFound
              ? MessageScreen(
                  title: t.notFoundTitle,
                  body: t.notFoundBody,
                  pose: LeoniPose.shrug,
                )
              : MessageScreen(
                  title: t.loadErrorTitle,
                  body: t.loadErrorBody,
                  actionLabel: t.retry,
                  onAction: () => setState(() => _future = _load()),
                  pose: LeoniPose.shrug,
                );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LeoColors.woodAsh,
                ),
              ),
            ),
          );
        }
        return widget.builder(context, snap.data!);
      },
    );
  }
}
