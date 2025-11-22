import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/campus_event.dart';
import '../theme/app_theme.dart';

class LiveEventsBanner extends StatefulWidget {
  final List<CampusEvent> liveEvents;
  final VoidCallback? onViewAll;
  final Function(CampusEvent)? onEventTap;

  const LiveEventsBanner({
    super.key,
    required this.liveEvents,
    this.onViewAll,
    this.onEventTap,
  });

  @override
  State<LiveEventsBanner> createState() => _LiveEventsBannerState();
}

class _LiveEventsBannerState extends State<LiveEventsBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Auto-scroll through events
    if (widget.liveEvents.length > 1) {
      Future.delayed(const Duration(seconds: 5), _autoScroll);
    }
  }

  void _autoScroll() {
    if (!mounted) return;
    if (widget.liveEvents.isEmpty) return;

    final nextPage = (_currentPage + 1) % widget.liveEvents.length;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(seconds: 5), _autoScroll);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.liveEvents.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withAlpha(230),
              AppColors.primary.withAlpha(204),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(77),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Animated gradient overlay
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withAlpha(
                              (25 + 25 * _pulseController.value).toInt(),
                            ),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Events carousel
              SizedBox(
                height: 120,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: widget.liveEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(
                      widget.liveEvents[index],
                      isDark,
                    );
                  },
                ),
              ),

              // Page indicators
              if (widget.liveEvents.length > 1)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.liveEvents.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == index ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withAlpha(128),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(CampusEvent event, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onEventTap?.call(event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Live indicator
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withAlpha(
                            (128 + 127 * _pulseController.value).toInt(),
                          ),
                          blurRadius: 8 + 4 * _pulseController.value,
                          spreadRadius: 2 * _pulseController.value,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),

              // Event content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'LIVE',
                            style: GoogleFonts.notoSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.title,
                            style: GoogleFonts.notoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.white.withAlpha(230),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.venue,
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              color: Colors.white.withAlpha(230),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.white.withAlpha(230),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.timeRangeFormatted,
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: Colors.white.withAlpha(230),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
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
