import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_navbar.dart';
import '../widgets/animated_success_card.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 1200));
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
        ),
      ),
      bottomNavigationBar: const ModernNavBar(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.diamond_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                'Campus Pro',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryAdaptive(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Unlock the full campus experience with AR directions, AI-powered recommendations, and advanced navigation features.',
            style: GoogleFonts.notoSans(
              fontSize: 15,
              color: AppColors.textSecondaryAdaptive(context),
              height: 1.5,
            ),
          ),
        ],
      ),
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
        ),
        const SizedBox(height: 16),
        _planCard(
          context,
          'Yearly Plan',
          '₦20,000',
          'per year',
          [
            {'icon': Icons.savings_rounded, 'text': '₦4,000 saved vs monthly', 'color': const Color(0xFF4CAF50)},
            {'icon': Icons.view_in_ar_rounded, 'text': 'AR Navigation (3D arrows)', 'color': const Color(0xFF9C27B0)},
            {'icon': Icons.auto_awesome_rounded, 'text': 'AI-powered suggestions', 'color': const Color(0xFFFF5722)},
            {'icon': Icons.offline_bolt_rounded, 'text': 'Offline maps', 'color': const Color(0xFF00BCD4)},
            {'icon': Icons.stars_rounded, 'text': 'Early access to features', 'color': const Color(0xFFFFC107)},
          ],
          recommended: true,
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
            color: const Color(0xFFFFD700).withOpacity(0.3),
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
                        color: const Color(0xFFFFD700).withOpacity(0.4),
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
                color: (f['color'] as Color).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (f['color'] as Color).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (f['color'] as Color).withOpacity(0.15),
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
            child: ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: recommended ? const Color(0xFFFFD700) : AppColors.primary,
                foregroundColor: recommended ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: recommended ? 4 : 0,
              ),
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
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
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
              color: color.withOpacity(0.15),
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
