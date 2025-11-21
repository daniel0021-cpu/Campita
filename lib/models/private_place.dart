import 'package:latlong2/latlong.dart';

/// Private place that users want to visit with reminder functionality
class PrivatePlace {
  final String id;
  final String name;
  final String description;
  final LatLng location;
  final String? buildingId;
  final DateTime? reminderTime;
  final bool reminderEnabled;
  final DateTime createdAt;
  final String category; // personal, academic, social, other
  final String? notes;
  final bool isVisited;
  final DateTime? visitedAt;

  PrivatePlace({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.buildingId,
    this.reminderTime,
    this.reminderEnabled = false,
    required this.createdAt,
    this.category = 'personal',
    this.notes,
    this.isVisited = false,
    this.visitedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'buildingId': buildingId,
      'reminderTime': reminderTime?.toIso8601String(),
      'reminderEnabled': reminderEnabled,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      'notes': notes,
      'isVisited': isVisited,
      'visitedAt': visitedAt?.toIso8601String(),
    };
  }

  factory PrivatePlace.fromJson(Map<String, dynamic> json) {
    return PrivatePlace(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      location: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      buildingId: json['buildingId'] as String?,
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'] as String)
          : null,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: json['category'] as String? ?? 'personal',
      notes: json['notes'] as String?,
      isVisited: json['isVisited'] as bool? ?? false,
      visitedAt: json['visitedAt'] != null
          ? DateTime.parse(json['visitedAt'] as String)
          : null,
    );
  }

  PrivatePlace copyWith({
    String? id,
    String? name,
    String? description,
    LatLng? location,
    String? buildingId,
    DateTime? reminderTime,
    bool? reminderEnabled,
    DateTime? createdAt,
    String? category,
    String? notes,
    bool? isVisited,
    DateTime? visitedAt,
  }) {
    return PrivatePlace(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      buildingId: buildingId ?? this.buildingId,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isVisited: isVisited ?? this.isVisited,
      visitedAt: visitedAt ?? this.visitedAt,
    );
  }
}
