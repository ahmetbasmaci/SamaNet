import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Persistent local storage service using file system
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  File? _storageFile;
  Map<String, String> _cache = {};
  bool _isInitialized = false;

  /// Get app storage directory path
  Future<String> _getStorageDirectoryPath() async {
    if (Platform.isAndroid) {
      return '/data/data/com.example.sama_net_messaging_app_mobile/app_flutter';
    } else if (Platform.isIOS) {
      return '${Platform.environment['HOME']}/Documents';
    } else {
      // Fallback for other platforms
      return Directory.current.path;
    }
  }

  /// Initialize storage file
  Future<void> _initStorage() async {
    if (_isInitialized) return;

    try {
      // Create storage directory and file
      final directoryPath = await _getStorageDirectoryPath();
      final directory = Directory(directoryPath);

      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      _storageFile = File('$directoryPath/app_storage.json');

      // Load existing data if file exists
      if (await _storageFile!.exists()) {
        final content = await _storageFile!.readAsString();
        if (content.isNotEmpty) {
          final data = json.decode(content) as Map<String, dynamic>;
          _cache = data.cast<String, String>();
        }
      }
      _isInitialized = true;
    } catch (e) {
      // Fallback to in-memory storage if file operations fail
      if (kDebugMode) {
        print('Storage initialization failed, using in-memory storage: $e');
      }
      _isInitialized = true;
    }
  }

  /// Save data to file
  Future<void> _saveToFile() async {
    if (_storageFile == null) return;

    try {
      final jsonString = json.encode(_cache);
      await _storageFile!.writeAsString(jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save to file: $e');
      }
    }
  }

  /// Save string value
  Future<void> saveString(String key, String value) async {
    await _initStorage();
    _cache[key] = value;
    await _saveToFile();
  }

  /// Get string value
  Future<String?> getString(String key) async {
    await _initStorage();
    return _cache[key];
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
    await _initStorage();
    _cache.remove(key);
    await _saveToFile();
  }

  /// Clear all values
  Future<void> clear() async {
    await _initStorage();
    _cache.clear();
    await _saveToFile();
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    await _initStorage();
    return _cache.containsKey(key);
  }

  /// Get all keys
  Future<Set<String>> getKeys() async {
    await _initStorage();
    return _cache.keys.toSet();
  }

  /// Get current user ID
  Future<int?> getUserId() async {
    return await getInt('user_id');
  }

  /// Save current user ID
  Future<void> saveUserId(int userId) async {
    await saveInt('user_id', userId);
  }
}
