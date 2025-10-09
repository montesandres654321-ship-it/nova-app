// lib/pages/profile_page.dart - VERSIÓN CORREGIDA
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'google_auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  bool _editing = false;
  bool _loading = false;
  int? userId;
  bool _isGoogleUser = false;

  final String backendUrl = "http://172.17.8.124:3000";

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      final isGoogle = await GoogleAuthService.isGoogleUser();

      setState(() {
        _isGoogleUser = isGoogle;
      });

      if (userStr != null) {
        final user = jsonDecode(userStr);

        setState(() {
          userId = user["id"];
          _firstNameCtrl.text = user["first_name"] ?? "";
          _lastNameCtrl.text = user["last_name"] ?? "";
          _usernameCtrl.text = user["username"] ?? "";
          _emailCtrl.text = user["email"] ?? "";
          _phoneCtrl.text = user["phone"] ?? "";
        });
      }
    } catch (e) {
      _showError("Error cargando perfil: $e");
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final url = Uri.parse("$backendUrl/users/update/$userId");

      debugPrint("🔄 Enviando actualización a: $url");

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "first_name": _firstNameCtrl.text.trim(),
          "last_name": _lastNameCtrl.text.trim(),
          "username": _usernameCtrl.text.trim(),
          "email": _emailCtrl.text.trim(),
          "phone": _isGoogleUser ? "" : _phoneCtrl.text.trim(), // ✅ Solo enviar teléfono si no es Google
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint("📡 Respuesta status: ${response.statusCode}");

      if (response.statusCode == 200) {
        if (response.body.trim().startsWith('<!DOCTYPE html>')) {
          throw Exception("El servidor respondió con HTML. Verifica el endpoint.");
        }

        final updatedUser = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(updatedUser));

        setState(() {
          _editing = false;
          _loading = false;
        });

        if (!mounted) return;
        _showSuccess("Perfil actualizado correctamente");

      } else {
        if (response.statusCode == 404) {
          throw Exception("Endpoint no encontrado (404). Verifica la URL.");
        } else if (response.statusCode == 500) {
          throw Exception("Error interno del servidor (500).");
        } else {
          throw Exception("Error ${response.statusCode}: ${response.body}");
        }
      }
    } on http.ClientException catch (e) {
      _showError("Error de conexión: $e");
    } on Exception catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: maxWidth,
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Perfil",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (!_loading)
                          IconButton(
                            icon: Icon(
                              _editing ? Icons.close : Icons.edit,
                              color: Colors.white,
                            ),
                            onPressed: () => setState(() => _editing = !_editing),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Formulario
                    Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField("Nombre", Icons.person, _firstNameCtrl, editable: _editing),
                              const SizedBox(height: 12),
                              _buildTextField("Apellido", Icons.person, _lastNameCtrl, editable: _editing),
                              const SizedBox(height: 12),
                              _buildTextField("Usuario", Icons.account_circle, _usernameCtrl, editable: _editing),
                              const SizedBox(height: 12),
                              _buildTextField("Correo", Icons.email, _emailCtrl, email: true, editable: _editing),

                              // ✅ CORREGIDO: Solo mostrar teléfono si NO es usuario Google
                              if (!_isGoogleUser) ...[
                                const SizedBox(height: 12),
                                _buildTextField("Teléfono", Icons.phone, _phoneCtrl, editable: _editing),
                              ],

                              const SizedBox(height: 20),
                              if (_editing) _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      IconData icon,
      TextEditingController controller, {
        bool email = false,
        required bool editable,
      }) {
    return TextFormField(
      controller: controller,
      enabled: editable && !_loading,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: editable ? Colors.grey.shade50 : Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) {
        if (!editable) return null;
        if (v == null || v.isEmpty) return "Campo obligatorio";
        if (email && !v.contains("@")) return "Correo inválido";
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _loading ? null : () => setState(() => _editing = false),
            child: const Text("Cancelar"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6A4),
              foregroundColor: Colors.white,
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
                : const Text("Guardar"),
          ),
        ),
      ],
    );
  }
}