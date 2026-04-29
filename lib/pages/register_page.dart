import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/design/app_back_button.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';

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

  // ── Lifecycle ──────────────────────────────────────────────

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

  // ── Actions ────────────────────────────────────────────────

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
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
            ),
          ),
          child: child!,
        ),
      );
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          _dobCtrl.text =
              '${picked.year.toString().padLeft(4, '0')}-'
              '${picked.month.toString().padLeft(2, '0')}-'
              '${picked.day.toString().padLeft(2, '0')}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: AppColors.error,
        ),
      );
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
          const SnackBar(
            content: Text('Cuenta creada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Error al registrar'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  String? Function(String?) _reqValidator(String field) =>
      (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu $field' : null;

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(),
              Expanded(child: _buildFormPanel()),
            ],
          ),
        ),
      ),
    );
  }

  // Sección superior: flecha de regreso + título
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBackButton(variant: AppBackButtonVariant.onPrimary),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Crear cuenta',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Únete a Nova y empieza tu aventura',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // Panel blanco inferior con secciones del formulario
  Widget _buildFormPanel() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Datos personales ──────────────────────────────
              _buildSectionLabel('Datos personales'),
              _buildInput(
                controller: _firstCtrl,
                label: 'Nombre',
                icon: Icons.person_outline_rounded,
                validator: _reqValidator('nombre'),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInput(
                controller: _lastCtrl,
                label: 'Apellido',
                icon: Icons.person_outline_rounded,
                validator: _reqValidator('apellido'),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInput(
                controller: _dobCtrl,
                label: 'Fecha de nacimiento',
                icon: Icons.cake_outlined,
                readOnly: true,
                onTap: _pickDate,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined,
                      color: AppColors.textHint, size: 18),
                  onPressed: _pickDate,
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Selecciona tu fecha'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  label: 'Género',
                  icon: Icons.wc_outlined,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Femenino', child: Text('Femenino')),
                  DropdownMenuItem(
                      value: 'Masculino', child: Text('Masculino')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (v) =>
                    setState(() => _gender = v ?? _gender),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Tu cuenta ─────────────────────────────────────
              _buildSectionLabel('Tu cuenta'),
              TextFormField(
                controller: _usernameCtrl,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textPrimary),
                onChanged: (v) {
                  if (v.contains(' ')) {
                    _usernameCtrl.text = v.replaceAll(' ', '_');
                    _usernameCtrl.selection = TextSelection.fromPosition(
                        TextPosition(
                            offset: _usernameCtrl.text.length));
                  }
                },
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Elige un nombre de usuario';
                  }
                  if (v.contains(' ')) return 'Sin espacios (usa _ o .)';
                  if (v.length < 3) return 'Mínimo 3 caracteres';
                  if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) {
                    return 'Solo letras, números, _ y .';
                  }
                  return null;
                },
                decoration: _inputDecoration(
                  label: 'Nombre de usuario',
                  icon: Icons.account_box_outlined,
                ).copyWith(
                  hintText: 'ej: viajero_nova',
                  helperText: 'Sin espacios · Solo letras, números, _ y .',
                  helperStyle: const TextStyle(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInput(
                controller: _emailCtrl,
                label: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(v)) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Seguridad ──────────────────────────────────────
              _buildSectionLabel('Seguridad'),
              _buildInput(
                controller: _passCtrl,
                label: 'Contraseña',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscure = !_obscure),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _buildInput(
                controller: _confirmCtrl,
                label: 'Confirmar contraseña',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                validator: (v) {
                  if (v != _passCtrl.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Contacto ──────────────────────────────────────
              _buildSectionLabel('Contacto'),
              _buildPhoneRow(),
              const SizedBox(height: AppSpacing.xl),

              // ── Términos ──────────────────────────────────────
              _buildTermsRow(),
              const SizedBox(height: AppSpacing.lg),

              // ── Botón principal ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isRegistering ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdAll),
                  ),
                  child: _isRegistering
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary),
                        )
                      : const Text(
                          'Crear cuenta',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Link de vuelta al login
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets privados ───────────────────────────────────────

  // Cabecera de sección: texto en mayúsculas con letra tracking
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Fila de teléfono: selector de código + campo de número
  Widget _buildPhoneRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown del código de país — ancho fijo, mismo estilo que inputs
        SizedBox(
          width: 88,
          child: DropdownButtonFormField<String>(
            initialValue: _countryCode,
            isExpanded: true,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.mdAll,
                borderSide:
                    const BorderSide(color: AppColors.error),
              ),
            ),
            items: _countryCodes
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c,
                        style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (v) =>
                setState(() => _countryCode = v ?? _countryCode),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildInput(
            controller: _phoneCtrl,
            label: 'Teléfono móvil',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requerido';
              if (v.trim().length < 7) return 'Número muy corto';
              return null;
            },
          ),
        ),
      ],
    );
  }

  // Fila de aceptación de términos
  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: _acceptTos,
            onChanged: (v) =>
                setState(() => _acceptTos = v ?? false),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const Expanded(
          child: Text(
            'Acepto los términos y condiciones',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  // InputDecoration base — única fuente de verdad para todos los campos
  InputDecoration _inputDecoration({
    required String label,
    required IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(fontSize: 14, color: AppColors.textHint),
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: AppColors.textHint)
          : null,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide:
            const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  // TextFormField estilizado con tokens del design system
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style:
          const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: _inputDecoration(label: label, icon: icon)
          .copyWith(suffixIcon: suffixIcon),
      validator: validator,
    );
  }
}
