# LearnwithLeoni

Lern-App für meine Preply-Schüler: Deutsch und Bündnerdütsch mit persönlichen
Vokabelkarten, Übungen und Spielen – begleitet von Leoni und Kumachan.

Online: <https://thatlionfish.github.io/LearnwithLeoni/>
(jeder Schüler hat einen eigenen Link `…/#/s/<codename>`).

- Flutter-Web-App, veröffentlicht über GitHub Pages ([Workflow](.github/workflows/deploy-pages.yml))
- Kein Server, kein Tracking: der Lernstand bleibt im Browser des Schülers
- Inhalte als JSON unter `web/data/`, Format siehe [CLAUDE.md](CLAUDE.md)
- Werkstatt (Windows): `Werkstatt starten.bat`

```bash
flutter analyze
flutter test
flutter run -d chrome
```

Schriften: Fraunces und Nunito, SIL Open Font License (`assets/fonts/*-OFL.txt`).
