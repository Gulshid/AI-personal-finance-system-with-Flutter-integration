import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../services/api_exception.dart';
import '../services/finance_ai_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/forecast_chart.dart';

class ForecastScreen extends StatefulWidget {
  final int userId;
  final FinanceAiService api;
  const ForecastScreen({super.key, required this.userId, required this.api});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  late Future<ForecastResult> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getUserForecast(widget.userId);
  }

  void _retry() => setState(() => _future = widget.api.getUserForecast(widget.userId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ForecastResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Forecasting next month...');
        }
        if (snapshot.hasError) {
          final message =
              snapshot.error is ApiException ? snapshot.error.toString() : 'Unexpected error occurred.';
          return ErrorView(message: message, onRetry: _retry);
        }

        final forecast = snapshot.data!;
        if (forecast.forecastNextMonth.isEmpty) {
          return const EmptyStateView(
            icon: Icons.query_stats_rounded,
            message: 'Not enough transaction history yet to forecast next month.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const SectionHeader(title: 'Next month forecast'),
            const SizedBox(height: 4),
            const Text(
              'Predicted spend per category, based on recent trend',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ForecastBarChart(forecast: forecast.forecastNextMonth),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total forecasted spend',
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
                        Text(
                          '\$${forecast.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
