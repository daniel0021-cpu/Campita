/// Enhanced user profile with comprehensive campus-relevant data
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? studentId;
  final String? department;
  final String? year; // Freshman, Sophomore, Junior, Senior, Graduate
  final String? major;
  final String? phoneNumber;
  final String? bio;
  final String? avatarBase64;
  final List<String> interests;
  final String role; // Student, Faculty, Staff, Visitor
  final bool notificationsEnabled;
  final bool locationSharingEnabled;
  final String? dormBuilding;
  final String? roomNumber;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.studentId,
    this.department,
    this.year,
    this.major,
    this.phoneNumber,
    this.bio,
    this.avatarBase64,
    this.interests = const [],
    this.role = 'Student',
    this.notificationsEnabled = true,
    this.locationSharingEnabled = false,
    this.dormBuilding,
    this.roomNumber,
    required this.createdAt,
    this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'department': department,
      'year': year,
      'major': major,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'avatarBase64': avatarBase64,
      'interests': interests,
      'role': role,
      'notificationsEnabled': notificationsEnabled,
      'locationSharingEnabled': locationSharingEnabled,
      'dormBuilding': dormBuilding,
      'roomNumber': roomNumber,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      studentId: json['studentId'] as String?,
      department: json['department'] as String?,
      year: json['year'] as String?,
      major: json['major'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      bio: json['bio'] as String?,
      avatarBase64: json['avatarBase64'] as String?,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      role: json['role'] as String? ?? 'Student',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      locationSharingEnabled: json['locationSharingEnabled'] as bool? ?? false,
      dormBuilding: json['dormBuilding'] as String?,
      roomNumber: json['roomNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    String? department,
    String? year,
    String? major,
    String? phoneNumber,
    String? bio,
    String? avatarBase64,
    List<String>? interests,
    String? role,
    bool? notificationsEnabled,
    bool? locationSharingEnabled,
    String? dormBuilding,
    String? roomNumber,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      year: year ?? this.year,
      major: major ?? this.major,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      interests: interests ?? this.interests,
      role: role ?? this.role,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      dormBuilding: dormBuilding ?? this.dormBuilding,
      roomNumber: roomNumber ?? this.roomNumber,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
