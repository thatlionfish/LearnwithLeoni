import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/data/library.dart';
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

      expect(
        [
          for (final id in student.setIds)
            if (File('${dir.path}/sets/$id.json').existsSync() &&
                (jsonDecode(
                      File('${dir.path}/sets/$id.json').readAsStringSync(),
                    ) as Map<String, dynamic>)['collection'] ==
                    true)
              id,
        ].length,
        lessThanOrEqualTo(1),
        reason: 'Höchstens eine Sammlung einzelner Wörter',
      );

      for (final id in student.setIds) {
        final file = File('${dir.path}/sets/$id.json');
        expect(file.existsSync(), isTrue, reason: 'Set $id fehlt');
        final set = VocabSet.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        );
        expect(set.id, id);
        checkSet(set, dir.path);
        // Ein Zusatz gehört zu einem Thema dieses Schülers.
        if (set.topic != null) {
          expect(
            [...student.themeIds, ...student.setIds],
            contains(set.topic),
            reason: '$id: Thema ${set.topic} fehlt im Profil',
          );
        }
      }
      for (final id in student.themeIds) {
        expect(
          File('web/data/themen/$id/thema.json').existsSync(),
          isTrue,
          reason: 'Thema $id fehlt in der Bibliothek',
        );
      }
    });
  }

  final library = Directory('web/data/themen');
  final themes = [
    if (library.existsSync())
      for (final d in library.listSync())
        if (d is Directory) d,
  ];
  for (final dir in themes) {
    final id = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    test('Bibliothek $id: gültig in jeder Hilfesprache', () {
      final file = File('${dir.path}/thema.json');
      expect(file.existsSync(), isTrue, reason: 'thema.json fehlt');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['id'], id);
      // Jede Übersetzung gibt es in allen Sprachen der Bibliothek.
      void walk(Object? v, String where) {
        if (v is List) {
          for (final (i, x) in v.indexed) {
            walk(x, '$where[$i]');
          }
        } else if (v is Map<String, dynamic>) {
          for (final MapEntry(:key, :value) in v.entries) {
            if (translatedKeys.contains(key)) {
              expect(value, isA<Map<String, dynamic>>(), reason: '$where.$key');
              for (final lang in libraryLanguages) {
                expect(
                  ((value as Map)[lang] as String?)?.trim(),
                  isNotEmpty,
                  reason: '$where.$key: $lang fehlt',
                );
              }
            } else {
              walk(value, '$where.$key');
            }
          }
        }
      }

      walk(json, id);
      for (final lang in libraryLanguages) {
        final set = VocabSet.fromJson(localizeTheme(json, lang));
        expect(set.variety, Variety.de, reason: 'fide-Themen sind Hochdeutsch');
        checkSet(set, dir.path);
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

/// Gemeinsame Prüfung für Schüler-Sets und Bibliotheksthemen; Audio-Pfade
/// sind relativ zu [dir].
void checkSet(VocabSet set, String dir) {
  final id = set.id;
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
        expect(File('$dir/$a').existsSync(), isTrue, reason: 'Audio fehlt: $a');
      }
    }
    if (c.audio != null) {
      expect(
        File('$dir/${c.audio}').existsSync(),
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
      expect(words, inInclusiveRange(25, 60), reason: '$why: $words Wörter');
      if (s.level == 'A2') {
        expect(item.pictures, hasLength(3), reason: '$why: drei Bilder');
        expect(item.answer, inInclusiveRange(0, 2), reason: why);
        for (final p in item.pictures) {
          expect(
            ['clock', 'cal', 'week', 'price', 'text', 'icon', 'icons', 'count'],
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
          File('$dir/${item.audio}').existsSync(),
          isTrue,
          reason: 'Audio fehlt: ${item.audio}',
        );
      }
    }
  }
}
