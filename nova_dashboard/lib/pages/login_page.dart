// lib/pages/login_page.dart
// CORRECCIÓN CRÍTICA: pushNamedAndRemoveUntil limpia TODO el stack
// Evita que el botón ← lleve a sesiones de otros usuarios
import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading         = false;
  bool _obscurePassword = true;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LÓGICA — SIN CAMBIOS ─────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final result = await AdminService.login(
        email:    _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result['success'] != true) {
        _showError(result['error'] ?? 'Credenciales inválidas');
        return;
      }

      final role      = result['role']      as String?;
      final placeId   = result['place_id']  as int?;
      final userName  = result['userName']  as String? ?? '';
      final userEmail = result['userEmail'] as String? ?? '';

      if (role == 'admin_general' || role == 'user_general') {
        // pushNamedAndRemoveUntil elimina TODAS las rutas anteriores
        // (_) => false = no mantener ninguna ruta en el stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard', (_) => false,
        );

      } else if (role == 'user_place') {
        if (placeId == null) {
          _showError('Tu usuario no tiene un lugar asignado.\nContacta al administrador.');
          await AdminService.logout();
          return;
        }
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/owner-dashboard',
          (_) => false, // limpia todo el stack
          arguments: {
            'placeId':   placeId,
            'userName':  userName,
            'userEmail': userEmail,
          },
        );

      } else {
        // role null = turista móvil, sin acceso al panel
        await AdminService.logout();
        _showError(
          'Este usuario no tiene acceso al panel administrativo.\n'
          'El panel es solo para administradores y propietarios.',
        );
      }
    } catch (e) {
      if (mounted) _showError('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 5),
    ));
  }

  // ── HELPER UI ────────────────────────────────────────────
  InputDecoration _inputDec({
    required String   hint,
    required IconData icon,
    Widget?           suffix,
  }) {
    return InputDecoration(
      hintText:  hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
      suffixIcon: suffix,
      filled:    true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF06B6A4), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // ── 1. FONDO GRADIENTE 3 COLORES ─────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [
                  Color(0xFF0F766E), // teal oscuro
                  Color(0xFF06B6A4), // primary
                  Color(0xFF67E8F9), // light accent
                ],
              ),
            ),
          ),

          // ── 2. CÍRCULOS DECORATIVOS SUTILES ───────────────
          Positioned(
            top: -100, right: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -80, left: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 120, left: 50,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // ── 3. CARD DE LOGIN (centrada, animada) ──────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                            spreadRadius: -8,
                          ),
                          BoxShadow(
                            color: const Color(0xFF0F766E).withOpacity(0.18),
                            blurRadius: 80,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              // ── HEADER / BRANDING ────────
                              Center(
                                child: Column(children: [

                                  // Logo badge con gradiente y sombra teal
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0F766E), Color(0xFF06B6A4)],
                                        begin: Alignment.topLeft,
                                        end:   Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF06B6A4).withOpacity(0.40),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // Título dos tonos: NOVA (negro bold) + Dashboard (slate ligero)
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: const TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'NOVA',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                            letterSpacing: 2.0,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' Dashboard',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w300,
                                            color: Color(0xFF475569),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  const Text(
                                    'Panel de administración',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF94A3B8),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ]),
                              ),

                              const SizedBox(height: 28),
                              const Divider(
                                  color: Color(0xFFF1F5F9), height: 1, thickness: 1),
                              const SizedBox(height: 24),

                              // ── EMAIL ────────────────────
                              const Text(
                                'Correo electrónico',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF0F172A)),
                                decoration: _inputDec(
                                  hint: 'admin@ejemplo.com',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Ingrese su email';
                                  if (!v.contains('@')) return 'Email inválido';
                                  return null;
                                },
                                enabled: !_loading,
                              ),

                              const SizedBox(height: 16),

                              // ── CONTRASEÑA ───────────────
                              const Text(
                                'Contraseña',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                    fontSize: 14, color: Color(0xFF0F172A)),
                                decoration: _inputDec(
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                    splashRadius: 16,
                                  ),
                                ),
                                validator: (v) =>
                                    v?.isEmpty ?? true ? 'Ingrese su contraseña' : null,
                                enabled: !_loading,
                                onFieldSubmitted: (_) => _login(),
                              ),

                              const SizedBox(height: 24),

                              // ── BOTÓN PRINCIPAL ──────────
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF06B6A4),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFF06B6A4).withOpacity(0.55),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 20, height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── FOOTER ───────────────────
                              const Text(
                                'Golfo de Morrosquillo · NOVA',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFCBD5E1),
                                  letterSpacing: 0.4,
                                ),
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
        ],
      ),
    );
  }
}
