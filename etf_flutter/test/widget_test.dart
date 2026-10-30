import 'package:flutter_test/flutter_test.dart';
import 'package:etf/utils/password.dart'; // <-- Using relative path fixes the error

void main() {
  test('hashPassword produces a consistent SHA-256 hex digest', () {
    final h1 = hashPassword('admin123');
    final h2 = hashPassword('admin123');
    expect(h1, h2);
    expect(h1.length, 64); // SHA-256 hex = 64 chars
    expect(h1, isNot(equals(hashPassword('different'))));
  });
}