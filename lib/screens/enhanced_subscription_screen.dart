import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_navbar.dart';

class EnhancedSubscriptionScreen extends StatefulWidget {
  final bool isProMember;
  final DateTime? expiryDate;
  
  const EnhancedSubscriptionScreen({
    super.key,
    this.isProMember = false,
    this.expiryDate,
  });

  @override
  State<EnhancedSubscriptionScreen> createState() => _EnhancedSubscriptionScreenState();
}

class _EnhancedSubscriptionScreenState extends State<EnhancedSubscriptionScreen> 
    with TickerProviderStateMixin {
  static const String email = 'admin@dmanapp.com';
  bool _isProMember = false;
  DateTime? _expiryDate;
  bool _showingSuccess = false;
  
  late AnimationController _successController;
  late AnimationController _proCardController;
  late AnimationController _shineController;
  late ConfettiController _confettiController;
  
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successFadeAnimation;
  late Animation<double> _proCardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _isProMember = widget.isProMember;
    _expiryDate = widget.expiryDate;
    
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _proCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    
    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0), // Bouncy spring
      ),
    );
    
    _successFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: Curves.easeIn,
      ),
    );
    
    _proCardSlideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _proCardController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    _proCardController.dispose();
    _shineController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleSubscription(String plan) async {
    // Show full screen success animation
    setState(() => _showingSuccess = true);
    
    _successController.forward();
    _confettiController.play();
    
    // Wait for success animation
    await Future.delayed(const Duration(milliseconds: 1800));
    
    // Hide success screen and show PRO member screen
    setState(() {
      _showingSuccess = false;
      _isProMember = true;
      _expiryDate = DateTime.now().add(const Duration(days: 30));
    });
    
    _successController.reset();
    _proCardController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isProMember)
                    _buildProMemberHeader()
                  else
                    _buildHeader(),
                  const SizedBox(height: 24),
                  if (_isProMember)
                    _buildProMemberStatus()
                  else
                    _buildPlanCards(context),
                  const SizedBox(height: 24),
                  if (!_isProMember) _buildBenefits(),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: _contactSupport,
                      icon: const Icon(Icons.email, color: AppColors.primary),
                      label: Text(
                        'Questions? Email $email',
                        style: GoogleFonts.openSans(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          if (_showingSuccess) _buildSuccessAnimation(),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              maxBlastForce: 20,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [
                AppColors.primary,
                Colors.amber,
                Colors.green,
                Colors.pink,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 2),
    );
  }

  Widget _buildSuccessAnimation() {
    return AnimatedBuilder(
      animation: _successController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withAlpha((179 * _successFadeAnimation.value).round()),
          child: Center(
            child: Transform.scale(
              scale: _successScaleAnimation.value,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF00C9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(128),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(64),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        size: 70,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to PRO!',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'ve joined the elite club',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        color: Colors.white.withAlpha(242),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProMemberHeader() {
    return AnimatedBuilder(
      animation: _proCardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _proCardSlideAnimation.value),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withAlpha(128),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, child) {
                    return Positioned(
                      left: -100 + (_shineController.value * 400),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withAlpha(0),
                              Colors.white.withAlpha(102),
                              Colors.white.withAlpha(0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(77),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            CupertinoIcons.star_fill,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PRO MEMBER',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                'Elite Campus Navigator',
                                style: GoogleFonts.openSans(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(242),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProMemberStatus() {
    if (_expiryDate == null) return const SizedBox();
    
    final daysLeft = _expiryDate!.difference(DateTime.now()).inDays;
    final percentage = (daysLeft / 30).clamp(0.0, 1.0);
    
    return AnimatedBuilder(
      animation: _proCardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _proCardSlideAnimation.value + 50),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subscription Status',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(26),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.check_mark_circled_solid,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Active',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: 12,
                          width: MediaQuery.of(context).size.width * percentage * 0.85,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: percentage > 0.3
                                  ? [AppColors.primary, const Color(0xFF00C9FF)]
                                  : [Colors.orange, Colors.red],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: (percentage > 0.3
                                        ? AppColors.primary
                                        : Colors.orange)
                                    .withAlpha(77),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Days Remaining',
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$daysLeft days',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: percentage > 0.3
                                    ? AppColors.primary
                                    : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Expires On',
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Renew subscription
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text(
                  'Renew Subscription',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withAlpha(204)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.star_fill,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Upgrade to PRO',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock premium campus navigation features',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 15,
              color: Colors.white.withAlpha(242),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCards(BuildContext context) {
    return Column(
      children: [
        _buildPlanCard(
          'Monthly Pro',
          '₦2,500',
          '/month',
          'Perfect for one semester',
          () => _handleSubscription('monthly'),
          showComingSoon: true,
        ),
        const SizedBox(height: 16),
        _buildPlanCard(
          'Yearly Pro',
          '₦25,000',
          '/year',
          'Best value - Save 17%',
          () => _handleSubscription('yearly'),
          isPopular: true,
          showComingSoon: true,
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    String title,
    String price,
    String period,
    String description,
    VoidCallback onTap, {
    bool isPopular = false,
    bool showComingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPopular ? AppColors.primary : const Color(0xFFE5E7EB),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPopular
                  ? AppColors.primary.withAlpha(51)
                  : Colors.black.withAlpha(13),
              blurRadius: isPopular ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (showComingSoon)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'COMING SOON',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF0052CC)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'POPULAR',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Text(
                    period,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isPopular ? AppColors.primary : const Color(0xFF6B7280),
                    isPopular
                        ? const Color(0xFF0052CC)
                        : const Color(0xFF4B5563),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Select Plan',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    final benefits = [
      'Unlimited navigation queries',
      'AR directions (coming soon)',
      'Offline maps',
      'Priority support',
      'Ad-free experience',
      'Early access to features',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRO Benefits',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      benefit,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _contactSupport() async {
    final uri = Uri(scheme: 'mailto', path: email, queryParameters: {
      'subject': 'Subscription - Campus Navigation',
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
