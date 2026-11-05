# LearnwithLeoni – Hinweise für Claude

Lern-App von Leoni (Preply-Lehrperson für Deutsch und Bündnerdütsch) für ihre
Schüler. Flutter-Web-App auf GitHub Pages (`thatlionfish/LearnwithLeoni`),
ohne Server. Spezifikation: `../SPEZIFIKATION.md`. Mit Leoni wird **Deutsch**
gesprochen.

## Inhalte erstellen (häufigste Aufgabe)

Inhalte liegen als JSON unter `web/data/` und werden zur Laufzeit geladen –
für neue Inhalte ist keine Code-Änderung nötig.

- Schüler: `web/data/students/<code>/student.json`
  `{ "name", "explainLanguage": "en", "level": "A2", "targets": ["de","gsw"], "sets": ["<set-id>", …] }`
  - `<code>` ist ein schwer erratbarer Codename (z. B. 8 Zeichen a–z, 0–9),
    nie der echte Name. Der Link ist `https://thatlionfish.github.io/LearnwithLeoni/#/s/<code>`.
  - Nur Vorname oder Spitzname, nie Nachname oder Preply-Daten (Repo ist öffentlich).
- Set: `web/data/students/<code>/sets/<id>.json`
  - `"status": "draft"` bis Leoni freigibt (Werkstatt), dann `"published"`.
  - `"variety": "de"` (Hochdeutsch) oder `"gsw"` (Bündnerdütsch).
  - `cards`: `{ "id", "term" (mit Artikel), "plural"?, "translation" (Erklärsprache),
    "alt"? (andere Varietät), "example"?, "exampleTranslation"?, "audio"?, "verified"? }`
  - `cloze`: `{ "id", "text" mit ___, "answers": [...], "options"?: [...], "translation"? }`
  - `listening`: `{ "id", "title", "titleTranslation"?, "text" ("Name: …"-Zeilen), "audio"?,
    "questions": [{ "q", "options", "answer" (Index), "translation"? }] }`
- ABC-Radio, gemeinsame Hinweise: `web/data/abc/hints.json`
  (`topic`: culture | people | food | traditions; jede Antwort muss mit dem
  Buchstaben beginnen – ein Test prüft das).
- Übersetzungen immer in die `explainLanguage` des Schülers.

## Bündnerdütsch

Leoni schreibt nach Gehör. **Immer zuerst `werkstatt/woerterbuch.json` verwenden.**
Neue Bündnerdütsch-Formen nur als Vorschlag mit `"verified": false` eintragen;
Leoni bestätigt sie in der Werkstatt. Keine Computerstimme für Bündnerdütsch –
Audio nimmt Leoni in der Werkstatt auf.

Private Notizen zu Schülern: `werkstatt/notizen/<code>.md` (nicht veröffentlicht).

## Werkstatt

Windows-Programm zum Prüfen, Freigeben und Aufnehmen:
`Werkstatt starten.bat` bzw. `flutter run -d windows --dart-define=WERKSTATT=true`.
Schreibt direkt in `web/data/` (Freigabe, `verified`, `audio/<set>-<karte>.m4a`).

## Entwicklung

```
flutter analyze
flutter test
dart run tool/gen_leoni.dart   # Posen von Leoni neu erzeugen
dart run tool/gen_kuma.dart    # Posen von Kumachan neu erzeugen
```

- Design: Wabi-Sabi, Farben in `lib/ui/colors.dart`; Lemon Grass nur als Detail.
- Texte der Oberfläche: `lib/l10n/app_*.arb` (de, en). Neue Sprache = neue ARB-Datei.
- Hangman stammt aus `C:\dev\Apps\Hangman` – Szene und Farben bleiben 1:1.
- Commit/Push nur, wenn Leoni es sagt.
