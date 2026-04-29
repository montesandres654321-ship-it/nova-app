import 'package:flutter/material.dart';
import '../core/design/app_back_button.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';
import '../core/design/app_text_styles.dart';
import '../services/google_auth_service.dart';
import 'profile_page.dart';
import 'change_password_page.dart';
import 'about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: AppColors.surface,
        automaticallyImplyLeading: false,
        leadingWidth: 52,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm),
          child: Center(child: AppBackButton()),
        ),
        titleTextStyle: AppTextStyles.title,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildGroup(context, [
            _SettingsTile(
              icon: Icons.person_rounded,
              label: 'Perfil',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfilePage())),
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          FutureBuilder<bool>(
            future: GoogleAuthService.isGoogleUser(),
            builder: (context, snapshot) {
              if (snapshot.data == true) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildGroup(context, [
                  _SettingsTile(
                    icon: Icons.lock_rounded,
                    label: 'Cambiar contraseña',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage())),
                  ),
                ]),
              );
            },
          ),
          _buildGroup(context, [
            _SettingsTile(
              icon: Icons.info_rounded,
              label: 'Acerca de',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AboutPage())),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildGroup(BuildContext context, List<_SettingsTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: List.generate(tiles.length, (i) {
          return Column(
            children: [
              InkWell(
                onTap: tiles[i].onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs + 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.smAll,
                        ),
                        child: Icon(tiles[i].icon,
                            size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child:
                            Text(tiles[i].label, style: AppTextStyles.bodyLg),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
              if (i < tiles.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                  indent: AppSpacing.md,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsTile {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
