// lib/widgets/charts/donut_chart_widget.dart
// ============================================================
// FIX: Donut responsivo — resuelve desborde en 3 páginas
// CAMBIOS:
//   1. LayoutBuilder en vez de Container(height: height) fijo
//   2. centerSpaceRadius y radius proporcionales al espacio real
//   3. Título/subtítulo se ocultan si el espacio es < 160px
//   4. Leyenda lateral con scroll si no cabe
// ============================================================
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DonutChartWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final String? subtitle;
  final double? height;
  final bool showLegend;

  const DonutChartWidget({
    Key? key,
    required this.title,
    required this.data,
    this.subtitle,
    this.height = 300,
    this.showLegend = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    // Si height es finito, usar Container con altura fija
    // Si height es infinity, dejar que el padre controle con LayoutBuilder
    final bool useFixedHeight = height != null &&
        height != double.infinity &&
        !height!.isInfinite;

    final Widget content = LayoutBuilder(
      builder: (context, constraints) {
        // Espacio total disponible
        final double availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (useFixedHeight ? height! : 300);
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 400;

        // Decidir si mostrar título (ocultar si muy poco espacio)
        final bool showTitle = availableHeight > 160 &&
            title.isNotEmpty;

        // Espacio que consume el título + padding
        final double headerHeight = showTitle
            ? (subtitle != null && subtitle!.isNotEmpty ? 56 : 40)
            : 8; // padding mínimo arriba

        // Espacio real para el chart
        final double chartHeight = (availableHeight - headerHeight - 16)
            .clamp(60, 600);

        // Calcular radius proporcional al espacio disponible
        // El diámetro del donut = 2*(centerSpace + radius)
        // Debe caber en min(chartHeight, chartWidth_disponible)
        final double chartWidthForDonut = showLegend
            ? availableWidth * 0.55  // 55% para donut, 45% para leyenda
            : availableWidth * 0.85;
        final double fitDimension = [chartHeight, chartWidthForDonut]
            .reduce((a, b) => a < b ? a : b);

        // El donut necesita: 2*(centerSpaceRadius + radius) <= fitDimension
        // Proporción: centerSpace = 55%, radius = 45% del radio total
        final double totalRadius = (fitDimension / 2) * 0.85; // 85% del espacio, dejar margen
        final double centerSpaceRadius = (totalRadius * 0.55).clamp(15, 80);
        final double sectionRadius = (totalRadius * 0.45).clamp(12, 60);

        // Tamaño de fuente del porcentaje dentro del donut
        final double titleFontSize = sectionRadius > 30 ? 14 : (sectionRadius > 20 ? 11 : 9);

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Título (condicional) ──────────────────
              if (showTitle) ...[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
              ],

              // ── Chart + Leyenda ───────────────────────
              Expanded(
                child: Row(
                  children: [
                    // Donut
                    Expanded(
                      flex: showLegend ? 3 : 1,
                      child: PieChart(
                        PieChartData(
                          sections: _buildSections(
                            sectionRadius: sectionRadius,
                            titleFontSize: titleFontSize,
                          ),
                          centerSpaceRadius: centerSpaceRadius,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event,
                                pieTouchResponse) {},
                          ),
                        ),
                      ),
                    ),

                    // Leyenda lateral
                    if (showLegend) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildLegend(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    // Envolver en Container con decoración
    if (useFixedHeight) {
      return Container(
        height: height,
        decoration: _boxDecoration(),
        child: content,
      );
    }

    // Cuando height es infinity, NO poner height en el Container
    // El padre (Expanded, SizedBox, etc.) controla el tamaño
    return Container(
      decoration: _boxDecoration(),
      child: content,
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections({
    required double sectionRadius,
    required double titleFontSize,
  }) {
    final total = _getTotal();

    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item['value'] ?? 0).toDouble();
      final percentage = total > 0 ? (value / total * 100) : 0;
      final color = item['color'] ?? _getColor(index);

      return PieChartSectionData(
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        color: color,
        radius: sectionRadius,
        titleStyle: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final label = item['label']?.toString() ?? '';
          final value = item['value'] ?? 0;
          final color = item['color'] ?? _getColor(index);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  double _getTotal() {
    double total = 0;
    for (var item in data) {
      total += (item['value'] ?? 0).toDouble();
    }
    return total;
  }

  Color _getColor(int index) {
    final colors = [
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyState() {
    final bool useFixedHeight = height != null &&
        height != double.infinity &&
        !height!.isInfinite;

    return Container(
      height: useFixedHeight ? height : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}