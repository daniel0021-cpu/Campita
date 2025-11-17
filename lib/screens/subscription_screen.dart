import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static const String email = 'admin@dmanapp.com';

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
      appBar: AppBar(
        title: Text('Subscription', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Unlock Premium Navigation', style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Accurate pedestrian routing to entrances, offline-ready maps (soon), favorites sync, priority updates and more.', style: GoogleFonts.notoSans(fontSize: 14, color: Colors.white.withValues(alpha: 0.95))),
        ],
      ),
    );
  }

  Widget _buildPlanCards(BuildContext context) {
    return Column(
      children: [
        _planCard(context, 'Monthly', '₦2,000', 'per month', [
          'All navigation modes',
          'Pedestrian entrance routing',
          'Favorites & settings sync',
          'Priority support',
        ]),
        const SizedBox(height: 14),
        _planCard(context, 'Yearly', '₦24,000', 'per year', [
          '2 months free compared to monthly',
          'All Monthly features',
          'Early access features',
          'Campus updates',
        ], featured: true, recommended: true),
      ],
    );
  }

  Widget _planCard(
    BuildContext context,
    String title,
    String price,
    String period,
    List<String> features, {
    bool featured = false,
    bool recommended = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: featured ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: featured ? Border.all(color: AppColors.primary, width: 2) : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              if (featured) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Best Value',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (recommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.recommend, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Recommended',
                        style: GoogleFonts.notoSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.notoSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                period,
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await _contactSupport();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email composer opened. Complete your subscription via email.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Subscribe',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('What you get', style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
        const SizedBox(height: 12),
        _benefitRow('Accurate entrance-based walking routes'),
        _benefitRow('Nearest-road snapping for car/bike'),
        _benefitRow('Favorites and settings sync across devices'),
        _benefitRow('Help & Support with fast response'),
        _benefitRow('Campus updates and improvements'),
      ]),
    );
  }

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        const Icon(Icons.star, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondary))),
      ]),
    );
  }
}
