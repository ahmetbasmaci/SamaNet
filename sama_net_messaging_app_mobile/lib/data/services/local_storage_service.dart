import 'dart:convert';

/// Simple local storage service using in-memory storage
/// In a real app, this would use SharedPreferences or similar
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  final Map<String, String> _storage = {};

  /// Save string value
  Future<void> saveString(String key, String value) async {
    _storage[key] = value;
  }

  /// Get string value
  Future<String?> getString(String key) async {
    return _storage[key];
  }

  /// Save object as JSON
  Future<void> saveObject(String key, Map<String, dynamic> object) async {
    final jsonString = json.encode(object);
    await saveString(key, jsonString);
  }

  /// Get object from JSON
  Future<Map<String, dynamic>?> getObject(String key) async {
    final jsonString = await getString(key);
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Save boolean value
  Future<void> saveBool(String key, bool value) async {
    await saveString(key, value.toString());
  }

  /// Get boolean value
  Future<bool?> getBool(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  /// Save integer value
  Future<void> saveInt(String key, int value) async {
    await saveString(key, value.toString());
  }

  /// Get integer value
  Future<int?> getInt(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Remove value
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  /// Clear all values
  Future<void> clear() async {
    _storage.clear();
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  /// Get all keys
  Future<Set<String>> getKeys() async {
    return _storage.keys.toSet();
  }
}
