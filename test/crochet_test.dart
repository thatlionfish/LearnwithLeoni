import 'package:flutter_test/flutter_test.dart';
import 'package:learnwithleoni/data/leitner.dart';
import 'package:learnwithleoni/data/models.dart';
import 'package:learnwithleoni/learn/crochet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final monday = DateTime(2026, 11, 2);
  const set = VocabSet(
    id: 'essen',
    title: 'Essen',
    titleTranslation: '',
    variety: Variety.de,
    published: true,
    cards: [
      VocabCard(id: 'brot', term: 'das Brot', translation: 'パン'),
      VocabCard(id: 'kaese', term: 'der Käse', translation: 'チーズ'),
      VocabCard(id: 'milch', term: 'die Milch', translation: '牛乳'),
      VocabCard(id: 'ei', term: 'das Ei', translation: '卵'),
    ],
  );

  test(
    'Jedes Wort ein Quadrat: Runden = Fach, sicher = an der Decke',
    () async {
      SharedPreferences.setMockInitialValues({});
      ProgressStore.resetCache();
      final p = await ProgressStore.open('reika');
      // Brot: dreimal gewusst → Fach 4 → 4 Runden.
      for (var i = 0; i < 3; i++) {
        await p.record(set, set.cards[0], Grade.knew, now: monday);
      }
      // Käse: fünfmal gewusst → sicher → an der Decke.
      for (var i = 0; i < 5; i++) {
        await p.record(set, set.cards[1], Grade.knew, now: monday);
      }
      // Milch: nicht gewusst → angefangen, 1 Runde.
      await p.record(set, set.cards[2], Grade.didNotKnow, now: monday);

      final work = CrochetWork.of([set], p);
      expect(work.attached.map((s) => s.card.id), ['kaese']);
      expect(work.onHook.map((s) => (s.card.id, s.rounds)), [
        ('brot', 4),
        ('milch', 1),
      ]);
      expect(work.waiting, 1); // das Ei
    },
  );

  test('Lernrunde: neue Runden zählen, fertig = an die Decke', () {
    const card = VocabCard(id: 'x', term: 'x', translation: 'x');
    CrochetSquare sq(int r) =>
        CrochetSquare(set: set, card: card, rounds: r, due: monday);
    final grown = CrochetStep(sq(3), from: 2, to: 3);
    expect(grown.newRounds, 1);
    expect(grown.joined, isFalse);
    final joined = CrochetStep(
      sq(Leitner.secure),
      from: Leitner.boxes,
      to: Leitner.secure,
    );
    expect(joined.joined, isTrue);
    expect(joined.newRounds, 1); // der Rand
    expect(CrochetStep(sq(2), from: 0, to: 2).newRounds, 2);
  });

  test('Die Decke wächst ohne Ende, in der Reihenfolge des Lernens', () async {
    SharedPreferences.setMockInitialValues({});
    ProgressStore.resetCache();
    final p = await ProgressStore.open('viel');
    final big = VocabSet(
      id: 'gross',
      title: 'Gross',
      titleTranslation: '',
      variety: Variety.de,
      published: true,
      cards: [
        for (var i = 0; i < 120; i++)
          VocabCard(id: 'c$i', term: 'w$i', translation: 't$i'),
      ],
    );
    // Jede Karte an einem anderen Tag fünfmal gewusst → sicher.
    for (final (i, c) in big.cards.indexed) {
      for (var k = 0; k < 5; k++) {
        await p.record(big, c, Grade.knew, now: monday.add(Duration(days: i)));
      }
    }
    final work = CrochetWork.of([big], p);
    expect(work.attached, hasLength(120)); // keine Grenze
    expect(work.attached.first.card.id, 'c0'); // das älteste zuerst
    expect(work.attached.last.card.id, 'c119');
  });
}
