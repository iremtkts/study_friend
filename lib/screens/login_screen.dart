import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import 'forgot_password_screen.dart';
import 'main_shell_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ApiClient.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 18),
          CircleAvatar(
            radius: 58,
            backgroundColor: const Color(0xFFE5DCFC),
            child: ClipOval(
              child: Image.asset(
                'Winking Fox Study Mascot.png',
                width: 108,
                height: 108,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Selam! Fiko geldi.',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'BiÖğren’de bugün ne öğreniyoruz?',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ForgotPasswordScreen(
                                email: _emailController.text.trim(),
                              ),
                            ),
                          ),
                    child: const Text(
                      'Şifremi unuttum',
                      style: TextStyle(color: AppColors.purple),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFE68181)),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Giriş yap'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                  child: const Text(
                    'Hesabın yok mu? Kayıt ol',
                    style: TextStyle(color: AppColors.purple),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
