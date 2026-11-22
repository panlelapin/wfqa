import 'dart:async';

import '../capture.dart';
import '../storage/outbox.dart';
import '../workflowy/client.dart';

class OutboxSender {
  OutboxSender(
    this.box,
    this.readKey,
    this.send, {
    this.initialDelay = const Duration(seconds: 2),
  });
  final Outbox box;
  final Future<String?> Function() readKey;
  final Future<void> Function(PendingEntry, String) send;
  final Duration initialDelay;
  late Duration _delay = initialDelay;
  Future<void>? _active;
  Timer? _timer;
  int _keyVersion = 0;
  String? _confirmed;
  bool _dirty = false, _disposed = false, _blocked = false;
  Future<void> wake({bool credentialsChanged = false}) {
    if (credentialsChanged) {
      _keyVersion++;
      _blocked = false;
      _timer?.cancel();
      _timer = null;
    }
    if (_disposed || _blocked || _timer != null) return Future.value();
    _dirty = true;
    return _active ??= _run().whenComplete(() => _active = null);
  }

  Future<void> _run() async {
    while (_dirty && !_disposed) {
      final version = _keyVersion;
      try {
        _dirty = false;
        if (_confirmed != null) {
          await box.acknowledge(_confirmed!);
          _confirmed = null;
        }
        final entries = await box.pending();
        if (entries.isEmpty) continue;
        final key = await readKey();
        if (key == null || key.isEmpty) continue;
        for (final entry in entries) {
          if (_disposed) return;
          if (version != _keyVersion) break;
          await send(entry, key);
          _confirmed = entry.id;
          await box.acknowledge(entry.id);
          _confirmed = null;
          _delay = initialDelay;
        }
      } catch (e) {
        if (_disposed) return;
        if (e is ApiFailure && e.status == 401) {
          if (version != _keyVersion) continue;
          _blocked = true;
          return;
        }
        final minimum = e is ApiFailure ? e.retryAfter : null;
        final wait = minimum != null && minimum > _delay ? minimum : _delay;
        _timer = Timer(wait, () {
          _timer = null;
          unawaited(wake());
        });
        _delay = Duration(
          milliseconds: (_delay.inMilliseconds * 2).clamp(1, 60000),
        );
        return;
      }
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
