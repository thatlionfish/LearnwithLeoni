@echo off
rem Startet die Werkstatt von LearnwithLeoni (nur auf diesem Rechner).
cd /d "%~dp0"
if not exist "build\windows\x64\runner\Release\learnwithleoni.exe" (
  echo Die Werkstatt wird zum ersten Mal gebaut, das dauert etwa eine Minute ...
  call flutter build windows --release --dart-define=WERKSTATT=true
)
start "" "build\windows\x64\runner\Release\learnwithleoni.exe"
