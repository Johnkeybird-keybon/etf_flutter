import '../database/database_helper.dart';
import '../models/category.dart';

class CategoryService {
  Future<List<Category>> findAll() async {
    final rows = await DatabaseHelper.db
        .query('categories', orderBy: 'type, name');
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Category>> findByType(TxType type) async {
    final rows = await DatabaseHelper.db.query(
      'categories',
      where: 'type = ?', whereArgs: [type.dbValue], orderBy: 'name',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<void> insert(String name, TxType type) async {
    await DatabaseHelper.db.insert(
        'categories', {'name': name, 'type': type.dbValue});
  }

  Future<void> update(int id, String name, TxType type) async {
    await DatabaseHelper.db.update('categories',
        {'name': name, 'type': type.dbValue},
        where: 'category_id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.db.delete('categories',
        where: 'category_id = ?', whereArgs: [id]);
  }
}