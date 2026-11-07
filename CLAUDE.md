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
  - `fide` (Hörverstehen wie im fide-Test „Verstehen“ A2–B1):
    `{ "id", "level": "A2"|"B1", "situation", "situationTranslation"?, "items": [...] }`
    - Item: `{ "id", "question", "questionTranslation"?, "text" ("Name: …", ein
      Dialogbeitrag; A2 30–45, B1 35–55 Wörter), "hint"? }`
    - A2: `"pictures"`: genau 3 (`"clock:19:30"`, `"price:4.50"`, `"cal:5,19"`,
      `"week:Di,Sa"`, `"count:4:person"`, `"icon:cake"`, `"icons:table,window"`,
      `"text:500 g"`, als `{ "pic", "label" }`), `"answer"`: Index.
      Zeichen-Namen: `fideIcons` in `lib/widgets/fide_picture.dart`.
    - B1: `"keywords"`: Gruppen, Alternativen mit `|`, alle Gruppen müssen
      vorkommen (`["sieben|7|19"]`); `"model"` (Musterantwort), `"modelTranslation"`?
    - Typisch fide: Im Hörtext kommen auch die falschen Antworten vor.
    - Eigene Texte schreiben – die fide-Modellversion ist urheberrechtlich geschützt.
- Die Oberfläche ist immer Deutsch. Die Erklärsprache (`explainLanguage`) ist nur
  „Hilfesprache“: klein daneben (`Glossed`) oder auf Tippen (`HelpReveal`).
  Sprachen mit Hilfetexten: `lib/l10n/app_*.arb` (de, en, ja).
- ABC-Radio, gemeinsame Hinweise: `web/data/abc/hints.json`
  (`topic`: culture | people | food | traditions; jede Antwort muss mit dem
  Buchstaben beginnen – ein Test prüft das).
- Übersetzungen immer in die `explainLanguage` des Schülers.

## Natürliche Stimmen (Microsoft / Azure AI Speech)

Nach jedem neuen oder geänderten hochdeutschen Set:

```
dart run tool/tts.dart --dry   # was würde erzeugt (ohne Schlüssel möglich)
dart run tool/tts.dart         # erzeugt MP3s unter <schüler>/audio/tts/
```

- Schlüssel in `werkstatt/azure-speech.env` (gitignored, Vorlage `.example`).
  Den Schlüssel nie ausgeben, nie committen.
- Erzeugt `audio` (Wort), `exampleAudio`, `gapAudio` (Lückensatz mit „hm, hm, hm“),
  `hintAudio` (Umschreibung) und `listening[].audio` (Dialog: jede Person eigene
  Stimme, „Leoni“ = de-CH-LeniNeural). Leonis eigene Aufnahmen (`audio/…`, nicht
  `audio/tts/…`) werden nie überschrieben. Nur Geändertes wird neu erzeugt.
- Bündnerdütsch-Sets werden übersprungen.
- `"voice": "de-CH"` im Schülerprofil → Schweizer Standardstimme.
- fide-Aufgaben: eine Aufnahme pro Frage – Prüferin (Situation, Frage),
  Hörtext mit anderen deutschen Stimmen, Frage nochmals. Der fide-Test prüft
  Hochdeutsch: keine Schweizer Stimmen für fide-Schüler.
- Kumachans Satzsammlung `web/data/kuma/` (für alle Schüler): jeder Tipp, den
  er geben kann (`kumaPhrases` in `lib/learn/kuma_phrases.dart`), mit seiner
  Kinderstimme. Feste Sätze stehen in `KumaLines` (`lib/learn/hints.dart`).

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
