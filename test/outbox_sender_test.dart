import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wf_quick_add/capture.dart';
import 'package:wf_quick_add/storage/outbox.dart';
import 'package:wf_quick_add/sync/outbox_sender.dart';
import 'package:wf_quick_add/workflowy/client.dart';

void main() {
  test(
    'une confirmation distante survit aux échecs successifs du retrait local',
    () async {
      final dir = await Directory.systemTemp.createTemp();
      addTearDown(() => dir.delete(recursive: true));
      final box = Outbox(dir);
      await box.enqueueBatch(captureBatch('A\n-\nB', DateTime(2025)));
      final blocker = Directory('${dir.path}/outbox.json.tmp');
      final sends = <String>[];
      final sender = OutboxSender(box, () async => 'key', (entry, key) async {
        sends.add(entry.text);
        if (sends.length == 1) await blocker.create();
      });
      addTearDown(sender.dispose);
      await sender.wake();
      await sender.wake(credentialsChanged: true);
      await blocker.delete();
      await sender.wake(credentialsChanged: true);
      expect(sends, ['A', 'B']);
      expect(await box.pending(), isEmpty);
    },
  );
  test('un ancien 401 ne bloque pas la clé déjà remplacée', () async {
    final dir = await Directory.systemTemp.createTemp();
    addTearDown(() => dir.delete(recursive: true));
    final box = Outbox(dir);
    await box.enqueueBatch(captureBatch('A', DateTime(2025)));
    var key = 'old';
    final started = Completer<void>(), reply = Completer<void>();
    final keys = <String>[];
    final sender = OutboxSender(box, () async => key, (entry, k) async {
      keys.add(k);
      if (k == 'old') {
        started.complete();
        await reply.future;
        throw const ApiFailure(401, null);
      }
    });
    addTearDown(sender.dispose);
    final first = sender.wake();
    await started.future;
    key = 'new';
    sender.wake(credentialsChanged: true);
    reply.complete();
    await first;
    expect(keys, ['old', 'new']);
    expect(await box.pending(), isEmpty);
  });
  test(
    'deux réveils, coupure après A, puis reprise automatique de B seul',
    () async {
      final dir = await Directory.systemTemp.createTemp();
      addTearDown(() => dir.delete(recursive: true));
      final box = Outbox(dir);
      await box.enqueueBatch(captureBatch('A\n-\nB', DateTime(2025)));
      final attempts = <String>[];
      final resumed = Completer<void>();
      final sender = OutboxSender(box, () async => 'key', (entry, key) async {
        attempts.add(entry.text);
        if (attempts.length == 2) throw const SocketException('offline');
        if (attempts.length == 3) resumed.complete();
      }, initialDelay: const Duration(milliseconds: 5));
      addTearDown(sender.dispose);
      sender.wake();
      await sender.wake();
      await resumed.future.timeout(const Duration(seconds: 3));
      await sender.wake();
      expect(attempts, ['A', 'B', 'B']);
      expect(await box.pending(), isEmpty);
    },
  );

  test('sans clé, garde la file ; après correction, reprend', () async {
    final dir = await Directory.systemTemp.createTemp();
    addTearDown(() => dir.delete(recursive: true));
    final box = Outbox(dir);
    await box.enqueueBatch(captureBatch('A', DateTime(2025)));
    String? key;
    final sent = <String>[];
    final sender = OutboxSender(box, () async => key, (e, k) async {
      sent.add(e.text);
    });
    addTearDown(sender.dispose);
    await sender.wake();
    expect(sent, isEmpty);
    expect(await box.pending(), hasLength(1));
    key = 'new';
    await sender.wake(credentialsChanged: true);
    expect(sent, ['A']);
  });
}
