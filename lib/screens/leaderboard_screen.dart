import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Campus Pro Leaderboard with 3D Badges and Advanced Animations
/// Motivates users to subscribe for Pro membership
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _shineController;

  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  final List<LeaderboardUser> _users = [
    LeaderboardUser(
      rank: 1,
      name: 'Emmanuel O.',
      points: 9850,
      badge: BadgeType.campusKing,
      level: 45,
      avatar: '👑',
      streak: 127,
    ),
    LeaderboardUser(
      rank: 2,
      name: 'Sarah A.',
      points: 8920,
      badge: BadgeType.campusPro,
      level: 42,
      avatar: '⭐',
      streak: 98,
    ),
    LeaderboardUser(
      rank: 3,
      name: 'David M.',
      points: 7645,
      badge: BadgeType.campusPro,
      level: 38,
      avatar: '🔥',
      streak: 76,
    ),
    LeaderboardUser(
      rank: 4,
      name: 'Grace U.',
      points: 6890,
      badge: BadgeType.navigator,
      level: 35,
      avatar: '🎯',
      streak: 54,
    ),
    LeaderboardUser(
      rank: 5,
      name: 'John B.',
      points: 6120,
      badge: BadgeType.navigator,
      level: 32,
      avatar: '🚀',
      streak: 43,
    ),
    LeaderboardUser(
      rank: 6,
      name: 'Mary K.',
      points: 5450,
      badge: BadgeType.explorer,
      level: 28,
      avatar: '🌟',
      streak: 31,
    ),
    LeaderboardUser(
      rank: 7,
      name: 'Peter J.',
      points: 4980,
      badge: BadgeType.explorer,
      level: 25,
      avatar: '💎',
      streak: 22,
    ),
    LeaderboardUser(
      rank: 8,
      name: 'You',
      points: 1250,
      badge: BadgeType.newbie,
      level: 8,
      avatar: '🎓',
      streak: 5,
      isCurrentUser: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _headerSlideAnimation = Tween<double>(
      begin: -100,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    _headerFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    ));

    _headerController.forward();
    _listController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient circles
            _buildBackgroundEffects(),

            Column(
              children: [
                _buildHeader(),
                _buildPodium(),
                Expanded(child: _buildLeaderboardList()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundEffects() {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100,
              right: -100 + (_rotateController.value * 50),
              child: Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withAlpha(26),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100 - (_rotateController.value * 50),
              child: Transform.rotate(
                angle: -_rotateController.value * 2 * math.pi,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withAlpha(26),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: Opacity(
            opacity: _headerFadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        color: const Color(0xFF1F2937),
                      ),
                      const Spacer(),
                      Text(
                        'Campus Leaderboard',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTopNavigatorBanner(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopNavigatorBanner() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.02),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                  Color(0xFFFFD700),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withAlpha((77 + _pulseController.value * 51).round()),
                  blurRadius: 20 + (_pulseController.value * 10),
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _rotateController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: math.sin(_rotateController.value * 2 * math.pi) * 0.1,
                      child: Text(
                        '👑',
                        style: const TextStyle(fontSize: 40),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Navigator',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withAlpha(242),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _users.first.name,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_users.first.points}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'points',
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: Colors.white.withAlpha(217),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPodium() {
    if (_users.length < 3) return const SizedBox();

    final topThree = _users.take(3).toList();

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          Expanded(
            child: _buildPodiumPlace(topThree[1], 2, 140, const Color(0xFFC0C0C0)),
          ),
          const SizedBox(width: 8),
          // 1st Place
          Expanded(
            child: _buildPodiumPlace(topThree[0], 1, 180, const Color(0xFFFFD700)),
          ),
          const SizedBox(width: 8),
          // 3rd Place
          Expanded(
            child: _buildPodiumPlace(topThree[2], 3, 120, const Color(0xFFCD7F32)),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(
    LeaderboardUser user,
    int place,
    double height,
    Color color,
  ) {
    final delay = (place == 1 ? 0.0 : place == 2 ? 0.1 : 0.2);

    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        final progress = Curves.easeOutBack.transform(
          (((_listController.value - delay) / (1.0 - delay)).clamp(0.0, 1.0)),
        );

        return Transform.translate(
          offset: Offset(0, (1 - progress) * 100),
          child: Opacity(
            opacity: progress,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Badge and Avatar
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = place == 1
                        ? 1.0 + (_pulseController.value * 0.05)
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: _build3DBadge(user, place),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  user.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.points} pts',
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                // Podium
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withAlpha(204),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(77),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '#$place',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _build3DBadge(LeaderboardUser user, int place) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Shadow layers for 3D effect
        for (var i = 3; i >= 0; i--)
          Transform.translate(
            offset: Offset(0, i * 2.0),
            child: Container(
              width: 70 - (i * 2),
              height: 70 - (i * 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withAlpha(10 + (i * 5)),
              ),
            ),
          ),

        // Main badge
        AnimatedBuilder(
          animation: _shineController,
          builder: (context, child) {
            return Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _getBadgeGradient(user.badge),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getBadgeGradient(user.badge)[0].withAlpha(128),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shine effect
                  Positioned.fill(
                    child: ClipOval(
                      child: OverflowBox(
                        maxWidth: double.infinity,
                        child: Transform.translate(
                          offset: Offset(
                            -70 + (_shineController.value * 140),
                            0,
                          ),
                          child: Container(
                            width: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withAlpha(0),
                                  Colors.white.withAlpha(128),
                                  Colors.white.withAlpha(0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      user.avatar,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Crown for #1
        if (place == 1)
          Positioned(
            top: -10,
            child: Transform.rotate(
              angle: -0.2,
              child: const Text('👑', style: TextStyle(fontSize: 24)),
            ),
          ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    final otherUsers = _users.skip(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: otherUsers.length + 1,
        itemBuilder: (context, index) {
          if (index == otherUsers.length) {
            return _buildProCallToAction();
          }

          final user = otherUsers[index];
          final delay = 0.3 + (index * 0.05);

          return AnimatedBuilder(
            animation: _listController,
            builder: (context, child) {
              final progress = Curves.easeOut.transform(
                (((_listController.value - delay) / (1.0 - delay))
                    .clamp(0.0, 1.0)),
              );

              return Transform.translate(
                offset: Offset((1 - progress) * 50, 0),
                child: Opacity(
                  opacity: progress,
                  child: _buildLeaderboardRow(user),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardRow(LeaderboardUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: user.isCurrentUser
            ? AppColors.primary.withAlpha(26)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: user.isCurrentUser
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: user.isCurrentUser
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(51),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Rank - with improved visibility
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: user.isCurrentUser
                  ? const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF0052CC)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                    ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (user.isCurrentUser ? AppColors.primary : Colors.grey).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#${user.rank}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Badge
          _buildSmallBadge(user),
          const SizedBox(width: 14),

          // Name and Level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    if (user.badge == BadgeType.campusKing ||
                        user.badge == BadgeType.campusPro) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getBadgeGradient(user.badge),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.badge == BadgeType.campusKing ? 'KING' : 'PRO',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Level ${user.level}',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.local_fire_department,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 2),
                    Text(
                      '${user.streak}',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.points}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'points',
                style: GoogleFonts.openSans(
                  fontSize: 11,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBadge(LeaderboardUser user) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: _getBadgeGradient(user.badge),
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _getBadgeGradient(user.badge)[0].withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          user.avatar,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  Widget _buildProCallToAction() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.01),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0366FC),
                  Color(0xFF0052CC),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha((77 + _pulseController.value * 51).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '🚀',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'Become a Campus Pro!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock exclusive badges, climb the ranks faster, and join the elite navigators',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: Colors.white.withAlpha(242),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Upgrade Now',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _getBadgeGradient(BadgeType badge) {
    switch (badge) {
      case BadgeType.campusKing:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case BadgeType.campusPro:
        return [const Color(0xFF0366FC), const Color(0xFF00C9FF)];
      case BadgeType.navigator:
        return [const Color(0xFF9C27B0), const Color(0xFFE91E63)];
      case BadgeType.explorer:
        return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
      case BadgeType.newbie:
        return [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)];
    }
  }
}

// Data Models
enum BadgeType {
  campusKing,
  campusPro,
  navigator,
  explorer,
  newbie,
}

class LeaderboardUser {
  final int rank;
  final String name;
  final int points;
  final BadgeType badge;
  final int level;
  final String avatar;
  final int streak;
  final bool isCurrentUser;

  LeaderboardUser({
    required this.rank,
    required this.name,
    required this.points,
    required this.badge,
    required this.level,
    required this.avatar,
    required this.streak,
    this.isCurrentUser = false,
  });
}
