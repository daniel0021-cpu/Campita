// Model for campus buildings with categories and details
import 'package:latlong2/latlong.dart';

enum BuildingCategory {
  academic,
  administrative,
  library,
  dining,
  banking,
  sports,
  student_services,
  research,
  health,
  residential,
  worship,
}

class CampusBuilding {
  final String name;
  final LatLng coordinates; // Building centroid (for display only)
  final LatLng? entrance; // Primary entrance coordinates (for routing)
  final List<LatLng>? entrances; // Multiple entrance points if available
  final BuildingCategory category;
  final String? description;
  final String? openingHours;
  final List<String>? amenities;
  final String? phoneNumber;
  final String? website;
  final String? email;
  final int? capacity;
  final String? buildingType;

  CampusBuilding({
    required this.name,
    required this.coordinates,
    this.entrance,
    this.entrances,
    required this.category,
    this.description,
    this.openingHours,
    this.amenities,
    this.phoneNumber,
    this.website,
    this.email,
    this.capacity,
    this.buildingType,
  });
  
  /// Get the best entrance point for routing (prefers entrance field, falls back to first in entrances list)
  LatLng? get primaryEntrance => entrance ?? (entrances?.isNotEmpty == true ? entrances!.first : null);

  String get categoryName {
    switch (category) {
      case BuildingCategory.academic:
        return 'Academic';
      case BuildingCategory.administrative:
        return 'Administrative';
      case BuildingCategory.library:
        return 'Library';
      case BuildingCategory.dining:
        return 'Dining';
      case BuildingCategory.banking:
        return 'Banking';
      case BuildingCategory.sports:
        return 'Sports';
      case BuildingCategory.student_services:
        return 'Student Services';
      case BuildingCategory.research:
        return 'Research';
      case BuildingCategory.health:
        return 'Health';
      case BuildingCategory.residential:
        return 'Residential';
      case BuildingCategory.worship:
        return 'Worship';
    }
  }

  String get categoryIcon {
    switch (category) {
      case BuildingCategory.academic:
        return '🎓';
      case BuildingCategory.administrative:
        return '🏢';
      case BuildingCategory.library:
        return '📚';
      case BuildingCategory.dining:
        return '🍽️';
      case BuildingCategory.banking:
        return '🏦';
      case BuildingCategory.sports:
        return '⚽';
      case BuildingCategory.student_services:
        return '👥';
      case BuildingCategory.research:
        return '🔬';
      case BuildingCategory.health:
        return '🏥';
      case BuildingCategory.residential:
        return '🏠';
      case BuildingCategory.worship:
        return '⛪';
    }
  }
}

// Campus buildings data with categories
final List<CampusBuilding> campusBuildings = [
  CampusBuilding(
    name: "Main Campus",
    coordinates: const LatLng(6.7442255, 5.4040473),
    entrance: const LatLng(6.7442455, 5.4039873), // Front entrance on main road
    category: BuildingCategory.administrative,
    description: "Igbinedion University Okada Main Administrative Building",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
    amenities: ["Reception", "Admin Offices", "Meeting Rooms"],
  ),
  CampusBuilding(
    name: "College of Law",
    coordinates: const LatLng(6.744662, 5.404184),
    entrance: const LatLng(6.744682, 5.404084), // Main entrance facing courtyard
    category: BuildingCategory.academic,
    description: "Faculty of Law with lecture halls and offices",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
    amenities: ["Lecture Halls", "Library", "Moot Court"],
  ),
  CampusBuilding(
    name: "College of Law Administrative Building",
    coordinates: const LatLng(6.744669, 5.403144),
    entrance: const LatLng(6.744669, 5.403044), // South entrance
    category: BuildingCategory.administrative,
    description: "Administrative offices for the College of Law",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
  ),
  CampusBuilding(
    name: "Igbinedion University Library",
    coordinates: const LatLng(6.741228, 5.403294),
    entrance: const LatLng(6.741308, 5.403274), // Front entrance on pedestrian path
    category: BuildingCategory.library,
    description: "Main university library with extensive collections",
    openingHours: "Mon-Sat: 8:00 AM - 10:00 PM",
    amenities: ["Study Rooms", "Computer Lab", "Reading Areas", "Wi-Fi"],
  ),
  CampusBuilding(
    name: "Buratai Center For Contemporary Security Affairs",
    coordinates: const LatLng(6.745408, 5.404163),
    entrance: const LatLng(6.745358, 5.404163), // West entrance
    category: BuildingCategory.research,
    description: "Research center for security and defense studies",
    openingHours: "Mon-Fri: 9:00 AM - 5:00 PM",
  ),
  CampusBuilding(
    name: "Main Auditorium",
    coordinates: const LatLng(6.743634, 5.404211),
    entrance: const LatLng(6.743684, 5.404211), // Main entrance east side
    category: BuildingCategory.academic,
    description: "Large auditorium for events and ceremonies",
    amenities: ["Seating for 500+", "Stage", "Sound System"],
  ),
  CampusBuilding(
    name: "College Of Law Cafeteria",
    coordinates: const LatLng(6.744761, 5.404791),
    entrance: const LatLng(6.744781, 5.404691), // Front entrance
    category: BuildingCategory.dining,
    description: "Cafeteria serving meals and snacks",
    openingHours: "Mon-Fri: 7:00 AM - 7:00 PM",
    amenities: ["Hot Meals", "Snacks", "Beverages"],
  ),
  CampusBuilding(
    name: "School Of PostGraduate Studies",
    coordinates: const LatLng(6.744675, 5.405681),
    entrance: const LatLng(6.744695, 5.405581), // South entrance
    category: BuildingCategory.academic,
    description: "Graduate programs and research facilities",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
  ),
  CampusBuilding(
    name: "Dean Of Student Affairs",
    coordinates: const LatLng(6.743927, 5.405995),
    entrance: const LatLng(6.743947, 5.405895), // Front entrance
    category: BuildingCategory.student_services,
    description: "Student affairs office for guidance and support",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
    amenities: ["Counseling", "Student IDs", "Support Services"],
  ),
  CampusBuilding(
    name: "Admissions Office",
    coordinates: const LatLng(6.744034, 5.405815),
    entrance: const LatLng(6.744054, 5.405715), // Main entrance
    category: BuildingCategory.administrative,
    description: "Admissions and registration services",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
    amenities: ["Application Processing", "Information Desk"],
  ),
  CampusBuilding(
    name: "Information & Communication Technology",
    coordinates: const LatLng(6.743578, 5.405952),
    entrance: const LatLng(6.743598, 5.405852), // Front door
    category: BuildingCategory.administrative,
    description: "IT support and computer services",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
    amenities: ["Computer Lab", "IT Support", "Wi-Fi"],
  ),
  CampusBuilding(
    name: "Vice Chancellors Building",
    coordinates: const LatLng(6.743066, 5.406475),
    entrance: const LatLng(6.743086, 5.406375), // Main entrance
    category: BuildingCategory.administrative,
    description: "Office of the Vice Chancellor",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
  ),
  CampusBuilding(
    name: "EPS Office",
    coordinates: const LatLng(6.743044, 5.407167),
    entrance: const LatLng(6.743064, 5.407067), // Front entrance
    category: BuildingCategory.administrative,
    description: "Examination and Postgraduate Studies office",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
  ),
  CampusBuilding(
    name: "College Of Arts & Social Sciences",
    coordinates: const LatLng(6.742358, 5.406379),
    entrance: const LatLng(6.742378, 5.406279), // Main entrance
    category: BuildingCategory.academic,
    description: "Faculty of Arts and Social Sciences",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
    amenities: ["Lecture Halls", "Seminar Rooms", "Labs"],
  ),
  CampusBuilding(
    name: "College Of Engineering",
    coordinates: const LatLng(6.741461, 5.406762),
    entrance: const LatLng(6.741481, 5.406662), // Main entrance south
    category: BuildingCategory.academic,
    description: "Engineering faculty with labs and workshops",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
    amenities: ["Engineering Labs", "Workshops", "Computer Lab"],
  ),
  CampusBuilding(
    name: "College Of Natural And Applied Science",
    coordinates: const LatLng(6.740969, 5.405791),
    entrance: const LatLng(6.740989, 5.405691), // Front entrance
    category: BuildingCategory.academic,
    description: "Science faculty with laboratories",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
    amenities: ["Science Labs", "Research Facilities"],
  ),
  CampusBuilding(
    name: "College Of Business & Management Studies",
    coordinates: const LatLng(6.740580, 5.404901),
    entrance: const LatLng(6.740600, 5.404801), // Main entrance
    category: BuildingCategory.academic,
    description: "Business and management faculty",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
    amenities: ["Lecture Halls", "Computer Lab", "Library"],
  ),
  CampusBuilding(
    name: "Chemistry Laboratory",
    coordinates: const LatLng(6.742010, 5.403771),
    entrance: const LatLng(6.742030, 5.403671), // Lab entrance
    category: BuildingCategory.research,
    description: "Chemistry research and teaching laboratory",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
    amenities: ["Lab Equipment", "Safety Equipment"],
  ),
  CampusBuilding(
    name: "Mini Stadium",
    coordinates: const LatLng(6.742558, 5.404828),
    entrance: const LatLng(6.742578, 5.404728), // Main gate
    category: BuildingCategory.sports,
    description: "Sports facility for athletics and events",
    openingHours: "Mon-Sat: 6:00 AM - 8:00 PM",
    amenities: ["Track", "Field", "Stands"],
  ),
  CampusBuilding(
    name: "Access Bank",
    coordinates: const LatLng(6.739618, 5.406319),
    entrance: const LatLng(6.739638, 5.406219), // Bank entrance
    category: BuildingCategory.banking,
    description: "On-campus banking services",
    openingHours: "Mon-Fri: 9:00 AM - 4:00 PM",
    amenities: ["ATM", "Teller Services"],
  ),
  CampusBuilding(
    name: "Student Cafe",
    coordinates: const LatLng(6.739983, 5.406035),
    entrance: const LatLng(6.740003, 5.405935), // Cafe entrance
    category: BuildingCategory.dining,
    description: "Student cafeteria and lounge",
    openingHours: "Mon-Sat: 7:00 AM - 8:00 PM",
    amenities: ["Meals", "Snacks", "Wi-Fi", "Seating Area"],
  ),
  CampusBuilding(
    name: "Zenith Bank",
    coordinates: const LatLng(6.738223, 5.405408),
    entrance: const LatLng(6.738243, 5.405308), // Bank entrance
    category: BuildingCategory.banking,
    description: "Banking services and ATM",
    openingHours: "Mon-Fri: 9:00 AM - 4:00 PM",
    amenities: ["ATM", "Banking Services"],
  ),
];
