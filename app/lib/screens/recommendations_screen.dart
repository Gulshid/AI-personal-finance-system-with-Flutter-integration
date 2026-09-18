import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../services/api_exception.dart';
import '../services/finance_ai_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/shimmer_loading.dart';

class RecommendationsScreen extends StatefulWidget {
  final int userId;
  final FinanceAiService api;
  const RecommendationsScreen({super.key, required this.userId, required this.api});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late Future<List<RecommendationItem>> _future;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getUserRecommendations(widget.userId);
  }

  void _retry() => setState(() {
        _selectedCategory = null;
        _future = widget.api.getUserRecommendations(widget.userId);
      });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _retry(),
      child: FutureBuilder<List<RecommendationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ShimmerBox(height: 90, borderRadius: BorderRadius.circular(18)),
                const SizedBox(height: 12),
                ShimmerBox(height: 90, borderRadius: BorderRadius.circular(18)),
                const SizedBox(height: 12),
                ShimmerBox(height: 90, borderRadius: BorderRadius.circular(18)),
              ],
            );
          }
          if (snapshot.hasError) {
            final message =
                snapshot.error is ApiException ? snapshot.error.toString() : 'Unexpected error occurred.';
            return ListView(children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ErrorView(message: message, onRetry: _retry),
              ),
            ]);
          }

          final allItems = snapshot.data!;
          if (allItems.isEmpty) {
            return ListView(children: const [
              SizedBox(
                height: 400,
                child: EmptyStateView(
                  icon: Icons.check_circle_rounded,
                  message:
                      'No unusual spending patterns detected right now.\nCheck back after your next few transactions.',
                ),
              ),
            ]);
          }

          final categories = allItems.map((e) => e.category).toSet().toList()..sort();
          final items = _selectedCategory == null
              ? allItems
              : allItems.where((e) => e.category == _selectedCategory).toList();

          return Column(
            children: [
              if (categories.length > 1)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    children: [
                      _FilterChip(
                        label: 'All (${allItems.length})',
                        selected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(width: 8),
                      ...categories.map((c) {
                        final count = allItems.where((e) => e.category == c).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: '$c ($count)',
                            color: CategoryStyle.of(c).color,
                            selected: _selectedCategory == c,
                            onTap: () => setState(() => _selectedCategory = c),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => StaggeredFadeIn(
                    index: i,
                    child: RecommendationCard(item: items[i]),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : chipColor,
          ),
        ),
      ),
    );
  }
}
