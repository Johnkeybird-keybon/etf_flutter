import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../services/category_service.dart';
import '../services/transaction_service.dart';
import '../utils/formats.dart';
import '../widgets/transaction_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _txService = TransactionService();
  final _catService = CategoryService();

  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _keywordCtrl = TextEditingController();
  int? _categoryId;
  TxType? _type;
  List<Category> _categories = [];
  List<Transaction> _data = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _search();
  }

  Future<void> _loadCategories() async {
    final list = await _catService.findAll();
    if (mounted) setState(() => _categories = list);
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final userId = context.read<AuthProvider>().user!.id;
    try {
      final data = await _txService.search(
        userId: userId,
        from: DateTime.tryParse(_fromCtrl.text.trim()),
        to: DateTime.tryParse(_toCtrl.text.trim()),
        categoryId: _categoryId,
        type: _type,
        min: double.tryParse(_minCtrl.text),
        max: double.tryParse(_maxCtrl.text),
        keyword: _keywordCtrl.text,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    _fromCtrl.clear();
    _toCtrl.clear();
    _minCtrl.clear();
    _maxCtrl.clear();
    _keywordCtrl.clear();
    setState(() {
      _categoryId = null;
      _type = null;
    });
    _search();
  }

  Future<void> _openDialog(Transaction? existing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => TransactionDialog(existing: existing),
    );
    if (ok == true) _search();
  }

  Future<void> _delete(Transaction t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Delete ${Formats.date(t.date)} - ${t.categoryName} - ${Formats.money(t.amount)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return; // <--- FIX: Async gap check

    final userId = context.read<AuthProvider>().user!.id;
    await _txService.delete(userId, t.id!);
    _search();
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0, totalExpense = 0;
    for (final t in _data) {
      if (t.type == TxType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Card(
            child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(
                width: 140,
                child: TextField(
                  controller: _fromCtrl,
                  decoration: const InputDecoration(
                      labelText: 'From (yyyy-MM-dd)', isDense: true),
                )),
            SizedBox(
                width: 140,
                child: TextField(
                  controller: _toCtrl,
                  decoration: const InputDecoration(
                      labelText: 'To (yyyy-MM-dd)', isDense: true),
                )),
            SizedBox(
                width: 160,
                child: DropdownButtonFormField<int?>(
                  // ignore: deprecated_member_use
                  value: _categoryId,
                  decoration:
                      const InputDecoration(labelText: 'Category', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._categories.map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                )),
            SizedBox(
                width: 130,
                child: DropdownButtonFormField<TxType?>(
                  // ignore: deprecated_member_use
                  value: _type,
                  decoration:
                      const InputDecoration(labelText: 'Type', isDense: true),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: TxType.income, child: Text('INCOME')),
                    DropdownMenuItem(
                        value: TxType.expense, child: Text('EXPENSE')),
                  ],
                  onChanged: (v) => setState(() => _type = v),
                )),
            SizedBox(
                width: 100,
                child: TextField(
                    controller: _minCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Min', isDense: true))),
            SizedBox(
                width: 100,
                child: TextField(
                    controller: _maxCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Max', isDense: true))),
            SizedBox(
                width: 160,
                child: TextField(
                    controller: _keywordCtrl,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                        labelText: 'Keyword', isDense: true))),
            FilledButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search),
                label: const Text('Search')),
            OutlinedButton(onPressed: _reset, child: const Text('Reset')),
          ]),
        )),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _data.isEmpty
                  ? const Center(child: Text('No transactions found.'))
                  : Card(
                      child: SingleChildScrollView(
                          child: SizedBox(
                              width: double.infinity,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Type')),
                                  DataColumn(label: Text('Category')),
                                  DataColumn(label: Text('Amount')),
                                  DataColumn(label: Text('Description')),
                                  DataColumn(label: Text('')),
                                ],
                                rows: _data.map((t) {
                                  return DataRow(cells: [
                                    DataCell(Text(Formats.date(t.date))),
                                    DataCell(Text(t.type.label)),
                                    DataCell(Text(t.categoryName)),
                                    DataCell(Text(Formats.money(t.amount))),
                                    DataCell(Text(t.description)),
                                    DataCell(Row(children: [
                                      IconButton(
                                          onPressed: () => _openDialog(t),
                                          icon: const Icon(Icons.edit, size: 18)),
                                      IconButton(
                                          onPressed: () => _delete(t),
                                          icon: const Icon(Icons.delete,
                                              size: 18, color: Colors.red)),
                                    ])),
                                  ]);
                                }).toList(),
                              )))),
        ),
        const SizedBox(height: 8),
        Row(children: [
          FilledButton.icon(
              onPressed: () => _openDialog(null),
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction')),
          const Spacer(),
          Text(
              'Showing ${_data.length}  |  Income: ${Formats.money(totalIncome)}  |  '
              'Expense: ${Formats.money(totalExpense)}'),
        ]),
      ]),
    );
  }
}