import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.notoSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              'Acceptance of Terms',
              'By accessing and using the Campus Navigation application, you accept and agree to be bound by the terms and provisions of this agreement.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Use License',
              'Permission is granted to temporarily use the Campus Navigation app for personal, non-commercial use only. This license shall automatically terminate if you violate any of these restrictions.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'User Responsibilities',
              '• You are responsible for maintaining the confidentiality of your account\n'
                  '• You must provide accurate and complete information\n'
                  '• You must not misuse the navigation services\n'
                  '• You are responsible for all activities under your account',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Location Services',
              'This app uses GPS and location services to provide navigation features. By using the app, you consent to the collection and use of location data. Location data is used solely for navigation purposes and is not shared with third parties.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Content Accuracy',
              'While we strive to provide accurate campus information and navigation data, we do not guarantee the completeness, reliability, or accuracy of this information. Building locations, routes, and other data are subject to change.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Privacy Policy',
              'Your privacy is important to us. We collect and use information in accordance with our Privacy Policy. By using the app, you consent to our data collection and usage practices as described in the Privacy Policy.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Intellectual Property',
              'The Campus Navigation app, including its original content, features, and functionality, is owned by Igbinedion University and is protected by international copyright, trademark, and other intellectual property laws.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Limitation of Liability',
              'In no event shall Campus Navigation or Igbinedion University be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Service Modifications',
              'We reserve the right to modify or discontinue the service at any time without notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuance of the service.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Third-Party Services',
              'The app may contain links to third-party websites or services that are not owned or controlled by Campus Navigation. We have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party sites or services.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Updates and Changes',
              'We may update these Terms and Conditions from time to time. We will notify users of any changes by posting the new Terms and Conditions on this page and updating the "Last Updated" date.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Termination',
              'We may terminate or suspend your access to the service immediately, without prior notice or liability, for any reason, including if you breach the Terms and Conditions.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Governing Law',
              'These Terms shall be governed and construed in accordance with the laws of Nigeria, without regard to its conflict of law provisions.',
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              'Contact Information',
              'If you have any questions about these Terms and Conditions, please contact us at:\n\n'
                  'Email: admin@dmanapp.com\n'
                  'Location: Igbinedion University Okada, Edo State, Nigeria',
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'Last Updated: November 20, 2025',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
