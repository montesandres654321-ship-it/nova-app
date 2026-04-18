// lib/pages/profile/profile_page.dart
// FIX: Responsive — colapsa a 1 columna si < 700px + color 0xFF06B6A4
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
  static const _teal = Color(0xFF06B6A4);
  String _userName = '', _userEmail = '', _userRole = ''; int? _userId;
  late TextEditingController _firstNameController, _lastNameController, _phoneController;
  bool _loading = true, _editing = false;

  @override
  void initState() { super.initState();
  _firstNameController = TextEditingController(); _lastNameController = TextEditingController();
  _phoneController = TextEditingController(); _loadUserData(); }

  @override
  void dispose() { _firstNameController.dispose(); _lastNameController.dispose(); _phoneController.dispose(); super.dispose(); }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString(AppConstants.keyUserName) ?? '';
        _userEmail = prefs.getString(AppConstants.keyUserEmail) ?? '';
        _userRole = prefs.getString(AppConstants.keyUserRole) ?? '';
        _userId = prefs.getInt(AppConstants.keyUserId);
        final parts = _userName.split(' ');
        if (parts.length >= 2) { _firstNameController.text = parts.first; _lastNameController.text = parts.sublist(1).join(' '); }
        else { _firstNameController.text = _userName; }
        _loading = false;
      });
    } catch (e) { setState(() => _loading = false); }
  }

  Future<void> _saveChanges() async {
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      final result = await AdminService.updateMyProfile(firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim());
      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final fullName = '${_firstNameController.text} ${_lastNameController.text}'.trim();
        await prefs.setString(AppConstants.keyUserName, fullName);
        setState(() { _userName = fullName; _editing = false; _loading = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Perfil actualizado'), backgroundColor: Colors.green));
      } else { setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Error'), backgroundColor: Colors.red)); }
    } catch (e) { setState(() => _loading = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); }
  }

  void _showChangePasswordDialog() {
    if (_userId == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo obtener el ID'), backgroundColor: Colors.red)); return; }
    showDialog(context: context, builder: (_) => ChangePasswordDialog(userId: _userId!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Mi Perfil'), backgroundColor: _teal, foregroundColor: Colors.white,
            actions: [
              if (!_editing) IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _editing = true))
              else ...[IconButton(icon: const Icon(Icons.close), onPressed: () { setState(() => _editing = false); _loadUserData(); }),
                IconButton(icon: const Icon(Icons.check), onPressed: _saveChanges)],
            ]),
        body: _loading ? const Center(child: CircularProgressIndicator(color: _teal))
            : LayoutBuilder(builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 700;
          return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Center(
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 860),
                child: isWide
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_headerCard(), const SizedBox(height: 16), _formCard()])),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _securityCard()),
                ])
                    : Column(children: [_headerCard(), const SizedBox(height: 12), _formCard(), const SizedBox(height: 12), _securityCard()]),
              )));
        }));
  }

  Widget _headerCard() => Container(padding: const EdgeInsets.all(20), decoration: _cardDec(),
      child: Row(children: [
        CircleAvatar(radius: 36, backgroundColor: _teal,
            child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(_userEmail, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
              child: Text('${AppConstants.getRoleEmoji(_userRole)} ${AppConstants.getRoleLabel(_userRole)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _teal))),
        ]))]));

  Widget _formCard() => Container(padding: const EdgeInsets.all(20), decoration: _cardDec(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Información Personal'),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _field('Nombre(s)', _firstNameController, Icons.person_rounded)),
          const SizedBox(width: 12), Expanded(child: _field('Apellido(s)', _lastNameController, Icons.person_outline_rounded))]),
        const SizedBox(height: 12),
        TextField(controller: TextEditingController(text: _userEmail), enabled: false,
            style: const TextStyle(fontSize: 13), decoration: _dec('Email', Icons.email_rounded)),
        const SizedBox(height: 12),
        _field('Teléfono (opcional)', _phoneController, Icons.phone_rounded),
      ]));

  Widget _securityCard() => Container(padding: const EdgeInsets.all(20), decoration: _cardDec(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Seguridad'), const SizedBox(height: 20),
        InkWell(onTap: _showChangePasswordDialog, borderRadius: BorderRadius.circular(12),
            child: Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _teal.withOpacity(0.04), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _teal.withOpacity(0.15))),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.lock_rounded, color: _teal, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Cambiar Contraseña', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2), Text('Actualiza tu contraseña de acceso', style: TextStyle(fontSize: 11, color: Colors.grey[600]))])),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
                ]))),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sesión activa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 6),
              Row(children: [Icon(Icons.check_circle_rounded, size: 14, color: Colors.green[600]), const SizedBox(width: 6),
                Text('Conectado como ${AppConstants.getRoleLabel(_userRole)}', style: TextStyle(fontSize: 11, color: Colors.grey[600]))])])),
      ]));

  Widget _sectionHeader(String t) => Row(children: [
    Container(width: 4, height: 16, decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8), Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]);

  Widget _field(String label, TextEditingController ctrl, IconData icon) => TextField(
      controller: ctrl, enabled: _editing, style: const TextStyle(fontSize: 13), decoration: _dec(label, icon));

  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18),
      isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _teal, width: 1.5)),
      filled: !_editing, fillColor: !_editing ? Colors.grey[100] : null);

  BoxDecoration _cardDec() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)]);
}