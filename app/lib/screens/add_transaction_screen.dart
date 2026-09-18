import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/models.dart';
import '../services/api_exception.dart';
import '../services/finance_ai_service.dart';
import '../widgets/common_widgets.dart';

/// Lets the user enter a raw transaction, predicts its category with the
/// ML model, then offers a one-tap check for whether it's unusual for
/// this user (anomaly detection). Two model calls chained in one flow.
class AddTransactionScreen extends StatefulWidget {
  final int userId;
  final FinanceAiService api;
  const AddTransactionScreen({super.key, required this.userId, required this.api});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  String _paymentMethod = 'Credit Card';

  bool _predicting = false;
  bool _checkingAnomaly = false;
  String? _error;
  CategoryPrediction? _prediction;
  AnomalyResult? _anomaly;

  static const _paymentMethods = ['Credit Card', 'Debit Card', 'Cash', 'Bank Transfer', 'UPI'];

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _predictCategory() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _predicting = true;
      _error = null;
      _prediction = null;
      _anomaly = null;
    });
    try {
      final result = await widget.api.predictCategory(
        merchant: _merchantController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        paymentMethod: _paymentMethod,
      );
      setState(() => _prediction = result);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.toString() : 'Something went wrong.');
    } finally {
      setState(() => _predicting = false);
    }
  }

  Future<void> _checkAnomaly() async {
    if (_prediction == null) return;
    setState(() {
      _checkingAnomaly = true;
      _error = null;
    });
    try {
      final result = await widget.api.checkAnomaly(
        userId: widget.userId,
        category: _prediction!.predictedCategory,
        merchant: _merchantController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
      );
      setState(() => _anomaly = result);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.toString() : 'Something went wrong.');
    } finally {
      setState(() => _checkingAnomaly = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _prediction != null ? CategoryStyle.of(_prediction!.predictedCategory) : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SectionHeader(title: 'Check a transaction'),
        const SizedBox(height: 4),
        const Text(
          'Enter a transaction to predict its category and check whether '
          'it looks unusual for this user.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                  hintText: 'e.g. Starbucks',
                  prefixIcon: Icon(Icons.storefront_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a merchant name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'e.g. 12.50',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment method',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
                items: _paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _predicting ? null : _predictCategory,
                  icon: _predicting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_predicting ? 'Predicting...' : 'Predict category'),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
              ],
            ),
          ),
        ],
        if (_prediction != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: style!.color.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(style.icon, color: style.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Predicted category',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          Text(
                            _prediction!.predictedCategory,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _prediction!.confidence,
                    minHeight: 8,
                    backgroundColor: style.color.withValues(alpha: 0.12),
                    color: style.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(_prediction!.confidence * 100).toStringAsFixed(1)}% confidence',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _checkingAnomaly ? null : _checkAnomaly,
                    icon: _checkingAnomaly
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.shield_outlined, size: 18),
                    label: Text(_checkingAnomaly ? 'Checking...' : 'Check if this is unusual'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_anomaly != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (_anomaly!.isAnomaly ? AppTheme.danger : AppTheme.accent).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _anomaly!.isAnomaly ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                  color: _anomaly!.isAnomaly ? AppTheme.danger : AppTheme.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _anomaly!.isAnomaly ? 'This looks unusual' : 'This looks normal',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _anomaly!.isAnomaly ? AppTheme.danger : AppTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_anomaly!.userTypicalAmount != null)
                        Text(
                          'Typical spend in this category: \$${_anomaly!.userTypicalAmount!.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                        ),
                      if (_anomaly!.deviationStd != null)
                        Text(
                          'Deviation: ${_anomaly!.deviationStd!.toStringAsFixed(2)} std. dev. from typical',
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
