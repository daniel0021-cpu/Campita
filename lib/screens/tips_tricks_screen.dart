import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class TipsTricksScreen extends StatefulWidget {
  const TipsTricksScreen({super.key});

  @override
  State<TipsTricksScreen> createState() => _TipsTricksScreenState();
}

class _TipsTricksScreenState extends State<TipsTricksScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : AppColors.ash,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            pinned: true,
            expandedHeight: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0F172A) : AppColors.ash).withOpacity(0.95),
              ),
            ),
            title: Text(
              'Tips & Tricks',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAnimatedHeader(isDark),
                const SizedBox(height: 32),
                _buildTipCard(
                  isDark,
                  '🎯',
                  'Quick Search',
                  'Tap the search bar and start typing. Auto-complete suggests buildings as you type!',
                  const Color(0xFF3B82F6),
                  0,
                ),
                _buildTipCard(
                  isDark,
                  '📍',
                  'Long Press to Drop Pin',
                  'Long press anywhere on the map to drop a pin and get directions to that exact spot.',
                  const Color(0xFF10B981),
                  1,
                ),
                _buildTipCard(
                  isDark,
                  '⚡',
                  'Double-Tap to Zoom',
                  'Double-tap on the map to quickly zoom in. Two-finger double-tap to zoom out.',
                  const Color(0xFFF59E0B),
                  2,
                ),
                _buildTipCard(
                  isDark,
                  '🌙',
                  'Dark Mode Magic',
                  'Dark mode saves battery and reduces eye strain. Enable it in Settings > Appearance.',
                  const Color(0xFF8B5CF6),
                  3,
                ),
                _buildTipCard(
                  isDark,
                  '⭐',
                  'Favorite Everything',
                  'Add buildings to favorites for instant access. No more searching repeatedly!',
                  const Color(0xFFEC4899),
                  4,
                ),
                _buildTipCard(
                  isDark,
                  '🚶',
                  'Smart Entrance Routing',
                  'Walking mode automatically routes you to building entrances, not just centroids.',
                  const Color(0xFF06B6D4),
                  5,
                ),
                _buildTipCard(
                  isDark,
                  '🎨',
                  'Change Map Style',
                  'Switch between Standard, Satellite, and Terrain views for different perspectives.',
                  const Color(0xFFF97316),
                  6,
                ),
                _buildTipCard(
                  isDark,
                  '🔔',
                  'Enable Notifications',
                  'Turn on notifications in Settings to get updates about campus events and navigation.',
                  const Color(0xFFEF4444),
                  7,
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader(bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([_headerController, _floatController]),
      builder: (context, child) {
        final slideValue = Curves.elasticOut.transform(_headerController.value);
        final floatValue = _floatController.value;

        return Transform.translate(
          offset: Offset(0, (1 - slideValue) * 100),
          child: Opacity(
            opacity: slideValue,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    Colors.purple.withOpacity(0.15),
                    Colors.orange.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Transform.translate(
                    offset: Offset(0, math.sin(floatValue * math.pi * 2) * 10),
                    child: Transform.rotate(
                      angle: math.sin(floatValue * math.pi * 2) * 0.1,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              Colors.purple,
                              Colors.orange,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 25,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lightbulb,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Master Campus Navigation',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Discover powerful shortcuts and hidden features',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipCard(bool isDark, String emoji, String title, String description, Color accentColor, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 50, 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accentColor.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.2),
                          accentColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
