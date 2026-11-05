import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/data/leitner.dart';
import 'package:learnwithleoni/data/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final monday = DateTime(2026, 11, 2, 15, 30);

  group('Leitner.review', () {
    test('neue Karte gewusst → Fach 2, in 2 Tagen', () {
      final s = Leitner.review(null, Grade.knew, now: monday);
      expect(s.box, 2);
      expect(s.due, DateTime(2026, 11, 4));
    });

    test('nicht gewusst → zurück in Fach 1, morgen', () {
      final s = Leitner.review(
        CardState(box: 4, due: monday),
        Grade.didNotKnow,
        now: monday,
      );
      expect(s.box, 1);
      expect(s.due, DateTime(2026, 11, 3));
    });

    test('fast → bleibt im Fach, morgen', () {
      final s = Leitner.review(
        CardState(box: 3, due: monday),
        Grade.almost,
        now: monday,
      );
      expect(s.box, 3);
      expect(s.due, DateTime(2026, 11, 3));
    });

    test('Fach 5 bleibt Fach 5, 16 Tage', () {
      final s = Leitner.review(
        CardState(box: 5, due: monday),
        Grade.knew,
        now: monday,
      );
      expect(s.box, 5);
      expect(s.due, DateTime(2026, 11, 18));
    });

    test('über den Monatswechsel', () {
      final s = Leitner.review(
        CardState(box: 4, due: monday),
        Grade.knew,
        now: DateTime(2026, 11, 28),
      );
      expect(s.due, DateTime(2026, 12, 14));
    });
  });

  test('ProgressStore speichert und zählt', () async {
    SharedPreferences.setMockInitialValues({});
    const set = VocabSet(
      id: 'arzt',
      title: 'Beim Arzt',
      titleTranslation: '',
      variety: Variety.de,
      published: true,
      cards: [
        VocabCard(id: 'a', term: 'a', translation: 'a'),
        VocabCard(id: 'b', term: 'b', translation: 'b'),
        VocabCard(id: 'c', term: 'c', translation: 'c'),
      ],
    );
    final store = await ProgressStore.open('anna1');
    await store.record(set, set.cards[0], Grade.knew, now: monday);
    await store.record(set, set.cards[1], Grade.didNotKnow, now: monday);

    final reopened = await ProgressStore.open('anna1');
    final tomorrow = reopened.stats(set, now: DateTime(2026, 11, 3));
    expect(tomorrow.learning, 2);
    expect(tomorrow.fresh, 1);
    expect(tomorrow.due, 1); // nur „b“
    expect(reopened.stats(set, now: DateTime(2026, 11, 4)).due, 2);
  });
}
