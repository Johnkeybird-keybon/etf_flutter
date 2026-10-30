import '../database/database_helper.dart';
import '../models/user.dart';
import '../utils/password.dart';

class AuthService {
  Future<User?> authenticate(String email, String password) async {
    final rows = await DatabaseHelper.db
        .query('users', where: 'email = ?', whereArgs: [email]);
    if (rows.isEmpty) return null;
    final user = User.fromMap(rows.first);
    if (user.passwordHash != hashPassword(password)) return null;
    return user;
  }

  Future<bool> emailExists(String email, int excludeId) async {
    final rows = await DatabaseHelper.db.query(
      'users',
      columns: ['user_id'],
      where: 'email = ? AND user_id <> ?',
      whereArgs: [email, excludeId],
    );
    return rows.isNotEmpty;
  }

  Future<void> updateCredentials(int userId, String email, String? newPassword) async {
    final values = <String, dynamic>{'email': email};
    if (newPassword != null) values['password_hash'] = hashPassword(newPassword);
    await DatabaseHelper.db.update('users', values,
        where: 'user_id = ?', whereArgs: [userId]);
  }
}