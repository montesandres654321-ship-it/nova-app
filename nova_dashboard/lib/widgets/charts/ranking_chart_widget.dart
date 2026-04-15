// lib/widgets/charts/ranking_chart_widget.dart
import 'package:flutter/material.dart';

/// Widget de ranking horizontal (Top N)
class RankingChartWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> data;
  final Color color;
  final String? subtitle;
  final double? height;
  final int? maxItems;

  const RankingChartWidget({
    Key? key,
    required this.title,
    required this.data,
    this.color = Colors.teal,
    this.subtitle,
    this.height = 400,
    this.maxItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    final displayData = maxItems != null && data.length > maxItems!
        ? data.sublist(0, maxItems!)
        : data;

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
              child: ListView.builder(
                itemCount: displayData.length,
                itemBuilder: (context, index) {
                  return _buildRankingItem(index, displayData[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(int index, Map<String, dynamic> item) {
    final label = item['label']?.toString() ?? item['name']?.toString() ?? 'N/A';
    final value = item['value'] ?? item['count'] ?? 0;
    final emoji = item['emoji']?.toString() ?? '';
    final maxValue = _getMaxValue();
    final percentage = maxValue > 0 ? (value / maxValue) : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con ranking y label
          Row(
            children: [
              // Número de ranking
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _getRankColor(index),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Emoji (si existe)
              if (emoji.isNotEmpty) ...[
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
              ],

              // Label
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Valor
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                color.withOpacity(0.7 + (0.3 * (1 - index / 10))),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber; // Oro
    if (index == 1) return Colors.grey;  // Plata
    if (index == 2) return Colors.brown; // Bronce
    return color;
  }

  double _getMaxValue() {
    if (data.isEmpty) return 0;
    double max = 0;
    for (var item in data) {
      final value = (item['value'] ?? item['count'] ?? 0).toDouble();
      if (value > max) max = value;
    }
    return max;
  }

  Widget _buildEmptyState() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              'No hay datos disponibles',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}