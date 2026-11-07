import '../data/models.dart';
import '../games/abc/abc_game.dart';
import 'answer_check.dart';
import 'crossword.dart';
import 'exercises.dart';
import 'hints.dart';

/// Alles, was Kumachan zu diesen Inhalten sagen kann – damit `tool/tts.dart`
/// jeden Satz vorab mit seiner Stimme aufnimmt. Lieber ein Satz zu viel als
/// einer zu wenig: Fehlt einer, liest ihn die Browser-Stimme vor.
Set<String> kumaPhrases(
  Iterable<VocabSet> sets, {
  Iterable<AbcHint> abc = const [],
}) {
  final out = <String>{...KumaLines.all};
  void add(Iterable<String> hints) {
    for (final h in hints) {
      if (h.trim().isNotEmpty) out.add(h.trim());
    }
  }

  for (final s in sets) {
    for (final c in s.cards) {
      final answers = <String>{
        '', // Zuordnen, Hangman: ohne Buchstaben-Tipp
        stripArticle(c.term), // ABC-Radio (eigene Wörter)
        crosswordHintAnswer(toGridWord(c.term)),
      };
      final gap = gapInExample(c);
      if (gap != null) {
        answers
          ..add(gap.found) // Lückentext
          ..add(crosswordHintAnswer(toGridWord(gap.found))); // Hör-Rätsel
      }
      for (final a in answers) {
        add(wordHints(description: c.hint, term: c.term, answer: a));
      }
      if (c.example != null) add(sentenceHints(c.example!));
    }
    for (final c in s.cloze) {
      add(wordHints(description: c.hint, answer: c.answers.first));
    }
    for (final f in s.fide) {
      for (final i in f.items) {
        add(fideHints(i));
      }
    }
  }
  for (final h in abc) {
    add(
      wordHints(
        description: h.card?.hint,
        term: h.card?.term,
        answer: h.answers.first,
      ),
    );
  }
  return out;
}
