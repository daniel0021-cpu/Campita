import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/expanding_dots_indicator.dart';
import 'enhanced_campus_map.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.map_outlined,
      title: 'Navigate Your Campus',
      description: 'Find buildings, routes, and services with ease using our modern campus map.',
      color: Colors.blue,
    ),
    _OnboardingSlide(
      icon: Icons.explore_outlined,
      title: '3D/2D Location View',
      description: 'Experience immersive navigation with 3D buildings and real-time orientation.',
      color: Colors.purple,
    ),
    _OnboardingSlide(
      icon: Icons.favorite_border,
      title: 'Save Your Favorites',
      description: 'Quickly access your favorite places and routes anytime.',
      color: Colors.pink,
    ),
  ];

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
        MaterialPageRoute(builder: (_) => const EnhancedCampusMap()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _CurvedBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 48.0, bottom: 24.0),
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: slide.color.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                slide.icon,
                                size: 80,
                                color: slide.color,
                              ),
                            ),
                          ),
                          Text(
                            slide.title,
                            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              slide.description,
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                ExpandingDotsIndicator(currentPage: _currentPage, count: _slides.length),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _skip,
                        child: Text('Skip', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w500)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        ),
                        onPressed: _next,
                        child: Text(
                          _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
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
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class _CurvedBackground extends StatelessWidget {
  const _CurvedBackground();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      child: CustomPaint(
        painter: _CurvedBackgroundPainter(),
        child: Container(),
      ),
    );
  }
}

class _CurvedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.blue.shade300, Colors.purple.shade200, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.5), topPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}