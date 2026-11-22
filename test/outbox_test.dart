import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wf_quick_add/capture.dart';
import 'package:wf_quick_add/storage/outbox.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp());
  tearDown(() async => dir.delete(recursive: true));

  test('survit au redémarrage et sérialise ajout et confirmation', () async {
    final batch = captureBatch('A\n-\nB', DateTime(2025));
    await Outbox(dir).enqueueBatch(batch);
    final box = Outbox(dir);
    await Future.wait([
      box.acknowledge(batch.first.id),
      box.enqueueBatch(captureBatch('C', DateTime(2026))),
    ]);
    expect((await Outbox(dir).pending()).map((e) => e.text), ['B', 'C']);
  });

  test('un échec avant renommage préserve la file précédente', () async {
    final box = Outbox(dir);
    await box.enqueueBatch(captureBatch('A', DateTime(2025)));
    await Directory('${dir.path}/outbox.json.tmp').create();
    await expectLater(
      box.enqueueBatch(captureBatch('B\n-\nC', DateTime(2025))),
      throwsA(isA<FileSystemException>()),
    );
    expect((await Outbox(dir).pending()).single.text, 'A');
  });

  test('une file illisible reste intacte', () async {
    final file = File('${dir.path}/outbox.json');
    await file.writeAsString('broken');
    await expectLater(
      Outbox(dir).enqueueBatch(captureBatch('A', DateTime(2025))),
      throwsFormatException,
    );
    expect(await file.readAsString(), 'broken');
  });
}
