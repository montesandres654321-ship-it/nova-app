import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../utils/constants.dart';
import '../core/design/app_back_button.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';

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

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadUser();
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

  // ── Data ───────────────────────────────────────────────────

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(AppConstants.keyUser);
      final isGoogle = await GoogleAuthService.isGoogleUser();
      if (!mounted) return;
      setState(() => _isGoogleUser = isGoogle);

      if (userStr != null) {
        final user = jsonDecode(userStr);
        if (!mounted) return;
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

  // ── Mensajes ───────────────────────────────────────────────

  void _showSuccess(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      );

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      );

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: AppColors.surface,
        automaticallyImplyLeading: false,
        leadingWidth: 52,
        leading: Navigator.canPop(context)
            ? const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Center(child: AppBackButton()),
              )
            : null,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        actions: [
          if (!_loading)
            IconButton(
              icon: Icon(
                _editing ? Icons.close_rounded : Icons.edit_rounded,
                size: 20,
              ),
              onPressed: () => setState(() => _editing = !_editing),
              color: _editing ? AppColors.error : AppColors.textSecondary,
              tooltip: _editing ? 'Cancelar edición' : 'Editar perfil',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAvatarSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildFormCard(),
              if (_editing) ...[
                const SizedBox(height: AppSpacing.md),
                _buildActionButtons(),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────────

  Widget _buildAvatarSection() {
    final initial = _firstNameCtrl.text.isNotEmpty
        ? _firstNameCtrl.text[0].toUpperCase()
        : '?';
    final fullName =
        '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim();

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (fullName.isNotEmpty)
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: AppSpacing.xs),
        if (_emailCtrl.text.isNotEmpty)
          Text(
            _emailCtrl.text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  // ── Formulario ─────────────────────────────────────────────

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildField('Nombre', Icons.person_rounded, _firstNameCtrl),
          _divider(),
          _buildField('Apellido', Icons.person_rounded, _lastNameCtrl),
          _divider(),
          _buildField(
              'Usuario', Icons.account_circle_rounded, _usernameCtrl),
          _divider(),
          _buildField(
            'Correo',
            Icons.email_rounded,
            _emailCtrl,
            email: true,
          ),
          if (!_isGoogleUser) ...[
            _divider(),
            _buildField(
                'Teléfono', Icons.phone_rounded, _phoneCtrl),
          ],
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: AppColors.border);

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController ctrl, {
    bool email = false,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: _editing && !_loading,
      keyboardType:
          email ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: _editing ? AppColors.primary : AppColors.textHint,
        ),
        filled: true,
        fillColor: _editing ? AppColors.surface : AppColors.surfaceVariant,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      validator: (v) {
        if (!_editing) return null;
        if (v == null || v.isEmpty) return 'Campo obligatorio';
        if (email && !v.contains('@')) return 'Correo inválido';
        return null;
      },
    );
  }

  // ── Acciones ───────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed:
                _loading ? null : () => setState(() => _editing = false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Guardar'),
          ),
        ),
      ],
    );
  }
}
