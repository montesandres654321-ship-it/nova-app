// lib/pages/login_page.dart
// CORRECCIÓN CRÍTICA: pushNamedAndRemoveUntil limpia TODO el stack
// Evita que el botón ← lleve a sesiones de otros usuarios
import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading         = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final result = await AdminService.login(
        email:    _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] != true) {
        _showError(result['error'] ?? 'Credenciales inválidas');
        return;
      }

      final role    = result['role']     as String?;
      final placeId = result['place_id'] as int?;
      final userName  = result['userName']  as String? ?? '';
      final userEmail = result['userEmail'] as String? ?? '';

      if (role == 'admin_general' || role == 'user_general') {
        // pushNamedAndRemoveUntil elimina TODAS las rutas anteriores
        // (_) => false = no mantener ninguna ruta en el stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard', (_) => false,
        );

      } else if (role == 'user_place') {
        if (placeId == null) {
          _showError('Tu usuario no tiene un lugar asignado.\nContacta al administrador.');
          await AdminService.logout();
          return;
        }
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/owner-dashboard',
              (_) => false, // limpia todo el stack
          arguments: {
            'placeId':   placeId,
            'userName':  userName,
            'userEmail': userEmail,
          },
        );

      } else {
        // role null = turista móvil, sin acceso al panel
        await AdminService.logout();
        _showError(
          'Este usuario no tiene acceso al panel administrativo.\n'
              'El panel es solo para administradores y propietarios.',
        );
      }
    } catch (e) {
      if (mounted) _showError('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF06B6A4), Color(0xFF0891B2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20, offset: const Offset(0, 10))],
              ),
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.qr_code_scanner,
                      size: 80, color: Color(0xFF06B6A4)),
                  const SizedBox(height: 24),
                  const Text('Nova Dashboard',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                          color: Color(0xFF06B6A4))),
                  const SizedBox(height: 8),
                  Text('Golfo de Morrosquillo',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.grey[50],
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingrese su email';
                      if (!v.contains('@')) return 'Email inválido';
                      return null;
                    },
                    enabled: !_loading,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true, fillColor: Colors.grey[50],
                    ),
                    validator: (v) =>
                    v?.isEmpty ?? true ? 'Ingrese su contraseña' : null,
                    enabled: !_loading,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6A4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : const Text('Iniciar Sesión',
                          style: TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}