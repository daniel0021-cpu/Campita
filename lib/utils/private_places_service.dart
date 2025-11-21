import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/private_place.dart';

/// Service for managing user's private places list with reminders
class PrivatePlacesService {
  static const String _privatePlacesKey = 'private_places_list';
  
  /// Load all private places from storage
  Future<List<PrivatePlace>> loadPrivatePlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_privatePlacesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => PrivatePlace.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading private places: $e');
      return [];
    }
  }
  
  /// Save private places to storage
  Future<bool> savePrivatePlaces(List<PrivatePlace> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = places.map((place) => place.toJson()).toList();
      final jsonString = json.encode(jsonList);
      return await prefs.setString(_privatePlacesKey, jsonString);
    } catch (e) {
      debugPrint('Error saving private places: $e');
      return false;
    }
  }
  
  /// Add a new private place
  Future<bool> addPrivatePlace(PrivatePlace place) async {
    final places = await loadPrivatePlaces();
    places.add(place);
    return await savePrivatePlaces(places);
  }
  
  /// Remove a private place by ID
  Future<bool> removePrivatePlace(String placeId) async {
    final places = await loadPrivatePlaces();
    places.removeWhere((place) => place.id == placeId);
    return await savePrivatePlaces(places);
  }
  
  /// Update a private place
  Future<bool> updatePrivatePlace(PrivatePlace updatedPlace) async {
    final places = await loadPrivatePlaces();
    final index = places.indexWhere((place) => place.id == updatedPlace.id);
    
    if (index != -1) {
      places[index] = updatedPlace;
      return await savePrivatePlaces(places);
    }
    
    return false;
  }
  
  /// Mark a place as visited
  Future<bool> markAsVisited(String placeId) async {
    final places = await loadPrivatePlaces();
    final index = places.indexWhere((place) => place.id == placeId);
    
    if (index != -1) {
      places[index] = places[index].copyWith(
        isVisited: true,
        visitedAt: DateTime.now(),
      );
      return await savePrivatePlaces(places);
    }
    
    return false;
  }
  
  /// Get upcoming reminders (within next 24 hours)
  Future<List<PrivatePlace>> getUpcomingReminders() async {
    final places = await loadPrivatePlaces();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(hours: 24));
    
    return places.where((place) {
      if (!place.reminderEnabled || place.reminderTime == null || place.isVisited) {
        return false;
      }
      return place.reminderTime!.isAfter(now) && 
             place.reminderTime!.isBefore(tomorrow);
    }).toList();
  }
  
  /// Get places by category
  Future<List<PrivatePlace>> getPlacesByCategory(String category) async {
    final places = await loadPrivatePlaces();
    return places.where((place) => place.category == category).toList();
  }
  
  /// Clear all private places
  Future<bool> clearAllPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_privatePlacesKey);
  }
}

