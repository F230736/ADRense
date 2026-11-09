import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore(this.key, {FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage();
  final String key;
  final FlutterSecureStorage storage;
  @override Future<String?> read() => storage.read(key: key);
  @override Future<void> write(String token) => storage.write(key: key, value: token);
  @override Future<void> clear() => storage.delete(key: key);
}
