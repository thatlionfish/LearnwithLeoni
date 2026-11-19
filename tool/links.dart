// Schreibt die Links aller Schüler nach werkstatt/notizen/links.md
// (privat, wird nicht veröffentlicht) und zeigt sie auch hier an.
//
// Aufruf: dart run tool/links.dart
import 'dart:convert';
import 'dart:io';

const base = 'https://thatlionfish.github.io/LearnwithLeoni/#/s/';

void main() {
  final rows = <(String, String, String)>[];
  for (final dir in Directory('web/data/students').listSync()) {
    if (dir is! Directory) continue;
    final code = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (code == 'demo') continue;
    final file = File('${dir.path}/student.json');
    if (!file.existsSync()) continue;
    final j = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final themes = [
      ...((j['themen'] as List?) ?? const []).cast<String>(),
      ...((j['sets'] as List?) ?? const []).cast<String>(),
    ];
    rows.add((j['name'] as String, code, themes.join(', ')));
  }
  rows.sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase()));

  final out = StringBuffer()
    ..writeln('# Links meiner Schüler')
    ..writeln()
    ..writeln('Privat – wird nicht veröffentlicht. Neu erzeugen mit')
    ..writeln('`dart run tool/links.dart`.')
    ..writeln();
  for (final (name, code, themes) in rows) {
    out
      ..writeln('- **$name**: [$base$code]($base$code)')
      ..writeln('  - ${themes.isEmpty ? 'noch keine Inhalte' : themes}');
  }
  File('werkstatt/notizen/links.md').writeAsStringSync(out.toString());
  stdout.write(out);
}
