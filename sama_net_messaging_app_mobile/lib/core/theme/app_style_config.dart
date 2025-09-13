import 'dart:convert';
import 'package:flutter/services.dart';

/// Configuration class for loading and managing app styles from JSON
class AppStyleConfig {
  final Map<String, dynamic> _config;

  AppStyleConfig._(this._config);

  /// Load style configuration from assets
  static Future<AppStyleConfig> load() async {
    final String jsonString = await rootBundle.loadString('assets/styles/style_messaging.json');
    final Map<String, dynamic> config = json.decode(jsonString);
    return AppStyleConfig._(config);
  }

  /// Get color by key
  Color getColor(String key) {
    final String? colorString = _config['colors']?[key];
    if (colorString == null) {
      throw ArgumentError('Color key "$key" not found in config');
    }
    return _parseColor(colorString);
  }

  /// Get font size by key
  double getFontSize(String key) {
    final dynamic fontSize = _config['fonts']?['sizes']?[key];
    if (fontSize == null) {
      throw ArgumentError('Font size key "$key" not found in config');
    }
    return fontSize.toDouble();
  }

  /// Get font weight by key
  FontWeight getFontWeight(String key) {
    final dynamic weight = _config['fonts']?['weights']?[key];
    if (weight == null) {
      throw ArgumentError('Font weight key "$key" not found in config');
    }
    return FontWeight.values.firstWhere((w) => w.value == weight, orElse: () => FontWeight.normal);
  }

  /// Get spacing value by key
  double getSpacing(String key) {
    final dynamic spacing = _config['spacing']?[key];
    if (spacing == null) {
      throw ArgumentError('Spacing key "$key" not found in config');
    }
    return spacing.toDouble();
  }

  /// Get border radius by key
  double getRadius(String key) {
    final dynamic radius = _config['radii']?[key];
    if (radius == null) {
      throw ArgumentError('Radius key "$key" not found in config');
    }
    return radius.toDouble();
  }

  /// Get component property by component name and property key
  T getComponentProperty<T>(String component, String property) {
    final dynamic value = _config['components']?[component]?[property];
    if (value == null) {
      throw ArgumentError('Component property "$component.$property" not found in config');
    }

    if (T == Color && value is String) {
      return _parseColor(value) as T;
    }

    if (T == double) {
      return value.toDouble() as T;
    }

    return value as T;
  }

  /// Parse color string to Color object
  Color _parseColor(String colorString) {
    String hex = colorString.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add alpha if not present
    }
    return Color(int.parse(hex, radix: 16));
  }

  /// Get primary font family
  String get primaryFont => _config['fonts']?['primary'] ?? 'SF Pro Rounded';
}
