import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/map_style.dart';

class MapLayersSheet extends StatefulWidget {
  final MapStyle currentStyle;
  final Function(MapStyle) onStyleChanged;

  const MapLayersSheet({
    super.key,
    required this.currentStyle,
    required this.onStyleChanged,
  });

  @override
  State<MapLayersSheet> createState() => _MapLayersSheetState();
}

class _MapLayersSheetState extends State<MapLayersSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _close,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: () {}, // Prevent tap through
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.layers_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Map Layers',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.darkGrey,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: isDark ? Colors.white70 : AppColors.grey,
                              ),
                              onPressed: _close,
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.06),
                      ),
                      
                      // Map styles
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildStyleTile(
                              MapStyle.standard,
                              'Standard',
                              'Default street map',
                              Icons.map_rounded,
                              isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildStyleTile(
                              MapStyle.satellite,
                              'Satellite',
                              'High-res aerial view',
                              Icons.satellite_alt_rounded,
                              isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildStyleTile(
                              MapStyle.satelliteHybrid,
                              'Satellite + Labels',
                              'Aerial with street names',
                              Icons.layers_rounded,
                              isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildStyleTile(
                              MapStyle.terrain3d,
                              '3D Terrain',
                              'Elevation & landforms',
                              Icons.view_in_ar_rounded,
                              isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildStyleTile(
                              MapStyle.topo,
                              'Topographic',
                              'Detailed contour lines',
                              Icons.terrain_rounded,
                              isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildStyleTile(
                              MapStyle.dark,
                              'Dark Mode',
                              'Night-friendly map',
                              Icons.dark_mode_rounded,
                              isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildStyleTile(
                              MapStyle.streetHD,
                              'Street HD',
                              'Ultra-clear street view',
                              Icons.hd_rounded,
                              isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyleTile(
    MapStyle style,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = widget.currentStyle == style;

    return InkWell(
      onTap: () {
        widget.onStyleChanged(style);
        _close();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark
                  ? Colors.grey[800]?.withOpacity(0.5)
                  : AppColors.ash),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.4)
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : (isDark
                        ? Colors.grey[700]
                        : Colors.white),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white70 : AppColors.darkGrey),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.darkGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : AppColors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
