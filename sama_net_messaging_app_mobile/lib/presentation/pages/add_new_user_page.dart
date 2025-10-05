import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/arabic_strings.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/auth.dart';
import '../../data/services/auth_service.dart';

/// Admin page for registering new users
class AddNewUserPage extends StatefulWidget {
  const AddNewUserPage({super.key});

  @override
  State<AddNewUserPage> createState() => _AddNewUserPageState();
}

class _AddNewUserPageState extends State<AddNewUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _displayNameController = TextEditingController();

  late final AuthService _authService;
  bool _isRegistering = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authService = serviceLocator.get<AuthService>();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ArabicStrings.emptyUsername;
    }
    if (value.trim().length < 4) {
      return ArabicStrings.usernameMinLength4;
    }
    if (value.trim().length > 50) {
      return ArabicStrings.usernameValidation;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ArabicStrings.emptyPassword;
    }
    if (value.length < 3) {
      return ArabicStrings.passwordMinLength;
    }
    if (value.length > 100) {
      return ArabicStrings.passwordValidation;
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ArabicStrings.enterPhoneNumber;
    }
    final phoneDigits = value.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (phoneDigits.length < 10 || phoneDigits.length > 20) {
      return ArabicStrings.phoneNumberValidation;
    }
    return null;
  }

  String? _validateDisplayName(String? value) {
    if (value != null && value.trim().length > 100) {
      return ArabicStrings.displayNameValidation;
    }
    return null;
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final registerRequest = RegisterRequest(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneNumberController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
      );

      final response = await _authService.register(registerRequest);

      if (!mounted) return;

      if (response.isSuccess) {
        _showSnackBar(ArabicStrings.userRegisteredSuccessfully);
        // Clear form
        _usernameController.clear();
        _passwordController.clear();
        _phoneNumberController.clear();
        _displayNameController.clear();
        // Optionally navigate back
        Navigator.of(context).pop();
      } else {
        _showSnackBar(
          '${ArabicStrings.userRegistrationFailed}: ${response.error ?? ArabicStrings.unexpectedError}',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        '${ArabicStrings.userRegistrationFailed}: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ArabicStrings.addNewUser),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                ArabicStrings.registerNewUser,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Username field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: ArabicStrings.usernameLabel,
                  hintText: ArabicStrings.usernameHint,
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                validator: _validateUsername,
                textInputAction: TextInputAction.next,
                enabled: !_isRegistering,
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: ArabicStrings.password,
                  hintText: ArabicStrings.passwordHint,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                validator: _validatePassword,
                textInputAction: TextInputAction.next,
                enabled: !_isRegistering,
              ),
              const SizedBox(height: 16),

              // Phone number field
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: ArabicStrings.phoneNumberLabel,
                  hintText: ArabicStrings.phoneNumberHint,
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                validator: _validatePhoneNumber,
                textInputAction: TextInputAction.next,
                enabled: !_isRegistering,
              ),
              const SizedBox(height: 16),

              // Display name field (optional)
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: ArabicStrings.displayNameLabel,
                  hintText: ArabicStrings.displayNameHint,
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                validator: _validateDisplayName,
                textInputAction: TextInputAction.done,
                enabled: !_isRegistering,
                onFieldSubmitted: (_) => _registerUser(),
              ),
              const SizedBox(height: 32),

              // Register button
              FilledButton.icon(
                onPressed: _isRegistering ? null : _registerUser,
                icon: _isRegistering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add),
                label: Text(
                  _isRegistering ? ArabicStrings.loading : ArabicStrings.register,
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
