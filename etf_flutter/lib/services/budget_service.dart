import '../database/database_helper.dart';
import '../models/budget.dart';

class BudgetService {
  Future<List<Budget>> findForPeriod(int userId, int year, int month) async {
    final rows = await DatabaseHelper.db.rawQuery('''
      SELECT b.budget_id, b.category_id, c.name AS category_name,
             b.month, b.year, b.amount,
             COALESCE((
               SELECT SUM(t.amount) FROM transactions t
               WHERE t.user_id = b.user_id
                 AND t.category_id = b.category_id
                 AND t.type = 'EXPENSE'
                 AND strftime('%Y', t.txn_date) = printf('%04d', b.year)
                 AND strftime('%m', t.txn_date) = printf('%02d', b.month)
             ), 0) AS spent
      FROM budgets b
      JOIN categories c ON b.category_id = c.category_id
      WHERE b.user_id = ? AND b.year = ? AND b.month = ?
      ORDER BY c.name
    ''', [userId, year, month]);

    return rows.map((r) => Budget(
      id: r['budget_id'] as int,
      categoryId: r['category_id'] as int,
      categoryName: r['category_name'] as String,
      month: r['month'] as int,
      year: r['year'] as int,
      limit: (r['amount'] as num).toDouble(),
      spent: (r['spent'] as num).toDouble(),
    )).toList();
  }

  Future<void> save(int userId, int categoryId, int year, int month, double amount) async {
    final existing = await DatabaseHelper.db.query(
      'budgets',
      where: 'user_id = ? AND category_id = ? AND year = ? AND month = ?',
      whereArgs: [userId, categoryId, year, month],
    );
    if (existing.isEmpty) {
      await DatabaseHelper.db.insert('budgets', {
        'user_id': userId, 'category_id': categoryId,
        'month': month, 'year': year, 'amount': amount,
      });
    } else {
      await DatabaseHelper.db.update('budgets', {'amount': amount},
          where: 'budget_id = ?', whereArgs: [existing.first['budget_id']]);
    }
  }

  Future<void> delete(int userId, int budgetId) async {
    await DatabaseHelper.db.delete('budgets',
        where: 'budget_id = ? AND user_id = ?', whereArgs: [budgetId, userId]);
  }
}