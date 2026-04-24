// lib/pages/register_page.dart
// ============================================================
// REGISTRO — Nova App Móvil
// ============================================================
// Usa ApiService.register() — IP y rutas centralizadas
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _gender = 'Femenino';
  String _countryCode = '+57';
  bool _obscure = true;
  bool _acceptTos = false;
  bool _isRegistering = false;

  final List<String> _countryCodes = ['+57', '+1', '+34', '+52'];

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (!mounted) return;
    final now = DateTime.now();
    final initial = DateTime(now.year - 20, now.month, now.day);
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: now,
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF06B6A4), onPrimary: Colors.white),
          ),
          child: child!,
        ),
      );
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          _dobCtrl.text = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTos) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes aceptar los términos y condiciones')));
      return;
    }
    setState(() => _isRegistering = true);

    try {
      final data = await ApiService.register(
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        phone: '$_countryCode ${_phoneCtrl.text.trim()}',
        dob: _dobCtrl.text.trim(),
        gender: _gender,
        acceptedTerms: _acceptTos,
      );

      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cuenta creada correctamente"), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Error al registrar')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color tealStart = Color(0xFF06B6A4);
    const Color tealEnd = Color(0xFF0EA5E9);
    final maxWidth = MediaQuery.of(context).size.width * 0.94;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro'), backgroundColor: tealStart,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop())),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [tealStart, tealEnd], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: SizedBox(
                width: maxWidth,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(children: [
                        _field('Nombre', Icons.person_outline, _firstCtrl, validator: _reqValidator('nombre')),
                        const SizedBox(height: 12),
                        _field('Apellido', Icons.person_outline, _lastCtrl, validator: _reqValidator('apellido')),
                        const SizedBox(height: 12),
                        // Username con hint claro
                        TextFormField(controller: _usernameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nombre de usuario',
                            hintText: 'ej: yeison_alvarez',
                            helperText: 'Sin espacios, será tu identificador único',
                            helperStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
                            prefixIcon: const Icon(Icons.account_box_outlined),
                            filled: true, fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (v) {
                            // Auto-reemplazar espacios por guion bajo
                            if (v.contains(' ')) {
                              _usernameCtrl.text = v.replaceAll(' ', '_');
                              _usernameCtrl.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _usernameCtrl.text.length));
                            }
                          },
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Elige un nombre de usuario';
                            if (v.contains(' ')) return 'Sin espacios (usa _ o .)';
                            if (v.length < 3) return 'Mínimo 3 caracteres';
                            if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) return 'Solo letras, números, _ y .';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _field('Correo electrónico', Icons.email_outlined, _emailCtrl,
                            keyboard: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Correo inválido';
                              return null;
                            }),
                        const SizedBox(height: 12),
                        _field('Contraseña', Icons.lock_outline, _passCtrl, obscure: _obscure,
                            suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
                            validator: (v) { if (v == null || v.isEmpty) return 'Requerido'; if (v.length < 6) return 'Mínimo 6 caracteres'; return null; }),
                        const SizedBox(height: 12),
                        _field('Confirmar contraseña', Icons.lock_outline, _confirmCtrl, obscure: _obscure,
                            validator: (v) { if (v != _passCtrl.text) return 'No coinciden'; return null; }),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: TextFormField(controller: _dobCtrl, readOnly: true, onTap: _pickDate,
                              decoration: _dec('Fecha de nacimiento', Icons.cake_outlined,
                                  suffix: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate), hint: 'YYYY-MM-DD'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Selecciona fecha' : null)),
                          const SizedBox(width: 12),
                          Expanded(child: DropdownButtonFormField<String>(value: _gender,
                              items: const [DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                                DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                                DropdownMenuItem(value: 'Otro', child: Text('Otro'))],
                              onChanged: (v) => setState(() => _gender = v ?? _gender),
                              decoration: _dec('Género', null))),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                              child: DropdownButton<String>(value: _countryCode, underline: const SizedBox(),
                                  items: _countryCodes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (v) => setState(() => _countryCode = v ?? _countryCode))),
                          const SizedBox(width: 8),
                          Expanded(child: _field('Teléfono móvil', Icons.phone, _phoneCtrl,
                              keyboard: TextInputType.phone,
                              validator: (v) { if (v == null || v.trim().isEmpty) return 'Requerido'; if (v.trim().length < 7) return 'Muy corto'; return null; })),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Checkbox(value: _acceptTos, onChanged: (v) => setState(() => _acceptTos = v ?? false)),
                          const Expanded(child: Text('Acepto los términos y condiciones')),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: _isRegistering ? null : _register,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: _isRegistering
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Crear cuenta', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => Navigator.of(context).pop(),
                            child: const Text('¿Ya tienes cuenta? Inicia sesión')),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, IconData? icon, TextEditingController ctrl,
      {bool obscure = false, Widget? suffix, TextInputType? keyboard, String? Function(String?)? validator}) {
    return TextFormField(controller: ctrl, obscureText: obscure, keyboardType: keyboard,
        decoration: _dec(label, icon, suffix: suffix), validator: validator);
  }

  InputDecoration _dec(String label, IconData? icon, {Widget? suffix, String? hint}) =>
      InputDecoration(labelText: label, hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null, suffixIcon: suffix,
          filled: true, fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));

  String? Function(String?) _reqValidator(String field) =>
          (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu $field' : null;
}