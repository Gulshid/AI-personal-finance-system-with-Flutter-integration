import 'package:app/flutter_integration/finance_ai_service.dart';
import 'package:flutter/material.dart';
import 'services/finance_ai_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // TODO: replace with your Mac's LAN IP (from `ipconfig getifaddr en0`)
  final financeApi = FinanceAiService(baseUrl: 'http://192.168.18.19:8000');

  String _result = 'Tap the button to fetch recommendations for user 1';
  bool _loading = false;

  Future<void> _loadRecommendations() async {
    setState(() {
      _loading = true;
      _result = 'Loading...';
    });
    try {
      final recs = await financeApi.getUserRecommendations(1);
      setState(() {
        _result = recs.toString();
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance AI Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _loading ? null : _loadRecommendations,
              child: Text(_loading ? 'Loading...' : 'Get Recommendations (user 1)'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
