// lib/widgets/charts/bar_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Widget de gráfica de barras reutilizable
///
/// Ejemplo de uso:
/// ```dart
/// BarChartWidget(
///   title: 'Recompensas por día',
///   data: [
///     {'label': '1 Mar', 'value': 12},
///     {'label': '2 Mar', 'value': 8},
///   ],
///   color: Colors.teal,
/// )
/// ```
class BarChartWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final Color color;
  final String? subtitle;
  final double? height;
  final bool showValues;

  const BarChartWidget({
    Key? key,
    required this.title,
    required this.data,
    this.color = Colors.teal,
    this.subtitle,
    this.height = 300,
    this.showValues = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue() * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.grey[800],
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final value = rod.toY.toInt();
                        final label = data[groupIndex]['label']?.toString() ?? '';
                        return BarTooltipItem(
                          '$label\n$value',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < data.length) {
                            final label = data[value.toInt()]['label']?.toString() ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                      left: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  barGroups: _buildBarGroups(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final value = (item['value'] ?? 0).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxValue() {
    if (data.isEmpty) return 10;
    double max = 0;
    for (var item in data) {
      final value = (item['value'] ?? 0).toDouble();
      if (value > max) max = value;
    }
    return max > 0 ? max : 10;
  }

  Widget _buildEmptyState() {
    return Container(
      height: height,
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