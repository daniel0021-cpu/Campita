import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/expanding_dots_indicator.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _waveController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;
  bool _musicInitialized = false;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.map_rounded,
      title: 'Smart Campus Navigation',
      description: 'Navigate Igbinedion University with precision. Real-time routes, 3D maps, and accurate entrance-based pathfinding.',
      color: const Color(0xFF0366FC),
      gradient: [const Color(0xFF0366FC), const Color(0xFF4A9FFF)],
    ),
    _OnboardingSlide(
      icon: Icons.view_in_ar_rounded,
      title: 'AR Directions & 3D View',
      description: 'Experience the future with AR-powered navigation. See directions overlaid on reality and explore campus in stunning 3D.',
      color: const Color(0xFF9C27B0),
      gradient: [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
      isARFeature: true,
    ),
    _OnboardingSlide(
      icon: Icons.explore_rounded,
      title: 'Discover & Personalize',
      description: 'Find buildings, save favorites, get live updates. Your personalized campus companion.',
      color: const Color(0xFFE91E63),
      gradient: [const Color(0xFFE91E63), const Color(0xFFF06292)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _initMusic();
  }
  
  Future<void> _initMusic() async {
    // Note: Add your music file to assets folder
    // For now, we'll use a simple approach
    setState(() => _musicInitialized = true);
  }
  
  void _toggleMusic() {
    setState(() {
      _isMusicPlaying = !_isMusicPlaying;
      // if (_isMusicPlaying) {
      //   _audioPlayer.play(AssetSource('audio/onboarding_music.mp3'));
      // } else {
      //   _audioPlayer.pause();
      // }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _skip() {
    _completeOnboarding();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _CurvedWavyBackground(
            animation: _waveController,
            currentPage: _currentPage,
            colors: _slides[_currentPage].gradient,
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar with music button and skip
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Music toggle button
                      _AnimatedButton(
                        onPressed: _toggleMusic,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isMusicPlaying ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      // Skip button
                      _AnimatedButton(
                        onPressed: _skip,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Skip',
                            style: GoogleFonts.notoSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(index),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutQuart,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Modern icon container with gradient
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: slide.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: slide.color.withOpacity(0.4),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Icon(
                                slide.icon,
                                size: 85,
                                color: Colors.white,
                              ),
                            ),
                            if (slide.isARFeature) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF6B6B),
                                      const Color(0xFFFF8E53),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B6B).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'FEATURED: AR NAVIGATION',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 40),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40.0),
                              child: Text(
                                slide.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40.0),
                              child: Text(
                                slide.description,
                                style: GoogleFonts.notoSans(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ExpandingDotsIndicator(
                  currentPage: _currentPage,
                  count: _slides.length,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.4),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: _AnimatedButton(
                      onPressed: _next,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _currentPage == _slides.length - 1 ? 'Get Started' : 'Continue',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<Color> gradient;
  final bool isARFeature;
  
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.gradient,
    this.isARFeature = false,
  });
}

class _CurvedWavyBackground extends StatelessWidget {
  final Animation<double> animation;
  final int currentPage;
  final List<Color> colors;

  const _CurvedWavyBackground({
    required this.animation,
    required this.currentPage,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: WavyBackgroundPainter(animation.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

// Animated Button Widget
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _AnimatedButton({
    required this.onPressed,
    required this.child,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

class WavyBackgroundPainter extends CustomPainter {
  final double animationValue;

  WavyBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.08);

    // Draw 3 wavy layers
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final waveHeight = 40.0 + (i * 10);
      final waveLength = size.width / 2;
      final offset = (animationValue * 2 * 3.14159) + (i * 0.5);

      path.moveTo(0, size.height * 0.3 + (i * 80));

      for (double x = 0; x <= size.width; x++) {
        final y = size.height * 0.3 +
            (i * 80) +
            waveHeight * sin((x / waveLength) * 2 * 3.14159 + offset);
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }

    // Draw floating circles
    final circlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.05);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.15 + (sin(animationValue * 2 * 3.14159) * 20)),
      60,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.25 + (cos(animationValue * 2 * 3.14159 + 1) * 15)),
      45,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.8 + (sin(animationValue * 2 * 3.14159 + 2) * 25)),
      70,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(WavyBackgroundPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}