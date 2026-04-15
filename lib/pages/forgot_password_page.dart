// lib/pages/forgot_password_page.dart -
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  final String backendUrl = "http://192.168.2.178:3000";

  Future<void> _sendRecoveryEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      // ✅ SIMULAR ENVÍO DE EMAIL (POR AHORA)
      // En una implementación real, aquí llamarías a tu backend
      await Future.delayed(const Duration(seconds: 2));

      // ✅ SIMULAR RESPUESTA EXITOSA
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      _showSuccess("✅ Se ha enviado un enlace de recuperación a ${_emailCtrl.text}");

      // ✅ REGRESAR AUTOMÁTICAMENTE DESPUÉS DE 3 SEGUNDOS
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      _showError("❌ Error al enviar el enlace: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _goBack() {
    if (!_isLoading) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const Color tealStart = Color(0xFF06B6A4);
    const Color tealEnd = Color(0xFF0EA5E9);

    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.94;

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
                child: Column(
                  children: [
                    // ✅ HEADER MEJORADO
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: _goBack,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Recuperar Contraseña',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // ✅ CARD PRINCIPAL MEJORADO
                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _emailSent
                            ? _buildSuccessState()
                            : _buildFormState(),
                      ),
                    ),

                    // ✅ INFORMACIÓN ADICIONAL
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white, size: 24),
                          SizedBox(height: 8),
                          Text(
                            '¿No recibiste el correo?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Revisa tu carpeta de spam o solicita un nuevo enlace',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ ICONO
          const Icon(
            Icons.lock_reset_rounded,
            size: 64,
            color: Color(0xFF06B6A4),
          ),
          const SizedBox(height: 16),

          // ✅ TÍTULO Y DESCRIPCIÓN
          const Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // ✅ CAMPO DE EMAIL MEJORADO
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: 'ejemplo@correo.com',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // ✅ BOTÓN ENVIAR MEJORADO
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendRecoveryEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6A4),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Enviar enlace de recuperación',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ BOTÓN ALTERNATIVO
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading ? null : _goBack,
            child: const Text(
              'Volver al inicio de sesión',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ ICONO DE ÉXITO
        const Icon(
          Icons.check_circle_rounded,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 16),

        // ✅ MENSAJE DE ÉXITO
        const Text(
          '¡Correo enviado!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hemos enviado un enlace de recuperación a:',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _emailCtrl.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF06B6A4),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Revisa tu bandeja de entrada y sigue las instrucciones',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),

        // ✅ BOTÓN CONTINUAR
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _goBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6A4),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continuar al login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }
}