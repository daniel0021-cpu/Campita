class CampusEvent {
  final String id;
  final String title;
  final String description;
  final String venue;
  final String venueId; // Building ID for map navigation
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final String organizer;
  final String? imageUrl;
  final bool isUpcoming;
  final List<String> attendees;

  const CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.venueId,
    required this.startTime,
    required this.endTime,
    required this.category,
    required this.organizer,
    this.imageUrl,
    required this.isUpcoming,
    this.attendees = const [],
  });

  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  bool get isHappening {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  String get timeRangeFormatted {
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  String get dateFormatted {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[startTime.month - 1]} ${startTime.day}, ${startTime.year}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'venue': venue,
        'venueId': venueId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'category': category,
        'organizer': organizer,
        'imageUrl': imageUrl,
        'isUpcoming': isUpcoming,
        'attendees': attendees,
      };

  factory CampusEvent.fromJson(Map<String, dynamic> json) => CampusEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        venue: json['venue'] as String,
        venueId: json['venueId'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        category: json['category'] as String,
        organizer: json['organizer'] as String,
        imageUrl: json['imageUrl'] as String?,
        isUpcoming: json['isUpcoming'] as bool,
        attendees: (json['attendees'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      );
}

// Sample events data
final List<CampusEvent> sampleEvents = [
  CampusEvent(
    id: '1',
    title: 'Mid-Semester Examination',
    description: 'Mid-semester exams for all 200-level students. Please arrive 15 minutes early with your student ID and writing materials.',
    venue: 'Main Auditorium',
    venueId: 'main_auditorium',
    startTime: DateTime.now().add(const Duration(hours: 2)),
    endTime: DateTime.now().add(const Duration(hours: 5)),
    category: 'Academics',
    organizer: 'Academic Affairs',
    isUpcoming: true,
    attendees: [],
  ),
  CampusEvent(
    id: '2',
    title: 'Career Fair 2025',
    description: 'Meet recruiters from top companies across Nigeria. Bring your CV and dress professionally.',
    venue: 'Danny K. Hall',
    venueId: 'danny_k_hall',
    startTime: DateTime.now().add(const Duration(days: 3, hours: 9)),
    endTime: DateTime.now().add(const Duration(days: 3, hours: 17)),
    category: 'Career',
    organizer: 'Student Affairs',
    isUpcoming: true,
    attendees: [],
  ),
  CampusEvent(
    id: '3',
    title: 'Inter-Faculty Football Tournament',
    description: 'Annual inter-faculty football competition. Finals match between Engineering and Sciences.',
    venue: 'Sports Complex',
    venueId: 'sports_complex',
    startTime: DateTime.now().add(const Duration(days: 5, hours: 16)),
    endTime: DateTime.now().add(const Duration(days: 5, hours: 18)),
    category: 'Sports',
    organizer: 'Sports Council',
    isUpcoming: true,
    attendees: [],
  ),
  CampusEvent(
    id: '4',
    title: 'Tech Workshop: AI & Machine Learning',
    description: 'Learn the fundamentals of AI and ML with hands-on projects. Limited seats available.',
    venue: 'ICT Center',
    venueId: 'ict_center',
    startTime: DateTime.now().add(const Duration(days: 7, hours: 10)),
    endTime: DateTime.now().add(const Duration(days: 7, hours: 15)),
    category: 'Workshop',
    organizer: 'Tech Club',
    isUpcoming: true,
    attendees: [],
  ),
  CampusEvent(
    id: '5',
    title: 'Freshers Welcome Party',
    description: 'Official welcome party for new students. Food, music, and entertainment provided.',
    venue: 'Student Center',
    venueId: 'student_center',
    startTime: DateTime.now().subtract(const Duration(days: 2)),
    endTime: DateTime.now().subtract(const Duration(days: 2, hours: -4)),
    category: 'Social',
    organizer: 'Student Union',
    isUpcoming: false,
    attendees: [],
  ),
];
