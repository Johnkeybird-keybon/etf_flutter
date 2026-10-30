import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../providers/auth_provider.dart';
import '../services/budget_service.dart';
import '../services/transaction_service.dart';
import '../utils/formats.dart';
import '../widgets/month_year_selector.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  final _txService = TransactionService();
  final _budgetService = BudgetService();
  double _income = 0, _expense = 0;
  List<Budget> _budgets = [];
  Map<String, double> _expenseByCategory = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user!.id;
    setState(() => _loading = true);
    try {
      final income =
          await _txService.monthlyTotal(userId, TxType.income, _year, _month);
      final expense =
          await _txService.monthlyTotal(userId, TxType.expense, _year, _month);
      final budgets = await _budgetService.findForPeriod(userId, _year, _month);
      final byCategory =
          await _txService.expenseByCategory(userId, _year, _month);

      if (!mounted) return;
      setState(() {
        _income = income;
        _expense = expense;
        _budgets = budgets;
        _expenseByCategory = byCategory;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Top Bar ---
          Row(
            children: [
              Text('Welcome, ${user.fullName}',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
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
            ],
          ),
          const SizedBox(height: 16),

          // --- Stat Cards ---
          Row(
            children: [
              Expanded(
                  child: _statCard(
                      'Total Income', _income, Colors.green, Icons.arrow_upward)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard(
                      'Total Expenses', _expense, Colors.red, Icons.arrow_downward)),
              const SizedBox(width: 12),
              Expanded(
                  child: _statCard('Net Balance', _income - _expense,
                      Colors.blue, Icons.account_balance_wallet)),
            ],
          ),
          const SizedBox(height: 16),

          // --- Charts & Tables ---
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pie Chart Area
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Expense Breakdown',
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: _expenseByCategory.isEmpty
                                      ? const Center(
                                          child: Text('No expenses recorded.'))
                                      : _buildPieChart(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Budget List Area
                      Expanded(
                        flex: 3,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Budget Status',
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: _budgets.isEmpty
                                      ? const Center(
                                          child: Text('No budgets set for this period.'))
                                      : SingleChildScrollView(
                                          child: SizedBox(
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
                                                  DataCell(
                                                      Text(Formats.money(b.limit))),
                                                  DataCell(
                                                      Text(Formats.money(b.spent))),
                                                  DataCell(Text(
                                                      Formats.money(b.remaining))),
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
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, double value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  'PHP ${Formats.money(value)}',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow[700]!,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    int colorIndex = 0;

    return Row(
      children: [
        // The Pie Chart
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _expenseByCategory.entries.map((e) {
                final percent = (e.value / _expense) * 100;
                final color = colors[colorIndex % colors.length];
                colorIndex++;
                return PieChartSectionData(
                  color: color,
                  value: e.value,
                  title: '${percent.toStringAsFixed(0)}%',
                  radius: 50,
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // The Legend
        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: _expenseByCategory.keys.map((key) {
              final index = _expenseByCategory.keys.toList().indexOf(key);
              final color = colors[index % colors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(key, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}