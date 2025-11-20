import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<CampusEvent> _upcomingEvents = _sampleUpcomingEvents;
  final List<CampusEvent> _pastEvents = _samplePastEvents;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                Tab(text: 'Past Events'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsList(_upcomingEvents, isUpcoming: true),
          _buildEventsList(_pastEvents, isUpcoming: false),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<CampusEvent> events, {required bool isUpcoming}) {
    if (events.isEmpty) {
      return _buildEmptyState(isUpcoming);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event, isUpcoming);
      },
    );
  }

  Widget _buildEmptyState(bool isUpcoming) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                isUpcoming ? Icons.event_available : Icons.history,
                size: 60,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isUpcoming ? 'No Upcoming Events' : 'No Past Events',
              style: GoogleFonts.notoSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isUpcoming
                  ? 'Check back later for upcoming campus events and activities'
                  : 'Past events will appear here once they\'re completed',
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

  Widget _buildEventCard(CampusEvent event, bool isUpcoming) {
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
                    if (isUpcoming) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Navigate to event location
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Navigating to ${event.location}'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('RSVP for ${event.title}'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
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
