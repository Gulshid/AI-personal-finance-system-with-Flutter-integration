import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../services/api_exception.dart';
import '../services/finance_ai_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/persona_card.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/spend_mix_chart.dart';
import '../widgets/stat_chip.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;
  final FinanceAiService api;
  const DashboardScreen({super.key, required this.userId, required this.api});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    // Fetch cluster, recommendations, and forecast together so the stat
    // row (which needs the forecast total) is ready at the same time as
    // everything else — one loading state for the whole screen. Forecast
    // is optional: if it fails (e.g. not enough history) we still show
    // the rest of the dashboard.
    final results = await Future.wait([
      widget.api.getUserCluster(widget.userId),
      widget.api.getUserRecommendations(widget.userId),
      widget.api
          .getUserForecast(widget.userId)
          .catchError((_) => const ForecastResult(userId: 0, forecastNextMonth: {})),
    ]);
    return _DashboardData(
      cluster: results[0] as ClusterProfile,
      recommendations: results[1] as List<RecommendationItem>,
      forecast: results[2] as ForecastResult,
    );
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _retry(),
      child: FutureBuilder<_DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DashboardSkeleton();
          }
          if (snapshot.hasError) {
            final message =
                snapshot.error is ApiException ? snapshot.error.toString() : 'Unexpected error occurred.';
            return ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ErrorView(message: message, onRetry: _retry),
                ),
              ],
            );
          }

          final data = snapshot.data!;
          final alertCount = data.recommendations.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              StaggeredFadeIn(index: 0, child: PersonaCard(profile: data.cluster)),
              const SizedBox(height: 16),
              StaggeredFadeIn(
                index: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: StatChip(
                        icon: Icons.trending_up_rounded,
                        label: 'Next month forecast',
                        value: data.forecast.forecastNextMonth.isEmpty
                            ? '—'
                            : '\$${data.forecast.total.toStringAsFixed(0)}',
                        accentColor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatChip(
                        icon: Icons.notifications_active_rounded,
                        label: 'Active insights',
                        value: '$alertCount',
                        accentColor: alertCount > 0 ? AppTheme.warning : AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              StaggeredFadeIn(index: 2, child: const SectionHeader(title: 'Spend mix')),
              const SizedBox(height: 12),
              StaggeredFadeIn(
                index: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: SpendMixChart(
                    spendMix: data.cluster.spendMix,
                    centerValue: data.cluster.monthlySpend,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              StaggeredFadeIn(index: 4, child: const SectionHeader(title: 'Top insights')),
              const SizedBox(height: 12),
              if (data.recommendations.isEmpty)
                StaggeredFadeIn(
                  index: 5,
                  child: const EmptyStateView(
                    icon: Icons.check_circle_rounded,
                    message: 'No unusual spending patterns detected right now.',
                  ),
                )
              else
                ...data.recommendations.take(3).toList().asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StaggeredFadeIn(
                          index: 5 + entry.key,
                          child: RecommendationCard(item: entry.value),
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardData {
  final ClusterProfile cluster;
  final List<RecommendationItem> recommendations;
  final ForecastResult forecast;
  _DashboardData({required this.cluster, required this.recommendations, required this.forecast});
}
