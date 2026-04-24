// lib/pages/change_password_page.dart
// ============================================================
// CAMBIAR CONTRASEÑA — Nova App Móvil
// ============================================================
// Usa ApiService.changePassword() — POST /users/me/password con token
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  Future<void> _updatePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final data = await ApiService.changePassword(
        currentPassword: _oldPassCtrl.text.trim(),
        newPassword: _newPassCtrl.text.trim(),
      );

      if (!mounted) return;

      if (data['success'] == true) {
        _showSuccess(data['message'] ?? 'Contraseña actualizada correctamente');
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmCtrl.clear();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        _showError(data['error'] ?? 'Error al actualizar contraseña');
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green));

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red));

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
    final maxWidth = MediaQuery.of(context).size.width * 0.94;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [tealStart, tealEnd], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: SizedBox(
                width: maxWidth,
                child: Column(children: [
                  Row(children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _loading ? null : () => Navigator.pop(context)),
                    const SizedBox(width: 8),
                    const Text('Cambiar contraseña',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 14),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          _buildPasswordField(controller: _oldPassCtrl, label: 'Contraseña actual',
                              obscure: _obscureOld, onToggle: () => setState(() => _obscureOld = !_obscureOld)),
                          const SizedBox(height: 12),
                          _buildPasswordField(controller: _newPassCtrl, label: 'Nueva contraseña',
                              obscure: _obscureNew, onToggle: () => setState(() => _obscureNew = !_obscureNew)),
                          const SizedBox(height: 12),
                          _buildPasswordField(controller: _confirmCtrl, label: 'Confirmar contraseña',
                              obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm), isConfirm: true),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity, height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _updatePassword,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6A4),
                                  foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                  : const Text('Actualizar contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ]),
                      ),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    bool isConfirm = false,
  }) {
    return TextFormField(
      controller: controller, obscureText: obscure, enabled: !_loading,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: onToggle),
        filled: true, fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa la contraseña';
        if (!isConfirm && v.length < 6) return 'Mínimo 6 caracteres';
        if (isConfirm && v != _newPassCtrl.text) return 'Las contraseñas no coinciden';
        return null;
      },
    );
  }
}