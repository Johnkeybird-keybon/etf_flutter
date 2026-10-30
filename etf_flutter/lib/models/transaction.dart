import 'category.dart';

class Transaction {
  final int? id;
  final int categoryId;
  final String categoryName;
  final TxType type;
  final double amount;
  final DateTime date;
  final String description;

  Transaction({
    this.id,
    required this.categoryId,
    required this.categoryName,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
  });

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
    id: m['transaction_id'] as int?,
    categoryId: m['category_id'] as int,
    categoryName: m['category_name'] as String,
    type: txTypeFromString(m['type'] as String),
    amount: (m['amount'] as num).toDouble(),
    date: DateTime.parse(m['txn_date'] as String),
    description: m['description'] as String? ?? '',
  );
}