import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/campus_event.dart';

/// Service to manage and fetch live campus events
class LiveEventsService extends ChangeNotifier {
  static final LiveEventsService _instance = LiveEventsService._internal();
  factory LiveEventsService() => _instance;
  LiveEventsService._internal();

  List<CampusEvent> _allEvents = [];
  List<CampusEvent> _liveEvents = [];
  Timer? _refreshTimer;

  List<CampusEvent> get allEvents => _allEvents;
  List<CampusEvent> get liveEvents => _liveEvents;

  bool get hasLiveEvents => _liveEvents.isNotEmpty;

  /// Initialize the service and start periodic updates
  void initialize() {
    _loadEvents();
    _startAutoRefresh();
  }

  /// Load events from data source (mock data for now, replace with API call)
  void _loadEvents() {
    _allEvents = List.from(sampleEvents);
    _updateLiveEvents();
    notifyListeners();
  }

  /// Update which events are currently live
  void _updateLiveEvents() {
    final now = DateTime.now();
    _liveEvents = _allEvents.where((event) {
      return event.isHappening && event.isUpcoming;
    }).toList();

    // Sort by priority: featured first, then by start time
    _liveEvents.sort((a, b) {
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      return a.startTime.compareTo(b.startTime);
    });

    debugPrint('🎉 Live Events Updated: ${_liveEvents.length} events');
  }

  /// Start automatic refresh every minute
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateLiveEvents();
      notifyListeners();
    });
  }

  /// Manually refresh events (call when returning to foreground)
  Future<void> refresh() async {
    // TODO: Replace with actual API call
    // final response = await http.get(Uri.parse('YOUR_API_ENDPOINT/events'));
    // final data = jsonDecode(response.body);
    // _allEvents = (data as List).map((json) => CampusEvent.fromJson(json)).toList();
    
    _loadEvents();
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
  }

  /// Add a new live event (for admin/organizer functionality)
  void addEvent(CampusEvent event) {
    _allEvents.add(event);
    _updateLiveEvents();
    notifyListeners();
  }

  /// Remove an event
  void removeEvent(String eventId) {
    _allEvents.removeWhere((event) => event.id == eventId);
    _updateLiveEvents();
    notifyListeners();
  }

  /// Get events happening today
  List<CampusEvent> get todayEvents {
    return _allEvents.where((event) => event.isToday).toList();
  }

  /// Get upcoming events (next 7 days)
  List<CampusEvent> get upcomingEvents {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return _allEvents.where((event) {
      return event.isUpcoming && 
             event.startTime.isAfter(now) && 
             event.startTime.isBefore(nextWeek);
    }).toList();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
