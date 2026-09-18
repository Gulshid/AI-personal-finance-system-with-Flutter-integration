import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Bar chart showing next month's forecasted spend per category, sorted
/// highest first. Bars are colored per-category to match the rest of the
/// app's visual language.
class ForecastBarChart extends StatelessWidget {
  final Map<String, double> forecast;
  const ForecastBarChart({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final entries = forecast.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No forecast data yet.')),
      );
    }

    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.25;

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppTheme.textSecondary.withValues(alpha: 0.1), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                  final label = entries[i].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        label.length > 8 ? '${label.substring(0, 7)}…' : label,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(entries.length, (i) {
            final e = entries[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: e.value,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: CategoryStyle.of(e.key).color,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
