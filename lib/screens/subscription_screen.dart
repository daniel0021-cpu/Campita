import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_navbar.dart';
import '../widgets/animated_success_card.dart';
import 'leaderboard_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> 
    with TickerProviderStateMixin {
  static const String email = 'admin@dmanapp.com';
  
  late AnimationController _crownController;
  late AnimationController _characterController;
  late AnimationController _pulseController;
  late AnimationController _shineController;
  late Animation<double> _crownRotation;
  late Animation<double> _characterFloat;

  @override
  void initState() {
    super.initState();
    
    _crownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _crownRotation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _crownController,
      curve: Curves.easeInOut,
    ));
    
    _characterFloat = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(
      parent: _characterController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _crownController.dispose();
    _characterController.dispose();
    _pulseController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  Future<void> _contactSupport() async {
    final uri = Uri(scheme: 'mailto', path: email, queryParameters: {
      'subject': 'Subscription - Campus Navigation',
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 1200));
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildPlanCards(context),
                  const SizedBox(height: 24),
                  _buildBenefits(),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: _contactSupport,
                      icon: const Icon(Icons.email, color: AppColors.primary),
                      label: Text('Questions? Email $email', style: GoogleFonts.notoSans(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _shineController]),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8F9FA),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withAlpha((77 + _pulseController.value * 51).round()),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha((51 + _pulseController.value * 51).round()),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shine effect
              Positioned(
                left: -100 + (_shineController.value * MediaQuery.of(context).size.width),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(0),
                        Colors.white.withAlpha(51),
                        Colors.white.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
              
              Column(
                children: [
                  // Animated Character with Crown
                  AnimatedBuilder(
                    animation: Listenable.merge([_characterController, _crownController]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _characterFloat.value),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow effect
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFFD700).withAlpha(77),
                                    const Color(0xFFFFD700).withAlpha(26),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            
                            // Character container with blue outline
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(128),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '🚀',
                                  style: TextStyle(
                                    fontSize: 60,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withAlpha(77),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            // Floating crown
                            Positioned(
                              top: -5,
                              child: Transform.rotate(
                                angle: _crownRotation.value,
                                child: const Text(
                                  '👑',
                                  style: TextStyle(fontSize: 40),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Campus King/Pro Title
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withAlpha(77),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'CAMPUS KING',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Become a Campus Pro',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryAdaptive(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    '🔥 Join the Elite Navigators 🔥',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Unlock premium features, climb the leaderboard, and dominate campus navigation!',
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      color: AppColors.textSecondaryAdaptive(context),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Leaderboard button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => const LeaderboardScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withAlpha(204),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(77),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'View Leaderboard',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlanCards(BuildContext context) {
    return Column(
      children: [
        _planCard(
          context,
          'Monthly Plan',
          '₦2,000',
          'per month',
          [
            {'icon': Icons.navigation_rounded, 'text': 'All navigation modes', 'color': const Color(0xFF0366FC)},
            {'icon': Icons.door_front_door_rounded, 'text': 'Entrance-based routing', 'color': const Color(0xFF4CAF50)},
            {'icon': Icons.favorite_rounded, 'text': 'Favorites sync', 'color': const Color(0xFFE91E63)},
            {'icon': Icons.support_agent_rounded, 'text': 'Priority support', 'color': const Color(0xFFFF9800)},
          ],
          showComingSoon: true,
        ),
        const SizedBox(height: 16),
        _planCard(
          context,
          'Yearly Plan',
          '₦20,000',
          'per year',
          [
            {'icon': Icons.savings_rounded, 'text': '₦4,000 saved vs monthly', 'color': const Color(0xFF4CAF50)},
            {'icon': Icons.workspace_premium_rounded, 'text': '👑 Golden Crown Badge on Profile', 'color': const Color(0xFFFFD700)},
            {'icon': Icons.person_outline, 'text': 'Direct access to Founder/Developer', 'color': const Color(0xFFFFD700)},
            {'icon': Icons.emoji_events, 'text': 'Exclusive leaderboard badge', 'color': const Color(0xFFFFD700)},
            {'icon': Icons.view_in_ar_rounded, 'text': 'AR Navigation (3D arrows)', 'color': const Color(0xFF9C27B0)},
            {'icon': Icons.auto_awesome_rounded, 'text': 'AI-powered suggestions', 'color': const Color(0xFFFF5722)},
            {'icon': Icons.offline_bolt_rounded, 'text': 'Offline maps', 'color': const Color(0xFF00BCD4)},
            {'icon': Icons.stars_rounded, 'text': 'Early access to features', 'color': const Color(0xFFFFC107)},
          ],
          recommended: true,
          showComingSoon: true,
        ),
      ],
    );
  }

  Widget _planCard(
    BuildContext context,
    String title,
    String price,
    String period,
    List<Map<String, Object>> features, {
    bool recommended = false,
    bool showComingSoon = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(
          color: recommended ? const Color(0xFFFFD700) : AppColors.primary,
          width: recommended ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: recommended ? [
          BoxShadow(
            color: const Color(0xFFFFD700).withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryAdaptive(context),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showComingSoon)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'COMING SOON',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  if (recommended)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withAlpha(102),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Recommended',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.notoSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  period,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: AppColors.textSecondaryAdaptive(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SizedBox(height: 20),
          
          // Features Grid
          ...features.map(
            (f) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (f['color'] as Color).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (f['color'] as Color).withAlpha(51),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (f['color'] as Color).withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      f['icon'] as IconData,
                      color: f['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f['text'] as String,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: AppColors.textPrimaryAdaptive(context),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _AnimatedPlanButton(
              onPressed: () async {
                await _contactSupport();
                if (context.mounted) {
                  showAnimatedSuccess(
                    context,
                    'Email composer opened. Complete your subscription via email.',
                    icon: Icons.email_rounded,
                    iconColor: AppColors.primary,
                  );
                }
              },
              backgroundColor: recommended ? const Color(0xFFFFD700) : AppColors.primary,
              foregroundColor: recommended ? Colors.black : Colors.white,
              elevation: recommended ? 4 : 0,
              child: Text(
                'Select Plan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Why Go Premium?',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryAdaptive(context),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _benefitCard(
          'AR Navigation Experience',
          'See 3D directional arrows overlaid on your camera view for intuitive campus navigation',
          Icons.view_in_ar_rounded,
          const Color(0xFF9C27B0),
        ),
        _benefitCard(
          'AI-Powered Recommendations',
          'Get smart suggestions for nearby facilities, optimal routes, and popular destinations',
          Icons.auto_awesome_rounded,
          const Color(0xFFFF5722),
        ),
        _benefitCard(
          'Offline Maps Access',
          'Download campus maps for offline use - navigate even without internet connection',
          Icons.offline_bolt_rounded,
          const Color(0xFF00BCD4),
        ),
        _benefitCard(
          'Entrance-Based Routing',
          'Walk directly to building entrances with accurate pedestrian pathfinding',
          Icons.door_front_door_rounded,
          const Color(0xFF4CAF50),
        ),
        _benefitCard(
          'Real-Time Campus Updates',
          'Stay informed about campus events, closures, and new facility additions',
          Icons.notifications_active_rounded,
          const Color(0xFFFF9800),
        ),
        _benefitCard(
          'Cross-Device Sync',
          'Your favorites, settings, and preferences sync seamlessly across all devices',
          Icons.sync_rounded,
          const Color(0xFF0366FC),
        ),
      ],
    );
  }

  Widget _benefitCard(String title, String description, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(51),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(26),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryAdaptive(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: AppColors.grey,
                    height: 1.5,
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

// Animated Plan Button with Apple-style smooth animations
class _AnimatedPlanButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double elevation;
  final Widget child;

  const _AnimatedPlanButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.elevation,
    required this.child,
  });

  @override
  State<_AnimatedPlanButton> createState() => _AnimatedPlanButtonState();
}

class _AnimatedPlanButtonState extends State<_AnimatedPlanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withAlpha(77),
                blurRadius: widget.elevation * 3,
                offset: Offset(0, widget.elevation),
              ),
            ],
          ),
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(color: widget.foregroundColor),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
