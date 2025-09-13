import 'package:flutter/material.dart';
import 'core/theme/app_style_config.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/services/api_client.dart';
import 'data/services/auth_service.dart';
import 'data/services/local_storage_service.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'presentation/blocs/bloc_provider.dart';
import 'presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load app style configuration
  final styleConfig = await AppStyleConfig.load();
  final appTheme = AppTheme(styleConfig);

  // Initialize services
  final apiClient = ApiClient(baseUrl: ApiConstants.baseUrl);
  final authService = AuthService(apiClient);
  final localStorage = LocalStorageService();

  // Initialize BLoCs
  final authBloc = AuthBloc(authService: authService, localStorage: localStorage);

  // Check authentication status
  authBloc.add(AuthCheckRequested());

  runApp(MessagingApp(theme: appTheme, authBloc: authBloc));
}

class MessagingApp extends StatelessWidget {
  final AppTheme theme;
  final AuthBloc authBloc;

  const MessagingApp({super.key, required this.theme, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      bloc: authBloc,
      child: MaterialApp(
        title: 'Sama Net Messaging',
        theme: theme.theme,
        debugShowCheckedModeBanner: false,
        home: BlocBuilder<AuthBloc, AuthState>(
          bloc: authBloc,
          builder: (context, state) {
            if (state is AuthLoading) {
              return const SplashScreen();
            } else if (state is AuthAuthenticated) {
              return const MainScreen();
            } else {
              return const LoginPage();
            }
          },
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}

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
              'Sama Net Messaging',
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

/// Placeholder for register page
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: const Center(
        child: Text('Register Page\n(To be implemented)', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

/// Placeholder for main screen (chat list, navigation)
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              final authBloc = BlocProvider.of<AuthBloc>(context);
              authBloc.add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Main Screen\n(Chat list, navigation to be implemented)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contacts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
