class User {
  final int id;
  final String email;
  final String passwordHash;
  final String fullName;

  User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.fullName,
  });

  factory User.fromMap(Map<String, dynamic> m) => User(
        id: m['user_id'] as int,
        email: m['email'] as String,
        passwordHash: m['password_hash'] as String,
        fullName: m['full_name'] as String,
      );

  User copyWith({
    String? email,
    String? passwordHash,
    String? fullName,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
    );
  }
}