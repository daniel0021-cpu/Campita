import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../utils/preferences_service.dart';
import '../utils/app_settings.dart';

class MapStyleScreen extends StatelessWidget {
  const MapStyleScreen({super.key});

  static final _styles = <_MapStyleOption>[
    _MapStyleOption('Standard', Icons.map, 'Default campus map'),
    _MapStyleOption('Satellite', Icons.satellite_alt, 'High-res imagery'),
    _MapStyleOption('Terrain', Icons.terrain, 'Elevation & land'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ash,
      appBar: AppBar(
        title: Text('Map Style', style: AppTextStyles.heading2.copyWith(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose your default map appearance', style: GoogleFonts.notoSans(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: _styles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final opt = _styles[index];
                  return _MapStyleCard(option: opt, onSelected: (value) async {
                    final prefs = PreferencesService();
                    await prefs.saveSettings(mapStyle: value);
                    AppSettings.mapStyle.value = value.toLowerCase();
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

class _MapStyleOption {
  final String name;
  final IconData icon;
  final String subtitle;
  const _MapStyleOption(this.name, this.icon, this.subtitle);
}

class _MapStyleCard extends StatelessWidget {
  final _MapStyleOption option;
  final ValueChanged<String> onSelected;
  const _MapStyleCard({required this.option, required this.onSelected});

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
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
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
                color: AppColors.primary.withOpacity(0.12),
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
