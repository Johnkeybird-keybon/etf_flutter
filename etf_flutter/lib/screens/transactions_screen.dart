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
  
  int? _categoryId;
  TxType? _type;
  
  // Sorting State
  String _sortBy = 'date';
  bool _isAscending = false;

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

  Future<void> _pickDate(TextEditingController controller) async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = Formats.date(picked);
    }
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
        sortBy: _sortBy,
        isAscending: _isAscending,
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
    setState(() {
      _categoryId = null;
      _type = null;
      _sortBy = 'date';
      _isAscending = false;
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
    if (!mounted) return; 

    final userId = context.read<AuthProvider>().user!.id;
    await _txService.delete(userId, t.id!);
    _search();
  }

  Widget _buildDateInput(String label, TextEditingController controller) {
    return SizedBox(
      width: 150,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _pickDate(controller),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
        ),
      ),
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Filter & Sort Bar ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildDateInput('From', _fromCtrl),
                  _buildDateInput('To', _toCtrl),
                  
                  // Category Filter
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<int?>(
                      // ignore: deprecated_member_use
                      value: _categoryId,
                      isExpanded: true, 
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ..._categories.map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  ),

                  // Type Filter
                  SizedBox(
                    width: 120,
                    child: DropdownButtonFormField<TxType?>(
                      // ignore: deprecated_member_use
                      value: _type,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: TxType.income, child: Text('INCOME')),
                        DropdownMenuItem(value: TxType.expense, child: Text('EXPENSE')),
                      ],
                      onChanged: (v) => setState(() => _type = v),
                    ),
                  ),

                  const SizedBox(width: 8), // Spacer before sorting

                  // Sort By Dropdown
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _sortBy,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sort By',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'date', child: Text('Date')),
                        DropdownMenuItem(value: 'amount', child: Text('Amount')),
                        DropdownMenuItem(value: 'category', child: Text('Category')),
                        DropdownMenuItem(value: 'type', child: Text('Type')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _sortBy = v);
                          _search();
                        }
                      },
                    ),
                  ),

                  // Ascending / Descending Toggle
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() => _isAscending = !_isAscending);
                      _search();
                    },
                    icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                    tooltip: _isAscending ? 'Ascending' : 'Descending',
                  ),

                  SizedBox(
                    height: 48, 
                    child: FilledButton.icon(
                      onPressed: _search,
                      icon: const Icon(Icons.search),
                      label: const Text('Apply'),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _reset, 
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // --- Data Table ---
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
          const SizedBox(height: 12),

          // --- Bottom Action Bar ---
          Row(
            children: [
              FilledButton.icon(
                  onPressed: () => _openDialog(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Transaction')),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Showing ${_data.length}  |  Income: ${Formats.money(totalIncome)}  |  Expense: ${Formats.money(totalExpense)}',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}