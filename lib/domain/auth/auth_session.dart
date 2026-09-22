import 'user.dart';

/// Value object representing an active authentication session.
final class AuthSession {
  final String token;
  final User user;
  final DateTime? expiresAt;

  const AuthSession({
    required this.token,
    required this.user,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!);

  Map<String, Object?> toJson() => {
        'token': token,
        'user': user.toJson(),
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory AuthSession.fromJson(Map<String, Object?> json) {
    return AuthSession(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, Object?>),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthSession &&
          other.token == token &&
          other.user == user &&
          other.expiresAt == expiresAt);

  @override
  int get hashCode => Object.hash(token, user, expiresAt);

  @override
  String toString() => 'AuthSession(user: ${user.email})';
}
