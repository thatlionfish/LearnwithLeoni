import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/data/models.dart';

/// Prüft alle Inhalte unter web/data, damit ein Fehler in einem neuen Set
/// nicht erst online auffällt.
void main() {
  final root = Directory('web/data/students');
  final students = [
    for (final d in root.listSync())
      if (d is Directory) d,
  ];

  test('Es gibt mindestens einen Schüler', () {
    expect(students, isNotEmpty);
  });

  for (final dir in students) {
    final code = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;

    test('Schüler $code: Profil und Sets sind gültig', () {
      expect(code, matches(RegExp(r'^[a-z0-9_-]{3,40}$')));
      final student = Student.fromJson(
        code,
        jsonDecode(File('${dir.path}/student.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      expect(student.name.trim(), isNotEmpty);
      expect(
        student.name.contains(' '),
        isFalse,
        reason: 'Nur Vorname/Spitzname, kein Nachname',
      );

      for (final id in student.setIds) {
        final file = File('${dir.path}/sets/$id.json');
        expect(file.existsSync(), isTrue, reason: 'Set $id fehlt');
        final set = VocabSet.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        );
        expect(set.id, id);
        expect(set.cards, isNotEmpty, reason: '$id hat keine Karten');

        final cardIds = set.cards.map((c) => c.id).toList();
        expect(
          cardIds.toSet().length,
          cardIds.length,
          reason: '$id: doppelte Karten-IDs',
        );
        for (final c in set.cards) {
          expect(c.term.trim(), isNotEmpty);
          expect(c.translation.trim(), isNotEmpty);
          if (c.audio != null) {
            expect(
              File('${dir.path}/${c.audio}').existsSync(),
              isTrue,
              reason: 'Audio fehlt: ${c.audio}',
            );
          }
        }
        for (final z in set.cloze) {
          expect(
            '___'.allMatches(z.text).length,
            1,
            reason: '${z.id}: genau eine Lücke',
          );
          expect(z.answers, isNotEmpty);
          if (z.options.isNotEmpty) {
            expect(
              z.options,
              contains(z.answers.first),
              reason: '${z.id}: Lösung nicht in der Auswahl',
            );
          }
        }
        for (final l in set.listening) {
          expect(l.questions, isNotEmpty);
          for (final q in l.questions) {
            expect(
              q.answer,
              inInclusiveRange(0, q.options.length - 1),
              reason: q.question,
            );
          }
        }
      }
    });
  }
}
