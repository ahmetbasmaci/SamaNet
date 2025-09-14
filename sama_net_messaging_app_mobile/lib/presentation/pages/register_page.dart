import 'package:flutter/material.dart';
import '../../core/constants/arabic_strings.dart';

/// Register page placeholder
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ArabicStrings.register)),
      body: Center(
        child: Text(
          ArabicStrings.registerPagePlaceholder,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
