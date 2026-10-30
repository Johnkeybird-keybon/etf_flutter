import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';
import '../utils/formats.dart';
import '../widgets/month_year_selector.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});
  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _service = BudgetService();
  final _catService = CategoryService();
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  List<Budget> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = context.read<AuthProvider>().user!.id;
    try {
      final list = await _service.findForPeriod(userId, _year, _month);
      if (!mounted) return;
      setState(() {
        _data = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDialog(Budget? existing) async {
    final categories = await _catService.findByType(TxType.expense);
    if (!mounted) return;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an EXPENSE category first.')),
      );
      return;
    }

    int categoryId = existing?.categoryId ?? categories.first.id;
    final amountCtrl = TextEditingController(
      text: existing?.limit.toStringAsFixed(2) ?? '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setSt(() => categoryId = v);
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monthly Limit'),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (!mounted) return; // <--- FIX: Async gap check

    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limit must be positive.')),
      );
      return;
    }

    final userId = context.read<AuthProvider>().user!.id;
    try {
      await _service.save(userId, categoryId, _year, _month, amount);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _delete(Budget b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Remove budget for "${b.categoryName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return; // <--- FIX: Async gap check

    final userId = context.read<AuthProvider>().user!.id;
    try {
      await _service.delete(userId, b.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Text('Period:'),
            const SizedBox(width: 8),
            MonthYearSelector(
              month: _month,
              year: _year,
              onMonthChanged: (m) {
                setState(() => _month = m);
                _load();
              },
              onYearChanged: (y) {
                setState(() => _year = y);
                _load();
              },
            ),
            const SizedBox(width: 8),
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _openDialog(null),
              icon: const Icon(Icons.add),
              label: const Text('Set / Update Budget'),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _data.isEmpty
                    ? const Center(
                        child: Text('No budgets set for this period.'))
                    : Card(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Category')),
                                DataColumn(label: Text('Limit')),
                                DataColumn(label: Text('Spent')),
                                DataColumn(label: Text('Remaining')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('')),
                              ],
                              rows: _data.map((b) {
                                return DataRow(cells: [
                                  DataCell(Text(b.categoryName)),
                                  DataCell(Text(Formats.money(b.limit))),
                                  DataCell(Text(Formats.money(b.spent))),
                                  DataCell(Text(Formats.money(b.remaining))),
                                  DataCell(Text(
                                    b.isOverBudget ? 'OVER BUDGET' : 'OK',
                                    style: TextStyle(
                                      color: b.isOverBudget
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )),
                                  DataCell(Row(children: [
                                    IconButton(
                                      onPressed: () => _openDialog(b),
                                      icon: const Icon(Icons.edit, size: 18),
                                    ),
                                    IconButton(
                                      onPressed: () => _delete(b),
                                      icon: const Icon(Icons.delete,
                                          size: 18, color: Colors.red),
                                    ),
                                  ])),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}