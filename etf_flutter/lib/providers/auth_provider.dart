import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  void login(User u)  { _user = u; notifyListeners(); }
  void logout()       { _user = null; notifyListeners(); }
  void updateUser(User u) { _user = u; notifyListeners(); }
}