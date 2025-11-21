import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BadgesScreen extends StatefulWidget {
  final List<BadgeData> badges;
  const BadgesScreen({super.key, required this.badges});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.ash,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryAdaptive(context),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withAlpha(26)
                  : Colors.black.withAlpha(13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimaryAdaptive(context),
              size: 18,
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: widget.badges.isEmpty
            ? _buildEmptyState(isDark)
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats header
                    _buildStatsHeader(isDark),
                    const SizedBox(height: 24),
                    
                    // Badges grid
                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: widget.badges.length,
                        itemBuilder: (context, i) {
                          final badge = widget.badges[i];
                          return FadeTransition(
                            opacity: Tween<double>(begin: 0, end: 1).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  i * 0.1,
                                  0.4 + (i * 0.1),
                                  curve: Curves.easeOut,
                                ),
                              ),
                            ),
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    i * 0.1,
                                    0.4 + (i * 0.1),
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                              ),
                              child: _BadgeCard(badge: badge, isDark: isDark),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Badges Yet',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryAdaptive(context),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Start exploring campus to earn your first achievement badges!',
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  color: AppColors.textSecondaryAdaptive(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.explore_rounded),
              label: Text(
                'Start Exploring',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(bool isDark) {
    final achieved = widget.badges.where((b) => b.achieved).length;
    final total = widget.badges.length;
    final percentage = total > 0 ? (achieved / total * 100).toInt() : 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(179),
            AppColors.primary.withAlpha(128),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Progress',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    color: Colors.white.withAlpha(204),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$achieved',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        '/ $total',
                        style: GoogleFonts.notoSans(
                          fontSize: 18,
                          color: Colors.white.withAlpha(179),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 6,
                    backgroundColor: Colors.white.withAlpha(51),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Colors.amber,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage%',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

class BadgeData {
  final String title;
  final String description;
  final String imageAsset;
  final bool achieved;
  final IconData icon;
  final Color color;
  
  BadgeData({
    required this.title,
    required this.description,
    required this.imageAsset,
    this.achieved = false,
    this.icon = Icons.emoji_events_rounded,
    this.color = Colors.amber,
  });
}

class _BadgeCard extends StatelessWidget {
  final BadgeData badge;
  final bool isDark;
  
  const _BadgeCard({required this.badge, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _showBadgeDetails(context);
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: badge.color.withAlpha(51),
        highlightColor: badge.color.withAlpha(26),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: badge.achieved
                ? (isDark 
                    ? AppColors.cardBackground(context)
                    : Colors.white)
                : (isDark 
                    ? Colors.grey.shade800.withAlpha(128)
                    : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: badge.achieved
                  ? badge.color.withAlpha(77)
                  : Colors.grey.withAlpha(51),
              width: 2,
            ),
            boxShadow: badge.achieved
                ? [
                    BoxShadow(
                      color: badge.color.withAlpha(51),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon/Badge
              Stack(
                alignment: Alignment.center,
                children: [
                  if (badge.achieved)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            badge.color.withAlpha(51),
                            badge.color.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: badge.achieved
                          ? badge.color.withAlpha(26)
                          : Colors.grey.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      badge.icon,
                      size: 40,
                      color: badge.achieved
                          ? badge.color
                          : Colors.grey,
                    ),
                  ),
                  if (badge.achieved)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: badge.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: badge.color.withAlpha(128),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                badge.title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: badge.achieved
                      ? AppColors.textPrimaryAdaptive(context)
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              
              // Description
              Text(
                badge.description,
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: badge.achieved
                      ? AppColors.textSecondaryAdaptive(context)
                      : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBackground
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: badge.color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                badge.icon,
                size: 60,
                color: badge.color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              badge.title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryAdaptive(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              badge.description,
              style: GoogleFonts.notoSans(
                fontSize: 15,
                color: AppColors.textSecondaryAdaptive(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: badge.achieved
                    ? badge.color.withAlpha(26)
                    : Colors.grey.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    badge.achieved ? Icons.check_circle_rounded : Icons.lock_rounded,
                    color: badge.achieved ? badge.color : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    badge.achieved ? 'Unlocked' : 'Locked',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: badge.achieved ? badge.color : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
