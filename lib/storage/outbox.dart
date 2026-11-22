import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../capture.dart';

class Outbox {
  Outbox(this.directory);
  final Directory directory;
  File get _file => File('${directory.path}/outbox.json');
  Future<void> _tail = Future.value();
  final _watchers = <MultiStreamController<int>>{};

  late final Stream<int> pendingCounts = Stream<int>.multi((listener) {
    _watchers.add(listener);
    listener.onCancel = () => _watchers.remove(listener);
    unawaited(
      _serial(() async {
        try {
          final entries = await _read();
          if (_watchers.contains(listener)) listener.add(entries.length);
        } catch (error, stack) {
          if (_watchers.contains(listener)) listener.addError(error, stack);
        }
      }),
    );
  }, isBroadcast: true).distinct();

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<List<PendingEntry>> _read() async {
    String raw;
    try {
      raw = await _file.readAsString();
    } on PathNotFoundException {
      return [];
    }
    final data = jsonDecode(raw);
    if (data is! Map || data['version'] != 1 || data['entries'] is! List) {
      throw const FormatException('File locale inconnue');
    }
    return [for (final m in data['entries']) PendingEntry.fromJson(m)];
  }

  Future<void> _replace(List<PendingEntry> entries) async {
    await directory.create(recursive: true);
    final temp = File('${_file.path}.tmp');
    await temp.writeAsString(
      jsonEncode({'version': 1, 'entries': entries}),
      flush: true,
    );
    await temp.rename(_file.path);
    for (final watcher in _watchers) {
      watcher.add(entries.length);
    }
  }

  Future<List<PendingEntry>> pending() => _serial(_read);
  Future<void> enqueueBatch(List<PendingEntry> entries) =>
      _serial(() async => _replace([...await _read(), ...entries]));
  Future<void> acknowledge(String id) => _serial(
    () async => _replace((await _read())..removeWhere((e) => e.id == id)),
  );
}
