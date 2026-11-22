import 'dart:convert';
import 'dart:math';

List<String> parseCapture(String input) {
  final entries = <String>[], lines = <String>[];
  void finish() {
    if (lines.isNotEmpty) entries.add(lines.join('\n'));
    lines.clear();
  }

  for (final line in const LineSplitter().convert(input)) {
    if (line == '-') {
      finish();
    } else if (line.trim().isNotEmpty) {
      lines.add(line);
    }
  }
  finish();
  return entries;
}

class PendingEntry {
  final String id, text, localTime;
  const PendingEntry(this.id, this.text, this.localTime);
  List<String> get path => [
    localTime.substring(0, 4),
    localTime.substring(5, 7),
    localTime.substring(8, 10),
    localTime.substring(11, 16).replaceAll(':', ''),
  ];
  Map<String, String> toJson() => {
    'id': id,
    'text': text,
    'localTime': localTime,
  };
  factory PendingEntry.fromJson(Map<String, dynamic> m) => PendingEntry(
    m['id'] as String,
    m['text'] as String,
    m['localTime'] as String,
  );
}

List<PendingEntry> captureBatch(String input, DateTime now) {
  final rng = Random.secure();
  final timestamp = now.toLocal().toIso8601String();
  return [
    for (final text in parseCapture(input))
      PendingEntry(
        base64Url.encode(List.generate(16, (_) => rng.nextInt(256))),
        text,
        timestamp,
      ),
  ];
}
