import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/token_store.dart';
import 'login_screen.dart';
import 'main_shell_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  late final Future<bool> _hasTokens = TokenStore().hasTokens();

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _hasTokens,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: Center(
            child: Text('Oturum bilgisi okunamadı: ${snapshot.error}'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Scaffold(
          backgroundColor: AppColors.bg,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          ),
        );
      }
      return snapshot.data! ? const MainShell() : const LoginScreen();
    },
  );
}
