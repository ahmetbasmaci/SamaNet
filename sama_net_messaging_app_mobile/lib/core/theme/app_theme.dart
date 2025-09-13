import 'package:flutter/material.dart';
import 'app_style_config.dart';

/// Theme provider that creates Flutter ThemeData from style configuration
class AppTheme {
  final AppStyleConfig _styleConfig;

  AppTheme(this._styleConfig);

  /// Get the main app theme
  ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: _styleConfig.getColor('primary'),
        secondary: _styleConfig.getColor('accent'),
        surface: _styleConfig.getColor('background'),
        onSurface: _styleConfig.getColor('textPrimary'),
        error: _styleConfig.getColor('danger'),
      ),
      scaffoldBackgroundColor: _styleConfig.getColor('background'),
      fontFamily: _styleConfig.primaryFont,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: _styleConfig.getComponentProperty<Color>('appBar', 'background'),
        foregroundColor: _styleConfig.getComponentProperty<Color>('appBar', 'textColor'),
        iconTheme: IconThemeData(color: _styleConfig.getComponentProperty<Color>('appBar', 'iconColor')),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: _styleConfig.getFontSize('xl'),
          fontWeight: _styleConfig.getFontWeight('semibold'),
          color: _styleConfig.getComponentProperty<Color>('appBar', 'textColor'),
          fontFamily: _styleConfig.primaryFont,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _styleConfig.getComponentProperty<Color>('buttonPrimary', 'background'),
          foregroundColor: _styleConfig.getComponentProperty<Color>('buttonPrimary', 'textColor'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_styleConfig.getComponentProperty<double>('buttonPrimary', 'radius')),
          ),
          padding: EdgeInsets.symmetric(
            vertical: _styleConfig.getComponentProperty<double>('buttonPrimary', 'paddingVertical'),
            horizontal: _styleConfig.getComponentProperty<double>('buttonPrimary', 'paddingHorizontal'),
          ),
          textStyle: TextStyle(
            fontSize: _styleConfig.getFontSize('md'),
            fontWeight: _styleConfig.getFontWeight('semibold'),
            fontFamily: _styleConfig.primaryFont,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _styleConfig.getComponentProperty<Color>('inputField', 'background'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_styleConfig.getComponentProperty<double>('inputField', 'radius')),
          borderSide: BorderSide(color: _styleConfig.getComponentProperty<Color>('inputField', 'borderColor')),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_styleConfig.getComponentProperty<double>('inputField', 'radius')),
          borderSide: BorderSide(color: _styleConfig.getComponentProperty<Color>('inputField', 'borderColor')),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_styleConfig.getComponentProperty<double>('inputField', 'radius')),
          borderSide: BorderSide(color: _styleConfig.getColor('primary'), width: 2),
        ),
        contentPadding: EdgeInsets.all(_styleConfig.getComponentProperty<double>('inputField', 'padding')),
        hintStyle: TextStyle(
          color: _styleConfig.getColor('textSecondary'),
          fontSize: _styleConfig.getFontSize('md'),
          fontFamily: _styleConfig.primaryFont,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: _styleConfig.getFontSize('title'),
          fontWeight: _styleConfig.getFontWeight('bold'),
          color: _styleConfig.getColor('textPrimary'),
          fontFamily: _styleConfig.primaryFont,
        ),
        titleLarge: TextStyle(
          fontSize: _styleConfig.getFontSize('xxl'),
          fontWeight: _styleConfig.getFontWeight('semibold'),
          color: _styleConfig.getColor('textPrimary'),
          fontFamily: _styleConfig.primaryFont,
        ),
        titleMedium: TextStyle(
          fontSize: _styleConfig.getFontSize('xl'),
          fontWeight: _styleConfig.getFontWeight('medium'),
          color: _styleConfig.getColor('textPrimary'),
          fontFamily: _styleConfig.primaryFont,
        ),
        bodyLarge: TextStyle(
          fontSize: _styleConfig.getFontSize('lg'),
          fontWeight: _styleConfig.getFontWeight('regular'),
          color: _styleConfig.getColor('textPrimary'),
          fontFamily: _styleConfig.primaryFont,
        ),
        bodyMedium: TextStyle(
          fontSize: _styleConfig.getFontSize('md'),
          fontWeight: _styleConfig.getFontWeight('regular'),
          color: _styleConfig.getColor('textPrimary'),
          fontFamily: _styleConfig.primaryFont,
        ),
        bodySmall: TextStyle(
          fontSize: _styleConfig.getFontSize('sm'),
          fontWeight: _styleConfig.getFontWeight('regular'),
          color: _styleConfig.getColor('textSecondary'),
          fontFamily: _styleConfig.primaryFont,
        ),
      ),
    );
  }

  /// Get style configuration for custom components
  AppStyleConfig get styleConfig => _styleConfig;
}
