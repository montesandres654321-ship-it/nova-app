import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/design/app_back_button.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';
import '../core/design/app_text_styles.dart';

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

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

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
        _showSnack(data['message'] ?? 'Contraseña actualizada', AppColors.success);
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmCtrl.clear();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        _showSnack(data['error'] ?? 'Error al actualizar', AppColors.error);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
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

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBackButton(
            variant: AppBackButtonVariant.onPrimary,
            onTap: _loading ? null : () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Cambiar contraseña',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Elige una contraseña segura',
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

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
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.lgAll,
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: AppColors.primary, size: 26),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Nueva contraseña', style: AppTextStyles.headline),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Ingresa tu contraseña actual y luego la nueva.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildPasswordField(
                controller: _oldPassCtrl,
                label: 'Contraseña actual',
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildPasswordField(
                controller: _newPassCtrl,
                label: 'Nueva contraseña',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildPasswordField(
                controller: _confirmCtrl,
                label: 'Confirmar contraseña',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                isConfirm: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mdAll),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.onPrimary),
                        )
                      : const Text('Actualizar contraseña',
                          style: AppTextStyles.labelLg),
                ),
              ),
            ],
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
      controller: controller,
      obscureText: obscure,
      enabled: !_loading,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            size: 20, color: AppColors.textHint),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textHint,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdAll, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdAll,
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        disabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdAll, borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdAll,
            borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.mdAll,
            borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa la contraseña';
        if (!isConfirm && v.length < 6) return 'Mínimo 6 caracteres';
        if (isConfirm && v != _newPassCtrl.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }
}
