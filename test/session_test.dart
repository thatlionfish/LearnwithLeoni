import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/data/leitner.dart';
import 'package:learnwithleoni/data/models.dart';
import 'package:learnwithleoni/learn/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

VocabSet makeSet(int cards) => VocabSet(
  id: 's',
  title: 'Set',
  titleTranslation: '',
  variety: Variety.de,
  published: true,
  cards: [
    for (var i = 0; i < cards; i++)
      VocabCard(id: 'c$i', term: 'Wort $i', translation: 'word $i'),
  ],
);

void main() {
  final monday = DateTime(2026, 11, 2, 9);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProgressStore.resetCache();
  });

  test('höchstens 10 neue Karten pro Sitzung', () async {
    final store = await ProgressStore.open('a');
    final s = LearnSession.build([makeSet(14)], store, now: monday);
    expect(s.total, 10);
  });

  test('fällige Karten kommen vor neuen', () async {
    final set = makeSet(3);
    final store = await ProgressStore.open('a');
    await store.record(set, set.cards[2], Grade.didNotKnow, now: monday);
    final s = LearnSession.build([set], store, now: DateTime(2026, 11, 3));
    expect(s.current!.card.id, 'c2');
    expect(s.total, 3);
  });

  test('nur die erste Antwort zählt, Nicht-Gewusstes kommt wieder', () async {
    final set = makeSet(2);
    final store = await ProgressStore.open('a');
    final s = LearnSession.build([set], store, now: monday);
    final recorded = <String>[];
    void rec(SessionItem i, Grade g) => recorded.add('${i.card.id}:${g.name}');

    s.answer(Grade.didNotKnow, rec); // c0 kommt wieder
    expect(s.isDone, isFalse);
    s.answer(Grade.knew, rec); // c1
    expect(s.current!.card.id, 'c0');
    s.answer(Grade.knew, rec); // c0 Wiederholung: zählt nicht nochmal
    expect(s.isDone, isTrue);
    expect(recorded, ['c0:didNotKnow', 'c1:knew']);
    expect((s.knew, s.almost, s.notKnown), (1, 0, 1));
  });

  test('Leoni lobt nach 3 richtigen und muntert nach 2 Fehlern auf', () async {
    final store = await ProgressStore.open('a');
    final s = LearnSession.build([makeSet(8)], store, now: monday);
    void rec(SessionItem _, Grade _) {}
    expect(s.answer(Grade.knew, rec), isNull);
    expect(s.answer(Grade.knew, rec), isNull);
    expect(s.answer(Grade.knew, rec), LeoniMoment.streak);
    expect(s.answer(Grade.didNotKnow, rec), isNull);
    expect(s.answer(Grade.didNotKnow, rec), LeoniMoment.encourage);
  });

  test('Lernserie zählt aufeinanderfolgende Tage', () async {
    final days = await PracticeDays.open('a');
    await days.markToday(now: DateTime(2026, 11, 1));
    await days.markToday(now: DateTime(2026, 11, 2));
    await days.markToday(now: DateTime(2026, 11, 3));
    expect(days.streak(now: DateTime(2026, 11, 3)), 3);
    // Heute noch nicht geübt: Serie von gestern zählt noch.
    expect(days.streak(now: DateTime(2026, 11, 4)), 3);
    expect(days.streak(now: DateTime(2026, 11, 5)), 0);
  });
}
