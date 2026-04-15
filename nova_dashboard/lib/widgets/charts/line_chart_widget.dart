// lib/widgets/charts/line_chart_widget.dart
// ✅ CORREGIDO DEFINITIVAMENTE - getTooltipColor y color nullable

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineChartWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Map<String, dynamic>> data;
  final Color? color;
  final double height;
  final bool fillArea;

  const LineChartWidget({
    Key? key,
    required this.title,
    this.subtitle,
    required this.data,
    this.color,
    this.height = 300,
    this.fillArea = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: data.length > 10 ? 2 : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            data[index]['label']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                    left: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                maxY: _getMaxY(),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getSpots(),
                    isCurved: true,
                    color: color ?? Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: fillArea,
                      // ✅ CORRECCIÓN 1: Usar operador ?? para manejar color nullable
                      color: (color ?? Colors.blue).withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    // ✅ CORRECCIÓN 2: Cambiar getTooltipColor por tooltipBgColor
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index < 0 || index >= data.length) {
                          return null;
                        }
                        return LineTooltipItem(
                          '${data[index]['label']}\n${spot.y.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getSpots() {
    return List.generate(data.length, (index) {
      final value = data[index]['value'];
      final doubleValue = value is int ? value.toDouble() : (value as num).toDouble();
      return FlSpot(index.toDouble(), doubleValue);
    });
  }

  double _getMaxY() {
    if (data.isEmpty) return 10;

    final values = data.map((item) {
      final value = item['value'];
      return value is int ? value.toDouble() : (value as num).toDouble();
    }).toList();

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

  Widget _buildEmptyState() {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}