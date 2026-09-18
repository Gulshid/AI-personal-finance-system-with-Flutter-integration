import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/root_shell.dart';

void main() {
  runApp(const FinanceAiApp());
}

class FinanceAiApp extends StatefulWidget {
  const FinanceAiApp({super.key});

  @override
  State<FinanceAiApp> createState() => _FinanceAiAppState();
}

class _FinanceAiAppState extends State<FinanceAiApp> {
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.light);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'AI Personal Finance',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: RootShell(themeMode: _themeMode),
        );
      },
    );
  }
}
