import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  final String planName;
  final String amount;
  
  const SubscriptionSuccessScreen({
    super.key,
    required this.planName,
    required this.amount,
  });

  @override
  State<SubscriptionSuccessScreen> createState() => _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _crownController;
  late AnimationController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _crownRotation;
  late Animation<double> _crownFloat;

  @override
  void initState() {
    super.initState();
    
    // Main entrance animation
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Crown animation
    _crownController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _crownRotation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _crownController, curve: Curves.easeInOut),
    );
    
    _crownFloat = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _crownController, curve: Curves.easeInOut),
    );
    
    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Rotate animation
    _rotateController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    // Start animations
    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _crownController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background effects
          _buildBackgroundEffects(),
          
          // Confetti
          _buildConfetti(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                
                // 3D Crown with glow
                AnimatedBuilder(
                  animation: Listenable.merge([_scaleAnimation, _crownController]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _crownFloat.value),
                        child: Transform.rotate(
                          angle: _crownRotation.value,
                          child: _build3DCrown(),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Success message
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Column(
                          children: [
                            Text(
                              'Welcome to Premium!',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withAlpha(102),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.planName,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'You\'ve unlocked all premium features!',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.amount,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const Spacer(),
                
                // Benefits list
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            _buildBenefit('Golden Crown on Your Profile', Icons.workspace_premium_rounded),
                            _buildBenefit('Exclusive Leaderboard Badge', Icons.emoji_events_rounded),
                            _buildBenefit('Priority Support Access', Icons.support_agent_rounded),
                            _buildBenefit('All Premium Features Unlocked', Icons.auto_awesome_rounded),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Continue button
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_pulseController.value * 0.05),
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: const Color(0xFFFFD700).withAlpha(128),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Start Exploring',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 24),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
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
              top: -150,
              right: -150 + (_rotateController.value * 100),
              child: Transform.rotate(
                angle: _rotateController.value * 2 * math.pi,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFD700).withAlpha(51),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -200,
              left: -200 - (_rotateController.value * 100),
              child: Transform.rotate(
                angle: -_rotateController.value * 2 * math.pi,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withAlpha(51),
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

  Widget _build3DCrown() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Shadow layers for 3D depth
        for (var i = 5; i >= 0; i--)
          Transform.translate(
            offset: Offset(0, i * 4.0),
            child: Container(
              width: 120 - (i * 4),
              height: 120 - (i * 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withAlpha(15 + (i * 5)),
              ),
            ),
          ),
        
        // Glow effect
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withAlpha(128),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        
        // Main crown circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withAlpha(179),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '👑',
              style: TextStyle(fontSize: 64),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return Stack(
          children: List.generate(50, (index) {
            final random = math.Random(index);
            final x = random.nextDouble() * MediaQuery.of(context).size.width;
            final y = -50 + (_confettiController.value * MediaQuery.of(context).size.height * 1.2);
            final rotation = random.nextDouble() * 2 * math.pi;
            final color = [
              const Color(0xFFFFD700),
              AppColors.primary,
              const Color(0xFFE91E63),
              const Color(0xFF4CAF50),
              const Color(0xFF9C27B0),
            ][random.nextInt(5)];
            
            return Positioned(
              left: x,
              top: y,
              child: Transform.rotate(
                angle: rotation + (_confettiController.value * 4 * math.pi),
                child: Container(
                  width: 8 + (random.nextDouble() * 4),
                  height: 8 + (random.nextDouble() * 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: random.nextBool() ? BoxShape.circle : BoxShape.rectangle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildBenefit(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withAlpha(51),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFFD700), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 24),
        ],
      ),
    );
  }
}
