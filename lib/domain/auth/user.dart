/// Authenticated user entity.
final class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
      };

  factory User.fromJson(Map<String, Object?> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == id &&
          other.email == email &&
          other.displayName == displayName &&
          other.photoUrl == photoUrl);

  @override
  int get hashCode => Object.hash(id, email, displayName, photoUrl);

  @override
  String toString() => 'User(id: $id, email: $email)';
}
