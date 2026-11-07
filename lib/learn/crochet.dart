import '../data/leitner.dart';
import '../data/models.dart';

/// Ein Wort als Häkelquadrat: Jedes Fach ist eine Runde. Ist das Wort
/// sicher, ist das Quadrat fertig und wird an die grosse Decke genäht.
class CrochetSquare {
  const CrochetSquare({
    required this.set,
    required this.card,
    required this.rounds,
    required this.due,
  });

  final VocabSet set;
  final VocabCard card;

  /// 1–5 Runden (= Fach), [Leitner.secure] = fertig.
  final int rounds;

  /// Beim fertigen Quadrat: Reihenfolge, in der es angenäht wurde.
  final DateTime due;

  bool get finished => rounds >= Leitner.secure;
  String get key => '${set.id}/${card.id}';
}

/// Kumachans Häkelarbeit für einen Schüler – über alle seine Sets.
class CrochetWork {
  const CrochetWork({
    required this.attached,
    required this.onHook,
    required this.waiting,
  });

  factory CrochetWork.of(Iterable<VocabSet> sets, ProgressStore progress) {
    final attached = <CrochetSquare>[];
    final onHook = <CrochetSquare>[];
    var waiting = 0;
    final seen = <String>{};
    for (final set in sets) {
      for (final card in set.cards) {
        if (!seen.add('${set.id}/${card.id}')) continue;
        final s = progress.stateOf(set, card);
        if (s == null) {
          waiting++;
          continue;
        }
        final sq = CrochetSquare(
          set: set,
          card: card,
          rounds: s.box.clamp(1, Leitner.secure),
          due: s.due,
        );
        (sq.finished ? attached : onHook).add(sq);
      }
    }
    // Angenäht in der Reihenfolge, in der die Wörter sicher wurden.
    attached.sort((a, b) => a.due.compareTo(b.due));
    // Am Haken: die fast fertigen zuerst.
    onHook.sort((a, b) => b.rounds.compareTo(a.rounds));
    return CrochetWork(attached: attached, onHook: onHook, waiting: waiting);
  }

  /// Quadrate pro Decke (6 × 6). Ist eine Decke voll, beginnt die nächste.
  static const perBlanket = 36;
  static const columns = 6;

  /// Fertige Quadrate, an die Decke genäht.
  final List<CrochetSquare> attached;

  /// Angefangene Quadrate (1–5 Runden).
  final List<CrochetSquare> onHook;

  /// Wörter, die noch nicht gelernt wurden.
  final int waiting;

  /// Ganz fertige Decken.
  int get blankets => attached.length ~/ perBlanket;

  /// Quadrate der Decke, an der Kumachan gerade näht.
  List<CrochetSquare> get currentBlanket =>
      attached.sublist(blankets * perBlanket);

  /// 0 … 1: wie weit sich Kumachan schon einkuscheln kann.
  double get snuggle => currentBlanket.length / perBlanket;

  bool get isEmpty => attached.isEmpty && onHook.isEmpty;
}

/// Was in einer Lernrunde an einem Quadrat gehäkelt wurde.
class CrochetStep {
  const CrochetStep(this.square, {required this.from, required this.to});

  final CrochetSquare square;

  /// Runden vorher (0 = neues Wort) und nachher.
  final int from;
  final int to;

  /// Ist in dieser Runde fertig geworden und kommt an die Decke.
  bool get joined => to >= Leitner.secure && from < Leitner.secure;

  /// Neue Runden; der Rand beim Fertigwerden zählt als Runde.
  int get newRounds =>
      (to.clamp(0, Leitner.secure) - from.clamp(0, Leitner.secure)).clamp(0, 9);
}
