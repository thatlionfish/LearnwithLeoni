import '../data/repository.dart';
import 'werkstatt_store_stub.dart'
    if (dart.library.io) 'werkstatt_store_io.dart'
    as impl;

/// Zugriff der Werkstatt auf die Projektdateien (nur Windows/lokal).
///
/// Liest und schreibt direkt in `web/data/` des Projekts, damit Aufnahmen
/// und Freigaben beim nächsten Veröffentlichen online sind.
abstract interface class WerkstattStore implements ContentSource {
  static WerkstattStore? create() => impl.create();

  /// Projektordner (enthält `web/data`).
  String get projectRoot;

  /// Codes aller Schülerordner.
  Future<List<String>> studentCodes();

  /// Set als rohes JSON (alle Felder bleiben erhalten).
  Future<Map<String, dynamic>> readSet(String code, String setId);
  Future<void> writeSet(String code, String setId, Map<String, dynamic> json);

  /// Absoluter Pfad für eine neue Aufnahme; relativ gespeichert als `audio/<datei>`.
  String audioFilePath(String code, String fileName);
  Future<bool> exists(String absolutePath);
  Future<void> delete(String absolutePath);

  /// Absoluter Pfad zu einer Datei relativ zum Schülerordner.
  String studentFile(String code, String relative);
}
