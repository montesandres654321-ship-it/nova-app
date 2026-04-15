// lib/widgets/stat_card.dart - CARD DE ESTADÍSTICA PROFESIONAL

import 'package:flutter/material.dart';
import 'package:nova_dashboard/utils/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool? isPositive;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppTheme.primary,
    this.trend,
    this.isPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceLG),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            boxShadow: AppTheme.shadowSM,
            border: Border.all(
              color: color.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icono y Trend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icono
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceSM),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),

                  // Trend badge (si existe)
                  if (trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceSM,
                        vertical: AppTheme.spaceXXS,
                      ),
                      decoration: BoxDecoration(
                        color: _getTrendColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTrendIcon(),
                            size: 14,
                            color: _getTrendColor(),
                          ),
                          const SizedBox(width: AppTheme.spaceXXS),
                          Text(
                            trend!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getTrendColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppTheme.spaceMD),

              // Valor principal
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.gray900,
                  height: 1,
                ),
              ),

              const SizedBox(height: AppTheme.spaceXS),

              // Título
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTrendColor() {
    if (isPositive == null) return AppTheme.gray500;
    return isPositive! ? AppTheme.success : AppTheme.error;
  }

  IconData _getTrendIcon() {
    if (isPositive == null) return Icons.remove;
    return isPositive! ? Icons.arrow_upward : Icons.arrow_downward;
  }
}