import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyStore {
  final _storage = const FlutterSecureStorage();
  Future<String?> read() => _storage.read(key: 'workflowy.api.key');
  Future<void> write(String value) => value.isEmpty
      ? _storage.delete(key: 'workflowy.api.key')
      : _storage.write(key: 'workflowy.api.key', value: value);
}
