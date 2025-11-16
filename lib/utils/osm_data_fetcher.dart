// Utility to fetch building data from OpenStreetMap
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/campus_building.dart';

class OSMDataFetcher {
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';
  
  // Fetch all buildings in campus area from OSM
  static Future<List<CampusBuilding>> fetchCampusBuildings() async {
    const campusCenter = LatLng(6.7415, 5.4055);
    const radius = 0.01; // ~1km radius
    
    final query = '''
[out:json][bbox:${campusCenter.latitude - radius},${campusCenter.longitude - radius},${campusCenter.latitude + radius},${campusCenter.longitude + radius}];
(
  node["amenity"~"university|college|school|library|bank|restaurant|cafe|clinic|hospital"];
  way["amenity"~"university|college|school|library|bank|restaurant|cafe|clinic|hospital"];
  relation["amenity"~"university|college|school|library|bank|restaurant|cafe|clinic|hospital"];
  
  node["building"~"university|college|school|library|commercial|public"];
  way["building"~"university|college|school|library|commercial|public"];
  
  node["leisure"~"sports_centre|stadium|pitch"];
  way["leisure"~"sports_centre|stadium|pitch"];
  
  node["name"]["building"];
  way["name"]["building"];
);
out center;
out tags;
''';

    try {
      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;
        
        List<CampusBuilding> buildings = [];
        
        for (var element in elements) {
          final tags = element['tags'] as Map<String, dynamic>?;
          if (tags == null || tags['name'] == null) continue;
          
          // Get coordinates
          double lat, lon;
          if (element['lat'] != null && element['lon'] != null) {
            lat = element['lat'];
            lon = element['lon'];
          } else if (element['center'] != null) {
            lat = element['center']['lat'];
            lon = element['center']['lon'];
          } else {
            continue;
          }
          
          // Determine category
          BuildingCategory category = _determineCategory(tags);
          
          // Extract amenities
          List<String> amenities = _extractAmenities(tags);
          
          buildings.add(CampusBuilding(
            name: tags['name'],
            coordinates: LatLng(lat, lon),
            category: category,
            description: tags['description'] ?? _generateDescription(tags),
            openingHours: tags['opening_hours'],
            amenities: amenities.isNotEmpty ? amenities : null,
            phoneNumber: tags['phone'] ?? tags['contact:phone'],
            website: tags['website'] ?? tags['contact:website'],
            email: tags['email'] ?? tags['contact:email'],
            capacity: _parseCapacity(tags['capacity']),
            buildingType: tags['building'],
          ));
        }
        
        return buildings;
      }
    } catch (e) {
      print('Error fetching OSM data: $e');
    }
    
    return [];
  }
  
  static BuildingCategory _determineCategory(Map<String, dynamic> tags) {
    final amenity = tags['amenity']?.toString().toLowerCase();
    final building = tags['building']?.toString().toLowerCase();
    final leisure = tags['leisure']?.toString().toLowerCase();
    
    // Check amenity first
    if (amenity != null) {
      if (amenity.contains('university') || amenity.contains('college') || amenity.contains('school')) {
        return BuildingCategory.academic;
      }
      if (amenity.contains('library')) return BuildingCategory.library;
      if (amenity.contains('bank')) return BuildingCategory.banking;
      if (amenity.contains('restaurant') || amenity.contains('cafe') || amenity.contains('food')) {
        return BuildingCategory.dining;
      }
      if (amenity.contains('clinic') || amenity.contains('hospital') || amenity.contains('health')) {
        return BuildingCategory.health;
      }
    }
    
    // Check building type
    if (building != null) {
      if (building.contains('university') || building.contains('college') || building.contains('school')) {
        return BuildingCategory.academic;
      }
      if (building.contains('library')) return BuildingCategory.library;
      if (building.contains('commercial')) return BuildingCategory.administrative;
      if (building.contains('public')) return BuildingCategory.administrative;
      if (building.contains('residential') || building.contains('dormitory')) {
        return BuildingCategory.residential;
      }
      if (building.contains('church') || building.contains('mosque') || building.contains('chapel')) {
        return BuildingCategory.worship;
      }
    }
    
    // Check leisure
    if (leisure != null) {
      if (leisure.contains('sport') || leisure.contains('stadium') || leisure.contains('pitch')) {
        return BuildingCategory.sports;
      }
    }
    
    // Check name patterns
    final name = tags['name']?.toString().toLowerCase() ?? '';
    if (name.contains('law') || name.contains('engineering') || name.contains('science') || 
        name.contains('business') || name.contains('arts') || name.contains('college')) {
      return BuildingCategory.academic;
    }
    if (name.contains('admin') || name.contains('vice') || name.contains('dean') || name.contains('office')) {
      return BuildingCategory.administrative;
    }
    if (name.contains('library')) return BuildingCategory.library;
    if (name.contains('cafe') || name.contains('cafeteria') || name.contains('restaurant')) {
      return BuildingCategory.dining;
    }
    if (name.contains('bank')) return BuildingCategory.banking;
    if (name.contains('sport') || name.contains('stadium') || name.contains('gym')) {
      return BuildingCategory.sports;
    }
    if (name.contains('student') || name.contains('affairs')) {
      return BuildingCategory.student_services;
    }
    if (name.contains('research') || name.contains('lab')) {
      return BuildingCategory.research;
    }
    if (name.contains('health') || name.contains('clinic') || name.contains('medical')) {
      return BuildingCategory.health;
    }
    if (name.contains('hostel') || name.contains('dormitory') || name.contains('residence')) {
      return BuildingCategory.residential;
    }
    if (name.contains('chapel') || name.contains('church') || name.contains('mosque')) {
      return BuildingCategory.worship;
    }
    
    return BuildingCategory.administrative;
  }
  
  static List<String> _extractAmenities(Map<String, dynamic> tags) {
    List<String> amenities = [];
    
    if (tags['internet_access'] == 'yes' || tags['wifi'] == 'yes') {
      amenities.add('Wi-Fi');
    }
    if (tags['wheelchair'] == 'yes') {
      amenities.add('Wheelchair Accessible');
    }
    if (tags['air_conditioning'] == 'yes') {
      amenities.add('Air Conditioning');
    }
    if (tags['parking'] == 'yes') {
      amenities.add('Parking');
    }
    if (tags['toilets'] == 'yes') {
      amenities.add('Restrooms');
    }
    
    // Category-specific amenities
    final amenity = tags['amenity']?.toString();
    if (amenity == 'library') {
      amenities.addAll(['Study Areas', 'Computer Lab', 'Reading Rooms']);
    }
    if (amenity == 'restaurant' || amenity == 'cafe') {
      amenities.addAll(['Seating Area', 'Takeout']);
    }
    if (amenity == 'bank') {
      amenities.addAll(['ATM', 'Teller Services']);
    }
    
    return amenities;
  }
  
  static String _generateDescription(Map<String, dynamic> tags) {
    final amenity = tags['amenity'];
    final building = tags['building'];
    
    if (amenity != null) {
      switch (amenity) {
        case 'university':
        case 'college':
          return 'Academic institution with educational facilities';
        case 'library':
          return 'Library with study areas and book collections';
        case 'bank':
          return 'Banking services and financial transactions';
        case 'restaurant':
        case 'cafe':
          return 'Food and beverage services';
        case 'clinic':
        case 'hospital':
          return 'Healthcare and medical services';
        default:
          return 'Campus facility';
      }
    }
    
    if (building == 'university' || building == 'college') {
      return 'University building with classrooms and offices';
    }
    
    return 'Campus building';
  }
  
  static int? _parseCapacity(dynamic capacity) {
    if (capacity == null) return null;
    try {
      return int.parse(capacity.toString());
    } catch (e) {
      return null;
    }
  }
  
  // Fetch detailed info for a specific building
  static Future<Map<String, dynamic>?> fetchBuildingDetails(LatLng location) async {
    final query = '''
[out:json];
(
  node(around:50,${location.latitude},${location.longitude});
  way(around:50,${location.latitude},${location.longitude});
);
out body;
out tags;
''';

    try {
      final response = await http.post(
        Uri.parse(overpassUrl),
        body: query,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;
        
        if (elements.isNotEmpty) {
          return elements.first['tags'] as Map<String, dynamic>?;
        }
      }
    } catch (e) {
      print('Error fetching building details: $e');
    }
    
    return null;
  }
}
