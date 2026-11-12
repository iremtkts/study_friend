import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_colors.dart';
import '../widgets/app_widgets.dart';
import 'email_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) {
      setState(() => _errorMessage = 'E-posta adresini gir.');
      return;
    }
    if (password.length < 12 || password.length > 128) {
      setState(
        () => _errorMessage = 'Şifre 12 ile 128 karakter arasında olmalı.',
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await ApiClient.instance.register(
        email: email,
        password: password,
        fullName: _nameController.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => EmailVerificationScreen(
              email: result.user.email,
              initialMessage: 'Kayıt başarılı. E-posta adresine gönderilen 6 haneli kodu gir.',
            ),
          ),
        );
      }
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

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: DetailPage(
        title: 'Hesap oluştur',
        subtitle: 'BiÖğren ile öğrenmeye başla.',
        children: [
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            maxLength: 200,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration('Ad soyad').copyWith(counterText: ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: _decoration('E-posta'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            maxLength: 128,
            decoration: _decoration('Şifre (en az 12 karakter)').copyWith(
              counterText: '',
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            AppError(message: _errorMessage!, onRetry: _register),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _register,
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
                : const Text('Kayıt ol'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text(
              'Zaten hesabın var mı? Giriş yap',
              style: TextStyle(color: AppColors.purple),
            ),
          ),
        ],
      ),
    ),
  );
}
