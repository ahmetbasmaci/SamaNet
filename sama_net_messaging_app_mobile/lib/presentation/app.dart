import 'package:flutter/material.dart';
import 'package:sama_net_messaging_app_mobile/core/constants/arabic_strings.dart';
import 'package:sama_net_messaging_app_mobile/core/theme/app_theme.dart';
import 'package:sama_net_messaging_app_mobile/presentation/blocs/auth_bloc.dart';
import 'package:sama_net_messaging_app_mobile/presentation/pages/login_page.dart';
import 'package:sama_net_messaging_app_mobile/presentation/pages/main_screen.dart';
import 'package:sama_net_messaging_app_mobile/presentation/pages/register_page.dart';
import 'package:sama_net_messaging_app_mobile/presentation/pages/search_page.dart';
import 'package:sama_net_messaging_app_mobile/presentation/widgets/splash_screen.dart';

import 'blocs/bloc_provider.dart';

class MessagingApp extends StatelessWidget {
  final AppTheme theme;
  final AuthBloc authBloc;

  const MessagingApp({super.key, required this.theme, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      bloc: authBloc,
      child: MaterialApp(
        title: ArabicStrings.appTitle,
        theme: theme.theme,
        locale: const Locale('ar', 'SA'),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return Directionality(textDirection: TextDirection.rtl, child: child!);
        },
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
          '/search': (context) => const SearchPage(),
        },
      ),
    );
  }
}
