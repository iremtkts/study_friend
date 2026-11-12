import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'navigation.dart';
import '../screens/auth_gate_screen.dart';
import '../screens/login_screen.dart';

class StudyFriendApp extends StatelessWidget {
  const StudyFriendApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: appNavigatorKey,
    debugShowCheckedModeBanner: false,
    title: 'BiÖğren',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        surface: AppColors.pale,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
      ),
    ),
    routes: {loginRouteName: (_) => const LoginScreen()},
    home: const AuthGateScreen(),
  );
}

// Keeps the starter project's widget test and existing entry references valid.
typedef MyApp = StudyFriendApp;
