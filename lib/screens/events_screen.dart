import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../widgets/animated_success_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<CampusEvent> _upcomingEvents = _sampleUpcomingEvents;
  final List<CampusEvent> _activeEvents = _sampleActiveEvents;
  final List<CampusEvent> _pastEvents = _samplePastEvents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkGrey : AppColors.ash,
      appBar: AppBar(
        title: Text(
          'Campus Events',
          style: AppTextStyles.heading2.copyWith(
            color: isDark ? AppColors.white : AppColors.darkGrey,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkGrey : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.white : AppColors.darkGrey,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: isDark ? AppColors.darkGrey : Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.grey : AppColors.darkGrey.withOpacity(0.6),
              labelStyle: GoogleFonts.notoSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Active'),
                Tab(text: 'Past'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRefreshableEventsList(_upcomingEvents, eventType: 'upcoming'),
          _buildRefreshableEventsList(_activeEvents, eventType: 'active'),
          _buildRefreshableEventsList(_pastEvents, eventType: 'past'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Event',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshableEventsList(List<CampusEvent> events, {required String eventType}) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) setState(() {});
      },
      color: AppColors.primary,
      child: _buildEventsList(events, eventType: eventType),
    );
  }

  Widget _buildEventsList(List<CampusEvent> events, {required String eventType}) {
    if (events.isEmpty) {
      return _buildEmptyState(eventType);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _AnimatedEventCard(
          event: event,
          eventType: eventType,
          index: index,
        );
      },
    );
  }

  Widget _buildEmptyState(String eventType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String title, message;
    IconData icon;
    
    switch (eventType) {
      case 'upcoming':
        title = 'No Upcoming Events';
        message = 'Check back later for upcoming campus events and activities';
        icon = Icons.event_available;
        break;
      case 'active':
        title = 'No Active Events';
        message = 'Active events happening now will appear here';
        icon = Icons.event_note_rounded;
        break;
      case 'past':
        title = 'No Past Events';
        message = 'Past events will appear here once they\'re completed';
        icon = Icons.history;
        break;
      default:
        title = 'No Events';
        message = 'No events to display';
        icon = Icons.event;
    }
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 15,
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      )..forward(),
      builder: (context) => _AddEventSheet(
        onEventAdded: (CampusEvent event) {
          setState(() {
            // Add event to appropriate list
            if (event.dateTime.isAfter(DateTime.now())) {
              _upcomingEvents.insert(0, event);
            } else {
              _activeEvents.insert(0, event);
            }
          });
        },
      ),
    );
  }

  void _showEventDetailSheet(BuildContext context, CampusEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _EventDetailSheet(event: event),
    );
  }

  Widget _buildEventCard(CampusEvent event, String eventType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackground(context) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? AppColors.borderAdaptive(context).withOpacity(0.2)
              : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEventDetails(event),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image/Header
              if (event.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    event.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            event.categoryColor.withOpacity(0.8),
                            event.categoryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          event.categoryIcon,
                          size: 60,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [
                        event.categoryColor.withOpacity(0.8),
                        event.categoryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      event.categoryIcon,
                      size: 60,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              
              // Event Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: event.categoryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.category,
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: event.categoryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Event Title
                    Text(
                      event.title,
                      style: GoogleFonts.notoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Date and Time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isDark ? AppColors.grey : AppColors.darkGrey.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(event.dateTime),
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: isDark ? AppColors.grey : AppColors.darkGrey.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isDark ? AppColors.grey : AppColors.darkGrey.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.location,
                            style: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: isDark ? AppColors.grey : AppColors.darkGrey.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      event.description,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: isDark ? AppColors.grey : AppColors.grey,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Action Buttons
                    if (eventType == 'upcoming') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Navigate to event location
                                showAnimatedSuccess(
                                  context,
                                  'Navigating to ${event.location}',
                                  icon: Icons.directions_rounded,
                                  iconColor: AppColors.primary,
                                );
                              },
                              icon: const Icon(Icons.directions, size: 18),
                              label: const Text('Directions'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // TODO: RSVP functionality
                                showAnimatedSuccess(
                                  context,
                                  'RSVP for ${event.title}',
                                  icon: Icons.event_available_rounded,
                                  iconColor: AppColors.success,
                                );
                              },
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('RSVP'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEventDetails(CampusEvent event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: Navigator.of(context),
      )..forward(),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardBackground(context) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                // Event Image
                if (event.imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.asset(
                      event.imageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              event.categoryColor.withOpacity(0.8),
                              event.categoryColor,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            event.categoryIcon,
                            size: 80,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          event.categoryColor.withOpacity(0.8),
                          event.categoryColor,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        event.categoryIcon,
                        size: 80,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: event.categoryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category,
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: event.categoryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      Text(
                        event.title,
                        style: GoogleFonts.notoSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Details
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date & Time',
                        DateFormat('EEEE, MMMM dd, yyyy\nhh:mm a').format(event.dateTime),
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.location_on,
                        'Location',
                        event.location,
                        isDark,
                      ),
                      if (event.organizer != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.person,
                          'Organizer',
                          event.organizer!,
                          isDark,
                        ),
                      ],
                      const SizedBox(height: 24),
                      
                      // Description
                      Text(
                        'About',
                        style: GoogleFonts.notoSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : AppColors.darkGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.description,
                        style: GoogleFonts.notoSans(
                          fontSize: 15,
                          color: isDark ? AppColors.grey : AppColors.grey,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // TODO: Navigate to location
                              },
                              icon: const Icon(Icons.directions, size: 20),
                              label: const Text('Get Directions'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                // TODO: RSVP
                              },
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text('RSVP'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.grey : AppColors.darkGrey.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.white : AppColors.darkGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Event Model
class CampusEvent {
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String category;
  final Color categoryColor;
  final IconData categoryIcon;
  final String? imageUrl;
  final String? organizer;

  CampusEvent({
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.category,
    required this.categoryColor,
    required this.categoryIcon,
    this.imageUrl,
    this.organizer,
  });
}

// Sample Data
final List<CampusEvent> _sampleUpcomingEvents = [
  CampusEvent(
    title: 'Annual Convocation Ceremony',
    description: 'Join us for the 2024 convocation ceremony celebrating our graduating class. The event will feature speeches from distinguished guests, award presentations, and a formal dinner reception.',
    dateTime: DateTime.now().add(const Duration(days: 15)),
    location: 'Main Auditorium',
    category: 'Academic',
    categoryColor: const Color(0xFF4CAF50),
    categoryIcon: Icons.school,
    organizer: 'Academic Affairs Office',
  ),
  CampusEvent(
    title: 'Inter-Faculty Sports Competition',
    description: 'Annual sports meet featuring football, basketball, athletics, and more. All students are welcome to participate or cheer for their faculties. Exciting prizes await winners!',
    dateTime: DateTime.now().add(const Duration(days: 7)),
    location: 'Sports Complex',
    category: 'Sports',
    categoryColor: const Color(0xFFFF9800),
    categoryIcon: Icons.sports_soccer,
    organizer: 'Sports & Recreation Department',
  ),
  CampusEvent(
    title: 'Tech Innovation Summit 2024',
    description: 'A showcase of student innovations and tech projects. Network with industry professionals, attend workshops on emerging technologies, and witness groundbreaking student innovations.',
    dateTime: DateTime.now().add(const Duration(days: 21)),
    location: 'ICT Building Auditorium',
    category: 'Technology',
    categoryColor: const Color(0xFF2196F3),
    categoryIcon: Icons.computer,
    organizer: 'Department of Computer Science',
  ),
  CampusEvent(
    title: 'Cultural Festival',
    description: 'Celebrate diversity through music, dance, art exhibitions, and cultural displays from various regions. Food stalls, performances, and traditional attire showcase.',
    dateTime: DateTime.now().add(const Duration(days: 30)),
    location: 'University Grounds',
    category: 'Cultural',
    categoryColor: const Color(0xFFE91E63),
    categoryIcon: Icons.celebration,
    organizer: 'Student Affairs Division',
  ),
  CampusEvent(
    title: 'Career Fair 2024',
    description: 'Connect with top employers and explore career opportunities. Bring your resume, attend company presentations, and participate in on-the-spot interviews.',
    dateTime: DateTime.now().add(const Duration(days: 45)),
    location: 'Main Hall Complex',
    category: 'Career',
    categoryColor: const Color(0xFF9C27B0),
    categoryIcon: Icons.work,
    organizer: 'Career Services Center',
  ),
];

final List<CampusEvent> _sampleActiveEvents = [
  CampusEvent(
    title: 'Library Study Session',
    description: 'Ongoing group study session at the library. Join fellow students for collaborative learning and exam preparation. Quiet zones available.',
    dateTime: DateTime.now(),
    location: 'Main Library - 2nd Floor',
    category: 'Academic',
    categoryColor: const Color(0xFF00BCD4),
    categoryIcon: Icons.menu_book_rounded,
    organizer: 'Library Services',
  ),
  CampusEvent(
    title: 'Cafeteria Special Lunch',
    description: 'Special international cuisine being served today. Multiple food stations featuring dishes from around the world. Limited time offer!',
    dateTime: DateTime.now(),
    location: 'Main Cafeteria',
    category: 'Food',
    categoryColor: const Color(0xFFFF5722),
    categoryIcon: Icons.restaurant_rounded,
    organizer: 'Catering Services',
  ),
];

final List<CampusEvent> _samplePastEvents = [
  CampusEvent(
    title: 'Orientation Week 2024',
    description: 'Welcome program for new students featuring campus tours, departmental introductions, and social activities to help freshmen settle into university life.',
    dateTime: DateTime.now().subtract(const Duration(days: 90)),
    location: 'Various Campus Locations',
    category: 'Academic',
    categoryColor: const Color(0xFF4CAF50),
    categoryIcon: Icons.school,
    organizer: 'Student Affairs Office',
  ),
  CampusEvent(
    title: 'Environmental Awareness Campaign',
    description: 'Tree planting exercise, recycling workshops, and sustainability talks. Students participated in making the campus greener and more environmentally conscious.',
    dateTime: DateTime.now().subtract(const Duration(days: 60)),
    location: 'Campus Grounds',
    category: 'Community',
    categoryColor: const Color(0xFF8BC34A),
    categoryIcon: Icons.eco,
    organizer: 'Environmental Club',
  ),
  CampusEvent(
    title: 'Guest Lecture: Future of AI',
    description: 'Industry expert Dr. Sarah Johnson delivered an insightful lecture on artificial intelligence trends, career prospects, and ethical considerations in AI development.',
    dateTime: DateTime.now().subtract(const Duration(days: 30)),
    location: 'Engineering Building',
    category: 'Technology',
    categoryColor: const Color(0xFF2196F3),
    categoryIcon: Icons.lightbulb,
    organizer: 'Department of Computer Science',
  ),
];

// Animated Event Card Widget
class _AnimatedEventCard extends StatefulWidget {
  final CampusEvent event;
  final String eventType;
  final int index;

  const _AnimatedEventCard({
    required this.event,
    required this.eventType,
    required this.index,
  });

  @override
  State<_AnimatedEventCard> createState() => _AnimatedEventCardState();
}

class _AnimatedEventCardState extends State<_AnimatedEventCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  double _pressScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = widget.eventType == 'active';

    return FadeTransition(
      opacity: _scaleAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressScale = 0.98),
            onTapUp: (_) => setState(() => _pressScale = 1.0),
            onTapCancel: () => setState(() => _pressScale = 1.0),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => _EventDetailSheet(event: widget.event),
              );
            },
            child: AnimatedScale(
              scale: _pressScale,
              duration: const Duration(milliseconds: 100),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardBackground(context) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isActive ? Border.all(
                    color: widget.event.categoryColor,
                    width: 2,
                  ) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with category badge
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: widget.event.categoryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.event.categoryIcon,
                              color: widget.event.categoryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.event.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.white : AppColors.darkGrey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.event.category,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 13,
                                    color: widget.event.categoryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'LIVE',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        widget.event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: AppColors.grey,
                          height: 1.5,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Footer with time and location
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.grey.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM dd, yyyy • h:mm a').format(widget.event.dateTime),
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.event.location,
                              style: GoogleFonts.notoSans(
                                fontSize: 13,
                                color: AppColors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Add Event Sheet - Animated Bottom Sheet
class _AddEventSheet extends StatefulWidget {
  final Function(CampusEvent) onEventAdded;

  const _AddEventSheet({required this.onEventAdded});

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'Academic';
  Color _selectedCategoryColor = const Color(0xFF4CAF50);
  IconData _selectedCategoryIcon = Icons.school_rounded;
  
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  final Map<String, Map<String, dynamic>> _categories = {
    'Academic': {'color': const Color(0xFF4CAF50), 'icon': Icons.school_rounded},
    'Sports': {'color': const Color(0xFFFF9800), 'icon': Icons.sports_basketball_rounded},
    'Cultural': {'color': const Color(0xFF9C27B0), 'icon': Icons.theater_comedy_rounded},
    'Technology': {'color': const Color(0xFF2196F3), 'icon': Icons.computer_rounded},
    'Social': {'color': const Color(0xFFE91E63), 'icon': Icons.group_rounded},
    'Workshop': {'color': const Color(0xFF00BCD4), 'icon': Icons.build_rounded},
  };
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.19, 1.0, 0.22, 1.0), // Smooth deceleration
    );
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0), // Spring bounce
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _controller.forward();
  }
  
  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedCategoryColor = _categories[category]!['color'];
      _selectedCategoryIcon = _categories[category]!['icon'];
    });
  }
  
  void _submitEvent() {
    if (_titleController.text.isEmpty) {
      showAnimatedSuccess(
        context,
        'Please enter an event title',
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
      );
      return;
    }
    
    final DateTime eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    final newEvent = CampusEvent(
      title: _titleController.text,
      description: _descriptionController.text.isEmpty 
          ? 'Join us for this exciting campus event!'
          : _descriptionController.text,
      dateTime: eventDateTime,
      location: _locationController.text.isEmpty 
          ? 'Campus Venue'
          : _locationController.text,
      category: _selectedCategory,
      categoryColor: _selectedCategoryColor,
      categoryIcon: _selectedCategoryIcon,
      organizer: 'Student Activities',
    );
    
    widget.onEventAdded(newEvent);
    Navigator.pop(context);
    
    showAnimatedSuccess(
      context,
      'Event created successfully! 🎉',
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 150),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Event',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.darkGrey,
                                ),
                              ),
                              Text(
                                'Share your event with the campus',
                                style: GoogleFonts.notoSans(
                                  fontSize: 13,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Event Title
                    Text(
                      'Event Title *',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter event name',
                        filled: true,
                        fillColor: isDark 
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.grey.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.event_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Category Selection
                    Text(
                      'Category',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _categories.entries.map((entry) {
                        final isSelected = _selectedCategory == entry.key;
                        return GestureDetector(
                          onTap: () => _selectCategory(entry.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? entry.value['color'].withOpacity(0.15)
                                  : isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : AppColors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? entry.value['color']
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  entry.value['icon'],
                                  size: 18,
                                  color: isSelected
                                      ? entry.value['color']
                                      : AppColors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: GoogleFonts.notoSans(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? entry.value['color']
                                        : AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    // Date & Time Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: AppColors.primary,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : AppColors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                                        style: GoogleFonts.notoSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : AppColors.darkGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.darkGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime,
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedTime = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : AppColors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedTime.format(context),
                                        style: GoogleFonts.notoSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : AppColors.darkGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Location
                    Text(
                      'Location',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Enter event location',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.grey.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Description
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tell us about your event...',
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.grey.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _submitEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Create Event',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Event Detail Sheet - Floating with margins
class _EventDetailSheet extends StatefulWidget {
  final CampusEvent event;

  const _EventDetailSheet({required this.event});

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isRsvped = false;
  int _rsvpCount = 0;

  @override
  void initState() {
    super.initState();
    _rsvpCount = (widget.event.title.hashCode % 50) + 10; // Mock count
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.19, 1.0, 0.22, 1.0), // Smooth deceleration
    );
    
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0), // Spring bounce
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleRsvp() {
    setState(() {
      _isRsvped = !_isRsvped;
      _rsvpCount += _isRsvped ? 1 : -1;
    });
    
    showAnimatedSuccess(
      context,
      _isRsvped ? 'You\'re going! 🎉' : 'RSVP cancelled',
      icon: _isRsvped ? Icons.check_circle_rounded : Icons.cancel_rounded,
      iconColor: _isRsvped ? AppColors.success : AppColors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 150),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.bottomCenter,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  children: [
                    // Category badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: widget.event.categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            widget.event.categoryIcon,
                            color: widget.event.categoryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: widget.event.categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.event.category,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: widget.event.categoryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      widget.event.title,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkGrey,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Date & Time
                    _buildInfoRow(
                      Icons.calendar_today_rounded,
                      'Date & Time',
                      DateFormat('EEEE, MMM dd, yyyy • h:mm a').format(widget.event.dateTime),
                    ),
                    const SizedBox(height: 16),
                    
                    // Location
                    _buildInfoRow(
                      Icons.location_on_rounded,
                      'Location',
                      widget.event.location,
                    ),
                    const SizedBox(height: 16),
                    
                    // Organizer
                    _buildInfoRow(
                      Icons.person_rounded,
                      'Organizer',
                      widget.event.organizer ?? 'Campus Activities',
                    ),
                    const SizedBox(height: 16),
                    
                    // RSVP Count
                    _buildInfoRow(
                      Icons.people_rounded,
                      'Attendees',
                      '$_rsvpCount people going',
                    ),
                    const SizedBox(height: 24),
                    
                    // Description
                    Text(
                      'About this event',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.event.description,
                      style: GoogleFonts.notoSans(
                        fontSize: 15,
                        color: AppColors.grey,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              showAnimatedSuccess(
                                context,
                                'Navigating to ${widget.event.location}',
                                icon: Icons.directions_rounded,
                                iconColor: AppColors.primary,
                              );
                            },
                            icon: const Icon(Icons.directions_rounded, size: 20),
                            label: const Text('Directions'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _handleRsvp,
                            icon: Icon(
                              _isRsvped ? Icons.check_circle_rounded : Icons.event_available_rounded,
                              size: 20,
                            ),
                            label: Text(_isRsvped ? 'You\'re Going!' : 'RSVP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRsvped ? AppColors.success : AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.white.withOpacity(0.05) 
            : AppColors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.darkGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
