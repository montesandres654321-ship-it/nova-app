// lib/pages/profile_page.dart
// ============================================================
// PERFIL — Nova App Móvil
// ============================================================
// Usa ApiService.updateProfile() — PATCH /users/me/profile con token
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../utils/constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _editing = false;
  bool _loading = false;
  bool _isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(AppConstants.keyUser);
      final isGoogle = await GoogleAuthService.isGoogleUser();
      setState(() => _isGoogleUser = isGoogle);

      if (userStr != null) {
        final user = jsonDecode(userStr);
        setState(() {
          _firstNameCtrl.text = user['first_name'] ?? '';
          _lastNameCtrl.text = user['last_name'] ?? '';
          _usernameCtrl.text = user['username'] ?? '';
          _emailCtrl.text = user['email'] ?? '';
          _phoneCtrl.text = user['phone'] ?? '';
        });
      }
    } catch (e) {
      _showError('Error cargando perfil: $e');
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final data = await ApiService.updateProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _isGoogleUser ? null : _phoneCtrl.text.trim(),
      );

      if (!mounted) return;

      if (data['success'] == true) {
        setState(() => _editing = false);
        _showSuccess('Perfil actualizado correctamente');
      } else {
        _showError(data['error'] ?? 'Error al actualizar');
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
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: maxWidth,
                child: Column(children: [
                  Row(children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 8),
                    const Text("Perfil", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (!_loading)
                      IconButton(icon: Icon(_editing ? Icons.close : Icons.edit, color: Colors.white),
                          onPressed: () => setState(() => _editing = !_editing)),
                  ]),
                  const SizedBox(height: 18),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(children: [
                          _buildField("Nombre", Icons.person, _firstNameCtrl, editable: _editing),
                          const SizedBox(height: 12),
                          _buildField("Apellido", Icons.person, _lastNameCtrl, editable: _editing),
                          const SizedBox(height: 12),
                          _buildField("Usuario", Icons.account_circle, _usernameCtrl, editable: _editing),
                          const SizedBox(height: 12),
                          _buildField("Correo", Icons.email, _emailCtrl, email: true, editable: _editing),
                          if (!_isGoogleUser) ...[
                            const SizedBox(height: 12),
                            _buildField("Teléfono", Icons.phone, _phoneCtrl, editable: _editing),
                          ],
                          const SizedBox(height: 20),
                          if (_editing) _buildActionButtons(),
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

  Widget _buildField(String label, IconData icon, TextEditingController ctrl, {bool email = false, required bool editable}) {
    return TextFormField(
      controller: ctrl,
      enabled: editable && !_loading,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon),
        filled: true, fillColor: editable ? Colors.grey.shade50 : Colors.grey.shade200,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) {
        if (!editable) return null;
        if (v == null || v.isEmpty) return 'Campo obligatorio';
        if (email && !v.contains('@')) return 'Correo inválido';
        return null;
      },
    );
  }

  Widget _buildActionButtons() => Row(children: [
    Expanded(child: OutlinedButton(
        onPressed: _loading ? null : () => setState(() => _editing = false),
        child: const Text("Cancelar"))),
    const SizedBox(width: 10),
    Expanded(child: ElevatedButton(
      onPressed: _loading ? null : _save,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF06B6A4), foregroundColor: Colors.white),
      child: _loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
          : const Text("Guardar"),
    )),
  ]);
}