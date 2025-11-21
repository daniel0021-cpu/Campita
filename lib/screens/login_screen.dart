import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'enhanced_campus_map.dart';

class OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      icon: Icons.explore_outlined,
      title: 'Navigate Your Campus Easily',
      description: 'Find classrooms, departments, and facilities instantly with your campus guide.',
      color: AppColors.primary,
    ),
    OnboardingSlide(
      icon: Icons.map_outlined,
      title: 'Real-Time Navigation',
      description: 'Get turn-by-turn directions with live location tracking and route optimization.',
      color: Color(0xFFE91E63),
    ),
    OnboardingSlide(
      icon: Icons.favorite_outline,
      title: 'Save Favorites',
      description: 'Quick access to your frequently visited locations for faster navigation.',
      color: Color(0xFF4CAF50),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page?.round() ?? 0;
        });
      }
    });
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background wavy line decoration
          Positioned(
            top: screenHeight * 0.15,
            left: -50,
            right: -50,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomPaint(
                size: Size(screenWidth + 100, 200),
                painter: WavyLinePainter(),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top section with carousel
                Expanded(
                  flex: 5,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _slides.length,
                            itemBuilder: (context, index) {
                              return SlideTransition(
                                position: _slideAnimation,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 40),
                                    
                                    // Icon illustration
                                    ScaleTransition(
                                      scale: _scaleAnimation,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(milliseconds: 600),
                                        curve: Curves.elasticOut,
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: Container(
                                              padding: const EdgeInsets.all(32),
                                              decoration: BoxDecoration(
                                                color: _slides[index].color.withAlpha(26),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _slides[index].icon,
                                                size: 120,
                                                color: _slides[index].color,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Title
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      child: Text(
                                        _slides[index].title,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Description
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 40),
                                      child: Text(
                                        _slides[index].description,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.notoSans(
                                          fontSize: 15,
                                          color: AppColors.grey,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Animated page indicators
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _slides.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _currentPage == index ? 32 : 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? _slides[index].color
                                      : AppColors.grey.withAlpha(77),
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: _currentPage == index
                                      ? [
                                          BoxShadow(
                                            color: _slides[index].color.withAlpha(102),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom floating card
                Expanded(
                  flex: 3,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                          bottomLeft: Radius.circular(48),
                          bottomRight: Radius.circular(48),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 30,
                            offset: const Offset(0, -10),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
                        child: Column(
                          children: [
                            // Sign up button
                            _AnimatedButton(
                              onPressed: _skipToMap,
                              isPrimary: true,
                              child: Text(
                                'Sign up',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Log in button
                            _AnimatedButton(
                              onPressed: _skipToMap,
                              isPrimary: false,
                              child: Text(
                                'Log in',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Bottom gesture bar
                            Container(
                              width: 60,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.grey.withAlpha(77),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
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

  Widget _buildIllustration() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(13),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Location pins with bounce animation
          Positioned(
            top: 40,
            right: 60,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary.withAlpha(153),
                    size: 32,
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 60,
            left: 50,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary.withAlpha(102),
                    size: 24,
                  ),
                );
              },
            ),
          ),
          
          // Buildings
          Positioned(
            top: 80,
            left: 40,
            child: Icon(
              Icons.domain_rounded,
              color: AppColors.primary.withAlpha(77),
              size: 28,
            ),
          ),
          Positioned(
            bottom: 50,
            right: 50,
            child: Icon(
              Icons.apartment_rounded,
              color: AppColors.primary.withAlpha(89),
              size: 26,
            ),
          ),
          
          // Center student with map
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    color: AppColors.primary,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ],
          ),
          
          // Compass with rotation animation
          Positioned(
            top: 50,
            left: 70,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 6.28,
                  child: Icon(
                    Icons.explore_rounded,
                    color: AppColors.primary.withAlpha(102),
                    size: 28,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.grey.withAlpha(77),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _skipToMap() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const EnhancedCampusMap(),
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

// Animated Button Widget
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isPrimary;
  final Widget child;

  const _AnimatedButton({
    required this.onPressed,
    required this.isPrimary,
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
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.isPrimary ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: widget.isPrimary ? null : Border.all(
              color: AppColors.primary,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isPrimary 
                    ? AppColors.primary.withAlpha(77)
                    : Colors.transparent,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(
                color: widget.isPrimary ? Colors.white : AppColors.primary,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for wavy background line
class WavyLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withAlpha(20)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i < size.width; i += 20) {
      path.quadraticBezierTo(
        i + 10, size.height * 0.5 + 15,
        i + 20, size.height * 0.5,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
