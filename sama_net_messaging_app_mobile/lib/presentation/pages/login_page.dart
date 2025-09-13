import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/validation_utils.dart';
import '../../core/constants/arabic_strings.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/bloc_provider.dart';

/// Login page for user authentication
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Auto-fill credentials in debug mode
    if (kDebugMode) {
      _identifierController.text = 'ahmet';
      _passwordController.text = '231';
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      authBloc.add(AuthLoginRequested(username: _identifierController.text.trim(), password: _passwordController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          bloc: BlocProvider.of<AuthBloc>(context),
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error));
            } else if (state is AuthAuthenticated) {
              Navigator.of(context).pushReplacementNamed('/main');
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            bloc: BlocProvider.of<AuthBloc>(context),
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),

                      // App Logo/Title
                      Icon(Icons.chat_bubble_outline, size: 80, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),

                      Text(
                        ArabicStrings.appTitle,
                        style: theme.textTheme.displayLarge?.copyWith(color: theme.colorScheme.primary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        ArabicStrings.appSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // Email/Phone Input
                      TextFormField(
                        controller: _identifierController,
                        decoration: InputDecoration(
                          labelText: ArabicStrings.nameOrPhone,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return ArabicStrings.nameOrPhoneRequired;
                          }
                          // Check if it's email or phone format
                          if (!ValidationUtils.isValidName(value) && !ValidationUtils.isValidPhone(value)) {
                            return ArabicStrings.enterValidNameOrPhone;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Password Input
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: ArabicStrings.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: ValidationUtils.validatePassword,
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        child: isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(ArabicStrings.login),
                      ),

                      const SizedBox(height: 16),

                      // Forgot Password Link
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                // TODO: Implement forgot password
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(ArabicStrings.forgotPasswordComingSoon)));
                              },
                        child: Text(ArabicStrings.forgotPassword, style: TextStyle(color: theme.colorScheme.primary)),
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(ArabicStrings.or, style: theme.textTheme.bodySmall),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Register Button
                      OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.of(context).pushNamed('/register');
                              },
                        child: Text(ArabicStrings.createNewAccount),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
