// Fallback ohne Ton.

String? localRoot;

bool get available => false;

Future<void> play({
  String? url,
  String? text,
  required String lang,
  required double rate,
}) async {}

Future<void> playFile(String absolutePath) async {}

void stop() {}
