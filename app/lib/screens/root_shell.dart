import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/finance_ai_service.dart';
import 'add_transaction_screen.dart';
import 'dashboard_screen.dart';
import 'forecast_screen.dart';
import 'recommendations_screen.dart';

/// Top-level shell: an AppBar with a user-ID switcher (the demo dataset
/// has 50 synthetic users) and a dark-mode toggle, a bottom navigation
/// bar, and the four main screens. Changing the user rebuilds each screen
/// with a fresh [ValueKey] so they refetch data for the newly selected
/// user. Tab switches use a fade transition instead of an instant cut.
class RootShell extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeMode;
  const RootShell({super.key, required this.themeMode});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final FinanceAiService _api = FinanceAiService();
  int _userId = 1;
  int _tabIndex = 0;

  static const _titles = ['Dashboard', 'Forecast', 'Insights', 'Check Transaction'];

  void _pickUser() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final textColor = Theme.of(context).textTheme.titleMedium?.color;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text('Select demo user', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textColor)),
              const SizedBox(height: 8),
              const Text(
                'The dataset has 50 synthetic users (1-50)',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              SizedBox(
                height: 280,
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: 50,
                  itemBuilder: (context, i) {
                    final id = i + 1;
                    final selected = id == _userId;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primary
                              : Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$id',
                          style: TextStyle(
                            color: selected ? Colors.white : textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null && selected != _userId) {
      setState(() => _userId = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(key: ValueKey('dash_$_userId'), userId: _userId, api: _api),
      ForecastScreen(key: ValueKey('forecast_$_userId'), userId: _userId, api: _api),
      RecommendationsScreen(key: ValueKey('recs_$_userId'), userId: _userId, api: _api),
      AddTransactionScreen(key: ValueKey('add_$_userId'), userId: _userId, api: _api),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tabIndex]),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: widget.themeMode,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return IconButton(
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                onPressed: () {
                  widget.themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _pickUser,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_rounded, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'User $_userId',
                      style: const TextStyle(
                          color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const Icon(Icons.expand_more_rounded, size: 16, color: AppTheme.primary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // IndexedStack keeps all four tabs mounted (each with its own
      // ValueKey per user), so scroll position and fetched data survive
      // switching back and forth — only the currently selected one paints.
      body: IndexedStack(index: _tabIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Forecast'),
          NavigationDestination(icon: Icon(Icons.lightbulb_outline_rounded), selectedIcon: Icon(Icons.lightbulb_rounded), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded), selectedIcon: Icon(Icons.add_circle_rounded), label: 'Check'),
        ],
      ),
    );
  }
}
