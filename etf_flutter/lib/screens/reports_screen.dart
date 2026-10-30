import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../services/budget_service.dart';
import '../services/transaction_service.dart';
import '../utils/formats.dart';
import '../widgets/month_year_selector.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _txService = TransactionService();
  final _budgetService = BudgetService();
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _loading = false;

  // Data variables
  double _income = 0;
  double _expense = 0;
  double _net = 0;
  Map<String, double> _byCategory = {};
  List<Budget> _budgets = [];

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    final userId = context.read<AuthProvider>().user!.id;
    try {
      final income = await _txService.monthlyTotal(userId, TxType.income, _year, _month);
      final expense = await _txService.monthlyTotal(userId, TxType.expense, _year, _month);
      final byCategory = await _txService.expenseByCategory(userId, _year, _month);
      final budgets = await _budgetService.findForPeriod(userId, _year, _month);

      if (!mounted) return;
      setState(() {
        _income = income;
        _expense = expense;
        _net = income - expense;
        _byCategory = byCategory;
        _budgets = budgets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report failed: $e')),
      );
    }
  }

  Future<void> _export() async {
    final sb = StringBuffer();
    sb.writeln('==============================================');
    sb.writeln('           ETF MONTHLY FINANCIAL REPORT       ');
    sb.writeln('==============================================');
    sb.writeln('Period        : ${_month.toString().padLeft(2, '0')}/$_year');
    sb.writeln('Total Income  : ${Formats.money(_income)}');
    sb.writeln('Total Expenses: ${Formats.money(_expense)}');
    sb.writeln('Net Balance   : ${Formats.money(_net)}');
    sb.writeln('----------------------------------------------');
    sb.writeln();
    sb.writeln('EXPENSES BY CATEGORY');
    if (_byCategory.isEmpty) {
      sb.writeln('  (no expenses recorded)');
    } else {
      _byCategory.forEach((cat, amt) {
        sb.writeln('  ${cat.padRight(20)}${Formats.money(amt).padLeft(12)}');
      });
    }
    sb.writeln();
    sb.writeln('BUDGET STATUS');
    if (_budgets.isEmpty) {
      sb.writeln('  (no budgets set for this period)');
    } else {
      sb.writeln('  ${"Category".padRight(15)}'
          '${"Limit".padLeft(12)}${"Spent".padLeft(12)}'
          '${"Remaining".padLeft(12)}  Status');
      for (final b in _budgets) {
        sb.writeln('  ${b.categoryName.padRight(15)}'
            '${Formats.money(b.limit).padLeft(12)}'
            '${Formats.money(b.spent).padLeft(12)}'
            '${Formats.money(b.remaining).padLeft(12)}  '
            '${b.isOverBudget ? 'OVER' : 'OK'}');
      }
    }
    sb.writeln();
    sb.writeln('==============================================');

    try {
      final file = File(
          '${Directory.current.path}/ETF_Report_${_year}_'
          '${_month.toString().padLeft(2, '0')}.txt');
      await file.writeAsString(sb.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report saved to ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
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
          // Header Controls
          Row(
            children: [
              const Text('Period:'),
              const SizedBox(width: 8),
              MonthYearSelector(
                month: _month,
                year: _year,
                onMonthChanged: (m) {
                  setState(() => _month = m);
                  _generate();
                },
                onYearChanged: (y) {
                  setState(() => _year = y);
                  _generate();
                },
              ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: _loading ? null : _generate,
                icon: const Icon(Icons.refresh),
                label: const Text('Generate'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _loading ? null : _export,
                icon: const Icon(Icons.file_download),
                label: const Text('Export as TXT'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Report Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary Row
                        Row(
                          children: [
                            _summaryCard('Total Income', _income, Colors.green),
                            const SizedBox(width: 16),
                            _summaryCard('Total Expenses', _expense, Colors.red),
                            const SizedBox(width: 16),
                            _summaryCard('Net Balance', _net, Colors.blue),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Expenses By Category
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expenses by Category',
                                    style: Theme.of(context).textTheme.titleMedium),
                                const Divider(),
                                _byCategory.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('No expenses recorded.'),
                                      )
                                    : SizedBox(
                                        width: double.infinity,
                                        child: DataTable(
                                          columns: const [
                                            DataColumn(label: Text('Category')),
                                            DataColumn(label: Text('Amount')),
                                          ],
                                          rows: _byCategory.entries.map((e) {
                                            return DataRow(cells: [
                                              DataCell(Text(e.key)),
                                              DataCell(Text(Formats.money(e.value))),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Budget Status
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Budget Status',
                                    style: Theme.of(context).textTheme.titleMedium),
                                const Divider(),
                                _budgets.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('No budgets set for this period.'),
                                      )
                                    : SizedBox(
                                        width: double.infinity,
                                        child: DataTable(
                                          columns: const [
                                            DataColumn(label: Text('Category')),
                                            DataColumn(label: Text('Limit')),
                                            DataColumn(label: Text('Spent')),
                                            DataColumn(label: Text('Remaining')),
                                            DataColumn(label: Text('Status')),
                                          ],
                                          rows: _budgets.map((b) {
                                            return DataRow(cells: [
                                              DataCell(Text(b.categoryName)),
                                              DataCell(Text(Formats.money(b.limit))),
                                              DataCell(Text(Formats.money(b.spent))),
                                              DataCell(Text(Formats.money(b.remaining))),
                                              DataCell(Text(
                                                b.isOverBudget ? 'OVER' : 'OK',
                                                style: TextStyle(
                                                  color: b.isOverBudget
                                                      ? Colors.red
                                                      : Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, double value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                'PHP ${Formats.money(value)}',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}