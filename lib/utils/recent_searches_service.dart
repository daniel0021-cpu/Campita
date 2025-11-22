import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Recent Searches Service - Google Maps Style
/// 
/// Key Features:
/// - Only saves FULL queries (no partial typing like "F", "Fe", "Fem")
/// - Filters using prefix match (startsWith) + contains match
/// - Ranks by: prefix match → frequency → recency → contains match
/// - Stores query, timestamp, frequency
/// - Max 50 searches stored, shows top 5
class RecentSearchesService {
  static const String _key = 'recent_searches_v2';
  static const int _maxStored = 50;
  static const int _maxDisplayed = 5;
  
  /// Save a completed search query (ONLY when user selects a result)
  /// Never call this for partial typing - only full selections
  static Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final searches = await _getSearches();
    
    // Find existing or create new
    final existing = searches.firstWhere(
      (s) => s.query.toLowerCase() == query.trim().toLowerCase(),
      orElse: () => SearchRecord(
        query: query.trim(),
        timestamp: DateTime.now(),
        frequency: 0,
      ),
    );
    
    // Update frequency and timestamp
    final updated = SearchRecord(
      query: existing.query,
      timestamp: DateTime.now(),
      frequency: existing.frequency + 1,
    );
    
    // Remove old entry if exists
    searches.removeWhere((s) => s.query.toLowerCase() == query.trim().toLowerCase());
    
    // Add to front
    searches.insert(0, updated);
    
    // Limit to max stored
    if (searches.length > _maxStored) {
      searches.removeRange(_maxStored, searches.length);
    }
    
    // Save
    final encoded = searches.map((s) => s.toJson()).toList();
    await prefs.setString(_key, jsonEncode(encoded));
  }
  
  /// Filter recent searches as user types
  /// Returns max 5 results sorted by:
  /// 1. Prefix match (startsWith) first
  /// 2. Frequency (higher = better)
  /// 3. Recency (newer = better)
  /// 4. Contains match
  static Future<List<SearchRecord>> filterSearches(String query) async {
    if (query.trim().isEmpty) {
      // Return recent 5 when search is empty
      final all = await _getSearches();
      return all.take(_maxDisplayed).toList();
    }
    
    final searches = await _getSearches();
    final lowerQuery = query.trim().toLowerCase();
    
    // Separate into prefix matches and contains matches
    final prefixMatches = <SearchRecord>[];
    final containsMatches = <SearchRecord>[];
    
    for (final search in searches) {
      final lowerSearch = search.query.toLowerCase();
      if (lowerSearch.startsWith(lowerQuery)) {
        prefixMatches.add(search);
      } else if (lowerSearch.contains(lowerQuery)) {
        containsMatches.add(search);
      }
    }
    
    // Sort prefix matches by frequency → recency
    prefixMatches.sort((a, b) {
      final freqCompare = b.frequency.compareTo(a.frequency);
      if (freqCompare != 0) return freqCompare;
      return b.timestamp.compareTo(a.timestamp);
    });
    
    // Sort contains matches by frequency → recency
    containsMatches.sort((a, b) {
      final freqCompare = b.frequency.compareTo(a.frequency);
      if (freqCompare != 0) return freqCompare;
      return b.timestamp.compareTo(a.timestamp);
    });
    
    // Combine: prefix first, then contains, limit to max displayed
    final combined = [...prefixMatches, ...containsMatches];
    return combined.take(_maxDisplayed).toList();
  }
  
  /// Get all recent searches (sorted by recency)
  static Future<List<SearchRecord>> _getSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr == null) return [];
      
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((json) => SearchRecord.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Clear all recent searches
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
  
  /// Remove a single search
  static Future<void> removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await _getSearches();
    searches.removeWhere((s) => s.query.toLowerCase() == query.toLowerCase());
    
    final encoded = searches.map((s) => s.toJson()).toList();
    await prefs.setString(_key, jsonEncode(encoded));
  }
}

/// Individual search record with metadata
class SearchRecord {
  final String query;
  final DateTime timestamp;
  final int frequency;
  
  SearchRecord({
    required this.query,
    required this.timestamp,
    required this.frequency,
  });
  
  Map<String, dynamic> toJson() => {
    'query': query,
    'timestamp': timestamp.toIso8601String(),
    'frequency': frequency,
  };
  
  factory SearchRecord.fromJson(Map<String, dynamic> json) => SearchRecord(
    query: json['query'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    frequency: json['frequency'] as int,
  );
}
