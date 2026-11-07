import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/data/models.dart';
import 'package:learnwithleoni/learn/answer_check.dart';
import 'package:learnwithleoni/widgets/fide_picture.dart';

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
          // Kumachans Umschreibung darf das Wort nicht verraten.
          final word = c.term.replaceFirst(RegExp(r'^(der|die|das) '), '');
          if (c.hint != null) {
            expect(
              c.hint!.toLowerCase().contains(word.toLowerCase()),
              isFalse,
              reason: 'Tipp verrät „$word“',
            );
          }
          expect(c.translation.trim(), isNotEmpty);
          for (final a in [c.exampleAudio, c.gapAudio, c.hintAudio]) {
            if (a != null) {
              expect(
                File('${dir.path}/$a').existsSync(),
                isTrue,
                reason: 'Audio fehlt: $a',
              );
            }
          }
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
        for (final s in set.fide) {
          expect(s.items, isNotEmpty, reason: 'fide ${s.id}: keine Fragen');
          expect(s.level, anyOf('A2', 'B1'), reason: 'fide ${s.id}');
          for (final item in s.items) {
            final why = 'fide ${item.id}';
            expect(item.question.trim(), isNotEmpty, reason: why);
            // Wie im Test: A2 30–45 Wörter, B1 35–55 (mit etwas Spielraum).
            final words = item.text
                .replaceAll(RegExp(r'^[^:\n]{1,30}:', multiLine: true), '')
                .split(RegExp(r'\s+'))
                .where((w) => RegExp(r'[A-Za-zÄÖÜäöü0-9]').hasMatch(w))
                .length;
            expect(
              words,
              inInclusiveRange(25, 60),
              reason: '$why: $words Wörter',
            );
            if (s.level == 'A2') {
              expect(item.pictures, hasLength(3), reason: '$why: drei Bilder');
              expect(item.answer, inInclusiveRange(0, 2), reason: why);
              for (final p in item.pictures) {
                expect(
                  [
                    'clock',
                    'cal',
                    'week',
                    'price',
                    'text',
                    'icon',
                    'icons',
                    'count',
                  ],
                  contains(p.kind),
                  reason: '$why: unbekanntes Bild ${p.spec}',
                );
                for (final name in switch (p.kind) {
                  'icon' => [p.value],
                  'icons' => p.value.split(','),
                  'count' => [p.value.split(':').last],
                  _ => const <String>[],
                }) {
                  expect(
                    fideIcons.containsKey(name.trim()),
                    isTrue,
                    reason: '$why: kein Zeichen für „$name“',
                  );
                }
              }
            } else {
              expect(item.pictures, isEmpty, reason: why);
              expect(item.keywords, isNotEmpty, reason: '$why: Stichwörter');
              expect(item.model, isNotNull, reason: '$why: Musterantwort');
              expect(
                checkKeywords(item.model!, item.keywords),
                isTrue,
                reason: '$why: Musterantwort passt nicht zu den Stichwörtern',
              );
            }
            if (item.hint != null) {
              expect(item.hint!.trim(), isNotEmpty, reason: why);
            }
            if (item.audio != null) {
              expect(
                File('${dir.path}/${item.audio}').existsSync(),
                isTrue,
                reason: 'Audio fehlt: ${item.audio}',
              );
            }
          }
        }
      }
    });
  }

  test('Kumachans Satzsammlung: jede Aufnahme ist da', () {
    final index = File('web/data/kuma/index.json');
    expect(index.existsSync(), isTrue);
    final phrases =
        (jsonDecode(index.readAsStringSync())
                as Map<String, dynamic>)['phrases']
            as Map<String, dynamic>;
    expect(phrases, isNotEmpty);
    for (final file in phrases.values) {
      expect(File('web/data/$file').existsSync(), isTrue, reason: '$file');
    }
  });
}
