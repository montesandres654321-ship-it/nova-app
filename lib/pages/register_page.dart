// lib/pages/register_page.dart - VERSIÓN CORREGIDA

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final String backendUrl = "http://172.20.10.2:3000";

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstCtrl = TextEditingController();
  final TextEditingController _lastCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

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

  // ✅ MÉTODO CORREGIDO PARA EL CALENDARIO
  Future<void> _pickDate() async {
    // Verificar que el contexto esté montado
    if (!mounted) return;

    final DateTime now = DateTime.now();
    final DateTime initial = DateTime(now.year - 20, now.month, now.day);

    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: now,
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: const Color(0xFF06B6A4),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF06B6A4),
                onPrimary: Colors.white,
              ),
              buttonTheme: const ButtonThemeData(
                textTheme: ButtonTextTheme.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      // Verificar nuevamente que el widget esté montado después del await
      if (!mounted) return;

      if (picked != null) {
        setState(() {
          _dobCtrl.text =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        });
      }
    } catch (e) {
      // Manejar error del date picker
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar fecha: $e')),
        );
      }
    }
  }

  // ✅ MÉTODO ALTERNATIVO SI EL ANTERIOR NO FUNCIONA
  Future<void> _pickDateAlternative() async {
    FocusScope.of(context).unfocus(); // Cerrar teclado si está abierto

    final DateTime now = DateTime.now();
    final DateTime initial = DateTime(now.year - 20, now.month, now.day);

    // Pequeño delay para asegurar que el contexto esté listo
    await Future.delayed(const Duration(milliseconds: 100));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null && mounted) {
      setState(() {
        _dobCtrl.text =
        "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
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
      final url = Uri.parse("$backendUrl/users/register");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": _firstCtrl.text.trim(),
          "lastName": _lastCtrl.text.trim(),
          "username": _usernameCtrl.text.trim(),
          "email": _emailCtrl.text.trim(),
          "password": _passCtrl.text.trim(),
          "dob": _dobCtrl.text.trim(),
          "gender": _gender,
          "phone": "$_countryCode ${_phoneCtrl.text.trim()}",
          "accepted_terms": _acceptTos ? 1 : 0,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data["success"] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cuenta creada correctamente")));
        Navigator.of(context).pop();
      } else {
        final err = data["error"] ?? "Error al registrar";
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión: $e")));
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa tu correo';
    if (!v.contains('@')) return 'Correo inválido';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const Color tealStart = Color(0xFF06B6A4);
    const Color tealEnd = Color(0xFF0EA5E9);

    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.94;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: tealStart,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: SizedBox(
                width: maxWidth,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Nombre
                          TextFormField(
                            controller: _firstCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa tu nombre'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Apellido
                          TextFormField(
                            controller: _lastCtrl,
                            decoration: InputDecoration(
                              labelText: 'Apellido',
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa tu apellido'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Usuario
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Nombre de usuario',
                              prefixIcon: const Icon(Icons.account_box_outlined),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Elige un nombre de usuario';
                              }
                              if (v.contains(' ')) return 'No uses espacios';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Correo
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 12),

                          // Contraseña
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 12),

                          // Confirmar contraseña
                          TextFormField(
                            controller: _confirmCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirma tu contraseña';
                              }
                              if (v != _passCtrl.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // ✅ FECHA DE NACIMIENTO - CORREGIDO
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _dobCtrl,
                                  readOnly: true,
                                  onTap: _pickDate, // ✅ Usar método corregido
                                  decoration: InputDecoration(
                                    labelText: 'Fecha de nacimiento',
                                    prefixIcon: const Icon(Icons.cake_outlined),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: _pickDate, // ✅ También funciona desde el ícono
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    hintText: 'YYYY-MM-DD',
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Selecciona tu fecha'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _gender,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Femenino', child: Text('Femenino')),
                                    DropdownMenuItem(
                                        value: 'Masculino', child: Text('Masculino')),
                                    DropdownMenuItem(
                                        value: 'Otro', child: Text('Otro')),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _gender = v ?? _gender),
                                  decoration: InputDecoration(
                                    labelText: 'Género',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Teléfono
                          Row(
                            children: [
                              Container(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: _countryCode,
                                  underline: const SizedBox(),
                                  items: _countryCodes
                                      .map((c) =>
                                      DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _countryCode = v ?? _countryCode),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'Teléfono móvil',
                                    prefixIcon: const Icon(Icons.phone),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Ingresa tu teléfono';
                                    }
                                    if (v.trim().length < 7) {
                                      return 'Teléfono muy corto';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Términos
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTos,
                                onChanged: (v) =>
                                    setState(() => _acceptTos = v ?? false),
                              ),
                              const Expanded(
                                  child: Text('Acepto los términos y condiciones'))
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Botón de registrar
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isRegistering ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isRegistering
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Text('Crear cuenta',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                          ),
                        ],
                      ),
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
}