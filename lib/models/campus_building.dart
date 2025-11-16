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
  final LatLng coordinates;
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
    category: BuildingCategory.administrative,
    description: "Igbinedion University Okada Main Administrative Building",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
    amenities: ["Reception", "Admin Offices", "Meeting Rooms"],
  ),
  CampusBuilding(
    name: "College of Law",
    coordinates: const LatLng(6.744662, 5.404184),
    category: BuildingCategory.academic,
    description: "Faculty of Law with lecture halls and offices",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
    amenities: ["Lecture Halls", "Library", "Moot Court"],
  ),
  CampusBuilding(
    name: "College of Law Administrative Building",
    coordinates: const LatLng(6.744669, 5.403144),
    category: BuildingCategory.administrative,
    description: "Administrative offices for the College of Law",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
  ),
  CampusBuilding(
    name: "Igbinedion University Library",
    coordinates: const LatLng(6.741228, 5.403294),
    category: BuildingCategory.library,
    description: "Main university library with extensive collections",
    openingHours: "Mon-Sat: 8:00 AM - 10:00 PM",
    amenities: ["Study Rooms", "Computer Lab", "Reading Areas", "Wi-Fi"],
  ),
  CampusBuilding(
    name: "Buratai Center For Contemporary Security Affairs",
    coordinates: const LatLng(6.745408, 5.404163),
    category: BuildingCategory.research,
    description: "Research center for security and defense studies",
    openingHours: "Mon-Fri: 9:00 AM - 5:00 PM",
  ),
  CampusBuilding(
    name: "Main Auditorium",
    coordinates: const LatLng(6.743634, 5.404211),
    category: BuildingCategory.academic,
    description: "Large auditorium for events and ceremonies",
    amenities: ["Seating for 500+", "Stage", "Sound System"],
  ),
  CampusBuilding(
    name: "College Of Law Cafeteria",
    coordinates: const LatLng(6.744761, 5.404791),
    category: BuildingCategory.dining,
    description: "Cafeteria serving meals and snacks",
    openingHours: "Mon-Fri: 7:00 AM - 7:00 PM",
    amenities: ["Hot Meals", "Snacks", "Beverages"],
  ),
  CampusBuilding(
    name: "School Of PostGraduate Studies",
    coordinates: const LatLng(6.744675, 5.405681),
    category: BuildingCategory.academic,
    description: "Graduate programs and research facilities",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
  ),
  CampusBuilding(
    name: "Dean Of Student Affairs",
    coordinates: const LatLng(6.743927, 5.405995),
    category: BuildingCategory.student_services,
    description: "Student affairs office for guidance and support",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
    amenities: ["Counseling", "Student IDs", "Support Services"],
  ),
  CampusBuilding(
    name: "Admissions Office",
    coordinates: const LatLng(6.744034, 5.405815),
    category: BuildingCategory.administrative,
    description: "Admissions and registration services",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
    amenities: ["Application Processing", "Information Desk"],
  ),
  CampusBuilding(
    name: "Information & Communication Technology",
    coordinates: const LatLng(6.743578, 5.405952),
    category: BuildingCategory.administrative,
    description: "IT support and computer services",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
    amenities: ["Computer Lab", "IT Support", "Wi-Fi"],
  ),
  CampusBuilding(
    name: "Vice Chancellors Building",
    coordinates: const LatLng(6.743066, 5.406475),
    category: BuildingCategory.administrative,
    description: "Office of the Vice Chancellor",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
  ),
  CampusBuilding(
    name: "EPS Office",
    coordinates: const LatLng(6.743044, 5.407167),
    category: BuildingCategory.administrative,
    description: "Examination and Postgraduate Studies office",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
  ),
  CampusBuilding(
    name: "College Of Arts & Social Sciences",
    coordinates: const LatLng(6.742358, 5.406379),
    category: BuildingCategory.academic,
    description: "Faculty of Arts and Social Sciences",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
    amenities: ["Lecture Halls", "Seminar Rooms", "Labs"],
  ),
  CampusBuilding(
    name: "College Of Engineering",
    coordinates: const LatLng(6.741461, 5.406762),
    category: BuildingCategory.academic,
    description: "Engineering faculty with labs and workshops",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
    amenities: ["Engineering Labs", "Workshops", "Computer Lab"],
  ),
  CampusBuilding(
    name: "College Of Natural And Applied Science",
    coordinates: const LatLng(6.740969, 5.405791),
    category: BuildingCategory.academic,
    description: "Science faculty with laboratories",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
    amenities: ["Science Labs", "Research Facilities"],
  ),
  CampusBuilding(
    name: "College Of Business & Management Studies",
    coordinates: const LatLng(6.740580, 5.404901),
    category: BuildingCategory.academic,
    description: "Business and management faculty",
    openingHours: "Mon-Fri: 8:00 AM - 6:00 PM",
    amenities: ["Lecture Halls", "Computer Lab", "Library"],
  ),
  CampusBuilding(
    name: "Chemistry Laboratory",
    coordinates: const LatLng(6.742010, 5.403771),
    category: BuildingCategory.research,
    description: "Chemistry research and teaching laboratory",
    openingHours: "Mon-Fri: 8:00 AM - 5:00 PM",
    amenities: ["Lab Equipment", "Safety Equipment"],
  ),
  CampusBuilding(
    name: "Mini Stadium",
    coordinates: const LatLng(6.742558, 5.404828),
    category: BuildingCategory.sports,
    description: "Sports facility for athletics and events",
    openingHours: "Mon-Sat: 6:00 AM - 8:00 PM",
    amenities: ["Track", "Field", "Stands"],
  ),
  CampusBuilding(
    name: "Access Bank",
    coordinates: const LatLng(6.739618, 5.406319),
    category: BuildingCategory.banking,
    description: "On-campus banking services",
    openingHours: "Mon-Fri: 9:00 AM - 4:00 PM",
    amenities: ["ATM", "Teller Services"],
  ),
  CampusBuilding(
    name: "Student Cafe",
    coordinates: const LatLng(6.739983, 5.406035),
    category: BuildingCategory.dining,
    description: "Student cafeteria and lounge",
    openingHours: "Mon-Sat: 7:00 AM - 8:00 PM",
    amenities: ["Meals", "Snacks", "Wi-Fi", "Seating Area"],
  ),
  CampusBuilding(
    name: "Zenith Bank",
    coordinates: const LatLng(6.738223, 5.405408),
    category: BuildingCategory.banking,
    description: "Banking services and ATM",
    openingHours: "Mon-Fri: 9:00 AM - 4:00 PM",
    amenities: ["ATM", "Banking Services"],
  ),
];
