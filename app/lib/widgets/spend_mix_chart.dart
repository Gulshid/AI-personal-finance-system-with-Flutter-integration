import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Donut chart breaking down a user's spend mix by category, with a
/// scrollable legend. Sorted largest-first so the legend reads like a
/// ranked list, not a random jumble.
class SpendMixChart extends StatefulWidget {
  final Map<String, double> spendMix;
  /// Optional dollar total shown in the donut's center hole.
  final double? centerValue;
  const SpendMixChart({super.key, required this.spendMix, this.centerValue});

  @override
  State<SpendMixChart> createState() => _SpendMixChartState();
}

class _SpendMixChartState extends State<SpendMixChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final entries = widget.spendMix.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No spend-mix data yet.')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 46,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            final index = response?.touchedSection?.touchedSectionIndex;
                            setState(() {
                              _touchedIndex = (index == null || index < 0) ? null : index;
                            });
                          },
                        ),
                        sections: List.generate(entries.length, (i) {
                          final e = entries[i];
                          final style = CategoryStyle.of(e.key);
                          final isTouched = i == _touchedIndex;
                          return PieChartSectionData(
                            value: e.value,
                            color: style.color,
                            radius: isTouched ? 46 : 40,
                            showTitle: false,
                          );
                        }),
                      ),
                    ),
                    if (_touchedIndex == null && widget.centerValue != null)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
                          Text(
                            '\$${widget.centerValue!.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      )
                    else if (_touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < entries.length)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entries[_touchedIndex!].key,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                          ),
                          Text(
                            '${(entries[_touchedIndex!].value * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final style = CategoryStyle.of(e.key);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.key,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(e.value * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}