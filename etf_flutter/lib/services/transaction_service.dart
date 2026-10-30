import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/formats.dart';

class TransactionService {
  static const _base = '''
    SELECT t.transaction_id, t.category_id, c.name AS category_name, t.type,
           t.amount, t.txn_date, t.description
    FROM transactions t
    JOIN categories c ON t.category_id = c.category_id
  ''';

  Future<void> insert(int userId, Transaction t) async {
    await DatabaseHelper.db.insert('transactions', {
      'user_id': userId,
      'category_id': t.categoryId,
      'type': t.type.dbValue,
      'amount': t.amount,
      'txn_date': Formats.date(t.date),
      'description': t.description,
    });
  }

  Future<void> update(int userId, Transaction t) async {
    await DatabaseHelper.db.update(
      'transactions',
      {
        'category_id': t.categoryId,
        'type': t.type.dbValue,
        'amount': t.amount,
        'txn_date': Formats.date(t.date),
        'description': t.description,
      },
      where: 'transaction_id = ? AND user_id = ?',
      whereArgs: [t.id, userId],
    );
  }

  Future<void> delete(int userId, int id) async {
    await DatabaseHelper.db.delete('transactions',
        where: 'transaction_id = ? AND user_id = ?', whereArgs: [id, userId]);
  }

  Future<List<Transaction>> search({
    required int userId,
    DateTime? from,
    DateTime? to,
    int? categoryId,
    TxType? type,
    double? min,
    double? max,
    String? keyword,
  }) async {
    final where = <String>['t.user_id = ?'];
    final args = <Object?>[userId];

    if (from != null)     { where.add('t.txn_date >= ?');   args.add(Formats.date(from)); }
    if (to != null)       { where.add('t.txn_date <= ?');   args.add(Formats.date(to)); }
    if (categoryId != null) { where.add('t.category_id = ?'); args.add(categoryId); }
    if (type != null)     { where.add('t.type = ?');        args.add(type.dbValue); }
    if (min != null)      { where.add('t.amount >= ?');     args.add(min); }
    if (max != null)      { where.add('t.amount <= ?');     args.add(max); }
    if (keyword != null && keyword.trim().isNotEmpty) {
      where.add('t.description LIKE ?');
      args.add('%${keyword.trim()}%');
    }

    final sql = '$_base WHERE ${where.join(' AND ')} '
        'ORDER BY t.txn_date DESC, t.transaction_id DESC';
    final rows = await DatabaseHelper.db.rawQuery(sql, args);
    return rows.map(Transaction.fromMap).toList();
  }

  Future<double> monthlyTotal(int userId, TxType type, int year, int month) async {
    final from = DateTime(year, month, 1);
    final to   = DateTime(year, month + 1, 1);
    final rows = await DatabaseHelper.db.rawQuery('''
      SELECT COALESCE(SUM(amount),0) AS total FROM transactions
      WHERE user_id = ? AND type = ? AND txn_date >= ? AND txn_date < ?
    ''', [userId, type.dbValue, Formats.date(from), Formats.date(to)]);
    return (rows.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> expenseByCategory(int userId, int year, int month) async {
    final from = DateTime(year, month, 1);
    final to   = DateTime(year, month + 1, 1);
    final rows = await DatabaseHelper.db.rawQuery('''
      SELECT c.name, SUM(t.amount) AS total
      FROM transactions t
      JOIN categories c ON t.category_id = c.category_id
      WHERE t.user_id = ? AND t.type = 'EXPENSE'
        AND t.txn_date >= ? AND t.txn_date < ?
      GROUP BY c.name ORDER BY total DESC
    ''', [userId, Formats.date(from), Formats.date(to)]);
    return { for (final r in rows)
      r['name'] as String: (r['total'] as num).toDouble() };
  }
}