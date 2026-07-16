class Profile {
  final String id;
  final String email;
  final String? displayName;
  final String role; // user, owner, admin
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.email,
    this.displayName,
    this.role = 'user',
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isOwner => role == 'owner' || role == 'admin';

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: (json['email'] as String?) ?? '',
        displayName: json['display_name'] as String?,
        role: (json['role'] as String?) ?? 'user',
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'role': role,
        'created_at': createdAt.toIso8601String(),
      };

  Profile copyWith({String? displayName, String? role}) => Profile(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        role: role ?? this.role,
        createdAt: createdAt,
      );
}
