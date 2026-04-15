// lib/pages/profile/profile_page.dart
// CAMBIO: _saveChanges() usa AdminService.updateMyProfile() en vez de updateUser()
// updateMyProfile() llama PATCH /users/me/profile que acepta cualquier rol
// (updateUser() llamaba PATCH /admin/users/:id que solo acepta admin_general)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../services/admin_service.dart';
import 'change_password_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName  = '';
  String _userEmail = '';
  String _userRole  = '';
  int?   _userId;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  bool _loading = true;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController  = TextEditingController();
    _phoneController     = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName  = prefs.getString(AppConstants.keyUserName)  ?? '';
        _userEmail = prefs.getString(AppConstants.keyUserEmail) ?? '';
        _userRole  = prefs.getString(AppConstants.keyUserRole)  ?? '';
        _userId    = prefs.getInt(AppConstants.keyUserId);

        final nameParts = _userName.split(' ');
        if (nameParts.length >= 2) {
          _firstNameController.text = nameParts.first;
          _lastNameController.text  = nameParts.sublist(1).join(' ');
        } else {
          _firstNameController.text = _userName;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  // ← CORRECCIÓN: usa updateMyProfile() que acepta cualquier rol (user_place incluido)
  Future<void> _saveChanges() async {
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      final result = await AdminService.updateMyProfile(
        firstName: _firstNameController.text.trim(),
        lastName:  _lastNameController.text.trim(),
        phone:     _phoneController.text.trim().isEmpty
            ? null : _phoneController.text.trim(),
      );

      if (result['success'] == true) {
        final prefs    = await SharedPreferences.getInstance();
        final fullName =
        '${_firstNameController.text} ${_lastNameController.text}'.trim();
        await prefs.setString(AppConstants.keyUserName, fullName);
        setState(() { _userName = fullName; _editing = false; _loading = false; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['message'] ?? 'Perfil actualizado'),
              backgroundColor: Colors.green));
        }
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['error'] ?? 'Error al actualizar perfil'),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showChangePasswordDialog() {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No se pudo obtener el ID de usuario'),
          backgroundColor: Colors.red));
      return;
    }
    showDialog(context: context,
        builder: (_) => ChangePasswordDialog(userId: _userId!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            if (!_editing)
              IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _editing = true))
            else ...[
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () { setState(() => _editing = false); _loadUserData(); }),
              IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveChanges),
            ],
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(children: [

                  // Avatar
                  CircleAvatar(radius: 60, backgroundColor: Colors.teal,
                      child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                              fontSize: 48, color: Colors.white,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  Text(_userName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_userEmail,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          '${AppConstants.getRoleEmoji(_userRole)} ${AppConstants.getRoleLabel(_userRole)}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: Colors.teal))),
                  const SizedBox(height: 32),

                  // Información personal
                  Card(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Información Personal',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            TextField(
                                controller: _firstNameController,
                                enabled: _editing,
                                decoration: InputDecoration(
                                    labelText: 'Nombre(s)',
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    filled: !_editing,
                                    fillColor: !_editing ? Colors.grey[100] : null)),
                            const SizedBox(height: 16),
                            TextField(
                                controller: _lastNameController,
                                enabled: _editing,
                                decoration: InputDecoration(
                                    labelText: 'Apellido(s)',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    filled: !_editing,
                                    fillColor: !_editing ? Colors.grey[100] : null)),
                            const SizedBox(height: 16),
                            TextField(
                                controller: TextEditingController(text: _userEmail),
                                enabled: false,
                                decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.grey[100])),
                            const SizedBox(height: 16),
                            TextField(
                                controller: _phoneController,
                                enabled: _editing,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                    labelText: 'Teléfono (opcional)',
                                    prefixIcon: const Icon(Icons.phone),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    filled: !_editing,
                                    fillColor: !_editing ? Colors.grey[100] : null)),
                          ]))),
                  const SizedBox(height: 24),

                  // Seguridad
                  Card(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Seguridad',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            ListTile(
                                leading: const Icon(Icons.lock, color: Colors.teal),
                                title: const Text('Cambiar Contraseña'),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios, size: 16),
                                onTap: _showChangePasswordDialog),
                          ]))),
                ]),
              ),
            )));
  }
}