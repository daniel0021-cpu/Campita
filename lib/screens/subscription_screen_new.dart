import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class SubscriptionScreenNew extends StatelessWidget {
  const SubscriptionScreenNew({super.key});

  static const String supportEmail = 'admin@dmanapp.com';

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': 'Premium Subscription Inquiry'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withAlpha(204),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Premium',
                      style: GoogleFonts.notoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Premium Icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(51),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Unlock Premium Features',
                        style: GoogleFonts.notoSans(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Get the most out of Campus Navigation',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          color: Colors.white.withAlpha(230),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Features List
                      _buildFeatureCard(
                        Icons.offline_pin,
                        'Offline Maps',
                        'Access campus maps without internet',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.navigation,
                        'Advanced Navigation',
                        'Turn-by-turn AR navigation',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.favorite,
                        'Unlimited Favorites',
                        'Save as many locations as you want',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.notifications_active,
                        'Priority Notifications',
                        'Get campus updates first',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.support_agent,
                        'Premium Support',
                        '24/7 priority customer support',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureCard(
                        Icons.update,
                        'Early Access',
                        'Try new features before everyone',
                      ),
                      const SizedBox(height: 40),

                      // Pricing Cards
                      _buildPricingCard(
                        'Monthly',
                        '₦2,500',
                        '/month',
                        'Billed monthly',
                        false,
                      ),
                      const SizedBox(height: 16),
                      _buildPricingCard(
                        'Yearly',
                        '₦25,000',
                        '/year',
                        'Save ₦5,000 annually',
                        true,
                      ),
                      const SizedBox(height: 32),

                      // Subscribe Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _contactSupport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                          ),
                          child: Text(
                            'Contact for Subscription',
                            style: GoogleFonts.notoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Contact: $supportEmail',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: Colors.white.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.notoSans(
                    fontSize: 13,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    String title,
    String price,
    String period,
    String subtitle,
    bool recommended,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: recommended ? Colors.white : Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: recommended
              ? Colors.white
              : Colors.white.withAlpha(77),
          width: recommended ? 3 : 1,
        ),
        boxShadow: recommended
            ? [
                BoxShadow(
                  color: Colors.white.withAlpha(77),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (recommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'BEST VALUE',
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          Text(
            title,
            style: GoogleFonts.notoSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: recommended ? AppColors.primary : Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: GoogleFonts.notoSans(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: recommended ? AppColors.primary : Colors.white,
                ),
              ),
              Text(
                period,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: recommended
                      ? AppColors.textSecondary
                      : Colors.white.withAlpha(204),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: recommended
                  ? AppColors.textSecondary
                  : Colors.white.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }
}
