import 'dart:convert';
import 'dart:io';

import '../capture.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.status, this.retryAfter);
  final int status;
  final Duration? retryAfter;
}

class WorkflowyClient {
  WorkflowyClient({Uri? base})
    : base = base ?? Uri.parse('https://workflowy.com/api/v1/');
  final Uri base;
  final _http = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  void close() => _http.close(force: true);
  Future<void> checkKey(String key) async {
    final data = await _request(key, parent: 'inbox');
    if (data['nodes'] is! List) {
      throw const FormatException('Réponse WorkFlowy inattendue');
    }
  }

  Future<Map<String, dynamic>> _request(
    String key, {
    required String parent,
    String? name,
  }) async {
    final uri = base.resolve('nodes');
    final request = name == null
        ? await _http.getUrl(
            uri.replace(queryParameters: {'parent_id': parent}),
          )
        : await _http.postUrl(uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $key');
    request.followRedirects = false;
    if (name != null) {
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({'parent_id': parent, 'name': name, 'position': 'bottom'}),
      );
    }
    const timeout = Duration(seconds: 30);
    final response = await request.close().timeout(
      timeout,
      onTimeout: () {
        request.abort();
        throw const SocketException('Timeout');
      },
    );
    final body = await utf8.decoder.bind(response).timeout(timeout).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final raw = response.headers.value(HttpHeaders.retryAfterHeader);
      Duration? delay;
      if (raw != null) {
        final seconds = int.tryParse(raw);
        if (seconds != null) {
          delay = Duration(seconds: seconds);
        } else {
          try {
            delay = HttpDate.parse(raw).difference(DateTime.now().toUtc());
          } on HttpException {
            /* invalid header */
          }
        }
      }
      throw ApiFailure(response.statusCode, delay);
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<String> _create(String key, String parent, String name) async {
    final id = (await _request(key, parent: parent, name: name))['item_id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Confirmation manquante');
    }
    return id;
  }

  Future<void> sendEntry(PendingEntry entry, String key) async {
    var parent = 'inbox';
    for (final segment in entry.path) {
      final data = await _request(key, parent: parent);
      final nodes = data['nodes'] as List;
      final match = nodes.where((n) => n['name'] == segment).firstOrNull;
      parent = match == null
          ? await _create(key, parent, segment)
          : match['id'] as String;
    }
    await _create(key, parent, entry.text);
  }
}
