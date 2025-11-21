import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'enhanced_campus_map.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _controller;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentPage = 0;
  bool _showLoginForm = false;
  bool _isSignup = true;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Navigate Your Campus Easily',
      'subtitle': 'Find classrooms, departments, and facilities instantly with your campus guide.',
      'icon': Icons.map_rounded,
      'color': AppColors.primary,
    },
    {
      'title': 'Real-Time Navigation',
      'subtitle': 'Get turn-by-turn directions with live GPS tracking and voice guidance.',
      'icon': Icons.navigation_rounded,
      'color': const Color(0xFF4CAF50),
    },
    {
      'title': 'Discover Campus Life',
      'subtitle': 'Explore events, amenities, and hidden gems around your campus.',
      'icon': Icons.explore_rounded,
      'color': const Color(0xFFFF9800),
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    
    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      if (page.round() != _currentPage) {
        setState(() => _currentPage = page.round());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _buttonController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_isSignup) {
      // Save signup data
      await prefs.setString('user_name', _nameController.text);
      await prefs.setString('user_email', _emailController.text);
      await prefs.setString('user_password', _passwordController.text);
      await prefs.setBool('is_logged_in', true);
    } else {
      // Check login
      final savedEmail = prefs.getString('user_email') ?? '';
      final savedPassword = prefs.getString('user_password') ?? '';
      
      if (_emailController.text == savedEmail && _passwordController.text == savedPassword) {
        await prefs.setBool('is_logged_in', true);
      } else {
        _showError('Invalid credentials');
        return;
      }
    }
    
    _navigateToMap();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _navigateToMap() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const EnhancedCampusMap(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _showLoginForm
            ? _buildLoginForm()
            : _buildOnboardingSlides(screenHeight),
      ),
    );
  }

  Widget _buildOnboardingSlides(double screenHeight) {
    return Stack(
      key: const ValueKey('onboarding'),
      children: [
        // Background wavy decoration
        Positioned(
          top: screenHeight * 0.15,
          left: -50,
          right: -50,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width + 100, 200),
              painter: WavyLinePainter(color: _slides[_currentPage]['color']),
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // PageView with slides
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index], index);
                  },
                ),
              ),

              // Bottom card with buttons
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
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 30,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
                      child: Column(
                        children: [
                          // Animated page indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _slides.length,
                              (index) => _buildDot(index),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Sign up button
                          _AnimatedButton(
                            onPressed: () {
                              setState(() {
                                _showLoginForm = true;
                                _isSignup = true;
                              });
                            },
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
                            onPressed: () {
                              setState(() {
                                _showLoginForm = true;
                                _isSignup = false;
                              });
                            },
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
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide, int index) {
    final isActive = _currentPage == index;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Illustration
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: isActive ? 1.0 : 0.9),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: _buildIllustration(slide['icon'], slide['color']),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedOpacity(
                opacity: isActive ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  slide['title'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AnimatedOpacity(
                opacity: isActive ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  slide['subtitle'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSans(
                    fontSize: 15,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(IconData icon, Color color) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated location pins
          ...List.generate(3, (index) {
            return Positioned(
              top: 40 + (index * 60.0),
              right: 60 + (index * 20.0),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 600 + (index * 200)),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      Icons.location_on_rounded,
                      color: color.withAlpha((77 + (index * 26)).clamp(0, 255)),
                      size: 28 - (index * 4.0),
                    ),
                  );
                },
              ),
            );
          }),
          
          // Center icon
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Icon(
                Icons.person_rounded,
                color: color,
                size: 48,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = _currentPage == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive 
            ? _slides[_currentPage]['color']
            : AppColors.grey.withAlpha(77),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive ? [
          BoxShadow(
            color: _slides[_currentPage]['color'].withAlpha(102),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
    );
  }

  Widget _buildLoginForm() {
    return SafeArea(
      key: const ValueKey('login'),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: _AnimatedButton(
                onPressed: () {
                  setState(() => _showLoginForm = false);
                },
                isPrimary: false,
                isIconOnly: true,
                child: const Icon(Icons.arrow_back_rounded, size: 24),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              _isSignup ? 'Create Account' : 'Welcome Back',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _isSignup 
                  ? 'Sign up to start navigating your campus'
                  : 'Log in to continue',
              style: GoogleFonts.notoSans(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Name field (signup only)
            if (_isSignup) ...[
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 20),
            ],
            
            // Email field
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 20),
            
            // Password field
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
            ),
            
            const SizedBox(height: 32),
            
            // Submit button
            _AnimatedButton(
              onPressed: _handleAuth,
              isPrimary: true,
              child: Text(
                _isSignup ? 'Sign Up' : 'Log In',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Toggle between signup/login
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _isSignup = !_isSignup);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                child: Text(
                  _isSignup 
                      ? 'Already have an account? Log in'
                      : 'Don\'t have an account? Sign up',
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              keyboardType: keyboardType,
              style: GoogleFonts.notoSans(fontSize: 16),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.notoSans(
                  color: AppColors.grey,
                ),
                prefixIcon: Icon(icon, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.grey.withAlpha(13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Animated Button Widget with universal Apple-style animations
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isPrimary;
  final Widget child;
  final bool isIconOnly;

  const _AnimatedButton({
    required this.onPressed,
    required this.isPrimary,
    required this.child,
    this.isIconOnly = false,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> 
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
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
          width: widget.isIconOnly ? 48 : double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.isPrimary ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(widget.isIconOnly ? 12 : 16),
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
  final Color color;
  
  WavyLinePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(20)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
