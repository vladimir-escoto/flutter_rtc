import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ClientPreferences {
  // Keys for storage
  static const _keyClientId = 'clientId';
  static const _keyAutoRefresh = 'autoRefresh';

  // Single instance of FlutterSecureStorage
  static final _storage = FlutterSecureStorage();

  /// Returns the stored client ID, generating and persisting a new
  /// 6-digit ID if none exists yet.
  static Future<String> getClientId() async {
    // Read from secure storage
    String? id = await _storage.read(key: _keyClientId);
    if (id == null) {
      id = _generate6DigitClientId();
      await _storage.write(key: _keyClientId, value: id);
    }
    return id;
  }

  /// Internal helper to generate a random 6-digit string.
  static String _generate6DigitClientId() {
    final random = Random();
    final number = random.nextInt(10);
    return number.toString();
  }

  /// Returns whether auto-refresh is enabled.
  /// Defaults to false if no value has been set.
  static Future<bool> isAutoRefreshEnabled() async {
    String? value = await _storage.read(key: _keyAutoRefresh);
    return value == 'true';
  }

  /// Sets the auto-refresh flag.
  static Future<void> setAutoRefreshEnabled(bool enabled) async {
    await _storage.write(key: _keyAutoRefresh, value: enabled ? 'true' : 'false');
  }
}
