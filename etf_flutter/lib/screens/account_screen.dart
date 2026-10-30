import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/password.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) _emailCtrl.text = user.email;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final newEmail = _emailCtrl.text.trim();
    final currentPassword = _currentPasswordCtrl.text;
    final newPassword = _newPasswordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;

    if (newEmail.isEmpty || currentPassword.isEmpty) {
      _snack('Email and current password are required.');
      return;
    }
    if (hashPassword(currentPassword) != user.passwordHash) {
      _snack('Current password is incorrect.');
      return;
    }
    if (newPassword.isNotEmpty && newPassword != confirmPassword) {
      _snack('New password and confirmation do not match.');
      return;
    }
    if (newPassword.isNotEmpty && newPassword.length < 6) {
      _snack('New password must be at least 6 characters.');
      return;
    }

    setState(() => _saving = true);
    try {
      if (newEmail.toLowerCase() != user.email.toLowerCase() &&
          await _authService.emailExists(newEmail, user.id)) {
        if (!mounted) return;
        setState(() => _saving = false);
        _snack('That email is already in use.');
        return;
      }

      final passwordToSave = newPassword.isEmpty ? null : newPassword;
      await _authService.updateCredentials(user.id, newEmail, passwordToSave);

      if (!mounted) return;
      context.read<AuthProvider>().updateUser(User(
            id: user.id,
            email: newEmail,
            passwordHash: passwordToSave != null
                ? hashPassword(passwordToSave)
                : user.passwordHash,
            fullName: user.fullName,
          ));
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      setState(() => _saving = false);
      _snack('Credentials updated successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Account Settings',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Logged in as: ${user?.email ?? ""}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 20),
                  const Text('Update Login Credentials',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}