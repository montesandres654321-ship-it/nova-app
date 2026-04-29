import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/design/app_back_button.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';
import '../core/design/app_text_styles.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(context),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppBackButton(variant: AppBackButtonVariant.onPrimary),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Acerca de',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.lgAll,
              ),
              child: const Icon(Icons.travel_explore_rounded,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Nova App', style: AppTextStyles.headline),
            const SizedBox(height: AppSpacing.xs),
            const Text('Versión 1.0', style: AppTextStyles.bodySm),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Prototipo de app para gestión de lugares con códigos QR. Desarrollada en Flutter.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _openLink('https://flutter.dev'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll),
                ),
                child: const Text('Visitar Flutter.dev',
                    style: AppTextStyles.labelLg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
