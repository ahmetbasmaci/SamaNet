import 'package:flutter/material.dart';
import '../../core/constants/arabic_strings.dart';

/// Splash screen shown during app initialization
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 100, color: theme.colorScheme.onPrimary),
            const SizedBox(height: 24),
            Text(
              ArabicStrings.appTitle,
              style: theme.textTheme.displayLarge?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary)),
          ],
        ),
      ),
    );
  }
}
