import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for InputFormatters
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
  final _formKey = GlobalKey<FormState>();
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
      _amountCtrl.text = e.amount.toStringAsFixed(2);
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

  Future<void> _pickDate() async {
    final initialDate = DateTime.tryParse(_dateCtrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateCtrl.text = Formats.date(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category.')));
      return;
    }

    setState(() => _saving = true);
    final userId = context.read<AuthProvider>().user!.id;
    
    try {
      final t = Transaction(
        id: widget.existing?.id,
        categoryId: _categoryId!,
        categoryName: '',
        type: _type,
        amount: double.parse(_amountCtrl.text.trim()),
        date: DateTime.parse(_dateCtrl.text.trim()),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Transaction' : 'Edit Transaction'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<TxType>(
                // ignore: deprecated_member_use
                value: _type,
                decoration: const InputDecoration(
                    labelText: 'Type', border: OutlineInputBorder()),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                // ignore: deprecated_member_use
                value: _categoryId,
                decoration: const InputDecoration(
                    labelText: 'Category', border: OutlineInputBorder()),
                items: _categories.map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Category is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                    labelText: 'Amount', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Amount must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Date is required';
                  }
                  if (DateTime.tryParse(value) == null) {
                    return 'Invalid date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description (Optional)', border: OutlineInputBorder()),
                maxLength: 150,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: _saving ? null : _save, 
            child: _saving 
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save')),
      ],
    );
  }
}