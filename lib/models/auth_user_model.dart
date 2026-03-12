// features/models/auth_user_model.dart
enum UserRole {
  child,        // Criança
  professional, // Profissional
}

class AuthUser {
  final String id;
  final String username;
  final String passwordHash;
  final UserRole role;
  final String? childProfileId;
  final String displayName;
  final DateTime createdAt;

  AuthUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.childProfileId,
    required this.displayName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'passwordHash': passwordHash,
    'role': role.index,
    'childProfileId': childProfileId,
    'displayName': displayName,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      username: json['username'],
      passwordHash: json['passwordHash'],
      role: UserRole.values[json['role']],
      childProfileId: json['childProfileId'],
      displayName: json['displayName'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}