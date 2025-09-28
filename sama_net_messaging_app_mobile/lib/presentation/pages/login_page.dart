import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sama_net_messaging_app_mobile/core/constants/app_constants.dart';
import 'package:sama_net_messaging_app_mobile/core/di/service_locator.dart';
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
      _passwordController.text = '123';
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
              // Enhanced error handling with different styles based on error type
              Color backgroundColor = theme.colorScheme.error;
              IconData icon = Icons.error_outline;

              switch (state.errorType) {
                case AuthErrorType.validationError:
                  backgroundColor = theme.colorScheme.secondary;
                  icon = Icons.warning_amber_outlined;
                  break;
                case AuthErrorType.networkError:
                  backgroundColor = Colors.orange;
                  icon = Icons.wifi_off_outlined;
                  break;
                case AuthErrorType.invalidCredentials:
                  backgroundColor = theme.colorScheme.error;
                  icon = Icons.lock_outline;
                  break;
                case AuthErrorType.timeout:
                  backgroundColor = Colors.amber;
                  icon = Icons.timer_outlined;
                  break;
                default:
                  backgroundColor = theme.colorScheme.error;
                  icon = Icons.error_outline;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: backgroundColor,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  action: state.errorType == AuthErrorType.networkError
                      ? SnackBarAction(
                          label: ArabicStrings.pleaseTryAgain,
                          textColor: Colors.white,
                          onPressed: _handleLogin,
                        )
                      : null,
                ),
              );
            } else if (state is AuthAuthenticated) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        ArabicStrings.loginSuccessful,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
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

                      // Username Input
                      TextFormField(
                        controller: _identifierController,
                        decoration: const InputDecoration(
                          labelText: ArabicStrings.nameOrPhone,
                          prefixIcon: Icon(Icons.person_outline),
                          helperText: ArabicStrings.usernameMinLength,
                          helperMaxLines: 2,
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        validator: ValidationUtils.validateUsername,
                      ),

                      const SizedBox(height: 16),

                      // Password Input
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: ArabicStrings.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          helperText: ArabicStrings.passwordMinLength,
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
                            : const Text(ArabicStrings.login),
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
                                ).showSnackBar(const SnackBar(content: Text(ArabicStrings.forgotPasswordComingSoon)));
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
                        child: const Text(ArabicStrings.createNewAccount),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              final apiUrlController = TextEditingController(text: ApiConstants.baseServerUrl);
              return AlertDialog(
                title: const Text('إعدادات الخادم'),
                content: TextField(
                  controller: apiUrlController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان API المحلي',
                    hintText: 'http://localhost:3000',
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newUrl = apiUrlController.text.trim();
                      await updateApiServerUrl(newUrl);

                      if (!mounted) return;

                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تحديث عنوان الخادم إلى: ${ApiConstants.baseServerUrl}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
