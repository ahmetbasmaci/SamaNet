import 'package:flutter/material.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_style_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await initializeDependencies();

  // Load app style configuration
  final styleConfig = await AppStyleConfig.load();
  final appTheme = AppTheme(styleConfig);

  // Get AuthBloc from service locator
  final authBloc = serviceLocator.get<AuthBloc>();

  // Check authentication status
  authBloc.add(AuthCheckRequested());

  runApp(MessagingApp(theme: appTheme, authBloc: authBloc));
}
