// lib/widgets/charts/bar_chart_widget.dart
// FIX: Labels responsive — trunca si hay muchos datos, barras proporcionales
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
    this.color = const Color(0xFF06B6A4),
    this.subtitle,
    this.height = 300,
    this.showValues = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return _buildEmptyState();
    final bool useFixed = height != null && height != double.infinity && !height!.isInfinite;
    final Widget content = LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 600.0;
      final n = data.length;
      final barW = ((w - 80) / (n * 2)).clamp(8.0, 24.0);
      final maxChars = n > 6 ? 8 : (n > 4 ? 12 : 20);
      final interval = n <= 8 ? 1.0 : (n / 6).ceilToDouble();
      return Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title.isNotEmpty) ...[
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (subtitle != null && subtitle!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 4),
                child: Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
          const SizedBox(height: 12),
        ],
        Expanded(child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround, maxY: _maxVal() * 1.2,
          barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.grey[800],
            getTooltipItem: (g, gi, rod, ri) {
              if (gi >= data.length) return null;
              return BarTooltipItem('${data[gi]['label']}\n${rod.toY.toInt()}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
            },
          )),
          titlesData: FlTitlesData(show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: interval,
              reservedSize: 40,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox();
                var l = data[i]['label']?.toString() ?? '';
                if (l.length > maxChars) l = '${l.substring(0, maxChars)}..';
                return Padding(padding: const EdgeInsets.only(top: 6),
                    child: SizedBox(width: barW * 2.5,
                        child: Text(l, style: const TextStyle(fontSize: 9),
                            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)));
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
              getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
            )),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[300], strokeWidth: 0.5)),
          borderData: FlBorderData(show: true, border: Border(
              bottom: BorderSide(color: Colors.grey[300]!), left: BorderSide(color: Colors.grey[300]!))),
          barGroups: data.asMap().entries.map((e) => BarChartGroupData(x: e.key,
              barRods: [BarChartRodData(toY: (e.value['value'] ?? 0).toDouble(), color: color, width: barW,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)))])).toList(),
        ))),
      ],
      ));
    });
    if (useFixed) return Container(height: height, decoration: _dec(), child: content);
    return Container(decoration: _dec(), child: content);
  }

  BoxDecoration _dec() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]);
  double _maxVal() { double m = 0; for (var i in data) { final v = (i['value'] ?? 0).toDouble(); if (v > m) m = v; } return m > 0 ? m : 10; }
  Widget _buildEmptyState() => Container(height: height != double.infinity ? height : null,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text('No hay datos disponibles', style: TextStyle(color: Colors.grey[600]))));
}