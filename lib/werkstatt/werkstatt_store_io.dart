import 'dart:convert';
import 'dart:io';

import 'werkstatt_store.dart';

/// Projektordner: `--dart-define=PROJEKT=C:\...`, sonst der aktuelle Ordner.
const _projectDefine = String.fromEnvironment('PROJEKT');

WerkstattStore? create() {
  final root = findProjectRoot();
  return root == null ? null : _IoStore(root);
}

/// Sucht den Projektordner: zuerst `PROJEKT`, dann der aktuelle Ordner,
/// dann aufwärts vom Programm aus (z. B. von build\windows\...\Release).
String? findProjectRoot() {
  bool isProject(String dir) =>
      Directory('$dir/web/data/students').existsSync();
  if (_projectDefine.isNotEmpty && isProject(_projectDefine)) {
    return _projectDefine;
  }
  if (isProject(Directory.current.path)) return Directory.current.path;
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 10; i++) {
    if (isProject(dir.path)) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

class _IoStore implements WerkstattStore {
  _IoStore(this.projectRoot);

  @override
  final String projectRoot;

  String get _data => '$projectRoot/web/data';

  @override
  Future<Map<String, dynamic>?> load(String path) async {
    final f = File('$_data/$path');
    if (!await f.exists()) return null;
    return jsonDecode(await f.readAsString()) as Map<String, dynamic>;
  }

  @override
  Future<List<String>> studentCodes() async {
    final dir = Directory('$_data/students');
    final codes = [
      await for (final e in dir.list())
        if (e is Directory) e.uri.pathSegments.where((s) => s.isNotEmpty).last,
    ]..sort();
    return codes;
  }

  @override
  Future<Map<String, dynamic>> readSet(String code, String setId) async =>
      (await load('students/$code/sets/$setId.json'))!;

  @override
  Future<void> writeSet(
    String code,
    String setId,
    Map<String, dynamic> json,
  ) async {
    final f = File('$_data/students/$code/sets/$setId.json');
    await f.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );
  }

  @override
  String audioFilePath(String code, String fileName) {
    final dir = Directory('$_data/students/$code/audio');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return '${dir.path}/$fileName';
  }

  @override
  String studentFile(String code, String relative) =>
      '$_data/students/$code/$relative';

  @override
  Future<bool> exists(String absolutePath) => File(absolutePath).exists();

  @override
  Future<void> delete(String absolutePath) async {
    final f = File(absolutePath);
    if (await f.exists()) await f.delete();
  }
}
