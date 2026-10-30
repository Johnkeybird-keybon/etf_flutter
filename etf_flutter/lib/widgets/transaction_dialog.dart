import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../services/category_service.dart';
import '../services/transaction_service.dart';
import '../utils/formats.dart';

class TransactionDialog extends StatefulWidget {
  final Transaction? existing;
  const TransactionDialog({super.key, this.existing});

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final _catService = CategoryService();
  final _txService = TransactionService();
  TxType _type = TxType.expense;
  List<Category> _categories = [];
  int? _categoryId;
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _type = e.type;
      _categoryId = e.categoryId;
      _amountCtrl.text = e.amount.toString();
      _dateCtrl.text = Formats.date(e.date);
      _descCtrl.text = e.description;
    } else {
      _dateCtrl.text = Formats.date(DateTime.now());
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await _catService.findByType(_type);
    if (!mounted) return;
    setState(() {
      _categories = list;
      if (!_categories.any((c) => c.id == _categoryId)) {
        _categoryId = _categories.isNotEmpty ? _categories.first.id : null;
      }
    });
  }

  Future<void> _save() async {
    final categoryId = _categoryId;
    if (categoryId == null) return _snack('No category available for this type.');
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return _snack('Amount must be positive.');
    final date = DateTime.tryParse(_dateCtrl.text.trim());
    if (date == null) return _snack('Date must be yyyy-MM-dd.');

    setState(() => _saving = true);
    final userId = context.read<AuthProvider>().user!.id;
    try {
      final t = Transaction(
        id: widget.existing?.id,
        categoryId: categoryId,
        categoryName: '',
        type: _type,
        amount: amount,
        date: date,
        description: _descCtrl.text.trim(),
      );
      if (widget.existing == null) {
        await _txService.insert(userId, t);
      } else {
        await _txService.update(userId, t);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _snack('Save failed: $e');
      }
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Transaction' : 'Edit Transaction'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TxType>(
              // ignore: deprecated_member_use
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: TxType.income, child: Text('INCOME')),
                DropdownMenuItem(value: TxType.expense, child: Text('EXPENSE')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _type = v);
                _loadCategories();
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dateCtrl,
              decoration: const InputDecoration(labelText: 'Date (yyyy-MM-dd)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    );
  }
}