// lib/pages/login_page.dart
// ============================================================
// LOGIN — Nova App Móvil
// ============================================================
// • Usa ApiService centralizado (IP + rutas correctas)
// • Guarda token JWT en SharedPreferences
// • Login manual + Google
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../utils/constants.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(AppConstants.keySavedEmail);
    final savedRemember = prefs.getBool(AppConstants.keyRememberMe) ?? false;
    if (savedEmail != null) _emailCtrl.text = savedEmail;
    setState(() => _rememberMe = savedRemember);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.login(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      if (data['success'] == true) {
        // Recordar email si está activado
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.keyAuthProvider, 'email');
        if (_rememberMe) {
          await prefs.setString(AppConstants.keySavedEmail, _emailCtrl.text.trim());
          await prefs.setBool(AppConstants.keyRememberMe, true);
        } else {
          await prefs.remove(AppConstants.keySavedEmail);
          await prefs.setBool(AppConstants.keyRememberMe, false);
        }

        if (!mounted) return;
        final user = data['user'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bienvenido ${user?['first_name'] ?? user?['username'] ?? ''}")),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Error en login')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await GoogleAuthService.signInWithGoogle();

      if (result != null && result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? '¡Bienvenido!'),
          backgroundColor: Colors.green,
        ));
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result?['error'] ?? 'Error al iniciar con Google'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color tealStart = Color(0xFF06B6A4);
    const Color tealEnd = Color(0xFF0EA5E9);
    final maxWidth = MediaQuery.of(context).size.width * 0.98;
    final inputIconColor = Colors.grey.shade700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [tealStart, tealEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: maxWidth,
                child: Column(children: [
                  const SizedBox(height: 8),
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text("Nova App",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),

                  // Card principal
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Correo",
                              prefixIcon: Padding(padding: const EdgeInsets.all(12),
                                  child: Icon(Icons.email_outlined, size: 20, color: inputIconColor)),
                              filled: true, fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu correo';
                              if (!v.contains('@')) return 'Correo inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              prefixIcon: Padding(padding: const EdgeInsets.all(12),
                                  child: Icon(Icons.lock_outline, size: 20, color: inputIconColor)),
                              filled: true, fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: inputIconColor),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Row(children: [
                              Checkbox(value: _rememberMe, onChanged: (val) => setState(() => _rememberMe = val ?? false)),
                              const Text("Recordarme"),
                            ]),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                              child: const Text("¿Olvidaste tu contraseña?", style: TextStyle(fontSize: 12)),
                            ),
                          ]),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity, height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white, foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Iniciar sesión'),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Google
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, foregroundColor: Colors.black87,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Image.asset('assets/images/google_icon.png', width: 24, height: 24,
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24, color: Colors.red)),
                        const SizedBox(width: 12),
                        const Text('Continuar con Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _socialButton(text: "Continuar con Facebook", icon: Icons.facebook,
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente')))),
                  const SizedBox(height: 10),
                  _socialButton(text: "Continuar con Apple", icon: Icons.apple,
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente')))),

                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("¿No tienes cuenta?", style: TextStyle(color: Colors.white)),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RegisterPage())),
                      child: const Text("Crear cuenta"),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({required String text, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity, height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(text),
      ),
    );
  }
}