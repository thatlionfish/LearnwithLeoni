import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class StudentNotFound implements Exception {
  const StudentNotFound(this.code);
  final String code;
  @override
  String toString() => 'StudentNotFound($code)';
}

/// Liefert die JSON-Dateien der Inhalte (online: neben der App unter `data/`).
abstract interface class ContentSource {
  /// `null`, wenn die Datei nicht existiert.
  Future<Map<String, dynamic>?> load(String path);
}

class HttpContentSource implements ContentSource {
  HttpContentSource({http.Client? client, Uri? base})
    : _client = client ?? http.Client(),
      _base = base ?? Uri.base;

  final http.Client _client;
  final Uri _base;

  @override
  Future<Map<String, dynamic>?> load(String path) async {
    // Uri.base ist auf GitHub Pages z. B. .../LearnwithLeoni/#/s/abc;
    // resolve ignoriert den #-Teil und landet bei .../LearnwithLeoni/data/...
    final uri = _base.removeFragment().resolve('data/$path');
    final res = await _client.get(uri);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', uri);
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}

/// Lädt Schüler und Sets und hält sie im Speicher.
class ContentRepository {
  ContentRepository(this._source, {this.includeDrafts = false});

  final ContentSource _source;

  /// Werkstatt-Modus: Entwürfe werden mit angezeigt.
  final bool includeDrafts;

  final Map<String, Future<StudentContent>> _cache = {};

  static final RegExp _validCode = RegExp(r'^[A-Za-z0-9_-]{3,40}$');

  final Map<String, Future<Map<String, dynamic>?>> _shared = {};

  /// Gemeinsame Inhalte für alle Schüler, z. B. `abc/hints.json`.
  Future<Map<String, dynamic>?> shared(String path) =>
      _shared.putIfAbsent(path, () => _source.load(path));

  /// Werkstatt: nach Änderungen neu laden.
  void invalidate(String code) => _cache.remove(code);

  Future<StudentContent> student(String code) {
    if (!_validCode.hasMatch(code)) {
      return Future.error(StudentNotFound(code));
    }
    return _cache.putIfAbsent(code, () {
      final future = _loadStudent(code);
      // Fehler nicht zwischenspeichern: beim nächsten Versuch neu laden.
      future.then(
        (_) {},
        onError: (Object _) {
          _cache.remove(code);
        },
      );
      return future;
    });
  }

  Future<StudentContent> _loadStudent(String code) async {
    final json = await _source.load('students/$code/student.json');
    if (json == null) throw StudentNotFound(code);
    final student = Student.fromJson(code, json);
    final sets = await Future.wait([
      for (final id in student.setIds)
        _source.load('students/$code/sets/$id.json'),
    ]);
    return StudentContent(
      student: student,
      sets: [
        for (final s in sets)
          if (s != null)
            if (VocabSet.fromJson(s) case final set
                when set.published || includeDrafts)
              set,
      ],
    );
  }
}

class StudentContent {
  const StudentContent({required this.student, required this.sets});

  final Student student;
  final List<VocabSet> sets;

  VocabSet? set(String id) {
    for (final s in sets) {
      if (s.id == id) return s;
    }
    return null;
  }
}
