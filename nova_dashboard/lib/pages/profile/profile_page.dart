// lib/pages/profile/profile_page.dart
// ============================================================
// REDESIGN: SaaS profile panel · avatar · sections · logout
// Lógica sin cambios
// ============================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';
import '../../services/admin_service.dart';
import 'change_password_dialog.dart';

// ── Design tokens ─────────────────────────────────────────────
const _kPrimary   = Color(0xFF06B6A4);
const _kBgPage    = Color(0xFFF1F5F9);
const _kTextHead  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kTextSub   = Color(0xFF94A3B8);
const _kBorder    = Color(0xFFE2E8F0);
const _kGreen     = Color(0xFF10B981);
const _kRed       = Color(0xFFEF4444);

// ─────────────────────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  // ── State — SIN CAMBIOS ───────────────────────────────
  String _userName = '', _userEmail = '', _userRole = '';
  int?   _userId;
  late TextEditingController _firstNameController,
      _lastNameController, _phoneController;
  bool _loading = true, _editing = false;

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

  // ── LÓGICA — SIN CAMBIOS ─────────────────────────────
  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName  = prefs.getString(AppConstants.keyUserName)  ?? '';
        _userEmail = prefs.getString(AppConstants.keyUserEmail) ?? '';
        _userRole  = prefs.getString(AppConstants.keyUserRole)  ?? '';
        _userId    = prefs.getInt(AppConstants.keyUserId);
        final parts = _userName.split(' ');
        if (parts.length >= 2) {
          _firstNameController.text = parts.first;
          _lastNameController.text  = parts.sublist(1).join(' ');
        } else {
          _firstNameController.text = _userName;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (_userId == null) return;
    setState(() => _loading = true);
    try {
      final result = await AdminService.updateMyProfile(
        firstName: _firstNameController.text.trim(),
        lastName:  _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
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
              content: Text(result['error'] ?? 'Error'),
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
          content: Text('No se pudo obtener el ID'),
          backgroundColor: Colors.red));
      return;
    }
    showDialog(context: context,
        builder: (_) => ChangePasswordDialog(userId: _userId!));
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => _LogoutDialog(
        onConfirm: () async {
          await AdminService.logout();
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (_) => false);
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBgPage,
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: _kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kTextHead,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Mi Perfil',
            style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w600, color: _kTextHead)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _kBorder),
        ),
      ),
      body: LayoutBuilder(builder: (_, constraints) {
        final isWide = constraints.maxWidth > 700;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28.0 : 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildSecurityCard(),
                  const SizedBox(height: 16),
                  _buildDangerCard(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────────────
  // PROFILE HEADER
  // ─────────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    final words    = _userName.trim().split(' ');
    final initials = words.length >= 2
        ? '${words.first[0]}${words.last[0]}'.toUpperCase()
        : _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: _cardDec(),
      child: Column(children: [

        // Avatar con gradiente
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF06B6A4), Color(0xFF0891B2)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: _kPrimary.withOpacity(0.30),
              blurRadius: 16, offset: const Offset(0, 5),
            )],
          ),
          child: Center(
            child: Text(initials,
                style: const TextStyle(fontSize: 26,
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 14),

        // Nombre
        Text(
          _userName.isNotEmpty ? _userName : 'Usuario',
          style: const TextStyle(fontSize: 20,
              fontWeight: FontWeight.w800, color: _kTextHead),
          textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Email
        Text(
          _userEmail,
          style: const TextStyle(fontSize: 13, color: _kTextMuted),
          textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),

        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kPrimary.withOpacity(0.2)),
          ),
          child: Text(
            '${AppConstants.getRoleEmoji(_userRole)} '
            '${AppConstants.getRoleLabel(_userRole)}',
            style: const TextStyle(fontSize: 12,
                color: _kPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────
  // INFO CARD
  // ─────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return _SectionCard(
      title: 'Información personal',
      child: _editing ? _editForm() : _displayInfo(),
    );
  }

  Widget _displayInfo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _infoRow(Icons.person_rounded, 'Nombre completo', _userName),
      _rowDivider(),
      _infoRow(Icons.email_outlined, 'Correo electrónico', _userEmail),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () => setState(() => _editing = true),
        icon: const Icon(Icons.edit_outlined, size: 15),
        label: const Text('Editar información',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimary,
          side: const BorderSide(color: _kBorder),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    ],
  );

  Widget _editForm() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(child: _field('Nombre(s)', _firstNameController,
            Icons.person_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _field('Apellido(s)', _lastNameController,
            Icons.person_outline_rounded)),
      ]),
      const SizedBox(height: 12),
      TextField(
        controller: TextEditingController(text: _userEmail),
        enabled: false,
        style: const TextStyle(fontSize: 13),
        decoration: _dec('Correo electrónico', Icons.email_rounded),
      ),
      const SizedBox(height: 12),
      _field('Teléfono (opcional)', _phoneController, Icons.phone_rounded),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () {
            setState(() => _editing = false);
            _loadUserData();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: _kTextMuted,
            side: const BorderSide(color: _kBorder),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Cancelar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Guardar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        )),
      ]),
    ],
  );

  // ─────────────────────────────────────────────────────
  // SECURITY CARD
  // ─────────────────────────────────────────────────────
  Widget _buildSecurityCard() {
    return _SectionCard(
      title: 'Seguridad',
      child: Column(children: [
        _actionRow(
          icon: Icons.lock_outlined,
          iconColor: _kPrimary,
          title: 'Cambiar contraseña',
          subtitle: 'Actualiza tu contraseña de acceso',
          onTap: _showChangePasswordDialog,
        ),
        _rowDivider(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kGreen.withOpacity(0.18)),
          ),
          child: Row(children: [
            Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(
                  color: _kGreen, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Conectado como ${AppConstants.getRoleLabel(_userRole)}',
                style: const TextStyle(fontSize: 12,
                    color: _kGreen, fontWeight: FontWeight.w500),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────
  // DANGER CARD
  // ─────────────────────────────────────────────────────
  Widget _buildDangerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Row(children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: _kRed, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Text('Zona de peligro',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w700, color: _kRed)),
          ]),
        ),
        const Divider(height: 20, thickness: 0.5,
            color: Color(0xFFFEE2E2)),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: _actionRow(
            icon: Icons.logout_rounded,
            iconColor: _kRed,
            title: 'Cerrar sesión',
            subtitle: 'Salir de tu cuenta actual',
            onTap: _confirmLogout,
            isDestructive: true,
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────
  // SHARED WIDGETS
  // ─────────────────────────────────────────────────────
  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: _kTextSub),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: _kTextSub)),
          const SizedBox(height: 2),
          Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontSize: 14,
                color: _kTextHead, fontWeight: FontWeight.w500),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ],
      )),
    ]),
  );

  Widget _actionRow({
    required IconData     icon,
    required Color        iconColor,
    required String       title,
    required String       subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isDestructive ? _kRed : _kTextHead)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: _kTextSub)),
            ],
          )),
          Icon(Icons.arrow_forward_ios_rounded, size: 13,
              color: isDestructive
                  ? _kRed.withOpacity(0.4) : _kBorder),
        ]),
      ),
    );

  Widget _rowDivider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 2),
    child: Divider(height: 1, thickness: 0.5, color: _kBorder),
  );

  Widget _field(String label, TextEditingController ctrl, IconData icon) =>
    TextField(
      controller: ctrl,
      enabled: true,
      style: const TextStyle(fontSize: 13),
      decoration: _dec(label, icon),
    );

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 13, color: _kTextSub),
    prefixIcon: Icon(icon, size: 17, color: _kTextSub),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 12, vertical: 13),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder)),
    disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBorder)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
  );

  BoxDecoration _cardDec() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: _kBorder),
    boxShadow: [BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8, offset: const Offset(0, 2),
    )],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kBorder),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8, offset: const Offset(0, 2),
      )],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Text(title,
            style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: _kTextHead)),
      ),
      const Divider(height: 20, thickness: 0.5, color: _kBorder),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: child,
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGOUT DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _LogoutDialog extends StatelessWidget {
  final Future<void> Function() onConfirm;
  const _LogoutDialog({required this.onConfirm});

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Icono
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.logout_rounded,
              color: _kRed, size: 30),
        ),
        const SizedBox(height: 18),

        const Text('¿Cerrar sesión?',
            style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800, color: _kTextHead)),
        const SizedBox(height: 8),
        const Text(
          'Se cerrará tu sesión actual y\ndeberás volver a iniciar sesión.',
          style: TextStyle(fontSize: 13,
              color: _kTextMuted, height: 1.55),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 26),

        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTextMuted,
              side: const BorderSide(color: _kBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: const Text('Cancelar',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w500)),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: const Text('Salir',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600)),
          )),
        ]),
      ]),
    ),
  );
}
