import 'package:flutter/material.dart';
import '../core/design/app_back_button.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────

  Future<void> _sendRecoveryEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      // TODO: reemplazar con ApiService.requestPasswordReset(_emailCtrl.text.trim())
      // cuando el endpoint esté disponible en el backend.
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error inesperado: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _goBack() {
    if (!_isLoading) Navigator.pop(context);
  }

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

  // Sección superior con gradiente: botón de regreso + título
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
          AppBackButton(
            variant: AppBackButtonVariant.onPrimary,
            onTap: _goBack,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Recuperar acceso',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Te enviaremos instrucciones a tu correo',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // Panel blanco inferior — muestra formulario o estado de éxito
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
        child: _emailSent ? _buildSuccessContent() : _buildFormContent(),
      ),
    );
  }

  // Estado inicial: formulario de correo
  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono ilustrativo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.lgAll,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          const Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Ingresa tu dirección de correo electrónico y te enviaremos instrucciones para recuperar tu acceso.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Campo de email
          _buildEmailInput(),
          const SizedBox(height: AppSpacing.lg),

          // Botón principal
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendRecoveryEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.55),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdAll),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Text(
                      'Enviar instrucciones',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Link de regreso
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _goBack,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Volver al inicio de sesión',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Estado de confirmación: mensaje honesto post-envío
  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icono de confirmación
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: AppRadius.lgAll,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.success,
            size: 30,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        const Text(
          'Solicitud enviada',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Mensaje honesto — no afirma que el correo existe
        const Text(
          'Si este correo está registrado en Nova, recibirás instrucciones para recuperar tu acceso en los próximos minutos.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Correo ingresado — referencia para el usuario
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppRadius.mdAll,
          ),
          child: Row(
            children: [
              const Icon(Icons.email_outlined,
                  color: AppColors.textHint, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _emailCtrl.text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Tip sobre spam
        const Text(
          'Revisa también tu carpeta de spam si no encuentras el correo.',
          style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
              height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Botón de regreso
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _goBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll),
            ),
            child: const Text(
              'Volver al inicio de sesión',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ── Widgets privados ───────────────────────────────────────

  Widget _buildEmailInput() {
    return TextFormField(
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
      enabled: !_isLoading,
      style:
          const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Correo electrónico',
        labelStyle:
            const TextStyle(fontSize: 14, color: AppColors.textHint),
        hintText: 'ejemplo@correo.com',
        prefixIcon: const Icon(Icons.email_outlined,
            size: 20, color: AppColors.textHint),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
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
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa tu correo';
        }
        if (!value.contains('@') || !value.contains('.')) {
          return 'Ingresa un correo válido';
        }
        return null;
      },
    );
  }
}
