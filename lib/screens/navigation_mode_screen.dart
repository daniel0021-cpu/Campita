import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/preferences_service.dart';
import '../utils/app_settings.dart';

class NavigationModeScreen extends StatelessWidget {
  const NavigationModeScreen({super.key});

  static final _modes = <_NavModeOption>[
    _NavModeOption('Walking', Icons.directions_walk, 'Pedestrian routing to entrances'),
    _NavModeOption('Driving', Icons.directions_car, 'Road-based routing for vehicles'),
    _NavModeOption('Transit', Icons.directions_bus, 'Bus / public campus shuttles'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text('Navigation Mode', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose how you want to move around campus', style: GoogleFonts.notoSans(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: _modes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final opt = _modes[index];
                  return _NavModeCard(option: opt, onSelected: (value) async {
                    final prefs = PreferencesService();
                    await prefs.saveSettings(navigationMode: value);
                    AppSettings.navigationMode.value = value.toLowerCase();
                    if (context.mounted) Navigator.pop(context, value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavModeOption {
  final String name;
  final IconData icon;
  final String subtitle;
  const _NavModeOption(this.name, this.icon, this.subtitle);
}

class _NavModeCard extends StatelessWidget {
  final _NavModeOption option;
  final ValueChanged<String> onSelected;
  const _NavModeCard({required this.option, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onSelected(option.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderAdaptive(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 115 : 20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(31),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(option.icon, color: AppColors.primary, size: 30),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.name, style: GoogleFonts.notoSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryAdaptive(context))),
                  const SizedBox(height: 6),
                  Text(option.subtitle, style: GoogleFonts.notoSans(fontSize: 13, color: AppColors.textSecondaryAdaptive(context))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
