// lib/pages/change_password_page.dart - VERSIÓN CORREGIDA
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  final String backendUrl = "http://172.17.8.124:3000"; // ✅ MISMA IP

  Future<void> _updatePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      // Obtener usuario logueado
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      if (userData == null) {
        _showError("No se encontró usuario logueado");
        return;
      }

      final user = jsonDecode(userData);
      final userId = user["id"];

      // ✅ LOG para debug
      debugPrint("Enviando cambio de contraseña para usuario: $userId");

      final response = await http.post(
        Uri.parse("$backendUrl/users/change-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "oldPassword": _oldPassCtrl.text.trim(),
          "newPassword": _newPassCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      // ✅ LOG de respuesta
      debugPrint("Respuesta status: ${response.statusCode}");
      debugPrint("Respuesta body: ${response.body}");

      // ✅ Verificar si la respuesta es JSON válido
      if (response.body.trim().startsWith('<!DOCTYPE html>')) {
        throw Exception("El servidor respondió con HTML. Verifica que la ruta sea correcta.");
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data["success"] == true) {
          _showSuccess(data["message"] ?? "Contraseña actualizada correctamente");
          _clearForm();
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
        } else {
          throw Exception(data["error"] ?? "Error al actualizar contraseña");
        }
      } else {
        throw Exception("Error ${response.statusCode}: ${data["error"] ?? response.body}");
      }
    } on http.ClientException catch (e) {
      _showError("Error de conexión: $e");
    } on FormatException catch (e) {
      _showError("Error en formato de respuesta: $e");
    } on Exception catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearForm() {
    _oldPassCtrl.clear();
    _newPassCtrl.clear();
    _confirmCtrl.clear();
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
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

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: SizedBox(
                width: maxWidth,
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: _loading ? null : () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cambiar contraseña',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Formulario
                    Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildPasswordField(
                                controller: _oldPassCtrl,
                                label: 'Contraseña actual',
                                obscureText: _obscureOld,
                                onToggle: () => setState(() => _obscureOld = !_obscureOld),
                              ),
                              const SizedBox(height: 12),
                              _buildPasswordField(
                                controller: _newPassCtrl,
                                label: 'Nueva contraseña',
                                obscureText: _obscureNew,
                                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                              ),
                              const SizedBox(height: 12),
                              _buildPasswordField(
                                controller: _confirmCtrl,
                                label: 'Confirmar contraseña',
                                obscureText: _obscureConfirm,
                                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                isConfirm: true,
                              ),
                              const SizedBox(height: 24),
                              _buildUpdateButton(),
                            ],
                          ),
                        ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    bool isConfirm = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: !_loading,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) {
          return 'Ingresa la contraseña';
        }
        if (!isConfirm && v.length < 6) {
          return 'Mínimo 6 caracteres';
        }
        if (isConfirm && v != _newPassCtrl.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _loading ? null : _updatePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF06B6A4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Actualizar contraseña',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}