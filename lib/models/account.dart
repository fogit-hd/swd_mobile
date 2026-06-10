class Account {
  const Account({
    required this.id,
    this.username,
    this.email,
    this.role,
    this.isActive = true,
    this.lastLoginAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'] as String)
          : null,
    );
  }

  final int id;
  final String? username;
  final String? email;
  final String? role;
  final bool isActive;
  final DateTime? lastLoginAt;
}
