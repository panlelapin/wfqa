import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wf_quick_add/capture.dart';
import 'package:wf_quick_add/workflowy/client.dart';

void main() {
  late HttpServer server;
  late WorkflowyClient client;
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    client = WorkflowyClient(
      base: Uri.parse('http://127.0.0.1:${server.port}/api/v1/'),
    );
  });
  tearDown(() async {
    client.close();
    await server.close(force: true);
  });
  final entry = captureBatch('A\nB', DateTime(2025, 11, 25, 9, 5)).single;
  test(
    'Check lit sans créer : une Inbox vide est une réponse valide',
    () async {
      server.listen((r) async {
        expect(r.method, 'GET');
        expect(r.uri.path, '/api/v1/nodes');
        if (r.headers.value('Authorization') == 'Bearer valide') {
          r.response.write('{"nodes":[]}');
        } else {
          r.response.statusCode = 401;
        }
        await r.response.close();
      });
      await client.checkKey('valide');
      await expectLater(
      client.checkKey('invalid-token'),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 401)),
      );
    },
  );
  test(
    'réutilise les parents et ajoute le texte complet en dernière position',
    () async {
      final creations = <Map>[];
      server.listen((r) async {
        expect(r.headers.value('Authorization'), 'Bearer test');
        expect(r.uri.path, '/api/v1/nodes');
        if (r.method == 'GET') {
          final parent = r.uri.queryParameters['parent_id'];
          final children = switch (parent) {
            'inbox' => [
              {'id': 'year', 'name': '2025'},
            ],
            'year' => [
              {'id': 'month', 'name': '11'},
            ],
            _ => [],
          };
          r.response.write(jsonEncode({'nodes': children}));
        } else {
          creations.add(jsonDecode(await utf8.decoder.bind(r).join()) as Map);
          r.response.write(jsonEncode({'item_id': 'new${creations.length}'}));
        }
        await r.response.close();
      });
      await client.sendEntry(entry, 'test');
      expect(creations.map((c) => c['parent_id']), ['month', 'new1', 'new2']);
      expect(creations.map((c) => c['name']), ['25', '0905', 'A\nB']);
      expect(creations.last['position'], 'bottom');
      expect(creations.last.containsKey('note'), false);
    },
  );
  for (final status in [401, 429, 200]) {
    test('refuse une confirmation absente ou invalide ($status)', () async {
      server.listen((r) async {
        r.response.statusCode = status;
        r.response.write(r.method == 'GET' ? '{"nodes":[]}' : '{}');
        await r.response.close();
      });
      await expectLater(client.sendEntry(entry, 'test'), throwsA(anything));
    });
  }
}
